# ST-koodin pariteettipäivitykset — Muutossuunnitelma

**Projekti:** OpenPLC Simulator — PLC Structured Text  
**Päivitetty:** 2026-02-28  
**Referenssi:** `PLC Simulator/sim-core/transporterTaskScheduler.js` (5053 riviä, 51 funktiota)  
**Kohde:** `openplc/OpenPLC/src/TSK_FB_*.st` + `STC_FB_*.st`

---

## Yhteenveto

Tavoite on **täysi toiminnallinen pariteetti** JS-referenssiin: ST:n tulee tuottaa samat päätökset, konfliktitulkinnat ja ajastuskäyttäytyminen samoilla syötteillä. Toteutuksessa ei käytetä kevennettyjä vaihtoehtoja niissä kohdissa, joissa JS:ssä on tarkempi logiikka.

Pariteettiraportissa tunnistettiin 6 puuttuvaa/vajaata ominaisuutta kolmella prioriteettitasolla:

| # | Prioriteetti | Muutos | Kohdetiedosto(t) | Arvio |
|---|-------------|--------|-------------------|-------|
| 1 | Perusta | TSK_LOCK_T struct | `types.st` | ~10 riviä |
| 2 | P1-A | Cross-transporter handoff -tarkistus | `TSK_FB_Analyze.st` | ~40 riviä |
| 3 | P1-B | Parallel station selection | `TSK_FB_CalcSchedule.st` | ~60 riviä |
| 4 | P2-A | LockedStages + Chain-flex resolve | `TSK_FB_Resolve.st` + `TSK_FB_Scheduler.st` | ~65 riviä |
| 5 | P2-B | NoTreatment idle-slot overlap | `TSK_FB_NoTreatment.st` | ~30 riviä |
| 6 | P3 | Analyze-järjestyssematiikka | `TSK_FB_Analyze.st` | ~160 riviä (rewrite) |

**Toteutusjärjestys:** Vaihe 1 → 6 → 2 → 3 → 4 → 5  
(P3+P1-A samaan tiedostoon yhdellä uudelleenkirjoituksella, sitten P1-B, P2-A, P2-B)

### Pariteetin hyväksymiskriteerit (Definition of Done)

Muutos hyväksytään vasta, kun kaikki ehdot täyttyvät:

1. Jokaiselle tunnistetulle gapille on toteutettu vastaava ST-logiikka ilman tarkoituksellista supistusta.
2. Vähintään 10 ennalta määritettyä regressioskenaariota (handoff, parallel, chain-flex, NTT idle-slot, SWAP-order) ajetaan sekä JS- että ST-ajossa ja tulokset täsmäävät.
3. Konfliktityyppi, kohde-stage, deficit ja resolve-suunnan valinta täsmäävät skenaarioittain.
4. Build + deploy onnistuu ilman uusia PLC-käännösvirheitä.
5. Poikkeamat dokumentoidaan, mutta niitä ei jätetä avoimeksi tässä kokonaisuudessa.

---

## Vaihe 1: Tyyppilisäykset

**Tiedosto:** `openplc/OpenPLC/src/types.st`

### Lisättävä: TSK_LOCK_T

Lukitustaulukko estää oskillaatiota resolve-kierroksilla. Kun stage on aikaistettu (ADVANCE), resolve ei saa viivästää samaa stagea saman scheduler-syklin aikana — ja päinvastoin.

```iecst
TYPE TSK_LOCK_T :
STRUCT
  unit      : INT;     (* erä-unit-indeksi, 0 = tyhjä *)
  stage     : INT;     (* ohjelmavaihe *)
  direction : INT;     (* 1=ADVANCE, 2=DELAY *)
END_STRUCT;
END_TYPE
```

**JS-referenssi:** `lockedStages` -objekti `resolveConflict()`:ssa (rivi 1641):
```javascript
const lockedStages = options.lockedStages || {};
// ...
lockedStages[conflictStageKey] === 'DELAY'  // estää ADVANCE
lockedStages[walkKey] === 'ADVANCE'         // estää DELAY
```

### Valinnainen: TSK_CHECKED_T laajennus

Lisää `conf_type : INT` kenttä olemassaolevaan `TSK_CHECKED_T` structiin:
- `1` = TASK_SEQUENCE
- `2` = TRANSPORTER_COLLISION  
- `3` = CROSS_TRANSPORTER_HANDOFF

Helpottaa Modbus-debug-vientiä ja gateway-lokitusta.

---

## Vaihe 2 (P1-A): Cross-transporter handoff conflict check

**Tiedosto:** `openplc/OpenPLC/src/TSK_FB_Analyze.st`  
**JS-referenssi:** `transporterTaskScheduler.js` rivit 1075–1200 — "5b. CROSS_TRANSPORTER_HANDOFF"

