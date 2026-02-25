(* ============================================================
   STC_FB_UpdateUnitLocation — Update a unit's location
   ============================================================
   Sets g_unit[i_unit].location to the given new location.
   Location < 100 = transporter, >= 100 = station.
   Updates unit_id + change_time on the relevant station(s).
   ============================================================ *)

FUNCTION_BLOCK STC_FB_UpdateUnitLocation
VAR_INPUT
  i_unit     : INT;   (* unit number to update *)
  i_location : INT;   (* new location: <100 = transporter id, >=100 = station number *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_UNITS           : INT;
    MAX_TRANSPORTERS    : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
END_VAR
VAR_EXTERNAL
  g_unit        : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_station     : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF STATION_T;
  g_transporter : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_time_s      : LINT;
END_VAR
VAR
  old_loc : INT;
END_VAR

IF (i_unit >= 1) AND (i_unit <= MAX_UNITS) THEN
  old_loc := g_unit[i_unit].location;

  (* --- Clear unit_id from old location --- *)
  IF (old_loc >= STATION_ARRAY_START) AND (old_loc <= STATION_ARRAY_END) THEN
    (* Was on a station — clear station unit_id, stamp change_time *)
    g_station[old_loc].unit_id     := 0;
    g_station[old_loc].change_time := g_time_s;
  ELSIF (old_loc >= 1) AND (old_loc <= MAX_TRANSPORTERS) THEN
    (* Was on a transporter — clear transporter unit_id *)
    g_transporter[old_loc].unit_id := 0;
  END_IF;

  (* --- Update unit location --- *)
  g_unit[i_unit].location := i_location;

  (* --- Set unit_id on new location --- *)
  IF (i_location >= STATION_ARRAY_START) AND (i_location <= STATION_ARRAY_END) THEN
    (* Moving to a station *)
    g_station[i_location].unit_id     := i_unit;
    g_station[i_location].change_time := g_time_s;
  ELSIF (i_location >= 1) AND (i_location <= MAX_TRANSPORTERS) THEN
    (* Moving to a transporter *)
    g_transporter[i_location].unit_id := i_unit;
    (* Stamp change_time on the station the unit came from *)
    (* (already done above when clearing old station) *)
  END_IF;
END_IF;

END_FUNCTION_BLOCK
