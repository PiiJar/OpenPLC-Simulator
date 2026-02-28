# DepartureScheduler — ST-pariteettipäivitykset — Muutossuunnitelma

**Projekti:** OpenPLC Simulator — PLC Structured Text  
**Päivitetty:** 2026-02-28  
**Referenssi:** `PLC Simulator/sim-core/departureScheduler.js` (3167 riviä) + `transporterTaskScheduler.js` (idle-slot fit)  
**Kohde:** `openplc/OpenPLC/src/DEP_FB_*.st` + `TSK_FB_Scheduler.st` + `types.st`

---

## Yhteenveto

Tavoite on **täysi toiminnallinen pariteetti** JS-DepartureSchedulerin kanssa: ST:n tulee tuottaa samat ACTIVATE/REJECT-päätökset, viiveketjut ja pending write -payloadit samoilla syötteillä.

Pariteettiraportin lähdekoodikatselmoinnissa (JS vs ST rivi riviltä) tunnistettiin **12 parity-gappia** kolmella vakavuustasolla:

| #    | Vakavuus | Muutos | Kohdetiedosto(t) | Arvio |
|------|----------|--------|-------------------|-------|
| G01  | CRITICAL | Pending write -payload vajaa | `TSK_FB_Scheduler.st` | ~10 riviä |
| G02  | CRITICAL | Backward chaining puuttuu | `DEP_FB_Scheduler.st` | ~60 riviä |
| G03  | HIGH     | `need_extra_s` ei tallennu overflow-polussa | `DEP_FB_FitTaskToSlot.st` | ~15 riviä |
| G04  | HIGH     | Stage 0 delay → välitön RECALC vs. continue | `DEP_FB_Scheduler.st` | ~30 riviä |
| G05  | HIGH     | Ensimmäisen idle-slotin lähtöankkuri = 0 | `DEP_FB_CalcIdleSlots.st` | ~10 riviä |
| G06  | HIGH     | Waiting-listan FIFO-sorttaus puuttuu | `DEP_FB_Scheduler.st` | ~30 riviä |
| G07  | HIGH     | `location < 100` hylätään suoraan | `DEP_FB_Scheduler.st` | ~15 riviä |
| G08  | MEDIUM   | Overlap-ehto: station equality vs. zone membership | `DEP_FB_OverlapDelay.st` | ~20 riviä |
| G09  | MEDIUM   | Overlap-flag domain `[101..130]` vs. `[0..200]` | `types.st` | ~5 riviä |
| G10  | HIGH     | Stage 0 overlap check puuttuu kokonaan | `DEP_FB_Scheduler.st` | ~20 riviä |
| G11  | HIGH     | Idle-slot trimming puuttuu taskien välillä | `DEP_FB_Scheduler.st` | ~15 riviä |
| G12  | MEDIUM   | Hardcoded transporter guard `> 3` | `DEP_FB_CalcIdleSlots.st`, `DEP_FB_FitTaskToSlot.st` | ~4 riviä |

**Toteutusjärjestys:** D1 → D2 → D3 → D4 → D5  
(Kriittinen handoff ensin, sitten core fit/resolve, sitten ordering, overlap, verifiointi)

### Pariteetin hyväksymiskriteerit (Definition of Done)

1. **Päätöspariteetti:** Samalla syötteellä JS ja ST tekevät saman ACTIVATE/REJECT-päätöksen jokaiselle odottavalle erälle.
2. **Viivepariteetti:** Delay action -joukko (stage, delay, writeTarget) on funktionaalisesti sama.
3. **Kierrospariteetti:** Kierrosten määrä ennen päätöstä on sama toleranssilla ±1 tick.
4. **Handoff-pariteetti:** DEP→TSK pending write -sisältö tuottaa saman lopullisen `g_program` + `g_schedule` + `g_batch.cur_stage` -tilan.
5. **Stabiilisuus:** Ei loop-jumiutumista, ei kasvavaa driftiä toistuvissa departure-sykleissä.
6. **Build + deploy** onnistuu ilman PLC-käännösvirheitä.

---

## Koodipohja analyysille

### JS-referenssi
- `PLC Simulator/sim-core/departureScheduler.js` — 3167 riviä, vaiherakenne PHASE 0–4101
- `PLC Simulator/sim-core/transporterTaskScheduler.js` — `fitSingleTaskToIdleSlots()` (rivi 4830+), `calculateTransporterIdleSlots()`

### ST-toteutus
- `DEP_FB_Scheduler.st` — 548 riviä, phase 0–9000
- `DEP_FB_CalcIdleSlots.st` — ~90 riviä
- `DEP_FB_FitTaskToSlot.st` — ~170 riviä
- `DEP_FB_CalcOverlap.st` — ~75 riviä
- `DEP_FB_OverlapDelay.st` — ~135 riviä
- `DEP_FB_Sandbox.st` — ~80 riviä
- `TSK_FB_Scheduler.st` — phase 10100 (DEP pending write kulutus)
- `types.st` — DEP-tyypit (DEP_PENDING_WRITE_T, DEP_OVERLAP_T, DEP_FIT_RESULT_T)

---

## Parity-gapit — Yksityiskohtainen analyysi

