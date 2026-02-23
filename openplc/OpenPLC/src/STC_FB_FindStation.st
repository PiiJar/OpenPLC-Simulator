(* ============================================================
   fb_station_lookup.st → STC_FB_FindStation — Find a station by its number
   ============================================================ *)

FUNCTION_BLOCK STC_FB_FindStation
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
  g_stations : ARRAY[101..125] OF STATION_T;
END_VAR
VAR
  st : STATION_T;
END_VAR
  (* Direct lookup by station number — no loop needed *)
  IF (station_number >= 101) AND (station_number <= 125) THEN
    st := g_stations[station_number];
    IF st.tank_id <> 0 THEN
      found := TRUE;
      idx := station_number;
      x_mm := st.x_position;
      stype := st.stn_type;
      device_delay_s := st.device_delay;
      dropping_time_s := st.dropping_time;
      RETURN;
    END_IF;
  END_IF;

  found := FALSE;
  idx := 0;
  x_mm := 0.0;
  stype := 0;
  device_delay_s := 0.0;
  dropping_time_s := 0.0;
END_FUNCTION_BLOCK
