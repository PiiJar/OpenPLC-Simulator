(* ============================================================
   TSK_FB_CreateTasks — Build task list from schedule
   ============================================================
   Ported from transporterTaskScheduler.js createTaskListFromSchedule()

   For each consecutive stage pair in g_schedule[unit]:
     - Lift station = current stage station
     - Sink station = next stage station
     - Assigns transporter from task_area match in g_cfg
     - Skips already completed stages (stage < batch.cur_stage)
   Appends tasks to g_task[transporter].queue.

   Called once per batch per scheduler cycle.
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_CreateTasks
VAR_INPUT
  i_unit : INT;   (* unit index 1..10 *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS : INT;
    MAX_UNITS        : INT;
END_VAR

VAR_EXTERNAL
  g_batch  : ARRAY[1..MAX_UNITS] OF BATCH_T;
  g_schedule : ARRAY[1..MAX_UNITS] OF TSK_SCHEDULE_T;
  g_task    : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  g_cfg    : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
END_VAR
VAR
  si         : INT;     (* schedule stage index *)
  sc         : INT;     (* stage count *)
  lift_stn   : INT;     (* lift station *)
  sink_stn   : INT;     (* sink station *)
  cur_stage  : INT;     (* batch current stage *)
  skip_before : INT;    (* skip stages before this *)
  tid        : INT;     (* transporter id found *)
  qi         : INT;     (* queue write index *)
  stg_num    : INT;     (* stage number from schedule *)
  fb_find    : STC_FindTransporter;  (* transporter lookup *)
END_VAR

IF i_unit < 1 OR i_unit > MAX_UNITS THEN RETURN; END_IF;

sc := g_schedule[i_unit].stage_count;
IF sc < 2 THEN RETURN; END_IF;

cur_stage := g_batch[i_unit].cur_stage;
IF g_batch[i_unit].state = 0 THEN  (* NOT_PROCESSED = waiting batch *)
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
      fb_find(i_lift_stn := lift_stn, i_sink_stn := sink_stn);
      tid := fb_find.o_trans;

      (* -- Append task to transporter queue -- *)
      IF tid >= 1 AND tid <= 3 THEN
        qi := g_task[tid].count + 1;
        IF qi <= MAX_UNITS THEN
          g_task[tid].queue[qi].unit         := i_unit;
          g_task[tid].queue[qi].stage        := stg_num;
          g_task[tid].queue[qi].lift_station := lift_stn;
          g_task[tid].queue[qi].sink_station := sink_stn;
          g_task[tid].queue[qi].start_time   := g_schedule[i_unit].stages[si].exit_time;
          g_task[tid].queue[qi].finish_time  := g_schedule[i_unit].stages[si + 1].entry_time;
          g_task[tid].queue[qi].calc_time    := g_schedule[i_unit].stages[si].calc_time;
          g_task[tid].queue[qi].min_time     := g_schedule[i_unit].stages[si].min_time;
          g_task[tid].queue[qi].max_time     := g_schedule[i_unit].stages[si].max_time;
          g_task[tid].count := qi;
        END_IF;
      END_IF;
    END_IF;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
