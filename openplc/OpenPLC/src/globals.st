(* ============================================================
   globals.st — Global variables (shared memory + Modbus I/O)
   ============================================================ *)

VAR_GLOBAL CONSTANT
  MAX_STATIONS     : INT := 25;    (* stations 101..125 *)
  MAX_TRANSPORTERS : INT := 3;     (* transporters 1..3 *)
  MAX_UNITS        : INT := 10;    (* units 1..10 *)
  (* Unit status *)
  USED             : INT := 1;
  NOT_USED         : INT := 0;
  (* Unit state *)
  EMPTY            : INT := 0;
  NOT_PROCESSED    : INT := 1;
  IN_PROCESS       : INT := 2;
  PROCESSED        : INT := 3;
  (* Unit target *)
  TO_NONE          : INT := 0;
  TO_LOADING       : INT := 1;
  TO_BUFFER        : INT := 2;
  TO_UNLOAD        : INT := 3;
  TO_AVOID         : INT := 4;
END_VAR

VAR_GLOBAL
  (* --- Shared data arrays --- *)
  g_station_count    : INT := 0;
  g_stations         : ARRAY[101..125] OF STATION_T;
  g_cfg              : ARRAY[1..3] OF TRANSPORTER_CFG_T;
  g_state            : ARRAY[1..3] OF TRANSPORTER_STATE_T;
  g_cmd_start        : ARRAY[1..3] OF BOOL;
  g_cmd_lift_station : ARRAY[1..3] OF INT;
  g_cmd_sink_station : ARRAY[1..3] OF INT;
  g_units            : ARRAY[1..10] OF UNIT_T;

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

  (* --- Config upload protocol (IW10..IW19, QW21) --- *)
  (*   Gateway writes station config one at a time.
       Sequence number change triggers PLC processing.
       cmd=1: write station, cmd=2: finish init         *)
  iw_cfg_seq       AT %IW10 : INT;   (* sequence number — triggers on change *)
  iw_cfg_cmd       AT %IW11 : INT;   (* 1=write_station, 2=init_transporters *)
  iw_cfg_param     AT %IW12 : INT;   (* station_number or station_count *)
  iw_cfg_d0        AT %IW13 : INT;   (* tank_id *)
  iw_cfg_d1        AT %IW14 : INT;   (* x_position mm *)
  iw_cfg_d2        AT %IW15 : INT;   (* y_position mm *)
  iw_cfg_d3        AT %IW16 : INT;   (* z_position mm *)
  iw_cfg_d4        AT %IW17 : INT;   (* type *)
  iw_cfg_d5        AT %IW18 : INT;   (* dropping_time x10 *)
  iw_cfg_d6        AT %IW19 : INT;   (* device_delay x10 *)

  qw_cfg_ack       AT %QW21 : INT;   (* ack: last processed seq number *)

  (* --- Modbus OUTPUT: Units (QW22..QW71) --- *)
  (*   10 units x 5 fields: batch_id, location, status, state, target
       Unit N at QW22 + (N-1)*5 .. QW22 + (N-1)*5 + 4            *)
  qw_u1_batch   AT %QW22 : INT;
  qw_u1_loc     AT %QW23 : INT;
  qw_u1_status  AT %QW24 : INT;
  qw_u1_state   AT %QW25 : INT;
  qw_u1_target  AT %QW26 : INT;
  qw_u2_batch   AT %QW27 : INT;
  qw_u2_loc     AT %QW28 : INT;
  qw_u2_status  AT %QW29 : INT;
  qw_u2_state   AT %QW30 : INT;
  qw_u2_target  AT %QW31 : INT;
  qw_u3_batch   AT %QW32 : INT;
  qw_u3_loc     AT %QW33 : INT;
  qw_u3_status  AT %QW34 : INT;
  qw_u3_state   AT %QW35 : INT;
  qw_u3_target  AT %QW36 : INT;
  qw_u4_batch   AT %QW37 : INT;
  qw_u4_loc     AT %QW38 : INT;
  qw_u4_status  AT %QW39 : INT;
  qw_u4_state   AT %QW40 : INT;
  qw_u4_target  AT %QW41 : INT;
  qw_u5_batch   AT %QW42 : INT;
  qw_u5_loc     AT %QW43 : INT;
  qw_u5_status  AT %QW44 : INT;
  qw_u5_state   AT %QW45 : INT;
  qw_u5_target  AT %QW46 : INT;
  qw_u6_batch   AT %QW47 : INT;
  qw_u6_loc     AT %QW48 : INT;
  qw_u6_status  AT %QW49 : INT;
  qw_u6_state   AT %QW50 : INT;
  qw_u6_target  AT %QW51 : INT;
  qw_u7_batch   AT %QW52 : INT;
  qw_u7_loc     AT %QW53 : INT;
  qw_u7_status  AT %QW54 : INT;
  qw_u7_state   AT %QW55 : INT;
  qw_u7_target  AT %QW56 : INT;
  qw_u8_batch   AT %QW57 : INT;
  qw_u8_loc     AT %QW58 : INT;
  qw_u8_status  AT %QW59 : INT;
  qw_u8_state   AT %QW60 : INT;
  qw_u8_target  AT %QW61 : INT;
  qw_u9_batch   AT %QW62 : INT;
  qw_u9_loc     AT %QW63 : INT;
  qw_u9_status  AT %QW64 : INT;
  qw_u9_state   AT %QW65 : INT;
  qw_u9_target  AT %QW66 : INT;
  qw_u10_batch  AT %QW67 : INT;
  qw_u10_loc    AT %QW68 : INT;
  qw_u10_status AT %QW69 : INT;
  qw_u10_state  AT %QW70 : INT;
  qw_u10_target AT %QW71 : INT;
  qw_unit_ack   AT %QW72 : INT;   (* ack: last processed unit write seq *)

  (* --- Modbus INPUT: Unit write command (IW20..IW26) --- *)
  iw_unit_seq    AT %IW20 : INT;  (* sequence — triggers on change *)
  iw_unit_id     AT %IW21 : INT;  (* unit number 1..10 *)
  iw_unit_batch  AT %IW22 : INT;  (* batch_id *)
  iw_unit_loc    AT %IW23 : INT;  (* location (station number) *)
  iw_unit_status AT %IW24 : INT;  (* NOT_USED=0, USED=1 *)
  iw_unit_state  AT %IW25 : INT;  (* EMPTY=0, NOT_PROCESSED=1, IN_PROCESS=2, PROCESSED=3 *)
  iw_unit_target AT %IW26 : INT;  (* TO_NONE=0..TO_AVOID=4 *)
END_VAR
