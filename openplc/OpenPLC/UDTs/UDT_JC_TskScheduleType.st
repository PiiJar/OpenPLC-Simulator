(* TskScheduleType - Calculated batch schedule, one per unit *)
TYPE TSK_SCHEDULE_T :
STRUCT
    StageCount : INT;                         (* number of active stages *)
    Stages     : ARRAY[1..30] OF TSK_STAGE_T; (* MAX_STEPS_PER_PROGRAM *)
END_STRUCT;
END_TYPE