### Tausta

Kun erä ylittää nostin-rajan (esim. T1 vie asemalle 110, T2 hakee asemalta 110), tarvitaan handoff-tarkistus: ehtiikö vastaanottava nostin (T2) siirtyä edelliseltä tehtävältään handoff-asemalle ennen kuin toimittava nostin (T1) on laskenut erän sinne?

Jos T2 ei ehdi → konflikti kohdistuu T1:n delivery-taskiin → resolver viivästää edellistä stagea → erä odottaa T1:n alueella pidempään.

### Nykyinen puute

ST:n `TSK_FB_Analyze` tarkistaa vain:
1. **TASK_SEQUENCE** — saman nostimen peräkkäiset tehtävät
2. **TRANSPORTER_COLLISION** — eri nostimien X+aika-overlap

Puuttuu kokonaan: **CROSS_TRANSPORTER_HANDOFF** — eri nostimien sama-erä-peräkkäiset staget.

### Muutoksen logiikka

Lisätään kolmas tarkistus Step 2 -silmukkaan, TRANSPORTER_COLLISION-tarkistuksen JÄLKEEN (nykyinen rivi ~165):

```
(* ─── Check CROSS_TRANSPORTER_HANDOFF: same batch, next stage, different transporter ─── *)
(* Find next stage of same batch in sorted[] *)
next_idx := 0;
FOR ni := 1 TO sorted_cnt DO
  IF sorted[ni].unit = sorted[si].unit
     AND sorted[ni].stage = sorted[si].stage + 1
     AND sorted_trans[ni] <> sorted_trans[si] THEN
    next_idx := ni;
    EXIT;
  END_IF;
END_FOR;

IF next_idx > 0 THEN
  (* Handoff: T_current delivers to sink, T_receiver picks up from there *)
  (* Find receiver's previous task — latest task before next_idx's start_time *)
  recv_prev_idx := 0;
  FOR ri := si - 1 TO 1 BY -1 DO
    IF sorted_trans[ri] = sorted_trans[next_idx]
       AND sorted[ri].finish_time <= sorted[next_idx].start_time THEN
      recv_prev_idx := ri;
      EXIT;
    END_IF;
  END_FOR;

  IF recv_prev_idx > 0 THEN
    (* Calculate receiver travel: prev.sink → current.sink (handoff station) *)
    fb_travel(
      i_from_stn := sorted[recv_prev_idx].sink_station,
      i_to_stn   := sorted[si].sink_station,
      i_trans    := sorted_trans[next_idx]
    );
    recv_travel := fb_travel.o_travel_s;
    recv_earliest := sorted[recv_prev_idx].finish_time + REAL_TO_LINT(recv_travel);
    handoff_deficit := LINT_TO_REAL(recv_earliest - sorted[si].finish_time);

    IF handoff_deficit > DEFICIT_TOL THEN
      o_has_conflict  := TRUE;
      o_conf_type     := 3;  (* CROSS_TRANSPORTER_HANDOFF *)
      o_conf_unit     := sorted[si].unit;
      o_conf_stage    := sorted[si].stage;
      o_conf_trans    := sorted_trans[si];
      o_blocked_unit  := sorted[recv_prev_idx].unit;
      o_blocked_stage := sorted[recv_prev_idx].stage;
      o_deficit       := handoff_deficit;
      IF chk_cnt <= 30 THEN
        chk[chk_cnt].is_conflict := TRUE;
      END_IF;
      checked_count := chk_cnt;
      RETURN;
    END_IF;
  END_IF;
END_IF;
```

### Uudet muuttujat (VAR-lohkoon)

```iecst
next_idx       : INT;     (* same batch next stage index in sorted[] *)
recv_prev_idx  : INT;     (* receiver's previous task index *)
recv_travel    : REAL;    (* receiver travel time to handoff station *)
recv_earliest  : LINT;    (* receiver earliest arrival at handoff *)
handoff_deficit : REAL;   (* deficit (s) *)
ni             : INT;     (* next search loop *)
ri             : INT;     (* receiver prev search loop *)
```

---

## Vaihe 3 (P1-B): Parallel station selection

**Tiedosto:** `openplc/OpenPLC/src/TSK_FB_CalcSchedule.st`  
**JS-referenssi:** `transporterTaskScheduler.js` rivit 105–235 — `selectBestParallelStation()`

### Tausta

Kun ohjelman stagella on useita rinnakkaisasemia (esim. 3 upotusallasta), scheduler valitsee mihin erä menee. JS käyttää kaksivaiheista heuristiikkaa:

1. **Aikataulupäällekkäisyys** — tarkista muiden erien aikatauluista, occupoiko joku toinen erä aseman samaan aikaan
2. **Idle-since** — vapaista asemista valitse se joka on ollut pisimpään tyhjänä (tasaa kulumista)

