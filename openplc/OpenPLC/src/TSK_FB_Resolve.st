(* ============================================================
   TSK_FB_Resolve — Conflict resolution with chain-flex + locks
   ============================================================
   Ported from transporterTaskScheduler.js solveConflictWithChainFlex()

   Three-priority chain-flex strategy:
     Priority 1: CHAIN_BACKWARD — advance blocked batch using
                  cumulative flex_down across stages 1..blocked_stage
     Priority 2: CHAIN_FORWARD  — delay conflict batch using
                  cumulative flex_up across stages 1..conf_stage
     Priority 3: CHAIN_COMBINED — both backward + forward

   lockedStages prevents oscillation: once a stage is advanced
   (BACKWARD), it cannot be delayed (FORWARD), and vice versa.

   Chain-flex calculates the SUM of flex across all stages from
   stage 1 up to the target stage (JS: calculateChainFlex).
   The actual reduction/increase is distributed across stages
   walking backward from the target, respecting each stage's
   own flex capacity.

   Cap factor: 90% if batch is on that stage, 50% otherwise.
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_Resolve
VAR_INPUT
  i_conf_unit     : INT;     (* conflict task: unit *)
  i_conf_stage    : INT;     (* conflict task: stage *)
  i_conf_trans    : INT;     (* conflict task: transporter *)
  i_blocked_unit  : INT;     (* blocking task: unit *)
  i_blocked_stage : INT;     (* blocking task: stage *)
  i_deficit       : REAL;    (* seconds short *)
END_VAR
VAR_IN_OUT
  io_locks    : ARRAY[1..50] OF TSK_LOCK_T;
  io_lock_cnt : INT;
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_Transporters : INT;
    MAX_Units        : INT;
END_VAR

VAR_EXTERNAL
  g_task    : ARRAY[1..MAX_Transporters] OF TSK_QUEUE_T;
  g_schedule : ARRAY[1..MAX_Units] OF TSK_SCHEDULE_T;
  g_batch  : ARRAY[1..MAX_Units] OF BATCH_T;
END_VAR
VAR_OUTPUT
  o_solved      : BOOL;
  o_total_delay : REAL;
  o_total_adv   : REAL;
END_VAR
VAR
  remain   : REAL;
  cap      : REAL;
  flex     : REAL;
  amount   : REAL;
  si       : INT;
  sc       : INT;
  (* Chain flex sums *)
  chain_flex_down : REAL;    (* sum of flex_down for blocked batch stages 1..blocked_stage *)
  chain_flex_up   : REAL;    (* sum of flex_up for conf batch stages 1..conf_stage *)
  stage_flex      : REAL;    (* single stage flex *)
  (* Lock checking *)
  is_locked_adv   : BOOL;   (* blocked stage locked DELAY → cannot ADVANCE *)
  is_locked_del   : BOOL;   (* conf stage locked ADVANCE → cannot DELAY *)
  lock_i          : INT;
  (* Distribution walk *)
  walk_remain     : REAL;
  walk_flex       : REAL;
  walk_amount     : REAL;
  walk_cap        : REAL;
  (* Combined *)
  use_adv         : REAL;
  use_del         : REAL;
  can_advance     : BOOL;
  can_delay       : BOOL;
  eff_adv         : REAL;
  eff_del         : REAL;
  (* Shared shift FB *)
  fb_shift : STC_FB_ShiftSchedule;
END_VAR

o_solved      := FALSE;
o_total_delay := 0.0;
o_total_adv   := 0.0;
remain        := i_deficit;

IF remain <= 0.1 THEN
  o_solved := TRUE;
  RETURN;
END_IF;

(* ══════ Lock check: is blocked stage locked DELAY? (cannot ADVANCE) ══════ *)
is_locked_adv := FALSE;
FOR lock_i := 1 TO io_lock_cnt DO
  IF io_locks[lock_i].unit = i_blocked_unit
     AND io_locks[lock_i].stage = i_blocked_stage
     AND io_locks[lock_i].direction = 2 THEN  (* 2=DELAY *)
    is_locked_adv := TRUE;
  END_IF;
END_FOR;

(* ══════ Lock check: is conf stage locked ADVANCE? (cannot DELAY) ══════ *)
is_locked_del := FALSE;
FOR lock_i := 1 TO io_lock_cnt DO
  IF io_locks[lock_i].unit = i_conf_unit
     AND io_locks[lock_i].stage = i_conf_stage
     AND io_locks[lock_i].direction = 1 THEN  (* 1=ADVANCE *)
    is_locked_del := TRUE;
  END_IF;
END_FOR;

can_advance := NOT is_locked_adv;
can_delay   := NOT is_locked_del;

(* ══════ Calculate chain flex DOWN for blocked batch ══════ *)
(* Sum of flex_down (calc_time - min_time) from stage 1 to blocked_stage *)
chain_flex_down := 0.0;
IF can_advance AND i_blocked_unit >= 1 AND i_blocked_unit <= MAX_Units THEN
  sc := g_schedule[i_blocked_unit].stage_count;
  FOR si := 1 TO sc DO
    IF si <= i_blocked_stage THEN
      stage_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].stages[si].calc_time
                  - g_schedule[i_blocked_unit].stages[si].min_time);
      IF stage_flex > 0.0 THEN
        chain_flex_down := chain_flex_down + stage_flex;
      END_IF;
    END_IF;
  END_FOR;
