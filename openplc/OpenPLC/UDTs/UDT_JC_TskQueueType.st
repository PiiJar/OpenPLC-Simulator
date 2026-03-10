(* TskQueueType - Transporter task queue *)
TYPE TSK_QUEUE_T :
STRUCT
    Count : INT;                        (* number of active tasks *)
    Queue : ARRAY[1..10] OF TSK_TASK_T; (* task slots, MAX_TASK_QUEUE *)
END_STRUCT;
END_TYPE
