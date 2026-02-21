# taskScheduler.js → PLC ST -muunnossuunnitelma

**Päivitetty:** 2026-02-20  
**Tiedosto:** `sim-core/taskScheduler.js` (~2100 riviä)  
**Tavoite:** Muuntaa JavaScript-tilakone PLC-ympäristöön ST-kielelle (IEC 61131-3)

---

## Nykytila (jo tehty)

### Perusrakenteet (alkuperäinen kierros)

| Rakenne | Tila |
|---------|------|
| `for...of` → indeksoidut FOR-loopit | ✅ Valmis |
| `?.` ja `??` → eksplisiittiset null-tarkistukset | ✅ Valmis |
| `Object.assign` → kenttäkohtainen kopio | ✅ Valmis |
| `new Set()` → boolean flag -objekti | ✅ Valmis |
| `.length` → COUNT-muuttujat | ✅ Valmis |
| `.includes()` → `_arrayIncludes()` helper | ✅ Valmis |
| `Array.sort()` → `_insertionSort()` | ✅ Valmis |
| MAX-vakiot kiinteiden taulukoiden rajoiksi | ✅ Valmis |

### Vaihe A1–A3: Hash-mapit → indeksoidut taulukot (toteutettu 2026-02-20)

| # | Kohde | Toteutus | Tila |
|---|-------|----------|------|
| A1 | `schedulesByBatchId` → `schedules[]` + `scheduleCount` | `_findScheduleIndex()`, `_getSchedule()`, `_setSchedule()`, `_schedulesToHashMap()` | ✅ Valmis |
| A2 | `programsByBatchId` → `programs[]` + `programCount` | `_findProgramIndex()`, `_getProgram()`, `_setProgram()`, `_programsToHashMap()` | ✅ Valmis |
| A3 | `lockedStages` → `lockedStages[]` + `lockedStageCount` | INT-pakatut avaimet (`batchId * 100 + stage`), `LOCK_DELAY=1`/`LOCK_ADVANCE=2`, `_lockKeyToInt()`, `_lockDirectionToInt()`, `_lockDirectionToString()`, `_findLockedStageIndex()`, `_setLockedStage()`, `_clearLockedStages()`, `_lockedStagesToHashMap()` | ✅ Valmis |

**Toteutetut vakiot:** `MAX_LOCKED_STAGES = 50`, `LOCK_DELAY = 1`, `LOCK_ADVANCE = 2`

**Ulkoinen API-yhteensopivuus:** Hash map -muuntimet (`_schedulesToHashMap()`, `_programsToHashMap()`, `_lockedStagesToHashMap()`) säilyttävät rajapinnan `departureScheduler.js`, `server.js` (`saveSchedules`, `writeTreatmentPrograms`) ja `transporterTaskScheduler.js` (`resolveConflict`) -tiedostojen kanssa. Nämä muuntimet poistetaan kun B- ja F-vaiheet on toteutettu.

**Muutetut käyttöpaikat (kaikki `taskScheduler.js`-tiedostossa):**
- State init, `reset()`
- INIT-faasi: erien lataus → `_setSchedule()`, `_setProgram()`
- INIT_PROGRAMS: ohjelmien täyttö
- INIT_DONE: lock-tietojen nollaus `_clearLockedStages()`
- SCHEDULE_BATCH: `_getSchedule()`, `_setSchedule()`
- TASKS_BATCH: `_getSchedule()`, `_getProgram()`
- TASKS_ANALYZE: `_lockedStagesToHashMap()` → `resolveConflict`-kutsuun
- TASKS_RESOLVE: `_setLockedStage()`
- TASKS_SAVE: `_copySandbox()` → muuntaa hash map -muodolla departuren sandboxiin
- SAVE_STRETCHES, SAVE_SCHEDULES, SAVE_DEPARTURE, SAVE_PROGRAMS, SAVE_CSV
- `getData()`: `_programsToHashMap()` departurelle
- `canAssignTasks()`: `programCount`-tarkistus

### Vaihe A4–A5: Loput hash-mapit (toteutettu 2026-02-20)

