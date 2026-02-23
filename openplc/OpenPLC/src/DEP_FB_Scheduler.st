(* ============================================================
   DEP_FB_Scheduler — Departure scheduler state machine
   ============================================================
   Ported from departureScheduler.js tick()

   Controls batch activation: waiting batches (stage=90) are
   checked against idle slots to see if their tasks fit into
   the existing transporter schedule without conflicts.

   Uses the "wrapper approach": works directly on globals while
   TSK is paused at phase >= 10000. Sandbox is a backup for
   rollback on REJECT.

   Phase flow:
     0      STOPPED
     1      WAIT_STABLE       (wait for TSK phase >= 10000)
     100    INIT              (snapshot, find waiting batches)
     200    CALC_OVERLAP      (compute overlap stations)
     1000   BATCH_START       (prepare current waiting batch)
     1010   CALC_SCHED        (calculate waiting batch schedule)
     1020   REBUILD_TASKS     (rebuild all task queues, sort, swap)
     1030   EXTRACT_WAIT      (extract waiting batch tasks)
     1040   CALC_IDLE         (calculate idle slots)
     2000   FIT_STAGE0        (check pickup fits in idle slot)
     2001   FIT_TASK          (check stage 1+ tasks)
     3000   APPLY_DELAY       (record delay → recalc loop)
     8000   ACTIVATE          (commit, set pending)
     8010   WAIT_SAVE         (wait for TSK to process)
     8020   END_DELAY         (stabilization ticks)
     8100   RESTART           (→ WAIT_STABLE)
     9000   REJECT            (restore sandbox, try next batch)
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_Scheduler
VAR_INPUT
  i_run       : BOOL;     (* TRUE = run *)
  i_time_s    : LINT;     (* current absolute time (s), unix seconds *)
  i_tsk_phase : INT;      (* TSK_FB_Scheduler.o_phase *)
END_VAR
VAR_EXTERNAL
  g_batches          : ARRAY[1..10] OF BATCH_T;
  g_units            : ARRAY[1..10] OF UNIT_T;
  g_programs         : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  g_schedule         : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_tasks            : ARRAY[1..3] OF TSK_QUEUE_T;
  g_cfg              : ARRAY[1..3] OF TRANSPORTER_CFG_T;
  g_dep_sandbox      : DEP_SANDBOX_T;
  g_dep_idle_slots   : ARRAY[1..3] OF DEP_IDLE_SLOT_SET_T;
  g_dep_overlap      : DEP_OVERLAP_T;
  g_dep_pending      : DEP_PENDING_WRITE_T;
  g_dep_activated    : BOOL;
  g_dep_stable       : BOOL;
  g_dep_waiting      : ARRAY[1..10] OF INT;
  g_dep_waiting_count : INT;
END_VAR
VAR_OUTPUT
  o_phase     : INT;
  o_wait_cnt  : INT;      (* waiting batch count *)
  o_activated : BOOL;     (* batch activated this cycle *)
END_VAR
VAR
  phase       : INT := 0;
  next_phase  : INT;

  (* ── Waiting batch management ── *)
  waiting_list  : ARRAY[1..10] OF INT;  (* unit indices with stage=90 *)
  waiting_cnt   : INT;
  cur_wait_idx  : INT;
  cur_wait_unit : INT;

  (* ── Active batch list for rebuild ── *)
  batch_list    : ARRAY[1..10] OF INT;
  batch_count   : INT;

  (* ── Extracted waiting batch tasks ── *)
  w_tasks       : ARRAY[1..30] OF TSK_TASK_T;
  w_trans       : ARRAY[1..30] OF INT;    (* transporter id per task *)
  w_task_cnt    : INT;
  cur_task_idx  : INT;

  (* ── Fit state ── *)
  fit_round      : INT;
  MAX_FIT_ROUNDS : INT := 50;
  sched_base_time : LINT;        (* adjusted base time for waiting batch *)

  (* ── Delay recording ── *)
  delay_stage  : INT;
  delay_amount : REAL;
  delay_target : INT;            (* 0=batch/stage0, 1=program stage *)

  (* ── Constants ── *)
  FLEX_FACTOR       : REAL := 0.5;
  MARGIN_S          : REAL := 5.0;
  CONFLICT_MARGIN_S : REAL := 1.0;
  MAX_INIT_WAIT_S   : REAL := 120.0;
  END_DELAY_TICKS   : INT := 100;

  (* ── End delay counter ── *)
  end_delay_cnt : INT;

  (* ── Sub-FB instances ── *)
  fb_sandbox      : DEP_FB_Sandbox;
  fb_overlap      : DEP_FB_CalcOverlap;
  fb_idle_slots   : DEP_FB_CalcIdleSlots;
  fb_fit          : DEP_FB_FitTaskToSlot;
  fb_ovlp_delay   : DEP_FB_OverlapDelay;
  fb_calc_sched   : TSK_FB_CalcSchedule;
  fb_create_tasks : TSK_FB_CreateTasks;
  fb_swap_tasks   : TSK_FB_SwapTasks;
  fb_find_trans   : STC_FB_FindTransporter;
  fb_xfer         : STC_FB_CalcTransferTime;
  fb_clear        : STC_FB_ClearTaskQueues;
  fb_sort         : STC_FB_SortTaskQueue;
  fb_collect_all  : STC_FB_CollectActiveBatches;
  fb_collect_wait : STC_FB_CollectActiveBatches;

  (* ── Temp variables ── *)
  ti : INT;  qi : INT;  bi : INT;  ui : INT;  si : INT;
  sched_trans   : INT;
  write_idx     : INT;
  loading_stn   : INT;
  first_stn     : INT;
  xfer_dur      : REAL;
  stage0_delay  : REAL;
  ovlp_delay_s  : REAL;
  total_delay_s : REAL;
  prog_idx      : INT;
  old_cal       : INT;
  new_cal       : INT;
  max_cal       : INT;
END_VAR

IF NOT i_run THEN
  phase := 0;
  o_phase := 0;
  o_activated := FALSE;
  RETURN;
END_IF;

next_phase := phase;
o_activated := FALSE;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 0: STOPPED                                           *)
(* ════════════════════════════════════════════════════════════ *)
IF phase = 0 THEN
  next_phase := 1;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 1: WAIT_STABLE                                       *)
