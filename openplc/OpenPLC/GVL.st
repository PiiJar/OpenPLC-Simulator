(************************************************************
* OpenPLC - 2D Physics Core (Globals)
************************************************************)

VAR_GLOBAL CONSTANT
  MAX_TRANSPORTERS : INT := 10;
  MAX_STATIONS : INT := 21;
  DT_S : REAL := 0.02;

  PHASE_IDLE : INT := 0;
  PHASE_MOVE_TO_LIFT : INT := 1;
  PHASE_LIFTING : INT := 2;
  PHASE_MOVE_TO_SINK : INT := 3;
  PHASE_SINKING : INT := 4;

  Z_IDLE : INT := 0;
  Z_DELAY_UP : INT := 1;
  Z_UP_SLOW : INT := 2;
  Z_UP_FAST : INT := 3;
  Z_UP_SLOW_END : INT := 4;
  Z_DRIP_UP : INT := 5;
  Z_DELAY_DOWN : INT := 6;
  Z_DOWN_FAST : INT := 7;
  Z_DOWN_SLOW : INT := 8;
END_VAR

VAR_GLOBAL
  g_station_count : INT := 0;
  g_stations : ARRAY[1..MAX_STATIONS] OF STATION_T;

  g_cfg : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_state : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_STATE_T;

  (* Manual commands for test driving *)
  g_cmd_start : ARRAY[1..MAX_TRANSPORTERS] OF BOOL;
  g_cmd_lift_station : ARRAY[1..MAX_TRANSPORTERS] OF INT;
  g_cmd_sink_station : ARRAY[1..MAX_TRANSPORTERS] OF INT;
END_VAR
