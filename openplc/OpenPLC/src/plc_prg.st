(* ============================================================
   plc_prg.st — Main program: config upload + transport cycle
   ============================================================ *)

PROGRAM PLC_PRG
VAR_EXTERNAL
  g_station_count    : INT;
  g_stations         : ARRAY[101..125] OF STATION_T;
  g_cfg              : ARRAY[1..3] OF TRANSPORTER_CFG_T;
  g_state            : ARRAY[1..3] OF TRANSPORTER_STATE_T;
  g_cmd_start        : ARRAY[1..3] OF BOOL;
  g_cmd_lift_station : ARRAY[1..3] OF INT;
  g_cmd_sink_station : ARRAY[1..3] OF INT;
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
  (* Epoch-offset time model *)
  g_epoch_h   : INT;
  g_time_s    : REAL;
  iw_epoch_h  : INT;
  iw_time_hi  : INT;
  iw_time_lo  : INT;
  (* Task scheduler globals *)
  g_schedule  : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_tasks     : ARRAY[1..3] OF TSK_QUEUE_T;
  (* Departure scheduler handshake *)
  g_dep_stable : BOOL;
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
  station_type : INT;
  device_delay : REAL;
  drop_time    : REAL;
  arrived_x    : BOOL;
  nearest_num  : INT;
  min_dist     : REAL;
  dx           : REAL;
  tmp_x        : REAL;
  tmp_vx       : REAL;
  fb_x1        : SIM_FB_XMotion;
  fb_x2        : SIM_FB_XMotion;
  fb_x3        : SIM_FB_XMotion;
  fb_z1        : SIM_FB_ZMotion;
  fb_z2        : SIM_FB_ZMotion;
  fb_z3        : SIM_FB_ZMotion;
  twa_calc     : TWA_FB_CalcLimits;
  lookup       : STC_FB_FindStation;
  clear_cfg    : FB_ClearConfig;
  cycle_count  : INT;
  tmp_z        : REAL;
  tmp_zs       : INT;
  tmp_zt       : REAL;
  arrived_z    : BOOL;
  tsk_sched    : TSK_FB_Scheduler;
  dep_sched    : DEP_FB_Scheduler;
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
      g_stations[iw_cfg_param].stn_type      := iw_cfg_d4;
      g_stations[iw_cfg_param].dropping_time := INT_TO_REAL(iw_cfg_d5) / 10.0;
      g_stations[iw_cfg_param].device_delay  := INT_TO_REAL(iw_cfg_d6) / 10.0;
    END_IF;
    qw_cfg_ack := iw_cfg_seq;

  ELSIF iw_cfg_cmd = 2 THEN
    (* --- Finish init: station data uploaded, now init transporters --- *)
    g_station_count := iw_cfg_param;

    (* Transporter 1 config — hardcoded for now *)
    g_cfg[1].x_min_limit := 100.0;
    g_cfg[1].x_max_limit := 20600.0;
    g_cfg[1].x_avoid_mm := 2000.0;
    g_cfg[1].phys2d.x_accel_s := 1.5;
    g_cfg[1].phys2d.x_decel_s := 1.5;
    g_cfg[1].phys2d.x_max_mm_s := 500.0;
    g_cfg[1].phys2d.z_total_mm := 2500.0;
    g_cfg[1].phys2d.z_slow_dry_mm := 300.0;
    g_cfg[1].phys2d.z_slow_wet_mm := 1000.0;
    g_cfg[1].phys2d.z_slow_end_mm := 50.0;
    g_cfg[1].phys2d.z_slow_mm_s := 100.0;
    g_cfg[1].phys2d.z_fast_mm_s := 200.0;
    g_cfg[1].phys2d.drip_delay_s := 5.0;
    g_cfg[1].phys2d.avoid_mm := 2000.0;
    g_cfg[1].task_area[1].min_lift := 101;
    g_cfg[1].task_area[1].max_lift := 111;
    g_cfg[1].task_area[1].min_sink := 101;
    g_cfg[1].task_area[1].max_sink := 114;

    (* Transporter 2 config *)
    g_cfg[2].x_min_limit := 14300.0;
    g_cfg[2].x_max_limit := 29100.0;
    g_cfg[2].x_avoid_mm := 2000.0;
    g_cfg[2].phys2d.x_accel_s := 1.5;
    g_cfg[2].phys2d.x_decel_s := 1.5;
    g_cfg[2].phys2d.x_max_mm_s := 500.0;
    g_cfg[2].phys2d.z_total_mm := 2500.0;
    g_cfg[2].phys2d.z_slow_dry_mm := 300.0;
    g_cfg[2].phys2d.z_slow_wet_mm := 1000.0;
    g_cfg[2].phys2d.z_slow_end_mm := 50.0;
    g_cfg[2].phys2d.z_slow_mm_s := 100.0;
    g_cfg[2].phys2d.z_fast_mm_s := 200.0;
    g_cfg[2].phys2d.drip_delay_s := 5.0;
    g_cfg[2].phys2d.avoid_mm := 2000.0;
    g_cfg[2].task_area[1].min_lift := 112;
    g_cfg[2].task_area[1].max_lift := 121;
    g_cfg[2].task_area[1].min_sink := 111;
    g_cfg[2].task_area[1].max_sink := 121;

    (* Init transporter states *)
    FOR i := 1 TO 3 DO
      IF i <= 2 THEN
        g_state[i].active := TRUE;
      ELSE
        g_state[i].active := FALSE;
      END_IF;
      g_state[i].phase := 0;
      g_state[i].z_stage := 0;
      g_state[i].vel_x := 0.0;
      g_state[i].vel_z := 0.0;
      g_state[i].z_timer_s := 0.0;
      g_state[i].x_min_limit := g_cfg[i].x_min_limit;
      g_state[i].x_max_limit := g_cfg[i].x_max_limit;

      (* Start position: use task_area[1].min_lift as start station *)
      IF g_cfg[i].task_area[1].min_lift > 0 THEN
        stn_num := g_cfg[i].task_area[1].min_lift;
      ELSE
        stn_num := 0;
      END_IF;
      lookup(station_number := stn_num);
      IF lookup.found THEN
        g_state[i].x_mm := lookup.x_mm;
        g_state[i].current_station := stn_num;
      ELSE
        g_state[i].x_mm := 0.0;
        g_state[i].current_station := 0;
      END_IF;
      g_state[i].z_mm := 0.0;
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

