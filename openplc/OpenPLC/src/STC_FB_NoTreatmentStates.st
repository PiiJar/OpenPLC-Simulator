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
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END  : INT;
    IN_PROCESS         : INT;
    PROCESSED          : INT;
    NOT_USED           : INT;
  END_VAR

  VAR
    u          : INT;        (* unit loop index *)
    cur        : INT;        (* current stage number *)
    loc        : INT;        (* unit location (station number) *)
    cal        : INT;        (* cal_time for current stage (seconds) *)
    elapsed    : LINT;       (* seconds spent at current station *)
  END_VAR

  FOR u := 1 TO MAX_UNITS DO
    IF g_unit[u].status = NOT_USED THEN
      CONTINUE;
    END_IF;

    (* Mark batch PROCESSED when batch is on its last treatment stage
       and the required cal_time has elapsed at the current station. *)
    IF g_batch[u].batch_code <> 0 AND g_batch[u].state = IN_PROCESS THEN
      cur := g_batch[u].cur_stage;
      IF cur >= 1 AND cur < MAX_STAGES THEN
        IF g_program[u].stages[cur + 1].stations[1] = 0 THEN
          loc := g_unit[u].location;
          IF loc >= STATION_ARRAY_START AND loc <= STATION_ARRAY_END THEN
            IF g_station[loc].change_time > 0 THEN
              elapsed := g_time_s - g_station[loc].change_time;
              cal := g_program[u].stages[cur].cal_time;
              IF elapsed >= INT_TO_LINT(cal) THEN
                g_batch[u].state := PROCESSED;
              END_IF;
            END_IF;
          END_IF;
        END_IF;
      END_IF;
    END_IF;

  END_FOR;

END_FUNCTION_BLOCK
