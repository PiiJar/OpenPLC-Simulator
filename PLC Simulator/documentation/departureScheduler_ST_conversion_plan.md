# departureScheduler.js → PLC ST -muunnossuunnitelma

**Päivitetty:** 2026-02-23  
**Tiedosto:** `sim-core/departureScheduler.js` (~3170 riviä)  
**Tavoite:** Muuntaa JavaScript-tilakone PLC-ympäristöön ST-kielelle (IEC 61131-3)  
**Edellytys:** `taskScheduler.js` ST-konversio (vaiheet A–G ✅, E ja F jäljellä)

---

## Yleiskatsaus

`departureScheduler.js` on ERILLINEN tilakone joka synkronoidaan `taskScheduler.js`:n (TASKS) kanssa. Se:
- Vuorottelee TASKS:n kanssa tikki kerrallaan (TASKS parillinen, DEPARTURE pariton)
- Laskee aikataulut kaikille erille ja sovittaa odottavat erät nostimien idle-slotteihin
- Käyttää sandbox-arkkitehtuuria: snapshot → muutokset → REJECT/ACTIVATE
- Kutsuu `transporterTaskScheduler.js`:n funktioita aikataulujen, tehtävien ja idle-slottien laskentaan

**Suuruusluokka:** ~3170 riviä JS → arvio ~2500–3000 riviä ST (struct-kopiot ovat jo PLC-ready, mutta hash map -muunnokset lisäävät koodia)

---

## Nykytila (jo tehty taskScheduler-konversion yhteydessä)

### Jaetut apufunktiot (jo PLC-valmiit)

Nämä funktiot on jo toteutettu `taskScheduler.js`-konversion yhteydessä ja samat implementaatiot ovat käytössä `departureScheduler.js`:ssä:

| Funktio | Kuvaus | Tila |
|---------|--------|------|
| `_insertionSort(arr, count, compareFn, context)` | Stabiili lajittelu, context-parametri | ✅ Käytössä |
| `_ringBufferWrite(arr, count, maxSize, value)` | Lineaarinen ring buffer | ✅ Käytössä |
| `_arrayIncludes(arr, count, value)` | .includes()-korvike | ✅ Käytössä |
| `_isFinite(x)` | Number.isFinite-korvike | ✅ Käytössä |
| `_getSystemTimeMs()` | Date.now()-korvike | ✅ Käytössä |
| `_copyBatch()`, `_copyBatchesArray()` | Kenttäkohtainen kopio | ✅ Käytössä |
| `_copyScheduleStage()`, `_copySchedule()` | Schedule-kopiot | ✅ Käytössä |
| `_copyProgramStage()`, `_copyProgram()` | Program-kopiot | ✅ Käytössä |
| `_copyTask()` | Task-struct kopio | ✅ Käytössä |
| `_copyTransporterState()`, `_copyTransporterStatesArray()` | Transporter-kopiot | ✅ Käytössä |
| `_copyDepartureSandbox()` | Sandbox-deep copy | ✅ Käytössä |

### PLC-yhteensopivat rakenteet (jo tehty)

| Rakenne | Nykytila | Tila |
|---------|----------|------|
| `for...of` → indeksoidut FOR-loopit | 95% korvattu (paitsi ACTIVATE:n `for...of` ja `Object.entries`) | ⚠ Osittain |
| `?.` ja `??` → eksplisiittiset null-tarkistukset | ✅ Valmis | ✅ |
| `.length` → COUNT-muuttujat | State-taulukoilla käytössä, muttei kaikissa paikallisissa | ⚠ Osittain |
| `.includes()` → `_arrayIncludes()` | ✅ Valmis | ✅ |
| `Array.sort()` → `_insertionSort()` | ✅ Valmis | ✅ |
| MAX-vakiot kiinteiden taulukoiden rajoiksi | ✅ Valmis | ✅ |
| `JSON.parse(JSON.stringify(...))` → kenttäkohtainen kopio | ✅ Valmis | ✅ |
| Template literals → string concat | ✅ Valmis | ✅ |
| `Date.now()` → `_getSystemTimeMs()` | ⚠ INIT:ssä vielä suora `Date.now()` (rivi ~1089) | ⚠ 1 jäljellä |
| `Number.isFinite()` → `_isFinite()` | ⚠ CALC:ssa 3 suoraa `Number.isFinite()` -kutsua | ⚠ 3 jäljellä |

### Hash map → indeksoidut taulukot (jo tehty osittain)

| # | Kohde | Nykytila | Tila |
|---|-------|----------|------|
| A1 | `schedules[]` + `scheduleCount` | `_findScheduleIndex()`, `_getSchedule()`, `_setSchedule()`, `_removeSchedule()` | ✅ Valmis |
| A2 | `programs[]` + `programCount` | `_findProgramIndex()`, `_getProgram()`, `_setProgram()` | ✅ Valmis |
| A3 | `_calcScheds[]` + `_calcSchedCount` | `_findCalcSchedIndex()`, `_getCalcSched()`, `_setCalcSched()` | ✅ Valmis |
| A4 | `waitingScheds[]` + `waitingSchedCount` | `_findWaitingSchedIndex()`, `_getWaitingSched()`, `_setWaitingSched()`, `_removeWaitingSched()` | ✅ Valmis |
| A5 | `waitingAnalyses[]` + `waitingAnalysisCount` | `_findWaitingAnalysisIndex()`, `_getWaitingAnalysis()`, `_setWaitingAnalysis()` | ✅ Valmis |
| A6 | `waitingTaskSets[]` + `waitingTaskSetCount` | `_findWaitingTaskSetIndex()`, `_getWaitingTaskSet()`, `_setWaitingTaskSet()`, `_removeWaitingTaskSet()` | ✅ Valmis |

---

## Jäljellä olevat muutokset

### Vaihe DA: Sandbox hash map -rakenteet → indeksoidut taulukot (KRIITTINEN)

**Miksi:** `departureSandbox` käyttää sisäisesti hash map -muotoa (`schedulesByBatchId`, `programsByBatchId`). PLC:ssä ei ole dynaamisia avainarvohakemistoja.

**Laajuus:** Sandbox-hash mapit käytetään ~40 paikassa INIT:stä ACTIVATE:een.

| # | Kohde | Nykytila | ST-tavoite | Arvio |
|---|-------|----------|------------|-------|
| DA1 | `departureSandbox.schedulesByBatchId` | Hash map `{ "batchId": scheduleData }` | `sbSchedules[]` + `sbScheduleCount` + indexed helpers | ~80 riviä |
| DA2 | `departureSandbox.programsByBatchId` | Hash map `{ "batchId": programData }` | `sbPrograms[]` + `sbProgramCount` + indexed helpers | ~80 riviä |
| DA3 | `idleSlotsPerTransporter` (CHECK_ANALYZE) | Hash map `{ transporterId: slots[] }` | `ARRAY[0..MAX_TRANSPORTERS] OF { slots[], count }` — transporterId suoraan indeksinä | ~30 riviä |
| DA4 | `pendingWriteData` sisäiset hash mapit | Hash map `{ programsByBatchId, schedulesByBatchId }` | Kiinteä struct + indexed arrays | ~40 riviä |

**Toteutusstrategia DA1/DA2:**
```javascript
// Nykyinen:
state.departureSandbox.schedulesByBatchId[String(batchId)] = scheduleResult;

// Tavoite:
// ST: ARRAY[0..MAX_BATCHES-1] OF { batchId: INT, data: ST_Schedule }
function _sbFindScheduleIndex(batchId) { ... }
function _sbGetSchedule(batchId) { ... }
function _sbSetSchedule(batchId, data) { ... }
// Kutsut:
_sbSetSchedule(batchId, scheduleResult);
```

**Toteutusstrategia DA3:**
```javascript
// Nykyinen:
const idleSlotsPerTransporter = {};
idleSlotsPerTransporter[tId] = scheduler.calculateTransporterIdleSlots(...);
const slots = idleSlotsPerTransporter[tId];

// Tavoite:
// PLC: ARRAY[0..MAX_TRANSPORTERS-1] OF { slots: ARRAY[0..MAX_IDLE_SLOTS-1], count: INT }
const idleSlotsByTransporter = [];
for (let i = 0; i < MAX_TRANSPORTERS; i++) idleSlotsByTransporter[i] = { slots: [], count: 0 };
idleSlotsByTransporter[tId].slots = scheduler.calculateTransporterIdleSlots(...);
idleSlotsByTransporter[tId].count = idleSlotsByTransporter[tId].slots.length;
const slots = idleSlotsByTransporter[tId].slots;
```

**Edellytys:** Ei riippuvuuksia — voidaan aloittaa heti.

---

### Vaihe DB: `new Set()` → PLC-yhteensopivat rakenteet (TÄRKEÄ)

**Miksi:** PLC:ssä ei ole Set-tietorakennetta.

| # | Kohde | Nykytila | ST-tavoite |
|---|-------|----------|------------|
| DB1 | `occupiedStations` (DEPARTURE_CALC, CHECK_RECALC_SCHEDULE) | `new Set()` + `.add()` | `BOOL[0..MAX_STATIONS]` flag-taulukko (station number suoraan indeksinä) |
| DB2 | `stationIdleSince` (ctx-parametri) | `new Map()` (server.js) | Odottaa server.js-konversiota — departure vain välittää eteenpäin |

**DB1 esiintyy 3 paikassa:**
1. DEPARTURE_CALC (rivi ~1399): `const occupiedStations = new Set()`
2. calculateWaitingBatchSchedule (rivi ~927): `const occupiedStations = new Set()`  
3. CHECK_RECALC_SCHEDULE (rivi ~2497): `const occupiedStations = new Set()`

**Toteutus:**
```javascript
// Nykyinen:
const occupiedStations = new Set();
for (...) { if (...) occupiedStations.add(_u.location); }

// Tavoite:
const occupiedStationFlags = [];
for (let i = 0; i <= MAX_STATIONS; i++) occupiedStationFlags[i] = false;
for (...) { if (...) occupiedStationFlags[_u.location] = true; }
```

> **⚠ DB1 huom:** `calculateBatchSchedule()` vaatii tällä hetkellä `Set`-rajapintaa (`occupiedStations.has()`). Tämä muutos vaatii myös `transporterTaskScheduler.js`:n muokkaamista, tai wrapper-funktion joka toteuttaa `.has()`-rajapinnan flag-taulukon päälle (kuten A4 teki taskScheduler.js:ssa).

---

