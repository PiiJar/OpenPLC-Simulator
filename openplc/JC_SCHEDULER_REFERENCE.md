# JC Scheduler — Structured Text Reference

## 1. Overview

### 1.1 What Is This?

The **JC Scheduler** is a deterministic, real-time task scheduler for automated surface treatment lines (plating, cleaning, phosphating, etc.). It runs inside a PLC as IEC 61131-3 Structured Text (ST), scheduling the movement of baskets/frames ("units") between treatment stations by overhead transporters (cranes).

The scheduler answers a deceptively complex question every scan cycle:

> *"Given N units at various treatment stages, M transporters with overlapping coverage areas, and strict chemical timing constraints (min/max soak times), what is the optimal sequence and timing of transporter moves?"*

### 1.2 Why Does It Exist?

In a real surface treatment plant, treatment times have strict chemical constraints. A basket left too long in an acid bath will be etched; too short and the coating is insufficient. The scheduler must:

1. **Compute schedules** — calculate entry/exit times for every unit at every station
2. **Create transfer tasks** — enumerate the transporter moves needed to execute the schedule
3. **Detect conflicts** — find timing/spatial collisions between tasks on the same or different transporters
4. **Resolve conflicts** — adjust treatment times within the allowed min/max flex to eliminate collisions
5. **Activate waiting batches** — determine when new production batches can enter the line without disrupting existing ones
6. **Dispatch tasks** — hand tasks to idle transporters at the right moment

All of this runs in the PLC scan cycle (~20 ms). The scheduler uses a scan-distributed state machine: each FB call does a bounded amount of work, and the orchestrator advances through phases across multiple scans.

### 1.3 Target PLC Environments

The codebase is written in IEC 61131-3 ST and designed for portability:

| Environment | Compiler | Notes |
|---|---|---|
| **OpenPLC (MATIEC)** | matiec → C → gcc | Current development/simulation target. 20 ms cycle. Docker container. |
| **Siemens TIA Portal** | SCL (S7-1500) | Production target. ST syntax is near-identical to SCL. |
| **CODESYS** | CODESYS V3 | Alternative production target. Native ST support. |

Key portability constraints:
- No dynamic memory allocation (all arrays are fixed-size)
- No recursion (flat iteration only)
- No STRING operations in hot path
- All `VAR_EXTERNAL` references go through `GVL_JC_Scheduler` / `GVL_Parameters` / `GVL_JC_Constants`
- Functions that need array-of-struct inputs are implemented as `FUNCTION_BLOCK` (MATIEC C codegen limitation with `__SET_VAR` macro)

### 1.4 Naming Conventions

| Prefix | Meaning | Examples |
|---|---|---|
| `TSK_FB_*` | Task scheduler core FBs | `TSK_FB_Scheduler`, `TSK_FB_Resolve` |
| `DEP_FB_*` | Departure (batch activation) FBs | `DEP_FB_Scheduler`, `DEP_FB_FitTaskToSlot` |
| `STC_FB_*` | Shared/common FBs | `STC_FB_MainScheduler`, `STC_FB_SortTaskQueue` |
| `STC_Calc*` | Pure functions (no state) | `STC_CalcTransferTime`, `STC_CalcHorizontalTravel` |
| `SIM_FB_*` | Simulation-only (not for production) | `SIM_FB_RunTasks`, `SIM_FB_XMotion` |
| `TWA_*` | Transporter Working Area | `TWA_FB_CalcLimits`, `TWA_CalcPriority` |
| `UDT_JC_*` | Scheduler-specific data types | `UDT_JC_TskTaskType`, `UDT_JC_TskScheduleType` |
| `UDT_*` | Plant-wide data types | `UDT_BatchType`, `UDT_StationType` |
| `GVL_JC_*` | Scheduler global variable lists | `GVL_JC_Scheduler`, `GVL_JC_Constants` |
| `g_*` | Global variable alias (VAR_EXTERNAL) | `g_task`, `g_schedule`, `g_batch` |

---

## 2. Architecture

### 2.1 Execution Model

The scheduler is **scan-distributed**: complex algorithms are split into phases, and one phase executes per PLC scan cycle. This guarantees bounded execution time and avoids watchdog timeouts.

```
plc_prg (main program, every scan)
  │
  ├── STC_FB_EventQueue()           ← always runs (Modbus event handshake)
  ├── STC_FB_Calibrate()            ← always runs (calibration state machine)
  │
  └── STC_FB_MainScheduler()        ← gated by i_run
        │
        ├── STC_FB_DispatchTask()   ← runs every scan (dispatch idle transporters)
        │
        ├── [Turn 1] TSK_FB_Scheduler()    ← task scheduling cycle
        │     ├── Phase 1:    CollectActiveBatches
        │     ├── Phase 2:    NoTreatmentStates
        │     ├── Phase 1001: CalcSchedule (one batch per scan)
        │     ├── Phase 2000: ClearTaskQueues
        │     ├── Phase 2001: CreateTasks (one batch per scan)
        │     ├── Phase 2200: SortTaskQueue → SwapTasks → Analyze
        │     ├── Phase 2203: Resolve (if conflict) → loop back to 2200
        │     ├── Phase 2204: NoTreatment (if no conflict)
        │     ├── Phase 10000: READY
        │     └── Phase 10100: Check DEP pending → restart
        │
        └── [Turn 2] DEP_FB_Scheduler()    ← departure scheduling cycle
              ├── Phase 1:    Wait for TSK stable
              ├── Phase 100:  Snapshot sandbox, find waiting batches
              ├── Phase 1010: CalcSchedule for waiting batch
              ├── Phase 1020: Rebuild all tasks
              ├── Phase 1030: Extract waiting batch tasks
              ├── Phase 1040: Calculate idle slots
              ├── Phase 2000: Fit stage 0 (pickup)
              ├── Phase 2001: Fit stage 1+ tasks
              ├── Phase 3000: Apply delay → recalculate
              ├── Phase 8000: ACTIVATE → pending write
              └── Phase 9000: REJECT → try next batch
```

