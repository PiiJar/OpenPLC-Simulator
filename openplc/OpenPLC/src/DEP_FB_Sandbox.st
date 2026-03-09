(* ============================================================
   DEP_FB_Sandbox — Sandbox snapshot / restore / clear
   ============================================================
   Copies global scheduler state to/from the departure sandbox.
   Struct assignment `a := b` in ST copies all fields automatically.

   Source: departureScheduler.js _copyDepartureSandbox()

   Commands:
     1 = SNAPSHOT  — copy globals → g_dep_sandbox
     2 = RESTORE   — copy g_dep_sandbox → globals
     3 = CLEAR     — invalidate sandbox

   Used by: DEP_FB_Scheduler (INIT, REJECT, ACTIVATE)
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_Sandbox
VAR_INPUT
  i_cmd : INT;     (* 1=SNAPSHOT, 2=RESTORE, 3=CLEAR *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_Transporters : INT;
    MAX_Units        : INT;
END_VAR

VAR_EXTERNAL
  g_schedule    : ARRAY[1..MAX_Units] OF TSK_SCHEDULE_T;
  g_batch     : ARRAY[1..MAX_Units] OF UDT_BatchType;
  g_program    : ARRAY[1..MAX_Units] OF UDT_TreatmentProgramType;
  g_task       : ARRAY[1..MAX_Transporters] OF TSK_QUEUE_T;
  g_dep_sandbox : DEP_SANDBOX_T;
END_VAR
VAR
  ui : INT;
  ti : INT;
END_VAR

IF i_cmd = 1 THEN
  (* ── SNAPSHOT: globals → sandbox ── *)
  FOR ui := 1 TO MAX_Units DO
    g_dep_sandbox.schedule[ui] := g_schedule[ui];
    g_dep_sandbox.batches[ui]  := g_batch[ui];
    g_dep_sandbox.programs[ui] := g_program[ui];
  END_FOR;
  FOR ti := 1 TO MAX_Transporters DO
    g_dep_sandbox.tasks[ti] := g_task[ti];
  END_FOR;
  g_dep_sandbox.valid := TRUE;

ELSIF i_cmd = 2 THEN
  (* ── RESTORE: sandbox → globals ── *)
  IF g_dep_sandbox.valid THEN
    FOR ui := 1 TO MAX_Units DO
      g_schedule[ui] := g_dep_sandbox.schedule[ui];
      g_batch[ui]  := g_dep_sandbox.batches[ui];
      g_program[ui] := g_dep_sandbox.programs[ui];
    END_FOR;
    FOR ti := 1 TO MAX_Transporters DO
      g_task[ti] := g_dep_sandbox.tasks[ti];
    END_FOR;
  END_IF;

ELSIF i_cmd = 3 THEN
  (* ── CLEAR: invalidate sandbox ── *)
  g_dep_sandbox.valid := FALSE;

END_IF;

END_FUNCTION_BLOCK
