(* DepSandboxType - Isolated copy of scheduler state for departure planning *)
TYPE DEP_SANDBOX_T :
STRUCT
    Schedule : ARRAY[1..10] OF TSK_SCHEDULE_T;           (* MAX_Units *)
    Batches  : ARRAY[1..10] OF UDT_BatchType;            (* MAX_Units *)
    Programs : ARRAY[1..10] OF UDT_TreatmentProgramType; (* MAX_Units *)
    Tasks    : ARRAY[1..3] OF TSK_QUEUE_T;               (* MAX_Transporters *)
    Valid    : BOOL;
END_STRUCT;
END_TYPE
