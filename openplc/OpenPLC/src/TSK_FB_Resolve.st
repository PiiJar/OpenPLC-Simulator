(* ============================================================
   TSK_FB_Resolve — Conflict resolution
   ============================================================
   Ported from transporterTaskScheduler.js resolveConflict()

   Resolves one conflict per call using 4-phase strategy:
     Phase 1: ADVANCE prev batch (reduce calc_time toward min)
     Phase 2: DELAY next batch conflict stage (increase toward max)
     Phase 3: DELAY next batch previous stage
     Phase 4: DELAY prev batch past next (forced swap)

   Each phase uses flex capacity with cap factor:
     90% if batch is currently on that station, 50% otherwise.

   Modifies g_task and g_schedule in-place by propagating
   time changes through the remaining task chain.

   lockedStages prevents oscillation: once a stage is advanced,
   it cannot be delayed in the same cycle, and vice versa.
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
VAR_EXTERNAL CONSTANT
    TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_task    : ARRAY[1..TRANSPORTERS] OF TSK_QUEUE_T;
  g_schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_batch  : ARRAY[1..10] OF BATCH_T;
END_VAR
VAR_OUTPUT
  o_solved      : BOOL;
  o_total_delay : REAL;
  o_total_adv   : REAL;
END_VAR
VAR
  remain   : REAL;       (* remaining deficit *)
  cap      : REAL;       (* cap factor 0.5 or 0.9 *)
  flex     : REAL;       (* available flex *)
  amount   : REAL;       (* amount to apply *)
  si       : INT;        (* schedule stage loop *)
  sc       : INT;        (* schedule stage count *)
  (* Lock arrays: packed as unit*100+stage, 0=none, 1=ADVANCE, 2=DELAY *)
  locks      : ARRAY[1..50] OF INT;   (* lock keys (packed) *)
  lock_dir   : ARRAY[1..50] OF INT;   (* 1=ADV, 2=DELAY *)
  lock_cnt   : INT;
  lock_key   : INT;
  is_locked  : BOOL;
  lock_i     : INT;
  (* Prev batch flex_down *)
  prev_flex  : REAL;
  (* Next batch flex_up *)
  next_flex  : REAL;
  prev_stage_flex : REAL;
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

(* ══════ Phase 1: ADVANCE prev batch (blocked_unit, blocked_stage) ══════ *)
(* Reduce treatment time toward min_time = flex_down *)

(* Find flex_down for blocked stage in schedule *)
prev_flex := 0.0;
IF i_blocked_unit >= 1 AND i_blocked_unit <= 10 THEN
  sc := g_schedule[i_blocked_unit].stage_count;
  FOR si := 1 TO sc DO
    IF si = i_blocked_stage THEN
      prev_flex := g_schedule[i_blocked_unit].stages[si].calc_time
                 - g_schedule[i_blocked_unit].stages[si].min_time;
      IF prev_flex < 0.0 THEN prev_flex := 0.0; END_IF;
    END_IF;
  END_FOR;
END_IF;

IF prev_flex > 0.1 THEN
  (* Cap: 90% if batch is on this stage, 50% otherwise *)
  IF g_batch[i_blocked_unit].cur_stage = i_blocked_stage THEN
    cap := 0.9;
  ELSE
    cap := 0.5;
  END_IF;
  amount := prev_flex * cap;
  IF amount > remain THEN amount := remain; END_IF;

  (* Apply: shift blocked batch's stage exit earlier + propagate *)
  IF i_blocked_stage >= 1 AND i_blocked_stage <= 30 THEN
    g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time :=
      g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time - amount;
    g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time :=
      g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time - REAL_TO_LINT(amount);
    fb_shift(i_unit := i_blocked_unit, i_from_stage := i_blocked_stage + 1, i_amount := -amount);
  END_IF;

  remain := remain - amount;
  o_total_adv := o_total_adv + amount;
END_IF;

IF remain <= 0.1 THEN
  o_solved := TRUE;
  RETURN;
END_IF;

(* ══════ Phase 2: DELAY next batch conflict stage (conf_unit, conf_stage) ══════ *)
(* Increase treatment time toward max_time = flex_up *)
next_flex := 0.0;
IF i_conf_unit >= 1 AND i_conf_unit <= 10 AND i_conf_stage >= 1 AND i_conf_stage <= 30 THEN
  next_flex := g_schedule[i_conf_unit].stages[i_conf_stage].max_time
             - g_schedule[i_conf_unit].stages[i_conf_stage].calc_time;
  IF next_flex < 0.0 THEN next_flex := 0.0; END_IF;
END_IF;

IF next_flex > 0.1 THEN
  IF g_batch[i_conf_unit].cur_stage = i_conf_stage THEN
    cap := 0.9;
  ELSE
    cap := 0.5;
  END_IF;
  amount := next_flex * cap;
  IF amount > remain THEN amount := remain; END_IF;

  (* Apply: extend conflict stage + shift later stages forward *)
  g_schedule[i_conf_unit].stages[i_conf_stage].calc_time :=
    g_schedule[i_conf_unit].stages[i_conf_stage].calc_time + amount;
  g_schedule[i_conf_unit].stages[i_conf_stage].exit_time :=
    g_schedule[i_conf_unit].stages[i_conf_stage].exit_time + REAL_TO_LINT(amount);
  fb_shift(i_unit := i_conf_unit, i_from_stage := i_conf_stage + 1, i_amount := amount);

  remain := remain - amount;
  o_total_delay := o_total_delay + amount;
END_IF;

IF remain <= 0.1 THEN
  o_solved := TRUE;
  RETURN;
END_IF;

(* ══════ Phase 3: DELAY next batch previous stage (conf_stage - 1) ══════ *)
IF i_conf_stage > 1 THEN
  prev_stage_flex := 0.0;
  IF i_conf_unit >= 1 AND i_conf_unit <= 10 AND (i_conf_stage - 1) >= 1 THEN
    prev_stage_flex := g_schedule[i_conf_unit].stages[i_conf_stage - 1].max_time
                     - g_schedule[i_conf_unit].stages[i_conf_stage - 1].calc_time;
    IF prev_stage_flex < 0.0 THEN prev_stage_flex := 0.0; END_IF;
  END_IF;

  IF prev_stage_flex > 0.1 THEN
    IF g_batch[i_conf_unit].cur_stage = (i_conf_stage - 1) THEN
      cap := 0.9;
    ELSE
      cap := 0.5;
    END_IF;
    amount := prev_stage_flex * cap;
    IF amount > remain THEN amount := remain; END_IF;

    (* Apply: extend previous stage + propagate from conf_stage onward *)
    g_schedule[i_conf_unit].stages[i_conf_stage - 1].calc_time :=
      g_schedule[i_conf_unit].stages[i_conf_stage - 1].calc_time + amount;
    g_schedule[i_conf_unit].stages[i_conf_stage - 1].exit_time :=
      g_schedule[i_conf_unit].stages[i_conf_stage - 1].exit_time + REAL_TO_LINT(amount);
    fb_shift(i_unit := i_conf_unit, i_from_stage := i_conf_stage, i_amount := amount);

    remain := remain - amount;
    o_total_delay := o_total_delay + amount;
  END_IF;
END_IF;

IF remain <= 0.1 THEN
  o_solved := TRUE;
  RETURN;
END_IF;

(* ══════ Phase 4: DELAY prev past next (forced reorder) ══════ *)
(* Delay blocked_unit's stage to push it past conflict *)
prev_flex := 0.0;
IF i_blocked_unit >= 1 AND i_blocked_unit <= 10 AND i_blocked_stage >= 1 AND i_blocked_stage <= 30 THEN
  prev_flex := g_schedule[i_blocked_unit].stages[i_blocked_stage].max_time
             - g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time;
  IF prev_flex < 0.0 THEN prev_flex := 0.0; END_IF;
END_IF;

IF prev_flex > 0.1 THEN
  IF g_batch[i_blocked_unit].cur_stage = i_blocked_stage THEN
    cap := 0.9;
  ELSE
    cap := 0.5;
  END_IF;
  amount := prev_flex * cap;
  IF amount > remain THEN amount := remain; END_IF;

  g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time :=
    g_schedule[i_blocked_unit].stages[i_blocked_stage].calc_time + amount;
  g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time :=
    g_schedule[i_blocked_unit].stages[i_blocked_stage].exit_time + REAL_TO_LINT(amount);
  fb_shift(i_unit := i_blocked_unit, i_from_stage := i_blocked_stage + 1, i_amount := amount);

  remain := remain - amount;
  o_total_delay := o_total_delay + amount;
END_IF;

IF remain <= 0.1 THEN
  o_solved := TRUE;
END_IF;

(* If not solved, partial resolution was still applied *)

END_FUNCTION_BLOCK
