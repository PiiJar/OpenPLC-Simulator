(* ============================================================
   plc_prg.st — Main program: station init + transport cycle
   ============================================================ *)

PROGRAM PLC_PRG
VAR_EXTERNAL
  g_station_count    : INT;
  g_stations         : ARRAY[1..21] OF STATION_T;
  g_cfg              : ARRAY[1..10] OF TRANSPORTER_CFG_T;
  g_state            : ARRAY[1..10] OF TRANSPORTER_STATE_T;
  g_cmd_start        : ARRAY[1..10] OF BOOL;
  g_cmd_lift_station : ARRAY[1..10] OF INT;
  g_cmd_sink_station : ARRAY[1..10] OF INT;
  qw_t1_x_mm    : INT;
  qw_t1_z_mm    : INT;
  qw_t1_vel_x10 : INT;
  qw_t1_phase   : INT;
  qw_t1_z_stage : INT;
  qw_t1_cur_st  : INT;
  qw_t1_lift_tgt : INT;
  qw_t1_sink_tgt : INT;
  qw_t1_active  : INT;
  qw_t2_x_mm    : INT;
  qw_t2_z_mm    : INT;
  qw_t2_vel_x10 : INT;
  qw_t2_phase   : INT;
  qw_t2_z_stage : INT;
  qw_t2_cur_st  : INT;
  qw_t2_lift_tgt : INT;
  qw_t2_sink_tgt : INT;
  qw_t2_active  : INT;
  qw_station_cnt : INT;
  qw_init_done   : INT;
  qw_cycle_cnt   : INT;
  iw_cmd_start_1 : INT;
  iw_cmd_lift_1  : INT;
  iw_cmd_sink_1  : INT;
  iw_cmd_start_2 : INT;
  iw_cmd_lift_2  : INT;
  iw_cmd_sink_2  : INT;
END_VAR
VAR
  init_done    : BOOL := FALSE;
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
  lookup       : FB_StationLookup;
  cycle_count  : INT;
END_VAR
IF NOT init_done THEN
  g_station_count := 21;

  g_stations[1].number := 101;
  g_stations[1].x_mm := 100.0;
  g_stations[1].station_type := 22;
  g_stations[1].device_delay_s := 0.0;
  g_stations[1].dropping_time_s := 0.0;

  g_stations[2].number := 102;
  g_stations[2].x_mm := 1550.0;
  g_stations[2].station_type := 30;
  g_stations[2].device_delay_s := 0.0;
  g_stations[2].dropping_time_s := 0.0;

  g_stations[3].number := 103;
  g_stations[3].x_mm := 3000.0;
  g_stations[3].station_type := 30;
  g_stations[3].device_delay_s := 0.0;
  g_stations[3].dropping_time_s := 0.0;

  g_stations[4].number := 104;
  g_stations[4].x_mm := 4450.0;
  g_stations[4].station_type := 0;
  g_stations[4].device_delay_s := 3.0;
  g_stations[4].dropping_time_s := 0.0;

  g_stations[5].number := 105;
  g_stations[5].x_mm := 5900.0;
  g_stations[5].station_type := 0;
  g_stations[5].device_delay_s := 3.0;
  g_stations[5].dropping_time_s := 0.0;

  g_stations[6].number := 106;
  g_stations[6].x_mm := 7350.0;
  g_stations[6].station_type := 0;
  g_stations[6].device_delay_s := 3.0;
  g_stations[6].dropping_time_s := 0.0;

  g_stations[7].number := 107;
  g_stations[7].x_mm := 8800.0;
  g_stations[7].station_type := 1;
  g_stations[7].device_delay_s := 3.0;
  g_stations[7].dropping_time_s := 10.0;

  g_stations[8].number := 108;
  g_stations[8].x_mm := 10250.0;
  g_stations[8].station_type := 1;
  g_stations[8].device_delay_s := 0.0;
  g_stations[8].dropping_time_s := 10.0;

  g_stations[9].number := 109;
  g_stations[9].x_mm := 11700.0;
  g_stations[9].station_type := 1;
  g_stations[9].device_delay_s := 0.0;
  g_stations[9].dropping_time_s := 10.0;

  g_stations[10].number := 110;
  g_stations[10].x_mm := 13150.0;
  g_stations[10].station_type := 1;
  g_stations[10].device_delay_s := 0.0;
  g_stations[10].dropping_time_s := 10.0;

  g_stations[11].number := 111;
  g_stations[11].x_mm := 14600.0;
  g_stations[11].station_type := 1;
  g_stations[11].device_delay_s := 0.0;
  g_stations[11].dropping_time_s := 10.0;

  g_stations[12].number := 112;
  g_stations[12].x_mm := 16050.0;
  g_stations[12].station_type := 1;
  g_stations[12].device_delay_s := 3.0;
  g_stations[12].dropping_time_s := 10.0;

  g_stations[13].number := 113;
  g_stations[13].x_mm := 17500.0;
  g_stations[13].station_type := 1;
  g_stations[13].device_delay_s := 0.0;
  g_stations[13].dropping_time_s := 10.0;

  g_stations[14].number := 114;
  g_stations[14].x_mm := 18950.0;
  g_stations[14].station_type := 32;
  g_stations[14].device_delay_s := 0.0;
  g_stations[14].dropping_time_s := 0.0;

  g_stations[15].number := 115;
  g_stations[15].x_mm := 20400.0;
  g_stations[15].station_type := 0;
  g_stations[15].device_delay_s := 3.0;
  g_stations[15].dropping_time_s := 10.0;

  g_stations[16].number := 116;
  g_stations[16].x_mm := 21850.0;
  g_stations[16].station_type := 1;
  g_stations[16].device_delay_s := 3.0;
  g_stations[16].dropping_time_s := 10.0;

  g_stations[17].number := 117;
  g_stations[17].x_mm := 23300.0;
  g_stations[17].station_type := 1;
  g_stations[17].device_delay_s := 0.0;
  g_stations[17].dropping_time_s := 10.0;

  g_stations[18].number := 118;
  g_stations[18].x_mm := 24750.0;
  g_stations[18].station_type := 1;
  g_stations[18].device_delay_s := 0.0;
  g_stations[18].dropping_time_s := 10.0;

  g_stations[19].number := 119;
  g_stations[19].x_mm := 26200.0;
  g_stations[19].station_type := 30;
  g_stations[19].device_delay_s := 0.0;
  g_stations[19].dropping_time_s := 0.0;

  g_stations[20].number := 120;
  g_stations[20].x_mm := 27650.0;
  g_stations[20].station_type := 30;
  g_stations[20].device_delay_s := 0.0;
  g_stations[20].dropping_time_s := 0.0;

  g_stations[21].number := 121;
  g_stations[21].x_mm := 29100.0;
  g_stations[21].station_type := 1;
  g_stations[21].device_delay_s := 0.0;
  g_stations[21].dropping_time_s := 10.0;

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

  FOR i := 1 TO 10 DO
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
END_IF;

FOR i := 1 TO 10 DO
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
  FOR idx := 1 TO g_station_count DO
    dx := g_stations[idx].x_mm - g_state[i].x_mm;
    IF ABS(dx) < min_dist THEN
      min_dist := ABS(dx);
      nearest_num := g_stations[idx].number;
    END_IF;
  END_FOR;
  g_state[i].current_station := nearest_num;

  END_IF;
END_FOR;

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
END_PROGRAM
