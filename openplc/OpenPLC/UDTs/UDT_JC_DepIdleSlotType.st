(* DepIdleSlotType - Time window where a transporter has no tasks *)
TYPE DEP_IDLE_SLOT_T :
STRUCT
    StartTime         : LINT; (* idle window start (s), unix seconds *)
    EndTime           : LINT; (* idle window end (s), 0 = open-ended *)
    LiftStationTarget : INT;  (* transporter at this station at idle start *)
    SinkStationTarget : INT;  (* transporter at this station at idle end *)
END_STRUCT;
END_TYPE
