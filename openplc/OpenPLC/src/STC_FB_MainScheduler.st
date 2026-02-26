(* ============================================================
   STC_FB_MainScheduler — Master scheduler orchestrator
   ============================================================
   Manages TSK_FB_Scheduler and DEP_FB_Scheduler calls on
   alternating PLC scan cycles. Ensures they never execute
   on the same cycle.

   Synchronization rules:
     1. Normal: alternate TSK_TURN → DEP_TURN → TSK_TURN ...
     2. Skip DEP when TSK is still computing (phase < 10000)
        → DEP would only sit in WAIT_STABLE anyway
     3. Skip DEP when g_dep_pending.valid = TRUE
        → TSK must process the pending data first
     4. g_dep_stable is computed internally after each TSK call

   Turn values:
     0 = INIT (first scan)
     1 = TSK_TURN  (TSK called this cycle)
     2 = DEP_TURN  (DEP called this cycle)

   Inputs:
     i_run     — enable (FALSE = both schedulers stopped)
     i_time_s  — absolute simulation time (seconds)

   Outputs:
     o_tsk_phase  — TSK current phase (forwarded)
     o_dep_phase  — DEP current phase (forwarded)
     o_turn       — which scheduler ran this cycle (1/2)
     o_skip_cnt   — DEP skip count (debug)
   ============================================================ *)

FUNCTION_BLOCK STC_FB_MainScheduler
VAR_INPUT
  i_run    : BOOL;     (* TRUE = run *)
  i_time_s : LINT;     (* current absolute time (s), unix seconds *)
END_VAR
VAR_EXTERNAL
  g_dep_stable  : BOOL;
  g_dep_pending : DEP_PENDING_WRITE_T;
  g_cal_active  : BOOL;
END_VAR
VAR_OUTPUT
  o_tsk_phase  : INT;     (* TSK scheduler phase *)
  o_dep_phase  : INT;     (* DEP scheduler phase *)
  o_turn       : INT;     (* 1=TSK ran, 2=DEP ran *)
  o_skip_cnt   : INT;     (* DEP skipped count (debug) *)
END_VAR
VAR
  tsk_sched    : TSK_FB_Scheduler;
  dep_sched    : DEP_FB_Scheduler;
  dispatch     : STC_FB_DispatchTask;
  turn         : INT := 0;   (* 0=init, 1=TSK, 2=DEP *)
  skip_cnt     : INT := 0;
  tsk_phase    : INT := 0;
END_VAR

IF NOT i_run THEN
  (* Stop both schedulers *)
  tsk_sched(i_run := FALSE, i_time_s := 0);
  dep_sched(i_run := FALSE, i_time_s := 0, i_tsk_phase := 0);
  turn := 0;
  tsk_phase := 0;
  o_tsk_phase := 0;
  o_dep_phase := 0;
  o_turn := 0;
  RETURN;
END_IF;

(* ── Inhibit during calibration ── *)
IF g_cal_active THEN
  tsk_sched(i_run := FALSE, i_time_s := 0);
  dep_sched(i_run := FALSE, i_time_s := 0, i_tsk_phase := 0);
  turn := 0;
  RETURN;
END_IF;

(* ── Dispatch tasks to idle transporters (every scan) ── *)
dispatch();

(* ── Determine this cycle's turn ── *)
IF turn = 0 THEN
  (* First scan: always start with TSK *)
  turn := 1;

ELSIF turn = 1 THEN
  (* Last cycle was TSK → normally DEP's turn *)
  (* But skip DEP if: *)
  (*   a) TSK has not reached READY yet (phase < 10000) *)
  (*   b) pending data waiting for TSK to process *)
  IF tsk_phase < 10000 THEN
    (* TSK still computing — DEP would be blocked at WAIT_STABLE *)
    turn := 1;
    skip_cnt := skip_cnt + 1;
  ELSIF g_dep_pending.valid THEN
    (* TSK must process pending before DEP continues *)
    turn := 1;
    skip_cnt := skip_cnt + 1;
  ELSE
    turn := 2;
  END_IF;

ELSIF turn = 2 THEN
  (* Last cycle was DEP → TSK's turn *)
  turn := 1;
END_IF;

(* ── Execute the selected scheduler ── *)
IF turn = 1 THEN
  (* TSK turn *)
  tsk_sched(i_run := TRUE, i_time_s := i_time_s);
  tsk_phase := tsk_sched.o_phase;

  (* Compute stability flag after TSK call *)
  g_dep_stable := (tsk_phase >= 10000);

ELSIF turn = 2 THEN
  (* DEP turn *)
  dep_sched(
    i_run       := TRUE,
    i_time_s    := i_time_s,
    i_tsk_phase := tsk_phase
  );
END_IF;

(* ── Update outputs ── *)
o_tsk_phase := tsk_sched.o_phase;
o_dep_phase := dep_sched.o_phase;
o_turn      := turn;
o_skip_cnt  := skip_cnt;

END_FUNCTION_BLOCK