### 2.2 Turn-Based Scheduling (MainScheduler)

`STC_FB_MainScheduler` alternates between TSK and DEP on successive scans:

```
Scan 1:  TSK (phase 1 → 2)
Scan 2:  DEP (phase 0 → 1, waiting for stable)
Scan 3:  TSK (phase 2 → 1000)
Scan 4:  DEP (still waiting)
  ...
Scan N:  TSK reaches phase 10000 (READY)
Scan N+1: DEP sees stable=TRUE, begins work
```

DEP is skipped when:
- TSK has not reached READY (phase < 10000) — DEP would just wait
- `g_dep_pending.Valid = TRUE` — TSK must process pending activation data first

### 2.3 Data Flow

```
                    ┌──────────────────────────────────────────┐
                    │          GVL_Parameters                  │
                    │  g_station[], g_cfg[], g_unit[],         │
                    │  g_batch[], g_program[], g_transporter[] │
                    └───────┬──────────────────────────────────┘
                            │ read/write
              ┌─────────────┼──────────────────┐
              │             │                  │
     ┌────────▼───┐  ┌──────▼──────┐  ┌───────▼──────┐
     │ CalcSchedule│  │ CreateTasks │  │ Dispatch     │
     │→g_schedule[]│  │→g_task[]    │  │←g_task[]     │
     └─────────────┘  └─────────────┘  │→g_transporter│
                                       └──────────────┘
              │             │
        ┌─────▼─────────────▼─────┐
        │  Sort → Swap → Analyze   │
        │  → Resolve (if conflict) │
        │  ←→ g_schedule, g_task,  │
        │     g_batch              │
        └──────────────────────────┘
```

---

## 3. Data Structures (UDTs)

### 3.1 Core Scheduler Types

#### `UDT_JC_TskScheduleType` — Per-Unit Schedule

```
StageCount : INT                          // number of active stages
Stages     : ARRAY[1..30] OF UDT_JC_TskStageType
```

One instance per unit (indexed 1..10 in `g_schedule[]`). Contains the calculated timeline of treatment stages for a batch.

#### `UDT_JC_TskStageType` — Single Schedule Stage

```
Station      : INT   // station number (e.g. 105), 0 = unused
ProgramStage : INT   // program stage number (1..N), 0 = pre-position entry
EntryTime    : LINT  // absolute arrival time (unix seconds)
ExitTime     : LINT  // absolute departure time (unix seconds)
MinTime      : DINT  // minimum treatment time (seconds)
CalcTime     : DINT  // calculated/target treatment time (seconds)
MaxTime      : DINT  // maximum treatment time (seconds)
TransferTime : DINT  // transfer time from previous station (seconds)
```

**Critical distinction — `ProgramStage` vs array index:**

When `CalcSchedule` prepends the unit's current location (because it's not at the first treatment station), schedule index 1 contains a pre-position entry with `ProgramStage = 0`. Real treatment stages start at index 2 with `ProgramStage = 1, 2, 3...`. Without the prepend, index 1 has `ProgramStage = 1`.

This means **schedule array index ≠ program stage number** when a prepend entry exists. All FBs that compare `g_batch[].CurStage` must use `ProgramStage`, not the raw array index.

#### `UDT_JC_TskTaskType` — Transporter Task

```
Unit              : INT   // unit index (1..10), 0 = empty/pseudo
Stage             : INT   // schedule array index (NOT program stage!)
LiftStationTarget : INT   // station to pick up from
SinkStationTarget : INT   // station to put down to
StartTime         : LINT  // absolute task start (unix seconds)
FinishTime        : LINT  // absolute task end (unix seconds)
CalcTime          : DINT  // treatment calc_time for flex (seconds)
MinTime           : DINT  // treatment min_time for flex_down
MaxTime           : DINT  // treatment max_time for flex_up
```

**`Stage` is a schedule array index**, used by `Resolve` and `ShiftSchedule` to access `g_schedule[unit].Stages[stage]`. To get the actual program stage number, use `g_schedule[unit].Stages[task.Stage].ProgramStage`.

#### `UDT_JC_TskQueueType` — Transporter Task Queue

```
Count : INT                           // number of active tasks
Queue : ARRAY[1..60] OF UDT_JC_TskTaskType
```

One instance per transporter (indexed 1..3 in `g_task[]`). Tasks are insertion-sorted by priority: emergency tasks first (overtime ratio > 1.0), then by `StartTime` ascending.

#### `UDT_JC_TskLockType` — Oscillation Lock

```
Unit      : INT  // batch unit index, 0 = empty
Stage     : INT  // schedule stage (array index)
Direction : INT  // 1 = ADVANCE, 2 = DELAY
```

