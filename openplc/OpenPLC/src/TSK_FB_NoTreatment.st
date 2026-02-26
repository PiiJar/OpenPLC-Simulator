(* ============================================================
   TSK_FB_NoTreatment — Create no-treatment transfer tasks
   ============================================================
   Scans units that have a target (TO_LOADING, TO_UNLOAD,
   TO_BUFFER, TO_AVOID, etc.) and creates transfer tasks using
   the g_ntt destination table (per target, per transporter).

   Destination lookup:
     1. Search primary stations (g_ntt[trans].target[tgt].stations)
     2. If all occupied → search fallback stations
     3. First free station wins

   Conditions for creating a task:
     - Unit has target <> TO_NONE and <> TO_PROCESS
     - Unit is on a station (location >= 100)
     - Covering transporter is idle (phase = 0, active)
     - A free destination station exists in g_ntt
   ============================================================ *)

FUNCTION_BLOCK TSK_FB_NoTreatment
VAR_INPUT
  i_time_s : LINT;   (* current absolute time (s), unix seconds *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    MAX_PARALLELS       : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
    MAX_UNITS           : INT;
END_VAR

VAR_EXTERNAL
  g_unit        : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_ntt         : ARRAY[1..MAX_TRANSPORTERS] OF NTT_TRANSPORTER_T;
  g_transporter : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_task        : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
END_VAR
VAR
  ui       : INT;     (* unit loop *)
  qi       : INT;     (* queue index *)
  loc      : INT;     (* unit location station *)
  tgt      : INT;     (* unit target *)
  cov_t    : INT;     (* covering transporter *)
  dest     : NTT_DEST_T;  (* destination descriptor for this target+transporter *)
  (* Destination search *)
  dest_stn : INT;     (* destination station *)
  si       : INT;     (* station loop *)
  stn      : INT;     (* candidate station *)
  stn_free : BOOL;
  uj       : INT;     (* inner unit loop for free check *)
  (* Timing *)
  xfer_s   : REAL;    (* total transfer time *)
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
  IF tgt >= 1 AND tgt <= 5 AND tgt <> 3 AND loc >= 100 THEN
    (* Find covering transporter *)
    fb_find(i_lift_stn := loc, i_sink_stn := 0);
    cov_t := fb_find.o_trans_id;

    IF cov_t >= 1 AND cov_t <= MAX_TRANSPORTERS THEN
      (* Check transporter is idle: phase=0, active *)
      IF g_transporter[cov_t].phase = 0 AND g_transporter[cov_t].active THEN

        (* Get destination descriptor for this target + transporter *)
        dest := g_ntt[cov_t].target[tgt];
        dest_stn := 0;

        (* 1. Search primary stations *)
        FOR si := 1 TO dest.station_count DO
          IF dest_stn = 0 THEN
            stn := dest.stations[si];
            IF stn <> loc AND stn >= STATION_ARRAY_START AND stn <= STATION_ARRAY_END THEN
              stn_free := TRUE;
              FOR uj := 1 TO MAX_UNITS DO
                IF g_unit[uj].location = stn AND g_unit[uj].status = 1 THEN
                  stn_free := FALSE;
                END_IF;
              END_FOR;
              IF stn_free THEN
                dest_stn := stn;
              END_IF;
            END_IF;
          END_IF;
        END_FOR;

        (* 2. Search fallback stations if no primary found *)
        IF dest_stn = 0 THEN
          FOR si := 1 TO dest.fallback_count DO
            IF dest_stn = 0 THEN
              stn := dest.fallback_stations[si];
              IF stn <> loc AND stn >= STATION_ARRAY_START AND stn <= STATION_ARRAY_END THEN
                stn_free := TRUE;
                FOR uj := 1 TO MAX_UNITS DO
                  IF g_unit[uj].location = stn AND g_unit[uj].status = 1 THEN
                    stn_free := FALSE;
                  END_IF;
                END_FOR;
                IF stn_free THEN
                  dest_stn := stn;
                END_IF;
              END_IF;
            END_IF;
          END_FOR;
        END_IF;

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
