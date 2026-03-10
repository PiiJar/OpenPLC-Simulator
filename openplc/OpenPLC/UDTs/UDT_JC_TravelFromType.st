(* TravelFromType - Travel time lookup: one source station → all destinations *)
TYPE TRAVEL_FROM_T :
STRUCT
    ToTime : ARRAY[1..30] OF INT; (* travel time ×10 = tenths of second, MAX_STATIONS_PER_LINE *)
END_STRUCT;
END_TYPE
