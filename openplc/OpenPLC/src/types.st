(* ============================================================
   types.st — Auto-generated from UDTs/*.st
   DO NOT EDIT — modify UDT files in UDTs/ directory instead
   ============================================================ *)

(* BatchType - Runtime state of a production batch/charge on a unit *)
TYPE UDT_BatchType :
STRUCT
    BatchCode : INT;  (* batch code - numeric ID *)
    CurStage  : INT;  (* current stage number, 0 = not started *)
    State     : INT;  (* NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2 *)
    ProgId    : INT;  (* treatment program number *)
    StartTime : LINT; (* batch start time (unix seconds) *)
    MinTime   : DINT; (* stage minimum time (seconds) *)
    MaxTime   : DINT; (* stage maximum time (seconds) *)
    CalTime   : DINT; (* stage calculated / target time (seconds) *)
END_STRUCT;
END_TYPE

(* CalibrationType - Calibration teaching data, one per transporter *)
(* Gateway writes plan, PLC fills results *)
TYPE UDT_JC_CalibrationType :
STRUCT
    (* Plan — set by gateway via cfg_cmd=7 *)
    WetStation  : INT;  (* wet station number *)
    DryStation  : INT;  (* dry station number *)

    (* Results — read from g_move after MeasureMoveTimes records them *)
    LiftWetTime : INT;  (* lift time at wet station ×10 = tenths of second *)
    SinkWetTime : INT;  (* sink time at wet station ×10 = tenths of second *)
    LiftDryTime : INT;  (* lift time at dry station ×10 = tenths of second *)
    SinkDryTime : INT;  (* sink time at dry station ×10 = tenths of second *)
    XAccelTime  : INT;  (* measured acceleration time ×10 = tenths of second *)
    XDecelTime  : INT;  (* measured deceleration time ×10 = tenths of second *)
    XMaxSpeed   : DINT; (* measured max X speed mm/s *)
END_STRUCT;
END_TYPE

(* DepDelayActionType - Schedule adjustment to accommodate departure *)
TYPE UDT_JC_DepDelayActionType :
STRUCT
    Stage     : INT;  (* program stage to delay *)
    DelayTime : DINT; (* delay amount (seconds) *)
    Target    : INT;  (* 0=batch cur_stage delay, 1=program stage delay *)
    Valid     : BOOL;
END_STRUCT;
END_TYPE

(* DepFitResultType - Outcome of fitting a departure task into idle slots *)
TYPE UDT_JC_DepFitResultType :
STRUCT
    Fits          : BOOL; (* TRUE = task fits in a slot *)
    DelayTime     : DINT; (* delay needed to make it fit (seconds) *)
    NeedExtraTime : DINT; (* extra time that does not fit (seconds) *)
    TaskEndTime   : LINT; (* calculated task end time (s), unix seconds *)
    SlotIdx       : INT;  (* index of the used idle slot *)
    TransporterId : INT;  (* transporter id that can handle it *)
END_STRUCT;
END_TYPE

(* DepIdleSlotType - Time window where a transporter has no tasks *)
TYPE UDT_JC_DepIdleSlotType :
STRUCT
    StartTime         : LINT; (* idle window start (s), unix seconds *)
    EndTime           : LINT; (* idle window end (s), 0 = open-ended *)
    LiftStationTarget : INT;  (* transporter at this station at idle start *)
    SinkStationTarget : INT;  (* transporter at this station at idle end *)
END_STRUCT;
END_TYPE

(* DepIdleSlotSetType - Collection of idle slots for a transporter *)
TYPE UDT_JC_DepIdleSlotSetType :
STRUCT
    Slots : ARRAY[1..20] OF UDT_JC_DepIdleSlotType; (* DEP_MAX_IDLE_SLOTS *)
    Count : INT;
END_STRUCT;
END_TYPE

(* DepOverlapType - Stations covered by multiple transporters *)
TYPE UDT_JC_DepOverlapType :
STRUCT
    Flags : ARRAY[0..200] OF BOOL; (* TRUE = station is in overlap zone — G09: full domain matching JS *)
    Count : INT;
END_STRUCT;
END_TYPE

(* EventMsgType - Generic event message with type-dependent payload *)
(*
   All events share TaskId in f[1..2] for cross-referencing:
     TaskId = f[1] * 65536 + f[2]  (= g_transporter.TaskId)

   msg_type=1 (TASK_DISPATCHED):
     f[1]=TaskId_Hi  f[2]=TaskId_Lo
     f[3]=transporter  f[4]=UnitId  f[5]=lift_stn  f[6]=sink_stn
     f[7]=stage  f[8]=batch_code
     f[9]=calc_time(s)  f[10]=min_time(s)  f[11]=max_time(s)
     f[12]=xfer_total(s)

   msg_type=2 (LIFT):
     f[1]=TaskId_Hi  f[2]=TaskId_Lo
     f[3]=transporter  f[4]=UnitId  f[5]=lift_stn  f[6]=batch_code
     f[7]=stage  f[8]=actual_time(s)  f[9]=calc_time(s)
     f[10]=min_time(s)  f[11]=max_time(s)  f[12]=xfer_total(s)

   msg_type=3 (TASK_COMPLETE):
     f[1]=TaskId_Hi  f[2]=TaskId_Lo  f[3]=transporter
     f[4]=siirto_nostoasemalle(s)   f[5]=odotus_ennen_nostoa(s)
     f[6]=nosto(s)  f[7]=valutus(s)  f[8]=trip_close(s)
     f[9]=siirto_laskuasemalle(s)  f[10]=trip_open(s)
     f[11]=lasku(s)  f[12]=total(s)
*)
TYPE UDT_JC_EventMsgType :
STRUCT
    Seq     : INT;                 (* unique incrementing sequence number *)
    MsgType : INT;                 (* 1=task_dispatched, 2=lift, ... *)
    TsHi    : INT;                 (* timestamp upper 16 bits (unix s) *)
    TsLo    : INT;                 (* timestamp lower 16 bits *)
    Payload : ARRAY[1..12] OF INT; (* payload — meaning depends on msg_type *)
END_STRUCT;
END_TYPE

(* EventQueueType - Event message queue PLC → Gateway *)
(* Handshake: PLC outputs head message via Modbus.
   Gateway reads it, processes it, writes ack_seq = head.seq.
   PLC sees ack match → advances head, count--. *)
TYPE UDT_JC_EventQueueType :
STRUCT
    Count   : INT;                         (* messages currently in queue (0..10) *)
    Head    : INT;                         (* index of oldest message, 1-based *)
    NextSeq : INT;                         (* next sequence number to assign *)
    Buffer  : ARRAY[1..10] OF UDT_JC_EventMsgType; (* circular buffer *)
END_STRUCT;
END_TYPE

(* NttDestType - No-treatment task destination: primary + fallback stations *)
TYPE UDT_JC_NttDestType :
STRUCT
    Stations         : ARRAY[1..5] OF INT; (* primary stations, up to MAX_STATIONS_PER_STEP *)
    StationCount     : INT;                (* how many primary stations are valid *)
    FallbackStations : ARRAY[1..5] OF INT; (* fallback stations, up to MAX_STATIONS_PER_STEP *)
    FallbackCount    : INT;                (* how many fallback stations are valid *)
END_STRUCT;
END_TYPE

(* NttTransporterType - No-treatment per-transporter destination map *)
TYPE UDT_JC_NttTransporterType :
STRUCT
    (* Index = target code: 1=TO_LOADING, 2=(reserved), 3=TO_PROCESS, 4=TO_UNLOAD, 5=TO_AVOID,
    6=TO_EMPTY_BUFFER, 7=TO_LOADED_BUFFER, 8=TO_PROCESSED_BUFFER *)
    Target : ARRAY[1..8] OF UDT_JC_NttDestType;
END_STRUCT;
END_TYPE

(* SimTransporterType - Simulation-internal transporter data *)
(* Scheduler command params + physics state — NOT in production UDT *)
TYPE UDT_JC_SimTransporterType :
STRUCT
    RunningTaskId   : LINT; (* copied from TaskId when accepted *)
    TreatmentTime   : DINT; (* treatment duration (seconds) *)
    MinTime         : DINT; (* minimum treatment time (seconds) *)
    MaxTime         : DINT; (* maximum treatment time (seconds) *)
    LiftDeviceDelay : INT;  (* lift station device delay ×10 = tenths of second *)
    SinkDeviceDelay : INT;  (* sink station device delay ×10 = tenths of second *)
    XVelocity       : DINT; (* X velocity mm/s *)
    ZStage          : INT;  (* Z motion sub-phase *)
    ZTimer          : REAL; (* Z motion timer *)
    NttPrimary      : INT;  (* 1 = current task sink is NTT primary, 0 = otherwise *)
END_STRUCT;
END_TYPE

(* TravelFromType - Travel time lookup: one source station → all destinations *)
TYPE UDT_JC_TravelFromType :
STRUCT
    ToTime : ARRAY[1..30] OF INT; (* travel time ×10 = tenths of second, MAX_STATIONS_PER_LINE *)
END_STRUCT;
END_TYPE

(* MoveTimesType - Precomputed movement times per transporter *)
(* Timed from real motions, not calculated *)
TYPE UDT_JC_MoveTimesType :
STRUCT
    LiftTime : ARRAY[1..30] OF INT;           (* lift time ×10 = tenths of second, MAX_STATIONS_PER_LINE *)
    SinkTime : ARRAY[1..30] OF INT;           (* sink time ×10 = tenths of second, MAX_STATIONS_PER_LINE *)
    Travel   : ARRAY[1..30] OF UDT_JC_TravelFromType; (* travel[from].to_s[to] ×10, MAX_STATIONS_PER_LINE *)
END_STRUCT;
END_TYPE

(* TskCheckedType - Conflict analysis working data for FB_AnalyzeConflicts *)
TYPE UDT_JC_TskCheckedType :
STRUCT
    Unit        : INT;  (* batch unit index *)
    Stage       : INT;  (* program stage *)
    Transporter : INT;  (* assigned transporter *)
    StartTime   : LINT; (* task start (s), unix seconds *)
    EndTime     : LINT; (* task end (s), unix seconds *)
    FlexDown    : DINT; (* available advance margin (seconds) *)
    FlexUp      : DINT; (* available delay margin (seconds) *)
    XMin        : DINT; (* X-area minimum (mm) *)
    XMax        : DINT; (* X-area maximum (mm) *)
    IsConflict  : BOOL; (* TRUE if this task is in conflict *)
END_STRUCT;
END_TYPE

(* TskLockType - Oscillation lock: prevents resolve from advancing & delaying same stage *)
TYPE UDT_JC_TskLockType :
STRUCT
    Unit      : INT; (* batch unit index, 0 = empty slot *)
    Stage     : INT; (* program stage *)
    Direction : INT; (* 1=ADVANCE, 2=DELAY *)
END_STRUCT;
END_TYPE

(* TskStageType - Calculated batch schedule stage *)
(* Times are absolute epoch-offset seconds (g_time_s reference frame) *)
TYPE UDT_JC_TskStageType :
STRUCT
    Station      : INT;  (* station number, 0 = unused stage *)
    ProgramStage : INT;  (* batch program stage number (1..N), 0 = pre-position entry *)
    EntryTime    : LINT; (* absolute arrival time (s), unix seconds *)
    ExitTime     : LINT; (* absolute departure time (s), unix seconds *)
    MinTime      : DINT; (* minimum treatment time (seconds) *)
    CalcTime     : DINT; (* calculated target treatment time (seconds) *)
    MaxTime      : DINT; (* maximum treatment time (seconds) *)
    TransferTime : DINT; (* transfer time from previous station (seconds) *)
END_STRUCT;
END_TYPE

(* TskScheduleType - Calculated batch schedule, one per unit *)
TYPE UDT_JC_TskScheduleType :
STRUCT
    StageCount : INT;                         (* number of active stages *)
    Stages     : ARRAY[1..30] OF UDT_JC_TskStageType; (* MAX_STEPS_PER_PROGRAM *)
END_STRUCT;
END_TYPE

(* TskStretchType - Resolve decision to persist: delay/advance amount for a program stage *)
TYPE UDT_JC_TskStretchType :
STRUCT
    Unit   : INT;  (* unit index 1..10, 0 = empty slot *)
    Stage  : INT;  (* program stage 1..N *)
    DelayS : DINT; (* seconds: positive = delay, negative = advance *)
END_STRUCT;
END_TYPE

(* TskTaskType - Transporter task: pickup/putdown assignment *)
TYPE UDT_JC_TskTaskType :
STRUCT
    Unit              : INT;  (* unit index 1..10, 0 = no task *)
    Stage             : INT;  (* program stage that created this task *)
    LiftStationTarget : INT;  (* station to pick up from *)
    SinkStationTarget : INT;  (* station to put down to *)
    StartTime         : LINT; (* absolute time task begins (s), unix seconds *)
    FinishTime        : LINT; (* absolute time task completes (s), unix seconds *)
    CalcTime          : DINT; (* treatment calc_time for flex (seconds) *)
    MinTime           : DINT; (* treatment min_time for flex_down (seconds) *)
    MaxTime           : DINT; (* treatment max_time for flex_up (seconds) *)
    NttPrimary        : INT;  (* 1 = sink is NTT primary destination, 0 = all other cases *)
END_STRUCT;
END_TYPE

(* TskQueueType - Transporter task queue *)
TYPE UDT_JC_TskQueueType :
STRUCT
    Count : INT;                        (* number of active tasks *)
    Queue : ARRAY[1..10] OF UDT_JC_TskTaskType; (* task slots, MAX_TASK_QUEUE *)
END_STRUCT;
END_TYPE

(* UnitSnapType - Snapshot of unit state, pre-computed once per cycle by NoTreatmentStates *)
TYPE UDT_JC_UnitSnapType :
STRUCT
    IsActive   : BOOL; (* status <> NOT_USED *)
    Location   : INT;  (* location *)
    LocationOp : INT;  (* station operation at location *)
    Target     : INT;  (* target *)
    HasBatch   : BOOL; (* batch_code <> 0 *)
    BatchState : INT;  (* batch state *)
    CurStage   : INT;  (* current stage from g_batch *)
    InBuffer   : BOOL; (* loc operation 44..47 *)
    OnStation  : BOOL; (* loc in STATION_ARRAY range *)
    Elapsed    : LINT; (* time at station, 0 if not on station *)
    CalTime    : DINT; (* cal_time for current stage (seconds) *)
END_STRUCT;
END_TYPE

TYPE UDT_StationType :
STRUCT
    StationId            : INT;  (* Primary key *)
    TankId               : INT;  (* Reference to tanks.TankId *)
    IsInUse              : BOOL; (* Station enabled *)
    StationType          : INT;  (* 0=Reserve, 1=Buffer, 2=Process, etc. *)

    (* Position in mm - used for collision avoidance and drive targets *)
    XPosition            : DINT; (* X position mm *)
    YPosition            : DINT; (* Y position mm *)
    ZPosition            : DINT; (* Z position mm *)
    LiftSinkZone         : INT;  (* Lift/sink zone *)
    AvoidDistance        : INT;  (* Avoid distance *)
    TakeOutDistance      : INT;  (* Take out distance *)
    DrippingTime         : INT;  (* Dripping time ×10 = tenths of second *)
    DeviceDelay          : INT;  (* Device delay ×10 = tenths of second *)
    DryWet               : INT;  (* 0=dry, 1=wet *)

    (* Cross transport parameters *)
    Crosstransport       : INT;  (* Cross transport index *)
    CrossTransportTime   : INT;  (* Cross transport time s *)
    ChangeStation        : INT;  (* Change station index *)
    DeviceConfig         : INT;  (* Device configuration *)

    (* Control indices - references to control arrays *)
    Temp_Index           : INT;  (* Temperature control index *)
    Level_Index          : INT;  (* Level control index *)
    Cond_Index           : INT;  (* Conductivity control index *)

    (* Rotation parameters *)
    HasAutomaticRotation : BOOL; (* TRUE = chemical tank (sink at 45°), FALSE = loading/buffer (sink at 0° vertical) *)
END_STRUCT;
END_TYPE

(*******************************************************************************
 * DUT Name: UDT_TankType
 * Description: Tank configuration - identity and sub-equipment mapping
 *              References control loop IDs and equipment IDs for FB_Tank
 *              ID > 0 means equipment is present (replaces Has* booleans)
 *              All IDs reference their respective GVL_Parameters arrays
 *
 * Usage:
 *   - TankId is primary key
 *   - Set unused equipment IDs to 0 to disable
 *   - Composite FBs resolve their own device IDs from control params
 *
 * Version History:
 * Version  | Date       | Author      | Description
 * ----------------------------------------------------------------------
 * 2.0      | 2026-02-26 |             | Merged UDT_TankControlType sub-equipment IDs into UDT_TankType.
 *                                     | Added: TemperatureControl x2, Measurement x3, Pump x3,
 *                                     | ChemicalDosing x3, Mixer, Blower, Rectifier.
 *                                     | Removed Has* booleans (ID > 0 = present).
 *                                     | Removed drain control (no longer in codebase).
 * 1.0      | 2026-01-13 |             | Initial version - identity only
 *****************************************************************************)
TYPE UDT_TankType :
STRUCT
    (* === Tank Identification === *)
    TankId                : INT;    (* Primary key *)
    EquipmentCode         : STRING; (* Equipment code matching PID *)
    TankName              : STRING; (* Optional descriptive name *)
    TypeId                : INT;    (* Tank type identifier *)
    IsInUse               : BOOL;   (* TRUE = in use *)
    LineId                : INT;    (* Process line identifier *)
    GroupId               : INT;    (* Reference to tank_group.GroupId *)
    RinseId               : INT;    (* Rinse tank reference *)
    FilterUnitId          : INT;    (* Filter unit reference *)
    Color                 : STRING; (* Display color RGB hex *)

    (* === Position in mm === *)
    XPosition             : DINT;   (* X position mm *)
    YPosition             : DINT;   (* Y position mm *)
    ZPosition             : DINT;   (* Z position mm *)

    (* === Temperature Control (x2) === *)
    TemperatureControl1Id : INT;    (* Reference to GVL_Parameters.TemperatureControls[id], 0 = none *)
    TemperatureControl2Id : INT;    (* Reference to GVL_Parameters.TemperatureControls[id], 0 = none *)

    (* === Level Control === *)
    LevelControlId        : INT;    (* Reference to GVL_Parameters.LevelControls[id], 0 = none *)

    (* === pH Control === *)
    PHControlId           : INT;    (* Reference to GVL_Parameters.PHControls[id], 0 = none *)

    (* === Conductivity Control === *)
    ConductivityControlId : INT;    (* Reference to GVL_Parameters.ConductivityControls[id], 0 = none *)

    (* === Measurements (x3) === *)
    Measurement1Id        : INT;    (* Reference to GVL_Parameters.Measurements[id], 0 = none *)
    Measurement2Id        : INT;    (* Reference to GVL_Parameters.Measurements[id], 0 = none *)
    Measurement3Id        : INT;    (* Reference to GVL_Parameters.Measurements[id], 0 = none *)

    (* === Pumps (x3) === *)
    Pump1Idx              : INT;    (* Reference to GVL_Parameters.Pumps[idx], 0 = none (e.g. filter pump) *)
    Pump2Idx              : INT;    (* Reference to GVL_Parameters.Pumps[idx], 0 = none *)
    Pump3Idx              : INT;    (* Reference to GVL_Parameters.Pumps[idx], 0 = none *)

    (* === Chemical Dosing (x3) === *)
    ChemicalDosing1Id     : INT;    (* Reference to GVL_Parameters.ChemicalDosings[id], 0 = none *)
    ChemicalDosing2Id     : INT;    (* Reference to GVL_Parameters.ChemicalDosings[id], 0 = none *)
    ChemicalDosing3Id     : INT;    (* Reference to GVL_Parameters.ChemicalDosings[id], 0 = none *)

    (* === Agitation === *)
    AgitationId           : INT;    (* Reference to GVL_Parameters.Agitations[id], 0 = none *)

    (* === Mixer === *)
    MixerId               : INT;    (* Reference to GVL_Parameters.Mixers[id], 0 = none *)

    (* === Blower === *)
    BlowerId              : INT;    (* Reference to GVL_Parameters.Blowers[id], 0 = none *)

    (* === Cover === *)
    CoverId               : INT;    (* Reference to GVL_Parameters.Covers[id], 0 = none *)

    (* === Rectifier === *)
    RectifierId           : INT;    (* Reference to GVL_Parameters.Rectifiers[id], 0 = none *)
END_STRUCT;
END_TYPE

(* TaskArea - Lift/sink station ranges per transporter task area slot *)
TYPE UDT_TaskArea :
STRUCT
    MinLift : INT; (* minimum lift station number *)
    MaxLift : INT; (* maximum lift station number *)
    MinSink : INT; (* minimum sink station number *)
    MaxSink : INT; (* maximum sink station number *)
END_STRUCT;
END_TYPE

(* TransporterStatusType - Runtime transporter status data structure *)
TYPE UDT_TransporterStatusType :
STRUCT
    TransporterId            : INT;  (* Reference to transporter config *)

    (* Current positions in mm *)
    XPosition                : DINT; (* Current X position mm *)
    YPosition                : DINT; (* Current Y position mm *)
    ZPosition                : DINT; (* Current Z position mm *)

    (* Station tracking *)
    CurrentStation           : INT;  (* Current station *)
    LiftStationTarget        : INT;  (* Lift target station *)
    SinkStationTarget        : INT;  (* Sink target station *)

    (* Phase and Status for collision avoidance *)
    Status                   : INT;  (* 0=off, 1=fault, 2=manual, 3=semi, 4=auto *)
    Phase                    : INT;  (* 0=idle, 1=to_source, 2=lift, 3=to_sink, 4=sink *)
    TaskId                   : LINT; (* Current task ID *)
    TaskRemainingTime        : DINT; (* Remaining time for current task s *)
    LiftStationRemainingTime : DINT; (* Remaining time at lift station s *)
    DrippingTime             : INT;  (* Dripping time ×10 = tenths of second *)

    (* Target positions *)
    XDriveTarget             : DINT; (* X drive target position mm *)
    XFinalTarget             : DINT; (* Final X target position mm *)
    YDriveTarget             : DINT; (* Y drive target position mm *)
    YFinalTarget             : DINT; (* Final Y target position mm *)

    (* Working area limits - calculated by FB_TransporterWorkingArea *)
    XMinDriveLimit           : DINT; (* Minimum X drive limit mm *)
    XMaxDriveLimit           : DINT; (* Maximum X drive limit mm *)

    (* Runtime status *)
    Busy                     : BOOL; (* Transporter busy *)
    Fault                    : BOOL; (* Transporter fault *)
    AtPosition               : BOOL; (* At target position *)
    CanEvade                 : BOOL; (* Can perform evasion maneuver *)
    Priority                 : DINT; (* Collision avoidance priority *)

    (* Additional status fields for FB_TransporterController *)
    IsActive                 : BOOL; (* Transporter is actively executing a task *)
    IsCarrying               : BOOL; (* Transporter is carrying product *)
END_STRUCT;
END_TYPE

(* TransporterType - Consolidated transporter configuration *)
(* Merged from: UDT_TransporterType, UDT_TransporterConfigType, UDT_Transporter2DConfigType *)

TYPE UDT_TransporterType :
STRUCT
    (* ===== Identity ===== *)
    TransporterId            : INT;                         (* Primary key *)
    EquipmentCode            : STRING;                      (* Equipment code *)
    AliasNumber              : INT;                         (* Alias number e.g. 21 = 200-line 1st *)
    IsInUse                  : BOOL;                        (* Transporter enabled *)
    Model                    : INT;                         (* 1=1D (X only), 2=2D (X+Y), 3=3D (X+Y+Z) *)
    LineNumber               : INT;                         (* Line number / StationLine *)
    MinStation               : INT;                         (* Minimum station *)
    MaxStation               : INT;                         (* Maximum station *)

    (* ===== Task Areas (per transporter-per-line) ===== *)
    TaskArea                 : ARRAY[1..3] OF UDT_TaskArea; (* lift/sink station ranges per slot *)

    (* ===== Sensor Limits ===== *)
    ZSensorLowLimit          : INT;                         (* Z sensor low limit *)
    ZSensorHighLimit         : INT;                         (* Z sensor high limit *)
    XSensorLineLimitBackward : INT;                         (* X sensor backward limit *)
    XSensorLineLimitForward  : INT;                         (* X sensor forward limit *)

    (* ===== Position Limits ===== *)
    DrivePosMin              : DINT;                        (* Minimum allowed drive position mm *)
    DrivePosMax              : DINT;                        (* Maximum allowed drive position mm *)
    CrashPosMin              : DINT;                        (* Crash position minimum mm *)
    CrashPosMax              : DINT;                        (* Crash position maximum mm *)
    YMinDriveLimit           : DINT;                        (* Minimum Y drive limit mm *)
    YMaxDriveLimit           : DINT;                        (* Maximum Y drive limit mm *)

    (* ===== Position Tolerances ===== *)
    PosTolerance_X           : DINT;                        (* X position acceptance tolerance mm *)
    PosTolerance_Y           : DINT;                        (* Y position acceptance tolerance mm *)
    PosLiftSinkTolerance_X   : DINT;                        (* Position monitoring window in lift/sink mm *)

    (* ===== Position Validation ===== *)
    PosValidationEnable_X    : BOOL;                        (* Enable X-axis position validation *)
    PosMaxChangeRate_X       : DINT;                        (* Max position change rate mm/s *)
    PosJumpThreshold_X       : DINT;                        (* Max single-cycle position change mm *)
    PosValidationEnable_Z    : BOOL;                        (* Enable Z-axis position validation *)
    PosMaxChangeRate_Z       : DINT;                        (* Max Z position change rate mm/s *)
    PosJumpThreshold_Z       : DINT;                        (* Max single-cycle Z position change mm *)

    (* ===== Collision Avoidance ===== *)
    CollisionWidth           : DINT;                        (* Physical width for collision detection mm *)
    AvoidanceWidth           : DINT;                        (* Safety distance to maintain from other transporters mm *)

    (* ===== Absolute to Position Conversion ===== *)
    AbsToPosDirection_X      : DINT;                        (* X axis direction: 1.0=normal, -1.0=inverted *)
    AbsToPosOffset_X         : DINT;                        (* X axis position offset mm *)
    AbsToPosDirection_Y      : DINT;                        (* Y axis direction: 1.0=normal, -1.0=inverted *)
    AbsToPosOffset_Y         : DINT;                        (* Y axis position offset mm *)
    PosMaxSensor_X           : DINT;                        (* X QR sensor max reading mm, 0=disabled *)
    PosMaxSensor_Y           : DINT;                        (* Y QR sensor max reading mm, 0=disabled *)

    (* ===== Maximum Speeds per Axis 0..100% ===== *)
    SpeedMax_X               : DINT;                        (* X axis maximum speed *)
    SpeedMax_Y               : DINT;                        (* Y axis maximum speed *)
    SpeedMax_Z               : DINT;                        (* Z axis maximum speed *)
    MaximumSpeed             : INT;                         (* Legacy: Maximum speed INT *)

    (* ===== Semi-Auto Speeds per Axis 0..100% ===== *)
    SpeedSemiAuto_X          : DINT;                        (* X axis semi-auto speed *)
    SpeedSemiAuto_Y          : DINT;                        (* Y axis semi-auto speed *)
    SpeedSemiAuto_Z          : DINT;                        (* Z axis semi-auto speed *)

    (* ===== Manual Speeds per Axis 0..100% ===== *)
    SpeedManual_X            : DINT;                        (* X axis manual speed *)
    SpeedManualFast_X        : DINT;                        (* X axis manual fast speed *)
    SpeedManual_Y            : DINT;                        (* Y axis manual speed *)
    SpeedManualFast_Y        : DINT;                        (* Y axis manual fast speed *)
    SpeedManual_Z            : DINT;                        (* Z axis manual speed *)
    SpeedManualFast_Z        : DINT;                        (* Z axis manual fast speed *)

    (* ===== Deceleration and Crawl Parameters ===== *)
    DecelerationDistance_X   : DINT;                        (* Distance for ramp-down start mm *)
    CrawlDistance_X          : DINT;                        (* Distance for crawl speed start mm *)
    SpeedCrawl_X             : DINT;                        (* Crawl speed near target *)

    (* ===== Acceleration per Axis 0..100% ===== *)
    Acceleration_X           : DINT;                        (* X axis acceleration *)
    Acceleration_Y           : DINT;                        (* Y axis acceleration *)
    Acceleration_Z           : DINT;                        (* Z axis acceleration *)

    (* ===== Deceleration per Axis 0..100% ===== *)
    Deceleration_X           : DINT;                        (* X axis deceleration *)
    Deceleration_Y           : DINT;                        (* Y axis deceleration *)
    Deceleration_Z           : DINT;                        (* Z axis deceleration *)

    (* ===== Lift Speeds - Z Axis ===== *)
    SpeedLiftSlow_Z          : DINT;                        (* Lift slow speed *)
    SpeedLiftMid_Z           : DINT;                        (* Lift mid speed *)
    SpeedLiftFast_Z          : DINT;                        (* Lift fast speed *)

    (* ===== Sink Speeds - Z Axis ===== *)
    SpeedSinkSlow_Z          : DINT;                        (* Sink slow speed *)
    SpeedSinkMid_Z           : DINT;                        (* Sink mid speed *)
    SpeedSinkFast_Z          : DINT;                        (* Sink fast speed *)

    (* ===== Wet Lift Timing ===== *)
    LiftWetSlowTime          : DINT;                        (* Wet lift slow drive time s *)
    LiftWetMidTime           : DINT;                        (* Wet lift mid drive time s *)
    LiftWetFastTime          : DINT;                        (* Wet lift fast drive time s *)

    (* ===== Dry Lift Timing ===== *)
    LiftDrySlowTime          : DINT;                        (* Dry lift slow drive time s *)
    LiftDryFastTime          : DINT;                        (* Dry lift fast drive time s *)

    (* ===== Sink Timing ===== *)
    SinkWetMidTime           : DINT;                        (* Wet sink mid drive time s *)
    SinkWetFastTime          : DINT;                        (* Wet sink fast drive time s *)
    SinkDryFastTime          : DINT;                        (* Dry sink fast drive time s *)

    (* ===== Hooking Feature ===== *)
    HookingInUse             : BOOL;                        (* TRUE to enable hooking offset functionality *)
    HookingOffset            : DINT;                        (* Hooking positioning offset mm, only used when HookingInUse = TRUE *)

    (* ===== Feature Flags ===== *)
    BarrelRotationInUse      : BOOL;                        (* TRUE if barrel rotation feature is used *)
    DripTrayInUse            : BOOL;                        (* TRUE if transporter has a drip tray *)
    MovesEmptyAtDown         : BOOL;                        (* TRUE = transporter travels at down position when empty (default behavior) *)

    (* ===== Z-Axis Encoder Position Control ===== *)
    ZAxisHasEncoder          : BOOL;                        (* TRUE = use encoder position for Z transitions, FALSE = use limit switches + timers *)
    ZPosUp                   : DINT;                        (* Z position at full up / home position mm *)
    ZPosDown                 : DINT;                        (* Z position at full down / in tank mm *)
    ZPosSlowUp               : DINT;                        (* Z position to switch from fast to slow when going up mm *)
    ZPosSlowDown             : DINT;                        (* Z position to switch from fast to slow when going down mm *)
    ZPosSlowEnd              : DINT;                        (* Z slow zone end position mm *)
    ZPosProduct              : DINT;                        (* Z position where product engages/disengages the hook mm *)
    ZPosDrip                 : DINT;                        (* Z position for dripping above tank mm *)
    ZPosTolerance            : DINT;                        (* Z position acceptance tolerance mm *)

    (* ===== Stall Detection ===== *)
    StallFilterTime_X        : DINT;                        (* X-axis stall alarm delay s, e.g. 2.0 *)
    StallMinDistance_X       : DINT;                        (* X-axis minimum expected movement during filter time mm, e.g. 2.0 *)
    StallFilterTime_Z        : DINT;                        (* Z-axis stall alarm delay s *)
    StallMinDistance_Z       : DINT;                        (* Z-axis minimum expected movement during filter time mm *)

    (* ===== Legacy Aliases - for backward compatibility ===== *)
    SpeedLiftMax             : DINT;                        (* Maximum lift speed = SpeedMax_Z *)
    SpeedDriveMax            : DINT;                        (* Maximum drive speed = SpeedMax_X *)
    DriveAcceleration        : DINT;                        (* Drive acceleration = Acceleration_X *)
    DriveDeceleration        : DINT;                        (* Drive deceleration = Deceleration_X *)

    (* ===== Drip tray ===== *)
    DripTrayDelay            : INT;                         (* Drip tray open/close delay x10 = tenths of second *)
END_STRUCT;
END_TYPE

(* TreatmentProgramStepType - Step within a treatment program, optimized for OPC UA transfer *)
(* Stations: Parallel groups fill multiple entries, serial/single groups fill only index 0 *)
(* StationCount indicates number of valid entries in Stations array *)
TYPE UDT_TreatmentProgramStepType :
STRUCT
    MinTime      : DINT;               (* Minimum treatment time in seconds *)
    MaxTime      : DINT;               (* Maximum treatment time in seconds *)
    CalTime      : DINT;               (* Calculated treatment time in seconds *)
    StationCount : INT;                (* Number of valid stations in Stations array *)
    Stations     : ARRAY[0..4] OF INT; (* Station indexes for this step *)
END_STRUCT;
END_TYPE

(* TreatmentProgramType - Complete treatment program with embedded steps for OPC UA transfer *)
(* StepCount indicates number of valid steps in the Steps array *)
TYPE UDT_TreatmentProgramType :
STRUCT
    ProgramId   : INT;                                          (* Treatment program number *)
    ProgramName : STRING;                                       (* Treatment program name *)
    StepCount   : INT;                                          (* Number of valid steps in Steps array *)
    Steps       : ARRAY[0..30] OF UDT_TreatmentProgramStepType; (* Embedded step array *)
END_STRUCT;
END_TYPE

(* DepPendingWriteType - Data to commit from sandbox to globals after ACTIVATE *)
TYPE UDT_JC_DepPendingWriteType :
STRUCT
    Valid        : BOOL;
    Programs     : ARRAY[1..10] OF UDT_TreatmentProgramType; (* MAX_Units *)
    Schedule     : ARRAY[1..10] OF UDT_JC_TskScheduleType;           (* MAX_Units *)
    BatchUnit    : INT;                                      (* activated batch: unit index *)
    BatchStage   : INT;                                      (* activated batch: new cur_stage *)
    BatchState   : INT;                                      (* activated batch: new state (IN_PROCESS=1) *)
    BatchMinTime : DINT;                                     (* stage 0 min_time for activated batch (seconds) *)
    BatchMaxTime : DINT;                                     (* stage 0 max_time for activated batch (seconds) *)
    BatchCalTime : DINT;                                     (* stage 0 cal_time for activated batch (seconds) *)
    TimeStamp    : LINT;                                     (* activation time (s), unix seconds *)
END_STRUCT;
END_TYPE

(* DepSandboxType - Isolated copy of scheduler state for departure planning *)
TYPE UDT_JC_DepSandboxType :
STRUCT
    Schedule : ARRAY[1..10] OF UDT_JC_TskScheduleType;           (* MAX_Units *)
    Batches  : ARRAY[1..10] OF UDT_BatchType;            (* MAX_Units *)
    Programs : ARRAY[1..10] OF UDT_TreatmentProgramType; (* MAX_Units *)
    Tasks    : ARRAY[1..3] OF UDT_JC_TskQueueType;               (* MAX_Transporters *)
    Valid    : BOOL;
END_STRUCT;
END_TYPE

TYPE UDT_UnitLocation :
STRUCT
    UnitId     : INT;  (* unit currently at this station, 0 = none *)
    ChangeTime : LINT; (* timestamp of last unit arrival/departure (unix seconds) *)
END_STRUCT;
END_TYPE

(* UDT_UnitType - Tracks a single bar/basket unit on the treatment line *)
TYPE UDT_UnitType :
STRUCT
    Location : INT; (* station number where unit currently is *)
    Status   : INT; (* NOT_USED=0, USED=1 *)
    Target   : INT; (* TO_NONE=0, TO_LOADING=1, TO_BUFFER=2, TO_PROCESS=3, TO_UNLOAD=4, TO_AVOID=5 *)
END_STRUCT;
END_TYPE