Prevents the resolver from advancing a stage that was previously delayed (and vice versa) within the same scheduler cycle. Up to 50 locks per cycle.

### 3.2 Departure Scheduler Types

#### `UDT_JC_DepSandboxType` — Sandbox Backup

```
Schedule : ARRAY[1..10] OF UDT_JC_TskScheduleType
Batches  : ARRAY[1..10] OF UDT_BatchType
Programs : ARRAY[1..10] OF UDT_TreatmentProgramType
Tasks    : ARRAY[1..3]  OF UDT_JC_TskQueueType
Valid    : BOOL
```

Before DEP modifies globals (to test whether a waiting batch fits), it snapshots the current state here. On REJECT, globals are restored from the sandbox.

#### `UDT_JC_DepPendingWriteType` — Activation Handoff

```
Valid        : BOOL
Programs     : ARRAY[1..10] OF UDT_TreatmentProgramType
Schedule     : ARRAY[1..10] OF UDT_JC_TskScheduleType
BatchUnit    : INT       // the unit being activated
BatchStage   : INT       // new CurStage (0 for freshly activated)
BatchState   : INT       // new State (1 = IN_PROCESS)
BatchMinTime : DINT      // stage 0 min_time
BatchMaxTime : DINT      // stage 0 max_time
BatchCalTime : DINT      // stage 0 cal_time
TimeStamp    : LINT      // activation time
```

DEP writes this when activating a batch. TSK reads it at phase 10100, applies the data to globals, clears `Valid`, and begins a full recalculation.

#### `UDT_JC_DepIdleSlotType` — Transporter Idle Window

```
StartTime         : LINT  // idle window start
EndTime           : LINT  // idle window end (0 = open-ended)
LiftStationTarget : INT   // transporter location at idle start
SinkStationTarget : INT   // transporter location at idle end
```

Calculated by `DEP_FB_CalcIdleSlots` from gaps between consecutive tasks. Used by `DEP_FB_FitTaskToSlot` to check whether a waiting batch's tasks can be inserted without collision.

#### `UDT_JC_DepFitResultType` — Fit Check Result

```
Fits          : BOOL  // TRUE = task fits
DelayTime     : DINT  // delay needed (seconds)
NeedExtraTime : DINT  // extra time that doesn't fit (for backward chaining)
TaskEndTime   : LINT  // calculated task end time
SlotIdx       : INT   // index of the used idle slot
TransporterId : INT   // transporter that handles it
```

### 3.3 Plant-Wide Types (Used by Scheduler)

#### `UDT_BatchType` — Runtime Batch State

```
BatchCode : INT   // numeric batch ID
CurStage  : INT   // current program stage (0 = not started, 1..N)
State     : INT   // 0=NOT_PROCESSED, 1=IN_PROCESS, 2=PROCESSED
ProgId    : INT   // treatment program number
StartTime : LINT  // batch stage start time (unix seconds)
MinTime   : DINT  // current stage min time (seconds)
MaxTime   : DINT  // current stage max time (seconds)
CalTime   : DINT  // current stage calc/target time (seconds)
```

`CalTime` is **mutable at runtime** — the resolver modifies it to shift the batch's remaining treatment time when resolving conflicts. `CurStage` is a **program stage number** (1..N), not a schedule array index.

#### `UDT_TreatmentProgramType` — Treatment Recipe

```
ProgramId   : INT
ProgramName : STRING
StepCount   : INT
Steps       : ARRAY[0..30] OF UDT_TreatmentProgramStepType
```

Each step defines one treatment stage:

```
MinTime      : DINT              // seconds
MaxTime      : DINT              // seconds
CalTime      : DINT              // seconds (mutable — DEP may adjust)
StationCount : INT               // number of parallel stations (1..5)
Stations     : ARRAY[0..4] OF INT  // station numbers
```

Note: `Steps` array is 0-based (`Steps[0]` = program stage 1).

#### `UDT_JC_MoveTimesType` — Precomputed Movement Times

```
LiftTime : ARRAY[1..30] OF INT    // lift time ×10 (tenths of second)
SinkTime : ARRAY[1..30] OF INT    // sink time ×10 (tenths of second)
Travel   : ARRAY[1..30] OF UDT_JC_TravelFromType
  └── ToTime : ARRAY[1..30] OF INT  // travel time ×10 (tenths of second)
```

Indexed by `station_number - 100`. Populated by `STC_FB_MeasureMoveTimes` during calibration or loaded from configuration. All times stored as ×10 integers (tenths of second) to avoid floating-point in lookup tables.

---

## 4. Global Variables

### 4.1 `GVL_JC_Scheduler` — Scheduler State

| Variable | Type | Description |
|---|---|---|
| `Schedule[1..10]` | `UDT_JC_TskScheduleType` | Calculated schedule per unit |
| `TaskQueue[1..3]` | `UDT_JC_TskQueueType` | Task queue per transporter |
| `MoveTimes[1..3]` | `UDT_JC_MoveTimesType` | Precomputed movement times |
| `DepSandbox` | `UDT_JC_DepSandboxType` | DEP rollback backup |
| `DepIdleSlot[1..3]` | `UDT_JC_DepIdleSlotSetType` | Idle slots per transporter |
| `DepPending` | `UDT_JC_DepPendingWriteType` | TSK ← DEP activation handoff |
| `DepActivated` | `BOOL` | DEP → TSK handshake flag |
| `DepStable` | `BOOL` | TSK → DEP: task list is stable |
| `TimeSeconds` | `LINT` | Absolute time in unix seconds |
| `EventQueue` | `UDT_JC_EventQueueType` | Event message buffer |
| `EventPending` | `UDT_JC_EventMsgType` | Staging slot for new events |
| `EventPendingValid` | `BOOL` | TRUE = pending event ready |
| `ProductionQueue` | `INT` | 1 = batches waiting, 0 = empty |
| `CalibrationActive` | `BOOL` | TRUE during calibration (inhibits scheduling) |

