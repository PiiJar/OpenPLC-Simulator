(* ============================================================
   TSK_FB_Scheduler — Main task scheduler state machine
   ============================================================
   Ported from taskScheduler.js tick() function (V3.4)

   One phase per PLC scan cycle. Phase counter advances through:
     0    STOPPED
     1    INIT (count active batches)
     1000 SCHEDULE_START
     1001..1010  SCHEDULE per batch (one per tick)
     1900 SCHEDULE_DONE
     2000 TASKS_START (clear task queues)
     2001..2010  CREATE_TASKS per batch (one per tick)
     2200 TASKS_SORT (insertion sort by start_time)
     2201 TASKS_SWAP
     2202 TASKS_ANALYZE
     2203 TASKS_RESOLVE (if conflict found)
     2204 TASKS_NO_TREATMENT (if no conflict)
     10000 READY
     10110 RESTART (begin new cycle)

   Conflict resolution: one conflict per cycle.
   If resolved → RESTART → new ANALYZE.
   If no conflict → NO_TREATMENT → READY.
   Max iterations to prevent infinite loops.
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_Scheduler
VAR_INPUT
  i_run    : BOOL;    (* TRUE = run, FALSE = stop *)
  i_time_s : REAL;    (* current absolute time (s) *)
END_VAR
VAR_EXTERNAL
  g_batches  : ARRAY[1..10] OF BATCH_T;
  g_units    : ARRAY[1..10] OF UNIT_T;
  g_programs : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  g_tasks    : ARRAY[1..3] OF TSK_QUEUE_T;
  g_schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;
  (* DEP handshake *)
  g_dep_pending : DEP_PENDING_WRITE_T;
END_VAR
VAR_OUTPUT
  o_phase      : INT;     (* current phase *)
  o_batch_cnt  : INT;     (* active batch count *)
  o_task_cnt   : INT;     (* total task count *)
  o_cycle_cnt  : INT;     (* completed cycles *)
  o_conflict   : BOOL;    (* TRUE during conflict resolution *)
END_VAR
VAR
  phase        : INT := 0;
  next_phase   : INT;
  (* Batch iteration *)
  batch_idx    : INT;      (* current batch being processed 1..10 *)
  batch_list   : ARRAY[1..10] OF INT;  (* active unit indices *)
  batch_count  : INT;
  (* Conflict iteration *)
  conflict_iter : INT;
  MAX_CONFLICT_ITER : INT := 20;
  (* Sub-FB instances *)
  fb_calc    : TSK_FB_CalcSchedule;
  fb_create  : TSK_FB_CreateTasks;
  fb_swap    : TSK_FB_SwapTasks;
  fb_analyze : TSK_FB_Analyze;
  fb_resolve : TSK_FB_Resolve;
  fb_notrt   : TSK_FB_NoTreatment;
  fb_find    : STC_FB_FindTransporter;  (* shared transporter finder *)
  (* Transporter assignment for schedule calculation *)
  sched_trans : INT;
  (* Temp *)
  bi         : INT;
  ti         : INT;
  qi         : INT;
  ui         : INT;
  total_tasks : INT;
  (* Insertion sort vars *)
  ins_i      : INT;
  ins_j      : INT;
  ins_cnt    : INT;
  tmp_task   : TSK_TASK_T;
  cycle_count : INT := 0;
END_VAR

IF NOT i_run THEN
  phase := 0;
  o_phase := 0;
  RETURN;
END_IF;

next_phase := phase;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 0: STOPPED — wait for i_run                            *)
(* ══════════════════════════════════════════════════════════════ *)
IF phase = 0 THEN
  next_phase := 1;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 1: INIT — collect active batches                       *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 1 THEN
  batch_count := 0;
  FOR bi := 1 TO 10 DO
    (* Active batch: state = IN_PROCESS (1) or has valid program *)
    IF g_batches[bi].state = 1 THEN
      batch_count := batch_count + 1;
      batch_list[batch_count] := bi;
    END_IF;
  END_FOR;
  o_batch_cnt := batch_count;
  conflict_iter := 0;

  IF batch_count = 0 THEN
    (* No active batches — go to READY directly *)
    next_phase := 10000;
  ELSE
    next_phase := 1000;
  END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 1000: SCHEDULE_START                                   *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 1000 THEN
  batch_idx := 1;
  next_phase := 1001;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 1001..1010: SCHEDULE per batch (one per tick)          *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase >= 1001 AND phase <= 1010 THEN
  IF batch_idx <= batch_count THEN
    ui := batch_list[batch_idx];

    (* Find transporter for this unit — first one with matching task_area *)
    fb_find(i_lift_stn := g_units[ui].location, i_sink_stn := 0);
    sched_trans := fb_find.o_trans_id;
    IF sched_trans = 0 THEN sched_trans := 1; END_IF;  (* fallback default *)

    fb_calc(i_unit := ui, i_trans := sched_trans, i_time_s := i_time_s);

    batch_idx := batch_idx + 1;
    IF batch_idx <= batch_count THEN
      next_phase := phase + 1;
    ELSE
      next_phase := 1900;
    END_IF;
  ELSE
    next_phase := 1900;
  END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 1900: SCHEDULE_DONE                                    *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 1900 THEN
  next_phase := 2000;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2000: TASKS_START — clear all task queues              *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 2000 THEN
  FOR ti := 1 TO 3 DO
    g_tasks[ti].count := 0;
    FOR qi := 1 TO 10 DO
      g_tasks[ti].queue[qi].unit := 0;
      g_tasks[ti].queue[qi].stage := 0;
      g_tasks[ti].queue[qi].lift_station := 0;
      g_tasks[ti].queue[qi].sink_station := 0;
      g_tasks[ti].queue[qi].start_time := 0.0;
      g_tasks[ti].queue[qi].finish_time := 0.0;
      g_tasks[ti].queue[qi].calc_time := 0.0;
      g_tasks[ti].queue[qi].min_time := 0.0;
      g_tasks[ti].queue[qi].max_time := 0.0;
    END_FOR;
  END_FOR;
  batch_idx := 1;
  next_phase := 2001;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2001..2010: CREATE_TASKS per batch (one per tick)      *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase >= 2001 AND phase <= 2010 THEN
  IF batch_idx <= batch_count THEN
    ui := batch_list[batch_idx];
    fb_create(i_unit := ui);
    batch_idx := batch_idx + 1;
    IF batch_idx <= batch_count THEN
      next_phase := phase + 1;
    ELSE
      next_phase := 2200;
    END_IF;
  ELSE
    next_phase := 2200;
  END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2200: TASKS_SORT — insertion sort each queue by time   *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 2200 THEN
  FOR ti := 1 TO 3 DO
    ins_cnt := g_tasks[ti].count;
    IF ins_cnt >= 2 THEN
      FOR ins_i := 2 TO ins_cnt DO
        tmp_task := g_tasks[ti].queue[ins_i];
        ins_j := ins_i - 1;
        WHILE ins_j >= 1 AND g_tasks[ti].queue[ins_j].start_time > tmp_task.start_time DO
          g_tasks[ti].queue[ins_j + 1] := g_tasks[ti].queue[ins_j];
          ins_j := ins_j - 1;
        END_WHILE;
        g_tasks[ti].queue[ins_j + 1] := tmp_task;
      END_FOR;
    END_IF;
  END_FOR;
  next_phase := 2201;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2201: TASKS_SWAP                                       *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 2201 THEN
  fb_swap();
  next_phase := 2202;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2202: TASKS_ANALYZE                                    *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 2202 THEN
  fb_analyze();
  o_conflict := fb_analyze.o_has_conflict;
  IF fb_analyze.o_has_conflict THEN
    next_phase := 2203;
  ELSE
    next_phase := 2204;
  END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2203: TASKS_RESOLVE                                    *)
