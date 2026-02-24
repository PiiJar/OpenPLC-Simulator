(* ============================================================
   STC_FB_CalcHorizontalTravel — Horizontal travel time (shared)
   ============================================================
   Calculates only the horizontal travel time between two stations
   (no lift/sink). Used for task sequence gap checks and departure
   idle-slot travel estimates.

   Logically stateless — implemented as FB because MATIEC does
   not allow VAR_EXTERNAL in FUNCTION.

   Used by: TSK_FB_Analyze (TASK_SEQUENCE check), DEP_*
   ============================================================ *)

FUNCTION_BLOCK STC_FB_CalcHorizontalTravel
VAR_INPUT
  i_from_stn : INT;     (* source station number *)
  i_to_stn   : INT;     (* destination station number *)
  i_trans    : INT;      (* transporter index 1..3 *)
END_VAR
VAR_OUTPUT
  o_travel_s : REAL;    (* horizontal travel time in seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_move : ARRAY[1..MAX_TRANSPORTERS] OF MOVE_TIMES_T;
END_VAR
VAR
  from_idx : INT;
  to_idx   : INT;
END_VAR

o_travel_s := 0.0;
IF i_from_stn > 0 AND i_to_stn > 0 AND i_from_stn <> i_to_stn THEN
  from_idx := i_from_stn - 100;
  to_idx   := i_to_stn - 100;
  IF from_idx >= 1 AND from_idx <= 25 AND to_idx >= 1 AND to_idx <= 25
     AND i_trans >= 1 AND i_trans <= 3 THEN
    o_travel_s := g_move[i_trans].travel[from_idx].to_s[to_idx];
  END_IF;
END_IF;

END_FUNCTION_BLOCK