---

### G01 — Pending write -payload ei ole semanttisesti sama
**Vakavuus:** CRITICAL

**JS (departureScheduler.js, ACTIVATE phase 3090, rivi ~2930):**
```javascript
state.pendingWriteData = {
    valid: true,
    programsByBatchId: ...,      // KAIKKI ohjelmat
    schedulesByBatchId: ...,     // KAIKKI aikataulut
    batchCalcUpdates,            // Muuttuneet erien calc_time -arvot
    currentTimeSec: ctx.currentTimeSec
};
```
TASKS SAVE -phase kirjoittaa **sekä ohjelmat, aikataulut** että batch-stage-muutoksen.

**ST (TSK_FB_Scheduler.st, phase 10100, rivit 283–294):**
```iecst
IF g_dep_pending.valid THEN
  FOR ui := 1 TO MAX_UNITS DO
    g_program[ui] := g_dep_pending.programs[ui];   (* ← vain ohjelmat! *)
  END_FOR;
  g_batch[g_dep_pending.batch_unit].cur_stage := g_dep_pending.batch_stage;
  g_dep_pending.valid := FALSE;
  next_phase := 1;
END_IF;
```
**Puuttuu:** `g_schedule[ui] := g_dep_pending.schedule[ui]` — aikataulut jäävät kopioimatta. Myös `time_s` -kenttää ei käytetä mihinkään.

**Vaikutus:** TSK jatkaa vanhalla aikataululla vaikka DEP on laskenut uuden. Taskit luodaan väärillä start/finish-ajoilla → konfliktit ja viivevirheet.

---

### G02 — Backward chaining puuttuu ST:stä
**Vakavuus:** CRITICAL

**JS (departureScheduler.js, CHECK_ANALYZE phase 3004, rivit 2140–2190):**
```javascript
// Ei mahdu → backward chaining
let remainingNeed = fitResult.needExtra;
for (let backIdx = taskIdx - 1; backIdx >= 0 && remainingNeed > 0; backIdx--) {
    const prevTask = waitingBatchTasks[backIdx];
    const prevCappedFlex = Math.max(0, prevTask.max_time_s - prevTask.calc_time_s) * flexUpFactor;
    const useDelay = Math.min(prevCappedFlex, remainingNeed);
    if (useDelay > marginSec) {
        chainDelays.push({ stage: prevTask.stage, delay: useDelay, ... });
        remainingNeed -= useDelay;
    }
}
```

**ST (DEP_FB_Scheduler.st, phase 2001, rivi 428):**
```iecst
ELSE
  (* Does not fit → REJECT (simplified: no backward chaining) *)
  next_phase := 9000;
END_IF;
```

**Vaikutus:** ST hylkää eriä joissa yksittäisen stagen oma flex ei riitä, mutta aiempien stagejen ketjutettu joustovara riittäisi. Tämä on DEP:n yleisin false-REJECT -skenaario.

---

### G03 — `need_extra_s` ei tallennu overflow-polussa
**Vakavuus:** HIGH

**JS (transporterTaskScheduler.js, fitSingleTaskToIdleSlots, rivi ~4880):**
```javascript
if (delay > cappedFlex + 1.0) {
    return { fits: false, delay, needExtra: delay - cappedFlex, ... };
}
```
`needExtra` palautetaan suoraan, koska `delay` on laskettu jokaiselle slotille.

**ST (DEP_FB_FitTaskToSlot.st, rivit 125–140):**
```iecst
IF delay <= capped_flex + i_margin_s THEN
  IF delay < best_delay THEN
    best_delay := delay;      (* ← päivittyy VAIN tässä haarassa *)
    best_slot  := si;
    found      := TRUE;
  END_IF;
END_IF;
```
Overflow-polussa (`delay > capped_flex + margin`) `best_delay` ei päivity → jää arvoon `1.0E9` → `IF best_delay < 1.0E8 THEN` on FALSE → `need_extra_s := 0.0`.

**Vaikutus:** Vaikka backward chaining lisättäisiin (G02), ST ei raportoisi oikeaa `need_extra_s`-arvoa → ketjutus ei tiedä paljonko joustoa tarvitaan.

**Korjaus:** Tarvitaan erillinen `overflow_best_delay`-muuttuja joka päivittyy myös flex-ylityksen polussa.

---

### G04 — Stage 0 -viiveen käsittely poikkeaa
**Vakavuus:** HIGH

**JS (CHECK_ANALYZE, rivit 2050–2070):**
```javascript
if (stage0Delay > fitParams.marginSec) {
    delayActions.push({ stage: 0, delay: stage0Delay, writeTarget: 'batch', ... });
    allFitNoChanges = false;
}
// ...
continue;  // ★ Stage 0 OK, jatka seuraavaan tehtävään (stage 1+)
```
JS kirjaa stage 0 delayn, mutta **jatkaa samalla kierroksella** stage 1+ tehtäviin. Vain stage 1+ delay päättää kierroksen RECALCiin.

