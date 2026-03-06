(* ============================================================
   types.st — Data type definitions for the transporter simulator
   ============================================================ *)

TYPE TANK_T :
STRUCT
  TankId    : INT;
  status     : INT;    (* NOT_USED=0, USED=1 *)
  XPosition    : DINT;
  YPosition    : DINT;
  ZPosition    : DINT;
  kind       : INT;
END_STRUCT;
END_TYPE

TYPE UDT_StationType :
STRUCT
  StationId            : INT;   (* Primary key *)
  TankId               : INT;   (* Reference to tanks.TankId *)
  IsInUse              : BOOL;  (* Station enabled *)
  StationType          : INT;   (* 0=Reserve, 1=Buffer, 2=Process, etc. *)
  UnitId               : INT;   (* unit currently at this station, 0 = none *)
  ChangeTime           : LINT;  (* timestamp of last unit arrival/departure (unix seconds) *)
  (* Position in mm *)
  XPosition            : DINT;  (* X position mm *)
  YPosition            : DINT;  (* Y position mm *)
  ZPosition            : DINT;  (* Z position mm *)
  LiftSinkZone         : INT;   (* Lift/sink zone *)
  AvoidDistance         : INT;   (* Avoid distance *)
  TakeOutDistance       : INT;   (* Take out distance *)
  DrippingTime         : INT;   (* Dripping time ×10 = tenths of second *)
  DeviceDelay          : INT;   (* Device delay ×10 = tenths of second *)
  DryWet               : INT;   (* 0=dry, 1=wet *)
  (* Cross transport parameters *)
  Crosstransport       : INT;   (* Cross transport index *)
  CrossTransportTime   : INT;   (* Cross transport time s *)
  ChangeStation        : INT;   (* Change station index *)
  DeviceConfig         : INT;   (* Device configuration *)
  (* Control indices *)
  Temp_Index           : INT;   (* Temperature control index *)
  Level_Index          : INT;   (* Level control index *)
  Cond_Index           : INT;   (* Conductivity control index *)
  (* Rotation *)
  HasAutomaticRotation : BOOL;  (* TRUE = chemical tank *)
END_STRUCT;
END_TYPE

TYPE UDT_UnitLocation :
STRUCT
  UnitId     : INT;   (* unit currently at this station, 0 = none *)
  ChangeTime : LINT;  (* timestamp of last unit arrival/departure (unix seconds) *)
END_STRUCT;
END_TYPE

TYPE PHYSICS_2D_T :
STRUCT
  x_accel_s      : REAL;
  x_decel_s      : REAL;
  x_max_mm_s     : REAL;
  z_total_mm     : REAL;
  z_slow_dry_mm  : REAL;
  z_slow_wet_mm  : REAL;
  z_slow_end_mm  : REAL;
  z_slow_mm_s    : REAL;
  z_fast_mm_s    : REAL;
  drip_delay_s   : REAL;
  avoid_mm       : REAL;
END_STRUCT;
END_TYPE

TYPE TASK_AREA_T :
STRUCT
  min_lift : INT;
  max_lift : INT;
  min_sink : INT;
  max_sink : INT;
END_STRUCT;
END_TYPE

TYPE TRANSPORTER_CFG_T :
STRUCT
  XMinLimit   : DINT;
  XMaxLimit   : DINT;
  YMinLimit   : DINT;
  YMaxLimit   : DINT;
  XAvoidMm    : DINT;
  YAvoidMm    : DINT;
  phys2d      : PHYSICS_2D_T;
  task_area   : ARRAY[1..3] OF TASK_AREA_T;  (* MAX_Transporters_PER_LINE — literal required in TYPE *)
END_STRUCT;
END_TYPE

