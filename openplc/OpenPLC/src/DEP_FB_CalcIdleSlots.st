(* ============================================================
   DEP_FB_CalcIdleSlots — Idle slot calculation per transporter
   ============================================================
   Calculates time windows where a transporter has no tasks.
   Each gap between consecutive tasks (or before the first /
   after the last task) is an idle slot.

   Source: transporterTaskScheduler.js calculateTransporterIdleSlots()

   Expects g_task[i_trans].queue to be already sorted by start_time
   (TSK_FB_Scheduler TASKS_SORT phase ensures this).

   Used by: DEP_FB_Scheduler (CHECK_ANALYZE phase)
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_CalcIdleSlots
VAR_INPUT
  i_trans  : INT;      (* transporter index 1..3 *)
  i_time_s : LINT;     (* current simulation time (s), unix seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS   : INT;
    MAX_UNITS          : INT;
    DEP_MAX_IDLE_SLOTS : INT;
END_VAR

VAR_EXTERNAL
  g_task          : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  g_dep_idle_slot : ARRAY[1..MAX_TRANSPORTERS] OF DEP_IDLE_SLOT_SET_T;
  g_transporter   : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
END_VAR
VAR
  qi       : INT;      (* queue index *)
  si       : INT;      (* slot index *)
  cnt      : INT;      (* task count for this transporter *)
  prev_end : LINT;     (* end time of previous task *)
  prev_sink : INT;     (* sink station of previous task *)
  gap_start : LINT;
  gap_end   : LINT;
  HORIZON  : LINT := 1000000000;   (* open-ended future *)
END_VAR

(* Guard *)
IF i_trans < 1 OR i_trans > MAX_TRANSPORTERS THEN
  RETURN;
END_IF;

(* Reset output *)
g_dep_idle_slot[i_trans].count := 0;
si := 0;
cnt := g_task[i_trans].count;

prev_end  := i_time_s;
(* G05: Use transporter's current station as first-slot anchor *)
prev_sink := g_transporter[i_trans].current_station;

FOR qi := 1 TO MAX_UNITS DO
  IF qi > cnt THEN
    EXIT;
  END_IF;

  gap_start := prev_end;
  gap_end   := g_task[i_trans].queue[qi].start_time;

  (* Only create slot if there is a meaningful gap *)
  IF gap_end > gap_start + LINT#1 THEN
    si := si + 1;
    IF si <= DEP_MAX_IDLE_SLOTS THEN
      g_dep_idle_slot[i_trans].slots[si].start_time   := gap_start;
      g_dep_idle_slot[i_trans].slots[si].end_time     := gap_end;
      g_dep_idle_slot[i_trans].slots[si].lift_station := prev_sink;
      g_dep_idle_slot[i_trans].slots[si].sink_station := g_task[i_trans].queue[qi].lift_station;
    END_IF;
  END_IF;

  prev_end  := g_task[i_trans].queue[qi].finish_time;
  prev_sink := g_task[i_trans].queue[qi].sink_station;
END_FOR;

(* Final slot: after last task → open-ended *)
si := si + 1;
IF si <= DEP_MAX_IDLE_SLOTS THEN
  g_dep_idle_slot[i_trans].slots[si].start_time   := prev_end;
  g_dep_idle_slot[i_trans].slots[si].end_time     := HORIZON;
  g_dep_idle_slot[i_trans].slots[si].lift_station := prev_sink;
  g_dep_idle_slot[i_trans].slots[si].sink_station := 0;
END_IF;

g_dep_idle_slot[i_trans].count := si;

END_FUNCTION_BLOCK
