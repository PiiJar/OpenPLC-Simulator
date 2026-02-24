(* ============================================================
   STC_FB_SortTaskQueue — Insertion sort task queues by start_time
   ============================================================
   Sorts one or all transporter task queues in-place using
   insertion sort (stable, O(n²) — fine for n ≤ 10).

   Mode controlled by i_trans:
     0   = sort ALL queues (1..3)
     1-3 = sort only that transporter's queue

   Replaces 3× duplicated insertion sort code in:
     TSK_FB_Scheduler (phase 2200)
     DEP_FB_Scheduler (phase 1020)
     TSK_FB_Analyze   (merge-sort variant — still inline)
   ============================================================ *)

FUNCTION_BLOCK STC_FB_SortTaskQueue
VAR_INPUT
  i_trans : INT;    (* 0 = all, 1..3 = specific transporter *)
END_VAR
VAR_EXTERNAL CONSTANT
    TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_tasks : ARRAY[1..TRANSPORTERS] OF TSK_QUEUE_T;
END_VAR
VAR
  ti       : INT;
  t_start  : INT;
  t_end    : INT;
  ins_i    : INT;
  ins_j    : INT;
  ins_cnt  : INT;
  tmp_task : TSK_TASK_T;
END_VAR

IF i_trans >= 1 AND i_trans <= 3 THEN
  t_start := i_trans;
  t_end   := i_trans;
ELSE
  t_start := 1;
  t_end   := 3;
END_IF;

FOR ti := t_start TO t_end DO
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

END_FUNCTION_BLOCK
