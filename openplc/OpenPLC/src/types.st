(* ============================================================
   types.st — Data type definitions for the transporter simulator
   ============================================================ *)

TYPE TANK_T :
STRUCT
  tank_id    : INT;
  status     : INT;    (* NOT_USED=0, USED=1 *)
  x_position : REAL;
  y_position : REAL;
  z_position : REAL;
  stn_type   : INT;
END_STRUCT;
END_TYPE

TYPE STATION_T :
STRUCT
  tank_id       : INT;
  status        : INT;    (* NOT_USED=0, USED=1 *)
  x_position    : REAL;
  y_position    : REAL;
  z_position    : REAL;
  stn_type      : INT;    (* 0=dry, 1=wet *)
  stn_function  : INT;    (* original station type from JSON *)
  dropping_time : REAL;
  device_delay  : REAL;
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
  x_min_limit : REAL;
  x_max_limit : REAL;
  y_min_limit : REAL;
  y_max_limit : REAL;
  x_avoid_mm  : REAL;
  y_avoid_mm  : REAL;
  phys2d      : PHYSICS_2D_T;
  task_area   : ARRAY[1..4] OF TASK_AREA_T;
END_STRUCT;
END_TYPE

(* ── Transporter interface — production-compatible ──────────── *)
(* Used by scheduler, TWA, simulation, and production alike.     *)
(* g_transporter : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T              *)
TYPE STC_TRANSPORTER_T :
STRUCT
  (* --- Command (scheduler → transporter) --- *)
  task_id            : LINT;     (* g_time_s at assignment — sync key *)
  lift_station       : INT;      (* pickup station number *)
  sink_station       : INT;      (* putdown station number *)
  treatment_time     : REAL;     (* treatment duration (s) *)
  lift_device_delay  : REAL;     (* lift station device delay (s) *)
  sink_device_delay  : REAL;     (* sink station device delay (s) *)
  dropping_time      : REAL;     (* dripping/dropping time at lift (s) *)
  (* --- Status (transporter → outside world) --- *)
  status             : INT;      (* 0=not_used 1=manual 2=half_manual 3=auto_idle 4=auto_run *)
  phase              : INT;      (* 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking *)
  running_task_id    : LINT;     (* copied from task_id when accepted *)
  current_station    : INT;      (* nearest station number *)
  remaining_time     : REAL;     (* remaining treatment time (s) *)
  (* --- Drive (runtime / TWA) --- *)
  final_target_x     : REAL;     (* destination X (station position) *)
  drive_target_x     : REAL;     (* TWA-clamped X drive target *)
  final_target_y     : REAL;     (* destination Y (3D transporter) *)
  drive_target_y     : REAL;     (* TWA-clamped Y drive target *)
  x_mm               : REAL;     (* current X position *)
  y_mm               : REAL;     (* current Y position (3D) *)
  z_mm               : REAL;     (* current Z position *)
  vel_x              : REAL;     (* X velocity *)
  z_stage            : INT;      (* Z motion sub-phase *)
  z_timer_s          : REAL;     (* Z motion timer *)
  x_min_limit        : REAL;     (* TWA lower X limit *)
  x_max_limit        : REAL;     (* TWA upper X limit *)
  (* --- General --- *)
  active             : BOOL;     (* transporter enabled *)
END_STRUCT;
END_TYPE

TYPE BATCH_T :
STRUCT
  batch_code : INT;     (* numeric batch code, e.g. 1, 2, 3 *)
  state      : INT;     (* NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2 *)
  prog_id    : INT;     (* treatment program number *)
  cur_stage  : INT;     (* current stage number, 0 = not started *)
END_STRUCT;
END_TYPE

TYPE PROGRAM_STAGE_T :
STRUCT
  stations : ARRAY[1..5] OF INT;   (* up to MAX_PARALLELS station numbers *)
  min_time : INT;                   (* minimum processing time (seconds) *)
  max_time : INT;                   (* maximum processing time (seconds) *)
  cal_time : INT;                   (* calculated / target time (seconds) *)
END_STRUCT;
END_TYPE

TYPE TREATMENT_PROGRAM_T :
STRUCT
  program_id : INT;                      (* treatment program number *)
  stages     : ARRAY[1..30] OF PROGRAM_STAGE_T;  (* up to MAX_STAGES *)
END_STRUCT;
END_TYPE

TYPE UNIT_T :
STRUCT
  location : INT;    (* station number where unit currently is *)
  status   : INT;    (* NOT_USED=0, USED=1 *)
  state    : INT;    (* EMPTY=0, FULL=1 *)
  target   : INT;    (* TO_NONE=0, TO_LOADING=1, TO_BUFFER=2, TO_PROCESS=3, TO_UNLOAD=4, TO_AVOID=5 *)
END_STRUCT;
END_TYPE

(* ── Task Scheduler types (TSK_) ─────────────────────────────────── *)
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
  stages      : ARRAY[1..30] OF TSK_STAGE_T;     (* MAX_STAGES *)
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
  queue : ARRAY[1..10] OF TSK_TASK_T;             (* task slots, MAX_UNITS *)
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
  x_min        : REAL;    (* X-area minimum (mm) *)
  x_max        : REAL;    (* X-area maximum (mm) *)
  is_conflict  : BOOL;    (* TRUE if this task is in conflict *)
END_STRUCT;
END_TYPE

(* Precomputed movement times — timed from real motions, not calculated *)
(* Station number IS the array index (STATION_ARRAY_START..STATION_ARRAY_END) *)
(* Access: g_move[transporter].travel[from_stn].to_s[to_stn]            *)

TYPE TRAVEL_FROM_T :
STRUCT
  to_s : ARRAY[1..25] OF REAL;   (* travel time to each station (seconds) *)
END_STRUCT;
END_TYPE

TYPE MOVE_TIMES_T :
STRUCT
  lift_s  : ARRAY[1..25] OF REAL;           (* lift time per station (seconds) *)
  sink_s  : ARRAY[1..25] OF REAL;           (* sink time per station (seconds) *)
  travel  : ARRAY[1..25] OF TRAVEL_FROM_T;  (* travel[from].to_s[to] (seconds) *)
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
  slots : ARRAY[1..20] OF DEP_IDLE_SLOT_T;
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
  flags : ARRAY[101..450] OF BOOL;  (* TRUE = station is in overlap zone — literal required in TYPE *)
  count : INT;
END_STRUCT;
END_TYPE

(* Sandbox: isolated copy of scheduler state for departure planning *)

TYPE DEP_SANDBOX_T :
STRUCT
  schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;
  batches  : ARRAY[1..10] OF BATCH_T;
  programs : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  tasks    : ARRAY[1..3] OF TSK_QUEUE_T;   (* literal — TYPE cannot use constants *)
  valid    : BOOL;
END_STRUCT;
END_TYPE

(* Pending write: data to commit from sandbox to globals after ACTIVATE *)

TYPE DEP_PENDING_WRITE_T :
STRUCT
  valid      : BOOL;
  programs   : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  schedule   : ARRAY[1..10] OF TSK_SCHEDULE_T;
  batch_unit : INT;     (* activated batch: unit index *)
  batch_stage : INT;    (* activated batch: new stage *)
  time_s     : LINT;    (* activation time (s), unix seconds *)
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
