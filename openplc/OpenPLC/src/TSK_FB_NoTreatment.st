(* ============================================================
   TSK_FB_NoTreatment — Create no-treatment transfer tasks
   ============================================================
   Scans units that have a target (TO_LOADING, TO_UNLOAD,
   TO_BUFFER, TO_AVOID, etc.) and creates transfer tasks using
   the g_ntt destination table (per target, per transporter).

   Destination lookup:
     1. Search primary stations (g_ntt[trans].target[tgt].stations)
     2. If all occupied → search fallback stations
     3. First free station wins

   Conditions for creating a task:
     - Unit has target <> TO_NONE
     - TO_PROCESS handled only when batch state = NOT_PROCESSED
       (routes to loaded-buffer via NTT index 7)
     - Unit is on a station (location >= 100)
     - Covering transporter is idle (phase = 0, active)
     - A free destination station exists in g_ntt
     - Destination station MUST be actually free (no unit present)
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_NoTreatment
VAR_INPUT
  i_time_s : LINT;   (* current absolute time (s), unix seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_Transporters    : INT;
    MAX_STATIONS_PER_STEP       : INT;
    MIN_StationIndex : INT;
    MAX_StationIndex   : INT;
    MAX_Units           : INT;
    MAX_TASK_QUEUE      : INT;
END_VAR

VAR_EXTERNAL
  g_unit        : ARRAY[1..MAX_Units] OF UDT_UnitType;
  g_batch       : ARRAY[1..MAX_Units] OF UDT_BatchType;
  g_ntt         : ARRAY[1..MAX_Transporters] OF NTT_TRANSPORTER_T;
  g_transporter : ARRAY[1..MAX_Transporters] OF UDT_TransporterStatusType;
  g_station_loc : ARRAY[1..MAX_StationIndex] OF UDT_UnitLocation;
  g_cfg         : ARRAY[1..MAX_Transporters] OF TRANSPORTER_CFG_T;
  g_task        : ARRAY[1..MAX_Transporters] OF TSK_QUEUE_T;
  g_move        : ARRAY[1..MAX_Transporters] OF MOVE_TIMES_T;
END_VAR
VAR
  ui       : INT;     (* unit loop *)
  qi       : INT;     (* queue index *)
  loc      : INT;     (* unit location station *)
  tgt      : INT;     (* unit target *)
  cov_t    : INT;     (* transporter loop *)
  ai       : INT;     (* task_area loop *)
  covers   : BOOL;    (* transporter covers this station *)
  done     : BOOL;    (* task created for this unit *)
  dest     : NTT_DEST_T;  (* destination descriptor for this target+transporter *)
  ntt_idx  : INT;     (* resolved NTT index (maps TO_BUFFER to 6/7/8 based on batch) *)
  (* Location classification *)
  on_primary  : BOOL;  (* unit is already on a primary station *)
  on_fallback : BOOL;  (* unit is on a fallback station *)
  primary_free : BOOL; (* at least one primary station is free *)
  (* Destination search *)
  dest_stn : INT;     (* destination station *)
  si       : INT;     (* station loop *)
  stn      : INT;     (* candidate station *)
  stn_free : BOOL;
  uj       : INT;     (* inner unit loop for free check *)
  (* Duplicate check *)
  ti       : INT;     (* inner transporter loop *)
  already  : BOOL;    (* unit already queued or being transported *)
  qi2      : INT;     (* queue scan index *)
  (* Timing *)
  xfer_s   : REAL;    (* total transfer time *)
  task_start : LINT;
  task_end   : LINT;
  (* Idle-slot overlap check *)
  has_overlap    : BOOL;
  ntt_start      : LINT;
  ntt_end        : LINT;
  ov_s           : LINT;
  ov_e           : LINT;
  margin_travel  : REAL;
  slot_start     : LINT;   (* idle slot bounds *)
  tmp_move       : MOVE_TIMES_T;  (* MATIEC cannot index arrays in FUNCTION args *)
  slot_end       : LINT;
  earliest_start : LINT;   (* earliest NTT start considering travel *)
  latest_end     : LINT;   (* latest NTT end considering travel *)
  travel_to_lift : REAL;
  travel_from_sink : REAL;
  ntt_duration   : LINT;
  qi3            : INT;   (* queue loop for idle-slot calc *)
  slot_ok        : BOOL;
  sh             : INT;   (* shift loop for insert-at-first *)
END_VAR

FOR ui := 1 TO MAX_Units DO
  tgt := g_unit[ui].target;
  loc := g_unit[ui].location;

  (* Skip: no target, not on station.
     TO_PROCESS(3) is only handled here when batch state = NOT_PROCESSED
     (loaded unit waiting for processing → route to loaded-buffer). *)
  IF tgt >= 1 AND tgt <= 5 AND loc >= 100 THEN

    (* TO_PROCESS with batch already IN_PROCESS or later → skip (handled by schedule) *)
    IF tgt = 3 AND (g_batch[ui].BatchCode = 0 OR g_batch[ui].State <> 0) THEN
      CONTINUE;
    END_IF;

    (* Skip if unit already has a pending task in any queue or is being transported *)
    already := FALSE;
    FOR ti := 1 TO MAX_Transporters DO
      IF NOT already THEN
        (* Being transported right now? *)
        IF g_transporter[ti].Phase > 0 AND g_station_loc[ti].UnitId = ui THEN
          already := TRUE;
        END_IF;
        (* In any task queue? *)
        FOR qi2 := 1 TO g_task[ti].count DO
          IF NOT already THEN
            IF g_task[ti].queue[qi2].unit = ui THEN
              already := TRUE;
            END_IF;
          END_IF;
        END_FOR;
      END_IF;
    END_FOR;

    IF NOT already THEN

    (* Try each transporter — not just the first covering one *)
    done := FALSE;
    FOR cov_t := 1 TO MAX_Transporters DO
      IF NOT done THEN

      (* Check coverage: transporter task_area covers this station *)
      covers := FALSE;
      FOR ai := 1 TO 4 DO
        IF NOT covers THEN
          IF g_cfg[cov_t].TaskArea[ai].MinLift > 0 OR g_cfg[cov_t].TaskArea[ai].MaxLift > 0 THEN
            IF loc >= g_cfg[cov_t].TaskArea[ai].MinLift AND loc <= g_cfg[cov_t].TaskArea[ai].MaxLift THEN
              covers := TRUE;
            END_IF;
          END_IF;
        END_IF;
      END_FOR;

      IF covers AND g_transporter[cov_t].IsActive
         AND (g_transporter[cov_t].Phase = 0 OR tgt = 5) THEN

        (* ── Resolve NTT index ── *)
        (* TO_BUFFER(2) maps to 6/7/8 depending on batch state *)
        (* TO_PROCESS(3) with NOT_PROCESSED batch → loaded buffer (7) *)
        IF tgt = 2 THEN
          IF g_batch[ui].BatchCode = 0 THEN
            ntt_idx := 6;  (* empty buffer — no batch *)
          ELSIF g_batch[ui].State = 2 THEN
            ntt_idx := 8;  (* processed buffer — batch PROCESSED *)
          ELSE
            ntt_idx := 7;  (* loaded buffer — batch NOT_PROCESSED or IN_PROCESS *)
          END_IF;
        ELSIF tgt = 3 THEN
          ntt_idx := 7;    (* TO_PROCESS + NOT_PROCESSED → loaded buffer *)
        ELSE
          ntt_idx := tgt;  (* other targets use their code directly *)
        END_IF;

        (* Get destination descriptor for this target + transporter *)
        dest := g_ntt[cov_t].target[ntt_idx];

        (* ── Classify current location ── *)
        on_primary := FALSE;
        FOR si := 1 TO dest.station_count DO
          IF dest.stations[si] = loc THEN
            on_primary := TRUE;
          END_IF;
        END_FOR;

        (* Already on a primary station → no move needed *)
        IF NOT on_primary THEN

          on_fallback := FALSE;
          FOR si := 1 TO dest.fallback_count DO
            IF dest.fallback_stations[si] = loc THEN
              on_fallback := TRUE;
            END_IF;
          END_FOR;

          (* Check if any primary station is free *)
          primary_free := FALSE;
          FOR si := 1 TO dest.station_count DO
            stn := dest.stations[si];
            IF stn <> loc AND stn >= MIN_StationIndex AND stn <= MAX_StationIndex THEN
              stn_free := TRUE;
              FOR uj := 1 TO MAX_Units DO
                IF g_unit[uj].location = stn AND g_unit[uj].Status = 1 THEN
                  stn_free := FALSE;
                END_IF;
              END_FOR;
              IF stn_free THEN
                primary_free := TRUE;
              END_IF;
            END_IF;
          END_FOR;

          dest_stn := 0;

          IF on_fallback AND NOT primary_free THEN
            (* On fallback, no primary free → stay put, don't bounce *)
            dest_stn := 0;
          ELSIF on_fallback AND primary_free THEN
            (* On fallback, primary is free → move to primary *)
            FOR si := 1 TO dest.station_count DO
              IF dest_stn = 0 THEN
                stn := dest.stations[si];
                IF stn <> loc AND stn >= MIN_StationIndex AND stn <= MAX_StationIndex THEN
                  stn_free := TRUE;
                  FOR uj := 1 TO MAX_Units DO
                    IF g_unit[uj].location = stn AND g_unit[uj].Status = 1 THEN
                      stn_free := FALSE;
                    END_IF;
                  END_FOR;
                  IF stn_free THEN
                    dest_stn := stn;
                  END_IF;
                END_IF;
              END_IF;
            END_FOR;
          ELSE
            (* Not on any known destination → full search: primary then fallback *)
            FOR si := 1 TO dest.station_count DO
              IF dest_stn = 0 THEN
                stn := dest.stations[si];
                IF stn <> loc AND stn >= MIN_StationIndex AND stn <= MAX_StationIndex THEN
                  stn_free := TRUE;
                  FOR uj := 1 TO MAX_Units DO
                    IF g_unit[uj].location = stn AND g_unit[uj].Status = 1 THEN
                      stn_free := FALSE;
                    END_IF;
                  END_FOR;
                  IF stn_free THEN
                    dest_stn := stn;
                  END_IF;
                END_IF;
              END_IF;
            END_FOR;

            IF dest_stn = 0 THEN
              FOR si := 1 TO dest.fallback_count DO
                IF dest_stn = 0 THEN
                  stn := dest.fallback_stations[si];
                  IF stn <> loc AND stn >= MIN_StationIndex AND stn <= MAX_StationIndex THEN
                    stn_free := TRUE;
                    FOR uj := 1 TO MAX_Units DO
                      IF g_unit[uj].location = stn AND g_unit[uj].Status = 1 THEN
                        stn_free := FALSE;
                      END_IF;
                    END_FOR;
                    IF stn_free THEN
                      dest_stn := stn;
                    END_IF;
                  END_IF;
                END_IF;
              END_FOR;
            END_IF;
          END_IF;

          IF dest_stn > 0 THEN
            (* Calculate timing *)
            tmp_move := g_move[cov_t];
            xfer_s := STC_CalcTransferTime(i_from_stn := loc, i_to_stn := dest_stn, i_move := tmp_move);

            task_start := i_time_s;
            task_end   := task_start + REAL_TO_LINT(xfer_s);
            ntt_duration := task_end - task_start;

            (* ── Current-slot check: NTT fits only in the CURRENT idle slot ──
               Like JS: find the slot where start <= now < end, check totalTime
               fits. NTT is never placed into future slots — only "right now". *)
            slot_ok := FALSE;

            IF g_task[cov_t].count = 0 THEN
              (* No existing tasks → NTT always fits *)
              slot_ok := TRUE;
            ELSE
              (* Current slot = time from NOW until first queued task starts.
                 NTT must fit: task_end + travel_to_next_lift <= queue[1].start_time *)
              IF g_task[cov_t].queue[1].start_time > task_start THEN
                slot_start := task_start;
                slot_end   := g_task[cov_t].queue[1].start_time;
                (* Travel from NTT sink to first task's lift *)
                travel_from_sink := STC_CalcHorizontalTravel(
                  i_from_stn := dest_stn,
                  i_to_stn   := g_task[cov_t].queue[1].LiftStationTarget,
                  i_move     := g_move[cov_t]
                );
                latest_end := slot_end - REAL_TO_LINT(travel_from_sink) - 1;
                IF task_start >= slot_start AND task_end <= latest_end THEN
                  slot_ok := TRUE;
                END_IF;
              END_IF;
            END_IF;

            IF NOT slot_ok THEN
              (* Exception: if the next queued task's sink station is where
                 this NTT unit sits, we MUST move it first or we deadlock.
                 Force-insert; future scheduling will re-stabilize the list. *)
              IF g_task[cov_t].count > 0
                 AND g_task[cov_t].queue[1].SinkStationTarget = loc THEN
                slot_ok := TRUE;  (* force — deadlock prevention *)
              ELSE
                dest_stn := 0;  (* NTT doesn't fit → skip *)
              END_IF;
            END_IF;
          END_IF;

          IF dest_stn > 0 THEN
            (* Insert as FIRST task — shift existing tasks down *)
            IF g_task[cov_t].count < MAX_TASK_QUEUE THEN
              (* Shift queue[1..count] → queue[2..count+1] *)
              FOR sh := g_task[cov_t].count TO 1 BY -1 DO
                g_task[cov_t].queue[sh + 1] := g_task[cov_t].queue[sh];
              END_FOR;
              g_task[cov_t].queue[1].unit         := ui;
              g_task[cov_t].queue[1].stage        := 0;  (* no program stage *)
              g_task[cov_t].queue[1].LiftStationTarget := loc;
              g_task[cov_t].queue[1].SinkStationTarget := dest_stn;
              g_task[cov_t].queue[1].start_time   := task_start;
              g_task[cov_t].queue[1].finish_time  := task_end;
              g_task[cov_t].queue[1].calc_time    := 0;
              g_task[cov_t].queue[1].min_time     := 0;
              g_task[cov_t].queue[1].max_time     := 0;
              g_task[cov_t].count := g_task[cov_t].count + 1;
              done := TRUE;
            END_IF;
          END_IF;

        END_IF; (* NOT on_primary *)

      END_IF; (* covers + idle *)

      END_IF; (* NOT done *)
    END_FOR; (* transporter loop *)

    END_IF; (* NOT already *)

  END_IF; (* valid target *)
END_FOR;

END_FUNCTION_BLOCK