### 4.2 `GVL_Parameters` — Plant Configuration

| Variable | Type | Description |
|---|---|---|
| `Stations[101..130]` | `UDT_StationType` | Station configuration (position, type, delays) |
| `StationLocations[1..130]` | `UDT_UnitLocation` | Unit currently at each station + change time |
| `Transporters[1..3]` | `UDT_TransporterType` | Full transporter configuration |
| `TransporterStatus[1..3]` | `UDT_TransporterStatusType` | Runtime transporter state (position, phase, task) |
| `Units[1..10]` | `UDT_UnitType` | Unit state (location, status, target) |
| `Batches[1..10]` | `UDT_BatchType` | Batch state per unit |
| `TreatmentPrograms[1..10]` | `UDT_TreatmentProgramType` | Treatment recipe per unit |

### 4.3 `GVL_JC_Constants` — Compile-Time Limits

| Constant | Value | Description |
|---|---|---|
| `MaxLines` | 1 | Production lines in plant |
| `MaxStationsPerLine` | 30 | Stations per line |
| `MaxTransporters` | 3 | Total transporters |
| `MaxUnits` | 10 | Max units (baskets/frames) |
| `MaxStationsPerStep` | 5 | Max parallel stations per program step |
| `MaxStepsPerProgram` | 30 | Max stages in a treatment program |
| `MaxTaskQueue` | 60 | Max tasks per transporter queue |
| `MinStationIndex` | 100 | First valid station (line 1 = 101) |
| `MaxStationIndex` | 130 | Last valid station |
| `DepMaxIdleSlots` | 20 | Max idle slots per transporter |
| `DepMaxWaiting` | 5 | Max waiting batches |

These are configurable per plant via `plant_config.json` and `apply_plant_config.py`, which patches `globals.st` and `types.st` before build.

---

## 5. Function Block Reference

### 5.1 `STC_FB_MainScheduler` — Master Orchestrator

**Purpose:** Alternates TSK and DEP scheduler calls across PLC scans. Ensures mutual exclusion and dispatches tasks to idle transporters.

**Inputs:**
- `i_run : BOOL` — enable scheduling
- `i_time_s : LINT` — current absolute time

**Outputs:**
- `o_tsk_phase, o_dep_phase : INT` — current phase of each scheduler
- `o_turn : INT` — which scheduler ran (1=TSK, 2=DEP)

**Behavior:**
1. Every scan: calls `STC_FB_DispatchTask()` (dispatches queued tasks to idle transporters)
2. Turn 1 (TSK): runs `TSK_FB_Scheduler` and computes `g_dep_stable := (phase >= 10000)`
3. Turn 2 (DEP): runs `DEP_FB_Scheduler` with `i_tsk_phase` for synchronization
4. Inhibits both during calibration (`g_cal_active = TRUE`)

---

### 5.2 `TSK_FB_Scheduler` — Task Scheduler State Machine

**Purpose:** The core scheduling loop. Builds schedules, creates tasks, detects and resolves conflicts, and manages unit-target (no-treatment) moves.

**Phase Map:**

| Phase | Name | Action |
|---|---|---|
| 0 | STOPPED | Wait for `i_run` |
| 1 | INIT | Collect active batches via `STC_FB_CollectActiveBatches(mode=0)` |
| 2 | NO_TREATMENT_STATES | Update unit/batch target states |
| 1001..1010 | SCHEDULE | `TSK_FB_CalcSchedule` — one batch per scan |
| 2000 | TASKS_START | `STC_FB_ClearTaskQueues` |
| 2001..2010 | CREATE_TASKS | `TSK_FB_CreateTasks` — one batch per scan |
| 2200 | SORT | `STC_FB_SortTaskQueue` + initialize oscillation locks |
| 2201 | SWAP | `TSK_FB_SwapTasks` |
| 2202 | ANALYZE | `TSK_FB_Analyze` — check for conflicts |
| 2203 | RESOLVE | `TSK_FB_Resolve` → loop back to 2200 (max 20 iterations) |
| 2204 | NO_TREATMENT | `TSK_FB_NoTreatment` — create unit-target tasks |
| 10000 | READY | Cycle complete, count total tasks |
| 10100 | CHECK_DEP_PENDING | If `g_dep_pending.Valid`: apply DEP data, restart |
| 10110 | RESTART | Increment cycle count, go to phase 1 |

**Conflict Resolution Loop:**

```
2200 SORT → 2201 SWAP → 2202 ANALYZE
  ├── conflict found → 2203 RESOLVE → back to 2200
  └── no conflict    → 2204 NO_TREATMENT → 10000 READY
```

Max 20 iterations. Partial solutions are accepted if the iteration limit is reached.

**DEP Pending Handoff (Phase 10100):**