**ST (DEP_FB_Scheduler.st, phase 2000, rivit 353–358):**
```iecst
IF stage0_delay > MARGIN_S THEN
  sched_base_time := sched_base_time + REAL_TO_LINT(stage0_delay);
  fit_round := fit_round + 1;
  IF fit_round > MAX_FIT_ROUNDS THEN
    next_phase := 9000;
  ELSE
    next_phase := 1010;   (* ★ RECALC välittömästi — ei jatketa stage 1+:iin *)
  END_IF;
END_IF;
```

**Vaikutus:** ST tekee ylimääräisiä RECALC-kierroksia → hidastaa konvergenssia, voi johtaa `MAX_FIT_ROUNDS`-ylitykseen ja REJECTiin tapauksissa joissa JS aktivoisi ensimmäisellä kierroksella.

---

### G05 — Ensimmäisen idle-slotin lähtöankkuri ei vastaa JS:ää
**Vakavuus:** HIGH

**JS (calculateTransporterIdleSlots):**
```javascript
if (slot.prevTask) {
    // prevTask.sink → nostoasema travel
} else if (transporter.start_station) {
    // start_station → nostoasema travel (fallback)
}
```

**ST (DEP_FB_CalcIdleSlots.st, rivi 53):**
```iecst
prev_sink := 0;   (* ← aina 0 ensimmäiselle slotille *)
```

**ST (DEP_FB_FitTaskToSlot.st, rivi 94):**
```iecst
IF from_stn > 0 AND from_stn <> i_lift_stn THEN
  (* laske matka — MUTTA from_stn = 0 → skippataan kokonaan *)
  travel_to := fb_travel_to.o_travel_s;
END_IF;
```

**Vaikutus:** Ensimmäisen idle-slotin travel-to-pickup = 0 → erä aktivoituu liian aikaisin suhteessa nostimen todelliseen sijaintiin.

**Korjaus:** Ensimmäisen slotin `lift_station` tulee olla nostimen `start_station` (tai todellinen sijainti).

---

### G06 — Waiting-järjestys (FIFO loaded_s) puuttuu ST:stä
**Vakavuus:** HIGH

**JS (WAITING_SORT_LOADED, rivi ~1530):**
```javascript
_insertionSort(state.waitingBatches, ..., function(aIdx, bIdx) {
    const loadedA = analysisA.loaded_s || batchA.loaded_s || batchA.start_time_s || 0;
    const loadedB = analysisB.loaded_s || batchB.loaded_s || batchB.start_time_s || 0;
    return loadedA - loadedB;
});
```

**ST (DEP_FB_Scheduler.st, phase 100):**
```iecst
(* Find waiting batches (cur_stage = 90) *)
fb_collect_wait(i_mode := 1);
waiting_cnt := fb_collect_wait.o_count;
FOR ui := 1 TO waiting_cnt DO
  waiting_list[ui] := fb_collect_wait.o_list[ui];
END_FOR;
(* ← Ei sorttausta *)
```

**Vaikutus:** Eri aktivointijärjestys → eri erä aktivoituu kun useita odottaa samanaikaisesti.

---

### G07 — Waiting batch transporterissa (`location < 100`) käsitellään eri tavalla
**Vakavuus:** HIGH

**JS:** Tukee odottavaa erää nostimessa — `isOnTransporter`-tarkistus löytää nostimen sijainnin ja käyttää sitä pickup-laskennassa.

**ST (DEP_FB_Scheduler.st, phase 2000, rivi 320):**
```iecst
IF first_stn = 0 OR loading_stn < 100 THEN
  (* No valid schedule or batch not on station → reject *)
  next_phase := 9000;
END_IF;
```

**Vaikutus:** ST hylkää suoraan erät jotka ovat nosturissa odottamassa (location = nostimen id, esim. 1–3). JS käsittelee nämä validisti.

---

### G08 — Overlap-konfliktin ehto on ST:ssä tiukempi kuin JS:ssä
**Vakavuus:** MEDIUM

**JS (calculateOverlapDelay, rivi ~770):**
```javascript
for (const existing of existingTasks) {
    if (existing.transporter_id === tId) continue;
    const eLift = existing.lift_station_id;
    const eSink = existing.sink_station_id;
    // Tarkistaa: onko EXISTING tehtävän lift/sink overlap-alueella?
    if (!(overlapStations.flags[eLift]) && !(overlapStations.flags[eSink])) continue;
    // ↑ Zone membership: "käyttääkö existing overlap-asemaa YLIPÄÄTÄÄN"
```

**ST (DEP_FB_OverlapDelay.st, rivit 98–104):**
```iecst
has_ovlp := FALSE;
IF lift_is_overlap AND (e_lift = i_lift_stn OR e_sink = i_lift_stn) THEN
  has_ovlp := TRUE;
END_IF;
IF sink_is_overlap AND (e_lift = i_sink_stn OR e_sink = i_sink_stn) THEN
  has_ovlp := TRUE;
END_IF;
```
ST vaatii **station equality** (`e_lift = i_lift_stn`) — ei pelkästään zone-jäsenyyttä.

**Esimerkki:** Task A (101→103), Task B (102→104), station 102 ja 103 ovat overlap-alueella.
- JS: B:n lift=102 on overlap → aikakonflikti → delay
- ST: B:n e_lift=102 ≠ A:n i_lift=101 JA e_lift=102 ≠ A:n i_sink=103 → has_ovlp=FALSE → delay puuttuu

