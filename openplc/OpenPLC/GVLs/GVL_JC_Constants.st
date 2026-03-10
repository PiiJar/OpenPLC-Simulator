(* GVL_JC_Constants — Simulator-internal global constants *)
(* Layout limits, scheduler parameters, and enumerated values *)
(* Source of truth for globals.st constant generation *)
VAR_GLOBAL CONSTANT

    (* ===== Layout Hierarchy Limits ===== *)
    (* Line is the top level: a plant has 1..MaxLines production lines.
       Each line has stations and transporters.
       Station numbering: Line N stations = N*100+1 .. N*100+MaxStationsPerLine
         Line 1: 101..130,  Line 2: 201..230, etc.
       Station number IS the array index → direct access. *)
    MaxLines                : INT  := 1;   (* max production lines in a plant *)
    MaxStationsPerLine      : INT  := 30;  (* max stations per line *)
    MaxTransportersPerLine  : INT  := 3;   (* max transporters per line *)
    MinStationIndex         : INT  := 100; (* first valid station index *)
    MaxStationIndex         : INT  := 130; (* MaxLines*100 + MaxStationsPerLine *)

    (* ===== Derived Absolute Limits ===== *)
    MaxTransporters         : INT  := 3;   (* absolute max transporters in a plant *)
    MaxUnits                : INT  := 10;  (* max units (lifting frames / hooks) *)
    MaxStationsPerStep      : INT  := 5;   (* max parallel stations per program stage *)
    MaxStepsPerProgram      : INT  := 30;  (* max stages in a treatment program *)
    MaxTaskQueue            : INT  := 60;  (* max tasks per transporter queue *)

    (* ===== Algorithm / Scheduler Limits ===== *)
    DepMaxIdleSlots         : INT  := 20;  (* max idle slots per transporter *)
    DepMaxDelayActions      : INT  := 20;  (* max delay actions per cycle *)
    DepMaxWaiting           : INT  := 5;   (* max waiting batches *)
    MinWorkingArea          : DINT := 20;  (* mm — TWA minimum working area *)

    (* ===== Enumerated Constants ===== *)

    (* Unit status *)
    UnitUsed                : INT  := 1;   (* unit in use *)
    UnitNotUsed             : INT  := 0;   (* unit not in use *)

    (* Unit state *)
    UnitEmpty               : INT  := 0;   (* unit is empty *)
    UnitFull                : INT  := 1;   (* unit is full *)

    (* Unit target *)
    TargetNone              : INT  := 0;   (* no target *)
    TargetLoading           : INT  := 1;   (* target: loading station *)
    TargetBuffer            : INT  := 2;   (* target: buffer station *)
    TargetProcess           : INT  := 3;   (* target: process station *)
    TargetUnload            : INT  := 4;   (* target: unloading station *)
    TargetAvoid             : INT  := 5;   (* target: avoidance position *)

    (* Station kind *)
    KindDry                 : INT  := 0;   (* dry station *)
    KindWet                 : INT  := 1;   (* wet station *)

    (* Station operation — logistics *)
    OpLoading               : INT  := 40;  (* loading operation *)
    OpUnloading             : INT  := 41;  (* unloading operation *)
    OpLoadingUnloading      : INT  := 42;  (* combined loading/unloading *)

    (* Batch state *)
    BatchNotProcessed       : INT  := 0;   (* batch not yet processed *)
    BatchInProcess          : INT  := 1;   (* batch currently in process *)
    BatchProcessed          : INT  := 2;   (* batch processing complete *)

    (* Avoid status for stations (TWA) *)
    AvoidNone               : INT  := 0;   (* station not avoided *)
    AvoidPassable           : INT  := 1;   (* pass through allowed, no stop *)
    AvoidBlock              : INT  := 2;   (* hard block, cannot pass *)
END_VAR
