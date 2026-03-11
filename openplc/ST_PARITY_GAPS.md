# PLC (.st) vs JS (.js) — Toiminnalliset poikkeamat

Vertailupäivä: 2026-03-10  
Haara: `OpenPLC2TIA`  
JS-referenssi: `PLC Simulator/sim-core/` (17 543 riviä, 5 tiedostoa)  
PLC-toteutus: `openplc/OpenPLC/src/` (10 963 riviä, 39 tiedostoa)

---

## GAP-1: ✅ Task sort — emergency-priorisointi puuttuu *(TOTEUTETTU 2026-03-10)*

**JS** (`taskScheduler.js`, phase 2200 `_compareTasksPriority`):
```
Lajitteluvertailija:
1. Ryhmittely transporter_id:n mukaan
2. Lasketaan overtime ratio = elapsedS / maxTimeS
3. Jos ratio > 1.0 → EMERGENCY — korkein prioriteetti
4. Molemmat emergency → suurempi ratio ensin
5. Normaali: task_start_time nouseva
```

**ST** (`STC_FB_SortTaskQueue.st`):
```
Insertion sort pelkästään StartTime-kentällä, nouseva järjestys.
Ei overtime-tarkistusta, ei emergency-priorisointia.
```

**Vaikutus**: Jos erän max_time ylittyy asemalla, JS nostaa sen noston etusijalle muiden tehtävien ohi. PLC käsittelee kaikki tehtävät pelkän aikataulun mukaan — myöhässä oleva erä ei saa erityiskohtelua. Tämä voi johtaa max_time-ylityksiin, jotka JS välttää.

**Korjaus**: Lisätään `STC_FB_SortTaskQueue`:n komparaattoriin overtime ratio -laskenta: lue `g_batch[unit].StartTime` ja `g_batch[unit].MaxTime`, laske `(g_time_s - StartTime) / MaxTime`. Jos > 1.0, priorisoi korkeammalle.

---

## GAP-2: ✅ Conflict resolve ei päivitä g_program[].CalTime:a *(TOTEUTETTU 2026-03-10)*

**JS** (`taskScheduler.js`, phase 2900 `TASKS_SAVE` + phase 10001 `SAVE_STRETCHES`):
```
1. RESOLVE kerää resolveHistory[]-tauluun kaikki delay/advance-toimenpiteet
2. TASKS_SAVE kokoaa ne candidateStretches[]-listaksi
3. SAVE_STRETCHES iteroi stretches:
   - Lukee treatment-ohjelman vastaavan vaiheen
   - Päivittää calc_time: newCalcS = clamp(minS, oldCalcS + delayS, maxS)
   - Kirjoittaa takaisin ohjelmaan (CSV / muisti)
```

**ST** (`TSK_FB_Resolve.st` + `STC_FB_ShiftSchedule.st`):
```
1. Resolve kutsuu STC_FB_ShiftSchedule, joka päivittää:
   - g_schedule[unit].Stages[].EntryTime / ExitTime
   - g_task[trans].Queue[].StartTime / FinishTime
2. g_program[unit].Steps[].CalTime EI PÄIVITY
```

**Vaikutus**: Seuraavalla scheduler-syklillä `TSK_FB_CalcSchedule` lukee `g_program[].CalTime`-arvot ja laskee aikataulun alusta. Edellisen syklin resolve-muutokset katoavat, koska ne tallennettiin vain schedule- ja task-tauluihin jotka ylikirjoitetaan. Tämä voi aiheuttaa konfliktin toistumisen syklien välillä.

**Korjaus**: `TSK_FB_Resolve`:n tulee päivittää myös `g_program[i_conf_unit].Steps[stage-1].CalTime` delay-tapauksissa ja `g_program[i_blocked_unit].Steps[stage-1].CalTime` advance-tapauksissa. Clamp min/max-rajoihin.

---

## GAP-3: ✅ STC_FB_ShiftSchedule — ei past-clampausta *(TOTEUTETTU 2026-03-10)*

**JS** (`transporterTaskScheduler.js`, `propagateEarlierToBatch`):
```javascript
// Guard: If newStartTime < currentTimeSec + 1 → clamp
if (newStartTime < currentTimeSec + 1) {
  actualEarlier = Math.max(0, task.task_start_time - (currentTimeSec + 1));
  task.task_start_time = currentTimeSec + 1;
  task.task_finished_time = task.task_start_time + taskDuration;
}
```