(* One conflict per cycle → recalculate                         *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 2203 THEN
  fb_resolve(
    i_conf_unit     := fb_analyze.o_conf_unit,
    i_conf_stage    := fb_analyze.o_conf_stage,
    i_conf_trans    := fb_analyze.o_conf_trans,
    i_blocked_unit  := fb_analyze.o_blocked_unit,
    i_blocked_stage := fb_analyze.o_blocked_stage,
    i_deficit       := fb_analyze.o_deficit
  );

  conflict_iter := conflict_iter + 1;

  IF conflict_iter >= MAX_CONFLICT_ITER THEN
    (* Max iterations reached — accept partial solution *)
    next_phase := 2204;
  ELSE
    (* Re-analyze: SORT → SWAP → ANALYZE again *)
    next_phase := 2200;
  END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 2204: TASKS_NO_TREATMENT                               *)
(* Task list is stable (no conflicts). Create unit-target tasks *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 2204 THEN
  fb_notrt(i_time_s := i_time_s);
  o_conflict := FALSE;
  next_phase := 10000;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 10000: READY — cycle complete                          *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 10000 THEN
  (* Count total tasks *)
  total_tasks := 0;
  FOR ti := 1 TO 3 DO
    total_tasks := total_tasks + g_tasks[ti].count;
  END_FOR;
  o_task_cnt := total_tasks;
  next_phase := 10100;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 10100: CHECK_DEP_PENDING — DEP activated a batch       *)
(* Copy pending data to globals and trigger full recalculation  *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 10100 THEN
  IF g_dep_pending.valid THEN
    (* Apply DEP’s pending data: programs + stage change *)
    FOR ui := 1 TO 10 DO
      g_programs[ui] := g_dep_pending.programs[ui];
    END_FOR;
    IF g_dep_pending.batch_unit >= 1 AND g_dep_pending.batch_unit <= 10 THEN
      g_batches[g_dep_pending.batch_unit].cur_stage := g_dep_pending.batch_stage;
    END_IF;
    g_dep_pending.valid := FALSE;
    (* Full recalculation with new data *)
    next_phase := 1;
  ELSE
    next_phase := 10110;
  END_IF;

(* ══════════════════════════════════════════════════════════════ *)
(* PHASE 10110: RESTART — begin new cycle                       *)
(* ══════════════════════════════════════════════════════════════ *)
ELSIF phase = 10110 THEN
  cycle_count := cycle_count + 1;
  o_cycle_cnt := cycle_count;
  next_phase := 1;  (* back to INIT *)

(* ══════════════════════════════════════════════════════════════ *)
(* Unknown phase → reset to INIT                                *)
(* ══════════════════════════════════════════════════════════════ *)
ELSE
  next_phase := 1;
END_IF;

(* ── Phase assignment at end of scan ── *)
phase := next_phase;
o_phase := phase;

END_FUNCTION_BLOCK