**Vaikutus:** ST voi jättää overlap-viiveen lisäämättä → nosturit törmäävät overlap-alueella.

---

### G09 — Overlap-flagien domain on eri
**Vakavuus:** MEDIUM

**JS:**
```javascript
const MAX_STATIONS = 200;
for (let i = 0; i <= MAX_STATIONS; i++) coverageCount[i] = 0;
```

**ST (types.st):**
```iecst
TYPE DEP_OVERLAP_T :
STRUCT
  flags : ARRAY[101..130] OF BOOL;
```

**Vaikutus:** Nykyisillä plant-templateilla riittää, mutta laajennettavuus on rajattu. Jos asemia lisätään alueen ulkopuolelle, overlap-tarkistus ei toimi.

---

### G10 — Stage 0 overlap check puuttuu kokonaan ST:stä
**Vakavuus:** HIGH

**JS (CHECK_ANALYZE, rivit 2003–2013):**
```javascript
if (overlapStations.count > 0 &&
    (overlapStations.flags[task.lift_station_id] || overlapStations.flags[task.sink_station_id])) {
    const stage0OverlapDelay = calculateOverlapDelay(
        task, effectiveStart - task.task_start_time,
        existingTasks, overlapStations, fitParams.conflictMarginSec
    );
    if (stage0OverlapDelay > 0) {
        effectiveStart += stage0OverlapDelay;
    }
}
```
JS tekee overlap-tarkistuksen **myös** stage 0:lle ennen slottiin mahtumisen tarkistusta.

**ST (DEP_FB_Scheduler.st, phase 2000):**
Stage 0 -käsittelyssä ei kutsuta `fb_ovlp_delay`:ta lainkaan. Overlap-tarkistus on vain phase 2001:ssa (stage 1+).

**Vaikutus:** Jos pickup-asema on overlap-alueella, ST ei huomioi toisen nostimen tehtäviä → aikatauluero.

---

### G11 — Idle-slot trimming puuttuu taskien välillä
**Vakavuus:** HIGH

**JS (CHECK_ANALYZE, rivit 2065–2080):**
```javascript
if (fitResult.fits) {
    // Typistä idle-slottia: tehtävä varaa alun, slotin start siirtyy tehtävän loppuun
    if (fitResult.slot && fitResult.taskEndTime != null) {
        fitResult.slot.start = fitResult.taskEndTime;
        fitResult.slot.duration = fitResult.slot.end - fitResult.slot.start;
    }
}
```
Myös stage 0:lle:
```javascript
const taskEndTime = effectiveStart + taskDuration;
slot.start = taskEndTime;
slot.duration = slot.end - slot.start;
```
JS **typistää** idle-slotin jokaisella onnistuneella sovituksella → seuraava taski näkee pienemmän loppu-slotin.

**ST:** Idle-slotit lasketaan kerran (phase 1040) eikä niitä päivitetä onnistuneen fitin jälkeen. Jokainen taski näkee alkuperäiset, trimmaamattomat slotit.

**Vaikutus:** Kaksi taskia voivat molemmat "mahtua" samaan idle-slottiin → todellisuudessa päällekkäisyys → nostinkonflikti ajon aikana.

---

### G12 — Hardcoded transporter guard `> 3`
**Vakavuus:** MEDIUM

**ST (DEP_FB_FitTaskToSlot.st, rivi 73):**
```iecst
IF i_trans_id < 1 OR i_trans_id > 3 THEN
  RETURN;
END_IF;
```

**ST (DEP_FB_CalcIdleSlots.st, rivi 44):**
```iecst
IF i_trans < 1 OR i_trans > 3 THEN
  RETURN;
END_IF;
```

**Pitäisi olla:** `> MAX_TRANSPORTERS`

**Vaikutus:** Jos plant-config tukee > 3 nostinta, DEP ei käsittele niitä. JS:ssä ei ole vastaavaa kovakoodattua rajaa.

---

## Vaiheistettu muutossuunnitelma

---

## Phase D1 — Kriittinen handoff-pariteetti (G01)

**Kohde:** `TSK_FB_Scheduler.st` phase 10100

### Muutos

Lisää schedule-kopiointi ja time_s-käsittely pending-datan kulutukseen:

```iecst
(* PHASE 10100: CHECK_DEP_PENDING — DEP activated a batch *)
IF g_dep_pending.valid THEN
  (* Apply DEP's pending data: programs + schedules + stage change *)
  FOR ui := 1 TO MAX_UNITS DO
    g_program[ui]  := g_dep_pending.programs[ui];
    g_schedule[ui] := g_dep_pending.schedule[ui];    (* ← UUSI *)
  END_FOR;
  IF g_dep_pending.batch_unit >= 1 AND g_dep_pending.batch_unit <= MAX_UNITS THEN
    g_batch[g_dep_pending.batch_unit].cur_stage := g_dep_pending.batch_stage;
  END_IF;
  g_dep_pending.valid := FALSE;
  next_phase := 1;
END_IF;
```

### Perustelut

