(* ============================================================
   plc_prg.st — Main program: config upload + transport cycle
   ============================================================ *)

PROGRAM PLC_PRG
VAR_EXTERNAL CONSTANT
    MAX_TRANSPORTERS    : INT;
    MAX_PARALLELS       : INT;
    STATION_ARRAY_START : INT;
    STATION_ARRAY_END   : INT;
    MAX_UNITS           : INT;
    DEP_MAX_WAITING     : INT;
END_VAR

VAR_EXTERNAL
  (* --- Shared data arrays --- *)
  g_station_count    : INT;
  g_station         : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF STATION_T;
  g_cfg              : ARRAY[1..MAX_TRANSPORTERS] OF TRANSPORTER_CFG_T;
  g_transporter      : ARRAY[1..MAX_TRANSPORTERS] OF STC_TRANSPORTER_T;
  g_unit            : ARRAY[1..MAX_UNITS] OF UNIT_T;
  g_ntt             : ARRAY[1..MAX_TRANSPORTERS] OF NTT_TRANSPORTER_T;
  g_batch          : ARRAY[1..MAX_UNITS] OF BATCH_T;
  g_program         : ARRAY[1..MAX_UNITS] OF TREATMENT_PROGRAM_T;
  g_avoid_status     : ARRAY[STATION_ARRAY_START..STATION_ARRAY_END] OF INT;
  g_move             : ARRAY[1..MAX_TRANSPORTERS] OF MOVE_TIMES_T;
  g_schedule         : ARRAY[1..MAX_UNITS] OF TSK_SCHEDULE_T;
  g_task            : ARRAY[1..MAX_TRANSPORTERS] OF TSK_QUEUE_T;
  (* --- Departure Scheduler state --- *)
  g_dep_activated     : BOOL;
  g_dep_stable        : BOOL;
  g_dep_waiting_count : INT;
  g_dep_overlap       : DEP_OVERLAP_T;
  g_dep_pending       : DEP_PENDING_WRITE_T;
  g_dep_waiting       : ARRAY[1..DEP_MAX_WAITING] OF INT;
  (* --- Calibration --- *)
  g_cal              : ARRAY[1..MAX_TRANSPORTERS] OF CALIBRATION_T;
  g_cal_active       : BOOL;
  (* --- Production --- *)
  g_production_queue : INT;
  (* --- Time --- *)
  g_time_s           : LINT;
  (* --- Event queue --- *)
  g_event                : EVENT_QUEUE_T;
  g_event_pending        : EVENT_MSG_T;
  g_event_pending_valid  : BOOL;
  (* --- BEGIN GENERATED MODBUS EXTERNALS --- *)
  qw_t1_x_mm                     : INT;
  qw_t1_z_mm                     : INT;
  qw_t1_vel_x10                  : INT;
  qw_t1_phase                    : INT;
  qw_t1_unit_id                  : INT;
  qw_t1_z_stage                  : INT;
  qw_t1_cur_st                   : INT;
  qw_t1_lift_tgt                 : INT;
  qw_t1_sink_tgt                 : INT;
  qw_t1_active                   : INT;
  qw_t1_status                   : INT;
  qw_t1_rtask_hi                 : INT;
  qw_t1_rtask_lo                 : INT;
  qw_t2_x_mm                     : INT;
  qw_t2_z_mm                     : INT;
  qw_t2_vel_x10                  : INT;
  qw_t2_phase                    : INT;
  qw_t2_unit_id                  : INT;
  qw_t2_z_stage                  : INT;
  qw_t2_cur_st                   : INT;
  qw_t2_lift_tgt                 : INT;
  qw_t2_sink_tgt                 : INT;
  qw_t2_active                   : INT;
  qw_t2_status                   : INT;
  qw_t2_rtask_hi                 : INT;
  qw_t2_rtask_lo                 : INT;
  qw_t3_x_mm                     : INT;
  qw_t3_z_mm                     : INT;
  qw_t3_vel_x10                  : INT;
  qw_t3_phase                    : INT;
  qw_t3_unit_id                  : INT;
  qw_t3_z_stage                  : INT;
  qw_t3_cur_st                   : INT;
  qw_t3_lift_tgt                 : INT;
  qw_t3_sink_tgt                 : INT;
  qw_t3_active                   : INT;
  qw_t3_status                   : INT;
  qw_t3_rtask_hi                 : INT;
  qw_t3_rtask_lo                 : INT;
  qw_t1_remain_x10               : INT;
  qw_t1_treat_time               : INT;
  qw_t1_fintgt_x                 : INT;
  qw_t1_drvtgt_x                 : INT;
  qw_t1_fintgt_y                 : INT;
  qw_t1_drvtgt_y                 : INT;
  qw_t1_y_mm                     : INT;
  qw_t1_ztimer_x10               : INT;
  qw_t1_ctask_hi                 : INT;
  qw_t1_ctask_lo                 : INT;
  qw_t1_ldev_x10                 : INT;
  qw_t1_sdev_x10                 : INT;
  qw_t1_drop_x10                 : INT;
  qw_t2_remain_x10               : INT;
  qw_t2_treat_time               : INT;
  qw_t2_fintgt_x                 : INT;
  qw_t2_drvtgt_x                 : INT;
  qw_t2_fintgt_y                 : INT;
  qw_t2_drvtgt_y                 : INT;
  qw_t2_y_mm                     : INT;
  qw_t2_ztimer_x10               : INT;
  qw_t2_ctask_hi                 : INT;
  qw_t2_ctask_lo                 : INT;
  qw_t2_ldev_x10                 : INT;
  qw_t2_sdev_x10                 : INT;
  qw_t2_drop_x10                 : INT;
  qw_t3_remain_x10               : INT;
  qw_t3_treat_time               : INT;
  qw_t3_fintgt_x                 : INT;
  qw_t3_drvtgt_x                 : INT;
  qw_t3_fintgt_y                 : INT;
  qw_t3_drvtgt_y                 : INT;
  qw_t3_y_mm                     : INT;
  qw_t3_ztimer_x10               : INT;
  qw_t3_ctask_hi                 : INT;
  qw_t3_ctask_lo                 : INT;
  qw_t3_ldev_x10                 : INT;
  qw_t3_sdev_x10                 : INT;
  qw_t3_drop_x10                 : INT;
  qw_t1_xmin                     : INT;
  qw_t1_xmax                     : INT;
  qw_t2_xmin                     : INT;
  qw_t2_xmax                     : INT;
  qw_t3_xmin                     : INT;
  qw_t3_xmax                     : INT;
  qw_plc_status_station_cnt      : INT;
  qw_plc_status_init_done        : INT;
  qw_plc_status_cycle_cnt        : INT;
  qw_plc_status_cfg_ack          : INT;
  qw_plc_status_unit_ack         : INT;
  qw_plc_status_batch_ack        : INT;
  qw_plc_status_prog_ack         : INT;
  qw_plc_status_avoid_ack        : INT;
  qw_plc_status_cal_active       : INT;
  qw_plc_status_prod_queue       : INT;
  qw_plc_status_time_hi          : INT;
  qw_plc_status_time_lo          : INT;
  qw_u1_loc                      : INT;
  qw_u1_status                   : INT;
  qw_u1_target                   : INT;
  qw_u2_loc                      : INT;
  qw_u2_status                   : INT;
  qw_u2_target                   : INT;
  qw_u3_loc                      : INT;
  qw_u3_status                   : INT;
  qw_u3_target                   : INT;
  qw_u4_loc                      : INT;
  qw_u4_status                   : INT;
  qw_u4_target                   : INT;
  qw_u5_loc                      : INT;
  qw_u5_status                   : INT;
  qw_u5_target                   : INT;
  qw_u6_loc                      : INT;
  qw_u6_status                   : INT;
  qw_u6_target                   : INT;
  qw_u7_loc                      : INT;
  qw_u7_status                   : INT;
  qw_u7_target                   : INT;
  qw_u8_loc                      : INT;
  qw_u8_status                   : INT;
  qw_u8_target                   : INT;
  qw_u9_loc                      : INT;
  qw_u9_status                   : INT;
  qw_u9_target                   : INT;
  qw_u10_loc                     : INT;
  qw_u10_status                  : INT;
  qw_u10_target                  : INT;
  qw_b1_code                     : INT;
  qw_b1_state                    : INT;
  qw_b1_prog                     : INT;
  qw_b1_stage                    : INT;
  qw_b1_min_time                 : INT;
  qw_b1_max_time                 : INT;
  qw_b1_cal_time                 : INT;
  qw_b1_start_hi                 : INT;
  qw_b1_start_lo                 : INT;
  qw_b2_code                     : INT;
  qw_b2_state                    : INT;
  qw_b2_prog                     : INT;
  qw_b2_stage                    : INT;
  qw_b2_min_time                 : INT;
  qw_b2_max_time                 : INT;
  qw_b2_cal_time                 : INT;
  qw_b2_start_hi                 : INT;
  qw_b2_start_lo                 : INT;
  qw_b3_code                     : INT;
  qw_b3_state                    : INT;
  qw_b3_prog                     : INT;
  qw_b3_stage                    : INT;
  qw_b3_min_time                 : INT;
  qw_b3_max_time                 : INT;
  qw_b3_cal_time                 : INT;
  qw_b3_start_hi                 : INT;
  qw_b3_start_lo                 : INT;
  qw_b4_code                     : INT;
  qw_b4_state                    : INT;
  qw_b4_prog                     : INT;
  qw_b4_stage                    : INT;
  qw_b4_min_time                 : INT;
  qw_b4_max_time                 : INT;
  qw_b4_cal_time                 : INT;
  qw_b4_start_hi                 : INT;
  qw_b4_start_lo                 : INT;
  qw_b5_code                     : INT;
  qw_b5_state                    : INT;
  qw_b5_prog                     : INT;
  qw_b5_stage                    : INT;
  qw_b5_min_time                 : INT;
  qw_b5_max_time                 : INT;
  qw_b5_cal_time                 : INT;
  qw_b5_start_hi                 : INT;
  qw_b5_start_lo                 : INT;
  qw_b6_code                     : INT;
  qw_b6_state                    : INT;
  qw_b6_prog                     : INT;
  qw_b6_stage                    : INT;
  qw_b6_min_time                 : INT;
  qw_b6_max_time                 : INT;
  qw_b6_cal_time                 : INT;
  qw_b6_start_hi                 : INT;
  qw_b6_start_lo                 : INT;
  qw_b7_code                     : INT;
  qw_b7_state                    : INT;
  qw_b7_prog                     : INT;
  qw_b7_stage                    : INT;
  qw_b7_min_time                 : INT;
  qw_b7_max_time                 : INT;
  qw_b7_cal_time                 : INT;
  qw_b7_start_hi                 : INT;
  qw_b7_start_lo                 : INT;
  qw_b8_code                     : INT;
  qw_b8_state                    : INT;
  qw_b8_prog                     : INT;
  qw_b8_stage                    : INT;
  qw_b8_min_time                 : INT;
  qw_b8_max_time                 : INT;
  qw_b8_cal_time                 : INT;
  qw_b8_start_hi                 : INT;
  qw_b8_start_lo                 : INT;
  qw_b9_code                     : INT;
  qw_b9_state                    : INT;
  qw_b9_prog                     : INT;
  qw_b9_stage                    : INT;
  qw_b9_min_time                 : INT;
  qw_b9_max_time                 : INT;
  qw_b9_cal_time                 : INT;
  qw_b9_start_hi                 : INT;
  qw_b9_start_lo                 : INT;
  qw_b10_code                    : INT;
  qw_b10_state                   : INT;
  qw_b10_prog                    : INT;
  qw_b10_stage                   : INT;
  qw_b10_min_time                : INT;
  qw_b10_max_time                : INT;
  qw_b10_cal_time                : INT;
  qw_b10_start_hi                : INT;
  qw_b10_start_lo                : INT;
  qw_calibration_step            : INT;
  qw_calibration_tid             : INT;
  qw_cal_t1_lift_wet             : INT;
  qw_cal_t1_sink_wet             : INT;
  qw_cal_t1_lift_dry             : INT;
  qw_cal_t1_sink_dry             : INT;
  qw_cal_t1_x_acc                : INT;
  qw_cal_t1_x_dec                : INT;
  qw_cal_t1_x_max                : INT;
  qw_cal_t2_lift_wet             : INT;
  qw_cal_t2_sink_wet             : INT;
  qw_cal_t2_lift_dry             : INT;
  qw_cal_t2_sink_dry             : INT;
  qw_cal_t2_x_acc                : INT;
  qw_cal_t2_x_dec                : INT;
  qw_cal_t2_x_max                : INT;
  qw_cal_t3_lift_wet             : INT;
  qw_cal_t3_sink_wet             : INT;
  qw_cal_t3_lift_dry             : INT;
  qw_cal_t3_sink_dry             : INT;
  qw_cal_t3_x_acc                : INT;
  qw_cal_t3_x_dec                : INT;
  qw_cal_t3_x_max                : INT;
  qw_cfg_t1_x_min                : INT;
  qw_cfg_t1_x_max                : INT;
  qw_cfg_t1_y_min                : INT;
  qw_cfg_t1_y_max                : INT;
  qw_cfg_t1_x_avoid              : INT;
  qw_cfg_t1_y_avoid              : INT;
  qw_cfg_t1_ph_xacc_x100         : INT;
  qw_cfg_t1_ph_xdec_x100         : INT;
  qw_cfg_t1_ph_xmax              : INT;
  qw_cfg_t1_ph_ztot              : INT;
  qw_cfg_t1_ph_zsdry             : INT;
  qw_cfg_t1_ph_zswet             : INT;
  qw_cfg_t1_ph_zsend             : INT;
  qw_cfg_t1_ph_zslow             : INT;
  qw_cfg_t1_ph_zfast             : INT;
  qw_cfg_t1_ph_drip_x10          : INT;
  qw_cfg_t1_ph_avoid             : INT;
  qw_cfg_t1_ta1_min_lift         : INT;
  qw_cfg_t1_ta1_max_lift         : INT;
  qw_cfg_t1_ta1_min_sink         : INT;
  qw_cfg_t1_ta1_max_sink         : INT;
  qw_cfg_t1_ta2_min_lift         : INT;
  qw_cfg_t1_ta2_max_lift         : INT;
  qw_cfg_t1_ta2_min_sink         : INT;
  qw_cfg_t1_ta2_max_sink         : INT;
  qw_cfg_t1_ta3_min_lift         : INT;
  qw_cfg_t1_ta3_max_lift         : INT;
  qw_cfg_t1_ta3_min_sink         : INT;
  qw_cfg_t1_ta3_max_sink         : INT;
  qw_cfg_t2_x_min                : INT;
  qw_cfg_t2_x_max                : INT;
  qw_cfg_t2_y_min                : INT;
  qw_cfg_t2_y_max                : INT;
  qw_cfg_t2_x_avoid              : INT;
  qw_cfg_t2_y_avoid              : INT;
  qw_cfg_t2_ph_xacc_x100         : INT;
  qw_cfg_t2_ph_xdec_x100         : INT;
  qw_cfg_t2_ph_xmax              : INT;
  qw_cfg_t2_ph_ztot              : INT;
  qw_cfg_t2_ph_zsdry             : INT;
  qw_cfg_t2_ph_zswet             : INT;
  qw_cfg_t2_ph_zsend             : INT;
  qw_cfg_t2_ph_zslow             : INT;
  qw_cfg_t2_ph_zfast             : INT;
  qw_cfg_t2_ph_drip_x10          : INT;
  qw_cfg_t2_ph_avoid             : INT;
  qw_cfg_t2_ta1_min_lift         : INT;
  qw_cfg_t2_ta1_max_lift         : INT;
  qw_cfg_t2_ta1_min_sink         : INT;
  qw_cfg_t2_ta1_max_sink         : INT;
  qw_cfg_t2_ta2_min_lift         : INT;
  qw_cfg_t2_ta2_max_lift         : INT;
  qw_cfg_t2_ta2_min_sink         : INT;
  qw_cfg_t2_ta2_max_sink         : INT;
  qw_cfg_t2_ta3_min_lift         : INT;
  qw_cfg_t2_ta3_max_lift         : INT;
  qw_cfg_t2_ta3_min_sink         : INT;
  qw_cfg_t2_ta3_max_sink         : INT;
  qw_cfg_t3_x_min                : INT;
  qw_cfg_t3_x_max                : INT;
  qw_cfg_t3_y_min                : INT;
  qw_cfg_t3_y_max                : INT;
  qw_cfg_t3_x_avoid              : INT;
  qw_cfg_t3_y_avoid              : INT;
  qw_cfg_t3_ph_xacc_x100         : INT;
  qw_cfg_t3_ph_xdec_x100         : INT;
  qw_cfg_t3_ph_xmax              : INT;
  qw_cfg_t3_ph_ztot              : INT;
  qw_cfg_t3_ph_zsdry             : INT;
  qw_cfg_t3_ph_zswet             : INT;
  qw_cfg_t3_ph_zsend             : INT;
  qw_cfg_t3_ph_zslow             : INT;
  qw_cfg_t3_ph_zfast             : INT;
  qw_cfg_t3_ph_drip_x10          : INT;
  qw_cfg_t3_ph_avoid             : INT;
  qw_cfg_t3_ta1_min_lift         : INT;
  qw_cfg_t3_ta1_max_lift         : INT;
  qw_cfg_t3_ta1_min_sink         : INT;
  qw_cfg_t3_ta1_max_sink         : INT;
  qw_cfg_t3_ta2_min_lift         : INT;
  qw_cfg_t3_ta2_max_lift         : INT;
  qw_cfg_t3_ta2_min_sink         : INT;
  qw_cfg_t3_ta2_max_sink         : INT;
  qw_cfg_t3_ta3_min_lift         : INT;
  qw_cfg_t3_ta3_max_lift         : INT;
  qw_cfg_t3_ta3_min_sink         : INT;
  qw_cfg_t3_ta3_max_sink         : INT;
  qw_s101_val                    : INT;
  qw_s102_val                    : INT;
  qw_s103_val                    : INT;
  qw_s104_val                    : INT;
  qw_s105_val                    : INT;
  qw_s106_val                    : INT;
  qw_s107_val                    : INT;
  qw_s108_val                    : INT;
  qw_s109_val                    : INT;
  qw_s110_val                    : INT;
  qw_s111_val                    : INT;
  qw_s112_val                    : INT;
  qw_s113_val                    : INT;
  qw_s114_val                    : INT;
  qw_s115_val                    : INT;
  qw_s116_val                    : INT;
  qw_s117_val                    : INT;
  qw_s118_val                    : INT;
  qw_s119_val                    : INT;
  qw_s120_val                    : INT;
  qw_s121_val                    : INT;
  qw_s122_val                    : INT;
  qw_s123_val                    : INT;
  qw_s124_val                    : INT;
  qw_s125_val                    : INT;
  qw_s126_val                    : INT;
  qw_s127_val                    : INT;
  qw_s128_val                    : INT;
  qw_s129_val                    : INT;
  qw_s130_val                    : INT;
  qw_sched_u1_stage_cnt          : INT;
  qw_sched_u2_stage_cnt          : INT;
  qw_sched_u3_stage_cnt          : INT;
  qw_sched_u4_stage_cnt          : INT;
  qw_sched_u5_stage_cnt          : INT;
  qw_sched_u6_stage_cnt          : INT;
  qw_sched_u7_stage_cnt          : INT;
  qw_sched_u8_stage_cnt          : INT;
  qw_sched_u9_stage_cnt          : INT;
  qw_sched_u10_stage_cnt         : INT;
  qw_tq1_count                   : INT;
  qw_tq1_q1_unit                 : INT;
  qw_tq1_q1_stage                : INT;
  qw_tq1_q1_lift                 : INT;
  qw_tq1_q1_sink                 : INT;
  qw_tq1_q1_start_hi             : INT;
  qw_tq1_q1_start_lo             : INT;
  qw_tq1_q1_fin_hi               : INT;
  qw_tq1_q1_fin_lo               : INT;
  qw_tq1_q1_calc_x10             : INT;
  qw_tq1_q1_min_x10              : INT;
  qw_tq1_q1_max_x10              : INT;
  qw_tq1_q2_unit                 : INT;
  qw_tq1_q2_stage                : INT;
  qw_tq1_q2_lift                 : INT;
  qw_tq1_q2_sink                 : INT;
  qw_tq1_q2_start_hi             : INT;
  qw_tq1_q2_start_lo             : INT;
  qw_tq1_q2_fin_hi               : INT;
  qw_tq1_q2_fin_lo               : INT;
  qw_tq1_q2_calc_x10             : INT;
  qw_tq1_q2_min_x10              : INT;
  qw_tq1_q2_max_x10              : INT;
  qw_tq1_q3_unit                 : INT;
  qw_tq1_q3_stage                : INT;
  qw_tq1_q3_lift                 : INT;
  qw_tq1_q3_sink                 : INT;
  qw_tq1_q3_start_hi             : INT;
  qw_tq1_q3_start_lo             : INT;
  qw_tq1_q3_fin_hi               : INT;
  qw_tq1_q3_fin_lo               : INT;
  qw_tq1_q3_calc_x10             : INT;
  qw_tq1_q3_min_x10              : INT;
  qw_tq1_q3_max_x10              : INT;
  qw_tq1_q4_unit                 : INT;
  qw_tq1_q4_stage                : INT;
  qw_tq1_q4_lift                 : INT;
  qw_tq1_q4_sink                 : INT;
  qw_tq1_q4_start_hi             : INT;
  qw_tq1_q4_start_lo             : INT;
  qw_tq1_q4_fin_hi               : INT;
  qw_tq1_q4_fin_lo               : INT;
  qw_tq1_q4_calc_x10             : INT;
  qw_tq1_q4_min_x10              : INT;
  qw_tq1_q4_max_x10              : INT;
  qw_tq1_q5_unit                 : INT;
  qw_tq1_q5_stage                : INT;
  qw_tq1_q5_lift                 : INT;
  qw_tq1_q5_sink                 : INT;
  qw_tq1_q5_start_hi             : INT;
  qw_tq1_q5_start_lo             : INT;
  qw_tq1_q5_fin_hi               : INT;
  qw_tq1_q5_fin_lo               : INT;
  qw_tq1_q5_calc_x10             : INT;
  qw_tq1_q5_min_x10              : INT;
  qw_tq1_q5_max_x10              : INT;
  qw_tq1_q6_unit                 : INT;
  qw_tq1_q6_stage                : INT;
  qw_tq1_q6_lift                 : INT;
  qw_tq1_q6_sink                 : INT;
  qw_tq1_q6_start_hi             : INT;
  qw_tq1_q6_start_lo             : INT;
  qw_tq1_q6_fin_hi               : INT;
  qw_tq1_q6_fin_lo               : INT;
  qw_tq1_q6_calc_x10             : INT;
  qw_tq1_q6_min_x10              : INT;
  qw_tq1_q6_max_x10              : INT;
  qw_tq1_q7_unit                 : INT;
  qw_tq1_q7_stage                : INT;
  qw_tq1_q7_lift                 : INT;
  qw_tq1_q7_sink                 : INT;
  qw_tq1_q7_start_hi             : INT;
  qw_tq1_q7_start_lo             : INT;
  qw_tq1_q7_fin_hi               : INT;
  qw_tq1_q7_fin_lo               : INT;
  qw_tq1_q7_calc_x10             : INT;
  qw_tq1_q7_min_x10              : INT;
  qw_tq1_q7_max_x10              : INT;
  qw_tq1_q8_unit                 : INT;
  qw_tq1_q8_stage                : INT;
  qw_tq1_q8_lift                 : INT;
  qw_tq1_q8_sink                 : INT;
  qw_tq1_q8_start_hi             : INT;
  qw_tq1_q8_start_lo             : INT;
  qw_tq1_q8_fin_hi               : INT;
  qw_tq1_q8_fin_lo               : INT;
  qw_tq1_q8_calc_x10             : INT;
  qw_tq1_q8_min_x10              : INT;
  qw_tq1_q8_max_x10              : INT;
  qw_tq1_q9_unit                 : INT;
  qw_tq1_q9_stage                : INT;
  qw_tq1_q9_lift                 : INT;
  qw_tq1_q9_sink                 : INT;
  qw_tq1_q9_start_hi             : INT;
  qw_tq1_q9_start_lo             : INT;
  qw_tq1_q9_fin_hi               : INT;
  qw_tq1_q9_fin_lo               : INT;
  qw_tq1_q9_calc_x10             : INT;
  qw_tq1_q9_min_x10              : INT;
  qw_tq1_q9_max_x10              : INT;
  qw_tq1_q10_unit                : INT;
  qw_tq1_q10_stage               : INT;
  qw_tq1_q10_lift                : INT;
  qw_tq1_q10_sink                : INT;
  qw_tq1_q10_start_hi            : INT;
  qw_tq1_q10_start_lo            : INT;
  qw_tq1_q10_fin_hi              : INT;
  qw_tq1_q10_fin_lo              : INT;
  qw_tq1_q10_calc_x10            : INT;
  qw_tq1_q10_min_x10             : INT;
  qw_tq1_q10_max_x10             : INT;
  qw_tq2_count                   : INT;
  qw_tq2_q1_unit                 : INT;
  qw_tq2_q1_stage                : INT;
  qw_tq2_q1_lift                 : INT;
  qw_tq2_q1_sink                 : INT;
  qw_tq2_q1_start_hi             : INT;
  qw_tq2_q1_start_lo             : INT;
  qw_tq2_q1_fin_hi               : INT;
  qw_tq2_q1_fin_lo               : INT;
  qw_tq2_q1_calc_x10             : INT;
  qw_tq2_q1_min_x10              : INT;
  qw_tq2_q1_max_x10              : INT;
  qw_tq2_q2_unit                 : INT;
  qw_tq2_q2_stage                : INT;
  qw_tq2_q2_lift                 : INT;
  qw_tq2_q2_sink                 : INT;
  qw_tq2_q2_start_hi             : INT;
  qw_tq2_q2_start_lo             : INT;
  qw_tq2_q2_fin_hi               : INT;
  qw_tq2_q2_fin_lo               : INT;
  qw_tq2_q2_calc_x10             : INT;
  qw_tq2_q2_min_x10              : INT;
  qw_tq2_q2_max_x10              : INT;
  qw_tq2_q3_unit                 : INT;
  qw_tq2_q3_stage                : INT;
  qw_tq2_q3_lift                 : INT;
  qw_tq2_q3_sink                 : INT;
  qw_tq2_q3_start_hi             : INT;
  qw_tq2_q3_start_lo             : INT;
  qw_tq2_q3_fin_hi               : INT;
  qw_tq2_q3_fin_lo               : INT;
  qw_tq2_q3_calc_x10             : INT;
  qw_tq2_q3_min_x10              : INT;
  qw_tq2_q3_max_x10              : INT;
  qw_tq2_q4_unit                 : INT;
  qw_tq2_q4_stage                : INT;
  qw_tq2_q4_lift                 : INT;
  qw_tq2_q4_sink                 : INT;
  qw_tq2_q4_start_hi             : INT;
  qw_tq2_q4_start_lo             : INT;
  qw_tq2_q4_fin_hi               : INT;
  qw_tq2_q4_fin_lo               : INT;
  qw_tq2_q4_calc_x10             : INT;
  qw_tq2_q4_min_x10              : INT;
  qw_tq2_q4_max_x10              : INT;
  qw_tq2_q5_unit                 : INT;
  qw_tq2_q5_stage                : INT;
  qw_tq2_q5_lift                 : INT;
  qw_tq2_q5_sink                 : INT;
  qw_tq2_q5_start_hi             : INT;
  qw_tq2_q5_start_lo             : INT;
  qw_tq2_q5_fin_hi               : INT;
  qw_tq2_q5_fin_lo               : INT;
  qw_tq2_q5_calc_x10             : INT;
  qw_tq2_q5_min_x10              : INT;
  qw_tq2_q5_max_x10              : INT;
  qw_tq2_q6_unit                 : INT;
  qw_tq2_q6_stage                : INT;
  qw_tq2_q6_lift                 : INT;
  qw_tq2_q6_sink                 : INT;
  qw_tq2_q6_start_hi             : INT;
  qw_tq2_q6_start_lo             : INT;
  qw_tq2_q6_fin_hi               : INT;
  qw_tq2_q6_fin_lo               : INT;
  qw_tq2_q6_calc_x10             : INT;
  qw_tq2_q6_min_x10              : INT;
  qw_tq2_q6_max_x10              : INT;
  qw_tq2_q7_unit                 : INT;
  qw_tq2_q7_stage                : INT;
  qw_tq2_q7_lift                 : INT;
  qw_tq2_q7_sink                 : INT;
  qw_tq2_q7_start_hi             : INT;
  qw_tq2_q7_start_lo             : INT;
  qw_tq2_q7_fin_hi               : INT;
  qw_tq2_q7_fin_lo               : INT;
  qw_tq2_q7_calc_x10             : INT;
  qw_tq2_q7_min_x10              : INT;
  qw_tq2_q7_max_x10              : INT;
  qw_tq2_q8_unit                 : INT;
  qw_tq2_q8_stage                : INT;
  qw_tq2_q8_lift                 : INT;
  qw_tq2_q8_sink                 : INT;
  qw_tq2_q8_start_hi             : INT;
  qw_tq2_q8_start_lo             : INT;
  qw_tq2_q8_fin_hi               : INT;
  qw_tq2_q8_fin_lo               : INT;
  qw_tq2_q8_calc_x10             : INT;
  qw_tq2_q8_min_x10              : INT;
  qw_tq2_q8_max_x10              : INT;
  qw_tq2_q9_unit                 : INT;
  qw_tq2_q9_stage                : INT;
  qw_tq2_q9_lift                 : INT;
  qw_tq2_q9_sink                 : INT;
  qw_tq2_q9_start_hi             : INT;
  qw_tq2_q9_start_lo             : INT;
  qw_tq2_q9_fin_hi               : INT;
  qw_tq2_q9_fin_lo               : INT;
  qw_tq2_q9_calc_x10             : INT;
  qw_tq2_q9_min_x10              : INT;
  qw_tq2_q9_max_x10              : INT;
  qw_tq2_q10_unit                : INT;
  qw_tq2_q10_stage               : INT;
  qw_tq2_q10_lift                : INT;
  qw_tq2_q10_sink                : INT;
  qw_tq2_q10_start_hi            : INT;
  qw_tq2_q10_start_lo            : INT;
  qw_tq2_q10_fin_hi              : INT;
  qw_tq2_q10_fin_lo              : INT;
  qw_tq2_q10_calc_x10            : INT;
  qw_tq2_q10_min_x10             : INT;
  qw_tq2_q10_max_x10             : INT;
  qw_tq3_count                   : INT;
  qw_tq3_q1_unit                 : INT;
  qw_tq3_q1_stage                : INT;
  qw_tq3_q1_lift                 : INT;
  qw_tq3_q1_sink                 : INT;
  qw_tq3_q1_start_hi             : INT;
  qw_tq3_q1_start_lo             : INT;
  qw_tq3_q1_fin_hi               : INT;
  qw_tq3_q1_fin_lo               : INT;
  qw_tq3_q1_calc_x10             : INT;
  qw_tq3_q1_min_x10              : INT;
  qw_tq3_q1_max_x10              : INT;
  qw_tq3_q2_unit                 : INT;
  qw_tq3_q2_stage                : INT;
  qw_tq3_q2_lift                 : INT;
  qw_tq3_q2_sink                 : INT;
  qw_tq3_q2_start_hi             : INT;
  qw_tq3_q2_start_lo             : INT;
  qw_tq3_q2_fin_hi               : INT;
  qw_tq3_q2_fin_lo               : INT;
  qw_tq3_q2_calc_x10             : INT;
  qw_tq3_q2_min_x10              : INT;
  qw_tq3_q2_max_x10              : INT;
  qw_tq3_q3_unit                 : INT;
  qw_tq3_q3_stage                : INT;
  qw_tq3_q3_lift                 : INT;
  qw_tq3_q3_sink                 : INT;
  qw_tq3_q3_start_hi             : INT;
  qw_tq3_q3_start_lo             : INT;
  qw_tq3_q3_fin_hi               : INT;
  qw_tq3_q3_fin_lo               : INT;
  qw_tq3_q3_calc_x10             : INT;
  qw_tq3_q3_min_x10              : INT;
  qw_tq3_q3_max_x10              : INT;
  qw_tq3_q4_unit                 : INT;
  qw_tq3_q4_stage                : INT;
  qw_tq3_q4_lift                 : INT;
  qw_tq3_q4_sink                 : INT;
  qw_tq3_q4_start_hi             : INT;
  qw_tq3_q4_start_lo             : INT;
  qw_tq3_q4_fin_hi               : INT;
  qw_tq3_q4_fin_lo               : INT;
  qw_tq3_q4_calc_x10             : INT;
  qw_tq3_q4_min_x10              : INT;
  qw_tq3_q4_max_x10              : INT;
  qw_tq3_q5_unit                 : INT;
  qw_tq3_q5_stage                : INT;
  qw_tq3_q5_lift                 : INT;
  qw_tq3_q5_sink                 : INT;
  qw_tq3_q5_start_hi             : INT;
  qw_tq3_q5_start_lo             : INT;
  qw_tq3_q5_fin_hi               : INT;
  qw_tq3_q5_fin_lo               : INT;
  qw_tq3_q5_calc_x10             : INT;
  qw_tq3_q5_min_x10              : INT;
  qw_tq3_q5_max_x10              : INT;
  qw_tq3_q6_unit                 : INT;
  qw_tq3_q6_stage                : INT;
  qw_tq3_q6_lift                 : INT;
  qw_tq3_q6_sink                 : INT;
  qw_tq3_q6_start_hi             : INT;
  qw_tq3_q6_start_lo             : INT;
  qw_tq3_q6_fin_hi               : INT;
  qw_tq3_q6_fin_lo               : INT;
  qw_tq3_q6_calc_x10             : INT;
  qw_tq3_q6_min_x10              : INT;
  qw_tq3_q6_max_x10              : INT;
  qw_tq3_q7_unit                 : INT;
  qw_tq3_q7_stage                : INT;
  qw_tq3_q7_lift                 : INT;
  qw_tq3_q7_sink                 : INT;
  qw_tq3_q7_start_hi             : INT;
  qw_tq3_q7_start_lo             : INT;
  qw_tq3_q7_fin_hi               : INT;
  qw_tq3_q7_fin_lo               : INT;
  qw_tq3_q7_calc_x10             : INT;
  qw_tq3_q7_min_x10              : INT;
  qw_tq3_q7_max_x10              : INT;
  qw_tq3_q8_unit                 : INT;
  qw_tq3_q8_stage                : INT;
  qw_tq3_q8_lift                 : INT;
  qw_tq3_q8_sink                 : INT;
  qw_tq3_q8_start_hi             : INT;
  qw_tq3_q8_start_lo             : INT;
  qw_tq3_q8_fin_hi               : INT;
  qw_tq3_q8_fin_lo               : INT;
  qw_tq3_q8_calc_x10             : INT;
  qw_tq3_q8_min_x10              : INT;
  qw_tq3_q8_max_x10              : INT;
  qw_tq3_q9_unit                 : INT;
  qw_tq3_q9_stage                : INT;
  qw_tq3_q9_lift                 : INT;
  qw_tq3_q9_sink                 : INT;
  qw_tq3_q9_start_hi             : INT;
  qw_tq3_q9_start_lo             : INT;
  qw_tq3_q9_fin_hi               : INT;
  qw_tq3_q9_fin_lo               : INT;
  qw_tq3_q9_calc_x10             : INT;
  qw_tq3_q9_min_x10              : INT;
  qw_tq3_q9_max_x10              : INT;
  qw_tq3_q10_unit                : INT;
  qw_tq3_q10_stage               : INT;
  qw_tq3_q10_lift                : INT;
  qw_tq3_q10_sink                : INT;
  qw_tq3_q10_start_hi            : INT;
  qw_tq3_q10_start_lo            : INT;
  qw_tq3_q10_fin_hi              : INT;
  qw_tq3_q10_fin_lo              : INT;
  qw_tq3_q10_calc_x10            : INT;
  qw_tq3_q10_min_x10             : INT;
  qw_tq3_q10_max_x10             : INT;
  qw_dep_state_activated         : INT;
  qw_dep_state_stable            : INT;
  qw_dep_state_waiting_cnt       : INT;
  qw_dep_state_overlap_cnt       : INT;
  qw_dep_state_pend_valid        : INT;
  qw_dep_state_pend_unit         : INT;
  qw_dep_state_pend_stage        : INT;
  qw_dep_state_pend_time_hi      : INT;
  qw_dep_state_pend_time_lo      : INT;
  qw_dw1_unit                    : INT;
  qw_dw2_unit                    : INT;
  qw_dw3_unit                    : INT;
  qw_dw4_unit                    : INT;
  qw_dw5_unit                    : INT;
  qw_ov_s101_flag                : INT;
  qw_ov_s102_flag                : INT;
  qw_ov_s103_flag                : INT;
  qw_ov_s104_flag                : INT;
  qw_ov_s105_flag                : INT;
  qw_ov_s106_flag                : INT;
  qw_ov_s107_flag                : INT;
  qw_ov_s108_flag                : INT;
  qw_ov_s109_flag                : INT;
  qw_ov_s110_flag                : INT;
  qw_ov_s111_flag                : INT;
  qw_ov_s112_flag                : INT;
  qw_ov_s113_flag                : INT;
  qw_ov_s114_flag                : INT;
  qw_ov_s115_flag                : INT;
  qw_ov_s116_flag                : INT;
  qw_ov_s117_flag                : INT;
  qw_ov_s118_flag                : INT;
  qw_ov_s119_flag                : INT;
  qw_ov_s120_flag                : INT;
  qw_ov_s121_flag                : INT;
  qw_ov_s122_flag                : INT;
  qw_ov_s123_flag                : INT;
  qw_ov_s124_flag                : INT;
  qw_ov_s125_flag                : INT;
  qw_ov_s126_flag                : INT;
  qw_ov_s127_flag                : INT;
  qw_ov_s128_flag                : INT;
  qw_ov_s129_flag                : INT;
  qw_ov_s130_flag                : INT;
  iw_cmd_t1_start                : INT;
  iw_cmd_t1_lift                 : INT;
  iw_cmd_t1_sink                 : INT;
  iw_cmd_t2_start                : INT;
  iw_cmd_t2_lift                 : INT;
  iw_cmd_t2_sink                 : INT;
  iw_cfg_seq                     : INT;
  iw_cfg_cmd                     : INT;
  iw_cfg_param                   : INT;
  iw_cfg_d0                      : INT;
  iw_cfg_d1                      : INT;
  iw_cfg_d2                      : INT;
  iw_cfg_d3                      : INT;
  iw_cfg_d4                      : INT;
  iw_cfg_d5                      : INT;
  iw_cfg_d6                      : INT;
  iw_cfg_d7                      : INT;
  iw_unit_seq                    : INT;
  iw_unit_id                     : INT;
  iw_unit_loc                    : INT;
  iw_unit_status                 : INT;
  iw_unit_target                 : INT;
  iw_batch_seq                   : INT;
  iw_batch_unit                  : INT;
  iw_batch_code                  : INT;
  iw_batch_state                 : INT;
  iw_batch_prog_id               : INT;
  iw_prog_seq                    : INT;
  iw_prog_unit                   : INT;
  iw_prog_stage                  : INT;
  iw_prog_s1                     : INT;
  iw_prog_s2                     : INT;
  iw_prog_s3                     : INT;
  iw_prog_s4                     : INT;
  iw_prog_s5                     : INT;
  iw_prog_min_time               : INT;
  iw_prog_max_time               : INT;
  iw_prog_cal_time               : INT;
  iw_avoid_seq                   : INT;
  iw_avoid_station               : INT;
  iw_avoid_value                 : INT;
  iw_production_queue            : INT;
  iw_time_hi                     : INT;
  iw_time_lo                     : INT;
  qw_event_out_count             : INT;
  qw_event_out_seq               : INT;
  qw_event_out_type              : INT;
  qw_event_out_ts_hi             : INT;
  qw_event_out_ts_lo             : INT;
  qw_event_out_f1                : INT;
  qw_event_out_f2                : INT;
  qw_event_out_f3                : INT;
  qw_event_out_f4                : INT;
  qw_event_out_f5                : INT;
  qw_event_out_f6                : INT;
  qw_event_out_f7                : INT;
  qw_event_out_f8                : INT;
  qw_event_out_f9                : INT;
  qw_event_out_f10               : INT;
  qw_event_out_f11               : INT;
  qw_event_out_f12               : INT;
  iw_event_ack_seq               : INT;
  (* --- END GENERATED MODBUS EXTERNALS --- *)