When DEP activates a batch, it writes to `g_dep_pending`. TSK at phase 10100:
1. Copies pending programs and schedules to globals (only where `ProgramId > 0`)
2. Updates the activated batch's `CurStage`, `State`, timing fields
3. Clears `g_dep_pending.Valid`
4. Jumps to phase 1 for full recalculation

---

### 5.3 `TSK_FB_CalcSchedule` — Schedule Calculator

**Purpose:** Calculates the complete timeline for one unit/batch. Writes to `g_schedule[unit]`.

**Inputs:**
- `i_unit : INT` — unit index (1..10)
- `i_trans : INT` — transporter index (for move time lookup)
- `i_time_s : LINT` — current time

**Algorithm:**

1. **Determine start stage:** If unit is on a station, start from `CurStage`. If on transporter, start from `CurStage + 1`. Minimum is stage 1.

2. **Prepend entry:** If the unit is on a station that is NOT the first treatment station, insert a schedule entry with `ProgramStage = 0`, `CalcTime = 0` at position 1. This generates a pre-position move task.

3. **For each program stage** (start_st → StepCount):
   - **Parallel station selection:** If multiple stations are valid for this step:
     - Estimate the time window [my_entry, my_exit]
     - Check schedule overlap (other units scheduled at each candidate)
     - Check physical occupation (unit currently present)
     - Pick the free station with the oldest `ChangeTime` (longest idle)
     - Fallback: schedule-free only → first candidate
   - **Transfer time:** Calculated via `STC_CalcTransferTime` (lift + travel + sink + delays)
   - **Timing:**
     - First stage, on station: `entry = now`, `exit = now + remaining_time`. Remaining time uses `g_batch[].CalTime` (resolver-modified), not program CalTime.
     - First stage, on transporter: `entry = now`, `exit = entry + calc_time`
     - Normal stage: `entry = prev_exit + transfer`, `exit = entry + calc_time`
   - **Write:** Station, ProgramStage (1..N), EntryTime, ExitTime, MinTime, CalcTime, MaxTime, TransferTime

4. **Finalize:** Set `g_schedule[unit].StageCount`.

---

### 5.4 `TSK_FB_CreateTasks` — Task Builder

**Purpose:** Converts a unit's schedule into transporter tasks. Each consecutive schedule stage pair becomes one task (lift from stage N station, sink to stage N+1 station).

**Inputs:**
- `i_unit : INT` — unit index

**Algorithm:**

For each stage pair `[si, si+1]` in `g_schedule[unit]`:
1. `lift_stn = Stages[si].Station`, `sink_stn = Stages[si+1].Station`
2. Find covering transporter via `STC_FindTransporter(lift, sink)`
3. Append task to `g_task[transporter].Queue`:
   - `Stage = si` (schedule array index, not program stage)
   - `StartTime = Stages[si].ExitTime` (when the lift happens)
   - `FinishTime = Stages[si+1].EntryTime` (when the sink completes)
   - CalcTime, MinTime, MaxTime copied from schedule stage

---

### 5.5 `TSK_FB_Analyze` — Conflict Detection

**Purpose:** Scans all tasks for three types of conflicts, stops at the first one found.

**Check Order (matches JS priority):**

1. **TASK_SEQUENCE (type=1):** Per-transporter queue: does the transporter have enough time to travel from task N's sink to task N+1's lift? Compares horizontal travel time against the gap between consecutive tasks.

2. **CROSS_TRANSPORTER_HANDOFF (type=3):** Same batch, consecutive program stages on different transporters. Checks if the receiving transporter can reach the handoff station in time after finishing its previous task.

3. **TRANSPORTER_COLLISION (type=2):** Different transporters with overlapping X-ranges and overlapping time-ranges. The later task (by `StartTime`) is flagged as `conf`, the earlier as `blocked`.

**Outputs:**
- `o_has_conflict : BOOL`
- `o_conf_unit, o_conf_stage, o_conf_trans` — the task to adjust
- `o_blocked_unit, o_blocked_stage` — the blocking task
- `o_deficit : REAL` — seconds short

---

### 5.6 `TSK_FB_Resolve` — Conflict Resolution

**Purpose:** Adjusts schedule timing to eliminate a single conflict. Uses four sequential phases, each consuming remaining deficit.

**Inputs:** Conflict data from `TSK_FB_Analyze`, plus `io_locks` array.

**Phases:**

| Phase | Strategy | Target | Flex Source |
|---|---|---|---|
| 1. ADVANCE | Shorten blocked stage | blocked_unit, blocked_stage | `CalcTime - MinTime` |
| 2. DELAY | Extend conflict stage | conf_unit, conf_stage | `MaxTime - CalcTime` |
| 3. PRECEDING_DELAY | Extend conf's previous stage | conf_unit, conf_stage-1 | `MaxTime - CalcTime` |
| 4. DELAY_PREV_PAST_NEXT | Extend blocked stage (force order swap) | blocked_unit, blocked_stage | `MaxTime - CalcTime` |

**Cap Factor:** 90% if the batch is currently at that stage (`CurStage = ProgramStage`), 50% otherwise. This prevents over-adjustment on stages the batch hasn't reached yet.

