(* ============================================================
   plc_prg.st — Main program: config upload + transport cycle
   ============================================================ *)

PROGRAM PLC_PRG
VAR_EXTERNAL CONSTANT
    MAX_Transporters    : INT;
    MAX_STATIONS_PER_STEP       : INT;
    MIN_StationIndex : INT;
    MAX_StationIndex   : INT;
    MAX_Units           : INT;
    DEP_MAX_WAITING     : INT;
END_VAR

VAR_EXTERNAL
  (* --- Shared data arrays --- *)
  g_station_count    : INT;
  g_station         : ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_StationType;
  g_station_loc     : ARRAY[1..MAX_StationIndex] OF UDT_UnitLocation;
  g_cfg              : ARRAY[1..MAX_Transporters] OF TRANSPORTER_CFG_T;
  g_transporter      : ARRAY[1..MAX_Transporters] OF UDT_TransporterStatusType;
  g_sim_trans        : ARRAY[1..MAX_Transporters] OF SIM_TRANSPORTER_T;
  g_unit            : ARRAY[1..MAX_Units] OF UDT_UnitType;
  g_ntt             : ARRAY[1..MAX_Transporters] OF NTT_TRANSPORTER_T;
  g_batch          : ARRAY[1..MAX_Units] OF UDT_BatchType;
  g_program         : ARRAY[1..MAX_Units] OF UDT_TreatmentProgramType;
  g_avoid_status     : ARRAY[MIN_StationIndex..MAX_StationIndex] OF INT;
  g_move             : ARRAY[1..MAX_Transporters] OF MOVE_TIMES_T;
  g_schedule         : ARRAY[1..MAX_Units] OF TSK_SCHEDULE_T;
  g_task            : ARRAY[1..MAX_Transporters] OF TSK_QUEUE_T;
  (* --- Departure Scheduler state --- *)
  g_dep_activated     : BOOL;
  g_dep_stable        : BOOL;
  g_dep_waiting_count : INT;
  g_dep_overlap       : DEP_OVERLAP_T;
  g_dep_pending       : DEP_PENDING_WRITE_T;
  g_dep_waiting       : ARRAY[1..DEP_MAX_WAITING] OF INT;
  (* --- Calibration --- *)
  g_cal              : ARRAY[1..MAX_Transporters] OF CALIBRATION_T;
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
  qw_schedule_window_unit_id     : INT;
  qw_schedule_window_stage_count : INT;
  qw_schedule_window_seq         : INT;
  qw_schedule_window_s1_stn      : INT;
  qw_schedule_window_s1_entry_hi : INT;
  qw_schedule_window_s1_entry_lo : INT;
  qw_schedule_window_s1_exit_hi  : INT;
  qw_schedule_window_s1_exit_lo  : INT;
  qw_schedule_window_s1_min_x10  : INT;
  qw_schedule_window_s1_max_x10  : INT;
  qw_schedule_window_s2_stn      : INT;
  qw_schedule_window_s2_entry_hi : INT;
  qw_schedule_window_s2_entry_lo : INT;
  qw_schedule_window_s2_exit_hi  : INT;
  qw_schedule_window_s2_exit_lo  : INT;
  qw_schedule_window_s2_min_x10  : INT;
  qw_schedule_window_s2_max_x10  : INT;
  qw_schedule_window_s3_stn      : INT;
  qw_schedule_window_s3_entry_hi : INT;
  qw_schedule_window_s3_entry_lo : INT;
  qw_schedule_window_s3_exit_hi  : INT;
  qw_schedule_window_s3_exit_lo  : INT;
  qw_schedule_window_s3_min_x10  : INT;
  qw_schedule_window_s3_max_x10  : INT;
  qw_schedule_window_s4_stn      : INT;
  qw_schedule_window_s4_entry_hi : INT;
  qw_schedule_window_s4_entry_lo : INT;
  qw_schedule_window_s4_exit_hi  : INT;
  qw_schedule_window_s4_exit_lo  : INT;
  qw_schedule_window_s4_min_x10  : INT;
  qw_schedule_window_s4_max_x10  : INT;
  qw_schedule_window_s5_stn      : INT;
  qw_schedule_window_s5_entry_hi : INT;
  qw_schedule_window_s5_entry_lo : INT;
  qw_schedule_window_s5_exit_hi  : INT;
  qw_schedule_window_s5_exit_lo  : INT;
  qw_schedule_window_s5_min_x10  : INT;
  qw_schedule_window_s5_max_x10  : INT;
  qw_schedule_window_s6_stn      : INT;
  qw_schedule_window_s6_entry_hi : INT;
  qw_schedule_window_s6_entry_lo : INT;
  qw_schedule_window_s6_exit_hi  : INT;
  qw_schedule_window_s6_exit_lo  : INT;
  qw_schedule_window_s6_min_x10  : INT;
  qw_schedule_window_s6_max_x10  : INT;
  qw_schedule_window_s7_stn      : INT;
  qw_schedule_window_s7_entry_hi : INT;
  qw_schedule_window_s7_entry_lo : INT;
  qw_schedule_window_s7_exit_hi  : INT;
  qw_schedule_window_s7_exit_lo  : INT;
  qw_schedule_window_s7_min_x10  : INT;
  qw_schedule_window_s7_max_x10  : INT;
  qw_schedule_window_s8_stn      : INT;
  qw_schedule_window_s8_entry_hi : INT;
  qw_schedule_window_s8_entry_lo : INT;
  qw_schedule_window_s8_exit_hi  : INT;
  qw_schedule_window_s8_exit_lo  : INT;
  qw_schedule_window_s8_min_x10  : INT;
  qw_schedule_window_s8_max_x10  : INT;
  qw_schedule_window_s9_stn      : INT;
  qw_schedule_window_s9_entry_hi : INT;
  qw_schedule_window_s9_entry_lo : INT;
  qw_schedule_window_s9_exit_hi  : INT;
  qw_schedule_window_s9_exit_lo  : INT;
  qw_schedule_window_s9_min_x10  : INT;
  qw_schedule_window_s9_max_x10  : INT;
  qw_schedule_window_s10_stn     : INT;
  qw_schedule_window_s10_entry_hi : INT;
  qw_schedule_window_s10_entry_lo : INT;
  qw_schedule_window_s10_exit_hi : INT;
  qw_schedule_window_s10_exit_lo : INT;
  qw_schedule_window_s10_min_x10 : INT;
  qw_schedule_window_s10_max_x10 : INT;
  qw_schedule_window_s11_stn     : INT;
  qw_schedule_window_s11_entry_hi : INT;
  qw_schedule_window_s11_entry_lo : INT;
  qw_schedule_window_s11_exit_hi : INT;
  qw_schedule_window_s11_exit_lo : INT;
  qw_schedule_window_s11_min_x10 : INT;
  qw_schedule_window_s11_max_x10 : INT;
  qw_schedule_window_s12_stn     : INT;
  qw_schedule_window_s12_entry_hi : INT;
  qw_schedule_window_s12_entry_lo : INT;
  qw_schedule_window_s12_exit_hi : INT;
  qw_schedule_window_s12_exit_lo : INT;
  qw_schedule_window_s12_min_x10 : INT;
  qw_schedule_window_s12_max_x10 : INT;
  qw_schedule_window_s13_stn     : INT;
  qw_schedule_window_s13_entry_hi : INT;
  qw_schedule_window_s13_entry_lo : INT;
  qw_schedule_window_s13_exit_hi : INT;
  qw_schedule_window_s13_exit_lo : INT;
  qw_schedule_window_s13_min_x10 : INT;
  qw_schedule_window_s13_max_x10 : INT;
  qw_schedule_window_s14_stn     : INT;
  qw_schedule_window_s14_entry_hi : INT;
  qw_schedule_window_s14_entry_lo : INT;
  qw_schedule_window_s14_exit_hi : INT;
  qw_schedule_window_s14_exit_lo : INT;
  qw_schedule_window_s14_min_x10 : INT;
  qw_schedule_window_s14_max_x10 : INT;
  qw_schedule_window_s15_stn     : INT;
  qw_schedule_window_s15_entry_hi : INT;
  qw_schedule_window_s15_entry_lo : INT;
  qw_schedule_window_s15_exit_hi : INT;
  qw_schedule_window_s15_exit_lo : INT;
  qw_schedule_window_s15_min_x10 : INT;
  qw_schedule_window_s15_max_x10 : INT;
  qw_schedule_window_s16_stn     : INT;
  qw_schedule_window_s16_entry_hi : INT;
  qw_schedule_window_s16_entry_lo : INT;
  qw_schedule_window_s16_exit_hi : INT;
  qw_schedule_window_s16_exit_lo : INT;
  qw_schedule_window_s16_min_x10 : INT;
  qw_schedule_window_s16_max_x10 : INT;
  qw_schedule_window_s17_stn     : INT;
  qw_schedule_window_s17_entry_hi : INT;
  qw_schedule_window_s17_entry_lo : INT;
  qw_schedule_window_s17_exit_hi : INT;
  qw_schedule_window_s17_exit_lo : INT;
  qw_schedule_window_s17_min_x10 : INT;
  qw_schedule_window_s17_max_x10 : INT;
  qw_schedule_window_s18_stn     : INT;
  qw_schedule_window_s18_entry_hi : INT;
  qw_schedule_window_s18_entry_lo : INT;
  qw_schedule_window_s18_exit_hi : INT;
  qw_schedule_window_s18_exit_lo : INT;
  qw_schedule_window_s18_min_x10 : INT;
  qw_schedule_window_s18_max_x10 : INT;
  qw_schedule_window_s19_stn     : INT;
  qw_schedule_window_s19_entry_hi : INT;
  qw_schedule_window_s19_entry_lo : INT;
  qw_schedule_window_s19_exit_hi : INT;
  qw_schedule_window_s19_exit_lo : INT;
  qw_schedule_window_s19_min_x10 : INT;
  qw_schedule_window_s19_max_x10 : INT;
  qw_schedule_window_s20_stn     : INT;
  qw_schedule_window_s20_entry_hi : INT;
  qw_schedule_window_s20_entry_lo : INT;
  qw_schedule_window_s20_exit_hi : INT;
  qw_schedule_window_s20_exit_lo : INT;
  qw_schedule_window_s20_min_x10 : INT;
  qw_schedule_window_s20_max_x10 : INT;
  qw_schedule_window_s21_stn     : INT;
  qw_schedule_window_s21_entry_hi : INT;
  qw_schedule_window_s21_entry_lo : INT;
  qw_schedule_window_s21_exit_hi : INT;
  qw_schedule_window_s21_exit_lo : INT;
  qw_schedule_window_s21_min_x10 : INT;
  qw_schedule_window_s21_max_x10 : INT;
  qw_schedule_window_s22_stn     : INT;
  qw_schedule_window_s22_entry_hi : INT;
  qw_schedule_window_s22_entry_lo : INT;
  qw_schedule_window_s22_exit_hi : INT;
  qw_schedule_window_s22_exit_lo : INT;
  qw_schedule_window_s22_min_x10 : INT;
  qw_schedule_window_s22_max_x10 : INT;
  qw_schedule_window_s23_stn     : INT;
  qw_schedule_window_s23_entry_hi : INT;
  qw_schedule_window_s23_entry_lo : INT;
  qw_schedule_window_s23_exit_hi : INT;
  qw_schedule_window_s23_exit_lo : INT;
  qw_schedule_window_s23_min_x10 : INT;
  qw_schedule_window_s23_max_x10 : INT;
  qw_schedule_window_s24_stn     : INT;
  qw_schedule_window_s24_entry_hi : INT;
  qw_schedule_window_s24_entry_lo : INT;
  qw_schedule_window_s24_exit_hi : INT;
  qw_schedule_window_s24_exit_lo : INT;
  qw_schedule_window_s24_min_x10 : INT;
  qw_schedule_window_s24_max_x10 : INT;
  qw_schedule_window_s25_stn     : INT;
  qw_schedule_window_s25_entry_hi : INT;
  qw_schedule_window_s25_entry_lo : INT;
  qw_schedule_window_s25_exit_hi : INT;
  qw_schedule_window_s25_exit_lo : INT;
  qw_schedule_window_s25_min_x10 : INT;
  qw_schedule_window_s25_max_x10 : INT;
  qw_schedule_window_s26_stn     : INT;
  qw_schedule_window_s26_entry_hi : INT;
  qw_schedule_window_s26_entry_lo : INT;
  qw_schedule_window_s26_exit_hi : INT;
  qw_schedule_window_s26_exit_lo : INT;
  qw_schedule_window_s26_min_x10 : INT;
  qw_schedule_window_s26_max_x10 : INT;
  qw_schedule_window_s27_stn     : INT;
  qw_schedule_window_s27_entry_hi : INT;
  qw_schedule_window_s27_entry_lo : INT;
  qw_schedule_window_s27_exit_hi : INT;
  qw_schedule_window_s27_exit_lo : INT;
  qw_schedule_window_s27_min_x10 : INT;
  qw_schedule_window_s27_max_x10 : INT;
  qw_schedule_window_s28_stn     : INT;
  qw_schedule_window_s28_entry_hi : INT;
  qw_schedule_window_s28_entry_lo : INT;
  qw_schedule_window_s28_exit_hi : INT;
  qw_schedule_window_s28_exit_lo : INT;
  qw_schedule_window_s28_min_x10 : INT;
  qw_schedule_window_s28_max_x10 : INT;
  qw_schedule_window_s29_stn     : INT;
  qw_schedule_window_s29_entry_hi : INT;
  qw_schedule_window_s29_entry_lo : INT;
  qw_schedule_window_s29_exit_hi : INT;
  qw_schedule_window_s29_exit_lo : INT;
  qw_schedule_window_s29_min_x10 : INT;
  qw_schedule_window_s29_max_x10 : INT;
  qw_schedule_window_s30_stn     : INT;
  qw_schedule_window_s30_entry_hi : INT;
  qw_schedule_window_s30_entry_lo : INT;
  qw_schedule_window_s30_exit_hi : INT;
  qw_schedule_window_s30_exit_lo : INT;
  qw_schedule_window_s30_min_x10 : INT;
  qw_schedule_window_s30_max_x10 : INT;
  iw_schedule_req_unit           : INT;
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
  (* Schedule window export *)
  sch_last_req   : INT := 0;      (* last exported unit_id *)
  sch_copy       : TSK_SCHEDULE_T; (* temp copy of requested schedule *)
  sch_s          : INT;            (* loop counter for stages *)
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
    IF (iw_cfg_param >= MIN_StationIndex) AND (iw_cfg_param <= MAX_StationIndex) THEN
      g_station[iw_cfg_param].TankId       := iw_cfg_d0;
      g_station[iw_cfg_param].XPosition    := INT_TO_DINT(iw_cfg_d1);
      g_station[iw_cfg_param].YPosition    := INT_TO_DINT(iw_cfg_d2);
      g_station[iw_cfg_param].ZPosition    := INT_TO_DINT(iw_cfg_d3);
      g_station[iw_cfg_param].StationType     := iw_cfg_d4;
      g_station[iw_cfg_param].DryWet            := iw_cfg_d7;
      g_station[iw_cfg_param].DrippingTime := iw_cfg_d5;
      g_station[iw_cfg_param].DeviceDelay  := iw_cfg_d6;
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
      g_cfg[j].XMinDriveLimit          := INT_TO_DINT(iw_cfg_d0);
      g_cfg[j].XMaxDriveLimit          := INT_TO_DINT(iw_cfg_d1);
      g_cfg[j].phys2d.x_accel_s     := iw_cfg_d2;
      g_cfg[j].phys2d.x_decel_s     := iw_cfg_d3;
      g_cfg[j].phys2d.x_max_mm_s    := INT_TO_DINT(iw_cfg_d4);
      g_cfg[j].phys2d.z_total_mm    := INT_TO_DINT(iw_cfg_d5);
      g_cfg[j].phys2d.avoid_mm      := INT_TO_DINT(iw_cfg_d6);
      g_cfg[j].XAvoidMm           := INT_TO_DINT(iw_cfg_d6);
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
      g_cfg[j].phys2d.z_slow_dry_mm := INT_TO_DINT(iw_cfg_d0);
      g_cfg[j].phys2d.z_slow_wet_mm := INT_TO_DINT(iw_cfg_d1);
      g_cfg[j].phys2d.z_slow_end_mm := INT_TO_DINT(iw_cfg_d2);
      g_cfg[j].phys2d.z_slow_mm_s   := INT_TO_DINT(iw_cfg_d3);
      g_cfg[j].phys2d.z_fast_mm_s   := INT_TO_DINT(iw_cfg_d4);
      g_cfg[j].phys2d.drip_delay_s  := iw_cfg_d5;
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
    IF (j >= 1) AND (j <= MAX_Transporters) AND (k >= 1) AND (k <= 8) AND (i >= 0) AND (i <= MAX_STATIONS_PER_STEP) THEN
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
    IF (j >= 1) AND (j <= MAX_Transporters) AND (k >= 1) AND (k <= 8) AND (i >= 0) AND (i <= MAX_STATIONS_PER_STEP) THEN
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
      g_cal[j].lift_wet_s := iw_cfg_d0 / 10;
      g_cal[j].sink_wet_s := iw_cfg_d1 / 10;
      g_cal[j].lift_dry_s := iw_cfg_d2 / 10;
      g_cal[j].sink_dry_s := iw_cfg_d3 / 10;
      g_cal[j].x_accel_s  := iw_cfg_d4 / 10;
      g_cal[j].x_decel_s  := iw_cfg_d5 / 10;
      g_cal[j].x_max_mm_s := INT_TO_DINT(iw_cfg_d6);
    END_IF;

  ELSIF iw_cfg_cmd = 12 THEN
    (* --- Compute g_move from loaded g_cal kinematic params --- *)
    (* No params needed — computes for all transporters with valid g_cal *)
    cal_load_run := TRUE;

  ELSIF iw_cfg_cmd = 2 THEN
    (* --- Finish init: all config uploaded, init transporter states --- *)
    g_station_count := iw_cfg_param;

    FOR i := 1 TO MAX_Transporters DO
      (* Active if task_area[1] has non-zero stations *)
      IF g_cfg[i].task_area[1].min_lift > 0 THEN
        g_transporter[i].IsActive := TRUE;
        g_transporter[i].Status := 3;  (* auto_idle *)
      ELSE
        g_transporter[i].IsActive := FALSE;
        g_transporter[i].Status := 0;  (* not_used *)
      END_IF;
      g_transporter[i].Phase := 0;
      g_sim_trans[i].z_stage := 0;
      g_sim_trans[i].XVelocity := 0;
      g_sim_trans[i].z_timer_s := 0.0;
      g_transporter[i].XMinDriveLimit := g_cfg[i].XMinDriveLimit;
      g_transporter[i].XMaxDriveLimit := g_cfg[i].XMaxDriveLimit;

      (* Start position: at own area minimum, z=0 *)
      g_transporter[i].XPosition := g_cfg[i].XMinDriveLimit;
      g_transporter[i].ZPosition := 0;
      g_transporter[i].CurrentStation := 0;
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