END_VAR
VAR
  init_done      : BOOL := FALSE;
  last_cfg_seq   : INT := 0;
  last_unit_seq  : INT := 0;
  last_batch_seq : INT := 0;
  last_prog_seq  : INT := 0;
  last_avoid_seq : INT := 0;
  j              : INT;
  k              : INT;
  i              : INT;
  stn_num        : INT;
  idx          : INT;
  twa_calc     : TWA_FB_CalcLimits;
  clear_cfg    : SIM_FB_ClearConfig;
  cycle_count  : INT;
  main_sched   : STC_FB_MainScheduler;
  run_tasks    : SIM_FB_RunTasks;
  calibrate    : STC_FB_Calibrate;
  calc_move    : STC_FB_CalcMoveTimes;
  evt_queue    : STC_FB_EventQueue;
  cal_cmd      : INT := 0;
  cal_load_run : BOOL := FALSE;  (* one-shot trigger for calc_move *)
  (* Time-keeping vars *)
  time_hi        : LINT;
  time_lo        : LINT;
  time_cycle_cnt : INT := 0;      (* counts 20ms cycles, resets at 50 = 1 s *)
  last_sync_hi   : INT := 0;      (* previous gateway iw_time_hi — for change detect *)
  last_sync_lo   : INT := 0;      (* previous gateway iw_time_lo *)
