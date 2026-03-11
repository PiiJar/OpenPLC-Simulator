(* ============================================================
   TSK_FB_Resolve — Conflict resolution with chain-flex + locks
   ============================================================
   Ported from transporterTaskScheduler.js solveConflictWithChainFlex()

   Five-priority chain-flex strategy:
     Priority 1: CHAIN_BACKWARD — advance blocked batch using
                  cumulative flex_down across stages 1..blocked_stage
     Priority 2: CHAIN_FORWARD  — delay conflict batch using
                  cumulative flex_up across stages 1..conf_stage
     Priority 3: CHAIN_COMBINED — both backward + forward
     Priority 4: PRECEDING_DELAY — delay conf batch at stage-1
                  (GAP-8: JS Phase 3)
     Priority 5: DELAY_PREV_PAST_NEXT — delay blocked batch to
                  force order swap if not swappable (GAP-8: JS Phase 4)

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
  io_locks    : ARRAY[1..50] OF UDT_JC_TskLockType;
  io_lock_cnt : INT;
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_Transporters : INT;
    MAX_Units        : INT;
END_VAR

VAR_EXTERNAL
  g_task    : ARRAY[1..MAX_Transporters] OF UDT_JC_TskQueueType;
  g_schedule : ARRAY[1..MAX_Units] OF UDT_JC_TskScheduleType;
  g_batch   : ARRAY[1..MAX_Units] OF UDT_BatchType;
  g_program : ARRAY[1..MAX_Units] OF UDT_TreatmentProgramType;
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
  (* Priority 4 — PRECEDING_DELAY *)
  prev_conf_stage   : INT;
  is_pcs_locked     : BOOL;
  (* Priority 5 — DELAY_PREV_PAST_NEXT *)
  prev_sink_stn     : INT;
  next_lift_stn     : INT;
  is_blk_adv_locked : BOOL;
  qi                : INT;
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
  IF io_locks[lock_i].Unit = i_blocked_unit
     AND io_locks[lock_i].Stage = i_blocked_stage
     AND io_locks[lock_i].Direction = 2 THEN  (* 2=DELAY *)
    is_locked_adv := TRUE;
  END_IF;
END_FOR;

(* ══════ Lock check: is conf stage locked ADVANCE? (cannot DELAY) ══════ *)
is_locked_del := FALSE;
FOR lock_i := 1 TO io_lock_cnt DO
  IF io_locks[lock_i].Unit = i_conf_unit
     AND io_locks[lock_i].Stage = i_conf_stage
     AND io_locks[lock_i].Direction = 1 THEN  (* 1=ADVANCE *)
    is_locked_del := TRUE;
  END_IF;
END_FOR;

can_advance := NOT is_locked_adv;
can_delay   := NOT is_locked_del;

(* ══════ Calculate chain flex DOWN for blocked batch ══════ *)
(* Sum of flex_down (calc_time - min_time) from stage 1 to blocked_stage *)
chain_flex_down := 0.0;
IF can_advance AND i_blocked_unit >= 1 AND i_blocked_unit <= MAX_Units THEN
  sc := g_schedule[i_blocked_unit].StageCount;
  FOR si := 1 TO sc DO
    IF si <= i_blocked_stage THEN
      stage_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].Stages[si].CalcTime
                  - g_schedule[i_blocked_unit].Stages[si].MinTime);
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
  sc := g_schedule[i_conf_unit].StageCount;
  FOR si := 1 TO sc DO
    IF si <= i_conf_stage THEN
      stage_flex := DINT_TO_REAL(g_schedule[i_conf_unit].Stages[si].MaxTime
                  - g_schedule[i_conf_unit].Stages[si].CalcTime);
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
  sc := g_schedule[i_blocked_unit].StageCount;

  (* Walk from blocked_stage backward to stage 1 *)
  FOR si := i_blocked_stage TO 1 BY -1 DO
    IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
      walk_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].Stages[si].CalcTime
                  - g_schedule[i_blocked_unit].Stages[si].MinTime);
      IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;

      IF walk_flex > 0.1 THEN
        (* Cap: 90% if on stage, 50% otherwise *)
        IF g_batch[i_blocked_unit].CurStage = si THEN
          walk_cap := 0.9;
        ELSE
          walk_cap := 0.5;
        END_IF;
        walk_amount := walk_flex * walk_cap;
        IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;

        (* Apply: reduce calc_time + shift subsequent stages *)
        g_schedule[i_blocked_unit].Stages[si].CalcTime :=
          g_schedule[i_blocked_unit].Stages[si].CalcTime - REAL_TO_DINT(walk_amount);
        g_schedule[i_blocked_unit].Stages[si].ExitTime :=
          g_schedule[i_blocked_unit].Stages[si].ExitTime - REAL_TO_LINT(walk_amount);
        fb_shift(i_unit := i_blocked_unit, i_from_stage := si + 1, i_amount := -walk_amount);

        (* GAP-2: Persist to g_program so next CalcSchedule cycle sees the change *)
        IF si >= 1 THEN
          g_program[i_blocked_unit].Steps[si - 1].CalTime :=
            g_schedule[i_blocked_unit].Stages[si].CalcTime;
        END_IF;

        walk_remain := walk_remain - walk_amount;
        o_total_adv := o_total_adv + walk_amount;
      END_IF;
    END_IF;
  END_FOR;

  remain := remain - o_total_adv;

  (* Record lock: ADVANCE on blocked stage *)
  IF io_lock_cnt < 50 THEN
    io_lock_cnt := io_lock_cnt + 1;
    io_locks[io_lock_cnt].Unit := i_blocked_unit;
    io_locks[io_lock_cnt].Stage := i_blocked_stage;
    io_locks[io_lock_cnt].Direction := 1;  (* 1=ADVANCE *)
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
  sc := g_schedule[i_conf_unit].StageCount;

  FOR si := i_conf_stage TO 1 BY -1 DO
    IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
      walk_flex := DINT_TO_REAL(g_schedule[i_conf_unit].Stages[si].MaxTime
                  - g_schedule[i_conf_unit].Stages[si].CalcTime);
      IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;

      IF walk_flex > 0.1 THEN
        IF g_batch[i_conf_unit].CurStage = si THEN
          walk_cap := 0.9;
        ELSE
          walk_cap := 0.5;
        END_IF;
        walk_amount := walk_flex * walk_cap;
        IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;

        g_schedule[i_conf_unit].Stages[si].CalcTime :=
          g_schedule[i_conf_unit].Stages[si].CalcTime + REAL_TO_DINT(walk_amount);
        g_schedule[i_conf_unit].Stages[si].ExitTime :=
          g_schedule[i_conf_unit].Stages[si].ExitTime + REAL_TO_LINT(walk_amount);
        fb_shift(i_unit := i_conf_unit, i_from_stage := si + 1, i_amount := walk_amount);

        (* GAP-2: Persist to g_program so next CalcSchedule cycle sees the change *)
        IF si >= 1 THEN
          g_program[i_conf_unit].Steps[si - 1].CalTime :=
            g_schedule[i_conf_unit].Stages[si].CalcTime;
        END_IF;

        walk_remain := walk_remain - walk_amount;
        o_total_delay := o_total_delay + walk_amount;
      END_IF;
    END_IF;
  END_FOR;

  remain := remain - o_total_delay;

  (* Record lock: DELAY on conf stage *)
  IF io_lock_cnt < 50 THEN
    io_lock_cnt := io_lock_cnt + 1;
    io_locks[io_lock_cnt].Unit := i_conf_unit;
    io_locks[io_lock_cnt].Stage := i_conf_stage;
    io_locks[io_lock_cnt].Direction := 2;  (* 2=DELAY *)
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
    sc := g_schedule[i_blocked_unit].StageCount;
    FOR si := i_blocked_stage TO 1 BY -1 DO
      IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
        walk_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].Stages[si].CalcTime
                  - g_schedule[i_blocked_unit].Stages[si].MinTime);
        IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;
        IF walk_flex > 0.1 THEN
          IF g_batch[i_blocked_unit].CurStage = si THEN walk_cap := 0.9; ELSE walk_cap := 0.5; END_IF;
          walk_amount := walk_flex * walk_cap;
          IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;
          g_schedule[i_blocked_unit].Stages[si].CalcTime :=
          g_schedule[i_blocked_unit].Stages[si].CalcTime - REAL_TO_DINT(walk_amount);
          g_schedule[i_blocked_unit].Stages[si].ExitTime :=
            g_schedule[i_blocked_unit].Stages[si].ExitTime - REAL_TO_LINT(walk_amount);
          fb_shift(i_unit := i_blocked_unit, i_from_stage := si + 1, i_amount := -walk_amount);
          (* GAP-2: Persist to g_program *)
          IF si >= 1 THEN
            g_program[i_blocked_unit].Steps[si - 1].CalTime :=
              g_schedule[i_blocked_unit].Stages[si].CalcTime;
          END_IF;
          walk_remain := walk_remain - walk_amount;
          o_total_adv := o_total_adv + walk_amount;
        END_IF;
      END_IF;
    END_FOR;

    IF io_lock_cnt < 50 THEN
      io_lock_cnt := io_lock_cnt + 1;
      io_locks[io_lock_cnt].Unit := i_blocked_unit;
      io_locks[io_lock_cnt].Stage := i_blocked_stage;
      io_locks[io_lock_cnt].Direction := 1;
    END_IF;
  END_IF;

  (* Apply DELAY portion *)
  IF can_delay AND use_del > 0.1 THEN
    walk_remain := use_del;
    sc := g_schedule[i_conf_unit].StageCount;
    FOR si := i_conf_stage TO 1 BY -1 DO
      IF si >= 1 AND si <= sc AND walk_remain > 0.1 THEN
        walk_flex := DINT_TO_REAL(g_schedule[i_conf_unit].Stages[si].MaxTime
                  - g_schedule[i_conf_unit].Stages[si].CalcTime);
        IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;
        IF walk_flex > 0.1 THEN
          IF g_batch[i_conf_unit].CurStage = si THEN walk_cap := 0.9; ELSE walk_cap := 0.5; END_IF;
          walk_amount := walk_flex * walk_cap;
          IF walk_amount > walk_remain THEN walk_amount := walk_remain; END_IF;
          g_schedule[i_conf_unit].Stages[si].CalcTime :=
          g_schedule[i_conf_unit].Stages[si].CalcTime + REAL_TO_DINT(walk_amount);
          g_schedule[i_conf_unit].Stages[si].ExitTime :=
            g_schedule[i_conf_unit].Stages[si].ExitTime + REAL_TO_LINT(walk_amount);
          fb_shift(i_unit := i_conf_unit, i_from_stage := si + 1, i_amount := walk_amount);
          (* GAP-2: Persist to g_program *)
          IF si >= 1 THEN
            g_program[i_conf_unit].Steps[si - 1].CalTime :=
              g_schedule[i_conf_unit].Stages[si].CalcTime;
          END_IF;
          walk_remain := walk_remain - walk_amount;
          o_total_delay := o_total_delay + walk_amount;
        END_IF;
      END_IF;
    END_FOR;

    IF io_lock_cnt < 50 THEN
      io_lock_cnt := io_lock_cnt + 1;
      io_locks[io_lock_cnt].Unit := i_conf_unit;
      io_locks[io_lock_cnt].Stage := i_conf_stage;
      io_locks[io_lock_cnt].Direction := 2;
    END_IF;
  END_IF;

  remain := remain - o_total_adv - o_total_delay;
  IF remain <= 0.1 THEN
    o_solved := TRUE;
    RETURN;
  END_IF;
