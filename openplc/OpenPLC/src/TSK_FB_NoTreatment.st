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
     - Unit has target <> TO_NONE and <> TO_PROCESS
     - Unit is on a station (location >= 100)
     - Covering transporter is idle (phase = 0, active)
     - A free destination station exists in g_ntt
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_NoTreatment
VAR_INPUT
  i_time_s : LINT;   (* current absolute time (s), unix seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    MAX_PARALLELS       : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
    MAX_UNITS           : INT;
END_VAR

VAR_EXTERNAL
  g_unit        : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_batch       : ARRAY[1..MAX_UNITS] OF BATCH_T;
  g_ntt         : ARRAY[1..MAX_TRANSPORTERS] OF NTT_TRANSPORTER_T;
  g_transporter : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_cfg         : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_task        : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
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
  (* Clearing check — station being vacated by another transporter *)
  ti           : INT;     (* inner transporter loop *)
  clearing     : BOOL;    (* another transporter is clearing the station *)
  sink_in_area : BOOL;    (* sink station inside our task_area *)
  ai2          : INT;     (* inner task_area loop *)
  (* Duplicate check *)
  already      : BOOL;    (* unit already queued or being transported *)
  qi2          : INT;     (* queue scan index *)
  (* Timing *)
  xfer_s   : REAL;    (* total transfer time *)
  task_start : LINT;
  task_end   : LINT;
  (* Shared FB instance *)
  fb_xfer  : STC_FB_CalcTransferTime;
END_VAR

FOR ui := 1 TO MAX_UNITS DO
  tgt := g_unit[ui].target;
  loc := g_unit[ui].location;

  (* Skip: no target, target is process (handled by schedule), not on station *)
  IF tgt >= 1 AND tgt <= 5 AND tgt <> 3 AND loc >= 100 THEN

    (* Skip if unit already has a pending task in any queue or is being transported *)
    already := FALSE;
    FOR ti := 1 TO MAX_TRANSPORTERS DO
      IF NOT already THEN
        (* Being transported right now? *)
        IF g_transporter[ti].phase > 0 AND g_transporter[ti].unit_id = ui THEN
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
    FOR cov_t := 1 TO MAX_TRANSPORTERS DO
      IF NOT done THEN

      (* Check coverage: transporter task_area covers this station *)
      covers := FALSE;
      FOR ai := 1 TO 4 DO
        IF NOT covers THEN
          IF g_cfg[cov_t].task_area[ai].min_lift > 0 OR g_cfg[cov_t].task_area[ai].max_lift > 0 THEN
            IF loc >= g_cfg[cov_t].task_area[ai].min_lift AND loc <= g_cfg[cov_t].task_area[ai].max_lift THEN
              covers := TRUE;
            END_IF;
          END_IF;
        END_IF;
      END_FOR;

      IF covers AND g_transporter[cov_t].phase = 0 AND g_transporter[cov_t].active THEN

        (* ── Resolve NTT index ── *)
        (* TO_BUFFER(2) maps to 6/7/8 depending on batch state *)
        IF tgt = 2 THEN
          IF g_batch[ui].batch_code = 0 THEN
            ntt_idx := 6;  (* empty buffer — no batch *)
          ELSIF g_batch[ui].state = 2 THEN
            ntt_idx := 8;  (* processed buffer — batch PROCESSED *)
          ELSE
            ntt_idx := 7;  (* loaded buffer — batch NOT_PROCESSED or IN_PROCESS *)
          END_IF;
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
            IF stn <> loc AND stn >= STATION_ARRAY_START AND stn <= STATION_ARRAY_END THEN
              stn_free := TRUE;
              FOR uj := 1 TO MAX_UNITS DO
                IF g_unit[uj].location = stn AND g_unit[uj].status = 1 THEN
                  (* Check if another transporter is clearing this station away from us *)
                  clearing := FALSE;
                  FOR ti := 1 TO MAX_TRANSPORTERS DO
                    IF ti <> cov_t AND g_transporter[ti].phase > 0
                       AND g_transporter[ti].lift_station = stn THEN
                      sink_in_area := FALSE;
                      FOR ai2 := 1 TO 4 DO
                        IF g_cfg[cov_t].task_area[ai2].min_lift > 0
                           OR g_cfg[cov_t].task_area[ai2].max_lift > 0 THEN
                          IF g_transporter[ti].sink_station >= g_cfg[cov_t].task_area[ai2].min_lift
                             AND g_transporter[ti].sink_station <= g_cfg[cov_t].task_area[ai2].max_lift THEN
                            sink_in_area := TRUE;
                          END_IF;
                        END_IF;
                      END_FOR;
                      IF NOT sink_in_area THEN
                        clearing := TRUE;
                      END_IF;
                    END_IF;
                  END_FOR;
                  IF NOT clearing THEN
                    stn_free := FALSE;
                  END_IF;
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
                IF stn <> loc AND stn >= STATION_ARRAY_START AND stn <= STATION_ARRAY_END THEN
                  stn_free := TRUE;
                  FOR uj := 1 TO MAX_UNITS DO
                    IF g_unit[uj].location = stn AND g_unit[uj].status = 1 THEN
                      clearing := FALSE;
                      FOR ti := 1 TO MAX_TRANSPORTERS DO
                        IF ti <> cov_t AND g_transporter[ti].phase > 0
                           AND g_transporter[ti].lift_station = stn THEN
                          sink_in_area := FALSE;
                          FOR ai2 := 1 TO 4 DO
                            IF g_cfg[cov_t].task_area[ai2].min_lift > 0
                               OR g_cfg[cov_t].task_area[ai2].max_lift > 0 THEN
                              IF g_transporter[ti].sink_station >= g_cfg[cov_t].task_area[ai2].min_lift
                                 AND g_transporter[ti].sink_station <= g_cfg[cov_t].task_area[ai2].max_lift THEN
                                sink_in_area := TRUE;
                              END_IF;
                            END_IF;
                          END_FOR;
                          IF NOT sink_in_area THEN
                            clearing := TRUE;
                          END_IF;
                        END_IF;
                      END_FOR;
                      IF NOT clearing THEN
                        stn_free := FALSE;
                      END_IF;
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
                IF stn <> loc AND stn >= STATION_ARRAY_START AND stn <= STATION_ARRAY_END THEN
                  stn_free := TRUE;
                  FOR uj := 1 TO MAX_UNITS DO
                    IF g_unit[uj].location = stn AND g_unit[uj].status = 1 THEN
                      clearing := FALSE;
                      FOR ti := 1 TO MAX_TRANSPORTERS DO
                        IF ti <> cov_t AND g_transporter[ti].phase > 0
                           AND g_transporter[ti].lift_station = stn THEN
                          sink_in_area := FALSE;
                          FOR ai2 := 1 TO 4 DO
                            IF g_cfg[cov_t].task_area[ai2].min_lift > 0
                               OR g_cfg[cov_t].task_area[ai2].max_lift > 0 THEN
                              IF g_transporter[ti].sink_station >= g_cfg[cov_t].task_area[ai2].min_lift
                                 AND g_transporter[ti].sink_station <= g_cfg[cov_t].task_area[ai2].max_lift THEN
                                sink_in_area := TRUE;
                              END_IF;
                            END_IF;
                          END_FOR;
                          IF NOT sink_in_area THEN
                            clearing := TRUE;
                          END_IF;
                        END_IF;
                      END_FOR;
                      IF NOT clearing THEN
                        stn_free := FALSE;
                      END_IF;
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
                  IF stn <> loc AND stn >= STATION_ARRAY_START AND stn <= STATION_ARRAY_END THEN
                    stn_free := TRUE;
                    FOR uj := 1 TO MAX_UNITS DO
                      IF g_unit[uj].location = stn AND g_unit[uj].status = 1 THEN
                        clearing := FALSE;
                        FOR ti := 1 TO MAX_TRANSPORTERS DO
                          IF ti <> cov_t AND g_transporter[ti].phase > 0
                             AND g_transporter[ti].lift_station = stn THEN
                            sink_in_area := FALSE;
                            FOR ai2 := 1 TO 4 DO
                              IF g_cfg[cov_t].task_area[ai2].min_lift > 0
                                 OR g_cfg[cov_t].task_area[ai2].max_lift > 0 THEN
                                IF g_transporter[ti].sink_station >= g_cfg[cov_t].task_area[ai2].min_lift
                                   AND g_transporter[ti].sink_station <= g_cfg[cov_t].task_area[ai2].max_lift THEN
                                  sink_in_area := TRUE;
                                END_IF;
                              END_IF;
                            END_FOR;
                            IF NOT sink_in_area THEN
                              clearing := TRUE;
                            END_IF;
                          END_IF;
                        END_FOR;
                        IF NOT clearing THEN
                          stn_free := FALSE;
                        END_IF;
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
            fb_xfer(i_from_stn := loc, i_to_stn := dest_stn, i_trans := cov_t);
            xfer_s := fb_xfer.o_total_s;

            task_start := i_time_s;
            task_end   := task_start + REAL_TO_LINT(xfer_s);

            (* Append to queue *)
            qi := g_task[cov_t].count + 1;
            IF qi <= MAX_UNITS THEN
              g_task[cov_t].queue[qi].unit         := ui;
              g_task[cov_t].queue[qi].stage        := 0;  (* no program stage *)
              g_task[cov_t].queue[qi].lift_station := loc;
              g_task[cov_t].queue[qi].sink_station := dest_stn;
              g_task[cov_t].queue[qi].start_time   := task_start;
              g_task[cov_t].queue[qi].finish_time  := task_end;
              g_task[cov_t].queue[qi].calc_time    := 0.0;
              g_task[cov_t].queue[qi].min_time     := 0.0;
              g_task[cov_t].queue[qi].max_time     := 0.0;
              g_task[cov_t].count := qi;
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
