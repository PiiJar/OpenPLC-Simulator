(* ============================================================
   STC_FB_ShiftSchedule — Shift schedule + task times
   ============================================================
   Propagates a time shift through one unit's schedule stages
   AND through all matching tasks in the 3 transporter queues.

   Positive i_amount = DELAY (shift later),
   Negative i_amount = ADVANCE (shift earlier).

   Replaces 4× duplicated propagation code in TSK_FB_Resolve.
   ============================================================ *)

FUNCTION_BLOCK STC_FB_ShiftSchedule
VAR_INPUT
  i_unit       : INT;     (* unit index 1..10 *)
  i_from_stage : INT;     (* propagate from this stage onward *)
  i_amount     : REAL;    (* seconds to shift (+ = later, - = earlier) *)
END_VAR
VAR_EXTERNAL CONSTANT
    TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_tasks    : ARRAY[1..TRANSPORTERS] OF TSK_QUEUE_T;
END_VAR
VAR
  sc : INT;
  si : INT;
  qi : INT;
  ti : INT;
END_VAR

IF i_unit < 1 OR i_unit > 10 THEN RETURN; END_IF;
IF ABS(i_amount) < 0.001 THEN RETURN; END_IF;

(* ── Shift schedule stages entry/exit times ── *)
sc := g_schedule[i_unit].stage_count;
FOR si := i_from_stage TO sc DO
  IF si >= 1 AND si <= 30 THEN
    g_schedule[i_unit].stages[si].entry_time :=
      g_schedule[i_unit].stages[si].entry_time + REAL_TO_LINT(i_amount);
    g_schedule[i_unit].stages[si].exit_time :=
      g_schedule[i_unit].stages[si].exit_time + REAL_TO_LINT(i_amount);
  END_IF;
END_FOR;

(* ── Shift matching tasks in all transporter queues ── *)
FOR ti := 1 TO TRANSPORTERS DO
  FOR qi := 1 TO g_tasks[ti].count DO
    IF g_tasks[ti].queue[qi].unit = i_unit
       AND g_tasks[ti].queue[qi].stage >= i_from_stage THEN
      g_tasks[ti].queue[qi].start_time :=
        g_tasks[ti].queue[qi].start_time + REAL_TO_LINT(i_amount);
      g_tasks[ti].queue[qi].finish_time :=
        g_tasks[ti].queue[qi].finish_time + REAL_TO_LINT(i_amount);
    END_IF;
  END_FOR;
END_FOR;

END_FUNCTION_BLOCK
