(* ============================================================
   STC_FindTransporter — Find covering transporter (FB)
   ============================================================
   Finds which transporter (1..3) can handle a lift→sink pair
   by checking cfg[].task_area[] coverage.

   If i_sink_stn = 0, only lift coverage is checked (used when
   looking for the transporter covering a single station).

   NOTE: Kept as FUNCTION_BLOCK because MATIEC's C code generator
   cannot handle ARRAY OF STRUCT as FUNCTION VAR_INPUT parameter.
   (C++ __SET_VAR macro produces type mismatch.)

   Used by: TSK_FB_CreateTasks, TSK_FB_Scheduler, DEP_FB_Scheduler
   ============================================================ *)

FUNCTION_BLOCK STC_FindTransporter
VAR_INPUT
  i_lift_stn : INT;     (* lift station number *)
  i_sink_stn : INT;     (* sink station number, 0 = lift-only search *)
END_VAR
VAR_OUTPUT
  o_trans : INT;         (* transporter ID 1..3, 0 = not found *)
END_VAR
VAR_EXTERNAL CONSTANT
  MAX_TRANSPORTERS : INT;
END_VAR
VAR_EXTERNAL
  g_cfg : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
END_VAR
VAR
  ti       : INT;
  ai       : INT;
  area     : TASK_AREA_T;
  can_lift : BOOL;
  can_sink : BOOL;
END_VAR

o_trans := 0;
FOR ti := 1 TO MAX_TRANSPORTERS DO
  IF o_trans = 0 THEN
    FOR ai := 1 TO 4 DO
      IF o_trans = 0 THEN
        area := g_cfg[ti].task_area[ai];
        IF area.min_lift > 0 OR area.max_lift > 0 THEN
          can_lift := (i_lift_stn >= area.min_lift) AND (i_lift_stn <= area.max_lift);
          IF i_sink_stn = 0 THEN
            IF can_lift THEN
              o_trans := ti;
            END_IF;
          ELSE
            can_sink := (i_sink_stn >= area.min_sink) AND (i_sink_stn <= area.max_sink);
            IF can_lift AND can_sink THEN
              o_trans := ti;
            END_IF;
          END_IF;
        END_IF;
      END_IF;
    END_FOR;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
