(* ============================================================
   plc_prg.st — Main program: config upload + transport cycle
   ============================================================ *)

PROGRAM PLC_PRG
VAR_EXTERNAL CONSTANT
    TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_station_count    : INT;
  g_stations         : ARRAY[101..125] OF STATION_T;
  g_cfg              : ARRAY[1..TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_transporter      : ARRAY[1..TRANSPORTERS] OF STC_TRANSPORTER_T;
  (* Modbus output: transporter 1 *)
  qw_t1_x_mm    : INT;
  qw_t1_z_mm    : INT;
  qw_t1_vel_x10 : INT;
  qw_t1_phase   : INT;
  qw_t1_z_stage : INT;
  qw_t1_cur_st  : INT;
  qw_t1_lift_tgt : INT;
  qw_t1_sink_tgt : INT;
  qw_t1_active  : INT;
  (* Modbus output: transporter 2 *)
  qw_t2_x_mm    : INT;
  qw_t2_z_mm    : INT;
  qw_t2_vel_x10 : INT;
  qw_t2_phase   : INT;
  qw_t2_z_stage : INT;
  qw_t2_cur_st  : INT;
  qw_t2_lift_tgt : INT;
  qw_t2_sink_tgt : INT;
  qw_t2_active  : INT;
  (* Modbus output: status *)
  qw_station_cnt : INT;
  qw_init_done   : INT;
  qw_cycle_cnt   : INT;
  (* Modbus input: move commands *)
  iw_cmd_start_1 : INT;
  iw_cmd_lift_1  : INT;
  iw_cmd_sink_1  : INT;
  iw_cmd_start_2 : INT;
  iw_cmd_lift_2  : INT;
  iw_cmd_sink_2  : INT;
  (* Config upload protocol *)
  iw_cfg_seq     : INT;
  iw_cfg_cmd     : INT;
  iw_cfg_param   : INT;
  iw_cfg_d0      : INT;
  iw_cfg_d1      : INT;
  iw_cfg_d2      : INT;
  iw_cfg_d3      : INT;
  iw_cfg_d4      : INT;
  iw_cfg_d5      : INT;
  iw_cfg_d6      : INT;
  qw_cfg_ack     : INT;
  (* Units array *)
  g_units        : ARRAY[1..10] OF UNIT_T;
  (* Modbus output: units QW22..QW61 *)
  qw_u1_loc  : INT;
  qw_u1_status  : INT;
  qw_u1_state  : INT;
  qw_u1_target  : INT;
  qw_u2_loc  : INT;
  qw_u2_status  : INT;
  qw_u2_state  : INT;
  qw_u2_target  : INT;
  qw_u3_loc  : INT;
  qw_u3_status  : INT;
  qw_u3_state  : INT;
  qw_u3_target  : INT;
  qw_u4_loc  : INT;
  qw_u4_status  : INT;
  qw_u4_state  : INT;
  qw_u4_target  : INT;
  qw_u5_loc  : INT;
  qw_u5_status  : INT;
  qw_u5_state  : INT;
  qw_u5_target  : INT;
  qw_u6_loc  : INT;
  qw_u6_status  : INT;
  qw_u6_state  : INT;
  qw_u6_target  : INT;
  qw_u7_loc  : INT;
  qw_u7_status  : INT;
  qw_u7_state  : INT;
  qw_u7_target  : INT;
  qw_u8_loc  : INT;
  qw_u8_status  : INT;
  qw_u8_state  : INT;
  qw_u8_target  : INT;
  qw_u9_loc  : INT;
  qw_u9_status  : INT;
  qw_u9_state  : INT;
  qw_u9_target  : INT;
  qw_u10_loc : INT;
  qw_u10_status : INT;
  qw_u10_state : INT;
  qw_u10_target : INT;
  qw_unit_ack  : INT;
  (* Modbus output: batch data QW65..QW104 *)
  qw_b1_code  : INT;  qw_b1_state  : INT;  qw_b1_prog  : INT;  qw_b1_stage  : INT;
  qw_b2_code  : INT;  qw_b2_state  : INT;  qw_b2_prog  : INT;  qw_b2_stage  : INT;
  qw_b3_code  : INT;  qw_b3_state  : INT;  qw_b3_prog  : INT;  qw_b3_stage  : INT;
  qw_b4_code  : INT;  qw_b4_state  : INT;  qw_b4_prog  : INT;  qw_b4_stage  : INT;
  qw_b5_code  : INT;  qw_b5_state  : INT;  qw_b5_prog  : INT;  qw_b5_stage  : INT;
  qw_b6_code  : INT;  qw_b6_state  : INT;  qw_b6_prog  : INT;  qw_b6_stage  : INT;
  qw_b7_code  : INT;  qw_b7_state  : INT;  qw_b7_prog  : INT;  qw_b7_stage  : INT;
  qw_b8_code  : INT;  qw_b8_state  : INT;  qw_b8_prog  : INT;  qw_b8_stage  : INT;
  qw_b9_code  : INT;  qw_b9_state  : INT;  qw_b9_prog  : INT;  qw_b9_stage  : INT;
  qw_b10_code : INT;  qw_b10_state : INT;  qw_b10_prog : INT;  qw_b10_stage : INT;
  (* Modbus input: unit write command *)
  iw_unit_seq    : INT;
  iw_unit_id     : INT;
  iw_unit_loc    : INT;
  iw_unit_status : INT;
  iw_unit_state  : INT;
  iw_unit_target : INT;
  (* Batch and program arrays *)
  g_batches      : ARRAY[1..10] OF BATCH_T;
  g_programs     : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  g_avoid_status : ARRAY[101..125] OF INT;
  (* Modbus input: batch write protocol *)
  iw_batch_seq     : INT;
  iw_batch_unit    : INT;
  iw_batch_code    : INT;
  iw_batch_state   : INT;
  iw_batch_prog_id : INT;
  qw_batch_ack     : INT;
  (* Modbus input: program stage write protocol *)
  iw_prog_seq      : INT;
  iw_prog_unit     : INT;
  iw_prog_stage    : INT;
  iw_prog_s1       : INT;
  iw_prog_s2       : INT;
  iw_prog_s3       : INT;
  iw_prog_s4       : INT;
  iw_prog_s5       : INT;
  iw_prog_min_time : INT;
  iw_prog_max_time : INT;
  iw_prog_cal_time : INT;
  qw_prog_ack      : INT;
  (* Unix time *)
  g_time_s    : LINT;
  iw_time_hi  : INT;
  iw_time_lo  : INT;
  (* Task scheduler globals *)
  g_schedule  : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_tasks     : ARRAY[1..TRANSPORTERS] OF TSK_QUEUE_T;
  (* Calibration *)
  g_cal       : ARRAY[1..TRANSPORTERS] OF CALIBRATION_T;
  g_cal_active : BOOL;
  (* Calibration output registers *)
  qw_cal_step     : INT;
  qw_cal_tid      : INT;
  qw_cal_t1_lift_wet : INT;
  qw_cal_t1_sink_wet : INT;
  qw_cal_t1_lift_dry : INT;
  qw_cal_t1_sink_dry : INT;
  qw_cal_t1_x_acc    : INT;
  qw_cal_t1_x_dec    : INT;
  qw_cal_t1_x_max    : INT;
  qw_cal_t2_lift_wet : INT;
  qw_cal_t2_sink_wet : INT;
  qw_cal_t2_lift_dry : INT;
  qw_cal_t2_sink_dry : INT;
  qw_cal_t2_x_acc    : INT;
  qw_cal_t2_x_dec    : INT;
  qw_cal_t2_x_max    : INT;
  qw_cal_t3_lift_wet : INT;
  qw_cal_t3_sink_wet : INT;
  qw_cal_t3_lift_dry : INT;
  qw_cal_t3_sink_dry : INT;
  qw_cal_t3_x_acc    : INT;
  qw_cal_t3_x_dec    : INT;
  qw_cal_t3_x_max    : INT;
END_VAR
VAR
  init_done      : BOOL := FALSE;
  last_cfg_seq   : INT := 0;
  last_unit_seq  : INT := 0;
  last_batch_seq : INT := 0;
  last_prog_seq  : INT := 0;
  j              : INT;
  k              : INT;
  i              : INT;
  stn_num        : INT;
  idx          : INT;
  twa_calc     : TWA_FB_CalcLimits;
  lookup       : STC_FB_FindStation;
  clear_cfg    : SIM_FB_ClearConfig;
  cycle_count  : INT;
  main_sched   : STC_FB_MainScheduler;
  run_tasks    : SIM_FB_RunTasks;
  calibrate    : STC_FB_Calibrate;
  cal_cmd      : INT := 0;
  (* Time-keeping vars *)
  time_hi        : LINT;
  time_lo        : LINT;
  time_cycle_cnt : INT := 0;      (* counts 20ms cycles, resets at 50 = 1 s *)
  last_sync_hi   : INT := 0;      (* previous gateway iw_time_hi — for change detect *)
  last_sync_lo   : INT := 0;      (* previous gateway iw_time_lo *)
END_VAR
(* ============================================================
   CONFIG UPLOAD HANDLER
   Gateway writes station data one at a time via Modbus IW regs.
   Sequence number change triggers processing.
   cmd=1: write_station  cmd=2: init  cmd=3: clear_all
   ============================================================ *)
IF iw_cfg_seq <> last_cfg_seq THEN
  last_cfg_seq := iw_cfg_seq;

  IF iw_cfg_cmd = 3 THEN
    (* --- Clear all config data --- *)
    clear_cfg();
    init_done := FALSE;
    qw_init_done := 0;
    qw_station_cnt := 0;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 1 THEN
    (* --- Write one station to g_stations array --- *)
    IF (iw_cfg_param >= 101) AND (iw_cfg_param <= 125) THEN
      g_stations[iw_cfg_param].tank_id       := iw_cfg_d0;
      g_stations[iw_cfg_param].x_position    := INT_TO_REAL(iw_cfg_d1);
      g_stations[iw_cfg_param].y_position    := INT_TO_REAL(iw_cfg_d2);
      g_stations[iw_cfg_param].z_position    := INT_TO_REAL(iw_cfg_d3);
      g_stations[iw_cfg_param].stn_function  := iw_cfg_d4;
      IF (iw_cfg_d4 = 1) OR (iw_cfg_d4 = 11) THEN
        g_stations[iw_cfg_param].stn_type := 1;   (* wet *)
      ELSE
        g_stations[iw_cfg_param].stn_type := 0;   (* dry *)
      END_IF;
      g_stations[iw_cfg_param].dropping_time := INT_TO_REAL(iw_cfg_d5) / 10.0;
      g_stations[iw_cfg_param].device_delay  := INT_TO_REAL(iw_cfg_d6) / 10.0;
    END_IF;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 4 THEN
    (* --- Write transporter physics page 1 --- *)
    (* param = transporter_id (1..3)
       d0 = x_min_limit mm      d1 = x_max_limit mm
       d2 = x_accel_s × 10      d3 = x_decel_s × 10
       d4 = x_max_mm_s           d5 = z_total_mm
       d6 = avoid_mm *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cfg[j].x_min_limit          := INT_TO_REAL(iw_cfg_d0);
      g_cfg[j].x_max_limit          := INT_TO_REAL(iw_cfg_d1);
      g_cfg[j].phys2d.x_accel_s     := INT_TO_REAL(iw_cfg_d2) / 10.0;
      g_cfg[j].phys2d.x_decel_s     := INT_TO_REAL(iw_cfg_d3) / 10.0;
      g_cfg[j].phys2d.x_max_mm_s    := INT_TO_REAL(iw_cfg_d4);
      g_cfg[j].phys2d.z_total_mm    := INT_TO_REAL(iw_cfg_d5);
      g_cfg[j].phys2d.avoid_mm      := INT_TO_REAL(iw_cfg_d6);
      g_cfg[j].x_avoid_mm           := INT_TO_REAL(iw_cfg_d6);
    END_IF;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 5 THEN
    (* --- Write transporter physics page 2 --- *)
    (* param = transporter_id (1..3)
       d0 = z_slow_dry_mm        d1 = z_slow_wet_mm
       d2 = z_slow_end_mm        d3 = z_slow_mm_s
       d4 = z_fast_mm_s          d5 = drip_delay_s × 10
       d6 = (reserved) *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cfg[j].phys2d.z_slow_dry_mm := INT_TO_REAL(iw_cfg_d0);
      g_cfg[j].phys2d.z_slow_wet_mm := INT_TO_REAL(iw_cfg_d1);
      g_cfg[j].phys2d.z_slow_end_mm := INT_TO_REAL(iw_cfg_d2);
      g_cfg[j].phys2d.z_slow_mm_s   := INT_TO_REAL(iw_cfg_d3);
      g_cfg[j].phys2d.z_fast_mm_s   := INT_TO_REAL(iw_cfg_d4);
      g_cfg[j].phys2d.drip_delay_s  := INT_TO_REAL(iw_cfg_d5) / 10.0;
    END_IF;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 6 THEN
    (* --- Write transporter task area --- *)
    (* param = transporter_id × 10 + area_index
       e.g. 11 = transporter 1 area 1, 23 = transporter 2 area 3
       d0 = min_lift   d1 = max_lift
       d2 = min_sink   d3 = max_sink *)
    j := iw_cfg_param / 10;
    k := iw_cfg_param MOD 10;
    IF (j >= 1) AND (j <= 3) AND (k >= 1) AND (k <= 4) THEN
      g_cfg[j].task_area[k].min_lift := iw_cfg_d0;
      g_cfg[j].task_area[k].max_lift := iw_cfg_d1;
      g_cfg[j].task_area[k].min_sink := iw_cfg_d2;
      g_cfg[j].task_area[k].max_sink := iw_cfg_d3;
    END_IF;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 7 THEN
    (* --- Calibration plan for one transporter --- *)
    (* param = transporter_id (1..3)
       d0 = wet_station   d1 = dry_station *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cal[j].wet_station := iw_cfg_d0;
      g_cal[j].dry_station := iw_cfg_d1;
    END_IF;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 8 THEN
    (* --- Calibration control --- *)
    (* param: 1=start, 2=calculate, 3=abort *)
    cal_cmd := iw_cfg_param;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 2 THEN
    (* --- Finish init: all config uploaded, init transporter states --- *)
    g_station_count := iw_cfg_param;

    FOR i := 1 TO TRANSPORTERS DO
      (* Active if task_area[1] has non-zero stations *)
      IF g_cfg[i].task_area[1].min_lift > 0 THEN
        g_transporter[i].active := TRUE;
      ELSE
        g_transporter[i].active := FALSE;
      END_IF;
      g_transporter[i].phase := 0;
      g_transporter[i].z_stage := 0;
      g_transporter[i].vel_x := 0.0;
      g_transporter[i].z_timer_s := 0.0;
      g_transporter[i].x_min_limit := g_cfg[i].x_min_limit;
      g_transporter[i].x_max_limit := g_cfg[i].x_max_limit;

      (* Start position: use task_area[1].min_lift as start station *)
      IF g_cfg[i].task_area[1].min_lift > 0 THEN
        stn_num := g_cfg[i].task_area[1].min_lift;
      ELSE
        stn_num := 0;
      END_IF;
      lookup(station_number := stn_num);
      IF lookup.found THEN
        g_transporter[i].x_mm := lookup.x_mm;
        g_transporter[i].current_station := stn_num;
      ELSE
        g_transporter[i].x_mm := 0.0;
        g_transporter[i].current_station := 0;
      END_IF;
      g_transporter[i].z_mm := 0.0;
    END_FOR;

    init_done := TRUE;
    qw_cfg_ack := iw_cfg_seq;
  END_IF;
END_IF;

(* ============================================================
   MAIN TRANSPORT CYCLE — only runs when init_done
   ============================================================ *)
IF init_done THEN

(* Calculate transporter working areas (X-limits) every cycle *)
twa_calc();

(* ── Unix time maintenance ── *)
(* PLC keeps g_time_s by incrementing +1 every 50 cycles (50 × 20 ms = 1 s).
   Gateway periodically writes reference unix seconds to QW160/QW161.
   When PLC detects the register values changed → sync to gateway time. *)
IF iw_time_hi <> last_sync_hi OR iw_time_lo <> last_sync_lo THEN
  (* Gateway wrote new reference time — sync *)
  time_hi := INT_TO_LINT(iw_time_hi);
  IF time_hi < LINT#0 THEN
    time_hi := time_hi + LINT#65536;
  END_IF;
  time_lo := INT_TO_LINT(iw_time_lo);
  IF time_lo < LINT#0 THEN
    time_lo := time_lo + LINT#65536;
  END_IF;
  g_time_s := time_hi * LINT#65536 + time_lo;
  last_sync_hi := iw_time_hi;
  last_sync_lo := iw_time_lo;
  time_cycle_cnt := 0;
ELSE
  (* Self-increment: +1 second every 50 cycles (50 × 20 ms) *)
  time_cycle_cnt := time_cycle_cnt + 1;
  IF time_cycle_cnt >= 50 THEN
    g_time_s := g_time_s + LINT#1;
    time_cycle_cnt := 0;
  END_IF;
END_IF;

(* ── Main Scheduler (TSK + DEP alternating cycles) ── *)
main_sched(i_run := init_done, i_time_s := g_time_s);

(* ── Execute transporter tasks (physics simulation) ── *)
run_tasks(i_run := init_done);

(* ── Calibration FB — issues test tasks, measures parameters ── *)
calibrate(i_run := init_done, i_cmd := cal_cmd);
cal_cmd := 0;   (* consumed after one cycle *)
g_cal_active := calibrate.o_active;

END_IF;  (* init_done *)

(* ============================================================
   UNIT WRITE HANDLER — gateway writes one unit at a time
   ============================================================ *)
IF iw_unit_seq <> last_unit_seq THEN
  last_unit_seq := iw_unit_seq;
  IF (iw_unit_id >= 1) AND (iw_unit_id <= 10) THEN
    g_units[iw_unit_id].location := iw_unit_loc;
    g_units[iw_unit_id].status   := iw_unit_status;
    g_units[iw_unit_id].state    := iw_unit_state;
    g_units[iw_unit_id].target   := iw_unit_target;
  END_IF;
  qw_unit_ack := iw_unit_seq;
END_IF;

(* ============================================================
   BATCH WRITE HANDLER — gateway writes batch data + program_id
   Also clears all stages of the treatment program for this unit.
   ============================================================ *)
IF iw_batch_seq <> last_batch_seq THEN
  last_batch_seq := iw_batch_seq;
  IF (iw_batch_unit >= 1) AND (iw_batch_unit <= 10) THEN
    g_batches[iw_batch_unit].batch_code := iw_batch_code;
    g_batches[iw_batch_unit].state      := iw_batch_state;
    g_batches[iw_batch_unit].prog_id    := iw_batch_prog_id;
    g_batches[iw_batch_unit].cur_stage      := 0;
    g_programs[iw_batch_unit].program_id := iw_batch_prog_id;
    (* Clear all stages *)
    FOR j := 1 TO 30 DO
      FOR k := 1 TO 5 DO
        g_programs[iw_batch_unit].stages[j].stations[k] := 0;
      END_FOR;
      g_programs[iw_batch_unit].stages[j].min_time := 0;
      g_programs[iw_batch_unit].stages[j].max_time := 0;
      g_programs[iw_batch_unit].stages[j].cal_time := 0;
    END_FOR;
  END_IF;
  qw_batch_ack := iw_batch_seq;
END_IF;

(* ============================================================
   PROGRAM STAGE WRITE HANDLER — gateway writes one stage at a time
   ============================================================ *)
IF iw_prog_seq <> last_prog_seq THEN
  last_prog_seq := iw_prog_seq;
  IF (iw_prog_unit >= 1) AND (iw_prog_unit <= 10) AND
     (iw_prog_stage >= 1) AND (iw_prog_stage <= 30) THEN
    g_programs[iw_prog_unit].stages[iw_prog_stage].stations[1] := iw_prog_s1;
    g_programs[iw_prog_unit].stages[iw_prog_stage].stations[2] := iw_prog_s2;
    g_programs[iw_prog_unit].stages[iw_prog_stage].stations[3] := iw_prog_s3;
    g_programs[iw_prog_unit].stages[iw_prog_stage].stations[4] := iw_prog_s4;
    g_programs[iw_prog_unit].stages[iw_prog_stage].stations[5] := iw_prog_s5;
    g_programs[iw_prog_unit].stages[iw_prog_stage].min_time := iw_prog_min_time;
    g_programs[iw_prog_unit].stages[iw_prog_stage].max_time := iw_prog_max_time;
    g_programs[iw_prog_unit].stages[iw_prog_stage].cal_time := iw_prog_cal_time;
  END_IF;
  qw_prog_ack := iw_prog_seq;
END_IF;

(* === MODBUS INPUT: Read commands → g_transporter command fields === *)
(* Note: task_id sync will be handled by SIM_FB_RunTasks later.
   For now, keep the old Modbus command interface working via direct write. *)
IF (iw_cmd_start_1 <> 0) AND (g_transporter[1].phase = 0) THEN
  g_transporter[1].task_id := g_time_s;
  g_transporter[1].lift_station := iw_cmd_lift_1;
  g_transporter[1].sink_station := iw_cmd_sink_1;
END_IF;
IF (iw_cmd_start_2 <> 0) AND (g_transporter[2].phase = 0) THEN
  g_transporter[2].task_id := g_time_s;
  g_transporter[2].lift_station := iw_cmd_lift_2;
  g_transporter[2].sink_station := iw_cmd_sink_2;
END_IF;

(* === MODBUS OUTPUT: Write transporter 1 state === *)
qw_t1_x_mm := REAL_TO_INT(g_transporter[1].x_mm);
qw_t1_z_mm := REAL_TO_INT(g_transporter[1].z_mm);
qw_t1_vel_x10 := REAL_TO_INT(g_transporter[1].vel_x * 10.0);
qw_t1_phase := g_transporter[1].phase;
qw_t1_z_stage := g_transporter[1].z_stage;
qw_t1_cur_st := g_transporter[1].current_station;
qw_t1_lift_tgt := g_transporter[1].lift_station;
qw_t1_sink_tgt := g_transporter[1].sink_station;
IF g_transporter[1].active THEN qw_t1_active := 1; ELSE qw_t1_active := 0; END_IF;

(* === MODBUS OUTPUT: Write transporter 2 state === *)
qw_t2_x_mm := REAL_TO_INT(g_transporter[2].x_mm);
qw_t2_z_mm := REAL_TO_INT(g_transporter[2].z_mm);
qw_t2_vel_x10 := REAL_TO_INT(g_transporter[2].vel_x * 10.0);
qw_t2_phase := g_transporter[2].phase;
qw_t2_z_stage := g_transporter[2].z_stage;
qw_t2_cur_st := g_transporter[2].current_station;
qw_t2_lift_tgt := g_transporter[2].lift_station;
qw_t2_sink_tgt := g_transporter[2].sink_station;
IF g_transporter[2].active THEN qw_t2_active := 1; ELSE qw_t2_active := 0; END_IF;

(* === MODBUS OUTPUT: Status registers === *)
qw_station_cnt := g_station_count;
IF init_done THEN qw_init_done := 1; ELSE qw_init_done := 0; END_IF;
cycle_count := cycle_count + 1;
IF cycle_count > 30000 THEN cycle_count := 0; END_IF;
qw_cycle_cnt := cycle_count;

(* Write unit data to Modbus output QW22..QW61 *)
qw_u1_loc    := g_units[1].location;
qw_u1_status := g_units[1].status;
qw_u1_state  := g_units[1].state;
qw_u1_target := g_units[1].target;
qw_u2_loc    := g_units[2].location;
qw_u2_status := g_units[2].status;
qw_u2_state  := g_units[2].state;
qw_u2_target := g_units[2].target;
qw_u3_loc    := g_units[3].location;
qw_u3_status := g_units[3].status;
qw_u3_state  := g_units[3].state;
qw_u3_target := g_units[3].target;
qw_u4_loc    := g_units[4].location;
qw_u4_status := g_units[4].status;
qw_u4_state  := g_units[4].state;
qw_u4_target := g_units[4].target;
qw_u5_loc    := g_units[5].location;
qw_u5_status := g_units[5].status;
qw_u5_state  := g_units[5].state;
qw_u5_target := g_units[5].target;
qw_u6_loc    := g_units[6].location;
qw_u6_status := g_units[6].status;
qw_u6_state  := g_units[6].state;
qw_u6_target := g_units[6].target;
qw_u7_loc    := g_units[7].location;
qw_u7_status := g_units[7].status;
qw_u7_state  := g_units[7].state;
qw_u7_target := g_units[7].target;
qw_u8_loc    := g_units[8].location;
qw_u8_status := g_units[8].status;
qw_u8_state  := g_units[8].state;
qw_u8_target := g_units[8].target;
qw_u9_loc    := g_units[9].location;
qw_u9_status := g_units[9].status;
qw_u9_state  := g_units[9].state;
qw_u9_target := g_units[9].target;
qw_u10_loc    := g_units[10].location;
qw_u10_status := g_units[10].status;
qw_u10_state  := g_units[10].state;
qw_u10_target := g_units[10].target;

(* Write batch data to Modbus output QW65..QW104 *)
qw_b1_code  := g_batches[1].batch_code;  qw_b1_state  := g_batches[1].state;  qw_b1_prog  := g_batches[1].prog_id;  qw_b1_stage  := g_batches[1].cur_stage;
qw_b2_code  := g_batches[2].batch_code;  qw_b2_state  := g_batches[2].state;  qw_b2_prog  := g_batches[2].prog_id;  qw_b2_stage  := g_batches[2].cur_stage;
qw_b3_code  := g_batches[3].batch_code;  qw_b3_state  := g_batches[3].state;  qw_b3_prog  := g_batches[3].prog_id;  qw_b3_stage  := g_batches[3].cur_stage;
qw_b4_code  := g_batches[4].batch_code;  qw_b4_state  := g_batches[4].state;  qw_b4_prog  := g_batches[4].prog_id;  qw_b4_stage  := g_batches[4].cur_stage;
qw_b5_code  := g_batches[5].batch_code;  qw_b5_state  := g_batches[5].state;  qw_b5_prog  := g_batches[5].prog_id;  qw_b5_stage  := g_batches[5].cur_stage;
qw_b6_code  := g_batches[6].batch_code;  qw_b6_state  := g_batches[6].state;  qw_b6_prog  := g_batches[6].prog_id;  qw_b6_stage  := g_batches[6].cur_stage;
qw_b7_code  := g_batches[7].batch_code;  qw_b7_state  := g_batches[7].state;  qw_b7_prog  := g_batches[7].prog_id;  qw_b7_stage  := g_batches[7].cur_stage;
qw_b8_code  := g_batches[8].batch_code;  qw_b8_state  := g_batches[8].state;  qw_b8_prog  := g_batches[8].prog_id;  qw_b8_stage  := g_batches[8].cur_stage;
qw_b9_code  := g_batches[9].batch_code;  qw_b9_state  := g_batches[9].state;  qw_b9_prog  := g_batches[9].prog_id;  qw_b9_stage  := g_batches[9].cur_stage;
qw_b10_code := g_batches[10].batch_code; qw_b10_state := g_batches[10].state; qw_b10_prog := g_batches[10].prog_id; qw_b10_stage := g_batches[10].cur_stage;

(* Write calibration status & results to Modbus QW170..QW192 *)
qw_cal_step := calibrate.o_step;
qw_cal_tid  := calibrate.o_tid;
(* T1 *)
qw_cal_t1_lift_wet := REAL_TO_INT(g_cal[1].lift_wet_s * 10.0);
qw_cal_t1_sink_wet := REAL_TO_INT(g_cal[1].sink_wet_s * 10.0);
qw_cal_t1_lift_dry := REAL_TO_INT(g_cal[1].lift_dry_s * 10.0);
qw_cal_t1_sink_dry := REAL_TO_INT(g_cal[1].sink_dry_s * 10.0);
qw_cal_t1_x_acc    := REAL_TO_INT(g_cal[1].x_accel_s * 10.0);
qw_cal_t1_x_dec    := REAL_TO_INT(g_cal[1].x_decel_s * 10.0);
qw_cal_t1_x_max    := REAL_TO_INT(g_cal[1].x_max_mm_s);
(* T2 *)
qw_cal_t2_lift_wet := REAL_TO_INT(g_cal[2].lift_wet_s * 10.0);
qw_cal_t2_sink_wet := REAL_TO_INT(g_cal[2].sink_wet_s * 10.0);
qw_cal_t2_lift_dry := REAL_TO_INT(g_cal[2].lift_dry_s * 10.0);
qw_cal_t2_sink_dry := REAL_TO_INT(g_cal[2].sink_dry_s * 10.0);
qw_cal_t2_x_acc    := REAL_TO_INT(g_cal[2].x_accel_s * 10.0);
qw_cal_t2_x_dec    := REAL_TO_INT(g_cal[2].x_decel_s * 10.0);
qw_cal_t2_x_max    := REAL_TO_INT(g_cal[2].x_max_mm_s);
(* T3 *)
qw_cal_t3_lift_wet := REAL_TO_INT(g_cal[3].lift_wet_s * 10.0);
qw_cal_t3_sink_wet := REAL_TO_INT(g_cal[3].sink_wet_s * 10.0);
qw_cal_t3_lift_dry := REAL_TO_INT(g_cal[3].lift_dry_s * 10.0);
qw_cal_t3_sink_dry := REAL_TO_INT(g_cal[3].sink_dry_s * 10.0);
qw_cal_t3_x_acc    := REAL_TO_INT(g_cal[3].x_accel_s * 10.0);
qw_cal_t3_x_dec    := REAL_TO_INT(g_cal[3].x_decel_s * 10.0);
qw_cal_t3_x_max    := REAL_TO_INT(g_cal[3].x_max_mm_s);
END_PROGRAM
