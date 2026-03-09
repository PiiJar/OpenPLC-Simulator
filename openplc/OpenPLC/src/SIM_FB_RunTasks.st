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
VAR_EXTERNAL CONSTANT
    MAX_Transporters    : INT;
    MAX_Units           : INT;
    MAX_STEPS_PER_PROGRAM          : INT;
    MIN_StationIndex : INT;
    MAX_StationIndex   : INT;
    IN_PROCESS          : INT;
END_VAR

VAR_EXTERNAL
  g_transporter  : ARRAY[1..MAX_Transporters] OF STC_TRANSPORTER_T;
  g_station     : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_StationType;    g_station_loc  : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_UnitLocation;  g_cfg          : ARRAY[1..MAX_Transporters] OF TRANSPORTER_CFG_T;
  g_move         : ARRAY[1..MAX_Transporters] OF MOVE_TIMES_T;
  g_unit         : ARRAY[1..MAX_Units] OF UNIT_T;
  g_batch        : ARRAY[1..MAX_Units] OF BATCH_T;
  g_program      : ARRAY[1..MAX_Units] OF TREATMENT_PROGRAM_T;
  g_time_s       : LINT;
  g_event_pending       : EVENT_MSG_T;
  g_event_pending_valid : BOOL;
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
  tmp_x        : DINT;
  tmp_vx       : DINT;
  tmp_z        : DINT;
  tmp_zs       : INT;
  tmp_zt       : REAL;
  arrived_x    : BOOL;
  at_station   : BOOL;    (* TRUE only when actually at station, not just at drive limit *)
  arrived_z    : BOOL;
  station_kind : INT;
  device_delay : REAL;
  drop_time    : REAL;
  pick_unit_id : INT;     (* unit_id picked up from lift station *)
  sink_unit_id : INT;     (* unit_id being placed at sink station *)
  (* Nearest-station calculation *)
  nearest_num  : INT;
  min_dist     : DINT;
  dx           : DINT;
  (* Time measurement instances *)
  tm1          : STC_FB_MeasureMoveTimes;
  tm2          : STC_FB_MeasureMoveTimes;
  tm3          : STC_FB_MeasureMoveTimes;
  (* Unit location update instances *)
  upd_loc1     : STC_FB_UpdateUnitLocation;
  upd_loc2     : STC_FB_UpdateUnitLocation;
  upd_loc3     : STC_FB_UpdateUnitLocation;
  (* Event helpers *)
  evt_unit     : INT;
  evt_diff     : LINT;
  (* Treatment time wait *)
  can_lift       : BOOL;
  lift_uid       : INT;      (* unit at lift station *)
  treat_cal      : DINT;      (* treatment cal_time for current stage *)
  treat_elapsed  : LINT;     (* seconds spent at lift station *)
END_VAR

IF NOT i_run THEN
  RETURN;
END_IF;