- Pienin mahdollinen muutos (~2 riviä)
- Suurin vaikutus: ilman tätä kaikki DEP:n laskemat aikataulut ovat käyttämättömiä TSK:lle
- Ei riko olemassa olevaa logiikkaa: schedule-data on jo `g_dep_pending`-rakenteessa

**Exit-kriteeri:** DEP activation tuottaa saman `g_program` + `g_schedule` + `g_batch.cur_stage` -tilan kuin JS.

---

## Phase D2 — Fit/resolve-ytimen parity (G02, G03, G04, G05, G07, G10, G11)

### D2.1: Backward chaining (G02 + G03)

**Kohde:** `DEP_FB_FitTaskToSlot.st` + `DEP_FB_Scheduler.st`

#### DEP_FB_FitTaskToSlot.st — overflow-polun korjaus (G03)

Lisää erillinen `overflow_best_delay` -muuttuja joka päivittyy myös flex-ylityksen polussa:

```iecst
(* Uudet VAR: *)
overflow_best_delay : REAL;
overflow_best_slot  : INT;
```

Muutetaan fit-silmukan loppuosa:

```iecst
(* Check if task fits *)
IF earliest + task_dur <= latest THEN
  delay := LINT_TO_REAL(earliest - i_task_start) - i_shift_s;
  IF delay < 0.0 THEN delay := 0.0; END_IF;

  IF delay <= capped_flex + i_margin_s THEN
    (* Fits within flex *)
    IF delay < best_delay THEN
      best_delay := delay;
      best_slot  := si;
      found      := TRUE;
    END_IF;
  ELSE
    (* Flex overflow — track separately for backward chaining *)
    IF delay < overflow_best_delay THEN
      overflow_best_delay := delay;
      overflow_best_slot  := si;
    END_IF;
  END_IF;
END_IF;
```

Ja output-laskenta:

```iecst
IF found THEN
  o_result.fits      := TRUE;
  o_result.delay_s   := best_delay;
  o_result.slot_idx  := best_slot;
  o_result.task_end_s := ...;
  o_result.need_extra_s := 0.0;
ELSE
  o_result.fits := FALSE;
  IF overflow_best_delay < 1.0E8 THEN
    (* Overflow found — report shortfall for backward chaining *)
    o_result.delay_s      := overflow_best_delay;
    o_result.need_extra_s := overflow_best_delay - capped_flex;
    IF o_result.need_extra_s < 0.0 THEN o_result.need_extra_s := 0.0; END_IF;
  ELSE
    (* No slot at all *)
    o_result.need_extra_s := 0.0;
  END_IF;
END_IF;
```

#### DEP_FB_Scheduler.st — backward chaining (G02)

Korvaa phase 2001:n REJECT-haara (`next_phase := 9000`) backward chaining -logiikalla:

```iecst
ELSE
  (* Does not fit → try backward chaining *)
  IF fb_fit.o_result.need_extra_s <= 0.0 THEN
    (* No slot at all → reject *)
    next_phase := 9000;
  ELSE
    (* Walk backward through w_tasks, accumulate flex *)
    remaining_need := fb_fit.o_result.need_extra_s;
    chain_delay_cnt := 0;
    chain_ok := FALSE;

    FOR bk := cur_task_idx - 1 TO 1 BY -1 DO
      IF remaining_need <= MARGIN_S THEN
        chain_ok := TRUE;
        EXIT;
      END_IF;
      prev_flex_up := w_tasks[bk].max_time - w_tasks[bk].calc_time;
      IF prev_flex_up < 0.0 THEN prev_flex_up := 0.0; END_IF;
      prev_capped := prev_flex_up * FLEX_FACTOR;
      use_delay := prev_capped;
      IF use_delay > remaining_need THEN use_delay := remaining_need; END_IF;

      IF use_delay > MARGIN_S THEN
        chain_delay_cnt := chain_delay_cnt + 1;
        IF chain_delay_cnt <= 10 THEN
          chain_delays[chain_delay_cnt].stage   := w_tasks[bk].stage;
          chain_delays[chain_delay_cnt].delay_s := use_delay;
          chain_delays[chain_delay_cnt].target  := 1;  (* program stage *)
          IF w_tasks[bk].stage = 0 THEN
            chain_delays[chain_delay_cnt].target := 0;  (* batch *)
          END_IF;
          chain_delays[chain_delay_cnt].valid := TRUE;
        END_IF;
        remaining_need := remaining_need - use_delay;
      END_IF;
    END_FOR;

    IF remaining_need <= MARGIN_S THEN chain_ok := TRUE; END_IF;

    IF chain_ok THEN
      (* Apply chain delays + original delay → RECALC *)
      FOR ci := 1 TO chain_delay_cnt DO
        IF chain_delays[ci].valid THEN
          (* Same applying logic as phase 3000 *)
          ... (* apply to program or sched_base_time *)
        END_IF;
      END_FOR;
      IF fb_fit.o_result.delay_s > MARGIN_S THEN
        delay_stage  := si;
        delay_amount := fb_fit.o_result.delay_s;
        delay_target := 1;
      END_IF;
      fit_round := fit_round + 1;
      IF fit_round > MAX_FIT_ROUNDS THEN
        next_phase := 9000;
      ELSE
        next_phase := 1010;  (* RECALC *)
      END_IF;
    ELSE
      (* Backward chaining insufficient → REJECT *)
      next_phase := 9000;
    END_IF;
  END_IF;
END_IF;
```

