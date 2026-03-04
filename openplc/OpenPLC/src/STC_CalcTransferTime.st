(* ============================================================
   STC_CalcTransferTime — Total transfer time (FUNCTION)
   ============================================================
   Calculates total transfer time (lift + horizontal travel + sink)
   between two stations using precomputed move time table.

   Converted from FUNCTION_BLOCK (STC_FB_CalcTransferTime) to
   FUNCTION: the caller passes the specific transporter's
   MOVE_TIMES_T instead of using VAR_EXTERNAL g_move.

   Returns total_s only (component times lift_s/travel_s/sink_s
   are not used by any caller in the codebase).

   Used by: TSK_FB_CalcSchedule, TSK_FB_NoTreatment, DEP_FB_Scheduler
   ============================================================ *)

FUNCTION STC_CalcTransferTime : REAL
VAR_INPUT
  i_from_stn : INT;     (* source station, e.g. 105 *)
  i_to_stn   : INT;     (* destination station, e.g. 112 *)
  i_move     : MOVE_TIMES_T;   (* transporter's precomputed move times *)
END_VAR
VAR
  from_idx : INT;
  to_idx   : INT;
END_VAR

STC_CalcTransferTime := 0.0;
IF i_from_stn > 0 AND i_from_stn <> i_to_stn THEN
  from_idx := i_from_stn - 100;
  to_idx   := i_to_stn - 100;
  IF from_idx >= 1 AND from_idx <= 25 AND to_idx >= 1 AND to_idx <= 25 THEN
    STC_CalcTransferTime :=
      i_move.lift_s[from_idx]
      + i_move.travel[from_idx].to_s[to_idx]
      + i_move.sink_s[to_idx];
  END_IF;
END_IF;

END_FUNCTION