FOR i := 1 TO MAX_Transporters DO
  IF g_transporter[i].active THEN

  (* ── Phase 0 → 1: Accept new task ───────────────────────── *)
  IF (g_transporter[i].phase = 0)
     AND (g_transporter[i].task_id <> g_transporter[i].running_task_id) THEN
    g_transporter[i].running_task_id := g_transporter[i].task_id;
    lookup(station_number := g_transporter[i].lift_station);
    g_transporter[i].XFinalTarget := lookup.x_mm;
    g_transporter[i].phase := 1;
    g_transporter[i].status := 4;  (* auto_run *)
    g_transporter[i].z_stage := 0;
    g_transporter[i].z_timer_s := 0.0;

  (* ── Phase 1: Drive X towards lift station ──────────────── *)
  ELSIF g_transporter[i].phase = 1 THEN
    tmp_x  := g_transporter[i].XPosition;
    tmp_vx := g_transporter[i].XVelocity;
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
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
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
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
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_transporter[i].XPosition  := tmp_x;
    g_transporter[i].XVelocity := tmp_vx;

    (* Only transition when actually at station, not just at drive limit *)
    at_station := arrived_x
                  AND (ABS(g_transporter[i].XPosition - g_transporter[i].XFinalTarget) <= 6);
    IF at_station THEN
      g_transporter[i].current_station := g_transporter[i].lift_station;

      (* ── Wait for treatment time before lifting ──────────────
         If the unit at the lift station is IN_PROCESS and its
         treatment cal_time has not yet elapsed, stay at station
         and do NOT begin the lift sequence. *)
      can_lift := TRUE;
      lift_uid := g_station_loc[g_transporter[i].lift_station].UnitId;
      IF lift_uid >= 1 AND lift_uid <= MAX_Units THEN
        IF g_batch[lift_uid].state = IN_PROCESS
           AND g_batch[lift_uid].cur_stage >= 1
           AND g_batch[lift_uid].cur_stage <= MAX_STEPS_PER_PROGRAM THEN
          treat_cal := g_program[lift_uid].Steps[g_batch[lift_uid].cur_stage - 1].CalTime;
          IF treat_cal > 0 THEN
            treat_elapsed := g_time_s - g_station_loc[g_transporter[i].lift_station].ChangeTime;
            IF treat_elapsed < DINT_TO_LINT(treat_cal) THEN
              can_lift := FALSE;
            END_IF;
          END_IF;
        END_IF;
      END_IF;

      IF can_lift THEN
      lookup(station_number := g_transporter[i].lift_station);
      device_delay := lookup.device_delay_s;
      drop_time    := lookup.dropping_time_s;
      g_transporter[i].z_timer_s := device_delay + drop_time;
      g_transporter[i].z_stage := 1;
      g_transporter[i].phase := 2;

      (* ── Emit LIFT event (msg_type=2) ── *)
      evt_unit := g_station_loc[g_transporter[i].lift_station].UnitId;
      IF NOT g_event_pending_valid AND evt_unit >= 1 THEN
        g_event_pending.msg_type := 2;
        g_event_pending.ts_hi := LINT_TO_INT(g_time_s / LINT#65536);
        g_event_pending.ts_lo := LINT_TO_INT(g_time_s MOD LINT#65536);
        g_event_pending.f[1]  := i;
        g_event_pending.f[2]  := evt_unit;
        g_event_pending.f[3]  := g_transporter[i].lift_station;
        g_event_pending.f[4]  := g_batch[evt_unit].batch_code;
        g_event_pending.f[5]  := g_batch[evt_unit].state;
        g_event_pending.f[6]  := g_batch[evt_unit].prog_id;
        g_event_pending.f[7]  := g_batch[evt_unit].cur_stage;
        evt_diff := g_time_s - g_station_loc[g_transporter[i].lift_station].ChangeTime;
        IF evt_diff > LINT#32000 THEN
          g_event_pending.f[8] := 32000;
        ELSE
          g_event_pending.f[8] := LINT_TO_INT(evt_diff);
        END_IF;
        g_event_pending.f[9]  := DINT_TO_INT(g_transporter[i].treatment_time);
        g_event_pending.f[10] := DINT_TO_INT(g_transporter[i].min_time);
        g_event_pending.f[11] := DINT_TO_INT(g_transporter[i].max_time);
        g_event_pending.f[12] := 0;
        g_event_pending_valid := TRUE;
      END_IF;

      (* Unit moves from lift station → transporter *)
      pick_unit_id := g_station_loc[g_transporter[i].lift_station].UnitId;
      IF pick_unit_id >= 1 THEN
        IF i = 1 THEN
          upd_loc1(i_unit := pick_unit_id, i_location := i);
        ELSIF i = 2 THEN
          upd_loc2(i_unit := pick_unit_id, i_location := i);
        ELSIF i = 3 THEN
          upd_loc3(i_unit := pick_unit_id, i_location := i);
        END_IF;
      END_IF;
      END_IF;  (* can_lift *)
    END_IF;
    (* If arrived_x but not at_station → at drive limit, wait for clearance *)

  (* ── Phase 2: Lift Z at lift station ────────────────────── *)
  ELSIF g_transporter[i].phase = 2 THEN
    lookup(station_number := g_transporter[i].lift_station);
    station_kind := lookup.skind;
    tmp_z  := g_transporter[i].ZPosition;
    tmp_zs := g_transporter[i].z_stage;
    tmp_zt := g_transporter[i].z_timer_s;
    IF i = 1 THEN
      fb_z1(
        delta_t       := 0.02,
        station_kind  := station_kind,
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
        station_kind  := station_kind,
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
        station_kind  := station_kind,
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
    g_transporter[i].ZPosition      := tmp_z;
    g_transporter[i].z_stage   := tmp_zs;
    g_transporter[i].z_timer_s := tmp_zt;
    IF arrived_z THEN
      lookup(station_number := g_transporter[i].sink_station);
      g_transporter[i].XFinalTarget := lookup.x_mm;
      g_transporter[i].phase := 3;
    END_IF;

  (* ── Phase 3: Drive X towards sink station ─────────────── *)
  ELSIF g_transporter[i].phase = 3 THEN
    tmp_x  := g_transporter[i].XPosition;
    tmp_vx := g_transporter[i].XVelocity;
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
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
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
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
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_transporter[i].XPosition  := tmp_x;
    g_transporter[i].XVelocity := tmp_vx;

    (* Only transition when actually at station, not just at drive limit *)
    at_station := arrived_x
                  AND (ABS(g_transporter[i].XPosition - g_transporter[i].XFinalTarget) <= 6);
    IF at_station THEN
      g_transporter[i].current_station := g_transporter[i].sink_station;
      lookup(station_number := g_transporter[i].sink_station);
      device_delay := lookup.device_delay_s;
      g_transporter[i].z_timer_s := device_delay + INT_TO_REAL(g_cfg[i].phys2d.drip_delay_s) / 10.0;
      g_transporter[i].z_stage := 6;
      g_transporter[i].phase := 4;
    END_IF;
    (* If arrived_x but not at_station → at drive limit, wait for clearance *)

  (* ── Phase 4: Sink Z at sink station ───────────────────── *)
  ELSIF g_transporter[i].phase = 4 THEN
    lookup(station_number := g_transporter[i].sink_station);
    station_kind := lookup.skind;
    tmp_z  := g_transporter[i].ZPosition;
    tmp_zs := g_transporter[i].z_stage;
    tmp_zt := g_transporter[i].z_timer_s;
    IF i = 1 THEN
      fb_z1(
        delta_t       := 0.02,
        station_kind  := station_kind,
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
        station_kind  := station_kind,
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
        station_kind  := station_kind,
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
    g_transporter[i].ZPosition      := tmp_z;
    g_transporter[i].z_stage   := tmp_zs;
    g_transporter[i].z_timer_s := tmp_zt;
    IF arrived_z THEN
      (* Unit moves from transporter → sink station *)
      sink_unit_id := g_transporter[i].UnitId;
      IF sink_unit_id >= 1 THEN
        IF i = 1 THEN
          upd_loc1(i_unit := sink_unit_id, i_location := g_transporter[i].sink_station);
        ELSIF i = 2 THEN
          upd_loc2(i_unit := sink_unit_id, i_location := g_transporter[i].sink_station);
        ELSIF i = 3 THEN
          upd_loc3(i_unit := sink_unit_id, i_location := g_transporter[i].sink_station);
        END_IF;
      END_IF;

      g_transporter[i].phase := 0;
      g_transporter[i].status := 3;  (* auto_idle *)

    END_IF;
  END_IF;  (* ELSIF chain: phases 0→1→2→3→4 *)

  (* ── Phase 0 idle: drive back inside limits if outside ────── *)
  IF g_transporter[i].phase = 0 THEN
    tmp_x  := g_transporter[i].XPosition;
    tmp_vx := g_transporter[i].XVelocity;
    (* Use current position as target — XMotion will clamp to nearest limit if outside *)
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := tmp_x,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
    ELSIF i = 2 THEN
      fb_x2(
        delta_t  := 0.02,
        x_target := tmp_x,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
    ELSIF i = 3 THEN
      fb_x3(
        delta_t  := 0.02,
        x_target := tmp_x,
        x_min    := g_transporter[i].XMinLimit,
        x_max    := g_transporter[i].XMaxLimit,
        v_max    := g_cfg[i].phys2d.x_max_mm_s,
        t_acc    := g_cfg[i].phys2d.x_accel_s,
        t_dec    := g_cfg[i].phys2d.x_decel_s,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
    END_IF;
    g_transporter[i].XPosition  := tmp_x;
    g_transporter[i].XVelocity := tmp_vx;
  END_IF;

  (* ── Nearest station tracking ──────────────────────────── *)
  min_dist := 999999999;
  nearest_num := g_transporter[i].current_station;
  FOR idx := MIN_StationIndex TO MAX_StationIndex DO
    IF g_station[idx].TankId <> 0 THEN
      dx := g_station[idx].XPosition - g_transporter[i].XPosition;
      IF ABS(dx) < min_dist THEN
        min_dist := ABS(dx);
        nearest_num := idx;
      END_IF;
    END_IF;
  END_FOR;
  g_transporter[i].current_station := nearest_num;

  (* ── Measure move times (one instance per transporter) ──── *)
  IF i = 1 THEN
    tm1(t_id := 1, phase := g_transporter[1].phase, delta_t := 0.02,
        vel_x := g_transporter[1].XVelocity, z_stage := g_transporter[1].z_stage,
        lift_stn := g_transporter[1].lift_station,
        sink_stn := g_transporter[1].sink_station,
        from_stn := g_transporter[1].current_station);
  ELSIF i = 2 THEN
    tm2(t_id := 2, phase := g_transporter[2].phase, delta_t := 0.02,
        vel_x := g_transporter[2].XVelocity, z_stage := g_transporter[2].z_stage,
        lift_stn := g_transporter[2].lift_station,
        sink_stn := g_transporter[2].sink_station,
        from_stn := g_transporter[2].current_station);
  ELSIF i = 3 THEN
    tm3(t_id := 3, phase := g_transporter[3].phase, delta_t := 0.02,
        vel_x := g_transporter[3].XVelocity, z_stage := g_transporter[3].z_stage,
        lift_stn := g_transporter[3].lift_station,
        sink_stn := g_transporter[3].sink_station,
        from_stn := g_transporter[3].current_station);
  END_IF;

  END_IF;  (* active *)
END_FOR;

END_FUNCTION_BLOCK