| # | Kohde | Toteutus | Tila |
|---|-------|----------|------|
| A4 | `occupiedStationFlags` → `ARRAY[0..MAX_STATIONS-1] OF BOOL` | Kiinteä boolean-taulukko, station number suoraan indeksinä. Erillinen `occupiedStationList[]` + `occupiedStationCount` iterointia varten. Set-like wrapper (`has()`, `Symbol.iterator`) säilyy API-yhteensopivuudelle `transporterTaskScheduler.js`:n kanssa. | ✅ Valmis |
| A5 | `ctx.departurePendingWriteData` → kiinteä struct + `.valid`-lippu | `{ valid: false }` default (ei `null`). Departure asettaa `valid: true` kun data luodaan, tasks tarkistaa `.valid`. Muutokset: `departureScheduler.js` (init, create, clear, reset), `server.js` (fallback), `taskScheduler.js` (SAVE_DEPARTURE check). | ✅ Valmis |

> **⚠ A4 huom:** `Object.keys().filter().map()` -ketju poistettu kokonaan. Korvattu pre-allokoitu `occupiedStationList[]` + `occupiedStationCount` -parilla, joka on suoraan ST-yhteensopiva `FOR i := 0 TO occupiedStationCount - 1 DO`.

> **⚠ A5 huom:** Departure luo edelleen sisäisesti hash map -kopiot (`programsByBatchId`, `schedulesByBatchId`). Nämä muunnetaan kun `departureScheduler.js` käy läpi oman ST-konversionsa. Tässä vaiheessa `.valid`-lippu poistaa `null`-tarkistukset.

### Vaihe B1–B2: `_copySandbox()` kenttäkohtainen kopio (toteutettu 2026-02-20)

| # | Kohde | Toteutus | Tila |
|---|-------|----------|------|
| B1 | `_copySandbox()` schedules | `_copyScheduleStage(src)` — kopioi 8 pääkenttää + 6 valinnaista kenttää. FOR-loop per schedule, per stage. | ✅ Valmis |
| B2 | `_copySandbox()` programs | `_copyProgramStage(src)` — kopioi 6 kenttää (`stage`, `min_station`, `max_station`, `min_time`, `max_time`, `calc_time`). FOR-loop per program, per stage. | ✅ Valmis |

**Toteutetut apufunktiot:**
- `_copyScheduleStage(src)` — Schedule-stage struct: `stage`, `station`, `entry_time_s`, `exit_time_s`, `treatment_time_s`, `transfer_time_s`, `min_time_s`, `max_time_s` + optional: `station_name`, `min_exit_time_s`, `max_exit_time_s`, `transfer_details`, `parallel_stations`, `selected_from_parallel`
- `_copyProgramStage(src)` — Program-stage struct: `stage`, `min_station`, `max_station`, `min_time`, `max_time`, `calc_time`

### Vaihe B3: `getData()` kenttäkohtainen kopio departurelle (toteutettu 2026-02-20)

**Ongelma:** `getData()` käytti `JSON.parse(JSON.stringify(_programsToHashMap()))` — PLC:ssä mahdoton.

**Toteutus:** FOR-loop joka kopioi kaikki ohjelmat `_copyProgramStage()`-apufunktiolla. Departure saa oman erilliskopion — ei viittausta tasks-tilakoneen dataan. `_programsToHashMap()` ei enää tarvita `getData()`-kutsussa.

**Poistettu JSON deep copy:** Viimeinen `JSON.parse(JSON.stringify(...))` poistettu `taskScheduler.js`:stä. ✅

### Vaihe C1–C3: Sulkeumat erilliisiksi funktioiksi (toteutettu 2026-02-20)

| # | Kohde | Toteutus | Tila |
|---|-------|----------|------|
| C1 | `isFree()` → `_isStationFree()` | Itsenäinen funktio, 7 parametria: `sid, unitStation, isLocationOccupied, transporterStates, transporterStateCount, tasks, taskCount`. `_findSinkStation` kutsuu eksplisiittisillä arvoilla. | ✅ Valmis |
| C2 | `getOvertimeRatio()` → `_getOvertimeRatio()` | Itsenäinen funktio, 5 parametria: `task, batches, batchCount, currentTimeSec, getBatchLocation`. | ✅ Valmis |
| C3 | Sort-callback → `_compareTasksPriority()` | Nimetty vertailufunktio, 3 parametria: `a, b, context`. `_insertionSort` laajennettu `context`-parametrilla (PLC: struct). Context-struct: `{ batches, batchCount, currentTimeSec, getBatchLocation }`. | ✅ Valmis |

