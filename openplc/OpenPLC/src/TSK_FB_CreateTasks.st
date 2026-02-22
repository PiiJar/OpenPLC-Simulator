(* ============================================================
   TSK_FB_CreateTasks — Build task list from schedule
   ============================================================
   Ported from transporterTaskScheduler.js createTaskListFromSchedule()

   For each consecutive stage pair in g_schedule[unit]:
     - Lift station = current stage station
     - Sink station = next stage station
     - Assigns transporter from task_area match in g_cfg
     - Skips already completed stages (stage < batch.cur_stage)
   Appends tasks to g_tasks[transporter].queue.

   Called once per batch per scheduler cycle.
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_CreateTasks
VAR_INPUT
  i_unit : INT;   (* unit index 1..10 *)
END_VAR
VAR_EXTERNAL
  g_batches  : ARRAY[1..10] OF BATCH_T;
  g_schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_cfg      : ARRAY[1..3] OF TRANSPORTER_CFG_T;
  g_tasks    : ARRAY[1..3] OF TSK_QUEUE_T;
END_VAR
VAR
  si         : INT;     (* schedule stage index *)
  sc         : INT;     (* stage count *)
  lift_stn   : INT;     (* lift station *)
  sink_stn   : INT;     (* sink station *)
  cur_stage  : INT;     (* batch current stage *)
  skip_before : INT;    (* skip stages before this *)
  tid        : INT;     (* transporter id found *)
  ti         : INT;     (* transporter loop *)
  ai         : INT;     (* task area loop *)
  area       : TASK_AREA_T; (* scratch *)
  can_lift   : BOOL;
  can_sink   : BOOL;
  qi         : INT;     (* queue write index *)
  stg_num    : INT;     (* stage number from schedule *)
END_VAR

IF i_unit < 1 OR i_unit > 10 THEN RETURN; END_IF;

sc := g_schedule[i_unit].stage_count;
IF sc < 2 THEN RETURN; END_IF;

cur_stage := g_batches[i_unit].cur_stage;
IF cur_stage = 90 THEN
  skip_before := 0;
ELSE
  skip_before := cur_stage;
END_IF;

(* Loop through consecutive stage pairs *)
FOR si := 1 TO sc - 1 DO
  (* schedule index si = current stage, si+1 = next stage *)
  stg_num := si;   (* simplified: schedule stage index = stage number *)

  (* Skip already completed stages *)
  IF stg_num >= skip_before THEN
    lift_stn := g_schedule[i_unit].stages[si].station;
    sink_stn := g_schedule[i_unit].stages[si + 1].station;

    IF lift_stn > 0 AND sink_stn > 0 THEN
      (* -- Find transporter via task_area matching -- *)
      tid := 0;
      FOR ti := 1 TO 3 DO
        IF tid = 0 THEN
          FOR ai := 1 TO 4 DO
            IF tid = 0 THEN
              area := g_cfg[ti].task_area[ai];
              (* Skip unconfigured areas *)
              IF area.min_lift > 0 OR area.max_lift > 0 THEN
                can_lift := (lift_stn >= area.min_lift) AND (lift_stn <= area.max_lift);
                can_sink := (sink_stn >= area.min_sink) AND (sink_stn <= area.max_sink);
                IF can_lift AND can_sink THEN
                  tid := ti;
                END_IF;
              END_IF;
            END_IF;
          END_FOR;
        END_IF;
      END_FOR;

      (* -- Append task to transporter queue -- *)
      IF tid >= 1 AND tid <= 3 THEN
        qi := g_tasks[tid].count + 1;
        IF qi <= 10 THEN
          g_tasks[tid].queue[qi].unit         := i_unit;
          g_tasks[tid].queue[qi].stage        := stg_num;
          g_tasks[tid].queue[qi].lift_station := lift_stn;
          g_tasks[tid].queue[qi].sink_station := sink_stn;
          g_tasks[tid].queue[qi].start_time   := g_schedule[i_unit].stages[si].exit_time;
          g_tasks[tid].queue[qi].finish_time  := g_schedule[i_unit].stages[si + 1].entry_time;
          g_tasks[tid].queue[qi].calc_time    := g_schedule[i_unit].stages[si].calc_time;
          g_tasks[tid].queue[qi].min_time     := g_schedule[i_unit].stages[si].min_time;
          g_tasks[tid].queue[qi].max_time     := g_schedule[i_unit].stages[si].max_time;
          g_tasks[tid].count := qi;
        END_IF;
      END_IF;
    END_IF;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
