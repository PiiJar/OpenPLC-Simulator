(* ============================================================
   fb_station_lookup.st — Find a station by its number
   ============================================================ *)

FUNCTION_BLOCK FB_StationLookup
VAR_INPUT
  station_number : INT;
END_VAR
VAR_OUTPUT
  found           : BOOL;
  idx             : INT;
  x_mm            : REAL;
  stype           : INT;
  device_delay_s  : REAL;
  dropping_time_s : REAL;
END_VAR
VAR_EXTERNAL
  g_station_count : INT;
  g_stations      : ARRAY[1..21] OF STATION_T;
END_VAR
VAR
  i      : INT;
  tmp_st : STATION_T;
END_VAR
  found := FALSE;
  idx := 0;
  x_mm := 0.0;
  stype := 0;
  device_delay_s := 0.0;
  dropping_time_s := 0.0;

  FOR i := 1 TO g_station_count DO
    tmp_st := g_stations[i];
    IF tmp_st.number = station_number THEN
      found := TRUE;
      idx := i;
      x_mm := tmp_st.x_mm;
      stype := tmp_st.station_type;
      device_delay_s := tmp_st.device_delay_s;
      dropping_time_s := tmp_st.dropping_time_s;
      RETURN;
    END_IF;
  END_FOR;
END_FUNCTION_BLOCK
