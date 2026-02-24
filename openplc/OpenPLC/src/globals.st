(* ============================================================
   globals.st — Global variables (shared memory + Modbus I/O)
   ============================================================ *)

VAR_GLOBAL CONSTANT
  (* ── Array size limits (used in ARRAY declarations with -a flag) ── *)
  MAX_STATIONS       : INT := 25;    (* stations 101..100+MAX_STATIONS *)
  TRANSPORTERS   : INT := 3;     (* number of transporters in this plant *)
  MAX_UNITS          : INT := 10;    (* units 1..MAX_UNITS *)
  MAX_PARALLELS      : INT := 5;     (* max parallel stations per program stage *)
  MAX_STAGES         : INT := 30;    (* max stages in a treatment program *)
  MAX_LINES          : INT := 4;     (* max production lines per transporter *)
  DEP_MAX_IDLE_SLOTS : INT := 20;    (* max idle slots per transporter *)
  DEP_MAX_DELAY_ACTS : INT := 10;    (* max delay actions per cycle *)
  DEP_MAX_WAITING    : INT := 10;    (* max waiting batches *)
  MIN_WORK_AREA      : REAL := 20.0; (* mm — TWA minimum working area *)

  (* ── Enumerated constants ── *)
  (* Unit status *)
  USED             : INT := 1;
  NOT_USED         : INT := 0;
  (* Unit state *)
  EMPTY            : INT := 0;
  FULL             : INT := 1;
  (* Unit target *)
  TO_NONE          : INT := 0;
  TO_LOADING       : INT := 1;
  TO_BUFFER        : INT := 2;
  TO_PROCESS       : INT := 3;
  TO_UNLOAD        : INT := 4;
  TO_AVOID         : INT := 5;
  (* Station type *)
  STN_DRY          : INT := 0;
  STN_WET          : INT := 1;
  (* Batch state *)
  NOT_PROCESSED    : INT := 0;
  IN_PROCESS       : INT := 1;
  PROCESSED        : INT := 2;
  (* Avoid status for stations (TWA) *)
  AVOID_NONE       : INT := 0;     (* station not avoided *)
  AVOID_PASS       : INT := 1;     (* pass through allowed, no stop *)
  AVOID_BLOCK      : INT := 2;     (* hard block, cannot pass *)
END_VAR

