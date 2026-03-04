(* ============================================================
   SIM_FB_ClearConfig.st — Clear all PLC configuration data
   
   Called by PLC_PRG when Gateway sends cmd=3 (clear_all).
   Zeroes out all stations, transporter configs, transporter
   states and units so the PLC is ready for fresh config upload.
   ============================================================ *)

FUNCTION_BLOCK SIM_FB_ClearConfig
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    MAX_PARALLELS       : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
    MAX_UNITS           : INT;
END_VAR

VAR_EXTERNAL
  g_station_count    : INT;
  g_station         : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF STATION_T;
  g_cfg              : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_transporter      : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_unit            : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_ntt             : ARRAY[1..MAX_TRANSPORTERS] OF NTT_TRANSPORTER_T;
  g_batch          : ARRAY[1..MAX_UNITS] OF BATCH_T;
  g_program         : ARRAY[1..MAX_UNITS] OF TREATMENT_PROGRAM_T;
  g_avoid_status     : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF INT;
  g_schedule         : ARRAY[1..MAX_UNITS] OF TSK_SCHEDULE_T;
  g_task             : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  g_dep_sandbox      : DEP_SANDBOX_T;
  g_dep_pending      : DEP_PENDING_WRITE_T;
END_VAR
VAR
  i : INT;
  j : INT;
  k : INT;
END_VAR

(* --- Clear all stations --- *)
FOR i := STATION_ARRAY_START TO STATION_ARRAY_END DO
  g_station[i].tank_id       := 0;
  g_station[i].status        := 0;
  g_station[i].x_position    := 0.0;
  g_station[i].y_position    := 0.0;
  g_station[i].z_position    := 0.0;
  g_station[i].kind          := 0;
  g_station[i].operation     := 0;
  g_station[i].dropping_time := 0.0;
  g_station[i].device_delay  := 0.0;
  g_station[i].unit_id       := 0;
  g_station[i].change_time   := 0;
END_FOR;
g_station_count := 0;

(* --- Clear all transporter configs --- *)
FOR i := 1 TO MAX_TRANSPORTERS DO
  g_cfg[i].x_min_limit   := 0.0;
  g_cfg[i].x_max_limit   := 0.0;
  g_cfg[i].y_min_limit   := 0.0;
  g_cfg[i].y_max_limit   := 0.0;
  g_cfg[i].x_avoid_mm    := 0.0;
  g_cfg[i].y_avoid_mm    := 0.0;
  g_cfg[i].phys2d.x_accel_s     := 0.0;
  g_cfg[i].phys2d.x_decel_s     := 0.0;
  g_cfg[i].phys2d.x_max_mm_s    := 0.0;
  g_cfg[i].phys2d.z_total_mm    := 0.0;
  g_cfg[i].phys2d.z_slow_dry_mm := 0.0;
  g_cfg[i].phys2d.z_slow_wet_mm := 0.0;
  g_cfg[i].phys2d.z_slow_end_mm := 0.0;
  g_cfg[i].phys2d.z_slow_mm_s   := 0.0;
  g_cfg[i].phys2d.z_fast_mm_s   := 0.0;
  g_cfg[i].phys2d.drip_delay_s  := 0.0;
  g_cfg[i].phys2d.avoid_mm      := 0.0;
  FOR j := 1 TO 4 DO
    g_cfg[i].task_area[j].min_lift := 0;
    g_cfg[i].task_area[j].max_lift := 0;
    g_cfg[i].task_area[j].min_sink := 0;
    g_cfg[i].task_area[j].max_sink := 0;
  END_FOR;
END_FOR;

(* --- Clear avoid status --- *)
FOR i := STATION_ARRAY_START TO STATION_ARRAY_END DO
  g_avoid_status[i] := 0;
END_FOR;

