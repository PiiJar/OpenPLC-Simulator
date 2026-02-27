(* ============================================================
   STC_FB_DispatchTask — Validate and dispatch tasks to transporters
   ============================================================
   Called every PLC scan from MainScheduler (before TSK/DEP).
   For each idle transporter with queued tasks:

     1. Skip if transporter not idle (phase <> 0) or queue empty
     2. Time check: is start_time close enough?
        travel_time_to_lift + 3s >= time_until_start → proceed
     3. Sink station free check:
        a) Original sink free → use it
        b) Not free → search alternative parallel stations
           (from g_program[].stages[] or g_ntt[] for stage=0)
        c) Pick the station with oldest change_time (longest empty)
        d) No free alternative → skip, don't dispatch
     4. Conflict check: no other active transporter targeting
        same lift or sink station
     5. Dispatch: write task_id, lift_station, sink_station
        to g_transporter → RunTasks picks it up

   Used by: STC_FB_MainScheduler
   ============================================================ *)

FUNCTION_BLOCK STC_FB_DispatchTask
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    MAX_UNITS           : INT;
    MAX_PARALLELS       : INT;
    MAX_STAGES          : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
END_VAR
VAR_EXTERNAL
  g_transporter : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_task        : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  g_station     : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF STATION_T;
  g_unit        : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_program     : ARRAY[1..MAX_UNITS] OF TREATMENT_PROGRAM_T;
  g_ntt         : ARRAY[1..MAX_TRANSPORTERS] OF NTT_TRANSPORTER_T;
  g_batch       : ARRAY[1..MAX_UNITS] OF BATCH_T;
  g_move        : ARRAY[1..MAX_TRANSPORTERS] OF MOVE_TIMES_T;
  g_time_s      : LINT;
  g_event_pending       : EVENT_MSG_T;
  g_event_pending_valid : BOOL;
END_VAR
VAR
  ti           : INT;     (* transporter loop *)
  (* Task fields — read from queue[1] to avoid struct copy *)
  t_unit       : INT;
  t_stage      : INT;
  t_lift       : INT;
  t_sink       : INT;
  t_start      : LINT;
  t_calc_time  : REAL;
  (* Time check *)
  travel_s     : REAL;
  margin_s     : LINT;
  from_idx     : INT;
  to_idx       : INT;
  (* Sink search *)
  sink_stn     : INT;
  sink_free    : BOOL;
  best_stn     : INT;
  best_change  : LINT;
  si           : INT;
  cand_stn     : INT;
  cand_free    : BOOL;
  uj           : INT;
  tgt          : INT;
  ntt_idx      : INT;     (* resolved NTT index (buffer 6/7/8) *)
  ntt_cnt      : INT;
  ntt_fb_cnt   : INT;
  (* Conflict check *)
  conflict     : BOOL;
  cj           : INT;
  task_min     : INT;     (* min station of our proposed task *)
  task_max     : INT;     (* max station of our proposed task *)
  (* Shift-down after dispatch *)
  sh           : INT;
END_VAR

