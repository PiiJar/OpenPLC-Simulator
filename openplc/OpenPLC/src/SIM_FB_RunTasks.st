(* ============================================================
   SIM_FB_RunTasks.st — Simulate transporter task execution

   For each active transporter [1..3], checks whether a new task
   has been assigned (task_id <> running_task_id) and executes
   the full transport cycle:

     Phase 0  idle        — waiting for new task
     Phase 1  to_lift     — X-drive towards lift station
     Phase 2  lifting     — Z-lift sequence (stages 1-5)
     Phase 3  to_sink     — X-drive towards sink station
     Phase 4  sinking     — Z-sink sequence (stages 6-8)

   Also maintains current_station (nearest station) every cycle.

   Called once per PLC scan from PLC_PRG.
   ============================================================ *)

FUNCTION_BLOCK SIM_FB_RunTasks
VAR_INPUT
  i_run : BOOL;       (* enable — typically init_done *)
END_VAR
VAR_EXTERNAL
  g_transporter  : ARRAY[1..3] OF STC_TRANSPORTER_T;
  g_stations     : ARRAY[101..125] OF STATION_T;
  g_cfg          : ARRAY[1..3] OF TRANSPORTER_CFG_T;
END_VAR
VAR
  i            : INT;
  idx          : INT;
  (* Physics FB instances — one per transporter (MATIEC needs separate instances) *)
  fb_x1        : SIM_FB_XMotion;
  fb_x2        : SIM_FB_XMotion;
  fb_x3        : SIM_FB_XMotion;
  fb_z1        : SIM_FB_ZMotion;
  fb_z2        : SIM_FB_ZMotion;
  fb_z3        : SIM_FB_ZMotion;
  (* Station lookup *)
  lookup       : STC_FB_FindStation;
  (* Temp vars for VAR_IN_OUT passing *)
  tmp_x        : REAL;
  tmp_vx       : REAL;
  tmp_z        : REAL;
  tmp_zs       : INT;
  tmp_zt       : REAL;
  arrived_x    : BOOL;
  arrived_z    : BOOL;
  station_type : INT;
  device_delay : REAL;
  drop_time    : REAL;
  (* Nearest-station calculation *)
  nearest_num  : INT;
  min_dist     : REAL;
  dx           : REAL;
END_VAR

IF NOT i_run THEN
  RETURN;
END_IF;