END_IF;

(* ══════ Calculate chain flex UP for conflict batch ══════ *)
(* Sum of flex_up (max_time - calc_time) from stage 1 to conf_stage *)
chain_flex_up := 0.0;
IF can_delay AND i_conf_unit >= 1 AND i_conf_unit <= MAX_Units THEN
  sc := g_schedule[i_conf_unit].stage_count;
  FOR si := 1 TO sc DO
    IF si <= i_conf_stage THEN
      stage_flex := DINT_TO_REAL(g_schedule[i_conf_unit].stages[si].max_time
                  - g_schedule[i_conf_unit].stages[si].calc_time);
      IF stage_flex > 0.0 THEN
        chain_flex_up := chain_flex_up + stage_flex;
      END_IF;
    END_IF;
  END_FOR;
END_IF;

(* Effective flex considering locks *)
IF can_advance THEN eff_adv := chain_flex_down; ELSE eff_adv := 0.0; END_IF;
IF can_delay   THEN eff_del := chain_flex_up;   ELSE eff_del := 0.0; END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PRIORITY 1: CHAIN_BACKWARD — advance blocked batch           *)
(* Walk backward from blocked_stage, reduce calc_time per stage *)
(* ══════════════════════════════════════════════════════════════ *)
IF can_advance AND chain_flex_down >= remain THEN
  walk_remain := remain;
  sc := g_schedule[i_blocked_unit].stage_count;

  (* Walk from blocked_stage backward to stage 1 *)
  FOR si := i_blocked_stage TO 1 BY -1 DO
    IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
      walk_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].stages[si].calc_time
                  - g_schedule[i_blocked_unit].stages[si].min_time);
      IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;

      IF walk_flex > 0.1 THEN
        (* Cap: 90% if on stage, 50% otherwise *)
        IF g_batch[i_blocked_unit].cur_stage = si THEN
          walk_cap := 0.9;
        ELSE
          walk_cap := 0.5;
        END_IF;
        walk_amount := walk_flex * walk_cap;
        IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;

        (* Apply: reduce calc_time + shift subsequent stages *)
        g_schedule[i_blocked_unit].stages[si].calc_time :=
          g_schedule[i_blocked_unit].stages[si].calc_time - REAL_TO_DINT(walk_amount);
        g_schedule[i_blocked_unit].stages[si].exit_time :=
          g_schedule[i_blocked_unit].stages[si].exit_time - REAL_TO_LINT(walk_amount);
        fb_shift(i_unit := i_blocked_unit, i_from_stage := si + 1, i_amount := -walk_amount);

        walk_remain := walk_remain - walk_amount;
        o_total_adv := o_total_adv + walk_amount;
      END_IF;
    END_IF;
  END_FOR;

  remain := remain - o_total_adv;

  (* Record lock: ADVANCE on blocked stage *)
  IF io_lock_cnt < 50 THEN
    io_lock_cnt := io_lock_cnt + 1;
    io_locks[io_lock_cnt].unit := i_blocked_unit;
    io_locks[io_lock_cnt].stage := i_blocked_stage;
    io_locks[io_lock_cnt].direction := 1;  (* 1=ADVANCE *)
  END_IF;

  IF remain <= 0.1 THEN
    o_solved := TRUE;
    RETURN;
  END_IF;
END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PRIORITY 2: CHAIN_FORWARD — delay conflict batch             *)
(* Walk backward from conf_stage, increase calc_time per stage  *)
(* ══════════════════════════════════════════════════════════════ *)
IF can_delay AND chain_flex_up >= remain THEN
  walk_remain := remain;
  sc := g_schedule[i_conf_unit].stage_count;

  FOR si := i_conf_stage TO 1 BY -1 DO
    IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
      walk_flex := DINT_TO_REAL(g_schedule[i_conf_unit].stages[si].max_time
                  - g_schedule[i_conf_unit].stages[si].calc_time);
      IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;

      IF walk_flex > 0.1 THEN
        IF g_batch[i_conf_unit].cur_stage = si THEN
          walk_cap := 0.9;
        ELSE
          walk_cap := 0.5;
        END_IF;
        walk_amount := walk_flex * walk_cap;
        IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;

        g_schedule[i_conf_unit].stages[si].calc_time :=
          g_schedule[i_conf_unit].stages[si].calc_time + REAL_TO_DINT(walk_amount);
        g_schedule[i_conf_unit].stages[si].exit_time :=
          g_schedule[i_conf_unit].stages[si].exit_time + REAL_TO_LINT(walk_amount);
        fb_shift(i_unit := i_conf_unit, i_from_stage := si + 1, i_amount := walk_amount);

        walk_remain := walk_remain - walk_amount;
        o_total_delay := o_total_delay + walk_amount;
      END_IF;
    END_IF;
  END_FOR;

  remain := remain - o_total_delay;

  (* Record lock: DELAY on conf stage *)
  IF io_lock_cnt < 50 THEN
    io_lock_cnt := io_lock_cnt + 1;
    io_locks[io_lock_cnt].unit := i_conf_unit;
    io_locks[io_lock_cnt].stage := i_conf_stage;
    io_locks[io_lock_cnt].direction := 2;  (* 2=DELAY *)
  END_IF;

  IF remain <= 0.1 THEN
    o_solved := TRUE;
    RETURN;
  END_IF;