(* ── Epoch-offset time decode ── *)
(* Server writes iw_epoch_h, iw_time_hi, iw_time_lo via Modbus.
   g_time_s = (iw_time_hi * 65536 + iw_time_lo) / 10.0 *)
g_epoch_h := iw_epoch_h;
g_time_s  := (INT_TO_REAL(iw_time_hi) * 65536.0 + INT_TO_REAL(iw_time_lo)) / 10.0;

(* ── Task Scheduler ── *)
tsk_sched(i_run := init_done, i_time_s := g_time_s);

(* ── Departure Scheduler ── *)
(* Stable signal: TSK is at READY (10000) or RESTART (10110) *)
g_dep_stable := (tsk_sched.o_phase >= 10000);
dep_sched(i_run := init_done, i_time_s := g_time_s, i_tsk_phase := tsk_sched.o_phase);

FOR i := 1 TO 3 DO
  IF g_state[i].active THEN

  IF (g_state[i].phase = 0) AND g_cmd_start[i] THEN
    g_state[i].lift_station_target := g_cmd_lift_station[i];
    g_state[i].sink_station_target := g_cmd_sink_station[i];
    lookup(station_number := g_state[i].lift_station_target);
    g_state[i].target_x := lookup.x_mm;
    g_state[i].phase := 1;
    g_state[i].z_stage := 0;
    g_state[i].z_timer_s := 0.0;
  END_IF;

  IF g_state[i].phase = 1 THEN
    tmp_x := g_state[i].x_mm;
    tmp_vx := g_state[i].vel_x;
    IF i = 1 THEN
      fb_x1(
        delta_t := 0.02,
        x_target := g_state[i].target_x,
        x_min := g_state[i].x_min_limit,
        x_max := g_state[i].x_max_limit,
        v_max := g_cfg[i].phys2d.x_max_mm_s,
        t_acc := g_cfg[i].phys2d.x_accel_s,
        t_dec := g_cfg[i].phys2d.x_decel_s,
        x_pos := tmp_x,
        v_x := tmp_vx
      );
      arrived_x := fb_x1.arrived;
    ELSIF i = 2 THEN
      fb_x2(
        delta_t := 0.02,
        x_target := g_state[i].target_x,
        x_min := g_state[i].x_min_limit,
        x_max := g_state[i].x_max_limit,
        v_max := g_cfg[i].phys2d.x_max_mm_s,
        t_acc := g_cfg[i].phys2d.x_accel_s,
        t_dec := g_cfg[i].phys2d.x_decel_s,
        x_pos := tmp_x,
        v_x := tmp_vx
      );
      arrived_x := fb_x2.arrived;
    ELSIF i = 3 THEN
      fb_x3(
        delta_t := 0.02,
        x_target := g_state[i].target_x,
        x_min := g_state[i].x_min_limit,
        x_max := g_state[i].x_max_limit,
        v_max := g_cfg[i].phys2d.x_max_mm_s,
        t_acc := g_cfg[i].phys2d.x_accel_s,
        t_dec := g_cfg[i].phys2d.x_decel_s,
        x_pos := tmp_x,
        v_x := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_state[i].x_mm := tmp_x;
    g_state[i].vel_x := tmp_vx;

    IF arrived_x THEN
      g_state[i].current_station := g_state[i].lift_station_target;
      lookup(station_number := g_state[i].lift_station_target);
      device_delay := lookup.device_delay_s;
      drop_time := lookup.dropping_time_s;
      g_state[i].z_timer_s := device_delay + drop_time;
      g_state[i].z_stage := 1;
      g_state[i].phase := 2;
    END_IF;
  END_IF;

  IF g_state[i].phase = 2 THEN
    lookup(station_number := g_state[i].lift_station_target);
    station_type := lookup.stype;
    tmp_z := g_state[i].z_mm;
    tmp_zs := g_state[i].z_stage;
    tmp_zt := g_state[i].z_timer_s;
    IF i = 1 THEN
      fb_z1(
        delta_t := 0.02,
        station_type := station_type,
        z_total_mm := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s := g_cfg[i].phys2d.drip_delay_s,
        z_mm := tmp_z,
        z_stage := tmp_zs,
        z_timer_s := tmp_zt
      );
      arrived_z := fb_z1.done;
    ELSIF i = 2 THEN
      fb_z2(
        delta_t := 0.02,
        station_type := station_type,
        z_total_mm := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s := g_cfg[i].phys2d.drip_delay_s,
        z_mm := tmp_z,
        z_stage := tmp_zs,
        z_timer_s := tmp_zt
      );
      arrived_z := fb_z2.done;
    ELSIF i = 3 THEN
      fb_z3(
        delta_t := 0.02,
        station_type := station_type,
        z_total_mm := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s := g_cfg[i].phys2d.drip_delay_s,
        z_mm := tmp_z,
        z_stage := tmp_zs,
        z_timer_s := tmp_zt
      );
      arrived_z := fb_z3.done;
    END_IF;
    g_state[i].z_mm := tmp_z;
    g_state[i].z_stage := tmp_zs;
    g_state[i].z_timer_s := tmp_zt;
    IF arrived_z THEN
      lookup(station_number := g_state[i].sink_station_target);
      g_state[i].target_x := lookup.x_mm;
      g_state[i].phase := 3;
    END_IF;
  END_IF;

  IF g_state[i].phase = 3 THEN
    tmp_x := g_state[i].x_mm;
    tmp_vx := g_state[i].vel_x;
    IF i = 1 THEN
      fb_x1(
        delta_t := 0.02,
        x_target := g_state[i].target_x,
        x_min := g_state[i].x_min_limit,
        x_max := g_state[i].x_max_limit,
        v_max := g_cfg[i].phys2d.x_max_mm_s,
        t_acc := g_cfg[i].phys2d.x_accel_s,
        t_dec := g_cfg[i].phys2d.x_decel_s,
        x_pos := tmp_x,
        v_x := tmp_vx
      );
      arrived_x := fb_x1.arrived;
    ELSIF i = 2 THEN
      fb_x2(
        delta_t := 0.02,
        x_target := g_state[i].target_x,
        x_min := g_state[i].x_min_limit,
        x_max := g_state[i].x_max_limit,
        v_max := g_cfg[i].phys2d.x_max_mm_s,
        t_acc := g_cfg[i].phys2d.x_accel_s,
        t_dec := g_cfg[i].phys2d.x_decel_s,
        x_pos := tmp_x,
        v_x := tmp_vx
      );
      arrived_x := fb_x2.arrived;
    ELSIF i = 3 THEN
      fb_x3(
        delta_t := 0.02,
        x_target := g_state[i].target_x,
        x_min := g_state[i].x_min_limit,
        x_max := g_state[i].x_max_limit,
        v_max := g_cfg[i].phys2d.x_max_mm_s,
        t_acc := g_cfg[i].phys2d.x_accel_s,
        t_dec := g_cfg[i].phys2d.x_decel_s,
        x_pos := tmp_x,
        v_x := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_state[i].x_mm := tmp_x;
    g_state[i].vel_x := tmp_vx;

    IF arrived_x THEN
      g_state[i].current_station := g_state[i].sink_station_target;
      lookup(station_number := g_state[i].sink_station_target);
      device_delay := lookup.device_delay_s;
      g_state[i].z_timer_s := device_delay + g_cfg[i].phys2d.drip_delay_s;
      g_state[i].z_stage := 6;
      g_state[i].phase := 4;
    END_IF;
  END_IF;

  IF g_state[i].phase = 4 THEN
    lookup(station_number := g_state[i].sink_station_target);
    station_type := lookup.stype;
    tmp_z := g_state[i].z_mm;
    tmp_zs := g_state[i].z_stage;
    tmp_zt := g_state[i].z_timer_s;
    IF i = 1 THEN
      fb_z1(
        delta_t := 0.02,
        station_type := station_type,
        z_total_mm := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s := g_cfg[i].phys2d.drip_delay_s,
        z_mm := tmp_z,
        z_stage := tmp_zs,
        z_timer_s := tmp_zt
      );
      arrived_z := fb_z1.done;
    ELSIF i = 2 THEN
      fb_z2(
        delta_t := 0.02,
        station_type := station_type,
        z_total_mm := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s := g_cfg[i].phys2d.drip_delay_s,
        z_mm := tmp_z,
        z_stage := tmp_zs,
        z_timer_s := tmp_zt
      );
      arrived_z := fb_z2.done;
    ELSIF i = 3 THEN
      fb_z3(
        delta_t := 0.02,
        station_type := station_type,
        z_total_mm := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s := g_cfg[i].phys2d.drip_delay_s,
        z_mm := tmp_z,
        z_stage := tmp_zs,
        z_timer_s := tmp_zt
      );
      arrived_z := fb_z3.done;
    END_IF;
    g_state[i].z_mm := tmp_z;
    g_state[i].z_stage := tmp_zs;
    g_state[i].z_timer_s := tmp_zt;
    IF arrived_z THEN
      g_state[i].phase := 0;
    END_IF;
  END_IF;

  min_dist := 1.0e9;
  nearest_num := g_state[i].current_station;
  FOR idx := 101 TO 125 DO
    IF g_stations[idx].tank_id <> 0 THEN
      dx := g_stations[idx].x_position - g_state[i].x_mm;
      IF ABS(dx) < min_dist THEN
        min_dist := ABS(dx);
        nearest_num := idx;
      END_IF;
    END_IF;
  END_FOR;
  g_state[i].current_station := nearest_num;

  END_IF;  (* active *)
END_FOR;

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

(* === MODBUS INPUT: Read commands from input registers === *)
g_cmd_start[1] := iw_cmd_start_1 <> 0;
g_cmd_lift_station[1] := iw_cmd_lift_1;
g_cmd_sink_station[1] := iw_cmd_sink_1;
g_cmd_start[2] := iw_cmd_start_2 <> 0;
g_cmd_lift_station[2] := iw_cmd_lift_2;
g_cmd_sink_station[2] := iw_cmd_sink_2;

(* === MODBUS OUTPUT: Write transporter 1 state === *)
qw_t1_x_mm := REAL_TO_INT(g_state[1].x_mm);
qw_t1_z_mm := REAL_TO_INT(g_state[1].z_mm);
qw_t1_vel_x10 := REAL_TO_INT(g_state[1].vel_x * 10.0);
qw_t1_phase := g_state[1].phase;
qw_t1_z_stage := g_state[1].z_stage;
qw_t1_cur_st := g_state[1].current_station;
qw_t1_lift_tgt := g_state[1].lift_station_target;
qw_t1_sink_tgt := g_state[1].sink_station_target;
IF g_state[1].active THEN qw_t1_active := 1; ELSE qw_t1_active := 0; END_IF;

(* === MODBUS OUTPUT: Write transporter 2 state === *)
qw_t2_x_mm := REAL_TO_INT(g_state[2].x_mm);
qw_t2_z_mm := REAL_TO_INT(g_state[2].z_mm);
qw_t2_vel_x10 := REAL_TO_INT(g_state[2].vel_x * 10.0);
qw_t2_phase := g_state[2].phase;
qw_t2_z_stage := g_state[2].z_stage;
qw_t2_cur_st := g_state[2].current_station;
qw_t2_lift_tgt := g_state[2].lift_station_target;
qw_t2_sink_tgt := g_state[2].sink_station_target;
IF g_state[2].active THEN qw_t2_active := 1; ELSE qw_t2_active := 0; END_IF;

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
END_PROGRAM
