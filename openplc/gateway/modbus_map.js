/**
 * Auto-generated Modbus register map — DO NOT EDIT
 * Generated from modbus_map.json (785 registers)
 */

const TOTAL_REGISTERS = 785;

// Block address ranges
const BLOCKS = {
  transporter_state: { start: 0, end: 38, count: 39, direction: 'out' },
  transporter_extended: { start: 39, end: 77, count: 39, direction: 'out' },
  twa_limits: { start: 78, end: 83, count: 6, direction: 'out' },
  plc_status: { start: 84, end: 95, count: 12, direction: 'out' },
  unit_state: { start: 96, end: 125, count: 30, direction: 'out' },
  batch_state: { start: 126, end: 195, count: 70, direction: 'out' },
  calibration: { start: 196, end: 197, count: 2, direction: 'out' },
  calibration_results: { start: 198, end: 218, count: 21, direction: 'out' },
  transporter_config: { start: 219, end: 305, count: 87, direction: 'out' },
  avoid_status: { start: 306, end: 335, count: 30, direction: 'out' },
  schedule_summary: { start: 336, end: 345, count: 10, direction: 'out' },
  task_queue: { start: 346, end: 678, count: 333, direction: 'out' },
  dep_state: { start: 679, end: 687, count: 9, direction: 'out' },
  dep_waiting: { start: 688, end: 692, count: 5, direction: 'out' },
  dep_overlap: { start: 693, end: 722, count: 30, direction: 'out' },
  cmd_transport: { start: 723, end: 728, count: 6, direction: 'in' },
  cfg: { start: 729, end: 739, count: 11, direction: 'in' },
  unit: { start: 740, end: 744, count: 5, direction: 'in' },
  batch: { start: 745, end: 749, count: 5, direction: 'in' },
  prog: { start: 750, end: 760, count: 11, direction: 'in' },
  avoid: { start: 761, end: 763, count: 3, direction: 'in' },
  production: { start: 764, end: 764, count: 1, direction: 'in' },
  time: { start: 765, end: 766, count: 2, direction: 'in' },
  event_out: { start: 767, end: 783, count: 17, direction: 'out' },
  event_ack: { start: 784, end: 784, count: 1, direction: 'in' },
};