(* Wait for TSK to be ready (phase >= 10000)                   *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 1 THEN
  IF i_tsk_phase >= 10000 AND g_dep_stable THEN
    next_phase := 100;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 100: INIT — snapshot sandbox, find waiting batches    *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 100 THEN
  (* Snapshot globals → sandbox (backup for rollback) *)
  fb_sandbox(i_cmd := 1);

  (* Find waiting batches (cur_stage = 90) *)
  fb_collect_wait(i_mode := 1);
  waiting_cnt := fb_collect_wait.o_count;
  FOR ui := 1 TO waiting_cnt DO
    waiting_list[ui] := fb_collect_wait.o_list[ui];
  END_FOR;

  o_wait_cnt := waiting_cnt;
  g_dep_waiting_count := waiting_cnt;
  FOR ui := 1 TO waiting_cnt DO
    g_dep_waiting[ui] := waiting_list[ui];
  END_FOR;

  (* Build active batch list for rebuild phases *)
  fb_collect_all(i_mode := 0);
  batch_count := fb_collect_all.o_count;
  FOR ui := 1 TO batch_count DO
    batch_list[ui] := fb_collect_all.o_list[ui];
  END_FOR;

  IF waiting_cnt = 0 THEN
    (* No waiting batches → back to waiting *)
    fb_sandbox(i_cmd := 3);   (* clear sandbox *)
    next_phase := 1;
  ELSE
    cur_wait_idx := 1;
    next_phase := 200;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 200: CALC_OVERLAP — compute overlap stations          *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 200 THEN
  fb_overlap();
  next_phase := 1000;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 1000: BATCH_START — prepare current waiting batch     *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 1000 THEN
  IF cur_wait_idx > waiting_cnt THEN
    (* All batches processed, none activated → back to waiting *)
    fb_sandbox(i_cmd := 2);   (* restore globals from snapshot *)
    fb_sandbox(i_cmd := 3);   (* clear sandbox *)
    next_phase := 1;
  ELSE
    cur_wait_unit := waiting_list[cur_wait_idx];
    fit_round := 0;
    sched_base_time := i_time_s;
    next_phase := 1010;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 1010: CALC_SCHED — calculate waiting batch schedule   *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 1010 THEN
  (* Find transporter for this batch based on its location *)
  fb_find_trans(i_lift_stn := g_units[cur_wait_unit].location, i_sink_stn := 0);
  sched_trans := fb_find_trans.o_trans_id;
  IF sched_trans = 0 THEN sched_trans := 1; END_IF;

  (* Calculate schedule using (possibly shifted) base time *)
  fb_calc_sched(
    i_unit   := cur_wait_unit,
    i_trans  := sched_trans,
    i_time_s := sched_base_time
  );

  next_phase := 1020;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 1020: REBUILD_TASKS — rebuild all task queues         *)