(* --- Clear all transporter states --- *)
FOR i := 1 TO MAX_TRANSPORTERS DO
  g_transporter[i].active          := FALSE;
  g_transporter[i].status          := 0;
  g_transporter[i].phase           := 0;
  g_transporter[i].unit_id         := 0;
  g_transporter[i].task_id         := 0;
  g_transporter[i].running_task_id := 0;
  g_transporter[i].lift_station    := 0;
  g_transporter[i].sink_station    := 0;
  g_transporter[i].treatment_time  := 0.0;
  g_transporter[i].lift_device_delay := 0.0;
  g_transporter[i].sink_device_delay := 0.0;
  g_transporter[i].dropping_time   := 0.0;
  g_transporter[i].remaining_time  := 0.0;
  g_transporter[i].current_station := 0;
  g_transporter[i].final_target_x  := 0.0;
  g_transporter[i].drive_target_x  := 0.0;
  g_transporter[i].final_target_y  := 0.0;
  g_transporter[i].drive_target_y  := 0.0;
  g_transporter[i].x_mm            := 0.0;
  g_transporter[i].y_mm            := 0.0;
  g_transporter[i].z_mm            := 0.0;
  g_transporter[i].vel_x           := 0.0;
  g_transporter[i].z_stage         := 0;
  g_transporter[i].z_timer_s       := 0.0;
  g_transporter[i].x_min_limit     := 0.0;
  g_transporter[i].x_max_limit     := 0.0;
END_FOR;

(* --- Clear all units --- *)
FOR i := 1 TO MAX_UNITS DO
  g_unit[i].location := 0;
  g_unit[i].status   := 0;
  g_unit[i].target   := 0;
END_FOR;

(* --- Clear NTT destinations --- *)
FOR i := 1 TO MAX_TRANSPORTERS DO
  FOR j := 1 TO 8 DO
    g_ntt[i].target[j].station_count := 0;
    g_ntt[i].target[j].fallback_count := 0;
    FOR k := 1 TO MAX_PARALLELS DO
      g_ntt[i].target[j].stations[k] := 0;
      g_ntt[i].target[j].fallback_stations[k] := 0;
    END_FOR;
  END_FOR;
END_FOR;

(* --- Clear all batches --- *)
FOR i := 1 TO MAX_UNITS DO
  g_batch[i].batch_code := 0;
  g_batch[i].state      := 0;
  g_batch[i].prog_id    := 0;
  g_batch[i].cur_stage      := 0;
END_FOR;

(* --- Clear all treatment programs --- *)
FOR i := 1 TO MAX_UNITS DO
  g_program[i].program_id := 0;
  FOR j := 1 TO 30 DO
    FOR k := 1 TO 5 DO
      g_program[i].stages[j].stations[k] := 0;
    END_FOR;
    g_program[i].stages[j].min_time := 0;
    g_program[i].stages[j].max_time := 0;
    g_program[i].stages[j].cal_time := 0;
  END_FOR;
END_FOR;

(* --- Clear all schedules (g_schedule) --- *)
FOR i := 1 TO MAX_UNITS DO
  g_schedule[i].stage_count := 0;
  FOR j := 1 TO 30 DO
    g_schedule[i].stages[j].station       := 0;
    g_schedule[i].stages[j].entry_time    := 0;
    g_schedule[i].stages[j].exit_time     := 0;
    g_schedule[i].stages[j].min_time      := 0.0;
    g_schedule[i].stages[j].calc_time     := 0.0;
    g_schedule[i].stages[j].max_time      := 0.0;
    g_schedule[i].stages[j].transfer_time := 0.0;
  END_FOR;
END_FOR;

(* --- Clear all task queues (g_task) --- *)
FOR i := 1 TO MAX_TRANSPORTERS DO
  g_task[i].count := 0;
  FOR j := 1 TO 10 DO
    g_task[i].queue[j].unit         := 0;
    g_task[i].queue[j].stage        := 0;
    g_task[i].queue[j].lift_station := 0;
    g_task[i].queue[j].sink_station := 0;
    g_task[i].queue[j].start_time   := 0;
    g_task[i].queue[j].finish_time  := 0;
    g_task[i].queue[j].calc_time    := 0.0;
    g_task[i].queue[j].min_time     := 0.0;
    g_task[i].queue[j].max_time     := 0.0;
  END_FOR;
END_FOR;

(* --- Clear departure sandbox and pending write --- *)
g_dep_sandbox.valid := FALSE;
g_dep_pending.valid := FALSE;
g_dep_pending.batch_unit  := 0;
g_dep_pending.batch_stage := 0;
g_dep_pending.batch_state := 0;

END_FUNCTION_BLOCK