VAR_GLOBAL
  (* --- Shared data arrays --- *)
  g_station_count    : INT := 0;
  g_stations         : ARRAY[101..125] OF STATION_T;
  g_cfg              : ARRAY[1..TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_transporter      : ARRAY[1..TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_units            : ARRAY[1..10] OF UNIT_T;
  g_batches          : ARRAY[1..10] OF BATCH_T;
  g_programs         : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  g_avoid_status     : ARRAY[101..125] OF INT;  (* AVOID_NONE/PASS/BLOCK per station *)
  g_move             : ARRAY[1..TRANSPORTERS] OF MOVE_TIMES_T;  (* precomputed movement times per transporter *)
  g_schedule         : ARRAY[1..10] OF TSK_SCHEDULE_T;  (* calculated schedule per unit *)
  g_tasks            : ARRAY[1..TRANSPORTERS] OF TSK_QUEUE_T;       (* task queue per transporter *)
  (* --- Departure Scheduler state --- *)
  g_dep_sandbox       : DEP_SANDBOX_T;                    (* sandbox: isolated copy for planning *)
  g_dep_idle_slots    : ARRAY[1..TRANSPORTERS] OF DEP_IDLE_SLOT_SET_T;  (* idle slots per transporter *)
  g_dep_waiting       : ARRAY[1..10] OF INT;              (* waiting batch unit indices *)
  g_dep_waiting_count : INT;
  g_dep_overlap       : DEP_OVERLAP_T;                    (* overlap station flags *)
  g_dep_pending       : DEP_PENDING_WRITE_T;              (* ACTIVATE → write buffer *)
  g_dep_activated     : BOOL;                             (* handshake TSK ← DEP *)
  g_dep_stable        : BOOL;                             (* handshake TSK → DEP: task list stable *)
  (* --- Calibration state --- *)
  g_cal              : ARRAY[1..TRANSPORTERS] OF CALIBRATION_T;      (* calibration plan + results per transporter *)
  g_cal_active       : BOOL;                              (* TRUE during calibration — inhibits schedulers *)
  (* --- Unix time --- *)
  (* g_time_s = absolute unix time in seconds (LINT)                       *)
  (* Gateway writes upper/lower 16-bit halves to QW160/QW161 every tick   *)
  g_time_s           : LINT;          (* absolute time in unix seconds *)
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

  (* --- Modbus OUTPUT: Batch data (QW65..QW104) --- *)
  (*   10 units x 4 fields: batch_code, state, program, stage
       Unit N batch at QW65 + (N-1)*4 .. QW65 + (N-1)*4 + 3     *)
  qw_b1_code    AT %QW65  : INT;
  qw_b1_state   AT %QW66  : INT;
  qw_b1_prog    AT %QW67  : INT;
  qw_b1_stage   AT %QW68  : INT;
  qw_b2_code    AT %QW69  : INT;
  qw_b2_state   AT %QW70  : INT;
  qw_b2_prog    AT %QW71  : INT;
  qw_b2_stage   AT %QW72  : INT;
  qw_b3_code    AT %QW73  : INT;
  qw_b3_state   AT %QW74  : INT;
  qw_b3_prog    AT %QW75  : INT;
  qw_b3_stage   AT %QW76  : INT;
  qw_b4_code    AT %QW77  : INT;
  qw_b4_state   AT %QW78  : INT;
  qw_b4_prog    AT %QW79  : INT;
  qw_b4_stage   AT %QW80  : INT;
  qw_b5_code    AT %QW81  : INT;
  qw_b5_state   AT %QW82  : INT;
  qw_b5_prog    AT %QW83  : INT;
  qw_b5_stage   AT %QW84  : INT;
  qw_b6_code    AT %QW85  : INT;
  qw_b6_state   AT %QW86  : INT;
  qw_b6_prog    AT %QW87  : INT;
  qw_b6_stage   AT %QW88  : INT;
  qw_b7_code    AT %QW89  : INT;
  qw_b7_state   AT %QW90  : INT;
  qw_b7_prog    AT %QW91  : INT;
  qw_b7_stage   AT %QW92  : INT;
  qw_b8_code    AT %QW93  : INT;
  qw_b8_state   AT %QW94  : INT;
  qw_b8_prog    AT %QW95  : INT;
  qw_b8_stage   AT %QW96  : INT;
  qw_b9_code    AT %QW97  : INT;
  qw_b9_state   AT %QW98  : INT;
  qw_b9_prog    AT %QW99  : INT;
  qw_b9_stage   AT %QW100 : INT;
  qw_b10_code   AT %QW101 : INT;
  qw_b10_state  AT %QW102 : INT;
  qw_b10_prog   AT %QW103 : INT;
  qw_b10_stage  AT %QW104 : INT;

  (* --- Modbus INPUT: Commands (QW200..QW205) --- *)
  (*   NOTE: Uses %QW (holding registers) because %IW (input registers)
       are read-only from Modbus master perspective.                  *)
  iw_cmd_start_1 AT %QW200 : INT;
  iw_cmd_lift_1  AT %QW201 : INT;
  iw_cmd_sink_1  AT %QW202 : INT;
  iw_cmd_start_2 AT %QW203 : INT;
  iw_cmd_lift_2  AT %QW204 : INT;
  iw_cmd_sink_2  AT %QW205 : INT;

  (* --- Config upload protocol (QW110..QW119, QW21) --- *)
  (*   Gateway writes station config one at a time.
       Sequence number change triggers PLC processing.
       cmd=1: write_station, cmd=2: init, cmd=3: clear_all
       NOTE: Uses %QW because %IW is read-only from Modbus master.  *)
  iw_cfg_seq       AT %QW110 : INT;   (* sequence number — triggers on change *)
  iw_cfg_cmd       AT %QW111 : INT;   (* 1=write_station, 2=init, 3=clear_all *)
  iw_cfg_param     AT %QW112 : INT;   (* station_number or station_count *)
  iw_cfg_d0        AT %QW113 : INT;   (* tank_id *)
  iw_cfg_d1        AT %QW114 : INT;   (* x_position mm *)
  iw_cfg_d2        AT %QW115 : INT;   (* y_position mm *)
  iw_cfg_d3        AT %QW116 : INT;   (* z_position mm *)
  iw_cfg_d4        AT %QW117 : INT;   (* type *)
  iw_cfg_d5        AT %QW118 : INT;   (* dropping_time x10 *)
  iw_cfg_d6        AT %QW119 : INT;   (* device_delay x10 *)

  qw_cfg_ack       AT %QW21 : INT;   (* ack: last processed seq number *)

  (* --- Modbus OUTPUT: Units (QW22..QW61) --- *)
  (*   10 units x 4 fields: location, status, state, target
       Unit N at QW22 + (N-1)*4 .. QW22 + (N-1)*4 + 3            *)
  qw_u1_loc     AT %QW22 : INT;
  qw_u1_status  AT %QW23 : INT;
  qw_u1_state   AT %QW24 : INT;
  qw_u1_target  AT %QW25 : INT;
  qw_u2_loc     AT %QW26 : INT;
  qw_u2_status  AT %QW27 : INT;
  qw_u2_state   AT %QW28 : INT;
  qw_u2_target  AT %QW29 : INT;
  qw_u3_loc     AT %QW30 : INT;
  qw_u3_status  AT %QW31 : INT;
  qw_u3_state   AT %QW32 : INT;
  qw_u3_target  AT %QW33 : INT;
  qw_u4_loc     AT %QW34 : INT;
  qw_u4_status  AT %QW35 : INT;
  qw_u4_state   AT %QW36 : INT;
  qw_u4_target  AT %QW37 : INT;
  qw_u5_loc     AT %QW38 : INT;
  qw_u5_status  AT %QW39 : INT;
  qw_u5_state   AT %QW40 : INT;
  qw_u5_target  AT %QW41 : INT;
  qw_u6_loc     AT %QW42 : INT;
  qw_u6_status  AT %QW43 : INT;
  qw_u6_state   AT %QW44 : INT;
  qw_u6_target  AT %QW45 : INT;
  qw_u7_loc     AT %QW46 : INT;
  qw_u7_status  AT %QW47 : INT;
  qw_u7_state   AT %QW48 : INT;
  qw_u7_target  AT %QW49 : INT;
  qw_u8_loc     AT %QW50 : INT;
  qw_u8_status  AT %QW51 : INT;
  qw_u8_state   AT %QW52 : INT;
  qw_u8_target  AT %QW53 : INT;
  qw_u9_loc     AT %QW54 : INT;
  qw_u9_status  AT %QW55 : INT;
  qw_u9_state   AT %QW56 : INT;
  qw_u9_target  AT %QW57 : INT;
  qw_u10_loc    AT %QW58 : INT;
  qw_u10_status AT %QW59 : INT;
  qw_u10_state  AT %QW60 : INT;
  qw_u10_target AT %QW61 : INT;
  qw_unit_ack   AT %QW62 : INT;   (* ack: last processed unit write seq *)

  (* --- Modbus INPUT: Unit write command (QW120..QW125) --- *)
  (*   NOTE: Uses %QW because %IW is read-only from Modbus master.  *)
  iw_unit_seq    AT %QW120 : INT;  (* sequence — triggers on change *)
  iw_unit_id     AT %QW121 : INT;  (* unit number 1..10 *)
  iw_unit_loc    AT %QW122 : INT;  (* location (station number) *)
  iw_unit_status AT %QW123 : INT;  (* NOT_USED=0, USED=1 *)
  iw_unit_state  AT %QW124 : INT;  (* EMPTY=0, FULL=1 *)
  iw_unit_target AT %QW125 : INT;  (* TO_NONE=0, TO_LOADING=1, TO_BUFFER=2, TO_PROCESS=3, TO_UNLOAD=4, TO_AVOID=5 *)

  (* --- Modbus INPUT: Batch write protocol (QW130..QW134, ack QW63) --- *)
  (*   Writes batch data and initializes treatment program for a unit.
       PLC handler also clears all stages of g_programs[unit] on write.  *)
  iw_batch_seq     AT %QW130 : INT;  (* sequence number — triggers on change *)
  iw_batch_unit    AT %QW131 : INT;  (* unit index 1..10 *)
  iw_batch_code    AT %QW132 : INT;  (* numeric batch code *)
  iw_batch_state   AT %QW133 : INT;  (* NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2 *)
  iw_batch_prog_id AT %QW134 : INT;  (* treatment program ID *)
  qw_batch_ack     AT %QW63  : INT;  (* ack: last processed batch write seq *)

  (* --- Modbus INPUT: Program stage write protocol (QW140..QW150, ack QW64) --- *)
  (*   Writes one treatment program stage at a time.
       Must send batch write first to set program_id and clear stages.  *)
  iw_prog_seq      AT %QW140 : INT;  (* sequence number — triggers on change *)
  iw_prog_unit     AT %QW141 : INT;  (* unit index 1..10 *)
  iw_prog_stage    AT %QW142 : INT;  (* stage index 1..30 *)
  iw_prog_s1       AT %QW143 : INT;  (* station 1 (0 = unused) *)
  iw_prog_s2       AT %QW144 : INT;  (* station 2 (0 = unused) *)
  iw_prog_s3       AT %QW145 : INT;  (* station 3 (0 = unused) *)
  iw_prog_s4       AT %QW146 : INT;  (* station 4 (0 = unused) *)
  iw_prog_s5       AT %QW147 : INT;  (* station 5 (0 = unused) *)
  iw_prog_min_time AT %QW148 : INT;  (* min processing time in seconds *)
  iw_prog_max_time AT %QW149 : INT;  (* max processing time in seconds *)
  iw_prog_cal_time AT %QW150 : INT;  (* calculated / target time in seconds *)
  qw_prog_ack      AT %QW64  : INT;  (* ack: last processed program stage seq *)

  (* --- Modbus INPUT: Unix time (QW160..QW161) --- *)
  (*   Gateway writes 32-bit unix seconds as two unsigned 16-bit halves.  *)
  (*   g_time_s = (uint16(iw_time_hi) * 65536) + uint16(iw_time_lo)      *)
  iw_time_hi   AT %QW160 : INT;  (* unix seconds upper 16 bits (unsigned) *)
  iw_time_lo   AT %QW161 : INT;  (* unix seconds lower 16 bits (unsigned) *)

  (* --- Modbus OUTPUT: Calibration status & results (QW170..QW192) --- *)
  (*   Gateway polls these during/after calibration.
       Times are × 10 for 0.1 s precision in INT Modbus registers.
       x_max is integer mm/s. *)
  qw_cal_step     AT %QW170 : INT;  (* calibration step: 0=idle, 10-40=measuring, 100=done, 200=calculating, 999=complete *)
  qw_cal_tid      AT %QW171 : INT;  (* transporter being calibrated (1..3, 0=none) *)
  (* T1 results: QW172..QW178 *)
  qw_cal_t1_lift_wet AT %QW172 : INT;
  qw_cal_t1_sink_wet AT %QW173 : INT;
  qw_cal_t1_lift_dry AT %QW174 : INT;
  qw_cal_t1_sink_dry AT %QW175 : INT;
  qw_cal_t1_x_acc    AT %QW176 : INT;
  qw_cal_t1_x_dec    AT %QW177 : INT;
  qw_cal_t1_x_max    AT %QW178 : INT;
  (* T2 results: QW179..QW185 *)
  qw_cal_t2_lift_wet AT %QW179 : INT;
  qw_cal_t2_sink_wet AT %QW180 : INT;
  qw_cal_t2_lift_dry AT %QW181 : INT;
  qw_cal_t2_sink_dry AT %QW182 : INT;
  qw_cal_t2_x_acc    AT %QW183 : INT;
  qw_cal_t2_x_dec    AT %QW184 : INT;
  qw_cal_t2_x_max    AT %QW185 : INT;
  (* T3 results: QW186..QW192 *)
  qw_cal_t3_lift_wet AT %QW186 : INT;
  qw_cal_t3_sink_wet AT %QW187 : INT;
  qw_cal_t3_lift_dry AT %QW188 : INT;
  qw_cal_t3_sink_dry AT %QW189 : INT;
  qw_cal_t3_x_acc    AT %QW190 : INT;
  qw_cal_t3_x_dec    AT %QW191 : INT;
  qw_cal_t3_x_max    AT %QW192 : INT;
END_VAR