**Each phase:**
1. Compute available flex from the target schedule stage
2. Apply cap factor, clamp to remaining deficit
3. Modify `CalcTime` and `ExitTime` of the target stage
4. Propagate via `STC_FB_ShiftSchedule` to all subsequent stages and matching task queue entries
5. Update `g_batch[].CalTime` (runtime remaining time)
6. Record lock (ADVANCE or DELAY) to prevent oscillation
7. Reduce `remain` by the applied amount

**Oscillation Prevention:**
- If a stage was locked with Direction=ADVANCE, it cannot be DELAY'd
- If a stage was locked with Direction=DELAY, it cannot be ADVANCE'd
- Locks persist for the entire scheduler cycle (cleared at phase 2200 once per cycle)

---

### 5.7 `TSK_FB_SwapTasks` — Same-Station Swap

**Purpose:** For each transporter queue, if consecutive tasks have `prev.SinkStation = next.LiftStation` (different units), swap their order. This avoids deadlock where the transporter would need to sink a unit at a station it also needs to lift from next.

---

### 5.8 `STC_FB_SortTaskQueue` — Priority Sort

**Purpose:** Insertion sort of transporter task queues.

**Priority comparator:**
1. **Emergency tasks first:** A task is emergency if `overtime_ratio > 1.0`, where `ratio = (now - batch.StartTime) / batch.MaxTime`, computed only when:
   - `batch.State = IN_PROCESS`
   - `batch.CurStage = g_schedule[unit].Stages[task.Stage].ProgramStage`
   - `unit.location = task.LiftStationTarget`
2. **Both emergency:** higher ratio first
3. **Neither emergency:** earlier `StartTime` first
4. **One emergency, one not:** emergency wins

---

### 5.9 `STC_FB_ShiftSchedule` — Time Propagation

**Purpose:** Propagates a time shift through a unit's schedule and all matching tasks.

**Inputs:**
- `i_unit` — unit to shift
- `i_from_stage` — first stage to shift (inclusive)
- `i_amount` — seconds (positive = delay, negative = advance)

**Behavior:**
1. Shifts `EntryTime` and `ExitTime` for stages `[from_stage..StageCount]`
2. Past-clamp: if advancing would put `EntryTime < now + 1`, clamp to `now + 1`
3. Shifts `StartTime` and `FinishTime` for tasks in all transporter queues where `task.Unit = unit AND task.Stage >= from_stage`

---

### 5.10 `STC_FB_DispatchTask` — Task Dispatcher

**Purpose:** Runs every scan. For each idle transporter with queued tasks:

1. **Time check:** Is it time to start? `travel_time_to_lift + 3s >= time_until_start`
2. **Sink station free?** Check if any unit occupies the sink station. If occupied, search parallel alternatives from `g_program[].Steps[]` (for treatment tasks) or `g_ntt[]` (for NTT tasks), picking the station with the oldest `ChangeTime`.
3. **Conflict check:** Ensure no other active transporter's task overlaps our lift/sink range.
4. **Dispatch:** Write `TaskId`, `LiftStationTarget`, `SinkStationTarget`, timing to `g_transporter[]`. Emit a `TASK_DISPATCHED` event. Shift queue (remove position 1).

**Schedule index → Program stage conversion:**
The dispatcher converts `task.Stage` (schedule index) to `prog_stage` via `g_schedule[unit].Stages[task.Stage].ProgramStage` for correct `g_program[].Steps[]` access when searching parallel stations.

---

### 5.11 `STC_FB_CollectActiveBatches` — Batch Filter

**Purpose:** Collects unit indices matching filter conditions.

| Mode | Filter | Use Case |
|---|---|---|
| 0 | `State=IN_PROCESS, CurStage 0..99, ProgId matches` | TSK: find active batches |
| 1 | Direct lookup at station 114, `State=NOT_PROCESSED` | DEP: find waiting batch |

---

### 5.12 `STC_FB_ClearTaskQueues` — Queue Reset

Zeros all fields in `g_task[1..3]`, including Count and all 60 Queue slots per transporter.

---

### 5.13 `STC_FB_EventQueue` — Event Queue Handler

**Purpose:** Manages a 10-slot circular event buffer for PLC → Gateway communication via Modbus.

**Protocol:**
1. Other FBs write to `g_event_pending`, set `g_event_pending_valid := TRUE`
2. EventQueue picks it up, assigns sequence number, adds to circular buffer
3. Head message is published to Modbus QW registers
4. Gateway reads, processes, writes `ack_seq` back via IW
5. On match: advance head, decrement count

**Event types:** TASK_DISPATCHED (1), LIFT (2), TASK_COMPLETE (3).

---

### 5.14 `DEP_FB_Scheduler` — Departure Scheduler

**Purpose:** Decides when and how to activate waiting batches (state=NOT_PROCESSED) onto the treatment line.

**Algorithm summary:**

1. **INIT:** Snapshot globals to sandbox. Find waiting batches. Sort by `StartTime` (FIFO).
2. **CALC_OVERLAP:** Identify stations covered by multiple transporters.
3. **For each waiting batch:**
   a. Calculate its schedule (`CalcSchedule`)
   b. Rebuild all tasks (active + waiting), sort, swap
   c. Extract waiting batch's tasks
   d. Inject in-flight pseudo-tasks for active transporters
   e. Calculate idle slots for all transporters
   f. **FIT_STAGE0:** Inline idle-slot scan for the pickup task. Accounts for travel time, overlap conflicts, `maxInitialWaitS` limit (120s).
   g. **FIT_TASK (stage 1+):** For each remaining task, check overlap delay + idle-slot fit:
      - Fits with small delay → continue to next task
      - Fits with large delay → record delay, recalculate (APPLY_DELAY → RECALC loop)
      - Doesn't fit → **backward chaining**: walk backward through tasks, accumulate flex from `MaxTime - CalcTime`. If enough flex exists, apply chain delays and recalculate. Otherwise REJECT.
   h. All fit → **ACTIVATE:** Write pending data, restore sandbox, set `g_dep_pending.Valid`
   i. Task doesn't fit → **REJECT:** Restore sandbox, try next waiting batch

