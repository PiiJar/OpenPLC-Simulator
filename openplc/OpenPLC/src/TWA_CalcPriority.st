(* ============================================================
   TWA_CalcPriority.st — Priority calculation for collision avoidance

   Priority rules (from transporterWorkingArea.js):
     canEvade = FALSE  → 100000 (cannot move, others must avoid)
     phase 3 (to_sink) → 200000 + (99999 - distance_to_target)
     phase 1 (to_lift) → 100000 + (99999 - distance_to_target)
     phase 0 (idle)    → 1

   Returns REAL to avoid DINT compatibility issues.
   Values fit within REAL precision (max ~300000).
   ============================================================ *)

FUNCTION TWA_CalcPriority : REAL
VAR_INPUT
  i_phase     : INT;
  i_can_evade : BOOL;
  i_x_pos     : REAL;
  i_x_target  : REAL;
END_VAR
VAR
  dist : REAL;
END_VAR

IF NOT i_can_evade THEN
  TWA_CalcPriority := 100000.0;
  RETURN;
END_IF;

IF i_phase = 3 THEN
  dist := ABS(i_x_pos - i_x_target);
  IF dist > 99999.0 THEN dist := 99999.0; END_IF;
  TWA_CalcPriority := 200000.0 + (99999.0 - dist);
ELSIF i_phase = 1 THEN
  dist := ABS(i_x_pos - i_x_target);
  IF dist > 99999.0 THEN dist := 99999.0; END_IF;
  TWA_CalcPriority := 100000.0 + (99999.0 - dist);
ELSE
  TWA_CalcPriority := 1.0;
END_IF;

END_FUNCTION
