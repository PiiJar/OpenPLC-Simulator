(* ============================================================
   DEP_FB_FitTaskToSlot — Fit a departure task into idle slots
   ============================================================
   Tries to fit a single waiting-batch task into the idle slots
   of its assigned transporter.  Calculates travel times from
   the previous task's sink to this task's lift, and from this
   task's sink to the next task's lift.

   Source: transporterTaskScheduler.js fitSingleTaskToIdleSlots()

   Flex constraint: delay cannot exceed flex_up × flexUpFactor.
   If no slot fits, o_need_extra_s reports the shortfall for
   backward chaining.

   Used by: DEP_FB_Scheduler (CHECK_ANALYZE phase)
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_FitTaskToSlot
VAR_INPUT
  i_lift_stn     : INT;     (* task lift station *)
  i_sink_stn     : INT;     (* task sink station *)
  i_trans_id     : INT;     (* transporter for this task *)
  i_task_start   : LINT;    (* scheduled task start time (s), unix seconds *)
  i_task_end     : LINT;    (* scheduled task end time (s), unix seconds *)
  i_shift_s      : REAL;    (* pre-applied shift (overlap delay) *)
  i_calc_time_s  : REAL;    (* treatment calc_time (s) *)
  i_max_time_s   : REAL;    (* treatment max_time (s) *)
  i_flex_factor  : REAL;    (* flex_up usage factor, e.g. 0.5 *)
  i_margin_s     : REAL;    (* minimum margin between tasks (s) *)
END_VAR
VAR_OUTPUT
  o_result : DEP_FIT_RESULT_T;
END_VAR
VAR_EXTERNAL
  g_dep_idle_slots : ARRAY[1..3] OF DEP_IDLE_SLOT_SET_T;
END_VAR
VAR
  fb_travel_to   : STC_FB_CalcHorizontalTravel;
  fb_travel_from : STC_FB_CalcHorizontalTravel;
  si          : INT;
  slot_cnt    : INT;
  slot_start  : LINT;
  slot_end    : LINT;
  from_stn    : INT;    (* previous task's sink or transporter home *)
  to_stn      : INT;    (* next task's lift *)
  travel_to   : REAL;   (* travel time: prev_sink → this lift *)
  travel_from : REAL;   (* travel time: this sink → next_lift *)
  earliest    : LINT;
  latest      : LINT;
  task_dur    : LINT;
  delay       : REAL;
  flex_up     : REAL;
  capped_flex : REAL;
  best_delay  : REAL;
  best_slot   : INT;
  found       : BOOL;
END_VAR

(* Initialize output *)
o_result.fits         := FALSE;
o_result.delay_s      := 0.0;
o_result.need_extra_s := 0.0;
o_result.task_end_s   := 0;
o_result.slot_idx     := 0;
o_result.trans_id     := i_trans_id;

IF i_trans_id < 1 OR i_trans_id > 3 THEN
  RETURN;
END_IF;

task_dur   := i_task_end - i_task_start;
flex_up    := i_max_time_s - i_calc_time_s;
IF flex_up < 0.0 THEN flex_up := 0.0; END_IF;
capped_flex := flex_up * i_flex_factor;

slot_cnt   := g_dep_idle_slots[i_trans_id].count;
best_delay := 1.0E9;
best_slot  := 0;
found      := FALSE;

FOR si := 1 TO 20 DO
  IF si > slot_cnt THEN
    EXIT;
  END_IF;

  slot_start := g_dep_idle_slots[i_trans_id].slots[si].start_time;
  slot_end   := g_dep_idle_slots[i_trans_id].slots[si].end_time;

  (* ── Travel time: prev task sink → this lift ── *)
  from_stn := g_dep_idle_slots[i_trans_id].slots[si].lift_station;
  travel_to := 0.0;
  IF from_stn > 0 AND from_stn <> i_lift_stn THEN
    fb_travel_to(i_from_stn := from_stn, i_to_stn := i_lift_stn, i_trans := i_trans_id);
    travel_to := fb_travel_to.o_travel_s;
  END_IF;

  (* ── Travel time: this sink → next task lift ── *)
  to_stn := g_dep_idle_slots[i_trans_id].slots[si].sink_station;
  travel_from := 0.0;
  IF to_stn > 0 AND to_stn <> i_sink_stn THEN
    fb_travel_from(i_from_stn := i_sink_stn, i_to_stn := to_stn, i_trans := i_trans_id);
    travel_from := fb_travel_from.o_travel_s;
  END_IF;

  (* Earliest start = max(slot_start, task_start + shift) + travel_to + margin *)
  IF slot_start > (i_task_start + REAL_TO_LINT(i_shift_s)) THEN
    earliest := slot_start + REAL_TO_LINT(travel_to + i_margin_s);
  ELSE
    earliest := i_task_start + REAL_TO_LINT(i_shift_s + travel_to + i_margin_s);
  END_IF;

  (* Latest end = slot_end - travel_from - margin *)
  IF slot_end > LINT#100000000 THEN
    (* Open-ended slot *)
    latest := LINT#100000000;
  ELSE
    latest := slot_end - REAL_TO_LINT(travel_from + i_margin_s);
  END_IF;

  (* Check if task fits *)
  IF earliest + task_dur <= latest THEN
    delay := LINT_TO_REAL(earliest - i_task_start) - i_shift_s;
    IF delay < 0.0 THEN delay := 0.0; END_IF;

    (* Flex constraint: delay must not exceed capped flex *)
    IF delay <= capped_flex + i_margin_s THEN
      IF delay < best_delay THEN
        best_delay := delay;
        best_slot  := si;
        found      := TRUE;
      END_IF;
    END_IF;
  END_IF;
END_FOR;

IF found THEN
  o_result.fits      := TRUE;
  o_result.delay_s   := best_delay;
  o_result.slot_idx  := best_slot;
  o_result.task_end_s := i_task_start + REAL_TO_LINT(i_shift_s + best_delay) + task_dur;
  o_result.need_extra_s := 0.0;
ELSE
  (* Report how much extra is needed for backward chaining *)
  (* Use the best near-miss: smallest overshoot beyond capped_flex *)
  o_result.fits := FALSE;
  IF best_delay < 1.0E8 THEN
    o_result.need_extra_s := best_delay - capped_flex;
    IF o_result.need_extra_s < 0.0 THEN
      o_result.need_extra_s := 0.0;
    END_IF;
  ELSE
    o_result.need_extra_s := 0.0;  (* no slot at all *)
  END_IF;
END_IF;

END_FUNCTION_BLOCK
