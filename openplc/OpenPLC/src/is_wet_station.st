(* ============================================================
   is_wet_station.st — Check if a station type is "wet"
   ============================================================ *)

FUNCTION IsWetStationType : BOOL
VAR_INPUT
  station_type : INT;
END_VAR
  IsWetStationType := (station_type = 1) OR (station_type = 11);
END_FUNCTION
