(* EventMsgType - Generic event message with type-dependent payload *)
(*
   msg_type=1 (TASK_DISPATCHED):
     f[1]=transporter  f[2]=UnitId  f[3]=lift_stn  f[4]=sink_stn
     f[5]=stage  f[6]=batch_code  f[7]=batch_state  f[8]=batch_program
     f[9]=target  f[10]=calc_time_x10  f[11]=min_time_x10  f[12]=max_time_x10

   msg_type=2 (LIFT):
     f[1]=transporter  f[2]=UnitId  f[3]=station  f[4]=batch_code
     f[5]=batch_state  f[6]=batch_program  f[7]=stage
     f[8]=actual_time_x10  f[9]=calc_time_x10  f[10]=min_time_x10
     f[11]=max_time_x10  f[12]=reserved
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
