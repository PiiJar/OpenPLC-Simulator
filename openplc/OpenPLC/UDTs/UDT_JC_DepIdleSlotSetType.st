(* DepIdleSlotSetType - Collection of idle slots for a transporter *)
TYPE DEP_IDLE_SLOT_SET_T :
STRUCT
    Slots : ARRAY[1..20] OF DEP_IDLE_SLOT_T; (* DEP_MAX_IDLE_SLOTS *)
    Count : INT;
END_STRUCT;
END_TYPE