**Sandbox mechanism:** DEP modifies globals directly (schedules, programs) during planning. If the batch doesn't fit, it restores from the sandbox snapshot. If it does fit, it writes to `g_dep_pending` and restores globals — TSK will apply the pending data at phase 10100.

---

### 5.15 `DEP_FB_Sandbox` — Snapshot/Restore

| Command | Action |
|---|---|
| 1 (SNAPSHOT) | Copy `g_schedule`, `g_batch`, `g_program`, `g_task` → sandbox |
| 2 (RESTORE) | Copy sandbox → globals (only entries that existed at snapshot time) |
| 3 (CLEAR) | Set `sandbox.Valid := FALSE` |

---

### 5.16 `DEP_FB_CalcIdleSlots` — Idle Slot Calculator

**Purpose:** Computes time gaps between consecutive tasks for one transporter. Each gap becomes an idle slot with start/end times and station context (where the transporter is at the slot boundaries). Used by `DEP_FB_FitTaskToSlot`.

---

### 5.17 `DEP_FB_FitTaskToSlot` — Idle Slot Fit Check

**Purpose:** Checks if a single waiting batch task fits into any idle slot of its transporter.

**Algorithm:**
1. For each idle slot:
   - Calculate travel time from slot's previous task sink → task lift
   - Calculate travel time from task sink → slot's next task lift
   - Compute `earliest` start and `latest` end
   - Check `earliest + task_duration <= latest`
   - Apply flex constraint: delay must be within `capped_flex = (MaxTime - CalcTime) × flex_factor`
2. Return best fitting slot (smallest delay) or report shortfall for backward chaining.

---

### 5.18 `DEP_FB_CalcOverlap` — Overlap Zone Detection

**Purpose:** Flags stations covered by 2+ transporters. Used by `DEP_FB_OverlapDelay` to detect multi-transporter conflicts.

---

### 5.19 `DEP_FB_OverlapDelay` — Overlap Conflict Resolution

**Purpose:** When a task uses a station in the overlap zone (shared by multiple transporters), iteratively calculates the minimum delay needed to avoid time conflicts with tasks on other transporters at the same station. Max 20 iterations.

---

### 5.20 `TSK_FB_NoTreatment` — Non-Treatment Task Creator

**Purpose:** Creates transfer tasks for units that have a target (TO_LOADING, TO_UNLOAD, TO_BUFFER, TO_AVOID) but are not part of the treatment schedule. Uses `g_ntt[]` (No-Treatment Task) destination tables per transporter per target type.

**Target resolution:**
- TO_LOADING (1) → NTT index 1
- TO_BUFFER (2) → NTT index 6 (empty), 7 (loaded), or 8 (processed) based on batch state
- TO_PROCESS (3) → NTT index 3
- TO_UNLOAD (4) → NTT index 4
- TO_AVOID (5) → NTT index 5

**Overlap conflict check:** Mirrors production `_hasOverlapConflict` — skips dispatching if another transporter shares the destination area and has conflicting active or queued tasks.

---

### 5.21 `STC_FB_NoTreatmentStates` — Unit Target State Machine

**Purpose:** Pre-computes unit states and manages non-treatment targets:

1. **PROCESSED:** Mark units at their last treatment stage as `State = PROCESSED`
2. **TO_AVOID:** If a unit's next treatment station is occupied, set `Target = TO_AVOID` to get it out of the way
3. **TO_LOADING:** Route one empty unit to the loading station when production queue is active

---

### 5.22 Pure Functions

#### `STC_CalcTransferTime`

Calculates total transfer time between two stations:
```
total = lift_time + dripping_time + drip_tray_delay
      + horizontal_travel_time
      + sink_time + drip_tray_delay + device_delay
```

All delay inputs are `INT ×10` (tenths of second). Uses precomputed `g_move[trans]` lookup table.

#### `STC_CalcHorizontalTravel`

Returns only the horizontal travel time (no lift/sink) from the precomputed move time table. Used by conflict analysis and departure planning.

#### `STC_FindTransporter`

Finds which transporter (1..3) covers a lift→sink station pair by checking `g_cfg[].TaskArea[]` ranges. Returns 0 if no transporter covers both stations.

---

## 6. Key Algorithms

### 6.1 Conflict Resolution — Convergence Loop

The scheduler's conflict resolution is iterative:

```
cycle:
  CalcSchedule (all batches)
  ClearTasks → CreateTasks (all batches)
  iteration := 0
  LOOP:
    Sort → Swap → Analyze
    if no conflict: exit LOOP
    if iteration >= 20: exit LOOP (accept partial)
    Resolve (apply flex to one stage)
    iteration++
    goto LOOP
  NoTreatment
  READY
```