END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PRIORITY 4: PRECEDING_DELAY — delay conf batch at stage-1    *)
(* (GAP-8 / JS Phase 3)                                        *)
(* Delay the conf batch's PREVIOUS stage to push everything     *)
(* ══════════════════════════════════════════════════════════════ *)
prev_conf_stage := i_conf_stage - 1;
IF remain > 0.1 AND prev_conf_stage >= 1 AND i_conf_unit >= 1 AND i_conf_unit <= MAX_Units THEN
  (* Check lock: is prev_conf_stage locked ADVANCE? → cannot DELAY *)
  is_pcs_locked := FALSE;
  FOR lock_i := 1 TO io_lock_cnt DO
    IF io_locks[lock_i].Unit = i_conf_unit
       AND io_locks[lock_i].Stage = prev_conf_stage
       AND io_locks[lock_i].Direction = 1 THEN
      is_pcs_locked := TRUE;
    END_IF;
  END_FOR;

  IF NOT is_pcs_locked THEN
    walk_flex := DINT_TO_REAL(g_schedule[i_conf_unit].Stages[prev_conf_stage].MaxTime
                - g_schedule[i_conf_unit].Stages[prev_conf_stage].CalcTime);
    IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;

    IF walk_flex > 0.1 THEN
      IF g_batch[i_conf_unit].CurStage = prev_conf_stage THEN
        walk_cap := 0.9;
      ELSE
        walk_cap := 0.5;
      END_IF;
      walk_amount := walk_flex * walk_cap;
      IF walk_amount > remain THEN walk_amount := remain; END_IF;

      g_schedule[i_conf_unit].Stages[prev_conf_stage].CalcTime :=
        g_schedule[i_conf_unit].Stages[prev_conf_stage].CalcTime + REAL_TO_DINT(walk_amount);
      g_schedule[i_conf_unit].Stages[prev_conf_stage].ExitTime :=
        g_schedule[i_conf_unit].Stages[prev_conf_stage].ExitTime + REAL_TO_LINT(walk_amount);
      fb_shift(i_unit := i_conf_unit, i_from_stage := prev_conf_stage + 1, i_amount := walk_amount);

      (* GAP-2: Persist to g_program *)
      IF prev_conf_stage >= 1 THEN
        g_program[i_conf_unit].Steps[prev_conf_stage - 1].CalTime :=
          g_schedule[i_conf_unit].Stages[prev_conf_stage].CalcTime;
      END_IF;

      remain := remain - walk_amount;
      o_total_delay := o_total_delay + walk_amount;

      (* Record lock *)
      IF io_lock_cnt < 50 THEN
        io_lock_cnt := io_lock_cnt + 1;
        io_locks[io_lock_cnt].Unit := i_conf_unit;
        io_locks[io_lock_cnt].Stage := prev_conf_stage;
        io_locks[io_lock_cnt].Direction := 2;
      END_IF;

      IF remain <= 0.1 THEN
        o_solved := TRUE;
        RETURN;
      END_IF;
    END_IF;
  END_IF;
END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PRIORITY 5: DELAY_PREV_PAST_NEXT — delay blocked batch to    *)
(* force order swap (GAP-8 / JS Phase 4)                        *)
(* Only if NOT swappable: prev.sink ≠ next.lift                 *)
(* ══════════════════════════════════════════════════════════════ *)
IF remain > 0.1 AND i_blocked_unit >= 1 AND i_blocked_unit <= MAX_Units THEN
  (* Find blocked and conf tasks in queue to check swap condition *)
  prev_sink_stn := 0;
  next_lift_stn := 0;
  IF i_conf_trans >= 1 AND i_conf_trans <= MAX_Transporters THEN
    FOR qi := 1 TO g_task[i_conf_trans].Count DO
      IF g_task[i_conf_trans].Queue[qi].Unit = i_blocked_unit
         AND g_task[i_conf_trans].Queue[qi].Stage = i_blocked_stage THEN
        prev_sink_stn := g_task[i_conf_trans].Queue[qi].SinkStationTarget;
      END_IF;
      IF g_task[i_conf_trans].Queue[qi].Unit = i_conf_unit
         AND g_task[i_conf_trans].Queue[qi].Stage = i_conf_stage THEN
        next_lift_stn := g_task[i_conf_trans].Queue[qi].LiftStationTarget;
      END_IF;
    END_FOR;
  END_IF;

  (* Swap check: if prev.sink = next.lift → swappable, skip *)
  IF NOT (prev_sink_stn > 0 AND next_lift_stn > 0 AND prev_sink_stn = next_lift_stn) THEN
    (* Check lock: is blocked stage locked ADVANCE? → cannot DELAY *)
    is_blk_adv_locked := FALSE;
    FOR lock_i := 1 TO io_lock_cnt DO
      IF io_locks[lock_i].Unit = i_blocked_unit
         AND io_locks[lock_i].Stage = i_blocked_stage
         AND io_locks[lock_i].Direction = 1 THEN
        is_blk_adv_locked := TRUE;
      END_IF;
    END_FOR;

    IF NOT is_blk_adv_locked THEN
      walk_flex := DINT_TO_REAL(g_schedule[i_blocked_unit].Stages[i_blocked_stage].MaxTime
                  - g_schedule[i_blocked_unit].Stages[i_blocked_stage].CalcTime);
      IF walk_flex < 0.0 THEN walk_flex := 0.0; END_IF;

      IF walk_flex > 0.1 THEN
        IF g_batch[i_blocked_unit].CurStage = i_blocked_stage THEN
          walk_cap := 0.9;
        ELSE
          walk_cap := 0.5;
        END_IF;
        walk_amount := walk_flex * walk_cap;
        IF walk_amount > remain THEN walk_amount := remain; END_IF;

        g_schedule[i_blocked_unit].Stages[i_blocked_stage].CalcTime :=
          g_schedule[i_blocked_unit].Stages[i_blocked_stage].CalcTime + REAL_TO_DINT(walk_amount);
        g_schedule[i_blocked_unit].Stages[i_blocked_stage].ExitTime :=
          g_schedule[i_blocked_unit].Stages[i_blocked_stage].ExitTime + REAL_TO_LINT(walk_amount);
        fb_shift(i_unit := i_blocked_unit, i_from_stage := i_blocked_stage + 1, i_amount := walk_amount);

        (* GAP-2: Persist to g_program *)
        IF i_blocked_stage >= 1 THEN
          g_program[i_blocked_unit].Steps[i_blocked_stage - 1].CalTime :=
            g_schedule[i_blocked_unit].Stages[i_blocked_stage].CalcTime;
        END_IF;

        remain := remain - walk_amount;
        o_total_delay := o_total_delay + walk_amount;

        (* Record lock: DELAY on blocked stage *)
        IF io_lock_cnt < 50 THEN
          io_lock_cnt := io_lock_cnt + 1;
          io_locks[io_lock_cnt].Unit := i_blocked_unit;
          io_locks[io_lock_cnt].Stage := i_blocked_stage;
          io_locks[io_lock_cnt].Direction := 2;
        END_IF;

        IF remain <= 0.1 THEN
          o_solved := TRUE;
          RETURN;
        END_IF;
      END_IF;
    END_IF;
  END_IF;
END_IF;

(* If not solved, partial resolution was applied *)

END_FUNCTION_BLOCK