(* ── Transporter interface — production-compatible ──────────── *)
(* Used by scheduler, TWA, simulation, and production alike.     *)
(* g_transporter : ARRAY[1..MAX_Transporters] OF STC_TRANSPORTER_T              *)
TYPE STC_TRANSPORTER_T :
STRUCT
  (* --- Command (scheduler → transporter) --- *)
  task_id            : LINT;     (* g_time_s at assignment — sync key *)
  lift_station       : INT;      (* pickup station number *)
  sink_station       : INT;      (* putdown station number *)
  treatment_time     : REAL;     (* treatment duration (s) *)
  min_time           : REAL;     (* minimum treatment time (s) — from task queue *)
  max_time           : REAL;     (* maximum treatment time (s) — from task queue *)
  lift_device_delay  : REAL;     (* lift station device delay (s) *)
  sink_device_delay  : REAL;     (* sink station device delay (s) *)
  dropping_time      : REAL;     (* dripping/dropping time at lift (s) *)
  (* --- Status (transporter → outside world) --- *)
  status             : INT;      (* 0=not_used 1=manual 2=half_manual 3=auto_idle 4=auto_run *)
  phase              : INT;      (* 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking *)
  UnitId            : INT;      (* unit currently being transported, 0 = none *)
  running_task_id    : LINT;     (* copied from task_id when accepted *)
  current_station    : INT;      (* nearest station number *)
  remaining_time     : REAL;     (* remaining treatment time (s) *)
  (* --- Drive (runtime / TWA) --- *)
  XFinalTarget       : DINT;     (* destination X (station position) mm *)
  XDriveTarget       : DINT;     (* TWA-clamped X drive target mm *)
  YFinalTarget       : DINT;     (* destination Y (3D transporter) mm *)
  YDriveTarget       : DINT;     (* TWA-clamped Y drive target mm *)
  XPosition          : DINT;     (* current X position mm *)
  YPosition          : DINT;     (* current Y position mm *)
  ZPosition          : DINT;     (* current Z position mm *)
  XVelocity          : DINT;     (* X velocity mm/s *)
  z_stage            : INT;      (* Z motion sub-phase *)
  z_timer_s          : REAL;     (* Z motion timer *)
  XMinLimit          : DINT;     (* TWA lower X limit mm *)
  XMaxLimit          : DINT;     (* TWA upper X limit mm *)
  (* --- General --- *)
  active             : BOOL;     (* transporter enabled *)
END_STRUCT;
END_TYPE

TYPE BATCH_T :
STRUCT
  batch_code  : INT;     (* numeric batch code — JS: batch_id *)
  cur_stage   : INT;     (* current stage number, 0 = not started — JS: stage *)
  state       : INT;     (* NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2 *)
  prog_id     : INT;     (* treatment program number — JS: treatment_program *)
  start_time  : LINT;    (* batch start time (unix seconds) — JS: start_time *)
  min_time    : INT;     (* stage 0 minimum time (seconds) *)
  max_time    : INT;     (* stage 0 maximum time (seconds) *)
  cal_time    : INT;     (* stage 0 calculated / target time (seconds) *)
END_STRUCT;
END_TYPE

TYPE PROGRAM_STAGE_T :
STRUCT
  stations : ARRAY[1..5] OF INT;   (* up to MAX_STATIONS_PER_STEP station numbers *)
  min_time : INT;                   (* minimum processing time (seconds) *)
  max_time : INT;                   (* maximum processing time (seconds) *)
  cal_time : INT;                   (* calculated / target time (seconds) *)
END_STRUCT;
END_TYPE

TYPE TREATMENT_PROGRAM_T :
STRUCT
  program_id : INT;                      (* treatment program number *)
  stages     : ARRAY[1..30] OF PROGRAM_STAGE_T;  (* up to MAX_STEPS_PER_PROGRAM *)
END_STRUCT;
END_TYPE

TYPE UNIT_T :
STRUCT
  location : INT;    (* station number where unit currently is *)
  status   : INT;    (* NOT_USED=0, USED=1 *)
  target   : INT;    (* TO_NONE=0, TO_LOADING=1, TO_BUFFER=2, TO_PROCESS=3, TO_UNLOAD=4, TO_AVOID=5 *)
END_STRUCT;
END_TYPE

(* Snapshot of unit state — pre-computed once per cycle by NoTreatmentStates *)
TYPE UNIT_SNAP_T :
STRUCT
  active     : BOOL;   (* status <> NOT_USED *)
  loc        : INT;    (* location *)
  loc_op     : INT;    (* station operation at location *)
  tgt        : INT;    (* target *)
  has_batch  : BOOL;   (* batch_code <> 0 *)
  bstate     : INT;    (* batch state *)
  cur_stage  : INT;    (* current stage from g_batch *)
  in_buffer  : BOOL;   (* loc operation 44..47 *)
  on_station : BOOL;   (* loc in STATION_ARRAY range *)
  elapsed    : LINT;   (* time at station, 0 if not on station *)
  cal        : INT;    (* cal_time for current stage *)
