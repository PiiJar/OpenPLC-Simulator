(* TreatmentProgramType - Complete treatment program with embedded steps for OPC UA transfer *)
(* StepCount indicates number of valid steps in the Steps array *)
TYPE UDT_TreatmentProgramType :
STRUCT
    RecordId    : INT;                                                                           (* Primary key / program ID *)
    ProgramName : STRING(30);                                                                    (* Treatment program name *)
    StepCount   : INT;                                                                           (* Number of valid steps in Steps array *)
    Steps       : ARRAY[0..GVL_Constants.MAX_STEPS_PER_PROGRAM] OF UDT_TreatmentProgramStepType; (* Embedded step array *)
END_STRUCT
END_TYPE