**Uudet muuttujat (DEP_FB_Scheduler VAR):**
```iecst
remaining_need   : REAL;
chain_delays     : ARRAY[1..10] OF DEP_DELAY_ACTION_T;
chain_delay_cnt  : INT;
chain_ok         : BOOL;
prev_flex_up     : REAL;
prev_capped      : REAL;
use_delay        : REAL;
bk               : INT;     (* backward loop index *)
ci               : INT;     (* chain apply loop index *)
```

### D2.2: Stage 0 continue-semantiikka (G04)

**Kohde:** `DEP_FB_Scheduler.st` phase 2000

Muutetaan stage 0 delay -haara niin, että delay kirjataan mutta analyysi **jatkuu stage 1+ -tehtäviin**:

```iecst
IF stage0_delay > MARGIN_S THEN
  (* Record stage 0 delay, but CONTINUE to stage 1+ (like JS) *)
  (* Store pending stage 0 delay for later application *)
  stage0_pending_delay := stage0_delay;
  sched_base_time := sched_base_time + REAL_TO_LINT(stage0_delay);
END_IF;

(* ★ Proceed to stage 1+ regardless of stage 0 delay *)
IF w_task_cnt = 0 THEN
  IF stage0_pending_delay > MARGIN_S THEN
    (* Only stage 0 delay, no more tasks → apply delay and recalc *)
    delay_stage  := 0;
    delay_amount := stage0_pending_delay;
    delay_target := 0;
    next_phase   := 3000;
  ELSE
    next_phase := 8000;  (* ACTIVATE *)
  END_IF;
ELSE
  cur_task_idx := 1;
  next_phase := 2001;    (* Continue to stage 1+ fit *)
END_IF;
```

Vastaavasti phase 2001:n onnistunut lopetus (`cur_task_idx > w_task_cnt`) tarkistaa onko stage 0 delay -odottamassa:
```iecst
IF cur_task_idx > w_task_cnt THEN
  IF stage0_pending_delay > MARGIN_S THEN
    (* Stage 0 delay recorded, no stage 1+ delays → apply stage 0 delay and RECALC *)
    delay_stage  := 0;
    delay_amount := stage0_pending_delay;
    delay_target := 0;
    next_phase   := 3000;
  ELSE
    next_phase := 8000;  (* All fit → ACTIVATE *)
  END_IF;
```

**Uusi muuttuja:**
```iecst
stage0_pending_delay : REAL;
```

### D2.3: Ensimmäisen idle-slotin lähtöankkuri (G05)

**Kohde:** `DEP_FB_CalcIdleSlots.st`

Muutetaan `prev_sink`-alustuks (rivi 53):

```iecst
(* First slot anchor: use transporter's start_station as fallback *)
prev_end  := i_time_s;
IF i_trans >= 1 AND i_trans <= MAX_TRANSPORTERS THEN
  prev_sink := g_cfg[i_trans].start_station;    (* ← JS: transporter.start_station *)
ELSE
  prev_sink := 0;
END_IF;
```

Tarvitsee `g_cfg` VAR_EXTERNAL -lisäyksen `DEP_FB_CalcIdleSlots`:iin:
```iecst
VAR_EXTERNAL
  g_cfg : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
END_VAR
```

### D2.4: Location < 100 -tuki (G07)

**Kohde:** `DEP_FB_Scheduler.st` phase 2000

Muutetaan hylkäysehto:

```iecst
IF first_stn = 0 THEN
  next_phase := 9000;
ELSIF loading_stn < 100 THEN
  (* Batch is on transporter — find transporter's current position *)
  (* Use loading_stn as transporter index *)
  IF loading_stn >= 1 AND loading_stn <= MAX_TRANSPORTERS THEN
    fb_find_trans(i_lift_stn := g_cfg[loading_stn].start_station, i_sink_stn := first_stn);
    sched_trans := loading_stn;  (* batch is ON this transporter *)
    loading_stn := g_cfg[loading_stn].start_station;  (* use start_station as pickup *)
  ELSE
    next_phase := 9000;
  END_IF;
END_IF;
```

### D2.5: Stage 0 overlap check (G10)

**Kohde:** `DEP_FB_Scheduler.st` phase 2000

Lisää overlap-tarkistus ennen slottiin mahtumisen tarkistusta:

```iecst
(* ★ Stage 0 overlap check — same as JS *)
fb_ovlp_delay(
  i_lift_stn   := loading_stn,
  i_sink_stn   := first_stn,
  i_trans_id   := sched_trans,
  i_task_start := sched_base_time,
  i_task_end   := sched_base_time + REAL_TO_LINT(xfer_dur),
  i_margin_s   := CONFLICT_MARGIN_S
);
stage0_ovlp := fb_ovlp_delay.o_delay_s;

(* Apply overlap delay to fit call shift *)
fb_fit(
  ...
  i_shift_s := stage0_ovlp,      (* ← was 0.0 *)
  ...
);
```

**Uusi muuttuja:**
```iecst
stage0_ovlp : REAL;
```