### Nykyinen puute

ST:n `TSK_FB_CalcSchedule` käyttää yksinkertaista "ensimmäinen löytyvä" -logiikkaa:

```iecst
(* Nykytila — rivit 116-122 *)
chosen_stn := 0;
FOR p := 1 TO 5 DO
  IF g_program[i_unit].stages[st].stations[p] > 0 AND chosen_stn = 0 THEN
    chosen_stn := g_program[i_unit].stages[st].stations[p];
  END_IF;
END_FOR;
```

Tämä johtaa siihen, että kaikki erät kasaantuvat aina ensimmäiseen rinnakkaisasemaan.

### Uusi logiikka

Korvaa yllä oleva blokki (7 riviä → ~60 riviä):

```
(* ── Parallel station selection: schedule-aware + idle-since ── *)

(* Step A: Collect all candidate stations *)
cand_cnt := 0;
FOR p := 1 TO MAX_PARALLELS DO
  IF g_program[i_unit].stages[st].stations[p] > 0 THEN
    cand_cnt := cand_cnt + 1;
    cand_arr[cand_cnt] := g_program[i_unit].stages[st].stations[p];
    sched_occupied[cand_cnt] := FALSE;
    phys_occupied[cand_cnt] := FALSE;
  END_IF;
END_FOR;

IF cand_cnt <= 1 THEN
  (* 0 or 1 candidate — no choice *)
  IF cand_cnt = 1 THEN
    chosen_stn := cand_arr[1];
  ELSE
    chosen_stn := 0;
  END_IF;

ELSE
  (* Step B: Calculate THIS stage's time window (estimate) *)
  (* my_entry ≈ exit_t + xfer_t (from previous stage), my_exit ≈ my_entry + calc_s *)
  (* These are computed incrementally in the main loop — use current values *)
  my_entry := exit_t + REAL_TO_LINT(xfer_t);
  my_exit  := my_entry + REAL_TO_LINT(calc_s);

  (* Step C: Check schedule overlap for each candidate *)
  FOR p := 1 TO cand_cnt DO
    FOR uj := 1 TO MAX_UNITS DO
      IF uj <> i_unit AND g_schedule[uj].stage_count > 0 THEN
        FOR sj := 1 TO g_schedule[uj].stage_count DO
          IF g_schedule[uj].stages[sj].station = cand_arr[p] THEN
            (* Time overlap check *)
            ov_start := my_entry;
            IF g_schedule[uj].stages[sj].entry_time > ov_start THEN
              ov_start := g_schedule[uj].stages[sj].entry_time;
            END_IF;
            ov_end := my_exit;
            IF g_schedule[uj].stages[sj].exit_time < ov_end THEN
              ov_end := g_schedule[uj].stages[sj].exit_time;
            END_IF;
            IF ov_end > ov_start THEN
              sched_occupied[p] := TRUE;
            END_IF;
          END_IF;
        END_FOR;
      END_IF;
    END_FOR;

    (* Step D: Check physical occupation *)
    FOR uj := 1 TO MAX_UNITS DO
      IF g_unit[uj].location = cand_arr[p] AND g_unit[uj].status = 1 THEN
        phys_occupied[p] := TRUE;
      END_IF;
    END_FOR;
  END_FOR;

  (* Step E: Select best free station (longest idle = smallest change_time) *)
  chosen_stn := 0;
  best_change_time := LINT#9999999999;
  FOR p := 1 TO cand_cnt DO
    IF NOT sched_occupied[p] AND NOT phys_occupied[p] THEN
      IF cand_arr[p] >= STATION_ARRAY_START AND cand_arr[p] <= STATION_ARRAY_END THEN
        IF g_station[cand_arr[p]].change_time < best_change_time THEN
          best_change_time := g_station[cand_arr[p]].change_time;
          chosen_stn := cand_arr[p];
        END_IF;
      END_IF;
    END_IF;
  END_FOR;

  (* Step F: Fallback — schedule-free only (physical may clear before arrival) *)
  IF chosen_stn = 0 THEN
    FOR p := 1 TO cand_cnt DO
      IF NOT sched_occupied[p] AND chosen_stn = 0 THEN
        chosen_stn := cand_arr[p];
      END_IF;
    END_FOR;
  END_IF;

  (* Step G: Ultimate fallback — first candidate *)
  IF chosen_stn = 0 THEN
    chosen_stn := cand_arr[1];
  END_IF;

END_IF;
```

### Uudet muuttujat (VAR-lohkoon)