**ST** (`STC_FB_ShiftSchedule.st`):
```
(* Shift matching tasks *)
FOR ti := 1 TO MAX_Transporters DO
  FOR qi := 1 TO g_task[ti].Count DO
    IF Queue[qi].Unit = i_unit AND Queue[qi].Stage >= i_from_stage THEN
      Queue[qi].StartTime  := Queue[qi].StartTime  + REAL_TO_LINT(i_amount);
      Queue[qi].FinishTime := Queue[qi].FinishTime + REAL_TO_LINT(i_amount);
      (* ← Ei tarkistusta: StartTime voi mennä menneisyyteen *)
    END_IF;
```

**Vaikutus**: Advance-operaatio (negatiivinen shift) voi siirtää tehtävän `StartTime`:n nykyhetken taakse. Käytännössä harvinainen, mutta voi aiheuttaa dispatch-ongelman: `STC_FB_DispatchTask` arvioi `margin_s = StartTime - g_time_s`, joka menisi negatiiviseksi ja tehtävä dispatchattaisiin välittömästi.

**Korjaus**: Lisää `STC_FB_ShiftSchedule`:n advance-haaraan:
```
IF i_amount < 0.0 THEN
  IF Queue[qi].StartTime < g_time_s + 1 THEN
    Queue[qi].StartTime := g_time_s + 1;
  END_IF;
END_IF;
```

---

## GAP-4: ✅ DEP — in-flight tasks puuttuu idle-slot-laskennasta *(TOTEUTETTU 2026-03-10)*

**JS** (`departureScheduler.js`, phase 3001 `CHECK_CREATE_TASKS`):
```javascript
// Build in-flight tasks from transporter states
for (const t of ctx.transporterStates) {
  if (t.state.phase !== 0 && t.state.current_task_batch_id != null) {
    if (isFinite(t.state.est_finish_s) && t.state.est_finish_s > 0) {
      inFlightTasks.push({
        batch_id: t.state.current_task_batch_id,
        transporter_id: t.id,
        task_start_time: nowSec,
        task_finished_time: t.state.est_finish_s,
        isInFlight: true
      });
    }
  }
}
// Filter sandbox tasks — remove duplicates matching in-flight
filteredTasks = sandboxTasks.filter(t => !inFlightKeys.has(key(t)));
// combinedTasks = inFlightTasks + filteredSandboxTasks
```

**ST** (`DEP_FB_Scheduler.st`):
```
(* Phase 1030: EXTRACT_WAIT — extracts waiting batch tasks, keeps rest *)
(* No in-flight task construction from g_transporter[].Phase *)
(* Uses g_task[] directly, which still contains the original planned tasks *)
```

**Vaikutus**: Kun nostin eksekutoi tehtävää (phase 1–4), JS luo "in-flight" -pseudotehtävän, jonka `task_finished_time` on realistinen `est_finish_s`. ST käyttää alkuperäistä suunniteltua tehtävää jonosta. Jos suoritusaika poikkeaa suunnitellusta (esim. TWA-väistö viivästytti), idle-slotit lasketaan väärin ja departure voi yrittää sovittaa tehtävän liian pieneen aukkoon.

**Korjaus**: Lisää `DEP_FB_Scheduler`:n phase 1030:n (EXTRACT_WAIT) yhteyteen:
```
FOR ti := 1 TO MAX_Transporters DO
  IF g_transporter[ti].Phase > 0 AND g_task[ti].Count >= 1 THEN
    (* Päivitä ensimmäisen tehtävän FinishTime realistiseksi *)
    (* Käytä STC_CalcTransferTime:a jäljellä olevan matkan perusteella *)
    (* tai korvaa FinishTime = g_time_s + arvioitu jäljellä oleva aika *)
  END_IF;
END_FOR;
```

---

## GAP-5: ⚪ DEP — departure stretch -palautus TSK:lle puuttuu *(N/A — ei relevantti 2026-03-10)*

**JS** (`departureScheduler.js` CHECK_ANALYZE + `taskScheduler.js` TASKS_SAVE/SAVE_STRETCHES):
```
1. DEP CHECK_ANALYZE kirjaa delay-toimenpiteet: departureCandidateStretches[]
2. DEP ACTIVATE siirtää ne candidateStretches[]:iin
3. TSK TASKS_SAVE kopioi ne osaksi candidateStretches[]:a
4. TSK SAVE_STRETCHES päivittää g_program[].calc_time:t niiden perusteella
```

