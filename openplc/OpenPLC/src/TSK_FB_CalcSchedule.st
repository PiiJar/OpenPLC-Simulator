(* ============================================================
   TSK_FB_CalcSchedule — Calculate batch schedule for one unit
   ============================================================
   Ported from transporterTaskScheduler.js calculateBatchSchedule()

   Calculates schedule timeline for one unit/batch:
   - Reads treatment program stages
   - Calculates transfer times from g_move
   - Writes entry/exit times to g_schedule[unit]

   Parallel stations: picks first available (stations[1] default).
   Transfer time: lift + travel + sink from g_move precomputed table.

   Called once per batch per scheduler cycle.
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_CalcSchedule
VAR_INPUT
  i_unit     : INT;     (* unit index 1..10 *)
  i_trans    : INT;     (* transporter index 1..3 for move times *)
  i_time_s   : REAL;    (* current absolute time (s) *)
END_VAR
VAR_EXTERNAL
  g_batches  : ARRAY[1..10] OF BATCH_T;
  g_programs : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  g_units    : ARRAY[1..10] OF UNIT_T;
  g_stations : ARRAY[101..125] OF STATION_T;
  g_move     : ARRAY[1..3] OF MOVE_TIMES_T;
  g_schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;
  g_station_count : INT;
END_VAR
VAR
  st         : INT;      (* loop: stage index *)
  stn_num    : INT;      (* target station number *)
  stn_idx    : INT;      (* station index in g_move (1..25) *)
  prev_idx   : INT;      (* previous station index in g_move *)
  prev_stn   : INT;      (* previous station number *)
  cur_stage  : INT;      (* batch current stage *)
  location   : INT;      (* unit location *)
  start_st   : INT;      (* first stage to calculate *)
  entry_t    : REAL;     (* entry time for stage *)
  exit_t     : REAL;     (* exit time for stage *)
  xfer_t     : REAL;     (* transfer time *)
  lift_t     : REAL;     (* lift time *)
  sink_t     : REAL;     (* sink time *)
  travel_t   : REAL;     (* horizontal travel time *)
  calc_s     : REAL;     (* calc_time in seconds *)
  min_s      : REAL;     (* min_time in seconds *)
  max_s      : REAL;     (* max_time in seconds *)
  is_on_stn  : BOOL;     (* TRUE if unit is on a station *)
  is_first   : BOOL;     (* TRUE for first stage in loop *)
  remain_s   : REAL;     (* remaining time on current station *)
  elapsed_s  : REAL;     (* elapsed time on current station *)
  out_count  : INT;      (* output stage counter *)
  p          : INT;      (* parallel station loop index *)
  chosen_stn : INT;      (* chosen parallel station *)
END_VAR

(* -- Validate inputs -- *)
IF i_unit < 1 OR i_unit > 10 THEN RETURN; END_IF;
IF i_trans < 1 OR i_trans > 3 THEN RETURN; END_IF;

(* -- Read batch and unit data -- *)
cur_stage := g_batches[i_unit].cur_stage;
location  := g_units[i_unit].location;
is_on_stn := location >= 100;
out_count := 0;

(* -- Clear old schedule -- *)
FOR st := 1 TO 30 DO
  g_schedule[i_unit].stages[st].station := 0;
  g_schedule[i_unit].stages[st].entry_time := 0.0;
  g_schedule[i_unit].stages[st].exit_time := 0.0;
  g_schedule[i_unit].stages[st].min_time := 0.0;
  g_schedule[i_unit].stages[st].calc_time := 0.0;
  g_schedule[i_unit].stages[st].max_time := 0.0;
  g_schedule[i_unit].stages[st].transfer_time := 0.0;
END_FOR;

(* -- Determine start stage -- *)
(* Stage 90 = waiting batch, treat as stage 0 *)
IF cur_stage = 90 THEN
  cur_stage := 0;
END_IF;

(* If on transporter, start from next stage; if on station, from current *)
IF is_on_stn THEN
  start_st := cur_stage;
ELSE
  start_st := cur_stage + 1;
END_IF;

(* Force minimum stage 1 *)
IF start_st < 1 THEN
  start_st := 1;
END_IF;

(* -- Previous station (where transfer starts from) -- *)
IF is_on_stn THEN
  prev_stn := location;
ELSIF cur_stage >= 1 AND cur_stage <= 30 THEN
  (* On transporter: use previous stage station *)
  prev_stn := g_programs[i_unit].stages[cur_stage].stations[1];
ELSE
  prev_stn := 0;
END_IF;

(* -- prevExitTime: when next stage can begin -- *)
IF is_on_stn THEN
  (* Unit is on station: calculate remaining time *)
  calc_s := INT_TO_REAL(g_batches[i_unit].cur_stage);
  (* For first stage, remaining time based on calc_time *)
  exit_t := i_time_s;
ELSE
  exit_t := i_time_s;
END_IF;

is_first := TRUE;

(* ============================================================
   MAIN LOOP: Calculate schedule for each program stage
   ============================================================ *)
FOR st := start_st TO 30 DO

  (* Check if stage has a valid station *)
  chosen_stn := 0;
  FOR p := 1 TO 5 DO
    IF g_programs[i_unit].stages[st].stations[p] > 0 AND chosen_stn = 0 THEN
      chosen_stn := g_programs[i_unit].stages[st].stations[p];
    END_IF;
  END_FOR;

  (* No station means end of program *)
  IF chosen_stn = 0 THEN
    EXIT;
  END_IF;

  stn_num := chosen_stn;

  (* Read treatment times from program *)
  calc_s := INT_TO_REAL(g_programs[i_unit].stages[st].cal_time);
  min_s  := INT_TO_REAL(g_programs[i_unit].stages[st].min_time);
  max_s  := INT_TO_REAL(g_programs[i_unit].stages[st].max_time);

  (* -- Calculate transfer time from prev_stn to stn_num -- *)
  xfer_t := 0.0;
  IF prev_stn > 0 AND prev_stn <> stn_num THEN
    prev_idx := prev_stn - 100;
    stn_idx  := stn_num - 100;
    IF prev_idx >= 1 AND prev_idx <= 25 AND stn_idx >= 1 AND stn_idx <= 25 THEN
      lift_t   := g_move[i_trans].lift_s[prev_idx];
      travel_t := g_move[i_trans].travel[prev_idx].to_s[stn_idx];
      sink_t   := g_move[i_trans].sink_s[stn_idx];
      xfer_t   := lift_t + travel_t + sink_t;
    END_IF;
  END_IF;

  (* -- Calculate entry and exit times -- *)
  IF is_first AND is_on_stn AND st = cur_stage THEN
    (* Batch is currently at this station *)
    entry_t := i_time_s;
    (* Remaining time: calc_time - elapsed *)
    remain_s := calc_s;
    IF remain_s < 1.0 THEN remain_s := 1.0; END_IF;
    exit_t := i_time_s + remain_s;
  ELSIF is_first AND NOT is_on_stn THEN
    (* Batch is on transporter: entry = now (transfer in progress) *)
    entry_t := exit_t;
    exit_t  := entry_t + calc_s;
  ELSE
    (* Normal stage: entry = prev exit + transfer *)
    entry_t := exit_t + xfer_t;
    exit_t  := entry_t + calc_s;
  END_IF;

  (* -- Write to schedule -- *)
  out_count := out_count + 1;
  IF out_count <= 30 THEN
    g_schedule[i_unit].stages[out_count].station       := stn_num;
    g_schedule[i_unit].stages[out_count].entry_time    := entry_t;
    g_schedule[i_unit].stages[out_count].exit_time     := exit_t;
    g_schedule[i_unit].stages[out_count].min_time      := min_s;
    g_schedule[i_unit].stages[out_count].calc_time     := calc_s;
    g_schedule[i_unit].stages[out_count].max_time      := max_s;
    g_schedule[i_unit].stages[out_count].transfer_time := xfer_t;
  END_IF;

  (* -- Update for next iteration -- *)
  prev_stn := stn_num;
  is_first := FALSE;

END_FOR;

g_schedule[i_unit].stage_count := out_count;

END_FUNCTION_BLOCK