// Register addresses
const REG = {
  qw_t1_x_mm: 0,  // X position mm
  qw_t1_z_mm: 1,  // Z position mm
  qw_t1_vel_x10: 2,  // X velocity ×10
  qw_t1_phase: 3,  // 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking
  qw_t1_unit_id: 4,  // unit currently being transported, 0=none
  qw_t1_z_stage: 5,  // Z motion sub-phase
  qw_t1_cur_st: 6,  // nearest station
  qw_t1_lift_tgt: 7,  // pickup station
  qw_t1_sink_tgt: 8,  // putdown station
  qw_t1_active: 9,  // 1=active 0=inactive
  qw_t1_status: 10,  // 0=not_used 1=manual 2=half 3=auto_idle 4=auto_run
  qw_t1_rtask_hi: 11,  // running task_id upper 16 bits
  qw_t1_rtask_lo: 12,  // running task_id lower 16 bits
  qw_t2_x_mm: 13,  // X position mm
  qw_t2_z_mm: 14,  // Z position mm
  qw_t2_vel_x10: 15,  // X velocity ×10
  qw_t2_phase: 16,  // 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking
  qw_t2_unit_id: 17,  // unit currently being transported, 0=none
  qw_t2_z_stage: 18,  // Z motion sub-phase
  qw_t2_cur_st: 19,  // nearest station
  qw_t2_lift_tgt: 20,  // pickup station
  qw_t2_sink_tgt: 21,  // putdown station
  qw_t2_active: 22,  // 1=active 0=inactive
  qw_t2_status: 23,  // 0=not_used 1=manual 2=half 3=auto_idle 4=auto_run
  qw_t2_rtask_hi: 24,  // running task_id upper 16 bits
  qw_t2_rtask_lo: 25,  // running task_id lower 16 bits
  qw_t3_x_mm: 26,  // X position mm
  qw_t3_z_mm: 27,  // Z position mm
  qw_t3_vel_x10: 28,  // X velocity ×10
  qw_t3_phase: 29,  // 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking
  qw_t3_unit_id: 30,  // unit currently being transported, 0=none
  qw_t3_z_stage: 31,  // Z motion sub-phase
  qw_t3_cur_st: 32,  // nearest station
  qw_t3_lift_tgt: 33,  // pickup station
  qw_t3_sink_tgt: 34,  // putdown station
  qw_t3_active: 35,  // 1=active 0=inactive
  qw_t3_status: 36,  // 0=not_used 1=manual 2=half 3=auto_idle 4=auto_run
  qw_t3_rtask_hi: 37,  // running task_id upper 16 bits
  qw_t3_rtask_lo: 38,  // running task_id lower 16 bits
  qw_t1_remain_x10: 39,  // remaining treatment time ×10 (0.1s)
  qw_t1_treat_time: 40,  // treatment duration (s)
  qw_t1_fintgt_x: 41,  // destination X mm
  qw_t1_drvtgt_x: 42,  // TWA-clamped X mm
  qw_t1_fintgt_y: 43,  // destination Y mm (3D)
  qw_t1_drvtgt_y: 44,  // TWA-clamped Y mm (3D)
  qw_t1_y_mm: 45,  // Y position mm (3D)
  qw_t1_ztimer_x10: 46,  // Z motion timer ×10 (0.1s)
  qw_t1_ctask_hi: 47,  // command task_id upper 16
  qw_t1_ctask_lo: 48,  // command task_id lower 16
  qw_t1_ldev_x10: 49,  // lift device delay ×10 (0.1s)
  qw_t1_sdev_x10: 50,  // sink device delay ×10 (0.1s)
  qw_t1_drop_x10: 51,  // dropping time ×10 (0.1s)
  qw_t2_remain_x10: 52,  // remaining treatment time ×10 (0.1s)
  qw_t2_treat_time: 53,  // treatment duration (s)
  qw_t2_fintgt_x: 54,  // destination X mm
  qw_t2_drvtgt_x: 55,  // TWA-clamped X mm
  qw_t2_fintgt_y: 56,  // destination Y mm (3D)
  qw_t2_drvtgt_y: 57,  // TWA-clamped Y mm (3D)
  qw_t2_y_mm: 58,  // Y position mm (3D)
  qw_t2_ztimer_x10: 59,  // Z motion timer ×10 (0.1s)
  qw_t2_ctask_hi: 60,  // command task_id upper 16
  qw_t2_ctask_lo: 61,  // command task_id lower 16
  qw_t2_ldev_x10: 62,  // lift device delay ×10 (0.1s)
  qw_t2_sdev_x10: 63,  // sink device delay ×10 (0.1s)
  qw_t2_drop_x10: 64,  // dropping time ×10 (0.1s)
  qw_t3_remain_x10: 65,  // remaining treatment time ×10 (0.1s)
  qw_t3_treat_time: 66,  // treatment duration (s)
  qw_t3_fintgt_x: 67,  // destination X mm
  qw_t3_drvtgt_x: 68,  // TWA-clamped X mm
  qw_t3_fintgt_y: 69,  // destination Y mm (3D)
  qw_t3_drvtgt_y: 70,  // TWA-clamped Y mm (3D)
  qw_t3_y_mm: 71,  // Y position mm (3D)
  qw_t3_ztimer_x10: 72,  // Z motion timer ×10 (0.1s)
  qw_t3_ctask_hi: 73,  // command task_id upper 16
  qw_t3_ctask_lo: 74,  // command task_id lower 16
  qw_t3_ldev_x10: 75,  // lift device delay ×10 (0.1s)
  qw_t3_sdev_x10: 76,  // sink device delay ×10 (0.1s)
  qw_t3_drop_x10: 77,  // dropping time ×10 (0.1s)
  qw_t1_xmin: 78,  // TWA lower X limit mm
  qw_t1_xmax: 79,  // TWA upper X limit mm
  qw_t2_xmin: 80,  // TWA lower X limit mm
  qw_t2_xmax: 81,  // TWA upper X limit mm
  qw_t3_xmin: 82,  // TWA lower X limit mm
  qw_t3_xmax: 83,  // TWA upper X limit mm
  qw_plc_status_station_cnt: 84,  // configured station count
  qw_plc_status_init_done: 85,  // 1=initialized
  qw_plc_status_cycle_cnt: 86,  // heartbeat counter
  qw_plc_status_cfg_ack: 87,  // last processed cfg seq
  qw_plc_status_unit_ack: 88,  // last processed unit write seq
  qw_plc_status_batch_ack: 89,  // last processed batch write seq
  qw_plc_status_prog_ack: 90,  // last processed program stage seq
  qw_plc_status_avoid_ack: 91,  // last processed avoid write seq
  qw_plc_status_cal_active: 92,  // 1=calibration in progress
  qw_plc_status_prod_queue: 93,  // 1=batches in queue, 0=empty
  qw_plc_status_time_hi: 94,  // PLC unix time upper 16 bits
  qw_plc_status_time_lo: 95,  // PLC unix time lower 16 bits
  qw_u1_loc: 96,  // station number
  qw_u1_status: 97,  // NOT_USED=0, USED=1
  qw_u1_target: 98,  // TO_NONE=0..TO_AVOID=5
  qw_u2_loc: 99,  // station number
  qw_u2_status: 100,  // NOT_USED=0, USED=1
  qw_u2_target: 101,  // TO_NONE=0..TO_AVOID=5
  qw_u3_loc: 102,  // station number
  qw_u3_status: 103,  // NOT_USED=0, USED=1
  qw_u3_target: 104,  // TO_NONE=0..TO_AVOID=5
  qw_u4_loc: 105,  // station number
  qw_u4_status: 106,  // NOT_USED=0, USED=1
  qw_u4_target: 107,  // TO_NONE=0..TO_AVOID=5
  qw_u5_loc: 108,  // station number
  qw_u5_status: 109,  // NOT_USED=0, USED=1
  qw_u5_target: 110,  // TO_NONE=0..TO_AVOID=5
  qw_u6_loc: 111,  // station number
  qw_u6_status: 112,  // NOT_USED=0, USED=1
  qw_u6_target: 113,  // TO_NONE=0..TO_AVOID=5
  qw_u7_loc: 114,  // station number
  qw_u7_status: 115,  // NOT_USED=0, USED=1
  qw_u7_target: 116,  // TO_NONE=0..TO_AVOID=5
  qw_u8_loc: 117,  // station number
  qw_u8_status: 118,  // NOT_USED=0, USED=1
  qw_u8_target: 119,  // TO_NONE=0..TO_AVOID=5
  qw_u9_loc: 120,  // station number
  qw_u9_status: 121,  // NOT_USED=0, USED=1
  qw_u9_target: 122,  // TO_NONE=0..TO_AVOID=5
  qw_u10_loc: 123,  // station number
  qw_u10_status: 124,  // NOT_USED=0, USED=1
  qw_u10_target: 125,  // TO_NONE=0..TO_AVOID=5
  qw_b1_code: 126,  // numeric batch code
  qw_b1_state: 127,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b1_prog: 128,  // treatment program ID
  qw_b1_stage: 129,  // current stage number
  qw_b1_min_time: 130,  // current stage min time (seconds)
  qw_b1_max_time: 131,  // current stage max time (seconds)
  qw_b1_cal_time: 132,  // current stage calc time (seconds)
  qw_b2_code: 133,  // numeric batch code
  qw_b2_state: 134,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b2_prog: 135,  // treatment program ID
  qw_b2_stage: 136,  // current stage number
  qw_b2_min_time: 137,  // current stage min time (seconds)
  qw_b2_max_time: 138,  // current stage max time (seconds)
  qw_b2_cal_time: 139,  // current stage calc time (seconds)
  qw_b3_code: 140,  // numeric batch code
  qw_b3_state: 141,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b3_prog: 142,  // treatment program ID
  qw_b3_stage: 143,  // current stage number
  qw_b3_min_time: 144,  // current stage min time (seconds)
  qw_b3_max_time: 145,  // current stage max time (seconds)
  qw_b3_cal_time: 146,  // current stage calc time (seconds)
  qw_b4_code: 147,  // numeric batch code
  qw_b4_state: 148,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b4_prog: 149,  // treatment program ID
  qw_b4_stage: 150,  // current stage number
  qw_b4_min_time: 151,  // current stage min time (seconds)
  qw_b4_max_time: 152,  // current stage max time (seconds)
  qw_b4_cal_time: 153,  // current stage calc time (seconds)
  qw_b5_code: 154,  // numeric batch code
  qw_b5_state: 155,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b5_prog: 156,  // treatment program ID
  qw_b5_stage: 157,  // current stage number
  qw_b5_min_time: 158,  // current stage min time (seconds)
  qw_b5_max_time: 159,  // current stage max time (seconds)
  qw_b5_cal_time: 160,  // current stage calc time (seconds)
  qw_b6_code: 161,  // numeric batch code
  qw_b6_state: 162,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b6_prog: 163,  // treatment program ID
  qw_b6_stage: 164,  // current stage number
  qw_b6_min_time: 165,  // current stage min time (seconds)
  qw_b6_max_time: 166,  // current stage max time (seconds)
  qw_b6_cal_time: 167,  // current stage calc time (seconds)
  qw_b7_code: 168,  // numeric batch code
  qw_b7_state: 169,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b7_prog: 170,  // treatment program ID
  qw_b7_stage: 171,  // current stage number
  qw_b7_min_time: 172,  // current stage min time (seconds)
  qw_b7_max_time: 173,  // current stage max time (seconds)
  qw_b7_cal_time: 174,  // current stage calc time (seconds)
  qw_b8_code: 175,  // numeric batch code
  qw_b8_state: 176,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b8_prog: 177,  // treatment program ID
  qw_b8_stage: 178,  // current stage number
  qw_b8_min_time: 179,  // current stage min time (seconds)
  qw_b8_max_time: 180,  // current stage max time (seconds)
  qw_b8_cal_time: 181,  // current stage calc time (seconds)
  qw_b9_code: 182,  // numeric batch code
  qw_b9_state: 183,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b9_prog: 184,  // treatment program ID
  qw_b9_stage: 185,  // current stage number
  qw_b9_min_time: 186,  // current stage min time (seconds)
  qw_b9_max_time: 187,  // current stage max time (seconds)
  qw_b9_cal_time: 188,  // current stage calc time (seconds)
  qw_b10_code: 189,  // numeric batch code
  qw_b10_state: 190,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b10_prog: 191,  // treatment program ID
  qw_b10_stage: 192,  // current stage number
  qw_b10_min_time: 193,  // current stage min time (seconds)
  qw_b10_max_time: 194,  // current stage max time (seconds)
  qw_b10_cal_time: 195,  // current stage calc time (seconds)
  qw_calibration_step: 196,  // 0=idle, 100=done, 999=complete
  qw_calibration_tid: 197,  // transporter being calibrated
  qw_cal_t1_lift_wet: 198,  // lift wet time ×10
  qw_cal_t1_sink_wet: 199,  // sink wet time ×10
  qw_cal_t1_lift_dry: 200,  // lift dry time ×10
  qw_cal_t1_sink_dry: 201,  // sink dry time ×10
  qw_cal_t1_x_acc: 202,  // X accel time ×10
  qw_cal_t1_x_dec: 203,  // X decel time ×10
  qw_cal_t1_x_max: 204,  // X max speed mm/s
  qw_cal_t2_lift_wet: 205,  // lift wet time ×10
  qw_cal_t2_sink_wet: 206,  // sink wet time ×10
  qw_cal_t2_lift_dry: 207,  // lift dry time ×10
  qw_cal_t2_sink_dry: 208,  // sink dry time ×10
  qw_cal_t2_x_acc: 209,  // X accel time ×10
  qw_cal_t2_x_dec: 210,  // X decel time ×10
  qw_cal_t2_x_max: 211,  // X max speed mm/s
  qw_cal_t3_lift_wet: 212,  // lift wet time ×10
  qw_cal_t3_sink_wet: 213,  // sink wet time ×10
  qw_cal_t3_lift_dry: 214,  // lift dry time ×10
  qw_cal_t3_sink_dry: 215,  // sink dry time ×10
  qw_cal_t3_x_acc: 216,  // X accel time ×10
  qw_cal_t3_x_dec: 217,  // X decel time ×10
  qw_cal_t3_x_max: 218,  // X max speed mm/s
  qw_cfg_t1_x_min: 219,  // config X min limit mm
  qw_cfg_t1_x_max: 220,  // config X max limit mm
  qw_cfg_t1_y_min: 221,  // config Y min limit mm
  qw_cfg_t1_y_max: 222,  // config Y max limit mm
  qw_cfg_t1_x_avoid: 223,  // X avoid distance mm
  qw_cfg_t1_y_avoid: 224,  // Y avoid distance mm
  qw_cfg_t1_ph_xacc_x100: 225,  // X accel ×100 (0.01s)
  qw_cfg_t1_ph_xdec_x100: 226,  // X decel ×100 (0.01s)
  qw_cfg_t1_ph_xmax: 227,  // X max speed mm/s
  qw_cfg_t1_ph_ztot: 228,  // Z total travel mm
  qw_cfg_t1_ph_zsdry: 229,  // Z slow zone dry mm
  qw_cfg_t1_ph_zswet: 230,  // Z slow zone wet mm
  qw_cfg_t1_ph_zsend: 231,  // Z slow zone end mm
  qw_cfg_t1_ph_zslow: 232,  // Z slow speed mm/s
  qw_cfg_t1_ph_zfast: 233,  // Z fast speed mm/s
  qw_cfg_t1_ph_drip_x10: 234,  // drip delay ×10 (0.1s)
  qw_cfg_t1_ph_avoid: 235,  // physics avoid mm
  qw_cfg_t1_ta1_min_lift: 236,  // task area 1 min lift station
  qw_cfg_t1_ta1_max_lift: 237,  // task area 1 max lift station
  qw_cfg_t1_ta1_min_sink: 238,  // task area 1 min sink station
  qw_cfg_t1_ta1_max_sink: 239,  // task area 1 max sink station
  qw_cfg_t1_ta2_min_lift: 240,  // task area 2 min lift station
  qw_cfg_t1_ta2_max_lift: 241,  // task area 2 max lift station
  qw_cfg_t1_ta2_min_sink: 242,  // task area 2 min sink station
  qw_cfg_t1_ta2_max_sink: 243,  // task area 2 max sink station
  qw_cfg_t1_ta3_min_lift: 244,  // task area 3 min lift station
  qw_cfg_t1_ta3_max_lift: 245,  // task area 3 max lift station
  qw_cfg_t1_ta3_min_sink: 246,  // task area 3 min sink station
  qw_cfg_t1_ta3_max_sink: 247,  // task area 3 max sink station
  qw_cfg_t2_x_min: 248,  // config X min limit mm
  qw_cfg_t2_x_max: 249,  // config X max limit mm
  qw_cfg_t2_y_min: 250,  // config Y min limit mm
  qw_cfg_t2_y_max: 251,  // config Y max limit mm
  qw_cfg_t2_x_avoid: 252,  // X avoid distance mm
  qw_cfg_t2_y_avoid: 253,  // Y avoid distance mm
  qw_cfg_t2_ph_xacc_x100: 254,  // X accel ×100 (0.01s)
  qw_cfg_t2_ph_xdec_x100: 255,  // X decel ×100 (0.01s)
  qw_cfg_t2_ph_xmax: 256,  // X max speed mm/s
  qw_cfg_t2_ph_ztot: 257,  // Z total travel mm
  qw_cfg_t2_ph_zsdry: 258,  // Z slow zone dry mm
  qw_cfg_t2_ph_zswet: 259,  // Z slow zone wet mm
  qw_cfg_t2_ph_zsend: 260,  // Z slow zone end mm
  qw_cfg_t2_ph_zslow: 261,  // Z slow speed mm/s
  qw_cfg_t2_ph_zfast: 262,  // Z fast speed mm/s
  qw_cfg_t2_ph_drip_x10: 263,  // drip delay ×10 (0.1s)
  qw_cfg_t2_ph_avoid: 264,  // physics avoid mm
  qw_cfg_t2_ta1_min_lift: 265,  // task area 1 min lift station
  qw_cfg_t2_ta1_max_lift: 266,  // task area 1 max lift station
  qw_cfg_t2_ta1_min_sink: 267,  // task area 1 min sink station
  qw_cfg_t2_ta1_max_sink: 268,  // task area 1 max sink station
  qw_cfg_t2_ta2_min_lift: 269,  // task area 2 min lift station
  qw_cfg_t2_ta2_max_lift: 270,  // task area 2 max lift station
  qw_cfg_t2_ta2_min_sink: 271,  // task area 2 min sink station
  qw_cfg_t2_ta2_max_sink: 272,  // task area 2 max sink station
  qw_cfg_t2_ta3_min_lift: 273,  // task area 3 min lift station
  qw_cfg_t2_ta3_max_lift: 274,  // task area 3 max lift station
  qw_cfg_t2_ta3_min_sink: 275,  // task area 3 min sink station
  qw_cfg_t2_ta3_max_sink: 276,  // task area 3 max sink station
  qw_cfg_t3_x_min: 277,  // config X min limit mm
  qw_cfg_t3_x_max: 278,  // config X max limit mm
  qw_cfg_t3_y_min: 279,  // config Y min limit mm
  qw_cfg_t3_y_max: 280,  // config Y max limit mm
  qw_cfg_t3_x_avoid: 281,  // X avoid distance mm
  qw_cfg_t3_y_avoid: 282,  // Y avoid distance mm
  qw_cfg_t3_ph_xacc_x100: 283,  // X accel ×100 (0.01s)
  qw_cfg_t3_ph_xdec_x100: 284,  // X decel ×100 (0.01s)
  qw_cfg_t3_ph_xmax: 285,  // X max speed mm/s
  qw_cfg_t3_ph_ztot: 286,  // Z total travel mm
  qw_cfg_t3_ph_zsdry: 287,  // Z slow zone dry mm
  qw_cfg_t3_ph_zswet: 288,  // Z slow zone wet mm
  qw_cfg_t3_ph_zsend: 289,  // Z slow zone end mm
  qw_cfg_t3_ph_zslow: 290,  // Z slow speed mm/s
  qw_cfg_t3_ph_zfast: 291,  // Z fast speed mm/s
  qw_cfg_t3_ph_drip_x10: 292,  // drip delay ×10 (0.1s)
  qw_cfg_t3_ph_avoid: 293,  // physics avoid mm
  qw_cfg_t3_ta1_min_lift: 294,  // task area 1 min lift station
  qw_cfg_t3_ta1_max_lift: 295,  // task area 1 max lift station
  qw_cfg_t3_ta1_min_sink: 296,  // task area 1 min sink station
  qw_cfg_t3_ta1_max_sink: 297,  // task area 1 max sink station
  qw_cfg_t3_ta2_min_lift: 298,  // task area 2 min lift station
  qw_cfg_t3_ta2_max_lift: 299,  // task area 2 max lift station
  qw_cfg_t3_ta2_min_sink: 300,  // task area 2 min sink station
  qw_cfg_t3_ta2_max_sink: 301,  // task area 2 max sink station
  qw_cfg_t3_ta3_min_lift: 302,  // task area 3 min lift station
  qw_cfg_t3_ta3_max_lift: 303,  // task area 3 max lift station
  qw_cfg_t3_ta3_min_sink: 304,  // task area 3 min sink station
  qw_cfg_t3_ta3_max_sink: 305,  // task area 3 max sink station
  qw_s101_val: 306,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s102_val: 307,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s103_val: 308,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s104_val: 309,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s105_val: 310,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s106_val: 311,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s107_val: 312,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s108_val: 313,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s109_val: 314,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s110_val: 315,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s111_val: 316,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s112_val: 317,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s113_val: 318,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s114_val: 319,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s115_val: 320,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s116_val: 321,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s117_val: 322,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s118_val: 323,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s119_val: 324,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s120_val: 325,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s121_val: 326,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s122_val: 327,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s123_val: 328,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s124_val: 329,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s125_val: 330,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s126_val: 331,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s127_val: 332,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s128_val: 333,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s129_val: 334,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s130_val: 335,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_sched_u1_stage_cnt: 336,  // number of active stages
  qw_sched_u2_stage_cnt: 337,  // number of active stages
  qw_sched_u3_stage_cnt: 338,  // number of active stages
  qw_sched_u4_stage_cnt: 339,  // number of active stages
  qw_sched_u5_stage_cnt: 340,  // number of active stages
  qw_sched_u6_stage_cnt: 341,  // number of active stages
  qw_sched_u7_stage_cnt: 342,  // number of active stages
  qw_sched_u8_stage_cnt: 343,  // number of active stages
  qw_sched_u9_stage_cnt: 344,  // number of active stages
  qw_sched_u10_stage_cnt: 345,  // number of active stages
  qw_tq1_count: 346,  // number of active tasks
  qw_tq1_q1_unit: 347,  // task 1 unit index (0=empty)
  qw_tq1_q1_stage: 348,  // task 1 program stage
  qw_tq1_q1_lift: 349,  // task 1 pickup station
  qw_tq1_q1_sink: 350,  // task 1 putdown station
  qw_tq1_q1_start_hi: 351,  // task 1 start time upper 16
  qw_tq1_q1_start_lo: 352,  // task 1 start time lower 16
  qw_tq1_q1_fin_hi: 353,  // task 1 finish time upper 16
  qw_tq1_q1_fin_lo: 354,  // task 1 finish time lower 16
  qw_tq1_q1_calc_x10: 355,  // task 1 calc time ×10
  qw_tq1_q1_min_x10: 356,  // task 1 min time ×10
  qw_tq1_q1_max_x10: 357,  // task 1 max time ×10
  qw_tq1_q2_unit: 358,  // task 2 unit index (0=empty)
  qw_tq1_q2_stage: 359,  // task 2 program stage
  qw_tq1_q2_lift: 360,  // task 2 pickup station
  qw_tq1_q2_sink: 361,  // task 2 putdown station
  qw_tq1_q2_start_hi: 362,  // task 2 start time upper 16
  qw_tq1_q2_start_lo: 363,  // task 2 start time lower 16
  qw_tq1_q2_fin_hi: 364,  // task 2 finish time upper 16
  qw_tq1_q2_fin_lo: 365,  // task 2 finish time lower 16
  qw_tq1_q2_calc_x10: 366,  // task 2 calc time ×10
  qw_tq1_q2_min_x10: 367,  // task 2 min time ×10
  qw_tq1_q2_max_x10: 368,  // task 2 max time ×10
  qw_tq1_q3_unit: 369,  // task 3 unit index (0=empty)
  qw_tq1_q3_stage: 370,  // task 3 program stage
  qw_tq1_q3_lift: 371,  // task 3 pickup station
  qw_tq1_q3_sink: 372,  // task 3 putdown station
  qw_tq1_q3_start_hi: 373,  // task 3 start time upper 16
  qw_tq1_q3_start_lo: 374,  // task 3 start time lower 16
  qw_tq1_q3_fin_hi: 375,  // task 3 finish time upper 16
  qw_tq1_q3_fin_lo: 376,  // task 3 finish time lower 16
  qw_tq1_q3_calc_x10: 377,  // task 3 calc time ×10
  qw_tq1_q3_min_x10: 378,  // task 3 min time ×10
  qw_tq1_q3_max_x10: 379,  // task 3 max time ×10
  qw_tq1_q4_unit: 380,  // task 4 unit index (0=empty)
  qw_tq1_q4_stage: 381,  // task 4 program stage
  qw_tq1_q4_lift: 382,  // task 4 pickup station
  qw_tq1_q4_sink: 383,  // task 4 putdown station
  qw_tq1_q4_start_hi: 384,  // task 4 start time upper 16
  qw_tq1_q4_start_lo: 385,  // task 4 start time lower 16
  qw_tq1_q4_fin_hi: 386,  // task 4 finish time upper 16
  qw_tq1_q4_fin_lo: 387,  // task 4 finish time lower 16
  qw_tq1_q4_calc_x10: 388,  // task 4 calc time ×10
  qw_tq1_q4_min_x10: 389,  // task 4 min time ×10
  qw_tq1_q4_max_x10: 390,  // task 4 max time ×10
  qw_tq1_q5_unit: 391,  // task 5 unit index (0=empty)
  qw_tq1_q5_stage: 392,  // task 5 program stage
  qw_tq1_q5_lift: 393,  // task 5 pickup station
  qw_tq1_q5_sink: 394,  // task 5 putdown station
  qw_tq1_q5_start_hi: 395,  // task 5 start time upper 16
  qw_tq1_q5_start_lo: 396,  // task 5 start time lower 16
  qw_tq1_q5_fin_hi: 397,  // task 5 finish time upper 16
  qw_tq1_q5_fin_lo: 398,  // task 5 finish time lower 16
  qw_tq1_q5_calc_x10: 399,  // task 5 calc time ×10
  qw_tq1_q5_min_x10: 400,  // task 5 min time ×10
  qw_tq1_q5_max_x10: 401,  // task 5 max time ×10
  qw_tq1_q6_unit: 402,  // task 6 unit index (0=empty)
  qw_tq1_q6_stage: 403,  // task 6 program stage
  qw_tq1_q6_lift: 404,  // task 6 pickup station
  qw_tq1_q6_sink: 405,  // task 6 putdown station
  qw_tq1_q6_start_hi: 406,  // task 6 start time upper 16
  qw_tq1_q6_start_lo: 407,  // task 6 start time lower 16
  qw_tq1_q6_fin_hi: 408,  // task 6 finish time upper 16
  qw_tq1_q6_fin_lo: 409,  // task 6 finish time lower 16
  qw_tq1_q6_calc_x10: 410,  // task 6 calc time ×10
  qw_tq1_q6_min_x10: 411,  // task 6 min time ×10
  qw_tq1_q6_max_x10: 412,  // task 6 max time ×10
  qw_tq1_q7_unit: 413,  // task 7 unit index (0=empty)
  qw_tq1_q7_stage: 414,  // task 7 program stage
  qw_tq1_q7_lift: 415,  // task 7 pickup station
  qw_tq1_q7_sink: 416,  // task 7 putdown station
  qw_tq1_q7_start_hi: 417,  // task 7 start time upper 16
  qw_tq1_q7_start_lo: 418,  // task 7 start time lower 16
  qw_tq1_q7_fin_hi: 419,  // task 7 finish time upper 16
  qw_tq1_q7_fin_lo: 420,  // task 7 finish time lower 16
  qw_tq1_q7_calc_x10: 421,  // task 7 calc time ×10
  qw_tq1_q7_min_x10: 422,  // task 7 min time ×10
  qw_tq1_q7_max_x10: 423,  // task 7 max time ×10
  qw_tq1_q8_unit: 424,  // task 8 unit index (0=empty)
  qw_tq1_q8_stage: 425,  // task 8 program stage
  qw_tq1_q8_lift: 426,  // task 8 pickup station
  qw_tq1_q8_sink: 427,  // task 8 putdown station
  qw_tq1_q8_start_hi: 428,  // task 8 start time upper 16
  qw_tq1_q8_start_lo: 429,  // task 8 start time lower 16
  qw_tq1_q8_fin_hi: 430,  // task 8 finish time upper 16
  qw_tq1_q8_fin_lo: 431,  // task 8 finish time lower 16
  qw_tq1_q8_calc_x10: 432,  // task 8 calc time ×10
  qw_tq1_q8_min_x10: 433,  // task 8 min time ×10
  qw_tq1_q8_max_x10: 434,  // task 8 max time ×10
  qw_tq1_q9_unit: 435,  // task 9 unit index (0=empty)
  qw_tq1_q9_stage: 436,  // task 9 program stage
  qw_tq1_q9_lift: 437,  // task 9 pickup station
  qw_tq1_q9_sink: 438,  // task 9 putdown station
  qw_tq1_q9_start_hi: 439,  // task 9 start time upper 16
  qw_tq1_q9_start_lo: 440,  // task 9 start time lower 16
  qw_tq1_q9_fin_hi: 441,  // task 9 finish time upper 16
  qw_tq1_q9_fin_lo: 442,  // task 9 finish time lower 16
  qw_tq1_q9_calc_x10: 443,  // task 9 calc time ×10
  qw_tq1_q9_min_x10: 444,  // task 9 min time ×10
  qw_tq1_q9_max_x10: 445,  // task 9 max time ×10
  qw_tq1_q10_unit: 446,  // task 10 unit index (0=empty)
  qw_tq1_q10_stage: 447,  // task 10 program stage
  qw_tq1_q10_lift: 448,  // task 10 pickup station
  qw_tq1_q10_sink: 449,  // task 10 putdown station
  qw_tq1_q10_start_hi: 450,  // task 10 start time upper 16
  qw_tq1_q10_start_lo: 451,  // task 10 start time lower 16
  qw_tq1_q10_fin_hi: 452,  // task 10 finish time upper 16
  qw_tq1_q10_fin_lo: 453,  // task 10 finish time lower 16
  qw_tq1_q10_calc_x10: 454,  // task 10 calc time ×10
  qw_tq1_q10_min_x10: 455,  // task 10 min time ×10
  qw_tq1_q10_max_x10: 456,  // task 10 max time ×10
  qw_tq2_count: 457,  // number of active tasks
  qw_tq2_q1_unit: 458,  // task 1 unit index (0=empty)
  qw_tq2_q1_stage: 459,  // task 1 program stage
  qw_tq2_q1_lift: 460,  // task 1 pickup station
  qw_tq2_q1_sink: 461,  // task 1 putdown station
  qw_tq2_q1_start_hi: 462,  // task 1 start time upper 16
  qw_tq2_q1_start_lo: 463,  // task 1 start time lower 16
  qw_tq2_q1_fin_hi: 464,  // task 1 finish time upper 16
  qw_tq2_q1_fin_lo: 465,  // task 1 finish time lower 16
  qw_tq2_q1_calc_x10: 466,  // task 1 calc time ×10
  qw_tq2_q1_min_x10: 467,  // task 1 min time ×10
  qw_tq2_q1_max_x10: 468,  // task 1 max time ×10
  qw_tq2_q2_unit: 469,  // task 2 unit index (0=empty)
  qw_tq2_q2_stage: 470,  // task 2 program stage
  qw_tq2_q2_lift: 471,  // task 2 pickup station
  qw_tq2_q2_sink: 472,  // task 2 putdown station
  qw_tq2_q2_start_hi: 473,  // task 2 start time upper 16
  qw_tq2_q2_start_lo: 474,  // task 2 start time lower 16
  qw_tq2_q2_fin_hi: 475,  // task 2 finish time upper 16
  qw_tq2_q2_fin_lo: 476,  // task 2 finish time lower 16
  qw_tq2_q2_calc_x10: 477,  // task 2 calc time ×10
  qw_tq2_q2_min_x10: 478,  // task 2 min time ×10
  qw_tq2_q2_max_x10: 479,  // task 2 max time ×10
  qw_tq2_q3_unit: 480,  // task 3 unit index (0=empty)
  qw_tq2_q3_stage: 481,  // task 3 program stage
  qw_tq2_q3_lift: 482,  // task 3 pickup station
  qw_tq2_q3_sink: 483,  // task 3 putdown station
  qw_tq2_q3_start_hi: 484,  // task 3 start time upper 16
  qw_tq2_q3_start_lo: 485,  // task 3 start time lower 16
  qw_tq2_q3_fin_hi: 486,  // task 3 finish time upper 16
  qw_tq2_q3_fin_lo: 487,  // task 3 finish time lower 16
  qw_tq2_q3_calc_x10: 488,  // task 3 calc time ×10
  qw_tq2_q3_min_x10: 489,  // task 3 min time ×10
  qw_tq2_q3_max_x10: 490,  // task 3 max time ×10
  qw_tq2_q4_unit: 491,  // task 4 unit index (0=empty)
  qw_tq2_q4_stage: 492,  // task 4 program stage
  qw_tq2_q4_lift: 493,  // task 4 pickup station
  qw_tq2_q4_sink: 494,  // task 4 putdown station
  qw_tq2_q4_start_hi: 495,  // task 4 start time upper 16
  qw_tq2_q4_start_lo: 496,  // task 4 start time lower 16
  qw_tq2_q4_fin_hi: 497,  // task 4 finish time upper 16
  qw_tq2_q4_fin_lo: 498,  // task 4 finish time lower 16
  qw_tq2_q4_calc_x10: 499,  // task 4 calc time ×10
  qw_tq2_q4_min_x10: 500,  // task 4 min time ×10
  qw_tq2_q4_max_x10: 501,  // task 4 max time ×10
  qw_tq2_q5_unit: 502,  // task 5 unit index (0=empty)
  qw_tq2_q5_stage: 503,  // task 5 program stage
  qw_tq2_q5_lift: 504,  // task 5 pickup station
  qw_tq2_q5_sink: 505,  // task 5 putdown station
  qw_tq2_q5_start_hi: 506,  // task 5 start time upper 16
  qw_tq2_q5_start_lo: 507,  // task 5 start time lower 16
  qw_tq2_q5_fin_hi: 508,  // task 5 finish time upper 16
  qw_tq2_q5_fin_lo: 509,  // task 5 finish time lower 16
  qw_tq2_q5_calc_x10: 510,  // task 5 calc time ×10
  qw_tq2_q5_min_x10: 511,  // task 5 min time ×10
  qw_tq2_q5_max_x10: 512,  // task 5 max time ×10
  qw_tq2_q6_unit: 513,  // task 6 unit index (0=empty)
  qw_tq2_q6_stage: 514,  // task 6 program stage
  qw_tq2_q6_lift: 515,  // task 6 pickup station
  qw_tq2_q6_sink: 516,  // task 6 putdown station
  qw_tq2_q6_start_hi: 517,  // task 6 start time upper 16
  qw_tq2_q6_start_lo: 518,  // task 6 start time lower 16
  qw_tq2_q6_fin_hi: 519,  // task 6 finish time upper 16
  qw_tq2_q6_fin_lo: 520,  // task 6 finish time lower 16
  qw_tq2_q6_calc_x10: 521,  // task 6 calc time ×10
  qw_tq2_q6_min_x10: 522,  // task 6 min time ×10
  qw_tq2_q6_max_x10: 523,  // task 6 max time ×10
  qw_tq2_q7_unit: 524,  // task 7 unit index (0=empty)
  qw_tq2_q7_stage: 525,  // task 7 program stage
  qw_tq2_q7_lift: 526,  // task 7 pickup station
  qw_tq2_q7_sink: 527,  // task 7 putdown station
  qw_tq2_q7_start_hi: 528,  // task 7 start time upper 16
  qw_tq2_q7_start_lo: 529,  // task 7 start time lower 16
  qw_tq2_q7_fin_hi: 530,  // task 7 finish time upper 16
  qw_tq2_q7_fin_lo: 531,  // task 7 finish time lower 16
  qw_tq2_q7_calc_x10: 532,  // task 7 calc time ×10
  qw_tq2_q7_min_x10: 533,  // task 7 min time ×10
  qw_tq2_q7_max_x10: 534,  // task 7 max time ×10
  qw_tq2_q8_unit: 535,  // task 8 unit index (0=empty)
  qw_tq2_q8_stage: 536,  // task 8 program stage
  qw_tq2_q8_lift: 537,  // task 8 pickup station
  qw_tq2_q8_sink: 538,  // task 8 putdown station
  qw_tq2_q8_start_hi: 539,  // task 8 start time upper 16
  qw_tq2_q8_start_lo: 540,  // task 8 start time lower 16
  qw_tq2_q8_fin_hi: 541,  // task 8 finish time upper 16
  qw_tq2_q8_fin_lo: 542,  // task 8 finish time lower 16
  qw_tq2_q8_calc_x10: 543,  // task 8 calc time ×10
  qw_tq2_q8_min_x10: 544,  // task 8 min time ×10
  qw_tq2_q8_max_x10: 545,  // task 8 max time ×10
  qw_tq2_q9_unit: 546,  // task 9 unit index (0=empty)
  qw_tq2_q9_stage: 547,  // task 9 program stage
  qw_tq2_q9_lift: 548,  // task 9 pickup station
  qw_tq2_q9_sink: 549,  // task 9 putdown station
  qw_tq2_q9_start_hi: 550,  // task 9 start time upper 16
  qw_tq2_q9_start_lo: 551,  // task 9 start time lower 16
  qw_tq2_q9_fin_hi: 552,  // task 9 finish time upper 16
  qw_tq2_q9_fin_lo: 553,  // task 9 finish time lower 16
  qw_tq2_q9_calc_x10: 554,  // task 9 calc time ×10
  qw_tq2_q9_min_x10: 555,  // task 9 min time ×10
  qw_tq2_q9_max_x10: 556,  // task 9 max time ×10
  qw_tq2_q10_unit: 557,  // task 10 unit index (0=empty)
  qw_tq2_q10_stage: 558,  // task 10 program stage
  qw_tq2_q10_lift: 559,  // task 10 pickup station
  qw_tq2_q10_sink: 560,  // task 10 putdown station
  qw_tq2_q10_start_hi: 561,  // task 10 start time upper 16
  qw_tq2_q10_start_lo: 562,  // task 10 start time lower 16
  qw_tq2_q10_fin_hi: 563,  // task 10 finish time upper 16
  qw_tq2_q10_fin_lo: 564,  // task 10 finish time lower 16
  qw_tq2_q10_calc_x10: 565,  // task 10 calc time ×10
  qw_tq2_q10_min_x10: 566,  // task 10 min time ×10
  qw_tq2_q10_max_x10: 567,  // task 10 max time ×10
  qw_tq3_count: 568,  // number of active tasks
  qw_tq3_q1_unit: 569,  // task 1 unit index (0=empty)
  qw_tq3_q1_stage: 570,  // task 1 program stage
  qw_tq3_q1_lift: 571,  // task 1 pickup station
  qw_tq3_q1_sink: 572,  // task 1 putdown station
  qw_tq3_q1_start_hi: 573,  // task 1 start time upper 16
  qw_tq3_q1_start_lo: 574,  // task 1 start time lower 16
  qw_tq3_q1_fin_hi: 575,  // task 1 finish time upper 16
  qw_tq3_q1_fin_lo: 576,  // task 1 finish time lower 16
  qw_tq3_q1_calc_x10: 577,  // task 1 calc time ×10
  qw_tq3_q1_min_x10: 578,  // task 1 min time ×10
  qw_tq3_q1_max_x10: 579,  // task 1 max time ×10
  qw_tq3_q2_unit: 580,  // task 2 unit index (0=empty)
  qw_tq3_q2_stage: 581,  // task 2 program stage
  qw_tq3_q2_lift: 582,  // task 2 pickup station
  qw_tq3_q2_sink: 583,  // task 2 putdown station
  qw_tq3_q2_start_hi: 584,  // task 2 start time upper 16
  qw_tq3_q2_start_lo: 585,  // task 2 start time lower 16
  qw_tq3_q2_fin_hi: 586,  // task 2 finish time upper 16
  qw_tq3_q2_fin_lo: 587,  // task 2 finish time lower 16
  qw_tq3_q2_calc_x10: 588,  // task 2 calc time ×10
  qw_tq3_q2_min_x10: 589,  // task 2 min time ×10
  qw_tq3_q2_max_x10: 590,  // task 2 max time ×10
  qw_tq3_q3_unit: 591,  // task 3 unit index (0=empty)
  qw_tq3_q3_stage: 592,  // task 3 program stage
  qw_tq3_q3_lift: 593,  // task 3 pickup station
  qw_tq3_q3_sink: 594,  // task 3 putdown station
  qw_tq3_q3_start_hi: 595,  // task 3 start time upper 16
  qw_tq3_q3_start_lo: 596,  // task 3 start time lower 16
  qw_tq3_q3_fin_hi: 597,  // task 3 finish time upper 16
  qw_tq3_q3_fin_lo: 598,  // task 3 finish time lower 16
  qw_tq3_q3_calc_x10: 599,  // task 3 calc time ×10
  qw_tq3_q3_min_x10: 600,  // task 3 min time ×10
  qw_tq3_q3_max_x10: 601,  // task 3 max time ×10
  qw_tq3_q4_unit: 602,  // task 4 unit index (0=empty)
  qw_tq3_q4_stage: 603,  // task 4 program stage
  qw_tq3_q4_lift: 604,  // task 4 pickup station
  qw_tq3_q4_sink: 605,  // task 4 putdown station
  qw_tq3_q4_start_hi: 606,  // task 4 start time upper 16
  qw_tq3_q4_start_lo: 607,  // task 4 start time lower 16
  qw_tq3_q4_fin_hi: 608,  // task 4 finish time upper 16
  qw_tq3_q4_fin_lo: 609,  // task 4 finish time lower 16
  qw_tq3_q4_calc_x10: 610,  // task 4 calc time ×10
  qw_tq3_q4_min_x10: 611,  // task 4 min time ×10
  qw_tq3_q4_max_x10: 612,  // task 4 max time ×10
  qw_tq3_q5_unit: 613,  // task 5 unit index (0=empty)
  qw_tq3_q5_stage: 614,  // task 5 program stage
  qw_tq3_q5_lift: 615,  // task 5 pickup station
  qw_tq3_q5_sink: 616,  // task 5 putdown station
  qw_tq3_q5_start_hi: 617,  // task 5 start time upper 16
  qw_tq3_q5_start_lo: 618,  // task 5 start time lower 16
  qw_tq3_q5_fin_hi: 619,  // task 5 finish time upper 16
  qw_tq3_q5_fin_lo: 620,  // task 5 finish time lower 16
  qw_tq3_q5_calc_x10: 621,  // task 5 calc time ×10
  qw_tq3_q5_min_x10: 622,  // task 5 min time ×10
  qw_tq3_q5_max_x10: 623,  // task 5 max time ×10
  qw_tq3_q6_unit: 624,  // task 6 unit index (0=empty)
  qw_tq3_q6_stage: 625,  // task 6 program stage
  qw_tq3_q6_lift: 626,  // task 6 pickup station
  qw_tq3_q6_sink: 627,  // task 6 putdown station
  qw_tq3_q6_start_hi: 628,  // task 6 start time upper 16
  qw_tq3_q6_start_lo: 629,  // task 6 start time lower 16
  qw_tq3_q6_fin_hi: 630,  // task 6 finish time upper 16
  qw_tq3_q6_fin_lo: 631,  // task 6 finish time lower 16
  qw_tq3_q6_calc_x10: 632,  // task 6 calc time ×10
  qw_tq3_q6_min_x10: 633,  // task 6 min time ×10
  qw_tq3_q6_max_x10: 634,  // task 6 max time ×10
  qw_tq3_q7_unit: 635,  // task 7 unit index (0=empty)
  qw_tq3_q7_stage: 636,  // task 7 program stage
  qw_tq3_q7_lift: 637,  // task 7 pickup station
  qw_tq3_q7_sink: 638,  // task 7 putdown station
  qw_tq3_q7_start_hi: 639,  // task 7 start time upper 16
  qw_tq3_q7_start_lo: 640,  // task 7 start time lower 16
  qw_tq3_q7_fin_hi: 641,  // task 7 finish time upper 16
  qw_tq3_q7_fin_lo: 642,  // task 7 finish time lower 16
  qw_tq3_q7_calc_x10: 643,  // task 7 calc time ×10
  qw_tq3_q7_min_x10: 644,  // task 7 min time ×10
  qw_tq3_q7_max_x10: 645,  // task 7 max time ×10
  qw_tq3_q8_unit: 646,  // task 8 unit index (0=empty)
  qw_tq3_q8_stage: 647,  // task 8 program stage
  qw_tq3_q8_lift: 648,  // task 8 pickup station
  qw_tq3_q8_sink: 649,  // task 8 putdown station
  qw_tq3_q8_start_hi: 650,  // task 8 start time upper 16
  qw_tq3_q8_start_lo: 651,  // task 8 start time lower 16
  qw_tq3_q8_fin_hi: 652,  // task 8 finish time upper 16
  qw_tq3_q8_fin_lo: 653,  // task 8 finish time lower 16
  qw_tq3_q8_calc_x10: 654,  // task 8 calc time ×10
  qw_tq3_q8_min_x10: 655,  // task 8 min time ×10
  qw_tq3_q8_max_x10: 656,  // task 8 max time ×10
  qw_tq3_q9_unit: 657,  // task 9 unit index (0=empty)
  qw_tq3_q9_stage: 658,  // task 9 program stage
  qw_tq3_q9_lift: 659,  // task 9 pickup station
  qw_tq3_q9_sink: 660,  // task 9 putdown station
  qw_tq3_q9_start_hi: 661,  // task 9 start time upper 16
  qw_tq3_q9_start_lo: 662,  // task 9 start time lower 16
  qw_tq3_q9_fin_hi: 663,  // task 9 finish time upper 16
  qw_tq3_q9_fin_lo: 664,  // task 9 finish time lower 16
  qw_tq3_q9_calc_x10: 665,  // task 9 calc time ×10
  qw_tq3_q9_min_x10: 666,  // task 9 min time ×10
  qw_tq3_q9_max_x10: 667,  // task 9 max time ×10
  qw_tq3_q10_unit: 668,  // task 10 unit index (0=empty)
  qw_tq3_q10_stage: 669,  // task 10 program stage
  qw_tq3_q10_lift: 670,  // task 10 pickup station
  qw_tq3_q10_sink: 671,  // task 10 putdown station
  qw_tq3_q10_start_hi: 672,  // task 10 start time upper 16
  qw_tq3_q10_start_lo: 673,  // task 10 start time lower 16
  qw_tq3_q10_fin_hi: 674,  // task 10 finish time upper 16
  qw_tq3_q10_fin_lo: 675,  // task 10 finish time lower 16
  qw_tq3_q10_calc_x10: 676,  // task 10 calc time ×10
  qw_tq3_q10_min_x10: 677,  // task 10 min time ×10
  qw_tq3_q10_max_x10: 678,  // task 10 max time ×10
  qw_dep_state_activated: 679,  // 1=departure activated handshake
  qw_dep_state_stable: 680,  // 1=task list stable for DEP
  qw_dep_state_waiting_cnt: 681,  // waiting batch count
  qw_dep_state_overlap_cnt: 682,  // overlap station count
  qw_dep_state_pend_valid: 683,  // 1=pending write valid
  qw_dep_state_pend_unit: 684,  // pending activated unit
  qw_dep_state_pend_stage: 685,  // pending activated stage
  qw_dep_state_pend_time_hi: 686,  // pending activation time upper 16
  qw_dep_state_pend_time_lo: 687,  // pending activation time lower 16
  qw_dw1_unit: 688,  // waiting batch unit index (0=empty)
  qw_dw2_unit: 689,  // waiting batch unit index (0=empty)
  qw_dw3_unit: 690,  // waiting batch unit index (0=empty)
  qw_dw4_unit: 691,  // waiting batch unit index (0=empty)
  qw_dw5_unit: 692,  // waiting batch unit index (0=empty)
  qw_ov_s101_flag: 693,  // 1=station in overlap zone
  qw_ov_s102_flag: 694,  // 1=station in overlap zone
  qw_ov_s103_flag: 695,  // 1=station in overlap zone
  qw_ov_s104_flag: 696,  // 1=station in overlap zone
  qw_ov_s105_flag: 697,  // 1=station in overlap zone
  qw_ov_s106_flag: 698,  // 1=station in overlap zone
  qw_ov_s107_flag: 699,  // 1=station in overlap zone
  qw_ov_s108_flag: 700,  // 1=station in overlap zone
  qw_ov_s109_flag: 701,  // 1=station in overlap zone
  qw_ov_s110_flag: 702,  // 1=station in overlap zone
  qw_ov_s111_flag: 703,  // 1=station in overlap zone
  qw_ov_s112_flag: 704,  // 1=station in overlap zone
  qw_ov_s113_flag: 705,  // 1=station in overlap zone
  qw_ov_s114_flag: 706,  // 1=station in overlap zone
  qw_ov_s115_flag: 707,  // 1=station in overlap zone
  qw_ov_s116_flag: 708,  // 1=station in overlap zone
  qw_ov_s117_flag: 709,  // 1=station in overlap zone
  qw_ov_s118_flag: 710,  // 1=station in overlap zone
  qw_ov_s119_flag: 711,  // 1=station in overlap zone
  qw_ov_s120_flag: 712,  // 1=station in overlap zone
  qw_ov_s121_flag: 713,  // 1=station in overlap zone
  qw_ov_s122_flag: 714,  // 1=station in overlap zone
  qw_ov_s123_flag: 715,  // 1=station in overlap zone
  qw_ov_s124_flag: 716,  // 1=station in overlap zone
  qw_ov_s125_flag: 717,  // 1=station in overlap zone
  qw_ov_s126_flag: 718,  // 1=station in overlap zone
  qw_ov_s127_flag: 719,  // 1=station in overlap zone
  qw_ov_s128_flag: 720,  // 1=station in overlap zone
  qw_ov_s129_flag: 721,  // 1=station in overlap zone
  qw_ov_s130_flag: 722,  // 1=station in overlap zone
  iw_cmd_t1_start: 723,  // 1=trigger command
  iw_cmd_t1_lift: 724,  // lift station number
  iw_cmd_t1_sink: 725,  // sink station number
  iw_cmd_t2_start: 726,  // 1=trigger command
  iw_cmd_t2_lift: 727,  // lift station number
  iw_cmd_t2_sink: 728,  // sink station number
  iw_cfg_seq: 729,  // sequence — triggers on change
  iw_cfg_cmd: 730,  // 1=write_station, 2=init, 3=clear_all
  iw_cfg_param: 731,  // station_number or station_count
  iw_cfg_d0: 732,  // tank_id
  iw_cfg_d1: 733,  // x_position mm
  iw_cfg_d2: 734,  // y_position mm
  iw_cfg_d3: 735,  // z_position mm
  iw_cfg_d4: 736,  // operation
  iw_cfg_d5: 737,  // dropping_time ×10
  iw_cfg_d6: 738,  // device_delay ×10
  iw_cfg_d7: 739,  // kind (0=dry, 1=wet)
  iw_unit_seq: 740,  // sequence — triggers on change
  iw_unit_id: 741,  // unit number 1..10
  iw_unit_loc: 742,  // location (station number)
  iw_unit_status: 743,  // NOT_USED=0, USED=1
  iw_unit_target: 744,  // TO_NONE=0..TO_AVOID=5
  iw_batch_seq: 745,  // sequence — triggers on change
  iw_batch_unit: 746,  // unit index 1..10
  iw_batch_code: 747,  // numeric batch code
  iw_batch_state: 748,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  iw_batch_prog_id: 749,  // treatment program ID
  iw_prog_seq: 750,  // sequence — triggers on change
  iw_prog_unit: 751,  // unit index 1..10
  iw_prog_stage: 752,  // stage index 1..30
  iw_prog_s1: 753,  // station 1 (0=unused)
  iw_prog_s2: 754,  // station 2
  iw_prog_s3: 755,  // station 3
  iw_prog_s4: 756,  // station 4
  iw_prog_s5: 757,  // station 5
  iw_prog_min_time: 758,  // min processing time seconds
  iw_prog_max_time: 759,  // max processing time seconds
  iw_prog_cal_time: 760,  // calculated time seconds
  iw_avoid_seq: 761,  // sequence — triggers on change
  iw_avoid_station: 762,  // station number
  iw_avoid_value: 763,  // AVOID_NONE=0, PASS=1, BLOCK=2
  iw_production_queue: 764,  // 1=batches in queue, 0=empty
  iw_time_hi: 765,  // unix seconds upper 16 bits
  iw_time_lo: 766,  // unix seconds lower 16 bits
  qw_event_out_count: 767,  // messages in queue (0..10)
  qw_event_out_seq: 768,  // head message sequence number
  qw_event_out_type: 769,  // message type (1=task,2=lift,...)
  qw_event_out_ts_hi: 770,  // timestamp upper 16 bits
  qw_event_out_ts_lo: 771,  // timestamp lower 16 bits
  qw_event_out_f1: 772,  // payload field 1
  qw_event_out_f2: 773,  // payload field 2
  qw_event_out_f3: 774,  // payload field 3
  qw_event_out_f4: 775,  // payload field 4
  qw_event_out_f5: 776,  // payload field 5
  qw_event_out_f6: 777,  // payload field 6
  qw_event_out_f7: 778,  // payload field 7
  qw_event_out_f8: 779,  // payload field 8
  qw_event_out_f9: 780,  // payload field 9
  qw_event_out_f10: 781,  // payload field 10
  qw_event_out_f11: 782,  // payload field 11
  qw_event_out_f12: 783,  // payload field 12
  iw_event_ack_seq: 784,  // last consumed sequence number
};