**C3 arkkitehtuuriratkaisu:** `_insertionSort(arr, count, compareFn, context)` — context-parametri korvaa sulkeuman. PLC:ssä vastaava struct välittyy vertailufunktiolle. Arrow-callback `(a, b) => { ... }` korvattu nimetyllä funktiolla `_compareTasksPriority`.

### Bugikorjaus: Unit target nollaus erän irrotuksessa (2026-02-20)

**Ongelma:** `server.js` rivi ~1777 — kun erä irrotetaan unitista finish-asemalla, `unit.target` jäi vanhaan arvoon (esim. `'to_unloading'`). Tämä esti `updateUnitTargets()`-funktion sääntöjen 2 ja 5 evaluoinnin, koska rivi 940:n guard `if (unit.target && unit.target !== 'none') continue` ohitti unitin.

**Korjaus:** Lisätty `unit.target = 'none'` irrotuskoodiin. Nyt `updateUnitTargets()` voi arvioida tilanteen uudelleen seuraavalla tickillä.

### Bugikorjaus: Rule 5 to_avoid ylikirjoitus (2026-02-20)

**Ongelma:** `server.js` `updateUnitTargets()` — sääntö 5 (`to_avoid`) ei voinut ylikirjoittaa olemassa olevaa targetia (esim. `to_empty_buffer`). Alkuperäinen guard `if (unit.target && unit.target !== 'none') continue` esti kaikki ylikirjoitukset, mutta `to_avoid` on prioriteettitarget joka pitää asettaa aina kun unloading-statiolla on tyhjä unit ilman erää.

**Korjaus:** Guard muutettu sallimaan ylikirjoitus — nyt ohitetaan vain unitit joilla on `to_unloading` target (aktiivinen purkutehtävä). `to_avoid`-target ylikirjoittaa muut targetit kuten `to_empty_buffer`, `to_loaded_buffer` jne.

### Vaihe G1-G5: Pienet syntaksi- ja tyyppikorjaukset (toteutettu 2026-02-21)

| # | Kohde | Toteutus | Tila |
|---|-------|----------|------|
| G1 | Template literals → string concat | 36 `log()` + 3 `getPhaseName()` — kaikki `` `text ${var}` `` → `'text ' + var` | ✅ Valmis |
| G2 | `Date.now()` / `new Date()` → wrapper-funktiot | `_getSystemTimeMs()` (PLC: `GET_SYSTEM_TIME`), `_getTimestampString()` (PLC: `DT_TO_STRING`). 4 instanssia: log(), INIT cycleStartTime, RESTART cycleTimeMs, task_analysis.json timestamp | ✅ Valmis |
| G3 | `Infinity` → `REAL_MAX` | 1 instanssi `_tryFlexFit()`:ssa — `let minStartAfter = REAL_MAX` | ✅ Valmis |
| G4 | `Number.isFinite()` → `_isFinite()` | `_isFinite(x)` — `typeof x === 'number' && x === x && x > REAL_MIN && x < REAL_MAX`. 5 instanssia: x_position, simTick, periodMs, dtMs, cycleTickPeriodMs | ✅ Valmis |
| G5 | `push/shift` → `_ringBufferWrite()` | `_ringBufferWrite(arr, count, maxSize, value)` — lineaarinen shift täydessä taulukossa, counter-based append. Kohteet: `phaseLog` (MAX_PHASE_LOG=100), `cycleHistory`/`cycleTickHistory`/`cycleSimTimeHistory` (MAX_CYCLE_HISTORY=1000). Uudet state-kentät: `phaseLogCount`, `cycleHistoryCount`, `cycleTickHistoryCount`, `cycleSimTimeHistoryCount` | ✅ Valmis |

