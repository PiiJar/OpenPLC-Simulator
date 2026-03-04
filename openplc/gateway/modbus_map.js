/**
 * Auto-generated Modbus register map — DO NOT EDIT
 * Generated from modbus_map.json (805 registers)
 */

const TOTAL_REGISTERS = 805;

// Block address ranges
const BLOCKS = {
  transporter_state: { start: 0, end: 38, count: 39, direction: 'out' },
  transporter_extended: { start: 39, end: 77, count: 39, direction: 'out' },
  twa_limits: { start: 78, end: 83, count: 6, direction: 'out' },
  plc_status: { start: 84, end: 95, count: 12, direction: 'out' },
  unit_state: { start: 96, end: 125, count: 30, direction: 'out' },
  batch_state: { start: 126, end: 215, count: 90, direction: 'out' },
  calibration: { start: 216, end: 217, count: 2, direction: 'out' },
  calibration_results: { start: 218, end: 238, count: 21, direction: 'out' },
  transporter_config: { start: 239, end: 325, count: 87, direction: 'out' },
  avoid_status: { start: 326, end: 355, count: 30, direction: 'out' },
  schedule_summary: { start: 356, end: 365, count: 10, direction: 'out' },
  task_queue: { start: 366, end: 698, count: 333, direction: 'out' },
  dep_state: { start: 699, end: 707, count: 9, direction: 'out' },
  dep_waiting: { start: 708, end: 712, count: 5, direction: 'out' },
  dep_overlap: { start: 713, end: 742, count: 30, direction: 'out' },
  cmd_transport: { start: 743, end: 748, count: 6, direction: 'in' },
  cfg: { start: 749, end: 759, count: 11, direction: 'in' },
  unit: { start: 760, end: 764, count: 5, direction: 'in' },
  batch: { start: 765, end: 769, count: 5, direction: 'in' },
  prog: { start: 770, end: 780, count: 11, direction: 'in' },
  avoid: { start: 781, end: 783, count: 3, direction: 'in' },
  production: { start: 784, end: 784, count: 1, direction: 'in' },
  time: { start: 785, end: 786, count: 2, direction: 'in' },
  event_out: { start: 787, end: 803, count: 17, direction: 'out' },
  event_ack: { start: 804, end: 804, count: 1, direction: 'in' },
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
  qw_b1_start_hi: 133,  // arrival time upper 16 bits
  qw_b1_start_lo: 134,  // arrival time lower 16 bits
  qw_b2_code: 135,  // numeric batch code
  qw_b2_state: 136,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b2_prog: 137,  // treatment program ID
  qw_b2_stage: 138,  // current stage number
  qw_b2_min_time: 139,  // current stage min time (seconds)
  qw_b2_max_time: 140,  // current stage max time (seconds)
  qw_b2_cal_time: 141,  // current stage calc time (seconds)
  qw_b2_start_hi: 142,  // arrival time upper 16 bits
  qw_b2_start_lo: 143,  // arrival time lower 16 bits
  qw_b3_code: 144,  // numeric batch code
  qw_b3_state: 145,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b3_prog: 146,  // treatment program ID
  qw_b3_stage: 147,  // current stage number
  qw_b3_min_time: 148,  // current stage min time (seconds)
  qw_b3_max_time: 149,  // current stage max time (seconds)
  qw_b3_cal_time: 150,  // current stage calc time (seconds)
  qw_b3_start_hi: 151,  // arrival time upper 16 bits
  qw_b3_start_lo: 152,  // arrival time lower 16 bits
  qw_b4_code: 153,  // numeric batch code
  qw_b4_state: 154,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b4_prog: 155,  // treatment program ID
  qw_b4_stage: 156,  // current stage number
  qw_b4_min_time: 157,  // current stage min time (seconds)
  qw_b4_max_time: 158,  // current stage max time (seconds)
  qw_b4_cal_time: 159,  // current stage calc time (seconds)
  qw_b4_start_hi: 160,  // arrival time upper 16 bits
  qw_b4_start_lo: 161,  // arrival time lower 16 bits
  qw_b5_code: 162,  // numeric batch code
  qw_b5_state: 163,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b5_prog: 164,  // treatment program ID
  qw_b5_stage: 165,  // current stage number
  qw_b5_min_time: 166,  // current stage min time (seconds)
  qw_b5_max_time: 167,  // current stage max time (seconds)
  qw_b5_cal_time: 168,  // current stage calc time (seconds)
  qw_b5_start_hi: 169,  // arrival time upper 16 bits
  qw_b5_start_lo: 170,  // arrival time lower 16 bits
  qw_b6_code: 171,  // numeric batch code
  qw_b6_state: 172,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b6_prog: 173,  // treatment program ID
  qw_b6_stage: 174,  // current stage number
  qw_b6_min_time: 175,  // current stage min time (seconds)
  qw_b6_max_time: 176,  // current stage max time (seconds)
  qw_b6_cal_time: 177,  // current stage calc time (seconds)
  qw_b6_start_hi: 178,  // arrival time upper 16 bits
  qw_b6_start_lo: 179,  // arrival time lower 16 bits
  qw_b7_code: 180,  // numeric batch code
  qw_b7_state: 181,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b7_prog: 182,  // treatment program ID
  qw_b7_stage: 183,  // current stage number
  qw_b7_min_time: 184,  // current stage min time (seconds)
  qw_b7_max_time: 185,  // current stage max time (seconds)
  qw_b7_cal_time: 186,  // current stage calc time (seconds)
  qw_b7_start_hi: 187,  // arrival time upper 16 bits
  qw_b7_start_lo: 188,  // arrival time lower 16 bits
  qw_b8_code: 189,  // numeric batch code
  qw_b8_state: 190,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b8_prog: 191,  // treatment program ID
  qw_b8_stage: 192,  // current stage number
  qw_b8_min_time: 193,  // current stage min time (seconds)
  qw_b8_max_time: 194,  // current stage max time (seconds)
  qw_b8_cal_time: 195,  // current stage calc time (seconds)
  qw_b8_start_hi: 196,  // arrival time upper 16 bits
  qw_b8_start_lo: 197,  // arrival time lower 16 bits
  qw_b9_code: 198,  // numeric batch code
  qw_b9_state: 199,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b9_prog: 200,  // treatment program ID
  qw_b9_stage: 201,  // current stage number
  qw_b9_min_time: 202,  // current stage min time (seconds)
  qw_b9_max_time: 203,  // current stage max time (seconds)
  qw_b9_cal_time: 204,  // current stage calc time (seconds)
  qw_b9_start_hi: 205,  // arrival time upper 16 bits
  qw_b9_start_lo: 206,  // arrival time lower 16 bits
  qw_b10_code: 207,  // numeric batch code
  qw_b10_state: 208,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b10_prog: 209,  // treatment program ID
  qw_b10_stage: 210,  // current stage number
  qw_b10_min_time: 211,  // current stage min time (seconds)
  qw_b10_max_time: 212,  // current stage max time (seconds)
  qw_b10_cal_time: 213,  // current stage calc time (seconds)
  qw_b10_start_hi: 214,  // arrival time upper 16 bits
  qw_b10_start_lo: 215,  // arrival time lower 16 bits
  qw_calibration_step: 216,  // 0=idle, 100=done, 999=complete
  qw_calibration_tid: 217,  // transporter being calibrated
  qw_cal_t1_lift_wet: 218,  // lift wet time ×10
  qw_cal_t1_sink_wet: 219,  // sink wet time ×10
  qw_cal_t1_lift_dry: 220,  // lift dry time ×10
  qw_cal_t1_sink_dry: 221,  // sink dry time ×10
  qw_cal_t1_x_acc: 222,  // X accel time ×10
  qw_cal_t1_x_dec: 223,  // X decel time ×10
  qw_cal_t1_x_max: 224,  // X max speed mm/s
  qw_cal_t2_lift_wet: 225,  // lift wet time ×10
  qw_cal_t2_sink_wet: 226,  // sink wet time ×10
  qw_cal_t2_lift_dry: 227,  // lift dry time ×10
  qw_cal_t2_sink_dry: 228,  // sink dry time ×10
  qw_cal_t2_x_acc: 229,  // X accel time ×10
  qw_cal_t2_x_dec: 230,  // X decel time ×10
  qw_cal_t2_x_max: 231,  // X max speed mm/s
  qw_cal_t3_lift_wet: 232,  // lift wet time ×10
  qw_cal_t3_sink_wet: 233,  // sink wet time ×10
  qw_cal_t3_lift_dry: 234,  // lift dry time ×10
  qw_cal_t3_sink_dry: 235,  // sink dry time ×10
  qw_cal_t3_x_acc: 236,  // X accel time ×10
  qw_cal_t3_x_dec: 237,  // X decel time ×10
  qw_cal_t3_x_max: 238,  // X max speed mm/s
  qw_cfg_t1_x_min: 239,  // config X min limit mm
  qw_cfg_t1_x_max: 240,  // config X max limit mm
  qw_cfg_t1_y_min: 241,  // config Y min limit mm
  qw_cfg_t1_y_max: 242,  // config Y max limit mm
  qw_cfg_t1_x_avoid: 243,  // X avoid distance mm
  qw_cfg_t1_y_avoid: 244,  // Y avoid distance mm
  qw_cfg_t1_ph_xacc_x100: 245,  // X accel ×100 (0.01s)
  qw_cfg_t1_ph_xdec_x100: 246,  // X decel ×100 (0.01s)
  qw_cfg_t1_ph_xmax: 247,  // X max speed mm/s
  qw_cfg_t1_ph_ztot: 248,  // Z total travel mm
  qw_cfg_t1_ph_zsdry: 249,  // Z slow zone dry mm
  qw_cfg_t1_ph_zswet: 250,  // Z slow zone wet mm
  qw_cfg_t1_ph_zsend: 251,  // Z slow zone end mm
  qw_cfg_t1_ph_zslow: 252,  // Z slow speed mm/s
  qw_cfg_t1_ph_zfast: 253,  // Z fast speed mm/s
  qw_cfg_t1_ph_drip_x10: 254,  // drip delay ×10 (0.1s)
  qw_cfg_t1_ph_avoid: 255,  // physics avoid mm
  qw_cfg_t1_ta1_min_lift: 256,  // task area 1 min lift station
  qw_cfg_t1_ta1_max_lift: 257,  // task area 1 max lift station
  qw_cfg_t1_ta1_min_sink: 258,  // task area 1 min sink station
  qw_cfg_t1_ta1_max_sink: 259,  // task area 1 max sink station
  qw_cfg_t1_ta2_min_lift: 260,  // task area 2 min lift station
  qw_cfg_t1_ta2_max_lift: 261,  // task area 2 max lift station
  qw_cfg_t1_ta2_min_sink: 262,  // task area 2 min sink station
  qw_cfg_t1_ta2_max_sink: 263,  // task area 2 max sink station
  qw_cfg_t1_ta3_min_lift: 264,  // task area 3 min lift station
  qw_cfg_t1_ta3_max_lift: 265,  // task area 3 max lift station
  qw_cfg_t1_ta3_min_sink: 266,  // task area 3 min sink station
  qw_cfg_t1_ta3_max_sink: 267,  // task area 3 max sink station
  qw_cfg_t2_x_min: 268,  // config X min limit mm
  qw_cfg_t2_x_max: 269,  // config X max limit mm
  qw_cfg_t2_y_min: 270,  // config Y min limit mm
  qw_cfg_t2_y_max: 271,  // config Y max limit mm
  qw_cfg_t2_x_avoid: 272,  // X avoid distance mm
  qw_cfg_t2_y_avoid: 273,  // Y avoid distance mm
  qw_cfg_t2_ph_xacc_x100: 274,  // X accel ×100 (0.01s)
  qw_cfg_t2_ph_xdec_x100: 275,  // X decel ×100 (0.01s)
  qw_cfg_t2_ph_xmax: 276,  // X max speed mm/s
  qw_cfg_t2_ph_ztot: 277,  // Z total travel mm
  qw_cfg_t2_ph_zsdry: 278,  // Z slow zone dry mm
  qw_cfg_t2_ph_zswet: 279,  // Z slow zone wet mm
  qw_cfg_t2_ph_zsend: 280,  // Z slow zone end mm
  qw_cfg_t2_ph_zslow: 281,  // Z slow speed mm/s
  qw_cfg_t2_ph_zfast: 282,  // Z fast speed mm/s
  qw_cfg_t2_ph_drip_x10: 283,  // drip delay ×10 (0.1s)
  qw_cfg_t2_ph_avoid: 284,  // physics avoid mm
  qw_cfg_t2_ta1_min_lift: 285,  // task area 1 min lift station
  qw_cfg_t2_ta1_max_lift: 286,  // task area 1 max lift station
  qw_cfg_t2_ta1_min_sink: 287,  // task area 1 min sink station
  qw_cfg_t2_ta1_max_sink: 288,  // task area 1 max sink station
  qw_cfg_t2_ta2_min_lift: 289,  // task area 2 min lift station
  qw_cfg_t2_ta2_max_lift: 290,  // task area 2 max lift station
  qw_cfg_t2_ta2_min_sink: 291,  // task area 2 min sink station
  qw_cfg_t2_ta2_max_sink: 292,  // task area 2 max sink station
  qw_cfg_t2_ta3_min_lift: 293,  // task area 3 min lift station
  qw_cfg_t2_ta3_max_lift: 294,  // task area 3 max lift station
  qw_cfg_t2_ta3_min_sink: 295,  // task area 3 min sink station
  qw_cfg_t2_ta3_max_sink: 296,  // task area 3 max sink station
  qw_cfg_t3_x_min: 297,  // config X min limit mm
  qw_cfg_t3_x_max: 298,  // config X max limit mm
  qw_cfg_t3_y_min: 299,  // config Y min limit mm
  qw_cfg_t3_y_max: 300,  // config Y max limit mm
  qw_cfg_t3_x_avoid: 301,  // X avoid distance mm
  qw_cfg_t3_y_avoid: 302,  // Y avoid distance mm
  qw_cfg_t3_ph_xacc_x100: 303,  // X accel ×100 (0.01s)
  qw_cfg_t3_ph_xdec_x100: 304,  // X decel ×100 (0.01s)
  qw_cfg_t3_ph_xmax: 305,  // X max speed mm/s
  qw_cfg_t3_ph_ztot: 306,  // Z total travel mm
  qw_cfg_t3_ph_zsdry: 307,  // Z slow zone dry mm
  qw_cfg_t3_ph_zswet: 308,  // Z slow zone wet mm
  qw_cfg_t3_ph_zsend: 309,  // Z slow zone end mm
  qw_cfg_t3_ph_zslow: 310,  // Z slow speed mm/s
  qw_cfg_t3_ph_zfast: 311,  // Z fast speed mm/s
  qw_cfg_t3_ph_drip_x10: 312,  // drip delay ×10 (0.1s)
  qw_cfg_t3_ph_avoid: 313,  // physics avoid mm
  qw_cfg_t3_ta1_min_lift: 314,  // task area 1 min lift station
  qw_cfg_t3_ta1_max_lift: 315,  // task area 1 max lift station
  qw_cfg_t3_ta1_min_sink: 316,  // task area 1 min sink station
  qw_cfg_t3_ta1_max_sink: 317,  // task area 1 max sink station
  qw_cfg_t3_ta2_min_lift: 318,  // task area 2 min lift station
  qw_cfg_t3_ta2_max_lift: 319,  // task area 2 max lift station
  qw_cfg_t3_ta2_min_sink: 320,  // task area 2 min sink station
  qw_cfg_t3_ta2_max_sink: 321,  // task area 2 max sink station
  qw_cfg_t3_ta3_min_lift: 322,  // task area 3 min lift station
  qw_cfg_t3_ta3_max_lift: 323,  // task area 3 max lift station
  qw_cfg_t3_ta3_min_sink: 324,  // task area 3 min sink station
  qw_cfg_t3_ta3_max_sink: 325,  // task area 3 max sink station
  qw_s101_val: 326,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s102_val: 327,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s103_val: 328,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s104_val: 329,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s105_val: 330,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s106_val: 331,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s107_val: 332,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s108_val: 333,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s109_val: 334,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s110_val: 335,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s111_val: 336,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s112_val: 337,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s113_val: 338,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s114_val: 339,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s115_val: 340,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s116_val: 341,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s117_val: 342,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s118_val: 343,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s119_val: 344,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s120_val: 345,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s121_val: 346,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s122_val: 347,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s123_val: 348,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s124_val: 349,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s125_val: 350,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s126_val: 351,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s127_val: 352,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s128_val: 353,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s129_val: 354,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s130_val: 355,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_sched_u1_stage_cnt: 356,  // number of active stages
  qw_sched_u2_stage_cnt: 357,  // number of active stages
  qw_sched_u3_stage_cnt: 358,  // number of active stages
  qw_sched_u4_stage_cnt: 359,  // number of active stages
  qw_sched_u5_stage_cnt: 360,  // number of active stages
  qw_sched_u6_stage_cnt: 361,  // number of active stages
  qw_sched_u7_stage_cnt: 362,  // number of active stages
  qw_sched_u8_stage_cnt: 363,  // number of active stages
  qw_sched_u9_stage_cnt: 364,  // number of active stages
  qw_sched_u10_stage_cnt: 365,  // number of active stages
  qw_tq1_count: 366,  // number of active tasks
  qw_tq1_q1_unit: 367,  // task 1 unit index (0=empty)
  qw_tq1_q1_stage: 368,  // task 1 program stage
  qw_tq1_q1_lift: 369,  // task 1 pickup station
  qw_tq1_q1_sink: 370,  // task 1 putdown station
  qw_tq1_q1_start_hi: 371,  // task 1 start time upper 16
  qw_tq1_q1_start_lo: 372,  // task 1 start time lower 16
  qw_tq1_q1_fin_hi: 373,  // task 1 finish time upper 16
  qw_tq1_q1_fin_lo: 374,  // task 1 finish time lower 16
  qw_tq1_q1_calc_x10: 375,  // task 1 calc time ×10
  qw_tq1_q1_min_x10: 376,  // task 1 min time ×10
  qw_tq1_q1_max_x10: 377,  // task 1 max time ×10
  qw_tq1_q2_unit: 378,  // task 2 unit index (0=empty)
  qw_tq1_q2_stage: 379,  // task 2 program stage
  qw_tq1_q2_lift: 380,  // task 2 pickup station
  qw_tq1_q2_sink: 381,  // task 2 putdown station
  qw_tq1_q2_start_hi: 382,  // task 2 start time upper 16
  qw_tq1_q2_start_lo: 383,  // task 2 start time lower 16
  qw_tq1_q2_fin_hi: 384,  // task 2 finish time upper 16
  qw_tq1_q2_fin_lo: 385,  // task 2 finish time lower 16
  qw_tq1_q2_calc_x10: 386,  // task 2 calc time ×10
  qw_tq1_q2_min_x10: 387,  // task 2 min time ×10
  qw_tq1_q2_max_x10: 388,  // task 2 max time ×10
  qw_tq1_q3_unit: 389,  // task 3 unit index (0=empty)
  qw_tq1_q3_stage: 390,  // task 3 program stage
  qw_tq1_q3_lift: 391,  // task 3 pickup station
  qw_tq1_q3_sink: 392,  // task 3 putdown station
  qw_tq1_q3_start_hi: 393,  // task 3 start time upper 16
  qw_tq1_q3_start_lo: 394,  // task 3 start time lower 16
  qw_tq1_q3_fin_hi: 395,  // task 3 finish time upper 16
  qw_tq1_q3_fin_lo: 396,  // task 3 finish time lower 16
  qw_tq1_q3_calc_x10: 397,  // task 3 calc time ×10
  qw_tq1_q3_min_x10: 398,  // task 3 min time ×10
  qw_tq1_q3_max_x10: 399,  // task 3 max time ×10
  qw_tq1_q4_unit: 400,  // task 4 unit index (0=empty)
  qw_tq1_q4_stage: 401,  // task 4 program stage
  qw_tq1_q4_lift: 402,  // task 4 pickup station
  qw_tq1_q4_sink: 403,  // task 4 putdown station
  qw_tq1_q4_start_hi: 404,  // task 4 start time upper 16
  qw_tq1_q4_start_lo: 405,  // task 4 start time lower 16
  qw_tq1_q4_fin_hi: 406,  // task 4 finish time upper 16
  qw_tq1_q4_fin_lo: 407,  // task 4 finish time lower 16
  qw_tq1_q4_calc_x10: 408,  // task 4 calc time ×10
  qw_tq1_q4_min_x10: 409,  // task 4 min time ×10
  qw_tq1_q4_max_x10: 410,  // task 4 max time ×10
  qw_tq1_q5_unit: 411,  // task 5 unit index (0=empty)
  qw_tq1_q5_stage: 412,  // task 5 program stage
  qw_tq1_q5_lift: 413,  // task 5 pickup station
  qw_tq1_q5_sink: 414,  // task 5 putdown station
  qw_tq1_q5_start_hi: 415,  // task 5 start time upper 16
  qw_tq1_q5_start_lo: 416,  // task 5 start time lower 16
  qw_tq1_q5_fin_hi: 417,  // task 5 finish time upper 16
  qw_tq1_q5_fin_lo: 418,  // task 5 finish time lower 16
  qw_tq1_q5_calc_x10: 419,  // task 5 calc time ×10
  qw_tq1_q5_min_x10: 420,  // task 5 min time ×10
  qw_tq1_q5_max_x10: 421,  // task 5 max time ×10
  qw_tq1_q6_unit: 422,  // task 6 unit index (0=empty)
  qw_tq1_q6_stage: 423,  // task 6 program stage
  qw_tq1_q6_lift: 424,  // task 6 pickup station
  qw_tq1_q6_sink: 425,  // task 6 putdown station
  qw_tq1_q6_start_hi: 426,  // task 6 start time upper 16
  qw_tq1_q6_start_lo: 427,  // task 6 start time lower 16
  qw_tq1_q6_fin_hi: 428,  // task 6 finish time upper 16
  qw_tq1_q6_fin_lo: 429,  // task 6 finish time lower 16
  qw_tq1_q6_calc_x10: 430,  // task 6 calc time ×10
  qw_tq1_q6_min_x10: 431,  // task 6 min time ×10
  qw_tq1_q6_max_x10: 432,  // task 6 max time ×10
  qw_tq1_q7_unit: 433,  // task 7 unit index (0=empty)
  qw_tq1_q7_stage: 434,  // task 7 program stage
  qw_tq1_q7_lift: 435,  // task 7 pickup station
  qw_tq1_q7_sink: 436,  // task 7 putdown station
  qw_tq1_q7_start_hi: 437,  // task 7 start time upper 16
  qw_tq1_q7_start_lo: 438,  // task 7 start time lower 16
  qw_tq1_q7_fin_hi: 439,  // task 7 finish time upper 16
  qw_tq1_q7_fin_lo: 440,  // task 7 finish time lower 16
  qw_tq1_q7_calc_x10: 441,  // task 7 calc time ×10
  qw_tq1_q7_min_x10: 442,  // task 7 min time ×10
  qw_tq1_q7_max_x10: 443,  // task 7 max time ×10
  qw_tq1_q8_unit: 444,  // task 8 unit index (0=empty)
  qw_tq1_q8_stage: 445,  // task 8 program stage
  qw_tq1_q8_lift: 446,  // task 8 pickup station
  qw_tq1_q8_sink: 447,  // task 8 putdown station
  qw_tq1_q8_start_hi: 448,  // task 8 start time upper 16
  qw_tq1_q8_start_lo: 449,  // task 8 start time lower 16
  qw_tq1_q8_fin_hi: 450,  // task 8 finish time upper 16
  qw_tq1_q8_fin_lo: 451,  // task 8 finish time lower 16
  qw_tq1_q8_calc_x10: 452,  // task 8 calc time ×10
  qw_tq1_q8_min_x10: 453,  // task 8 min time ×10
  qw_tq1_q8_max_x10: 454,  // task 8 max time ×10
  qw_tq1_q9_unit: 455,  // task 9 unit index (0=empty)
  qw_tq1_q9_stage: 456,  // task 9 program stage
  qw_tq1_q9_lift: 457,  // task 9 pickup station
  qw_tq1_q9_sink: 458,  // task 9 putdown station
  qw_tq1_q9_start_hi: 459,  // task 9 start time upper 16
  qw_tq1_q9_start_lo: 460,  // task 9 start time lower 16
  qw_tq1_q9_fin_hi: 461,  // task 9 finish time upper 16
  qw_tq1_q9_fin_lo: 462,  // task 9 finish time lower 16
  qw_tq1_q9_calc_x10: 463,  // task 9 calc time ×10
  qw_tq1_q9_min_x10: 464,  // task 9 min time ×10
  qw_tq1_q9_max_x10: 465,  // task 9 max time ×10
  qw_tq1_q10_unit: 466,  // task 10 unit index (0=empty)
  qw_tq1_q10_stage: 467,  // task 10 program stage
  qw_tq1_q10_lift: 468,  // task 10 pickup station
  qw_tq1_q10_sink: 469,  // task 10 putdown station
  qw_tq1_q10_start_hi: 470,  // task 10 start time upper 16
  qw_tq1_q10_start_lo: 471,  // task 10 start time lower 16
  qw_tq1_q10_fin_hi: 472,  // task 10 finish time upper 16
  qw_tq1_q10_fin_lo: 473,  // task 10 finish time lower 16
  qw_tq1_q10_calc_x10: 474,  // task 10 calc time ×10
  qw_tq1_q10_min_x10: 475,  // task 10 min time ×10
  qw_tq1_q10_max_x10: 476,  // task 10 max time ×10
  qw_tq2_count: 477,  // number of active tasks
  qw_tq2_q1_unit: 478,  // task 1 unit index (0=empty)
  qw_tq2_q1_stage: 479,  // task 1 program stage
  qw_tq2_q1_lift: 480,  // task 1 pickup station
  qw_tq2_q1_sink: 481,  // task 1 putdown station
  qw_tq2_q1_start_hi: 482,  // task 1 start time upper 16
  qw_tq2_q1_start_lo: 483,  // task 1 start time lower 16
  qw_tq2_q1_fin_hi: 484,  // task 1 finish time upper 16
  qw_tq2_q1_fin_lo: 485,  // task 1 finish time lower 16
  qw_tq2_q1_calc_x10: 486,  // task 1 calc time ×10
  qw_tq2_q1_min_x10: 487,  // task 1 min time ×10
  qw_tq2_q1_max_x10: 488,  // task 1 max time ×10
  qw_tq2_q2_unit: 489,  // task 2 unit index (0=empty)
  qw_tq2_q2_stage: 490,  // task 2 program stage
  qw_tq2_q2_lift: 491,  // task 2 pickup station
  qw_tq2_q2_sink: 492,  // task 2 putdown station
  qw_tq2_q2_start_hi: 493,  // task 2 start time upper 16
  qw_tq2_q2_start_lo: 494,  // task 2 start time lower 16
  qw_tq2_q2_fin_hi: 495,  // task 2 finish time upper 16
  qw_tq2_q2_fin_lo: 496,  // task 2 finish time lower 16
  qw_tq2_q2_calc_x10: 497,  // task 2 calc time ×10
  qw_tq2_q2_min_x10: 498,  // task 2 min time ×10
  qw_tq2_q2_max_x10: 499,  // task 2 max time ×10
  qw_tq2_q3_unit: 500,  // task 3 unit index (0=empty)
  qw_tq2_q3_stage: 501,  // task 3 program stage
  qw_tq2_q3_lift: 502,  // task 3 pickup station
  qw_tq2_q3_sink: 503,  // task 3 putdown station
  qw_tq2_q3_start_hi: 504,  // task 3 start time upper 16
  qw_tq2_q3_start_lo: 505,  // task 3 start time lower 16
  qw_tq2_q3_fin_hi: 506,  // task 3 finish time upper 16
  qw_tq2_q3_fin_lo: 507,  // task 3 finish time lower 16
  qw_tq2_q3_calc_x10: 508,  // task 3 calc time ×10
  qw_tq2_q3_min_x10: 509,  // task 3 min time ×10
  qw_tq2_q3_max_x10: 510,  // task 3 max time ×10
  qw_tq2_q4_unit: 511,  // task 4 unit index (0=empty)
  qw_tq2_q4_stage: 512,  // task 4 program stage
  qw_tq2_q4_lift: 513,  // task 4 pickup station
  qw_tq2_q4_sink: 514,  // task 4 putdown station
  qw_tq2_q4_start_hi: 515,  // task 4 start time upper 16
  qw_tq2_q4_start_lo: 516,  // task 4 start time lower 16
  qw_tq2_q4_fin_hi: 517,  // task 4 finish time upper 16
  qw_tq2_q4_fin_lo: 518,  // task 4 finish time lower 16
  qw_tq2_q4_calc_x10: 519,  // task 4 calc time ×10
  qw_tq2_q4_min_x10: 520,  // task 4 min time ×10
  qw_tq2_q4_max_x10: 521,  // task 4 max time ×10
  qw_tq2_q5_unit: 522,  // task 5 unit index (0=empty)
  qw_tq2_q5_stage: 523,  // task 5 program stage
  qw_tq2_q5_lift: 524,  // task 5 pickup station
  qw_tq2_q5_sink: 525,  // task 5 putdown station
  qw_tq2_q5_start_hi: 526,  // task 5 start time upper 16
  qw_tq2_q5_start_lo: 527,  // task 5 start time lower 16
  qw_tq2_q5_fin_hi: 528,  // task 5 finish time upper 16
  qw_tq2_q5_fin_lo: 529,  // task 5 finish time lower 16
  qw_tq2_q5_calc_x10: 530,  // task 5 calc time ×10
  qw_tq2_q5_min_x10: 531,  // task 5 min time ×10
  qw_tq2_q5_max_x10: 532,  // task 5 max time ×10
  qw_tq2_q6_unit: 533,  // task 6 unit index (0=empty)
  qw_tq2_q6_stage: 534,  // task 6 program stage
  qw_tq2_q6_lift: 535,  // task 6 pickup station
  qw_tq2_q6_sink: 536,  // task 6 putdown station
  qw_tq2_q6_start_hi: 537,  // task 6 start time upper 16
  qw_tq2_q6_start_lo: 538,  // task 6 start time lower 16
  qw_tq2_q6_fin_hi: 539,  // task 6 finish time upper 16
  qw_tq2_q6_fin_lo: 540,  // task 6 finish time lower 16
  qw_tq2_q6_calc_x10: 541,  // task 6 calc time ×10
  qw_tq2_q6_min_x10: 542,  // task 6 min time ×10
  qw_tq2_q6_max_x10: 543,  // task 6 max time ×10
  qw_tq2_q7_unit: 544,  // task 7 unit index (0=empty)
  qw_tq2_q7_stage: 545,  // task 7 program stage
  qw_tq2_q7_lift: 546,  // task 7 pickup station
  qw_tq2_q7_sink: 547,  // task 7 putdown station
  qw_tq2_q7_start_hi: 548,  // task 7 start time upper 16
  qw_tq2_q7_start_lo: 549,  // task 7 start time lower 16
  qw_tq2_q7_fin_hi: 550,  // task 7 finish time upper 16
  qw_tq2_q7_fin_lo: 551,  // task 7 finish time lower 16
  qw_tq2_q7_calc_x10: 552,  // task 7 calc time ×10
  qw_tq2_q7_min_x10: 553,  // task 7 min time ×10
  qw_tq2_q7_max_x10: 554,  // task 7 max time ×10
  qw_tq2_q8_unit: 555,  // task 8 unit index (0=empty)
  qw_tq2_q8_stage: 556,  // task 8 program stage
  qw_tq2_q8_lift: 557,  // task 8 pickup station
  qw_tq2_q8_sink: 558,  // task 8 putdown station
  qw_tq2_q8_start_hi: 559,  // task 8 start time upper 16
  qw_tq2_q8_start_lo: 560,  // task 8 start time lower 16
  qw_tq2_q8_fin_hi: 561,  // task 8 finish time upper 16
  qw_tq2_q8_fin_lo: 562,  // task 8 finish time lower 16
  qw_tq2_q8_calc_x10: 563,  // task 8 calc time ×10
  qw_tq2_q8_min_x10: 564,  // task 8 min time ×10
  qw_tq2_q8_max_x10: 565,  // task 8 max time ×10
  qw_tq2_q9_unit: 566,  // task 9 unit index (0=empty)
  qw_tq2_q9_stage: 567,  // task 9 program stage
  qw_tq2_q9_lift: 568,  // task 9 pickup station
  qw_tq2_q9_sink: 569,  // task 9 putdown station
  qw_tq2_q9_start_hi: 570,  // task 9 start time upper 16
  qw_tq2_q9_start_lo: 571,  // task 9 start time lower 16
  qw_tq2_q9_fin_hi: 572,  // task 9 finish time upper 16
  qw_tq2_q9_fin_lo: 573,  // task 9 finish time lower 16
  qw_tq2_q9_calc_x10: 574,  // task 9 calc time ×10
  qw_tq2_q9_min_x10: 575,  // task 9 min time ×10
  qw_tq2_q9_max_x10: 576,  // task 9 max time ×10
  qw_tq2_q10_unit: 577,  // task 10 unit index (0=empty)
  qw_tq2_q10_stage: 578,  // task 10 program stage
  qw_tq2_q10_lift: 579,  // task 10 pickup station
  qw_tq2_q10_sink: 580,  // task 10 putdown station
  qw_tq2_q10_start_hi: 581,  // task 10 start time upper 16
  qw_tq2_q10_start_lo: 582,  // task 10 start time lower 16
  qw_tq2_q10_fin_hi: 583,  // task 10 finish time upper 16
  qw_tq2_q10_fin_lo: 584,  // task 10 finish time lower 16
  qw_tq2_q10_calc_x10: 585,  // task 10 calc time ×10
  qw_tq2_q10_min_x10: 586,  // task 10 min time ×10
  qw_tq2_q10_max_x10: 587,  // task 10 max time ×10
  qw_tq3_count: 588,  // number of active tasks
  qw_tq3_q1_unit: 589,  // task 1 unit index (0=empty)
  qw_tq3_q1_stage: 590,  // task 1 program stage
  qw_tq3_q1_lift: 591,  // task 1 pickup station
  qw_tq3_q1_sink: 592,  // task 1 putdown station
  qw_tq3_q1_start_hi: 593,  // task 1 start time upper 16
  qw_tq3_q1_start_lo: 594,  // task 1 start time lower 16
  qw_tq3_q1_fin_hi: 595,  // task 1 finish time upper 16
  qw_tq3_q1_fin_lo: 596,  // task 1 finish time lower 16
  qw_tq3_q1_calc_x10: 597,  // task 1 calc time ×10
  qw_tq3_q1_min_x10: 598,  // task 1 min time ×10
  qw_tq3_q1_max_x10: 599,  // task 1 max time ×10
  qw_tq3_q2_unit: 600,  // task 2 unit index (0=empty)
  qw_tq3_q2_stage: 601,  // task 2 program stage
  qw_tq3_q2_lift: 602,  // task 2 pickup station
  qw_tq3_q2_sink: 603,  // task 2 putdown station
  qw_tq3_q2_start_hi: 604,  // task 2 start time upper 16
  qw_tq3_q2_start_lo: 605,  // task 2 start time lower 16
  qw_tq3_q2_fin_hi: 606,  // task 2 finish time upper 16
  qw_tq3_q2_fin_lo: 607,  // task 2 finish time lower 16
  qw_tq3_q2_calc_x10: 608,  // task 2 calc time ×10
  qw_tq3_q2_min_x10: 609,  // task 2 min time ×10
  qw_tq3_q2_max_x10: 610,  // task 2 max time ×10
  qw_tq3_q3_unit: 611,  // task 3 unit index (0=empty)
  qw_tq3_q3_stage: 612,  // task 3 program stage
  qw_tq3_q3_lift: 613,  // task 3 pickup station
  qw_tq3_q3_sink: 614,  // task 3 putdown station
  qw_tq3_q3_start_hi: 615,  // task 3 start time upper 16
  qw_tq3_q3_start_lo: 616,  // task 3 start time lower 16
  qw_tq3_q3_fin_hi: 617,  // task 3 finish time upper 16
  qw_tq3_q3_fin_lo: 618,  // task 3 finish time lower 16
  qw_tq3_q3_calc_x10: 619,  // task 3 calc time ×10
  qw_tq3_q3_min_x10: 620,  // task 3 min time ×10
  qw_tq3_q3_max_x10: 621,  // task 3 max time ×10
  qw_tq3_q4_unit: 622,  // task 4 unit index (0=empty)
  qw_tq3_q4_stage: 623,  // task 4 program stage
  qw_tq3_q4_lift: 624,  // task 4 pickup station
  qw_tq3_q4_sink: 625,  // task 4 putdown station
  qw_tq3_q4_start_hi: 626,  // task 4 start time upper 16
  qw_tq3_q4_start_lo: 627,  // task 4 start time lower 16
  qw_tq3_q4_fin_hi: 628,  // task 4 finish time upper 16
  qw_tq3_q4_fin_lo: 629,  // task 4 finish time lower 16
  qw_tq3_q4_calc_x10: 630,  // task 4 calc time ×10
  qw_tq3_q4_min_x10: 631,  // task 4 min time ×10
  qw_tq3_q4_max_x10: 632,  // task 4 max time ×10
  qw_tq3_q5_unit: 633,  // task 5 unit index (0=empty)
  qw_tq3_q5_stage: 634,  // task 5 program stage
  qw_tq3_q5_lift: 635,  // task 5 pickup station
  qw_tq3_q5_sink: 636,  // task 5 putdown station
  qw_tq3_q5_start_hi: 637,  // task 5 start time upper 16
  qw_tq3_q5_start_lo: 638,  // task 5 start time lower 16
  qw_tq3_q5_fin_hi: 639,  // task 5 finish time upper 16
  qw_tq3_q5_fin_lo: 640,  // task 5 finish time lower 16
  qw_tq3_q5_calc_x10: 641,  // task 5 calc time ×10
  qw_tq3_q5_min_x10: 642,  // task 5 min time ×10
  qw_tq3_q5_max_x10: 643,  // task 5 max time ×10
  qw_tq3_q6_unit: 644,  // task 6 unit index (0=empty)
  qw_tq3_q6_stage: 645,  // task 6 program stage
  qw_tq3_q6_lift: 646,  // task 6 pickup station
  qw_tq3_q6_sink: 647,  // task 6 putdown station
  qw_tq3_q6_start_hi: 648,  // task 6 start time upper 16
  qw_tq3_q6_start_lo: 649,  // task 6 start time lower 16
  qw_tq3_q6_fin_hi: 650,  // task 6 finish time upper 16
  qw_tq3_q6_fin_lo: 651,  // task 6 finish time lower 16
  qw_tq3_q6_calc_x10: 652,  // task 6 calc time ×10
  qw_tq3_q6_min_x10: 653,  // task 6 min time ×10
  qw_tq3_q6_max_x10: 654,  // task 6 max time ×10
  qw_tq3_q7_unit: 655,  // task 7 unit index (0=empty)
  qw_tq3_q7_stage: 656,  // task 7 program stage
  qw_tq3_q7_lift: 657,  // task 7 pickup station
  qw_tq3_q7_sink: 658,  // task 7 putdown station
  qw_tq3_q7_start_hi: 659,  // task 7 start time upper 16
  qw_tq3_q7_start_lo: 660,  // task 7 start time lower 16
  qw_tq3_q7_fin_hi: 661,  // task 7 finish time upper 16
  qw_tq3_q7_fin_lo: 662,  // task 7 finish time lower 16
  qw_tq3_q7_calc_x10: 663,  // task 7 calc time ×10
  qw_tq3_q7_min_x10: 664,  // task 7 min time ×10
  qw_tq3_q7_max_x10: 665,  // task 7 max time ×10
  qw_tq3_q8_unit: 666,  // task 8 unit index (0=empty)
  qw_tq3_q8_stage: 667,  // task 8 program stage
  qw_tq3_q8_lift: 668,  // task 8 pickup station
  qw_tq3_q8_sink: 669,  // task 8 putdown station
  qw_tq3_q8_start_hi: 670,  // task 8 start time upper 16
  qw_tq3_q8_start_lo: 671,  // task 8 start time lower 16
  qw_tq3_q8_fin_hi: 672,  // task 8 finish time upper 16
  qw_tq3_q8_fin_lo: 673,  // task 8 finish time lower 16
  qw_tq3_q8_calc_x10: 674,  // task 8 calc time ×10
  qw_tq3_q8_min_x10: 675,  // task 8 min time ×10
  qw_tq3_q8_max_x10: 676,  // task 8 max time ×10
  qw_tq3_q9_unit: 677,  // task 9 unit index (0=empty)
  qw_tq3_q9_stage: 678,  // task 9 program stage
  qw_tq3_q9_lift: 679,  // task 9 pickup station
  qw_tq3_q9_sink: 680,  // task 9 putdown station
  qw_tq3_q9_start_hi: 681,  // task 9 start time upper 16
  qw_tq3_q9_start_lo: 682,  // task 9 start time lower 16
  qw_tq3_q9_fin_hi: 683,  // task 9 finish time upper 16
  qw_tq3_q9_fin_lo: 684,  // task 9 finish time lower 16
  qw_tq3_q9_calc_x10: 685,  // task 9 calc time ×10
  qw_tq3_q9_min_x10: 686,  // task 9 min time ×10
  qw_tq3_q9_max_x10: 687,  // task 9 max time ×10
  qw_tq3_q10_unit: 688,  // task 10 unit index (0=empty)
  qw_tq3_q10_stage: 689,  // task 10 program stage
  qw_tq3_q10_lift: 690,  // task 10 pickup station
  qw_tq3_q10_sink: 691,  // task 10 putdown station
  qw_tq3_q10_start_hi: 692,  // task 10 start time upper 16
  qw_tq3_q10_start_lo: 693,  // task 10 start time lower 16
  qw_tq3_q10_fin_hi: 694,  // task 10 finish time upper 16
  qw_tq3_q10_fin_lo: 695,  // task 10 finish time lower 16
  qw_tq3_q10_calc_x10: 696,  // task 10 calc time ×10
  qw_tq3_q10_min_x10: 697,  // task 10 min time ×10
  qw_tq3_q10_max_x10: 698,  // task 10 max time ×10
  qw_dep_state_activated: 699,  // 1=departure activated handshake
  qw_dep_state_stable: 700,  // 1=task list stable for DEP
  qw_dep_state_waiting_cnt: 701,  // waiting batch count
  qw_dep_state_overlap_cnt: 702,  // overlap station count
  qw_dep_state_pend_valid: 703,  // 1=pending write valid
  qw_dep_state_pend_unit: 704,  // pending activated unit
  qw_dep_state_pend_stage: 705,  // pending activated stage
  qw_dep_state_pend_time_hi: 706,  // pending activation time upper 16
  qw_dep_state_pend_time_lo: 707,  // pending activation time lower 16
  qw_dw1_unit: 708,  // waiting batch unit index (0=empty)
  qw_dw2_unit: 709,  // waiting batch unit index (0=empty)
  qw_dw3_unit: 710,  // waiting batch unit index (0=empty)
  qw_dw4_unit: 711,  // waiting batch unit index (0=empty)
  qw_dw5_unit: 712,  // waiting batch unit index (0=empty)
  qw_ov_s101_flag: 713,  // 1=station in overlap zone
  qw_ov_s102_flag: 714,  // 1=station in overlap zone
  qw_ov_s103_flag: 715,  // 1=station in overlap zone
  qw_ov_s104_flag: 716,  // 1=station in overlap zone
  qw_ov_s105_flag: 717,  // 1=station in overlap zone
  qw_ov_s106_flag: 718,  // 1=station in overlap zone
  qw_ov_s107_flag: 719,  // 1=station in overlap zone
  qw_ov_s108_flag: 720,  // 1=station in overlap zone
  qw_ov_s109_flag: 721,  // 1=station in overlap zone
  qw_ov_s110_flag: 722,  // 1=station in overlap zone
  qw_ov_s111_flag: 723,  // 1=station in overlap zone
  qw_ov_s112_flag: 724,  // 1=station in overlap zone
  qw_ov_s113_flag: 725,  // 1=station in overlap zone
  qw_ov_s114_flag: 726,  // 1=station in overlap zone
  qw_ov_s115_flag: 727,  // 1=station in overlap zone
  qw_ov_s116_flag: 728,  // 1=station in overlap zone
  qw_ov_s117_flag: 729,  // 1=station in overlap zone
  qw_ov_s118_flag: 730,  // 1=station in overlap zone
  qw_ov_s119_flag: 731,  // 1=station in overlap zone
  qw_ov_s120_flag: 732,  // 1=station in overlap zone
  qw_ov_s121_flag: 733,  // 1=station in overlap zone
  qw_ov_s122_flag: 734,  // 1=station in overlap zone
  qw_ov_s123_flag: 735,  // 1=station in overlap zone
  qw_ov_s124_flag: 736,  // 1=station in overlap zone
  qw_ov_s125_flag: 737,  // 1=station in overlap zone
  qw_ov_s126_flag: 738,  // 1=station in overlap zone
  qw_ov_s127_flag: 739,  // 1=station in overlap zone
  qw_ov_s128_flag: 740,  // 1=station in overlap zone
  qw_ov_s129_flag: 741,  // 1=station in overlap zone
  qw_ov_s130_flag: 742,  // 1=station in overlap zone
  iw_cmd_t1_start: 743,  // 1=trigger command
  iw_cmd_t1_lift: 744,  // lift station number
  iw_cmd_t1_sink: 745,  // sink station number
  iw_cmd_t2_start: 746,  // 1=trigger command
  iw_cmd_t2_lift: 747,  // lift station number
  iw_cmd_t2_sink: 748,  // sink station number
  iw_cfg_seq: 749,  // sequence — triggers on change
  iw_cfg_cmd: 750,  // 1=write_station, 2=init, 3=clear_all
  iw_cfg_param: 751,  // station_number or station_count
  iw_cfg_d0: 752,  // tank_id
  iw_cfg_d1: 753,  // x_position mm
  iw_cfg_d2: 754,  // y_position mm
  iw_cfg_d3: 755,  // z_position mm
  iw_cfg_d4: 756,  // operation
  iw_cfg_d5: 757,  // dropping_time ×10
  iw_cfg_d6: 758,  // device_delay ×10
  iw_cfg_d7: 759,  // kind (0=dry, 1=wet)
  iw_unit_seq: 760,  // sequence — triggers on change
  iw_unit_id: 761,  // unit number 1..10
  iw_unit_loc: 762,  // location (station number)
  iw_unit_status: 763,  // NOT_USED=0, USED=1
  iw_unit_target: 764,  // TO_NONE=0..TO_AVOID=5
  iw_batch_seq: 765,  // sequence — triggers on change
  iw_batch_unit: 766,  // unit index 1..10
  iw_batch_code: 767,  // numeric batch code
  iw_batch_state: 768,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  iw_batch_prog_id: 769,  // treatment program ID
  iw_prog_seq: 770,  // sequence — triggers on change
  iw_prog_unit: 771,  // unit index 1..10
  iw_prog_stage: 772,  // stage index 1..30
  iw_prog_s1: 773,  // station 1 (0=unused)
  iw_prog_s2: 774,  // station 2
  iw_prog_s3: 775,  // station 3
  iw_prog_s4: 776,  // station 4
  iw_prog_s5: 777,  // station 5
  iw_prog_min_time: 778,  // min processing time seconds
  iw_prog_max_time: 779,  // max processing time seconds
  iw_prog_cal_time: 780,  // calculated time seconds
  iw_avoid_seq: 781,  // sequence — triggers on change
  iw_avoid_station: 782,  // station number
  iw_avoid_value: 783,  // AVOID_NONE=0, PASS=1, BLOCK=2
  iw_production_queue: 784,  // 1=batches in queue, 0=empty
  iw_time_hi: 785,  // unix seconds upper 16 bits
  iw_time_lo: 786,  // unix seconds lower 16 bits
  qw_event_out_count: 787,  // messages in queue (0..10)
  qw_event_out_seq: 788,  // head message sequence number
  qw_event_out_type: 789,  // message type (1=task,2=lift,...)
  qw_event_out_ts_hi: 790,  // timestamp upper 16 bits
  qw_event_out_ts_lo: 791,  // timestamp lower 16 bits
  qw_event_out_f1: 792,  // payload field 1
  qw_event_out_f2: 793,  // payload field 2
  qw_event_out_f3: 794,  // payload field 3
  qw_event_out_f4: 795,  // payload field 4
  qw_event_out_f5: 796,  // payload field 5
  qw_event_out_f6: 797,  // payload field 6
  qw_event_out_f7: 798,  // payload field 7
  qw_event_out_f8: 799,  // payload field 8
  qw_event_out_f9: 800,  // payload field 9
  qw_event_out_f10: 801,  // payload field 10
  qw_event_out_f11: 802,  // payload field 11
  qw_event_out_f12: 803,  // payload field 12
  iw_event_ack_seq: 804,  // last consumed sequence number
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
  state.batch_state[1].batch_start_hi = toSigned(r[133]);
  state.batch_state[1].batch_start_lo = toSigned(r[134]);
  state.batch_state[2] = {};
  state.batch_state[2].batch_code = toSigned(r[135]);
  state.batch_state[2].batch_state = toSigned(r[136]);
  state.batch_state[2].batch_program = toSigned(r[137]);
  state.batch_state[2].batch_stage = toSigned(r[138]);
  state.batch_state[2].batch_min_time = toSigned(r[139]);
  state.batch_state[2].batch_max_time = toSigned(r[140]);
  state.batch_state[2].batch_cal_time = toSigned(r[141]);
  state.batch_state[2].batch_start_hi = toSigned(r[142]);
  state.batch_state[2].batch_start_lo = toSigned(r[143]);
  state.batch_state[3] = {};
  state.batch_state[3].batch_code = toSigned(r[144]);
  state.batch_state[3].batch_state = toSigned(r[145]);
  state.batch_state[3].batch_program = toSigned(r[146]);
  state.batch_state[3].batch_stage = toSigned(r[147]);
  state.batch_state[3].batch_min_time = toSigned(r[148]);
  state.batch_state[3].batch_max_time = toSigned(r[149]);
  state.batch_state[3].batch_cal_time = toSigned(r[150]);
  state.batch_state[3].batch_start_hi = toSigned(r[151]);
  state.batch_state[3].batch_start_lo = toSigned(r[152]);
  state.batch_state[4] = {};
  state.batch_state[4].batch_code = toSigned(r[153]);
  state.batch_state[4].batch_state = toSigned(r[154]);
  state.batch_state[4].batch_program = toSigned(r[155]);
  state.batch_state[4].batch_stage = toSigned(r[156]);
  state.batch_state[4].batch_min_time = toSigned(r[157]);
  state.batch_state[4].batch_max_time = toSigned(r[158]);
  state.batch_state[4].batch_cal_time = toSigned(r[159]);
  state.batch_state[4].batch_start_hi = toSigned(r[160]);
  state.batch_state[4].batch_start_lo = toSigned(r[161]);
  state.batch_state[5] = {};
  state.batch_state[5].batch_code = toSigned(r[162]);
  state.batch_state[5].batch_state = toSigned(r[163]);
  state.batch_state[5].batch_program = toSigned(r[164]);
  state.batch_state[5].batch_stage = toSigned(r[165]);
  state.batch_state[5].batch_min_time = toSigned(r[166]);
  state.batch_state[5].batch_max_time = toSigned(r[167]);
  state.batch_state[5].batch_cal_time = toSigned(r[168]);
  state.batch_state[5].batch_start_hi = toSigned(r[169]);
  state.batch_state[5].batch_start_lo = toSigned(r[170]);
  state.batch_state[6] = {};
  state.batch_state[6].batch_code = toSigned(r[171]);
  state.batch_state[6].batch_state = toSigned(r[172]);
  state.batch_state[6].batch_program = toSigned(r[173]);
  state.batch_state[6].batch_stage = toSigned(r[174]);
  state.batch_state[6].batch_min_time = toSigned(r[175]);
  state.batch_state[6].batch_max_time = toSigned(r[176]);
  state.batch_state[6].batch_cal_time = toSigned(r[177]);
  state.batch_state[6].batch_start_hi = toSigned(r[178]);
  state.batch_state[6].batch_start_lo = toSigned(r[179]);
  state.batch_state[7] = {};
  state.batch_state[7].batch_code = toSigned(r[180]);
  state.batch_state[7].batch_state = toSigned(r[181]);
  state.batch_state[7].batch_program = toSigned(r[182]);
  state.batch_state[7].batch_stage = toSigned(r[183]);
  state.batch_state[7].batch_min_time = toSigned(r[184]);
  state.batch_state[7].batch_max_time = toSigned(r[185]);
  state.batch_state[7].batch_cal_time = toSigned(r[186]);
  state.batch_state[7].batch_start_hi = toSigned(r[187]);
  state.batch_state[7].batch_start_lo = toSigned(r[188]);
  state.batch_state[8] = {};
  state.batch_state[8].batch_code = toSigned(r[189]);
  state.batch_state[8].batch_state = toSigned(r[190]);
  state.batch_state[8].batch_program = toSigned(r[191]);
  state.batch_state[8].batch_stage = toSigned(r[192]);
  state.batch_state[8].batch_min_time = toSigned(r[193]);
  state.batch_state[8].batch_max_time = toSigned(r[194]);
  state.batch_state[8].batch_cal_time = toSigned(r[195]);
  state.batch_state[8].batch_start_hi = toSigned(r[196]);
  state.batch_state[8].batch_start_lo = toSigned(r[197]);
  state.batch_state[9] = {};
  state.batch_state[9].batch_code = toSigned(r[198]);
  state.batch_state[9].batch_state = toSigned(r[199]);
  state.batch_state[9].batch_program = toSigned(r[200]);
  state.batch_state[9].batch_stage = toSigned(r[201]);
  state.batch_state[9].batch_min_time = toSigned(r[202]);
  state.batch_state[9].batch_max_time = toSigned(r[203]);
  state.batch_state[9].batch_cal_time = toSigned(r[204]);
  state.batch_state[9].batch_start_hi = toSigned(r[205]);
  state.batch_state[9].batch_start_lo = toSigned(r[206]);
  state.batch_state[10] = {};
  state.batch_state[10].batch_code = toSigned(r[207]);
  state.batch_state[10].batch_state = toSigned(r[208]);
  state.batch_state[10].batch_program = toSigned(r[209]);
  state.batch_state[10].batch_stage = toSigned(r[210]);
  state.batch_state[10].batch_min_time = toSigned(r[211]);
  state.batch_state[10].batch_max_time = toSigned(r[212]);
  state.batch_state[10].batch_cal_time = toSigned(r[213]);
  state.batch_state[10].batch_start_hi = toSigned(r[214]);
  state.batch_state[10].batch_start_lo = toSigned(r[215]);
  // --- calibration ---
  state.calibration = {};
  state.calibration.cal_step = toSigned(r[216]);
  state.calibration.cal_tid = toSigned(r[217]);
  // --- calibration_results ---
  if (!state.calibration_results) state.calibration_results = {};
  state.calibration_results[1] = {};
  state.calibration_results[1].lift_wet = toSigned(r[218]) * 0.1;
  state.calibration_results[1].sink_wet = toSigned(r[219]) * 0.1;
  state.calibration_results[1].lift_dry = toSigned(r[220]) * 0.1;
  state.calibration_results[1].sink_dry = toSigned(r[221]) * 0.1;
  state.calibration_results[1].x_acc = toSigned(r[222]) * 0.1;
  state.calibration_results[1].x_dec = toSigned(r[223]) * 0.1;
  state.calibration_results[1].x_max = toSigned(r[224]);
  state.calibration_results[2] = {};
  state.calibration_results[2].lift_wet = toSigned(r[225]) * 0.1;
  state.calibration_results[2].sink_wet = toSigned(r[226]) * 0.1;
  state.calibration_results[2].lift_dry = toSigned(r[227]) * 0.1;
  state.calibration_results[2].sink_dry = toSigned(r[228]) * 0.1;
  state.calibration_results[2].x_acc = toSigned(r[229]) * 0.1;
  state.calibration_results[2].x_dec = toSigned(r[230]) * 0.1;
  state.calibration_results[2].x_max = toSigned(r[231]);
  state.calibration_results[3] = {};
  state.calibration_results[3].lift_wet = toSigned(r[232]) * 0.1;
  state.calibration_results[3].sink_wet = toSigned(r[233]) * 0.1;
  state.calibration_results[3].lift_dry = toSigned(r[234]) * 0.1;
  state.calibration_results[3].sink_dry = toSigned(r[235]) * 0.1;
  state.calibration_results[3].x_acc = toSigned(r[236]) * 0.1;
  state.calibration_results[3].x_dec = toSigned(r[237]) * 0.1;
  state.calibration_results[3].x_max = toSigned(r[238]);
  // --- transporter_config ---
  if (!state.transporter_config) state.transporter_config = {};
  state.transporter_config[1] = {};
  state.transporter_config[1].x_min_limit = toSigned(r[239]);
  state.transporter_config[1].x_max_limit = toSigned(r[240]);
  state.transporter_config[1].y_min_limit = toSigned(r[241]);
  state.transporter_config[1].y_max_limit = toSigned(r[242]);
  state.transporter_config[1].x_avoid_mm = toSigned(r[243]);
  state.transporter_config[1].y_avoid_mm = toSigned(r[244]);
  state.transporter_config[1].phys_x_accel = toSigned(r[245]) * 0.01;
  state.transporter_config[1].phys_x_decel = toSigned(r[246]) * 0.01;
  state.transporter_config[1].phys_x_max = toSigned(r[247]);
  state.transporter_config[1].phys_z_total = toSigned(r[248]);
  state.transporter_config[1].phys_z_sdry = toSigned(r[249]);
  state.transporter_config[1].phys_z_swet = toSigned(r[250]);
  state.transporter_config[1].phys_z_send = toSigned(r[251]);
  state.transporter_config[1].phys_z_slow = toSigned(r[252]);
  state.transporter_config[1].phys_z_fast = toSigned(r[253]);
  state.transporter_config[1].phys_drip = toSigned(r[254]) * 0.1;
  state.transporter_config[1].phys_avoid = toSigned(r[255]);
  state.transporter_config[1].ta1_min_lift = toSigned(r[256]);
  state.transporter_config[1].ta1_max_lift = toSigned(r[257]);
  state.transporter_config[1].ta1_min_sink = toSigned(r[258]);
  state.transporter_config[1].ta1_max_sink = toSigned(r[259]);
  state.transporter_config[1].ta2_min_lift = toSigned(r[260]);
  state.transporter_config[1].ta2_max_lift = toSigned(r[261]);
  state.transporter_config[1].ta2_min_sink = toSigned(r[262]);
  state.transporter_config[1].ta2_max_sink = toSigned(r[263]);
  state.transporter_config[1].ta3_min_lift = toSigned(r[264]);
  state.transporter_config[1].ta3_max_lift = toSigned(r[265]);
  state.transporter_config[1].ta3_min_sink = toSigned(r[266]);
  state.transporter_config[1].ta3_max_sink = toSigned(r[267]);
  state.transporter_config[2] = {};
  state.transporter_config[2].x_min_limit = toSigned(r[268]);
  state.transporter_config[2].x_max_limit = toSigned(r[269]);
  state.transporter_config[2].y_min_limit = toSigned(r[270]);
  state.transporter_config[2].y_max_limit = toSigned(r[271]);
  state.transporter_config[2].x_avoid_mm = toSigned(r[272]);
  state.transporter_config[2].y_avoid_mm = toSigned(r[273]);
  state.transporter_config[2].phys_x_accel = toSigned(r[274]) * 0.01;
  state.transporter_config[2].phys_x_decel = toSigned(r[275]) * 0.01;
  state.transporter_config[2].phys_x_max = toSigned(r[276]);
  state.transporter_config[2].phys_z_total = toSigned(r[277]);
  state.transporter_config[2].phys_z_sdry = toSigned(r[278]);
  state.transporter_config[2].phys_z_swet = toSigned(r[279]);
  state.transporter_config[2].phys_z_send = toSigned(r[280]);
  state.transporter_config[2].phys_z_slow = toSigned(r[281]);
  state.transporter_config[2].phys_z_fast = toSigned(r[282]);
  state.transporter_config[2].phys_drip = toSigned(r[283]) * 0.1;
  state.transporter_config[2].phys_avoid = toSigned(r[284]);
  state.transporter_config[2].ta1_min_lift = toSigned(r[285]);
  state.transporter_config[2].ta1_max_lift = toSigned(r[286]);
  state.transporter_config[2].ta1_min_sink = toSigned(r[287]);
  state.transporter_config[2].ta1_max_sink = toSigned(r[288]);
  state.transporter_config[2].ta2_min_lift = toSigned(r[289]);
  state.transporter_config[2].ta2_max_lift = toSigned(r[290]);
  state.transporter_config[2].ta2_min_sink = toSigned(r[291]);
  state.transporter_config[2].ta2_max_sink = toSigned(r[292]);
  state.transporter_config[2].ta3_min_lift = toSigned(r[293]);
  state.transporter_config[2].ta3_max_lift = toSigned(r[294]);
  state.transporter_config[2].ta3_min_sink = toSigned(r[295]);
  state.transporter_config[2].ta3_max_sink = toSigned(r[296]);
  state.transporter_config[3] = {};
  state.transporter_config[3].x_min_limit = toSigned(r[297]);
  state.transporter_config[3].x_max_limit = toSigned(r[298]);
  state.transporter_config[3].y_min_limit = toSigned(r[299]);
  state.transporter_config[3].y_max_limit = toSigned(r[300]);
  state.transporter_config[3].x_avoid_mm = toSigned(r[301]);
  state.transporter_config[3].y_avoid_mm = toSigned(r[302]);
  state.transporter_config[3].phys_x_accel = toSigned(r[303]) * 0.01;
  state.transporter_config[3].phys_x_decel = toSigned(r[304]) * 0.01;
  state.transporter_config[3].phys_x_max = toSigned(r[305]);
  state.transporter_config[3].phys_z_total = toSigned(r[306]);
  state.transporter_config[3].phys_z_sdry = toSigned(r[307]);
  state.transporter_config[3].phys_z_swet = toSigned(r[308]);
  state.transporter_config[3].phys_z_send = toSigned(r[309]);
  state.transporter_config[3].phys_z_slow = toSigned(r[310]);
  state.transporter_config[3].phys_z_fast = toSigned(r[311]);
  state.transporter_config[3].phys_drip = toSigned(r[312]) * 0.1;
  state.transporter_config[3].phys_avoid = toSigned(r[313]);
  state.transporter_config[3].ta1_min_lift = toSigned(r[314]);
  state.transporter_config[3].ta1_max_lift = toSigned(r[315]);
  state.transporter_config[3].ta1_min_sink = toSigned(r[316]);
  state.transporter_config[3].ta1_max_sink = toSigned(r[317]);
  state.transporter_config[3].ta2_min_lift = toSigned(r[318]);
  state.transporter_config[3].ta2_max_lift = toSigned(r[319]);
  state.transporter_config[3].ta2_min_sink = toSigned(r[320]);
  state.transporter_config[3].ta2_max_sink = toSigned(r[321]);
  state.transporter_config[3].ta3_min_lift = toSigned(r[322]);
  state.transporter_config[3].ta3_max_lift = toSigned(r[323]);
  state.transporter_config[3].ta3_min_sink = toSigned(r[324]);
  state.transporter_config[3].ta3_max_sink = toSigned(r[325]);
  state.avoid_status[101] = {};
  state.avoid_status[101].avoid_val = toSigned(r[326]);
  state.avoid_status[102] = {};
  state.avoid_status[102].avoid_val = toSigned(r[327]);
  state.avoid_status[103] = {};
  state.avoid_status[103].avoid_val = toSigned(r[328]);
  state.avoid_status[104] = {};
  state.avoid_status[104].avoid_val = toSigned(r[329]);
  state.avoid_status[105] = {};
  state.avoid_status[105].avoid_val = toSigned(r[330]);
  state.avoid_status[106] = {};
  state.avoid_status[106].avoid_val = toSigned(r[331]);
  state.avoid_status[107] = {};
  state.avoid_status[107].avoid_val = toSigned(r[332]);
  state.avoid_status[108] = {};
  state.avoid_status[108].avoid_val = toSigned(r[333]);
  state.avoid_status[109] = {};
  state.avoid_status[109].avoid_val = toSigned(r[334]);
  state.avoid_status[110] = {};
  state.avoid_status[110].avoid_val = toSigned(r[335]);
  state.avoid_status[111] = {};
  state.avoid_status[111].avoid_val = toSigned(r[336]);
  state.avoid_status[112] = {};
  state.avoid_status[112].avoid_val = toSigned(r[337]);
  state.avoid_status[113] = {};
  state.avoid_status[113].avoid_val = toSigned(r[338]);
  state.avoid_status[114] = {};
  state.avoid_status[114].avoid_val = toSigned(r[339]);
  state.avoid_status[115] = {};
  state.avoid_status[115].avoid_val = toSigned(r[340]);
  state.avoid_status[116] = {};
  state.avoid_status[116].avoid_val = toSigned(r[341]);
  state.avoid_status[117] = {};
  state.avoid_status[117].avoid_val = toSigned(r[342]);
  state.avoid_status[118] = {};
  state.avoid_status[118].avoid_val = toSigned(r[343]);
  state.avoid_status[119] = {};
  state.avoid_status[119].avoid_val = toSigned(r[344]);
  state.avoid_status[120] = {};
  state.avoid_status[120].avoid_val = toSigned(r[345]);
  state.avoid_status[121] = {};
  state.avoid_status[121].avoid_val = toSigned(r[346]);
  state.avoid_status[122] = {};
  state.avoid_status[122].avoid_val = toSigned(r[347]);
  state.avoid_status[123] = {};
  state.avoid_status[123].avoid_val = toSigned(r[348]);
  state.avoid_status[124] = {};
  state.avoid_status[124].avoid_val = toSigned(r[349]);
  state.avoid_status[125] = {};
  state.avoid_status[125].avoid_val = toSigned(r[350]);
  state.avoid_status[126] = {};
  state.avoid_status[126].avoid_val = toSigned(r[351]);
  state.avoid_status[127] = {};
  state.avoid_status[127].avoid_val = toSigned(r[352]);
  state.avoid_status[128] = {};
  state.avoid_status[128].avoid_val = toSigned(r[353]);
  state.avoid_status[129] = {};
  state.avoid_status[129].avoid_val = toSigned(r[354]);
  state.avoid_status[130] = {};
  state.avoid_status[130].avoid_val = toSigned(r[355]);
  // --- schedule_summary ---
  if (!state.schedule_summary) state.schedule_summary = {};
  state.schedule_summary[1] = {};
  state.schedule_summary[1].stage_count = toSigned(r[356]);
  state.schedule_summary[2] = {};
  state.schedule_summary[2].stage_count = toSigned(r[357]);
  state.schedule_summary[3] = {};
  state.schedule_summary[3].stage_count = toSigned(r[358]);
  state.schedule_summary[4] = {};
  state.schedule_summary[4].stage_count = toSigned(r[359]);
  state.schedule_summary[5] = {};
  state.schedule_summary[5].stage_count = toSigned(r[360]);
  state.schedule_summary[6] = {};
  state.schedule_summary[6].stage_count = toSigned(r[361]);
  state.schedule_summary[7] = {};
  state.schedule_summary[7].stage_count = toSigned(r[362]);
  state.schedule_summary[8] = {};
  state.schedule_summary[8].stage_count = toSigned(r[363]);
  state.schedule_summary[9] = {};
  state.schedule_summary[9].stage_count = toSigned(r[364]);
  state.schedule_summary[10] = {};
  state.schedule_summary[10].stage_count = toSigned(r[365]);
  // --- task_queue ---
  if (!state.task_queue) state.task_queue = {};
  state.task_queue[1] = {};
  state.task_queue[1].task_count = toSigned(r[366]);
  state.task_queue[1].q1_unit = toSigned(r[367]);
  state.task_queue[1].q1_stage = toSigned(r[368]);
  state.task_queue[1].q1_lift = toSigned(r[369]);
  state.task_queue[1].q1_sink = toSigned(r[370]);
  state.task_queue[1]._q1_start_hi = r[371];
  state.task_queue[1]._q1_start_lo = r[372];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[1].q1_start_time = ((state.task_queue[1]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_start_lo & 0xFFFF);
  state.task_queue[1]._q1_fin_hi = r[373];
  state.task_queue[1]._q1_fin_lo = r[374];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[1].q1_finish_time = ((state.task_queue[1]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_fin_lo & 0xFFFF);
  state.task_queue[1].q1_calc_time = toSigned(r[375]) * 0.1;
  state.task_queue[1].q1_min_time = toSigned(r[376]) * 0.1;
  state.task_queue[1].q1_max_time = toSigned(r[377]) * 0.1;
  state.task_queue[1].q2_unit = toSigned(r[378]);
  state.task_queue[1].q2_stage = toSigned(r[379]);
  state.task_queue[1].q2_lift = toSigned(r[380]);
  state.task_queue[1].q2_sink = toSigned(r[381]);
  state.task_queue[1]._q2_start_hi = r[382];
  state.task_queue[1]._q2_start_lo = r[383];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[1].q2_start_time = ((state.task_queue[1]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_start_lo & 0xFFFF);
  state.task_queue[1]._q2_fin_hi = r[384];
  state.task_queue[1]._q2_fin_lo = r[385];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[1].q2_finish_time = ((state.task_queue[1]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_fin_lo & 0xFFFF);
  state.task_queue[1].q2_calc_time = toSigned(r[386]) * 0.1;
  state.task_queue[1].q2_min_time = toSigned(r[387]) * 0.1;
  state.task_queue[1].q2_max_time = toSigned(r[388]) * 0.1;
  state.task_queue[1].q3_unit = toSigned(r[389]);
  state.task_queue[1].q3_stage = toSigned(r[390]);
  state.task_queue[1].q3_lift = toSigned(r[391]);
  state.task_queue[1].q3_sink = toSigned(r[392]);
  state.task_queue[1]._q3_start_hi = r[393];
  state.task_queue[1]._q3_start_lo = r[394];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[1].q3_start_time = ((state.task_queue[1]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_start_lo & 0xFFFF);
  state.task_queue[1]._q3_fin_hi = r[395];
  state.task_queue[1]._q3_fin_lo = r[396];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[1].q3_finish_time = ((state.task_queue[1]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_fin_lo & 0xFFFF);
  state.task_queue[1].q3_calc_time = toSigned(r[397]) * 0.1;
  state.task_queue[1].q3_min_time = toSigned(r[398]) * 0.1;
  state.task_queue[1].q3_max_time = toSigned(r[399]) * 0.1;
  state.task_queue[1].q4_unit = toSigned(r[400]);
  state.task_queue[1].q4_stage = toSigned(r[401]);
  state.task_queue[1].q4_lift = toSigned(r[402]);
  state.task_queue[1].q4_sink = toSigned(r[403]);
  state.task_queue[1]._q4_start_hi = r[404];
  state.task_queue[1]._q4_start_lo = r[405];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[1].q4_start_time = ((state.task_queue[1]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_start_lo & 0xFFFF);
  state.task_queue[1]._q4_fin_hi = r[406];
  state.task_queue[1]._q4_fin_lo = r[407];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[1].q4_finish_time = ((state.task_queue[1]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_fin_lo & 0xFFFF);
  state.task_queue[1].q4_calc_time = toSigned(r[408]) * 0.1;
  state.task_queue[1].q4_min_time = toSigned(r[409]) * 0.1;
  state.task_queue[1].q4_max_time = toSigned(r[410]) * 0.1;
  state.task_queue[1].q5_unit = toSigned(r[411]);
  state.task_queue[1].q5_stage = toSigned(r[412]);
  state.task_queue[1].q5_lift = toSigned(r[413]);
  state.task_queue[1].q5_sink = toSigned(r[414]);
  state.task_queue[1]._q5_start_hi = r[415];
  state.task_queue[1]._q5_start_lo = r[416];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[1].q5_start_time = ((state.task_queue[1]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_start_lo & 0xFFFF);
  state.task_queue[1]._q5_fin_hi = r[417];
  state.task_queue[1]._q5_fin_lo = r[418];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[1].q5_finish_time = ((state.task_queue[1]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_fin_lo & 0xFFFF);
  state.task_queue[1].q5_calc_time = toSigned(r[419]) * 0.1;
  state.task_queue[1].q5_min_time = toSigned(r[420]) * 0.1;
  state.task_queue[1].q5_max_time = toSigned(r[421]) * 0.1;
  state.task_queue[1].q6_unit = toSigned(r[422]);
  state.task_queue[1].q6_stage = toSigned(r[423]);
  state.task_queue[1].q6_lift = toSigned(r[424]);
  state.task_queue[1].q6_sink = toSigned(r[425]);
  state.task_queue[1]._q6_start_hi = r[426];
  state.task_queue[1]._q6_start_lo = r[427];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[1].q6_start_time = ((state.task_queue[1]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_start_lo & 0xFFFF);
  state.task_queue[1]._q6_fin_hi = r[428];
  state.task_queue[1]._q6_fin_lo = r[429];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[1].q6_finish_time = ((state.task_queue[1]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_fin_lo & 0xFFFF);
  state.task_queue[1].q6_calc_time = toSigned(r[430]) * 0.1;
  state.task_queue[1].q6_min_time = toSigned(r[431]) * 0.1;
  state.task_queue[1].q6_max_time = toSigned(r[432]) * 0.1;
  state.task_queue[1].q7_unit = toSigned(r[433]);
  state.task_queue[1].q7_stage = toSigned(r[434]);
  state.task_queue[1].q7_lift = toSigned(r[435]);
  state.task_queue[1].q7_sink = toSigned(r[436]);
  state.task_queue[1]._q7_start_hi = r[437];
  state.task_queue[1]._q7_start_lo = r[438];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[1].q7_start_time = ((state.task_queue[1]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_start_lo & 0xFFFF);
  state.task_queue[1]._q7_fin_hi = r[439];
  state.task_queue[1]._q7_fin_lo = r[440];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[1].q7_finish_time = ((state.task_queue[1]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_fin_lo & 0xFFFF);
  state.task_queue[1].q7_calc_time = toSigned(r[441]) * 0.1;
  state.task_queue[1].q7_min_time = toSigned(r[442]) * 0.1;
  state.task_queue[1].q7_max_time = toSigned(r[443]) * 0.1;
  state.task_queue[1].q8_unit = toSigned(r[444]);
  state.task_queue[1].q8_stage = toSigned(r[445]);
  state.task_queue[1].q8_lift = toSigned(r[446]);
  state.task_queue[1].q8_sink = toSigned(r[447]);
  state.task_queue[1]._q8_start_hi = r[448];
  state.task_queue[1]._q8_start_lo = r[449];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[1].q8_start_time = ((state.task_queue[1]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_start_lo & 0xFFFF);
  state.task_queue[1]._q8_fin_hi = r[450];
  state.task_queue[1]._q8_fin_lo = r[451];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[1].q8_finish_time = ((state.task_queue[1]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_fin_lo & 0xFFFF);
  state.task_queue[1].q8_calc_time = toSigned(r[452]) * 0.1;
  state.task_queue[1].q8_min_time = toSigned(r[453]) * 0.1;
  state.task_queue[1].q8_max_time = toSigned(r[454]) * 0.1;
  state.task_queue[1].q9_unit = toSigned(r[455]);
  state.task_queue[1].q9_stage = toSigned(r[456]);
  state.task_queue[1].q9_lift = toSigned(r[457]);
  state.task_queue[1].q9_sink = toSigned(r[458]);
  state.task_queue[1]._q9_start_hi = r[459];
  state.task_queue[1]._q9_start_lo = r[460];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[1].q9_start_time = ((state.task_queue[1]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_start_lo & 0xFFFF);
  state.task_queue[1]._q9_fin_hi = r[461];
  state.task_queue[1]._q9_fin_lo = r[462];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[1].q9_finish_time = ((state.task_queue[1]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_fin_lo & 0xFFFF);
  state.task_queue[1].q9_calc_time = toSigned(r[463]) * 0.1;
  state.task_queue[1].q9_min_time = toSigned(r[464]) * 0.1;
  state.task_queue[1].q9_max_time = toSigned(r[465]) * 0.1;
  state.task_queue[1].q10_unit = toSigned(r[466]);
  state.task_queue[1].q10_stage = toSigned(r[467]);
  state.task_queue[1].q10_lift = toSigned(r[468]);
  state.task_queue[1].q10_sink = toSigned(r[469]);
  state.task_queue[1]._q10_start_hi = r[470];
  state.task_queue[1]._q10_start_lo = r[471];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[1].q10_start_time = ((state.task_queue[1]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_start_lo & 0xFFFF);
  state.task_queue[1]._q10_fin_hi = r[472];
  state.task_queue[1]._q10_fin_lo = r[473];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[1].q10_finish_time = ((state.task_queue[1]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_fin_lo & 0xFFFF);
  state.task_queue[1].q10_calc_time = toSigned(r[474]) * 0.1;
  state.task_queue[1].q10_min_time = toSigned(r[475]) * 0.1;
  state.task_queue[1].q10_max_time = toSigned(r[476]) * 0.1;
  state.task_queue[2] = {};
  state.task_queue[2].task_count = toSigned(r[477]);
  state.task_queue[2].q1_unit = toSigned(r[478]);
  state.task_queue[2].q1_stage = toSigned(r[479]);
  state.task_queue[2].q1_lift = toSigned(r[480]);
  state.task_queue[2].q1_sink = toSigned(r[481]);
  state.task_queue[2]._q1_start_hi = r[482];
  state.task_queue[2]._q1_start_lo = r[483];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[2].q1_start_time = ((state.task_queue[2]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_start_lo & 0xFFFF);
  state.task_queue[2]._q1_fin_hi = r[484];
  state.task_queue[2]._q1_fin_lo = r[485];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[2].q1_finish_time = ((state.task_queue[2]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_fin_lo & 0xFFFF);
  state.task_queue[2].q1_calc_time = toSigned(r[486]) * 0.1;
  state.task_queue[2].q1_min_time = toSigned(r[487]) * 0.1;
  state.task_queue[2].q1_max_time = toSigned(r[488]) * 0.1;
  state.task_queue[2].q2_unit = toSigned(r[489]);
  state.task_queue[2].q2_stage = toSigned(r[490]);
  state.task_queue[2].q2_lift = toSigned(r[491]);
  state.task_queue[2].q2_sink = toSigned(r[492]);
  state.task_queue[2]._q2_start_hi = r[493];
  state.task_queue[2]._q2_start_lo = r[494];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[2].q2_start_time = ((state.task_queue[2]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_start_lo & 0xFFFF);
  state.task_queue[2]._q2_fin_hi = r[495];
  state.task_queue[2]._q2_fin_lo = r[496];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[2].q2_finish_time = ((state.task_queue[2]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_fin_lo & 0xFFFF);
  state.task_queue[2].q2_calc_time = toSigned(r[497]) * 0.1;
  state.task_queue[2].q2_min_time = toSigned(r[498]) * 0.1;
  state.task_queue[2].q2_max_time = toSigned(r[499]) * 0.1;
  state.task_queue[2].q3_unit = toSigned(r[500]);
  state.task_queue[2].q3_stage = toSigned(r[501]);
  state.task_queue[2].q3_lift = toSigned(r[502]);
  state.task_queue[2].q3_sink = toSigned(r[503]);
  state.task_queue[2]._q3_start_hi = r[504];
  state.task_queue[2]._q3_start_lo = r[505];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[2].q3_start_time = ((state.task_queue[2]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_start_lo & 0xFFFF);
  state.task_queue[2]._q3_fin_hi = r[506];
  state.task_queue[2]._q3_fin_lo = r[507];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[2].q3_finish_time = ((state.task_queue[2]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_fin_lo & 0xFFFF);
  state.task_queue[2].q3_calc_time = toSigned(r[508]) * 0.1;
  state.task_queue[2].q3_min_time = toSigned(r[509]) * 0.1;
  state.task_queue[2].q3_max_time = toSigned(r[510]) * 0.1;
  state.task_queue[2].q4_unit = toSigned(r[511]);
  state.task_queue[2].q4_stage = toSigned(r[512]);
  state.task_queue[2].q4_lift = toSigned(r[513]);
  state.task_queue[2].q4_sink = toSigned(r[514]);
  state.task_queue[2]._q4_start_hi = r[515];
  state.task_queue[2]._q4_start_lo = r[516];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[2].q4_start_time = ((state.task_queue[2]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_start_lo & 0xFFFF);
  state.task_queue[2]._q4_fin_hi = r[517];
  state.task_queue[2]._q4_fin_lo = r[518];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[2].q4_finish_time = ((state.task_queue[2]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_fin_lo & 0xFFFF);
  state.task_queue[2].q4_calc_time = toSigned(r[519]) * 0.1;
  state.task_queue[2].q4_min_time = toSigned(r[520]) * 0.1;
  state.task_queue[2].q4_max_time = toSigned(r[521]) * 0.1;
  state.task_queue[2].q5_unit = toSigned(r[522]);
  state.task_queue[2].q5_stage = toSigned(r[523]);
  state.task_queue[2].q5_lift = toSigned(r[524]);
  state.task_queue[2].q5_sink = toSigned(r[525]);
  state.task_queue[2]._q5_start_hi = r[526];
  state.task_queue[2]._q5_start_lo = r[527];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[2].q5_start_time = ((state.task_queue[2]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_start_lo & 0xFFFF);
  state.task_queue[2]._q5_fin_hi = r[528];
  state.task_queue[2]._q5_fin_lo = r[529];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[2].q5_finish_time = ((state.task_queue[2]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_fin_lo & 0xFFFF);
  state.task_queue[2].q5_calc_time = toSigned(r[530]) * 0.1;
  state.task_queue[2].q5_min_time = toSigned(r[531]) * 0.1;
  state.task_queue[2].q5_max_time = toSigned(r[532]) * 0.1;
  state.task_queue[2].q6_unit = toSigned(r[533]);
  state.task_queue[2].q6_stage = toSigned(r[534]);
  state.task_queue[2].q6_lift = toSigned(r[535]);
  state.task_queue[2].q6_sink = toSigned(r[536]);
  state.task_queue[2]._q6_start_hi = r[537];
  state.task_queue[2]._q6_start_lo = r[538];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[2].q6_start_time = ((state.task_queue[2]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_start_lo & 0xFFFF);
  state.task_queue[2]._q6_fin_hi = r[539];
  state.task_queue[2]._q6_fin_lo = r[540];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[2].q6_finish_time = ((state.task_queue[2]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_fin_lo & 0xFFFF);
  state.task_queue[2].q6_calc_time = toSigned(r[541]) * 0.1;
  state.task_queue[2].q6_min_time = toSigned(r[542]) * 0.1;
  state.task_queue[2].q6_max_time = toSigned(r[543]) * 0.1;
  state.task_queue[2].q7_unit = toSigned(r[544]);
  state.task_queue[2].q7_stage = toSigned(r[545]);
  state.task_queue[2].q7_lift = toSigned(r[546]);
  state.task_queue[2].q7_sink = toSigned(r[547]);
  state.task_queue[2]._q7_start_hi = r[548];
  state.task_queue[2]._q7_start_lo = r[549];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[2].q7_start_time = ((state.task_queue[2]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_start_lo & 0xFFFF);
  state.task_queue[2]._q7_fin_hi = r[550];
  state.task_queue[2]._q7_fin_lo = r[551];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[2].q7_finish_time = ((state.task_queue[2]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_fin_lo & 0xFFFF);
  state.task_queue[2].q7_calc_time = toSigned(r[552]) * 0.1;
  state.task_queue[2].q7_min_time = toSigned(r[553]) * 0.1;
  state.task_queue[2].q7_max_time = toSigned(r[554]) * 0.1;
  state.task_queue[2].q8_unit = toSigned(r[555]);
  state.task_queue[2].q8_stage = toSigned(r[556]);
  state.task_queue[2].q8_lift = toSigned(r[557]);
  state.task_queue[2].q8_sink = toSigned(r[558]);
  state.task_queue[2]._q8_start_hi = r[559];
  state.task_queue[2]._q8_start_lo = r[560];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[2].q8_start_time = ((state.task_queue[2]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_start_lo & 0xFFFF);
  state.task_queue[2]._q8_fin_hi = r[561];
  state.task_queue[2]._q8_fin_lo = r[562];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[2].q8_finish_time = ((state.task_queue[2]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_fin_lo & 0xFFFF);
  state.task_queue[2].q8_calc_time = toSigned(r[563]) * 0.1;
  state.task_queue[2].q8_min_time = toSigned(r[564]) * 0.1;
  state.task_queue[2].q8_max_time = toSigned(r[565]) * 0.1;
  state.task_queue[2].q9_unit = toSigned(r[566]);
  state.task_queue[2].q9_stage = toSigned(r[567]);
  state.task_queue[2].q9_lift = toSigned(r[568]);
  state.task_queue[2].q9_sink = toSigned(r[569]);
  state.task_queue[2]._q9_start_hi = r[570];
  state.task_queue[2]._q9_start_lo = r[571];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[2].q9_start_time = ((state.task_queue[2]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_start_lo & 0xFFFF);
  state.task_queue[2]._q9_fin_hi = r[572];
  state.task_queue[2]._q9_fin_lo = r[573];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[2].q9_finish_time = ((state.task_queue[2]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_fin_lo & 0xFFFF);
  state.task_queue[2].q9_calc_time = toSigned(r[574]) * 0.1;
  state.task_queue[2].q9_min_time = toSigned(r[575]) * 0.1;
  state.task_queue[2].q9_max_time = toSigned(r[576]) * 0.1;
  state.task_queue[2].q10_unit = toSigned(r[577]);
  state.task_queue[2].q10_stage = toSigned(r[578]);
  state.task_queue[2].q10_lift = toSigned(r[579]);
  state.task_queue[2].q10_sink = toSigned(r[580]);
  state.task_queue[2]._q10_start_hi = r[581];
  state.task_queue[2]._q10_start_lo = r[582];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[2].q10_start_time = ((state.task_queue[2]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_start_lo & 0xFFFF);
  state.task_queue[2]._q10_fin_hi = r[583];
  state.task_queue[2]._q10_fin_lo = r[584];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[2].q10_finish_time = ((state.task_queue[2]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_fin_lo & 0xFFFF);
  state.task_queue[2].q10_calc_time = toSigned(r[585]) * 0.1;
  state.task_queue[2].q10_min_time = toSigned(r[586]) * 0.1;
  state.task_queue[2].q10_max_time = toSigned(r[587]) * 0.1;
  state.task_queue[3] = {};
  state.task_queue[3].task_count = toSigned(r[588]);
  state.task_queue[3].q1_unit = toSigned(r[589]);
  state.task_queue[3].q1_stage = toSigned(r[590]);
  state.task_queue[3].q1_lift = toSigned(r[591]);
  state.task_queue[3].q1_sink = toSigned(r[592]);
  state.task_queue[3]._q1_start_hi = r[593];
  state.task_queue[3]._q1_start_lo = r[594];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[3].q1_start_time = ((state.task_queue[3]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_start_lo & 0xFFFF);
  state.task_queue[3]._q1_fin_hi = r[595];
  state.task_queue[3]._q1_fin_lo = r[596];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[3].q1_finish_time = ((state.task_queue[3]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_fin_lo & 0xFFFF);
  state.task_queue[3].q1_calc_time = toSigned(r[597]) * 0.1;
  state.task_queue[3].q1_min_time = toSigned(r[598]) * 0.1;
  state.task_queue[3].q1_max_time = toSigned(r[599]) * 0.1;
  state.task_queue[3].q2_unit = toSigned(r[600]);
  state.task_queue[3].q2_stage = toSigned(r[601]);
  state.task_queue[3].q2_lift = toSigned(r[602]);
  state.task_queue[3].q2_sink = toSigned(r[603]);
  state.task_queue[3]._q2_start_hi = r[604];
  state.task_queue[3]._q2_start_lo = r[605];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[3].q2_start_time = ((state.task_queue[3]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_start_lo & 0xFFFF);
  state.task_queue[3]._q2_fin_hi = r[606];
  state.task_queue[3]._q2_fin_lo = r[607];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[3].q2_finish_time = ((state.task_queue[3]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_fin_lo & 0xFFFF);
  state.task_queue[3].q2_calc_time = toSigned(r[608]) * 0.1;
  state.task_queue[3].q2_min_time = toSigned(r[609]) * 0.1;
  state.task_queue[3].q2_max_time = toSigned(r[610]) * 0.1;
  state.task_queue[3].q3_unit = toSigned(r[611]);
  state.task_queue[3].q3_stage = toSigned(r[612]);
  state.task_queue[3].q3_lift = toSigned(r[613]);
  state.task_queue[3].q3_sink = toSigned(r[614]);
  state.task_queue[3]._q3_start_hi = r[615];
  state.task_queue[3]._q3_start_lo = r[616];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[3].q3_start_time = ((state.task_queue[3]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_start_lo & 0xFFFF);
  state.task_queue[3]._q3_fin_hi = r[617];
  state.task_queue[3]._q3_fin_lo = r[618];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[3].q3_finish_time = ((state.task_queue[3]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_fin_lo & 0xFFFF);
  state.task_queue[3].q3_calc_time = toSigned(r[619]) * 0.1;
  state.task_queue[3].q3_min_time = toSigned(r[620]) * 0.1;
  state.task_queue[3].q3_max_time = toSigned(r[621]) * 0.1;
  state.task_queue[3].q4_unit = toSigned(r[622]);
  state.task_queue[3].q4_stage = toSigned(r[623]);
  state.task_queue[3].q4_lift = toSigned(r[624]);
  state.task_queue[3].q4_sink = toSigned(r[625]);
  state.task_queue[3]._q4_start_hi = r[626];
  state.task_queue[3]._q4_start_lo = r[627];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[3].q4_start_time = ((state.task_queue[3]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_start_lo & 0xFFFF);
  state.task_queue[3]._q4_fin_hi = r[628];
  state.task_queue[3]._q4_fin_lo = r[629];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[3].q4_finish_time = ((state.task_queue[3]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_fin_lo & 0xFFFF);
  state.task_queue[3].q4_calc_time = toSigned(r[630]) * 0.1;
  state.task_queue[3].q4_min_time = toSigned(r[631]) * 0.1;
  state.task_queue[3].q4_max_time = toSigned(r[632]) * 0.1;
  state.task_queue[3].q5_unit = toSigned(r[633]);
  state.task_queue[3].q5_stage = toSigned(r[634]);
  state.task_queue[3].q5_lift = toSigned(r[635]);
  state.task_queue[3].q5_sink = toSigned(r[636]);
  state.task_queue[3]._q5_start_hi = r[637];
  state.task_queue[3]._q5_start_lo = r[638];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[3].q5_start_time = ((state.task_queue[3]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_start_lo & 0xFFFF);
  state.task_queue[3]._q5_fin_hi = r[639];
  state.task_queue[3]._q5_fin_lo = r[640];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[3].q5_finish_time = ((state.task_queue[3]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_fin_lo & 0xFFFF);
  state.task_queue[3].q5_calc_time = toSigned(r[641]) * 0.1;
  state.task_queue[3].q5_min_time = toSigned(r[642]) * 0.1;
  state.task_queue[3].q5_max_time = toSigned(r[643]) * 0.1;
  state.task_queue[3].q6_unit = toSigned(r[644]);
  state.task_queue[3].q6_stage = toSigned(r[645]);
  state.task_queue[3].q6_lift = toSigned(r[646]);
  state.task_queue[3].q6_sink = toSigned(r[647]);
  state.task_queue[3]._q6_start_hi = r[648];
  state.task_queue[3]._q6_start_lo = r[649];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[3].q6_start_time = ((state.task_queue[3]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_start_lo & 0xFFFF);
  state.task_queue[3]._q6_fin_hi = r[650];
  state.task_queue[3]._q6_fin_lo = r[651];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[3].q6_finish_time = ((state.task_queue[3]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_fin_lo & 0xFFFF);
  state.task_queue[3].q6_calc_time = toSigned(r[652]) * 0.1;
  state.task_queue[3].q6_min_time = toSigned(r[653]) * 0.1;
  state.task_queue[3].q6_max_time = toSigned(r[654]) * 0.1;
  state.task_queue[3].q7_unit = toSigned(r[655]);
  state.task_queue[3].q7_stage = toSigned(r[656]);
  state.task_queue[3].q7_lift = toSigned(r[657]);
  state.task_queue[3].q7_sink = toSigned(r[658]);
  state.task_queue[3]._q7_start_hi = r[659];
  state.task_queue[3]._q7_start_lo = r[660];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[3].q7_start_time = ((state.task_queue[3]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_start_lo & 0xFFFF);
  state.task_queue[3]._q7_fin_hi = r[661];
  state.task_queue[3]._q7_fin_lo = r[662];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[3].q7_finish_time = ((state.task_queue[3]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_fin_lo & 0xFFFF);
  state.task_queue[3].q7_calc_time = toSigned(r[663]) * 0.1;
  state.task_queue[3].q7_min_time = toSigned(r[664]) * 0.1;
  state.task_queue[3].q7_max_time = toSigned(r[665]) * 0.1;
  state.task_queue[3].q8_unit = toSigned(r[666]);
  state.task_queue[3].q8_stage = toSigned(r[667]);
  state.task_queue[3].q8_lift = toSigned(r[668]);
  state.task_queue[3].q8_sink = toSigned(r[669]);
  state.task_queue[3]._q8_start_hi = r[670];
  state.task_queue[3]._q8_start_lo = r[671];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[3].q8_start_time = ((state.task_queue[3]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_start_lo & 0xFFFF);
  state.task_queue[3]._q8_fin_hi = r[672];
  state.task_queue[3]._q8_fin_lo = r[673];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[3].q8_finish_time = ((state.task_queue[3]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_fin_lo & 0xFFFF);
  state.task_queue[3].q8_calc_time = toSigned(r[674]) * 0.1;
  state.task_queue[3].q8_min_time = toSigned(r[675]) * 0.1;
  state.task_queue[3].q8_max_time = toSigned(r[676]) * 0.1;
  state.task_queue[3].q9_unit = toSigned(r[677]);
  state.task_queue[3].q9_stage = toSigned(r[678]);
  state.task_queue[3].q9_lift = toSigned(r[679]);
  state.task_queue[3].q9_sink = toSigned(r[680]);
  state.task_queue[3]._q9_start_hi = r[681];
  state.task_queue[3]._q9_start_lo = r[682];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[3].q9_start_time = ((state.task_queue[3]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_start_lo & 0xFFFF);
  state.task_queue[3]._q9_fin_hi = r[683];
  state.task_queue[3]._q9_fin_lo = r[684];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[3].q9_finish_time = ((state.task_queue[3]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_fin_lo & 0xFFFF);
  state.task_queue[3].q9_calc_time = toSigned(r[685]) * 0.1;
  state.task_queue[3].q9_min_time = toSigned(r[686]) * 0.1;
  state.task_queue[3].q9_max_time = toSigned(r[687]) * 0.1;
  state.task_queue[3].q10_unit = toSigned(r[688]);
  state.task_queue[3].q10_stage = toSigned(r[689]);
  state.task_queue[3].q10_lift = toSigned(r[690]);
  state.task_queue[3].q10_sink = toSigned(r[691]);
  state.task_queue[3]._q10_start_hi = r[692];
  state.task_queue[3]._q10_start_lo = r[693];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[3].q10_start_time = ((state.task_queue[3]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_start_lo & 0xFFFF);
  state.task_queue[3]._q10_fin_hi = r[694];
  state.task_queue[3]._q10_fin_lo = r[695];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[3].q10_finish_time = ((state.task_queue[3]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_fin_lo & 0xFFFF);
  state.task_queue[3].q10_calc_time = toSigned(r[696]) * 0.1;
  state.task_queue[3].q10_min_time = toSigned(r[697]) * 0.1;
  state.task_queue[3].q10_max_time = toSigned(r[698]) * 0.1;
  // --- dep_state ---
  state.dep_state = {};
  state.dep_state.dep_activated = toSigned(r[699]);
  state.dep_state.dep_stable = toSigned(r[700]);
  state.dep_state.dep_waiting_count = toSigned(r[701]);
  state.dep_state.dep_overlap_count = toSigned(r[702]);
  state.dep_state.dep_pending_valid = toSigned(r[703]);
  state.dep_state.dep_pending_unit = toSigned(r[704]);
  state.dep_state.dep_pending_stage = toSigned(r[705]);
  state.dep_state._dep_pend_time_hi = r[706];
  state.dep_state._dep_pend_time_lo = r[707];
  // Combined uint32: dep_pending_time = (hi << 16) | lo
  state.dep_state.dep_pending_time = ((state.dep_state._pend_time_hi & 0xFFFF) * 65536) + (state.dep_state._pend_time_lo & 0xFFFF);
  // --- dep_waiting ---
  if (!state.dep_waiting) state.dep_waiting = {};
  state.dep_waiting[1] = {};
  state.dep_waiting[1].waiting_unit = toSigned(r[708]);
  state.dep_waiting[2] = {};
  state.dep_waiting[2].waiting_unit = toSigned(r[709]);
  state.dep_waiting[3] = {};
  state.dep_waiting[3].waiting_unit = toSigned(r[710]);
  state.dep_waiting[4] = {};
  state.dep_waiting[4].waiting_unit = toSigned(r[711]);
  state.dep_waiting[5] = {};
  state.dep_waiting[5].waiting_unit = toSigned(r[712]);
  state.dep_overlap[101] = {};
  state.dep_overlap[101].overlap_flag = toSigned(r[713]);
  state.dep_overlap[102] = {};
  state.dep_overlap[102].overlap_flag = toSigned(r[714]);
  state.dep_overlap[103] = {};
  state.dep_overlap[103].overlap_flag = toSigned(r[715]);
  state.dep_overlap[104] = {};
  state.dep_overlap[104].overlap_flag = toSigned(r[716]);
  state.dep_overlap[105] = {};
  state.dep_overlap[105].overlap_flag = toSigned(r[717]);
  state.dep_overlap[106] = {};
  state.dep_overlap[106].overlap_flag = toSigned(r[718]);
  state.dep_overlap[107] = {};
  state.dep_overlap[107].overlap_flag = toSigned(r[719]);
  state.dep_overlap[108] = {};
  state.dep_overlap[108].overlap_flag = toSigned(r[720]);
  state.dep_overlap[109] = {};
  state.dep_overlap[109].overlap_flag = toSigned(r[721]);
  state.dep_overlap[110] = {};
  state.dep_overlap[110].overlap_flag = toSigned(r[722]);
  state.dep_overlap[111] = {};
  state.dep_overlap[111].overlap_flag = toSigned(r[723]);
  state.dep_overlap[112] = {};
  state.dep_overlap[112].overlap_flag = toSigned(r[724]);
  state.dep_overlap[113] = {};
  state.dep_overlap[113].overlap_flag = toSigned(r[725]);
  state.dep_overlap[114] = {};
  state.dep_overlap[114].overlap_flag = toSigned(r[726]);
  state.dep_overlap[115] = {};
  state.dep_overlap[115].overlap_flag = toSigned(r[727]);
  state.dep_overlap[116] = {};
  state.dep_overlap[116].overlap_flag = toSigned(r[728]);
  state.dep_overlap[117] = {};
  state.dep_overlap[117].overlap_flag = toSigned(r[729]);
  state.dep_overlap[118] = {};
  state.dep_overlap[118].overlap_flag = toSigned(r[730]);
  state.dep_overlap[119] = {};
  state.dep_overlap[119].overlap_flag = toSigned(r[731]);
  state.dep_overlap[120] = {};
  state.dep_overlap[120].overlap_flag = toSigned(r[732]);
  state.dep_overlap[121] = {};
  state.dep_overlap[121].overlap_flag = toSigned(r[733]);
  state.dep_overlap[122] = {};
  state.dep_overlap[122].overlap_flag = toSigned(r[734]);
  state.dep_overlap[123] = {};
  state.dep_overlap[123].overlap_flag = toSigned(r[735]);
  state.dep_overlap[124] = {};
  state.dep_overlap[124].overlap_flag = toSigned(r[736]);
  state.dep_overlap[125] = {};
  state.dep_overlap[125].overlap_flag = toSigned(r[737]);
  state.dep_overlap[126] = {};
  state.dep_overlap[126].overlap_flag = toSigned(r[738]);
  state.dep_overlap[127] = {};
  state.dep_overlap[127].overlap_flag = toSigned(r[739]);
  state.dep_overlap[128] = {};
  state.dep_overlap[128].overlap_flag = toSigned(r[740]);
  state.dep_overlap[129] = {};
  state.dep_overlap[129].overlap_flag = toSigned(r[741]);
  state.dep_overlap[130] = {};
  state.dep_overlap[130].overlap_flag = toSigned(r[742]);
  // --- event_out ---
  state.event_out = {};
  state.event_out.evt_count = toSigned(r[787]);
  state.event_out.evt_seq = toSigned(r[788]);
  state.event_out.evt_type = toSigned(r[789]);
  state.event_out.evt_ts_hi = toSigned(r[790]);
  state.event_out.evt_ts_lo = toSigned(r[791]);
  state.event_out.evt_f1 = toSigned(r[792]);
  state.event_out.evt_f2 = toSigned(r[793]);
  state.event_out.evt_f3 = toSigned(r[794]);
  state.event_out.evt_f4 = toSigned(r[795]);
  state.event_out.evt_f5 = toSigned(r[796]);
  state.event_out.evt_f6 = toSigned(r[797]);
  state.event_out.evt_f7 = toSigned(r[798]);
  state.event_out.evt_f8 = toSigned(r[799]);
  state.event_out.evt_f9 = toSigned(r[800]);
  state.event_out.evt_f10 = toSigned(r[801]);
  state.event_out.evt_f11 = toSigned(r[802]);
  state.event_out.evt_f12 = toSigned(r[803]);

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
    'iw_cmd_t1_start': 743,
    'iw_cmd_t1_lift': 744,
    'iw_cmd_t1_sink': 745,
    'iw_cmd_t2_start': 746,
    'iw_cmd_t2_lift': 747,
    'iw_cmd_t2_sink': 748,
    'iw_cfg_seq': 749,
    'iw_cfg_cmd': 750,
    'iw_cfg_param': 751,
    'iw_cfg_d0': 752,
    'iw_cfg_d1': 753,
    'iw_cfg_d2': 754,
    'iw_cfg_d3': 755,
    'iw_cfg_d4': 756,
    'iw_cfg_d5': 757,
    'iw_cfg_d6': 758,
    'iw_cfg_d7': 759,
    'iw_unit_seq': 760,
    'iw_unit_id': 761,
    'iw_unit_loc': 762,
    'iw_unit_status': 763,
    'iw_unit_target': 764,
    'iw_batch_seq': 765,
    'iw_batch_unit': 766,
    'iw_batch_code': 767,
    'iw_batch_state': 768,
    'iw_batch_prog_id': 769,
    'iw_prog_seq': 770,
    'iw_prog_unit': 771,
    'iw_prog_stage': 772,
    'iw_prog_s1': 773,
    'iw_prog_s2': 774,
    'iw_prog_s3': 775,
    'iw_prog_s4': 776,
    'iw_prog_s5': 777,
    'iw_prog_min_time': 778,
    'iw_prog_max_time': 779,
    'iw_prog_cal_time': 780,
    'iw_avoid_seq': 781,
    'iw_avoid_station': 782,
    'iw_avoid_value': 783,
    'iw_production_queue': 784,
    'iw_time_hi': 785,
    'iw_time_lo': 786,
    'iw_event_ack_seq': 804,
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
  cmd_transport: { start: 743, fields: ["cmd_start", "cmd_lift", "cmd_sink", "cmd_start", "cmd_lift", "cmd_sink"] },
  cfg: { start: 749, fields: ["cfg_seq", "cfg_cmd", "cfg_param", "cfg_d0", "cfg_d1", "cfg_d2", "cfg_d3", "cfg_d4", "cfg_d5", "cfg_d6", "cfg_d7"] },
  unit: { start: 760, fields: ["unit_seq", "unit_id", "unit_loc", "unit_status", "unit_target"] },
  batch: { start: 765, fields: ["batch_seq", "batch_unit", "batch_code", "batch_state", "batch_prog_id"] },
  prog: { start: 770, fields: ["prog_seq", "prog_unit", "prog_stage", "prog_s1", "prog_s2", "prog_s3", "prog_s4", "prog_s5", "prog_min_time", "prog_max_time", "prog_cal_time"] },
  avoid: { start: 781, fields: ["avoid_seq", "avoid_station", "avoid_value"] },
  production: { start: 784, fields: ["production_queue"] },
  time: { start: 785, fields: ["time_hi", "time_lo"] },
  event_ack: { start: 804, fields: ["evt_ack_seq"] },
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
