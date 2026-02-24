(* ============================================================
   TSK_FB_SwapTasks — Swap same-station task pairs
   ============================================================
   Ported from transporterTaskScheduler.js swapSameStationTasks()

   For each transporter queue, checks consecutive task pairs:
   if prev.sink_station == next.lift_station AND different units,
   swap order so the lift happens first (avoids deadlock).

   Operates on g_task[1..3] in-place.
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_SwapTasks
VAR_EXTERNAL CONSTANT
    TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_task : ARRAY[1..TRANSPORTERS] OF TSK_QUEUE_T;
END_VAR
VAR_OUTPUT
  o_swap_count : INT;   (* number of swaps performed *)
END_VAR
VAR
  ti     : INT;    (* transporter loop *)
  qi     : INT;    (* queue pair index *)
  cnt    : INT;    (* queue count *)
  tmp    : TSK_TASK_T;  (* swap scratch *)
END_VAR

o_swap_count := 0;

FOR ti := 1 TO TRANSPORTERS DO
  cnt := g_task[ti].count;
  IF cnt >= 2 THEN
    FOR qi := 1 TO cnt - 1 DO
      (* Check: different units AND prev.sink == next.lift *)
      IF g_task[ti].queue[qi].unit <> g_task[ti].queue[qi + 1].unit
         AND g_task[ti].queue[qi].sink_station = g_task[ti].queue[qi + 1].lift_station THEN
        (* Swap *)
        tmp := g_task[ti].queue[qi];
        g_task[ti].queue[qi] := g_task[ti].queue[qi + 1];
        g_task[ti].queue[qi + 1] := tmp;
        o_swap_count := o_swap_count + 1;
      END_IF;
    END_FOR;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