**Toteutetut apufunktiot (G1-G5):**
- `_getSystemTimeMs()` — PLC: `GET_SYSTEM_TIME` RTC millisekuntteina
- `_getTimestampString()` — PLC: `DT_TO_STRING(GET_DATE_AND_TIME())`
- `_isFinite(x)` — PLC: `(x > REAL_MIN) AND (x < REAL_MAX)` (ST:ssä REAL on aina numero, ei NaN:ia)
- `_ringBufferWrite(arr, count, maxSize, value)` — PLC: `IF count >= maxSize THEN FOR-shift; ELSE arr[count]:=value; count:=count+1; END_IF`

**Lisätyt vakiot:** `MAX_PHASE_LOG = 100`

> **⚠ G5 huom:** Ring buffer käyttää lineaarista shiftiä (O(n) kun taulukko täysi), ei modulo-indeksiä. Tämä säilyttää API-yhteensopivuuden: `arr[0]` = vanhin, `arr[count-1]` = uusin. `getStatus()` palauttaa taulukoiden viitteet suoraan. PLC:ssä vastaava toteutus: `FOR i := 0 TO maxSize - 2 DO arr[i] := arr[i+1]; END_FOR; arr[maxSize-1] := value;`

---

## Jäljellä olevat muutokset

### Vaihe B: JSON deep copy → kenttäkohtainen kopio (KRIITTINEN)

**Miksi:** `JSON.parse(JSON.stringify(...))` on PLC:ssä mahdoton — ei sarjallistamista, ei dynaamista muistia.

**Edellytys:** Vaihe A valmis ✅

| # | Kohde | Nykytila | ST-tavoite | Tila |
|---|-------|----------|------------|------|
| B1 | `_copySandbox()` schedules | ~~`JSON.parse(JSON.stringify(...))`~~ | FOR-loop + `_copyScheduleStage()` | ✅ Valmis |
| B2 | `_copySandbox()` programs | ~~`JSON.parse(JSON.stringify(...))`~~ | FOR-loop + `_copyProgramStage()` | ✅ Valmis |
| B3 | `getData()` | ~~`JSON.parse(JSON.stringify(...))`~~ | FOR-loop + `_copyProgramStage()` departurelle | ✅ Valmis |

> **⚠ B3 kriittinen: `getData()` EI voi palauttaa viitettä.**
> `departureScheduler.js` muokkaa saamiaan ohjelmia itsenäisesti:
> - Tallentaa waiting-batchin ohjelman ja palauttaa sen myöhemmin (rivi 546–547)
> - Laskee sandbox-scheduleja jotka muuttavat ohjelmien `calc_time`-arvoja
> - Käyttää `JSON.parse(JSON.stringify(...))` omissa kopioissaan
>
> Jos ST:ssä palautetaan viittaus, departure muokkaisi tasks-tilakoneen ohjelmatietoja
> suoraan → vääristyneet aikataulut seuraavalla SCHEDULE-syklillä.
>
> **Ratkaisu:** Departure tarvitsee oman erillisen ohjelma-puskurin:
> `departure_programs : ARRAY[0..MAX_BATCHES-1] OF ST_Program` johon `getData()`
> kopioi kenttä kerrallaan. Tämä on departure-tilakoneen omaa muistia.

---

### Vaihe C: Sulkeumat ja sisäfunktiot → erilliset funktiot (TÄRKEÄ)

**Miksi:** PLC ST ei tue sulkeumia (closures) eikä sisäkkäisiä funktioita. Jokainen funktio on itsenäinen, parametrit eksplisiittisesti.

| # | Kohde | Nykytila | ST-tavoite |
|---|-------|----------|------------|
| C1 | `isFree()` funktiossa `_findSinkStation` | ~~Sisäfunktio, viittaa ulkoisiin~~ → `_isStationFree()` | ✅ Valmis |
| C2 | `getOvertimeRatio()` TASKS_SORT:ssa | ~~Sulkeuma~~ → `_getOvertimeRatio()` | ✅ Valmis |
| C3 | Callback `(a, b) => ...` _insertionSort:ssa | ~~Arrow-funktio~~ → `_compareTasksPriority(a, b, context)` | ✅ Valmis |

**Esimerkki C1:**
```javascript
// Nykyinen:
function _findSinkStation(...) {
    function isFree(sid) {         // ← sulkeuma
        if (ctx.isLocationOccupied(sid)) return false;  // ← viittaus ulkoiseen
        ...
    }
}

// Tavoite:
function _isStationFree(sid, unitStation, isLocationOccupied, tStates, tsCount, tasks, taskCount) {
    if (sid === unitStation) return false;
    if (isLocationOccupied(sid)) return false;
    for (let i = 0; i < tsCount; i++) { ... }
    for (let i = 0; i < taskCount; i++) { ... }
    return true;
}
```