```iecst
cand_arr         : ARRAY[1..5] OF INT;     (* candidate station numbers *)
cand_cnt         : INT;                     (* candidate count *)
sched_occupied   : ARRAY[1..5] OF BOOL;    (* schedule overlap flag per candidate *)
phys_occupied    : ARRAY[1..5] OF BOOL;    (* physical occupation flag per candidate *)
best_change_time : LINT;                    (* oldest change_time among free candidates *)
my_entry         : LINT;                    (* estimated entry time for this stage *)
my_exit          : LINT;                    (* estimated exit time for this stage *)
ov_start         : LINT;                    (* overlap calc temp *)
ov_end           : LINT;                    (* overlap calc temp *)
uj               : INT;                     (* unit loop for schedule/occupation check *)
sj               : INT;                     (* stage loop for schedule check *)
```

---

## Vaihe 4 (P2-A): LockedStages + Chain-flex resolve (täysi JS-vastaavuus)

**Tiedostot:**
- `openplc/OpenPLC/src/TSK_FB_Resolve.st`
- `openplc/OpenPLC/src/TSK_FB_Scheduler.st`

**JS-referenssi:**
- `transporterTaskScheduler.js` rivit 1638–1900 — `resolveConflict()` chain-flex
- `transporterTaskScheduler.js` rivit 3527–3580 — `calculateChainFlex()`

### Tausta

JS:n resolver käyttää kahta mekanismia joita ST:stä puuttuu:

1. **lockedStages** — Kun stage on aikaistettu, se "lukitaan" eikä sitä saa viivästää samalla scheduler-syklillä (ja päinvastoin). Estää oskillaation jossa resolver vuorotellen aikaistaa ja viivästää samaa stagea loputtomasti.

2. **Chain-flex** — Resolver hyödyntää ketjun joustoa usealla strategialla, ei vain yksinkertaisella paikallisella flexillä. Esimerkki:
   - B1s5 flex_down = 20s, B1s4 flex_down = 5s, B1s3 flex_down = 30s
   - Chain bottleneck = min(5, 30) = 5s (B1s4 rajoittaa)
   - Ketjuaikaistus = 5s × cap, sitten konflikti-stagen suffix = (20-5) × cap

### 4a: TSK_FB_Scheduler.st — Lukitustaulukon hallinta

Lisää VAR-lohkoon:
```iecst
(* Locked stages — prevents oscillation in resolve loop *)
locks           : ARRAY[1..50] OF TSK_LOCK_T;
lock_cnt        : INT := 0;
locks_initialized : BOOL := FALSE;
```

**Phase 1 (INIT):** Nollaa lippu:
```iecst
locks_initialized := FALSE;
```

**Phase 2200 (TASKS_SORT):** Alusta lukitukset vain kerran per scheduler-sykli:
```iecst
IF NOT locks_initialized THEN
  lock_cnt := 0;
  FOR bi := 1 TO 50 DO
    locks[bi].unit := 0;
    locks[bi].stage := 0;
    locks[bi].direction := 0;
  END_FOR;
  locks_initialized := TRUE;
END_IF;
```

**Phase 2203 (TASKS_RESOLVE):** Välitä lukitustaulukko:
```iecst
fb_resolve(
  i_conf_unit     := fb_analyze.o_conf_unit,
  i_conf_stage    := fb_analyze.o_conf_stage,
  i_conf_trans    := fb_analyze.o_conf_trans,
  i_blocked_unit  := fb_analyze.o_blocked_unit,
  i_blocked_stage := fb_analyze.o_blocked_stage,
  i_deficit       := fb_analyze.o_deficit,
  io_locks        := locks,
  io_lock_cnt     := lock_cnt
);
```

### 4b: TSK_FB_Resolve.st — Chain-flex + lukitustarkistukset

**Muutos 1:** Lisää VAR_IN_OUT:
```iecst
VAR_IN_OUT
  io_locks    : ARRAY[1..50] OF TSK_LOCK_T;
  io_lock_cnt : INT;
END_VAR
```

**Muutos 2:** Helper — lock check -funktio (inline, koska FUNCTION ei saa käyttää globaaleja):
```iecst
(* Check if unit+stage is locked in opposite direction *)
(* Returns TRUE if action is blocked *)
is_locked := FALSE;
lock_key_unit := <unit>;
lock_key_stage := <stage>;
lock_check_dir := <1=ADVANCE, 2=DELAY>;
FOR lock_i := 1 TO io_lock_cnt DO
  IF io_locks[lock_i].unit = lock_key_unit
     AND io_locks[lock_i].stage = lock_key_stage
     AND io_locks[lock_i].direction = lock_check_dir THEN
    is_locked := TRUE;
  END_IF;
END_FOR;
```

**Muutos 3:** Phase 1 (ADVANCE prev) — Chain-flex:

Korvaa nykyinen suora `prev_flex` laskenta:

```iecst
(* ── Phase 1: ADVANCE prev — Chain-flex bottleneck ── *)

(* Get conflict stage's own flex_down *)
conflict_flex_down := 0.0;
IF i_blocked_stage >= 1 AND i_blocked_stage <= 30 THEN
  conflict_flex_down := g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time
                      - g_schedule[i_blocked_unit].stages[i_blocked_stage].min_time;
  IF conflict_flex_down < 0.0 THEN conflict_flex_down := 0.0; END_IF;
END_IF;

(* Lock check: if blocked stage is locked DELAY, skip ADVANCE *)
is_locked := FALSE;
FOR lock_i := 1 TO io_lock_cnt DO
  IF io_locks[lock_i].unit = i_blocked_unit
     AND io_locks[lock_i].stage = i_blocked_stage
     AND io_locks[lock_i].direction = 2 THEN  (* 2=DELAY *)
    is_locked := TRUE;
  END_IF;
END_FOR;

IF NOT is_locked AND conflict_flex_down > 0.1 THEN

  (* Find chain bottleneck: smallest non-zero flex_down < conflict_flex_down *)
  chain_flex := 0.0;
  chain_min := conflict_flex_down;  (* starts at own flex *)
  sc := g_schedule[i_blocked_unit].stage_count;
  FOR si := 1 TO i_blocked_stage - 1 DO
    IF si >= 1 AND si <= sc THEN
      stage_fd := g_schedule[i_blocked_unit].stages[si].calc_time
                - g_schedule[i_blocked_unit].stages[si].min_time;
      IF stage_fd > 0.0 AND stage_fd < chain_min THEN
        chain_min := stage_fd;
      END_IF;
    END_IF;
  END_FOR;
  IF chain_min < conflict_flex_down THEN
    chain_flex := chain_min;
  END_IF;

  (* Cap factor: 90% if batch is on this stage, 50% otherwise *)
  IF g_batch[i_blocked_unit].cur_stage = i_blocked_stage THEN
    cap := 0.9;
  ELSE
    cap := 0.5;
  END_IF;

  (* Apply chain advance *)
  IF chain_flex > 0.0 THEN
    amount := chain_flex * cap;
    IF amount > remain THEN amount := remain; END_IF;
    g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time :=
      g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time - amount;
    g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time :=
      g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time - REAL_TO_LINT(amount);
    fb_shift(i_unit := i_blocked_unit, i_from_stage := i_blocked_stage + 1, i_amount := -amount);
    remain := remain - amount;
    o_total_adv := o_total_adv + amount;
  END_IF;

  (* Apply suffix advance (own flex minus chain) *)
  IF remain > 0.1 AND conflict_flex_down > chain_flex THEN
    suffix_flex := (conflict_flex_down - chain_flex) * cap;
    IF suffix_flex > remain THEN suffix_flex := remain; END_IF;
    g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time :=
      g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time - suffix_flex;
    g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time :=
      g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time - REAL_TO_LINT(suffix_flex);
    fb_shift(i_unit := i_blocked_unit, i_from_stage := i_blocked_stage + 1, i_amount := -suffix_flex);
    remain := remain - suffix_flex;
    o_total_adv := o_total_adv + suffix_flex;
  END_IF;

  (* Record lock: ADVANCE on blocked stage *)
  IF io_lock_cnt < 50 THEN
    io_lock_cnt := io_lock_cnt + 1;
    io_locks[io_lock_cnt].unit := i_blocked_unit;
    io_locks[io_lock_cnt].stage := i_blocked_stage;
    io_locks[io_lock_cnt].direction := 1;  (* 1=ADVANCE *)
  END_IF;

END_IF;
```

**Muutos 3.1 (täysi pariteetti):** Lisää JS:n chain-flex-strategioiden vastaavuus ST:hen:
- `CHAIN_BACKWARD`: pullonkaula edeltävistä stageista
- `CHAIN_FORWARD`: vaikutus myös eteenpäin silloin kun aikataulu sallii
- `CHAIN_COMBINED`: priorisoitu yhdistelmä yllä olevista, kuten JS-resolverissa

Tämä tarkoittaa, että resolve-vaiheen päätöspolku vastaa JS:n valintajärjestystä eikä pysähdy pelkkään backward-supistettuun malliin.

**Muutos 4:** Vastaavat lock-tarkistukset Phase 2, 3, 4:lle:
- Phase 2 (DELAY next conf_stage): Tarkista `direction=1 (ADVANCE)` → ohita DELAY
- Phase 3 (DELAY next prev stage): Tarkista `direction=1 (ADVANCE)` → ohita DELAY
- Phase 4 (DELAY prev past next): Tarkista `direction=1 (ADVANCE)` → ohita DELAY
- Jokaisen onnistuneen DELAY:n jälkeen: tallenna lock `direction=2`

### Uudet muuttujat (TSK_FB_Resolve VAR-lohkoon)

