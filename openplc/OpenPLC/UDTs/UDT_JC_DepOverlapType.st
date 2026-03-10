(* DepOverlapType - Stations covered by multiple transporters *)
TYPE UDT_JC_DepOverlapType :
STRUCT
    Flags : ARRAY[101..130] OF BOOL; (* TRUE = station is in overlap zone *)
    Count : INT;
END_STRUCT;
END_TYPE