**ST**:
```
DEP_FB_Scheduler phase 8000 (ACTIVATE):
  - Kopioi g_program/g_schedule → g_dep_pending
  - TSK phase 10100 mergeää g_dep_pending → g_program/g_schedule
  - Mutta: DEP:n sovittamisen aikana tehdyt calc_time-MUUTOKSET ovat jo
    suoraan g_program[]:ssa (phase 3000 APPLY_DELAY kirjoittaa sinne)
  - Sandbox restore (phase 9000/8000) palauttaa alkuperäiset arvot
  → Netto: DEP:n delay-muutokset tallentuvat sandbox-kopioon,
    joka mergeätään TSK:lle g_dep_pending:n kautta
```

**Analyysi (2026-03-10)**: Tarkempi analyysi osoitti, että tämä GAP **ei toteudu ST:ssä**:

1. ST:n `APPLY_DELAY` (phase 3000) muokkaa **vain `cur_wait_unit`-erän** CalTime:a — ei muiden erien
2. JS:n `departureCandidateStretches` nollataan myös JS:ssä REJECT:ssa (`departureCandidateStretches = []`)
3. JS:n `candidateStretches` kerää muutoksia vain ACTIVATE:tuista eristä — sama kuin ST:n `g_dep_pending`-mekanismi
4. ST:n DEP ei kutsu `TSK_FB_Resolve`-tyyppistä ketjuvenytystä muille erille sovituksen aikana

**Tulos**: Alkuperäinen huoli ("muiden erien calc_time-muutokset katoavat reject:ssa") ei toteudu, koska ST:n DEP ei muokkaa muiden erien ohjelmia. Ei vaadi koodimuutoksia.

---

## GAP-6: ⚪ NTT — station free -tarkistus ei huomioi task-jonoja eikä nostimen headingiä *(N/A — ei relevantti 2026-03-10)*

**JS** (`taskScheduler.js`, phase 2204 `_isStationFree`):
```javascript
function _isStationFree(sid, unitStation, isLocationOccupied, transporterStates, tasks, taskCount) {
  if (sid === unitStation) return false;          // sama asema
  if (isLocationOccupied(sid)) return false;      // fyysisesti varattu
  // Nostin matkalla sinne?
  for (const ts of transporterStates) {
    if (ts.state.phase >= 1 && ts.state.phase <= 4 &&
        ts.state.sink_station_target === sid) return false;
  }
  // Task-jonossa sink?
  for (let i = 0; i < taskCount; i++) {
    if (tasks[i].sink_station_id === sid) return false;
  }
  return true;
}
```

**ST** (`TSK_FB_NoTreatment.st`, destination selection):
```
(* Check if station is free: only physical occupancy *)
FOR uj := 1 TO MAX_Units DO
  IF g_unit[uj].location = dest_stn AND g_unit[uj].Status = 1 THEN
    dest_free := FALSE;
    EXIT;
  END_IF;
END_FOR;
```

**Analyysi (2026-03-10)**: Tarkempi analyysi osoitti, että lisätarkistuksia **ei tarvita**:

1. **Uniikki target per unit** — järjestelmässä vain yksi yksikkö voi olla samalla targetilla kerrallaan. Duplikaattivaraus estetään target-asetuksen tasolla, ei NTT:ssä.
2. **Nostin idle-tarkistus** — NTT vaatii `g_transporter[cov_t].Phase = 0` (paitsi TO_AVOID). Kun nostin on idle, se ei ole matkalla mihinkään → transporter heading -tarkistus on turha.
3. **Ensimmäinen slotti** — NTT sovitetaan vain nykyiseen idle-slottiin (now → queue[1].StartTime), ajoitus validoidaan jo. Ei yritetä sovittaa tuleviin slotteihin.
4. **Asemajoukkojen erottelu** — NTT-kohteet ovat buffer/loading/unloading-asemia, batch-tehtävät käsittelyasemia → eri asemajoukot.

**Tulos**: Ei vaadi koodimuutoksia.

---

## GAP-7: ✅ Dispatch — canStartEarly (min_time elapsed) puuttuu *(TOTEUTETTU 2026-03-10)*