### Vaihe DC: `Object.keys()` / `Object.entries()` → indeksoidut loopit (TÄRKEÄ)

**Miksi:** PLC:ssä ei ole `Object.keys()` -mekanismia.

| # | Sijainti | Nykytila | ST-tavoite | Tila |
|---|---------|----------|------------|------|
| DC1 | INIT: `_programsFromHashMap()` | `Object.keys(hashMap)` | Odottaa DA2-vaihetta (poistetaan kokonaan) | ⬜ |
| DC2 | CHECK_RECALC_SCHEDULE: sandbox iteraatio | `Object.keys(_sbSchedMap)` | FOR-loop `sbScheduleCount` -taulukolla | ⬜ |
| DC3 | CHECK_RECALC_TASKS: sandbox iteraatio | `Object.keys(_rtSchedMap)` | FOR-loop `sbScheduleCount` -taulukolla | ⬜ |
| DC4 | ACTIVATE: sandbox schedule kopio | `Object.keys(sbSchedMap)`, `Object.entries(...)` | FOR-loop indexed arrays | ⬜ |
| DC5 | ACTIVATE: snapshot `Object.entries(schedulesByBatchId)` | Debug-koodia | Poistetaan tai korvataan FOR-loopilla | ⬜ |
| DC6 | ACTIVATE: `pendingWriteData` rakentaminen | `Object.keys()`, `Object.entries()` | FOR-loop indexed arrays | ⬜ |
| DC7 | `computeOverlapStations()`: `Object.keys(t.task_areas)` | Nostin-konfiguraation avaimet | PLC: kiinteä `ARRAY[0..MAX_TASK_AREAS] OF ST_TaskArea` + count | ⬜ |
| DC8 | `_copyProgramsHashMap()` | `Object.keys(srcMap)` | Poistetaan — korvataan DA2:n indexed copy | ⬜ |
| DC9 | `_schedulesToHashMap()`, `_programsToHashMap()` | Muunnosfunktiot | Poistetaan kun DA valmis (ei enää hash-map-rajapintaa) | ⬜ |

> **DC7 erityistapaus:** `task_areas` on konfiguraatio-objekti jossa avaimet ovat nimiä (`"area_1"`, `"area_2"`). PLC:ssä tämä on kiinteä taulukko `ARRAY[0..MAX_TASK_AREAS-1] OF ST_TaskArea` + `taskAreaCount`. Vaatii myös `transporters.json`-latauskoodin muutosta.

---

### Vaihe DD: `for...of` → indeksoidut FOR-loopit (PIENI)

**Miksi:** `for...of` ei ole suoraan tuettu ST:ssä.

Suurin osa on jo korvattu. **Jäljellä:**

| # | Sijainti | Nykytila | Muutos |
|---|---------|----------|--------|
| DD1 | DEPARTURE_CALC_START: `for (const t of (ctx.transporterStates \|\| []))` (in-flight) | `for...of` | `for (let i = 0; i < tsArr.length; i++)` |
| DD2 | CHECK_CREATE_TASKS: `for (const t of (ctx.transporterStates \|\| []))` | `for...of` | `for (let i = 0; i < tsArr.length; i++)` |
| DD3 | CHECK_SWAP: `for (const transporterId of transporterIds)` | `for...of` | `for (let i = 0; i < transporterIds.length; i++)` |
| DD4 | CHECK_ANALYZE: `for (const tId of transporterIds)` (5 instanssia) | `for...of` | `for (let i = 0; i < transporterIds.length; i++)` |
| DD5 | CHECK_ANALYZE: `for (const slot of idleSlots)` | `for...of` | `for (let si = 0; si < slots.length; si++)` |
| DD6 | CHECK_ANALYZE: `for (const action of delayActions)` | `for...of` | `for (let ai = 0; ai < delayActions.length; ai++)` |
| DD7 | CHECK_UPDATE_PROGRAM: `for (const pending of pendingList)` | `for...of` | `for (let pi = 0; pi < pendingList.length; pi++)` |
| DD8 | CHECK_RECALC_SCHEDULE: `for (const batch of sandboxBatches)` | `for...of` | `for (let i = 0; i < sandboxBatches.length; i++)` |
| DD9 | CHECK_RECALC_TASKS: `for (const t of (ctx.transporterStates \|\| []))` | `for...of` | `for (let i = 0; i < tsArr.length; i++)` |
| DD10 | ACTIVATE: `for (const s of activatedSchedule.stages)` | `for...of` | `for (let i = 0; i < stages.length; i++)` |
| DD11 | ACTIVATE: `for (const [batchIdStr, program] of Object.entries(...)` | `for...of` + destructuring | `for (let i = 0; i < sbProgramCount; i++)` |
| DD12 | ACTIVATE: `for (const k of Object.keys(sbSchedMap))` | `for...of` | `for (let i = 0; i < sbScheduleCount; i++)` |
| DD13 | `calculateOverlapDelay()`: `for (const existing of existingTasks)` | `for...of` | `for (let i = 0; i < existingTasks.length; i++)` |

**Arvio:** ~30 min, mekaaninen korvaus.

---

### Vaihe DE: async/await → synkroninen tilakone (ARKKITEHTUURINEN)

**Miksi:** PLC:ssä ei ole `async/await`. Kaikki I/O on synkronista tai tilakoneella hallittua.

| # | Kohde | Nykytila | ST-tavoite |
|---|-------|----------|------------|
| DE1 | `tick(context)` on `async` | `async function tick(context)` | `function tick(context)` — poista async |
| DE2 | INIT: tiedostojen luku | Ei `await` — DEPARTURE lukee kontekstista | ✅ Jo synkroninen |
| DE3 | ACTIVATE: `await ctx.setBatchStage(...)` | Ainoa `await`-kutsu | Tilakoneen jako: ACTIVATE → ACTIVATE_SAVE_REQ → ACTIVATE_SAVE_WAIT |
| DE4 | ACTIVATE: `fs.writeFileSync(snapshot)` | Synkroninen tiedostokirjoitus | PLC: poistetaan (debug-tiedostoja ei kirjoiteta) |

**Erityishuomiot:**
- DEPARTURE ei lue tiedostoja suoraan — kaikki data tulee `ctx`-kontekstista. Tämä on jo PLC-yhteensopiva malli.
- Ainoa `await` on `ctx.setBatchStage()` ACTIVATE:ssa (rivi ~2897). Tämä voidaan siirtää TASKS SAVE -vaiheeseen (kuten `pendingWriteData` jo tekee).
- `fs.writeFileSync()` ACTIVATE:ssa (debug snapshot, rivi ~2810) on poistetaan PLC:ssä.

**Arvio:** Pieni muutos — `async` poistetaan, yksi `await` siirretään.

---

### Vaihe DF: Scheduler-kutsut → PLC-yhteensopivat paluuarvot (LAAJIN)

**Miksi:** `transporterTaskScheduler.js`:n funktiot palauttavat dynaamisia JS-objekteja. ST:ssä paluuarvot täytetään kiinteisiin puskureihin.

**HUOM:** Tämä vaihe on SAMA kuin taskScheduler-konversion vaihe F — molemmat tilakoneet kutsuvat samoja `scheduler.*()` -funktioita. Toteutetaan kerran, molemmat hyötyvät.

| Kutsu departureScheduler:ssä | Palauttaa nyt | ST-tavoite | Esiintymät |
|-------------------------------|---------------|------------|------------|
| `scheduler.calculateBatchSchedule(...)` | `{ stages: [...], ... }` | Kiinteä ST_Schedule struct + stages-taulukko | 3 paikkaa (CALC, calculateWaitingBatchSchedule, RECALC_SCHEDULE) |
| `scheduler.createTaskListFromSchedule(...)` | `task[]` | Kiinteä task-taulukko + count | 4 paikkaa (CALC_DONE, CREATE_TASKS, RECALC_TASKS ×2) |
| `scheduler.calculateTransporterIdleSlots(...)` | `slot[]` | `ARRAY[0..MAX_IDLE_SLOTS] OF ST_IdleSlot` + count | 3 paikkaa (CALC stage0, CHECK_ANALYZE) |
| `scheduler.fitSingleTaskToIdleSlots(...)` | `{ fits, delay, needExtra, slot, ... }` | Kiinteä struct ST_FitResult | 1 paikka (CHECK_ANALYZE) |
| `scheduler.canTransporterHandleTask(...)` | `BOOL` | **OK** sellaisenaan | 2 paikkaa |
| `scheduler.findStation(...)` | station object | **OK** (palauttaa viitteen) | ~10 paikkaa |
| `scheduler.calculateTransferTime(...)` | `{ phase3_travel_s, total_s, ... }` | Kiinteä struct tai REAL-paluuarvo | ~8 paikkaa |
| `scheduler.calculateHorizontalTravelTime(...)` | `REAL` | **OK** sellaisenaan | 1 paikka |
| `scheduler.parseTimeToSeconds(...)` | `REAL` | **OK** sellaisenaan | 5 paikkaa |
| `scheduler.formatSecondsToTime(...)` | `STRING` | **OK** sellaisenaan | 3 paikkaa |

---

### Vaihe DG: Pienet syntaksi- ja tyyppikorjaukset (PIENI)

| # | Kohde | Nykytila | ST-tavoite |
|---|-------|----------|------------|
| DG1 | `Date.now()` rivi ~1089 (INIT) | Suora kutsu | `_getSystemTimeMs()` |
| DG2 | `Number.isFinite()` rivi ~1092, ~879, ~1322 | 3 suoraa kutsua | `_isFinite()` |
| DG3 | `new Date().toISOString()` ACTIVATE snapshot | Debug-koodi | Poistetaan tai `_getTimestampString()` |
| DG4 | `parseInt(..., 10)` | 2 instanssia | Suora tyyppimuunnos (PLC: INT-muuttuja) |
| DG5 | `Math.max()`, `Math.min()`, `Math.round()` | ~20 instanssia | ST: `MAX()`, `MIN()`, `REAL_TO_INT()` — suora vastaavuus |
| DG6 | `try...catch` | 3 instanssia (CALC, calculateWaitingBatchSchedule, ACTIVATE snapshot) | PLC: poistetaan (ei poikkeuskäsittelyä), lisätään ennakoivat tarkistukset |
| DG7 | IIFE `(function() { ... })()` rivi ~1408, ~2984 | 2 instanssia | PLC: erillinen funktio tai inline-koodi |
| DG8 | Destructuring `[a, b] = [b, a]` (CHECK_SWAP) | 2 instanssia | PLC: `tmp := a; a := b; b := tmp;` |
| DG9 | `push()` | ~30 instanssia (paikalliset taulukot) | PLC: `arr[count] := value; count := count + 1;` |
| DG10 | `.toFixed(n)` | ~40 instanssia (lokitus) | PLC: `REAL_TO_STRING()` tai poistetaan log-kutsuista |

