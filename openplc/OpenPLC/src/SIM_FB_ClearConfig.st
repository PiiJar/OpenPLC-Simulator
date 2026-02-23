(* ============================================================
   SIM_FB_ClearConfig.st — Clear all PLC configuration data
   
   Called by PLC_PRG when Gateway sends cmd=3 (clear_all).
   Zeroes out all stations, transporter configs, transporter
   states and units so the PLC is ready for fresh config upload.
   ============================================================ *)

FUNCTION_BLOCK SIM_FB_ClearConfig
VAR_EXTERNAL
  g_station_count    : INT;
  g_stations         : ARRAY[101..125] OF STATION_T;
  g_cfg              : ARRAY[1..3] OF TRANSPORTER_CFG_T;
  g_state            : ARRAY[1..3] OF TRANSPORTER_STATE_T;
  g_cmd_start        : ARRAY[1..3] OF BOOL;
  g_cmd_lift_station : ARRAY[1..3] OF INT;
  g_cmd_sink_station : ARRAY[1..3] OF INT;
  g_units            : ARRAY[1..10] OF UNIT_T;
  g_batches          : ARRAY[1..10] OF BATCH_T;
  g_programs         : ARRAY[1..10] OF TREATMENT_PROGRAM_T;
  g_avoid_status     : ARRAY[101..125] OF INT;
END_VAR
VAR
  i : INT;
  j : INT;
  k : INT;
END_VAR

(* --- Clear all stations --- *)
FOR i := 101 TO 125 DO
  g_stations[i].tank_id       := 0;
  g_stations[i].status        := 0;
  g_stations[i].x_position    := 0.0;
  g_stations[i].y_position    := 0.0;
  g_stations[i].z_position    := 0.0;
  g_stations[i].stn_type      := 0;
  g_stations[i].dropping_time := 0.0;
  g_stations[i].device_delay  := 0.0;
END_FOR;
g_station_count := 0;

(* --- Clear all transporter configs --- *)
FOR i := 1 TO 3 DO
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
FOR i := 101 TO 125 DO
  g_avoid_status[i] := 0;
END_FOR;

(* --- Clear all transporter states --- *)
FOR i := 1 TO 3 DO
  g_state[i].active              := FALSE;
  g_state[i].phase               := 0;
  g_state[i].z_stage             := 0;
  g_state[i].x_mm                := 0.0;
  g_state[i].z_mm                := 0.0;
  g_state[i].vel_x               := 0.0;
  g_state[i].vel_z               := 0.0;
  g_state[i].current_station     := 0;
  g_state[i].lift_station_target := 0;
  g_state[i].sink_station_target := 0;
  g_state[i].target_x            := 0.0;
  g_state[i].x_min_limit         := 0.0;
  g_state[i].x_max_limit         := 0.0;
  g_state[i].z_timer_s           := 0.0;
  g_cmd_start[i]        := FALSE;
  g_cmd_lift_station[i]  := 0;
  g_cmd_sink_station[i]  := 0;
END_FOR;

(* --- Clear all units --- *)
FOR i := 1 TO 10 DO
  g_units[i].location := 0;
  g_units[i].status   := 0;
  g_units[i].state    := 0;
  g_units[i].target   := 0;
END_FOR;

(* --- Clear all batches --- *)
FOR i := 1 TO 10 DO
  g_batches[i].batch_code := 0;
  g_batches[i].state      := 0;
  g_batches[i].prog_id    := 0;
  g_batches[i].cur_stage      := 0;
END_FOR;

(* --- Clear all treatment programs --- *)
FOR i := 1 TO 10 DO
  g_programs[i].program_id := 0;
  FOR j := 1 TO 30 DO
    FOR k := 1 TO 5 DO
      g_programs[i].stages[j].stations[k] := 0;
    END_FOR;
    g_programs[i].stages[j].min_time := 0;
    g_programs[i].stages[j].max_time := 0;
    g_programs[i].stages[j].cal_time := 0;
  END_FOR;
END_FOR;

END_FUNCTION_BLOCK
