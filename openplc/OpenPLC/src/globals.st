(* ============================================================
   globals.st — Global variables (shared memory + Modbus I/O)
   ============================================================ *)

VAR_GLOBAL
  (* --- Shared data arrays --- *)
  g_station_count    : INT := 0;
  g_stations         : ARRAY[1..21] OF STATION_T;
  g_cfg              : ARRAY[1..10] OF TRANSPORTER_CFG_T;
  g_state            : ARRAY[1..10] OF TRANSPORTER_STATE_T;
  g_cmd_start        : ARRAY[1..10] OF BOOL;
  g_cmd_lift_station : ARRAY[1..10] OF INT;
  g_cmd_sink_station : ARRAY[1..10] OF INT;

  (* --- Modbus OUTPUT: Transporter 1 (QW0..QW8) --- *)
  qw_t1_x_mm    AT %QW0  : INT;
  qw_t1_z_mm    AT %QW1  : INT;
  qw_t1_vel_x10 AT %QW2  : INT;
  qw_t1_phase   AT %QW3  : INT;
  qw_t1_z_stage AT %QW4  : INT;
  qw_t1_cur_st  AT %QW5  : INT;
  qw_t1_lift_tgt AT %QW6 : INT;
  qw_t1_sink_tgt AT %QW7 : INT;
  qw_t1_active  AT %QW8  : INT;

  (* --- Modbus OUTPUT: Transporter 2 (QW9..QW17) --- *)
  qw_t2_x_mm    AT %QW9  : INT;
  qw_t2_z_mm    AT %QW10 : INT;
  qw_t2_vel_x10 AT %QW11 : INT;
  qw_t2_phase   AT %QW12 : INT;
  qw_t2_z_stage AT %QW13 : INT;
  qw_t2_cur_st  AT %QW14 : INT;
  qw_t2_lift_tgt AT %QW15 : INT;
  qw_t2_sink_tgt AT %QW16 : INT;
  qw_t2_active  AT %QW17 : INT;

  (* --- Modbus OUTPUT: Status (QW18..QW20) --- *)
  qw_station_cnt AT %QW18 : INT;
  qw_init_done   AT %QW19 : INT;
  qw_cycle_cnt   AT %QW20 : INT;

  (* --- Modbus INPUT: Commands (IW0..IW5) --- *)
  iw_cmd_start_1 AT %IW0 : INT;
  iw_cmd_lift_1  AT %IW1 : INT;
  iw_cmd_sink_1  AT %IW2 : INT;
  iw_cmd_start_2 AT %IW3 : INT;
  iw_cmd_lift_2  AT %IW4 : INT;
  iw_cmd_sink_2  AT %IW5 : INT;
END_VAR
