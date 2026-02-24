(* ============================================================
   TSK_FB_NoTreatment — Create no-treatment transfer tasks
   ============================================================
   Ported from taskScheduler.js TASKS_NO_TREATMENT phase (2204)

   After the task list is stable (no conflicts), scans units
   that have a target (TO_UNLOAD, TO_BUFFER, TO_AVOID, etc.)
   and creates transfer tasks that fit into transporter idle slots.

   Conditions for creating a task:
     - Unit has target <> TO_NONE and <> TO_PROCESS
     - Unit is on a station (location >= 100)
     - Covering transporter is idle (phase = 0, status = 3)
     - Transfer fits within transporter idle gap
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_NoTreatment
VAR_INPUT
  i_time_s : LINT;   (* current absolute time (s), unix seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
    MAX_UNITS           : INT;
END_VAR

VAR_EXTERNAL
  g_unit    : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_transporter : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_cfg      : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_task    : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  g_station : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF STATION_T;
  g_station_count : INT;
END_VAR
VAR
  ui     : INT;     (* unit loop *)
  ai     : INT;     (* task area loop *)
  qi     : INT;     (* queue index *)
  loc    : INT;     (* unit location station *)
  tgt    : INT;     (* unit target *)
  cov_t  : INT;     (* covering transporter *)
  area   : TASK_AREA_T;
  (* Destination search *)
  dest_stn : INT;   (* destination station *)
  si       : INT;   (* station loop *)
  stn_free : BOOL;
  stn_ok   : BOOL;
  (* Timing *)
  xfer_s   : REAL;  (* total transfer time *)
  task_start : LINT;
  task_end   : LINT;
  (* Shared FB instances *)
  fb_find  : STC_FB_FindTransporter;
  fb_xfer  : STC_FB_CalcTransferTime;
END_VAR

FOR ui := 1 TO MAX_UNITS DO
  tgt := g_unit[ui].target;
  loc := g_unit[ui].location;

  (* Skip: no target, target is process (handled by schedule), not on station *)
  IF tgt <> 0 AND tgt <> 3 AND loc >= 100 THEN
    (* Find covering transporter *)
    fb_find(i_lift_stn := loc, i_sink_stn := 0);
    cov_t := fb_find.o_trans_id;

    IF cov_t >= 1 AND cov_t <= 3 THEN
      (* Check transporter is idle: phase=0, active *)
      IF g_transporter[cov_t].phase = 0 AND g_transporter[cov_t].active THEN

        (* Find destination station: first available in transporter area *)
        dest_stn := 0;
        FOR ai := 1 TO 4 DO
          IF dest_stn = 0 THEN
            area := g_cfg[cov_t].task_area[ai];
            IF area.min_sink > 0 THEN
              FOR si := area.min_sink TO area.max_sink DO
                IF dest_stn = 0 AND si <> loc AND si >= STATION_ARRAY_START AND si <= STATION_ARRAY_END THEN
                  (* Check station is free: no unit there *)
                  stn_free := TRUE;
                  FOR qi := 1 TO MAX_UNITS DO
                    IF g_unit[qi].location = si AND g_unit[qi].status = 1 THEN
                      stn_free := FALSE;
                    END_IF;
                  END_FOR;
                  IF stn_free THEN
                    dest_stn := si;
                  END_IF;
                END_IF;
              END_FOR;
            END_IF;
          END_IF;
        END_FOR;

        IF dest_stn > 0 THEN
          (* Calculate timing *)
          fb_xfer(i_from_stn := loc, i_to_stn := dest_stn, i_trans := cov_t);
          xfer_s := fb_xfer.o_total_s;

          task_start := i_time_s;
          task_end   := task_start + REAL_TO_LINT(xfer_s);

          (* Append to queue *)
          qi := g_task[cov_t].count + 1;
          IF qi <= MAX_UNITS THEN
            g_task[cov_t].queue[qi].unit         := ui;
            g_task[cov_t].queue[qi].stage        := 0;  (* no program stage *)
            g_task[cov_t].queue[qi].lift_station := loc;
            g_task[cov_t].queue[qi].sink_station := dest_stn;
            g_task[cov_t].queue[qi].start_time   := task_start;
            g_task[cov_t].queue[qi].finish_time  := task_end;
            g_task[cov_t].queue[qi].calc_time    := 0.0;
            g_task[cov_t].queue[qi].min_time     := 0.0;
            g_task[cov_t].queue[qi].max_time     := 0.0;
            g_task[cov_t].count := qi;
          END_IF;
        END_IF;

      END_IF; (* transporter idle *)
    END_IF; (* covering transporter found *)
  END_IF; (* valid target *)
END_FOR;

END_FUNCTION_BLOCK