END_STRUCT;
END_TYPE

(* ── No-Treatment Task destination types (NTT_) ─────────────────── *)
(* Per target per transporter: which stations a unit can be moved to  *)
(* Mirrors no_treatment_tasks.json structure                          *)

TYPE NTT_DEST_T :
STRUCT
  stations          : ARRAY[1..5] OF INT;   (* primary stations, up to MAX_STATIONS_PER_STEP *)
  station_count     : INT;                   (* how many primary stations are valid *)
  fallback_stations : ARRAY[1..5] OF INT;   (* fallback stations, up to MAX_STATIONS_PER_STEP *)
  fallback_count    : INT;                   (* how many fallback stations are valid *)
END_STRUCT;
END_TYPE

TYPE NTT_TRANSPORTER_T :
STRUCT
  (* Index = target code: 1=TO_LOADING, 2=(reserved), 3=TO_PROCESS, 4=TO_UNLOAD, 5=TO_AVOID,
     6=TO_EMPTY_BUFFER, 7=TO_LOADED_BUFFER, 8=TO_PROCESSED_BUFFER *)
  target : ARRAY[1..8] OF NTT_DEST_T;
END_STRUCT;
END_TYPE

(* ── Task Scheduler types (TSK_) ─────────────────────────────────── *)

(* Oscillation lock: prevents resolve from advancing&delaying same stage *)
(* Used by TSK_FB_Resolve via VAR_IN_OUT from TSK_FB_Scheduler          *)
TYPE TSK_LOCK_T :
STRUCT
  unit      : INT;     (* batch unit index, 0 = empty slot *)
  stage     : INT;     (* program stage *)
  direction : INT;     (* 1=ADVANCE, 2=DELAY *)
END_STRUCT;
END_TYPE

(* Calculated batch schedule — one per unit, stages indexed 1..30       *)
(* Times are absolute epoch-offset seconds (g_time_s reference frame)   *)
(* Access: g_schedule[unit].stages[stage].entry_time                    *)

TYPE TSK_STAGE_T :
STRUCT
  station       : INT;     (* station number, 0 = unused stage *)
  entry_time    : LINT;    (* absolute arrival time (s), unix seconds *)
  exit_time     : LINT;    (* absolute departure time (s), unix seconds *)
  min_time      : REAL;    (* minimum treatment time (s) *)
  calc_time     : REAL;    (* calculated target treatment time (s) *)
  max_time      : REAL;    (* maximum treatment time (s) *)
  transfer_time : REAL;    (* transfer time from previous station (s) *)
END_STRUCT;
END_TYPE

TYPE TSK_SCHEDULE_T :
STRUCT
  stage_count : INT;                              (* number of active stages *)
  stages      : ARRAY[1..30] OF TSK_STAGE_T;     (* MAX_STEPS_PER_PROGRAM *)
END_STRUCT;
END_TYPE

(* Transporter task queue — indexed by transporter, then task slot       *)
(* unit is direct index to g_batch, g_program, g_schedule, g_unit   *)
(* Access: g_task[transporter].queue[slot].lift_station                *)

TYPE TSK_TASK_T :
STRUCT
  unit         : INT;     (* unit index 1..10, 0 = no task *)
  stage        : INT;     (* program stage that created this task *)
  lift_station : INT;     (* station to pick up from *)
  sink_station : INT;     (* station to put down to *)
  start_time   : LINT;    (* absolute time task begins (s), unix seconds *)
  finish_time  : LINT;    (* absolute time task completes (s), unix seconds *)
  calc_time    : REAL;    (* treatment calc_time for flex (s) *)
  min_time     : REAL;    (* treatment min_time for flex_down (s) *)
  max_time     : REAL;    (* treatment max_time for flex_up (s) *)
END_STRUCT;
END_TYPE

TYPE TSK_QUEUE_T :
STRUCT
  count : INT;                                    (* number of active tasks *)
  queue : ARRAY[1..10] OF TSK_TASK_T;             (* task slots, MAX_TASK_QUEUE — literal required in TYPE *)
END_STRUCT;
END_TYPE

(* Conflict analysis — internal working data for FB_AnalyzeConflicts    *)