FOR ti := 1 TO MAX_TRANSPORTERS DO

  (* ── 1. Skip if not idle or queue empty ── *)
  IF g_transporter[ti].phase = 0 AND g_task[ti].count >= 1 THEN

    (* Read task fields from queue position 1 *)
    t_unit      := g_task[ti].queue[1].unit;
    t_stage     := g_task[ti].queue[1].stage;
    t_lift      := g_task[ti].queue[1].lift_station;
    t_sink      := g_task[ti].queue[1].sink_station;
    t_start     := g_task[ti].queue[1].start_time;
    t_calc_time := g_task[ti].queue[1].calc_time;

    (* ── 2. Time check ── *)
    travel_s := 0.0;
    IF g_transporter[ti].current_station > 0 AND t_lift > 0
       AND g_transporter[ti].current_station <> t_lift THEN
      from_idx := g_transporter[ti].current_station - 100;
      to_idx   := t_lift - 100;
      IF from_idx >= 1 AND from_idx <= 30 AND to_idx >= 1 AND to_idx <= 30 THEN
        travel_s := g_move[ti].travel[from_idx].to_s[to_idx];
      END_IF;
    END_IF;

    margin_s := t_start - g_time_s;

    IF margin_s <= REAL_TO_LINT(travel_s) + 3 THEN

      (* ── 3. Sink station free check ── *)
      sink_stn := t_sink;
      sink_free := FALSE;

      IF sink_stn >= STATION_ARRAY_START AND sink_stn <= STATION_ARRAY_END THEN
        sink_free := TRUE;
        FOR uj := 1 TO MAX_UNITS DO
          IF g_unit[uj].location = sink_stn AND g_unit[uj].status = 1 THEN
            sink_free := FALSE;
          END_IF;
        END_FOR;
      END_IF;

      IF NOT sink_free THEN
        (* Search alternative parallel stations *)
        best_stn := 0;
        best_change := LINT#2000000000;

        IF t_stage >= 1 AND t_stage <= MAX_STAGES
           AND t_unit >= 1 AND t_unit <= MAX_UNITS THEN
          (* Treatment task — look in g_program for parallel stations *)
          FOR si := 1 TO MAX_PARALLELS DO
            cand_stn := g_program[t_unit].stages[t_stage].stations[si];
            IF cand_stn > 0 AND cand_stn <> t_sink THEN
              IF cand_stn >= STATION_ARRAY_START AND cand_stn <= STATION_ARRAY_END THEN
                cand_free := TRUE;
                FOR uj := 1 TO MAX_UNITS DO
                  IF g_unit[uj].location = cand_stn AND g_unit[uj].status = 1 THEN
                    cand_free := FALSE;
                  END_IF;
                END_FOR;
                IF cand_free THEN
                  IF g_station[cand_stn].change_time < best_change THEN
                    best_change := g_station[cand_stn].change_time;
                    best_stn := cand_stn;
                  END_IF;
                END_IF;
              END_IF;
            END_IF;
          END_FOR;

        ELSIF t_stage = 0 AND t_unit >= 1 AND t_unit <= MAX_UNITS THEN
          (* No-treatment task — look in g_ntt for alternatives *)
          tgt := g_unit[t_unit].target;
          IF tgt >= 1 AND tgt <= 5 THEN
            (* Resolve buffer NTT index like NoTreatment does *)
            IF tgt = 2 THEN
              IF g_batch[t_unit].batch_code = 0 THEN
                ntt_idx := 6;
              ELSIF g_batch[t_unit].state = 2 THEN
                ntt_idx := 8;
              ELSE
                ntt_idx := 7;
              END_IF;
            ELSE
              ntt_idx := tgt;
            END_IF;
            (* Check primary stations *)
            ntt_cnt := g_ntt[ti].target[ntt_idx].station_count;
            FOR si := 1 TO ntt_cnt DO
              IF si <= MAX_PARALLELS THEN
                cand_stn := g_ntt[ti].target[ntt_idx].stations[si];
                IF cand_stn > 0 AND cand_stn <> t_sink THEN
                  IF cand_stn >= STATION_ARRAY_START AND cand_stn <= STATION_ARRAY_END THEN
                    cand_free := TRUE;
                    FOR uj := 1 TO MAX_UNITS DO
                      IF g_unit[uj].location = cand_stn AND g_unit[uj].status = 1 THEN
                        cand_free := FALSE;
                      END_IF;
                    END_FOR;
                    IF cand_free THEN
                      IF g_station[cand_stn].change_time < best_change THEN
                        best_change := g_station[cand_stn].change_time;
                        best_stn := cand_stn;
                      END_IF;
                    END_IF;
                  END_IF;
                END_IF;
              END_IF;
            END_FOR;
            (* Check fallback stations *)
            ntt_fb_cnt := g_ntt[ti].target[ntt_idx].fallback_count;
            FOR si := 1 TO ntt_fb_cnt DO
              IF si <= MAX_PARALLELS THEN
                cand_stn := g_ntt[ti].target[ntt_idx].fallback_stations[si];
                IF cand_stn > 0 AND cand_stn <> t_sink THEN
                  IF cand_stn >= STATION_ARRAY_START AND cand_stn <= STATION_ARRAY_END THEN
                    cand_free := TRUE;
                    FOR uj := 1 TO MAX_UNITS DO
                      IF g_unit[uj].location = cand_stn AND g_unit[uj].status = 1 THEN
                        cand_free := FALSE;
                      END_IF;
                    END_FOR;
                    IF cand_free THEN
                      IF g_station[cand_stn].change_time < best_change THEN
                        best_change := g_station[cand_stn].change_time;
                        best_stn := cand_stn;
                      END_IF;
                    END_IF;
                  END_IF;
                END_IF;
              END_IF;
            END_FOR;
          END_IF;
        END_IF;

        IF best_stn > 0 THEN
          sink_stn := best_stn;
          sink_free := TRUE;
        END_IF;
      END_IF;  (* NOT sink_free *)

      IF sink_free THEN

        (* ── 4. Conflict check ── *)
        (* Check against other transporters' ACTIVE tasks (phase>0).
           Two rules:
           a) T2's entire task (lift AND sink) is inside our task
              range [task_min..task_max] → conflict.
              Example: our 114→101 range [101,114]
                T2 114→113: both in [101,114] → conflict
                T2 114→117: 117 outside     → no conflict (going away)
           b) T2 delivers (sink) to one of our exact stations
              from outside our range → conflict.
              Example: T2 120→114, 114 is our lift → conflict *)
        conflict := FALSE;

        IF t_lift <= sink_stn THEN
          task_min := t_lift;
          task_max := sink_stn;
        ELSE
          task_min := sink_stn;
          task_max := t_lift;
        END_IF;

        FOR cj := 1 TO MAX_TRANSPORTERS DO
          IF cj <> ti AND g_transporter[cj].phase > 0 THEN

            (* a) T2's entire active task inside our range → conflict *)
            IF g_transporter[cj].lift_station >= task_min
               AND g_transporter[cj].lift_station <= task_max
               AND g_transporter[cj].sink_station >= task_min
               AND g_transporter[cj].sink_station <= task_max THEN
              conflict := TRUE;
            END_IF;

            (* b) T2 delivers to one of our exact stations → conflict *)
            IF g_transporter[cj].sink_station = t_lift
               OR g_transporter[cj].sink_station = sink_stn THEN
              conflict := TRUE;
            END_IF;

          END_IF;
        END_FOR;

        IF NOT conflict THEN
          (* ── 5. Dispatch: assign task to transporter ── *)
          g_transporter[ti].task_id      := t_start;
          g_transporter[ti].lift_station := t_lift;
          g_transporter[ti].sink_station := sink_stn;
          g_transporter[ti].unit_id      := t_unit;
          g_transporter[ti].treatment_time := t_calc_time;
          g_transporter[ti].min_time := g_task[ti].queue[1].min_time;
          g_transporter[ti].max_time := g_task[ti].queue[1].max_time;
          g_transporter[ti].remaining_time := t_calc_time;

          (* ── Emit TASK_DISPATCHED event (msg_type=1) ── *)
          IF NOT g_event_pending_valid THEN
            g_event_pending.msg_type := 1;
            g_event_pending.ts_hi := LINT_TO_INT(g_time_s / LINT#65536);
            g_event_pending.ts_lo := LINT_TO_INT(g_time_s MOD LINT#65536);
            g_event_pending.f[1]  := ti;
            g_event_pending.f[2]  := t_unit;
            g_event_pending.f[3]  := t_lift;
            g_event_pending.f[4]  := sink_stn;
            g_event_pending.f[5]  := t_stage;
            g_event_pending.f[6]  := g_batch[t_unit].batch_code;
            g_event_pending.f[7]  := g_batch[t_unit].state;
            g_event_pending.f[8]  := g_batch[t_unit].prog_id;
            g_event_pending.f[9]  := g_unit[t_unit].target;
            g_event_pending.f[10] := REAL_TO_INT(t_calc_time * 10.0);
            g_event_pending.f[11] := REAL_TO_INT(g_task[ti].queue[1].min_time * 10.0);
            g_event_pending.f[12] := REAL_TO_INT(g_task[ti].queue[1].max_time * 10.0);
            g_event_pending_valid := TRUE;
          END_IF;

          (* Copy station-specific timing from config *)
          IF t_lift >= STATION_ARRAY_START AND t_lift <= STATION_ARRAY_END THEN
            g_transporter[ti].dropping_time := g_station[t_lift].dropping_time;
            g_transporter[ti].lift_device_delay := g_station[t_lift].device_delay;
          END_IF;
          IF sink_stn >= STATION_ARRAY_START AND sink_stn <= STATION_ARRAY_END THEN
            g_transporter[ti].sink_device_delay := g_station[sink_stn].device_delay;
          END_IF;

          (* Shift queue: remove position 1, move rest up *)
          FOR sh := 2 TO g_task[ti].count DO
            g_task[ti].queue[sh - 1] := g_task[ti].queue[sh];
          END_FOR;
          (* Clear last slot *)
          g_task[ti].queue[g_task[ti].count].unit := 0;
          g_task[ti].queue[g_task[ti].count].stage := 0;
          g_task[ti].queue[g_task[ti].count].lift_station := 0;
          g_task[ti].queue[g_task[ti].count].sink_station := 0;
          g_task[ti].queue[g_task[ti].count].start_time := 0;
          g_task[ti].queue[g_task[ti].count].finish_time := 0;
          g_task[ti].queue[g_task[ti].count].calc_time := 0.0;
          g_task[ti].queue[g_task[ti].count].min_time := 0.0;
          g_task[ti].queue[g_task[ti].count].max_time := 0.0;
          g_task[ti].count := g_task[ti].count - 1;

        END_IF;  (* NOT conflict *)

      END_IF;  (* sink_free *)

    END_IF;  (* time check *)

  END_IF;  (* idle + queue *)

END_FOR;

END_FUNCTION_BLOCK