---

### Vaihe DH: Debug/tiedosto-I/O -koodin poisto (PLC-EI-TARVETTA)

**Miksi:** PLC:ssä ei ole tiedostojärjestelmää eikä konsoli-I/O:ta.

| # | Kohde | Rivit | Toimenpide |
|---|-------|-------|------------|
| DH1 | `fs.writeFileSync()` ACTIVATE snapshot | ~2770–2810 | Poistetaan kokonaan |
| DH2 | `fs.existsSync()`, `fs.mkdirSync()` | ~2771–2772 | Poistetaan |
| DH3 | `path.join()` | ~2770 | Poistetaan |
| DH4 | `require('fs')`, `require('path')` | Rivi ~46–47 | Poistetaan |
| DH5 | Laajennetut debug-logit (`log('DEBUG ...')`) | ~20 instanssia | Tiivistetään tai poistetaan (PLC ring buffer riittää) |
| DH6 | `summarizeTasks()` funktio | Rivit ~800–840 | Poistetaan tai yksinkertaistetaan |

**Arvio:** ~100 riviä poistetaan, koodi kevenee.

---

### Vaihe DI: Sulkeumat ja callback-funktiot → erilliset funktiot (PIENI)

Suurin osa sulkeumista on jo korvattu. **Jäljellä:**

| # | Kohde | Nykytila | ST-tavoite |
|---|-------|----------|------------|
| DI1 | `_insertionSort` callback WAITING_SORT_LOADED (rivi ~1540) | Inline `function(aIdx, bIdx) { ... }` | Nimetty `_compareWaitingBatchesByLoaded(aIdx, bIdx, context)` |
| DI2 | `_insertionSort` callback CHECK_SORT (rivi ~1774) | Inline `function(a, b) { return a.task_start_time - b.task_start_time; }` | Nimetty `_compareTasksByStartTime(a, b)` |
| DI3 | `applyDeltaToProgram` (CHECK_UPDATE_PROGRAM, rivi ~2382) | `var applyDeltaToProgram = function(...)` | Itsenäinen `_applyDeltaToProgram(program, targetStage, delay_s, propagate)` |
| DI4 | IIFE CALC (rivi ~1408) nostin-haku | `(function() { for (...) ... })()` | Erillinen `_findTransporterById(transporters, id)` |
| DI5 | IIFE ACTIVATE (rivi ~2984) schedule-kopio | `(function() { ... })()` | FOR-loop inline |

---

## Suositeltu toteutusjärjestys

```
DG (pienet korjaukset) → DD (for...of) → DI (sulkeumat)
    → DA (sandbox hash mapit, KRIITTINEN)
        → DB (Set) → DC (Object.keys, tulee DA:n sivutuotteena)
            → DH (debug-poisto)
                → DE (async→sync, PIENI)
                    → DF (scheduler API, LAAJIN — YHDESSÄ taskScheduler F-vaiheen kanssa)
```

| Vaihe | Työmäärä | Riski | Vaikutus ST-yhteensopivuuteen | Tila |
|-------|----------|-------|-------------------------------|------|
| **DG** | Pieni | Ei riskiä | `Date.now()`, `parseInt`, `try/catch` yms. | ⬜ Seuraava |
| **DD** | Pieni | Ei riskiä | `for...of` → indeksoidut | ⬜ |
| **DI** | Pieni | Pieni | Sulkeumat → nimetyt funktiot | ⬜ |
| **DA** | Suuri | Keskisuuri | Sandbox hash map → indexed array (40+ muutospaikkaa) | ⬜ |
| **DB** | Keskisuuri | Pieni | `new Set()` → flag-taulukko | ⬜ |
| **DC** | Automaattinen | Ei riskiä | `Object.keys` poistetaan DA:n myötä | ⬜ |
| **DH** | Pieni | Ei riskiä | Debug/tiedosto-koodi pois | ⬜ |
| **DE** | Pieni | Pieni | `async` pois, yksi `await` siirretään | ⬜ |
| **DF** | Suurin | Suuri | Scheduler API → kiinteät puskurit (yhdessä tasks F:n kanssa) | ⬜ |

---

## Riippuvuudet taskScheduler-konversiosta

| taskScheduler-vaihe | Departure-vaikutus |
|---------------------|--------------------|
| E (async→sync) | DE voidaan tehdä itsenäisesti — departure `tick()` on jo lähes synkroninen |
| F (scheduler API) | **DF riippuu tästä** — molemmat kutsuvat samoja `scheduler.*()` -funktioita. Toteutetaan yhdessä. |

---

## ST Struct -määrittelyt (departure-spesifiset)

```
TYPE ST_DepartureSandbox :
STRUCT
    batches          : ARRAY[0..MAX_BATCHES-1] OF ST_Batch;
    batchCount       : INT;
    schedules        : ARRAY[0..MAX_BATCHES-1] OF ST_Schedule;
    scheduleCount    : INT;
    programs         : ARRAY[0..MAX_BATCHES-1] OF ST_ProgramEntry;
    programCount     : INT;
    tasks            : ARRAY[0..MAX_TASKS-1] OF ST_Task;
    taskCount        : INT;
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_IdleSlotSet :
STRUCT
    slots            : ARRAY[0..49] OF ST_IdleSlot;
    slotCount        : INT;
END_STRUCT
END_TYPE

TYPE ST_IdleSlotsPerTransporter :
STRUCT
    byTransporter    : ARRAY[0..MAX_TRANSPORTERS-1] OF ST_IdleSlotSet;
END_STRUCT
END_TYPE

TYPE ST_FitResult :
STRUCT
    fits             : BOOL;
    delay            : REAL;
    needExtra        : REAL;
    taskEndTime      : REAL;
    slotIndex        : INT;          (* viittaus slot-taulukkoon *)
    transporterId    : INT;
    log              : STRING[200];
END_STRUCT
END_TYPE

TYPE ST_DelayAction :
STRUCT
    stage            : INT;
    delay            : REAL;
    writeTarget      : INT;         (* 0=batch, 1=program *)
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_PendingWriteData :
STRUCT
    valid            : BOOL;
    programs         : ARRAY[0..MAX_BATCHES-1] OF ST_ProgramEntry;
    programCount     : INT;
    schedules        : ARRAY[0..MAX_BATCHES-1] OF ST_Schedule;
    scheduleCount    : INT;
    batchCalcUpdates : ARRAY[0..MAX_BATCHES-1] OF ST_BatchCalcUpdate;
    updateCount      : INT;
    currentTimeSec   : REAL;
END_STRUCT
END_TYPE

TYPE ST_BatchCalcUpdate :
STRUCT
    batchId          : INT;
    stage            : INT;
    calcTimeS        : REAL;
    valid            : BOOL;
END_STRUCT
END_TYPE

TYPE ST_OverlapStations :
STRUCT
    flags            : ARRAY[0..MAX_STATIONS] OF BOOL;
    count            : INT;
END_STRUCT
END_TYPE
```

---

## Seuraavat konkreettiset askeleet

### Askel 1: DG + DD + DI — Pienet syntaksi- ja rakennekorjaukset

Mekaaninen korvaus: `Date.now()` → `_getSystemTimeMs()`, `Number.isFinite()` → `_isFinite()`, `for...of` → indeksoidut loopit, sulkeumat → nimetyt funktiot, destructuring → temp-muuttujat, `try...catch` → ennakoivat tarkistukset.

**Arvioitu muutokset:** ~100–150 riviä
**Testaus:** Docker — toiminnallisuus ei saa muuttua.

### Askel 2: DA — Sandbox hash map -konversio (PÄÄTYÖ)

Kaikki `departureSandbox.schedulesByBatchId[...]` ja `.programsByBatchId[...]` → indexed array helpers. Tämä on suurin yksittäinen muutos (~40 muutospaikkaa).

**Arvioitu muutokset:** ~200–300 riviä  
**Testaus:** Docker — sandbox-laskenta, ACTIVATE, REJECT -polut.

### Askel 3: DB + DC — Set ja Object.keys poisto

`new Set()` → flag-taulukko (3 paikkaa). `Object.keys` häviää automaattisesti DA:n myötä, paitsi `computeOverlapStations()`:n `task_areas`-avaimet.

**Arvioitu muutokset:** ~50 riviä

### Askel 4: DH + DE — Debug-poisto ja async-poisto

Poistetaan `fs`/`path`, debug-snapshot-koodi ja `async`-avainsana. Pieni arkkitehtuurinen muutos.

**Arvioitu muutokset:** ~100 riviä poistetaan

### Askel 5: DF — Scheduler API (yhdessä taskScheduler F-vaiheen kanssa)

Kaikki `scheduler.*()` -kutsut → kiinteät puskurit. Tämä koskee `transporterTaskScheduler.js`:ää ja toteutetaan yhteisesti molemmille tilakoneille.

**Arvioitu muutokset:** ~300–500 riviä (molemmissa tiedostoissa yhteensä)

---

## Työarvio yhteenveto

| Vaihe | Rivit | Aika-arvio |
|-------|-------|------------|
| DG + DD + DI | ~150 | 1–2h |
| DA | ~250 | 3–4h |
| DB + DC | ~50 | 1h |
| DH + DE | ~100 (poistoja) | 0.5–1h |
| DF (yhdessä tasks F:n kanssa) | ~400 | 4–6h |
| **Yhteensä** | **~950** | **~10–14h** |

> **Huom:** DF-vaihe on yhteinen taskScheduler F-vaiheen kanssa. Jos F on jo aloitettu tasks-puolella, departure-puolen työ on pienempi (~2–3h).

---

---

## Analyysi: Yhteiset funktiot TWA_, TSK_ ja DEP_ välillä

### Nykyiset ST-tiedostot