### D2.6: Idle-slot trimming (G11)

**Kohde:** `DEP_FB_Scheduler.st` phase 2000 + 2001

Lisää slottien typistys jokaisen onnistuneen fitin jälkeen:

**Phase 2000 (stage 0 fit):**
```iecst
IF fb_fit.o_result.fits THEN
  (* ★ Trim idle slot — same as JS *)
  IF fb_fit.o_result.slot_idx >= 1 AND fb_fit.o_result.slot_idx <= DEP_MAX_IDLE_SLOTS THEN
    g_dep_idle_slot[sched_trans].slots[fb_fit.o_result.slot_idx].start_time :=
      fb_fit.o_result.task_end_s;
  END_IF;
  ...
```

**Phase 2001 (stage 1+ fit):**
```iecst
IF fb_fit.o_result.fits THEN
  (* ★ Trim idle slot *)
  IF fb_fit.o_result.slot_idx >= 1 AND fb_fit.o_result.slot_idx <= DEP_MAX_IDLE_SLOTS THEN
    g_dep_idle_slot[ti].slots[fb_fit.o_result.slot_idx].start_time :=
      fb_fit.o_result.task_end_s;
  END_IF;
  ...
```

**Exit-kriteeri:** Samat hyväksyntä/hylkäyspäätökset ja viiveketjut kuin JS testiskenaarioissa.

---

## Phase D3 — Ordering parity (G06)

**Kohde:** `DEP_FB_Scheduler.st`

### Muutos

Lisää insertion sort waiting-listalle FIFO-avaimella: **ensisijainen `loaded_s` (jos saatavilla), fallback `start_time`**. Sijoitetaan phase 100:n jälkeen, ennen phase 1000:

**Uusi phase 150: SORT_WAITING**
```iecst
ELSIF phase = 150 THEN
  (* Sort waiting list by FIFO key: loaded_s if available, else start_time *)
  FOR si := 2 TO waiting_cnt DO
    tmp_unit := waiting_list[si];
    (* ST: BATCH_T:ssa ei vielä loaded_s-kenttää → käytä start_time fallbackina.
       Jos loaded_s lisätään BATCH_T:hen/gateway-syöttöön, käytä sitä ensisijaisesti. *)
    tmp_key  := g_batch[tmp_unit].start_time;
    ji := si - 1;
    WHILE ji >= 1 AND g_batch[waiting_list[ji]].start_time > tmp_key DO
      waiting_list[ji + 1] := waiting_list[ji];
      ji := ji - 1;
    END_WHILE;
    waiting_list[ji + 1] := tmp_unit;
  END_FOR;
  next_phase := 1000;
```

**Uudet muuttujat:**
```iecst
tmp_unit : INT;
tmp_key  : LINT;
ji       : INT;
```

**Muuta** phase 100:n `next_phase`:
```iecst
(* Ennen: *)
next_phase := 200;
(* Jälkeen: *)
next_phase := 150;   (* Sort waiting list first *)
```

Huom: phase 200 (CALC_OVERLAP) siirretään phase 150:n jälkeen tai ennen sitä — järjestys ei vaikuta, koska overlap-laskenta ei tarvitse sortattua listaa.

Vaihtoehto: `150 → 200 → 1000` tai `200 → 150 → 1000`.

**Exit-kriteeri:** Aktivointijärjestys identtinen JS:n kanssa usean odottavan erän tapauksessa.

---

## Phase D4 — Overlap parity (G08, G09, G12)

### D4.1: Overlap-ehdon korjaus (G08)

**Kohde:** `DEP_FB_OverlapDelay.st`

Muutetaan `has_ovlp`-tarkistus vastaamaan JS:n zone-membership -logiikkaa:

```iecst
(* Nykytila (rivit 98-104): *)
(* has_ovlp = station equality — LIIAN TIUKKA *)

(* Uusi logiikka: onko EXISTING tehtävän lift/sink overlap-alueella YLIPÄÄTÄÄN? *)
has_ovlp := FALSE;
IF e_lift >= STATION_ARRAY_START AND e_lift <= STATION_ARRAY_END THEN
  IF g_dep_overlap.flags[e_lift] THEN
    has_ovlp := TRUE;
  END_IF;
END_IF;
IF NOT has_ovlp AND e_sink >= STATION_ARRAY_START AND e_sink <= STATION_ARRAY_END THEN
  IF g_dep_overlap.flags[e_sink] THEN
    has_ovlp := TRUE;
  END_IF;
END_IF;
```

JS tarkistaa: "Onko existing-tehtävä overlap-alueella?" → jos kyllä JA aikaikkuna limittää → konflikti.

**Huomio:** Myös uuden tehtävän täytyy olla overlap-alueella (lift_is_overlap OR sink_is_overlap). Tämä tarkistus on jo olemassa ja säilyy.

### D4.2: Overlap-flag domain (G09)

**Kohde:** `types.st`

```iecst
(* Nykytila: *)
flags : ARRAY[101..130] OF BOOL;

(* Uusi: *)
flags : ARRAY[0..200] OF BOOL;     (* MAX_STATIONS, sama domain kuin JS *)
```