```iecst
conflict_flex_down : REAL;
chain_flex         : REAL;
chain_min          : REAL;
suffix_flex        : REAL;
stage_fd           : REAL;
lock_key_unit      : INT;
lock_key_stage     : INT;
lock_check_dir     : INT;
```

---

## Vaihe 5 (P2-B): NoTreatment idle-slot sovitus (täysi JS-vastaavuus)

**Tiedosto:** `openplc/OpenPLC/src/TSK_FB_NoTreatment.st`  
**JS-referenssi:** `calculateTransporterIdleSlots()` + `fitBatchToIdleSlots()`

### Tausta

Nykyinen NoTreatment luo siirtotehtävän kunhan nostin on idle (phase=0) ja kohdeasema vapaa. Se EI laske nostinkohtaisia vapaita aikavälejä eikä sovita NTT-taskia niihin JS:n tapaan.

Ongelma: NTT-taski voi ajastua väärään kohtaan jonossa, vaikka yksittäinen overlap-tarkistus menisi läpi.

### Muutoksen logiikka

Toteutetaan JS:n mukainen kaksivaiheinen prosessi:

1. **Laske idle-slotit nostinkohtaisesti** olemassa olevasta `g_task[cov_t].queue[]`-jonosta:
  - muodostetaan aikavälit tehtävien väleistä
  - huomioidaan nykyhetki, jonon alku ja loppu
  - slotit sisältävät myös siirtymämarginaalit

2. **Sovita NTT-taski idle-slotiin**:
  - arvioidaan koko NTT-kesto (nosto + ajo + lasku + tarvittavat marginaalit)
  - valitaan ensimmäinen/paras slot joka täyttää ehdot
  - jos sopivaa slottia ei löydy, NTT jätetään luomatta tällä kierroksella

Alla oleva overlap-tarkistus toimii minimisuojana, mutta ei yksin riitä pariteettiin:

```iecst
(* ── Overlap check: does NTT task conflict with existing queue? ── *)
has_overlap := FALSE;
ntt_start := i_time_s;
fb_xfer(i_from_stn := loc, i_to_stn := dest_stn, i_trans := cov_t);
xfer_s := fb_xfer.o_total_s;
ntt_end := ntt_start + REAL_TO_LINT(xfer_s);

FOR qi := 1 TO g_task[cov_t].count DO
  IF NOT has_overlap THEN
    (* Time overlap check *)
    ov_s := ntt_start;
    IF g_task[cov_t].queue[qi].start_time > ov_s THEN
      ov_s := g_task[cov_t].queue[qi].start_time;
    END_IF;
    ov_e := ntt_end;
    IF g_task[cov_t].queue[qi].finish_time < ov_e THEN
      ov_e := g_task[cov_t].queue[qi].finish_time;
    END_IF;
    IF ov_e > ov_s THEN
      has_overlap := TRUE;
    END_IF;

    (* Transition margin check: NTT ends before queue task starts *)
    IF NOT has_overlap AND ntt_end <= g_task[cov_t].queue[qi].start_time THEN
      (* Check travel from NTT sink to queue task's lift station *)
      fb_ntt_margin(
        i_from_stn := dest_stn,
        i_to_stn   := g_task[cov_t].queue[qi].lift_station,
        i_trans    := cov_t
      );
      margin_travel := fb_ntt_margin.o_travel_s;
      IF LINT_TO_REAL(g_task[cov_t].queue[qi].start_time - ntt_end) < margin_travel THEN
        has_overlap := TRUE;
      END_IF;
    END_IF;
  END_IF;
END_FOR;

IF has_overlap THEN
  (* Skip this transporter — NTT task would conflict *)
  dest_stn := 0;
END_IF;
```

Lisäksi lisätään slot-laskennan vaatimat taulukot (esim. `idle_slots[]`) ja valintalogiikka ennen varsinaista enqueue-vaihetta.

### Uudet muuttujat (VAR-lohkoon)

```iecst
has_overlap    : BOOL;
ntt_start      : LINT;
ntt_end        : LINT;
ov_s           : LINT;
ov_e           : LINT;
margin_travel  : REAL;
fb_ntt_margin  : STC_FB_CalcHorizontalTravel;
```

**Lisättävät muuttujat täyteen slot-sovitukseen:**

```iecst
idle_slot_start : ARRAY[1..20] OF LINT;
idle_slot_end   : ARRAY[1..20] OF LINT;
idle_slot_count : INT;
fit_slot_idx    : INT;
required_start  : LINT;
required_end    : LINT;
```

---

## Vaihe 6 (P3): Analyze-järjestyssematiikka

**Tiedosto:** `openplc/OpenPLC/src/TSK_FB_Analyze.st`  
**JS-referenssi:** `transporterTaskScheduler.js` rivit 838–850 — "EI SAA järjestää uudelleen"