| Tiedosto | Prefiksi | Tyyppi | Rivit | Kuvaus |
|----------|---------|--------|-------|--------|
| `TSK_FB_Scheduler.st` | TSK_ | FB | 302 | Päätilakone — faasit, iterointi, sub-FB kutsut |
| `TSK_FB_CalcSchedule.st` | TSK_ | FB | 197 | Aikataulun laskenta (schedule) per erä |
| `TSK_FB_CreateTasks.st` | TSK_ | FB | 107 | Tehtävälistan rakentaminen schedulesta |
| `TSK_FB_SwapTasks.st` | TSK_ | FB | 50 | Same-station swap (lift ennen sink) |
| `TSK_FB_Analyze.st` | TSK_ | FB | 260 | Konfliktianalyysi (TASK_SEQUENCE + COLLISION) |
| `TSK_FB_Resolve.st` | TSK_ | FB | 297 | Konfliktin ratkaisu (4-vaiheinen ADVANCE/DELAY) |
| `TSK_FB_NoTreatment.st` | TSK_ | FB | 145 | No-treatment siirtotehtävät |
| `TWA_FB_CalcLimits.st` | TWA_ | FB | 437 | Nostimien X-rajojen laskenta (törmäyksenesto) |
| `TWA_CalcPriority.st` | TWA_ | FUNCTION | 40 | Prioriteettilaskenta TWA:lle |
| `FB_TimeMoves.st` | — | FB | 144 | Siirtoaikojen mittaus (ei prefiksiä) |
| `FB_StationLookup.st` | — | FB | 45 | Asemahaku numerolla |
| `types.st` | — | TYPEt | 203 | Kaikki struct-määrittelyt |
| `globals.st` | — | VAR_GLOBAL | 248 | Globaalit muuttujat + Modbus I/O |

### DEPARTURE tarvitsee JS:ssä seuraavat toiminnot

Alla on kattava kartoitus siitä, mitä `departureScheduler.js` kutsuu ja miten ne vastaavat jo toteutettuja ST-lohkoja:

#### 1. Suoraan uudelleenkäytettävät ST-lohkot (muutoksitta tai pienin muutoksin)

| JS-funktio (departureScheduler) | Nykyinen ST-lohko | Käyttöpaikat DEP:ssä | Uudelleenkäyttö |
|--------------------------------|-------------------|---------------------|-----------------|
| `scheduler.calculateBatchSchedule(batch, program, stations, transporter, baseTime, ...)` | **TSK_FB_CalcSchedule** | DEPARTURE_CALC (3×), RECALC_SCHEDULE | **✅ SUORA** — sama logiikka, samat globaalit |
| `scheduler.createTaskListFromSchedule(schedule, batch, transporters)` | **TSK_FB_CreateTasks** | CALC_DONE, CREATE_TASKS, RECALC_TASKS (2×) | **✅ SUORA** — sama logiikka |
| `scheduler.swapSameStationTasks(tasks, ...)` | **TSK_FB_SwapTasks** | CHECK_SWAP | **✅ SUORA** — identtinen logiikka |
| `scheduler.findStation(stationNum, stations)` | **FB_StationLookup** | ~10 paikkaa | **✅ SUORA** — sama funktio |
| Transfer/travel-ajat (`g_move[trans].travel[from].to_s[to]`) | **FB_TimeMoves** (mittaus) + `g_move` (data) | ~8 paikkaa | **✅ SUORA** — lukee samoja `g_move`-taulukoita |

**Yhteenveto:** 5 olemassa olevaa ST-lohkoa voidaan käyttää sellaisenaan departure-tilakoneesta. Tämä kattaa ~40% departuran laskentalogiikasta.

#### 2. Osittain uudelleenkäytettävät (vaatii pientä laajennusta)

| JS-funktio | Nykyinen ST-lohko | Ero | Muutosehdotus |
|------------|-------------------|-----|---------------|
| `scheduler.calculateTransferTime(from, to, transporter, movementTimes)` | Ei erillistä FB:tä — logiikka **TSK_FB_CalcSchedule**:n sisällä | CalcSchedule lukee `g_move` suoraan; departure tarvitsee saman laskennan erikseen (idle-slot travel) | **Eriytetään** yhteinen `FUNCTION CalcTransferTime` jota molemmat käyttävät |
| `scheduler.calculateHorizontalTravelTime(fromStation, toStation, transporter)` | Ei erillistä FB:tä — logiikka CalcSchedule:n sisällä | Samoin: puhdas matka-aika ilman nosto/lasku | **Eriytetään** `FUNCTION CalcHorizontalTravel` |
| `scheduler.canTransporterHandleTask(transporter, liftStation, sinkStation)` | Logiikka **TSK_FB_CreateTasks**:n sisällä (task_area match) | Sama logiikka ~3 rivillä | **Eriytetään** `FUNCTION CanTransporterHandle : BOOL` |
| `scheduler.parseTimeToSeconds(timeStr)` / `scheduler.formatSecondsToTime(sec)` | Ei ST-vastinetta | PLC:ssä ajat ovat jo REAL-sekunteja — ei tarvita | **Poistetaan** — PLC käyttää suoraan REAL-arvoja |

**Yhteenveto:** 3 funktiota kannattaa eriyttää omiksi FUNCTION-lohkoiksi, jolloin sekä TSK_ että DEP_ kutsuvat samaa koodia.

#### 3. Departure-spesifiset uudet lohkot (ei vastinetta nykyisissä ST-tiedostoissa)

| Toiminto | JS-funktio | ST-lohko (ehdotettu) | Kuvaus |
|----------|-----------|----------------------|--------|
| Idle-slot-laskenta | `scheduler.calculateTransporterIdleSlots(tId, tasks, now)` | **DEP_FB_CalcIdleSlots** | Laskee tyhjäkäynti-ikkunat tehtävälistasta per nostin |
| Idle-slot-sovitus | `scheduler.fitSingleTaskToIdleSlots(task, slotsPerT, shift, params)` | **DEP_FB_FitTaskToSlot** | Sovittaa yksittäisen tehtävän idle-slottiin |
| Overlap-analyysi | `computeOverlapStations(transporters)` | **DEP_FB_CalcOverlap** | Laskee asemat joissa useampi nostin voi toimia |
| Overlap-viive | `calculateOverlapDelay(task, shift, existing, overlap, margin)` | **DEP_FB_OverlapDelay** | Viive overlap-konfliktin vuoksi |
| Backward chaining | CHECK_ANALYZE:n sisäinen logiikka | **DEP_FB_BackwardChain** | Ketjutettu viivästys aiempiin tehtäviin |
| Sandbox mgmt | `_copyDepartureSandbox()`, snapshot/restore | **DEP_FB_Sandbox** | Sandboxin luonti, kopio, palautus |
| Päätilakone | `tick()` faasit 0–4101 | **DEP_FB_Scheduler** | Departure-pääsilmukka |
| Viiveen kirjaus | CHECK_ANALYZE:n delay-kirjaus sandboxiin | sisältyy DEP_FB_Scheduler:iin | Stage 0 → batch, stage 1+ → program |

#### 4. Jaetut tietorakenteet (globaalit)

| Globaali | TSK käyttää | DEP käyttää | TWA käyttää | Huomautus |
|----------|------------|------------|------------|-----------|
| `g_batches[1..10]` | ✅ | ✅ | — | Erätiedot |
| `g_units[1..10]` | ✅ | ✅ | — | Unit-sijainnit |
| `g_programs[1..10]` | ✅ | ✅ | — | Käsittelyohjelmat |
| `g_stations[101..125]` | ✅ | ✅ | ✅ | Asemadata |
| `g_cfg[1..3]` | ✅ | ✅ | ✅ | Nostin-konfiguraatio (task_areas!) |
| `g_state[1..3]` | — | ✅ | ✅ | Nostimien reaaliaikainen tila |
| `g_move[1..3]` | ✅ | ✅ | — | Esilasketut siirtoajat |
| `g_schedule[1..10]` | ✅ (kirjoittaa) | ✅ (lukee + kirjoittaa sandbox) | — | Aikataulut |
| `g_tasks[1..3]` | ✅ (kirjoittaa) | ✅ (lukee idle-slotteja varten) | — | Tehtäväjonot |
| `g_time_s` | ✅ | ✅ | — | Absoluuttinen aika |
| `g_avoid_status[101..125]` | — | — | ✅ | Station avoid (vain TWA) |

**Yhteenveto:** 9/11 globaalista on yhteisiä TSK_ ja DEP_ välillä. Kaikki data jaetaan samasta muistista — ei tarvita kopiointia PLC:ssä (toisin kuin JS:ssä jossa ctx kopioidaan).

### Uudet globaalit (departure-spesifiset)

| Ehdotettu globaali | Tyyppi | Kuvaus |
|-------------------|--------|--------|
| `g_dep_phase` | INT | Departure-tilakoneen nykyinen faasi |
| `g_dep_sandbox_schedule[1..10]` | TSK_SCHEDULE_T | Sandbox-aikataulut (erillinen kopio) |
| `g_dep_sandbox_batches[1..10]` | BATCH_T | Sandbox-erätiedot |
| `g_dep_sandbox_tasks[1..3]` | TSK_QUEUE_T | Sandbox-tehtäväjonot |
| `g_dep_waiting[1..10]` | INT | Odottavat erät (unit-indeksit, sorted) |
| `g_dep_waiting_count` | INT | Odottavien erien lukumäärä |
| `g_dep_idle_slots[1..3]` | DEP_IDLE_SLOT_SET_T | Idle-slotit per nostin |
| `g_dep_activated` | BOOL | Handshake: erä aktivoitu tällä syklillä |
| `g_dep_stable_flag` | BOOL | TASKS stabiili → DEPARTURE voi aloittaa |

### Yhteenveto: uudelleenkäytettävyysanalyysi