END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PRIORITY 3: CHAIN_COMBINED — use both backward + forward     *)
(* First consume advance flex, then delay flex for the rest     *)
(* ══════════════════════════════════════════════════════════════ *)
IF eff_adv + eff_del >= remain THEN
  (* Distribute: advance first, delay for remainder *)
  use_adv := eff_adv;
  IF use_adv > remain THEN use_adv := remain; END_IF;
  use_del := remain - use_adv;
  IF use_del > eff_del THEN
    use_del := eff_del;
    use_adv := remain - use_del;
  END_IF;

  (* Apply ADVANCE portion *)
  IF can_advance AND use_adv > 0.1 THEN
    walk_remain := use_adv;
    sc := g_schedule[i_blocked_unit].stage_count;
    FOR si := i_blocked_stage TO 1 BY -1 DO
      IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
        walk_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].stages[si].calc_time
                  - g_schedule[i_blocked_unit].stages[si].min_time);
        IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;
        IF walk_flex > 0.1 THEN
          IF g_batch[i_blocked_unit].cur_stage = si THEN walk_cap := 0.9; ELSE walk_cap := 0.5; END_IF;
          walk_amount := walk_flex * walk_cap;
          IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;
          g_schedule[i_blocked_unit].stages[si].calc_time :=
          g_schedule[i_blocked_unit].stages[si].calc_time - REAL_TO_DINT(walk_amount);
          g_schedule[i_blocked_unit].stages[si].exit_time :=
            g_schedule[i_blocked_unit].stages[si].exit_time - REAL_TO_LINT(walk_amount);
          fb_shift(i_unit := i_blocked_unit, i_from_stage := si + 1, i_amount := -walk_amount);
          walk_remain := walk_remain - walk_amount;
          o_total_adv := o_total_adv + walk_amount;
        END_IF;
      END_IF;
    END_FOR;

    IF io_lock_cnt < 50 THEN
      io_lock_cnt := io_lock_cnt + 1;
      io_locks[io_lock_cnt].unit := i_blocked_unit;
      io_locks[io_lock_cnt].stage := i_blocked_stage;
      io_locks[io_lock_cnt].direction := 1;
    END_IF;
  END_IF;

  (* Apply DELAY portion *)
  IF can_delay AND use_del > 0.1 THEN
    walk_remain := use_del;
    sc := g_schedule[i_conf_unit].stage_count;
    FOR si := i_conf_stage TO 1 BY -1 DO
      IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
        walk_flex := DINT_TO_REAL(g_schedule[i_conf_unit].stages[si].max_time
                  - g_schedule[i_conf_unit].stages[si].calc_time);
        IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;
        IF walk_flex > 0.1 THEN
          IF g_batch[i_conf_unit].cur_stage = si THEN walk_cap := 0.9; ELSE walk_cap := 0.5; END_IF;
          walk_amount := walk_flex * walk_cap;
          IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;
          g_schedule[i_conf_unit].stages[si].calc_time :=
          g_schedule[i_conf_unit].stages[si].calc_time + REAL_TO_DINT(walk_amount);
          g_schedule[i_conf_unit].stages[si].exit_time :=
            g_schedule[i_conf_unit].stages[si].exit_time + REAL_TO_LINT(walk_amount);
          fb_shift(i_unit := i_conf_unit, i_from_stage := si + 1, i_amount := walk_amount);
          walk_remain := walk_remain - walk_amount;
          o_total_delay := o_total_delay + walk_amount;
        END_IF;
      END_IF;
    END_FOR;

    IF io_lock_cnt < 50 THEN
      io_lock_cnt := io_lock_cnt + 1;
      io_locks[io_lock_cnt].unit := i_conf_unit;
      io_locks[io_lock_cnt].stage := i_conf_stage;
      io_locks[io_lock_cnt].direction := 2;
    END_IF;
  END_IF;

  remain := remain - o_total_adv - o_total_delay;
  IF remain <= 0.1 THEN
    o_solved := TRUE;
    RETURN;
  END_IF;
END_IF;

(* If not solved, partial resolution was applied *)

END_FUNCTION_BLOCK
