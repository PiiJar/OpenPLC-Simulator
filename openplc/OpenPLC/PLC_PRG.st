(************************************************************
* OpenPLC - 2D Physics Core (Program)
************************************************************)

PROGRAM PLC_PRG
VAR
  init_done : BOOL := FALSE;
  i : INT;
  idx : INT;
  station_type : INT;
  device_delay : REAL;
  drop_time : REAL;
  slow_start : REAL;
  arrived_x : BOOL;
  nearest_num : INT;
  min_dist : REAL;
  dx : REAL;

  fb_x : ARRAY[1..MAX_TRANSPORTERS] OF FB_XMotion;
END_VAR

IF NOT init_done THEN
  g_station_count := 21;

  g_stations[1] := (number := 101, x_mm := 100.0, station_type := 22, device_delay_s := 0.0, dropping_time_s := 0.0);
  g_stations[2] := (number := 102, x_mm := 1550.0, station_type := 30, device_delay_s := 0.0, dropping_time_s := 0.0);
  g_stations[3] := (number := 103, x_mm := 3000.0, station_type := 30, device_delay_s := 0.0, dropping_time_s := 0.0);
  g_stations[4] := (number := 104, x_mm := 4450.0, station_type := 0, device_delay_s := 3.0, dropping_time_s := 0.0);
  g_stations[5] := (number := 105, x_mm := 5900.0, station_type := 0, device_delay_s := 3.0, dropping_time_s := 0.0);
  g_stations[6] := (number := 106, x_mm := 7350.0, station_type := 0, device_delay_s := 3.0, dropping_time_s := 0.0);
  g_stations[7] := (number := 107, x_mm := 8800.0, station_type := 1, device_delay_s := 3.0, dropping_time_s := 10.0);
  g_stations[8] := (number := 108, x_mm := 10250.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[9] := (number := 109, x_mm := 11700.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[10] := (number := 110, x_mm := 13150.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[11] := (number := 111, x_mm := 14600.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[12] := (number := 112, x_mm := 16050.0, station_type := 1, device_delay_s := 3.0, dropping_time_s := 10.0);
  g_stations[13] := (number := 113, x_mm := 17500.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[14] := (number := 114, x_mm := 18950.0, station_type := 32, device_delay_s := 0.0, dropping_time_s := 0.0);
  g_stations[15] := (number := 115, x_mm := 20400.0, station_type := 0, device_delay_s := 3.0, dropping_time_s := 10.0);
  g_stations[16] := (number := 116, x_mm := 21850.0, station_type := 1, device_delay_s := 3.0, dropping_time_s := 10.0);
  g_stations[17] := (number := 117, x_mm := 23300.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[18] := (number := 118, x_mm := 24750.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);
  g_stations[19] := (number := 119, x_mm := 26200.0, station_type := 30, device_delay_s := 0.0, dropping_time_s := 0.0);
  g_stations[20] := (number := 120, x_mm := 27650.0, station_type := 30, device_delay_s := 0.0, dropping_time_s := 0.0);
  g_stations[21] := (number := 121, x_mm := 29100.0, station_type := 1, device_delay_s := 0.0, dropping_time_s := 10.0);

  g_cfg[1].id := 1;
  g_cfg[1].start_station := 101;
  g_cfg[1].x_min_limit := 100.0;
  g_cfg[1].x_max_limit := 20600.0;
  g_cfg[1].phys2d := (
    x_accel_s := 1.5,
    x_decel_s := 1.5,
    x_max_mm_s := 500.0,
    z_total_mm := 2500.0,
    z_slow_dry_mm := 300.0,
    z_slow_wet_mm := 1000.0,
    z_slow_end_mm := 50.0,
    z_slow_mm_s := 100.0,
    z_fast_mm_s := 200.0,
    drip_delay_s := 5.0,
    avoid_mm := 2000.0
  );

  g_cfg[2].id := 2;
  g_cfg[2].start_station := 118;
  g_cfg[2].x_min_limit := 14300.0;
  g_cfg[2].x_max_limit := 29100.0;
  g_cfg[2].phys2d := (
    x_accel_s := 1.5,
    x_decel_s := 1.5,
    x_max_mm_s := 500.0,
    z_total_mm := 2500.0,
    z_slow_dry_mm := 300.0,
    z_slow_wet_mm := 1000.0,
    z_slow_end_mm := 50.0,
    z_slow_mm_s := 100.0,
    z_fast_mm_s := 200.0,
    drip_delay_s := 5.0,
    avoid_mm := 2000.0
  );

  FOR i := 1 TO MAX_TRANSPORTERS DO
    g_state[i].active := (i <= 2);
    g_state[i].phase := PHASE_IDLE;
    g_state[i].z_stage := Z_IDLE;
    g_state[i].vel_x := 0.0;
    g_state[i].vel_z := 0.0;
    g_state[i].z_timer_s := 0.0;
    g_state[i].x_min_limit := g_cfg[i].x_min_limit;
    g_state[i].x_max_limit := g_cfg[i].x_max_limit;

    idx := FindStationIndexByNumber(g_cfg[i].start_station);
    IF idx > 0 THEN
      g_state[i].x_mm := g_stations[idx].x_mm;
      g_state[i].current_station := g_stations[idx].number;
    ELSE
      g_state[i].x_mm := 0.0;
      g_state[i].current_station := 0;
    END_IF
    g_state[i].z_mm := 0.0;
  END_FOR

  init_done := TRUE;
END_IF

FOR i := 1 TO MAX_TRANSPORTERS DO
  IF NOT g_state[i].active THEN
    CONTINUE;
  END_IF

  IF (g_state[i].phase = PHASE_IDLE) AND g_cmd_start[i] THEN
    g_state[i].lift_station_target := g_cmd_lift_station[i];
    g_state[i].sink_station_target := g_cmd_sink_station[i];
    g_state[i].target_x := GetStationX(g_state[i].lift_station_target);
    g_state[i].phase := PHASE_MOVE_TO_LIFT;
    g_state[i].z_stage := Z_IDLE;
    g_state[i].z_timer_s := 0.0;
  END_IF

  IF g_state[i].phase = PHASE_MOVE_TO_LIFT THEN
    fb_x[i](
      dt := DT_S,
      x_target := g_state[i].target_x,
      x_min := g_state[i].x_min_limit,
      x_max := g_state[i].x_max_limit,
      v_max := g_cfg[i].phys2d.x_max_mm_s,
      t_acc := g_cfg[i].phys2d.x_accel_s,
      t_dec := g_cfg[i].phys2d.x_decel_s,
      x_pos := g_state[i].x_mm,
      v_x := g_state[i].vel_x
    );
    arrived_x := fb_x[i].arrived;
    IF arrived_x THEN
      g_state[i].current_station := g_state[i].lift_station_target;
      device_delay := GetStationDeviceDelay(g_state[i].lift_station_target);
      drop_time := GetStationDroppingTime(g_state[i].lift_station_target);
      g_state[i].z_timer_s := device_delay + drop_time;
      g_state[i].z_stage := Z_DELAY_UP;
      g_state[i].phase := PHASE_LIFTING;
    END_IF
  END_IF

  IF g_state[i].phase = PHASE_LIFTING THEN
    station_type := GetStationType(g_state[i].lift_station_target);
    IF IsWetStationType(station_type) THEN
      slow_start := g_cfg[i].phys2d.z_slow_wet_mm;
    ELSE
      slow_start := g_cfg[i].phys2d.z_slow_dry_mm;
    END_IF

    CASE g_state[i].z_stage OF
      Z_DELAY_UP:
        g_state[i].z_timer_s := g_state[i].z_timer_s - DT_S;
        IF g_state[i].z_timer_s <= 0.0 THEN
          g_state[i].z_stage := Z_UP_SLOW;
          g_state[i].z_mm := g_cfg[i].phys2d.z_total_mm;
        END_IF
      Z_UP_SLOW:
        g_state[i].z_mm := g_state[i].z_mm - g_cfg[i].phys2d.z_slow_mm_s * DT_S;
        IF g_state[i].z_mm <= (g_cfg[i].phys2d.z_total_mm - slow_start) THEN
          g_state[i].z_stage := Z_UP_FAST;
        END_IF
      Z_UP_FAST:
        g_state[i].z_mm := g_state[i].z_mm - g_cfg[i].phys2d.z_fast_mm_s * DT_S;
        IF g_state[i].z_mm <= g_cfg[i].phys2d.z_slow_end_mm THEN
          g_state[i].z_stage := Z_UP_SLOW_END;
        END_IF
      Z_UP_SLOW_END:
        g_state[i].z_mm := g_state[i].z_mm - g_cfg[i].phys2d.z_slow_mm_s * DT_S;
        IF g_state[i].z_mm <= 0.0 THEN
          g_state[i].z_mm := 0.0;
          g_state[i].z_timer_s := g_cfg[i].phys2d.drip_delay_s;
          g_state[i].z_stage := Z_DRIP_UP;
        END_IF
      Z_DRIP_UP:
        g_state[i].z_timer_s := g_state[i].z_timer_s - DT_S;
        IF g_state[i].z_timer_s <= 0.0 THEN
          g_state[i].z_stage := Z_IDLE;
          g_state[i].target_x := GetStationX(g_state[i].sink_station_target);
          g_state[i].phase := PHASE_MOVE_TO_SINK;
        END_IF
    ELSE
    END_CASE
  END_IF

  IF g_state[i].phase = PHASE_MOVE_TO_SINK THEN
    fb_x[i](
      dt := DT_S,
      x_target := g_state[i].target_x,
      x_min := g_state[i].x_min_limit,
      x_max := g_state[i].x_max_limit,
      v_max := g_cfg[i].phys2d.x_max_mm_s,
      t_acc := g_cfg[i].phys2d.x_accel_s,
      t_dec := g_cfg[i].phys2d.x_decel_s,
      x_pos := g_state[i].x_mm,
      v_x := g_state[i].vel_x
    );
    arrived_x := fb_x[i].arrived;
    IF arrived_x THEN
      g_state[i].current_station := g_state[i].sink_station_target;
      device_delay := GetStationDeviceDelay(g_state[i].sink_station_target);
      g_state[i].z_timer_s := device_delay + g_cfg[i].phys2d.drip_delay_s;
      g_state[i].z_stage := Z_DELAY_DOWN;
      g_state[i].phase := PHASE_SINKING;
    END_IF
  END_IF

  IF g_state[i].phase = PHASE_SINKING THEN
    station_type := GetStationType(g_state[i].sink_station_target);
    IF IsWetStationType(station_type) THEN
      slow_start := g_cfg[i].phys2d.z_slow_wet_mm;
    ELSE
      slow_start := g_cfg[i].phys2d.z_slow_dry_mm;
    END_IF

    CASE g_state[i].z_stage OF
      Z_DELAY_DOWN:
        g_state[i].z_timer_s := g_state[i].z_timer_s - DT_S;
        IF g_state[i].z_timer_s <= 0.0 THEN
          g_state[i].z_stage := Z_DOWN_FAST;
        END_IF
      Z_DOWN_FAST:
        g_state[i].z_mm := g_state[i].z_mm + g_cfg[i].phys2d.z_fast_mm_s * DT_S;
        IF g_state[i].z_mm >= (g_cfg[i].phys2d.z_total_mm - slow_start) THEN
          g_state[i].z_stage := Z_DOWN_SLOW;
        END_IF
      Z_DOWN_SLOW:
        g_state[i].z_mm := g_state[i].z_mm + g_cfg[i].phys2d.z_slow_mm_s * DT_S;
        IF g_state[i].z_mm >= g_cfg[i].phys2d.z_total_mm THEN
          g_state[i].z_mm := g_cfg[i].phys2d.z_total_mm;
          g_state[i].z_stage := Z_IDLE;
          g_state[i].phase := PHASE_IDLE;
        END_IF
    ELSE
    END_CASE
  END_IF

  min_dist := 1.0e9;
  nearest_num := g_state[i].current_station;
  FOR idx := 1 TO g_station_count DO
    dx := g_stations[idx].x_mm - g_state[i].x_mm;
    IF ABS(dx) < min_dist THEN
      min_dist := ABS(dx);
      nearest_num := g_stations[idx].number;
    END_IF
  END_FOR
  g_state[i].current_station := nearest_num;
END_FOR

END_PROGRAM
