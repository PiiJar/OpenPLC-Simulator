(* ============================================================
   TWA_FB_CalcLimits.st — Transporter Working Area: X-limit calculation

   Calculates x_min_limit and x_max_limit for all active transporters.
   Algorithm ported from transporterWorkingArea.js:

     Phase 1:   Station-based restrictions (g_avoid_status)
     Step 2.0:  Basic safety distance (current positions)
     Step 2.2:  Priority-based collision avoidance
       2.2.1:   Sort by x-position (selection sort)
       2.2.2:   Calculate canEvade + priority
       2.2.3:   Priority restrictions (target-based)
       2.2.4:   Bidirectional safety
       2.2.5:   Trap validation

   Only X-direction for now (y_avoid_mm reserved for future).
   ============================================================ *)

FUNCTION_BLOCK TWA_FB_CalcLimits
VAR_EXTERNAL
  g_cfg            : ARRAY[1..3] OF TRANSPORTER_CFG_T;
  g_state          : ARRAY[1..3] OF TRANSPORTER_STATE_T;
  g_stations       : ARRAY[101..125] OF STATION_T;
  g_station_count  : INT;
  g_avoid_status   : ARRAY[101..125] OF INT;
END_VAR
VAR_EXTERNAL CONSTANT
  MAX_TRANSPORTERS : INT;
  AVOID_PASS       : INT;
  AVOID_BLOCK      : INT;
  MIN_WORK_AREA    : REAL;
END_VAR
VAR
  i            : INT;
  j            : INT;
  k            : INT;
  stn_num      : INT;
  stn_x        : REAL;
  avoid_st     : INT;
  min_x        : REAL;
  max_x        : REAL;
  current_x    : REAL;
  avoid_dist   : REAL;
  is_target    : BOOL;
  new_val      : REAL;
  left_s2_x    : REAL;
  right_s2_x   : REAL;
  has_left_s2  : BOOL;
  has_right_s2 : BOOL;
  midpoint     : REAL;

  (* Working arrays for sort + priority (max 3 transporters) *)
  n_active     : INT;
  w_idx        : ARRAY[1..3] OF INT;
  w_xpos       : ARRAY[1..3] OF REAL;
  w_phase      : ARRAY[1..3] OF INT;
  w_target     : ARRAY[1..3] OF REAL;
  w_avoid      : ARRAY[1..3] OF REAL;
  w_can_evade  : ARRAY[1..3] OF BOOL;
  w_priority   : ARRAY[1..3] OF REAL;

  (* Sort temp vars *)
  min_idx      : INT;
  tmp_int      : INT;
  tmp_real     : REAL;
  tmp_bool     : BOOL;

  (* Step 2.2.3 vars *)
  a_wins       : BOOL;
  restrict_x   : REAL;
  between      : INT;
  chain_ofs    : REAL;
  cur_min      : REAL;
  cur_max      : REAL;
  adjusted     : REAL;

  (* Step 2.2.4 vars *)
  left_right   : BOOL;
  right_right  : BOOL;
  left_left    : BOOL;
  right_left   : BOOL;
  safety_val   : REAL;

  work_area    : REAL;
  other_x      : REAL;
  other_avoid  : REAL;
END_VAR

(* ================================================================
   PHASE 1: Station-based restrictions from g_avoid_status
   For each active transporter, search stations near current_station
   and restrict x_min/x_max based on avoid_status 1 (pass) and 2 (block).
   ================================================================ *)
