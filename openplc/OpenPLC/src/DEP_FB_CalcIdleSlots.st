(* ============================================================
   DEP_FB_CalcIdleSlots — Idle slot calculation per transporter
   ============================================================
   Calculates time windows where a transporter has no tasks.
   Each gap between consecutive tasks (or before the first /
   after the last task) is an idle slot.

   Source: transporterTaskScheduler.js calculateTransporterIdleSlots()

   Expects g_tasks[i_trans].queue to be already sorted by start_time
   (TSK_FB_Scheduler TASKS_SORT phase ensures this).

   Used by: DEP_FB_Scheduler (CHECK_ANALYZE phase)
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_CalcIdleSlots
VAR_INPUT
  i_trans  : INT;      (* transporter index 1..3 *)
  i_time_s : REAL;     (* current simulation time (s) *)
END_VAR
VAR_EXTERNAL
  g_tasks          : ARRAY[1..3] OF TSK_QUEUE_T;
  g_dep_idle_slots : ARRAY[1..3] OF DEP_IDLE_SLOT_SET_T;
END_VAR
VAR
  qi       : INT;      (* queue index *)
  si       : INT;      (* slot index *)
  cnt      : INT;      (* task count for this transporter *)
  prev_end : REAL;     (* end time of previous task *)
  prev_sink : INT;     (* sink station of previous task *)
  gap_start : REAL;
  gap_end   : REAL;
  HORIZON  : REAL := 1.0E9;   (* open-ended future *)
END_VAR

(* Guard *)
IF i_trans < 1 OR i_trans > 3 THEN
  RETURN;
END_IF;

(* Reset output *)
g_dep_idle_slots[i_trans].count := 0;
si := 0;
cnt := g_tasks[i_trans].count;

prev_end  := i_time_s;
prev_sink := 0;

FOR qi := 1 TO 10 DO
  IF qi > cnt THEN
    EXIT;
  END_IF;

  gap_start := prev_end;
  gap_end   := g_tasks[i_trans].queue[qi].start_time;

  (* Only create slot if there is a meaningful gap *)
  IF gap_end > gap_start + 0.1 THEN
    si := si + 1;
    IF si <= 20 THEN
      g_dep_idle_slots[i_trans].slots[si].start_time   := gap_start;
      g_dep_idle_slots[i_trans].slots[si].end_time     := gap_end;
      g_dep_idle_slots[i_trans].slots[si].lift_station := prev_sink;
      g_dep_idle_slots[i_trans].slots[si].sink_station := g_tasks[i_trans].queue[qi].lift_station;
    END_IF;
  END_IF;

  prev_end  := g_tasks[i_trans].queue[qi].finish_time;
  prev_sink := g_tasks[i_trans].queue[qi].sink_station;
END_FOR;

(* Final slot: after last task → open-ended *)
si := si + 1;
IF si <= 20 THEN
  g_dep_idle_slots[i_trans].slots[si].start_time   := prev_end;
  g_dep_idle_slots[i_trans].slots[si].end_time     := HORIZON;
  g_dep_idle_slots[i_trans].slots[si].lift_station := prev_sink;
  g_dep_idle_slots[i_trans].slots[si].sink_station := 0;
END_IF;

g_dep_idle_slots[i_trans].count := si;

END_FUNCTION_BLOCK
