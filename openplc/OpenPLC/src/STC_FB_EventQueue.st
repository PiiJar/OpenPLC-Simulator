(* ============================================================
   STC_FB_EventQueue — Generic event message queue handler
   ============================================================
   Manages a circular 10-slot event queue (g_event) and the
   Modbus handshake with Gateway.

   - enqueue: caller writes msg fields to g_event_pending,
     then sets g_event_pending_valid := TRUE.
     This FB picks it up and adds to queue.
   - dequeue: copies head message to QW Modbus registers.
     Gateway reads, writes ack_seq back via IW.
     On ack match → advance head, count--.

   Called every PLC scan from plc_prg (always, not gated by
   scheduler turn).

   Handshake protocol:
     PLC:  qw_event_out_count, qw_event_out_seq, qw_event_out_type,
           qw_event_out_ts_hi/lo, qw_event_out_f1..f12 → Modbus holding regs
     GW:   iw_event_ack_seq → Modbus input register
     When qw_event_out_seq = iw_event_ack_seq: message consumed → next.
   ============================================================ *)

FUNCTION_BLOCK STC_FB_EventQueue
VAR_EXTERNAL
  g_event          : EVENT_QUEUE_T;
  (* Pending message — set by other FBs, consumed here *)
  g_event_pending       : EVENT_MSG_T;
  g_event_pending_valid : BOOL;
  (* Modbus output — head message visible to gateway *)
  qw_event_out_count   : INT;
  qw_event_out_seq     : INT;
  qw_event_out_type    : INT;
  qw_event_out_ts_hi   : INT;
  qw_event_out_ts_lo   : INT;
  qw_event_out_f1      : INT;
  qw_event_out_f2      : INT;
  qw_event_out_f3      : INT;
  qw_event_out_f4      : INT;
  qw_event_out_f5      : INT;
  qw_event_out_f6      : INT;
  qw_event_out_f7      : INT;
  qw_event_out_f8      : INT;
  qw_event_out_f9      : INT;
  qw_event_out_f10     : INT;
  qw_event_out_f11     : INT;
  qw_event_out_f12     : INT;
  (* Modbus input — gateway ack *)
  iw_event_ack_seq     : INT;
END_VAR
VAR
  tail : INT;   (* insertion index *)
END_VAR

(* ── 1. Enqueue: pick up pending message if queue not full ── *)
IF g_event_pending_valid AND g_event.Count < 10 THEN
  (* Calculate tail position in circular buffer *)
  tail := ((g_event.Head - 1 + g_event.Count) MOD 10) + 1;

  (* Assign sequence number *)
  g_event_pending.Seq := g_event.NextSeq;
  g_event.NextSeq := g_event.NextSeq + 1;
  IF g_event.NextSeq > 32000 THEN
    g_event.NextSeq := 1;  (* wrap to avoid INT overflow *)
  END_IF;

  (* Store in buffer *)
  g_event.Buffer[tail] := g_event_pending;
  g_event.Count := g_event.Count + 1;

  (* Clear pending flag *)
  g_event_pending_valid := FALSE;
END_IF;

(* ── 2. Dequeue: check gateway ack for head message ── *)
IF g_event.Count > 0 THEN
  IF iw_event_ack_seq = g_event.Buffer[g_event.Head].Seq THEN
    (* Gateway consumed this message — advance head *)
    g_event.Head := (g_event.Head MOD 10) + 1;
    g_event.Count := g_event.Count - 1;
  END_IF;
END_IF;

(* ── 3. Publish: copy head message to Modbus QW registers ── *)
qw_event_out_count := g_event.Count;

IF g_event.Count > 0 THEN
  qw_event_out_seq    := g_event.Buffer[g_event.Head].Seq;
  qw_event_out_type   := g_event.Buffer[g_event.Head].MsgType;
  qw_event_out_ts_hi  := g_event.Buffer[g_event.Head].TsHi;
  qw_event_out_ts_lo  := g_event.Buffer[g_event.Head].TsLo;
  qw_event_out_f1     := g_event.Buffer[g_event.Head].Payload[1];
  qw_event_out_f2     := g_event.Buffer[g_event.Head].Payload[2];
  qw_event_out_f3     := g_event.Buffer[g_event.Head].Payload[3];
  qw_event_out_f4     := g_event.Buffer[g_event.Head].Payload[4];
  qw_event_out_f5     := g_event.Buffer[g_event.Head].Payload[5];
  qw_event_out_f6     := g_event.Buffer[g_event.Head].Payload[6];
  qw_event_out_f7     := g_event.Buffer[g_event.Head].Payload[7];
  qw_event_out_f8     := g_event.Buffer[g_event.Head].Payload[8];
  qw_event_out_f9     := g_event.Buffer[g_event.Head].Payload[9];
  qw_event_out_f10    := g_event.Buffer[g_event.Head].Payload[10];
  qw_event_out_f11    := g_event.Buffer[g_event.Head].Payload[11];
  qw_event_out_f12    := g_event.Buffer[g_event.Head].Payload[12];
ELSE
  (* Queue empty — clear output *)
  qw_event_out_seq    := 0;
  qw_event_out_type   := 0;
  qw_event_out_ts_hi  := 0;
  qw_event_out_ts_lo  := 0;
  qw_event_out_f1     := 0;
  qw_event_out_f2     := 0;
  qw_event_out_f3     := 0;
  qw_event_out_f4     := 0;
  qw_event_out_f5     := 0;
  qw_event_out_f6     := 0;
  qw_event_out_f7     := 0;
  qw_event_out_f8     := 0;
  qw_event_out_f9     := 0;
  qw_event_out_f10    := 0;
  qw_event_out_f11    := 0;
  qw_event_out_f12    := 0;
END_IF;

END_FUNCTION_BLOCK