**JS** (`server.js`, dispatch logic ~L2141):
```javascript
// Batch-kandidaatti: canStartEarly jos min_time kulunut
let candidateCanStartEarly = false;
const timeOnStation = nowSec - (batch.stage_start_time / 1000);
const minTime = parseTimeToSeconds(stageInfo.min_time) || batch.min_time_s;
if (timeOnStation >= minTime) candidateCanStartEarly = true;

// Dispatch jos: lähellä aikataulua TAI min_time kulunut
if (timeUntilStart <= travelTime + 5 || candidateCanStartEarly) {
  nextTask = candidate;
}
```

**ST** (`STC_FB_DispatchTask.st`):
```
(* Dispatch timing check *)
travel_s := STC_CalcHorizontalTravel(...);
margin_s := LINT_TO_REAL(t_start - g_time_s);
IF margin_s <= travel_s + 3.0 THEN
  (* Proceed with dispatch *)
(* ← Ei canStartEarly -tarkistusta *)
```

**Vaikutus**: JS voi dispatchata tehtävän aikaisemmin kuin aikataulutettu, jos erän `min_time` on kulunut asemalla. PLC odottaa aina kunnes `task_start_time - travel_time <= 3s`. Käytännön ero on tyypillisesti 0–30 sekuntia — PLC on konservatiivisempi.

**Korjaus**: Lisää `STC_FB_DispatchTask`:iin canStartEarly-haara:
```
(* canStartEarly: min_time kulunut *)
can_start_early := FALSE;
IF g_batch[t_unit].State = IN_PROCESS THEN
  elapsed := LINT_TO_REAL(g_time_s - g_batch[t_unit].StartTime);
  IF elapsed >= DINT_TO_REAL(g_batch[t_unit].MinTime) THEN
    can_start_early := TRUE;
  END_IF;
END_IF;

IF margin_s <= travel_s + 3.0 OR can_start_early THEN
```

---

## GAP-8: ✅ TOTEUTETTU — Conflict resolve DELAY_PREV + DELAY_PAST_NEXT

**Toteutettu**: `TSK_FB_Resolve.st` — lisätty Priority 4 ja Priority 5.

**Priority 4 — PRECEDING_DELAY** (JS Phase 3):
- Viivästyttää conf-batchin edellistä vaihetta (`i_conf_stage - 1`)
- Käyttää kyseisen vaiheen `flex_up` (MaxTime - CalcTime)
- Cap: 90% jos erä on asemalla, 50% muuten
- Lock-tarkistus: ADVANCE-lukko estää DELAYn
- GAP-2-persistointi g_program:iin

**Priority 5 — DELAY_PREV_PAST_NEXT** (JS Phase 4):
- Viivästyttää blocked-batchin omaa vaihetta pakottaen järjestyksen vaihdon
- **Swap-ehto**: vain jos prev.sink ≠ next.lift (ei swapattavissa)
- Hakee sink/lift-asemat tehtäväjonosta `g_task[i_conf_trans].Queue[]`
- Lock-tarkistus: ADVANCE-lukko estää DELAYn
- GAP-2-persistointi g_program:iin

**Deployed & compiled successfully.**

---

## Yhteenveto

| GAP | Tiedosto | Vakavuus | Työmäärä |
|-----|----------|----------|----------|
| GAP-1 | `STC_FB_SortTaskQueue.st` | 🔴 Korkea | ✅ TOTEUTETTU |
| GAP-2 | `TSK_FB_Resolve.st` | 🔴 Korkea | ✅ TOTEUTETTU |
| GAP-3 | `STC_FB_ShiftSchedule.st` | 🔴 Korkea | ✅ TOTEUTETTU |
| GAP-4 | `DEP_FB_Scheduler.st` | 🔴 Korkea | ✅ TOTEUTETTU |
| GAP-5 | `DEP_FB_Scheduler.st` | ⚪ N/A | Ei relevantti — ei koodimuutosta |
| GAP-6 | `TSK_FB_NoTreatment.st` | ⚪ N/A | Ei relevantti — ei koodimuutosta |
| GAP-7 | `STC_FB_DispatchTask.st` | 🟡 Keskitaso | ✅ TOTEUTETTU |
| GAP-8 | `TSK_FB_Resolve.st` | 🟡 Keskitaso | ✅ TOTEUTETTU |

**Kaikki 8 GAP:ia käsitelty**: 6 toteutettu, 2 ei relevantti (N/A).