---

### Vaihe D: Object.keys / Object.entries → indeksoidut loopit (OSITTAIN AUTOMAATTINEN)

**A1–A3 toteutettu** → suurin osa `Object.keys()` -kutsuista on jo korvattu `scheduleCount`/`programCount`/`lockedStageCount` -muuttujilla.

**Jäljellä A4/A5:n jälkeen:**

| Rivi | Nykyinen | Korvaus | Tila |
|------|----------|---------|------|
| ~704 | `Object.keys(state.programsByBatchId).length` | `state.programCount` | ✅ Korjattu A2:ssa |
| ~1424 | `Object.keys(state.schedulesByBatchId).length` | `state.scheduleCount` | ✅ Korjattu A1:ssä |
| ~308-313 | `Object.keys(state.lockedStages)` | FOR-loop `lockedStages`-taulukolla | ✅ Korjattu A3:ssa |
| ~1460-1490 | `Object.keys(depPrograms)` (departure sandbox) | FOR-loop indeksoiduilla taulukoilla | ⬜ Odottaa F-vaihetta (departure-konversio) |
| A4-riippuvat | `occupiedStationFlags` iteraatio | Korjattu A4:n myötä | ✅ Valmis |

---

### Vaihe E: async/await → synkroninen I/O -tilakone (PLC-arkkitehtuuri)

**Miksi:** PLC:ssä ei ole `async/await`-mekanismia. I/O on asynkronista mutta tilakoneella hallittua: REQUEST → WAIT → DONE, ei JavaScript-lupauksia.

| # | Kohde | Nykytila | ST-tavoite |
|---|-------|----------|------------|
| E1 | `tick()` on `async` | `await ctx.loadRuntimeFile(...)` | I/O-pyynnöt FB-kutsuina, tulos seuraavalla syklillä |
| E2 | INIT: tiedostojen luku | `await` 2 tiedostoa samassa tickissä | Erota: INIT_READ_BATCHES → INIT_WAIT_BATCHES → INIT_READ_STATES → INIT_WAIT_STATES |
| E3 | SAVE: tiedostojen kirjoitus | `await ctx.saveSchedules(...)` | Erota: SAVE_WRITE → SAVE_WAIT |

**Arkkitehtuuri:**
```
Nykyinen:       INIT (await load1, await load2) → INIT_DONE
ST-tavoite:     INIT_REQ1 → INIT_WAIT1 → INIT_REQ2 → INIT_WAIT2 → INIT_DONE

Nykyinen:       SAVE_SCHEDULES (await save) → SAVE_TASKS
ST-tavoite:     SAVE_SCHEDULES_REQ → SAVE_SCHEDULES_WAIT → SAVE_TASKS_REQ → ...
```

**Uudet PHASE-arvot (esimerkkejä):**
```javascript
INIT_READ_BATCHES: 1,
INIT_WAIT_BATCHES: 2,
INIT_READ_STATES: 3,
INIT_WAIT_STATES: 4,
INIT_DONE: 5,
```

> **⚠ E-vaihe: faasialueet eivät saa muuttua.**
> `departureScheduler.js` sisältää kovakoodatun `TASKS_READY = 10000` ja tarkistaa
> `tasksPhase >= 10000`. Myös `canAssignTasks()` tarkistaa `phase > TASKS_SWAP (2201)`.
> **Sääntö:** SCHEDULE-alue (1000–1899), TASKS-alue (2000–2900) ja READY (10000+)
> pysyvät ennallaan. INIT:n alifaasit (1→5) ja SAVE:n alifaasit (10001→10007) lisätään
> **nykyisten alueiden sisälle** — eivät muuta ylätason raja-arvoja.
> SAVE-faasien jako REQUEST/WAIT-pareihin: käytetään väliarvoja nykyisen alueen sisällä,
> esim. `SAVE_SCHEDULES_REQ = 10002`, `SAVE_SCHEDULES_WAIT = 10012`.

