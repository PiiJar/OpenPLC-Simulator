/**
 * DepartureScheduler - Lähtölupalaskennan tilakone
 * 
 * ERILLINEN TILAKONE joka synkronoidaan TASKS-tilakoneen (taskScheduler.js) kanssa.
 * 
 * SYNKRONOINTI:
 * - Odottaa TASKS-tilakoneen valmistumista (phase = READY tai SAVE)
 * - Ei aloita uutta laskentaa ennen kuin TASKS on stabiloitunut
 * - END_DELAY (100 tickiä) VAIN onnistuneen aktivoinnin jälkeen
 * - Epäonnistuneen/hylätyn laskennan jälkeen palataan suoraan WAITING_FOR_TASKS
 * 
 * IDLE-SLOT SOVITUS (departure_target_description.md):
 * - Sovittelee odottavan erän nostimien tyhjäkäynti-ikkunoihin
 * - Linjalla jo olevien erien aikatauluja EI muuteta
 * - Ensimmäisen tehtävän ajoitus: idle_start + travel → min/max (ei program min/max)
 * - max_initial_wait_s rajaa 1. tehtävän odotuksen
 * - flex_up_factor kertoo kuinka paljon joustosta käytetään (oletus 50%)
 * - Jos tehtävä ei mahdu omalla flex_up:lla → backward chaining aiempiin tehtäviin
 * - Yksi viive per kierros: kirjaa, palauta WAITING_FOR_TASKS, seuraava kierros laskee uudestaan
 * - Kaikki mahtuvat → ACTIVATE
 * 
 * Vaiherakenne:
 *   0:         WAITING_FOR_TASKS (odottaa TASKS-koneen valmistumista)
 *   100:       INIT (alusta departure-laskenta, lue context)
 *   1000:      DEPARTURE_CALC_START (kerää stage 90 erät)
 *   1001-1099: DEPARTURE_CALC (laske aikataulut per erä)
 *   1900:      DEPARTURE_CALC_DONE
 *   2000:      WAITING_SORT_START
 *   2001:      WAITING_SORT_LOADED (järjestä loaded_s mukaan)
 *   2900:      WAITING_SORT_DONE
 *   3000:      CHECK_START (aloita lähtöluparkistus)
 *   3001:      CHECK_CREATE_TASKS
 *   3002:      CHECK_SORT
 *   3003:      CHECK_SWAP
 *   3004:      CHECK_ANALYZE
 *   3005:      CHECK_RESOLVE
 *   3006:      CHECK_UPDATE_PROGRAM
 *   3007:      CHECK_RECALC_SCHEDULE
 *   3008:      CHECK_RECALC_TASKS
 *   3090:      ACTIVATE (aktivoi erä, store pending data)
 *   3091:      WAIT_FOR_SAVE (wait for TASKS SAVE to write pending data)
 *   4000:      END_DELAY_START (100 tyhjää tickiä)
 *   4100:      END_DELAY_END
 *   4101:      RESTART (palaa odottamaan)
 * 
 * @module departureScheduler
 */

const scheduler = require('./transporterTaskScheduler');
const fs = require('fs');
const path = require('path');

// ═══════════════════════════════════════════════════════════════════════════════
// VAKIOT
// ═══════════════════════════════════════════════════════════════════════════════

const PHASE = {
    WAITING_FOR_TASKS: 0,
    INIT: 100,
    DEPARTURE_CALC_START: 1000,
    DEPARTURE_CALC_END: 1099,
    DEPARTURE_CALC_DONE: 1900,
    WAITING_SORT_START: 2000,
    WAITING_SORT_LOADED: 2001,
    WAITING_SORT_DONE: 2900,
    CHECK_START: 3000,
    CHECK_CREATE_TASKS: 3001,
    CHECK_SORT: 3002,
    CHECK_SWAP: 3003,
    CHECK_ANALYZE: 3004,
    CHECK_RESOLVE: 3005,
    CHECK_UPDATE_PROGRAM: 3006,
    CHECK_RECALC_SCHEDULE: 3007,
    CHECK_RECALC_TASKS: 3008,
    ACTIVATE: 3090,
    WAIT_FOR_SAVE: 3091,
    END_DELAY_START: 4000,
    END_DELAY_END: 4100,
    RESTART: 4101
};

const END_DELAY_TICKS = 100;  // 100 tyhjää tickiä stabilointia varten
const MAX_WAITING_BATCHES = 20;

// ═══════════════════════════════════════════════════════════════════════════════
// TILAKONE - TILA (säilyy tikien välillä)
// ═══════════════════════════════════════════════════════════════════════════════

const state = {
    phase: 0,
    
    // Synkronointi TASKS-tilakoneen kanssa
    tasksPhase: 0,           // TASKS-tilakoneen nykyinen vaihe
    lastTasksReadyTick: 0,   // Viimeisin tick jolloin TASKS oli READY
    
    // Cycle timing statistics (sama rakenne kuin taskScheduler)
    cycleStartTime: 0,       // Date.now() kun sykli alkaa
    cycleStartTick: 0,       // simTick kun sykli alkaa
    cycleTickCount: 0,       // tickit tässä syklissä
    cycleTickPeriodMs: 0,    // tick-jakso (2× BASE_DT_MS koska vuorottelu)
    totalCycles: 0,
    lastCycleTimeMs: 0,
    lastCycleTicks: 0,
    lastCycleSimTimeMs: 0,
    longestCycleTimeMs: 0,
    longestCycleTicks: 0,
    cycleHistory: [],        // wall-clock ms per cycle (max 1000)
    cycleTickHistory: [],    // ticks per cycle (max 1000)
    cycleSimTimeHistory: [], // sim-time ms per cycle (max 1000)
    
    // Kierroksen data (kopioidaan INIT:ssä)
    batches: [],
    stations: [],
    transporters: [],
    transporterStates: [],
    
    // Tulokset
    schedulesByBatchId: {},
    programsByBatchId: {},
    waitingSchedules: {},
    waitingBatchAnalysis: {},
    waitingBatchTasks: {},
    
    // Lähtölupalaskenta
    waitingBatches: [],
    waitingBatchCount: 0,
    currentWaitingIndex: 0,
    allCalcBatches: [],
    allCalcCount: 0,
    currentCalcIndex: 0,
    departureSandbox: null,
    sandboxSnapshot: null,
    combinedTasks: [],
    departureAnalysis: null,
    departureCandidateStretches: [],
    candidateStretches: [],
    pendingDelay: null,
    pendingDelays: [],
    departureLockedStages: {},
    
    // Handshake TASKS-tilakoneen kanssa
    // PLC-vastine: DB-bitti jonka FB_DEPARTURE asettaa ja FB_TASKS lukee
    activatedThisCycle: false,
    pendingWriteData: { valid: false },  // Data waiting for TASKS SAVE to write (PLC: fixed struct + valid flag)
    
    // Konfiguraatio
    waitingBatchMaxCount: 20,
    departureMaxIterations: 50,
    departureConflictMarginSec: 1,
    departureIteration: 0,
    
    // Tavoitetilan parametrit (departure_target_description.md)
    maxInitialWaitS: 120,    // max_initial_wait_s: suurin sallittu odotus 1. tehtävän alkuun
    flexUpFactor: 0.5,       // flex_up_factor: kerroin jolla MaxTime-CalcTime jousto käytössä
    
    // Kierroksittainen eteneminen (target): DEPARTURE-kierrosten välinen tila
    departureRound: 0,       // Monesko sovittelukierros tälle erälle (0 = ensimmäinen)
    
    // Statistiikka
    departureTimes: [],
    avgDepartureIntervalSec: 0,
    lastDepartureConflict: null,
    finalDepartureConflict: null,
    departureCheckResultsSummary: null,
    
    // END_DELAY laskuri
    endDelayCounter: 0,
    
    // Debug
    phaseLog: []
};

// ═══════════════════════════════════════════════════════════════════════════════
// KONTEKSTI
// ═══════════════════════════════════════════════════════════════════════════════

let ctx = {};

// ═══════════════════════════════════════════════════════════════════════════════
// APUFUNKTIOT
// ═══════════════════════════════════════════════════════════════════════════════

function log(msg) {
    state.phaseLog.push({ phase: state.phase, msg, time: Date.now() });
    if (state.phaseLog.length > 100) state.phaseLog.shift();
    console.log(`[DEPARTURE ${state.phase}] ${msg}`);
}

/**
 * Laske overlap-asemat: asemat joissa USEAMPI nostin voi toimia.
 * Vertaa jokaisen nostimen task_areas-alueita (lift + sink) ja etsii
 * asemanumerot jotka kuuluvat vähintään kahden eri nostimen alueisiin.
 * 
 * @param {Array} transporters - Nostimet task_areas-tiedoilla
 * @returns {Set<number>} Overlap-asemanumerot
 */
function computeOverlapStations(transporters) {
    const stationCoverage = new Map(); // station number → Set<transporter id>
    for (const t of transporters) {
        if (!t.task_areas) continue;
        for (const area of Object.values(t.task_areas)) {
            const ranges = [
                [area.min_lift_station || 0, area.max_lift_station || 0],
                [area.min_sink_station || 0, area.max_sink_station || 0]
            ];
            for (const [min, max] of ranges) {
                if (min > 0 && max > 0) {
                    for (let n = min; n <= max; n++) {
                        if (!stationCoverage.has(n)) stationCoverage.set(n, new Set());
                        stationCoverage.get(n).add(t.id);
                    }
                }
            }
        }
    }
    const overlapStations = new Set();
    for (const [station, tIds] of stationCoverage) {
        if (tIds.size > 1) overlapStations.add(station);
    }
    return overlapStations;
}

/**
 * Laske overlap-alueen viive yksittäiselle tehtävälle.
 * 
 * Jos tehtävä käyttää overlap-asemaa (nosto- tai laskuasema), tarkistaa
 * ettei mikään TOISEN nostimen tehtävä overlap-alueella ole samaan aikaan.
 * Jos konflikti löytyy, palauttaa tarvittavan viiveen (sekuntia) jotta
 * tehtävä voidaan aloittaa konfliktin jälkeen.
 * 
 * @param {Object} task - Tehtävä (lift_station_id, sink_station_id, transporter_id, task_start_time, task_finished_time)
 * @param {number} cumulativeShift - Kumulatiivinen viive aiemmista stageista
 * @param {Array} existingTasks - Olemassa olevat tehtävät (linja-erien)
 * @param {Set<number>} overlapStations - Overlap-asemanumerot
 * @param {number} [marginSec=2] - Turvamarginaali (sekuntia)
 * @returns {number} Tarvittava lisäviive (0 = ei konfliktia)
 */
function calculateOverlapDelay(task, cumulativeShift, existingTasks, overlapStations, marginSec) {
    if (!overlapStations || overlapStations.size === 0) return 0;
    
    const isOverlap = overlapStations.has(task.lift_station_id) || overlapStations.has(task.sink_station_id);
    if (!isOverlap) return 0;
    
    const taskDuration = task.task_finished_time - task.task_start_time;
    const tId = task.transporter_id;
    const margin = marginSec || 2;
    let adjustedStart = task.task_start_time + cumulativeShift;
    
    // Iteratiivinen haku: etsi ensimmäinen konfliktiton aikaikkuna (max 20 kierrosta)
    for (let iter = 0; iter < 20; iter++) {
        const adjustedEnd = adjustedStart + taskDuration;
        let foundConflict = false;
        let latestConflictEnd = adjustedStart;
        
        for (const existing of existingTasks) {
            if (existing.transporter_id === tId) continue;
            
            // Tarkista käyttääkö olemassa oleva tehtävä overlap-asemaa
            if (!overlapStations.has(existing.lift_station_id) && !overlapStations.has(existing.sink_station_id)) {
                continue;
            }
            
            // Aikakonflikti: tehtävät limittyvät ajallisesti (marginaalilla)
            if (adjustedStart < existing.task_finished_time + margin &&
                adjustedEnd > existing.task_start_time - margin) {
                foundConflict = true;
                latestConflictEnd = Math.max(latestConflictEnd, existing.task_finished_time + margin);
            }
        }
        
        if (!foundConflict) break;
        adjustedStart = latestConflictEnd;
    }
    
    return Math.max(0, adjustedStart - (task.task_start_time + cumulativeShift));
}

function summarizeTasks(label, tasks) {
    const byBatch = new Map();
    for (const t of tasks || []) {
        const key = `B${t.batch_id}`;
        if (!byBatch.has(key)) byBatch.set(key, { count: 0, stages: new Set() });
        const entry = byBatch.get(key);
        entry.count++;
        entry.stages.add(t.stage);
    }
    const summary = [...byBatch.entries()]
        .map(([key, info]) => `${key}:${info.count} s[${[...info.stages].sort((a, b) => a - b).join(',')}]`)
        .join('; ');
    console.log(`${label}: ${(tasks || []).length} tasks${summary ? ` (${summary})` : ''}`);
}

/**
 * Calculate schedule for a waiting batch (stage 0 pre-calc + full schedule).
 * Called from CHECK_CREATE_TASKS — each waiting batch gets its own schedule.
 * Uses sandbox line tasks for idle-slot calculation.
 */
