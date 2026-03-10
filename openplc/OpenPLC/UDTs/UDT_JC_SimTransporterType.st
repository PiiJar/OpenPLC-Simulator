(* SimTransporterType - Simulation-internal transporter data *)
(* Scheduler command params + physics state — NOT in production UDT *)
TYPE SIM_TRANSPORTER_T :
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
END_STRUCT;
END_TYPE
