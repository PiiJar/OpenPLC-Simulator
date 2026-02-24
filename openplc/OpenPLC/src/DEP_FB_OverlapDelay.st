(* ============================================================
   DEP_FB_OverlapDelay — Overlap conflict delay calculation
   ============================================================
   When a new task uses a station in the overlap zone (covered
   by multiple transporters), checks for time conflicts with
   tasks on OTHER transporters at the same station.

   Iteratively calculates the minimum delay needed to avoid
   overlap conflicts (max 20 iterations).

   Source: departureScheduler.js calculateOverlapDelay()

   Used by: DEP_FB_Scheduler / DEP_FB_FitTaskToSlot
   ============================================================ *)

FUNCTION_BLOCK DEP_FB_OverlapDelay
VAR_INPUT
  i_lift_stn   : INT;     (* task lift station *)
  i_sink_stn   : INT;     (* task sink station *)
  i_trans_id   : INT;     (* task transporter id *)
  i_task_start : LINT;    (* task start time (s), already shifted *)
  i_task_end   : LINT;    (* task end time (s), already shifted *)
  i_margin_s   : REAL;    (* conflict margin (s), default 1.0 *)
END_VAR
VAR_OUTPUT
  o_delay_s : REAL;       (* total delay needed (s), 0 = no conflict *)
END_VAR
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
    MAX_UNITS           : INT;
    DEP_MAX_DELAY_ACTS  : INT;
END_VAR

VAR_EXTERNAL
  g_task       : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  g_dep_overlap : DEP_OVERLAP_T;
END_VAR
VAR
  lift_is_overlap : BOOL;
  sink_is_overlap : BOOL;
  round    : INT;
  ti       : INT;    (* transporter index *)
  qi       : INT;    (* queue index *)
  max_conf : REAL;   (* maximum conflict in this round *)
  t_start  : LINT;   (* shifted task start *)
  t_end    : LINT;   (* shifted task end *)
  e_start  : LINT;   (* existing task start *)
  e_end    : LINT;   (* existing task end *)
  e_lift   : INT;
  e_sink   : INT;
  has_ovlp : BOOL;
  needed   : REAL;
END_VAR

o_delay_s := 0.0;

(* Check if lift/sink are in overlap zone *)
IF i_lift_stn >= STATION_ARRAY_START AND i_lift_stn <= STATION_ARRAY_END THEN
  lift_is_overlap := g_dep_overlap.flags[i_lift_stn];
ELSE
  lift_is_overlap := FALSE;
END_IF;
IF i_sink_stn >= STATION_ARRAY_START AND i_sink_stn <= STATION_ARRAY_END THEN
  sink_is_overlap := g_dep_overlap.flags[i_sink_stn];
ELSE
  sink_is_overlap := FALSE;
END_IF;

(* No overlap stations involved → no delay *)
IF NOT lift_is_overlap AND NOT sink_is_overlap THEN
  RETURN;
END_IF;

(* Iterative conflict resolution — max DEP_MAX_DELAY_ACTS rounds *)
FOR round := 1 TO DEP_MAX_DELAY_ACTS DO
  max_conf := 0.0;
  t_start  := i_task_start + REAL_TO_LINT(o_delay_s);
  t_end    := i_task_end + REAL_TO_LINT(o_delay_s);

  (* Check all tasks on OTHER transporters *)
  FOR ti := 1 TO MAX_TRANSPORTERS DO
    IF ti <> i_trans_id THEN
      FOR qi := 1 TO MAX_UNITS DO
        IF qi > g_task[ti].count THEN
          EXIT;
        END_IF;

        e_lift  := g_task[ti].queue[qi].lift_station;
        e_sink  := g_task[ti].queue[qi].sink_station;
        e_start := g_task[ti].queue[qi].start_time;
        e_end   := g_task[ti].queue[qi].finish_time;

        (* Does existing task share an overlap station? *)
        has_ovlp := FALSE;
        IF lift_is_overlap AND (e_lift = i_lift_stn OR e_sink = i_lift_stn) THEN
          has_ovlp := TRUE;
        END_IF;
        IF sink_is_overlap AND (e_lift = i_sink_stn OR e_sink = i_sink_stn) THEN
          has_ovlp := TRUE;
        END_IF;

        IF has_ovlp THEN
          (* Time overlap check: task overlaps with existing? *)
          IF t_start < (e_end + REAL_TO_LINT(i_margin_s)) AND t_end > (e_start - REAL_TO_LINT(i_margin_s)) THEN
            needed := LINT_TO_REAL(e_end - t_start) + i_margin_s;
            IF needed > max_conf THEN
              max_conf := needed;
            END_IF;
          END_IF;
        END_IF;

      END_FOR;  (* qi *)
    END_IF;
  END_FOR;  (* ti *)

  (* No conflict found → done *)
  IF max_conf <= 0.0 THEN
    EXIT;
  END_IF;
  o_delay_s := o_delay_s + max_conf;
END_FOR;  (* round *)

END_FUNCTION_BLOCK
