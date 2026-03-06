(* ==========================================================
   STC_FB_NoTreatmentStates
   ----------------------------------------------------------
   Manages non-treatment target states for all units.

   Structure:
     Pass 0 — SNAPSHOT: read unit/batch/station state once into
              snap[] array. Also detects has_loading flag.
     Section 1 — PROCESSED: mark last-stage units as PROCESSED.
     Section 2 — TO_AVOID: clear occupied next-stage stations.
     Section 3 — TO_LOADING: route one empty unit to loading.
   ========================================================== *)

FUNCTION_BLOCK STC_FB_NoTreatmentStates
  VAR_EXTERNAL CONSTANT
    MAX_Units          : INT;
    MAX_STEPS_PER_PROGRAM         : INT;
    MAX_STATIONS_PER_STEP      : INT;
    MIN_StationIndex : INT;
    MAX_StationIndex  : INT;
    IN_PROCESS         : INT;
    PROCESSED          : INT;
    NOT_USED           : INT;
    TO_NONE            : INT;
    TO_AVOID           : INT;
    TO_LOADING         : INT;
    USED               : INT;
    OP_LOADING           : INT;
    OP_LOADING_UNLOADING : INT;
  END_VAR

  VAR_EXTERNAL
    g_unit             : ARRAY[1..MAX_Units] OF UNIT_T;
    g_batch            : ARRAY[1..MAX_Units] OF BATCH_T;
    g_program          : ARRAY[1..MAX_Units] OF TREATMENT_PROGRAM_T;
    g_station          : ARRAY[MIN_StationIndex..MAX_StationIndex] OF STATION_T;
    g_time_s           : LINT;
    g_production_queue : INT;
  END_VAR

  VAR
    (* Snapshot *)
    snap        : ARRAY[1..MAX_Units] OF UNIT_SNAP_T;
    u           : INT;        (* unit loop index *)
    has_loading : BOOL;       (* any unit already has TO_LOADING *)
    (* Section 1+2 *)
    p           : INT;        (* parallel station loop *)
    next_stn    : INT;        (* next stage station *)
    occ_uid     : INT;        (* unit_id at an occupied station *)
    free_found  : BOOL;       (* any next-stage station is free *)
    avoid_uid   : INT;        (* unit to mark TO_AVOID *)
    (* Section 3 *)
    load_free   : BOOL;       (* a loading station is free *)
    load_uid    : INT;        (* best candidate for TO_LOADING *)
    load_in_buf : BOOL;       (* current candidate is in buffer *)
    stk         : INT;        (* station loop *)
    op          : INT;        (* station operation code *)
  END_VAR

  (* ════════════════════════════════════════════════════════════
     Pass 0 — SNAPSHOT: collect per-unit state in one pass
     ════════════════════════════════════════════════════════════ *)
  has_loading := FALSE;

  FOR u := 1 TO MAX_Units DO
    snap[u].active := g_unit[u].status <> NOT_USED;
    IF NOT snap[u].active THEN
      CONTINUE;
    END_IF;

    snap[u].loc       := g_unit[u].location;
    snap[u].tgt       := g_unit[u].target;
    snap[u].has_batch := g_batch[u].batch_code <> 0;
    snap[u].bstate    := g_batch[u].state;
    snap[u].cur_stage := g_batch[u].cur_stage;

    snap[u].on_station := snap[u].loc >= MIN_StationIndex
                          AND snap[u].loc <= MAX_StationIndex;
    IF snap[u].on_station THEN
      snap[u].loc_op    := g_station[snap[u].loc].StationType;
      snap[u].in_buffer := snap[u].loc_op >= 44 AND snap[u].loc_op <= 47;
      IF g_station[snap[u].loc].ChangeTime > 0 THEN
        snap[u].elapsed := g_time_s - g_station[snap[u].loc].ChangeTime;
      ELSE
        snap[u].elapsed := 0;
      END_IF;
      snap[u].cal := g_program[u].stages[snap[u].cur_stage].cal_time;
    ELSE
      snap[u].loc_op    := 0;
      snap[u].in_buffer := FALSE;
      snap[u].elapsed   := 0;
      snap[u].cal       := 0;
    END_IF;

    IF snap[u].tgt = TO_LOADING THEN
      has_loading := TRUE;
    END_IF;
  END_FOR;

  (* ════════════════════════════════════════════════════════════
     Section 1 — PROCESSED: mark batch done at last treatment stage
     ════════════════════════════════════════════════════════════
     For each IN_PROCESS unit on a station:
       If next stage is empty (stations[1]=0) → last stage.
       If elapsed >= cal_time → set state := PROCESSED. *)
  FOR u := 1 TO MAX_Units DO
    IF NOT snap[u].active OR NOT snap[u].has_batch THEN
      CONTINUE;
    END_IF;
    IF snap[u].bstate <> IN_PROCESS OR NOT snap[u].on_station THEN
      CONTINUE;
    END_IF;
    IF snap[u].cur_stage >= 1 AND snap[u].cur_stage < MAX_STEPS_PER_PROGRAM THEN
      IF g_program[u].stages[snap[u].cur_stage + 1].stations[1] = 0 THEN
        IF snap[u].elapsed > 0 AND snap[u].elapsed >= INT_TO_LINT(snap[u].cal) THEN
          g_batch[u].state := PROCESSED;
          snap[u].bstate   := PROCESSED;  (* update snapshot *)
        END_IF;
      END_IF;
    END_IF;
  END_FOR;

  (* ════════════════════════════════════════════════════════════
     Section 2 — TO_AVOID: clear the way to next treatment station
     ════════════════════════════════════════════════════════════
     For each IN_PROCESS unit whose next stage exists:
       Pass 1: check if any next-stage station is free or already
               has a TO_AVOID unit (slot being cleared).
       Pass 2: if all occupied, mark ONE empty-batch TO_NONE unit
               at those stations as TO_AVOID. *)
  FOR u := 1 TO MAX_Units DO
    IF NOT snap[u].active OR NOT snap[u].has_batch THEN
      CONTINUE;
    END_IF;
    IF snap[u].bstate <> IN_PROCESS THEN
      CONTINUE;
    END_IF;
    IF snap[u].cur_stage < 1 OR snap[u].cur_stage >= MAX_STEPS_PER_PROGRAM THEN
      CONTINUE;
    END_IF;
    IF g_program[u].stages[snap[u].cur_stage + 1].stations[1] = 0 THEN
      CONTINUE;  (* no next stage *)
    END_IF;

    (* — Pass 1: any next-stage station free or being cleared? — *)
    free_found := FALSE;
    avoid_uid  := 0;
    FOR p := 1 TO MAX_STATIONS_PER_STEP DO
      next_stn := g_program[u].stages[snap[u].cur_stage + 1].stations[p];
      IF next_stn = 0 THEN
        EXIT;
      END_IF;
      IF next_stn >= MIN_StationIndex AND next_stn <= MAX_StationIndex THEN
        IF g_station[next_stn].UnitId = 0 THEN
          free_found := TRUE;
          EXIT;
        END_IF;
        occ_uid := g_station[next_stn].UnitId;
        IF occ_uid >= 1 AND occ_uid <= MAX_Units THEN
          IF snap[occ_uid].tgt = TO_AVOID THEN
            free_found := TRUE;
            EXIT;
          END_IF;
        END_IF;
      END_IF;
    END_FOR;

    (* — Pass 2: all occupied → mark ONE movable unit TO_AVOID — *)
    IF NOT free_found THEN
      FOR p := 1 TO MAX_STATIONS_PER_STEP DO
        next_stn := g_program[u].stages[snap[u].cur_stage + 1].stations[p];
        IF next_stn = 0 THEN
          EXIT;
        END_IF;
        IF next_stn >= MIN_StationIndex AND next_stn <= MAX_StationIndex THEN
          occ_uid := g_station[next_stn].UnitId;
          IF occ_uid >= 1 AND occ_uid <= MAX_Units THEN
            IF NOT snap[occ_uid].has_batch AND snap[occ_uid].tgt = TO_NONE THEN
              avoid_uid := occ_uid;
              EXIT;
            END_IF;
          END_IF;
        END_IF;
      END_FOR;

      IF avoid_uid >= 1 THEN
        g_unit[avoid_uid].target := TO_AVOID;
        snap[avoid_uid].tgt     := TO_AVOID;  (* update snapshot *)
      END_IF;
    END_IF;
  END_FOR;

  (* ════════════════════════════════════════════════════════════
     Section 3 — TO_LOADING: route one empty unit to loading station
     ════════════════════════════════════════════════════════════
     When production is active and a loading/loading_unloading station
     is free, find ONE batchless USED unit with TO_NONE target.
     Priority: units NOT in buffer/storage first. *)
  IF g_production_queue = 1 AND NOT has_loading THEN

    (* Check if any loading station is free *)
    load_free := FALSE;
    FOR stk := MIN_StationIndex TO MAX_StationIndex DO
      op := g_station[stk].StationType;
      IF (op = OP_LOADING OR op = OP_LOADING_UNLOADING)
         AND g_station[stk].UnitId = 0 THEN
        load_free := TRUE;
        EXIT;
      END_IF;
    END_FOR;

    IF load_free THEN
      load_uid    := 0;
      load_in_buf := FALSE;
      FOR u := 1 TO MAX_Units DO
        IF snap[u].active AND NOT snap[u].has_batch
           AND snap[u].tgt = TO_NONE AND snap[u].on_station THEN
          IF snap[u].in_buffer THEN
            IF load_uid = 0 THEN
              load_uid    := u;
              load_in_buf := TRUE;
            END_IF;
          ELSE
            IF load_uid = 0 OR load_in_buf THEN
              load_uid    := u;
              load_in_buf := FALSE;
            END_IF;
          END_IF;
        END_IF;
      END_FOR;

      IF load_uid >= 1 THEN
        g_unit[load_uid].target := TO_LOADING;
      END_IF;
    END_IF; (* load_free *)

  END_IF; (* production_queue AND NOT has_loading *)

END_FUNCTION_BLOCK
