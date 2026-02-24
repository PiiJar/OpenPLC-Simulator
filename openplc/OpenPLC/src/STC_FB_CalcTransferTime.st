(* ============================================================
   STC_FB_CalcTransferTime — Transfer time calculation (shared)
   ============================================================
   Calculates total transfer time (lift + horizontal travel + sink)
   between two stations using precomputed g_move table.

   Logically stateless — implemented as FB because MATIEC does
   not allow VAR_EXTERNAL in FUNCTION.

   Used by: TSK_FB_CalcSchedule, TSK_FB_NoTreatment, DEP_*
   ============================================================ *)

FUNCTION_BLOCK STC_FB_CalcTransferTime
VAR_INPUT
  i_from_stn : INT;     (* source station, e.g. 105 *)
  i_to_stn   : INT;     (* destination station, e.g. 112 *)
  i_trans    : INT;      (* transporter index 1..3 *)
END_VAR
VAR_OUTPUT
  o_total_s  : REAL;    (* lift + travel + sink *)
  o_lift_s   : REAL;
  o_travel_s : REAL;
  o_sink_s   : REAL;
END_VAR
VAR_EXTERNAL CONSTANT
    TRANSPORTERS : INT;
END_VAR

VAR_EXTERNAL
  g_move : ARRAY[1..TRANSPORTERS] OF MOVE_TIMES_T;
END_VAR
VAR
  from_idx : INT;
  to_idx   : INT;
END_VAR

o_total_s  := 0.0;
o_lift_s   := 0.0;
o_travel_s := 0.0;
o_sink_s   := 0.0;

IF i_from_stn > 0 AND i_from_stn <> i_to_stn THEN
  from_idx := i_from_stn - 100;
  to_idx   := i_to_stn - 100;
  IF from_idx >= 1 AND from_idx <= 25 AND to_idx >= 1 AND to_idx <= 25
     AND i_trans >= 1 AND i_trans <= 3 THEN
    o_lift_s   := g_move[i_trans].lift_s[from_idx];
    o_travel_s := g_move[i_trans].travel[from_idx].to_s[to_idx];
    o_sink_s   := g_move[i_trans].sink_s[to_idx];
    o_total_s  := o_lift_s + o_travel_s + o_sink_s;
  END_IF;
END_IF;

END_FUNCTION_BLOCK
