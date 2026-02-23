(* ============================================================
   STC_FB_CollectActiveBatches — Filter active batches to list
   ============================================================
   Scans g_batches[1..10] and collects unit indices where
   state = IN_PROCESS (1) into an output list.

   Optionally filters by cur_stage and unit target for
   departure-specific waiting batch collection.

   Mode:
     i_mode = 0 — all active batches (state = 1)
     i_mode = 1 — waiting batches (state = 1, cur_stage = 90,
                   unit target = TO_NONE = 0)

   Replaces 3× duplicated collection loops in:
     TSK_FB_Scheduler (phase 1, active batches)
     DEP_FB_Scheduler (phase 100, active + waiting batches)
   ============================================================ *)

FUNCTION_BLOCK STC_FB_CollectActiveBatches
VAR_INPUT
  i_mode : INT;    (* 0 = all active, 1 = waiting only *)
END_VAR
VAR_EXTERNAL
  g_batches : ARRAY[1..10] OF BATCH_T;
  g_units   : ARRAY[1..10] OF UNIT_T;
END_VAR
VAR_OUTPUT
  o_list  : ARRAY[1..10] OF INT;  (* unit indices *)
  o_count : INT;
END_VAR
VAR
  ui : INT;
END_VAR

o_count := 0;
FOR ui := 1 TO 10 DO
  o_list[ui] := 0;
END_FOR;

FOR ui := 1 TO 10 DO
  IF g_batches[ui].state = 1 THEN
    IF i_mode = 0 THEN
      (* All active batches *)
      o_count := o_count + 1;
      o_list[o_count] := ui;
    ELSIF i_mode = 1 THEN
      (* Waiting batches: stage=90 AND unit target = TO_NONE (0) *)
      IF g_batches[ui].cur_stage = 90 AND g_units[ui].target = 0 THEN
        o_count := o_count + 1;
        o_list[o_count] := ui;
      END_IF;
    END_IF;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