```
┌─────────────────────────────────────────────────────────────┐
│            DEPARTURE ST -toteutuksen koostuminen            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐                                   │
│  │ SUORAAN KÄYTETTÄVÄT  │  ~40% logiikasta                  │
│  │ (nykyiset ST-lohkot) │                                   │
│  │                      │                                   │
│  │ • TSK_FB_CalcSchedule│  Aikataulun laskenta              │
│  │ • TSK_FB_CreateTasks │  Tehtävälistan rakennus           │
│  │ • TSK_FB_SwapTasks   │  Same-station swap                │
│  │ • FB_StationLookup   │  Asemahaku                        │
│  │ • g_move[] data      │  Siirtoajat (FB_TimeMoves mittaa) │
│  └──────────────────────┘                                   │
│                                                             │
│  ┌──────────────────────┐                                   │
│  │ ERIYTETÄÄN YHTEISIKSI│  ~10% logiikasta                  │
│  │ (TSK + DEP käyttävät)│                                   │
│  │                      │                                   │
│  │ • CalcTransferTime   │  Siirtoaika (lift+travel+sink)    │
│  │ • CalcHorizontalTrav │  Pelkkä vaakamatka                │
│  │ • CanTransporterHndl │  Task_area-tarkistus              │
│  └──────────────────────┘                                   │
│                                                             │
│  ┌──────────────────────┐                                   │
│  │ DEPARTURE-SPESIFISET │  ~50% logiikasta                  │
│  │ (uudet DEP_ lohkot)  │                                   │
│  │                      │                                   │
│  │ • DEP_FB_Scheduler   │  Päätilakone (faasit 0-4101)     │
│  │ • DEP_FB_CalcIdleSlot│  Idle-slotit tehtävistä          │
│  │ • DEP_FB_FitTaskToSlt│  Tehtävän sovitus slottiin       │
│  │ • DEP_FB_CalcOverlap │  Overlap-asemien laskenta        │
│  │ • DEP_FB_OverlapDelay│  Overlap-viive                   │
│  │ • DEP_FB_BackwardChn │  Ketjutettu viivästys            │
│  │ • DEP_FB_Sandbox     │  Sandbox-hallinta                │
│  └──────────────────────┘                                   │
│                                                             │
│  ┌──────────────────────┐                                   │
│  │ JAETUT RAKENTEET     │  Tyypit + globaalit               │
│  │ (types.st, globals)  │                                   │
│  │                      │                                   │
│  │ • 9/11 globaalia yht │  g_batches, g_schedule, g_move...│
│  │ • Kaikki TSK_ tyypit │  TSK_TASK_T, TSK_SCHEDULE_T...   │
│  │ • Uusia: DEP_ tyypit │  DEP_IDLE_SLOT_T, DEP_FIT_T...   │
│  └──────────────────────┘                                   │
└─────────────────────────────────────────────────────────────┘
```

### Konkreettinen vaikutus työmäärään

| Skenaario | Ilman uudelleenkäyttöä | Uudelleenkäytöllä | Säästö |
|-----------|----------------------|-------------------|--------|
| CalcSchedule | ~200 riviä uutta koodia | 0 riviä (kutsutaan TSK_FB_CalcSchedule) | **-200 riviä** |
| CreateTasks | ~110 riviä uutta | 0 riviä (kutsutaan TSK_FB_CreateTasks) | **-110 riviä** |
| SwapTasks | ~50 riviä | 0 riviä (kutsutaan TSK_FB_SwapTasks) | **-50 riviä** |
| StationLookup | ~45 riviä per instanssi | 0 riviä (kutsutaan FB_StationLookup) | **-45 riviä** |
| TransferTime (eriytetty) | ~30 riviä × 2 tiedostoa | 30 riviä × 1 funktio | **-30 riviä** |
| Task_area match (eriytetty) | ~15 riviä × 2 tiedostoa | 15 riviä × 1 funktio | **-15 riviä** |
| **Yhteensä** | | | **~-450 riviä** |

Arvioitu departure-spesifinen koodi: **~800–1000 riviä** (sandbox-hallinta + idle-slot-laskenta + sovituslogiikka + päätilakone + overlap).

Kokonaisarvio DEP_ ST-toteutukselle: **~800–1000 riviä uutta koodia** + **~450 riviä uudelleenkäytettyä** = ~1250–1450 riviä toiminnallista koodia.

### Suositeltu eriyttämisjärjestys

1. **Heti (ennen DEP-toteutusta):** Eriytä `CalcTransferTime`, `CalcHorizontalTravel`, `CanTransporterHandle` omiksi FUNCTION-lohkoiksi. Päivitä TSK_FB_CalcSchedule ja TSK_FB_CreateTasks kutsumaan niitä.
2. **DEP-toteutuksen yhteydessä:** Käytä TSK_FB_CalcSchedule, TSK_FB_CreateTasks, TSK_FB_SwapTasks suorina sub-FB-kutsuina DEP_FB_Scheduler:stä.
3. **Sandbox-arkkitehtuuri:** `g_dep_sandbox_schedule[]` on erillinen kopio `g_schedule[]`:sta — TSK_FB_CalcSchedule voi kirjoittaa jompaankumpaan (parametrina tai globaalivalinnalla).

---
---

## TOTEUTUSSUUNNITELMA

Kokonaissuunnitelma kahdessa osassa:
- **Osa 1:** STC_-jaettujen funktioiden luonti + käyttöönotto nykyisissä FB:issä
- **Osa 2:** DEP_-departure schedulerin toteuttaminen ST:llä (tyypit, globaalit, FB:t)

---

### Osa 1: Jaetut STC_-funktiot (arvio: 4–6h)

#### Vaihe 1.1: STC_FB_CalcTransferTime — uusi tiedosto

**Tiedosto:** `openplc/OpenPLC/src/STC_FB_CalcTransferTime.st`

Eriyttää siirtoajan laskennan joka on nyt kopioituna kolmessa FB:ssä.

> **Miksi FB eikä FUNCTION:** OpenPLC:n MATIEC ei salli VAR_EXTERNAL FUNCTIONissa.
> Tämä on loogisesti tilaton laskenta, mutta FB teknisestä syystä.

```st
FUNCTION_BLOCK STC_FB_CalcTransferTime
VAR_INPUT
  i_from_stn : INT;     (* lähtöasema, esim. 105 *)
  i_to_stn   : INT;     (* kohde, esim. 112 *)
  i_trans     : INT;     (* nostin 1..3 *)
END_VAR
VAR_OUTPUT
  o_total_s   : REAL;   (* lift + travel + sink *)
  o_lift_s    : REAL;
  o_travel_s  : REAL;
  o_sink_s    : REAL;
END_VAR
VAR_EXTERNAL
  g_move : ARRAY[1..3] OF MOVE_TIMES_T;
END_VAR
VAR
  from_idx : INT;
  to_idx   : INT;
END_VAR
```

**Logiikka — eriytettävä koodi (nyt TSK_FB_CalcSchedule rivit 131–141):**
```st
o_total_s  := 0.0;  o_lift_s := 0.0;  o_travel_s := 0.0;  o_sink_s := 0.0;
IF i_from_stn > 0 AND i_from_stn <> i_to_stn THEN
  from_idx := i_from_stn - 100;
  to_idx   := i_to_stn - 100;
  IF from_idx >= 1 AND from_idx <= 25 AND to_idx >= 1 AND to_idx <= 25 THEN
    o_lift_s   := g_move[i_trans].lift_s[from_idx];
    o_travel_s := g_move[i_trans].travel[from_idx].to_s[to_idx];
    o_sink_s   := g_move[i_trans].sink_s[to_idx];
    o_total_s  := o_lift_s + o_travel_s + o_sink_s;
  END_IF;
END_IF;
```

**Tämä korvaa identtisen koodinpätkän seuraavissa paikoissa:**

| Tiedosto | Rivit | Nykytila |
|----------|-------|----------|
| `TSK_FB_CalcSchedule.st` | 131–141 | `xfer_t := lift_t + travel_t + sink_t` |
| `TSK_FB_NoTreatment.st` | 110–122 | `xfer_s := lift_s + travel_s + sink_s_v` |
| `TSK_FB_Analyze.st` | 169–177 | `travel_s := g_move[...].travel[...].to_s[...]` (pelkkä travel) |

**Tehtävät:**
1. ✅ Luo `STC_FB_CalcTransferTime.st`
2. 🔧 Muokkaa `TSK_FB_CalcSchedule.st`: lisää instanssi, korvaa inline-koodi kutsulla
3. 🔧 Muokkaa `TSK_FB_NoTreatment.st`: lisää instanssi, korvaa inline-koodi kutsulla
4. 🔧 Muokkaa `TSK_FB_Analyze.st`: käytä `o_travel_s`:ää (SEQUENCE-check käyttää vain travel-osaa)
5. 🧪 Build + deploy + testaa: ajoitus ei saa muuttua

---

#### Vaihe 1.2: STC_FB_FindTransporter — uusi tiedosto

**Tiedosto:** `openplc/OpenPLC/src/STC_FB_FindTransporter.st`

Etsii nostimen joka voi käsitellä annetun lift→sink parin. Nyt kopioitu 3 paikkaan.

```st
FUNCTION_BLOCK STC_FB_FindTransporter
VAR_INPUT
  i_lift_stn  : INT;     (* lift station *)
  i_sink_stn  : INT;     (* sink station, 0 = etsi pelkkä lift-kattavuus *)
END_VAR
VAR_OUTPUT
  o_trans_id : INT;       (* löydetty nostin 1..3, 0 = ei löytynyt *)
END_VAR
VAR_EXTERNAL
  g_cfg : ARRAY[1..3] OF TRANSPORTER_CFG_T;
END_VAR
VAR
  ti   : INT;
  ai   : INT;
  area : TASK_AREA_T;
  can_lift : BOOL;
  can_sink : BOOL;
END_VAR
```

**Logiikka:**
```st
o_trans_id := 0;
FOR ti := 1 TO 3 DO
  IF o_trans_id = 0 THEN
    FOR ai := 1 TO 4 DO
      IF o_trans_id = 0 THEN
        area := g_cfg[ti].task_area[ai];
        IF area.min_lift > 0 OR area.max_lift > 0 THEN
          can_lift := (i_lift_stn >= area.min_lift) AND (i_lift_stn <= area.max_lift);
          IF i_sink_stn = 0 THEN
            (* Pelkkä kattavuushaku *)
            IF can_lift THEN o_trans_id := ti; END_IF;
          ELSE
            can_sink := (i_sink_stn >= area.min_sink) AND (i_sink_stn <= area.max_sink);
            IF can_lift AND can_sink THEN o_trans_id := ti; END_IF;
          END_IF;
        END_IF;
      END_IF;
    END_FOR;
  END_IF;
END_FOR;
```

**Korvaa identtisen koodin seuraavissa paikoissa:**

| Tiedosto | Rivit | Käyttö | Erityishuomio |
|----------|-------|--------|---------------|
| `TSK_FB_CreateTasks.st` | 63–82 | lift+sink haku | Suora korvaus |
| `TSK_FB_NoTreatment.st` | 63–78 | pelkkä station kattavuus | `i_sink_stn := 0` → kattavuushaku |
| `TSK_FB_Scheduler.st` | 119–127 | pelkkä location kattavuus schedule-laskentaan | `i_sink_stn := 0` → kattavuushaku |

**Tehtävät:**
1. ✅ Luo `STC_FB_FindTransporter.st`
2. 🔧 Muokkaa `TSK_FB_CreateTasks.st`: lisää instanssi, korvaa inline task_area loop
3. 🔧 Muokkaa `TSK_FB_NoTreatment.st`: lisää instanssi, korvaa kattavuushaku
4. 🔧 Muokkaa `TSK_FB_Scheduler.st`: lisää instanssi, korvaa sched_trans-haku
5. 🧪 Build + deploy + testaa