### Tausta

JS:n SWAP (phase 6003) järjestää tehtävät oikein (nosto ennen laskua) per nostin. Analyze:n kommentti sanoo eksplisiittisesti:

> "EI SAA järjestää uudelleen task_start_time mukaan - se kumoaisi SWAP:n."

Mutta ST:n `TSK_FB_Analyze` yhdistää KAIKKI jonot yhdeksi `sorted[]`-listaksi start_time insertion sortilla → SWAP:n tuottama per-nostin-järjestys katoaa.

### Uusi lähestymistapa

Uudelleenkirjoitetaan Analyze niin, että TASK_SEQUENCE-tarkistus käyttää per-nostin **jonojärjestystä** (ei globaalia sorted[]):

```
(* ═══ TASK_SEQUENCE: Check per-transporter queues (preserves SWAP order) ═══ *)
FOR ti := 1 TO MAX_TRANSPORTERS DO
  FOR qi := 1 TO g_task[ti].count - 1 DO
    IF g_task[ti].queue[qi].unit > 0 AND g_task[ti].queue[qi + 1].unit > 0 THEN

      prev_sink := g_task[ti].queue[qi].sink_station;
      next_lift := g_task[ti].queue[qi + 1].lift_station;

      fb_travel(i_from_stn := prev_sink, i_to_stn := next_lift, i_trans := ti);
      travel_s := fb_travel.o_travel_s;

      gap_s := LINT_TO_REAL(
        g_task[ti].queue[qi + 1].start_time - g_task[ti].queue[qi].finish_time
      );
      deficit_s := travel_s - gap_s;

      IF deficit_s > DEFICIT_TOL THEN
        o_has_conflict  := TRUE;
        o_conf_type     := 1;  (* TASK_SEQUENCE *)
        o_conf_unit     := g_task[ti].queue[qi + 1].unit;
        o_conf_stage    := g_task[ti].queue[qi + 1].stage;
        o_conf_trans    := ti;
        o_blocked_unit  := g_task[ti].queue[qi].unit;
        o_blocked_stage := g_task[ti].queue[qi].stage;
        o_deficit       := deficit_s;
        RETURN;
      END_IF;

    END_IF;
  END_FOR;
END_FOR;
```

TRANSPORTER_COLLISION ja CROSS_TRANSPORTER_HANDOFF iteroidaan erikseen (tarvitsevat eri nostimien tehtävien vertailua):

```
(* ═══ TRANSPORTER_COLLISION: X+time overlap between different transporters ═══ *)
FOR ti := 1 TO MAX_TRANSPORTERS DO
  FOR qi := 1 TO g_task[ti].count DO
    IF g_task[ti].queue[qi].unit > 0 THEN
      (* Get X range for this task *)
      ... (sama X-logiikka kuin nykyisessä, mutta suoraan g_task:sta)

      FOR tj := ti + 1 TO MAX_TRANSPORTERS DO
        FOR qj := 1 TO g_task[tj].count DO
          IF g_task[tj].queue[qj].unit > 0 THEN
            ... (X overlap + time overlap tarkistus)
          END_IF;
        END_FOR;
      END_FOR;
    END_IF;
  END_FOR;
END_FOR;
```

```
(* ═══ CROSS_TRANSPORTER_HANDOFF: same batch, consecutive stages, different transporter ═══ *)
(* Iterate all tasks; for each, find next stage of same batch in different transporter *)
FOR ti := 1 TO MAX_TRANSPORTERS DO
  FOR qi := 1 TO g_task[ti].count DO
    cur_unit  := g_task[ti].queue[qi].unit;
    cur_stage := g_task[ti].queue[qi].stage;
    IF cur_unit > 0 THEN
      (* Find next stage in any other transporter *)
      FOR tj := 1 TO MAX_TRANSPORTERS DO
        IF tj <> ti THEN
          FOR qj := 1 TO g_task[tj].count DO
            IF g_task[tj].queue[qj].unit = cur_unit
               AND g_task[tj].queue[qj].stage = cur_stage + 1 THEN
              (* Found handoff pair: ti delivers, tj picks up *)
              ... (receiver prev task lookup + deficit calc — same as Vaihe 2)
            END_IF;
          END_FOR;
        END_IF;
      END_FOR;
    END_IF;
  END_FOR;
END_FOR;
```

### Vaikutus

- `sorted[]` ja `sorted_trans[]` -taulukot POISTUVAT kokonaan → yksinkertaisempi muistinkäyttö
- Kukin tarkistustyyppi on oma selkeä lohkonsa → helpompi debugata
- SWAP-järjestys säilyy TASK_SEQUENCE-tarkistuksessa
- `chk[]` / `checked_count` säilytetään jos tarvitaan debug-Modbusta varten — vaihtoehtoisesti poistetaan ja yksinkertaistetaan

