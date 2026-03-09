(* ============================================================
   STC_FB_UpdateUnitLocation — Update a unit's location
   ============================================================
   Sets g_unit[i_unit].location to the given new location.
   Location < 100 = transporter, >= 100 = station.
   Updates unit_id + change_time on the relevant station(s).

   When moving to a station (sink / task completion):
     - Advances batch cur_stage if batch is IN_PROCESS
     - Updates batch min_time/max_time/cal_time from treatment program
     - Clears unit target to TO_NONE if target was set (NTT done)
   ============================================================ *)

FUNCTION_BLOCK STC_FB_UpdateUnitLocation
VAR_INPUT
  i_unit     : INT;   (* unit number to update *)
  i_location : INT;   (* new location: <100 = transporter id, >=100 = station number *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_Units           : INT;
    MAX_Transporters    : INT;
    MAX_STEPS_PER_PROGRAM          : INT;
    MIN_StationIndex : INT;
    MAX_StationIndex   : INT;
    IN_PROCESS          : INT;
END_VAR
VAR_EXTERNAL
  g_unit        : ARRAY[1..MAX_Units] OF UNIT_T;
  g_station     : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_StationType;
  g_station_loc : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_UnitLocation;
  g_transporter : ARRAY[1..MAX_Transporters] OF STC_TRANSPORTER_T;
  g_batch       : ARRAY[1..MAX_Units] OF BATCH_T;
  g_program     : ARRAY[1..MAX_Units] OF TREATMENT_PROGRAM_T;
  g_time_s      : LINT;
END_VAR
VAR
  old_loc : INT;
  new_stg : INT;
END_VAR

IF (i_unit >= 1) AND (i_unit <= MAX_Units) THEN
  old_loc := g_unit[i_unit].location;

  (* --- Clear unit_id from old location --- *)
  IF (old_loc >= MIN_StationIndex) AND (old_loc <= MAX_StationIndex) THEN
    (* Was on a station — clear station unit_id, stamp change_time *)
    g_station_loc[old_loc].UnitId     := 0;
    g_station_loc[old_loc].ChangeTime := g_time_s;
  ELSIF (old_loc >= 1) AND (old_loc <= MAX_Transporters) THEN
    (* Was on a transporter — clear transporter unit_id *)
    g_transporter[old_loc].UnitId := 0;
  END_IF;

  (* --- Update unit location --- *)
  g_unit[i_unit].location := i_location;

  (* --- Set unit_id on new location --- *)
  IF (i_location >= MIN_StationIndex) AND (i_location <= MAX_StationIndex) THEN
    (* Moving to a station (sink completion) *)
    g_station_loc[i_location].UnitId     := i_unit;
    g_station_loc[i_location].ChangeTime := g_time_s;

    (* Advance batch stage if unit is USED with an active batch *)
    IF (g_unit[i_unit].status = 1)  (* USED *)
       AND (g_batch[i_unit].batch_code <> 0)
       AND (g_batch[i_unit].state = IN_PROCESS)
       AND (g_batch[i_unit].cur_stage < MAX_STEPS_PER_PROGRAM) THEN
      g_batch[i_unit].cur_stage := g_batch[i_unit].cur_stage + 1;

      (* Stamp arrival time on new station — used by CalcSchedule for elapsed calculation *)
      g_batch[i_unit].start_time := g_time_s;

      (* Update batch treatment times from program for the new stage *)
      IF (g_program[i_unit].program_id = g_batch[i_unit].prog_id)
         AND (g_program[i_unit].program_id > 0) THEN
        new_stg := g_batch[i_unit].cur_stage;
        IF (new_stg >= 1) AND (new_stg <= MAX_STEPS_PER_PROGRAM) THEN
          g_batch[i_unit].min_time := g_program[i_unit].Steps[new_stg - 1].MinTime;
          g_batch[i_unit].max_time := g_program[i_unit].Steps[new_stg - 1].MaxTime;
          g_batch[i_unit].cal_time := g_program[i_unit].Steps[new_stg - 1].CalTime;
        END_IF;
      END_IF;
    END_IF;

    (* NOT_PROCESSED batch on station: clear times so UI shows no progress bar *)
    IF (g_batch[i_unit].batch_code <> 0)
       AND (g_batch[i_unit].state <> IN_PROCESS) THEN
      g_batch[i_unit].min_time   := 0;
      g_batch[i_unit].cal_time   := 0;
      g_batch[i_unit].max_time   := 32000;  (* ~8.9 h cap, INT max safe *)
      g_batch[i_unit].start_time := g_time_s;
    END_IF;

    (* Clear unit target after placement (NTT task done) *)
    IF g_unit[i_unit].target <> 0 THEN
      g_unit[i_unit].target := 0;  (* TO_NONE *)
    END_IF;

  ELSIF (i_location >= 1) AND (i_location <= MAX_Transporters) THEN
    (* Moving to a transporter (lift start) *)
    g_transporter[i_location].UnitId := i_unit;
  END_IF;
END_IF;

END_FUNCTION_BLOCK
