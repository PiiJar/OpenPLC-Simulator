(* GVL_Parameters — Production process data arrays *)
(* Runtime data shared between PLC and HMI/SCADA *)
VAR_GLOBAL
    StationCount       : INT;                                                                              (* configured station count *)
    Stations           : ARRAY[GVL_JC_Constants.MinStationIndex..GVL_JC_Constants.MaxStationIndex] OF UDT_StationType;        (* station configuration *)
    StationLocations   : ARRAY[1..GVL_JC_Constants.MaxStationIndex] OF UDT_UnitLocation;                   (* unit location per station *)
    Transporters       : ARRAY[1..GVL_JC_Constants.MaxTransporters] OF UDT_TransporterType;                (* transporter configuration *)
    TransporterStatus  : ARRAY[1..GVL_JC_Constants.MaxTransporters] OF UDT_TransporterStatusType;          (* transporter runtime status *)
    Units              : ARRAY[1..GVL_JC_Constants.MaxUnits] OF UDT_UnitType;                              (* unit (lifting frame) state *)
    Batches            : ARRAY[1..GVL_JC_Constants.MaxUnits] OF UDT_BatchType;                             (* batch state per unit *)
    TreatmentPrograms  : ARRAY[1..GVL_JC_Constants.MaxUnits] OF UDT_TreatmentProgramType;                  (* treatment program per unit *)
    AvoidStatus        : ARRAY[GVL_JC_Constants.MinStationIndex..GVL_JC_Constants.MaxStationIndex] OF INT; (* AVOID_None/Passable/Block per station *)
END_VAR