---

#### Vaihe 1.3: Olemassaolevien FB:iden uudelleennimeäminen (NAMING_CONVENTION)

Nimeämiskäytännön mukaiset tiedostomuutokset:

| Nykyinen tiedosto | Uusi tiedosto | POU-nimi muuttuu |
|-------------------|--------------|-----------------|
| `FB_TimeMoves.st` | `STC_FB_MeasureMoveTimes.st` | `FB_TimeMoves` → `STC_FB_MeasureMoveTimes` |
| `fb_station_lookup.st` | `STC_FB_FindStation.st` | `FB_StationLookup` → `STC_FB_FindStation` |

**Vaikutusalue — viittaukset jotka pitää päivittää:**

`FB_TimeMoves` → `STC_FB_MeasureMoveTimes`:
- `plc_prg.st`: instanssit `tm1`, `tm2`, `tm3` (tyyppi muuttuu)

`FB_StationLookup` → `STC_FB_FindStation`:
- `plc_prg.st`: instanssi `lookup` (tyyppi muuttuu, ~15 kutsua)

**Tehtävät:**
1. 🔧 Uudelleennimeä tiedostot (`mv`)
2. 🔧 Päivitä POU-nimet tiedostojen sisällä
3. 🔧 Päivitä `plc_prg.st` instanssityypit ja kutsut
4. 🧪 Build + deploy + testaa

> **⚠ Huomio:** Tämä vaihe voidaan tehdä myöhemmin jos se on liian riskialtis tehdä samalla kertaa. Nimeäminen on kosmeettista — toiminnallisuus ei muutu.

---

#### Vaihe 1.4: STC_FB_CalcHorizontalTravel — uusi tiedosto

**Tiedosto:** `openplc/OpenPLC/src/STC_FB_CalcHorizontalTravel.st`

Pelkkä vaakamatka-aika ilman nosto/lasku. Departure tarvitsee tätä idle-slot-sovituksessa kun nostin on jo asemalla.

```st
FUNCTION_BLOCK STC_FB_CalcHorizontalTravel
VAR_INPUT
  i_from_stn : INT;
  i_to_stn   : INT;
  i_trans     : INT;
END_VAR
VAR_OUTPUT
  o_travel_s : REAL;
END_VAR
VAR_EXTERNAL
  g_move : ARRAY[1..3] OF MOVE_TIMES_T;
END_VAR
VAR
  from_idx : INT;
  to_idx   : INT;
END_VAR

o_travel_s := 0.0;
IF i_from_stn > 0 AND i_to_stn > 0 AND i_from_stn <> i_to_stn THEN
  from_idx := i_from_stn - 100;
  to_idx   := i_to_stn - 100;
  IF from_idx >= 1 AND from_idx <= 25 AND to_idx >= 1 AND to_idx <= 25
     AND i_trans >= 1 AND i_trans <= 3 THEN
    o_travel_s := g_move[i_trans].travel[from_idx].to_s[to_idx];
  END_IF;
END_IF;
```

**Käyttöpaikat:** TSK_FB_Analyze (travel between tasks), DEP-idle-slot (travel to pickup).
Nykyisessä koodissa TSK_FB_Analyze rivit 169–177 tekevät saman manuaalisesti.

**Tehtävät:**
1. ✅ Luo `STC_FB_CalcHorizontalTravel.st`
2. 🔧 Muokkaa `TSK_FB_Analyze.st`: käytä STC_FB_CalcHorizontalTravel SEQUENCE-checkissä
3. 🧪 Build + deploy + testaa

---

#### Vaihe 1.5: Validoi kokonaisuus

**Tehtävät:**
1. 🧪 `python3 build_plcxml.py` — käännös onnistuu
2. 🧪 `bash deploy_plc.sh` — deploy toimii
3. 🧪 docker testaus: lataa asiakas → aja batch → tarkista ajoitukset täsmäävät
4. 📄 Päivitä `PLC_KEHITYSOHJE.md` hakemistorakenne uusilla tiedostoilla

**Osa 1 muutosyhteenveto:**

| Toimenpide | Tiedosto | Tyyppi |
|-----------|----------|--------|
| Uusi | `STC_FB_CalcTransferTime.st` | ~35 riviä |
| Uusi | `STC_FB_FindTransporter.st` | ~40 riviä |
| Uusi | `STC_FB_CalcHorizontalTravel.st` | ~25 riviä |
| Muokkaus | `TSK_FB_CalcSchedule.st` | -10, +5 (instanssi + kutsu) |
| Muokkaus | `TSK_FB_CreateTasks.st` | -18, +5 |
| Muokkaus | `TSK_FB_NoTreatment.st` | -20, +10 |
| Muokkaus | `TSK_FB_Analyze.st` | -8, +5 |
| Muokkaus | `TSK_FB_Scheduler.st` | -8, +5 |
| Uudelleennimeys | `FB_TimeMoves.st` → `STC_FB_MeasureMoveTimes.st` | Nimi |
| Uudelleennimeys | `fb_station_lookup.st` → `STC_FB_FindStation.st` | Nimi |
| Muokkaus | `plc_prg.st` | Instanssityyppien nimet |
| Muokkaus | `PLC_KEHITYSOHJE.md` | Hakemistorakenne |

**Netto:** ~100 riviä uutta koodia, ~60 riviä poistetaan duplikaattia = **~40 riviä nettolisäys**, mutta 3 uudelleenkäytettävää FB:tä.

---

### Osa 2: DEP_-departure scheduler (arvio: 12–18h)

Osa 2 noudattaa järjestystä: tyypit → globaalit → apulohkot → päätilakone → integraatio.

---

#### Vaihe 2.1: Uudet tietotyypit (types.st)

Lisätään `types.st`:iin departure-spesifiset tyypit:

```st
(* ── Departure Scheduler types (DEP_) ─────────────────────── *)

TYPE DEP_IDLE_SLOT_T :
STRUCT
  start_time   : REAL;    (* idle-jakson alku (s) *)
  end_time     : REAL;    (* idle-jakson loppu (s) *)
  lift_station : INT;     (* nostin on tällä asemalla idle-alussa *)
  sink_station : INT;     (* nostin on tällä asemalla idle-lopussa *)
END_STRUCT;
END_TYPE

TYPE DEP_IDLE_SLOT_SET_T :
STRUCT
  slots     : ARRAY[1..20] OF DEP_IDLE_SLOT_T;
  count     : INT;
END_STRUCT;
END_TYPE

TYPE DEP_FIT_RESULT_T :
STRUCT
  fits          : BOOL;    (* TRUE = tehtävä mahtuu slottiin *)
  delay_s       : REAL;    (* viive joka tarvitaan (s) *)
  need_extra_s  : REAL;    (* lisäaika joka ei mahdu (s) *)
  task_end_s    : REAL;    (* tehtävän loppuaika (s) *)
  slot_idx      : INT;     (* käytetyn slotin indeksi *)
  trans_id      : INT;     (* nostimen id *)
END_STRUCT;
END_TYPE

TYPE DEP_DELAY_ACTION_T :
STRUCT
  stage      : INT;       (* ohjelma-stage johon viive kohdistuu *)
  delay_s    : REAL;      (* viiveen suuruus (s) *)
  target     : INT;       (* 0=batch cur_stage delay, 1=program stage delay *)
  valid      : BOOL;
END_STRUCT;
END_TYPE

TYPE DEP_OVERLAP_T :
STRUCT
  flags : ARRAY[101..125] OF BOOL;   (* TRUE = asema on overlap-alueella *)
  count : INT;
END_STRUCT;
END_TYPE

TYPE DEP_SANDBOX_T :
STRUCT
  schedule     : ARRAY[1..10] OF TSK_SCHEDULE_T;
  batches      : ARRAY[1..10] OF BATCH_T;
  programs     : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  tasks        : ARRAY[1..3] OF TSK_QUEUE_T;
  valid        : BOOL;
END_STRUCT;
END_TYPE

TYPE DEP_PENDING_WRITE_T :
STRUCT
  valid        : BOOL;
  programs     : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  schedule     : ARRAY[1..10] OF TSK_SCHEDULE_T;
  batch_unit   : INT;       (* aktivoitu erä: unit-indeksi *)
  batch_stage  : INT;       (* aktivoitu erä: uusi stage *)
  time_s       : REAL;      (* aktivointihetken aika *)
END_STRUCT;
END_TYPE
```

**Tehtävät:**
1. 🔧 Lisää kaikki DEP_-tyypit `types.st`:n loppuun
2. 🧪 Build — tarkista ettei tyyppejä ole ristiriidassa

---

#### Vaihe 2.2: Uudet globaalit (globals.st)

Lisätään `globals.st`:iin departure-muuttujat:

```st
VAR_GLOBAL CONSTANT
  DEP_MAX_IDLE_SLOTS  : INT := 20;   (* max idle-slottia per nostin *)
  DEP_MAX_DELAY_ACTS  : INT := 10;   (* max viivekirjauksia per kierros *)
  DEP_MAX_WAITING     : INT := 10;   (* max odottavia eriä *)
END_VAR

VAR_GLOBAL
  (* Departure Scheduler state *)
  g_dep_sandbox       : DEP_SANDBOX_T;         (* sandbox — erillinen kopio *)
  g_dep_idle_slots    : ARRAY[1..3] OF DEP_IDLE_SLOT_SET_T;  (* idle-slotit per nostin *)
  g_dep_waiting       : ARRAY[1..10] OF INT;   (* odottavien erien unit-indeksit *)
  g_dep_waiting_count : INT;
  g_dep_overlap       : DEP_OVERLAP_T;         (* overlap-asemaflagit *)
  g_dep_pending       : DEP_PENDING_WRITE_T;   (* ACTIVATE → kirjoituspuskuri *)
  g_dep_activated     : BOOL;                   (* handshake TSK ← DEP *)
  g_dep_stable        : BOOL;                   (* handshake TSK → DEP: task list stable *)
END_VAR
```

**Tehtävät:**
1. 🔧 Lisää DEP_-vakiot `globals.st` VAR_GLOBAL CONSTANT -lohkoon
2. 🔧 Lisää DEP_-muuttujat `globals.st` VAR_GLOBAL -lohkoon
3. 🧪 Build — muistirajat ok (huom: DEP_SANDBOX_T on iso ~10kB)

