(************************************************************
* OpenPLC - 2D Physics Core (Types)
************************************************************)

TYPE STATION_T :
STRUCT
  number : INT;
  x_mm : REAL;
  station_type : INT;
  device_delay_s : REAL;
  dropping_time_s : REAL;
END_STRUCT
END_TYPE

TYPE PHYSICS_2D_T :
STRUCT
  x_accel_s : REAL;
  x_decel_s : REAL;
  x_max_mm_s : REAL;
  z_total_mm : REAL;
  z_slow_dry_mm : REAL;
  z_slow_wet_mm : REAL;
  z_slow_end_mm : REAL;
  z_slow_mm_s : REAL;
  z_fast_mm_s : REAL;
  drip_delay_s : REAL;
  avoid_mm : REAL;
END_STRUCT
END_TYPE

TYPE TRANSPORTER_CFG_T :
STRUCT
  id : INT;
  start_station : INT;
  x_min_limit : REAL;
  x_max_limit : REAL;
  phys2d : PHYSICS_2D_T;
END_STRUCT
END_TYPE

TYPE TRANSPORTER_STATE_T :
STRUCT
  active : BOOL;
  phase : INT;
  z_stage : INT;
  x_mm : REAL;
  z_mm : REAL;
  vel_x : REAL;
  vel_z : REAL;
  current_station : INT;
  lift_station_target : INT;
  sink_station_target : INT;
  target_x : REAL;
  x_min_limit : REAL;
  x_max_limit : REAL;
  z_timer_s : REAL;
END_STRUCT
END_TYPE
