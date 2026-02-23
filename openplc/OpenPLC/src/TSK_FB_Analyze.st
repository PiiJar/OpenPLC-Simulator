(* ============================================================
   TSK_FB_Analyze — Conflict analysis for task list
   ============================================================
   Ported from transporterTaskScheduler.js analyzeTaskConflicts()

   Flattens all transporter queues into one global list sorted
   by start_time (insertion sort). Then checks:
   1. TASK_SEQUENCE: same transporter consecutive pair — does
      the transporter have time to travel from prev.sink to
      next.lift? Uses g_move precomputed travel times.
   2. TRANSPORTER_COLLISION: different transporters — do their
      X-ranges and time-ranges overlap?

   Stops at first conflict found (one conflict per cycle).

   Outputs:
     o_has_conflict — TRUE if conflict found
     o_conf_unit, o_conf_stage — which task is blocked
     o_blocked_unit, o_blocked_stage — which task blocks it
     o_deficit — how many seconds short
     o_conf_type — 1=TASK_SEQUENCE, 2=TRANSPORTER_COLLISION
     checked — internal array for resolve phase
     checked_count — how many tasks were checked
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_Analyze
VAR_EXTERNAL
  g_tasks    : ARRAY[1..3] OF TSK_QUEUE_T;
  g_stations : ARRAY[101..125] OF STATION_T;
END_VAR
VAR_OUTPUT
  o_has_conflict  : BOOL;
  o_conf_type     : INT;     (* 1=TASK_SEQUENCE, 2=COLLISION *)
  o_conf_unit     : INT;     (* conflict task: unit *)
  o_conf_stage    : INT;     (* conflict task: stage *)
  o_conf_trans    : INT;     (* conflict task: transporter *)
  o_blocked_unit  : INT;     (* blocking task: unit *)
  o_blocked_stage : INT;     (* blocking task: stage *)
  o_deficit       : REAL;    (* seconds short *)
  checked_count   : INT;     (* tasks checked before conflict *)
END_VAR
VAR
  (* Merged sorted task list — max 3 transporters x 10 tasks = 30 *)
  sorted       : ARRAY[1..30] OF TSK_TASK_T;
  sorted_trans : ARRAY[1..30] OF INT;    (* transporter id for each sorted task *)
  sorted_cnt   : INT;
  (* Checked tasks with flex info *)
  chk          : ARRAY[1..30] OF TSK_CHECKED_T;
  chk_cnt      : INT;
  (* Loop variables *)
  ti       : INT;
  qi       : INT;
  si       : INT;
  ins      : INT;
  ci       : INT;
  (* Temp *)
  tmp_task : TSK_TASK_T;
  tmp_tid  : INT;
  (* Conflict check vars *)
  prev_sink : INT;
  next_lift : INT;
  travel_s  : REAL;
  gap_s     : REAL;
  deficit_s : REAL;
  (* Flex calculation *)
  calc_t   : REAL;
  min_t    : REAL;
  max_t    : REAL;
  f_down   : REAL;
  f_up     : REAL;
  (* X overlap check *)
  x1_min   : REAL;
  x1_max   : REAL;
  x2_min   : REAL;
  x2_max   : REAL;
  xo_start : REAL;
  xo_end   : REAL;
  to_start : REAL;
  to_end   : REAL;
  lift_x   : REAL;
  sink_x   : REAL;
  l_idx    : INT;
  s_idx    : INT;
  DEFICIT_TOL : REAL := 1.0;
  fb_travel : STC_FB_CalcHorizontalTravel;  (* shared horizontal travel calc *)
END_VAR

o_has_conflict := FALSE;
o_conf_type    := 0;
o_deficit      := 0.0;
checked_count  := 0;
chk_cnt        := 0;

(* ══════ Step 1: Merge all queues into sorted[] by start_time (insertion sort) ══════ *)
sorted_cnt := 0;
FOR ti := 1 TO 3 DO
  FOR qi := 1 TO g_tasks[ti].count DO
    IF g_tasks[ti].queue[qi].unit > 0 THEN
      (* Insert into sorted position *)
      sorted_cnt := sorted_cnt + 1;
      IF sorted_cnt <= 30 THEN
        sorted[sorted_cnt] := g_tasks[ti].queue[qi];
        sorted_trans[sorted_cnt] := ti;
        (* Insertion sort: bubble up *)
        ins := sorted_cnt;
        WHILE ins > 1 DO
          IF sorted[ins].start_time < sorted[ins - 1].start_time THEN
            tmp_task := sorted[ins];
            tmp_tid  := sorted_trans[ins];
            sorted[ins] := sorted[ins - 1];
            sorted_trans[ins] := sorted_trans[ins - 1];
            sorted[ins - 1] := tmp_task;
            sorted_trans[ins - 1] := tmp_tid;
            ins := ins - 1;
          ELSE
            ins := 0; (* break *)
          END_IF;
        END_WHILE;
      END_IF;
    END_IF;
  END_FOR;
END_FOR;

IF sorted_cnt = 0 THEN RETURN; END_IF;

(* ══════ Step 2: Walk sorted list, build checked[], detect conflicts ══════ *)
FOR si := 1 TO sorted_cnt DO

  (* Calculate flex for this task *)
  calc_t := sorted[si].calc_time;
  min_t  := sorted[si].min_time;
  max_t  := sorted[si].max_time;
  f_down := calc_t - min_t;
  IF f_down < 0.0 THEN f_down := 0.0; END_IF;
  f_up := max_t - calc_t;
  IF f_up < 0.0 THEN f_up := 0.0; END_IF;

  (* Get X range for this task *)
  l_idx := sorted[si].lift_station - 100;
  s_idx := sorted[si].sink_station - 100;
  IF l_idx >= 1 AND l_idx <= 25 THEN
    lift_x := g_stations[sorted[si].lift_station].x_position;
  ELSE
    lift_x := 0.0;
  END_IF;
  IF s_idx >= 1 AND s_idx <= 25 THEN
    sink_x := g_stations[sorted[si].sink_station].x_position;
  ELSE
    sink_x := 0.0;
  END_IF;
  IF lift_x < sink_x THEN
    x1_min := lift_x;
    x1_max := sink_x;
  ELSE
    x1_min := sink_x;
    x1_max := lift_x;
  END_IF;

  (* Add to checked list *)
  chk_cnt := chk_cnt + 1;
  IF chk_cnt <= 30 THEN
    chk[chk_cnt].unit        := sorted[si].unit;
    chk[chk_cnt].stage       := sorted[si].stage;
    chk[chk_cnt].transporter := sorted_trans[si];
    chk[chk_cnt].start_time  := sorted[si].start_time;
    chk[chk_cnt].end_time    := sorted[si].finish_time;
    chk[chk_cnt].flex_down   := f_down;
    chk[chk_cnt].flex_up     := f_up;
    chk[chk_cnt].x_min       := x1_min;
    chk[chk_cnt].x_max       := x1_max;
    chk[chk_cnt].is_conflict := FALSE;
  END_IF;

  (* ─── Check TASK_SEQUENCE: same transporter, previous task ─── *)
  (* Find the previous task for this transporter in sorted order *)
  FOR ci := si - 1 TO 1 BY -1 DO
    IF sorted_trans[ci] = sorted_trans[si] THEN
      (* Found previous task on same transporter *)
      prev_sink := sorted[ci].sink_station;
      next_lift := sorted[si].lift_station;

      fb_travel(i_from_stn := prev_sink, i_to_stn := next_lift, i_trans := sorted_trans[si]);
      travel_s := fb_travel.o_travel_s;

      gap_s := sorted[si].start_time - sorted[ci].finish_time;
      deficit_s := travel_s - gap_s;

      IF deficit_s > DEFICIT_TOL THEN
        (* TASK_SEQUENCE conflict! *)
        o_has_conflict  := TRUE;
        o_conf_type     := 1;
        o_conf_unit     := sorted[si].unit;
        o_conf_stage    := sorted[si].stage;
        o_conf_trans    := sorted_trans[si];
        o_blocked_unit  := sorted[ci].unit;
        o_blocked_stage := sorted[ci].stage;
        o_deficit       := deficit_s;
        IF chk_cnt <= 30 THEN
          chk[chk_cnt].is_conflict := TRUE;
        END_IF;
        checked_count := chk_cnt;
        RETURN;
      END_IF;

      EXIT; (* only check immediate predecessor *)
    END_IF;
  END_FOR;

  (* ─── Check TRANSPORTER_COLLISION: different transporter, X+time overlap ─── *)
  FOR ci := 1 TO chk_cnt - 1 DO
    IF chk[ci].transporter <> sorted_trans[si] THEN
      (* X overlap *)
      x2_min := chk[ci].x_min;
      x2_max := chk[ci].x_max;
      xo_start := x1_min;
      IF x2_min > xo_start THEN xo_start := x2_min; END_IF;
      xo_end := x1_max;
      IF x2_max < xo_end THEN xo_end := x2_max; END_IF;

      IF xo_start < xo_end THEN
        (* Time overlap *)
        to_start := sorted[si].start_time;
        IF chk[ci].start_time > to_start THEN to_start := chk[ci].start_time; END_IF;
        to_end := sorted[si].finish_time;
        IF chk[ci].end_time < to_end THEN to_end := chk[ci].end_time; END_IF;

        IF to_start < to_end THEN
          (* TRANSPORTER_COLLISION conflict! *)
          deficit_s := (to_end - to_start) + 2.0; (* +2s margin *)
          o_has_conflict  := TRUE;
          o_conf_type     := 2;
          o_conf_unit     := sorted[si].unit;
          o_conf_stage    := sorted[si].stage;
          o_conf_trans    := sorted_trans[si];
          o_blocked_unit  := chk[ci].unit;
          o_blocked_stage := chk[ci].stage;
          o_deficit       := deficit_s;
          IF chk_cnt <= 30 THEN
            chk[chk_cnt].is_conflict := TRUE;
          END_IF;
          checked_count := chk_cnt;
          RETURN;
        END_IF;
      END_IF;
    END_IF;
  END_FOR;

END_FOR;

(* No conflict found *)
checked_count := chk_cnt;

END_FUNCTION_BLOCK
