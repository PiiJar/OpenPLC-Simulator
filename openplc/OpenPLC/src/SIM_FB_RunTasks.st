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
  g_transporter  : ARRAY[1..MAX_Transporters] OF UDT_TransporterStatusType;
  g_sim_trans    : ARRAY[1..MAX_Transporters] OF UDT_JC_SimTransporterType;
  g_station     : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_StationType;    g_station_loc  : ARRAY[1..MAX_StationIndex] OF UDT_UnitLocation;  g_cfg          : ARRAY[1..MAX_Transporters] OF UDT_TransporterType;
  g_move         : ARRAY[1..MAX_Transporters] OF UDT_JC_MoveTimesType;
  g_unit         : ARRAY[1..MAX_Units] OF UDT_UnitType;
  g_batch        : ARRAY[1..MAX_Units] OF UDT_BatchType;
  g_program      : ARRAY[1..MAX_Units] OF UDT_TreatmentProgramType;
  g_time_s       : LINT;
  g_event_pending       : UDT_JC_EventMsgType;
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
  IF g_transporter[i].IsActive THEN

  (* ── Phase 0 → 1: Accept new task ───────────────────────── *)
  IF (g_transporter[i].Phase = 0)
     AND (g_transporter[i].TaskId <> g_sim_trans[i].RunningTaskId) THEN
    g_sim_trans[i].RunningTaskId := g_transporter[i].TaskId;
    lookup(station_number := g_transporter[i].LiftStationTarget);
    g_transporter[i].XFinalTarget := lookup.x_mm;
    g_transporter[i].Phase := 1;
    g_transporter[i].Status := 4;  (* auto_run *)
    g_sim_trans[i].ZStage := 0;
    g_sim_trans[i].ZTimer := 0.0;

  (* ── Phase 1: Drive X towards lift station ──────────────── *)
  ELSIF g_transporter[i].Phase = 1 THEN
    tmp_x  := g_transporter[i].XPosition;
    tmp_vx := g_sim_trans[i].XVelocity;
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x1.arrived;
    ELSIF i = 2 THEN
      fb_x2(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x2.arrived;
    ELSIF i = 3 THEN
      fb_x3(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_transporter[i].XPosition  := tmp_x;
    g_sim_trans[i].XVelocity := tmp_vx;

    (* Only transition when actually at station, not just at drive limit *)
    at_station := arrived_x
                  AND (ABS(g_transporter[i].XPosition - g_transporter[i].XFinalTarget) <= 6);
    IF at_station THEN
      g_transporter[i].CurrentStation := g_transporter[i].LiftStationTarget;

      (* ── Wait for treatment time before lifting ──────────────
         If the unit at the lift station is IN_PROCESS and its
         treatment cal_time has not yet elapsed, stay at station
         and do NOT begin the lift sequence. *)
      can_lift := TRUE;
      lift_uid := g_station_loc[g_transporter[i].LiftStationTarget].UnitId;
      IF lift_uid >= 1 AND lift_uid <= MAX_Units THEN
        IF g_batch[lift_uid].State = IN_PROCESS
           AND g_batch[lift_uid].CurStage >= 1
           AND g_batch[lift_uid].CurStage <= MAX_STEPS_PER_PROGRAM THEN
          treat_cal := g_program[lift_uid].Steps[g_batch[lift_uid].CurStage - 1].CalTime;
          IF treat_cal > 0 THEN
            treat_elapsed := g_time_s - g_station_loc[g_transporter[i].LiftStationTarget].ChangeTime;
            IF treat_elapsed < DINT_TO_LINT(treat_cal) THEN
              can_lift := FALSE;
            END_IF;
          END_IF;
        END_IF;
      END_IF;

      IF can_lift THEN
      lookup(station_number := g_transporter[i].LiftStationTarget);
      device_delay := lookup.device_delay_s;
      drop_time    := lookup.dropping_time_s;
      g_sim_trans[i].ZTimer := device_delay + drop_time;
      g_sim_trans[i].ZStage := 1;
      g_transporter[i].Phase := 2;

      (* ── Emit LIFT event (msg_type=2) ── *)
      evt_unit := g_station_loc[g_transporter[i].LiftStationTarget].UnitId;
      IF NOT g_event_pending_valid AND evt_unit >= 1 THEN
        g_event_pending.MsgType := 2;
        g_event_pending.TsHi := LINT_TO_INT(g_time_s / LINT#65536);
        g_event_pending.TsLo := LINT_TO_INT(g_time_s MOD LINT#65536);
        g_event_pending.Payload[1]  := i;
        g_event_pending.Payload[2]  := evt_unit;
        g_event_pending.Payload[3]  := g_transporter[i].LiftStationTarget;
        g_event_pending.Payload[4]  := g_batch[evt_unit].BatchCode;
        g_event_pending.Payload[5]  := g_batch[evt_unit].State;
        g_event_pending.Payload[6]  := g_batch[evt_unit].ProgId;
        g_event_pending.Payload[7]  := g_batch[evt_unit].CurStage;
        evt_diff := g_time_s - g_station_loc[g_transporter[i].LiftStationTarget].ChangeTime;
        IF evt_diff > LINT#32000 THEN
          g_event_pending.Payload[8] := 32000;
        ELSE
          g_event_pending.Payload[8] := LINT_TO_INT(evt_diff);
        END_IF;
        g_event_pending.Payload[9]  := DINT_TO_INT(g_sim_trans[i].TreatmentTime);
        g_event_pending.Payload[10] := DINT_TO_INT(g_sim_trans[i].MinTime);
        g_event_pending.Payload[11] := DINT_TO_INT(g_sim_trans[i].MaxTime);
        g_event_pending.Payload[12] := 0;
        g_event_pending_valid := TRUE;
      END_IF;

      (* Unit moves from lift station → transporter *)
      pick_unit_id := g_station_loc[g_transporter[i].LiftStationTarget].UnitId;
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
  ELSIF g_transporter[i].Phase = 2 THEN
    lookup(station_number := g_transporter[i].LiftStationTarget);
    station_kind := lookup.skind;
    tmp_z  := g_transporter[i].ZPosition;
    tmp_zs := g_sim_trans[i].ZStage;
    tmp_zt := g_sim_trans[i].ZTimer;
    IF i = 1 THEN
      fb_z1(
        delta_t       := 0.02,
        station_kind  := station_kind,
        ZPosDown        := g_cfg[i].ZPosDown,
        ZPosUp          := 0,
        ZPosSlowUp      := g_cfg[i].ZPosSlowUp,
        ZPosSlowDown    := g_cfg[i].ZPosSlowDown,
        ZPosSlowEnd     := g_cfg[i].ZPosSlowEnd,
        SpeedLiftSlow_Z := g_cfg[i].SpeedLiftSlow_Z,
        SpeedLiftFast_Z := g_cfg[i].SpeedLiftFast_Z,
        DripTrayDelay   := g_cfg[i].DripTrayDelay,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z1.done;
    ELSIF i = 2 THEN
      fb_z2(
        delta_t       := 0.02,
        station_kind  := station_kind,
        ZPosDown        := g_cfg[i].ZPosDown,
        ZPosUp          := 0,
        ZPosSlowUp      := g_cfg[i].ZPosSlowUp,
        ZPosSlowDown    := g_cfg[i].ZPosSlowDown,
        ZPosSlowEnd     := g_cfg[i].ZPosSlowEnd,
        SpeedLiftSlow_Z := g_cfg[i].SpeedLiftSlow_Z,
        SpeedLiftFast_Z := g_cfg[i].SpeedLiftFast_Z,
        DripTrayDelay   := g_cfg[i].DripTrayDelay,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z2.done;
    ELSIF i = 3 THEN
      fb_z3(
        delta_t       := 0.02,
        station_kind  := station_kind,
        ZPosDown        := g_cfg[i].ZPosDown,
        ZPosUp          := 0,
        ZPosSlowUp      := g_cfg[i].ZPosSlowUp,
        ZPosSlowDown    := g_cfg[i].ZPosSlowDown,
        ZPosSlowEnd     := g_cfg[i].ZPosSlowEnd,
        SpeedLiftSlow_Z := g_cfg[i].SpeedLiftSlow_Z,
        SpeedLiftFast_Z := g_cfg[i].SpeedLiftFast_Z,
        DripTrayDelay   := g_cfg[i].DripTrayDelay,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z3.done;
    END_IF;
    g_transporter[i].ZPosition      := tmp_z;
    g_sim_trans[i].ZStage   := tmp_zs;
    g_sim_trans[i].ZTimer := tmp_zt;
    IF arrived_z THEN
      lookup(station_number := g_transporter[i].SinkStationTarget);
      g_transporter[i].XFinalTarget := lookup.x_mm;
      g_transporter[i].Phase := 3;
    END_IF;

  (* ── Phase 3: Drive X towards sink station ─────────────── *)
  ELSIF g_transporter[i].Phase = 3 THEN
    tmp_x  := g_transporter[i].XPosition;
    tmp_vx := g_sim_trans[i].XVelocity;
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x1.arrived;
    ELSIF i = 2 THEN
      fb_x2(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x2.arrived;
    ELSIF i = 3 THEN
      fb_x3(
        delta_t  := 0.02,
        x_target := g_transporter[i].XFinalTarget,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
      arrived_x := fb_x3.arrived;
    END_IF;
    g_transporter[i].XPosition  := tmp_x;
    g_sim_trans[i].XVelocity := tmp_vx;

    (* Only transition when actually at station, not just at drive limit *)
    at_station := arrived_x
                  AND (ABS(g_transporter[i].XPosition - g_transporter[i].XFinalTarget) <= 6);
    IF at_station THEN
      g_transporter[i].CurrentStation := g_transporter[i].SinkStationTarget;
      lookup(station_number := g_transporter[i].SinkStationTarget);
      device_delay := lookup.device_delay_s;
      g_sim_trans[i].ZTimer := device_delay + INT_TO_REAL(g_cfg[i].DripTrayDelay) / 10.0;
      g_sim_trans[i].ZStage := 6;
      g_transporter[i].Phase := 4;
    END_IF;
    (* If arrived_x but not at_station → at drive limit, wait for clearance *)

  (* ── Phase 4: Sink Z at sink station ───────────────────── *)
  ELSIF g_transporter[i].Phase = 4 THEN
    lookup(station_number := g_transporter[i].SinkStationTarget);
    station_kind := lookup.skind;
    tmp_z  := g_transporter[i].ZPosition;
    tmp_zs := g_sim_trans[i].ZStage;
    tmp_zt := g_sim_trans[i].ZTimer;
    IF i = 1 THEN
      fb_z1(
        delta_t       := 0.02,
        station_kind  := station_kind,
        ZPosDown        := g_cfg[i].ZPosDown,
        ZPosUp          := 0,
        ZPosSlowUp      := g_cfg[i].ZPosSlowUp,
        ZPosSlowDown    := g_cfg[i].ZPosSlowDown,
        ZPosSlowEnd     := g_cfg[i].ZPosSlowEnd,
        SpeedLiftSlow_Z := g_cfg[i].SpeedLiftSlow_Z,
        SpeedLiftFast_Z := g_cfg[i].SpeedLiftFast_Z,
        DripTrayDelay   := g_cfg[i].DripTrayDelay,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z1.done;
    ELSIF i = 2 THEN
      fb_z2(
        delta_t       := 0.02,
        station_kind  := station_kind,
        ZPosDown        := g_cfg[i].ZPosDown,
        ZPosUp          := 0,
        ZPosSlowUp      := g_cfg[i].ZPosSlowUp,
        ZPosSlowDown    := g_cfg[i].ZPosSlowDown,
        ZPosSlowEnd     := g_cfg[i].ZPosSlowEnd,
        SpeedLiftSlow_Z := g_cfg[i].SpeedLiftSlow_Z,
        SpeedLiftFast_Z := g_cfg[i].SpeedLiftFast_Z,
        DripTrayDelay   := g_cfg[i].DripTrayDelay,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z2.done;
    ELSIF i = 3 THEN
      fb_z3(
        delta_t       := 0.02,
        station_kind  := station_kind,
        ZPosDown        := g_cfg[i].ZPosDown,
        ZPosUp          := 0,
        ZPosSlowUp      := g_cfg[i].ZPosSlowUp,
        ZPosSlowDown    := g_cfg[i].ZPosSlowDown,
        ZPosSlowEnd     := g_cfg[i].ZPosSlowEnd,
        SpeedLiftSlow_Z := g_cfg[i].SpeedLiftSlow_Z,
        SpeedLiftFast_Z := g_cfg[i].SpeedLiftFast_Z,
        DripTrayDelay   := g_cfg[i].DripTrayDelay,
        z_mm          := tmp_z,
        z_stage       := tmp_zs,
        z_timer_s     := tmp_zt
      );
      arrived_z := fb_z3.done;
    END_IF;
    g_transporter[i].ZPosition      := tmp_z;
    g_sim_trans[i].ZStage   := tmp_zs;
    g_sim_trans[i].ZTimer := tmp_zt;
    IF arrived_z THEN
      (* Unit moves from transporter → sink station *)
      sink_unit_id := g_station_loc[i].UnitId;
      IF sink_unit_id >= 1 THEN
        IF i = 1 THEN
          upd_loc1(i_unit := sink_unit_id, i_location := g_transporter[i].SinkStationTarget);
        ELSIF i = 2 THEN
          upd_loc2(i_unit := sink_unit_id, i_location := g_transporter[i].SinkStationTarget);
        ELSIF i = 3 THEN
          upd_loc3(i_unit := sink_unit_id, i_location := g_transporter[i].SinkStationTarget);
        END_IF;
      END_IF;

      g_transporter[i].Phase := 0;
      g_transporter[i].Status := 3;  (* auto_idle *)

    END_IF;
  END_IF;  (* ELSIF chain: phases 0→1→2→3→4 *)

  (* ── Phase 0 idle: drive back inside limits if outside ────── *)
  IF g_transporter[i].Phase = 0 THEN
    tmp_x  := g_transporter[i].XPosition;
    tmp_vx := g_sim_trans[i].XVelocity;
    (* Use current position as target — XMotion will clamp to nearest limit if outside *)
    IF i = 1 THEN
      fb_x1(
        delta_t  := 0.02,
        x_target := tmp_x,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
    ELSIF i = 2 THEN
      fb_x2(
        delta_t  := 0.02,
        x_target := tmp_x,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
    ELSIF i = 3 THEN
      fb_x3(
        delta_t  := 0.02,
        x_target := tmp_x,
        x_min    := g_transporter[i].XMinDriveLimit,
        x_max    := g_transporter[i].XMaxDriveLimit,
        v_max    := g_cfg[i].SpeedMax_X,
        t_acc    := g_cfg[i].Acceleration_X,
        t_dec    := g_cfg[i].Deceleration_X,
        x_pos    := tmp_x,
        v_x      := tmp_vx
      );
    END_IF;
    g_transporter[i].XPosition  := tmp_x;
    g_sim_trans[i].XVelocity := tmp_vx;
  END_IF;

  (* ── Nearest station tracking ──────────────────────────── *)
  min_dist := 999999999;
  nearest_num := g_transporter[i].CurrentStation;
  FOR idx := MIN_StationIndex TO MAX_StationIndex DO
    IF g_station[idx].TankId <> 0 THEN
      dx := g_station[idx].XPosition - g_transporter[i].XPosition;
      IF ABS(dx) < min_dist THEN
        min_dist := ABS(dx);
        nearest_num := idx;
      END_IF;
    END_IF;
  END_FOR;
  g_transporter[i].CurrentStation := nearest_num;

  (* ── Measure move times (one instance per transporter) ──── *)
  IF i = 1 THEN
    tm1(t_id := 1, phase := g_transporter[1].Phase, delta_t := 0.02,
        vel_x := g_sim_trans[1].XVelocity, z_stage := g_sim_trans[1].ZStage,
        lift_stn := g_transporter[1].LiftStationTarget,
        sink_stn := g_transporter[1].SinkStationTarget,
        from_stn := g_transporter[1].CurrentStation);
  ELSIF i = 2 THEN
    tm2(t_id := 2, phase := g_transporter[2].Phase, delta_t := 0.02,
        vel_x := g_sim_trans[2].XVelocity, z_stage := g_sim_trans[2].ZStage,
        lift_stn := g_transporter[2].LiftStationTarget,
        sink_stn := g_transporter[2].SinkStationTarget,
        from_stn := g_transporter[2].CurrentStation);
  ELSIF i = 3 THEN
    tm3(t_id := 3, phase := g_transporter[3].Phase, delta_t := 0.02,
        vel_x := g_sim_trans[3].XVelocity, z_stage := g_sim_trans[3].ZStage,
        lift_stn := g_transporter[3].LiftStationTarget,
        sink_stn := g_transporter[3].SinkStationTarget,
        from_stn := g_transporter[3].CurrentStation);
  END_IF;

  END_IF;  (* active *)
END_FOR;

END_FUNCTION_BLOCK