**⚠ Muistiarvio DEP_SANDBOX_T:**
- `schedule[1..10]`: 10 × (1 INT + 30 × 7 REAL) = 10 × 844B ≈ 8.4kB
- `batches[1..10]`: 10 × 16B ≈ 160B
- `programs[1..10]`: 10 × (4B + 30 × (20B + 12B)) ≈ 10 × 964B ≈ 9.6kB
- `tasks[1..3]`: 3 × (4B + 10 × 36B) ≈ 1.1kB
- **Yhteensä:** ~19kB — ok OpenPLC:lle (128MB+ muistia)

---

#### Vaihe 2.3: DEP_FB_CalcIdleSlots — idle-slot-laskenta

**Tiedosto:** `openplc/OpenPLC/src/DEP_FB_CalcIdleSlots.st`

Laskee tyhjäkäynti-ikkunat nostimen tehtäväjonosta. Jokainen aikaväli jossa nostin EI suorita tehtävää on idle-slot.

**Lähde:** `transporterTaskScheduler.js:calculateTransporterIdleSlots()`

```
Syöte:  g_tasks[trans].queue (lajiteltu start_time mukaan)
Tulos:  g_dep_idle_slots[trans].slots[1..N], .count

Logiikka:
  slot_1: [now .. task_1.start_time]     (nostin idle ennen ensimmäistä tehtävää)
  slot_2: [task_1.finish .. task_2.start] (gap tehtävien välissä)
  ...
  slot_N: [task_last.finish .. INF]       (nostin idle viimeisen jälkeen)
```

**VAR_EXTERNAL:** `g_tasks`, `g_dep_idle_slots`
**VAR_INPUT:** `i_trans : INT`, `i_time_s : REAL`
**Arvio:** ~60 riviä

---

#### Vaihe 2.4: DEP_FB_FitTaskToSlot — tehtävän sovitus idle-slottiin

**Tiedosto:** `openplc/OpenPLC/src/DEP_FB_FitTaskToSlot.st`

Sovittaa odottavan erän siirron idle-slottiin, huomioiden matka-aika nykyiseltä asemalta lift-asemalle.

**Lähde:** `transporterTaskScheduler.js:fitSingleTaskToIdleSlots()`

```
Syöte:  lift_stn, sink_stn, unit, time_s
        g_dep_idle_slots[1..3] (kaikki nostimet)
        g_move (siirtoajat)
Tulos:  DEP_FIT_RESULT_T (fits, delay_s, trans_id, slot_idx)

Logiikka per nostin:
  1. Tarkista STC_FB_FindTransporter — voiko nostin käsitellä parin
  2. Loop idle-slotit: mahtuuko tehtävä aikaikkunaan
  3. Laske matka-aika nostin→lift + lift→sink
  4. Jos mahtuu → paras fit (pienin viive)
  5. Palauta paras tulos
```

**Sisäiset kutsut:** `STC_FB_FindTransporter`, `STC_FB_CalcTransferTime`, `STC_FB_CalcHorizontalTravel`
**Arvio:** ~120 riviä

---

#### Vaihe 2.5: DEP_FB_CalcOverlap — overlap-asemien laskenta

**Tiedosto:** `openplc/OpenPLC/src/DEP_FB_CalcOverlap.st`

Laskee asemat joissa useampi nostin voi toimia (task_area:t menevät päällekkäin).

**Lähde:** `departureScheduler.js:computeOverlapStations()`

```
Syöte:  g_cfg[1..3].task_area[1..4]
Tulos:  g_dep_overlap.flags[101..125], .count

Logiikka:
  1. Per asema 101..125: laske kuinka monta nostinta kattaa sen
  2. Jos ≥2 nostinta → overlap = TRUE
```

**Arvio:** ~50 riviä

---

#### Vaihe 2.6: DEP_FB_OverlapDelay — overlap-viiveen laskenta

**Tiedosto:** `openplc/OpenPLC/src/DEP_FB_OverlapDelay.st`

Jos uusi tehtävä menee overlap-asemalle, tarkistaa aikakonfliktit toisen nostimen tehtävien kanssa.

**Lähde:** `departureScheduler.js:calculateOverlapDelay()`

```
Syöte:  lift_stn, sink_stn, task_start_s, task_end_s,
        g_tasks[1..3] (olemassaolevat tehtävät), g_dep_overlap
Tulos:  delay_s : REAL (lisäviive overlap-konfliktin vuoksi)

Logiikka:
  1. Tarkista overlap-flagit lift ja sink -asemille
  2. Jos overlap: etsi ristiin ajoitetut tehtävät toisilla nostimilla
  3. Laske minimaalinen viive jolla konflikti vältetään
```

**Arvio:** ~80 riviä

---

#### Vaihe 2.7: DEP_FB_Sandbox — sandbox-hallinta

**Tiedosto:** `openplc/OpenPLC/src/DEP_FB_Sandbox.st`

Kopioi globaalit → sandbox tai sandbox → globaalit. Korvaa JS:n `_copyDepartureSandbox()`.

```
VAR_INPUT:
  i_cmd : INT;   (* 1=SNAPSHOT (globals→sandbox), 2=RESTORE (sandbox→globals), 3=CLEAR *)
VAR_EXTERNAL:
  g_batches, g_programs, g_schedule, g_tasks  (globaalit)
  g_dep_sandbox                                (sandbox)

Logiikka cmd=1 (SNAPSHOT):
  FOR u := 1 TO 10 DO
    g_dep_sandbox.batches[u]  := g_batches[u];
    g_dep_sandbox.schedule[u] := g_schedule[u];
    g_dep_sandbox.programs[u] := g_programs[u];
  END_FOR;
  FOR t := 1 TO 3 DO
    g_dep_sandbox.tasks[t] := g_tasks[t];
  END_FOR;
  g_dep_sandbox.valid := TRUE;

Logiikka cmd=2 (RESTORE): käänteinen kopiointi
```

> **ST-etu:** Struct-kopio `a := b;` kopioi kaikki kentät — ei tarvita kenttäkohtaista kopiointia kuten JS:ssä.

**Arvio:** ~60 riviä

---

#### Vaihe 2.8: DEP_FB_Scheduler — päätilakone

**Tiedosto:** `openplc/OpenPLC/src/DEP_FB_Scheduler.st`

Suurin yksittäinen lohko. Tilakone noudattaa JS:n faaseja yksinkertaistettuna:

```
Faasit:

  0     STOPPED
  1     WAIT_FOR_STABLE  (odota g_dep_stable = TRUE)
  
  100   INIT             (laske odottavat erät, snapshot sandbox)
  
  1000  CALC_START       (laske overlap-asemat)
  1001  CALC_SCHEDULES   (laske sandbox-aikataulut per erä — yksi/tick)
  1010  CALC_TASKS       (luo sandbox-tehtävät per erä — yksi/tick)
  1020  CALC_SORT        (lajittele sandbox-tehtävät)
  1030  CALC_IDLE_SLOTS  (laske idle-slotit per nostin)

  2000  FIT_START        (aloita odottavien erien sovitus)
  2001  FIT_BATCH        (sovita yksi erä idle-slottiin — yksi/tick)
  2010  FIT_DELAY_CHECK  (tarkista overlap-viiveet)
  2020  FIT_RECALC       (laske uudelleen jos viiveitä)
  2090  FIT_DONE

  3000  ACTIVATE         (kopioi sandbox → globaalit, aseta g_dep_pending)
  3001  WAIT_SAVE        (odota TSK prosessoi pending-kirjoitukset)
  
  4000  END_DELAY        (pieni viive ennen uutta kierrosta)
  4100  RESTART          (palaa 1:een)
  
  9000  REJECT           (hylkää sandbox, palaa odotukseen)
```

**Sub-FB-instanssit DEP_FB_Scheduler:ssä:**
```st
VAR
  (* STC_ jaetut *)
  fb_calc_schedule  : TSK_FB_CalcSchedule;    (* aikataulun laskenta *)
  fb_create_tasks   : TSK_FB_CreateTasks;     (* tehtävälistan rakennus *)
  fb_swap_tasks     : TSK_FB_SwapTasks;       (* same-station swap *)
  fb_find_trans     : STC_FB_FindTransporter; (* nostin-haku *)
  fb_calc_xfer      : STC_FB_CalcTransferTime;(* siirtoaika *)
  fb_calc_travel    : STC_FB_CalcHorizontalTravel;
  (* DEP_ omat *)
  fb_idle_slots     : DEP_FB_CalcIdleSlots;
  fb_fit_task       : DEP_FB_FitTaskToSlot;
  fb_overlap        : DEP_FB_CalcOverlap;
  fb_overlap_delay  : DEP_FB_OverlapDelay;
  fb_sandbox        : DEP_FB_Sandbox;
END_VAR
```

**Sandbox-arkkitehtuuri PLC:ssä:**

JS:ssä sandbox on kopio jota muokataan ja sitten aktivoidaan tai hylätään. PLC:ssä:

1. **SNAPSHOT (faasi 100):** `fb_sandbox(i_cmd := 1)` — kopioi `g_schedule`, `g_batches`, `g_programs`, `g_tasks` → `g_dep_sandbox`
2. **LASKENTA (1000–2090):** Kaikki laskenta tehdään `g_dep_sandbox.*`-datalla
   - TSK_FB_CalcSchedule kirjoittaa `g_dep_sandbox.schedule[u]`:hin (ei `g_schedule[u]`)
   - Tämä vaatii CalcSchedule:n laajennuksen: **uusi VAR_INPUT `i_use_sandbox : BOOL`** tai erillinen `DEP_FB_CalcSchedule` -wrapper
3. **ACTIVATE (3000):** Kopioi `g_dep_sandbox` → globaalit + aseta pending-kirjoitukset
4. **REJECT (9000):** Hylkää sandbox → ei kopiointia

**⚠ KRIITTINEN SUUNNITTELUPÄÄTÖS: CalcSchedule sandbox-tuki**

Kaksi vaihtoehtoa:

**A) Wrapper-lähestymistapa** (suositeltu):
```st
(* DEP_FB_Scheduler sisällä, sandbox-schedule-laskenta: *)
(* 1. Kopioi sandbox-data → globaalit tilapäisesti *)
(* 2. Kutsu TSK_FB_CalcSchedule (joka kirjoittaa g_schedule) *)
(* 3. Kopioi tulos → sandbox *)
(* 4. Palauta globaalit *)
```
→ Ei vaadi TSK_FB_CalcSchedule:n muuttamista, mutta vaatii tilapäisen kopioinnin.

