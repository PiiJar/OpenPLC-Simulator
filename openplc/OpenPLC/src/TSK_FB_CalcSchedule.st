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
  i_time_s   : LINT;    (* current absolute time (s), unix seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MIN_StationIndex : INT;
    MAX_StationIndex   : INT;
    MAX_Units           : INT;
    MAX_Transporters    : INT;
END_VAR
VAR_EXTERNAL
  g_batch  : ARRAY[1..MAX_Units] OF BATCH_T;
  g_program : ARRAY[1..MAX_Units] OF TREATMENT_PROGRAM_T;
  g_unit    : ARRAY[1..MAX_Units] OF UNIT_T;
  g_station : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_StationType;
  g_schedule : ARRAY[1..MAX_Units] OF TSK_SCHEDULE_T;
  g_station_count : INT;
  g_move    : ARRAY[1..MAX_Transporters] OF MOVE_TIMES_T;
END_VAR
VAR
  st         : INT;      (* loop: stage index *)
  stn_num    : INT;      (* target station number *)
  prev_stn   : INT;      (* previous station number *)
  cur_stage  : INT;      (* batch current stage *)
  location   : INT;      (* unit location *)
  start_st   : INT;      (* first stage to calculate *)
  entry_t    : LINT;     (* entry time for stage, absolute *)
  exit_t     : LINT;     (* exit time for stage, absolute *)
  xfer_t     : REAL;     (* transfer time *)
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
  tmp_move   : MOVE_TIMES_T;  (* MATIEC cannot index arrays in FUNCTION args *)
  (* ── Parallel station selection (schedule-aware + idle-since) ── *)
  cand_arr         : ARRAY[1..5] OF INT;
  cand_cnt         : INT;
  sched_occupied   : ARRAY[1..5] OF BOOL;
  phys_occupied    : ARRAY[1..5] OF BOOL;
  best_change_time : LINT;
  my_entry         : LINT;
  my_exit          : LINT;
  ov_start         : LINT;
  ov_end           : LINT;
  uj               : INT;
  sj               : INT;
END_VAR

(* -- Validate inputs -- *)
IF i_unit < 1 OR i_unit > MAX_Units THEN RETURN; END_IF;
IF i_trans < 1 OR i_trans > MAX_Transporters THEN RETURN; END_IF;

(* -- Read batch and unit data -- *)
cur_stage := g_batch[i_unit].cur_stage;
location  := g_unit[i_unit].location;
is_on_stn := location >= 100;
out_count := 0;

(* -- Clear old schedule -- *)
FOR st := 1 TO 30 DO
  g_schedule[i_unit].stages[st].station := 0;
  g_schedule[i_unit].stages[st].entry_time := 0;
  g_schedule[i_unit].stages[st].exit_time := 0;
  g_schedule[i_unit].stages[st].min_time := 0;
  g_schedule[i_unit].stages[st].calc_time := 0;
  g_schedule[i_unit].stages[st].max_time := 0;
  g_schedule[i_unit].stages[st].transfer_time := 0;
END_FOR;

(* -- Determine start stage -- *)
(* Waiting batch (state = NOT_PROCESSED): treat as stage 0 *)
IF g_batch[i_unit].state = 0 THEN
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
  prev_stn := g_program[i_unit].stages[cur_stage].stations[1];
ELSE
  prev_stn := 0;
END_IF;

(* -- prevExitTime: when next stage can begin -- *)
IF is_on_stn THEN
  (* Unit is on station: calculate remaining time *)
  calc_s := INT_TO_REAL(g_batch[i_unit].cur_stage);
  (* For first stage, remaining time based on calc_time *)
  exit_t := i_time_s;
ELSE
  exit_t := i_time_s;
END_IF;

is_first := TRUE;

(* -- Prepend current location when unit needs pre-positioning -- *)
(* If unit is on a station that is NOT the first treatment station,
   insert it as schedule entry 0 (0 treatment time) so that
   CreateTasks generates a move-to-first-station task. *)
IF is_on_stn AND start_st >= 1 THEN
  stn_num := 0;
  FOR p := 1 TO 5 DO
    IF g_program[i_unit].stages[start_st].stations[p] = location THEN
      stn_num := location;  (* flag: already on first treatment station *)
    END_IF;
  END_FOR;
  IF stn_num = 0 THEN
    out_count := out_count + 1;
    g_schedule[i_unit].stages[out_count].station       := location;
    g_schedule[i_unit].stages[out_count].entry_time    := exit_t;
    g_schedule[i_unit].stages[out_count].exit_time     := exit_t;
    g_schedule[i_unit].stages[out_count].min_time      := 0;
    g_schedule[i_unit].stages[out_count].calc_time     := 0;
    g_schedule[i_unit].stages[out_count].max_time      := 0;
    g_schedule[i_unit].stages[out_count].transfer_time := 0;
    is_first := FALSE;
  END_IF;
END_IF;

(* ============================================================
   MAIN LOOP: Calculate schedule for each program stage
   ============================================================ *)
FOR st := start_st TO 30 DO

  (* Check if stage has valid stations — parallel selection *)
  cand_cnt := 0;
  FOR p := 1 TO 5 DO
    IF g_program[i_unit].stages[st].stations[p] > 0 THEN
      cand_cnt := cand_cnt + 1;
      cand_arr[cand_cnt] := g_program[i_unit].stages[st].stations[p];
      sched_occupied[cand_cnt] := FALSE;
      phys_occupied[cand_cnt] := FALSE;
    END_IF;
  END_FOR;

  (* No station means end of program *)
  IF cand_cnt = 0 THEN
    EXIT;
  END_IF;

  IF cand_cnt = 1 THEN
    chosen_stn := cand_arr[1];
  ELSE
    (* Read treatment times early — needed for time window estimate *)
    calc_s := DINT_TO_REAL(g_program[i_unit].stages[st].cal_time);

    (* Estimate this stage's time window *)
    tmp_move := g_move[i_trans];
    xfer_t := STC_CalcTransferTime(i_from_stn := prev_stn, i_to_stn := cand_arr[1], i_move := tmp_move);
    my_entry := exit_t + REAL_TO_LINT(xfer_t);
    my_exit  := my_entry + REAL_TO_LINT(calc_s);

    (* Check schedule overlap + physical occupation for each candidate *)
    FOR p := 1 TO cand_cnt DO
      FOR uj := 1 TO MAX_Units DO
        IF uj <> i_unit AND g_schedule[uj].stage_count > 0 THEN
          FOR sj := 1 TO g_schedule[uj].stage_count DO
            IF g_schedule[uj].stages[sj].station = cand_arr[p] THEN
              ov_start := my_entry;
              IF g_schedule[uj].stages[sj].entry_time > ov_start THEN
                ov_start := g_schedule[uj].stages[sj].entry_time;
              END_IF;
              ov_end := my_exit;
              IF g_schedule[uj].stages[sj].exit_time < ov_end THEN
                ov_end := g_schedule[uj].stages[sj].exit_time;
              END_IF;
              IF ov_end > ov_start THEN
                sched_occupied[p] := TRUE;
              END_IF;
            END_IF;
          END_FOR;
        END_IF;
      END_FOR;

      (* Physical occupation *)
      FOR uj := 1 TO MAX_Units DO
        IF g_unit[uj].location = cand_arr[p] AND g_unit[uj].status = 1 THEN
          phys_occupied[p] := TRUE;
        END_IF;
      END_FOR;
    END_FOR;

    (* Select best free station: longest idle = smallest change_time *)
    chosen_stn := 0;
    best_change_time := LINT#9999999999;
    FOR p := 1 TO cand_cnt DO
      IF NOT sched_occupied[p] AND NOT phys_occupied[p] THEN
        IF cand_arr[p] >= MIN_StationIndex AND cand_arr[p] <= MAX_StationIndex THEN
          IF g_station[cand_arr[p]].ChangeTime < best_change_time THEN
            best_change_time := g_station[cand_arr[p]].ChangeTime;
            chosen_stn := cand_arr[p];
          END_IF;
        END_IF;
      END_IF;
    END_FOR;

    (* Fallback: schedule-free only *)
    IF chosen_stn = 0 THEN
      FOR p := 1 TO cand_cnt DO
        IF NOT sched_occupied[p] AND chosen_stn = 0 THEN
          chosen_stn := cand_arr[p];
        END_IF;
      END_FOR;
    END_IF;

    (* Ultimate fallback: first candidate *)
    IF chosen_stn = 0 THEN
      chosen_stn := cand_arr[1];
    END_IF;
  END_IF;

  stn_num := chosen_stn;

  (* Read treatment times from program *)
  calc_s := DINT_TO_REAL(g_program[i_unit].stages[st].cal_time);
  min_s  := DINT_TO_REAL(g_program[i_unit].stages[st].min_time);
  max_s  := DINT_TO_REAL(g_program[i_unit].stages[st].max_time);

  (* -- Calculate transfer time from prev_stn to stn_num -- *)
  tmp_move := g_move[i_trans];
  xfer_t := STC_CalcTransferTime(i_from_stn := prev_stn, i_to_stn := stn_num, i_move := tmp_move);

  (* -- Calculate entry and exit times -- *)
  IF is_first AND is_on_stn AND st = cur_stage THEN
    (* Batch is currently at this station *)
    entry_t := i_time_s;
    (* Remaining time: calc_time - elapsed since arrival *)
    IF g_batch[i_unit].start_time > 0 THEN
      elapsed_s := LINT_TO_REAL(i_time_s - g_batch[i_unit].start_time);
    ELSE
      elapsed_s := 0.0;
    END_IF;
    remain_s := calc_s - elapsed_s;
    IF remain_s < 1.0 THEN remain_s := 1.0; END_IF;
    exit_t := i_time_s + REAL_TO_LINT(remain_s);
  ELSIF is_first AND NOT is_on_stn THEN
    (* Batch is on transporter: entry = now (transfer in progress) *)
    entry_t := exit_t;
    exit_t  := entry_t + REAL_TO_LINT(calc_s);
  ELSE
    (* Normal stage: entry = prev exit + transfer *)
    entry_t := exit_t + REAL_TO_LINT(xfer_t);
    exit_t  := entry_t + REAL_TO_LINT(calc_s);
  END_IF;

  (* -- Write to schedule -- *)
  out_count := out_count + 1;
  IF out_count <= 30 THEN
    g_schedule[i_unit].stages[out_count].station       := stn_num;
    g_schedule[i_unit].stages[out_count].entry_time    := entry_t;
    g_schedule[i_unit].stages[out_count].exit_time     := exit_t;
    g_schedule[i_unit].stages[out_count].min_time      := REAL_TO_DINT(min_s);
    g_schedule[i_unit].stages[out_count].calc_time     := REAL_TO_DINT(calc_s);
    g_schedule[i_unit].stages[out_count].max_time      := REAL_TO_DINT(max_s);
    g_schedule[i_unit].stages[out_count].transfer_time := REAL_TO_DINT(xfer_t);
  END_IF;

  (* -- Update for next iteration -- *)
  prev_stn := stn_num;
  is_first := FALSE;

END_FOR;

g_schedule[i_unit].stage_count := out_count;

END_FUNCTION_BLOCK