(* Clear, create for all active batches, sort, swap — one tick *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 1020 THEN
  (* Clear all task queues *)
  fb_clear();

  (* Create tasks for ALL active batches *)
  FOR bi := 1 TO batch_count DO
    fb_create_tasks(i_unit := batch_list[bi]);
  END_FOR;

  (* Sort each queue by start_time *)
  fb_sort(i_trans := 0);

  (* Swap same-station pairs *)
  fb_swap_tasks();

  next_phase := 1030;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 1030: EXTRACT_WAIT — extract waiting batch tasks      *)
(* Copy waiting batch's tasks to w_tasks[], remove from queues *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 1030 THEN
  w_task_cnt := 0;

  FOR ti := 1 TO 3 DO
    write_idx := 0;
    FOR qi := 1 TO g_tasks[ti].count DO
      IF g_tasks[ti].queue[qi].unit = cur_wait_unit THEN
        (* Copy to waiting task array *)
        w_task_cnt := w_task_cnt + 1;
        IF w_task_cnt <= 30 THEN
          w_tasks[w_task_cnt] := g_tasks[ti].queue[qi];
          w_trans[w_task_cnt] := ti;
        END_IF;
      ELSE
        (* Keep in queue — shift down *)
        write_idx := write_idx + 1;
        IF write_idx <> qi THEN
          g_tasks[ti].queue[write_idx] := g_tasks[ti].queue[qi];
        END_IF;
      END_IF;
    END_FOR;
    (* Clear remaining slots *)
    FOR qi := write_idx + 1 TO g_tasks[ti].count DO
      g_tasks[ti].queue[qi].unit := 0;
    END_FOR;
    g_tasks[ti].count := write_idx;
  END_FOR;

  next_phase := 1040;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 1040: CALC_IDLE — calc idle slots for all transporters*)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 1040 THEN
  FOR ti := 1 TO 3 DO
    fb_idle_slots(i_trans := ti, i_time_s := i_time_s);
  END_FOR;
  cur_task_idx := 1;
  next_phase := 2000;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 2000: FIT_STAGE0 — check pickup from loading station *)