END_VAR
(* ============================================================
   CONFIG UPLOAD HANDLER
   Gateway writes station data one at a time via Modbus IW regs.
   Sequence number change triggers processing.
   cmd=1: write_station  cmd=2: init  cmd=3: clear_all
   ============================================================ *)
IF iw_cfg_seq <> last_cfg_seq THEN
  last_cfg_seq := iw_cfg_seq;

  IF iw_cfg_cmd = 3 THEN
    (* --- Clear all config data --- *)
    clear_cfg();
    init_done := FALSE;
    g_station_count := 0;

  ELSIF iw_cfg_cmd = 1 THEN
    (* --- Write one station to g_station array --- *)
    IF (iw_cfg_param >= STATION_ARRAY_START) AND (iw_cfg_param <= STATION_ARRAY_END) THEN
      g_station[iw_cfg_param].tank_id       := iw_cfg_d0;
      g_station[iw_cfg_param].x_position    := INT_TO_REAL(iw_cfg_d1);
      g_station[iw_cfg_param].y_position    := INT_TO_REAL(iw_cfg_d2);
      g_station[iw_cfg_param].z_position    := INT_TO_REAL(iw_cfg_d3);
      g_station[iw_cfg_param].operation     := iw_cfg_d4;
      g_station[iw_cfg_param].kind            := iw_cfg_d7;
      g_station[iw_cfg_param].dropping_time := INT_TO_REAL(iw_cfg_d5) / 10.0;
      g_station[iw_cfg_param].device_delay  := INT_TO_REAL(iw_cfg_d6) / 10.0;
    END_IF;

  ELSIF iw_cfg_cmd = 4 THEN
    (* --- Write transporter physics page 1 --- *)
    (* param = transporter_id (1..3)
       d0 = x_min_limit mm      d1 = x_max_limit mm
       d2 = x_accel_s × 10      d3 = x_decel_s × 10
       d4 = x_max_mm_s           d5 = z_total_mm
       d6 = avoid_mm *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cfg[j].x_min_limit          := INT_TO_REAL(iw_cfg_d0);
      g_cfg[j].x_max_limit          := INT_TO_REAL(iw_cfg_d1);
      g_cfg[j].phys2d.x_accel_s     := INT_TO_REAL(iw_cfg_d2) / 10.0;
      g_cfg[j].phys2d.x_decel_s     := INT_TO_REAL(iw_cfg_d3) / 10.0;
      g_cfg[j].phys2d.x_max_mm_s    := INT_TO_REAL(iw_cfg_d4);
      g_cfg[j].phys2d.z_total_mm    := INT_TO_REAL(iw_cfg_d5);
      g_cfg[j].phys2d.avoid_mm      := INT_TO_REAL(iw_cfg_d6);
      g_cfg[j].x_avoid_mm           := INT_TO_REAL(iw_cfg_d6);
    END_IF;

  ELSIF iw_cfg_cmd = 5 THEN
    (* --- Write transporter physics page 2 --- *)
    (* param = transporter_id (1..3)
       d0 = z_slow_dry_mm        d1 = z_slow_wet_mm
       d2 = z_slow_end_mm        d3 = z_slow_mm_s
       d4 = z_fast_mm_s          d5 = drip_delay_s × 10
       d6 = (reserved) *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cfg[j].phys2d.z_slow_dry_mm := INT_TO_REAL(iw_cfg_d0);
      g_cfg[j].phys2d.z_slow_wet_mm := INT_TO_REAL(iw_cfg_d1);
      g_cfg[j].phys2d.z_slow_end_mm := INT_TO_REAL(iw_cfg_d2);
      g_cfg[j].phys2d.z_slow_mm_s   := INT_TO_REAL(iw_cfg_d3);
      g_cfg[j].phys2d.z_fast_mm_s   := INT_TO_REAL(iw_cfg_d4);
      g_cfg[j].phys2d.drip_delay_s  := INT_TO_REAL(iw_cfg_d5) / 10.0;
    END_IF;

  ELSIF iw_cfg_cmd = 6 THEN
    (* --- Write transporter task area --- *)
    (* param = transporter_id × 10 + area_index
       e.g. 11 = transporter 1 area 1, 23 = transporter 2 area 3
       d0 = min_lift   d1 = max_lift
       d2 = min_sink   d3 = max_sink *)
    j := iw_cfg_param / 10;
    k := iw_cfg_param MOD 10;
    IF (j >= 1) AND (j <= 3) AND (k >= 1) AND (k <= 4) THEN
      g_cfg[j].task_area[k].min_lift := iw_cfg_d0;
      g_cfg[j].task_area[k].max_lift := iw_cfg_d1;
      g_cfg[j].task_area[k].min_sink := iw_cfg_d2;
      g_cfg[j].task_area[k].max_sink := iw_cfg_d3;
    END_IF;

  ELSIF iw_cfg_cmd = 7 THEN
    (* --- Calibration plan for one transporter --- *)
    (* param = transporter_id (1..3)
       d0 = wet_station   d1 = dry_station *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cal[j].wet_station := iw_cfg_d0;
      g_cal[j].dry_station := iw_cfg_d1;
    END_IF;

  ELSIF iw_cfg_cmd = 8 THEN
    (* --- Calibration control --- *)
    (* param: 1=start, 2=calculate, 3=abort *)
    cal_cmd := iw_cfg_param;

  ELSIF iw_cfg_cmd = 9 THEN
    (* --- Write NTT primary stations --- *)
    (* param = transporter_id × 100 + target_code × 10 + station_count
       e.g. 112 = transporter 1, TO_LOADING(1), 2 stations
       d0..d4 = stations[1..5] *)
    j := iw_cfg_param / 100;             (* transporter *)
    k := (iw_cfg_param / 10) MOD 10;     (* target code 1..8 *)
    i := iw_cfg_param MOD 10;            (* station_count *)
    IF (j >= 1) AND (j <= MAX_TRANSPORTERS) AND (k >= 1) AND (k <= 8) AND (i >= 0) AND (i <= MAX_PARALLELS) THEN
      g_ntt[j].target[k].station_count := i;
      g_ntt[j].target[k].stations[1] := iw_cfg_d0;
      g_ntt[j].target[k].stations[2] := iw_cfg_d1;
      g_ntt[j].target[k].stations[3] := iw_cfg_d2;
      g_ntt[j].target[k].stations[4] := iw_cfg_d3;
      g_ntt[j].target[k].stations[5] := iw_cfg_d4;
    END_IF;

  ELSIF iw_cfg_cmd = 10 THEN
    (* --- Write NTT fallback stations --- *)
    (* param = transporter_id × 100 + target_code × 10 + fallback_count
       d0..d4 = fallback_stations[1..5] *)
    j := iw_cfg_param / 100;             (* transporter *)
    k := (iw_cfg_param / 10) MOD 10;     (* target code 1..8 *)
    i := iw_cfg_param MOD 10;            (* fallback_count *)
    IF (j >= 1) AND (j <= MAX_TRANSPORTERS) AND (k >= 1) AND (k <= 8) AND (i >= 0) AND (i <= MAX_PARALLELS) THEN
      g_ntt[j].target[k].fallback_count := i;
      g_ntt[j].target[k].fallback_stations[1] := iw_cfg_d0;
      g_ntt[j].target[k].fallback_stations[2] := iw_cfg_d1;
      g_ntt[j].target[k].fallback_stations[3] := iw_cfg_d2;
      g_ntt[j].target[k].fallback_stations[4] := iw_cfg_d3;
      g_ntt[j].target[k].fallback_stations[5] := iw_cfg_d4;
    END_IF;

  ELSIF iw_cfg_cmd = 11 THEN
    (* --- Load kinematic params for one transporter into g_cal --- *)
    (* param = tid (1..3)
       d0 = lift_wet_s × 100   d1 = sink_wet_s × 100
       d2 = lift_dry_s × 100   d3 = sink_dry_s × 100
       d4 = x_accel_s × 100    d5 = x_decel_s × 100
       d6 = x_max_mm_s (integer, mm/s) *)
    j := iw_cfg_param;
    IF (j >= 1) AND (j <= 3) THEN
      g_cal[j].lift_wet_s := INT_TO_REAL(iw_cfg_d0) / 100.0;
      g_cal[j].sink_wet_s := INT_TO_REAL(iw_cfg_d1) / 100.0;
      g_cal[j].lift_dry_s := INT_TO_REAL(iw_cfg_d2) / 100.0;
      g_cal[j].sink_dry_s := INT_TO_REAL(iw_cfg_d3) / 100.0;
      g_cal[j].x_accel_s  := INT_TO_REAL(iw_cfg_d4) / 100.0;
      g_cal[j].x_decel_s  := INT_TO_REAL(iw_cfg_d5) / 100.0;
      g_cal[j].x_max_mm_s := INT_TO_REAL(iw_cfg_d6);
    END_IF;

  ELSIF iw_cfg_cmd = 12 THEN
    (* --- Compute g_move from loaded g_cal kinematic params --- *)
    (* No params needed — computes for all transporters with valid g_cal *)
    cal_load_run := TRUE;

  ELSIF iw_cfg_cmd = 2 THEN
    (* --- Finish init: all config uploaded, init transporter states --- *)
    g_station_count := iw_cfg_param;

    FOR i := 1 TO MAX_TRANSPORTERS DO
      (* Active if task_area[1] has non-zero stations *)
      IF g_cfg[i].task_area[1].min_lift > 0 THEN
        g_transporter[i].active := TRUE;
        g_transporter[i].status := 3;  (* auto_idle *)
      ELSE
        g_transporter[i].active := FALSE;
        g_transporter[i].status := 0;  (* not_used *)
      END_IF;
      g_transporter[i].phase := 0;
      g_transporter[i].z_stage := 0;
      g_transporter[i].vel_x := 0.0;
      g_transporter[i].z_timer_s := 0.0;
      g_transporter[i].x_min_limit := g_cfg[i].x_min_limit;
      g_transporter[i].x_max_limit := g_cfg[i].x_max_limit;

      (* Start position: at own area minimum, z=0 *)
      g_transporter[i].x_mm := g_cfg[i].x_min_limit;
      g_transporter[i].z_mm := 0.0;
      g_transporter[i].current_station := 0;
    END_FOR;

    init_done := TRUE;

    (* Init event queue *)
    g_event.head := 1;
    g_event.next_seq := 1;
    g_event.count := 0;
  END_IF;
END_IF;

(* ============================================================
   MAIN TRANSPORT CYCLE — only runs when init_done
   ============================================================ *)
IF init_done THEN

(* ── Compute g_move from loaded kinematic params (one-shot) ── *)
calc_move(i_run := cal_load_run);
IF cal_load_run THEN
  cal_load_run := FALSE;
END_IF;

(* Calculate transporter working areas (X-limits) every cycle *)
twa_calc();

(* ── Production queue sync from gateway ── *)
g_production_queue := iw_production_queue;

(* ── Unix time maintenance ── *)
(* PLC keeps g_time_s by incrementing +1 every 50 cycles (50 × 20 ms = 1 s).
   Gateway periodically writes reference unix seconds to QW160/QW161.
   When PLC detects the register values changed → sync to gateway time. *)
IF iw_time_hi <> last_sync_hi OR iw_time_lo <> last_sync_lo THEN
  (* Gateway wrote new reference time — sync *)
  time_hi := INT_TO_LINT(iw_time_hi);
  IF time_hi < LINT#0 THEN
    time_hi := time_hi + LINT#65536;
  END_IF;
  time_lo := INT_TO_LINT(iw_time_lo);
  IF time_lo < LINT#0 THEN
    time_lo := time_lo + LINT#65536;
  END_IF;
  g_time_s := time_hi * LINT#65536 + time_lo;
  last_sync_hi := iw_time_hi;
  last_sync_lo := iw_time_lo;
  time_cycle_cnt := 0;
ELSE
  (* Self-increment: +1 second every 50 cycles (50 × 20 ms) *)
  time_cycle_cnt := time_cycle_cnt + 1;
  IF time_cycle_cnt >= 50 THEN
    g_time_s := g_time_s + LINT#1;
    time_cycle_cnt := 0;
  END_IF;
END_IF;

(* ── Main Scheduler (TSK + DEP alternating cycles) ── *)
main_sched(i_run := init_done, i_time_s := g_time_s);

(* ── Execute transporter tasks (physics simulation) ── *)
run_tasks(i_run := init_done);

(* ── Calibration FB — issues test tasks, measures parameters ── *)
calibrate(i_run := init_done, i_cmd := cal_cmd);
cal_cmd := 0;   (* consumed after one cycle *)
g_cal_active := calibrate.o_active;

END_IF;  (* init_done *)

(* ── Event queue — always runs, not gated by init_done ── *)
evt_queue();

(* ============================================================
   UNIT WRITE HANDLER — gateway writes one unit at a time
   ============================================================ *)
IF iw_unit_seq <> last_unit_seq THEN
  last_unit_seq := iw_unit_seq;
  IF (iw_unit_id >= 1) AND (iw_unit_id <= MAX_UNITS) THEN
    (* Clear unit_id from old station if unit had a valid location *)
    IF (g_unit[iw_unit_id].location >= STATION_ARRAY_START) AND (g_unit[iw_unit_id].location <= STATION_ARRAY_END) THEN
      g_station[g_unit[iw_unit_id].location].unit_id := 0;
    END_IF;

    g_unit[iw_unit_id].location := iw_unit_loc;
    g_unit[iw_unit_id].status   := iw_unit_status;
    g_unit[iw_unit_id].target   := iw_unit_target;

    (* Set unit_id on the new station *)
    IF (iw_unit_loc >= STATION_ARRAY_START) AND (iw_unit_loc <= STATION_ARRAY_END) THEN
      g_station[iw_unit_loc].unit_id := iw_unit_id;
    END_IF;
  END_IF;
END_IF;

(* ============================================================
   BATCH WRITE HANDLER — gateway writes batch data + program_id
   Also clears all stages of the treatment program for this unit.
   ============================================================ *)
IF iw_batch_seq <> last_batch_seq THEN
  last_batch_seq := iw_batch_seq;
  IF (iw_batch_unit >= 1) AND (iw_batch_unit <= MAX_UNITS) THEN
    g_batch[iw_batch_unit].batch_code := iw_batch_code;
    g_batch[iw_batch_unit].state      := iw_batch_state;
    g_batch[iw_batch_unit].prog_id    := iw_batch_prog_id;
    g_batch[iw_batch_unit].cur_stage      := 0;
    g_program[iw_batch_unit].program_id := iw_batch_prog_id;
    (* Clear all stages *)
    FOR j := 1 TO 30 DO
      FOR k := 1 TO 5 DO
        g_program[iw_batch_unit].stages[j].stations[k] := 0;
      END_FOR;
      g_program[iw_batch_unit].stages[j].min_time := 0;
      g_program[iw_batch_unit].stages[j].max_time := 0;
      g_program[iw_batch_unit].stages[j].cal_time := 0;
    END_FOR;
  END_IF;
END_IF;

(* ============================================================
   PROGRAM STAGE WRITE HANDLER — gateway writes one stage at a time
   ============================================================ *)
IF iw_prog_seq <> last_prog_seq THEN
  last_prog_seq := iw_prog_seq;
  IF (iw_prog_unit >= 1) AND (iw_prog_unit <= MAX_UNITS) AND
     (iw_prog_stage >= 1) AND (iw_prog_stage <= 30) THEN
    g_program[iw_prog_unit].stages[iw_prog_stage].stations[1] := iw_prog_s1;
    g_program[iw_prog_unit].stages[iw_prog_stage].stations[2] := iw_prog_s2;
    g_program[iw_prog_unit].stages[iw_prog_stage].stations[3] := iw_prog_s3;
    g_program[iw_prog_unit].stages[iw_prog_stage].stations[4] := iw_prog_s4;
    g_program[iw_prog_unit].stages[iw_prog_stage].stations[5] := iw_prog_s5;
    g_program[iw_prog_unit].stages[iw_prog_stage].min_time := iw_prog_min_time;
    g_program[iw_prog_unit].stages[iw_prog_stage].max_time := iw_prog_max_time;
    g_program[iw_prog_unit].stages[iw_prog_stage].cal_time := iw_prog_cal_time;
  END_IF;
END_IF;

(* ============================================================
   AVOID STATUS WRITE HANDLER — gateway writes one avoid status at a time
   ============================================================ *)
IF iw_avoid_seq <> last_avoid_seq THEN
  last_avoid_seq := iw_avoid_seq;
  IF (iw_avoid_station >= STATION_ARRAY_START) AND (iw_avoid_station <= STATION_ARRAY_END) THEN
    g_avoid_status[iw_avoid_station] := iw_avoid_value;
  END_IF;
END_IF;

(* === MODBUS INPUT: Read commands → g_transporter command fields === *)
(* Note: task_id sync will be handled by SIM_FB_RunTasks later.
   For now, keep the old Modbus command interface working via direct write. *)
IF (iw_cmd_t1_start <> 0) AND (g_transporter[1].status = 3) THEN
  g_transporter[1].task_id := g_time_s;
  g_transporter[1].lift_station := iw_cmd_t1_lift;
  g_transporter[1].sink_station := iw_cmd_t1_sink;
END_IF;
IF (iw_cmd_t2_start <> 0) AND (g_transporter[2].status = 3) THEN
  g_transporter[2].task_id := g_time_s;
  g_transporter[2].lift_station := iw_cmd_t2_lift;
  g_transporter[2].sink_station := iw_cmd_t2_sink;
END_IF;

(* ── Cycle counter ── *)
cycle_count := cycle_count + 1;
IF cycle_count > 30000 THEN cycle_count := 0; END_IF;

(* --- BEGIN GENERATED MODBUS OUTPUT --- *)
(* Auto-generated from modbus_map.json — 760 output registers *)

(* === Per-transporter live state — PLC writes, gateway reads === *)
qw_t1_x_mm := REAL_TO_INT(g_transporter[1].x_mm);
qw_t1_z_mm := REAL_TO_INT(g_transporter[1].z_mm);
qw_t1_vel_x10 := REAL_TO_INT(g_transporter[1].vel_x * 10.0);
qw_t1_phase := g_transporter[1].phase;
qw_t1_unit_id := g_transporter[1].unit_id;
qw_t1_z_stage := g_transporter[1].z_stage;
qw_t1_cur_st := g_transporter[1].current_station;
qw_t1_lift_tgt := g_transporter[1].lift_station;
qw_t1_sink_tgt := g_transporter[1].sink_station;
IF g_transporter[1].active THEN qw_t1_active := 1; ELSE qw_t1_active := 0; END_IF;
qw_t1_status := g_transporter[1].status;
qw_t1_rtask_hi := LINT_TO_INT(g_transporter[1].running_task_id / 65536);
qw_t1_rtask_lo := LINT_TO_INT(g_transporter[1].running_task_id MOD 65536);
qw_t2_x_mm := REAL_TO_INT(g_transporter[2].x_mm);
qw_t2_z_mm := REAL_TO_INT(g_transporter[2].z_mm);
qw_t2_vel_x10 := REAL_TO_INT(g_transporter[2].vel_x * 10.0);
qw_t2_phase := g_transporter[2].phase;
qw_t2_unit_id := g_transporter[2].unit_id;
qw_t2_z_stage := g_transporter[2].z_stage;
qw_t2_cur_st := g_transporter[2].current_station;
qw_t2_lift_tgt := g_transporter[2].lift_station;
qw_t2_sink_tgt := g_transporter[2].sink_station;
IF g_transporter[2].active THEN qw_t2_active := 1; ELSE qw_t2_active := 0; END_IF;
qw_t2_status := g_transporter[2].status;
qw_t2_rtask_hi := LINT_TO_INT(g_transporter[2].running_task_id / 65536);
qw_t2_rtask_lo := LINT_TO_INT(g_transporter[2].running_task_id MOD 65536);
qw_t3_x_mm := REAL_TO_INT(g_transporter[3].x_mm);
qw_t3_z_mm := REAL_TO_INT(g_transporter[3].z_mm);
qw_t3_vel_x10 := REAL_TO_INT(g_transporter[3].vel_x * 10.0);
qw_t3_phase := g_transporter[3].phase;
qw_t3_unit_id := g_transporter[3].unit_id;
qw_t3_z_stage := g_transporter[3].z_stage;
qw_t3_cur_st := g_transporter[3].current_station;
qw_t3_lift_tgt := g_transporter[3].lift_station;
qw_t3_sink_tgt := g_transporter[3].sink_station;
IF g_transporter[3].active THEN qw_t3_active := 1; ELSE qw_t3_active := 0; END_IF;
qw_t3_status := g_transporter[3].status;
qw_t3_rtask_hi := LINT_TO_INT(g_transporter[3].running_task_id / 65536);
qw_t3_rtask_lo := LINT_TO_INT(g_transporter[3].running_task_id MOD 65536);
(* === Per-transporter extended state — remaining STC_TRANSPORTER_T fields === *)
qw_t1_remain_x10 := REAL_TO_INT(g_transporter[1].remaining_time * 10.0);
qw_t1_treat_time := REAL_TO_INT(g_transporter[1].treatment_time);
qw_t1_fintgt_x := REAL_TO_INT(g_transporter[1].final_target_x);
qw_t1_drvtgt_x := REAL_TO_INT(g_transporter[1].drive_target_x);
qw_t1_fintgt_y := REAL_TO_INT(g_transporter[1].final_target_y);
qw_t1_drvtgt_y := REAL_TO_INT(g_transporter[1].drive_target_y);
qw_t1_y_mm := REAL_TO_INT(g_transporter[1].y_mm);
qw_t1_ztimer_x10 := REAL_TO_INT(g_transporter[1].z_timer_s * 10.0);
qw_t1_ctask_hi := LINT_TO_INT(g_transporter[1].task_id / 65536);
qw_t1_ctask_lo := LINT_TO_INT(g_transporter[1].task_id MOD 65536);
qw_t1_ldev_x10 := REAL_TO_INT(g_transporter[1].lift_device_delay * 10.0);
qw_t1_sdev_x10 := REAL_TO_INT(g_transporter[1].sink_device_delay * 10.0);
qw_t1_drop_x10 := REAL_TO_INT(g_transporter[1].dropping_time * 10.0);
qw_t2_remain_x10 := REAL_TO_INT(g_transporter[2].remaining_time * 10.0);
qw_t2_treat_time := REAL_TO_INT(g_transporter[2].treatment_time);
qw_t2_fintgt_x := REAL_TO_INT(g_transporter[2].final_target_x);
qw_t2_drvtgt_x := REAL_TO_INT(g_transporter[2].drive_target_x);
qw_t2_fintgt_y := REAL_TO_INT(g_transporter[2].final_target_y);
qw_t2_drvtgt_y := REAL_TO_INT(g_transporter[2].drive_target_y);
qw_t2_y_mm := REAL_TO_INT(g_transporter[2].y_mm);
qw_t2_ztimer_x10 := REAL_TO_INT(g_transporter[2].z_timer_s * 10.0);
qw_t2_ctask_hi := LINT_TO_INT(g_transporter[2].task_id / 65536);
qw_t2_ctask_lo := LINT_TO_INT(g_transporter[2].task_id MOD 65536);
qw_t2_ldev_x10 := REAL_TO_INT(g_transporter[2].lift_device_delay * 10.0);
qw_t2_sdev_x10 := REAL_TO_INT(g_transporter[2].sink_device_delay * 10.0);
qw_t2_drop_x10 := REAL_TO_INT(g_transporter[2].dropping_time * 10.0);
qw_t3_remain_x10 := REAL_TO_INT(g_transporter[3].remaining_time * 10.0);
qw_t3_treat_time := REAL_TO_INT(g_transporter[3].treatment_time);
qw_t3_fintgt_x := REAL_TO_INT(g_transporter[3].final_target_x);
qw_t3_drvtgt_x := REAL_TO_INT(g_transporter[3].drive_target_x);
qw_t3_fintgt_y := REAL_TO_INT(g_transporter[3].final_target_y);
qw_t3_drvtgt_y := REAL_TO_INT(g_transporter[3].drive_target_y);
qw_t3_y_mm := REAL_TO_INT(g_transporter[3].y_mm);
qw_t3_ztimer_x10 := REAL_TO_INT(g_transporter[3].z_timer_s * 10.0);
qw_t3_ctask_hi := LINT_TO_INT(g_transporter[3].task_id / 65536);
qw_t3_ctask_lo := LINT_TO_INT(g_transporter[3].task_id MOD 65536);
qw_t3_ldev_x10 := REAL_TO_INT(g_transporter[3].lift_device_delay * 10.0);
qw_t3_sdev_x10 := REAL_TO_INT(g_transporter[3].sink_device_delay * 10.0);
qw_t3_drop_x10 := REAL_TO_INT(g_transporter[3].dropping_time * 10.0);
(* === TWA dynamic drive limits — PLC writes, gateway reads === *)
qw_t1_xmin := REAL_TO_INT(g_transporter[1].x_min_limit);
qw_t1_xmax := REAL_TO_INT(g_transporter[1].x_max_limit);
qw_t2_xmin := REAL_TO_INT(g_transporter[2].x_min_limit);
qw_t2_xmax := REAL_TO_INT(g_transporter[2].x_max_limit);
qw_t3_xmin := REAL_TO_INT(g_transporter[3].x_min_limit);
qw_t3_xmax := REAL_TO_INT(g_transporter[3].x_max_limit);
(* === PLC status + acks — PLC writes, gateway reads === *)
qw_plc_status_station_cnt := g_station_count;
IF init_done THEN qw_plc_status_init_done := 1; ELSE qw_plc_status_init_done := 0; END_IF;
qw_plc_status_cycle_cnt := cycle_count;
qw_plc_status_cfg_ack := last_cfg_seq;
qw_plc_status_unit_ack := last_unit_seq;
qw_plc_status_batch_ack := last_batch_seq;
qw_plc_status_prog_ack := last_prog_seq;
qw_plc_status_avoid_ack := last_avoid_seq;
IF g_cal_active THEN qw_plc_status_cal_active := 1; ELSE qw_plc_status_cal_active := 0; END_IF;
qw_plc_status_prod_queue := g_production_queue;
qw_plc_status_time_hi := LINT_TO_INT(g_time_s / 65536);
qw_plc_status_time_lo := LINT_TO_INT(g_time_s MOD 65536);
(* === Per-unit live state — PLC writes, gateway reads === *)
qw_u1_loc := g_unit[1].location;
qw_u1_status := g_unit[1].status;
qw_u1_target := g_unit[1].target;
qw_u2_loc := g_unit[2].location;
qw_u2_status := g_unit[2].status;
qw_u2_target := g_unit[2].target;
qw_u3_loc := g_unit[3].location;
qw_u3_status := g_unit[3].status;
qw_u3_target := g_unit[3].target;
qw_u4_loc := g_unit[4].location;
qw_u4_status := g_unit[4].status;
qw_u4_target := g_unit[4].target;
qw_u5_loc := g_unit[5].location;
qw_u5_status := g_unit[5].status;
qw_u5_target := g_unit[5].target;
qw_u6_loc := g_unit[6].location;
qw_u6_status := g_unit[6].status;
qw_u6_target := g_unit[6].target;
qw_u7_loc := g_unit[7].location;
qw_u7_status := g_unit[7].status;
qw_u7_target := g_unit[7].target;
qw_u8_loc := g_unit[8].location;
qw_u8_status := g_unit[8].status;
qw_u8_target := g_unit[8].target;
qw_u9_loc := g_unit[9].location;
qw_u9_status := g_unit[9].status;
qw_u9_target := g_unit[9].target;
qw_u10_loc := g_unit[10].location;
qw_u10_status := g_unit[10].status;
qw_u10_target := g_unit[10].target;
(* === Per-unit batch data — PLC writes, gateway reads === *)
qw_b1_code := g_batch[1].batch_code;
qw_b1_state := g_batch[1].state;
qw_b1_prog := g_batch[1].prog_id;
qw_b1_stage := g_batch[1].cur_stage;
qw_b1_min_time := g_batch[1].min_time;
qw_b1_max_time := g_batch[1].max_time;
qw_b1_cal_time := g_batch[1].cal_time;
qw_b1_start_hi := LINT_TO_INT(g_batch[1].start_time / LINT#65536);
qw_b1_start_lo := LINT_TO_INT(g_batch[1].start_time MOD LINT#65536);
qw_b2_code := g_batch[2].batch_code;
qw_b2_state := g_batch[2].state;
qw_b2_prog := g_batch[2].prog_id;
qw_b2_stage := g_batch[2].cur_stage;
qw_b2_min_time := g_batch[2].min_time;
qw_b2_max_time := g_batch[2].max_time;
qw_b2_cal_time := g_batch[2].cal_time;
qw_b2_start_hi := LINT_TO_INT(g_batch[2].start_time / LINT#65536);
qw_b2_start_lo := LINT_TO_INT(g_batch[2].start_time MOD LINT#65536);
qw_b3_code := g_batch[3].batch_code;
qw_b3_state := g_batch[3].state;
qw_b3_prog := g_batch[3].prog_id;
qw_b3_stage := g_batch[3].cur_stage;
qw_b3_min_time := g_batch[3].min_time;
qw_b3_max_time := g_batch[3].max_time;
qw_b3_cal_time := g_batch[3].cal_time;
qw_b3_start_hi := LINT_TO_INT(g_batch[3].start_time / LINT#65536);
qw_b3_start_lo := LINT_TO_INT(g_batch[3].start_time MOD LINT#65536);
qw_b4_code := g_batch[4].batch_code;
qw_b4_state := g_batch[4].state;
qw_b4_prog := g_batch[4].prog_id;
qw_b4_stage := g_batch[4].cur_stage;
qw_b4_min_time := g_batch[4].min_time;
qw_b4_max_time := g_batch[4].max_time;
qw_b4_cal_time := g_batch[4].cal_time;
qw_b4_start_hi := LINT_TO_INT(g_batch[4].start_time / LINT#65536);
qw_b4_start_lo := LINT_TO_INT(g_batch[4].start_time MOD LINT#65536);
qw_b5_code := g_batch[5].batch_code;
qw_b5_state := g_batch[5].state;
qw_b5_prog := g_batch[5].prog_id;
qw_b5_stage := g_batch[5].cur_stage;
qw_b5_min_time := g_batch[5].min_time;
qw_b5_max_time := g_batch[5].max_time;
qw_b5_cal_time := g_batch[5].cal_time;
qw_b5_start_hi := LINT_TO_INT(g_batch[5].start_time / LINT#65536);
qw_b5_start_lo := LINT_TO_INT(g_batch[5].start_time MOD LINT#65536);
qw_b6_code := g_batch[6].batch_code;
qw_b6_state := g_batch[6].state;
qw_b6_prog := g_batch[6].prog_id;
qw_b6_stage := g_batch[6].cur_stage;
qw_b6_min_time := g_batch[6].min_time;
qw_b6_max_time := g_batch[6].max_time;
qw_b6_cal_time := g_batch[6].cal_time;
qw_b6_start_hi := LINT_TO_INT(g_batch[6].start_time / LINT#65536);
qw_b6_start_lo := LINT_TO_INT(g_batch[6].start_time MOD LINT#65536);
qw_b7_code := g_batch[7].batch_code;
qw_b7_state := g_batch[7].state;
qw_b7_prog := g_batch[7].prog_id;
qw_b7_stage := g_batch[7].cur_stage;
qw_b7_min_time := g_batch[7].min_time;
qw_b7_max_time := g_batch[7].max_time;
qw_b7_cal_time := g_batch[7].cal_time;
qw_b7_start_hi := LINT_TO_INT(g_batch[7].start_time / LINT#65536);
qw_b7_start_lo := LINT_TO_INT(g_batch[7].start_time MOD LINT#65536);
qw_b8_code := g_batch[8].batch_code;
qw_b8_state := g_batch[8].state;
qw_b8_prog := g_batch[8].prog_id;
qw_b8_stage := g_batch[8].cur_stage;
qw_b8_min_time := g_batch[8].min_time;
qw_b8_max_time := g_batch[8].max_time;
qw_b8_cal_time := g_batch[8].cal_time;
qw_b8_start_hi := LINT_TO_INT(g_batch[8].start_time / LINT#65536);
qw_b8_start_lo := LINT_TO_INT(g_batch[8].start_time MOD LINT#65536);
qw_b9_code := g_batch[9].batch_code;
qw_b9_state := g_batch[9].state;
qw_b9_prog := g_batch[9].prog_id;
qw_b9_stage := g_batch[9].cur_stage;
qw_b9_min_time := g_batch[9].min_time;
qw_b9_max_time := g_batch[9].max_time;
qw_b9_cal_time := g_batch[9].cal_time;
qw_b9_start_hi := LINT_TO_INT(g_batch[9].start_time / LINT#65536);
qw_b9_start_lo := LINT_TO_INT(g_batch[9].start_time MOD LINT#65536);
qw_b10_code := g_batch[10].batch_code;
qw_b10_state := g_batch[10].state;
qw_b10_prog := g_batch[10].prog_id;
qw_b10_stage := g_batch[10].cur_stage;
qw_b10_min_time := g_batch[10].min_time;
qw_b10_max_time := g_batch[10].max_time;
qw_b10_cal_time := g_batch[10].cal_time;
qw_b10_start_hi := LINT_TO_INT(g_batch[10].start_time / LINT#65536);
qw_b10_start_lo := LINT_TO_INT(g_batch[10].start_time MOD LINT#65536);
(* === Calibration status — PLC writes, gateway reads === *)
qw_calibration_step := calibrate.o_step;
qw_calibration_tid := calibrate.o_tid;
(* === Per-transporter calibration results — PLC writes, gateway reads === *)
qw_cal_t1_lift_wet := REAL_TO_INT(g_cal[1].lift_wet_s * 10.0);
qw_cal_t1_sink_wet := REAL_TO_INT(g_cal[1].sink_wet_s * 10.0);
qw_cal_t1_lift_dry := REAL_TO_INT(g_cal[1].lift_dry_s * 10.0);
qw_cal_t1_sink_dry := REAL_TO_INT(g_cal[1].sink_dry_s * 10.0);
qw_cal_t1_x_acc := REAL_TO_INT(g_cal[1].x_accel_s * 10.0);
qw_cal_t1_x_dec := REAL_TO_INT(g_cal[1].x_decel_s * 10.0);
qw_cal_t1_x_max := REAL_TO_INT(g_cal[1].x_max_mm_s);
qw_cal_t2_lift_wet := REAL_TO_INT(g_cal[2].lift_wet_s * 10.0);
qw_cal_t2_sink_wet := REAL_TO_INT(g_cal[2].sink_wet_s * 10.0);
qw_cal_t2_lift_dry := REAL_TO_INT(g_cal[2].lift_dry_s * 10.0);
qw_cal_t2_sink_dry := REAL_TO_INT(g_cal[2].sink_dry_s * 10.0);
qw_cal_t2_x_acc := REAL_TO_INT(g_cal[2].x_accel_s * 10.0);
qw_cal_t2_x_dec := REAL_TO_INT(g_cal[2].x_decel_s * 10.0);
qw_cal_t2_x_max := REAL_TO_INT(g_cal[2].x_max_mm_s);
qw_cal_t3_lift_wet := REAL_TO_INT(g_cal[3].lift_wet_s * 10.0);
qw_cal_t3_sink_wet := REAL_TO_INT(g_cal[3].sink_wet_s * 10.0);
qw_cal_t3_lift_dry := REAL_TO_INT(g_cal[3].lift_dry_s * 10.0);
qw_cal_t3_sink_dry := REAL_TO_INT(g_cal[3].sink_dry_s * 10.0);
qw_cal_t3_x_acc := REAL_TO_INT(g_cal[3].x_accel_s * 10.0);
qw_cal_t3_x_dec := REAL_TO_INT(g_cal[3].x_decel_s * 10.0);
qw_cal_t3_x_max := REAL_TO_INT(g_cal[3].x_max_mm_s);
(* === Per-transporter config (g_cfg) — limits, physics, task areas === *)
qw_cfg_t1_x_min := REAL_TO_INT(g_cfg[1].x_min_limit);
qw_cfg_t1_x_max := REAL_TO_INT(g_cfg[1].x_max_limit);
qw_cfg_t1_y_min := REAL_TO_INT(g_cfg[1].y_min_limit);
qw_cfg_t1_y_max := REAL_TO_INT(g_cfg[1].y_max_limit);
qw_cfg_t1_x_avoid := REAL_TO_INT(g_cfg[1].x_avoid_mm);
qw_cfg_t1_y_avoid := REAL_TO_INT(g_cfg[1].y_avoid_mm);
qw_cfg_t1_ph_xacc_x100 := REAL_TO_INT(g_cfg[1].phys2d.x_accel_s * 100.0);
qw_cfg_t1_ph_xdec_x100 := REAL_TO_INT(g_cfg[1].phys2d.x_decel_s * 100.0);
qw_cfg_t1_ph_xmax := REAL_TO_INT(g_cfg[1].phys2d.x_max_mm_s);
qw_cfg_t1_ph_ztot := REAL_TO_INT(g_cfg[1].phys2d.z_total_mm);
qw_cfg_t1_ph_zsdry := REAL_TO_INT(g_cfg[1].phys2d.z_slow_dry_mm);
qw_cfg_t1_ph_zswet := REAL_TO_INT(g_cfg[1].phys2d.z_slow_wet_mm);
qw_cfg_t1_ph_zsend := REAL_TO_INT(g_cfg[1].phys2d.z_slow_end_mm);
qw_cfg_t1_ph_zslow := REAL_TO_INT(g_cfg[1].phys2d.z_slow_mm_s);
qw_cfg_t1_ph_zfast := REAL_TO_INT(g_cfg[1].phys2d.z_fast_mm_s);
qw_cfg_t1_ph_drip_x10 := REAL_TO_INT(g_cfg[1].phys2d.drip_delay_s * 10.0);
qw_cfg_t1_ph_avoid := REAL_TO_INT(g_cfg[1].phys2d.avoid_mm);
qw_cfg_t1_ta1_min_lift := g_cfg[1].task_area[1].min_lift;
qw_cfg_t1_ta1_max_lift := g_cfg[1].task_area[1].max_lift;
qw_cfg_t1_ta1_min_sink := g_cfg[1].task_area[1].min_sink;
qw_cfg_t1_ta1_max_sink := g_cfg[1].task_area[1].max_sink;
qw_cfg_t1_ta2_min_lift := g_cfg[1].task_area[2].min_lift;
qw_cfg_t1_ta2_max_lift := g_cfg[1].task_area[2].max_lift;
qw_cfg_t1_ta2_min_sink := g_cfg[1].task_area[2].min_sink;
qw_cfg_t1_ta2_max_sink := g_cfg[1].task_area[2].max_sink;
qw_cfg_t1_ta3_min_lift := g_cfg[1].task_area[3].min_lift;
qw_cfg_t1_ta3_max_lift := g_cfg[1].task_area[3].max_lift;
qw_cfg_t1_ta3_min_sink := g_cfg[1].task_area[3].min_sink;
qw_cfg_t1_ta3_max_sink := g_cfg[1].task_area[3].max_sink;
qw_cfg_t2_x_min := REAL_TO_INT(g_cfg[2].x_min_limit);
qw_cfg_t2_x_max := REAL_TO_INT(g_cfg[2].x_max_limit);
qw_cfg_t2_y_min := REAL_TO_INT(g_cfg[2].y_min_limit);
qw_cfg_t2_y_max := REAL_TO_INT(g_cfg[2].y_max_limit);
qw_cfg_t2_x_avoid := REAL_TO_INT(g_cfg[2].x_avoid_mm);
qw_cfg_t2_y_avoid := REAL_TO_INT(g_cfg[2].y_avoid_mm);
qw_cfg_t2_ph_xacc_x100 := REAL_TO_INT(g_cfg[2].phys2d.x_accel_s * 100.0);
qw_cfg_t2_ph_xdec_x100 := REAL_TO_INT(g_cfg[2].phys2d.x_decel_s * 100.0);
qw_cfg_t2_ph_xmax := REAL_TO_INT(g_cfg[2].phys2d.x_max_mm_s);
qw_cfg_t2_ph_ztot := REAL_TO_INT(g_cfg[2].phys2d.z_total_mm);
qw_cfg_t2_ph_zsdry := REAL_TO_INT(g_cfg[2].phys2d.z_slow_dry_mm);
qw_cfg_t2_ph_zswet := REAL_TO_INT(g_cfg[2].phys2d.z_slow_wet_mm);
qw_cfg_t2_ph_zsend := REAL_TO_INT(g_cfg[2].phys2d.z_slow_end_mm);
qw_cfg_t2_ph_zslow := REAL_TO_INT(g_cfg[2].phys2d.z_slow_mm_s);
qw_cfg_t2_ph_zfast := REAL_TO_INT(g_cfg[2].phys2d.z_fast_mm_s);
qw_cfg_t2_ph_drip_x10 := REAL_TO_INT(g_cfg[2].phys2d.drip_delay_s * 10.0);
qw_cfg_t2_ph_avoid := REAL_TO_INT(g_cfg[2].phys2d.avoid_mm);
qw_cfg_t2_ta1_min_lift := g_cfg[2].task_area[1].min_lift;
qw_cfg_t2_ta1_max_lift := g_cfg[2].task_area[1].max_lift;
qw_cfg_t2_ta1_min_sink := g_cfg[2].task_area[1].min_sink;
qw_cfg_t2_ta1_max_sink := g_cfg[2].task_area[1].max_sink;
qw_cfg_t2_ta2_min_lift := g_cfg[2].task_area[2].min_lift;
qw_cfg_t2_ta2_max_lift := g_cfg[2].task_area[2].max_lift;
qw_cfg_t2_ta2_min_sink := g_cfg[2].task_area[2].min_sink;
qw_cfg_t2_ta2_max_sink := g_cfg[2].task_area[2].max_sink;
qw_cfg_t2_ta3_min_lift := g_cfg[2].task_area[3].min_lift;
qw_cfg_t2_ta3_max_lift := g_cfg[2].task_area[3].max_lift;
qw_cfg_t2_ta3_min_sink := g_cfg[2].task_area[3].min_sink;
qw_cfg_t2_ta3_max_sink := g_cfg[2].task_area[3].max_sink;
qw_cfg_t3_x_min := REAL_TO_INT(g_cfg[3].x_min_limit);
qw_cfg_t3_x_max := REAL_TO_INT(g_cfg[3].x_max_limit);
qw_cfg_t3_y_min := REAL_TO_INT(g_cfg[3].y_min_limit);
qw_cfg_t3_y_max := REAL_TO_INT(g_cfg[3].y_max_limit);
qw_cfg_t3_x_avoid := REAL_TO_INT(g_cfg[3].x_avoid_mm);
qw_cfg_t3_y_avoid := REAL_TO_INT(g_cfg[3].y_avoid_mm);
qw_cfg_t3_ph_xacc_x100 := REAL_TO_INT(g_cfg[3].phys2d.x_accel_s * 100.0);
qw_cfg_t3_ph_xdec_x100 := REAL_TO_INT(g_cfg[3].phys2d.x_decel_s * 100.0);
qw_cfg_t3_ph_xmax := REAL_TO_INT(g_cfg[3].phys2d.x_max_mm_s);
qw_cfg_t3_ph_ztot := REAL_TO_INT(g_cfg[3].phys2d.z_total_mm);
qw_cfg_t3_ph_zsdry := REAL_TO_INT(g_cfg[3].phys2d.z_slow_dry_mm);
qw_cfg_t3_ph_zswet := REAL_TO_INT(g_cfg[3].phys2d.z_slow_wet_mm);
qw_cfg_t3_ph_zsend := REAL_TO_INT(g_cfg[3].phys2d.z_slow_end_mm);
qw_cfg_t3_ph_zslow := REAL_TO_INT(g_cfg[3].phys2d.z_slow_mm_s);
qw_cfg_t3_ph_zfast := REAL_TO_INT(g_cfg[3].phys2d.z_fast_mm_s);
qw_cfg_t3_ph_drip_x10 := REAL_TO_INT(g_cfg[3].phys2d.drip_delay_s * 10.0);
qw_cfg_t3_ph_avoid := REAL_TO_INT(g_cfg[3].phys2d.avoid_mm);
qw_cfg_t3_ta1_min_lift := g_cfg[3].task_area[1].min_lift;
qw_cfg_t3_ta1_max_lift := g_cfg[3].task_area[1].max_lift;
qw_cfg_t3_ta1_min_sink := g_cfg[3].task_area[1].min_sink;
qw_cfg_t3_ta1_max_sink := g_cfg[3].task_area[1].max_sink;
qw_cfg_t3_ta2_min_lift := g_cfg[3].task_area[2].min_lift;
qw_cfg_t3_ta2_max_lift := g_cfg[3].task_area[2].max_lift;
qw_cfg_t3_ta2_min_sink := g_cfg[3].task_area[2].min_sink;
qw_cfg_t3_ta2_max_sink := g_cfg[3].task_area[2].max_sink;
qw_cfg_t3_ta3_min_lift := g_cfg[3].task_area[3].min_lift;
qw_cfg_t3_ta3_max_lift := g_cfg[3].task_area[3].max_lift;
qw_cfg_t3_ta3_min_sink := g_cfg[3].task_area[3].min_sink;
qw_cfg_t3_ta3_max_sink := g_cfg[3].task_area[3].max_sink;
(* === Per-station avoid flags readback (g_avoid_status) — 30 stations === *)
qw_s101_val := g_avoid_status[101];
qw_s102_val := g_avoid_status[102];
qw_s103_val := g_avoid_status[103];
qw_s104_val := g_avoid_status[104];
qw_s105_val := g_avoid_status[105];
qw_s106_val := g_avoid_status[106];
qw_s107_val := g_avoid_status[107];
qw_s108_val := g_avoid_status[108];
qw_s109_val := g_avoid_status[109];
qw_s110_val := g_avoid_status[110];
qw_s111_val := g_avoid_status[111];
qw_s112_val := g_avoid_status[112];
qw_s113_val := g_avoid_status[113];
qw_s114_val := g_avoid_status[114];
qw_s115_val := g_avoid_status[115];
qw_s116_val := g_avoid_status[116];
qw_s117_val := g_avoid_status[117];
qw_s118_val := g_avoid_status[118];
qw_s119_val := g_avoid_status[119];
qw_s120_val := g_avoid_status[120];
qw_s121_val := g_avoid_status[121];
qw_s122_val := g_avoid_status[122];
qw_s123_val := g_avoid_status[123];
qw_s124_val := g_avoid_status[124];
qw_s125_val := g_avoid_status[125];
qw_s126_val := g_avoid_status[126];
qw_s127_val := g_avoid_status[127];
qw_s128_val := g_avoid_status[128];
qw_s129_val := g_avoid_status[129];
qw_s130_val := g_avoid_status[130];
(* === Per-unit schedule summary (g_schedule) — stage count only === *)
qw_sched_u1_stage_cnt := g_schedule[1].stage_count;
qw_sched_u2_stage_cnt := g_schedule[2].stage_count;
qw_sched_u3_stage_cnt := g_schedule[3].stage_count;
qw_sched_u4_stage_cnt := g_schedule[4].stage_count;
qw_sched_u5_stage_cnt := g_schedule[5].stage_count;
qw_sched_u6_stage_cnt := g_schedule[6].stage_count;
qw_sched_u7_stage_cnt := g_schedule[7].stage_count;
qw_sched_u8_stage_cnt := g_schedule[8].stage_count;
qw_sched_u9_stage_cnt := g_schedule[9].stage_count;
qw_sched_u10_stage_cnt := g_schedule[10].stage_count;
(* === Per-transporter task queue (g_task) — count + 10 task slots === *)
qw_tq1_count := g_task[1].count;
qw_tq1_q1_unit := g_task[1].queue[1].unit;
qw_tq1_q1_stage := g_task[1].queue[1].stage;
qw_tq1_q1_lift := g_task[1].queue[1].lift_station;
qw_tq1_q1_sink := g_task[1].queue[1].sink_station;
qw_tq1_q1_start_hi := LINT_TO_INT(g_task[1].queue[1].start_time / 65536);
qw_tq1_q1_start_lo := LINT_TO_INT(g_task[1].queue[1].start_time MOD 65536);
qw_tq1_q1_fin_hi := LINT_TO_INT(g_task[1].queue[1].finish_time / 65536);
qw_tq1_q1_fin_lo := LINT_TO_INT(g_task[1].queue[1].finish_time MOD 65536);
qw_tq1_q1_calc_x10 := REAL_TO_INT(g_task[1].queue[1].calc_time * 10.0);
qw_tq1_q1_min_x10 := REAL_TO_INT(g_task[1].queue[1].min_time * 10.0);
qw_tq1_q1_max_x10 := REAL_TO_INT(g_task[1].queue[1].max_time * 10.0);
qw_tq1_q2_unit := g_task[1].queue[2].unit;
qw_tq1_q2_stage := g_task[1].queue[2].stage;
qw_tq1_q2_lift := g_task[1].queue[2].lift_station;
qw_tq1_q2_sink := g_task[1].queue[2].sink_station;
qw_tq1_q2_start_hi := LINT_TO_INT(g_task[1].queue[2].start_time / 65536);
qw_tq1_q2_start_lo := LINT_TO_INT(g_task[1].queue[2].start_time MOD 65536);
qw_tq1_q2_fin_hi := LINT_TO_INT(g_task[1].queue[2].finish_time / 65536);
qw_tq1_q2_fin_lo := LINT_TO_INT(g_task[1].queue[2].finish_time MOD 65536);
qw_tq1_q2_calc_x10 := REAL_TO_INT(g_task[1].queue[2].calc_time * 10.0);
qw_tq1_q2_min_x10 := REAL_TO_INT(g_task[1].queue[2].min_time * 10.0);
qw_tq1_q2_max_x10 := REAL_TO_INT(g_task[1].queue[2].max_time * 10.0);
qw_tq1_q3_unit := g_task[1].queue[3].unit;
qw_tq1_q3_stage := g_task[1].queue[3].stage;
qw_tq1_q3_lift := g_task[1].queue[3].lift_station;
qw_tq1_q3_sink := g_task[1].queue[3].sink_station;
qw_tq1_q3_start_hi := LINT_TO_INT(g_task[1].queue[3].start_time / 65536);
qw_tq1_q3_start_lo := LINT_TO_INT(g_task[1].queue[3].start_time MOD 65536);
qw_tq1_q3_fin_hi := LINT_TO_INT(g_task[1].queue[3].finish_time / 65536);
qw_tq1_q3_fin_lo := LINT_TO_INT(g_task[1].queue[3].finish_time MOD 65536);
qw_tq1_q3_calc_x10 := REAL_TO_INT(g_task[1].queue[3].calc_time * 10.0);
qw_tq1_q3_min_x10 := REAL_TO_INT(g_task[1].queue[3].min_time * 10.0);
qw_tq1_q3_max_x10 := REAL_TO_INT(g_task[1].queue[3].max_time * 10.0);
qw_tq1_q4_unit := g_task[1].queue[4].unit;
qw_tq1_q4_stage := g_task[1].queue[4].stage;
qw_tq1_q4_lift := g_task[1].queue[4].lift_station;
qw_tq1_q4_sink := g_task[1].queue[4].sink_station;
qw_tq1_q4_start_hi := LINT_TO_INT(g_task[1].queue[4].start_time / 65536);
qw_tq1_q4_start_lo := LINT_TO_INT(g_task[1].queue[4].start_time MOD 65536);
qw_tq1_q4_fin_hi := LINT_TO_INT(g_task[1].queue[4].finish_time / 65536);
qw_tq1_q4_fin_lo := LINT_TO_INT(g_task[1].queue[4].finish_time MOD 65536);
qw_tq1_q4_calc_x10 := REAL_TO_INT(g_task[1].queue[4].calc_time * 10.0);
qw_tq1_q4_min_x10 := REAL_TO_INT(g_task[1].queue[4].min_time * 10.0);
qw_tq1_q4_max_x10 := REAL_TO_INT(g_task[1].queue[4].max_time * 10.0);
qw_tq1_q5_unit := g_task[1].queue[5].unit;
qw_tq1_q5_stage := g_task[1].queue[5].stage;
qw_tq1_q5_lift := g_task[1].queue[5].lift_station;
qw_tq1_q5_sink := g_task[1].queue[5].sink_station;
qw_tq1_q5_start_hi := LINT_TO_INT(g_task[1].queue[5].start_time / 65536);
qw_tq1_q5_start_lo := LINT_TO_INT(g_task[1].queue[5].start_time MOD 65536);
qw_tq1_q5_fin_hi := LINT_TO_INT(g_task[1].queue[5].finish_time / 65536);
qw_tq1_q5_fin_lo := LINT_TO_INT(g_task[1].queue[5].finish_time MOD 65536);
qw_tq1_q5_calc_x10 := REAL_TO_INT(g_task[1].queue[5].calc_time * 10.0);
qw_tq1_q5_min_x10 := REAL_TO_INT(g_task[1].queue[5].min_time * 10.0);
qw_tq1_q5_max_x10 := REAL_TO_INT(g_task[1].queue[5].max_time * 10.0);
qw_tq1_q6_unit := g_task[1].queue[6].unit;
qw_tq1_q6_stage := g_task[1].queue[6].stage;
qw_tq1_q6_lift := g_task[1].queue[6].lift_station;
qw_tq1_q6_sink := g_task[1].queue[6].sink_station;
qw_tq1_q6_start_hi := LINT_TO_INT(g_task[1].queue[6].start_time / 65536);
qw_tq1_q6_start_lo := LINT_TO_INT(g_task[1].queue[6].start_time MOD 65536);
qw_tq1_q6_fin_hi := LINT_TO_INT(g_task[1].queue[6].finish_time / 65536);
qw_tq1_q6_fin_lo := LINT_TO_INT(g_task[1].queue[6].finish_time MOD 65536);
qw_tq1_q6_calc_x10 := REAL_TO_INT(g_task[1].queue[6].calc_time * 10.0);
qw_tq1_q6_min_x10 := REAL_TO_INT(g_task[1].queue[6].min_time * 10.0);
qw_tq1_q6_max_x10 := REAL_TO_INT(g_task[1].queue[6].max_time * 10.0);
qw_tq1_q7_unit := g_task[1].queue[7].unit;
qw_tq1_q7_stage := g_task[1].queue[7].stage;
qw_tq1_q7_lift := g_task[1].queue[7].lift_station;
qw_tq1_q7_sink := g_task[1].queue[7].sink_station;
qw_tq1_q7_start_hi := LINT_TO_INT(g_task[1].queue[7].start_time / 65536);
qw_tq1_q7_start_lo := LINT_TO_INT(g_task[1].queue[7].start_time MOD 65536);
qw_tq1_q7_fin_hi := LINT_TO_INT(g_task[1].queue[7].finish_time / 65536);
qw_tq1_q7_fin_lo := LINT_TO_INT(g_task[1].queue[7].finish_time MOD 65536);
qw_tq1_q7_calc_x10 := REAL_TO_INT(g_task[1].queue[7].calc_time * 10.0);
qw_tq1_q7_min_x10 := REAL_TO_INT(g_task[1].queue[7].min_time * 10.0);
qw_tq1_q7_max_x10 := REAL_TO_INT(g_task[1].queue[7].max_time * 10.0);
qw_tq1_q8_unit := g_task[1].queue[8].unit;
qw_tq1_q8_stage := g_task[1].queue[8].stage;
qw_tq1_q8_lift := g_task[1].queue[8].lift_station;
qw_tq1_q8_sink := g_task[1].queue[8].sink_station;
qw_tq1_q8_start_hi := LINT_TO_INT(g_task[1].queue[8].start_time / 65536);
qw_tq1_q8_start_lo := LINT_TO_INT(g_task[1].queue[8].start_time MOD 65536);
qw_tq1_q8_fin_hi := LINT_TO_INT(g_task[1].queue[8].finish_time / 65536);
qw_tq1_q8_fin_lo := LINT_TO_INT(g_task[1].queue[8].finish_time MOD 65536);
qw_tq1_q8_calc_x10 := REAL_TO_INT(g_task[1].queue[8].calc_time * 10.0);
qw_tq1_q8_min_x10 := REAL_TO_INT(g_task[1].queue[8].min_time * 10.0);
qw_tq1_q8_max_x10 := REAL_TO_INT(g_task[1].queue[8].max_time * 10.0);
qw_tq1_q9_unit := g_task[1].queue[9].unit;
qw_tq1_q9_stage := g_task[1].queue[9].stage;
qw_tq1_q9_lift := g_task[1].queue[9].lift_station;
qw_tq1_q9_sink := g_task[1].queue[9].sink_station;
qw_tq1_q9_start_hi := LINT_TO_INT(g_task[1].queue[9].start_time / 65536);
qw_tq1_q9_start_lo := LINT_TO_INT(g_task[1].queue[9].start_time MOD 65536);
qw_tq1_q9_fin_hi := LINT_TO_INT(g_task[1].queue[9].finish_time / 65536);
qw_tq1_q9_fin_lo := LINT_TO_INT(g_task[1].queue[9].finish_time MOD 65536);
qw_tq1_q9_calc_x10 := REAL_TO_INT(g_task[1].queue[9].calc_time * 10.0);
qw_tq1_q9_min_x10 := REAL_TO_INT(g_task[1].queue[9].min_time * 10.0);
qw_tq1_q9_max_x10 := REAL_TO_INT(g_task[1].queue[9].max_time * 10.0);
qw_tq1_q10_unit := g_task[1].queue[10].unit;
qw_tq1_q10_stage := g_task[1].queue[10].stage;
qw_tq1_q10_lift := g_task[1].queue[10].lift_station;
qw_tq1_q10_sink := g_task[1].queue[10].sink_station;
qw_tq1_q10_start_hi := LINT_TO_INT(g_task[1].queue[10].start_time / 65536);
qw_tq1_q10_start_lo := LINT_TO_INT(g_task[1].queue[10].start_time MOD 65536);
qw_tq1_q10_fin_hi := LINT_TO_INT(g_task[1].queue[10].finish_time / 65536);
qw_tq1_q10_fin_lo := LINT_TO_INT(g_task[1].queue[10].finish_time MOD 65536);
qw_tq1_q10_calc_x10 := REAL_TO_INT(g_task[1].queue[10].calc_time * 10.0);
qw_tq1_q10_min_x10 := REAL_TO_INT(g_task[1].queue[10].min_time * 10.0);
qw_tq1_q10_max_x10 := REAL_TO_INT(g_task[1].queue[10].max_time * 10.0);
qw_tq2_count := g_task[2].count;
qw_tq2_q1_unit := g_task[2].queue[1].unit;
qw_tq2_q1_stage := g_task[2].queue[1].stage;
qw_tq2_q1_lift := g_task[2].queue[1].lift_station;
qw_tq2_q1_sink := g_task[2].queue[1].sink_station;
qw_tq2_q1_start_hi := LINT_TO_INT(g_task[2].queue[1].start_time / 65536);
qw_tq2_q1_start_lo := LINT_TO_INT(g_task[2].queue[1].start_time MOD 65536);
qw_tq2_q1_fin_hi := LINT_TO_INT(g_task[2].queue[1].finish_time / 65536);
qw_tq2_q1_fin_lo := LINT_TO_INT(g_task[2].queue[1].finish_time MOD 65536);
qw_tq2_q1_calc_x10 := REAL_TO_INT(g_task[2].queue[1].calc_time * 10.0);
qw_tq2_q1_min_x10 := REAL_TO_INT(g_task[2].queue[1].min_time * 10.0);
qw_tq2_q1_max_x10 := REAL_TO_INT(g_task[2].queue[1].max_time * 10.0);
qw_tq2_q2_unit := g_task[2].queue[2].unit;
qw_tq2_q2_stage := g_task[2].queue[2].stage;
qw_tq2_q2_lift := g_task[2].queue[2].lift_station;
qw_tq2_q2_sink := g_task[2].queue[2].sink_station;
qw_tq2_q2_start_hi := LINT_TO_INT(g_task[2].queue[2].start_time / 65536);
qw_tq2_q2_start_lo := LINT_TO_INT(g_task[2].queue[2].start_time MOD 65536);
qw_tq2_q2_fin_hi := LINT_TO_INT(g_task[2].queue[2].finish_time / 65536);
qw_tq2_q2_fin_lo := LINT_TO_INT(g_task[2].queue[2].finish_time MOD 65536);
qw_tq2_q2_calc_x10 := REAL_TO_INT(g_task[2].queue[2].calc_time * 10.0);
qw_tq2_q2_min_x10 := REAL_TO_INT(g_task[2].queue[2].min_time * 10.0);
qw_tq2_q2_max_x10 := REAL_TO_INT(g_task[2].queue[2].max_time * 10.0);
qw_tq2_q3_unit := g_task[2].queue[3].unit;
qw_tq2_q3_stage := g_task[2].queue[3].stage;
qw_tq2_q3_lift := g_task[2].queue[3].lift_station;
qw_tq2_q3_sink := g_task[2].queue[3].sink_station;
qw_tq2_q3_start_hi := LINT_TO_INT(g_task[2].queue[3].start_time / 65536);
qw_tq2_q3_start_lo := LINT_TO_INT(g_task[2].queue[3].start_time MOD 65536);
qw_tq2_q3_fin_hi := LINT_TO_INT(g_task[2].queue[3].finish_time / 65536);
qw_tq2_q3_fin_lo := LINT_TO_INT(g_task[2].queue[3].finish_time MOD 65536);
qw_tq2_q3_calc_x10 := REAL_TO_INT(g_task[2].queue[3].calc_time * 10.0);
qw_tq2_q3_min_x10 := REAL_TO_INT(g_task[2].queue[3].min_time * 10.0);
qw_tq2_q3_max_x10 := REAL_TO_INT(g_task[2].queue[3].max_time * 10.0);
qw_tq2_q4_unit := g_task[2].queue[4].unit;
qw_tq2_q4_stage := g_task[2].queue[4].stage;
qw_tq2_q4_lift := g_task[2].queue[4].lift_station;
qw_tq2_q4_sink := g_task[2].queue[4].sink_station;
qw_tq2_q4_start_hi := LINT_TO_INT(g_task[2].queue[4].start_time / 65536);
qw_tq2_q4_start_lo := LINT_TO_INT(g_task[2].queue[4].start_time MOD 65536);
qw_tq2_q4_fin_hi := LINT_TO_INT(g_task[2].queue[4].finish_time / 65536);
qw_tq2_q4_fin_lo := LINT_TO_INT(g_task[2].queue[4].finish_time MOD 65536);
qw_tq2_q4_calc_x10 := REAL_TO_INT(g_task[2].queue[4].calc_time * 10.0);
qw_tq2_q4_min_x10 := REAL_TO_INT(g_task[2].queue[4].min_time * 10.0);
qw_tq2_q4_max_x10 := REAL_TO_INT(g_task[2].queue[4].max_time * 10.0);
qw_tq2_q5_unit := g_task[2].queue[5].unit;
qw_tq2_q5_stage := g_task[2].queue[5].stage;
qw_tq2_q5_lift := g_task[2].queue[5].lift_station;
qw_tq2_q5_sink := g_task[2].queue[5].sink_station;
qw_tq2_q5_start_hi := LINT_TO_INT(g_task[2].queue[5].start_time / 65536);
qw_tq2_q5_start_lo := LINT_TO_INT(g_task[2].queue[5].start_time MOD 65536);
qw_tq2_q5_fin_hi := LINT_TO_INT(g_task[2].queue[5].finish_time / 65536);
qw_tq2_q5_fin_lo := LINT_TO_INT(g_task[2].queue[5].finish_time MOD 65536);
qw_tq2_q5_calc_x10 := REAL_TO_INT(g_task[2].queue[5].calc_time * 10.0);
qw_tq2_q5_min_x10 := REAL_TO_INT(g_task[2].queue[5].min_time * 10.0);
qw_tq2_q5_max_x10 := REAL_TO_INT(g_task[2].queue[5].max_time * 10.0);
qw_tq2_q6_unit := g_task[2].queue[6].unit;
qw_tq2_q6_stage := g_task[2].queue[6].stage;
qw_tq2_q6_lift := g_task[2].queue[6].lift_station;
qw_tq2_q6_sink := g_task[2].queue[6].sink_station;
qw_tq2_q6_start_hi := LINT_TO_INT(g_task[2].queue[6].start_time / 65536);
qw_tq2_q6_start_lo := LINT_TO_INT(g_task[2].queue[6].start_time MOD 65536);
qw_tq2_q6_fin_hi := LINT_TO_INT(g_task[2].queue[6].finish_time / 65536);
qw_tq2_q6_fin_lo := LINT_TO_INT(g_task[2].queue[6].finish_time MOD 65536);
qw_tq2_q6_calc_x10 := REAL_TO_INT(g_task[2].queue[6].calc_time * 10.0);
qw_tq2_q6_min_x10 := REAL_TO_INT(g_task[2].queue[6].min_time * 10.0);
qw_tq2_q6_max_x10 := REAL_TO_INT(g_task[2].queue[6].max_time * 10.0);
qw_tq2_q7_unit := g_task[2].queue[7].unit;
qw_tq2_q7_stage := g_task[2].queue[7].stage;
qw_tq2_q7_lift := g_task[2].queue[7].lift_station;
qw_tq2_q7_sink := g_task[2].queue[7].sink_station;
qw_tq2_q7_start_hi := LINT_TO_INT(g_task[2].queue[7].start_time / 65536);
qw_tq2_q7_start_lo := LINT_TO_INT(g_task[2].queue[7].start_time MOD 65536);
qw_tq2_q7_fin_hi := LINT_TO_INT(g_task[2].queue[7].finish_time / 65536);
qw_tq2_q7_fin_lo := LINT_TO_INT(g_task[2].queue[7].finish_time MOD 65536);
qw_tq2_q7_calc_x10 := REAL_TO_INT(g_task[2].queue[7].calc_time * 10.0);
qw_tq2_q7_min_x10 := REAL_TO_INT(g_task[2].queue[7].min_time * 10.0);
qw_tq2_q7_max_x10 := REAL_TO_INT(g_task[2].queue[7].max_time * 10.0);
qw_tq2_q8_unit := g_task[2].queue[8].unit;
qw_tq2_q8_stage := g_task[2].queue[8].stage;
qw_tq2_q8_lift := g_task[2].queue[8].lift_station;
qw_tq2_q8_sink := g_task[2].queue[8].sink_station;
qw_tq2_q8_start_hi := LINT_TO_INT(g_task[2].queue[8].start_time / 65536);
qw_tq2_q8_start_lo := LINT_TO_INT(g_task[2].queue[8].start_time MOD 65536);
qw_tq2_q8_fin_hi := LINT_TO_INT(g_task[2].queue[8].finish_time / 65536);
qw_tq2_q8_fin_lo := LINT_TO_INT(g_task[2].queue[8].finish_time MOD 65536);
qw_tq2_q8_calc_x10 := REAL_TO_INT(g_task[2].queue[8].calc_time * 10.0);
qw_tq2_q8_min_x10 := REAL_TO_INT(g_task[2].queue[8].min_time * 10.0);
qw_tq2_q8_max_x10 := REAL_TO_INT(g_task[2].queue[8].max_time * 10.0);
qw_tq2_q9_unit := g_task[2].queue[9].unit;
qw_tq2_q9_stage := g_task[2].queue[9].stage;
qw_tq2_q9_lift := g_task[2].queue[9].lift_station;
qw_tq2_q9_sink := g_task[2].queue[9].sink_station;
qw_tq2_q9_start_hi := LINT_TO_INT(g_task[2].queue[9].start_time / 65536);
qw_tq2_q9_start_lo := LINT_TO_INT(g_task[2].queue[9].start_time MOD 65536);
qw_tq2_q9_fin_hi := LINT_TO_INT(g_task[2].queue[9].finish_time / 65536);
qw_tq2_q9_fin_lo := LINT_TO_INT(g_task[2].queue[9].finish_time MOD 65536);
qw_tq2_q9_calc_x10 := REAL_TO_INT(g_task[2].queue[9].calc_time * 10.0);
qw_tq2_q9_min_x10 := REAL_TO_INT(g_task[2].queue[9].min_time * 10.0);
qw_tq2_q9_max_x10 := REAL_TO_INT(g_task[2].queue[9].max_time * 10.0);
qw_tq2_q10_unit := g_task[2].queue[10].unit;
qw_tq2_q10_stage := g_task[2].queue[10].stage;
qw_tq2_q10_lift := g_task[2].queue[10].lift_station;
qw_tq2_q10_sink := g_task[2].queue[10].sink_station;
qw_tq2_q10_start_hi := LINT_TO_INT(g_task[2].queue[10].start_time / 65536);
qw_tq2_q10_start_lo := LINT_TO_INT(g_task[2].queue[10].start_time MOD 65536);
qw_tq2_q10_fin_hi := LINT_TO_INT(g_task[2].queue[10].finish_time / 65536);
qw_tq2_q10_fin_lo := LINT_TO_INT(g_task[2].queue[10].finish_time MOD 65536);
qw_tq2_q10_calc_x10 := REAL_TO_INT(g_task[2].queue[10].calc_time * 10.0);
qw_tq2_q10_min_x10 := REAL_TO_INT(g_task[2].queue[10].min_time * 10.0);
qw_tq2_q10_max_x10 := REAL_TO_INT(g_task[2].queue[10].max_time * 10.0);
qw_tq3_count := g_task[3].count;
qw_tq3_q1_unit := g_task[3].queue[1].unit;
qw_tq3_q1_stage := g_task[3].queue[1].stage;
qw_tq3_q1_lift := g_task[3].queue[1].lift_station;
qw_tq3_q1_sink := g_task[3].queue[1].sink_station;
qw_tq3_q1_start_hi := LINT_TO_INT(g_task[3].queue[1].start_time / 65536);
qw_tq3_q1_start_lo := LINT_TO_INT(g_task[3].queue[1].start_time MOD 65536);
qw_tq3_q1_fin_hi := LINT_TO_INT(g_task[3].queue[1].finish_time / 65536);
qw_tq3_q1_fin_lo := LINT_TO_INT(g_task[3].queue[1].finish_time MOD 65536);
qw_tq3_q1_calc_x10 := REAL_TO_INT(g_task[3].queue[1].calc_time * 10.0);
qw_tq3_q1_min_x10 := REAL_TO_INT(g_task[3].queue[1].min_time * 10.0);
qw_tq3_q1_max_x10 := REAL_TO_INT(g_task[3].queue[1].max_time * 10.0);
qw_tq3_q2_unit := g_task[3].queue[2].unit;
qw_tq3_q2_stage := g_task[3].queue[2].stage;
qw_tq3_q2_lift := g_task[3].queue[2].lift_station;
qw_tq3_q2_sink := g_task[3].queue[2].sink_station;
qw_tq3_q2_start_hi := LINT_TO_INT(g_task[3].queue[2].start_time / 65536);
qw_tq3_q2_start_lo := LINT_TO_INT(g_task[3].queue[2].start_time MOD 65536);
qw_tq3_q2_fin_hi := LINT_TO_INT(g_task[3].queue[2].finish_time / 65536);
qw_tq3_q2_fin_lo := LINT_TO_INT(g_task[3].queue[2].finish_time MOD 65536);
qw_tq3_q2_calc_x10 := REAL_TO_INT(g_task[3].queue[2].calc_time * 10.0);
qw_tq3_q2_min_x10 := REAL_TO_INT(g_task[3].queue[2].min_time * 10.0);
qw_tq3_q2_max_x10 := REAL_TO_INT(g_task[3].queue[2].max_time * 10.0);
qw_tq3_q3_unit := g_task[3].queue[3].unit;
qw_tq3_q3_stage := g_task[3].queue[3].stage;
qw_tq3_q3_lift := g_task[3].queue[3].lift_station;
qw_tq3_q3_sink := g_task[3].queue[3].sink_station;
qw_tq3_q3_start_hi := LINT_TO_INT(g_task[3].queue[3].start_time / 65536);
qw_tq3_q3_start_lo := LINT_TO_INT(g_task[3].queue[3].start_time MOD 65536);
qw_tq3_q3_fin_hi := LINT_TO_INT(g_task[3].queue[3].finish_time / 65536);
qw_tq3_q3_fin_lo := LINT_TO_INT(g_task[3].queue[3].finish_time MOD 65536);
qw_tq3_q3_calc_x10 := REAL_TO_INT(g_task[3].queue[3].calc_time * 10.0);
qw_tq3_q3_min_x10 := REAL_TO_INT(g_task[3].queue[3].min_time * 10.0);
qw_tq3_q3_max_x10 := REAL_TO_INT(g_task[3].queue[3].max_time * 10.0);
qw_tq3_q4_unit := g_task[3].queue[4].unit;
qw_tq3_q4_stage := g_task[3].queue[4].stage;
qw_tq3_q4_lift := g_task[3].queue[4].lift_station;
qw_tq3_q4_sink := g_task[3].queue[4].sink_station;
qw_tq3_q4_start_hi := LINT_TO_INT(g_task[3].queue[4].start_time / 65536);
qw_tq3_q4_start_lo := LINT_TO_INT(g_task[3].queue[4].start_time MOD 65536);
qw_tq3_q4_fin_hi := LINT_TO_INT(g_task[3].queue[4].finish_time / 65536);
qw_tq3_q4_fin_lo := LINT_TO_INT(g_task[3].queue[4].finish_time MOD 65536);
qw_tq3_q4_calc_x10 := REAL_TO_INT(g_task[3].queue[4].calc_time * 10.0);
qw_tq3_q4_min_x10 := REAL_TO_INT(g_task[3].queue[4].min_time * 10.0);
qw_tq3_q4_max_x10 := REAL_TO_INT(g_task[3].queue[4].max_time * 10.0);
qw_tq3_q5_unit := g_task[3].queue[5].unit;
qw_tq3_q5_stage := g_task[3].queue[5].stage;
qw_tq3_q5_lift := g_task[3].queue[5].lift_station;
qw_tq3_q5_sink := g_task[3].queue[5].sink_station;
qw_tq3_q5_start_hi := LINT_TO_INT(g_task[3].queue[5].start_time / 65536);
qw_tq3_q5_start_lo := LINT_TO_INT(g_task[3].queue[5].start_time MOD 65536);
qw_tq3_q5_fin_hi := LINT_TO_INT(g_task[3].queue[5].finish_time / 65536);
qw_tq3_q5_fin_lo := LINT_TO_INT(g_task[3].queue[5].finish_time MOD 65536);
qw_tq3_q5_calc_x10 := REAL_TO_INT(g_task[3].queue[5].calc_time * 10.0);
qw_tq3_q5_min_x10 := REAL_TO_INT(g_task[3].queue[5].min_time * 10.0);
qw_tq3_q5_max_x10 := REAL_TO_INT(g_task[3].queue[5].max_time * 10.0);
qw_tq3_q6_unit := g_task[3].queue[6].unit;
qw_tq3_q6_stage := g_task[3].queue[6].stage;
qw_tq3_q6_lift := g_task[3].queue[6].lift_station;
qw_tq3_q6_sink := g_task[3].queue[6].sink_station;
qw_tq3_q6_start_hi := LINT_TO_INT(g_task[3].queue[6].start_time / 65536);
qw_tq3_q6_start_lo := LINT_TO_INT(g_task[3].queue[6].start_time MOD 65536);
qw_tq3_q6_fin_hi := LINT_TO_INT(g_task[3].queue[6].finish_time / 65536);
qw_tq3_q6_fin_lo := LINT_TO_INT(g_task[3].queue[6].finish_time MOD 65536);
qw_tq3_q6_calc_x10 := REAL_TO_INT(g_task[3].queue[6].calc_time * 10.0);
qw_tq3_q6_min_x10 := REAL_TO_INT(g_task[3].queue[6].min_time * 10.0);
qw_tq3_q6_max_x10 := REAL_TO_INT(g_task[3].queue[6].max_time * 10.0);
qw_tq3_q7_unit := g_task[3].queue[7].unit;
qw_tq3_q7_stage := g_task[3].queue[7].stage;
qw_tq3_q7_lift := g_task[3].queue[7].lift_station;
qw_tq3_q7_sink := g_task[3].queue[7].sink_station;
qw_tq3_q7_start_hi := LINT_TO_INT(g_task[3].queue[7].start_time / 65536);
qw_tq3_q7_start_lo := LINT_TO_INT(g_task[3].queue[7].start_time MOD 65536);
qw_tq3_q7_fin_hi := LINT_TO_INT(g_task[3].queue[7].finish_time / 65536);
qw_tq3_q7_fin_lo := LINT_TO_INT(g_task[3].queue[7].finish_time MOD 65536);
qw_tq3_q7_calc_x10 := REAL_TO_INT(g_task[3].queue[7].calc_time * 10.0);
qw_tq3_q7_min_x10 := REAL_TO_INT(g_task[3].queue[7].min_time * 10.0);
qw_tq3_q7_max_x10 := REAL_TO_INT(g_task[3].queue[7].max_time * 10.0);
qw_tq3_q8_unit := g_task[3].queue[8].unit;
qw_tq3_q8_stage := g_task[3].queue[8].stage;
qw_tq3_q8_lift := g_task[3].queue[8].lift_station;
qw_tq3_q8_sink := g_task[3].queue[8].sink_station;
qw_tq3_q8_start_hi := LINT_TO_INT(g_task[3].queue[8].start_time / 65536);
qw_tq3_q8_start_lo := LINT_TO_INT(g_task[3].queue[8].start_time MOD 65536);
qw_tq3_q8_fin_hi := LINT_TO_INT(g_task[3].queue[8].finish_time / 65536);
qw_tq3_q8_fin_lo := LINT_TO_INT(g_task[3].queue[8].finish_time MOD 65536);
qw_tq3_q8_calc_x10 := REAL_TO_INT(g_task[3].queue[8].calc_time * 10.0);
qw_tq3_q8_min_x10 := REAL_TO_INT(g_task[3].queue[8].min_time * 10.0);
qw_tq3_q8_max_x10 := REAL_TO_INT(g_task[3].queue[8].max_time * 10.0);
qw_tq3_q9_unit := g_task[3].queue[9].unit;
qw_tq3_q9_stage := g_task[3].queue[9].stage;
qw_tq3_q9_lift := g_task[3].queue[9].lift_station;
qw_tq3_q9_sink := g_task[3].queue[9].sink_station;
qw_tq3_q9_start_hi := LINT_TO_INT(g_task[3].queue[9].start_time / 65536);
qw_tq3_q9_start_lo := LINT_TO_INT(g_task[3].queue[9].start_time MOD 65536);
qw_tq3_q9_fin_hi := LINT_TO_INT(g_task[3].queue[9].finish_time / 65536);
qw_tq3_q9_fin_lo := LINT_TO_INT(g_task[3].queue[9].finish_time MOD 65536);
qw_tq3_q9_calc_x10 := REAL_TO_INT(g_task[3].queue[9].calc_time * 10.0);
qw_tq3_q9_min_x10 := REAL_TO_INT(g_task[3].queue[9].min_time * 10.0);
qw_tq3_q9_max_x10 := REAL_TO_INT(g_task[3].queue[9].max_time * 10.0);
qw_tq3_q10_unit := g_task[3].queue[10].unit;
qw_tq3_q10_stage := g_task[3].queue[10].stage;
qw_tq3_q10_lift := g_task[3].queue[10].lift_station;
qw_tq3_q10_sink := g_task[3].queue[10].sink_station;
qw_tq3_q10_start_hi := LINT_TO_INT(g_task[3].queue[10].start_time / 65536);
qw_tq3_q10_start_lo := LINT_TO_INT(g_task[3].queue[10].start_time MOD 65536);
qw_tq3_q10_fin_hi := LINT_TO_INT(g_task[3].queue[10].finish_time / 65536);
qw_tq3_q10_fin_lo := LINT_TO_INT(g_task[3].queue[10].finish_time MOD 65536);
qw_tq3_q10_calc_x10 := REAL_TO_INT(g_task[3].queue[10].calc_time * 10.0);
qw_tq3_q10_min_x10 := REAL_TO_INT(g_task[3].queue[10].min_time * 10.0);
qw_tq3_q10_max_x10 := REAL_TO_INT(g_task[3].queue[10].max_time * 10.0);
(* === Departure scheduler state — PLC writes, gateway reads === *)
IF g_dep_activated THEN qw_dep_state_activated := 1; ELSE qw_dep_state_activated := 0; END_IF;
IF g_dep_stable THEN qw_dep_state_stable := 1; ELSE qw_dep_state_stable := 0; END_IF;
qw_dep_state_waiting_cnt := g_dep_waiting_count;
qw_dep_state_overlap_cnt := g_dep_overlap.count;
IF g_dep_pending.valid THEN qw_dep_state_pend_valid := 1; ELSE qw_dep_state_pend_valid := 0; END_IF;
qw_dep_state_pend_unit := g_dep_pending.batch_unit;
qw_dep_state_pend_stage := g_dep_pending.batch_stage;
qw_dep_state_pend_time_hi := LINT_TO_INT(g_dep_pending.time_s / 65536);
qw_dep_state_pend_time_lo := LINT_TO_INT(g_dep_pending.time_s MOD 65536);
(* === Departure waiting batch unit indices === *)
qw_dw1_unit := g_dep_waiting[1];
qw_dw2_unit := g_dep_waiting[2];
qw_dw3_unit := g_dep_waiting[3];
qw_dw4_unit := g_dep_waiting[4];
qw_dw5_unit := g_dep_waiting[5];
(* === Departure overlap flags per station (g_dep_overlap.flags) === *)
IF g_dep_overlap.flags[101] THEN qw_ov_s101_flag := 1; ELSE qw_ov_s101_flag := 0; END_IF;
IF g_dep_overlap.flags[102] THEN qw_ov_s102_flag := 1; ELSE qw_ov_s102_flag := 0; END_IF;
IF g_dep_overlap.flags[103] THEN qw_ov_s103_flag := 1; ELSE qw_ov_s103_flag := 0; END_IF;
IF g_dep_overlap.flags[104] THEN qw_ov_s104_flag := 1; ELSE qw_ov_s104_flag := 0; END_IF;
IF g_dep_overlap.flags[105] THEN qw_ov_s105_flag := 1; ELSE qw_ov_s105_flag := 0; END_IF;
IF g_dep_overlap.flags[106] THEN qw_ov_s106_flag := 1; ELSE qw_ov_s106_flag := 0; END_IF;
IF g_dep_overlap.flags[107] THEN qw_ov_s107_flag := 1; ELSE qw_ov_s107_flag := 0; END_IF;
IF g_dep_overlap.flags[108] THEN qw_ov_s108_flag := 1; ELSE qw_ov_s108_flag := 0; END_IF;
IF g_dep_overlap.flags[109] THEN qw_ov_s109_flag := 1; ELSE qw_ov_s109_flag := 0; END_IF;
IF g_dep_overlap.flags[110] THEN qw_ov_s110_flag := 1; ELSE qw_ov_s110_flag := 0; END_IF;
IF g_dep_overlap.flags[111] THEN qw_ov_s111_flag := 1; ELSE qw_ov_s111_flag := 0; END_IF;
IF g_dep_overlap.flags[112] THEN qw_ov_s112_flag := 1; ELSE qw_ov_s112_flag := 0; END_IF;
IF g_dep_overlap.flags[113] THEN qw_ov_s113_flag := 1; ELSE qw_ov_s113_flag := 0; END_IF;
IF g_dep_overlap.flags[114] THEN qw_ov_s114_flag := 1; ELSE qw_ov_s114_flag := 0; END_IF;
IF g_dep_overlap.flags[115] THEN qw_ov_s115_flag := 1; ELSE qw_ov_s115_flag := 0; END_IF;
IF g_dep_overlap.flags[116] THEN qw_ov_s116_flag := 1; ELSE qw_ov_s116_flag := 0; END_IF;
IF g_dep_overlap.flags[117] THEN qw_ov_s117_flag := 1; ELSE qw_ov_s117_flag := 0; END_IF;
IF g_dep_overlap.flags[118] THEN qw_ov_s118_flag := 1; ELSE qw_ov_s118_flag := 0; END_IF;
IF g_dep_overlap.flags[119] THEN qw_ov_s119_flag := 1; ELSE qw_ov_s119_flag := 0; END_IF;
IF g_dep_overlap.flags[120] THEN qw_ov_s120_flag := 1; ELSE qw_ov_s120_flag := 0; END_IF;
IF g_dep_overlap.flags[121] THEN qw_ov_s121_flag := 1; ELSE qw_ov_s121_flag := 0; END_IF;
IF g_dep_overlap.flags[122] THEN qw_ov_s122_flag := 1; ELSE qw_ov_s122_flag := 0; END_IF;
IF g_dep_overlap.flags[123] THEN qw_ov_s123_flag := 1; ELSE qw_ov_s123_flag := 0; END_IF;
IF g_dep_overlap.flags[124] THEN qw_ov_s124_flag := 1; ELSE qw_ov_s124_flag := 0; END_IF;
IF g_dep_overlap.flags[125] THEN qw_ov_s125_flag := 1; ELSE qw_ov_s125_flag := 0; END_IF;
IF g_dep_overlap.flags[126] THEN qw_ov_s126_flag := 1; ELSE qw_ov_s126_flag := 0; END_IF;
IF g_dep_overlap.flags[127] THEN qw_ov_s127_flag := 1; ELSE qw_ov_s127_flag := 0; END_IF;
IF g_dep_overlap.flags[128] THEN qw_ov_s128_flag := 1; ELSE qw_ov_s128_flag := 0; END_IF;
IF g_dep_overlap.flags[129] THEN qw_ov_s129_flag := 1; ELSE qw_ov_s129_flag := 0; END_IF;
IF g_dep_overlap.flags[130] THEN qw_ov_s130_flag := 1; ELSE qw_ov_s130_flag := 0; END_IF;
(* === Event queue head — PLC writes, gateway reads (17 regs) === *)
(* qw_event_out_count — no source (manual) *)
(* qw_event_out_seq — no source (manual) *)
(* qw_event_out_type — no source (manual) *)
(* qw_event_out_ts_hi — no source (manual) *)
(* qw_event_out_ts_lo — no source (manual) *)
(* qw_event_out_f1 — no source (manual) *)
(* qw_event_out_f2 — no source (manual) *)
(* qw_event_out_f3 — no source (manual) *)
(* qw_event_out_f4 — no source (manual) *)
(* qw_event_out_f5 — no source (manual) *)
(* qw_event_out_f6 — no source (manual) *)
(* qw_event_out_f7 — no source (manual) *)
(* qw_event_out_f8 — no source (manual) *)
(* qw_event_out_f9 — no source (manual) *)
(* qw_event_out_f10 — no source (manual) *)
(* qw_event_out_f11 — no source (manual) *)
(* qw_event_out_f12 — no source (manual) *)

(* --- END GENERATED MODBUS OUTPUT --- *)













END_PROGRAM