---

### Vaihe F: Scheduler-kutsut → PLC-yhteensopivat paluuarvot (LAAJIN)

**Miksi:** `transporterTaskScheduler.js`:n funktiot palauttavat dynaamisia JS-objekteja ja taulukoita. ST:ssä paluuarvot täytetään ennalta varattuihin puskureihin.

| Kutsu | Palauttaa nyt | ST-tavoite |
|-------|---------------|------------|
| `scheduler.calculateBatchSchedule(...)` | `{ stages: [...], ... }` | Täyttää `ARRAY[0..MAX_STAGES] OF ST_Stage` + palauttaa `stageCount` |
| `scheduler.createTaskListFromSchedule(...)` | `task[]` | Täyttää olemassa olevan taulukon, palauttaa count |
| `scheduler.analyzeTaskConflicts(...)` | `{ hasConflict, conflict, conflicts[] }` | Kiinteä struct + `conflicts`-taulukko + count |
| `scheduler.resolveConflict(...)` | `{ solved, actions[], ... }` | Kiinteä struct + `actions`-taulukko + count |
| `scheduler.calculateTransporterIdleSlots(...)` | `slot[]` | `ARRAY[0..MAX_IDLE_SLOTS] OF ST_IdleSlot` + count |
| `scheduler.swapSameStationTasks(...)` | `{ swapCount }` | **OK** sellaisenaan |
| `scheduler.calculateHorizontalTravelTime(...)` | `REAL` | **OK** sellaisenaan |
| `scheduler.calculateTransferTime(...)` | `{ total_s }` | **OK** sellaisenaan |
| `scheduler.findStation(...)` | `station object` | **OK** (palauttaa viitteen) |

**Huom:** Tämä vaihe vaatii `transporterTaskScheduler.js`:n muokkaamista.

---

### Vaihe G: Pienet syntaksi- ja tyyppikorjaukset

| # | Kohde | Nykytila | ST-tavoite | Tila |
|---|-------|----------|------------|------|
| G1 | Template literals `` `text ${var}` `` | ~~Log-viestit~~ | String-yhdistäminen `'text ' + var` | ✅ Valmis |
| G2 | `Date.now()`, `new Date()` | ~~Aikaleima~~ | `_getSystemTimeMs()`, `_getTimestampString()` wrapper-funktiot (PLC: `GET_SYSTEM_TIME`) | ✅ Valmis |
| G3 | `Infinity` | ~~Vertailuarvo~~ | → `REAL_MAX` | ✅ Valmis |
| G4 | `Number.isFinite()` | ~~Tyyppitarkistus~~ | `_isFinite(x)` — `typeof x === 'number' && x === x && x > REAL_MIN && x < REAL_MAX` | ✅ Valmis |
| G5 | `phaseLog.push/shift`, `cycleHistory.push/shift` | ~~Dynaaminen rengaspuskuri~~ | `_ringBufferWrite(arr, count, maxSize, value)` — lineaarinen shift täydessä taulukossa, counter-pohjainen append | ✅ Valmis |

---

## Suositeltu toteutusjärjestys

```
A1-A5 ✅ → B1-B3 ✅ → C1-C3 ✅ → D (✔ automaattinen A+B myötä)
    → G1-G5 ✅ → E (async→sync) → F (scheduler API, laajin)
```

| Vaihe | Työmäärä | Riski | Vaikutus ST-yhteensopivuuteen | Tila |
|-------|----------|-------|-------------------------------|------|
| **A1-A3** | Suuri | Keskisuuri | Päärakenteet (schedule, program, lock) | ✅ Valmis |
| **A4-A5** | Keskisuuri | Pieni | `occupiedStationFlags` + departure write data | ✅ Valmis |
| **B** | Keskisuuri | Pieni — riippuu A:sta | JSON deep copy → kenttäkohtainen kopio | ✅ Valmis |
| **C** | Pieni | Pieni | Poistaa sulkeumat (ei tuettu ST:ssä) | ✅ Valmis |
| **D** | Automaattinen | Ei riskiä | Tulee A:n ja B:n sivutuotteena | ✅ Valmis |
| **G** | Pieni | Ei riskiä | Kosmeettinen, mutta pakollinen käännökselle | ✅ Valmis |
| **E** | Keskisuuri/Arkkitehtuuri | Keskisuuri — faasien määrä kasvaa | Poistaa async/await (ei tuettu PLC:ssä) | ⬜ Seuraava |
| **F** | Suurin | Suuri — toinen iso tiedosto muuttuu | Tekee kaikista scheduler-kutsuista ST-yhteensopivia | ⬜ |

