(* ============================================================
   DEP_FB_CalcOverlap — Overlap station detection
   ============================================================
   Identifies stations where multiple transporters can operate
   (task_area ranges overlap).  A station is marked as overlap
   if two or more different transporters have task_area ranges
   that cover it (either lift or sink range).

   Source: departureScheduler.js computeOverlapStations()

   Used by: DEP_FB_Scheduler (CALC phase)
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_CalcOverlap
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
END_VAR

VAR_EXTERNAL
  g_cfg         : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_dep_overlap : DEP_OVERLAP_T;
END_VAR
VAR
  stn         : INT;
  ti          : INT;
  ai          : INT;
  cover_count : INT;
  covered     : BOOL;
  area        : TASK_AREA_T;
END_VAR

g_dep_overlap.count := 0;

FOR stn := STATION_ARRAY_START TO STATION_ARRAY_END DO
  cover_count := 0;

  FOR ti := 1 TO MAX_TRANSPORTERS DO
    covered := FALSE;
    FOR ai := 1 TO 4 DO
      IF NOT covered THEN
        area := g_cfg[ti].task_area[ai];
        (* Station is covered if within lift OR sink range *)
        IF (area.min_lift > 0 AND stn >= area.min_lift AND stn <= area.max_lift)
           OR (area.min_sink > 0 AND stn >= area.min_sink AND stn <= area.max_sink) THEN
          covered := TRUE;
        END_IF;
      END_IF;
    END_FOR;
    IF covered THEN
      cover_count := cover_count + 1;
    END_IF;
  END_FOR;

  IF cover_count >= 2 THEN
    g_dep_overlap.flags[stn] := TRUE;
    g_dep_overlap.count := g_dep_overlap.count + 1;
  ELSE
    g_dep_overlap.flags[stn] := FALSE;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