function calculateWaitingBatchSchedule(batch, batchId) {
    const program = state.programsByBatchId[String(batchId)];
    if (!program) return null;
    
    const transporter = state.transporters[0];
    const now = ctx.currentTimeSec || 0;
    const baseTime = now;
    
    // 1. Line tasks from sandbox + in-flight
    const lineTasks = [...(state.departureSandbox?.tasks || [])];
    if (state._inFlightTasks && state._inFlightTasks.length > 0) {
        lineTasks.push(...state._inFlightTasks);
    }
    
    // 2. Find stage 0 transporter
    const firstStageStation = parseInt(program[0]?.min_station, 10);
    const batchLoc = ctx.getBatchLocation(batch.batch_id);
    const pickupStation = scheduler.findStation(batchLoc, state.stations);
    let stage0Transporter = null;
    for (const t of state.transporters) {
        if (scheduler.canTransporterHandleTask(t, batchLoc, firstStageStation)) {
            stage0Transporter = t;
            break;
        }
    }
    if (!stage0Transporter) stage0Transporter = transporter;
    
    // 3. Idle slots for stage 0 transporter
    const tId = stage0Transporter.id;
    const idleSlots = scheduler.calculateTransporterIdleSlots(tId, lineTasks, now);
    
    // 4. Stage 0 calc time from idle slot + travel
    const maxInitWait = state.maxInitialWaitS || 120;
    let stage0CalcTime = 0;
    for (const slot of idleSlots) {
        if (slot.end <= now) continue;
        let travelToPickup = 0;
        if (pickupStation) {
            let fromStation = null;
            if (slot.prevTask) {
                fromStation = scheduler.findStation(slot.prevTask.sink_station_id, state.stations);
            } else {
                const tCurrentState = (ctx.transporterStates || []).find(ts => ts.id === tId);
                const currentX = tCurrentState?.state?.x_position;
                if (currentX != null && Number.isFinite(currentX)) {
                    fromStation = { number: -1, x_position: currentX };
                } else if (stage0Transporter.start_station) {
                    fromStation = scheduler.findStation(stage0Transporter.start_station, state.stations);
                }
            }
            if (fromStation && fromStation.number !== pickupStation.number) {
                if (fromStation.number === -1) {
                    travelToPickup = scheduler.calculateHorizontalTravelTime(
                        fromStation, pickupStation, stage0Transporter
                    );
                } else {
                    const transfer = scheduler.calculateTransferTime(
                        fromStation, pickupStation, stage0Transporter,
                        ctx.movementTimes || null
                    );
                    travelToPickup = transfer?.phase3_travel_s ?? 0;
                }
            }
        }
        const pickupTime = Math.max(slot.start, now) + travelToPickup;
        const waitTime = pickupTime - now;
        if (waitTime > maxInitWait) continue;
        stage0CalcTime = waitTime;
        break;
    }
    
    // 5. Write stage 0 times to batch
    const s0min = stage0CalcTime;
    const s0max = Math.max(s0min, 2 * s0min);
    batch.calc_time_s = stage0CalcTime;
    batch.min_time_s = s0min;
    batch.max_time_s = s0max;
    log(`CHECK B${batchId}: stage 0 pre-calc → calc=${stage0CalcTime.toFixed(1)}s, min=${s0min.toFixed(1)}s, max=${s0max.toFixed(1)}s (T${tId}, ${idleSlots.length} idle-slots)`);
    
    // 6. Calculate full schedule
    const existingSchedules = Object.entries(state.schedulesByBatchId)
        .filter(([id]) => id !== String(batchId))
        .map(([, sched]) => sched);
    const occupiedStations = new Set(
        (ctx.units || [])
            .filter(u => u.batch_id != null && u.batch_id !== batch.batch_id && u.location > 0)
            .map(u => u.location)
    );
    const batchLocForCalc = ctx.getBatchLocation(batch.batch_id);
    const isOnTransporter = batchLocForCalc != null && batchLocForCalc < 100;
    let calcTransporterState = null;
    if (isOnTransporter) {
        const tState = (ctx.transporterStates || []).find(t => t.id === batchLocForCalc);
        if (tState) calcTransporterState = tState;
    }
    
    try {
        const scheduleResult = scheduler.calculateBatchSchedule(
            batch, program, state.stations,
            isOnTransporter ? (state.transporters.find(t => t.id === batchLocForCalc) || transporter) : transporter,
            baseTime, batch.isDelayed, calcTransporterState,
            {
                movementTimes: ctx.movementTimes || null,
                lineSchedules: existingSchedules,
                occupiedStations: occupiedStations,
                stationIdleSince: ctx.stationIdleSince || new Map(),
                units: ctx.units || []
            }
        );
        
        if (scheduleResult) {
            scheduleResult.batchStage = batch.stage;
            scheduleResult.dynamicOffsetSec = baseTime - now;
            
            const stage0Sched = scheduleResult.stages?.find(s => s.stage === 0);
            if (stage0Sched) {
                const sandboxBatch = state.departureSandbox?.batches?.find(b => b.batch_id === batchId);
                if (sandboxBatch) {
                    sandboxBatch.calc_time_s = stage0Sched.treatment_time_s;
                    sandboxBatch.min_time_s = stage0Sched.min_time_s;
                    sandboxBatch.max_time_s = stage0Sched.max_time_s;
                }
                batch.calc_time_s = stage0Sched.treatment_time_s;
                batch.min_time_s = stage0Sched.min_time_s;
                batch.max_time_s = stage0Sched.max_time_s;
                log(`CHECK B${batchId}: stage 0 → calc=${stage0Sched.treatment_time_s.toFixed(1)}s, min=${stage0Sched.min_time_s.toFixed(1)}s, max=${stage0Sched.max_time_s.toFixed(1)}s`);
            }
            
            state.schedulesByBatchId[String(batchId)] = scheduleResult;
            state.departureSandbox.schedulesByBatchId[String(batchId)] = scheduleResult;
            state.waitingSchedules[String(batchId)] = scheduleResult;
        }
        return scheduleResult;
    } catch (err) {
        log(`CHECK B${batchId} schedule error: ${err.message}`);
        return null;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TICK - Pääsilmukka
// ═══════════════════════════════════════════════════════════════════════════════

async function tick(context) {
    ctx = context || {};
    
    const p = state.phase;
    let nextPhase = p;
    
    // Kasvata syklin tick-laskuria
    state.cycleTickCount++;
    
    // Päivitä TASKS-tilakoneen tila synkronointia varten
    state.tasksPhase = ctx.tasksPhase || 0;
    
    // DEBUG: Tulosta aina tick-tila
    console.log(`[DEPARTURE TICK] phase=${p} (${getPhaseName(p)}), tasksPhase=${state.tasksPhase}, simTick=${ctx.simTick || 0}`);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 0: WAITING_FOR_TASKS
    // Odota kunnes TASKS-tilakone on valmis (READY = 10000 tai SAVE = 10001)
    // ═══════════════════════════════════════════════════════════════════════════════
    if (p === PHASE.WAITING_FOR_TASKS) {
        const TASKS_READY = 10000;
        const TASKS_SAVE = 10001;
        const tasksConflictResolved = ctx.tasksConflictResolved || false;
        
        console.log(`[DEPARTURE] WAITING_FOR_TASKS: tasksPhase=${state.tasksPhase}, conflictResolved=${tasksConflictResolved}`);
        
        // DEPARTURE odottaa kunnes:
        // 1. TASKS on valmis (phase >= READY)
        // 2. TASKS:n konfliktianalyysi on stabiili (conflictResolved = true)
        // Stabiili lähtötilanne takaa luotettavat idle-slotit.
        if (state.tasksPhase >= TASKS_READY && tasksConflictResolved) {
            log(`TASKS ready & stable (phase=${state.tasksPhase}, conflictResolved=${tasksConflictResolved}), starting DEPARTURE cycle`);
            state.lastTasksReadyTick = ctx.simTick || 0;
            nextPhase = PHASE.INIT;
        } else if (state.tasksPhase >= TASKS_READY && !tasksConflictResolved) {
            console.log(`[DEPARTURE] TASKS ready but conflicts unresolved — waiting for stable state`);
        } else {
            console.log(`[DEPARTURE] Waiting for TASKS... (current: ${state.tasksPhase})`);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 100: INIT
    // Kopioi tarvittava data kontekstista
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.INIT) {
        log('INIT: Loading raw data from context (no schedules — DEPARTURE calculates them)');
        // Syklin ajoituksen aloitus
        state.cycleStartTime = Date.now();
        state.cycleStartTick = Number.isFinite(Number(ctx.simTick)) ? Number(ctx.simTick) : 0;
        state.cycleTickCount = 0;
        const periodMs = Number(ctx.tickPeriodMs);
        const dtMs = Number(ctx.tickDtMs);
        // Departure saa tickin joka toinen PLC-tick → efektiivinen jakso = 2×
        state.cycleTickPeriodMs = Number.isFinite(periodMs) ? periodMs * 2 : (Number.isFinite(dtMs) ? dtMs * 2 : 0);
        
        // Kopioi RAAKADATA kontekstista - DEEP COPY kaikelle!
        // PLC-vastine: FB:n IN-parametrit ovat aina kopioita DB:stä.
        // JavaScript-viitteet vaativat eksplisiittisen kopioinnin,
        // jotta departure ei mutatoi server.js:n live-dataa.
        //
        // HUOM: schedulesByBatchId EI kopioida TASKS:lta!
        // DEPARTURE laskee KAIKKI aikataulut itse DEPARTURE_CALC -vaiheessa.
        state.batches = ctx.batches ? JSON.parse(JSON.stringify(ctx.batches)) : [];
        state.stations = ctx.stations ? JSON.parse(JSON.stringify(ctx.stations)) : [];
        state.transporters = ctx.transporters ? JSON.parse(JSON.stringify(ctx.transporters)) : [];
        state.transporterStates = ctx.transporterStates ? JSON.parse(JSON.stringify(ctx.transporterStates)) : [];
        // schedulesByBatchId EI nollata tässä — API lukee sen suoraan.
        // Käytetään _calcSchedules-välimuistia laskennassa, korvataan atomisesti CALC_DONE:ssa.
        state._calcSchedules = {};
        
        // Säilytä odottavan erän sandboxin ohjelma ja batch-tiedot jos samaa erää jatketaan (round > 0)
        // Stage 0 viive kirjataan sandbox-batchin calc_time_s:ään, ja sen pitää säilyä
        // kierrosten välillä jotta seuraava kierros laskee aikataulun viiveen kanssa.
        const continuingBatchId = state._currentDepartureBatchId;
        let savedWaitingProgram = null;
        let savedWaitingBatchTimes = null;
        if (continuingBatchId && state.departureSandbox?.programsByBatchId?.[String(continuingBatchId)]) {
            savedWaitingProgram = JSON.parse(JSON.stringify(
                state.departureSandbox.programsByBatchId[String(continuingBatchId)]
            ));
            // Säilytä myös sandbox-batchin calc_time_s/min_time_s/max_time_s (stage 0 viive)
            const savedBatch = state.departureSandbox.batches?.find(b => b.batch_id === continuingBatchId);
            if (savedBatch) {
                savedWaitingBatchTimes = {
                    calc_time_s: savedBatch.calc_time_s,
                    min_time_s: savedBatch.min_time_s,
                    max_time_s: savedBatch.max_time_s
                };
            }
            log(`INIT: Säilytetään B${continuingBatchId} sandboxin ohjelma ja batch-ajat (round=${state.departureRound}, calc=${savedWaitingBatchTimes?.calc_time_s?.toFixed?.(1)}s)`);
        }
        
        state.programsByBatchId = ctx.programsByBatchId ? JSON.parse(JSON.stringify(ctx.programsByBatchId)) : {};
        
        // Luo puhdas sandbox (ei valmiita aikatauluja, ei TASKS:n taskeja)
        state.departureSandbox = {
            batches: JSON.parse(JSON.stringify(state.batches)),
            schedulesByBatchId: {},  // Lasketaan DEPARTURE_CALC:ssa
            programsByBatchId: JSON.parse(JSON.stringify(state.programsByBatchId)),
            tasks: []  // Rakennetaan schedulen pohjalta
        };
        
        // Palauta säilytetty ohjelma sandboxiin ja state:een
        if (continuingBatchId && savedWaitingProgram) {
            state.departureSandbox.programsByBatchId[String(continuingBatchId)] = savedWaitingProgram;
            state.programsByBatchId[String(continuingBatchId)] = JSON.parse(JSON.stringify(savedWaitingProgram));
            log(`INIT: Palautettu B${continuingBatchId} ohjelma sandboxista (viiveet säilytetty)`);
        }
        
        // Nollaa kierroksen muuttujat
        state.waitingBatches = [];
        state.waitingSchedules = {};
        state.waitingBatchAnalysis = {};
        state.waitingBatchTasks = {};
        state.departureCandidateStretches = [];
        state.departureLockedStages = {};
        state.departureIteration = 0;
        state.lastDepartureConflict = null;
        
        nextPhase = PHASE.DEPARTURE_CALC_START;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 1000: DEPARTURE_CALC_START
    // Collect ALL batches that need schedule calculation:
    //   - Line batches (stage 1-60): active in the line
    //   - Waiting batches (stage 90): waiting for departure permission
    // DEPARTURE calculates ALL schedules itself from programs.
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.DEPARTURE_CALC_START) {
        // Collect ALL batches needing schedules: line batches first, then waiting
        state.allCalcBatches = [];  // Indices into state.batches
        state.waitingBatches = [];
        
        for (let i = 0; i < state.batches.length; i++) {
            const batch = state.batches[i];
            if (!batch) continue;
            
            if (batch.stage >= 0 && batch.stage <= 89) {
                // Line batch — needs schedule
                state.allCalcBatches.push(i);
            } else if (batch.stage === 90) {
                // Waiting batch — schedule calculated per-batch in CHECK_CREATE_TASKS
                // Only add to waitingBatches, NOT allCalcBatches
                const unitForBatch = ctx.getUnitByBatchId ? ctx.getUnitByBatchId(batch.batch_id) : null;
                if (unitForBatch && unitForBatch.target && unitForBatch.target !== 'none') {
                    log(`CALC_START: B${batch.batch_id} stage=90 SKIP — unit U${unitForBatch.unit_id} target='${unitForBatch.target}' (not 'none')`);
                    continue;
                }
                state.waitingBatches.push(i);
                // Populate analysis metadata for SORT (no schedule needed)
                const prog = state.programsByBatchId[String(batch.batch_id)];
                state.waitingBatchAnalysis[String(batch.batch_id)] = {
                    batch_id: batch.batch_id,
                    program_id: batch.treatment_program,
                    loaded_s: batch.loaded_s || batch.start_time_s || 0,
                    stage_count: prog ? prog.length : 0
                };
            }
            // stage 0, 61-89, 91+: skip
        }
        
        state.waitingBatchCount = state.waitingBatches.length;
        state.allCalcCount = state.allCalcBatches.length;
        state.currentCalcIndex = 0;
        state.currentWaitingIndex = 0;
        
        log(`CALC_START: ${state.allCalcBatches.length} line batches to calculate, ${state.waitingBatches.length} waiting for CHECK phase`);
        
        // ═══════════════════════════════════════════════════════════════
        // Rakenna in-flight-tehtävät nostimien tiloista.
        // Kun erä on nostimessa, meneillään oleva siirto (lift→sink) ei
        // näy schedule-pohjaisissa tehtävälistoissa koska aikataulu alkaa
        // vasta seuraavasta stagesta. In-flight-tehtävä varmistaa:
        //   1) Idle-slot-laskenta näkee nostimen varattuna est_finish:iin asti
        //   2) Odottavan erän stage0CalcTime lasketaan oikein
        // ═══════════════════════════════════════════════════════════════
        state._inFlightTasks = [];
        for (const t of (ctx.transporterStates || [])) {
            const s = t?.state;
            if (!s || s.phase === 0) continue;
            if (s.current_task_batch_id == null) continue;
            const estFinish = Number(s.current_task_est_finish_s);
            if (!Number.isFinite(estFinish) || estFinish <= 0) continue;
            
            state._inFlightTasks.push({
                batch_id: s.current_task_batch_id,
                transporter_id: t.id,
                lift_station_id: s.current_task_lift_station_id || s.lift_station_target,
                sink_station_id: s.current_task_sink_station_id || s.sink_station_target,
                task_start_time: ctx.currentTimeSec || 0,
                task_finished_time: estFinish,
                stage: -1,  // pseudo-stage: meneillään oleva siirto
                isInFlight: true
            });
            log(`CALC_START: In-flight T${t.id} B${s.current_task_batch_id} ${s.current_task_lift_station_id}→${s.current_task_sink_station_id} est_finish=${estFinish.toFixed(1)}s`);
        }
        
        if (state.allCalcCount > 0) {
            nextPhase = PHASE.DEPARTURE_CALC_START + 1;  // 1001
        } else {
            log('No batches to calculate');
            nextPhase = PHASE.DEPARTURE_CALC_DONE;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 1001-1099: DEPARTURE_CALC
    // Calculate schedule for each batch (line + waiting)
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p >= PHASE.DEPARTURE_CALC_START + 1 && p <= PHASE.DEPARTURE_CALC_END) {
        const calcIndex = state.currentCalcIndex;
        
        if (calcIndex >= state.allCalcCount) {
            nextPhase = PHASE.DEPARTURE_CALC_DONE;
        } else {
            const batchIndex = state.allCalcBatches[calcIndex];
            const batch = state.batches[batchIndex];
            const batchId = batch?.batch_id;
            const isWaiting = batch?.stage === 90;
            
            if (batch && batchId) {
                log(`CALC B${batchId} stage=${batch.stage} (${calcIndex + 1}/${state.allCalcCount})${isWaiting ? ' [WAITING]' : ''}`);
                
                const program = state.programsByBatchId[String(batchId)];
                
                if (program) {
                    const transporter = state.transporters[0];
                    const now = ctx.currentTimeSec || 0;
                    
                    // Base time = now (kaikille erille, myös odottaville)
                    const baseTime = now;
                    
                    // ═══════════════════════════════════════════════════════════════
                    // Odottavan erän stage 0 -ajat ENNEN aikataulun laskentaa
                    // (departure_target_description.md: "Ensimmäisen tehtävän ajoitus")
                    //
                    // CalcTime = MinTime = pickup_time - start_time
                    //   pickup_time = idle_start + travel(idle_start_pos → pickup_station)
                    //   start_time  = now (currentTimeSec)
                    // MaxTime = 2 × MinTime
                    //
                    // Näin calculateBatchSchedule saa oikean stage 0:n keston,
                    // ja koko aikataulun stage 1+ ajoitus on oikein alusta alkaen.
                    // ═══════════════════════════════════════════════════════════════
                    if (isWaiting) {
                        // 1. Rakenna tehtävälista jo lasketuista linja-erien aikatauluista
                        const lineTasks = [];
                        for (const [id, sched] of Object.entries(state._calcSchedules || {})) {
                            const lineBatch = state.batches.find(b => b.batch_id === Number(id) || b.batch_id === id);
                            if (lineBatch && sched) {
                                const tasks = scheduler.createTaskListFromSchedule(sched, lineBatch, state.transporters);
                                lineTasks.push(...tasks);
                            }
                        }
                        
                        // 1b. Lisää in-flight-tehtävät → nostimien meneillään olevat
                        //     siirrot näkyvät idle-sloteissa (varaus now→est_finish)
                        if (state._inFlightTasks && state._inFlightTasks.length > 0) {
                            for (const ift of state._inFlightTasks) {
                                lineTasks.push(ift);
                            }
                            log(`CALC B${batchId}: Added ${state._inFlightTasks.length} in-flight tasks to lineTasks`);
                        }
                        
                        // 2. Selvitä mikä nostin hoitaa ensimmäisen siirron
                        const firstStageStation = parseInt(program[0]?.min_station, 10);
                        const batchLoc = ctx.getBatchLocation(batch.batch_id);
                        const pickupStation = scheduler.findStation(batchLoc, state.stations);
                        let stage0Transporter = null;
                        for (const t of state.transporters) {
                            if (scheduler.canTransporterHandleTask(t, batchLoc, firstStageStation)) {
                                stage0Transporter = t;
                                break;
                            }
                        }
                        if (!stage0Transporter) stage0Transporter = transporter;
                        
                        // 3. Laske idle-slotit tälle nostimelle
                        const tId = stage0Transporter.id;
                        const idleSlots = scheduler.calculateTransporterIdleSlots(tId, lineTasks, now);
                        
                        // 4. Etsi ensimmäinen sopiva idle-slot ja laske pickup_time
                        const maxInitWait = state.maxInitialWaitS || 120;
                        let stage0CalcTime = 0;
                        
                        for (const slot of idleSlots) {
                            if (slot.end <= now) continue;
                            
                            // idle_start_pos: edellisen tehtävän sink tai nostimen TODELLINEN sijainti
                            // Nostin ajaa TYHJÄNÄ hakemaan erää → vain matka-aika (phase3),
                            // EI nosto+lasku -sykliä (calculateTransferTime laskee koko syklin).
                            let travelToPickup = 0;
                            if (pickupStation) {
                                let fromStation = null;
                                if (slot.prevTask) {
                                    fromStation = scheduler.findStation(slot.prevTask.sink_station_id, state.stations);
                                } else {
                                    // Ensimmäinen idle-slot ilman edeltävää tehtävää:
                                    // Käytä nostimen TODELLISTA sijaintia, ei konfiguraation start_station:ia.
                                    const tCurrentState = (ctx.transporterStates || []).find(ts => ts.id === tId);
                                    const currentX = tCurrentState?.state?.x_position;
                                    if (currentX != null && Number.isFinite(currentX)) {
                                        // Luo virtuaalinen "asema" nostimen x-positiosta
                                        fromStation = { number: -1, x_position: currentX };
                                    } else if (stage0Transporter.start_station) {
                                        fromStation = scheduler.findStation(stage0Transporter.start_station, state.stations);
                                    }
                                }
                                if (fromStation && fromStation.number !== pickupStation.number) {
                                    // Virtuaaliasemalle tai eri asemalle: laske matka-aika suoraan
                                    if (fromStation.number === -1) {
                                        // Virtuaalinen sijainti → laske suoraan x-etäisyydestä
                                        travelToPickup = scheduler.calculateHorizontalTravelTime(
                                            fromStation, pickupStation, stage0Transporter
                                        );
                                    } else {
                                        const transfer = scheduler.calculateTransferTime(
                                            fromStation, pickupStation, stage0Transporter,
                                            ctx.movementTimes || null
                                        );
                                        // Käytä vain matka-aikaa (phase3), ei nosto/lasku -aikoja
                                        travelToPickup = transfer?.phase3_travel_s ?? 0;
                                    }
                                }
                            }
                            
                            const pickupTime = Math.max(slot.start, now) + travelToPickup;
                            const waitTime = pickupTime - now;
                            
                            if (waitTime > maxInitWait) continue;  // Liian kaukana
                            
                            stage0CalcTime = waitTime;
                            break;
                        }
                        
                        // 5. Kirjoita batch-tietoihin → calculateBatchSchedule lukee nämä
                        const minTime = stage0CalcTime;
                        const maxTime = Math.max(minTime, 2 * minTime);
                        batch.calc_time_s = stage0CalcTime;
                        batch.min_time_s = minTime;
                        batch.max_time_s = maxTime;
                        log(`CALC B${batchId}: stage 0 pre-calc → calc=${stage0CalcTime.toFixed(1)}s, min=${minTime.toFixed(1)}s, max=${maxTime.toFixed(1)}s (T${tId}, ${idleSlots.length} idle-slots)`);
                    }
                    
                    try {
                        // Other batch schedules for parallel station selection (use current calc results)
                        const existingSchedules = Object.entries(state._calcSchedules || {})
                            .filter(([id]) => id !== String(batchId))
                            .map(([, sched]) => sched);
                        
                        const occupiedStations = new Set(
                            (ctx.units || [])
                                .filter(u => u.batch_id != null && u.batch_id !== batch.batch_id && u.location > 0)
                                .map(u => u.location)
                        );
                        
                        // Etsi nostimen tila jos erä on nostimessa
                        // → calculateBatchSchedule käyttää est_finish_s:ää entry_time:na
                        const batchLocForCalc = ctx.getBatchLocation(batch.batch_id);
                        const isOnTransporter = batchLocForCalc != null && batchLocForCalc < 100;
                        let calcTransporterState = null;
                        if (isOnTransporter) {
                            const tState = (ctx.transporterStates || []).find(t => t.id === batchLocForCalc);
                            if (tState) {
                                calcTransporterState = tState;
                            }
                        }
                        
                        const scheduleResult = scheduler.calculateBatchSchedule(
                            batch,
                            program,
                            state.stations,
                            isOnTransporter ? (state.transporters.find(t => t.id === batchLocForCalc) || transporter) : transporter,
                            baseTime,
                            batch.isDelayed,
                            calcTransporterState,
                            { 
                                movementTimes: ctx.movementTimes || null,
                                lineSchedules: existingSchedules,
                                occupiedStations: occupiedStations,
                                stationIdleSince: ctx.stationIdleSince || new Map(),
                                units: ctx.units || []
                            }
                        );
                        
                        if (scheduleResult) {
                            scheduleResult.batchStage = batch.stage;
                            if (isWaiting) {
                                scheduleResult.dynamicOffsetSec = baseTime - now;
                                
                                // Kirjoita stage 0:n calc_time sandbox-batchiin
                                // ACTIVATE lukee sandbox.batches — EI state.batches!
                                const stage0 = scheduleResult.stages?.find(s => s.stage === 0);
                                if (stage0) {
                                    const sandboxBatch = state.departureSandbox?.batches?.find(b => b.batch_id === batchId);
                                    if (sandboxBatch) {
                                        sandboxBatch.calc_time_s = stage0.treatment_time_s;
                                        sandboxBatch.min_time_s = stage0.min_time_s;
                                        sandboxBatch.max_time_s = stage0.max_time_s;
                                    }
                                    // Kirjoita myös state.batches:iin (resolver lukee tätä)
                                    batch.calc_time_s = stage0.treatment_time_s;
                                    batch.min_time_s = stage0.min_time_s;
                                    batch.max_time_s = stage0.max_time_s;
                                    log(`CALC B${batchId}: stage 0 → calc=${stage0.treatment_time_s.toFixed(1)}s, min=${stage0.min_time_s.toFixed(1)}s, max=${stage0.max_time_s.toFixed(1)}s`);
                                }
                            }
                            
                            // Store in _calcSchedules (temp buffer, swapped to schedulesByBatchId in CALC_DONE)
                            state._calcSchedules[String(batchId)] = scheduleResult;
                            state.departureSandbox.schedulesByBatchId[String(batchId)] = scheduleResult;
                            
                            if (isWaiting) {
                                state.waitingSchedules[String(batchId)] = scheduleResult;
                                state.waitingBatchAnalysis[String(batchId)] = {
                                    batch_id: batchId,
                                    program_id: batch.treatment_program,
                                    loaded_s: batch.loaded_s || batch.start_time_s || 0,
                                    stage_count: program.length
                                };
                            }
                        }
                    } catch (err) {
                        log(`CALC B${batchId} error: ${err.message}`);
                    }
                }
            }
            
            state.currentCalcIndex++;
            if (state.currentCalcIndex < state.allCalcCount) {
                nextPhase = p + 1;
                if (nextPhase > PHASE.DEPARTURE_CALC_END) {
                    nextPhase = PHASE.DEPARTURE_CALC_DONE;
                }
            } else {
                nextPhase = PHASE.DEPARTURE_CALC_DONE;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 1900: DEPARTURE_CALC_DONE
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.DEPARTURE_CALC_DONE) {
        // Atomic swap: replace schedulesByBatchId only when ALL calcs are done → no API flicker
        state.schedulesByBatchId = state._calcSchedules;
        state._calcSchedules = {};
        
        const totalSchedules = Object.keys(state.schedulesByBatchId).length;
        const waitingSchedules = Object.keys(state.waitingSchedules).length;
        log(`CALC done: ${totalSchedules} total schedules (${totalSchedules - waitingSchedules} line + ${waitingSchedules} waiting)`);
        
        // Build sandbox tasks from ALL calculated schedules
        const allTasks = [];
        for (const [batchIdStr, schedule] of Object.entries(state.schedulesByBatchId)) {
            if (!schedule || !schedule.stages) continue;
            const batch = state.batches.find(b => b.batch_id === Number(batchIdStr));
            if (!batch) continue;
            // Only non-waiting batch tasks go into sandbox.tasks (waiting batch tasks are added per-check)
            if (batch.stage !== 90) {
                const tasks = scheduler.createTaskListFromSchedule(schedule, batch, state.transporters);
                allTasks.push(...tasks);
            }
        }
        state.departureSandbox.tasks = allTasks;
        log(`Built ${allTasks.length} sandbox tasks from line batch schedules`);
        
        nextPhase = PHASE.WAITING_SORT_START;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 2000-2900: WAITING_SORT
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.WAITING_SORT_START) {
        log('SORT start');
        nextPhase = PHASE.WAITING_SORT_LOADED;
    }
    
    else if (p === PHASE.WAITING_SORT_LOADED) {
        if (state.waitingBatches.length > 1) {
            state.waitingBatches.sort((aIdx, bIdx) => {
                const batchA = state.batches[aIdx];
                const batchB = state.batches[bIdx];
                const analysisA = state.waitingBatchAnalysis[String(batchA?.batch_id)] || {};
                const analysisB = state.waitingBatchAnalysis[String(batchB?.batch_id)] || {};
                const loadedA = analysisA.loaded_s || batchA?.loaded_s || batchA?.start_time_s || 0;
                const loadedB = analysisB.loaded_s || batchB?.loaded_s || batchB?.start_time_s || 0;
                return loadedA - loadedB;
            });
            log(`Sorted ${state.waitingBatches.length} batches by loaded_s (FIFO)`);
        }
        
        state.currentWaitingIndex = 0;
        nextPhase = PHASE.WAITING_SORT_DONE;
    }
    
    else if (p === PHASE.WAITING_SORT_DONE) {
        log('SORT done');
        nextPhase = PHASE.CHECK_START;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3000: CHECK_START
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_START) {
        state.pendingDelay = null;
        state.pendingDelays = [];
        state.departureAnalysis = null;
        
        console.log(`\n${'='.repeat(80)}`);
        console.log(`[DEPARTURE] CHECK_START: waitingBatchCount=${state.waitingBatchCount}, currentIndex=${state.currentWaitingIndex}`);
        if (state.waitingBatches && state.waitingBatches.length > 0) {
            for (let i = 0; i < state.waitingBatches.length; i++) {
                const bIdx = state.waitingBatches[i];
                const b = state.batches[bIdx];
                console.log(`[DEPARTURE]   [${i}] B${b?.batch_id} stage=${b?.stage} location=${b?.location}`);
            }
        }
        console.log(`${'='.repeat(80)}\n`);
        
        if (state.waitingBatchCount === 0) {
            log('No waiting batches → back to WAITING_FOR_TASKS');
            nextPhase = PHASE.WAITING_FOR_TASKS;
        } else if (state.currentWaitingIndex >= state.waitingBatchCount) {
            log('All batches processed, no departure granted → back to WAITING_FOR_TASKS');
            nextPhase = PHASE.WAITING_FOR_TASKS;
        } else {
            log(`CHECK: ${state.waitingBatchCount} waiting, index=${state.currentWaitingIndex}`);
            nextPhase = PHASE.CHECK_CREATE_TASKS;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3001: CHECK_CREATE_TASKS
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_CREATE_TASKS) {
        const batchIndex = state.waitingBatches[state.currentWaitingIndex];
        const batch = state.batches[batchIndex];
        const batchId = batch?.batch_id;
        
        if (!batch || !batchId) {
            state.currentWaitingIndex++;
            nextPhase = PHASE.CHECK_START;
        } else {
            log(`CHECK B${batchId}: Create tasks`);
            
            // Nollaa kierroslaskuri ja snapshot VAIN kun erä vaihtuu
            // (saman erän jatko-kierroksilla sandbox ja round säilyvät)
            if (state._currentDepartureBatchId !== batchId) {
                state._currentDepartureBatchId = batchId;
                state.sandboxSnapshot = JSON.parse(JSON.stringify(state.departureSandbox));
                state.departureRound = 0;  // Kierroslaskuri tälle erälle
                log(`New batch B${batchId} — reset round=0, fresh snapshot`);
            } else {
                log(`Continue batch B${batchId} — round=${state.departureRound}, keeping sandbox`);
            }
            state.departureCandidateStretches = [];
            state.departureIteration = 0;
            
            // Calculate schedule for this waiting batch (if not already done by RECALC)
            if (!state.waitingSchedules[String(batchId)]) {
                calculateWaitingBatchSchedule(batch, batchId);
            }
            
            const schedule = state.waitingSchedules[String(batchId)];
            
            if (!schedule || !schedule.stages) {
                state.currentWaitingIndex++;
                nextPhase = PHASE.CHECK_START;
            } else {
                // DEBUG: Näytä schedulen joustovarat
                console.log(`\n[DEPARTURE-DEBUG] B${batchId} schedule stages:`);
                for (const s of schedule.stages.slice(0, 5)) {
                    console.log(`[DEPARTURE-DEBUG]   stage ${s.stage}: treatment=${s.treatment_time_s}s, min=${s.min_time_s}s, max=${s.max_time_s}s`);
                }
                
                const tasks = scheduler.createTaskListFromSchedule(
                    schedule,
                    batch,
                    state.transporters
                );
                
                state.waitingBatchTasks[String(batchId)] = tasks;
                
                // Lue in-flight tehtävät
                const inFlightTasks = [];
                for (const t of (ctx.transporterStates || [])) {
                    const s = t?.state;
                    if (!s || s.phase === 0) continue;
                    
                    let pendingBatchId = s.pending_batch_id;
                    const liftStation = s.lift_station_target;
                    const sinkStation = s.sink_station_target;
                    
                    if (pendingBatchId == null && s.phase > 0) {
                        const unitOnT = ctx.getUnitAtLocation(t.id);
                        const batchOnTransporter = unitOnT ? state.batches.find(b => b.batch_id === unitOnT.batch_id) : null;
                        if (batchOnTransporter) pendingBatchId = batchOnTransporter.batch_id;
                    }
                    
                    if (pendingBatchId != null && liftStation != null && sinkStation != null) {
                        const batchObj = state.batches.find(b => b.batch_id === pendingBatchId);
                        const inferredStage = batchObj?.stage || 0;
                        
                        const batchSchedule = state.departureSandbox?.schedulesByBatchId?.[String(pendingBatchId)];
                        const sinkStageSchedule = batchSchedule?.stages?.find(st => st.station_id === sinkStation);
                        const taskFinishedTime = sinkStageSchedule?.entry_time || (ctx.currentTimeSec + 60);
                        const liftStageSchedule = batchSchedule?.stages?.find(st => st.station_id === liftStation);
                        const taskStartTime = liftStageSchedule?.exit_time || ctx.currentTimeSec;
                        
                        inFlightTasks.push({
                            batch_id: pendingBatchId,
                            transporter_id: t.id,
                            lift_station_id: liftStation,
                            sink_station_id: sinkStation,
                            task_start_time: taskStartTime,
                            task_finished_time: taskFinishedTime,
                            stage: inferredStage,
                            isInFlight: true
                        });
                    }
                }
                
                // Yhdistä: in-flight + sandbox + odottavan erän tehtävät
                let sandboxTasks = state.departureSandbox?.tasks || [];
                
                // DEBUG: Näytä sandboxin tehtävien joustovarat
                console.log(`[DEPARTURE-DEBUG] Sandbox tasks (${sandboxTasks.length}):`);
                for (const t of sandboxTasks.slice(0, 5)) {
                    console.log(`[DEPARTURE-DEBUG]   B${t.batch_id}s${t.stage}: calc=${t.calc_time_s}s, min=${t.min_time_s}s, max=${t.max_time_s}s → flex_down=${Math.max(0, (t.calc_time_s || 0) - (t.min_time_s || 0))}s, flex_up=${Math.max(0, (t.max_time_s || 0) - (t.calc_time_s || 0))}s`);
                }
                
                // Suodata pois in-flight tehtävät (korvataan tuoreemmilla)
                if (inFlightTasks.length > 0) {
                    const inFlightKeys = new Set(inFlightTasks.map(t => `${t.batch_id}_${t.stage}`));
                    sandboxTasks = sandboxTasks.filter(t => !inFlightKeys.has(`${t.batch_id}_${t.stage}`));
                }
                
                // combinedTasks = vain linja-erien taskit (in-flight + sandbox)
                // Odottavan erän taskit EIVÄT kuulu tänne — ne haetaan erikseen CHECK_ANALYZE:ssa
                // waitingBatchTasks-mapista. Jos ne olisivat täällä, SORT ja SWAP sotkisivat
                // linja-erien taskijärjestyksen ja idle-slotit laskettaisiin väärin.
                state.combinedTasks = [...inFlightTasks, ...sandboxTasks];
                console.log(`[DEPARTURE-3001] Combined: ${inFlightTasks.length} in-flight + ${sandboxTasks.length} sandbox = ${state.combinedTasks.length} total (waiting B${batchId}: ${tasks.length} tasks separate)`);
                
                nextPhase = PHASE.CHECK_SORT;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3002: CHECK_SORT
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_SORT) {
        const batchIndex = state.waitingBatches[state.currentWaitingIndex];
        const batch = state.batches[batchIndex];
        const batchId = batch?.batch_id;
        
        // Idle-slot -strategia: yksi läpikäynti, ei iteraatiota
        console.log(`[DEPARTURE] CHECK_SORT B${batchId}: sorting ${(state.combinedTasks || []).length} tasks`);
        
        if (state.combinedTasks && state.combinedTasks.length > 0) {
            state.combinedTasks.sort((a, b) => a.task_start_time - b.task_start_time);
        }
        
        nextPhase = PHASE.CHECK_SWAP;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3003: CHECK_SWAP
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_SWAP) {
        let swapCount = 0;
        
        if (state.combinedTasks && state.combinedTasks.length > 1) {
            const transporterIds = [...new Set(state.combinedTasks.map(t => t.transporter_id))];
            
            for (const transporterId of transporterIds) {
                if (transporterId === null) continue;
                
                const transporterTasks = state.combinedTasks.filter(t => t.transporter_id === transporterId);
                
                for (let i = 0; i < transporterTasks.length - 1; i++) {
                    const prevTask = transporterTasks[i];
                    const nextTask = transporterTasks[i + 1];
                    
                    if (prevTask.batch_id !== nextTask.batch_id &&
                        prevTask.sink_station_id === nextTask.lift_station_id) {
                        
                        swapCount++;
                        [transporterTasks[i], transporterTasks[i + 1]] = [transporterTasks[i + 1], transporterTasks[i]];
                        
                        const globalPrevIdx = state.combinedTasks.indexOf(prevTask);
                        const globalNextIdx = state.combinedTasks.indexOf(nextTask);
                        if (globalPrevIdx !== -1 && globalNextIdx !== -1) {
                            [state.combinedTasks[globalPrevIdx], state.combinedTasks[globalNextIdx]] = 
                                [state.combinedTasks[globalNextIdx], state.combinedTasks[globalPrevIdx]];
                        }
                    }
                }
            }
        }
        
        nextPhase = PHASE.CHECK_ANALYZE;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3004: CHECK_ANALYZE (TAVOITETILA: kierroksittainen idle-slot-sovitus)
    //
    // departure_target_description.md mukaan:
    //   1. Laske idle-slotit linja-erien tehtävistä
    //   2. Käy odottavan erän tehtävät alusta järjestyksessä
    //   3. Jos tehtävä mahtuu sellaisenaan → jatka seuraavaan (saman kierroksen aikana)
    //   4. Jos ei mahdu → yritä viivästää flex_up:lla
    //      4a. Jos riittää → kirjaa viive, päätä kierros → WAITING_FOR_TASKS
    //      4b. Jos ei riitä → backward chain aiempiin tehtäviin
    //          - Riittää → kirjaa kaikki viiveet, päätä kierros
    //          - Ei riitä → REJECT
    //   5. Kaikki mahtuvat ilman muutoksia → ACTIVATE
    //
    // Ensimmäinen tehtävä (stage 0): aikarajat idle-slotista, max_initial_wait_s
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_ANALYZE) {
        const batchIndex = state.waitingBatches[state.currentWaitingIndex];
        const batch = state.batches[batchIndex];
        const batchId = batch?.batch_id;
        
        console.log(`\n${'='.repeat(80)}`);
        console.log(`[DEPARTURE] ★★★ CHECK_ANALYZE B${batchId} (TAVOITETILA) round=${state.departureRound} ★★★`);
        console.log(`${'='.repeat(80)}`);
        
        const currentTimeSec = ctx.currentTimeSec || 0;
        const flexUpFactor = state.flexUpFactor;
        const maxInitialWaitS = state.maxInitialWaitS;
        const fitParams = {
            stations: state.stations,
            transporters: state.transporters,
            movementTimes: ctx.movementTimes || null,
            marginSec: 5,
            conflictMarginSec: state.departureConflictMarginSec || 1,
            flexUpFactor: flexUpFactor,
        };
        
        // Hae odottavan erän taskit — tallennettu erikseen 3001:ssä
        // EI JÄRJESTETÄ: tehtävälista pysyy laskennan mukaisena (target)
        const waitingBatchTasks = (state.waitingBatchTasks[String(batchId)] || []);
        
        // Kerää nostintunnisteet SEKÄ linja-erien ETTÄ odottavan erän taskeista
        const transporterIds = [...new Set([
            ...(state.combinedTasks || [])
                .filter(t => t.transporter_id !== null)
                .map(t => t.transporter_id),
            ...waitingBatchTasks
                .filter(t => t.transporter_id !== null)
                .map(t => t.transporter_id)
        ])];
        
        // Laske idle-slotit VAIN linja-erien tehtävistä (odottavan erän taskit eivät mukana)
        const existingTasks = (state.combinedTasks || []).filter(t => t.batch_id !== batchId);
        
        // ★ OVERLAP: Laske overlap-asemat (asemat joissa useampi nostin voi toimia)
        const overlapStations = computeOverlapStations(state.transporters);
        if (overlapStations.size > 0) {
            console.log(`[OVERLAP] Overlap-asemat: [${[...overlapStations].sort((a, b) => a - b).join(', ')}]`);
            // Logita olemassa olevat overlap-tehtävät per nostin
            for (const tId of transporterIds) {
                const overlapTasks = existingTasks.filter(t =>
                    t.transporter_id !== tId &&
                    (overlapStations.has(t.lift_station_id) || overlapStations.has(t.sink_station_id))
                );
                if (overlapTasks.length > 0) {
                    console.log(`[OVERLAP] T${tId}: ${overlapTasks.length} cross-transporter overlap task(s):`);
                    for (const ot of overlapTasks.slice(0, 5)) {
                        console.log(`[OVERLAP]   B${ot.batch_id}s${ot.stage} T${ot.transporter_id}: lift=${ot.lift_station_id} sink=${ot.sink_station_id} ${ot.task_start_time?.toFixed(0)}-${ot.task_finished_time?.toFixed(0)}s`);
                    }
                }
            }
        }
        
        const idleSlotsPerTransporter = {};
        for (const tId of transporterIds) {
            idleSlotsPerTransporter[tId] = scheduler.calculateTransporterIdleSlots(
                tId, existingTasks, currentTimeSec
            );
        }
        
        // Log idle-slotit
        for (const tId of transporterIds) {
            const slots = idleSlotsPerTransporter[tId];
            console.log(`[IDLE-SLOT] T${tId}: ${slots.length} idle-slottia`);
            for (const s of slots.slice(0, 10)) {
                const prevInfo = s.prevTask ? `B${s.prevTask.batch_id}s${s.prevTask.stage}` : 'START';
                const nextInfo = s.nextTask ? `B${s.nextTask.batch_id}s${s.nextTask.stage}` : 'END';
                console.log(`[IDLE-SLOT]   ${s.start.toFixed(0)}-${s.end.toFixed(0)} (${s.duration.toFixed(0)}s) [${prevInfo} → ${nextInfo}]`);
            }
        }
        
        console.log(`[IDLE-SLOT] B${batchId}: ${waitingBatchTasks.length} taskia sovitettavana`);
        for (const t of waitingBatchTasks) {
            const flex_up = Math.max(0, (t.max_time_s || 0) - (t.calc_time_s || 0));
            console.log(`[IDLE-SLOT]   B${batchId}s${t.stage} T${t.transporter_id || '?'}: ${t.task_start_time?.toFixed(1)}s → ${t.task_finished_time?.toFixed(1)}s (flex_up=${flex_up.toFixed(0)}s)`);
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // KIERROKSITTAINEN SOVITUS (departure_target_description.md)
        // Käydään tehtävät alusta alkaen järjestyksessä.
        // ═══════════════════════════════════════════════════════════════════
        // cumulativeShift poistettu — viiveet kirjataan sandboxiin ja
        // RECALC_SCHEDULE laskee aikataulun uudelleen.  Jokainen viive
        // päättää tämän CHECK_ANALYZE-kierroksen ja palaa RECALC-silmukan kautta.
        let allFitNoChanges = true;
        let delayNeeded = false;
        let rejected = false;
        const delayActions = [];  // Kirjattavat viiveet tällä kierroksella
        
        for (let taskIdx = 0; taskIdx < waitingBatchTasks.length; taskIdx++) {
            const task = waitingBatchTasks[taskIdx];
            
            // ═══════════════════════════════════════════════════════════════
            // Ensimmäinen tehtävä (stage 0): tarkista mahtuuko idle-slottiin
            // CALC on jo laskenut stage 0:n ajat (batch.calc_time_s, min, max)
            // ja aikataulu sisältää oikean keston → tehtävän task_start/finished
            // ovat oikein. Tässä vain tarkistetaan slottiin mahtuminen.
            // ═══════════════════════════════════════════════════════════════
            if (task.stage === 0) {
                const tId = task.transporter_id;
                const slots = idleSlotsPerTransporter[tId] || [];
                console.log(`[IDLE-SLOT-DBG] Stage 0: tId=${tId}, slots=${slots.length}, keys=${Object.keys(idleSlotsPerTransporter)}`);
                
                let stage0Fitted = false;
                for (const slot of slots) {
                    if (slot.end <= currentTimeSec) continue;
                    
                    // Travel idle_start_pos → nostoasema
                    let travelToPickup = 0;
                    const transporter = state.transporters.find(t => t.id === tId);
                    const pickupStation = scheduler.findStation(task.lift_station_id, state.stations);
                    if (slot.prevTask) {
                        const fromStation = scheduler.findStation(slot.prevTask.sink_station_id, state.stations);
                        if (fromStation && pickupStation && transporter) {
                            // Tyhjä nosturi siirtyy → vain horisontaalinen matka-aika (ei nosto/lasku)
                            const transfer = scheduler.calculateTransferTime(
                                fromStation, pickupStation, transporter,
                                ctx.movementTimes || null
                            );
                            travelToPickup = transfer?.phase3_travel_s ?? 0;
                        }
                    } else if (transporter && transporter.start_station) {
                        const fromStation = scheduler.findStation(transporter.start_station, state.stations);
                        if (fromStation && pickupStation) {
                            // Tyhjä nosturi siirtyy → vain horisontaalinen matka-aika (ei nosto/lasku)
                            const transfer = scheduler.calculateTransferTime(
                                fromStation, pickupStation, transporter,
                                ctx.movementTimes || null
                            );
                            travelToPickup = transfer?.phase3_travel_s ?? 0;
                        }
                    }
                    
                    const earliestPickup = Math.max(slot.start, currentTimeSec) + travelToPickup;
                    
                    // Mahtuuko tehtävä slottiin?
                    const taskDuration = task.task_finished_time - task.task_start_time;
                    let travelFromSink = 0;
                    if (slot.nextTask) {
                        const sinkStation = scheduler.findStation(task.sink_station_id, state.stations);
                        const toStation = scheduler.findStation(slot.nextTask.lift_station_id, state.stations);
                        if (sinkStation && toStation && transporter) {
                            // Tyhjä nosturi siirtyy → vain horisontaalinen matka-aika (ei nosto/lasku)
                            const transfer = scheduler.calculateTransferTime(
                                sinkStation, toStation, transporter,
                                ctx.movementTimes || null
                            );
                            travelFromSink = transfer?.phase3_travel_s ?? 0;
                        }
                    }
                    
                    const slotEnd = slot.nextTask ? slot.end - travelFromSink - fitParams.conflictMarginSec : slot.end;
                    let effectiveStart = earliestPickup;
                    
                    // ★ OVERLAP CHECK: Stage 0 – jos nosto/lasku käyttää overlap-asemaa,
                    // varmista ettei toisen nostimen overlap-tehtävä ole samaan aikaan.
                    if (overlapStations.size > 0 &&
                        (overlapStations.has(task.lift_station_id) || overlapStations.has(task.sink_station_id))) {
                        const stage0OverlapDelay = calculateOverlapDelay(
                            task, effectiveStart - task.task_start_time,
                            existingTasks, overlapStations, fitParams.conflictMarginSec
                        );
                        if (stage0OverlapDelay > 0) {
                            console.log(`[OVERLAP] B${batchId}s0: overlap conflict → shift effectiveStart +${stage0OverlapDelay.toFixed(1)}s`);
                            effectiveStart += stage0OverlapDelay;
                        }
                    }
                    
                    console.log(`[IDLE-SLOT-DBG] Stage 0 check: effectiveStart=${effectiveStart.toFixed(1)}, taskDuration=${taskDuration.toFixed(1)}, slotEnd=${slotEnd.toFixed(1)}, fits=${effectiveStart + taskDuration <= slotEnd}`);
                    
                    if (effectiveStart + taskDuration <= slotEnd) {
                        // Laske stage 0:n viive: ero sovitetun aloitusajan ja schedulen aloitusajan välillä
                        const stage0Delay = effectiveStart - task.task_start_time;
                        
                        // ★ maxInitialWaitS -tarkistus: odotus ei saa ylittää maksimiarvoa (oletus 120s)
                        const maxInitWait = state.maxInitialWaitS || 120;
                        if (stage0Delay > maxInitWait) {
                            console.log(`[IDLE-SLOT] ✗ Stage 0: slot ${slot.start.toFixed(0)}-${slot.end.toFixed(0)} delay=${stage0Delay.toFixed(1)}s > maxInitialWait=${maxInitWait}s → hylätty`);
                            continue;  // Kokeillaan seuraavaa slottia
                        }
                        
                        stage0Fitted = true;
                        console.log(`[IDLE-SLOT] ✓ Stage 0: mahtuu slottiin ${slot.start.toFixed(0)}-${slot.end.toFixed(0)} (delay=${stage0Delay.toFixed(1)}s)`);
                        
                        // Typistä idle-slottia
                        const taskEndTime = effectiveStart + taskDuration;
                        slot.start = taskEndTime;
                        slot.duration = slot.end - slot.start;
                        
                        // Stage 0 offset = nosturin matka-aika (idle slot vs. schedule).
                        // Merkittävä viive → kirjaa sandboxiin ja laske aikataulu uudelleen.
                        if (stage0Delay > fitParams.marginSec) {
                            delayActions.push({
                                stage: 0,
                                delay: stage0Delay,
                                writeTarget: 'batch',
                                log: `Stage 0: calc_time offset ${stage0Delay.toFixed(1)}s (slot ${slot.start.toFixed(0)}-${slot.end.toFixed(0)})`
                            });
                            allFitNoChanges = false;
                            console.log(`[DEPARTURE] Stage 0 offset: ${stage0Delay.toFixed(1)}s → sovittelukierros (RECALC)`);
                        }
                        break;
                    }
                }
                
                if (!stage0Fitted) {
                    console.log(`\n[DEPARTURE] ✗ B${batchId}: Stage 0 ei mahdu → REJECT\n`);
                    state.idleSlotResult = {
                        fits: false, actions: [], log: ['Stage 0: ei sopivaa idle-slottia'],
                        userReason: `Nostin T${task.transporter_id} varattu — ei vapaata slottia`
                    };
                    rejected = true;
                    break;
                }
                // Stage 0 offset on nosturin matka-aika (fysiikka), EI konfliktiratkaisu.
                // Se kirjataan sandboxiin mutta sovitus JATKAA samalla kierroksella
                // stage 1+ tehtäviin. Vain stage 1+ viive triggeröi RECALC-kierroksen.
                continue;  // Stage 0 OK, jatka seuraavaan tehtävään
            }
            
            // ═══════════════════════════════════════════════════════════════
            // Muut tehtävät (stage 1+): fitSingleTaskToIdleSlots
            // ★ OVERLAP CHECK: Jos tehtävä käyttää overlap-asemaa, tarkista
            //   ettei toisen nostimen overlap-tehtävä ole samaan aikaan.
            //   Lisää tarvittava viive ENNEN idle-slot -sovitusta jotta
            //   fitSingleTaskToIdleSlots etsii slotin oikeasta ajankohdasta.
            // ═══════════════════════════════════════════════════════════════
            // cumulativeShift = 0 — RECALC on jo päivittänyt task-ajat
            const overlapDelay = calculateOverlapDelay(
                task, 0, existingTasks, overlapStations, fitParams.conflictMarginSec
            );
            if (overlapDelay > 0) {
                console.log(`[OVERLAP] B${batchId}s${task.stage} T${task.transporter_id}: overlap conflict → delay ${overlapDelay.toFixed(1)}s (lift=${task.lift_station_id}, sink=${task.sink_station_id})`);
                allFitNoChanges = false;
            }
            
            // Overlap-viive on ainoa shift — ei kumulatiivista kertymää
            const fitResult = scheduler.fitSingleTaskToIdleSlots(
                task, idleSlotsPerTransporter, overlapDelay, fitParams
            );
            console.log(`[IDLE-SLOT] ${fitResult.log}`);
            
            if (fitResult.fits) {
                // Typistä idle-slottia: tehtävä varaa alun, slotin start siirtyy tehtävän loppuun
                if (fitResult.slot && fitResult.taskEndTime != null) {
                    const oldStart = fitResult.slot.start;
                    fitResult.slot.start = fitResult.taskEndTime;
                    fitResult.slot.duration = fitResult.slot.end - fitResult.slot.start;
                    console.log(`[IDLE-SLOT] Slot typistetty: ${oldStart.toFixed(0)}-${fitResult.slot.end.toFixed(0)} → ${fitResult.slot.start.toFixed(0)}-${fitResult.slot.end.toFixed(0)} (${fitResult.slot.duration.toFixed(0)}s jäljellä)`);
                }
                // Mahtuu — kirjaa mahdollinen viive
                // Nostimen vaihtuminen ei vaadi erillistä tarkistusta:
                // jokainen tehtävä sovitetaan oman nostimensa idle-slottiin
                // automaattisesti. TASKS hoitaa handoff-konfliktit.
                
                // ★ OVERLAP: Kokonaisviive = overlap-viive + idle-slot-viive
                const totalDelay = overlapDelay + (fitResult.delay || 0);
                
                if (totalDelay > fitParams.marginSec) {
                    allFitNoChanges = false;
                    delayActions.push({
                        stage: task.stage,
                        delay: totalDelay,
                        writeTarget: 'program',  // Stage 1+ → käsittelyohjelma
                        log: overlapDelay > 0
                            ? fitResult.log + ' + overlap delay ' + overlapDelay.toFixed(1) + 's'
                            : fitResult.log
                    });
                    // Tavoitetila: yksi viive per kierros → päätä kierros tähän
                    console.log(`[DEPARTURE] Viive stage ${task.stage}: ${totalDelay.toFixed(1)}s (overlap=${overlapDelay.toFixed(1)}s, idle=${(fitResult.delay || 0).toFixed(1)}s) → kierros päätetään`);
                    delayNeeded = true;
                    break;
                }
                // Ei viivettä → jatka seuraavaan tehtävään saman kierroksen aikana
                continue;
            }
            
            // ═══════════════════════════════════════════════════════════════
            // Ei mahdu → backward chaining
            // Kulje taaksepäin yksi tehtävä kerrallaan, ketjuta viiveet
            // ═══════════════════════════════════════════════════════════════
            console.log(`[IDLE-SLOT] Stage ${task.stage} ei mahdu → backward chaining`);
            
            // needExtra = viivästystarve joka ylittää tehtävän oman jouston (dokumentti: "jäljelle jäävä viivästystarve")
            // Jos needExtra puuttuu, slot ei löytynyt lainkaan → backward chaining ei voi auttaa
            if (fitResult.needExtra == null || fitResult.needExtra <= 0) {
                console.log(`\n[DEPARTURE] ✗ B${batchId}: Stage ${task.stage} ei sopivaa idle-slottia → REJECT\n`);
                state.idleSlotResult = {
                    fits: false, actions: [], log: [`Stage ${task.stage}: ei sopivaa idle-slottia`],
                    userReason: `Stage ${task.stage}: nostin T${task.transporter_id} varattu`
                };
                rejected = true;
                break;
            }
            let remainingNeed = fitResult.needExtra;
            const chainDelays = [];  // Ketjutetut viiveet
            let chainSuccess = false;
            
            // Aloita nykyisestä tehtävästä (sen oma flex_up on jo käytetty fitSingleTaskToIdleSlots:ssa)
            // ja kulje taaksepäin
            for (let backIdx = taskIdx - 1; backIdx >= 0 && remainingNeed > 0; backIdx--) {
                const prevTask = waitingBatchTasks[backIdx];
                const prevFlexUp = Math.max(0, (prevTask.max_time_s || 0) - (prevTask.calc_time_s || 0));
                const prevCappedFlex = prevFlexUp * flexUpFactor;
                const useDelay = Math.min(prevCappedFlex, remainingNeed);
                
                if (useDelay > fitParams.marginSec) {
                    chainDelays.push({
                        stage: prevTask.stage,
                        delay: useDelay,
                        writeTarget: prevTask.stage === 0 ? 'batch' : 'program',
                        log: `backward chain: stage ${prevTask.stage} delay ${useDelay.toFixed(1)}s (flex_up=${prevFlexUp.toFixed(0)}s × ${flexUpFactor})`
                    });
                    remainingNeed -= useDelay;
                    console.log(`[BACKWARD] Stage ${prevTask.stage}: delay ${useDelay.toFixed(1)}s, remaining need ${remainingNeed.toFixed(1)}s`);
                }
            }
            
            if (remainingNeed <= fitParams.marginSec) {
                // Backward chaining riitti!
                console.log(`[BACKWARD] ✓ Ketju riittää, ${chainDelays.length} viivettä`);
                allFitNoChanges = false;
                delayNeeded = true;
                
                // Lisää ketjutetut viiveet + alkuperäinen tehtävä
                delayActions.push(...chainDelays);
                // Alkuperäinen tehtävä saa saman viiveen mikä oli fitResult.delay (se mahtuisi nyt)
                if (fitResult.delay > fitParams.marginSec) {
                    delayActions.push({
                        stage: task.stage,
                        delay: fitResult.delay,
                        writeTarget: 'program',
                        log: `Stage ${task.stage}: delay ${fitResult.delay.toFixed(1)}s (after backward chain)`
                    });
                }
                break;  // Kierros päätetään
            } else {
                // Backward chaining ei riittänyt → REJECT
                console.log(`\n[DEPARTURE] ✗ B${batchId}: backward chaining ei riitä (remaining ${remainingNeed.toFixed(1)}s) → REJECT\n`);
                state.idleSlotResult = {
                    fits: false, actions: [], log: [`Stage ${task.stage}: backward chain insufficient, remaining ${remainingNeed.toFixed(1)}s`],
                    userReason: `Stage ${task.stage}: joustovara ei riitä, puuttuu ${remainingNeed.toFixed(0)}s`
                };
                rejected = true;
                break;
            }
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // Päätöspuu (departure_target_description.md)
        // ═══════════════════════════════════════════════════════════════════
        if (rejected) {
            // 3) Joustot eivät riitä → REJECT
            nextPhase = PHASE.CHECK_RESOLVE;
        } else if (!delayNeeded) {
            // 1) Kaikki tehtävät mahtuvat — ei viiveitä tarvita
            console.log(`\n[DEPARTURE] ✓ B${batchId}: Kaikki tehtävät mahtuvat (round ${state.departureRound}) → ACTIVATE\n`);
            state.idleSlotResult = { fits: true, actions: delayActions, log: ['Kaikki mahtuvat'] };
            nextPhase = PHASE.CHECK_RESOLVE;
        } else if (delayNeeded) {
            // 2) Viive tarvitaan → kirjaa viiveet sandboxiin, laske uusi aikataulu
            //    Sovittelukierros B: EI palata WAITING_FOR_TASKS:iin.
            //    Kirjataan viiveet → RECALC_SCHEDULE → RECALC_TASKS → SORT → ANALYZE
            state.departureRound++;
            
            // Turvarajoitin: max 50 sovittelukierrosta
            const MAX_FIT_ROUNDS = 50;
            if (state.departureRound > MAX_FIT_ROUNDS) {
                console.log(`\n[DEPARTURE] ✗ B${batchId}: Max sovittelukierrokset (${MAX_FIT_ROUNDS}) ylitetty → REJECT\n`);
                state.idleSlotResult = {
                    fits: false, actions: [], log: [`Max ${MAX_FIT_ROUNDS} fit-rounds exceeded`],
                    userReason: `Sovittelu ei konvergoidu ${MAX_FIT_ROUNDS} kierroksella`
                };
                nextPhase = PHASE.CHECK_RESOLVE;
            } else {
                console.log(`\n[DEPARTURE] ⟳ B${batchId}: Viiveet kirjataan, sovittelukierros ${state.departureRound} → RECALC\n`);
                
                // Kirjaa viiveet sandbox-batchiin ja -ohjelmaan
                for (const action of delayActions) {
                    if (action.writeTarget === 'batch') {
                        // Stage 0: kirjaa batch-tietoihin
                        const sandboxBatch = state.departureSandbox?.batches?.find(b => b.batch_id === batchId);
                        if (sandboxBatch) {
                            sandboxBatch.calc_time_s = (sandboxBatch.calc_time_s || 0) + action.delay;
                            sandboxBatch.min_time_s = sandboxBatch.calc_time_s;
                            sandboxBatch.max_time_s = Math.max(sandboxBatch.calc_time_s, 2 * sandboxBatch.calc_time_s);
                            log(`Viive kirjattu batch B${batchId} stage 0: calc=${sandboxBatch.calc_time_s.toFixed(1)}s`);
                        }
                        // Kirjaa myös state.batches (RECALC_SCHEDULE lukee tätä)
                        if (batch) {
                            batch.calc_time_s = (batch.calc_time_s || 0) + action.delay;
                            batch.min_time_s = batch.calc_time_s;
                            batch.max_time_s = Math.max(batch.calc_time_s, 2 * batch.calc_time_s);
                        }
                    } else {
                        // Stage 1+: kirjaa käsittelyohjelmaan
                        const program = state.departureSandbox?.programsByBatchId?.[String(batchId)];
                        if (program) {
                            const programIdx = action.stage - 1;
                            const stageEntry = program[programIdx];
                            if (stageEntry) {
                                const oldCalcS = scheduler.parseTimeToSeconds(stageEntry.calc_time) || 0;
                                const maxTimeS = scheduler.parseTimeToSeconds(stageEntry.max_time) || oldCalcS;
                                const newCalcS = Math.min(maxTimeS, oldCalcS + action.delay);
                                stageEntry.calc_time = scheduler.formatSecondsToTime(newCalcS);
                                log(`Viive kirjattu program B${batchId} stage ${action.stage}: ${oldCalcS.toFixed(0)}s → ${newCalcS.toFixed(0)}s`);
                            }
                        }
                        // Kirjaa myös server-puolen ohjelmaan
                        const serverProgram = state.programsByBatchId?.[String(batchId)];
                        if (serverProgram) {
                            const programIdx = action.stage - 1;
                            const stageEntry = serverProgram[programIdx];
                            if (stageEntry) {
                                const oldCalcS = scheduler.parseTimeToSeconds(stageEntry.calc_time) || 0;
                                const maxTimeS = scheduler.parseTimeToSeconds(stageEntry.max_time) || oldCalcS;
                                const newCalcS = Math.min(maxTimeS, oldCalcS + action.delay);
                                stageEntry.calc_time = scheduler.formatSecondsToTime(newCalcS);
                            }
                        }
                    }
                }
                
                log(`Sovittelukierros ${state.departureRound}: viiveet kirjattu → RECALC_SCHEDULE`);
                
                // Sovittelukierros: laske aikataulu uudelleen sandboxista → uudet taskit → uusi sovitus
                nextPhase = PHASE.CHECK_RECALC_SCHEDULE;
            }
        } else {
            // Kaikki mahtuvat viiveillä jotka eivät vaadi uutta kierrosta
            console.log(`\n[DEPARTURE] ✓ B${batchId}: Kaikki tehtävät mahtuvat (viiveet kirjattu) → ACTIVATE\n`);
            state.idleSlotResult = { fits: true, actions: delayActions, log: delayActions.map(a => a.log) };
            nextPhase = PHASE.CHECK_RESOLVE;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3005: CHECK_RESOLVE (IDLE-SLOT ONLY)
    //
    // Yksinkertainen päätös idle-slot -tuloksen perusteella:
    //   fits  → suoraan ACTIVATE (viiveet kirjataan ACTIVATE:ssa)
    //   !fits → REJECT
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_RESOLVE) {
        const batchIndex = state.waitingBatches[state.currentWaitingIndex];
        const batch = state.batches[batchIndex];
        const batchId = batch?.batch_id;
        
        const idleSlotResult = state.idleSlotResult || { fits: false, actions: [], log: [] };
        
        if (idleSlotResult.fits) {
            // ═══════════════════════════════════════════════════════════════
            // OK: Kaikki taskit mahtuivat → suoraan ACTIVATE
            // Viiveet kirjataan ACTIVATE-vaiheessa batchiin ja ohjelmaan
            // ═══════════════════════════════════════════════════════════════
            console.log(`\n[DEPARTURE] ✓ B${batchId}: Idle-slot OK → ACTIVATE (${idleSlotResult.actions.length} viivettä)`);
            log(`CHECK B${batchId}: Idle-slot fit → ACTIVATE`);
            state.lastDepartureConflict = null;
            nextPhase = PHASE.ACTIVATE;
        } else {
            // ═══════════════════════════════════════════════════════════════
            // FAIL: Taski ei mahtunut → REJECT
            // ═══════════════════════════════════════════════════════════════
            const failLog = idleSlotResult.log.filter(l => l.includes('FAIL') || l.includes('OVERFLOW'));
            
            console.log(`\n${'='.repeat(80)}`);
            console.log(`[DEPARTURE] ╔═══════════════════════════════════════════════════════╗`);
            console.log(`[DEPARTURE] ║ IDLE-SLOT FAIL → B${batchId} HYLÄTTY                    ║`);
            console.log(`[DEPARTURE] ╠═══════════════════════════════════════════════════════╣`);
            for (const line of failLog) {
                console.log(`[DEPARTURE] ║ ${line}`);
            }
            console.log(`[DEPARTURE] ╚═══════════════════════════════════════════════════════╝`);
            console.log(`${'='.repeat(80)}\n`);
            
            log(`CHECK B${batchId}: REJECT (idle-slot fail)`);
            
            state.lastDepartureConflict = {
                waitingBatchId: batchId,
                reason: `IDLE_SLOT_FAIL: ${failLog[0] || 'unknown'}`
            };
            
            // Palauta sandbox snapshotista (palauttaa vain linja-erien schedulet)
            if (state.sandboxSnapshot) {
                state.departureSandbox = JSON.parse(JSON.stringify(state.sandboxSnapshot));
            }
            // Poista hylätyn erän schedule
            delete state.schedulesByBatchId[String(batchId)];
            delete state.waitingSchedules[String(batchId)];
            state.departureRound = 0;  // Nollaa sovittelukierros REJECT:in jälkeen
            state.departureCandidateStretches = [];
            state.departureLockedStages = {};
            
            // Siirry seuraavaan odottavaan erään
            state.currentWaitingIndex++;
            
            if (state.currentWaitingIndex >= state.waitingBatchCount) {
                log(`All waiting batches checked, no activation → resync with TASKS`);
                state.finalDepartureConflict = state.lastDepartureConflict || null;
                state.lastDepartureConflict = null;
                nextPhase = PHASE.WAITING_FOR_TASKS;
            } else {
                nextPhase = PHASE.CHECK_START;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3006: CHECK_UPDATE_PROGRAM
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_UPDATE_PROGRAM) {
        const pendingList = state.pendingDelays || [];
        
        if (pendingList.length === 0) {
            nextPhase = PHASE.CHECK_SORT;
        } else {
            const applyDeltaToProgram = (program, targetStage, delay_s, propagate = false) => {
                if (!program) return null;
                
                const results = [];
                const startIdx = targetStage - 1;
                const endIdx = propagate ? program.length : targetStage;
                
                for (let i = startIdx; i < endIdx; i++) {
                    if (!program[i]) continue;
                    const stage = program[i];
                    const oldCalc = scheduler.parseTimeToSeconds(stage.calc_time) || 
                                    scheduler.parseTimeToSeconds(stage.min_time) || 0;
                    const minTime = scheduler.parseTimeToSeconds(stage.min_time) || oldCalc;
                    const maxTime = scheduler.parseTimeToSeconds(stage.max_time) || oldCalc;
                    const newCalc = Math.min(maxTime, Math.max(minTime, oldCalc + delay_s));
                    stage.calc_time = scheduler.formatSecondsToTime(newCalc);
                    results.push({ stage: i + 1, oldCalc, newCalc, minTime, maxTime });
                }
                return results.length > 0 ? results : null;
            };
            
            for (const pending of pendingList) {
                // Stage 0 ei ole käsittelyohjelmassa (program on 1-pohjainen)
                // propagateDelayToBatch (applyResolutionActions:ssa) on JO päivittänyt
                // sandbox-batchin calc_time_s:n → ei saa lisätä uudelleen (tuplaus!)
                // Tarvitaan vain loki.
                if (pending.stage === 0) {
                    const sandboxBatch = state.departureSandbox?.batches?.find(b => b.batch_id === pending.batch_id);
                    if (sandboxBatch) {
                        // Stage 0 ei ole käsittelyohjelmassa.
                        // propagateDelayToBatch on päivittänyt calc, min JA max (suhteellinen flex-ikkuna).
                        log(`Stage 0 delay for B${pending.batch_id}: calc=${sandboxBatch.calc_time_s?.toFixed(1)}s, min=${sandboxBatch.min_time_s?.toFixed(1)}s, max=${sandboxBatch.max_time_s?.toFixed(1)}s (applied by propagateDelayToBatch)`);
                    }
                    continue;
                }
                
                const results = applyDeltaToProgram(
                    state.departureSandbox?.programsByBatchId[String(pending.batch_id)],
                    pending.stage,
                    pending.delay_s,
                    pending.propagate
                );
                
                if (results && results.length > 0) {
                    const sandboxBatch = state.departureSandbox?.batches?.find(b => b.batch_id === pending.batch_id);
                    const currentStageResult = results.find(r => r.stage === sandboxBatch?.stage);
                    if (sandboxBatch && currentStageResult) {
                        sandboxBatch.calc_time_s = currentStageResult.newCalc;
                        sandboxBatch.min_time_s = currentStageResult.minTime;
                        sandboxBatch.max_time_s = currentStageResult.maxTime;
                    }
                }
            }
            
            nextPhase = PHASE.CHECK_RECALC_SCHEDULE;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3007: CHECK_RECALC_SCHEDULE
    // Recalculate ALL batch schedules from sandbox programs after conflict resolution.
    // This ensures that every schedule reflects the updated calc_times, so that
    // subsequent conflict analysis operates on accurate task times.
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_RECALC_SCHEDULE) {
        log(`RECALC_SCHEDULE: Recalculating ALL schedules from updated sandbox programs`);
        
        const sandboxBatches = state.departureSandbox?.batches || [];
        const transporter = state.transporters[0];
        let recalcCount = 0;
        
        for (const batch of sandboxBatches) {
            if (!batch || !batch.batch_id) continue;
            // Only recalculate batches in the line (stage 0-60) or waiting (stage 90)
            if (batch.stage > 60 && batch.stage !== 90) continue;
            
            const batchIdStr = String(batch.batch_id);
            const program = state.departureSandbox?.programsByBatchId[batchIdStr];
            if (!program) continue;
            
            // Only recalculate batches that have an existing schedule in sandbox
            // (other waiting batches are not part of this cycle)
            const existingSchedule = state.departureSandbox?.schedulesByBatchId[batchIdStr];
            if (!existingSchedule) continue;
            const baseTime = existingSchedule.calculated_at || (ctx.currentTimeSec || 0);
            
            // Other schedules for parallel station selection
            const otherSchedules = Object.entries(state.departureSandbox?.schedulesByBatchId || {})
                .filter(([id]) => id !== batchIdStr)
                .map(([, sched]) => sched);
            
            const occupiedStations = new Set(
                (ctx.units || [])
                    .filter(u => u.batch_id != null && u.batch_id !== batch.batch_id && u.location > 0)
                    .map(u => u.location)
            );
            
            const newSchedule = scheduler.calculateBatchSchedule(
                batch,
                program,
                state.stations,
                transporter,
                baseTime,
                false,
                null,
                { 
                    movementTimes: ctx.movementTimes || null,
                    lineSchedules: otherSchedules,
                    occupiedStations: occupiedStations,
                    stationIdleSince: ctx.stationIdleSince || new Map(),
                    units: ctx.units || []
                }
            );
            
            if (newSchedule && newSchedule.stages) {
                // DEBUG: Trace stage 0 timing for waiting batches
                if (batch.stage === 90) {
                    const s0 = newSchedule.stages.find(s => s.stage === 0);
                    if (s0) {
                        console.log(`[RECALC_SCHEDULE-DEBUG] B${batch.batch_id} stage=90: batch.calc_time_s=${batch.calc_time_s?.toFixed?.(1)}s → schedule stage0: entry=${s0.entry_time_s?.toFixed?.(1)}s, exit=${s0.exit_time_s?.toFixed?.(1)}s, treatment=${s0.treatment_time_s?.toFixed?.(1)}s, baseTime=${baseTime?.toFixed?.(1)}s`);
                    }
                }
                state.departureSandbox.schedulesByBatchId[batchIdStr] = newSchedule;
                
                // Synkronoi batch-tiedot aikataulun nykyisestä stagesta.
                // Kun erä ON asemalla, aikataulun laskenta alkaa batch-tiedoista.
                // min/max pitää olla ajan tasalla jotta propagateDelayToBatch clamp toimii oikein.
                // HUOM: EI synkronoida calc_time_s:ää — aktiivisille erille schedule
                // sisältää remainingTime (jäljellä oleva), ei kokonaisaikaa.
                const recalcBatchLoc = ctx.getBatchLocation(batch.batch_id);
                if (recalcBatchLoc != null && recalcBatchLoc >= 100) {
                    const batchCurrentStage = batch.stage === 90 ? 0 : (Number(batch.stage) || 0);
                    const currentStageInSchedule = newSchedule.stages.find(s => s.stage === batchCurrentStage);
                    if (currentStageInSchedule) {
                        const oldMin = batch.min_time_s;
                        const oldMax = batch.max_time_s;
                        batch.min_time_s = currentStageInSchedule.min_time_s;
                        batch.max_time_s = currentStageInSchedule.max_time_s;
                        if (oldMax !== batch.max_time_s) {
                            console.log(`[RECALC_SCHEDULE] B${batch.batch_id}: Synced batch min/max from schedule stage ${batchCurrentStage}: min ${oldMin?.toFixed?.(1)}→${batch.min_time_s?.toFixed?.(1)}s, max ${oldMax?.toFixed?.(1)}→${batch.max_time_s?.toFixed?.(1)}s`);
                        }
                    }
                }
                
                // Update waitingSchedules for waiting batches
                if (batch.stage === 90) {
                    state.waitingSchedules[batchIdStr] = newSchedule;
                }
                recalcCount++;
            }
        }
        
        log(`RECALC_SCHEDULE: ${recalcCount} schedules recalculated`);
        nextPhase = PHASE.CHECK_RECALC_TASKS;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3008: CHECK_RECALC_TASKS
    // Rebuild ALL tasks from ALL sandbox schedules.
    // This is the key fix: after a conflict resolve and schedule recalculation,
    // combinedTasks is rebuilt from scratch so task times accurately reflect
    // the resolved changes. No stale times from previous iterations.
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.CHECK_RECALC_TASKS) {
        const batchIndex = state.waitingBatches[state.currentWaitingIndex];
        const waitingBatch = state.batches[batchIndex];
        const waitingBatchId = waitingBatch?.batch_id;
        
        log(`RECALC_TASKS: Rebuilding ALL tasks from sandbox schedules`);
        
        // 1. Build in-flight tasks (real-time transporter state, same logic as CHECK_CREATE_TASKS)
        const inFlightTasks = [];
        for (const t of (ctx.transporterStates || [])) {
            const s = t?.state;
            if (!s || s.phase === 0) continue;
            
            let pendingBatchId = s.pending_batch_id;
            const liftStation = s.lift_station_target;
            const sinkStation = s.sink_station_target;
            
            if (pendingBatchId == null && s.phase > 0) {
                const unitOnT = ctx.getUnitAtLocation(t.id);
                const batchOnTransporter = unitOnT ? state.batches.find(b => b.batch_id === unitOnT.batch_id) : null;
                if (batchOnTransporter) pendingBatchId = batchOnTransporter.batch_id;
            }
            
            if (pendingBatchId != null && liftStation != null && sinkStation != null) {
                const batchObj = state.batches.find(b => b.batch_id === pendingBatchId);
                const inferredStage = batchObj?.stage || 0;
                
                const batchSchedule = state.departureSandbox?.schedulesByBatchId?.[String(pendingBatchId)];
                const sinkStageSchedule = batchSchedule?.stages?.find(st => st.station_id === sinkStation);
                const taskFinishedTime = sinkStageSchedule?.entry_time || (ctx.currentTimeSec + 60);
                const liftStageSchedule = batchSchedule?.stages?.find(st => st.station_id === liftStation);
                const taskStartTime = liftStageSchedule?.exit_time || ctx.currentTimeSec;
                
                inFlightTasks.push({
                    batch_id: pendingBatchId,
                    transporter_id: t.id,
                    lift_station_id: liftStation,
                    sink_station_id: sinkStation,
                    task_start_time: taskStartTime,
                    task_finished_time: taskFinishedTime,
                    stage: inferredStage,
                    isInFlight: true
                });
            }
        }
        
        // 2. Create tasks from ALL sandbox schedules
        let allTasks = [];
        const sandboxBatches = state.departureSandbox?.batches || [];
        
        for (const [batchIdStr, schedule] of Object.entries(state.departureSandbox?.schedulesByBatchId || {})) {
            if (!schedule || !schedule.stages) continue;
            const batch = sandboxBatches.find(b => b.batch_id === Number(batchIdStr)) ||
                          state.batches.find(b => b.batch_id === Number(batchIdStr));
            if (!batch) continue;
            
            const tasks = scheduler.createTaskListFromSchedule(schedule, batch, state.transporters);
            allTasks.push(...tasks);
        }
        
        // 3. Filter out in-flight tasks (replaced by real-time transporter data)
        if (inFlightTasks.length > 0) {
            const inFlightKeys = new Set(inFlightTasks.map(t => `${t.batch_id}_${t.stage}`));
            allTasks = allTasks.filter(t => !inFlightKeys.has(`${t.batch_id}_${t.stage}`));
        }
        
        // 4. Update sandbox.tasks (for potential subsequent waiting batch checks)
        state.departureSandbox.tasks = allTasks.filter(t => t.batch_id !== waitingBatchId);
        
        // 5. Store waiting batch tasks separately
        if (waitingBatchId) {
            state.waitingBatchTasks[String(waitingBatchId)] = allTasks.filter(t => t.batch_id === waitingBatchId);
        }
        
        // 6. Rebuild combinedTasks completely from scratch
        state.combinedTasks = [...inFlightTasks, ...allTasks];
        
        state.pendingDelay = null;
        state.pendingDelays = [];
        
        log(`RECALC_TASKS: ${inFlightTasks.length} in-flight + ${allTasks.length} from schedules = ${state.combinedTasks.length} total`);
        
        // Sovittelukierros: palaa CHECK_SORT → CHECK_ANALYZE uusilla tehtävillä
        log(`RECALC_TASKS done → CHECK_SORT (sovittelukierros ${state.departureRound})`);
        nextPhase = PHASE.CHECK_SORT;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3090: ACTIVATE
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.ACTIVATE) {
        const batchIndex = state.waitingBatches[state.currentWaitingIndex];
        const batch = state.batches[batchIndex];
        const batchId = batch?.batch_id;
        
        console.log(`\n[DEPARTURE-DIAG] ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★`);
        console.log(`[DEPARTURE-DIAG] ★ ACTIVATE B${batchId} @ ${ctx.currentTimeSec?.toFixed(1)}s`);
        console.log(`[DEPARTURE-DIAG] ★ Edellinen aktivointi: ${state.departureTimes?.length > 0 ? state.departureTimes[state.departureTimes.length-1].simTimeSec.toFixed(1) + 's' : 'N/A'}`);
        console.log(`[DEPARTURE-DIAG] ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★\n`);
        
        log(`ACTIVATE B${batchId}`);
        
        // ═══════════════════════════════════════════════════════════════
        // SNAPSHOT: Tallenna aktivointihetken aikataulut debug-analyysiin
        // ═══════════════════════════════════════════════════════════════
        try {
            const snapshotDir = path.join(__dirname, '..', 'debug_snapshots');
            if (!fs.existsSync(snapshotDir)) fs.mkdirSync(snapshotDir, { recursive: true });
            
            const sandbox = state.departureSandbox || {};
            const currentTimeSec = ctx.currentTimeSec || 0;
            
            // Kerää kaikkien linjalla olevien erien aikataulut
            const lineSchedules = {};
            if (sandbox.schedulesByBatchId) {
                for (const [bid, sched] of Object.entries(sandbox.schedulesByBatchId)) {
                    if (sched && sched.stages && sched.stages.length > 0) {
                        lineSchedules[`B${bid}`] = {
                            batch_id: Number(bid),
                            batchStage: sched.batchStage,
                            stages: sched.stages.map(s => ({
                                stage: s.stage,
                                station: s.station,
                                entry_time_s: s.entry_time_s,
                                exit_time_s: s.exit_time_s,
                                treatment_time_s: s.treatment_time_s,
                                min_time_s: s.min_time_s,
                                max_time_s: s.max_time_s,
                                transfer_time_s: s.transfer_time_s
                            }))
                        };
                    }
                }
            }
            
            // Kerää sandbox-taskit
            const sandboxTasks = (sandbox.tasks || []).map(t => ({
                batch_id: t.batch_id,
                stage: t.stage,
                transporter_id: t.transporter_id,
                lift_station_id: t.lift_station_id,
                sink_station_id: t.sink_station_id,
                task_start_time: t.task_start_time,
                task_finished_time: t.task_finished_time,
                calc_time_s: t.calc_time_s,
                min_time_s: t.min_time_s,
                max_time_s: t.max_time_s
            }));
            
            // Kerää idle-slot tulokset
            const idleSlotInfo = state.idleSlotResult ? {
                allFit: state.idleSlotResult.allFit,
                actions: state.idleSlotResult.actions,
                logs: state.idleSlotResult.logs
            } : null;
            
            // Kerää erien nykytilat
            const batchStates = (state.batches || []).filter(b => b).map(b => ({
                batch_id: b.batch_id,
                stage: b.stage,
                location: ctx.getBatchLocation(b.batch_id) ?? b.location,
                calc_time_s: b.calc_time_s,
                min_time_s: b.min_time_s,
                max_time_s: b.max_time_s
            }));
            
            const snapshot = {
                event: 'ACTIVATE',
                activated_batch_id: batchId,
                sim_time_sec: currentTimeSec,
                sim_time_formatted: scheduler.formatSecondsToTime(currentTimeSec),
                batch_states: batchStates,
                schedules: lineSchedules,
                sandbox_tasks: sandboxTasks,
                idle_slot_result: idleSlotInfo,
                timestamp: new Date().toISOString()
            };
            
            const filename = `activate_B${batchId}_t${Math.round(currentTimeSec)}.json`;
            fs.writeFileSync(path.join(snapshotDir, filename), JSON.stringify(snapshot, null, 2));
            console.log(`[SNAPSHOT] Saved activation snapshot: ${filename}`);
        } catch (snapshotErr) {
            console.error(`[SNAPSHOT] Error saving snapshot:`, snapshotErr.message);
        }
        
        const currentSimTimeSec = ctx.currentTimeSec || 0;
        
        // Tallenna linjaanlähtöaika
        state.departureTimes.push({ batchId, simTimeSec: currentSimTimeSec });
        
        // Laske keskimääräinen linjaanlähtöväli
        if (state.departureTimes.length >= 2) {
            const times = state.departureTimes.map(d => d.simTimeSec);
            let totalInterval = 0;
            for (let i = 1; i < times.length; i++) {
                totalInterval += times[i] - times[i - 1];
            }
            state.avgDepartureIntervalSec = totalInterval / (times.length - 1);
        }
        
        // Muuta stage 90 → 0 ja kirjaa sovittelun viiveet
        if (batch) {
            batch.stage = 0;
            batch.justActivated = true;
            
            // ═══════════════════════════════════════════════════════════════
            // Sandbox sisältää lopulliset arvot: kaikki viiveet (stage 0 + 1+)
            // on jo kirjattu RECALC-kierroksilla → lue suoraan sandboxista
            // ═══════════════════════════════════════════════════════════════
            const sandboxBatch = state.departureSandbox?.batches?.find(b => b.batch_id === batchId);
            
            batch.start_time = Math.round(currentSimTimeSec * 1000);
            batch.calc_time_s = sandboxBatch?.calc_time_s || 0;
            batch.min_time_s = sandboxBatch?.min_time_s || 0;
            batch.max_time_s = sandboxBatch?.max_time_s || 0;
            
            log(`ACTIVATE B${batchId}: stage 0 → start=${currentSimTimeSec.toFixed(1)}s, calc=${batch.calc_time_s.toFixed?.(1) ?? batch.calc_time_s}s`);
            
            // ═══════════════════════════════════════════════════════════════
            // Viiveet on jo kirjattu sandboxiin RECALC-kierroksilla.
            // Logataan lopulliset sandbox-ohjelman arvot.
            // ═══════════════════════════════════════════════════════════════
            const sandboxProgram = state.departureSandbox?.programsByBatchId?.[String(batchId)];
            if (sandboxProgram) {
                for (let pi = 0; pi < sandboxProgram.length; pi++) {
                    const entry = sandboxProgram[pi];
                    if (!entry) continue;
                    const calcS = scheduler.parseTimeToSeconds(entry.calc_time) || 0;
                    log(`ACTIVATE B${batchId}: program[${pi}] calc_time=${calcS.toFixed(0)}s`);
                }
            }
            
            // Kutsu serverin setBatchStage — justActivated-lippu tallentuu batches.json:iin
            if (ctx.setBatchStage) {
                try {
                    await ctx.setBatchStage(batchId, 0, {
                        start_time: batch.start_time,
                        calc_time_s: batch.calc_time_s,
                        min_time_s: batch.min_time_s,
                        max_time_s: batch.max_time_s,
                        justActivated: true
                    });
                } catch (err) {
                    log(`setBatchStage failed: ${err.message}`);
                }
            }
            
            // ═══════════════════════════════════════════════════════════════
            // Tallenna lähtevän erän aikataulu (EntryTime / ExitTime)
            // Tämä on DEPARTUREn laskema aikataulu, jota vasten voidaan
            // verrata TASKSin ja toteutuneen suorituksen ajoituksia.
            // ═══════════════════════════════════════════════════════════════
            const activatedSchedule = state.departureSandbox?.schedulesByBatchId?.[String(batchId)];
            if (activatedSchedule && activatedSchedule.stages) {
                console.log(`[DEPARTURE-SCHEDULE] B${batchId} aktivointihetken aikataulu:`);
                for (const s of activatedSchedule.stages) {
                    console.log(`[DEPARTURE-SCHEDULE]   stage=${s.stage} station=${s.station} entry=${s.entry_time_s?.toFixed(1)}s exit=${s.exit_time_s?.toFixed(1)}s treatment=${s.treatment_time_s?.toFixed(1)}s min=${s.min_time_s?.toFixed(1)}s max=${s.max_time_s?.toFixed(1)}s`);
                }
                // Tallenna stateen niin TASKS ja debug voivat verrata
                state.activatedSchedules = state.activatedSchedules || {};
                state.activatedSchedules[String(batchId)] = JSON.parse(JSON.stringify(activatedSchedule));
            }
        }
        
        // ═══════════════════════════════════════════════════════════════════
        // Store pending write data — DO NOT write files here!
        // Files are written by TASKS SAVE phase to avoid race conditions.
        // DEPARTURE waits in WAIT_FOR_SAVE until TASKS has written.
        // ═══════════════════════════════════════════════════════════════════
        if (state.departureSandbox) {
            state.schedulesByBatchId = JSON.parse(JSON.stringify(state.departureSandbox.schedulesByBatchId || {}));
            state.programsByBatchId = JSON.parse(JSON.stringify(state.departureSandbox.programsByBatchId || {}));
            
            // Collect batch calc_time updates for server
            const batchCalcUpdates = [];
            for (const [batchIdStr, program] of Object.entries(state.departureSandbox.programsByBatchId)) {
                const targetBatchId = parseInt(batchIdStr, 10);
                if (!Number.isFinite(targetBatchId) || targetBatchId === batchId) continue;
                
                const targetBatch = state.departureSandbox.batches?.find(b => b.batch_id === targetBatchId);
                if (!targetBatch || targetBatch.stage < 1 || targetBatch.stage >= 90) continue;
                
                const stageData = program[targetBatch.stage - 1];
                if (!stageData) continue;
                
                const calcTimeS = scheduler.parseTimeToSeconds(stageData.calc_time) || 0;
                if (calcTimeS > 0) {
                    batchCalcUpdates.push({ batchId: targetBatchId, stage: targetBatch.stage, calcTimeS });
                }
            }
            
            // Store pending data for TASKS SAVE to write
            state.pendingWriteData = {
                valid: true,
                programsByBatchId: JSON.parse(JSON.stringify(state.programsByBatchId)),
                schedulesByBatchId: JSON.parse(JSON.stringify(state.schedulesByBatchId)),
                batchCalcUpdates,
                currentTimeSec: ctx.currentTimeSec || 0
            };
            
            log(`ACTIVATE B${batchId}: Pending write data stored, waiting for TASKS SAVE`);
        }
        
        // Siirrä väliaikaiset viivästykset pysyvään listaan
        if (state.departureCandidateStretches && state.departureCandidateStretches.length > 0) {
            state.candidateStretches = state.candidateStretches || [];
            state.candidateStretches.push(...state.departureCandidateStretches);
            state.departureCandidateStretches = [];
        }
        
        // Siivoa
        delete state.waitingBatchTasks[String(batchId)];
        delete state.waitingSchedules[String(batchId)];
        state.departureSandbox = null;
        state.sandboxSnapshot = null;
        state.finalDepartureConflict = null;
        
        state.currentWaitingIndex++;
        
        // Aseta handshake-lippu: TASKS-tilakone tietää olla ylikirjoittamatta CSV:tä
        state.activatedThisCycle = true;
        
        const waitSec = batch.calc_time_s || 0;
        log(`ACTIVATE B${batchId} DONE → WAIT_FOR_SAVE`);
        nextPhase = PHASE.WAIT_FOR_SAVE;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 3091: WAIT_FOR_SAVE
    // Wait for TASKS to reach SAVE phase and write our pending data.
    // This ensures no race condition: TASKS writes DEPARTURE's changes
    // before reading them back in the next INIT.
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.WAIT_FOR_SAVE) {
        // ACTIVATE-tikki palautti activated=true kerran → server.js reagoi.
        // Nollataan heti seuraavalla tikillä, ettei signaali toistu.
        state.activatedThisCycle = false;
        
        const TASKS_SAVE = 10001;
        
        // Check if TASKS has written our data (signaled via ctx.departureSaveConfirmed)
        if (ctx.departureSaveConfirmed) {
            log('WAIT_FOR_SAVE: TASKS confirmed save, proceeding to END_DELAY');
            state.pendingWriteData = { valid: false };
            nextPhase = PHASE.END_DELAY_START;
        } else {
            // Keep waiting — pendingWriteData stays available for TASKS to read
            console.log(`[DEPARTURE] WAIT_FOR_SAVE: Waiting for TASKS to save our data (tasksPhase=${state.tasksPhase})`);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 4000-4100: END_DELAY
    // 100 tyhjää tickiä stabilointia varten - VAIN onnistuneen aktivoinnin jälkeen
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.END_DELAY_START) {
        log('END_DELAY start (100 ticks) after successful activation');
        state.endDelayCounter = 0;
        nextPhase = PHASE.END_DELAY_START + 1;
    }
    
    else if (p > PHASE.END_DELAY_START && p <= PHASE.END_DELAY_END) {
        state.endDelayCounter++;
        if (state.endDelayCounter >= END_DELAY_TICKS) {
            log('END_DELAY done');
            nextPhase = PHASE.RESTART;
        } else {
            nextPhase = p + 1;
            if (nextPhase > PHASE.END_DELAY_END) {
                nextPhase = PHASE.RESTART;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // PHASE 4101: RESTART
    // Palaa odottamaan TASKS-tilakonetta
    // ═══════════════════════════════════════════════════════════════════════════════
    else if (p === PHASE.RESTART) {
        // Syklin ajoitustilastot
        state.lastCycleTimeMs = Date.now() - state.cycleStartTime;
        state.totalCycles++;
        state.lastCycleTicks = state.cycleTickCount;
        state.lastCycleSimTimeMs = Math.round(state.lastCycleTicks * (Number.isFinite(state.cycleTickPeriodMs) ? state.cycleTickPeriodMs : 0));
        if (state.lastCycleTimeMs > state.longestCycleTimeMs) state.longestCycleTimeMs = state.lastCycleTimeMs;
        if (state.lastCycleTicks > state.longestCycleTicks) state.longestCycleTicks = state.lastCycleTicks;
        state.cycleHistory.push(state.lastCycleTimeMs);
        if (state.cycleHistory.length > 1000) state.cycleHistory.shift();
        state.cycleTickHistory.push(state.lastCycleTicks);
        if (state.cycleTickHistory.length > 1000) state.cycleTickHistory.shift();
        state.cycleSimTimeHistory.push(state.lastCycleSimTimeMs);
        if (state.cycleSimTimeHistory.length > 1000) state.cycleSimTimeHistory.shift();
        log(`Cycle complete: ${state.lastCycleTimeMs}ms wall, ${state.lastCycleTicks} ticks`);

        log('RESTART → waiting for TASKS');
        state.finalDepartureConflict = state.lastDepartureConflict || null;
        state.lastDepartureConflict = null;
        // Nollaa handshake-lippu vasta kun TASKS on kuitannut sen
        // (activatedThisCycle nollataan WAITING_FOR_TASKS:ssa kun TASKS on lukenut uudet CSV:t)
        nextPhase = PHASE.WAITING_FOR_TASKS;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // Aseta seuraava vaihe
    // ═══════════════════════════════════════════════════════════════════════════════
    state.phase = nextPhase;
    
    return {
        phase: state.phase,
        phaseName: getPhaseName(state.phase),
        activated: state.activatedThisCycle,
        // Pending write data for TASKS SAVE to merge and write
        pendingWriteData: state.pendingWriteData,
        schedulesByBatchId: state.schedulesByBatchId,
        programsByBatchId: state.programsByBatchId,
        candidateStretches: state.candidateStretches,
        departureTimes: state.departureTimes,
        avgDepartureIntervalSec: state.avgDepartureIntervalSec,
        lastDepartureConflict: state.lastDepartureConflict,
        finalDepartureConflict: state.finalDepartureConflict
    };
}

// ═══════════════════════════════════════════════════════════════════════════════
// APUFUNKTIOT
// ═══════════════════════════════════════════════════════════════════════════════

function getPhaseName(p) {
    if (p === PHASE.WAITING_FOR_TASKS) return 'WAITING_FOR_TASKS';
    if (p === PHASE.INIT) return 'INIT';
    if (p === PHASE.DEPARTURE_CALC_START) return 'DEPARTURE_CALC_START';
    if (p >= PHASE.DEPARTURE_CALC_START + 1 && p <= PHASE.DEPARTURE_CALC_END) return 'DEPARTURE_CALC';
    if (p === PHASE.DEPARTURE_CALC_DONE) return 'DEPARTURE_CALC_DONE';
    if (p === PHASE.WAITING_SORT_START) return 'WAITING_SORT_START';
    if (p === PHASE.WAITING_SORT_LOADED) return 'WAITING_SORT_LOADED';
    if (p === PHASE.WAITING_SORT_DONE) return 'WAITING_SORT_DONE';
    if (p === PHASE.CHECK_START) return 'CHECK_START';
    if (p === PHASE.CHECK_CREATE_TASKS) return 'CHECK_CREATE_TASKS';
    if (p === PHASE.CHECK_SORT) return 'CHECK_SORT';
    if (p === PHASE.CHECK_SWAP) return 'CHECK_SWAP';
    if (p === PHASE.CHECK_ANALYZE) return 'CHECK_ANALYZE';
    if (p === PHASE.CHECK_RESOLVE) return 'CHECK_RESOLVE';
    if (p === PHASE.CHECK_UPDATE_PROGRAM) return 'CHECK_UPDATE_PROGRAM';
    if (p === PHASE.CHECK_RECALC_SCHEDULE) return 'CHECK_RECALC_SCHEDULE';
    if (p === PHASE.CHECK_RECALC_TASKS) return 'CHECK_RECALC_TASKS';
    if (p === PHASE.ACTIVATE) return 'ACTIVATE';
    if (p === PHASE.WAIT_FOR_SAVE) return 'WAIT_FOR_SAVE';
    if (p === PHASE.END_DELAY_START) return 'END_DELAY_START';
    if (p > PHASE.END_DELAY_START && p <= PHASE.END_DELAY_END) return 'END_DELAY';
    if (p === PHASE.RESTART) return 'RESTART';
    return `UNKNOWN(${p})`;
}

function getState() {
    return state;
}

function getPhase() {
    return state.phase;
}

function reset() {
    state.phase = PHASE.WAITING_FOR_TASKS;
    state.batches = [];
    state.stations = [];
    state.transporters = [];
    state.transporterStates = [];
    state.schedulesByBatchId = {};
    state.programsByBatchId = {};
    state.waitingSchedules = {};
    state.waitingBatchAnalysis = {};
    state.waitingBatchTasks = {};
    state.waitingBatches = [];
    state.waitingBatchCount = 0;
    state.currentWaitingIndex = 0;
    state.allCalcBatches = [];
    state.allCalcCount = 0;
    state.currentCalcIndex = 0;
    state.departureSandbox = null;
    state.sandboxSnapshot = null;
    state.combinedTasks = [];
    state.departureAnalysis = null;
    state.departureCandidateStretches = [];
    state.candidateStretches = [];
    state.pendingDelay = null;
    state.pendingDelays = [];
    state.departureLockedStages = {};
    state.departureIteration = 0;
    state.departureRound = 0;
    state._currentDepartureBatchId = null;
    state.departureTimes = [];
    state.avgDepartureIntervalSec = 0;
    state.lastDepartureConflict = null;
    state.finalDepartureConflict = null;
    state.pendingWriteData = { valid: false };
    state.endDelayCounter = 0;
    state.activatedThisCycle = false;
    state.phaseLog = [];
    log('RESET');
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════════

module.exports = {
    tick,
    getState,
    getPhase,
    reset,
    getPhaseName,
    PHASE
};