TYPE TSK_CHECKED_T :
STRUCT
  unit         : INT;     (* batch unit index *)
  stage        : INT;     (* program stage *)
  transporter  : INT;     (* assigned transporter *)
  start_time   : LINT;    (* task start (s), unix seconds *)
  end_time     : LINT;    (* task end (s), unix seconds *)
  flex_down    : REAL;    (* available advance margin (s) *)
  flex_up      : REAL;    (* available delay margin (s) *)
  XMin         : DINT;    (* X-area minimum (mm) *)
  XMax         : DINT;    (* X-area maximum (mm) *)
  is_conflict  : BOOL;    (* TRUE if this task is in conflict *)
END_STRUCT;
END_TYPE

(* Precomputed movement times — timed from real motions, not calculated *)
(* Station number IS the array index (MIN_StationIndex..MAX_StationIndex) *)
(* Access: g_move[transporter].travel[from_stn].to_s[to_stn]            *)

TYPE TRAVEL_FROM_T :
STRUCT
  to_s : ARRAY[1..30] OF REAL;   (* travel time to each station (seconds), MAX_STATIONS_PER_LINE *)
END_STRUCT;
END_TYPE

TYPE MOVE_TIMES_T :
STRUCT
  lift_s  : ARRAY[1..30] OF REAL;           (* lift time per station (seconds), MAX_STATIONS_PER_LINE *)
  sink_s  : ARRAY[1..30] OF REAL;           (* sink time per station (seconds), MAX_STATIONS_PER_LINE *)
  travel  : ARRAY[1..30] OF TRAVEL_FROM_T;  (* travel[from].to_s[to] (seconds), MAX_STATIONS_PER_LINE *)
END_STRUCT;
END_TYPE

(* ── Departure Scheduler types (DEP_) ────────────────────────────── *)
(* Idle slot: a time window where a transporter has no tasks           *)
(* Used by departure scheduler to fit new batch activations            *)

TYPE DEP_IDLE_SLOT_T :
STRUCT
  start_time   : LINT;    (* idle window start (s), unix seconds *)
  end_time     : LINT;    (* idle window end (s), 0 = open-ended *)
  lift_station : INT;     (* transporter at this station at idle start *)
  sink_station : INT;     (* transporter at this station at idle end *)
END_STRUCT;
END_TYPE

TYPE DEP_IDLE_SLOT_SET_T :
STRUCT
  slots : ARRAY[1..20] OF DEP_IDLE_SLOT_T;  (* DEP_MAX_IDLE_SLOTS — literal required in TYPE *)
  count : INT;
END_STRUCT;
END_TYPE

(* Fit result: outcome of trying to fit a departure task into idle slots *)

TYPE DEP_FIT_RESULT_T :
STRUCT
  fits         : BOOL;    (* TRUE = task fits in a slot *)
  delay_s      : REAL;    (* delay needed to make it fit (s) *)
  need_extra_s : REAL;    (* extra time that does not fit (s) *)
  task_end_s   : LINT;    (* calculated task end time (s), unix seconds *)
  slot_idx     : INT;     (* index of the used idle slot *)
  trans_id     : INT;     (* transporter id that can handle it *)
END_STRUCT;
END_TYPE

(* Delay action: a schedule adjustment to accommodate departure *)

TYPE DEP_DELAY_ACTION_T :
STRUCT
  stage   : INT;     (* program stage to delay *)
  delay_s : REAL;    (* delay amount (s) *)
  target  : INT;     (* 0=batch cur_stage delay, 1=program stage delay *)
  valid   : BOOL;
END_STRUCT;
END_TYPE

(* Overlap: stations covered by multiple transporters *)

TYPE DEP_OVERLAP_T :
STRUCT
  flags : ARRAY[101..130] OF BOOL;  (* TRUE = station is in overlap zone — G09: full 0..200 domain like JS *)
  count : INT;
END_STRUCT;
END_TYPE

(* Sandbox: isolated copy of scheduler state for departure planning *)

TYPE DEP_SANDBOX_T :
STRUCT
  schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;           (* MAX_Units *)
  batches  : ARRAY[1..10] OF BATCH_T;                   (* MAX_Units *)
  programs : ARRAY[1..10] OF TREATMENT_PROGRAM_T;       (* MAX_Units *)
  tasks    : ARRAY[1..3] OF TSK_QUEUE_T;                (* MAX_Transporters — literal required in TYPE *)
  valid    : BOOL;
