(* ============================================================
   STC_FB_FindTransporter — Find covering transporter (shared)
   ============================================================
   Finds which transporter (1..3) can handle a lift→sink pair
   by checking g_cfg[].task_area[] coverage.

   If i_sink_stn = 0, only lift coverage is checked (used when
   looking for the transporter covering a single station).

   Logically stateless — implemented as FB because MATIEC does
   not allow VAR_EXTERNAL in FUNCTION.

   Used by: TSK_FB_CreateTasks, TSK_FB_NoTreatment,
            TSK_FB_Scheduler, DEP_*
   ============================================================ *)

FUNCTION_BLOCK STC_FB_FindTransporter
VAR_INPUT
  i_lift_stn : INT;     (* lift station number *)
  i_sink_stn : INT;     (* sink station number, 0 = lift-only search *)
END_VAR
VAR_OUTPUT
  o_trans_id : INT;     (* found transporter 1..3, 0 = not found *)
END_VAR
VAR_EXTERNAL
  g_cfg : ARRAY[1..3] OF TRANSPORTER_CFG_T;
END_VAR
VAR
  ti   : INT;
  ai   : INT;
  area : TASK_AREA_T;
  can_lift : BOOL;
  can_sink : BOOL;
END_VAR

o_trans_id := 0;
FOR ti := 1 TO 3 DO
  IF o_trans_id = 0 THEN
    FOR ai := 1 TO 4 DO
      IF o_trans_id = 0 THEN
        area := g_cfg[ti].task_area[ai];
        IF area.min_lift > 0 OR area.max_lift > 0 THEN
          can_lift := (i_lift_stn >= area.min_lift) AND (i_lift_stn <= area.max_lift);
          IF i_sink_stn = 0 THEN
            (* Lift-only coverage search *)
            IF can_lift THEN
              o_trans_id := ti;
            END_IF;
          ELSE
            can_sink := (i_sink_stn >= area.min_sink) AND (i_sink_stn <= area.max_sink);
            IF can_lift AND can_sink THEN
              o_trans_id := ti;
            END_IF;
          END_IF;
        END_IF;
      END_IF;
    END_FOR;
  END_IF;
END_FOR;

END_FUNCTION_BLOCK