FOR i := 1 TO 3 DO
  IF g_transporter[i].active THEN

  (* ── Phase 0 → 1: Accept new task ───────────────────────── *)
  IF (g_transporter[i].phase = 0)
     AND (g_transporter[i].task_id <> g_transporter[i].running_task_id) THEN
    g_transporter[i].running_task_id := g_transporter[i].task_id;
    lookup(station_number := g_transporter[i].lift_station);
    g_transporter[i].final_target_x := lookup.x_mm;
    g_transporter[i].phase := 1;
    g_transporter[i].z_stage := 0;
    g_transporter[i].z_timer_s := 0.0;
  END_IF;

  (* ── Phase 1: Drive X towards lift station ──────────────── *)
  IF g_transporter[i].phase = 1 THEN
    tmp_x  := g_transporter[i].x_mm;
    tmp_vx := g_transporter[i].vel_x;
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := g_transporter[i].final_target_x,
        x_min    := g_transporter[i].x_min_limit,
        x_max    := g_transporter[i].x_max_limit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x1.arrived;
    ELSIF i = 2 THEN
      fb_x2(
        delta_t  := 0.02,
        x_target := g_transporter[i].final_target_x,
        x_min    := g_transporter[i].x_min_limit,
        x_max    := g_transporter[i].x_max_limit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x2.arrived;
    ELSIF i = 3 THEN
      fb_x3(
        delta_t  := 0.02,
        x_target := g_transporter[i].final_target_x,
        x_min    := g_transporter[i].x_min_limit,
        x_max    := g_transporter[i].x_max_limit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_transporter[i].x_mm  := tmp_x;
    g_transporter[i].vel_x := tmp_vx;

    IF arrived_x THEN
      g_transporter[i].current_station := g_transporter[i].lift_station;
      lookup(station_number := g_transporter[i].lift_station);
      device_delay := lookup.device_delay_s;
      drop_time    := lookup.dropping_time_s;
      g_transporter[i].z_timer_s := device_delay + drop_time;
      g_transporter[i].z_stage := 1;
      g_transporter[i].phase := 2;
    END_IF;
  END_IF;

  (* ── Phase 2: Lift Z at lift station ────────────────────── *)
  IF g_transporter[i].phase = 2 THEN
    lookup(station_number := g_transporter[i].lift_station);
    station_type := lookup.stype;
    tmp_z  := g_transporter[i].z_mm;
    tmp_zs := g_transporter[i].z_stage;
    tmp_zt := g_transporter[i].z_timer_s;
    IF i = 1 THEN
      fb_z1(
        delta_t       := 0.02,
        station_type  := station_type,
        z_total_mm    := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s   := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s   := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s  := g_cfg[i].phys2d.drip_delay_s,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z1.done;
    ELSIF i = 2 THEN
      fb_z2(
        delta_t       := 0.02,
        station_type  := station_type,
        z_total_mm    := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s   := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s   := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s  := g_cfg[i].phys2d.drip_delay_s,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z2.done;
    ELSIF i = 3 THEN
      fb_z3(
        delta_t       := 0.02,
        station_type  := station_type,
        z_total_mm    := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s   := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s   := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s  := g_cfg[i].phys2d.drip_delay_s,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z3.done;
    END_IF;
    g_transporter[i].z_mm      := tmp_z;
    g_transporter[i].z_stage   := tmp_zs;
    g_transporter[i].z_timer_s := tmp_zt;
    IF arrived_z THEN
      lookup(station_number := g_transporter[i].sink_station);
      g_transporter[i].final_target_x := lookup.x_mm;
      g_transporter[i].phase := 3;
    END_IF;
  END_IF;

  (* ── Phase 3: Drive X towards sink station ─────────────── *)
  IF g_transporter[i].phase = 3 THEN
    tmp_x  := g_transporter[i].x_mm;
    tmp_vx := g_transporter[i].vel_x;
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := g_transporter[i].final_target_x,
        x_min    := g_transporter[i].x_min_limit,
        x_max    := g_transporter[i].x_max_limit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x1.arrived;
    ELSIF i = 2 THEN
      fb_x2(
        delta_t  := 0.02,
        x_target := g_transporter[i].final_target_x,
        x_min    := g_transporter[i].x_min_limit,
        x_max    := g_transporter[i].x_max_limit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x2.arrived;
    ELSIF i = 3 THEN
      fb_x3(
        delta_t  := 0.02,
        x_target := g_transporter[i].final_target_x,
        x_min    := g_transporter[i].x_min_limit,
        x_max    := g_transporter[i].x_max_limit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_transporter[i].x_mm  := tmp_x;
    g_transporter[i].vel_x := tmp_vx;

    IF arrived_x THEN
      g_transporter[i].current_station := g_transporter[i].sink_station;
      lookup(station_number := g_transporter[i].sink_station);
      device_delay := lookup.device_delay_s;
      g_transporter[i].z_timer_s := device_delay + g_cfg[i].phys2d.drip_delay_s;
      g_transporter[i].z_stage := 6;
      g_transporter[i].phase := 4;
    END_IF;
  END_IF;

  (* ── Phase 4: Sink Z at sink station ───────────────────── *)
  IF g_transporter[i].phase = 4 THEN
    lookup(station_number := g_transporter[i].sink_station);
    station_type := lookup.stype;
    tmp_z  := g_transporter[i].z_mm;
    tmp_zs := g_transporter[i].z_stage;
    tmp_zt := g_transporter[i].z_timer_s;
    IF i = 1 THEN
      fb_z1(
        delta_t       := 0.02,
        station_type  := station_type,
        z_total_mm    := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s   := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s   := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s  := g_cfg[i].phys2d.drip_delay_s,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z1.done;
    ELSIF i = 2 THEN
      fb_z2(
        delta_t       := 0.02,
        station_type  := station_type,
        z_total_mm    := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s   := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s   := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s  := g_cfg[i].phys2d.drip_delay_s,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z2.done;
    ELSIF i = 3 THEN
      fb_z3(
        delta_t       := 0.02,
        station_type  := station_type,
        z_total_mm    := g_cfg[i].phys2d.z_total_mm,
        z_slow_dry_mm := g_cfg[i].phys2d.z_slow_dry_mm,
        z_slow_wet_mm := g_cfg[i].phys2d.z_slow_wet_mm,
        z_slow_end_mm := g_cfg[i].phys2d.z_slow_end_mm,
        z_slow_mm_s   := g_cfg[i].phys2d.z_slow_mm_s,
        z_fast_mm_s   := g_cfg[i].phys2d.z_fast_mm_s,
        drip_delay_s  := g_cfg[i].phys2d.drip_delay_s,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z3.done;
    END_IF;
    g_transporter[i].z_mm      := tmp_z;
    g_transporter[i].z_stage   := tmp_zs;
    g_transporter[i].z_timer_s := tmp_zt;
    IF arrived_z THEN
      g_transporter[i].phase := 0;
    END_IF;
  END_IF;

  (* ── Nearest station tracking ──────────────────────────── *)
  min_dist := 1.0e9;
  nearest_num := g_transporter[i].current_station;
  FOR idx := 101 TO 125 DO
    IF g_stations[idx].tank_id <> 0 THEN
      dx := g_stations[idx].x_position - g_transporter[i].x_mm;
      IF ABS(dx) < min_dist THEN
        min_dist := ABS(dx);
        nearest_num := idx;
      END_IF;
    END_IF;
  END_FOR;
  g_transporter[i].current_station := nearest_num;

  END_IF;  (* active *)
END_FOR;

END_FUNCTION_BLOCK