END_STRUCT;
END_TYPE

(* Pending write: data to commit from sandbox to globals after ACTIVATE *)

TYPE DEP_PENDING_WRITE_T :
STRUCT
  valid      : BOOL;
  programs   : ARRAY[1..10] OF TREATMENT_PROGRAM_T;    (* MAX_Units *)
  schedule   : ARRAY[1..10] OF TSK_SCHEDULE_T;          (* MAX_Units *)
  batch_unit       : INT;     (* activated batch: unit index *)
  batch_stage      : INT;     (* activated batch: new cur_stage *)
  batch_state      : INT;     (* activated batch: new state (IN_PROCESS=1) *)
  batch_min_time   : INT;     (* stage 0 min_time for activated batch *)
  batch_max_time   : INT;     (* stage 0 max_time for activated batch *)
  batch_cal_time   : INT;     (* stage 0 cal_time for activated batch *)
  time_s           : LINT;    (* activation time (s), unix seconds *)
END_STRUCT;
END_TYPE

(* ── Calibration teaching type ─────────────────────────────────── *)
(* One per transporter. Gateway writes plan, PLC fills results.      *)
(* Only wet_station + dry_station needed: 2 normal tasks per         *)
(* transporter give all lift/sink/travel measurements.               *)
(*   Task 1: lift=dry, sink=wet → lift_dry, sink_wet, travel dry→wet *)
(*   Task 2: lift=wet, sink=dry → lift_wet, sink_dry, travel wet→dry *)
TYPE CALIBRATION_T :
STRUCT
  (* Plan — set by gateway via cfg_cmd=7 *)
  wet_station   : INT;    (* wet station number *)
  dry_station   : INT;    (* dry station number *)
  (* Results — read from g_move after MeasureMoveTimes records them *)
  lift_wet_s    : REAL;   (* lift time at wet station (s) *)
  sink_wet_s    : REAL;   (* sink time at wet station (s) *)
  lift_dry_s    : REAL;   (* lift time at dry station (s) *)
  sink_dry_s    : REAL;   (* sink time at dry station (s) *)
  x_accel_s     : REAL;   (* measured acceleration time (s) *)
  x_decel_s     : REAL;   (* measured deceleration time (s) *)
  x_max_mm_s    : REAL;   (* measured max X speed (mm/s) *)
END_STRUCT;
END_TYPE

(* ── Event message queue (PLC → Gateway) ──────────────────────
   Generic message with type-dependent payload fields.
   msg_type determines the meaning of f[1..12]:

   msg_type=1 (TASK_DISPATCHED):
     f[1]=transporter  f[2]=UnitId  f[3]=lift_stn  f[4]=sink_stn
     f[5]=stage  f[6]=batch_code  f[7]=batch_state  f[8]=batch_program
     f[9]=target  f[10]=calc_time_x10  f[11]=min_time_x10  f[12]=max_time_x10

   msg_type=2 (LIFT):
     f[1]=transporter  f[2]=UnitId  f[3]=station  f[4]=batch_code
     f[5]=batch_state  f[6]=batch_program  f[7]=stage
     f[8]=actual_time_x10  f[9]=calc_time_x10  f[10]=min_time_x10
     f[11]=max_time_x10  f[12]=reserved

   Handshake: PLC outputs head message via Modbus.
   Gateway reads it, processes it, writes ack_seq = head.seq.
   PLC sees ack match → advances head, count--.
   ─────────────────────────────────────────────────────────── *)

TYPE EVENT_MSG_T :
STRUCT
  seq      : INT;                  (* unique incrementing sequence number *)
  msg_type : INT;                  (* 1=task_dispatched, 2=lift, ... *)
  ts_hi    : INT;                  (* timestamp upper 16 bits (unix s) *)
  ts_lo    : INT;                  (* timestamp lower 16 bits *)
  f        : ARRAY[1..12] OF INT;  (* payload — meaning depends on msg_type *)
END_STRUCT;
END_TYPE

TYPE EVENT_QUEUE_T :
STRUCT
  count    : INT;                  (* messages currently in queue (0..10) *)
  head     : INT;                  (* index of oldest message, 1-based *)
  next_seq : INT;                  (* next sequence number to assign *)
  buf      : ARRAY[1..10] OF EVENT_MSG_T;  (* circular buffer *)
END_STRUCT;
END_TYPE