(* Uses DEP_FB_FitTaskToSlot to fit the virtual pickup task    *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 2000 THEN
  loading_stn := g_units[cur_wait_unit].location;

  (* Find first treatment station from schedule *)
  first_stn := 0;
  IF g_schedule[cur_wait_unit].stage_count >= 1 THEN
    first_stn := g_schedule[cur_wait_unit].stages[1].station;
  END_IF;

  IF first_stn = 0 OR loading_stn < 100 THEN
    (* No valid schedule or batch not on station → reject *)
    next_phase := 9000;
  ELSE
    (* Find transporter for pickup *)
    fb_find_trans(i_lift_stn := loading_stn, i_sink_stn := first_stn);
    sched_trans := fb_find_trans.o_trans_id;
    IF sched_trans = 0 THEN sched_trans := 1; END_IF;

    (* Calculate transfer time for pickup *)
    fb_xfer(i_from_stn := loading_stn, i_to_stn := first_stn, i_trans := sched_trans);
    xfer_dur := fb_xfer.o_total_s;
    IF xfer_dur < 1.0 THEN xfer_dur := 1.0; END_IF;

    (* Try fitting pickup into idle slots *)
    fb_fit(
      i_lift_stn     := loading_stn,
      i_sink_stn     := first_stn,
      i_trans_id     := sched_trans,
      i_task_start   := sched_base_time,
      i_task_end     := sched_base_time + REAL_TO_LINT(xfer_dur),
      i_shift_s      := 0.0,
      i_calc_time_s  := 0.0,
      i_max_time_s   := 2.0 * MAX_INIT_WAIT_S,
      i_flex_factor  := FLEX_FACTOR,
      i_margin_s     := MARGIN_S
    );

    IF fb_fit.o_result.fits THEN
      stage0_delay := fb_fit.o_result.delay_s;

      IF stage0_delay > MARGIN_S THEN
        (* Stage 0 needs delay — shift base time and recalculate *)
        sched_base_time := sched_base_time + REAL_TO_LINT(stage0_delay);
        fit_round := fit_round + 1;
        IF fit_round > MAX_FIT_ROUNDS THEN
          next_phase := 9000;
        ELSE
          (* Recalculate schedule with shifted base time *)
          next_phase := 1010;
        END_IF;
      ELSE
        (* Stage 0 fits → proceed to stage 1+ tasks *)
        IF w_task_cnt = 0 THEN
          next_phase := 8000;  (* No more tasks → ACTIVATE *)
        ELSE
          cur_task_idx := 1;
          next_phase := 2001;
        END_IF;
      END_IF;
    ELSE
      (* Stage 0 doesn't fit → REJECT this batch *)
      next_phase := 9000;
    END_IF;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 2001: FIT_TASK — fit stage 1+ tasks one per tick      *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 2001 THEN
  IF cur_task_idx > w_task_cnt THEN
    (* All tasks fit → ACTIVATE *)
    next_phase := 8000;
  ELSE
    (* Get current task data *)
    si := w_tasks[cur_task_idx].stage;
    ti := w_trans[cur_task_idx];

    (* Overlap delay check *)
    fb_ovlp_delay(
      i_lift_stn   := w_tasks[cur_task_idx].lift_station,
      i_sink_stn   := w_tasks[cur_task_idx].sink_station,
      i_trans_id   := ti,
      i_task_start := w_tasks[cur_task_idx].start_time,
      i_task_end   := w_tasks[cur_task_idx].finish_time,
      i_margin_s   := CONFLICT_MARGIN_S
    );
    ovlp_delay_s := fb_ovlp_delay.o_delay_s;

    (* Idle-slot fit check *)
    fb_fit(
      i_lift_stn     := w_tasks[cur_task_idx].lift_station,
      i_sink_stn     := w_tasks[cur_task_idx].sink_station,
      i_trans_id     := ti,
      i_task_start   := w_tasks[cur_task_idx].start_time,
      i_task_end     := w_tasks[cur_task_idx].finish_time,
      i_shift_s      := ovlp_delay_s,
      i_calc_time_s  := w_tasks[cur_task_idx].calc_time,
      i_max_time_s   := w_tasks[cur_task_idx].max_time,
      i_flex_factor  := FLEX_FACTOR,
      i_margin_s     := MARGIN_S
    );

    total_delay_s := ovlp_delay_s + fb_fit.o_result.delay_s;

    IF fb_fit.o_result.fits THEN
      IF total_delay_s <= MARGIN_S THEN
        (* Fits with negligible delay → next task *)
        cur_task_idx := cur_task_idx + 1;
        next_phase := 2001;
      ELSE
        (* Delay needed → record and recalculate *)
        delay_stage  := si;
        delay_amount := total_delay_s;
        delay_target := 1;   (* program stage *)
        next_phase   := 3000;
      END_IF;
    ELSE
      (* Does not fit → REJECT (simplified: no backward chaining) *)
      next_phase := 9000;
    END_IF;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 3000: APPLY_DELAY — write delay to program, recalc   *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 3000 THEN
  fit_round := fit_round + 1;
  IF fit_round > MAX_FIT_ROUNDS THEN
    next_phase := 9000;
  ELSE
    IF delay_target = 0 THEN
      (* Stage 0 delay: shift base time (handled in FIT_STAGE0, shouldn't reach here) *)
      sched_base_time := sched_base_time + REAL_TO_LINT(delay_amount);
    ELSIF delay_target = 1 THEN
      (* Program stage delay: increase cal_time *)
      prog_idx := delay_stage;
      IF prog_idx >= 1 AND prog_idx <= 30 THEN
        old_cal := g_programs[cur_wait_unit].stages[prog_idx].cal_time;
        max_cal := g_programs[cur_wait_unit].stages[prog_idx].max_time;
        new_cal := old_cal + REAL_TO_INT(delay_amount);
        IF new_cal > max_cal AND max_cal > 0 THEN
          new_cal := max_cal;
        END_IF;
        g_programs[cur_wait_unit].stages[prog_idx].cal_time := new_cal;
      END_IF;
    END_IF;
    (* Recalculate: schedule → tasks → idle → fit *)
    next_phase := 1010;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 8000: ACTIVATE — commit changes to pending write      *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 8000 THEN
  (* Store pending write data *)
  FOR ui := 1 TO 10 DO
    g_dep_pending.programs[ui] := g_programs[ui];
    g_dep_pending.schedule[ui] := g_schedule[ui];
  END_FOR;
  g_dep_pending.batch_unit  := cur_wait_unit;
  g_dep_pending.batch_stage := 0;    (* 90 → 0 *)
  g_dep_pending.time_s      := i_time_s;
  g_dep_pending.valid        := TRUE;

  (* Restore globals from sandbox (undo DEP's temp changes) *)
  fb_sandbox(i_cmd := 2);
  fb_sandbox(i_cmd := 3);   (* clear sandbox *)

  g_dep_activated := TRUE;
  o_activated := TRUE;

  next_phase := 8010;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 8010: WAIT_SAVE — wait for TSK to process pending     *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 8010 THEN
  IF NOT g_dep_pending.valid THEN
    (* TSK has processed the pending write *)
    next_phase := 8020;
  END_IF;
  (* Otherwise keep waiting *)

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 8020: END_DELAY — stabilization ticks                 *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 8020 THEN
  end_delay_cnt := 0;
  next_phase := 8021;

ELSIF phase >= 8021 AND phase <= 8120 THEN
  end_delay_cnt := end_delay_cnt + 1;
  IF end_delay_cnt >= END_DELAY_TICKS THEN
    next_phase := 8100;
  ELSE
    next_phase := phase + 1;
    IF next_phase > 8120 THEN
      next_phase := 8100;
    END_IF;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 8100: RESTART — back to WAIT_STABLE                   *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 8100 THEN
  g_dep_activated := FALSE;
  next_phase := 1;

(* ════════════════════════════════════════════════════════════ *)
(* PHASE 9000: REJECT — restore, try next batch                *)
(* ════════════════════════════════════════════════════════════ *)
ELSIF phase = 9000 THEN
  (* Restore globals from sandbox (undo changes for this batch) *)
  fb_sandbox(i_cmd := 2);

  (* Try next waiting batch *)
  cur_wait_idx := cur_wait_idx + 1;
  IF cur_wait_idx > waiting_cnt THEN
    (* No more batches → back to waiting *)
    fb_sandbox(i_cmd := 3);
    next_phase := 1;
  ELSE
    (* Try next batch — re-snapshot is still valid *)
    next_phase := 1000;
  END_IF;

(* ════════════════════════════════════════════════════════════ *)
(* Unknown phase → reset                                       *)
(* ════════════════════════════════════════════════════════════ *)
ELSE
  next_phase := 1;
END_IF;

(* ── Phase assignment ── *)
phase := next_phase;
o_phase := phase;

END_FUNCTION_BLOCK
