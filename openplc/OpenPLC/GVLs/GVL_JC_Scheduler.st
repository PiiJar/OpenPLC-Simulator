(* GVL_JC_Scheduler — Simulator-internal global variables *)
(* These variables exist only in the JC simulator, NOT in production TIA PLC *)
(* Source of truth for globals.st generation *)
VAR_GLOBAL
    (* ===== Simulation Transporter State ===== *)
    SimTransporter         : ARRAY[1..MAX_Transporters] OF UDT_JC_SimTransporterType;           (* physics + scheduler command state *)

    (* ===== No-Treatment Task Destinations ===== *)
    NttTransporter         : ARRAY[1..MAX_Transporters] OF UDT_JC_NttTransporterType;           (* no-treatment task destinations *)

    (* ===== Precomputed Movement Times ===== *)
    MoveTimes              : ARRAY[1..MAX_Transporters] OF UDT_JC_MoveTimesType;                (* precomputed movement times per transporter *)

    (* ===== Unit Schedule ===== *)
    Schedule               : ARRAY[1..MAX_Units] OF UDT_JC_TskScheduleType;                     (* calculated schedule per unit *)

    (* ===== Task Queues ===== *)
    TaskQueue              : ARRAY[1..MAX_Transporters] OF UDT_JC_TskQueueType;                 (* task queue per transporter *)

    (* ===== Departure Scheduler State ===== *)
    DepSandbox             : UDT_JC_DepSandboxType;                                              (* isolated copy for planning *)
    DepIdleSlot            : ARRAY[1..MAX_Transporters] OF UDT_JC_DepIdleSlotSetType;         (* idle slots per transporter *)
    DepWaiting             : ARRAY[1..DEP_MAX_WAITING] OF INT;                          (* waiting batch unit indices *)
    DepWaitingCount        : INT;                                                        (* number of waiting batches *)
    DepOverlap             : UDT_JC_DepOverlapType;                                              (* overlap station flags *)
    DepPending             : UDT_JC_DepPendingWriteType;                                        (* ACTIVATE write buffer *)
    DepActivated           : BOOL;                                                       (* handshake TSK ← DEP *)
    DepStable              : BOOL;                                                       (* handshake TSK → DEP: task list stable *)

    (* ===== Calibration State ===== *)
    Calibration            : ARRAY[1..MAX_Transporters] OF UDT_JC_CalibrationType;               (* calibration plan + results per transporter *)
    CalibrationActive      : BOOL;                                                       (* TRUE during calibration — inhibits schedulers *)

    (* ===== Production Queue ===== *)
    ProductionQueue        : INT;                                                        (* 1=batches in queue, 0=queue empty *)

    (* ===== Unix Time ===== *)
    TimeSeconds            : LINT;                                                       (* absolute time in unix seconds *)

    (* ===== Event Queue ===== *)
    EventQueue             : UDT_JC_EventQueueType;                                              (* circular event buffer *)
    EventPending           : UDT_JC_EventMsgType;                                                (* staging slot — written by other FBs *)
    EventPendingValid      : BOOL;                                                       (* TRUE = pending message ready to enqueue *)
END_VAR