(* ── Execute transporter tasks (physics simulation) ── *)
run_tasks(i_run := init_done);

(* ── Calibration FB — issues test tasks, measures parameters ── *)
calibrate(i_run := init_done, i_cmd := cal_cmd);
cal_cmd := 0;   (* consumed after one cycle *)
g_cal_active := calibrate.o_active;

END_IF;  (* init_done *)

(* ── Main Scheduler (TSK + DEP alternating cycles) ──
   MUST run outside init_done block so that when init_done=FALSE
   (during RESET), MainScheduler's i_run=FALSE path executes,
   properly resetting internal state of both TSK and DEP FBs. *)
main_sched(i_run := init_done, i_time_s := g_time_s);

(* ── Event queue — always runs, not gated by init_done ── *)
evt_queue();

(* ============================================================
   UNIT WRITE HANDLER — gateway writes one unit at a time
   ============================================================ *)
IF iw_unit_seq <> last_unit_seq THEN
  last_unit_seq := iw_unit_seq;
  IF (iw_unit_id >= 1) AND (iw_unit_id <= MAX_Units) THEN
    (* Clear unit_id from old station if unit had a valid location *)
    IF (g_unit[iw_unit_id].location >= MIN_StationIndex) AND (g_unit[iw_unit_id].location <= MAX_StationIndex) THEN
      g_station_loc[g_unit[iw_unit_id].location].UnitId := 0;
    END_IF;

    g_unit[iw_unit_id].location := iw_unit_loc;
    g_unit[iw_unit_id].Status   := iw_unit_status;
    g_unit[iw_unit_id].target   := iw_unit_target;

    (* Set unit_id on the new station *)
    IF (iw_unit_loc >= MIN_StationIndex) AND (iw_unit_loc <= MAX_StationIndex) THEN
      g_station_loc[iw_unit_loc].UnitId := iw_unit_id;
    END_IF;
  END_IF;
END_IF;

(* ============================================================
   BATCH WRITE HANDLER — gateway writes batch data + program_id
   Also clears all stages of the treatment program for this unit.
   ============================================================ *)
IF iw_batch_seq <> last_batch_seq THEN
  last_batch_seq := iw_batch_seq;
  IF (iw_batch_unit >= 1) AND (iw_batch_unit <= MAX_Units) THEN
    g_batch[iw_batch_unit].batch_code := iw_batch_code;
    g_batch[iw_batch_unit].state      := iw_batch_state;
    g_batch[iw_batch_unit].prog_id    := iw_batch_prog_id;
    g_batch[iw_batch_unit].cur_stage      := 0;
    g_program[iw_batch_unit].program_id := iw_batch_prog_id;
    (* Clear all steps *)
    g_program[iw_batch_unit].StepCount := 0;
    FOR j := 0 TO 30 DO
      FOR k := 0 TO 4 DO
        g_program[iw_batch_unit].Steps[j].Stations[k] := 0;
      END_FOR;
      g_program[iw_batch_unit].Steps[j].StationCount := 0;
      g_program[iw_batch_unit].Steps[j].MinTime := 0;
      g_program[iw_batch_unit].Steps[j].MaxTime := 0;
      g_program[iw_batch_unit].Steps[j].CalTime := 0;
    END_FOR;
  END_IF;
END_IF;

(* ============================================================
   PROGRAM STAGE WRITE HANDLER — gateway writes one stage at a time
   ============================================================ *)
IF iw_prog_seq <> last_prog_seq THEN
  last_prog_seq := iw_prog_seq;
  IF (iw_prog_unit >= 1) AND (iw_prog_unit <= MAX_Units) AND
     (iw_prog_stage >= 1) AND (iw_prog_stage <= 30) THEN
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].Stations[0] := iw_prog_s1;
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].Stations[1] := iw_prog_s2;
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].Stations[2] := iw_prog_s3;
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].Stations[3] := iw_prog_s4;
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].Stations[4] := iw_prog_s5;
    (* Compute StationCount from non-zero entries *)
    j := 0;
    IF iw_prog_s1 <> 0 THEN j := j + 1; END_IF;
    IF iw_prog_s2 <> 0 THEN j := j + 1; END_IF;
    IF iw_prog_s3 <> 0 THEN j := j + 1; END_IF;
    IF iw_prog_s4 <> 0 THEN j := j + 1; END_IF;
    IF iw_prog_s5 <> 0 THEN j := j + 1; END_IF;
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].StationCount := j;
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].MinTime := INT_TO_DINT(iw_prog_min_time);
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].MaxTime := INT_TO_DINT(iw_prog_max_time);
    g_program[iw_prog_unit].Steps[iw_prog_stage - 1].CalTime := INT_TO_DINT(iw_prog_cal_time);
    (* Update StepCount: gateway writes stages sequentially 1,2,...N *)
    IF iw_prog_stage > g_program[iw_prog_unit].StepCount THEN
      g_program[iw_prog_unit].StepCount := iw_prog_stage;
    END_IF;
  END_IF;
END_IF;

(* ============================================================
   AVOID STATUS WRITE HANDLER — gateway writes one avoid status at a time
   ============================================================ *)
IF iw_avoid_seq <> last_avoid_seq THEN
  last_avoid_seq := iw_avoid_seq;
  IF (iw_avoid_station >= MIN_StationIndex) AND (iw_avoid_station <= MAX_StationIndex) THEN
    g_avoid_status[iw_avoid_station] := iw_avoid_value;
  END_IF;
END_IF;

(* === MODBUS INPUT: Read commands → g_transporter command fields === *)
(* Note: task_id sync will be handled by SIM_FB_RunTasks later.
   For now, keep the old Modbus command interface working via direct write. *)
IF (iw_cmd_t1_start <> 0) AND (g_transporter[1].Status = 3) THEN
  g_transporter[1].TaskId := g_time_s;
  g_transporter[1].LiftStationTarget := iw_cmd_t1_lift;
  g_transporter[1].SinkStationTarget := iw_cmd_t1_sink;
END_IF;
IF (iw_cmd_t2_start <> 0) AND (g_transporter[2].Status = 3) THEN
  g_transporter[2].TaskId := g_time_s;
  g_transporter[2].LiftStationTarget := iw_cmd_t2_lift;
  g_transporter[2].SinkStationTarget := iw_cmd_t2_sink;
END_IF;

(* ── Cycle counter ── *)
cycle_count := cycle_count + 1;
IF cycle_count > 30000 THEN cycle_count := 0; END_IF;

(* --- BEGIN GENERATED MODBUS OUTPUT --- *)
(* Auto-generated from modbus_map.json — 973 output registers *)

