(* ==========================================================
   STC_FB_NoTreatmentStates
   ----------------------------------------------------------
   Manages non-treatment states for all units.
   Iterates all units. For each unit whose batch is IN_PROCESS:
     1. Reads cur_stage from g_batch[u].
     2. Checks if the NEXT stage in the treatment program is
        empty (stations[1] = 0) — meaning the unit is currently
        at its last treatment station.
     3. Compares elapsed time at the station
        (g_time_s − g_station[loc].change_time) against the
        current stage's cal_time.
     4. If elapsed >= cal_time → marks batch as PROCESSED.
   ========================================================== *)

FUNCTION_BLOCK STC_FB_NoTreatmentStates
  VAR_EXTERNAL
    g_unit       : ARRAY[1..10] OF UNIT_T;
    g_batch      : ARRAY[1..10] OF BATCH_T;
    g_program    : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
    g_station    : ARRAY[101..130] OF STATION_T;
    g_time_s     : LINT;
  END_VAR

  VAR_EXTERNAL CONSTANT
    MAX_UNITS          : INT;
    MAX_STAGES         : INT;
    MAX_PARALLELS      : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END  : INT;
    IN_PROCESS         : INT;
    PROCESSED          : INT;
    NOT_USED           : INT;
    TO_NONE            : INT;
    TO_AVOID           : INT;
  END_VAR

  VAR
    u          : INT;        (* unit loop index *)
    cur        : INT;        (* current stage number *)
    loc        : INT;        (* unit location (station number) *)
    cal        : INT;        (* cal_time for current stage (seconds) *)
    elapsed    : LINT;       (* seconds spent at current station *)
    p          : INT;        (* parallel station loop index *)
    next_stn   : INT;        (* next stage station number *)
    occ_uid    : INT;        (* unit_id at an occupied station *)
    free_found : BOOL;       (* TRUE if any next-stage station is free *)
    avoid_uid  : INT;        (* unit to mark TO_AVOID, 0 = none found *)
  END_VAR

  FOR u := 1 TO MAX_UNITS DO
    IF g_unit[u].status = NOT_USED THEN
      CONTINUE;
    END_IF;

    cur := g_batch[u].cur_stage;
    loc := g_unit[u].location;
    elapsed := g_time_s - g_station[loc].change_time;
    cal := g_program[u].stages[cur].cal_time;

    (* Mark batch PROCESSED when batch is on its last treatment stage
       and the required cal_time has elapsed at the current station. *)
    IF g_batch[u].batch_code <> 0 AND g_batch[u].state = IN_PROCESS THEN
      IF cur >= 1 AND cur < MAX_STAGES THEN
        IF g_program[u].stages[cur + 1].stations[1] = 0 THEN
          IF loc >= STATION_ARRAY_START AND loc <= STATION_ARRAY_END THEN
            IF g_station[loc].change_time > 0 THEN
              IF elapsed >= INT_TO_LINT(cal) THEN
                g_batch[u].state := PROCESSED;
              END_IF;
            END_IF;
          END_IF;
        END_IF;
      END_IF;
    END_IF;

    (* ── TO_AVOID: clear the way to the next treatment station ──────
       For an IN_PROCESS unit whose next stage exists, check whether
       ALL parallel stations of the next stage are occupied.
       If at least one is free → nothing to do.
       If ALL are occupied → find the first station whose unit has
       no batch (batch_code=0) and target=TO_NONE, then set that
       unit's target to TO_AVOID so NTT will move it out of the way. *)
    IF g_batch[u].batch_code <> 0 AND g_batch[u].state = IN_PROCESS THEN
      IF cur >= 1 AND cur < MAX_STAGES THEN
        IF g_program[u].stages[cur + 1].stations[1] <> 0 THEN

          (* — Pass 1: is any next-stage station free? — *)
          free_found := FALSE;
          avoid_uid  := 0;
          FOR p := 1 TO MAX_PARALLELS DO
            next_stn := g_program[u].stages[cur + 1].stations[p];
            IF next_stn = 0 THEN
              EXIT;  (* no more parallel stations *)
            END_IF;
            IF next_stn >= STATION_ARRAY_START AND next_stn <= STATION_ARRAY_END THEN
              IF g_station[next_stn].unit_id = 0 THEN
                free_found := TRUE;
                EXIT;
              END_IF;
            END_IF;
          END_FOR;

          (* — Pass 2: only if no free station, find a movable unit — *)
          IF NOT free_found THEN
            FOR p := 1 TO MAX_PARALLELS DO
              next_stn := g_program[u].stages[cur + 1].stations[p];
              IF next_stn = 0 THEN
                EXIT;
              END_IF;
              IF next_stn >= STATION_ARRAY_START AND next_stn <= STATION_ARRAY_END THEN
                occ_uid := g_station[next_stn].unit_id;
                IF occ_uid >= 1 AND occ_uid <= MAX_UNITS THEN
                  IF g_batch[occ_uid].batch_code = 0
                     AND g_unit[occ_uid].target = TO_NONE THEN
                    avoid_uid := occ_uid;
                    EXIT;  (* mark only the first one *)
                  END_IF;
                END_IF;
              END_IF;
            END_FOR;

            IF avoid_uid >= 1 THEN
              g_unit[avoid_uid].target := TO_AVOID;
            END_IF;
          END_IF;

        END_IF;  (* next stage exists *)
      END_IF;  (* cur range check *)
    END_IF;  (* IN_PROCESS check *)

  END_FOR;

END_FUNCTION_BLOCK
