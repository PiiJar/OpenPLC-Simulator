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
  stn_type      : INT;
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

TYPE TRANSPORTER_STATE_T :
STRUCT
  active               : BOOL;
  phase                : INT;
  z_stage              : INT;
  x_mm                 : REAL;
  z_mm                 : REAL;
  vel_x                : REAL;
  vel_z                : REAL;
  current_station      : INT;
  lift_station_target  : INT;
  sink_station_target  : INT;
  target_x             : REAL;
  x_min_limit          : REAL;
  x_max_limit          : REAL;
  z_timer_s            : REAL;
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

(* Precomputed movement times — timed from real motions, not calculated *)
(* Index 1..25 maps to station 101..125 (idx = stn_num - 100)           *)
(* Access: g_move[transporter].travel[from_idx].to_s[to_idx]            *)

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