---

## Seuraavat konkreettiset askeleet

### ~~Askel 1: G1-G5 — Pienet syntaksikorjaukset~~ ✅ Valmis (2026-02-21)

### Askel 2: E — async/await → synkroninen I/O-tilakone

INIT ja SAVE -faasien jako REQUEST/WAIT-pareihin.

**Arvioitu muutokset:** ~100–150 riviä (arkkitehtuurinen muutos, faasimäärä kasvaa)

### Askel 3: F — Scheduler API (laajin, koskee `transporterTaskScheduler.js`)

Kaikki `scheduler.*()` -kutsut → kiinteät puskurit + count-paluuarvot.

---

## ST Struct -määrittelyt (tavoiterakenteet)

```
TYPE ST_Task :
STRUCT
    batch_id         : INT;
    stage            : INT;
    transporter_id   : INT;
    lift_station_id  : INT;
    sink_station_id  : INT;
    task_start_time  : REAL;
    task_finished_time : REAL;
    is_no_treatment  : BOOL;
    is_primary_dest  : BOOL;
    unit_id          : INT;
    unit_target      : INT;    (* enum: 0=none, 1=to_loading, 2=to_loaded_buffer ... *)
    min_time_s       : REAL;
    max_time_s       : REAL;
    calc_time_s      : REAL;
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_Batch :
STRUCT
    batch_id         : INT;
    stage            : INT;
    treatment_program : INT;
    start_time       : LREAL;   (* ms *)
    calc_time_s      : REAL;
    min_time_s       : REAL;
    max_time_s       : REAL;
    isDelayed        : BOOL;
    justActivated    : BOOL;
    location         : INT;
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_ScheduleStage :
STRUCT
    stage            : INT;
    station          : INT;
    entry_time_s     : REAL;
    exit_time_s      : REAL;
    treatment_time_s : REAL;
    min_time_s       : REAL;
    max_time_s       : REAL;
    transfer_time_s  : REAL;
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_Schedule :
STRUCT
    batchId          : INT;
    batchStage       : INT;
    stages           : ARRAY[0..19] OF ST_ScheduleStage;
    stageCount       : INT;
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_LockedStage :
STRUCT
    lockKey          : INT;          (* batchId * 100 + stage, esim. B3s5 → 305 *)
    lockDirection    : INT;          (* 1 = DELAY, 2 = ADVANCE *)
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_IdleSlot :
STRUCT
    startTime        : REAL;
    endTime          : REAL;
    valid            : BOOL;
END_STRUCT
END_TYPE
```

---

## Huomautukset

- **Toiminnallisuus ei saa muuttua** — jokainen vaihe tulee testata Docker-ympäristössä ennen seuraavaan siirtymistä
- Vaiheiden A–D jälkeen koodia voidaan lukea suoraan ST-pseudokoodina
- Vaihe E muuttaa tilakoneautomaatin rakennetta (lisää faaseja) mutta ei logiikkaa
- Vaihe F on laajin koska se koskee toista tiedostoa (`transporterTaskScheduler.js`, ~5000 riviä)
- A1–A3:n hash map -muuntimet (`_schedulesToHashMap` jne.) ovat väliaikaisia — ne poistetaan kun B- ja F-vaiheet poistavat tarpeen hash map -rajapinnoille
- `stationIdleSince` (new Map, `server.js`) ei kuulu taskScheduler-muunnokseen mutta vaatii oman konversion myöhemmin
- ~~`cycleHistory` / `departureTimes` push/shift → rengaspuskuri käsitellään G5:ssä~~ ✅ `cycleHistory`, `cycleTickHistory`, `cycleSimTimeHistory`, `phaseLog` käsitelty G5:ssä. `departureTimes` push/shift ei ole `taskScheduler.js`:ssä (käsitellään `server.js`-konversiossa)