// Convert unsigned 16-bit to signed
const toSigned = (v) => v > 32767 ? v - 65536 : v;

/**
 * Decode holding register array into structured objects.
 * @param {number[]} r - Array of register values, r[0] = QW0
 * @returns {object} Decoded state
 */
function decodeRegisters(r) {
  const state = {};

  // --- transporter_state ---
  if (!state.transporter_state) state.transporter_state = {};
  state.transporter_state[1] = {};
  state.transporter_state[1].x_position = toSigned(r[0]);
  state.transporter_state[1].z_position = toSigned(r[1]);
  state.transporter_state[1].velocity_x = toSigned(r[2]) * 0.1;
  state.transporter_state[1].phase = toSigned(r[3]);
  state.transporter_state[1].unit_id = toSigned(r[4]);
  state.transporter_state[1].z_stage = toSigned(r[5]);
  state.transporter_state[1].current_station = toSigned(r[6]);
  state.transporter_state[1].lift_station_target = toSigned(r[7]);
  state.transporter_state[1].sink_station_target = toSigned(r[8]);
  state.transporter_state[1].active = toSigned(r[9]);
  state.transporter_state[1].status_raw = toSigned(r[10]);
  state.transporter_state[1]._rtask_id_hi = r[11];
  state.transporter_state[1]._rtask_id_lo = r[12];
  // Combined uint32: running_task_id = (hi << 16) | lo
  state.transporter_state[1].running_task_id = ((state.transporter_state[1]._rtask_hi & 0xFFFF) * 65536) + (state.transporter_state[1]._rtask_lo & 0xFFFF);
  state.transporter_state[2] = {};
  state.transporter_state[2].x_position = toSigned(r[13]);
  state.transporter_state[2].z_position = toSigned(r[14]);
  state.transporter_state[2].velocity_x = toSigned(r[15]) * 0.1;
  state.transporter_state[2].phase = toSigned(r[16]);
  state.transporter_state[2].unit_id = toSigned(r[17]);
  state.transporter_state[2].z_stage = toSigned(r[18]);
  state.transporter_state[2].current_station = toSigned(r[19]);
  state.transporter_state[2].lift_station_target = toSigned(r[20]);
  state.transporter_state[2].sink_station_target = toSigned(r[21]);
  state.transporter_state[2].active = toSigned(r[22]);
  state.transporter_state[2].status_raw = toSigned(r[23]);
  state.transporter_state[2]._rtask_id_hi = r[24];
  state.transporter_state[2]._rtask_id_lo = r[25];
  // Combined uint32: running_task_id = (hi << 16) | lo
  state.transporter_state[2].running_task_id = ((state.transporter_state[2]._rtask_hi & 0xFFFF) * 65536) + (state.transporter_state[2]._rtask_lo & 0xFFFF);
  state.transporter_state[3] = {};
  state.transporter_state[3].x_position = toSigned(r[26]);
  state.transporter_state[3].z_position = toSigned(r[27]);
  state.transporter_state[3].velocity_x = toSigned(r[28]) * 0.1;
  state.transporter_state[3].phase = toSigned(r[29]);
  state.transporter_state[3].unit_id = toSigned(r[30]);
  state.transporter_state[3].z_stage = toSigned(r[31]);
  state.transporter_state[3].current_station = toSigned(r[32]);
  state.transporter_state[3].lift_station_target = toSigned(r[33]);
  state.transporter_state[3].sink_station_target = toSigned(r[34]);
  state.transporter_state[3].active = toSigned(r[35]);
  state.transporter_state[3].status_raw = toSigned(r[36]);
  state.transporter_state[3]._rtask_id_hi = r[37];
  state.transporter_state[3]._rtask_id_lo = r[38];
  // Combined uint32: running_task_id = (hi << 16) | lo
  state.transporter_state[3].running_task_id = ((state.transporter_state[3]._rtask_hi & 0xFFFF) * 65536) + (state.transporter_state[3]._rtask_lo & 0xFFFF);
  // --- transporter_extended ---
  if (!state.transporter_extended) state.transporter_extended = {};
  state.transporter_extended[1] = {};
  state.transporter_extended[1].remaining_time = toSigned(r[39]) * 0.1;
  state.transporter_extended[1].treatment_time = toSigned(r[40]);
  state.transporter_extended[1].final_target_x = toSigned(r[41]);
  state.transporter_extended[1].drive_target_x = toSigned(r[42]);
  state.transporter_extended[1].final_target_y = toSigned(r[43]);
  state.transporter_extended[1].drive_target_y = toSigned(r[44]);
  state.transporter_extended[1].y_position = toSigned(r[45]);
  state.transporter_extended[1].z_timer = toSigned(r[46]) * 0.1;
  state.transporter_extended[1]._cmd_task_hi = r[47];
  state.transporter_extended[1]._cmd_task_lo = r[48];
  // Combined uint32: cmd_task_id = (hi << 16) | lo
  state.transporter_extended[1].cmd_task_id = ((state.transporter_extended[1]._ctask_hi & 0xFFFF) * 65536) + (state.transporter_extended[1]._ctask_lo & 0xFFFF);
  state.transporter_extended[1].lift_device_delay = toSigned(r[49]) * 0.1;
  state.transporter_extended[1].sink_device_delay = toSigned(r[50]) * 0.1;
  state.transporter_extended[1].dropping_time = toSigned(r[51]) * 0.1;
  state.transporter_extended[2] = {};
  state.transporter_extended[2].remaining_time = toSigned(r[52]) * 0.1;
  state.transporter_extended[2].treatment_time = toSigned(r[53]);
  state.transporter_extended[2].final_target_x = toSigned(r[54]);
  state.transporter_extended[2].drive_target_x = toSigned(r[55]);
  state.transporter_extended[2].final_target_y = toSigned(r[56]);
  state.transporter_extended[2].drive_target_y = toSigned(r[57]);
  state.transporter_extended[2].y_position = toSigned(r[58]);
  state.transporter_extended[2].z_timer = toSigned(r[59]) * 0.1;
  state.transporter_extended[2]._cmd_task_hi = r[60];
  state.transporter_extended[2]._cmd_task_lo = r[61];
  // Combined uint32: cmd_task_id = (hi << 16) | lo
  state.transporter_extended[2].cmd_task_id = ((state.transporter_extended[2]._ctask_hi & 0xFFFF) * 65536) + (state.transporter_extended[2]._ctask_lo & 0xFFFF);
  state.transporter_extended[2].lift_device_delay = toSigned(r[62]) * 0.1;
  state.transporter_extended[2].sink_device_delay = toSigned(r[63]) * 0.1;
  state.transporter_extended[2].dropping_time = toSigned(r[64]) * 0.1;
  state.transporter_extended[3] = {};
  state.transporter_extended[3].remaining_time = toSigned(r[65]) * 0.1;
  state.transporter_extended[3].treatment_time = toSigned(r[66]);
  state.transporter_extended[3].final_target_x = toSigned(r[67]);
  state.transporter_extended[3].drive_target_x = toSigned(r[68]);
  state.transporter_extended[3].final_target_y = toSigned(r[69]);
  state.transporter_extended[3].drive_target_y = toSigned(r[70]);
  state.transporter_extended[3].y_position = toSigned(r[71]);
  state.transporter_extended[3].z_timer = toSigned(r[72]) * 0.1;
  state.transporter_extended[3]._cmd_task_hi = r[73];
  state.transporter_extended[3]._cmd_task_lo = r[74];
  // Combined uint32: cmd_task_id = (hi << 16) | lo
  state.transporter_extended[3].cmd_task_id = ((state.transporter_extended[3]._ctask_hi & 0xFFFF) * 65536) + (state.transporter_extended[3]._ctask_lo & 0xFFFF);
  state.transporter_extended[3].lift_device_delay = toSigned(r[75]) * 0.1;
  state.transporter_extended[3].sink_device_delay = toSigned(r[76]) * 0.1;
  state.transporter_extended[3].dropping_time = toSigned(r[77]) * 0.1;
  // --- twa_limits ---
  if (!state.twa_limits) state.twa_limits = {};
  state.twa_limits[1] = {};
  state.twa_limits[1].x_min_drive_limit = toSigned(r[78]);
  state.twa_limits[1].x_max_drive_limit = toSigned(r[79]);
  state.twa_limits[2] = {};
  state.twa_limits[2].x_min_drive_limit = toSigned(r[80]);
  state.twa_limits[2].x_max_drive_limit = toSigned(r[81]);
  state.twa_limits[3] = {};
  state.twa_limits[3].x_min_drive_limit = toSigned(r[82]);
  state.twa_limits[3].x_max_drive_limit = toSigned(r[83]);
  // --- plc_status ---
  state.plc_status = {};
  state.plc_status.station_count = toSigned(r[84]);
  state.plc_status.init_done = toSigned(r[85]);
  state.plc_status.cycle_count = toSigned(r[86]);
  state.plc_status.cfg_ack = toSigned(r[87]);
  state.plc_status.unit_ack = toSigned(r[88]);
  state.plc_status.batch_ack = toSigned(r[89]);
  state.plc_status.prog_ack = toSigned(r[90]);
  state.plc_status.avoid_ack = toSigned(r[91]);
  state.plc_status.cal_active = toSigned(r[92]);
  state.plc_status.production_queue = toSigned(r[93]);
  state.plc_status._plc_time_hi = r[94];
  state.plc_status._plc_time_lo = r[95];
  // Combined uint32: plc_time_s = (hi << 16) | lo
  state.plc_status.plc_time_s = ((state.plc_status._time_hi & 0xFFFF) * 65536) + (state.plc_status._time_lo & 0xFFFF);
  // --- unit_state ---
  if (!state.unit_state) state.unit_state = {};
  state.unit_state[1] = {};
  state.unit_state[1].location = toSigned(r[96]);
  state.unit_state[1].status = toSigned(r[97]);
  state.unit_state[1].target = toSigned(r[98]);
  state.unit_state[2] = {};
  state.unit_state[2].location = toSigned(r[99]);
  state.unit_state[2].status = toSigned(r[100]);
  state.unit_state[2].target = toSigned(r[101]);
  state.unit_state[3] = {};
  state.unit_state[3].location = toSigned(r[102]);
  state.unit_state[3].status = toSigned(r[103]);
  state.unit_state[3].target = toSigned(r[104]);
  state.unit_state[4] = {};
  state.unit_state[4].location = toSigned(r[105]);
  state.unit_state[4].status = toSigned(r[106]);
  state.unit_state[4].target = toSigned(r[107]);
  state.unit_state[5] = {};
  state.unit_state[5].location = toSigned(r[108]);
  state.unit_state[5].status = toSigned(r[109]);
  state.unit_state[5].target = toSigned(r[110]);
  state.unit_state[6] = {};
  state.unit_state[6].location = toSigned(r[111]);
  state.unit_state[6].status = toSigned(r[112]);
  state.unit_state[6].target = toSigned(r[113]);
  state.unit_state[7] = {};
  state.unit_state[7].location = toSigned(r[114]);
  state.unit_state[7].status = toSigned(r[115]);
  state.unit_state[7].target = toSigned(r[116]);
  state.unit_state[8] = {};
  state.unit_state[8].location = toSigned(r[117]);
  state.unit_state[8].status = toSigned(r[118]);
  state.unit_state[8].target = toSigned(r[119]);
  state.unit_state[9] = {};
  state.unit_state[9].location = toSigned(r[120]);
  state.unit_state[9].status = toSigned(r[121]);
  state.unit_state[9].target = toSigned(r[122]);
  state.unit_state[10] = {};
  state.unit_state[10].location = toSigned(r[123]);
  state.unit_state[10].status = toSigned(r[124]);
  state.unit_state[10].target = toSigned(r[125]);
  // --- batch_state ---
  if (!state.batch_state) state.batch_state = {};
  state.batch_state[1] = {};
  state.batch_state[1].batch_code = toSigned(r[126]);
  state.batch_state[1].batch_state = toSigned(r[127]);
  state.batch_state[1].batch_program = toSigned(r[128]);
  state.batch_state[1].batch_stage = toSigned(r[129]);
  state.batch_state[1].batch_min_time = toSigned(r[130]);
  state.batch_state[1].batch_max_time = toSigned(r[131]);
  state.batch_state[1].batch_cal_time = toSigned(r[132]);
  state.batch_state[2] = {};
  state.batch_state[2].batch_code = toSigned(r[133]);
  state.batch_state[2].batch_state = toSigned(r[134]);
  state.batch_state[2].batch_program = toSigned(r[135]);
  state.batch_state[2].batch_stage = toSigned(r[136]);
  state.batch_state[2].batch_min_time = toSigned(r[137]);
  state.batch_state[2].batch_max_time = toSigned(r[138]);
  state.batch_state[2].batch_cal_time = toSigned(r[139]);
  state.batch_state[3] = {};
  state.batch_state[3].batch_code = toSigned(r[140]);
  state.batch_state[3].batch_state = toSigned(r[141]);
  state.batch_state[3].batch_program = toSigned(r[142]);
  state.batch_state[3].batch_stage = toSigned(r[143]);
  state.batch_state[3].batch_min_time = toSigned(r[144]);
  state.batch_state[3].batch_max_time = toSigned(r[145]);
  state.batch_state[3].batch_cal_time = toSigned(r[146]);
  state.batch_state[4] = {};
  state.batch_state[4].batch_code = toSigned(r[147]);
  state.batch_state[4].batch_state = toSigned(r[148]);
  state.batch_state[4].batch_program = toSigned(r[149]);
  state.batch_state[4].batch_stage = toSigned(r[150]);
  state.batch_state[4].batch_min_time = toSigned(r[151]);
  state.batch_state[4].batch_max_time = toSigned(r[152]);
  state.batch_state[4].batch_cal_time = toSigned(r[153]);
  state.batch_state[5] = {};
  state.batch_state[5].batch_code = toSigned(r[154]);
  state.batch_state[5].batch_state = toSigned(r[155]);
  state.batch_state[5].batch_program = toSigned(r[156]);
  state.batch_state[5].batch_stage = toSigned(r[157]);
  state.batch_state[5].batch_min_time = toSigned(r[158]);
  state.batch_state[5].batch_max_time = toSigned(r[159]);
  state.batch_state[5].batch_cal_time = toSigned(r[160]);
  state.batch_state[6] = {};
  state.batch_state[6].batch_code = toSigned(r[161]);
  state.batch_state[6].batch_state = toSigned(r[162]);
  state.batch_state[6].batch_program = toSigned(r[163]);
  state.batch_state[6].batch_stage = toSigned(r[164]);
  state.batch_state[6].batch_min_time = toSigned(r[165]);
  state.batch_state[6].batch_max_time = toSigned(r[166]);
  state.batch_state[6].batch_cal_time = toSigned(r[167]);
  state.batch_state[7] = {};
  state.batch_state[7].batch_code = toSigned(r[168]);
  state.batch_state[7].batch_state = toSigned(r[169]);
  state.batch_state[7].batch_program = toSigned(r[170]);
  state.batch_state[7].batch_stage = toSigned(r[171]);
  state.batch_state[7].batch_min_time = toSigned(r[172]);
  state.batch_state[7].batch_max_time = toSigned(r[173]);
  state.batch_state[7].batch_cal_time = toSigned(r[174]);
  state.batch_state[8] = {};
  state.batch_state[8].batch_code = toSigned(r[175]);
  state.batch_state[8].batch_state = toSigned(r[176]);
  state.batch_state[8].batch_program = toSigned(r[177]);
  state.batch_state[8].batch_stage = toSigned(r[178]);
  state.batch_state[8].batch_min_time = toSigned(r[179]);
  state.batch_state[8].batch_max_time = toSigned(r[180]);
  state.batch_state[8].batch_cal_time = toSigned(r[181]);
  state.batch_state[9] = {};
  state.batch_state[9].batch_code = toSigned(r[182]);
  state.batch_state[9].batch_state = toSigned(r[183]);
  state.batch_state[9].batch_program = toSigned(r[184]);
  state.batch_state[9].batch_stage = toSigned(r[185]);
  state.batch_state[9].batch_min_time = toSigned(r[186]);
  state.batch_state[9].batch_max_time = toSigned(r[187]);
  state.batch_state[9].batch_cal_time = toSigned(r[188]);
  state.batch_state[10] = {};
  state.batch_state[10].batch_code = toSigned(r[189]);
  state.batch_state[10].batch_state = toSigned(r[190]);
  state.batch_state[10].batch_program = toSigned(r[191]);
  state.batch_state[10].batch_stage = toSigned(r[192]);
  state.batch_state[10].batch_min_time = toSigned(r[193]);
  state.batch_state[10].batch_max_time = toSigned(r[194]);
  state.batch_state[10].batch_cal_time = toSigned(r[195]);
  // --- calibration ---
  state.calibration = {};
  state.calibration.cal_step = toSigned(r[196]);
  state.calibration.cal_tid = toSigned(r[197]);
  // --- calibration_results ---
  if (!state.calibration_results) state.calibration_results = {};
  state.calibration_results[1] = {};
  state.calibration_results[1].lift_wet = toSigned(r[198]) * 0.1;
  state.calibration_results[1].sink_wet = toSigned(r[199]) * 0.1;
  state.calibration_results[1].lift_dry = toSigned(r[200]) * 0.1;
  state.calibration_results[1].sink_dry = toSigned(r[201]) * 0.1;
  state.calibration_results[1].x_acc = toSigned(r[202]) * 0.1;
  state.calibration_results[1].x_dec = toSigned(r[203]) * 0.1;
  state.calibration_results[1].x_max = toSigned(r[204]);
  state.calibration_results[2] = {};
  state.calibration_results[2].lift_wet = toSigned(r[205]) * 0.1;
  state.calibration_results[2].sink_wet = toSigned(r[206]) * 0.1;
  state.calibration_results[2].lift_dry = toSigned(r[207]) * 0.1;
  state.calibration_results[2].sink_dry = toSigned(r[208]) * 0.1;
  state.calibration_results[2].x_acc = toSigned(r[209]) * 0.1;
  state.calibration_results[2].x_dec = toSigned(r[210]) * 0.1;
  state.calibration_results[2].x_max = toSigned(r[211]);
  state.calibration_results[3] = {};
  state.calibration_results[3].lift_wet = toSigned(r[212]) * 0.1;
  state.calibration_results[3].sink_wet = toSigned(r[213]) * 0.1;
  state.calibration_results[3].lift_dry = toSigned(r[214]) * 0.1;
  state.calibration_results[3].sink_dry = toSigned(r[215]) * 0.1;
  state.calibration_results[3].x_acc = toSigned(r[216]) * 0.1;
  state.calibration_results[3].x_dec = toSigned(r[217]) * 0.1;
  state.calibration_results[3].x_max = toSigned(r[218]);
  // --- transporter_config ---
  if (!state.transporter_config) state.transporter_config = {};
  state.transporter_config[1] = {};
  state.transporter_config[1].x_min_limit = toSigned(r[219]);
  state.transporter_config[1].x_max_limit = toSigned(r[220]);
  state.transporter_config[1].y_min_limit = toSigned(r[221]);
  state.transporter_config[1].y_max_limit = toSigned(r[222]);
  state.transporter_config[1].x_avoid_mm = toSigned(r[223]);
  state.transporter_config[1].y_avoid_mm = toSigned(r[224]);
  state.transporter_config[1].phys_x_accel = toSigned(r[225]) * 0.01;
  state.transporter_config[1].phys_x_decel = toSigned(r[226]) * 0.01;
  state.transporter_config[1].phys_x_max = toSigned(r[227]);
  state.transporter_config[1].phys_z_total = toSigned(r[228]);
  state.transporter_config[1].phys_z_sdry = toSigned(r[229]);
  state.transporter_config[1].phys_z_swet = toSigned(r[230]);
  state.transporter_config[1].phys_z_send = toSigned(r[231]);
  state.transporter_config[1].phys_z_slow = toSigned(r[232]);
  state.transporter_config[1].phys_z_fast = toSigned(r[233]);
  state.transporter_config[1].phys_drip = toSigned(r[234]) * 0.1;
  state.transporter_config[1].phys_avoid = toSigned(r[235]);
  state.transporter_config[1].ta1_min_lift = toSigned(r[236]);
  state.transporter_config[1].ta1_max_lift = toSigned(r[237]);
  state.transporter_config[1].ta1_min_sink = toSigned(r[238]);
  state.transporter_config[1].ta1_max_sink = toSigned(r[239]);
  state.transporter_config[1].ta2_min_lift = toSigned(r[240]);
  state.transporter_config[1].ta2_max_lift = toSigned(r[241]);
  state.transporter_config[1].ta2_min_sink = toSigned(r[242]);
  state.transporter_config[1].ta2_max_sink = toSigned(r[243]);
  state.transporter_config[1].ta3_min_lift = toSigned(r[244]);
  state.transporter_config[1].ta3_max_lift = toSigned(r[245]);
  state.transporter_config[1].ta3_min_sink = toSigned(r[246]);
  state.transporter_config[1].ta3_max_sink = toSigned(r[247]);
  state.transporter_config[2] = {};
  state.transporter_config[2].x_min_limit = toSigned(r[248]);
  state.transporter_config[2].x_max_limit = toSigned(r[249]);
  state.transporter_config[2].y_min_limit = toSigned(r[250]);
  state.transporter_config[2].y_max_limit = toSigned(r[251]);
  state.transporter_config[2].x_avoid_mm = toSigned(r[252]);
  state.transporter_config[2].y_avoid_mm = toSigned(r[253]);
  state.transporter_config[2].phys_x_accel = toSigned(r[254]) * 0.01;
  state.transporter_config[2].phys_x_decel = toSigned(r[255]) * 0.01;
  state.transporter_config[2].phys_x_max = toSigned(r[256]);
  state.transporter_config[2].phys_z_total = toSigned(r[257]);
  state.transporter_config[2].phys_z_sdry = toSigned(r[258]);
  state.transporter_config[2].phys_z_swet = toSigned(r[259]);
  state.transporter_config[2].phys_z_send = toSigned(r[260]);
  state.transporter_config[2].phys_z_slow = toSigned(r[261]);
  state.transporter_config[2].phys_z_fast = toSigned(r[262]);
  state.transporter_config[2].phys_drip = toSigned(r[263]) * 0.1;
  state.transporter_config[2].phys_avoid = toSigned(r[264]);
  state.transporter_config[2].ta1_min_lift = toSigned(r[265]);
  state.transporter_config[2].ta1_max_lift = toSigned(r[266]);
  state.transporter_config[2].ta1_min_sink = toSigned(r[267]);
  state.transporter_config[2].ta1_max_sink = toSigned(r[268]);
  state.transporter_config[2].ta2_min_lift = toSigned(r[269]);
  state.transporter_config[2].ta2_max_lift = toSigned(r[270]);
  state.transporter_config[2].ta2_min_sink = toSigned(r[271]);
  state.transporter_config[2].ta2_max_sink = toSigned(r[272]);
  state.transporter_config[2].ta3_min_lift = toSigned(r[273]);
  state.transporter_config[2].ta3_max_lift = toSigned(r[274]);
  state.transporter_config[2].ta3_min_sink = toSigned(r[275]);
  state.transporter_config[2].ta3_max_sink = toSigned(r[276]);
  state.transporter_config[3] = {};
  state.transporter_config[3].x_min_limit = toSigned(r[277]);
  state.transporter_config[3].x_max_limit = toSigned(r[278]);
  state.transporter_config[3].y_min_limit = toSigned(r[279]);
  state.transporter_config[3].y_max_limit = toSigned(r[280]);
  state.transporter_config[3].x_avoid_mm = toSigned(r[281]);
  state.transporter_config[3].y_avoid_mm = toSigned(r[282]);
  state.transporter_config[3].phys_x_accel = toSigned(r[283]) * 0.01;
  state.transporter_config[3].phys_x_decel = toSigned(r[284]) * 0.01;
  state.transporter_config[3].phys_x_max = toSigned(r[285]);
  state.transporter_config[3].phys_z_total = toSigned(r[286]);
  state.transporter_config[3].phys_z_sdry = toSigned(r[287]);
  state.transporter_config[3].phys_z_swet = toSigned(r[288]);
  state.transporter_config[3].phys_z_send = toSigned(r[289]);
  state.transporter_config[3].phys_z_slow = toSigned(r[290]);
  state.transporter_config[3].phys_z_fast = toSigned(r[291]);
  state.transporter_config[3].phys_drip = toSigned(r[292]) * 0.1;
  state.transporter_config[3].phys_avoid = toSigned(r[293]);
  state.transporter_config[3].ta1_min_lift = toSigned(r[294]);
  state.transporter_config[3].ta1_max_lift = toSigned(r[295]);
  state.transporter_config[3].ta1_min_sink = toSigned(r[296]);
  state.transporter_config[3].ta1_max_sink = toSigned(r[297]);
  state.transporter_config[3].ta2_min_lift = toSigned(r[298]);
  state.transporter_config[3].ta2_max_lift = toSigned(r[299]);
  state.transporter_config[3].ta2_min_sink = toSigned(r[300]);
  state.transporter_config[3].ta2_max_sink = toSigned(r[301]);
  state.transporter_config[3].ta3_min_lift = toSigned(r[302]);
  state.transporter_config[3].ta3_max_lift = toSigned(r[303]);
  state.transporter_config[3].ta3_min_sink = toSigned(r[304]);
  state.transporter_config[3].ta3_max_sink = toSigned(r[305]);
  state.avoid_status[101] = {};
  state.avoid_status[101].avoid_val = toSigned(r[306]);
  state.avoid_status[102] = {};
  state.avoid_status[102].avoid_val = toSigned(r[307]);
  state.avoid_status[103] = {};
  state.avoid_status[103].avoid_val = toSigned(r[308]);
  state.avoid_status[104] = {};
  state.avoid_status[104].avoid_val = toSigned(r[309]);
  state.avoid_status[105] = {};
  state.avoid_status[105].avoid_val = toSigned(r[310]);
  state.avoid_status[106] = {};
  state.avoid_status[106].avoid_val = toSigned(r[311]);
  state.avoid_status[107] = {};
  state.avoid_status[107].avoid_val = toSigned(r[312]);
  state.avoid_status[108] = {};
  state.avoid_status[108].avoid_val = toSigned(r[313]);
  state.avoid_status[109] = {};
  state.avoid_status[109].avoid_val = toSigned(r[314]);
  state.avoid_status[110] = {};
  state.avoid_status[110].avoid_val = toSigned(r[315]);
  state.avoid_status[111] = {};
  state.avoid_status[111].avoid_val = toSigned(r[316]);
  state.avoid_status[112] = {};
  state.avoid_status[112].avoid_val = toSigned(r[317]);
  state.avoid_status[113] = {};
  state.avoid_status[113].avoid_val = toSigned(r[318]);
  state.avoid_status[114] = {};
  state.avoid_status[114].avoid_val = toSigned(r[319]);
  state.avoid_status[115] = {};
  state.avoid_status[115].avoid_val = toSigned(r[320]);
  state.avoid_status[116] = {};
  state.avoid_status[116].avoid_val = toSigned(r[321]);
  state.avoid_status[117] = {};
  state.avoid_status[117].avoid_val = toSigned(r[322]);
  state.avoid_status[118] = {};
  state.avoid_status[118].avoid_val = toSigned(r[323]);
  state.avoid_status[119] = {};
  state.avoid_status[119].avoid_val = toSigned(r[324]);
  state.avoid_status[120] = {};
  state.avoid_status[120].avoid_val = toSigned(r[325]);
  state.avoid_status[121] = {};
  state.avoid_status[121].avoid_val = toSigned(r[326]);
  state.avoid_status[122] = {};
  state.avoid_status[122].avoid_val = toSigned(r[327]);
  state.avoid_status[123] = {};
  state.avoid_status[123].avoid_val = toSigned(r[328]);
  state.avoid_status[124] = {};
  state.avoid_status[124].avoid_val = toSigned(r[329]);
  state.avoid_status[125] = {};
  state.avoid_status[125].avoid_val = toSigned(r[330]);
  state.avoid_status[126] = {};
  state.avoid_status[126].avoid_val = toSigned(r[331]);
  state.avoid_status[127] = {};
  state.avoid_status[127].avoid_val = toSigned(r[332]);
  state.avoid_status[128] = {};
  state.avoid_status[128].avoid_val = toSigned(r[333]);
  state.avoid_status[129] = {};
  state.avoid_status[129].avoid_val = toSigned(r[334]);
  state.avoid_status[130] = {};
  state.avoid_status[130].avoid_val = toSigned(r[335]);
  // --- schedule_summary ---
  if (!state.schedule_summary) state.schedule_summary = {};
  state.schedule_summary[1] = {};
  state.schedule_summary[1].stage_count = toSigned(r[336]);
  state.schedule_summary[2] = {};
  state.schedule_summary[2].stage_count = toSigned(r[337]);
  state.schedule_summary[3] = {};
  state.schedule_summary[3].stage_count = toSigned(r[338]);
  state.schedule_summary[4] = {};
  state.schedule_summary[4].stage_count = toSigned(r[339]);
  state.schedule_summary[5] = {};
  state.schedule_summary[5].stage_count = toSigned(r[340]);
  state.schedule_summary[6] = {};
  state.schedule_summary[6].stage_count = toSigned(r[341]);
  state.schedule_summary[7] = {};
  state.schedule_summary[7].stage_count = toSigned(r[342]);
  state.schedule_summary[8] = {};
  state.schedule_summary[8].stage_count = toSigned(r[343]);
  state.schedule_summary[9] = {};
  state.schedule_summary[9].stage_count = toSigned(r[344]);
  state.schedule_summary[10] = {};
  state.schedule_summary[10].stage_count = toSigned(r[345]);
  // --- task_queue ---
  if (!state.task_queue) state.task_queue = {};
  state.task_queue[1] = {};
  state.task_queue[1].task_count = toSigned(r[346]);
  state.task_queue[1].q1_unit = toSigned(r[347]);
  state.task_queue[1].q1_stage = toSigned(r[348]);
  state.task_queue[1].q1_lift = toSigned(r[349]);
  state.task_queue[1].q1_sink = toSigned(r[350]);
  state.task_queue[1]._q1_start_hi = r[351];
  state.task_queue[1]._q1_start_lo = r[352];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[1].q1_start_time = ((state.task_queue[1]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_start_lo & 0xFFFF);
  state.task_queue[1]._q1_fin_hi = r[353];
  state.task_queue[1]._q1_fin_lo = r[354];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[1].q1_finish_time = ((state.task_queue[1]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_fin_lo & 0xFFFF);
  state.task_queue[1].q1_calc_time = toSigned(r[355]) * 0.1;
  state.task_queue[1].q1_min_time = toSigned(r[356]) * 0.1;
  state.task_queue[1].q1_max_time = toSigned(r[357]) * 0.1;
  state.task_queue[1].q2_unit = toSigned(r[358]);
  state.task_queue[1].q2_stage = toSigned(r[359]);
  state.task_queue[1].q2_lift = toSigned(r[360]);
  state.task_queue[1].q2_sink = toSigned(r[361]);
  state.task_queue[1]._q2_start_hi = r[362];
  state.task_queue[1]._q2_start_lo = r[363];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[1].q2_start_time = ((state.task_queue[1]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_start_lo & 0xFFFF);
  state.task_queue[1]._q2_fin_hi = r[364];
  state.task_queue[1]._q2_fin_lo = r[365];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[1].q2_finish_time = ((state.task_queue[1]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_fin_lo & 0xFFFF);
  state.task_queue[1].q2_calc_time = toSigned(r[366]) * 0.1;
  state.task_queue[1].q2_min_time = toSigned(r[367]) * 0.1;
  state.task_queue[1].q2_max_time = toSigned(r[368]) * 0.1;
  state.task_queue[1].q3_unit = toSigned(r[369]);
  state.task_queue[1].q3_stage = toSigned(r[370]);
  state.task_queue[1].q3_lift = toSigned(r[371]);
  state.task_queue[1].q3_sink = toSigned(r[372]);
  state.task_queue[1]._q3_start_hi = r[373];
  state.task_queue[1]._q3_start_lo = r[374];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[1].q3_start_time = ((state.task_queue[1]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_start_lo & 0xFFFF);
  state.task_queue[1]._q3_fin_hi = r[375];
  state.task_queue[1]._q3_fin_lo = r[376];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[1].q3_finish_time = ((state.task_queue[1]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_fin_lo & 0xFFFF);
  state.task_queue[1].q3_calc_time = toSigned(r[377]) * 0.1;
  state.task_queue[1].q3_min_time = toSigned(r[378]) * 0.1;
  state.task_queue[1].q3_max_time = toSigned(r[379]) * 0.1;
  state.task_queue[1].q4_unit = toSigned(r[380]);
  state.task_queue[1].q4_stage = toSigned(r[381]);
  state.task_queue[1].q4_lift = toSigned(r[382]);
  state.task_queue[1].q4_sink = toSigned(r[383]);
  state.task_queue[1]._q4_start_hi = r[384];
  state.task_queue[1]._q4_start_lo = r[385];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[1].q4_start_time = ((state.task_queue[1]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_start_lo & 0xFFFF);
  state.task_queue[1]._q4_fin_hi = r[386];
  state.task_queue[1]._q4_fin_lo = r[387];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[1].q4_finish_time = ((state.task_queue[1]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_fin_lo & 0xFFFF);
  state.task_queue[1].q4_calc_time = toSigned(r[388]) * 0.1;
  state.task_queue[1].q4_min_time = toSigned(r[389]) * 0.1;
  state.task_queue[1].q4_max_time = toSigned(r[390]) * 0.1;
  state.task_queue[1].q5_unit = toSigned(r[391]);
  state.task_queue[1].q5_stage = toSigned(r[392]);
  state.task_queue[1].q5_lift = toSigned(r[393]);
  state.task_queue[1].q5_sink = toSigned(r[394]);
  state.task_queue[1]._q5_start_hi = r[395];
  state.task_queue[1]._q5_start_lo = r[396];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[1].q5_start_time = ((state.task_queue[1]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_start_lo & 0xFFFF);
  state.task_queue[1]._q5_fin_hi = r[397];
  state.task_queue[1]._q5_fin_lo = r[398];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[1].q5_finish_time = ((state.task_queue[1]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_fin_lo & 0xFFFF);
  state.task_queue[1].q5_calc_time = toSigned(r[399]) * 0.1;
  state.task_queue[1].q5_min_time = toSigned(r[400]) * 0.1;
  state.task_queue[1].q5_max_time = toSigned(r[401]) * 0.1;
  state.task_queue[1].q6_unit = toSigned(r[402]);
  state.task_queue[1].q6_stage = toSigned(r[403]);
  state.task_queue[1].q6_lift = toSigned(r[404]);
  state.task_queue[1].q6_sink = toSigned(r[405]);
  state.task_queue[1]._q6_start_hi = r[406];
  state.task_queue[1]._q6_start_lo = r[407];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[1].q6_start_time = ((state.task_queue[1]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_start_lo & 0xFFFF);
  state.task_queue[1]._q6_fin_hi = r[408];
  state.task_queue[1]._q6_fin_lo = r[409];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[1].q6_finish_time = ((state.task_queue[1]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_fin_lo & 0xFFFF);
  state.task_queue[1].q6_calc_time = toSigned(r[410]) * 0.1;
  state.task_queue[1].q6_min_time = toSigned(r[411]) * 0.1;
  state.task_queue[1].q6_max_time = toSigned(r[412]) * 0.1;
  state.task_queue[1].q7_unit = toSigned(r[413]);
  state.task_queue[1].q7_stage = toSigned(r[414]);
  state.task_queue[1].q7_lift = toSigned(r[415]);
  state.task_queue[1].q7_sink = toSigned(r[416]);
  state.task_queue[1]._q7_start_hi = r[417];
  state.task_queue[1]._q7_start_lo = r[418];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[1].q7_start_time = ((state.task_queue[1]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_start_lo & 0xFFFF);
  state.task_queue[1]._q7_fin_hi = r[419];
  state.task_queue[1]._q7_fin_lo = r[420];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[1].q7_finish_time = ((state.task_queue[1]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_fin_lo & 0xFFFF);
  state.task_queue[1].q7_calc_time = toSigned(r[421]) * 0.1;
  state.task_queue[1].q7_min_time = toSigned(r[422]) * 0.1;
  state.task_queue[1].q7_max_time = toSigned(r[423]) * 0.1;
  state.task_queue[1].q8_unit = toSigned(r[424]);
  state.task_queue[1].q8_stage = toSigned(r[425]);
  state.task_queue[1].q8_lift = toSigned(r[426]);
  state.task_queue[1].q8_sink = toSigned(r[427]);
  state.task_queue[1]._q8_start_hi = r[428];
  state.task_queue[1]._q8_start_lo = r[429];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[1].q8_start_time = ((state.task_queue[1]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_start_lo & 0xFFFF);
  state.task_queue[1]._q8_fin_hi = r[430];
  state.task_queue[1]._q8_fin_lo = r[431];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[1].q8_finish_time = ((state.task_queue[1]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_fin_lo & 0xFFFF);
  state.task_queue[1].q8_calc_time = toSigned(r[432]) * 0.1;
  state.task_queue[1].q8_min_time = toSigned(r[433]) * 0.1;
  state.task_queue[1].q8_max_time = toSigned(r[434]) * 0.1;
  state.task_queue[1].q9_unit = toSigned(r[435]);
  state.task_queue[1].q9_stage = toSigned(r[436]);
  state.task_queue[1].q9_lift = toSigned(r[437]);
  state.task_queue[1].q9_sink = toSigned(r[438]);
  state.task_queue[1]._q9_start_hi = r[439];
  state.task_queue[1]._q9_start_lo = r[440];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[1].q9_start_time = ((state.task_queue[1]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_start_lo & 0xFFFF);
  state.task_queue[1]._q9_fin_hi = r[441];
  state.task_queue[1]._q9_fin_lo = r[442];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[1].q9_finish_time = ((state.task_queue[1]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_fin_lo & 0xFFFF);
  state.task_queue[1].q9_calc_time = toSigned(r[443]) * 0.1;
  state.task_queue[1].q9_min_time = toSigned(r[444]) * 0.1;
  state.task_queue[1].q9_max_time = toSigned(r[445]) * 0.1;
  state.task_queue[1].q10_unit = toSigned(r[446]);
  state.task_queue[1].q10_stage = toSigned(r[447]);
  state.task_queue[1].q10_lift = toSigned(r[448]);
  state.task_queue[1].q10_sink = toSigned(r[449]);
  state.task_queue[1]._q10_start_hi = r[450];
  state.task_queue[1]._q10_start_lo = r[451];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[1].q10_start_time = ((state.task_queue[1]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_start_lo & 0xFFFF);
  state.task_queue[1]._q10_fin_hi = r[452];
  state.task_queue[1]._q10_fin_lo = r[453];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[1].q10_finish_time = ((state.task_queue[1]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_fin_lo & 0xFFFF);
  state.task_queue[1].q10_calc_time = toSigned(r[454]) * 0.1;
  state.task_queue[1].q10_min_time = toSigned(r[455]) * 0.1;
  state.task_queue[1].q10_max_time = toSigned(r[456]) * 0.1;
  state.task_queue[2] = {};
  state.task_queue[2].task_count = toSigned(r[457]);
  state.task_queue[2].q1_unit = toSigned(r[458]);
  state.task_queue[2].q1_stage = toSigned(r[459]);
  state.task_queue[2].q1_lift = toSigned(r[460]);
  state.task_queue[2].q1_sink = toSigned(r[461]);
  state.task_queue[2]._q1_start_hi = r[462];
  state.task_queue[2]._q1_start_lo = r[463];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[2].q1_start_time = ((state.task_queue[2]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_start_lo & 0xFFFF);
  state.task_queue[2]._q1_fin_hi = r[464];
  state.task_queue[2]._q1_fin_lo = r[465];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[2].q1_finish_time = ((state.task_queue[2]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_fin_lo & 0xFFFF);
  state.task_queue[2].q1_calc_time = toSigned(r[466]) * 0.1;
  state.task_queue[2].q1_min_time = toSigned(r[467]) * 0.1;
  state.task_queue[2].q1_max_time = toSigned(r[468]) * 0.1;
  state.task_queue[2].q2_unit = toSigned(r[469]);
  state.task_queue[2].q2_stage = toSigned(r[470]);
  state.task_queue[2].q2_lift = toSigned(r[471]);
  state.task_queue[2].q2_sink = toSigned(r[472]);
  state.task_queue[2]._q2_start_hi = r[473];
  state.task_queue[2]._q2_start_lo = r[474];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[2].q2_start_time = ((state.task_queue[2]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_start_lo & 0xFFFF);
  state.task_queue[2]._q2_fin_hi = r[475];
  state.task_queue[2]._q2_fin_lo = r[476];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[2].q2_finish_time = ((state.task_queue[2]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_fin_lo & 0xFFFF);
  state.task_queue[2].q2_calc_time = toSigned(r[477]) * 0.1;
  state.task_queue[2].q2_min_time = toSigned(r[478]) * 0.1;
  state.task_queue[2].q2_max_time = toSigned(r[479]) * 0.1;
  state.task_queue[2].q3_unit = toSigned(r[480]);
  state.task_queue[2].q3_stage = toSigned(r[481]);
  state.task_queue[2].q3_lift = toSigned(r[482]);
  state.task_queue[2].q3_sink = toSigned(r[483]);
  state.task_queue[2]._q3_start_hi = r[484];
  state.task_queue[2]._q3_start_lo = r[485];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[2].q3_start_time = ((state.task_queue[2]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_start_lo & 0xFFFF);
  state.task_queue[2]._q3_fin_hi = r[486];
  state.task_queue[2]._q3_fin_lo = r[487];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[2].q3_finish_time = ((state.task_queue[2]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_fin_lo & 0xFFFF);
  state.task_queue[2].q3_calc_time = toSigned(r[488]) * 0.1;
  state.task_queue[2].q3_min_time = toSigned(r[489]) * 0.1;
  state.task_queue[2].q3_max_time = toSigned(r[490]) * 0.1;
  state.task_queue[2].q4_unit = toSigned(r[491]);
  state.task_queue[2].q4_stage = toSigned(r[492]);
  state.task_queue[2].q4_lift = toSigned(r[493]);
  state.task_queue[2].q4_sink = toSigned(r[494]);
  state.task_queue[2]._q4_start_hi = r[495];
  state.task_queue[2]._q4_start_lo = r[496];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[2].q4_start_time = ((state.task_queue[2]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_start_lo & 0xFFFF);
  state.task_queue[2]._q4_fin_hi = r[497];
  state.task_queue[2]._q4_fin_lo = r[498];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[2].q4_finish_time = ((state.task_queue[2]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_fin_lo & 0xFFFF);
  state.task_queue[2].q4_calc_time = toSigned(r[499]) * 0.1;
  state.task_queue[2].q4_min_time = toSigned(r[500]) * 0.1;
  state.task_queue[2].q4_max_time = toSigned(r[501]) * 0.1;
  state.task_queue[2].q5_unit = toSigned(r[502]);
  state.task_queue[2].q5_stage = toSigned(r[503]);
  state.task_queue[2].q5_lift = toSigned(r[504]);
  state.task_queue[2].q5_sink = toSigned(r[505]);
  state.task_queue[2]._q5_start_hi = r[506];
  state.task_queue[2]._q5_start_lo = r[507];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[2].q5_start_time = ((state.task_queue[2]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_start_lo & 0xFFFF);
  state.task_queue[2]._q5_fin_hi = r[508];
  state.task_queue[2]._q5_fin_lo = r[509];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[2].q5_finish_time = ((state.task_queue[2]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_fin_lo & 0xFFFF);
  state.task_queue[2].q5_calc_time = toSigned(r[510]) * 0.1;
  state.task_queue[2].q5_min_time = toSigned(r[511]) * 0.1;
  state.task_queue[2].q5_max_time = toSigned(r[512]) * 0.1;
  state.task_queue[2].q6_unit = toSigned(r[513]);
  state.task_queue[2].q6_stage = toSigned(r[514]);
  state.task_queue[2].q6_lift = toSigned(r[515]);
  state.task_queue[2].q6_sink = toSigned(r[516]);
  state.task_queue[2]._q6_start_hi = r[517];
  state.task_queue[2]._q6_start_lo = r[518];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[2].q6_start_time = ((state.task_queue[2]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_start_lo & 0xFFFF);
  state.task_queue[2]._q6_fin_hi = r[519];
  state.task_queue[2]._q6_fin_lo = r[520];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[2].q6_finish_time = ((state.task_queue[2]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_fin_lo & 0xFFFF);
  state.task_queue[2].q6_calc_time = toSigned(r[521]) * 0.1;
  state.task_queue[2].q6_min_time = toSigned(r[522]) * 0.1;
  state.task_queue[2].q6_max_time = toSigned(r[523]) * 0.1;
  state.task_queue[2].q7_unit = toSigned(r[524]);
  state.task_queue[2].q7_stage = toSigned(r[525]);
  state.task_queue[2].q7_lift = toSigned(r[526]);
  state.task_queue[2].q7_sink = toSigned(r[527]);
  state.task_queue[2]._q7_start_hi = r[528];
  state.task_queue[2]._q7_start_lo = r[529];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[2].q7_start_time = ((state.task_queue[2]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_start_lo & 0xFFFF);
  state.task_queue[2]._q7_fin_hi = r[530];
  state.task_queue[2]._q7_fin_lo = r[531];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[2].q7_finish_time = ((state.task_queue[2]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_fin_lo & 0xFFFF);
  state.task_queue[2].q7_calc_time = toSigned(r[532]) * 0.1;
  state.task_queue[2].q7_min_time = toSigned(r[533]) * 0.1;
  state.task_queue[2].q7_max_time = toSigned(r[534]) * 0.1;
  state.task_queue[2].q8_unit = toSigned(r[535]);
  state.task_queue[2].q8_stage = toSigned(r[536]);
  state.task_queue[2].q8_lift = toSigned(r[537]);
  state.task_queue[2].q8_sink = toSigned(r[538]);
  state.task_queue[2]._q8_start_hi = r[539];
  state.task_queue[2]._q8_start_lo = r[540];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[2].q8_start_time = ((state.task_queue[2]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_start_lo & 0xFFFF);
  state.task_queue[2]._q8_fin_hi = r[541];
  state.task_queue[2]._q8_fin_lo = r[542];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[2].q8_finish_time = ((state.task_queue[2]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_fin_lo & 0xFFFF);
  state.task_queue[2].q8_calc_time = toSigned(r[543]) * 0.1;
  state.task_queue[2].q8_min_time = toSigned(r[544]) * 0.1;
  state.task_queue[2].q8_max_time = toSigned(r[545]) * 0.1;
  state.task_queue[2].q9_unit = toSigned(r[546]);
  state.task_queue[2].q9_stage = toSigned(r[547]);
  state.task_queue[2].q9_lift = toSigned(r[548]);
  state.task_queue[2].q9_sink = toSigned(r[549]);
  state.task_queue[2]._q9_start_hi = r[550];
  state.task_queue[2]._q9_start_lo = r[551];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[2].q9_start_time = ((state.task_queue[2]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_start_lo & 0xFFFF);
  state.task_queue[2]._q9_fin_hi = r[552];
  state.task_queue[2]._q9_fin_lo = r[553];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[2].q9_finish_time = ((state.task_queue[2]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_fin_lo & 0xFFFF);
  state.task_queue[2].q9_calc_time = toSigned(r[554]) * 0.1;
  state.task_queue[2].q9_min_time = toSigned(r[555]) * 0.1;
  state.task_queue[2].q9_max_time = toSigned(r[556]) * 0.1;
  state.task_queue[2].q10_unit = toSigned(r[557]);
  state.task_queue[2].q10_stage = toSigned(r[558]);
  state.task_queue[2].q10_lift = toSigned(r[559]);
  state.task_queue[2].q10_sink = toSigned(r[560]);
  state.task_queue[2]._q10_start_hi = r[561];
  state.task_queue[2]._q10_start_lo = r[562];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[2].q10_start_time = ((state.task_queue[2]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_start_lo & 0xFFFF);
  state.task_queue[2]._q10_fin_hi = r[563];
  state.task_queue[2]._q10_fin_lo = r[564];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[2].q10_finish_time = ((state.task_queue[2]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_fin_lo & 0xFFFF);
  state.task_queue[2].q10_calc_time = toSigned(r[565]) * 0.1;
  state.task_queue[2].q10_min_time = toSigned(r[566]) * 0.1;
  state.task_queue[2].q10_max_time = toSigned(r[567]) * 0.1;
  state.task_queue[3] = {};
  state.task_queue[3].task_count = toSigned(r[568]);
  state.task_queue[3].q1_unit = toSigned(r[569]);
  state.task_queue[3].q1_stage = toSigned(r[570]);
  state.task_queue[3].q1_lift = toSigned(r[571]);
  state.task_queue[3].q1_sink = toSigned(r[572]);
  state.task_queue[3]._q1_start_hi = r[573];
  state.task_queue[3]._q1_start_lo = r[574];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[3].q1_start_time = ((state.task_queue[3]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_start_lo & 0xFFFF);
  state.task_queue[3]._q1_fin_hi = r[575];
  state.task_queue[3]._q1_fin_lo = r[576];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[3].q1_finish_time = ((state.task_queue[3]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_fin_lo & 0xFFFF);
  state.task_queue[3].q1_calc_time = toSigned(r[577]) * 0.1;
  state.task_queue[3].q1_min_time = toSigned(r[578]) * 0.1;
  state.task_queue[3].q1_max_time = toSigned(r[579]) * 0.1;
  state.task_queue[3].q2_unit = toSigned(r[580]);
  state.task_queue[3].q2_stage = toSigned(r[581]);
  state.task_queue[3].q2_lift = toSigned(r[582]);
  state.task_queue[3].q2_sink = toSigned(r[583]);
  state.task_queue[3]._q2_start_hi = r[584];
  state.task_queue[3]._q2_start_lo = r[585];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[3].q2_start_time = ((state.task_queue[3]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_start_lo & 0xFFFF);
  state.task_queue[3]._q2_fin_hi = r[586];
  state.task_queue[3]._q2_fin_lo = r[587];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[3].q2_finish_time = ((state.task_queue[3]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_fin_lo & 0xFFFF);
  state.task_queue[3].q2_calc_time = toSigned(r[588]) * 0.1;
  state.task_queue[3].q2_min_time = toSigned(r[589]) * 0.1;
  state.task_queue[3].q2_max_time = toSigned(r[590]) * 0.1;
  state.task_queue[3].q3_unit = toSigned(r[591]);
  state.task_queue[3].q3_stage = toSigned(r[592]);
  state.task_queue[3].q3_lift = toSigned(r[593]);
  state.task_queue[3].q3_sink = toSigned(r[594]);
  state.task_queue[3]._q3_start_hi = r[595];
  state.task_queue[3]._q3_start_lo = r[596];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[3].q3_start_time = ((state.task_queue[3]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_start_lo & 0xFFFF);
  state.task_queue[3]._q3_fin_hi = r[597];
  state.task_queue[3]._q3_fin_lo = r[598];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[3].q3_finish_time = ((state.task_queue[3]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_fin_lo & 0xFFFF);
  state.task_queue[3].q3_calc_time = toSigned(r[599]) * 0.1;
  state.task_queue[3].q3_min_time = toSigned(r[600]) * 0.1;
  state.task_queue[3].q3_max_time = toSigned(r[601]) * 0.1;
  state.task_queue[3].q4_unit = toSigned(r[602]);
  state.task_queue[3].q4_stage = toSigned(r[603]);
  state.task_queue[3].q4_lift = toSigned(r[604]);
  state.task_queue[3].q4_sink = toSigned(r[605]);
  state.task_queue[3]._q4_start_hi = r[606];
  state.task_queue[3]._q4_start_lo = r[607];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[3].q4_start_time = ((state.task_queue[3]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_start_lo & 0xFFFF);
  state.task_queue[3]._q4_fin_hi = r[608];
  state.task_queue[3]._q4_fin_lo = r[609];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[3].q4_finish_time = ((state.task_queue[3]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_fin_lo & 0xFFFF);
  state.task_queue[3].q4_calc_time = toSigned(r[610]) * 0.1;
  state.task_queue[3].q4_min_time = toSigned(r[611]) * 0.1;
  state.task_queue[3].q4_max_time = toSigned(r[612]) * 0.1;
  state.task_queue[3].q5_unit = toSigned(r[613]);
  state.task_queue[3].q5_stage = toSigned(r[614]);
  state.task_queue[3].q5_lift = toSigned(r[615]);
  state.task_queue[3].q5_sink = toSigned(r[616]);
  state.task_queue[3]._q5_start_hi = r[617];
  state.task_queue[3]._q5_start_lo = r[618];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[3].q5_start_time = ((state.task_queue[3]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_start_lo & 0xFFFF);
  state.task_queue[3]._q5_fin_hi = r[619];
  state.task_queue[3]._q5_fin_lo = r[620];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[3].q5_finish_time = ((state.task_queue[3]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_fin_lo & 0xFFFF);
  state.task_queue[3].q5_calc_time = toSigned(r[621]) * 0.1;
  state.task_queue[3].q5_min_time = toSigned(r[622]) * 0.1;
  state.task_queue[3].q5_max_time = toSigned(r[623]) * 0.1;
  state.task_queue[3].q6_unit = toSigned(r[624]);
  state.task_queue[3].q6_stage = toSigned(r[625]);
  state.task_queue[3].q6_lift = toSigned(r[626]);
  state.task_queue[3].q6_sink = toSigned(r[627]);
  state.task_queue[3]._q6_start_hi = r[628];
  state.task_queue[3]._q6_start_lo = r[629];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[3].q6_start_time = ((state.task_queue[3]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_start_lo & 0xFFFF);
  state.task_queue[3]._q6_fin_hi = r[630];
  state.task_queue[3]._q6_fin_lo = r[631];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[3].q6_finish_time = ((state.task_queue[3]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_fin_lo & 0xFFFF);
  state.task_queue[3].q6_calc_time = toSigned(r[632]) * 0.1;
  state.task_queue[3].q6_min_time = toSigned(r[633]) * 0.1;
  state.task_queue[3].q6_max_time = toSigned(r[634]) * 0.1;
  state.task_queue[3].q7_unit = toSigned(r[635]);
  state.task_queue[3].q7_stage = toSigned(r[636]);
  state.task_queue[3].q7_lift = toSigned(r[637]);
  state.task_queue[3].q7_sink = toSigned(r[638]);
  state.task_queue[3]._q7_start_hi = r[639];
  state.task_queue[3]._q7_start_lo = r[640];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[3].q7_start_time = ((state.task_queue[3]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_start_lo & 0xFFFF);
  state.task_queue[3]._q7_fin_hi = r[641];
  state.task_queue[3]._q7_fin_lo = r[642];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[3].q7_finish_time = ((state.task_queue[3]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_fin_lo & 0xFFFF);
  state.task_queue[3].q7_calc_time = toSigned(r[643]) * 0.1;
  state.task_queue[3].q7_min_time = toSigned(r[644]) * 0.1;
  state.task_queue[3].q7_max_time = toSigned(r[645]) * 0.1;
  state.task_queue[3].q8_unit = toSigned(r[646]);
  state.task_queue[3].q8_stage = toSigned(r[647]);
  state.task_queue[3].q8_lift = toSigned(r[648]);
  state.task_queue[3].q8_sink = toSigned(r[649]);
  state.task_queue[3]._q8_start_hi = r[650];
  state.task_queue[3]._q8_start_lo = r[651];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[3].q8_start_time = ((state.task_queue[3]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_start_lo & 0xFFFF);
  state.task_queue[3]._q8_fin_hi = r[652];
  state.task_queue[3]._q8_fin_lo = r[653];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[3].q8_finish_time = ((state.task_queue[3]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_fin_lo & 0xFFFF);
  state.task_queue[3].q8_calc_time = toSigned(r[654]) * 0.1;
  state.task_queue[3].q8_min_time = toSigned(r[655]) * 0.1;
  state.task_queue[3].q8_max_time = toSigned(r[656]) * 0.1;
  state.task_queue[3].q9_unit = toSigned(r[657]);
  state.task_queue[3].q9_stage = toSigned(r[658]);
  state.task_queue[3].q9_lift = toSigned(r[659]);
  state.task_queue[3].q9_sink = toSigned(r[660]);
  state.task_queue[3]._q9_start_hi = r[661];
  state.task_queue[3]._q9_start_lo = r[662];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[3].q9_start_time = ((state.task_queue[3]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_start_lo & 0xFFFF);
  state.task_queue[3]._q9_fin_hi = r[663];
  state.task_queue[3]._q9_fin_lo = r[664];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[3].q9_finish_time = ((state.task_queue[3]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_fin_lo & 0xFFFF);
  state.task_queue[3].q9_calc_time = toSigned(r[665]) * 0.1;
  state.task_queue[3].q9_min_time = toSigned(r[666]) * 0.1;
  state.task_queue[3].q9_max_time = toSigned(r[667]) * 0.1;
  state.task_queue[3].q10_unit = toSigned(r[668]);
  state.task_queue[3].q10_stage = toSigned(r[669]);
  state.task_queue[3].q10_lift = toSigned(r[670]);
  state.task_queue[3].q10_sink = toSigned(r[671]);
  state.task_queue[3]._q10_start_hi = r[672];
  state.task_queue[3]._q10_start_lo = r[673];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[3].q10_start_time = ((state.task_queue[3]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_start_lo & 0xFFFF);
  state.task_queue[3]._q10_fin_hi = r[674];
  state.task_queue[3]._q10_fin_lo = r[675];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[3].q10_finish_time = ((state.task_queue[3]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_fin_lo & 0xFFFF);
  state.task_queue[3].q10_calc_time = toSigned(r[676]) * 0.1;
  state.task_queue[3].q10_min_time = toSigned(r[677]) * 0.1;
  state.task_queue[3].q10_max_time = toSigned(r[678]) * 0.1;
  // --- dep_state ---
  state.dep_state = {};
  state.dep_state.dep_activated = toSigned(r[679]);
  state.dep_state.dep_stable = toSigned(r[680]);
  state.dep_state.dep_waiting_count = toSigned(r[681]);
  state.dep_state.dep_overlap_count = toSigned(r[682]);
  state.dep_state.dep_pending_valid = toSigned(r[683]);
  state.dep_state.dep_pending_unit = toSigned(r[684]);
  state.dep_state.dep_pending_stage = toSigned(r[685]);
  state.dep_state._dep_pend_time_hi = r[686];
  state.dep_state._dep_pend_time_lo = r[687];
  // Combined uint32: dep_pending_time = (hi << 16) | lo
  state.dep_state.dep_pending_time = ((state.dep_state._pend_time_hi & 0xFFFF) * 65536) + (state.dep_state._pend_time_lo & 0xFFFF);
  // --- dep_waiting ---
  if (!state.dep_waiting) state.dep_waiting = {};
  state.dep_waiting[1] = {};
  state.dep_waiting[1].waiting_unit = toSigned(r[688]);
  state.dep_waiting[2] = {};
  state.dep_waiting[2].waiting_unit = toSigned(r[689]);
  state.dep_waiting[3] = {};
  state.dep_waiting[3].waiting_unit = toSigned(r[690]);
  state.dep_waiting[4] = {};
  state.dep_waiting[4].waiting_unit = toSigned(r[691]);
  state.dep_waiting[5] = {};
  state.dep_waiting[5].waiting_unit = toSigned(r[692]);
  state.dep_overlap[101] = {};
  state.dep_overlap[101].overlap_flag = toSigned(r[693]);
  state.dep_overlap[102] = {};
  state.dep_overlap[102].overlap_flag = toSigned(r[694]);
  state.dep_overlap[103] = {};
  state.dep_overlap[103].overlap_flag = toSigned(r[695]);
  state.dep_overlap[104] = {};
  state.dep_overlap[104].overlap_flag = toSigned(r[696]);
  state.dep_overlap[105] = {};
  state.dep_overlap[105].overlap_flag = toSigned(r[697]);
  state.dep_overlap[106] = {};
  state.dep_overlap[106].overlap_flag = toSigned(r[698]);
  state.dep_overlap[107] = {};
  state.dep_overlap[107].overlap_flag = toSigned(r[699]);
  state.dep_overlap[108] = {};
  state.dep_overlap[108].overlap_flag = toSigned(r[700]);
  state.dep_overlap[109] = {};
  state.dep_overlap[109].overlap_flag = toSigned(r[701]);
  state.dep_overlap[110] = {};
  state.dep_overlap[110].overlap_flag = toSigned(r[702]);
  state.dep_overlap[111] = {};
  state.dep_overlap[111].overlap_flag = toSigned(r[703]);
  state.dep_overlap[112] = {};
  state.dep_overlap[112].overlap_flag = toSigned(r[704]);
  state.dep_overlap[113] = {};
  state.dep_overlap[113].overlap_flag = toSigned(r[705]);
  state.dep_overlap[114] = {};
  state.dep_overlap[114].overlap_flag = toSigned(r[706]);
  state.dep_overlap[115] = {};
  state.dep_overlap[115].overlap_flag = toSigned(r[707]);
  state.dep_overlap[116] = {};
  state.dep_overlap[116].overlap_flag = toSigned(r[708]);
  state.dep_overlap[117] = {};
  state.dep_overlap[117].overlap_flag = toSigned(r[709]);
  state.dep_overlap[118] = {};
  state.dep_overlap[118].overlap_flag = toSigned(r[710]);
  state.dep_overlap[119] = {};
  state.dep_overlap[119].overlap_flag = toSigned(r[711]);
  state.dep_overlap[120] = {};
  state.dep_overlap[120].overlap_flag = toSigned(r[712]);
  state.dep_overlap[121] = {};
  state.dep_overlap[121].overlap_flag = toSigned(r[713]);
  state.dep_overlap[122] = {};
  state.dep_overlap[122].overlap_flag = toSigned(r[714]);
  state.dep_overlap[123] = {};
  state.dep_overlap[123].overlap_flag = toSigned(r[715]);
  state.dep_overlap[124] = {};
  state.dep_overlap[124].overlap_flag = toSigned(r[716]);
  state.dep_overlap[125] = {};
  state.dep_overlap[125].overlap_flag = toSigned(r[717]);
  state.dep_overlap[126] = {};
  state.dep_overlap[126].overlap_flag = toSigned(r[718]);
  state.dep_overlap[127] = {};
  state.dep_overlap[127].overlap_flag = toSigned(r[719]);
  state.dep_overlap[128] = {};
  state.dep_overlap[128].overlap_flag = toSigned(r[720]);
  state.dep_overlap[129] = {};
  state.dep_overlap[129].overlap_flag = toSigned(r[721]);
  state.dep_overlap[130] = {};
  state.dep_overlap[130].overlap_flag = toSigned(r[722]);
  // --- event_out ---
  state.event_out = {};
  state.event_out.evt_count = toSigned(r[767]);
  state.event_out.evt_seq = toSigned(r[768]);
  state.event_out.evt_type = toSigned(r[769]);
  state.event_out.evt_ts_hi = toSigned(r[770]);
  state.event_out.evt_ts_lo = toSigned(r[771]);
  state.event_out.evt_f1 = toSigned(r[772]);
  state.event_out.evt_f2 = toSigned(r[773]);
  state.event_out.evt_f3 = toSigned(r[774]);
  state.event_out.evt_f4 = toSigned(r[775]);
  state.event_out.evt_f5 = toSigned(r[776]);
  state.event_out.evt_f6 = toSigned(r[777]);
  state.event_out.evt_f7 = toSigned(r[778]);
  state.event_out.evt_f8 = toSigned(r[779]);
  state.event_out.evt_f9 = toSigned(r[780]);
  state.event_out.evt_f10 = toSigned(r[781]);
  state.event_out.evt_f11 = toSigned(r[782]);
  state.event_out.evt_f12 = toSigned(r[783]);

  return state;
}

/**
 * Get the QW address for an input register by api name.
 * @param {string} blockName
 * @param {string} apiName
 * @param {number} [instance] - For repeat blocks
 * @returns {number|null} QW address
 */
function getInputAddress(blockName, apiName, instance) {
  const key = instance ? `iw_${blockName.replace('_write','')}_t${instance}_${apiName}` : null;
  // lookup table
  const lookup = {
    'iw_cmd_t1_start': 723,
    'iw_cmd_t1_lift': 724,
    'iw_cmd_t1_sink': 725,
    'iw_cmd_t2_start': 726,
    'iw_cmd_t2_lift': 727,
    'iw_cmd_t2_sink': 728,
    'iw_cfg_seq': 729,
    'iw_cfg_cmd': 730,
    'iw_cfg_param': 731,
    'iw_cfg_d0': 732,
    'iw_cfg_d1': 733,
    'iw_cfg_d2': 734,
    'iw_cfg_d3': 735,
    'iw_cfg_d4': 736,
    'iw_cfg_d5': 737,
    'iw_cfg_d6': 738,
    'iw_cfg_d7': 739,
    'iw_unit_seq': 740,
    'iw_unit_id': 741,
    'iw_unit_loc': 742,
    'iw_unit_status': 743,
    'iw_unit_target': 744,
    'iw_batch_seq': 745,
    'iw_batch_unit': 746,
    'iw_batch_code': 747,
    'iw_batch_state': 748,
    'iw_batch_prog_id': 749,
    'iw_prog_seq': 750,
    'iw_prog_unit': 751,
    'iw_prog_stage': 752,
    'iw_prog_s1': 753,
    'iw_prog_s2': 754,
    'iw_prog_s3': 755,
    'iw_prog_s4': 756,
    'iw_prog_s5': 757,
    'iw_prog_min_time': 758,
    'iw_prog_max_time': 759,
    'iw_prog_cal_time': 760,
    'iw_avoid_seq': 761,
    'iw_avoid_station': 762,
    'iw_avoid_value': 763,
    'iw_production_queue': 764,
    'iw_time_hi': 765,
    'iw_time_lo': 766,
    'iw_event_ack_seq': 784,
  };
  // Try direct var name match
  const varName = `iw_${blockName}_${apiName}`;
  if (lookup[varName] !== undefined) return lookup[varName];
  // Try with instance label
  for (const [k, v] of Object.entries(lookup)) {
    if (k.includes(blockName) && k.endsWith('_' + apiName)) return v;
  }
  return null;
}

// Input block info (gateway → PLC)
const INPUT_BLOCKS = {
  cmd_transport: { start: 723, fields: ["cmd_start", "cmd_lift", "cmd_sink", "cmd_start", "cmd_lift", "cmd_sink"] },
  cfg: { start: 729, fields: ["cfg_seq", "cfg_cmd", "cfg_param", "cfg_d0", "cfg_d1", "cfg_d2", "cfg_d3", "cfg_d4", "cfg_d5", "cfg_d6", "cfg_d7"] },
  unit: { start: 740, fields: ["unit_seq", "unit_id", "unit_loc", "unit_status", "unit_target"] },
  batch: { start: 745, fields: ["batch_seq", "batch_unit", "batch_code", "batch_state", "batch_prog_id"] },
  prog: { start: 750, fields: ["prog_seq", "prog_unit", "prog_stage", "prog_s1", "prog_s2", "prog_s3", "prog_s4", "prog_s5", "prog_min_time", "prog_max_time", "prog_cal_time"] },
  avoid: { start: 761, fields: ["avoid_seq", "avoid_station", "avoid_value"] },
  production: { start: 764, fields: ["production_queue"] },
  time: { start: 765, fields: ["time_hi", "time_lo"] },
  event_ack: { start: 784, fields: ["evt_ack_seq"] },
};

module.exports = {
  TOTAL_REGISTERS,
  BLOCKS,
  REG,
  toSigned,
  decodeRegisters,
  getInputAddress,
  INPUT_BLOCKS,
};
