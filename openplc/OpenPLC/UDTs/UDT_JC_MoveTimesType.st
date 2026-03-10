(* MoveTimesType - Precomputed movement times per transporter *)
(* Timed from real motions, not calculated *)
TYPE MOVE_TIMES_T :
STRUCT
    LiftTime : ARRAY[1..30] OF INT;           (* lift time ×10 = tenths of second, MAX_STATIONS_PER_LINE *)
    SinkTime : ARRAY[1..30] OF INT;           (* sink time ×10 = tenths of second, MAX_STATIONS_PER_LINE *)
    Travel   : ARRAY[1..30] OF TRAVEL_FROM_T; (* travel[from].to_s[to] ×10, MAX_STATIONS_PER_LINE *)
END_STRUCT;
END_TYPE