Each `Resolve` call modifies schedule CalcTime/ExitTime for a single stage and propagates. The next iteration's Sort → Analyze may find the conflict resolved, find a new conflict, or find the same conflict reduced. Oscillation locks prevent infinite back-and-forth.

### 6.2 Departure Batch Activation — Backward Chaining

When a waiting batch's task doesn't fit into any idle slot even with flex, the departure scheduler walks backward through the batch's earlier tasks, accumulating available flex (MaxTime - CalcTime) from each. If accumulated flex covers the shortfall, delays are distributed across those earlier stages, programs are modified, and the schedule is recalculated.

```
task[5] doesn't fit — needs 30s extra
  task[4]: flex = 15s × 0.5 = 7.5s  → delay 7.5s, need 22.5s
  task[3]: flex = 60s × 0.5 = 30s   → delay 22.5s, need 0s ✓
Recalculate → retry all tasks
```

### 6.3 Schedule Index vs Program Stage

This is the most critical data model insight. The schedule array may contain a **prepend entry** at index 1 (when the unit needs to be moved to its first treatment station). In that case:

| Schedule Index | ProgramStage | Meaning |
|---|---|---|
| 1 | 0 | Pre-position entry (zero treatment time) |
| 2 | 1 | First treatment stage |
| 3 | 2 | Second treatment stage |
| ... | ... | ... |

Without prepend:

| Schedule Index | ProgramStage | Meaning |
|---|---|---|
| 1 | 1 | First treatment stage |
| 2 | 2 | Second treatment stage |
| ... | ... | ... |

**`task.Stage`** stores the **schedule array index** (used by Resolve/ShiftSchedule to access `g_schedule[unit].Stages[stage]`). To compare with `g_batch[].CurStage` (which is a program stage number), use `g_schedule[unit].Stages[task.Stage].ProgramStage`.

Affected FBs: `TSK_FB_Resolve` (5 comparisons), `STC_FB_SortTaskQueue` (2 comparisons), `STC_FB_DispatchTask` (parallel station search + NTT condition).

---

## 7. Configuration & Build

### 7.1 Plant Configuration

`plant_config.json` defines plant-specific limits:

```json
{
  "MAX_LINES": 1,
  "MAX_STATIONS_PER_LINE": 30,
  "MAX_TRANSPORTERS": 3,
  "MAX_UNITS": 10,
  "DEP_MAX_IDLE_SLOTS": 20,
  "DEP_MAX_WAITING": 5
}
```

`apply_plant_config.py` patches `globals.st` and `types.st` with these values before compilation.

### 7.2 Build Pipeline

```
plant_config.json
       │
       ▼
apply_plant_config.py → patches globals.st, types.st
       │
generate_globals.py   → generates GVL_JC_Scheduler variable declarations
generate_types.py     → generates type definitions
       │
build_plcxml.py       → assembles all .st files into plc.xml
       │
deploy_plc.sh         → uploads to PLC container, compiles, restarts
```

### 7.3 Station Numbering

Stations are numbered by line: `line_number × 100 + station_index`.

- Line 1: stations 101..130
- Line 2: stations 201..230

The station number IS the array index (`g_station[105]` = station 105). This eliminates lookup loops.

### 7.4 Time Reference

All times are absolute **unix seconds** stored as `LINT` (64-bit integer). The scheduler receives `i_time_s` from the simulation clock or real-time clock. This simplifies comparison and arithmetic — no relative-time conversions needed.

---

## 8. Porting Guide — TIA Portal / CODESYS

### 8.1 Syntax Differences

| Feature | MATIEC (OpenPLC) | TIA Portal (SCL) | Notes |
|---|---|---|---|
| Global constants | `VAR_GLOBAL CONSTANT` in GVL | Same | |
| External access | `VAR_EXTERNAL` | `VAR_EXTERNAL` or direct GVL access | TIA allows `"GVL".Variable` |
| LINT (64-bit) | Supported | S7-1500 only | S7-1200 needs DINT workaround |
| Array struct copy | `a := b` | Same | Full struct assignment |
| FUNCTION with struct input | Limited (MATIEC bug) | Works | FBs used as workaround |

### 8.2 Memory Considerations

Total scheduler memory footprint (approximate):

| Structure | Size | Count | Total |
|---|---|---|---|
| `g_schedule` (10 units × 30 stages) | ~300 × 44B | 1 | ~13 KB |
| `g_task` (3 trans × 60 tasks) | ~180 × 36B | 1 | ~6.5 KB |
| `g_dep_sandbox` | ~40 KB | 1 | ~40 KB |
| `g_move` (3 trans × 30×30 matrix) | ~5.4 KB | 1 | ~5.4 KB |
| Total | | | ~65 KB |

Well within S7-1500 work memory limits (typically 1-5 MB).

### 8.3 What to Exclude in Production

| Module | Reason |
|---|---|
| `SIM_FB_RunTasks` | Simulates transporter physics (X/Z motion) |
| `SIM_FB_XMotion`, `SIM_FB_ZMotion` | Physics simulation |
| `SIM_FB_ClearConfig` | Config reset for simulation |
| `UDT_JC_SimTransporterType` | Simulation-only fields |

Production PLC replaces `SIM_FB_RunTasks` with real drive controllers (FB_TransporterController). The scheduler's API contract is the same: it writes to `g_transporter[ti].TaskId/LiftStationTarget/SinkStationTarget`, and the drive controller reads those.