(* === Per-transporter live state — PLC writes, gateway reads === *)
qw_t1_x_mm := DINT_TO_INT(g_transporter[1].XPosition);
qw_t1_z_mm := DINT_TO_INT(g_transporter[1].ZPosition);
qw_t1_vel_x10 := DINT_TO_INT(g_sim_trans[1].XVelocity) * 10;
qw_t1_phase := g_transporter[1].Phase;
qw_t1_unit_id := g_station_loc[1].UnitId;
qw_t1_z_stage := g_sim_trans[1].z_stage;
qw_t1_cur_st := g_transporter[1].CurrentStation;
qw_t1_lift_tgt := g_transporter[1].LiftStationTarget;
qw_t1_sink_tgt := g_transporter[1].SinkStationTarget;
IF g_transporter[1].IsActive THEN qw_t1_active := 1; ELSE qw_t1_active := 0; END_IF;
qw_t1_status := g_transporter[1].Status;
qw_t1_rtask_hi := LINT_TO_INT(g_sim_trans[1].RunningTaskId / 65536);
qw_t1_rtask_lo := LINT_TO_INT(g_sim_trans[1].RunningTaskId MOD 65536);
qw_t2_x_mm := DINT_TO_INT(g_transporter[2].XPosition);
qw_t2_z_mm := DINT_TO_INT(g_transporter[2].ZPosition);
qw_t2_vel_x10 := DINT_TO_INT(g_sim_trans[2].XVelocity) * 10;
qw_t2_phase := g_transporter[2].Phase;
qw_t2_unit_id := g_station_loc[2].UnitId;
qw_t2_z_stage := g_sim_trans[2].z_stage;
qw_t2_cur_st := g_transporter[2].CurrentStation;
qw_t2_lift_tgt := g_transporter[2].LiftStationTarget;
qw_t2_sink_tgt := g_transporter[2].SinkStationTarget;
IF g_transporter[2].IsActive THEN qw_t2_active := 1; ELSE qw_t2_active := 0; END_IF;
qw_t2_status := g_transporter[2].Status;
qw_t2_rtask_hi := LINT_TO_INT(g_sim_trans[2].RunningTaskId / 65536);
qw_t2_rtask_lo := LINT_TO_INT(g_sim_trans[2].RunningTaskId MOD 65536);
qw_t3_x_mm := DINT_TO_INT(g_transporter[3].XPosition);
qw_t3_z_mm := DINT_TO_INT(g_transporter[3].ZPosition);
qw_t3_vel_x10 := DINT_TO_INT(g_sim_trans[3].XVelocity) * 10;
qw_t3_phase := g_transporter[3].Phase;
qw_t3_unit_id := g_station_loc[3].UnitId;
qw_t3_z_stage := g_sim_trans[3].z_stage;
qw_t3_cur_st := g_transporter[3].CurrentStation;
qw_t3_lift_tgt := g_transporter[3].LiftStationTarget;
qw_t3_sink_tgt := g_transporter[3].SinkStationTarget;
IF g_transporter[3].IsActive THEN qw_t3_active := 1; ELSE qw_t3_active := 0; END_IF;
qw_t3_status := g_transporter[3].Status;
qw_t3_rtask_hi := LINT_TO_INT(g_sim_trans[3].RunningTaskId / 65536);
qw_t3_rtask_lo := LINT_TO_INT(g_sim_trans[3].RunningTaskId MOD 65536);
(* === Per-transporter extended state — remaining UDT_TransporterStatusType fields === *)
qw_t1_remain_x10 := DINT_TO_INT(g_transporter[1].TaskRemainingTime) * 10;
qw_t1_treat_time := DINT_TO_INT(g_sim_trans[1].treatment_time);
qw_t1_fintgt_x := DINT_TO_INT(g_transporter[1].XFinalTarget);
qw_t1_drvtgt_x := DINT_TO_INT(g_transporter[1].XDriveTarget);
qw_t1_fintgt_y := DINT_TO_INT(g_transporter[1].YFinalTarget);
qw_t1_drvtgt_y := DINT_TO_INT(g_transporter[1].YDriveTarget);
qw_t1_y_mm := DINT_TO_INT(g_transporter[1].YPosition);
qw_t1_ztimer_x10 := REAL_TO_INT(g_sim_trans[1].z_timer_s * 10.0);
qw_t1_ctask_hi := LINT_TO_INT(g_transporter[1].TaskId / 65536);
qw_t1_ctask_lo := LINT_TO_INT(g_transporter[1].TaskId MOD 65536);
qw_t1_ldev_x10 := g_sim_trans[1].lift_device_delay;
qw_t1_sdev_x10 := g_sim_trans[1].sink_device_delay;
qw_t1_drop_x10 := g_transporter[1].DrippingTime;
qw_t2_remain_x10 := DINT_TO_INT(g_transporter[2].TaskRemainingTime) * 10;
qw_t2_treat_time := DINT_TO_INT(g_sim_trans[2].treatment_time);
qw_t2_fintgt_x := DINT_TO_INT(g_transporter[2].XFinalTarget);
qw_t2_drvtgt_x := DINT_TO_INT(g_transporter[2].XDriveTarget);
qw_t2_fintgt_y := DINT_TO_INT(g_transporter[2].YFinalTarget);
qw_t2_drvtgt_y := DINT_TO_INT(g_transporter[2].YDriveTarget);
qw_t2_y_mm := DINT_TO_INT(g_transporter[2].YPosition);
qw_t2_ztimer_x10 := REAL_TO_INT(g_sim_trans[2].z_timer_s * 10.0);
qw_t2_ctask_hi := LINT_TO_INT(g_transporter[2].TaskId / 65536);
qw_t2_ctask_lo := LINT_TO_INT(g_transporter[2].TaskId MOD 65536);
qw_t2_ldev_x10 := g_sim_trans[2].lift_device_delay;
qw_t2_sdev_x10 := g_sim_trans[2].sink_device_delay;
qw_t2_drop_x10 := g_transporter[2].DrippingTime;
qw_t3_remain_x10 := DINT_TO_INT(g_transporter[3].TaskRemainingTime) * 10;
qw_t3_treat_time := DINT_TO_INT(g_sim_trans[3].treatment_time);
qw_t3_fintgt_x := DINT_TO_INT(g_transporter[3].XFinalTarget);
qw_t3_drvtgt_x := DINT_TO_INT(g_transporter[3].XDriveTarget);
qw_t3_fintgt_y := DINT_TO_INT(g_transporter[3].YFinalTarget);
qw_t3_drvtgt_y := DINT_TO_INT(g_transporter[3].YDriveTarget);
qw_t3_y_mm := DINT_TO_INT(g_transporter[3].YPosition);
qw_t3_ztimer_x10 := REAL_TO_INT(g_sim_trans[3].z_timer_s * 10.0);
qw_t3_ctask_hi := LINT_TO_INT(g_transporter[3].TaskId / 65536);
qw_t3_ctask_lo := LINT_TO_INT(g_transporter[3].TaskId MOD 65536);
qw_t3_ldev_x10 := g_sim_trans[3].lift_device_delay;
qw_t3_sdev_x10 := g_sim_trans[3].sink_device_delay;
qw_t3_drop_x10 := g_transporter[3].DrippingTime;
(* === TWA dynamic drive limits — PLC writes, gateway reads === *)
qw_t1_xmin := DINT_TO_INT(g_transporter[1].XMinDriveLimit);
qw_t1_xmax := DINT_TO_INT(g_transporter[1].XMaxDriveLimit);
qw_t2_xmin := DINT_TO_INT(g_transporter[2].XMinDriveLimit);
qw_t2_xmax := DINT_TO_INT(g_transporter[2].XMaxDriveLimit);
qw_t3_xmin := DINT_TO_INT(g_transporter[3].XMinDriveLimit);
qw_t3_xmax := DINT_TO_INT(g_transporter[3].XMaxDriveLimit);
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
qw_u1_status := g_unit[1].Status;
qw_u1_target := g_unit[1].target;
qw_u2_loc := g_unit[2].location;
qw_u2_status := g_unit[2].Status;
qw_u2_target := g_unit[2].target;
qw_u3_loc := g_unit[3].location;
qw_u3_status := g_unit[3].Status;
qw_u3_target := g_unit[3].target;
qw_u4_loc := g_unit[4].location;
qw_u4_status := g_unit[4].Status;
qw_u4_target := g_unit[4].target;
qw_u5_loc := g_unit[5].location;
qw_u5_status := g_unit[5].Status;
qw_u5_target := g_unit[5].target;
qw_u6_loc := g_unit[6].location;
qw_u6_status := g_unit[6].Status;
qw_u6_target := g_unit[6].target;
qw_u7_loc := g_unit[7].location;
qw_u7_status := g_unit[7].Status;
qw_u7_target := g_unit[7].target;
qw_u8_loc := g_unit[8].location;
qw_u8_status := g_unit[8].Status;
qw_u8_target := g_unit[8].target;
qw_u9_loc := g_unit[9].location;
qw_u9_status := g_unit[9].Status;
qw_u9_target := g_unit[9].target;
qw_u10_loc := g_unit[10].location;
qw_u10_status := g_unit[10].Status;
qw_u10_target := g_unit[10].target;
(* === Per-unit batch data — PLC writes, gateway reads === *)
qw_b1_code := g_batch[1].batch_code;
qw_b1_state := g_batch[1].state;
qw_b1_prog := g_batch[1].prog_id;
qw_b1_stage := g_batch[1].cur_stage;
qw_b1_min_time := DINT_TO_INT(g_batch[1].min_time);
qw_b1_max_time := DINT_TO_INT(g_batch[1].max_time);
qw_b1_cal_time := DINT_TO_INT(g_batch[1].cal_time);
qw_b1_start_hi := LINT_TO_INT(g_batch[1].start_time / LINT#65536);
qw_b1_start_lo := LINT_TO_INT(g_batch[1].start_time MOD LINT#65536);
qw_b2_code := g_batch[2].batch_code;
qw_b2_state := g_batch[2].state;
qw_b2_prog := g_batch[2].prog_id;
qw_b2_stage := g_batch[2].cur_stage;
qw_b2_min_time := DINT_TO_INT(g_batch[2].min_time);
qw_b2_max_time := DINT_TO_INT(g_batch[2].max_time);
qw_b2_cal_time := DINT_TO_INT(g_batch[2].cal_time);
qw_b2_start_hi := LINT_TO_INT(g_batch[2].start_time / LINT#65536);
qw_b2_start_lo := LINT_TO_INT(g_batch[2].start_time MOD LINT#65536);
qw_b3_code := g_batch[3].batch_code;
qw_b3_state := g_batch[3].state;
qw_b3_prog := g_batch[3].prog_id;
qw_b3_stage := g_batch[3].cur_stage;
qw_b3_min_time := DINT_TO_INT(g_batch[3].min_time);
qw_b3_max_time := DINT_TO_INT(g_batch[3].max_time);
qw_b3_cal_time := DINT_TO_INT(g_batch[3].cal_time);
qw_b3_start_hi := LINT_TO_INT(g_batch[3].start_time / LINT#65536);
qw_b3_start_lo := LINT_TO_INT(g_batch[3].start_time MOD LINT#65536);
qw_b4_code := g_batch[4].batch_code;
qw_b4_state := g_batch[4].state;
qw_b4_prog := g_batch[4].prog_id;
qw_b4_stage := g_batch[4].cur_stage;
qw_b4_min_time := DINT_TO_INT(g_batch[4].min_time);
qw_b4_max_time := DINT_TO_INT(g_batch[4].max_time);
qw_b4_cal_time := DINT_TO_INT(g_batch[4].cal_time);
qw_b4_start_hi := LINT_TO_INT(g_batch[4].start_time / LINT#65536);
qw_b4_start_lo := LINT_TO_INT(g_batch[4].start_time MOD LINT#65536);
qw_b5_code := g_batch[5].batch_code;
qw_b5_state := g_batch[5].state;
qw_b5_prog := g_batch[5].prog_id;
qw_b5_stage := g_batch[5].cur_stage;
qw_b5_min_time := DINT_TO_INT(g_batch[5].min_time);
qw_b5_max_time := DINT_TO_INT(g_batch[5].max_time);
qw_b5_cal_time := DINT_TO_INT(g_batch[5].cal_time);
qw_b5_start_hi := LINT_TO_INT(g_batch[5].start_time / LINT#65536);
qw_b5_start_lo := LINT_TO_INT(g_batch[5].start_time MOD LINT#65536);
qw_b6_code := g_batch[6].batch_code;
qw_b6_state := g_batch[6].state;
qw_b6_prog := g_batch[6].prog_id;
qw_b6_stage := g_batch[6].cur_stage;
qw_b6_min_time := DINT_TO_INT(g_batch[6].min_time);
qw_b6_max_time := DINT_TO_INT(g_batch[6].max_time);
qw_b6_cal_time := DINT_TO_INT(g_batch[6].cal_time);
qw_b6_start_hi := LINT_TO_INT(g_batch[6].start_time / LINT#65536);
qw_b6_start_lo := LINT_TO_INT(g_batch[6].start_time MOD LINT#65536);
qw_b7_code := g_batch[7].batch_code;
qw_b7_state := g_batch[7].state;
qw_b7_prog := g_batch[7].prog_id;
qw_b7_stage := g_batch[7].cur_stage;
qw_b7_min_time := DINT_TO_INT(g_batch[7].min_time);
qw_b7_max_time := DINT_TO_INT(g_batch[7].max_time);
qw_b7_cal_time := DINT_TO_INT(g_batch[7].cal_time);
qw_b7_start_hi := LINT_TO_INT(g_batch[7].start_time / LINT#65536);
qw_b7_start_lo := LINT_TO_INT(g_batch[7].start_time MOD LINT#65536);
qw_b8_code := g_batch[8].batch_code;
qw_b8_state := g_batch[8].state;
qw_b8_prog := g_batch[8].prog_id;
qw_b8_stage := g_batch[8].cur_stage;
qw_b8_min_time := DINT_TO_INT(g_batch[8].min_time);
qw_b8_max_time := DINT_TO_INT(g_batch[8].max_time);
qw_b8_cal_time := DINT_TO_INT(g_batch[8].cal_time);
qw_b8_start_hi := LINT_TO_INT(g_batch[8].start_time / LINT#65536);
qw_b8_start_lo := LINT_TO_INT(g_batch[8].start_time MOD LINT#65536);
qw_b9_code := g_batch[9].batch_code;
qw_b9_state := g_batch[9].state;
qw_b9_prog := g_batch[9].prog_id;
qw_b9_stage := g_batch[9].cur_stage;
qw_b9_min_time := DINT_TO_INT(g_batch[9].min_time);
qw_b9_max_time := DINT_TO_INT(g_batch[9].max_time);
qw_b9_cal_time := DINT_TO_INT(g_batch[9].cal_time);
qw_b9_start_hi := LINT_TO_INT(g_batch[9].start_time / LINT#65536);
qw_b9_start_lo := LINT_TO_INT(g_batch[9].start_time MOD LINT#65536);
qw_b10_code := g_batch[10].batch_code;
qw_b10_state := g_batch[10].state;
qw_b10_prog := g_batch[10].prog_id;
qw_b10_stage := g_batch[10].cur_stage;
qw_b10_min_time := DINT_TO_INT(g_batch[10].min_time);
qw_b10_max_time := DINT_TO_INT(g_batch[10].max_time);
qw_b10_cal_time := DINT_TO_INT(g_batch[10].cal_time);
qw_b10_start_hi := LINT_TO_INT(g_batch[10].start_time / LINT#65536);
qw_b10_start_lo := LINT_TO_INT(g_batch[10].start_time MOD LINT#65536);
(* === Calibration status — PLC writes, gateway reads === *)
qw_calibration_step := calibrate.o_step;
qw_calibration_tid := calibrate.o_tid;
(* === Per-transporter calibration results — PLC writes, gateway reads === *)
qw_cal_t1_lift_wet := g_cal[1].lift_wet_s;
qw_cal_t1_sink_wet := g_cal[1].sink_wet_s;
qw_cal_t1_lift_dry := g_cal[1].lift_dry_s;
qw_cal_t1_sink_dry := g_cal[1].sink_dry_s;
qw_cal_t1_x_acc := g_cal[1].x_accel_s;
qw_cal_t1_x_dec := g_cal[1].x_decel_s;
qw_cal_t1_x_max := DINT_TO_INT(g_cal[1].x_max_mm_s);
qw_cal_t2_lift_wet := g_cal[2].lift_wet_s;
qw_cal_t2_sink_wet := g_cal[2].sink_wet_s;
qw_cal_t2_lift_dry := g_cal[2].lift_dry_s;
qw_cal_t2_sink_dry := g_cal[2].sink_dry_s;
qw_cal_t2_x_acc := g_cal[2].x_accel_s;
qw_cal_t2_x_dec := g_cal[2].x_decel_s;
qw_cal_t2_x_max := DINT_TO_INT(g_cal[2].x_max_mm_s);
qw_cal_t3_lift_wet := g_cal[3].lift_wet_s;
qw_cal_t3_sink_wet := g_cal[3].sink_wet_s;
qw_cal_t3_lift_dry := g_cal[3].lift_dry_s;
qw_cal_t3_sink_dry := g_cal[3].sink_dry_s;
qw_cal_t3_x_acc := g_cal[3].x_accel_s;
qw_cal_t3_x_dec := g_cal[3].x_decel_s;
qw_cal_t3_x_max := DINT_TO_INT(g_cal[3].x_max_mm_s);
(* === Per-transporter config (g_cfg) — limits, physics, task areas === *)
qw_cfg_t1_x_min := DINT_TO_INT(g_cfg[1].XMinDriveLimit);
qw_cfg_t1_x_max := DINT_TO_INT(g_cfg[1].XMaxDriveLimit);
qw_cfg_t1_y_min := DINT_TO_INT(g_cfg[1].YMinLimit);
qw_cfg_t1_y_max := DINT_TO_INT(g_cfg[1].YMaxLimit);
qw_cfg_t1_x_avoid := DINT_TO_INT(g_cfg[1].XAvoidMm);
qw_cfg_t1_y_avoid := DINT_TO_INT(g_cfg[1].YAvoidMm);
qw_cfg_t1_ph_xacc_x100 := g_cfg[1].phys2d.x_accel_s * 10;
qw_cfg_t1_ph_xdec_x100 := g_cfg[1].phys2d.x_decel_s * 10;
qw_cfg_t1_ph_xmax := DINT_TO_INT(g_cfg[1].phys2d.x_max_mm_s);
qw_cfg_t1_ph_ztot := DINT_TO_INT(g_cfg[1].phys2d.z_total_mm);
qw_cfg_t1_ph_zsdry := DINT_TO_INT(g_cfg[1].phys2d.z_slow_dry_mm);
qw_cfg_t1_ph_zswet := DINT_TO_INT(g_cfg[1].phys2d.z_slow_wet_mm);
qw_cfg_t1_ph_zsend := DINT_TO_INT(g_cfg[1].phys2d.z_slow_end_mm);
qw_cfg_t1_ph_zslow := DINT_TO_INT(g_cfg[1].phys2d.z_slow_mm_s);
qw_cfg_t1_ph_zfast := DINT_TO_INT(g_cfg[1].phys2d.z_fast_mm_s);
qw_cfg_t1_ph_drip_x10 := g_cfg[1].phys2d.drip_delay_s;
qw_cfg_t1_ph_avoid := DINT_TO_INT(g_cfg[1].phys2d.avoid_mm);
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
qw_cfg_t2_x_min := DINT_TO_INT(g_cfg[2].XMinDriveLimit);
qw_cfg_t2_x_max := DINT_TO_INT(g_cfg[2].XMaxDriveLimit);
qw_cfg_t2_y_min := DINT_TO_INT(g_cfg[2].YMinLimit);
qw_cfg_t2_y_max := DINT_TO_INT(g_cfg[2].YMaxLimit);
qw_cfg_t2_x_avoid := DINT_TO_INT(g_cfg[2].XAvoidMm);
qw_cfg_t2_y_avoid := DINT_TO_INT(g_cfg[2].YAvoidMm);
qw_cfg_t2_ph_xacc_x100 := g_cfg[2].phys2d.x_accel_s * 10;
qw_cfg_t2_ph_xdec_x100 := g_cfg[2].phys2d.x_decel_s * 10;
qw_cfg_t2_ph_xmax := DINT_TO_INT(g_cfg[2].phys2d.x_max_mm_s);
qw_cfg_t2_ph_ztot := DINT_TO_INT(g_cfg[2].phys2d.z_total_mm);
qw_cfg_t2_ph_zsdry := DINT_TO_INT(g_cfg[2].phys2d.z_slow_dry_mm);
qw_cfg_t2_ph_zswet := DINT_TO_INT(g_cfg[2].phys2d.z_slow_wet_mm);
qw_cfg_t2_ph_zsend := DINT_TO_INT(g_cfg[2].phys2d.z_slow_end_mm);
qw_cfg_t2_ph_zslow := DINT_TO_INT(g_cfg[2].phys2d.z_slow_mm_s);
qw_cfg_t2_ph_zfast := DINT_TO_INT(g_cfg[2].phys2d.z_fast_mm_s);
qw_cfg_t2_ph_drip_x10 := g_cfg[2].phys2d.drip_delay_s;
qw_cfg_t2_ph_avoid := DINT_TO_INT(g_cfg[2].phys2d.avoid_mm);
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
qw_cfg_t3_x_min := DINT_TO_INT(g_cfg[3].XMinDriveLimit);
qw_cfg_t3_x_max := DINT_TO_INT(g_cfg[3].XMaxDriveLimit);
qw_cfg_t3_y_min := DINT_TO_INT(g_cfg[3].YMinLimit);
qw_cfg_t3_y_max := DINT_TO_INT(g_cfg[3].YMaxLimit);
qw_cfg_t3_x_avoid := DINT_TO_INT(g_cfg[3].XAvoidMm);
qw_cfg_t3_y_avoid := DINT_TO_INT(g_cfg[3].YAvoidMm);
qw_cfg_t3_ph_xacc_x100 := g_cfg[3].phys2d.x_accel_s * 10;
qw_cfg_t3_ph_xdec_x100 := g_cfg[3].phys2d.x_decel_s * 10;
qw_cfg_t3_ph_xmax := DINT_TO_INT(g_cfg[3].phys2d.x_max_mm_s);
qw_cfg_t3_ph_ztot := DINT_TO_INT(g_cfg[3].phys2d.z_total_mm);
qw_cfg_t3_ph_zsdry := DINT_TO_INT(g_cfg[3].phys2d.z_slow_dry_mm);
qw_cfg_t3_ph_zswet := DINT_TO_INT(g_cfg[3].phys2d.z_slow_wet_mm);
qw_cfg_t3_ph_zsend := DINT_TO_INT(g_cfg[3].phys2d.z_slow_end_mm);
qw_cfg_t3_ph_zslow := DINT_TO_INT(g_cfg[3].phys2d.z_slow_mm_s);
qw_cfg_t3_ph_zfast := DINT_TO_INT(g_cfg[3].phys2d.z_fast_mm_s);
qw_cfg_t3_ph_drip_x10 := g_cfg[3].phys2d.drip_delay_s;
qw_cfg_t3_ph_avoid := DINT_TO_INT(g_cfg[3].phys2d.avoid_mm);
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
qw_tq1_q1_lift := g_task[1].queue[1].LiftStationTarget;
qw_tq1_q1_sink := g_task[1].queue[1].SinkStationTarget;
qw_tq1_q1_start_hi := LINT_TO_INT(g_task[1].queue[1].start_time / 65536);
qw_tq1_q1_start_lo := LINT_TO_INT(g_task[1].queue[1].start_time MOD 65536);
qw_tq1_q1_fin_hi := LINT_TO_INT(g_task[1].queue[1].finish_time / 65536);
qw_tq1_q1_fin_lo := LINT_TO_INT(g_task[1].queue[1].finish_time MOD 65536);
qw_tq1_q1_calc_x10 := DINT_TO_INT(g_task[1].queue[1].calc_time) * 10;
qw_tq1_q1_min_x10 := DINT_TO_INT(g_task[1].queue[1].min_time) * 10;
qw_tq1_q1_max_x10 := DINT_TO_INT(g_task[1].queue[1].max_time) * 10;
qw_tq1_q2_unit := g_task[1].queue[2].unit;
qw_tq1_q2_stage := g_task[1].queue[2].stage;
qw_tq1_q2_lift := g_task[1].queue[2].LiftStationTarget;
qw_tq1_q2_sink := g_task[1].queue[2].SinkStationTarget;
qw_tq1_q2_start_hi := LINT_TO_INT(g_task[1].queue[2].start_time / 65536);
qw_tq1_q2_start_lo := LINT_TO_INT(g_task[1].queue[2].start_time MOD 65536);
qw_tq1_q2_fin_hi := LINT_TO_INT(g_task[1].queue[2].finish_time / 65536);
qw_tq1_q2_fin_lo := LINT_TO_INT(g_task[1].queue[2].finish_time MOD 65536);
qw_tq1_q2_calc_x10 := DINT_TO_INT(g_task[1].queue[2].calc_time) * 10;
qw_tq1_q2_min_x10 := DINT_TO_INT(g_task[1].queue[2].min_time) * 10;
qw_tq1_q2_max_x10 := DINT_TO_INT(g_task[1].queue[2].max_time) * 10;
qw_tq1_q3_unit := g_task[1].queue[3].unit;
qw_tq1_q3_stage := g_task[1].queue[3].stage;
qw_tq1_q3_lift := g_task[1].queue[3].LiftStationTarget;
qw_tq1_q3_sink := g_task[1].queue[3].SinkStationTarget;
qw_tq1_q3_start_hi := LINT_TO_INT(g_task[1].queue[3].start_time / 65536);
qw_tq1_q3_start_lo := LINT_TO_INT(g_task[1].queue[3].start_time MOD 65536);
qw_tq1_q3_fin_hi := LINT_TO_INT(g_task[1].queue[3].finish_time / 65536);
qw_tq1_q3_fin_lo := LINT_TO_INT(g_task[1].queue[3].finish_time MOD 65536);
qw_tq1_q3_calc_x10 := DINT_TO_INT(g_task[1].queue[3].calc_time) * 10;
qw_tq1_q3_min_x10 := DINT_TO_INT(g_task[1].queue[3].min_time) * 10;
qw_tq1_q3_max_x10 := DINT_TO_INT(g_task[1].queue[3].max_time) * 10;
qw_tq1_q4_unit := g_task[1].queue[4].unit;
qw_tq1_q4_stage := g_task[1].queue[4].stage;
qw_tq1_q4_lift := g_task[1].queue[4].LiftStationTarget;
qw_tq1_q4_sink := g_task[1].queue[4].SinkStationTarget;
qw_tq1_q4_start_hi := LINT_TO_INT(g_task[1].queue[4].start_time / 65536);
qw_tq1_q4_start_lo := LINT_TO_INT(g_task[1].queue[4].start_time MOD 65536);
qw_tq1_q4_fin_hi := LINT_TO_INT(g_task[1].queue[4].finish_time / 65536);
qw_tq1_q4_fin_lo := LINT_TO_INT(g_task[1].queue[4].finish_time MOD 65536);
qw_tq1_q4_calc_x10 := DINT_TO_INT(g_task[1].queue[4].calc_time) * 10;
qw_tq1_q4_min_x10 := DINT_TO_INT(g_task[1].queue[4].min_time) * 10;
qw_tq1_q4_max_x10 := DINT_TO_INT(g_task[1].queue[4].max_time) * 10;
qw_tq1_q5_unit := g_task[1].queue[5].unit;
qw_tq1_q5_stage := g_task[1].queue[5].stage;
qw_tq1_q5_lift := g_task[1].queue[5].LiftStationTarget;
qw_tq1_q5_sink := g_task[1].queue[5].SinkStationTarget;
qw_tq1_q5_start_hi := LINT_TO_INT(g_task[1].queue[5].start_time / 65536);
qw_tq1_q5_start_lo := LINT_TO_INT(g_task[1].queue[5].start_time MOD 65536);
qw_tq1_q5_fin_hi := LINT_TO_INT(g_task[1].queue[5].finish_time / 65536);
qw_tq1_q5_fin_lo := LINT_TO_INT(g_task[1].queue[5].finish_time MOD 65536);
qw_tq1_q5_calc_x10 := DINT_TO_INT(g_task[1].queue[5].calc_time) * 10;
qw_tq1_q5_min_x10 := DINT_TO_INT(g_task[1].queue[5].min_time) * 10;
qw_tq1_q5_max_x10 := DINT_TO_INT(g_task[1].queue[5].max_time) * 10;
qw_tq1_q6_unit := g_task[1].queue[6].unit;
qw_tq1_q6_stage := g_task[1].queue[6].stage;
qw_tq1_q6_lift := g_task[1].queue[6].LiftStationTarget;
qw_tq1_q6_sink := g_task[1].queue[6].SinkStationTarget;
qw_tq1_q6_start_hi := LINT_TO_INT(g_task[1].queue[6].start_time / 65536);
qw_tq1_q6_start_lo := LINT_TO_INT(g_task[1].queue[6].start_time MOD 65536);
qw_tq1_q6_fin_hi := LINT_TO_INT(g_task[1].queue[6].finish_time / 65536);
qw_tq1_q6_fin_lo := LINT_TO_INT(g_task[1].queue[6].finish_time MOD 65536);
qw_tq1_q6_calc_x10 := DINT_TO_INT(g_task[1].queue[6].calc_time) * 10;
qw_tq1_q6_min_x10 := DINT_TO_INT(g_task[1].queue[6].min_time) * 10;
qw_tq1_q6_max_x10 := DINT_TO_INT(g_task[1].queue[6].max_time) * 10;
qw_tq1_q7_unit := g_task[1].queue[7].unit;
qw_tq1_q7_stage := g_task[1].queue[7].stage;
qw_tq1_q7_lift := g_task[1].queue[7].LiftStationTarget;
qw_tq1_q7_sink := g_task[1].queue[7].SinkStationTarget;
qw_tq1_q7_start_hi := LINT_TO_INT(g_task[1].queue[7].start_time / 65536);
qw_tq1_q7_start_lo := LINT_TO_INT(g_task[1].queue[7].start_time MOD 65536);
qw_tq1_q7_fin_hi := LINT_TO_INT(g_task[1].queue[7].finish_time / 65536);
qw_tq1_q7_fin_lo := LINT_TO_INT(g_task[1].queue[7].finish_time MOD 65536);
qw_tq1_q7_calc_x10 := DINT_TO_INT(g_task[1].queue[7].calc_time) * 10;
qw_tq1_q7_min_x10 := DINT_TO_INT(g_task[1].queue[7].min_time) * 10;
qw_tq1_q7_max_x10 := DINT_TO_INT(g_task[1].queue[7].max_time) * 10;
qw_tq1_q8_unit := g_task[1].queue[8].unit;
qw_tq1_q8_stage := g_task[1].queue[8].stage;
qw_tq1_q8_lift := g_task[1].queue[8].LiftStationTarget;
qw_tq1_q8_sink := g_task[1].queue[8].SinkStationTarget;
qw_tq1_q8_start_hi := LINT_TO_INT(g_task[1].queue[8].start_time / 65536);
qw_tq1_q8_start_lo := LINT_TO_INT(g_task[1].queue[8].start_time MOD 65536);
qw_tq1_q8_fin_hi := LINT_TO_INT(g_task[1].queue[8].finish_time / 65536);
qw_tq1_q8_fin_lo := LINT_TO_INT(g_task[1].queue[8].finish_time MOD 65536);
qw_tq1_q8_calc_x10 := DINT_TO_INT(g_task[1].queue[8].calc_time) * 10;
qw_tq1_q8_min_x10 := DINT_TO_INT(g_task[1].queue[8].min_time) * 10;
qw_tq1_q8_max_x10 := DINT_TO_INT(g_task[1].queue[8].max_time) * 10;
qw_tq1_q9_unit := g_task[1].queue[9].unit;
qw_tq1_q9_stage := g_task[1].queue[9].stage;
qw_tq1_q9_lift := g_task[1].queue[9].LiftStationTarget;
qw_tq1_q9_sink := g_task[1].queue[9].SinkStationTarget;
qw_tq1_q9_start_hi := LINT_TO_INT(g_task[1].queue[9].start_time / 65536);
qw_tq1_q9_start_lo := LINT_TO_INT(g_task[1].queue[9].start_time MOD 65536);
qw_tq1_q9_fin_hi := LINT_TO_INT(g_task[1].queue[9].finish_time / 65536);
qw_tq1_q9_fin_lo := LINT_TO_INT(g_task[1].queue[9].finish_time MOD 65536);
qw_tq1_q9_calc_x10 := DINT_TO_INT(g_task[1].queue[9].calc_time) * 10;
qw_tq1_q9_min_x10 := DINT_TO_INT(g_task[1].queue[9].min_time) * 10;
qw_tq1_q9_max_x10 := DINT_TO_INT(g_task[1].queue[9].max_time) * 10;
qw_tq1_q10_unit := g_task[1].queue[10].unit;
qw_tq1_q10_stage := g_task[1].queue[10].stage;
qw_tq1_q10_lift := g_task[1].queue[10].LiftStationTarget;
qw_tq1_q10_sink := g_task[1].queue[10].SinkStationTarget;
qw_tq1_q10_start_hi := LINT_TO_INT(g_task[1].queue[10].start_time / 65536);
qw_tq1_q10_start_lo := LINT_TO_INT(g_task[1].queue[10].start_time MOD 65536);
qw_tq1_q10_fin_hi := LINT_TO_INT(g_task[1].queue[10].finish_time / 65536);
qw_tq1_q10_fin_lo := LINT_TO_INT(g_task[1].queue[10].finish_time MOD 65536);
qw_tq1_q10_calc_x10 := DINT_TO_INT(g_task[1].queue[10].calc_time) * 10;
qw_tq1_q10_min_x10 := DINT_TO_INT(g_task[1].queue[10].min_time) * 10;
qw_tq1_q10_max_x10 := DINT_TO_INT(g_task[1].queue[10].max_time) * 10;
qw_tq2_count := g_task[2].count;
qw_tq2_q1_unit := g_task[2].queue[1].unit;
qw_tq2_q1_stage := g_task[2].queue[1].stage;
qw_tq2_q1_lift := g_task[2].queue[1].LiftStationTarget;
qw_tq2_q1_sink := g_task[2].queue[1].SinkStationTarget;
qw_tq2_q1_start_hi := LINT_TO_INT(g_task[2].queue[1].start_time / 65536);
qw_tq2_q1_start_lo := LINT_TO_INT(g_task[2].queue[1].start_time MOD 65536);
qw_tq2_q1_fin_hi := LINT_TO_INT(g_task[2].queue[1].finish_time / 65536);
qw_tq2_q1_fin_lo := LINT_TO_INT(g_task[2].queue[1].finish_time MOD 65536);
qw_tq2_q1_calc_x10 := DINT_TO_INT(g_task[2].queue[1].calc_time) * 10;
qw_tq2_q1_min_x10 := DINT_TO_INT(g_task[2].queue[1].min_time) * 10;
qw_tq2_q1_max_x10 := DINT_TO_INT(g_task[2].queue[1].max_time) * 10;
qw_tq2_q2_unit := g_task[2].queue[2].unit;
qw_tq2_q2_stage := g_task[2].queue[2].stage;
qw_tq2_q2_lift := g_task[2].queue[2].LiftStationTarget;
qw_tq2_q2_sink := g_task[2].queue[2].SinkStationTarget;
qw_tq2_q2_start_hi := LINT_TO_INT(g_task[2].queue[2].start_time / 65536);
qw_tq2_q2_start_lo := LINT_TO_INT(g_task[2].queue[2].start_time MOD 65536);
qw_tq2_q2_fin_hi := LINT_TO_INT(g_task[2].queue[2].finish_time / 65536);
qw_tq2_q2_fin_lo := LINT_TO_INT(g_task[2].queue[2].finish_time MOD 65536);
qw_tq2_q2_calc_x10 := DINT_TO_INT(g_task[2].queue[2].calc_time) * 10;
qw_tq2_q2_min_x10 := DINT_TO_INT(g_task[2].queue[2].min_time) * 10;
qw_tq2_q2_max_x10 := DINT_TO_INT(g_task[2].queue[2].max_time) * 10;
qw_tq2_q3_unit := g_task[2].queue[3].unit;
qw_tq2_q3_stage := g_task[2].queue[3].stage;
qw_tq2_q3_lift := g_task[2].queue[3].LiftStationTarget;
qw_tq2_q3_sink := g_task[2].queue[3].SinkStationTarget;
qw_tq2_q3_start_hi := LINT_TO_INT(g_task[2].queue[3].start_time / 65536);
qw_tq2_q3_start_lo := LINT_TO_INT(g_task[2].queue[3].start_time MOD 65536);
qw_tq2_q3_fin_hi := LINT_TO_INT(g_task[2].queue[3].finish_time / 65536);
qw_tq2_q3_fin_lo := LINT_TO_INT(g_task[2].queue[3].finish_time MOD 65536);
qw_tq2_q3_calc_x10 := DINT_TO_INT(g_task[2].queue[3].calc_time) * 10;
qw_tq2_q3_min_x10 := DINT_TO_INT(g_task[2].queue[3].min_time) * 10;
qw_tq2_q3_max_x10 := DINT_TO_INT(g_task[2].queue[3].max_time) * 10;
qw_tq2_q4_unit := g_task[2].queue[4].unit;
qw_tq2_q4_stage := g_task[2].queue[4].stage;
qw_tq2_q4_lift := g_task[2].queue[4].LiftStationTarget;
qw_tq2_q4_sink := g_task[2].queue[4].SinkStationTarget;
qw_tq2_q4_start_hi := LINT_TO_INT(g_task[2].queue[4].start_time / 65536);
qw_tq2_q4_start_lo := LINT_TO_INT(g_task[2].queue[4].start_time MOD 65536);
qw_tq2_q4_fin_hi := LINT_TO_INT(g_task[2].queue[4].finish_time / 65536);
qw_tq2_q4_fin_lo := LINT_TO_INT(g_task[2].queue[4].finish_time MOD 65536);
qw_tq2_q4_calc_x10 := DINT_TO_INT(g_task[2].queue[4].calc_time) * 10;
qw_tq2_q4_min_x10 := DINT_TO_INT(g_task[2].queue[4].min_time) * 10;
qw_tq2_q4_max_x10 := DINT_TO_INT(g_task[2].queue[4].max_time) * 10;
qw_tq2_q5_unit := g_task[2].queue[5].unit;
qw_tq2_q5_stage := g_task[2].queue[5].stage;
qw_tq2_q5_lift := g_task[2].queue[5].LiftStationTarget;
qw_tq2_q5_sink := g_task[2].queue[5].SinkStationTarget;
qw_tq2_q5_start_hi := LINT_TO_INT(g_task[2].queue[5].start_time / 65536);
qw_tq2_q5_start_lo := LINT_TO_INT(g_task[2].queue[5].start_time MOD 65536);
qw_tq2_q5_fin_hi := LINT_TO_INT(g_task[2].queue[5].finish_time / 65536);
qw_tq2_q5_fin_lo := LINT_TO_INT(g_task[2].queue[5].finish_time MOD 65536);
qw_tq2_q5_calc_x10 := DINT_TO_INT(g_task[2].queue[5].calc_time) * 10;
qw_tq2_q5_min_x10 := DINT_TO_INT(g_task[2].queue[5].min_time) * 10;
qw_tq2_q5_max_x10 := DINT_TO_INT(g_task[2].queue[5].max_time) * 10;
qw_tq2_q6_unit := g_task[2].queue[6].unit;
qw_tq2_q6_stage := g_task[2].queue[6].stage;
qw_tq2_q6_lift := g_task[2].queue[6].LiftStationTarget;
qw_tq2_q6_sink := g_task[2].queue[6].SinkStationTarget;
qw_tq2_q6_start_hi := LINT_TO_INT(g_task[2].queue[6].start_time / 65536);
qw_tq2_q6_start_lo := LINT_TO_INT(g_task[2].queue[6].start_time MOD 65536);
qw_tq2_q6_fin_hi := LINT_TO_INT(g_task[2].queue[6].finish_time / 65536);
qw_tq2_q6_fin_lo := LINT_TO_INT(g_task[2].queue[6].finish_time MOD 65536);
qw_tq2_q6_calc_x10 := DINT_TO_INT(g_task[2].queue[6].calc_time) * 10;
qw_tq2_q6_min_x10 := DINT_TO_INT(g_task[2].queue[6].min_time) * 10;
qw_tq2_q6_max_x10 := DINT_TO_INT(g_task[2].queue[6].max_time) * 10;
qw_tq2_q7_unit := g_task[2].queue[7].unit;
qw_tq2_q7_stage := g_task[2].queue[7].stage;
qw_tq2_q7_lift := g_task[2].queue[7].LiftStationTarget;
qw_tq2_q7_sink := g_task[2].queue[7].SinkStationTarget;
qw_tq2_q7_start_hi := LINT_TO_INT(g_task[2].queue[7].start_time / 65536);
qw_tq2_q7_start_lo := LINT_TO_INT(g_task[2].queue[7].start_time MOD 65536);
qw_tq2_q7_fin_hi := LINT_TO_INT(g_task[2].queue[7].finish_time / 65536);
qw_tq2_q7_fin_lo := LINT_TO_INT(g_task[2].queue[7].finish_time MOD 65536);
qw_tq2_q7_calc_x10 := DINT_TO_INT(g_task[2].queue[7].calc_time) * 10;
qw_tq2_q7_min_x10 := DINT_TO_INT(g_task[2].queue[7].min_time) * 10;
qw_tq2_q7_max_x10 := DINT_TO_INT(g_task[2].queue[7].max_time) * 10;
qw_tq2_q8_unit := g_task[2].queue[8].unit;
qw_tq2_q8_stage := g_task[2].queue[8].stage;
qw_tq2_q8_lift := g_task[2].queue[8].LiftStationTarget;
qw_tq2_q8_sink := g_task[2].queue[8].SinkStationTarget;
qw_tq2_q8_start_hi := LINT_TO_INT(g_task[2].queue[8].start_time / 65536);
qw_tq2_q8_start_lo := LINT_TO_INT(g_task[2].queue[8].start_time MOD 65536);
qw_tq2_q8_fin_hi := LINT_TO_INT(g_task[2].queue[8].finish_time / 65536);
qw_tq2_q8_fin_lo := LINT_TO_INT(g_task[2].queue[8].finish_time MOD 65536);
qw_tq2_q8_calc_x10 := DINT_TO_INT(g_task[2].queue[8].calc_time) * 10;
qw_tq2_q8_min_x10 := DINT_TO_INT(g_task[2].queue[8].min_time) * 10;
qw_tq2_q8_max_x10 := DINT_TO_INT(g_task[2].queue[8].max_time) * 10;
qw_tq2_q9_unit := g_task[2].queue[9].unit;
qw_tq2_q9_stage := g_task[2].queue[9].stage;
qw_tq2_q9_lift := g_task[2].queue[9].LiftStationTarget;
qw_tq2_q9_sink := g_task[2].queue[9].SinkStationTarget;
qw_tq2_q9_start_hi := LINT_TO_INT(g_task[2].queue[9].start_time / 65536);
qw_tq2_q9_start_lo := LINT_TO_INT(g_task[2].queue[9].start_time MOD 65536);
qw_tq2_q9_fin_hi := LINT_TO_INT(g_task[2].queue[9].finish_time / 65536);
qw_tq2_q9_fin_lo := LINT_TO_INT(g_task[2].queue[9].finish_time MOD 65536);
qw_tq2_q9_calc_x10 := DINT_TO_INT(g_task[2].queue[9].calc_time) * 10;
qw_tq2_q9_min_x10 := DINT_TO_INT(g_task[2].queue[9].min_time) * 10;
qw_tq2_q9_max_x10 := DINT_TO_INT(g_task[2].queue[9].max_time) * 10;
qw_tq2_q10_unit := g_task[2].queue[10].unit;
qw_tq2_q10_stage := g_task[2].queue[10].stage;
qw_tq2_q10_lift := g_task[2].queue[10].LiftStationTarget;
qw_tq2_q10_sink := g_task[2].queue[10].SinkStationTarget;
qw_tq2_q10_start_hi := LINT_TO_INT(g_task[2].queue[10].start_time / 65536);
qw_tq2_q10_start_lo := LINT_TO_INT(g_task[2].queue[10].start_time MOD 65536);
qw_tq2_q10_fin_hi := LINT_TO_INT(g_task[2].queue[10].finish_time / 65536);
qw_tq2_q10_fin_lo := LINT_TO_INT(g_task[2].queue[10].finish_time MOD 65536);
qw_tq2_q10_calc_x10 := DINT_TO_INT(g_task[2].queue[10].calc_time) * 10;
qw_tq2_q10_min_x10 := DINT_TO_INT(g_task[2].queue[10].min_time) * 10;
qw_tq2_q10_max_x10 := DINT_TO_INT(g_task[2].queue[10].max_time) * 10;
qw_tq3_count := g_task[3].count;
qw_tq3_q1_unit := g_task[3].queue[1].unit;
qw_tq3_q1_stage := g_task[3].queue[1].stage;
qw_tq3_q1_lift := g_task[3].queue[1].LiftStationTarget;
qw_tq3_q1_sink := g_task[3].queue[1].SinkStationTarget;
qw_tq3_q1_start_hi := LINT_TO_INT(g_task[3].queue[1].start_time / 65536);
qw_tq3_q1_start_lo := LINT_TO_INT(g_task[3].queue[1].start_time MOD 65536);
qw_tq3_q1_fin_hi := LINT_TO_INT(g_task[3].queue[1].finish_time / 65536);
qw_tq3_q1_fin_lo := LINT_TO_INT(g_task[3].queue[1].finish_time MOD 65536);
qw_tq3_q1_calc_x10 := DINT_TO_INT(g_task[3].queue[1].calc_time) * 10;
qw_tq3_q1_min_x10 := DINT_TO_INT(g_task[3].queue[1].min_time) * 10;
qw_tq3_q1_max_x10 := DINT_TO_INT(g_task[3].queue[1].max_time) * 10;
qw_tq3_q2_unit := g_task[3].queue[2].unit;
qw_tq3_q2_stage := g_task[3].queue[2].stage;
qw_tq3_q2_lift := g_task[3].queue[2].LiftStationTarget;
qw_tq3_q2_sink := g_task[3].queue[2].SinkStationTarget;
qw_tq3_q2_start_hi := LINT_TO_INT(g_task[3].queue[2].start_time / 65536);
qw_tq3_q2_start_lo := LINT_TO_INT(g_task[3].queue[2].start_time MOD 65536);
qw_tq3_q2_fin_hi := LINT_TO_INT(g_task[3].queue[2].finish_time / 65536);
qw_tq3_q2_fin_lo := LINT_TO_INT(g_task[3].queue[2].finish_time MOD 65536);
qw_tq3_q2_calc_x10 := DINT_TO_INT(g_task[3].queue[2].calc_time) * 10;
qw_tq3_q2_min_x10 := DINT_TO_INT(g_task[3].queue[2].min_time) * 10;
qw_tq3_q2_max_x10 := DINT_TO_INT(g_task[3].queue[2].max_time) * 10;
qw_tq3_q3_unit := g_task[3].queue[3].unit;
qw_tq3_q3_stage := g_task[3].queue[3].stage;
qw_tq3_q3_lift := g_task[3].queue[3].LiftStationTarget;
qw_tq3_q3_sink := g_task[3].queue[3].SinkStationTarget;
qw_tq3_q3_start_hi := LINT_TO_INT(g_task[3].queue[3].start_time / 65536);
qw_tq3_q3_start_lo := LINT_TO_INT(g_task[3].queue[3].start_time MOD 65536);
qw_tq3_q3_fin_hi := LINT_TO_INT(g_task[3].queue[3].finish_time / 65536);
qw_tq3_q3_fin_lo := LINT_TO_INT(g_task[3].queue[3].finish_time MOD 65536);
qw_tq3_q3_calc_x10 := DINT_TO_INT(g_task[3].queue[3].calc_time) * 10;
qw_tq3_q3_min_x10 := DINT_TO_INT(g_task[3].queue[3].min_time) * 10;
qw_tq3_q3_max_x10 := DINT_TO_INT(g_task[3].queue[3].max_time) * 10;
qw_tq3_q4_unit := g_task[3].queue[4].unit;
qw_tq3_q4_stage := g_task[3].queue[4].stage;
qw_tq3_q4_lift := g_task[3].queue[4].LiftStationTarget;
qw_tq3_q4_sink := g_task[3].queue[4].SinkStationTarget;
qw_tq3_q4_start_hi := LINT_TO_INT(g_task[3].queue[4].start_time / 65536);
qw_tq3_q4_start_lo := LINT_TO_INT(g_task[3].queue[4].start_time MOD 65536);
qw_tq3_q4_fin_hi := LINT_TO_INT(g_task[3].queue[4].finish_time / 65536);
qw_tq3_q4_fin_lo := LINT_TO_INT(g_task[3].queue[4].finish_time MOD 65536);
qw_tq3_q4_calc_x10 := DINT_TO_INT(g_task[3].queue[4].calc_time) * 10;
qw_tq3_q4_min_x10 := DINT_TO_INT(g_task[3].queue[4].min_time) * 10;
qw_tq3_q4_max_x10 := DINT_TO_INT(g_task[3].queue[4].max_time) * 10;
qw_tq3_q5_unit := g_task[3].queue[5].unit;
qw_tq3_q5_stage := g_task[3].queue[5].stage;
qw_tq3_q5_lift := g_task[3].queue[5].LiftStationTarget;
qw_tq3_q5_sink := g_task[3].queue[5].SinkStationTarget;
qw_tq3_q5_start_hi := LINT_TO_INT(g_task[3].queue[5].start_time / 65536);
qw_tq3_q5_start_lo := LINT_TO_INT(g_task[3].queue[5].start_time MOD 65536);
qw_tq3_q5_fin_hi := LINT_TO_INT(g_task[3].queue[5].finish_time / 65536);
qw_tq3_q5_fin_lo := LINT_TO_INT(g_task[3].queue[5].finish_time MOD 65536);
qw_tq3_q5_calc_x10 := DINT_TO_INT(g_task[3].queue[5].calc_time) * 10;
qw_tq3_q5_min_x10 := DINT_TO_INT(g_task[3].queue[5].min_time) * 10;
qw_tq3_q5_max_x10 := DINT_TO_INT(g_task[3].queue[5].max_time) * 10;
qw_tq3_q6_unit := g_task[3].queue[6].unit;
qw_tq3_q6_stage := g_task[3].queue[6].stage;
qw_tq3_q6_lift := g_task[3].queue[6].LiftStationTarget;
qw_tq3_q6_sink := g_task[3].queue[6].SinkStationTarget;
qw_tq3_q6_start_hi := LINT_TO_INT(g_task[3].queue[6].start_time / 65536);
qw_tq3_q6_start_lo := LINT_TO_INT(g_task[3].queue[6].start_time MOD 65536);
qw_tq3_q6_fin_hi := LINT_TO_INT(g_task[3].queue[6].finish_time / 65536);
qw_tq3_q6_fin_lo := LINT_TO_INT(g_task[3].queue[6].finish_time MOD 65536);
qw_tq3_q6_calc_x10 := DINT_TO_INT(g_task[3].queue[6].calc_time) * 10;
qw_tq3_q6_min_x10 := DINT_TO_INT(g_task[3].queue[6].min_time) * 10;
qw_tq3_q6_max_x10 := DINT_TO_INT(g_task[3].queue[6].max_time) * 10;
qw_tq3_q7_unit := g_task[3].queue[7].unit;
qw_tq3_q7_stage := g_task[3].queue[7].stage;
qw_tq3_q7_lift := g_task[3].queue[7].LiftStationTarget;
qw_tq3_q7_sink := g_task[3].queue[7].SinkStationTarget;
qw_tq3_q7_start_hi := LINT_TO_INT(g_task[3].queue[7].start_time / 65536);
qw_tq3_q7_start_lo := LINT_TO_INT(g_task[3].queue[7].start_time MOD 65536);
qw_tq3_q7_fin_hi := LINT_TO_INT(g_task[3].queue[7].finish_time / 65536);
qw_tq3_q7_fin_lo := LINT_TO_INT(g_task[3].queue[7].finish_time MOD 65536);
qw_tq3_q7_calc_x10 := DINT_TO_INT(g_task[3].queue[7].calc_time) * 10;
qw_tq3_q7_min_x10 := DINT_TO_INT(g_task[3].queue[7].min_time) * 10;
qw_tq3_q7_max_x10 := DINT_TO_INT(g_task[3].queue[7].max_time) * 10;
qw_tq3_q8_unit := g_task[3].queue[8].unit;
qw_tq3_q8_stage := g_task[3].queue[8].stage;
qw_tq3_q8_lift := g_task[3].queue[8].LiftStationTarget;
qw_tq3_q8_sink := g_task[3].queue[8].SinkStationTarget;
qw_tq3_q8_start_hi := LINT_TO_INT(g_task[3].queue[8].start_time / 65536);
qw_tq3_q8_start_lo := LINT_TO_INT(g_task[3].queue[8].start_time MOD 65536);
qw_tq3_q8_fin_hi := LINT_TO_INT(g_task[3].queue[8].finish_time / 65536);
qw_tq3_q8_fin_lo := LINT_TO_INT(g_task[3].queue[8].finish_time MOD 65536);
qw_tq3_q8_calc_x10 := DINT_TO_INT(g_task[3].queue[8].calc_time) * 10;
qw_tq3_q8_min_x10 := DINT_TO_INT(g_task[3].queue[8].min_time) * 10;
qw_tq3_q8_max_x10 := DINT_TO_INT(g_task[3].queue[8].max_time) * 10;
qw_tq3_q9_unit := g_task[3].queue[9].unit;
qw_tq3_q9_stage := g_task[3].queue[9].stage;
qw_tq3_q9_lift := g_task[3].queue[9].LiftStationTarget;
qw_tq3_q9_sink := g_task[3].queue[9].SinkStationTarget;
qw_tq3_q9_start_hi := LINT_TO_INT(g_task[3].queue[9].start_time / 65536);
qw_tq3_q9_start_lo := LINT_TO_INT(g_task[3].queue[9].start_time MOD 65536);
qw_tq3_q9_fin_hi := LINT_TO_INT(g_task[3].queue[9].finish_time / 65536);
qw_tq3_q9_fin_lo := LINT_TO_INT(g_task[3].queue[9].finish_time MOD 65536);
qw_tq3_q9_calc_x10 := DINT_TO_INT(g_task[3].queue[9].calc_time) * 10;
qw_tq3_q9_min_x10 := DINT_TO_INT(g_task[3].queue[9].min_time) * 10;
qw_tq3_q9_max_x10 := DINT_TO_INT(g_task[3].queue[9].max_time) * 10;
qw_tq3_q10_unit := g_task[3].queue[10].unit;
qw_tq3_q10_stage := g_task[3].queue[10].stage;
qw_tq3_q10_lift := g_task[3].queue[10].LiftStationTarget;
qw_tq3_q10_sink := g_task[3].queue[10].SinkStationTarget;
qw_tq3_q10_start_hi := LINT_TO_INT(g_task[3].queue[10].start_time / 65536);
qw_tq3_q10_start_lo := LINT_TO_INT(g_task[3].queue[10].start_time MOD 65536);
qw_tq3_q10_fin_hi := LINT_TO_INT(g_task[3].queue[10].finish_time / 65536);
qw_tq3_q10_fin_lo := LINT_TO_INT(g_task[3].queue[10].finish_time MOD 65536);
qw_tq3_q10_calc_x10 := DINT_TO_INT(g_task[3].queue[10].calc_time) * 10;
qw_tq3_q10_min_x10 := DINT_TO_INT(g_task[3].queue[10].min_time) * 10;
qw_tq3_q10_max_x10 := DINT_TO_INT(g_task[3].queue[10].max_time) * 10;
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

(* ── SCHEDULE WINDOW EXPORT ──
   Gateway writes iw_schedule_req_unit = N (1..10).
   PLC copies g_schedule[N] into the window registers and bumps seq.
   Gateway detects seq change → reads window → stores → requests next unit. *)
IF iw_schedule_req_unit >= 1 AND iw_schedule_req_unit <= 10
   AND iw_schedule_req_unit <> sch_last_req THEN
  sch_last_req := iw_schedule_req_unit;
  sch_copy := g_schedule[iw_schedule_req_unit];

  qw_schedule_window_unit_id := iw_schedule_req_unit;
  qw_schedule_window_stage_count := sch_copy.stage_count;

  (* Stage 1 *)
  qw_schedule_window_s1_stn := sch_copy.stages[1].station;
  qw_schedule_window_s1_entry_hi := LINT_TO_INT(sch_copy.stages[1].entry_time / 65536);
  qw_schedule_window_s1_entry_lo := LINT_TO_INT(sch_copy.stages[1].entry_time MOD 65536);
  qw_schedule_window_s1_exit_hi := LINT_TO_INT(sch_copy.stages[1].exit_time / 65536);
  qw_schedule_window_s1_exit_lo := LINT_TO_INT(sch_copy.stages[1].exit_time MOD 65536);
  qw_schedule_window_s1_min_x10 := DINT_TO_INT(sch_copy.stages[1].min_time) * 10;
  qw_schedule_window_s1_max_x10 := DINT_TO_INT(sch_copy.stages[1].max_time) * 10;
  (* Stage 2 *)
  qw_schedule_window_s2_stn := sch_copy.stages[2].station;
  qw_schedule_window_s2_entry_hi := LINT_TO_INT(sch_copy.stages[2].entry_time / 65536);
  qw_schedule_window_s2_entry_lo := LINT_TO_INT(sch_copy.stages[2].entry_time MOD 65536);
  qw_schedule_window_s2_exit_hi := LINT_TO_INT(sch_copy.stages[2].exit_time / 65536);
  qw_schedule_window_s2_exit_lo := LINT_TO_INT(sch_copy.stages[2].exit_time MOD 65536);
  qw_schedule_window_s2_min_x10 := DINT_TO_INT(sch_copy.stages[2].min_time) * 10;
  qw_schedule_window_s2_max_x10 := DINT_TO_INT(sch_copy.stages[2].max_time) * 10;
  (* Stage 3 *)
  qw_schedule_window_s3_stn := sch_copy.stages[3].station;
  qw_schedule_window_s3_entry_hi := LINT_TO_INT(sch_copy.stages[3].entry_time / 65536);
  qw_schedule_window_s3_entry_lo := LINT_TO_INT(sch_copy.stages[3].entry_time MOD 65536);
  qw_schedule_window_s3_exit_hi := LINT_TO_INT(sch_copy.stages[3].exit_time / 65536);
  qw_schedule_window_s3_exit_lo := LINT_TO_INT(sch_copy.stages[3].exit_time MOD 65536);
  qw_schedule_window_s3_min_x10 := DINT_TO_INT(sch_copy.stages[3].min_time) * 10;
  qw_schedule_window_s3_max_x10 := DINT_TO_INT(sch_copy.stages[3].max_time) * 10;
  (* Stage 4 *)
  qw_schedule_window_s4_stn := sch_copy.stages[4].station;
  qw_schedule_window_s4_entry_hi := LINT_TO_INT(sch_copy.stages[4].entry_time / 65536);
  qw_schedule_window_s4_entry_lo := LINT_TO_INT(sch_copy.stages[4].entry_time MOD 65536);
  qw_schedule_window_s4_exit_hi := LINT_TO_INT(sch_copy.stages[4].exit_time / 65536);
  qw_schedule_window_s4_exit_lo := LINT_TO_INT(sch_copy.stages[4].exit_time MOD 65536);
  qw_schedule_window_s4_min_x10 := DINT_TO_INT(sch_copy.stages[4].min_time) * 10;
  qw_schedule_window_s4_max_x10 := DINT_TO_INT(sch_copy.stages[4].max_time) * 10;
  (* Stage 5 *)
  qw_schedule_window_s5_stn := sch_copy.stages[5].station;
  qw_schedule_window_s5_entry_hi := LINT_TO_INT(sch_copy.stages[5].entry_time / 65536);
  qw_schedule_window_s5_entry_lo := LINT_TO_INT(sch_copy.stages[5].entry_time MOD 65536);
  qw_schedule_window_s5_exit_hi := LINT_TO_INT(sch_copy.stages[5].exit_time / 65536);
  qw_schedule_window_s5_exit_lo := LINT_TO_INT(sch_copy.stages[5].exit_time MOD 65536);
  qw_schedule_window_s5_min_x10 := DINT_TO_INT(sch_copy.stages[5].min_time) * 10;
  qw_schedule_window_s5_max_x10 := DINT_TO_INT(sch_copy.stages[5].max_time) * 10;
  (* Stage 6 *)
  qw_schedule_window_s6_stn := sch_copy.stages[6].station;
  qw_schedule_window_s6_entry_hi := LINT_TO_INT(sch_copy.stages[6].entry_time / 65536);
  qw_schedule_window_s6_entry_lo := LINT_TO_INT(sch_copy.stages[6].entry_time MOD 65536);
  qw_schedule_window_s6_exit_hi := LINT_TO_INT(sch_copy.stages[6].exit_time / 65536);
  qw_schedule_window_s6_exit_lo := LINT_TO_INT(sch_copy.stages[6].exit_time MOD 65536);
  qw_schedule_window_s6_min_x10 := DINT_TO_INT(sch_copy.stages[6].min_time) * 10;
  qw_schedule_window_s6_max_x10 := DINT_TO_INT(sch_copy.stages[6].max_time) * 10;
  (* Stage 7 *)
  qw_schedule_window_s7_stn := sch_copy.stages[7].station;
  qw_schedule_window_s7_entry_hi := LINT_TO_INT(sch_copy.stages[7].entry_time / 65536);
  qw_schedule_window_s7_entry_lo := LINT_TO_INT(sch_copy.stages[7].entry_time MOD 65536);
  qw_schedule_window_s7_exit_hi := LINT_TO_INT(sch_copy.stages[7].exit_time / 65536);
  qw_schedule_window_s7_exit_lo := LINT_TO_INT(sch_copy.stages[7].exit_time MOD 65536);
  qw_schedule_window_s7_min_x10 := DINT_TO_INT(sch_copy.stages[7].min_time) * 10;
  qw_schedule_window_s7_max_x10 := DINT_TO_INT(sch_copy.stages[7].max_time) * 10;
  (* Stage 8 *)
  qw_schedule_window_s8_stn := sch_copy.stages[8].station;
  qw_schedule_window_s8_entry_hi := LINT_TO_INT(sch_copy.stages[8].entry_time / 65536);
  qw_schedule_window_s8_entry_lo := LINT_TO_INT(sch_copy.stages[8].entry_time MOD 65536);
  qw_schedule_window_s8_exit_hi := LINT_TO_INT(sch_copy.stages[8].exit_time / 65536);
  qw_schedule_window_s8_exit_lo := LINT_TO_INT(sch_copy.stages[8].exit_time MOD 65536);
  qw_schedule_window_s8_min_x10 := DINT_TO_INT(sch_copy.stages[8].min_time) * 10;
  qw_schedule_window_s8_max_x10 := DINT_TO_INT(sch_copy.stages[8].max_time) * 10;
  (* Stage 9 *)
  qw_schedule_window_s9_stn := sch_copy.stages[9].station;
  qw_schedule_window_s9_entry_hi := LINT_TO_INT(sch_copy.stages[9].entry_time / 65536);
  qw_schedule_window_s9_entry_lo := LINT_TO_INT(sch_copy.stages[9].entry_time MOD 65536);
  qw_schedule_window_s9_exit_hi := LINT_TO_INT(sch_copy.stages[9].exit_time / 65536);
  qw_schedule_window_s9_exit_lo := LINT_TO_INT(sch_copy.stages[9].exit_time MOD 65536);
  qw_schedule_window_s9_min_x10 := DINT_TO_INT(sch_copy.stages[9].min_time) * 10;
  qw_schedule_window_s9_max_x10 := DINT_TO_INT(sch_copy.stages[9].max_time) * 10;
  (* Stage 10 *)
  qw_schedule_window_s10_stn := sch_copy.stages[10].station;
  qw_schedule_window_s10_entry_hi := LINT_TO_INT(sch_copy.stages[10].entry_time / 65536);
  qw_schedule_window_s10_entry_lo := LINT_TO_INT(sch_copy.stages[10].entry_time MOD 65536);
  qw_schedule_window_s10_exit_hi := LINT_TO_INT(sch_copy.stages[10].exit_time / 65536);
  qw_schedule_window_s10_exit_lo := LINT_TO_INT(sch_copy.stages[10].exit_time MOD 65536);
  qw_schedule_window_s10_min_x10 := DINT_TO_INT(sch_copy.stages[10].min_time) * 10;
  qw_schedule_window_s10_max_x10 := DINT_TO_INT(sch_copy.stages[10].max_time) * 10;
  (* Stage 11 *)
  qw_schedule_window_s11_stn := sch_copy.stages[11].station;
  qw_schedule_window_s11_entry_hi := LINT_TO_INT(sch_copy.stages[11].entry_time / 65536);
  qw_schedule_window_s11_entry_lo := LINT_TO_INT(sch_copy.stages[11].entry_time MOD 65536);
  qw_schedule_window_s11_exit_hi := LINT_TO_INT(sch_copy.stages[11].exit_time / 65536);
  qw_schedule_window_s11_exit_lo := LINT_TO_INT(sch_copy.stages[11].exit_time MOD 65536);
  qw_schedule_window_s11_min_x10 := DINT_TO_INT(sch_copy.stages[11].min_time) * 10;
  qw_schedule_window_s11_max_x10 := DINT_TO_INT(sch_copy.stages[11].max_time) * 10;
  (* Stage 12 *)
  qw_schedule_window_s12_stn := sch_copy.stages[12].station;
  qw_schedule_window_s12_entry_hi := LINT_TO_INT(sch_copy.stages[12].entry_time / 65536);
  qw_schedule_window_s12_entry_lo := LINT_TO_INT(sch_copy.stages[12].entry_time MOD 65536);
  qw_schedule_window_s12_exit_hi := LINT_TO_INT(sch_copy.stages[12].exit_time / 65536);
  qw_schedule_window_s12_exit_lo := LINT_TO_INT(sch_copy.stages[12].exit_time MOD 65536);
  qw_schedule_window_s12_min_x10 := DINT_TO_INT(sch_copy.stages[12].min_time) * 10;
  qw_schedule_window_s12_max_x10 := DINT_TO_INT(sch_copy.stages[12].max_time) * 10;
  (* Stage 13 *)
  qw_schedule_window_s13_stn := sch_copy.stages[13].station;
  qw_schedule_window_s13_entry_hi := LINT_TO_INT(sch_copy.stages[13].entry_time / 65536);
  qw_schedule_window_s13_entry_lo := LINT_TO_INT(sch_copy.stages[13].entry_time MOD 65536);
  qw_schedule_window_s13_exit_hi := LINT_TO_INT(sch_copy.stages[13].exit_time / 65536);
  qw_schedule_window_s13_exit_lo := LINT_TO_INT(sch_copy.stages[13].exit_time MOD 65536);
  qw_schedule_window_s13_min_x10 := DINT_TO_INT(sch_copy.stages[13].min_time) * 10;
  qw_schedule_window_s13_max_x10 := DINT_TO_INT(sch_copy.stages[13].max_time) * 10;
  (* Stage 14 *)
  qw_schedule_window_s14_stn := sch_copy.stages[14].station;
  qw_schedule_window_s14_entry_hi := LINT_TO_INT(sch_copy.stages[14].entry_time / 65536);
  qw_schedule_window_s14_entry_lo := LINT_TO_INT(sch_copy.stages[14].entry_time MOD 65536);
  qw_schedule_window_s14_exit_hi := LINT_TO_INT(sch_copy.stages[14].exit_time / 65536);
  qw_schedule_window_s14_exit_lo := LINT_TO_INT(sch_copy.stages[14].exit_time MOD 65536);
  qw_schedule_window_s14_min_x10 := DINT_TO_INT(sch_copy.stages[14].min_time) * 10;
  qw_schedule_window_s14_max_x10 := DINT_TO_INT(sch_copy.stages[14].max_time) * 10;
  (* Stage 15 *)
  qw_schedule_window_s15_stn := sch_copy.stages[15].station;
  qw_schedule_window_s15_entry_hi := LINT_TO_INT(sch_copy.stages[15].entry_time / 65536);
  qw_schedule_window_s15_entry_lo := LINT_TO_INT(sch_copy.stages[15].entry_time MOD 65536);
  qw_schedule_window_s15_exit_hi := LINT_TO_INT(sch_copy.stages[15].exit_time / 65536);
  qw_schedule_window_s15_exit_lo := LINT_TO_INT(sch_copy.stages[15].exit_time MOD 65536);
  qw_schedule_window_s15_min_x10 := DINT_TO_INT(sch_copy.stages[15].min_time) * 10;
  qw_schedule_window_s15_max_x10 := DINT_TO_INT(sch_copy.stages[15].max_time) * 10;
  (* Stage 16 *)
  qw_schedule_window_s16_stn := sch_copy.stages[16].station;
  qw_schedule_window_s16_entry_hi := LINT_TO_INT(sch_copy.stages[16].entry_time / 65536);
  qw_schedule_window_s16_entry_lo := LINT_TO_INT(sch_copy.stages[16].entry_time MOD 65536);
  qw_schedule_window_s16_exit_hi := LINT_TO_INT(sch_copy.stages[16].exit_time / 65536);
  qw_schedule_window_s16_exit_lo := LINT_TO_INT(sch_copy.stages[16].exit_time MOD 65536);
  qw_schedule_window_s16_min_x10 := DINT_TO_INT(sch_copy.stages[16].min_time) * 10;
  qw_schedule_window_s16_max_x10 := DINT_TO_INT(sch_copy.stages[16].max_time) * 10;
  (* Stage 17 *)
  qw_schedule_window_s17_stn := sch_copy.stages[17].station;
  qw_schedule_window_s17_entry_hi := LINT_TO_INT(sch_copy.stages[17].entry_time / 65536);
  qw_schedule_window_s17_entry_lo := LINT_TO_INT(sch_copy.stages[17].entry_time MOD 65536);
  qw_schedule_window_s17_exit_hi := LINT_TO_INT(sch_copy.stages[17].exit_time / 65536);
  qw_schedule_window_s17_exit_lo := LINT_TO_INT(sch_copy.stages[17].exit_time MOD 65536);
  qw_schedule_window_s17_min_x10 := DINT_TO_INT(sch_copy.stages[17].min_time) * 10;
  qw_schedule_window_s17_max_x10 := DINT_TO_INT(sch_copy.stages[17].max_time) * 10;
  (* Stage 18 *)
  qw_schedule_window_s18_stn := sch_copy.stages[18].station;
  qw_schedule_window_s18_entry_hi := LINT_TO_INT(sch_copy.stages[18].entry_time / 65536);
  qw_schedule_window_s18_entry_lo := LINT_TO_INT(sch_copy.stages[18].entry_time MOD 65536);
  qw_schedule_window_s18_exit_hi := LINT_TO_INT(sch_copy.stages[18].exit_time / 65536);
  qw_schedule_window_s18_exit_lo := LINT_TO_INT(sch_copy.stages[18].exit_time MOD 65536);
  qw_schedule_window_s18_min_x10 := DINT_TO_INT(sch_copy.stages[18].min_time) * 10;
  qw_schedule_window_s18_max_x10 := DINT_TO_INT(sch_copy.stages[18].max_time) * 10;
  (* Stage 19 *)
  qw_schedule_window_s19_stn := sch_copy.stages[19].station;
  qw_schedule_window_s19_entry_hi := LINT_TO_INT(sch_copy.stages[19].entry_time / 65536);
  qw_schedule_window_s19_entry_lo := LINT_TO_INT(sch_copy.stages[19].entry_time MOD 65536);
  qw_schedule_window_s19_exit_hi := LINT_TO_INT(sch_copy.stages[19].exit_time / 65536);
  qw_schedule_window_s19_exit_lo := LINT_TO_INT(sch_copy.stages[19].exit_time MOD 65536);
  qw_schedule_window_s19_min_x10 := DINT_TO_INT(sch_copy.stages[19].min_time) * 10;
  qw_schedule_window_s19_max_x10 := DINT_TO_INT(sch_copy.stages[19].max_time) * 10;
  (* Stage 20 *)
  qw_schedule_window_s20_stn := sch_copy.stages[20].station;
  qw_schedule_window_s20_entry_hi := LINT_TO_INT(sch_copy.stages[20].entry_time / 65536);
  qw_schedule_window_s20_entry_lo := LINT_TO_INT(sch_copy.stages[20].entry_time MOD 65536);
  qw_schedule_window_s20_exit_hi := LINT_TO_INT(sch_copy.stages[20].exit_time / 65536);
  qw_schedule_window_s20_exit_lo := LINT_TO_INT(sch_copy.stages[20].exit_time MOD 65536);
  qw_schedule_window_s20_min_x10 := DINT_TO_INT(sch_copy.stages[20].min_time) * 10;
  qw_schedule_window_s20_max_x10 := DINT_TO_INT(sch_copy.stages[20].max_time) * 10;
  (* Stage 21 *)
  qw_schedule_window_s21_stn := sch_copy.stages[21].station;
  qw_schedule_window_s21_entry_hi := LINT_TO_INT(sch_copy.stages[21].entry_time / 65536);
  qw_schedule_window_s21_entry_lo := LINT_TO_INT(sch_copy.stages[21].entry_time MOD 65536);
  qw_schedule_window_s21_exit_hi := LINT_TO_INT(sch_copy.stages[21].exit_time / 65536);
  qw_schedule_window_s21_exit_lo := LINT_TO_INT(sch_copy.stages[21].exit_time MOD 65536);
  qw_schedule_window_s21_min_x10 := DINT_TO_INT(sch_copy.stages[21].min_time) * 10;
  qw_schedule_window_s21_max_x10 := DINT_TO_INT(sch_copy.stages[21].max_time) * 10;
  (* Stage 22 *)
  qw_schedule_window_s22_stn := sch_copy.stages[22].station;
  qw_schedule_window_s22_entry_hi := LINT_TO_INT(sch_copy.stages[22].entry_time / 65536);
  qw_schedule_window_s22_entry_lo := LINT_TO_INT(sch_copy.stages[22].entry_time MOD 65536);
  qw_schedule_window_s22_exit_hi := LINT_TO_INT(sch_copy.stages[22].exit_time / 65536);
  qw_schedule_window_s22_exit_lo := LINT_TO_INT(sch_copy.stages[22].exit_time MOD 65536);
  qw_schedule_window_s22_min_x10 := DINT_TO_INT(sch_copy.stages[22].min_time) * 10;
  qw_schedule_window_s22_max_x10 := DINT_TO_INT(sch_copy.stages[22].max_time) * 10;
  (* Stage 23 *)
  qw_schedule_window_s23_stn := sch_copy.stages[23].station;
  qw_schedule_window_s23_entry_hi := LINT_TO_INT(sch_copy.stages[23].entry_time / 65536);
  qw_schedule_window_s23_entry_lo := LINT_TO_INT(sch_copy.stages[23].entry_time MOD 65536);
  qw_schedule_window_s23_exit_hi := LINT_TO_INT(sch_copy.stages[23].exit_time / 65536);
  qw_schedule_window_s23_exit_lo := LINT_TO_INT(sch_copy.stages[23].exit_time MOD 65536);
  qw_schedule_window_s23_min_x10 := DINT_TO_INT(sch_copy.stages[23].min_time) * 10;
  qw_schedule_window_s23_max_x10 := DINT_TO_INT(sch_copy.stages[23].max_time) * 10;
  (* Stage 24 *)
  qw_schedule_window_s24_stn := sch_copy.stages[24].station;
  qw_schedule_window_s24_entry_hi := LINT_TO_INT(sch_copy.stages[24].entry_time / 65536);
  qw_schedule_window_s24_entry_lo := LINT_TO_INT(sch_copy.stages[24].entry_time MOD 65536);
  qw_schedule_window_s24_exit_hi := LINT_TO_INT(sch_copy.stages[24].exit_time / 65536);
  qw_schedule_window_s24_exit_lo := LINT_TO_INT(sch_copy.stages[24].exit_time MOD 65536);
  qw_schedule_window_s24_min_x10 := DINT_TO_INT(sch_copy.stages[24].min_time) * 10;
  qw_schedule_window_s24_max_x10 := DINT_TO_INT(sch_copy.stages[24].max_time) * 10;
  (* Stage 25 *)
  qw_schedule_window_s25_stn := sch_copy.stages[25].station;
  qw_schedule_window_s25_entry_hi := LINT_TO_INT(sch_copy.stages[25].entry_time / 65536);
  qw_schedule_window_s25_entry_lo := LINT_TO_INT(sch_copy.stages[25].entry_time MOD 65536);
  qw_schedule_window_s25_exit_hi := LINT_TO_INT(sch_copy.stages[25].exit_time / 65536);
  qw_schedule_window_s25_exit_lo := LINT_TO_INT(sch_copy.stages[25].exit_time MOD 65536);
  qw_schedule_window_s25_min_x10 := DINT_TO_INT(sch_copy.stages[25].min_time) * 10;
  qw_schedule_window_s25_max_x10 := DINT_TO_INT(sch_copy.stages[25].max_time) * 10;
  (* Stage 26 *)
  qw_schedule_window_s26_stn := sch_copy.stages[26].station;
  qw_schedule_window_s26_entry_hi := LINT_TO_INT(sch_copy.stages[26].entry_time / 65536);
  qw_schedule_window_s26_entry_lo := LINT_TO_INT(sch_copy.stages[26].entry_time MOD 65536);
  qw_schedule_window_s26_exit_hi := LINT_TO_INT(sch_copy.stages[26].exit_time / 65536);
  qw_schedule_window_s26_exit_lo := LINT_TO_INT(sch_copy.stages[26].exit_time MOD 65536);
  qw_schedule_window_s26_min_x10 := DINT_TO_INT(sch_copy.stages[26].min_time) * 10;
  qw_schedule_window_s26_max_x10 := DINT_TO_INT(sch_copy.stages[26].max_time) * 10;
  (* Stage 27 *)
  qw_schedule_window_s27_stn := sch_copy.stages[27].station;
  qw_schedule_window_s27_entry_hi := LINT_TO_INT(sch_copy.stages[27].entry_time / 65536);
  qw_schedule_window_s27_entry_lo := LINT_TO_INT(sch_copy.stages[27].entry_time MOD 65536);
  qw_schedule_window_s27_exit_hi := LINT_TO_INT(sch_copy.stages[27].exit_time / 65536);
  qw_schedule_window_s27_exit_lo := LINT_TO_INT(sch_copy.stages[27].exit_time MOD 65536);
  qw_schedule_window_s27_min_x10 := DINT_TO_INT(sch_copy.stages[27].min_time) * 10;
  qw_schedule_window_s27_max_x10 := DINT_TO_INT(sch_copy.stages[27].max_time) * 10;
  (* Stage 28 *)
  qw_schedule_window_s28_stn := sch_copy.stages[28].station;
  qw_schedule_window_s28_entry_hi := LINT_TO_INT(sch_copy.stages[28].entry_time / 65536);
  qw_schedule_window_s28_entry_lo := LINT_TO_INT(sch_copy.stages[28].entry_time MOD 65536);
  qw_schedule_window_s28_exit_hi := LINT_TO_INT(sch_copy.stages[28].exit_time / 65536);
  qw_schedule_window_s28_exit_lo := LINT_TO_INT(sch_copy.stages[28].exit_time MOD 65536);
  qw_schedule_window_s28_min_x10 := DINT_TO_INT(sch_copy.stages[28].min_time) * 10;
  qw_schedule_window_s28_max_x10 := DINT_TO_INT(sch_copy.stages[28].max_time) * 10;
  (* Stage 29 *)
  qw_schedule_window_s29_stn := sch_copy.stages[29].station;
  qw_schedule_window_s29_entry_hi := LINT_TO_INT(sch_copy.stages[29].entry_time / 65536);
  qw_schedule_window_s29_entry_lo := LINT_TO_INT(sch_copy.stages[29].entry_time MOD 65536);
  qw_schedule_window_s29_exit_hi := LINT_TO_INT(sch_copy.stages[29].exit_time / 65536);
  qw_schedule_window_s29_exit_lo := LINT_TO_INT(sch_copy.stages[29].exit_time MOD 65536);
  qw_schedule_window_s29_min_x10 := DINT_TO_INT(sch_copy.stages[29].min_time) * 10;
  qw_schedule_window_s29_max_x10 := DINT_TO_INT(sch_copy.stages[29].max_time) * 10;
  (* Stage 30 *)
  qw_schedule_window_s30_stn := sch_copy.stages[30].station;
  qw_schedule_window_s30_entry_hi := LINT_TO_INT(sch_copy.stages[30].entry_time / 65536);
  qw_schedule_window_s30_entry_lo := LINT_TO_INT(sch_copy.stages[30].entry_time MOD 65536);
  qw_schedule_window_s30_exit_hi := LINT_TO_INT(sch_copy.stages[30].exit_time / 65536);
  qw_schedule_window_s30_exit_lo := LINT_TO_INT(sch_copy.stages[30].exit_time MOD 65536);
  qw_schedule_window_s30_min_x10 := DINT_TO_INT(sch_copy.stages[30].min_time) * 10;
  qw_schedule_window_s30_max_x10 := DINT_TO_INT(sch_copy.stages[30].max_time) * 10;

  qw_schedule_window_seq := qw_schedule_window_seq + 1;
END_IF;

END_PROGRAM