Tämä vaatii myös `DEP_FB_CalcOverlap.st`:n ja `DEP_FB_OverlapDelay.st`:n bounds-tarkistusten päivitystä.

Tässä suunnitelmassa **ei käytetä vaihtoehtoa pitää domainia [101..130]**, koska tavoite on täysi JS-pariteetti.

### D4.3: Transporter guard (G12)

**Kohde:** `DEP_FB_FitTaskToSlot.st`, `DEP_FB_CalcIdleSlots.st`

```iecst
(* Nykytila: *)
IF i_trans_id < 1 OR i_trans_id > 3 THEN

(* Uusi: *)
IF i_trans_id < 1 OR i_trans_id > MAX_TRANSPORTERS THEN
```

**Exit-kriteeri:** Overlap-konfliktien delay-päätökset vastaavat JS:ää.

---

## Phase D5 — Parity-verifiointi

### Testiskenaariot

| # | Skenaario | Testattavat gapit | Odotettu tulos |
|---|-----------|-------------------|----------------|
| A | Yksittäinen erä, kaikki mahtuvat | G01, G11 | ACTIVATE, samat schedule-ajat |
| B | Yksittäinen erä, stage 2 ei mahdu → backward chain | G02, G03 | JS: ACTIVATE ketjulla, ST: ACTIVATE ketjulla (ei REJECT) |
| C | Stage 0 delay + stage 3 delay | G04 | Sama kierrosmäärä, sama aktivointihetki |
| D | Erä nosturissa (location=2) | G07 | ACTIVATE (ei REJECT loading_stn < 100) |
| E | 3 odottavaa erää, eri loaded_s | G06 | Sama aktivointijärjestys |
| F | Overlap-alue, pickup-asema conflict | G08, G10 | Sama delay-arvo |
| G | 2 taskia samaan idle-slottiin | G11 | Toinen taski näkee trimmautueen slotin |

### Verifointimenetelmä

1. Ajeta sama syötetilanne JS:ssä ja ST:ssä (sama snapshot lähtöpiste).
2. Kirjata: (a) ACTIVATE/REJECT-päätös per erä, (b) delay_actions-joukko, (c) kierrosmäärä, (d) pending write -sisältö.
3. Vertailla funktionaalista tulosmatriiisia — ajoituserot ±1 tick hyväksyttäviä PLC-scan-vuorottelusta johtuen.

### Build & Deploy

```bash
cd openplc/OpenPLC && python3 build_plcxml.py
bash deploy_plc.sh "Nammo Lapua Oy" "Factory X Zinc Phosphating"
docker compose up -d
```

---

## Suositeltu toteutusjärjestys ja riippuvuudet

```
D1: TSK_FB_Scheduler.st phase 10100 (G01)
    │   ↑ ei riippuvuuksia, suurin vaikutus
    │
D2: DEP_FB_Scheduler.st + DEP_FB_FitTaskToSlot.st + DEP_FB_CalcIdleSlots.st
    │   (G02, G03, G04, G05, G07, G10, G11)
    │   ↑ G03 täytyy ennen G02:ta (need_extra_s korjaus ennen backward chaining)
    │   ↑ G11 täytyy ennen G02:ta (trimmaus vaikuttaa slottien kokoon)
    │   Suositeltu sisäinen järjestys: G03 → G11 → G05 → G10 → G04 → G07 → G02
    │
D3: DEP_FB_Scheduler.st (G06)
    │   ↑ itsenäinen, voi tehdä D2:n kanssa rinnakkain
    │
D4: DEP_FB_OverlapDelay.st + types.st + DEP_FB_FitTaskToSlot.st + DEP_FB_CalcIdleSlots.st
    │   (G08, G09, G12)
    │   ↑ itsenäinen
    │
D5: Verifiointi (A–G)
    │   ↑ riippuu D1–D4:stä
```

**Toteutusjärjestys:** D1 → D2 → D3 → D4 → D5

Jokaisen vaiheen jälkeen: `python3 build_plcxml.py` + `bash deploy_plc.sh` + testaus.

---

## Päätökset ja rajaukset

| Päätös | Perustelu |
|--------|-----------|
| D1 ensin | Estää väärän datan commitoinnin — ilman tätä kaikki muu on hyödytöntä |
| G03 ennen G02:ta | Backward chaining tarvitsee oikeaa `need_extra_s`:ää |
| G11 ennen G02:ta | Trimmaus muuttaa slottien kokoa → vaikuttaa fit-tuloksiin |
| Stage 0 continue-semantiikka (G04) | JS:n `continue` on ytimekäs eikä lisää kierroksia turhaan |
| Overlap-flag domain laajennetaan `0..200` | Lukitaan sama domain kuin JS:ssä (täysi pariteetti) |
| DEP_DELAY_ACTION_T uudelleenkäyttö chain-delayille | Sama struct kuin yksittäisille delay actiomeille — yhtenäinen käsittely |

**Rajaus:** Tässä suunnitelmassa ei jätetä tietoisia "riittää käytännössä" -poikkeamia. Jos jokin JS-käytös jätetään toteuttamatta, se kirjataan eksplisiittiseksi poikkeamaksi ja käsitellään erillisenä päätöksenä.
