(* TreatmentProgramStepType - Step within a treatment program, optimized for OPC UA transfer *)
(* StationIndexes: Parallel groups fill multiple entries, serial/single groups fill only index 0 *)
(* StationCount indicates number of valid entries in StationIndexes array *)
TYPE UDT_TreatmentProgramStepType :
STRUCT
    StepOrder      : INT;                                                  (* Step order/sequence number *)
    MinTime        : DINT;                                                 (* Minimum treatment time in seconds *)
    MaxTime        : DINT;                                                 (* Maximum treatment time in seconds *)
    CalcTime       : INT;                                                  (* Calculated treatment time in seconds *)
    StationCount   : INT;                                                  (* Number of valid stations in StationIndexes array *)
    StationIndexes : ARRAY[0..GVL_Constants.MAX_STATIONS_PER_STEP] OF INT; (* Station indexes for this step *)
END_STRUCT
END_TYPE
