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
  (* Modbus output: units QW22..QW71 *)
  qw_u1_batch  : INT;
  qw_u1_loc  : INT;
  qw_u1_status  : INT;
  qw_u1_state  : INT;
  qw_u1_target  : INT;
  qw_u2_batch  : INT;
  qw_u2_loc  : INT;
  qw_u2_status  : INT;
  qw_u2_state  : INT;
  qw_u2_target  : INT;
  qw_u3_batch  : INT;
  qw_u3_loc  : INT;
  qw_u3_status  : INT;
  qw_u3_state  : INT;
  qw_u3_target  : INT;
  qw_u4_batch  : INT;
  qw_u4_loc  : INT;
  qw_u4_status  : INT;
  qw_u4_state  : INT;
  qw_u4_target  : INT;
  qw_u5_batch  : INT;
  qw_u5_loc  : INT;
  qw_u5_status  : INT;
  qw_u5_state  : INT;
  qw_u5_target  : INT;
  qw_u6_batch  : INT;
  qw_u6_loc  : INT;
  qw_u6_status  : INT;
  qw_u6_state  : INT;
  qw_u6_target  : INT;
  qw_u7_batch  : INT;
  qw_u7_loc  : INT;
  qw_u7_status  : INT;
  qw_u7_state  : INT;
  qw_u7_target  : INT;
  qw_u8_batch  : INT;
  qw_u8_loc  : INT;
  qw_u8_status  : INT;
  qw_u8_state  : INT;
  qw_u8_target  : INT;
  qw_u9_batch  : INT;
  qw_u9_loc  : INT;
  qw_u9_status  : INT;
  qw_u9_state  : INT;
  qw_u9_target  : INT;
  qw_u10_batch : INT;
  qw_u10_loc : INT;
  qw_u10_status : INT;
  qw_u10_state : INT;
  qw_u10_target : INT;
  qw_unit_ack  : INT;
  (* Modbus input: unit write command IW20..IW26 *)
  iw_unit_seq    : INT;
  iw_unit_id     : INT;
  iw_unit_batch  : INT;
  iw_unit_loc    : INT;
  iw_unit_status : INT;
  iw_unit_state  : INT;
  iw_unit_target : INT;
END_VAR
VAR
  init_done      : BOOL := FALSE;
  last_cfg_seq   : INT := 0;
  last_unit_seq  : INT := 0;
  i            : INT;
  idx          : INT;
  station_type : INT;
  device_delay : REAL;
  drop_time    : REAL;
  slow_start   : REAL;
  arrived_x    : BOOL;
  nearest_num  : INT;
  min_dist     : REAL;
  dx           : REAL;
  tmp_x        : REAL;
  tmp_vx       : REAL;
  fb_x1        : FB_XMotion;
  fb_x2        : FB_XMotion;
  fb_x3        : FB_XMotion;
  lookup       : FB_StationLookup;
  cycle_count  : INT;
END_VAR
(* ============================================================
   CONFIG UPLOAD HANDLER
   Gateway writes station data one at a time via Modbus IW regs.
   Sequence number change triggers processing.
   cmd=1: write one station  cmd=2: finish init (start sim)
   ============================================================ *)