**B) Parametrisoitu lähestymistapa:**
TSK_FB_CalcSchedule saa uuden `i_sandbox : BOOL` -parametrin joka vaihtaa kohdetaulukon.
→ Muuttaa olemassaolevaa FB:tä mutta eleganttimpi.

> **Suositus:** Vaihtoehto A. Se pitää TSK_-lohkot muuttumattomina ja siirtää sandbox-logiikan DEP_-puolelle.

**Arvio:** ~400–500 riviä (suurin yksittäinen FB)

---

#### Vaihe 2.9: TSK↔DEP handshake (plc_prg.st)

Lisätään `plc_prg.st`:iin DEP_FB_Scheduler ja synkronointilogiikka:

```st
(* -- plc_prg.st VAR-lohkoon -- *)
dep_sched : DEP_FB_Scheduler;

(* -- MAIN TRANSPORT CYCLE -lohkoon, tsk_sched-kutsun jälkeen -- *)
(* Departure scheduler: ajetaan joka syklillä *)
(* TSK asettaa g_dep_stable kun tehtävälista on valmis *)
g_dep_stable := (tsk_sched.o_phase = 10000) OR (tsk_sched.o_phase = 10110);
dep_sched(i_run := init_done, i_time_s := g_time_s);
```

**Tehtävät:**
1. 🔧 Lisää `dep_sched`-instanssi `plc_prg.st` VAR-lohkoon
2. 🔧 Lisää DEP-globaalit VAR_EXTERNAL-lohkoon
3. 🔧 Lisää synkronointilogiikka + dep_sched-kutsu
4. 🧪 Build + deploy + testaa kaksoisajoa

---

#### Vaihe 2.10: ACTIVATE → TSK pending kirjoitus

Kun DEP aktivoi erän, `g_dep_pending` sisältää:
- Päivitetyt aikataulut
- Päivitetyt ohjelma-stapet (jos viiveitä)
- Batch-stage-muutos

TSK_FB_Scheduler tarkistaa `g_dep_pending.valid`:
1. Jos TRUE → kopioi pending-data globaaleihin
2. Aseta `g_dep_pending.valid := FALSE`
3. Uudelleenlaskee tehtävälistan

**Muokkaus `TSK_FB_Scheduler.st`:iin** — uusi faasi 10100:

```st
(* PHASE 10100: CHECK_DEP_PENDING — DEP has activated a batch *)
ELSIF phase = 10100 THEN
  IF g_dep_pending.valid THEN
    (* Kopioi DEP:n pending-data globaaleihin *)
    FOR ui := 1 TO 10 DO
      g_schedule[ui] := g_dep_pending.schedule[ui];
      g_programs[ui] := g_dep_pending.programs[ui];
    END_FOR;
    IF g_dep_pending.batch_unit >= 1 AND g_dep_pending.batch_unit <= 10 THEN
      g_batches[g_dep_pending.batch_unit].cur_stage := g_dep_pending.batch_stage;
    END_IF;
    g_dep_pending.valid := FALSE;
    g_dep_activated := TRUE;
    next_phase := 1;   (* → INIT: täysi uudelleenlaskenta *)
  ELSE
    next_phase := 10110; (* → RESTART: normaali sykli *)
  END_IF;
```

**Tehtävät:**
1. 🔧 Lisää DEP-globaalit TSK_FB_Scheduler VAR_EXTERNAL-lohkoon
2. 🔧 Lisää faasi 10100 (READY → CHECK_DEP → RESTART)
3. 🧪 Testaa aktivointi end-to-end

---

### Toteutusjärjestys (vaiheet kokonaisuutena)

```
Osa 1 (jaetut funktiot):
  1.1 STC_FB_CalcTransferTime   ─┐
  1.2 STC_FB_FindTransporter    ─┼─ Rinnakkain toteutettavissa
  1.4 STC_FB_CalcHorizontalTravel┘
  1.3 Uudelleennimeäminen       ──── Tämän jälkeen
  1.5 Kokonaisvalidointi         ──── Lopuksi build+deploy+test

Osa 2 (departure):
  2.1 Tyypit (types.st)         ─┐
  2.2 Globaalit (globals.st)    ─┘── Ensin pohja kuntoon
  2.3 DEP_FB_CalcIdleSlots      ──── Ensimmäinen uusi FB
  2.4 DEP_FB_FitTaskToSlot      ──── Käyttää 2.3:a
  2.5 DEP_FB_CalcOverlap        ─┐
  2.6 DEP_FB_OverlapDelay       ─┘── Rinnakkain
  2.7 DEP_FB_Sandbox            ──── Sandbox-infra
  2.8 DEP_FB_Scheduler          ──── Päätilakone (SUURIN)
  2.9 plc_prg.st integraatio    ──── Kytkentä
  2.10 TSK↔DEP handshake        ──── Lopullinen synkronointi
```

---

### Riippuvuuskaavio

```
STC_FB_CalcTransferTime ──────┐
STC_FB_FindTransporter ───────┤
STC_FB_CalcHorizontalTravel ──┤
                              ▼
                    ┌─────────────────┐
                    │  TSK_ FB:t      │
                    │ (päivitetty     │
                    │  käyttämään     │
                    │  STC_-kutsuja)  │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  DEP_FB_CalcIdleSlots  DEP_FB_CalcOverlap  DEP_FB_Sandbox
         │                   │
         ▼                   ▼
  DEP_FB_FitTaskToSlot  DEP_FB_OverlapDelay
         │                   │
         └─────────┬─────────┘
                   ▼
           DEP_FB_Scheduler
                   │
                   ▼
        ┌──────────────────┐
        │  plc_prg.st      │
        │  TSK↔DEP handsh. │
        └──────────────────┘
```

---

### Tiedostoluettelo lopullinen (kaikki ST-tiedostot Osa 1 + 2 jälkeen)

```
openplc/OpenPLC/src/
├── types.st                      (* + DEP_ tyypit *)
├── globals.st                    (* + DEP_ globaalit *)
├── config.st
├── plc_prg.st                    (* + dep_sched instanssi *)
│
├── STC_FB_CalcTransferTime.st    ← UUSI (Osa 1)
├── STC_FB_CalcHorizontalTravel.st← UUSI (Osa 1)
├── STC_FB_FindTransporter.st     ← UUSI (Osa 1)
├── STC_FB_MeasureMoveTimes.st    ← NIMETTY UUDELLEEN (FB_TimeMoves)
├── STC_FB_FindStation.st         ← NIMETTY UUDELLEEN (fb_station_lookup)
│
├── TSK_FB_Scheduler.st           (* + DEP pending check *)
├── TSK_FB_CalcSchedule.st        (* käyttää STC_-kutsuja *)
├── TSK_FB_CreateTasks.st         (* käyttää STC_-kutsuja *)
├── TSK_FB_SwapTasks.st
├── TSK_FB_Analyze.st             (* käyttää STC_-kutsuja *)
├── TSK_FB_Resolve.st
├── TSK_FB_NoTreatment.st         (* käyttää STC_-kutsuja *)
│
├── DEP_FB_Scheduler.st           ← UUSI (Osa 2)
├── DEP_FB_CalcIdleSlots.st       ← UUSI (Osa 2)
├── DEP_FB_FitTaskToSlot.st       ← UUSI (Osa 2)
├── DEP_FB_CalcOverlap.st         ← UUSI (Osa 2)
├── DEP_FB_OverlapDelay.st        ← UUSI (Osa 2)
├── DEP_FB_Sandbox.st             ← UUSI (Osa 2)
│
├── TWA_FB_CalcLimits.st
├── TWA_CalcPriority.st
├── SIM_FB_XMotion.st
├── SIM_FB_ZMotion.st
└── clear_config.st
```

**Yhteensä:** 27 tiedostoa (nykyiset 18 + 3 STC + 6 DEP)

---

### Työarvio yhteenveto

| Vaihe | Kuvaus | Rivit | Aika |
|-------|--------|-------|------|
| **1.1** | STC_FB_CalcTransferTime + integraatio | ~35 + refaktori | 1h |
| **1.2** | STC_FB_FindTransporter + integraatio | ~40 + refaktori | 1h |
| **1.3** | Uudelleennimeäminen | ~0 uutta | 0.5h |
| **1.4** | STC_FB_CalcHorizontalTravel + integraatio | ~25 + refaktori | 0.5h |
| **1.5** | Kokonaisvalidointi | — | 1h |
| **2.1** | DEP_ tyypit | ~80 | 0.5h |
| **2.2** | DEP_ globaalit | ~20 | 0.5h |
| **2.3** | DEP_FB_CalcIdleSlots | ~60 | 1.5h |
| **2.4** | DEP_FB_FitTaskToSlot | ~120 | 2.5h |
| **2.5** | DEP_FB_CalcOverlap | ~50 | 1h |
| **2.6** | DEP_FB_OverlapDelay | ~80 | 1.5h |
| **2.7** | DEP_FB_Sandbox | ~60 | 1h |
| **2.8** | DEP_FB_Scheduler (päätilakone) | ~400–500 | 4–6h |
| **2.9** | plc_prg.st integraatio | ~20 | 0.5h |
| **2.10** | TSK↔DEP handshake | ~40 | 1h |
| | **YHTEENSÄ** | **~1100–1200** | **~18–22h** |

---

## Huomautukset

- **Toiminnallisuus ei saa muuttua** — jokainen vaihe tulee testata Docker-ympäristössä
- DA on kriittisin vaihe: sandbox hash map -konversio koskettaa lähes kaikkia DEPARTURE-faaseja
- DF-vaihe on jaettu taskScheduler-konversion kanssa — toteutetaan kerran
- `_schedulesToHashMap()` ja `_programsToHashMap()` muuntimet poistetaan kun DA + DF ovat valmiit
- `computeOverlapStations()` on departure-spesifinen funktio joka tarvitsee `task_areas`-konfiguraation PLC-rakenteen
- ACTIVATE:n debug-snapshot (`fs.writeFileSync`) on hyödyllinen kehityksessä mutta poistetaan PLC-versiossa
- **Osa 1 tulee tehdä ENSIN** — STC_-lohkot ovat edellytys Osa 2:lle
- **Uudelleennimeäminen (1.3) on valinnainen** ja voidaan lykätä — toiminnallisuus ei riipu siitä
- **Sandbox wrapper (2.8 lähestymistapa A)** pitää TSK_-lohkot muuttumattomina — suositeltavaa