FOR i := 1 TO MAX_TRANSPORTERS DO
  IF NOT g_state[i].active THEN
    CONTINUE;
  END_IF;

  min_x := g_cfg[i].x_min_limit;
  max_x := g_cfg[i].x_max_limit;
  current_x := g_state[i].x_mm;
  avoid_dist := g_cfg[i].x_avoid_mm;

  (* If no limits configured, lock to current position *)
  IF (min_x < 1.0) OR (max_x < 1.0) THEN
    g_state[i].x_min_limit := current_x;
    g_state[i].x_max_limit := current_x;
    CONTINUE;
  END_IF;

  has_left_s2 := FALSE;
  has_right_s2 := FALSE;
  left_s2_x := 0.0;
  right_s2_x := 0.0;

  (* --- Search downward (smaller station numbers) from current_station --- *)
  stn_num := g_state[i].current_station - 1;
  WHILE stn_num >= 101 DO
    IF g_stations[stn_num].tank_id = 0 THEN
      stn_num := stn_num - 1;
      CONTINUE;
    END_IF;

    stn_x := g_stations[stn_num].x_position;
    IF stn_x < min_x THEN
      EXIT;
    END_IF;

    avoid_st := g_avoid_status[stn_num];

    (* AVOID_PASS: passable unless it is this transporter's target station *)
    IF avoid_st = AVOID_PASS THEN
      is_target := (stn_num = g_state[i].lift_station_target)
               OR  (stn_num = g_state[i].sink_station_target);
      IF is_target THEN
        IF current_x < stn_x THEN
          new_val := stn_x - avoid_dist;
          IF new_val < max_x THEN max_x := new_val; END_IF;
          right_s2_x := stn_x;
          has_right_s2 := TRUE;
        ELSE
          new_val := stn_x + avoid_dist;
          IF new_val > min_x THEN min_x := new_val; END_IF;
          left_s2_x := stn_x;
          has_left_s2 := TRUE;
        END_IF;
        EXIT;
      END_IF;
      (* else: passable, keep searching *)
    END_IF;

    (* AVOID_BLOCK: hard block — transporter cannot cross *)
    IF avoid_st = AVOID_BLOCK THEN
      IF current_x < stn_x THEN
        new_val := stn_x - avoid_dist;
        IF new_val < max_x THEN max_x := new_val; END_IF;
        right_s2_x := stn_x;
        has_right_s2 := TRUE;
      ELSE
        new_val := stn_x + avoid_dist;
        IF new_val > min_x THEN min_x := new_val; END_IF;
        left_s2_x := stn_x;
        has_left_s2 := TRUE;
      END_IF;
      EXIT;
    END_IF;

    stn_num := stn_num - 1;
  END_WHILE;

  (* --- Search upward (larger station numbers) from current_station --- *)
  stn_num := g_state[i].current_station + 1;
  WHILE stn_num <= 125 DO
    IF g_stations[stn_num].tank_id = 0 THEN
      stn_num := stn_num + 1;
      CONTINUE;
    END_IF;

    stn_x := g_stations[stn_num].x_position;
    IF stn_x > max_x THEN
      EXIT;
    END_IF;

    avoid_st := g_avoid_status[stn_num];

    IF avoid_st = AVOID_PASS THEN
      is_target := (stn_num = g_state[i].lift_station_target)
               OR  (stn_num = g_state[i].sink_station_target);
      IF is_target THEN
        IF current_x < stn_x THEN
          new_val := stn_x - avoid_dist;
          IF new_val < max_x THEN max_x := new_val; END_IF;
          right_s2_x := stn_x;
          has_right_s2 := TRUE;
        ELSE
          new_val := stn_x + avoid_dist;
          IF new_val > min_x THEN min_x := new_val; END_IF;
          left_s2_x := stn_x;
          has_left_s2 := TRUE;
        END_IF;
        EXIT;
      END_IF;
    END_IF;

    IF avoid_st = AVOID_BLOCK THEN
      IF current_x < stn_x THEN
        new_val := stn_x - avoid_dist;
        IF new_val < max_x THEN max_x := new_val; END_IF;
        right_s2_x := stn_x;
        has_right_s2 := TRUE;
      ELSE
        new_val := stn_x + avoid_dist;
        IF new_val > min_x THEN min_x := new_val; END_IF;
        left_s2_x := stn_x;
        has_left_s2 := TRUE;
      END_IF;
      EXIT;
    END_IF;

    stn_num := stn_num + 1;
  END_WHILE;

  (* Conflict resolution: trapped between two BLOCK stations *)
  IF (min_x >= max_x) AND has_left_s2 AND has_right_s2 THEN
    midpoint := (left_s2_x + right_s2_x) / 2.0;
    min_x := midpoint - 5.0;
    max_x := midpoint + 5.0;
  END_IF;

  g_state[i].x_min_limit := min_x;
  g_state[i].x_max_limit := max_x;
END_FOR;

(* ================================================================
   STEP 2.0: Basic safety distance — current positions
   Every active transporter pushes neighbors away by x_avoid_mm.
   ================================================================ *)
FOR i := 1 TO MAX_TRANSPORTERS DO
  IF NOT g_state[i].active THEN
    CONTINUE;
  END_IF;

  current_x := g_state[i].x_mm;
  avoid_dist := g_cfg[i].x_avoid_mm;

  FOR j := 1 TO MAX_TRANSPORTERS DO
    IF j = i THEN CONTINUE; END_IF;
    IF NOT g_state[j].active THEN CONTINUE; END_IF;

    other_x := g_state[j].x_mm;

    IF other_x > current_x THEN
      (* j is to the RIGHT of i — restrict j's x_min *)
      new_val := current_x + avoid_dist;
      IF new_val > g_state[j].x_min_limit THEN
        g_state[j].x_min_limit := new_val;
      END_IF;
    ELSIF other_x < current_x THEN
      (* j is to the LEFT of i — restrict j's x_max *)
      new_val := current_x - avoid_dist;
      IF new_val < g_state[j].x_max_limit THEN
        g_state[j].x_max_limit := new_val;
      END_IF;
    END_IF;
  END_FOR;
END_FOR;

(* ================================================================
   STEP 2.2: Priority-based collision avoidance
   ================================================================ *)

(* --- 2.2.1: Build sorted array of active transporters by x-position --- *)
n_active := 0;
FOR i := 1 TO MAX_TRANSPORTERS DO
  IF g_state[i].active THEN
    n_active := n_active + 1;
    w_idx[n_active] := i;
    w_xpos[n_active] := g_state[i].x_mm;
    w_phase[n_active] := g_state[i].phase;
    w_target[n_active] := g_state[i].target_x;
    w_avoid[n_active] := g_cfg[i].x_avoid_mm;
  END_IF;
END_FOR;

(* Selection sort by x-position (ascending) *)
FOR i := 1 TO n_active - 1 DO
  min_idx := i;
  FOR j := i + 1 TO n_active DO
    IF w_xpos[j] < w_xpos[min_idx] THEN
      min_idx := j;
    END_IF;
  END_FOR;
  IF min_idx <> i THEN
    tmp_int := w_idx[i];    w_idx[i] := w_idx[min_idx];    w_idx[min_idx] := tmp_int;
    tmp_real := w_xpos[i];  w_xpos[i] := w_xpos[min_idx];  w_xpos[min_idx] := tmp_real;
    tmp_int := w_phase[i];  w_phase[i] := w_phase[min_idx]; w_phase[min_idx] := tmp_int;
    tmp_real := w_target[i]; w_target[i] := w_target[min_idx]; w_target[min_idx] := tmp_real;
    tmp_real := w_avoid[i];  w_avoid[i] := w_avoid[min_idx];  w_avoid[min_idx] := tmp_real;
  END_IF;
END_FOR;

(* --- 2.2.2: Calculate canEvade and priority --- *)
FOR i := 1 TO n_active DO
  k := w_idx[i];

  (* canEvade rules:
     - phase 2 or 4 (Z-movement): cannot evade
     - working area too small: cannot evade *)
  w_can_evade[i] := TRUE;
  IF (w_phase[i] = 2) OR (w_phase[i] = 4) THEN
    w_can_evade[i] := FALSE;
  END_IF;
  work_area := g_state[k].x_max_limit - g_state[k].x_min_limit;
  IF work_area < MIN_WORK_AREA THEN
    w_can_evade[i] := FALSE;
  END_IF;

  w_priority[i] := TWA_CalcPriority(
    i_phase := w_phase[i],
    i_can_evade := w_can_evade[i],
    i_x_pos := w_xpos[i],
    i_x_target := w_target[i]
  );
END_FOR;

(* Skip Steps 2.2.3-2.2.5 if fewer than 2 active transporters *)
IF n_active >= 2 THEN

  (* --- 2.2.3: Priority restrictions (higher priority → lower priority) --- *)
  FOR i := 1 TO n_active DO
    (* Skip idle transporters — they don't set priority restrictions *)
    IF w_phase[i] = 0 THEN CONTINUE; END_IF;

    FOR j := 1 TO n_active DO
      IF i = j THEN CONTINUE; END_IF;

      (* Determine if i has higher priority than j *)
      a_wins := FALSE;
      IF w_priority[i] > w_priority[j] THEN
        a_wins := TRUE;
      ELSIF (w_priority[i] = w_priority[j]) AND (w_idx[i] < w_idx[j]) THEN
        a_wins := TRUE;
      END_IF;

      IF NOT a_wins THEN CONTINUE; END_IF;

      (* Higher priority transporter uses target for phase 1/3, else current pos *)
      IF (w_phase[i] = 1) OR (w_phase[i] = 3) THEN
        restrict_x := w_target[i];
      ELSE
        restrict_x := w_xpos[i];
      END_IF;

      k := w_idx[j];
      cur_min := g_state[k].x_min_limit;
      cur_max := g_state[k].x_max_limit;

      IF w_xpos[i] < w_xpos[j] THEN
        (* i is LEFT, j is RIGHT — i sets j's x_min *)
        between := j - i - 1;
        chain_ofs := w_avoid[i] + INT_TO_REAL(between) * (MIN_WORK_AREA + w_avoid[i]);
        new_val := restrict_x + chain_ofs;

        IF new_val > cur_min THEN
          IF new_val <= (cur_max - MIN_WORK_AREA) THEN
            g_state[k].x_min_limit := new_val;
          ELSE
            adjusted := cur_max - MIN_WORK_AREA;
            IF adjusted > cur_min THEN
              g_state[k].x_min_limit := adjusted;
            END_IF;
          END_IF;
        END_IF;

      ELSIF w_xpos[i] > w_xpos[j] THEN
        (* i is RIGHT, j is LEFT — i sets j's x_max *)
        between := i - j - 1;
        chain_ofs := w_avoid[i] + INT_TO_REAL(between) * (MIN_WORK_AREA + w_avoid[i]);
        new_val := restrict_x - chain_ofs;

        IF new_val < cur_max THEN
          IF new_val >= (cur_min + MIN_WORK_AREA) THEN
            g_state[k].x_max_limit := new_val;
          ELSE
            adjusted := cur_min + MIN_WORK_AREA;
            IF adjusted < cur_max THEN
              g_state[k].x_max_limit := adjusted;
            END_IF;
          END_IF;
        END_IF;
      END_IF;
    END_FOR;
  END_FOR;

  (* --- 2.2.4: Bidirectional safety (both moving same direction) --- *)
  FOR i := 1 TO n_active - 1 DO
    j := i + 1;
    (* i = left (smaller x), j = right (larger x) — sorted array *)

    left_right := ((w_phase[i] = 1) OR (w_phase[i] = 3)) AND (w_target[i] > w_xpos[i]);
    right_right := ((w_phase[j] = 1) OR (w_phase[j] = 3)) AND (w_target[j] > w_xpos[j]);
    left_left := ((w_phase[i] = 1) OR (w_phase[i] = 3)) AND (w_target[i] < w_xpos[i]);
    right_left := ((w_phase[j] = 1) OR (w_phase[j] = 3)) AND (w_target[j] < w_xpos[j]);

    IF left_right AND right_right THEN
      (* Both moving right — left chasing right *)
      safety_val := w_xpos[i] + w_avoid[i];
      k := w_idx[j];
      IF safety_val > g_state[k].x_min_limit THEN
        g_state[k].x_min_limit := safety_val;
      END_IF;
    END_IF;

    IF left_left AND right_left THEN
      (* Both moving left — right chasing left *)
      safety_val := w_xpos[j] - w_avoid[j];
      k := w_idx[i];
      IF safety_val < g_state[k].x_max_limit THEN
        g_state[k].x_max_limit := safety_val;
      END_IF;
    END_IF;
  END_FOR;

  (* --- 2.2.5: Validate limits (trap detection) --- *)
  FOR i := 1 TO n_active DO
    k := w_idx[i];
    IF g_state[k].x_min_limit > g_state[k].x_max_limit THEN
      (* Trapped — lock in place *)
      g_state[k].x_min_limit := g_state[k].x_mm;
      g_state[k].x_max_limit := g_state[k].x_mm;
    END_IF;
  END_FOR;

END_IF;  (* n_active >= 2 *)

END_FUNCTION_BLOCK