### Arvio

~160 riviä uutta koodia (korvaa nykyiset ~180 riviä). Nettovaikutus: lähes sama rivimäärä mutta rakenteellisesti selkeämpi.

---

## Toteutusjärjestys ja riippuvuudet

```
Vaihe 1: types.st (TSK_LOCK_T)
    │
    ├── Vaihe 6+2: TSK_FB_Analyze.st (uudelleenkirjoitus: P3 + P1-A)
    │       ↑ ei riippuvuuksia types.st:hen
    │
    ├── Vaihe 3: TSK_FB_CalcSchedule.st (P1-B)
    │       ↑ ei riippuvuuksia muihin muutoksiin
    │
    ├── Vaihe 4: TSK_FB_Resolve.st + TSK_FB_Scheduler.st (P2-A)
    │       ↑ riippuu TSK_LOCK_T:stä (Vaihe 1)
    │
    └── Vaihe 5: TSK_FB_NoTreatment.st (P2-B)
            ↑ ei riippuvuuksia muihin muutoksiin
```

**Suositeltava järjestys:**
1. Vaihe 1 (types.st) — edellytys Vaihe 4:lle
2. Vaihe 6+2 (Analyze rewrite) — suurin yksittäinen muutos, tehdään yhtenä uudelleenkirjoituksena
3. Vaihe 3 (CalcSchedule) — itsenäinen
4. Vaihe 4 (Resolve + Scheduler) — hyödyntää Vaihe 1:n tyyppejä
5. Vaihe 5 (NoTreatment) — itsenäinen

Jokaisen vaiheen jälkeen: `python3 build_plcxml.py` + `bash deploy_plc.sh` + testaus.

Lisäksi vaiheen 4 ja 5 jälkeen ajetaan parity-regressio JS-vertailua vasten.

---

## Verifiointisuunnitelma

### Build & Deploy

```bash
cd openplc/OpenPLC && python3 build_plcxml.py
bash deploy_plc.sh "Nammo Lapua Oy" "Factory X Zinc Phosphating"
docker compose up -d
```

### Testitapaukset

| # | Muutos | Testitapaus | Odotettu tulos |
|---|--------|-------------|----------------|
| 1 | P1-A Handoff | 2+ erää jotka ylittävät nostin-rajat | Nostin ei saa tehtäviä joita vastaanottaja ei ehdi hakea |
| 2 | P1-B Parallel | Ohjelma jossa 2-3 rinnakkaisallasta | Erät jakautuvat tasaisesti, eivät kasaannu yhteen |
| 3 | P2-A Locks | 3+ erää linjalla, ristiriitaiset aikataulut | Ei oskillaatiota resolve-silmukassa (cycle count < MAX_CONFLICT_ITER) |
| 4 | P2-B NTT | NTT-siirto + tiheä task-jono samalla nostimella | NTT sijoittuu vain validiin idle-slottiin tai jätetään tekemättä |
| 5 | P3 Order | SWAP-tilanne: prev.sink == next.lift | Analyze löytää oikean konfliktin swapatun järjestyksen perusteella |
| 6 | Chain-flex mode | Sama konflikti kolmella resolve-polulla | ST valitsee saman chain-strategian kuin JS |
| 7 | E2E parity | Sama syöteajon snapshot JS vs ST | konfliktit, deficitit ja stage-aikasiirrot täsmäävät |

### Logitus

```bash
# Gateway lokit
docker logs plc_gateway --tail 100

# PLC status
curl -s http://localhost:8080/dashboard | grep -oi "Running\|Stopped"

# Scheduler phase
curl -s http://localhost:3001/api/status | jq '.plc'
```

---

## Päätökset ja rajaukset

| Päätös | Perustelu |
|--------|-----------|
| Lukitustaulukko TSK_FB_Scheduler:n VAR:ssa (ei globaali) | Parempi kapselointi, vain TSK tarvitsee |
| P3 + P1-A yhtenä uudelleenkirjoituksena | Molemmat muuttavat samaa tiedostoa → yksi muutos |
| NTT toteutetaan full idle-slot -mallilla | Tavoite on 100 % JS-funktionaalinen vastaavuus |
| Chain-flex toteutetaan JS:n valintapolun mukaisesti | Tavoite on identtinen resolve-käytös konfliktitilanteissa |
| conf_type=3 (HANDOFF) lisätään myöhemmin Modbus-vientiin tarvittaessa | Ei blokkaa toimintaa |

**Rajaus:** tässä suunnitelmassa ei jätetä tietoisia “riittää käytännössä” -poikkeamia. Jos jokin JS-käytös jätetään toteuttamatta, se kirjataan eksplisiittiseksi poikkeamaksi ja käsitellään erillisenä päätöksenä.