IF iw_cfg_seq <> last_cfg_seq THEN
  last_cfg_seq := iw_cfg_seq;

  IF iw_cfg_cmd = 1 THEN
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

    (* Clear old station data for slots not uploaded *)
    FOR idx := 101 TO 125 DO
      IF g_stations[idx].tank_id = 0 THEN
        g_stations[idx].x_position := 0.0;
        g_stations[idx].y_position := 0.0;
        g_stations[idx].z_position := 0.0;
        g_stations[idx].stn_type := 0;
        g_stations[idx].dropping_time := 0.0;
        g_stations[idx].device_delay := 0.0;
      END_IF;
    END_FOR;

    (* Transporter 1 config — hardcoded for now *)
    g_cfg[1].id := 1;
    g_cfg[1].start_station := 101;
    g_cfg[1].x_min_limit := 100.0;
    g_cfg[1].x_max_limit := 20600.0;
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

    (* Transporter 2 config *)
    g_cfg[2].id := 2;
    g_cfg[2].start_station := 118;
    g_cfg[2].x_min_limit := 14300.0;
    g_cfg[2].x_max_limit := 29100.0;
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

      lookup(station_number := g_cfg[i].start_station);
      IF lookup.found THEN
        g_state[i].x_mm := lookup.x_mm;
        g_state[i].current_station := g_cfg[i].start_station;
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
    IF IsWetStationType(station_type) THEN
      slow_start := g_cfg[i].phys2d.z_slow_wet_mm;
    ELSE
      slow_start := g_cfg[i].phys2d.z_slow_dry_mm;
    END_IF;

    CASE g_state[i].z_stage OF
      1:
        g_state[i].z_timer_s := g_state[i].z_timer_s - 0.02;
        IF g_state[i].z_timer_s <= 0.0 THEN
          g_state[i].z_stage := 2;
          g_state[i].z_mm := g_cfg[i].phys2d.z_total_mm;
        END_IF;
      2:
        g_state[i].z_mm := g_state[i].z_mm - g_cfg[i].phys2d.z_slow_mm_s * 0.02;
        IF g_state[i].z_mm <= (g_cfg[i].phys2d.z_total_mm - slow_start) THEN
          g_state[i].z_stage := 3;
        END_IF;
      3:
        g_state[i].z_mm := g_state[i].z_mm - g_cfg[i].phys2d.z_fast_mm_s * 0.02;
        IF g_state[i].z_mm <= g_cfg[i].phys2d.z_slow_end_mm THEN
          g_state[i].z_stage := 4;
        END_IF;
      4:
        g_state[i].z_mm := g_state[i].z_mm - g_cfg[i].phys2d.z_slow_mm_s * 0.02;
        IF g_state[i].z_mm <= 0.0 THEN
          g_state[i].z_mm := 0.0;
          g_state[i].z_timer_s := g_cfg[i].phys2d.drip_delay_s;
          g_state[i].z_stage := 5;
        END_IF;
      5:
        g_state[i].z_timer_s := g_state[i].z_timer_s - 0.02;
        IF g_state[i].z_timer_s <= 0.0 THEN
          g_state[i].z_stage := 0;
          lookup(station_number := g_state[i].sink_station_target);
          g_state[i].target_x := lookup.x_mm;
          g_state[i].phase := 3;
        END_IF;
    END_CASE;
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
    IF IsWetStationType(station_type) THEN
      slow_start := g_cfg[i].phys2d.z_slow_wet_mm;
    ELSE
      slow_start := g_cfg[i].phys2d.z_slow_dry_mm;
    END_IF;

    CASE g_state[i].z_stage OF
      6:
        g_state[i].z_timer_s := g_state[i].z_timer_s - 0.02;
        IF g_state[i].z_timer_s <= 0.0 THEN
          g_state[i].z_stage := 7;
        END_IF;
      7:
        g_state[i].z_mm := g_state[i].z_mm + g_cfg[i].phys2d.z_fast_mm_s * 0.02;
        IF g_state[i].z_mm >= (g_cfg[i].phys2d.z_total_mm - slow_start) THEN
          g_state[i].z_stage := 8;
        END_IF;
      8:
        g_state[i].z_mm := g_state[i].z_mm + g_cfg[i].phys2d.z_slow_mm_s * 0.02;
        IF g_state[i].z_mm >= g_cfg[i].phys2d.z_total_mm THEN
          g_state[i].z_mm := g_cfg[i].phys2d.z_total_mm;
          g_state[i].z_stage := 0;
          g_state[i].phase := 0;
        END_IF;
    END_CASE;
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
    g_units[iw_unit_id].batch_id := iw_unit_batch;
    g_units[iw_unit_id].location := iw_unit_loc;
    g_units[iw_unit_id].status   := iw_unit_status;
    g_units[iw_unit_id].state    := iw_unit_state;
    g_units[iw_unit_id].target   := iw_unit_target;
  END_IF;
  qw_unit_ack := iw_unit_seq;
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

(* Write unit data to Modbus output QW22..QW71 *)
qw_u1_batch  := g_units[1].batch_id;
qw_u1_loc    := g_units[1].location;
qw_u1_status := g_units[1].status;
qw_u1_state  := g_units[1].state;
qw_u1_target := g_units[1].target;
qw_u2_batch  := g_units[2].batch_id;
qw_u2_loc    := g_units[2].location;
qw_u2_status := g_units[2].status;
qw_u2_state  := g_units[2].state;
qw_u2_target := g_units[2].target;
qw_u3_batch  := g_units[3].batch_id;
qw_u3_loc    := g_units[3].location;
qw_u3_status := g_units[3].status;
qw_u3_state  := g_units[3].state;
qw_u3_target := g_units[3].target;
qw_u4_batch  := g_units[4].batch_id;
qw_u4_loc    := g_units[4].location;
qw_u4_status := g_units[4].status;
qw_u4_state  := g_units[4].state;
qw_u4_target := g_units[4].target;
qw_u5_batch  := g_units[5].batch_id;
qw_u5_loc    := g_units[5].location;
qw_u5_status := g_units[5].status;
qw_u5_state  := g_units[5].state;
qw_u5_target := g_units[5].target;
qw_u6_batch  := g_units[6].batch_id;
qw_u6_loc    := g_units[6].location;
qw_u6_status := g_units[6].status;
qw_u6_state  := g_units[6].state;
qw_u6_target := g_units[6].target;
qw_u7_batch  := g_units[7].batch_id;
qw_u7_loc    := g_units[7].location;
qw_u7_status := g_units[7].status;
qw_u7_state  := g_units[7].state;
qw_u7_target := g_units[7].target;
qw_u8_batch  := g_units[8].batch_id;
qw_u8_loc    := g_units[8].location;
qw_u8_status := g_units[8].status;
qw_u8_state  := g_units[8].state;
qw_u8_target := g_units[8].target;
qw_u9_batch  := g_units[9].batch_id;
qw_u9_loc    := g_units[9].location;
qw_u9_status := g_units[9].status;
qw_u9_state  := g_units[9].state;
qw_u9_target := g_units[9].target;
qw_u10_batch  := g_units[10].batch_id;
qw_u10_loc    := g_units[10].location;
qw_u10_status := g_units[10].status;
qw_u10_state  := g_units[10].state;
qw_u10_target := g_units[10].target;
END_PROGRAM
