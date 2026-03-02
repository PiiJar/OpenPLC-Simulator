(* ============================================================
   STC_FB_CollectActiveBatches — Filter active batches to list
   ============================================================
   Scans g_batch[1..10] and collects unit indices matching
   mode-specific conditions into an output list.

   Common conditions for both modes:
     unit.status  = USED (1)
     unit.target  = TO_NONE (0)
     batch.prog_id = g_program[ui].program_id  (valid program)

   Mode:
     i_mode = 0 — active (in-production) batches:
                   batch.state = IN_PROCESS (1)
                   batch.cur_stage >= 0 AND <= 99
     i_mode = 1 — waiting batches:
                   batch.state = NOT_PROCESSED (0)

   Replaces 3× duplicated collection loops in:
     TSK_FB_Scheduler (phase 1, active batches)
     DEP_FB_Scheduler (phase 100, active + waiting batches)
   ============================================================ *)

FUNCTION_BLOCK STC_FB_CollectActiveBatches
VAR_INPUT
  i_mode : INT;    (* 0 = all active, 1 = waiting only *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_UNITS : INT;
END_VAR
VAR_EXTERNAL
  g_batch   : ARRAY[1..MAX_UNITS] OF BATCH_T;
  g_unit    : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_program : ARRAY[1..MAX_UNITS] OF TREATMENT_PROGRAM_T;
END_VAR
VAR_OUTPUT
  o_list  : ARRAY[1..MAX_UNITS] OF INT;  (* unit indices *)
  o_count : INT;
END_VAR
VAR
  ui : INT;
END_VAR

o_count := 0;
FOR ui := 1 TO MAX_UNITS DO
  o_list[ui] := 0;
END_FOR;

FOR ui := 1 TO MAX_UNITS DO
  (* Common conditions: unit USED, target TO_NONE, valid program *)
  IF g_unit[ui].status = 1
     AND g_unit[ui].target = 0
     AND g_batch[ui].prog_id = g_program[ui].program_id
     AND g_program[ui].program_id > 0 THEN

    IF i_mode = 0 THEN
      (* Active batches: IN_PROCESS, stage 0..99 *)
      IF g_batch[ui].state = 1
         AND g_batch[ui].cur_stage >= 0
         AND g_batch[ui].cur_stage <= 99 THEN
        o_count := o_count + 1;
        o_list[o_count] := ui;
      END_IF;
    ELSIF i_mode = 1 THEN
      (* Waiting batches: NOT_PROCESSED *)
      IF g_batch[ui].state = 0 THEN
        o_count := o_count + 1;
        o_list[o_count] := ui;
      END_IF;
    END_IF;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
