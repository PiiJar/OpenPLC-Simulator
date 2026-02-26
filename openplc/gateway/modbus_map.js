/**
 * Auto-generated Modbus register map — DO NOT EDIT
 * Generated from modbus_map.json (737 registers)
 */

const TOTAL_REGISTERS = 737;

// Block address ranges
const BLOCKS = {
  transporter_state: { start: 0, end: 38, count: 39, direction: 'out' },
  transporter_extended: { start: 39, end: 77, count: 39, direction: 'out' },
  twa_limits: { start: 78, end: 83, count: 6, direction: 'out' },
  plc_status: { start: 84, end: 95, count: 12, direction: 'out' },
  unit_state: { start: 96, end: 125, count: 30, direction: 'out' },
  batch_state: { start: 126, end: 165, count: 40, direction: 'out' },
  calibration: { start: 166, end: 167, count: 2, direction: 'out' },
  calibration_results: { start: 168, end: 188, count: 21, direction: 'out' },
  transporter_config: { start: 189, end: 275, count: 87, direction: 'out' },
  avoid_status: { start: 276, end: 305, count: 30, direction: 'out' },
  schedule_summary: { start: 306, end: 315, count: 10, direction: 'out' },
  task_queue: { start: 316, end: 648, count: 333, direction: 'out' },
  dep_state: { start: 649, end: 657, count: 9, direction: 'out' },
  dep_waiting: { start: 658, end: 662, count: 5, direction: 'out' },
  dep_overlap: { start: 663, end: 692, count: 30, direction: 'out' },
  cmd_transport: { start: 693, end: 698, count: 6, direction: 'in' },
  cfg: { start: 699, end: 709, count: 11, direction: 'in' },
  unit: { start: 710, end: 714, count: 5, direction: 'in' },
  batch: { start: 715, end: 719, count: 5, direction: 'in' },
  prog: { start: 720, end: 730, count: 11, direction: 'in' },
  avoid: { start: 731, end: 733, count: 3, direction: 'in' },
  production: { start: 734, end: 734, count: 1, direction: 'in' },
  time: { start: 735, end: 736, count: 2, direction: 'in' },
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
  qw_b2_code: 130,  // numeric batch code
  qw_b2_state: 131,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b2_prog: 132,  // treatment program ID
  qw_b2_stage: 133,  // current stage number
  qw_b3_code: 134,  // numeric batch code
  qw_b3_state: 135,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b3_prog: 136,  // treatment program ID
  qw_b3_stage: 137,  // current stage number
  qw_b4_code: 138,  // numeric batch code
  qw_b4_state: 139,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b4_prog: 140,  // treatment program ID
  qw_b4_stage: 141,  // current stage number
  qw_b5_code: 142,  // numeric batch code
  qw_b5_state: 143,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b5_prog: 144,  // treatment program ID
  qw_b5_stage: 145,  // current stage number
  qw_b6_code: 146,  // numeric batch code
  qw_b6_state: 147,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b6_prog: 148,  // treatment program ID
  qw_b6_stage: 149,  // current stage number
  qw_b7_code: 150,  // numeric batch code
  qw_b7_state: 151,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b7_prog: 152,  // treatment program ID
  qw_b7_stage: 153,  // current stage number
  qw_b8_code: 154,  // numeric batch code
  qw_b8_state: 155,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b8_prog: 156,  // treatment program ID
  qw_b8_stage: 157,  // current stage number
  qw_b9_code: 158,  // numeric batch code
  qw_b9_state: 159,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b9_prog: 160,  // treatment program ID
  qw_b9_stage: 161,  // current stage number
  qw_b10_code: 162,  // numeric batch code
  qw_b10_state: 163,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b10_prog: 164,  // treatment program ID
  qw_b10_stage: 165,  // current stage number
  qw_calibration_step: 166,  // 0=idle, 100=done, 999=complete
  qw_calibration_tid: 167,  // transporter being calibrated
  qw_cal_t1_lift_wet: 168,  // lift wet time ×10
  qw_cal_t1_sink_wet: 169,  // sink wet time ×10
  qw_cal_t1_lift_dry: 170,  // lift dry time ×10
  qw_cal_t1_sink_dry: 171,  // sink dry time ×10
  qw_cal_t1_x_acc: 172,  // X accel time ×10
  qw_cal_t1_x_dec: 173,  // X decel time ×10
  qw_cal_t1_x_max: 174,  // X max speed mm/s
  qw_cal_t2_lift_wet: 175,  // lift wet time ×10
  qw_cal_t2_sink_wet: 176,  // sink wet time ×10
  qw_cal_t2_lift_dry: 177,  // lift dry time ×10
  qw_cal_t2_sink_dry: 178,  // sink dry time ×10
  qw_cal_t2_x_acc: 179,  // X accel time ×10
  qw_cal_t2_x_dec: 180,  // X decel time ×10
  qw_cal_t2_x_max: 181,  // X max speed mm/s
  qw_cal_t3_lift_wet: 182,  // lift wet time ×10
  qw_cal_t3_sink_wet: 183,  // sink wet time ×10
  qw_cal_t3_lift_dry: 184,  // lift dry time ×10
  qw_cal_t3_sink_dry: 185,  // sink dry time ×10
  qw_cal_t3_x_acc: 186,  // X accel time ×10
  qw_cal_t3_x_dec: 187,  // X decel time ×10
  qw_cal_t3_x_max: 188,  // X max speed mm/s
  qw_cfg_t1_x_min: 189,  // config X min limit mm
  qw_cfg_t1_x_max: 190,  // config X max limit mm
  qw_cfg_t1_y_min: 191,  // config Y min limit mm
  qw_cfg_t1_y_max: 192,  // config Y max limit mm
  qw_cfg_t1_x_avoid: 193,  // X avoid distance mm
  qw_cfg_t1_y_avoid: 194,  // Y avoid distance mm
  qw_cfg_t1_ph_xacc_x100: 195,  // X accel ×100 (0.01s)
  qw_cfg_t1_ph_xdec_x100: 196,  // X decel ×100 (0.01s)
  qw_cfg_t1_ph_xmax: 197,  // X max speed mm/s
  qw_cfg_t1_ph_ztot: 198,  // Z total travel mm
  qw_cfg_t1_ph_zsdry: 199,  // Z slow zone dry mm
  qw_cfg_t1_ph_zswet: 200,  // Z slow zone wet mm
  qw_cfg_t1_ph_zsend: 201,  // Z slow zone end mm
  qw_cfg_t1_ph_zslow: 202,  // Z slow speed mm/s
  qw_cfg_t1_ph_zfast: 203,  // Z fast speed mm/s
  qw_cfg_t1_ph_drip_x10: 204,  // drip delay ×10 (0.1s)
  qw_cfg_t1_ph_avoid: 205,  // physics avoid mm
  qw_cfg_t1_ta1_min_lift: 206,  // task area 1 min lift station
  qw_cfg_t1_ta1_max_lift: 207,  // task area 1 max lift station
  qw_cfg_t1_ta1_min_sink: 208,  // task area 1 min sink station
  qw_cfg_t1_ta1_max_sink: 209,  // task area 1 max sink station
  qw_cfg_t1_ta2_min_lift: 210,  // task area 2 min lift station
  qw_cfg_t1_ta2_max_lift: 211,  // task area 2 max lift station
  qw_cfg_t1_ta2_min_sink: 212,  // task area 2 min sink station
  qw_cfg_t1_ta2_max_sink: 213,  // task area 2 max sink station
  qw_cfg_t1_ta3_min_lift: 214,  // task area 3 min lift station
  qw_cfg_t1_ta3_max_lift: 215,  // task area 3 max lift station
  qw_cfg_t1_ta3_min_sink: 216,  // task area 3 min sink station
  qw_cfg_t1_ta3_max_sink: 217,  // task area 3 max sink station
  qw_cfg_t2_x_min: 218,  // config X min limit mm
  qw_cfg_t2_x_max: 219,  // config X max limit mm
  qw_cfg_t2_y_min: 220,  // config Y min limit mm
  qw_cfg_t2_y_max: 221,  // config Y max limit mm
  qw_cfg_t2_x_avoid: 222,  // X avoid distance mm
  qw_cfg_t2_y_avoid: 223,  // Y avoid distance mm
  qw_cfg_t2_ph_xacc_x100: 224,  // X accel ×100 (0.01s)
  qw_cfg_t2_ph_xdec_x100: 225,  // X decel ×100 (0.01s)
  qw_cfg_t2_ph_xmax: 226,  // X max speed mm/s
  qw_cfg_t2_ph_ztot: 227,  // Z total travel mm
  qw_cfg_t2_ph_zsdry: 228,  // Z slow zone dry mm
  qw_cfg_t2_ph_zswet: 229,  // Z slow zone wet mm
  qw_cfg_t2_ph_zsend: 230,  // Z slow zone end mm
  qw_cfg_t2_ph_zslow: 231,  // Z slow speed mm/s
  qw_cfg_t2_ph_zfast: 232,  // Z fast speed mm/s
  qw_cfg_t2_ph_drip_x10: 233,  // drip delay ×10 (0.1s)
  qw_cfg_t2_ph_avoid: 234,  // physics avoid mm
  qw_cfg_t2_ta1_min_lift: 235,  // task area 1 min lift station
  qw_cfg_t2_ta1_max_lift: 236,  // task area 1 max lift station
  qw_cfg_t2_ta1_min_sink: 237,  // task area 1 min sink station
  qw_cfg_t2_ta1_max_sink: 238,  // task area 1 max sink station
  qw_cfg_t2_ta2_min_lift: 239,  // task area 2 min lift station
  qw_cfg_t2_ta2_max_lift: 240,  // task area 2 max lift station
  qw_cfg_t2_ta2_min_sink: 241,  // task area 2 min sink station
  qw_cfg_t2_ta2_max_sink: 242,  // task area 2 max sink station
  qw_cfg_t2_ta3_min_lift: 243,  // task area 3 min lift station
  qw_cfg_t2_ta3_max_lift: 244,  // task area 3 max lift station
  qw_cfg_t2_ta3_min_sink: 245,  // task area 3 min sink station
  qw_cfg_t2_ta3_max_sink: 246,  // task area 3 max sink station
  qw_cfg_t3_x_min: 247,  // config X min limit mm
  qw_cfg_t3_x_max: 248,  // config X max limit mm
  qw_cfg_t3_y_min: 249,  // config Y min limit mm
  qw_cfg_t3_y_max: 250,  // config Y max limit mm
  qw_cfg_t3_x_avoid: 251,  // X avoid distance mm
  qw_cfg_t3_y_avoid: 252,  // Y avoid distance mm
  qw_cfg_t3_ph_xacc_x100: 253,  // X accel ×100 (0.01s)
  qw_cfg_t3_ph_xdec_x100: 254,  // X decel ×100 (0.01s)
  qw_cfg_t3_ph_xmax: 255,  // X max speed mm/s
  qw_cfg_t3_ph_ztot: 256,  // Z total travel mm
  qw_cfg_t3_ph_zsdry: 257,  // Z slow zone dry mm
  qw_cfg_t3_ph_zswet: 258,  // Z slow zone wet mm
  qw_cfg_t3_ph_zsend: 259,  // Z slow zone end mm
  qw_cfg_t3_ph_zslow: 260,  // Z slow speed mm/s
  qw_cfg_t3_ph_zfast: 261,  // Z fast speed mm/s
  qw_cfg_t3_ph_drip_x10: 262,  // drip delay ×10 (0.1s)
  qw_cfg_t3_ph_avoid: 263,  // physics avoid mm
  qw_cfg_t3_ta1_min_lift: 264,  // task area 1 min lift station
  qw_cfg_t3_ta1_max_lift: 265,  // task area 1 max lift station
  qw_cfg_t3_ta1_min_sink: 266,  // task area 1 min sink station
  qw_cfg_t3_ta1_max_sink: 267,  // task area 1 max sink station
  qw_cfg_t3_ta2_min_lift: 268,  // task area 2 min lift station
  qw_cfg_t3_ta2_max_lift: 269,  // task area 2 max lift station
  qw_cfg_t3_ta2_min_sink: 270,  // task area 2 min sink station
  qw_cfg_t3_ta2_max_sink: 271,  // task area 2 max sink station
  qw_cfg_t3_ta3_min_lift: 272,  // task area 3 min lift station
  qw_cfg_t3_ta3_max_lift: 273,  // task area 3 max lift station
  qw_cfg_t3_ta3_min_sink: 274,  // task area 3 min sink station
  qw_cfg_t3_ta3_max_sink: 275,  // task area 3 max sink station
  qw_s101_val: 276,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s102_val: 277,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s103_val: 278,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s104_val: 279,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s105_val: 280,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s106_val: 281,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s107_val: 282,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s108_val: 283,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s109_val: 284,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s110_val: 285,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s111_val: 286,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s112_val: 287,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s113_val: 288,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s114_val: 289,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s115_val: 290,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s116_val: 291,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s117_val: 292,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s118_val: 293,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s119_val: 294,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s120_val: 295,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s121_val: 296,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s122_val: 297,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s123_val: 298,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s124_val: 299,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s125_val: 300,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s126_val: 301,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s127_val: 302,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s128_val: 303,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s129_val: 304,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s130_val: 305,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_sched_u1_stage_cnt: 306,  // number of active stages
  qw_sched_u2_stage_cnt: 307,  // number of active stages
  qw_sched_u3_stage_cnt: 308,  // number of active stages
  qw_sched_u4_stage_cnt: 309,  // number of active stages
  qw_sched_u5_stage_cnt: 310,  // number of active stages
  qw_sched_u6_stage_cnt: 311,  // number of active stages
  qw_sched_u7_stage_cnt: 312,  // number of active stages
  qw_sched_u8_stage_cnt: 313,  // number of active stages
  qw_sched_u9_stage_cnt: 314,  // number of active stages
  qw_sched_u10_stage_cnt: 315,  // number of active stages
  qw_tq1_count: 316,  // number of active tasks
  qw_tq1_q1_unit: 317,  // task 1 unit index (0=empty)
  qw_tq1_q1_stage: 318,  // task 1 program stage
  qw_tq1_q1_lift: 319,  // task 1 pickup station
  qw_tq1_q1_sink: 320,  // task 1 putdown station
  qw_tq1_q1_start_hi: 321,  // task 1 start time upper 16
  qw_tq1_q1_start_lo: 322,  // task 1 start time lower 16
  qw_tq1_q1_fin_hi: 323,  // task 1 finish time upper 16
  qw_tq1_q1_fin_lo: 324,  // task 1 finish time lower 16
  qw_tq1_q1_calc_x10: 325,  // task 1 calc time ×10
  qw_tq1_q1_min_x10: 326,  // task 1 min time ×10
  qw_tq1_q1_max_x10: 327,  // task 1 max time ×10
  qw_tq1_q2_unit: 328,  // task 2 unit index (0=empty)
  qw_tq1_q2_stage: 329,  // task 2 program stage
  qw_tq1_q2_lift: 330,  // task 2 pickup station
  qw_tq1_q2_sink: 331,  // task 2 putdown station
  qw_tq1_q2_start_hi: 332,  // task 2 start time upper 16
  qw_tq1_q2_start_lo: 333,  // task 2 start time lower 16
  qw_tq1_q2_fin_hi: 334,  // task 2 finish time upper 16
  qw_tq1_q2_fin_lo: 335,  // task 2 finish time lower 16
  qw_tq1_q2_calc_x10: 336,  // task 2 calc time ×10
  qw_tq1_q2_min_x10: 337,  // task 2 min time ×10
  qw_tq1_q2_max_x10: 338,  // task 2 max time ×10
  qw_tq1_q3_unit: 339,  // task 3 unit index (0=empty)
  qw_tq1_q3_stage: 340,  // task 3 program stage
  qw_tq1_q3_lift: 341,  // task 3 pickup station
  qw_tq1_q3_sink: 342,  // task 3 putdown station
  qw_tq1_q3_start_hi: 343,  // task 3 start time upper 16
  qw_tq1_q3_start_lo: 344,  // task 3 start time lower 16
  qw_tq1_q3_fin_hi: 345,  // task 3 finish time upper 16
  qw_tq1_q3_fin_lo: 346,  // task 3 finish time lower 16
  qw_tq1_q3_calc_x10: 347,  // task 3 calc time ×10
  qw_tq1_q3_min_x10: 348,  // task 3 min time ×10
  qw_tq1_q3_max_x10: 349,  // task 3 max time ×10
  qw_tq1_q4_unit: 350,  // task 4 unit index (0=empty)
  qw_tq1_q4_stage: 351,  // task 4 program stage
  qw_tq1_q4_lift: 352,  // task 4 pickup station
  qw_tq1_q4_sink: 353,  // task 4 putdown station
  qw_tq1_q4_start_hi: 354,  // task 4 start time upper 16
  qw_tq1_q4_start_lo: 355,  // task 4 start time lower 16
  qw_tq1_q4_fin_hi: 356,  // task 4 finish time upper 16
  qw_tq1_q4_fin_lo: 357,  // task 4 finish time lower 16
  qw_tq1_q4_calc_x10: 358,  // task 4 calc time ×10
  qw_tq1_q4_min_x10: 359,  // task 4 min time ×10
  qw_tq1_q4_max_x10: 360,  // task 4 max time ×10
  qw_tq1_q5_unit: 361,  // task 5 unit index (0=empty)
  qw_tq1_q5_stage: 362,  // task 5 program stage
  qw_tq1_q5_lift: 363,  // task 5 pickup station
  qw_tq1_q5_sink: 364,  // task 5 putdown station
  qw_tq1_q5_start_hi: 365,  // task 5 start time upper 16
  qw_tq1_q5_start_lo: 366,  // task 5 start time lower 16
  qw_tq1_q5_fin_hi: 367,  // task 5 finish time upper 16
  qw_tq1_q5_fin_lo: 368,  // task 5 finish time lower 16
  qw_tq1_q5_calc_x10: 369,  // task 5 calc time ×10
  qw_tq1_q5_min_x10: 370,  // task 5 min time ×10
  qw_tq1_q5_max_x10: 371,  // task 5 max time ×10
  qw_tq1_q6_unit: 372,  // task 6 unit index (0=empty)
  qw_tq1_q6_stage: 373,  // task 6 program stage
  qw_tq1_q6_lift: 374,  // task 6 pickup station
  qw_tq1_q6_sink: 375,  // task 6 putdown station
  qw_tq1_q6_start_hi: 376,  // task 6 start time upper 16
  qw_tq1_q6_start_lo: 377,  // task 6 start time lower 16
  qw_tq1_q6_fin_hi: 378,  // task 6 finish time upper 16
  qw_tq1_q6_fin_lo: 379,  // task 6 finish time lower 16
  qw_tq1_q6_calc_x10: 380,  // task 6 calc time ×10
  qw_tq1_q6_min_x10: 381,  // task 6 min time ×10
  qw_tq1_q6_max_x10: 382,  // task 6 max time ×10
  qw_tq1_q7_unit: 383,  // task 7 unit index (0=empty)
  qw_tq1_q7_stage: 384,  // task 7 program stage
  qw_tq1_q7_lift: 385,  // task 7 pickup station
  qw_tq1_q7_sink: 386,  // task 7 putdown station
  qw_tq1_q7_start_hi: 387,  // task 7 start time upper 16
  qw_tq1_q7_start_lo: 388,  // task 7 start time lower 16
  qw_tq1_q7_fin_hi: 389,  // task 7 finish time upper 16
  qw_tq1_q7_fin_lo: 390,  // task 7 finish time lower 16
  qw_tq1_q7_calc_x10: 391,  // task 7 calc time ×10
  qw_tq1_q7_min_x10: 392,  // task 7 min time ×10
  qw_tq1_q7_max_x10: 393,  // task 7 max time ×10
  qw_tq1_q8_unit: 394,  // task 8 unit index (0=empty)
  qw_tq1_q8_stage: 395,  // task 8 program stage
  qw_tq1_q8_lift: 396,  // task 8 pickup station
  qw_tq1_q8_sink: 397,  // task 8 putdown station
  qw_tq1_q8_start_hi: 398,  // task 8 start time upper 16
  qw_tq1_q8_start_lo: 399,  // task 8 start time lower 16
  qw_tq1_q8_fin_hi: 400,  // task 8 finish time upper 16
  qw_tq1_q8_fin_lo: 401,  // task 8 finish time lower 16
  qw_tq1_q8_calc_x10: 402,  // task 8 calc time ×10
  qw_tq1_q8_min_x10: 403,  // task 8 min time ×10
  qw_tq1_q8_max_x10: 404,  // task 8 max time ×10
  qw_tq1_q9_unit: 405,  // task 9 unit index (0=empty)
  qw_tq1_q9_stage: 406,  // task 9 program stage
  qw_tq1_q9_lift: 407,  // task 9 pickup station
  qw_tq1_q9_sink: 408,  // task 9 putdown station
  qw_tq1_q9_start_hi: 409,  // task 9 start time upper 16
  qw_tq1_q9_start_lo: 410,  // task 9 start time lower 16
  qw_tq1_q9_fin_hi: 411,  // task 9 finish time upper 16
  qw_tq1_q9_fin_lo: 412,  // task 9 finish time lower 16
  qw_tq1_q9_calc_x10: 413,  // task 9 calc time ×10
  qw_tq1_q9_min_x10: 414,  // task 9 min time ×10
  qw_tq1_q9_max_x10: 415,  // task 9 max time ×10
  qw_tq1_q10_unit: 416,  // task 10 unit index (0=empty)
  qw_tq1_q10_stage: 417,  // task 10 program stage
  qw_tq1_q10_lift: 418,  // task 10 pickup station
  qw_tq1_q10_sink: 419,  // task 10 putdown station
  qw_tq1_q10_start_hi: 420,  // task 10 start time upper 16
  qw_tq1_q10_start_lo: 421,  // task 10 start time lower 16
  qw_tq1_q10_fin_hi: 422,  // task 10 finish time upper 16
  qw_tq1_q10_fin_lo: 423,  // task 10 finish time lower 16
  qw_tq1_q10_calc_x10: 424,  // task 10 calc time ×10
  qw_tq1_q10_min_x10: 425,  // task 10 min time ×10
  qw_tq1_q10_max_x10: 426,  // task 10 max time ×10
  qw_tq2_count: 427,  // number of active tasks
  qw_tq2_q1_unit: 428,  // task 1 unit index (0=empty)
  qw_tq2_q1_stage: 429,  // task 1 program stage
  qw_tq2_q1_lift: 430,  // task 1 pickup station
  qw_tq2_q1_sink: 431,  // task 1 putdown station
  qw_tq2_q1_start_hi: 432,  // task 1 start time upper 16
  qw_tq2_q1_start_lo: 433,  // task 1 start time lower 16
  qw_tq2_q1_fin_hi: 434,  // task 1 finish time upper 16
  qw_tq2_q1_fin_lo: 435,  // task 1 finish time lower 16
  qw_tq2_q1_calc_x10: 436,  // task 1 calc time ×10
  qw_tq2_q1_min_x10: 437,  // task 1 min time ×10
  qw_tq2_q1_max_x10: 438,  // task 1 max time ×10
  qw_tq2_q2_unit: 439,  // task 2 unit index (0=empty)
  qw_tq2_q2_stage: 440,  // task 2 program stage
  qw_tq2_q2_lift: 441,  // task 2 pickup station
  qw_tq2_q2_sink: 442,  // task 2 putdown station
  qw_tq2_q2_start_hi: 443,  // task 2 start time upper 16
  qw_tq2_q2_start_lo: 444,  // task 2 start time lower 16
  qw_tq2_q2_fin_hi: 445,  // task 2 finish time upper 16
  qw_tq2_q2_fin_lo: 446,  // task 2 finish time lower 16
  qw_tq2_q2_calc_x10: 447,  // task 2 calc time ×10
  qw_tq2_q2_min_x10: 448,  // task 2 min time ×10
  qw_tq2_q2_max_x10: 449,  // task 2 max time ×10
  qw_tq2_q3_unit: 450,  // task 3 unit index (0=empty)
  qw_tq2_q3_stage: 451,  // task 3 program stage
  qw_tq2_q3_lift: 452,  // task 3 pickup station
  qw_tq2_q3_sink: 453,  // task 3 putdown station
  qw_tq2_q3_start_hi: 454,  // task 3 start time upper 16
  qw_tq2_q3_start_lo: 455,  // task 3 start time lower 16
  qw_tq2_q3_fin_hi: 456,  // task 3 finish time upper 16
  qw_tq2_q3_fin_lo: 457,  // task 3 finish time lower 16
  qw_tq2_q3_calc_x10: 458,  // task 3 calc time ×10
  qw_tq2_q3_min_x10: 459,  // task 3 min time ×10
  qw_tq2_q3_max_x10: 460,  // task 3 max time ×10
  qw_tq2_q4_unit: 461,  // task 4 unit index (0=empty)
  qw_tq2_q4_stage: 462,  // task 4 program stage
  qw_tq2_q4_lift: 463,  // task 4 pickup station
  qw_tq2_q4_sink: 464,  // task 4 putdown station
  qw_tq2_q4_start_hi: 465,  // task 4 start time upper 16
  qw_tq2_q4_start_lo: 466,  // task 4 start time lower 16
  qw_tq2_q4_fin_hi: 467,  // task 4 finish time upper 16
  qw_tq2_q4_fin_lo: 468,  // task 4 finish time lower 16
  qw_tq2_q4_calc_x10: 469,  // task 4 calc time ×10
  qw_tq2_q4_min_x10: 470,  // task 4 min time ×10
  qw_tq2_q4_max_x10: 471,  // task 4 max time ×10
  qw_tq2_q5_unit: 472,  // task 5 unit index (0=empty)
  qw_tq2_q5_stage: 473,  // task 5 program stage
  qw_tq2_q5_lift: 474,  // task 5 pickup station
  qw_tq2_q5_sink: 475,  // task 5 putdown station
  qw_tq2_q5_start_hi: 476,  // task 5 start time upper 16
  qw_tq2_q5_start_lo: 477,  // task 5 start time lower 16
  qw_tq2_q5_fin_hi: 478,  // task 5 finish time upper 16
  qw_tq2_q5_fin_lo: 479,  // task 5 finish time lower 16
  qw_tq2_q5_calc_x10: 480,  // task 5 calc time ×10
  qw_tq2_q5_min_x10: 481,  // task 5 min time ×10
  qw_tq2_q5_max_x10: 482,  // task 5 max time ×10
  qw_tq2_q6_unit: 483,  // task 6 unit index (0=empty)
  qw_tq2_q6_stage: 484,  // task 6 program stage
  qw_tq2_q6_lift: 485,  // task 6 pickup station
  qw_tq2_q6_sink: 486,  // task 6 putdown station
  qw_tq2_q6_start_hi: 487,  // task 6 start time upper 16
  qw_tq2_q6_start_lo: 488,  // task 6 start time lower 16
  qw_tq2_q6_fin_hi: 489,  // task 6 finish time upper 16
  qw_tq2_q6_fin_lo: 490,  // task 6 finish time lower 16
  qw_tq2_q6_calc_x10: 491,  // task 6 calc time ×10
  qw_tq2_q6_min_x10: 492,  // task 6 min time ×10
  qw_tq2_q6_max_x10: 493,  // task 6 max time ×10
  qw_tq2_q7_unit: 494,  // task 7 unit index (0=empty)
  qw_tq2_q7_stage: 495,  // task 7 program stage
  qw_tq2_q7_lift: 496,  // task 7 pickup station
  qw_tq2_q7_sink: 497,  // task 7 putdown station
  qw_tq2_q7_start_hi: 498,  // task 7 start time upper 16
  qw_tq2_q7_start_lo: 499,  // task 7 start time lower 16
  qw_tq2_q7_fin_hi: 500,  // task 7 finish time upper 16
  qw_tq2_q7_fin_lo: 501,  // task 7 finish time lower 16
  qw_tq2_q7_calc_x10: 502,  // task 7 calc time ×10
  qw_tq2_q7_min_x10: 503,  // task 7 min time ×10
  qw_tq2_q7_max_x10: 504,  // task 7 max time ×10
  qw_tq2_q8_unit: 505,  // task 8 unit index (0=empty)
  qw_tq2_q8_stage: 506,  // task 8 program stage
  qw_tq2_q8_lift: 507,  // task 8 pickup station
  qw_tq2_q8_sink: 508,  // task 8 putdown station
  qw_tq2_q8_start_hi: 509,  // task 8 start time upper 16
  qw_tq2_q8_start_lo: 510,  // task 8 start time lower 16
  qw_tq2_q8_fin_hi: 511,  // task 8 finish time upper 16
  qw_tq2_q8_fin_lo: 512,  // task 8 finish time lower 16
  qw_tq2_q8_calc_x10: 513,  // task 8 calc time ×10
  qw_tq2_q8_min_x10: 514,  // task 8 min time ×10
  qw_tq2_q8_max_x10: 515,  // task 8 max time ×10
  qw_tq2_q9_unit: 516,  // task 9 unit index (0=empty)
  qw_tq2_q9_stage: 517,  // task 9 program stage
  qw_tq2_q9_lift: 518,  // task 9 pickup station
  qw_tq2_q9_sink: 519,  // task 9 putdown station
  qw_tq2_q9_start_hi: 520,  // task 9 start time upper 16
  qw_tq2_q9_start_lo: 521,  // task 9 start time lower 16
  qw_tq2_q9_fin_hi: 522,  // task 9 finish time upper 16
  qw_tq2_q9_fin_lo: 523,  // task 9 finish time lower 16
  qw_tq2_q9_calc_x10: 524,  // task 9 calc time ×10
  qw_tq2_q9_min_x10: 525,  // task 9 min time ×10
  qw_tq2_q9_max_x10: 526,  // task 9 max time ×10
  qw_tq2_q10_unit: 527,  // task 10 unit index (0=empty)
  qw_tq2_q10_stage: 528,  // task 10 program stage
  qw_tq2_q10_lift: 529,  // task 10 pickup station
  qw_tq2_q10_sink: 530,  // task 10 putdown station
  qw_tq2_q10_start_hi: 531,  // task 10 start time upper 16
  qw_tq2_q10_start_lo: 532,  // task 10 start time lower 16
  qw_tq2_q10_fin_hi: 533,  // task 10 finish time upper 16
  qw_tq2_q10_fin_lo: 534,  // task 10 finish time lower 16
  qw_tq2_q10_calc_x10: 535,  // task 10 calc time ×10
  qw_tq2_q10_min_x10: 536,  // task 10 min time ×10
  qw_tq2_q10_max_x10: 537,  // task 10 max time ×10
  qw_tq3_count: 538,  // number of active tasks
  qw_tq3_q1_unit: 539,  // task 1 unit index (0=empty)
  qw_tq3_q1_stage: 540,  // task 1 program stage
  qw_tq3_q1_lift: 541,  // task 1 pickup station
  qw_tq3_q1_sink: 542,  // task 1 putdown station
  qw_tq3_q1_start_hi: 543,  // task 1 start time upper 16
  qw_tq3_q1_start_lo: 544,  // task 1 start time lower 16
  qw_tq3_q1_fin_hi: 545,  // task 1 finish time upper 16
  qw_tq3_q1_fin_lo: 546,  // task 1 finish time lower 16
  qw_tq3_q1_calc_x10: 547,  // task 1 calc time ×10
  qw_tq3_q1_min_x10: 548,  // task 1 min time ×10
  qw_tq3_q1_max_x10: 549,  // task 1 max time ×10
  qw_tq3_q2_unit: 550,  // task 2 unit index (0=empty)
  qw_tq3_q2_stage: 551,  // task 2 program stage
  qw_tq3_q2_lift: 552,  // task 2 pickup station
  qw_tq3_q2_sink: 553,  // task 2 putdown station
  qw_tq3_q2_start_hi: 554,  // task 2 start time upper 16
  qw_tq3_q2_start_lo: 555,  // task 2 start time lower 16
  qw_tq3_q2_fin_hi: 556,  // task 2 finish time upper 16
  qw_tq3_q2_fin_lo: 557,  // task 2 finish time lower 16
  qw_tq3_q2_calc_x10: 558,  // task 2 calc time ×10
  qw_tq3_q2_min_x10: 559,  // task 2 min time ×10
  qw_tq3_q2_max_x10: 560,  // task 2 max time ×10
  qw_tq3_q3_unit: 561,  // task 3 unit index (0=empty)
  qw_tq3_q3_stage: 562,  // task 3 program stage
  qw_tq3_q3_lift: 563,  // task 3 pickup station
  qw_tq3_q3_sink: 564,  // task 3 putdown station
  qw_tq3_q3_start_hi: 565,  // task 3 start time upper 16
  qw_tq3_q3_start_lo: 566,  // task 3 start time lower 16
  qw_tq3_q3_fin_hi: 567,  // task 3 finish time upper 16
  qw_tq3_q3_fin_lo: 568,  // task 3 finish time lower 16
  qw_tq3_q3_calc_x10: 569,  // task 3 calc time ×10
  qw_tq3_q3_min_x10: 570,  // task 3 min time ×10
  qw_tq3_q3_max_x10: 571,  // task 3 max time ×10
  qw_tq3_q4_unit: 572,  // task 4 unit index (0=empty)
  qw_tq3_q4_stage: 573,  // task 4 program stage
  qw_tq3_q4_lift: 574,  // task 4 pickup station
  qw_tq3_q4_sink: 575,  // task 4 putdown station
  qw_tq3_q4_start_hi: 576,  // task 4 start time upper 16
  qw_tq3_q4_start_lo: 577,  // task 4 start time lower 16
  qw_tq3_q4_fin_hi: 578,  // task 4 finish time upper 16
  qw_tq3_q4_fin_lo: 579,  // task 4 finish time lower 16
  qw_tq3_q4_calc_x10: 580,  // task 4 calc time ×10
  qw_tq3_q4_min_x10: 581,  // task 4 min time ×10
  qw_tq3_q4_max_x10: 582,  // task 4 max time ×10
  qw_tq3_q5_unit: 583,  // task 5 unit index (0=empty)
  qw_tq3_q5_stage: 584,  // task 5 program stage
  qw_tq3_q5_lift: 585,  // task 5 pickup station
  qw_tq3_q5_sink: 586,  // task 5 putdown station
  qw_tq3_q5_start_hi: 587,  // task 5 start time upper 16
  qw_tq3_q5_start_lo: 588,  // task 5 start time lower 16
  qw_tq3_q5_fin_hi: 589,  // task 5 finish time upper 16
  qw_tq3_q5_fin_lo: 590,  // task 5 finish time lower 16
  qw_tq3_q5_calc_x10: 591,  // task 5 calc time ×10
  qw_tq3_q5_min_x10: 592,  // task 5 min time ×10
  qw_tq3_q5_max_x10: 593,  // task 5 max time ×10
  qw_tq3_q6_unit: 594,  // task 6 unit index (0=empty)
  qw_tq3_q6_stage: 595,  // task 6 program stage
  qw_tq3_q6_lift: 596,  // task 6 pickup station
  qw_tq3_q6_sink: 597,  // task 6 putdown station
  qw_tq3_q6_start_hi: 598,  // task 6 start time upper 16
  qw_tq3_q6_start_lo: 599,  // task 6 start time lower 16
  qw_tq3_q6_fin_hi: 600,  // task 6 finish time upper 16
  qw_tq3_q6_fin_lo: 601,  // task 6 finish time lower 16
  qw_tq3_q6_calc_x10: 602,  // task 6 calc time ×10
  qw_tq3_q6_min_x10: 603,  // task 6 min time ×10
  qw_tq3_q6_max_x10: 604,  // task 6 max time ×10
  qw_tq3_q7_unit: 605,  // task 7 unit index (0=empty)
  qw_tq3_q7_stage: 606,  // task 7 program stage
  qw_tq3_q7_lift: 607,  // task 7 pickup station
  qw_tq3_q7_sink: 608,  // task 7 putdown station
  qw_tq3_q7_start_hi: 609,  // task 7 start time upper 16
  qw_tq3_q7_start_lo: 610,  // task 7 start time lower 16
  qw_tq3_q7_fin_hi: 611,  // task 7 finish time upper 16
  qw_tq3_q7_fin_lo: 612,  // task 7 finish time lower 16
  qw_tq3_q7_calc_x10: 613,  // task 7 calc time ×10
  qw_tq3_q7_min_x10: 614,  // task 7 min time ×10
  qw_tq3_q7_max_x10: 615,  // task 7 max time ×10
  qw_tq3_q8_unit: 616,  // task 8 unit index (0=empty)
  qw_tq3_q8_stage: 617,  // task 8 program stage
  qw_tq3_q8_lift: 618,  // task 8 pickup station
  qw_tq3_q8_sink: 619,  // task 8 putdown station
  qw_tq3_q8_start_hi: 620,  // task 8 start time upper 16
  qw_tq3_q8_start_lo: 621,  // task 8 start time lower 16
  qw_tq3_q8_fin_hi: 622,  // task 8 finish time upper 16
  qw_tq3_q8_fin_lo: 623,  // task 8 finish time lower 16
  qw_tq3_q8_calc_x10: 624,  // task 8 calc time ×10
  qw_tq3_q8_min_x10: 625,  // task 8 min time ×10
  qw_tq3_q8_max_x10: 626,  // task 8 max time ×10
  qw_tq3_q9_unit: 627,  // task 9 unit index (0=empty)
  qw_tq3_q9_stage: 628,  // task 9 program stage
  qw_tq3_q9_lift: 629,  // task 9 pickup station
  qw_tq3_q9_sink: 630,  // task 9 putdown station
  qw_tq3_q9_start_hi: 631,  // task 9 start time upper 16
  qw_tq3_q9_start_lo: 632,  // task 9 start time lower 16
  qw_tq3_q9_fin_hi: 633,  // task 9 finish time upper 16
  qw_tq3_q9_fin_lo: 634,  // task 9 finish time lower 16
  qw_tq3_q9_calc_x10: 635,  // task 9 calc time ×10
  qw_tq3_q9_min_x10: 636,  // task 9 min time ×10
  qw_tq3_q9_max_x10: 637,  // task 9 max time ×10
  qw_tq3_q10_unit: 638,  // task 10 unit index (0=empty)
  qw_tq3_q10_stage: 639,  // task 10 program stage
  qw_tq3_q10_lift: 640,  // task 10 pickup station
  qw_tq3_q10_sink: 641,  // task 10 putdown station
  qw_tq3_q10_start_hi: 642,  // task 10 start time upper 16
  qw_tq3_q10_start_lo: 643,  // task 10 start time lower 16
  qw_tq3_q10_fin_hi: 644,  // task 10 finish time upper 16
  qw_tq3_q10_fin_lo: 645,  // task 10 finish time lower 16
  qw_tq3_q10_calc_x10: 646,  // task 10 calc time ×10
  qw_tq3_q10_min_x10: 647,  // task 10 min time ×10
  qw_tq3_q10_max_x10: 648,  // task 10 max time ×10
  qw_dep_state_activated: 649,  // 1=departure activated handshake
  qw_dep_state_stable: 650,  // 1=task list stable for DEP
  qw_dep_state_waiting_cnt: 651,  // waiting batch count
  qw_dep_state_overlap_cnt: 652,  // overlap station count
  qw_dep_state_pend_valid: 653,  // 1=pending write valid
  qw_dep_state_pend_unit: 654,  // pending activated unit
  qw_dep_state_pend_stage: 655,  // pending activated stage
  qw_dep_state_pend_time_hi: 656,  // pending activation time upper 16
  qw_dep_state_pend_time_lo: 657,  // pending activation time lower 16
  qw_dw1_unit: 658,  // waiting batch unit index (0=empty)
  qw_dw2_unit: 659,  // waiting batch unit index (0=empty)
  qw_dw3_unit: 660,  // waiting batch unit index (0=empty)
  qw_dw4_unit: 661,  // waiting batch unit index (0=empty)
  qw_dw5_unit: 662,  // waiting batch unit index (0=empty)
  qw_ov_s101_flag: 663,  // 1=station in overlap zone
  qw_ov_s102_flag: 664,  // 1=station in overlap zone
  qw_ov_s103_flag: 665,  // 1=station in overlap zone
  qw_ov_s104_flag: 666,  // 1=station in overlap zone
  qw_ov_s105_flag: 667,  // 1=station in overlap zone
  qw_ov_s106_flag: 668,  // 1=station in overlap zone
  qw_ov_s107_flag: 669,  // 1=station in overlap zone
  qw_ov_s108_flag: 670,  // 1=station in overlap zone
  qw_ov_s109_flag: 671,  // 1=station in overlap zone
  qw_ov_s110_flag: 672,  // 1=station in overlap zone
  qw_ov_s111_flag: 673,  // 1=station in overlap zone
  qw_ov_s112_flag: 674,  // 1=station in overlap zone
  qw_ov_s113_flag: 675,  // 1=station in overlap zone
  qw_ov_s114_flag: 676,  // 1=station in overlap zone
  qw_ov_s115_flag: 677,  // 1=station in overlap zone
  qw_ov_s116_flag: 678,  // 1=station in overlap zone
  qw_ov_s117_flag: 679,  // 1=station in overlap zone
  qw_ov_s118_flag: 680,  // 1=station in overlap zone
  qw_ov_s119_flag: 681,  // 1=station in overlap zone
  qw_ov_s120_flag: 682,  // 1=station in overlap zone
  qw_ov_s121_flag: 683,  // 1=station in overlap zone
  qw_ov_s122_flag: 684,  // 1=station in overlap zone
  qw_ov_s123_flag: 685,  // 1=station in overlap zone
  qw_ov_s124_flag: 686,  // 1=station in overlap zone
  qw_ov_s125_flag: 687,  // 1=station in overlap zone
  qw_ov_s126_flag: 688,  // 1=station in overlap zone
  qw_ov_s127_flag: 689,  // 1=station in overlap zone
  qw_ov_s128_flag: 690,  // 1=station in overlap zone
  qw_ov_s129_flag: 691,  // 1=station in overlap zone
  qw_ov_s130_flag: 692,  // 1=station in overlap zone
  iw_cmd_t1_start: 693,  // 1=trigger command
  iw_cmd_t1_lift: 694,  // lift station number
  iw_cmd_t1_sink: 695,  // sink station number
  iw_cmd_t2_start: 696,  // 1=trigger command
  iw_cmd_t2_lift: 697,  // lift station number
  iw_cmd_t2_sink: 698,  // sink station number
  iw_cfg_seq: 699,  // sequence — triggers on change
  iw_cfg_cmd: 700,  // 1=write_station, 2=init, 3=clear_all
  iw_cfg_param: 701,  // station_number or station_count
  iw_cfg_d0: 702,  // tank_id
  iw_cfg_d1: 703,  // x_position mm
  iw_cfg_d2: 704,  // y_position mm
  iw_cfg_d3: 705,  // z_position mm
  iw_cfg_d4: 706,  // operation
  iw_cfg_d5: 707,  // dropping_time ×10
  iw_cfg_d6: 708,  // device_delay ×10
  iw_cfg_d7: 709,  // kind (0=dry, 1=wet)
  iw_unit_seq: 710,  // sequence — triggers on change
  iw_unit_id: 711,  // unit number 1..10
  iw_unit_loc: 712,  // location (station number)
  iw_unit_status: 713,  // NOT_USED=0, USED=1
  iw_unit_target: 714,  // TO_NONE=0..TO_AVOID=5
  iw_batch_seq: 715,  // sequence — triggers on change
  iw_batch_unit: 716,  // unit index 1..10
  iw_batch_code: 717,  // numeric batch code
  iw_batch_state: 718,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  iw_batch_prog_id: 719,  // treatment program ID
  iw_prog_seq: 720,  // sequence — triggers on change
  iw_prog_unit: 721,  // unit index 1..10
  iw_prog_stage: 722,  // stage index 1..30
  iw_prog_s1: 723,  // station 1 (0=unused)
  iw_prog_s2: 724,  // station 2
  iw_prog_s3: 725,  // station 3
  iw_prog_s4: 726,  // station 4
  iw_prog_s5: 727,  // station 5
  iw_prog_min_time: 728,  // min processing time seconds
  iw_prog_max_time: 729,  // max processing time seconds
  iw_prog_cal_time: 730,  // calculated time seconds
  iw_avoid_seq: 731,  // sequence — triggers on change
  iw_avoid_station: 732,  // station number
  iw_avoid_value: 733,  // AVOID_NONE=0, PASS=1, BLOCK=2
  iw_production_queue: 734,  // 1=batches in queue, 0=empty
  iw_time_hi: 735,  // unix seconds upper 16 bits
  iw_time_lo: 736,  // unix seconds lower 16 bits
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
  state.batch_state[2] = {};
  state.batch_state[2].batch_code = toSigned(r[130]);
  state.batch_state[2].batch_state = toSigned(r[131]);
  state.batch_state[2].batch_program = toSigned(r[132]);
  state.batch_state[2].batch_stage = toSigned(r[133]);
  state.batch_state[3] = {};
  state.batch_state[3].batch_code = toSigned(r[134]);
  state.batch_state[3].batch_state = toSigned(r[135]);
  state.batch_state[3].batch_program = toSigned(r[136]);
  state.batch_state[3].batch_stage = toSigned(r[137]);
  state.batch_state[4] = {};
  state.batch_state[4].batch_code = toSigned(r[138]);
  state.batch_state[4].batch_state = toSigned(r[139]);
  state.batch_state[4].batch_program = toSigned(r[140]);
  state.batch_state[4].batch_stage = toSigned(r[141]);
  state.batch_state[5] = {};
  state.batch_state[5].batch_code = toSigned(r[142]);
  state.batch_state[5].batch_state = toSigned(r[143]);
  state.batch_state[5].batch_program = toSigned(r[144]);
  state.batch_state[5].batch_stage = toSigned(r[145]);
  state.batch_state[6] = {};
  state.batch_state[6].batch_code = toSigned(r[146]);
  state.batch_state[6].batch_state = toSigned(r[147]);
  state.batch_state[6].batch_program = toSigned(r[148]);
  state.batch_state[6].batch_stage = toSigned(r[149]);
  state.batch_state[7] = {};
  state.batch_state[7].batch_code = toSigned(r[150]);
  state.batch_state[7].batch_state = toSigned(r[151]);
  state.batch_state[7].batch_program = toSigned(r[152]);
  state.batch_state[7].batch_stage = toSigned(r[153]);
  state.batch_state[8] = {};
  state.batch_state[8].batch_code = toSigned(r[154]);
  state.batch_state[8].batch_state = toSigned(r[155]);
  state.batch_state[8].batch_program = toSigned(r[156]);
  state.batch_state[8].batch_stage = toSigned(r[157]);
  state.batch_state[9] = {};
  state.batch_state[9].batch_code = toSigned(r[158]);
  state.batch_state[9].batch_state = toSigned(r[159]);
  state.batch_state[9].batch_program = toSigned(r[160]);
  state.batch_state[9].batch_stage = toSigned(r[161]);
  state.batch_state[10] = {};
  state.batch_state[10].batch_code = toSigned(r[162]);
  state.batch_state[10].batch_state = toSigned(r[163]);
  state.batch_state[10].batch_program = toSigned(r[164]);
  state.batch_state[10].batch_stage = toSigned(r[165]);
  // --- calibration ---
  state.calibration = {};
  state.calibration.cal_step = toSigned(r[166]);
  state.calibration.cal_tid = toSigned(r[167]);
  // --- calibration_results ---
  if (!state.calibration_results) state.calibration_results = {};
  state.calibration_results[1] = {};
  state.calibration_results[1].lift_wet = toSigned(r[168]) * 0.1;
  state.calibration_results[1].sink_wet = toSigned(r[169]) * 0.1;
  state.calibration_results[1].lift_dry = toSigned(r[170]) * 0.1;
  state.calibration_results[1].sink_dry = toSigned(r[171]) * 0.1;
  state.calibration_results[1].x_acc = toSigned(r[172]) * 0.1;
  state.calibration_results[1].x_dec = toSigned(r[173]) * 0.1;
  state.calibration_results[1].x_max = toSigned(r[174]);
  state.calibration_results[2] = {};
  state.calibration_results[2].lift_wet = toSigned(r[175]) * 0.1;
  state.calibration_results[2].sink_wet = toSigned(r[176]) * 0.1;
  state.calibration_results[2].lift_dry = toSigned(r[177]) * 0.1;
  state.calibration_results[2].sink_dry = toSigned(r[178]) * 0.1;
  state.calibration_results[2].x_acc = toSigned(r[179]) * 0.1;
  state.calibration_results[2].x_dec = toSigned(r[180]) * 0.1;
  state.calibration_results[2].x_max = toSigned(r[181]);
  state.calibration_results[3] = {};
  state.calibration_results[3].lift_wet = toSigned(r[182]) * 0.1;
  state.calibration_results[3].sink_wet = toSigned(r[183]) * 0.1;
  state.calibration_results[3].lift_dry = toSigned(r[184]) * 0.1;
  state.calibration_results[3].sink_dry = toSigned(r[185]) * 0.1;
  state.calibration_results[3].x_acc = toSigned(r[186]) * 0.1;
  state.calibration_results[3].x_dec = toSigned(r[187]) * 0.1;
  state.calibration_results[3].x_max = toSigned(r[188]);
  // --- transporter_config ---
  if (!state.transporter_config) state.transporter_config = {};
  state.transporter_config[1] = {};
  state.transporter_config[1].x_min_limit = toSigned(r[189]);
  state.transporter_config[1].x_max_limit = toSigned(r[190]);
  state.transporter_config[1].y_min_limit = toSigned(r[191]);
  state.transporter_config[1].y_max_limit = toSigned(r[192]);
  state.transporter_config[1].x_avoid_mm = toSigned(r[193]);
  state.transporter_config[1].y_avoid_mm = toSigned(r[194]);
  state.transporter_config[1].phys_x_accel = toSigned(r[195]) * 0.01;
  state.transporter_config[1].phys_x_decel = toSigned(r[196]) * 0.01;
  state.transporter_config[1].phys_x_max = toSigned(r[197]);
  state.transporter_config[1].phys_z_total = toSigned(r[198]);
  state.transporter_config[1].phys_z_sdry = toSigned(r[199]);
  state.transporter_config[1].phys_z_swet = toSigned(r[200]);
  state.transporter_config[1].phys_z_send = toSigned(r[201]);
  state.transporter_config[1].phys_z_slow = toSigned(r[202]);
  state.transporter_config[1].phys_z_fast = toSigned(r[203]);
  state.transporter_config[1].phys_drip = toSigned(r[204]) * 0.1;
  state.transporter_config[1].phys_avoid = toSigned(r[205]);
  state.transporter_config[1].ta1_min_lift = toSigned(r[206]);
  state.transporter_config[1].ta1_max_lift = toSigned(r[207]);
  state.transporter_config[1].ta1_min_sink = toSigned(r[208]);
  state.transporter_config[1].ta1_max_sink = toSigned(r[209]);
  state.transporter_config[1].ta2_min_lift = toSigned(r[210]);
  state.transporter_config[1].ta2_max_lift = toSigned(r[211]);
  state.transporter_config[1].ta2_min_sink = toSigned(r[212]);
  state.transporter_config[1].ta2_max_sink = toSigned(r[213]);
  state.transporter_config[1].ta3_min_lift = toSigned(r[214]);
  state.transporter_config[1].ta3_max_lift = toSigned(r[215]);
  state.transporter_config[1].ta3_min_sink = toSigned(r[216]);
  state.transporter_config[1].ta3_max_sink = toSigned(r[217]);
  state.transporter_config[2] = {};
  state.transporter_config[2].x_min_limit = toSigned(r[218]);
  state.transporter_config[2].x_max_limit = toSigned(r[219]);
  state.transporter_config[2].y_min_limit = toSigned(r[220]);
  state.transporter_config[2].y_max_limit = toSigned(r[221]);
  state.transporter_config[2].x_avoid_mm = toSigned(r[222]);
  state.transporter_config[2].y_avoid_mm = toSigned(r[223]);
  state.transporter_config[2].phys_x_accel = toSigned(r[224]) * 0.01;
  state.transporter_config[2].phys_x_decel = toSigned(r[225]) * 0.01;
  state.transporter_config[2].phys_x_max = toSigned(r[226]);
  state.transporter_config[2].phys_z_total = toSigned(r[227]);
  state.transporter_config[2].phys_z_sdry = toSigned(r[228]);
  state.transporter_config[2].phys_z_swet = toSigned(r[229]);
  state.transporter_config[2].phys_z_send = toSigned(r[230]);
  state.transporter_config[2].phys_z_slow = toSigned(r[231]);
  state.transporter_config[2].phys_z_fast = toSigned(r[232]);
  state.transporter_config[2].phys_drip = toSigned(r[233]) * 0.1;
  state.transporter_config[2].phys_avoid = toSigned(r[234]);
  state.transporter_config[2].ta1_min_lift = toSigned(r[235]);
  state.transporter_config[2].ta1_max_lift = toSigned(r[236]);
  state.transporter_config[2].ta1_min_sink = toSigned(r[237]);
  state.transporter_config[2].ta1_max_sink = toSigned(r[238]);
  state.transporter_config[2].ta2_min_lift = toSigned(r[239]);
  state.transporter_config[2].ta2_max_lift = toSigned(r[240]);
  state.transporter_config[2].ta2_min_sink = toSigned(r[241]);
  state.transporter_config[2].ta2_max_sink = toSigned(r[242]);
  state.transporter_config[2].ta3_min_lift = toSigned(r[243]);
  state.transporter_config[2].ta3_max_lift = toSigned(r[244]);
  state.transporter_config[2].ta3_min_sink = toSigned(r[245]);
  state.transporter_config[2].ta3_max_sink = toSigned(r[246]);
  state.transporter_config[3] = {};
  state.transporter_config[3].x_min_limit = toSigned(r[247]);
  state.transporter_config[3].x_max_limit = toSigned(r[248]);
  state.transporter_config[3].y_min_limit = toSigned(r[249]);
  state.transporter_config[3].y_max_limit = toSigned(r[250]);
  state.transporter_config[3].x_avoid_mm = toSigned(r[251]);
  state.transporter_config[3].y_avoid_mm = toSigned(r[252]);
  state.transporter_config[3].phys_x_accel = toSigned(r[253]) * 0.01;
  state.transporter_config[3].phys_x_decel = toSigned(r[254]) * 0.01;
  state.transporter_config[3].phys_x_max = toSigned(r[255]);
  state.transporter_config[3].phys_z_total = toSigned(r[256]);
  state.transporter_config[3].phys_z_sdry = toSigned(r[257]);
  state.transporter_config[3].phys_z_swet = toSigned(r[258]);
  state.transporter_config[3].phys_z_send = toSigned(r[259]);
  state.transporter_config[3].phys_z_slow = toSigned(r[260]);
  state.transporter_config[3].phys_z_fast = toSigned(r[261]);
  state.transporter_config[3].phys_drip = toSigned(r[262]) * 0.1;
  state.transporter_config[3].phys_avoid = toSigned(r[263]);
  state.transporter_config[3].ta1_min_lift = toSigned(r[264]);
  state.transporter_config[3].ta1_max_lift = toSigned(r[265]);
  state.transporter_config[3].ta1_min_sink = toSigned(r[266]);
  state.transporter_config[3].ta1_max_sink = toSigned(r[267]);
  state.transporter_config[3].ta2_min_lift = toSigned(r[268]);
  state.transporter_config[3].ta2_max_lift = toSigned(r[269]);
  state.transporter_config[3].ta2_min_sink = toSigned(r[270]);
  state.transporter_config[3].ta2_max_sink = toSigned(r[271]);
  state.transporter_config[3].ta3_min_lift = toSigned(r[272]);
  state.transporter_config[3].ta3_max_lift = toSigned(r[273]);
  state.transporter_config[3].ta3_min_sink = toSigned(r[274]);
  state.transporter_config[3].ta3_max_sink = toSigned(r[275]);
  state.avoid_status[101] = {};
  state.avoid_status[101].avoid_val = toSigned(r[276]);
  state.avoid_status[102] = {};
  state.avoid_status[102].avoid_val = toSigned(r[277]);
  state.avoid_status[103] = {};
  state.avoid_status[103].avoid_val = toSigned(r[278]);
  state.avoid_status[104] = {};
  state.avoid_status[104].avoid_val = toSigned(r[279]);
  state.avoid_status[105] = {};
  state.avoid_status[105].avoid_val = toSigned(r[280]);
  state.avoid_status[106] = {};
  state.avoid_status[106].avoid_val = toSigned(r[281]);
  state.avoid_status[107] = {};
  state.avoid_status[107].avoid_val = toSigned(r[282]);
  state.avoid_status[108] = {};
  state.avoid_status[108].avoid_val = toSigned(r[283]);
  state.avoid_status[109] = {};
  state.avoid_status[109].avoid_val = toSigned(r[284]);
  state.avoid_status[110] = {};
  state.avoid_status[110].avoid_val = toSigned(r[285]);
  state.avoid_status[111] = {};
  state.avoid_status[111].avoid_val = toSigned(r[286]);
  state.avoid_status[112] = {};
  state.avoid_status[112].avoid_val = toSigned(r[287]);
  state.avoid_status[113] = {};
  state.avoid_status[113].avoid_val = toSigned(r[288]);
  state.avoid_status[114] = {};
  state.avoid_status[114].avoid_val = toSigned(r[289]);
  state.avoid_status[115] = {};
  state.avoid_status[115].avoid_val = toSigned(r[290]);
  state.avoid_status[116] = {};
  state.avoid_status[116].avoid_val = toSigned(r[291]);
  state.avoid_status[117] = {};
  state.avoid_status[117].avoid_val = toSigned(r[292]);
  state.avoid_status[118] = {};
  state.avoid_status[118].avoid_val = toSigned(r[293]);
  state.avoid_status[119] = {};
  state.avoid_status[119].avoid_val = toSigned(r[294]);
  state.avoid_status[120] = {};
  state.avoid_status[120].avoid_val = toSigned(r[295]);
  state.avoid_status[121] = {};
  state.avoid_status[121].avoid_val = toSigned(r[296]);
  state.avoid_status[122] = {};
  state.avoid_status[122].avoid_val = toSigned(r[297]);
  state.avoid_status[123] = {};
  state.avoid_status[123].avoid_val = toSigned(r[298]);
  state.avoid_status[124] = {};
  state.avoid_status[124].avoid_val = toSigned(r[299]);
  state.avoid_status[125] = {};
  state.avoid_status[125].avoid_val = toSigned(r[300]);
  state.avoid_status[126] = {};
  state.avoid_status[126].avoid_val = toSigned(r[301]);
  state.avoid_status[127] = {};
  state.avoid_status[127].avoid_val = toSigned(r[302]);
  state.avoid_status[128] = {};
  state.avoid_status[128].avoid_val = toSigned(r[303]);
  state.avoid_status[129] = {};
  state.avoid_status[129].avoid_val = toSigned(r[304]);
  state.avoid_status[130] = {};
  state.avoid_status[130].avoid_val = toSigned(r[305]);
  // --- schedule_summary ---
  if (!state.schedule_summary) state.schedule_summary = {};
  state.schedule_summary[1] = {};
  state.schedule_summary[1].stage_count = toSigned(r[306]);
  state.schedule_summary[2] = {};
  state.schedule_summary[2].stage_count = toSigned(r[307]);
  state.schedule_summary[3] = {};
  state.schedule_summary[3].stage_count = toSigned(r[308]);
  state.schedule_summary[4] = {};
  state.schedule_summary[4].stage_count = toSigned(r[309]);
  state.schedule_summary[5] = {};
  state.schedule_summary[5].stage_count = toSigned(r[310]);
  state.schedule_summary[6] = {};
  state.schedule_summary[6].stage_count = toSigned(r[311]);
  state.schedule_summary[7] = {};
  state.schedule_summary[7].stage_count = toSigned(r[312]);
  state.schedule_summary[8] = {};
  state.schedule_summary[8].stage_count = toSigned(r[313]);
  state.schedule_summary[9] = {};
  state.schedule_summary[9].stage_count = toSigned(r[314]);
  state.schedule_summary[10] = {};
  state.schedule_summary[10].stage_count = toSigned(r[315]);
  // --- task_queue ---
  if (!state.task_queue) state.task_queue = {};
  state.task_queue[1] = {};
  state.task_queue[1].task_count = toSigned(r[316]);
  state.task_queue[1].q1_unit = toSigned(r[317]);
  state.task_queue[1].q1_stage = toSigned(r[318]);
  state.task_queue[1].q1_lift = toSigned(r[319]);
  state.task_queue[1].q1_sink = toSigned(r[320]);
  state.task_queue[1]._q1_start_hi = r[321];
  state.task_queue[1]._q1_start_lo = r[322];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[1].q1_start_time = ((state.task_queue[1]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_start_lo & 0xFFFF);
  state.task_queue[1]._q1_fin_hi = r[323];
  state.task_queue[1]._q1_fin_lo = r[324];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[1].q1_finish_time = ((state.task_queue[1]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_fin_lo & 0xFFFF);
  state.task_queue[1].q1_calc_time = toSigned(r[325]) * 0.1;
  state.task_queue[1].q1_min_time = toSigned(r[326]) * 0.1;
  state.task_queue[1].q1_max_time = toSigned(r[327]) * 0.1;
  state.task_queue[1].q2_unit = toSigned(r[328]);
  state.task_queue[1].q2_stage = toSigned(r[329]);
  state.task_queue[1].q2_lift = toSigned(r[330]);
  state.task_queue[1].q2_sink = toSigned(r[331]);
  state.task_queue[1]._q2_start_hi = r[332];
  state.task_queue[1]._q2_start_lo = r[333];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[1].q2_start_time = ((state.task_queue[1]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_start_lo & 0xFFFF);
  state.task_queue[1]._q2_fin_hi = r[334];
  state.task_queue[1]._q2_fin_lo = r[335];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[1].q2_finish_time = ((state.task_queue[1]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_fin_lo & 0xFFFF);
  state.task_queue[1].q2_calc_time = toSigned(r[336]) * 0.1;
  state.task_queue[1].q2_min_time = toSigned(r[337]) * 0.1;
  state.task_queue[1].q2_max_time = toSigned(r[338]) * 0.1;
  state.task_queue[1].q3_unit = toSigned(r[339]);
  state.task_queue[1].q3_stage = toSigned(r[340]);
  state.task_queue[1].q3_lift = toSigned(r[341]);
  state.task_queue[1].q3_sink = toSigned(r[342]);
  state.task_queue[1]._q3_start_hi = r[343];
  state.task_queue[1]._q3_start_lo = r[344];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[1].q3_start_time = ((state.task_queue[1]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_start_lo & 0xFFFF);
  state.task_queue[1]._q3_fin_hi = r[345];
  state.task_queue[1]._q3_fin_lo = r[346];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[1].q3_finish_time = ((state.task_queue[1]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_fin_lo & 0xFFFF);
  state.task_queue[1].q3_calc_time = toSigned(r[347]) * 0.1;
  state.task_queue[1].q3_min_time = toSigned(r[348]) * 0.1;
  state.task_queue[1].q3_max_time = toSigned(r[349]) * 0.1;
  state.task_queue[1].q4_unit = toSigned(r[350]);
  state.task_queue[1].q4_stage = toSigned(r[351]);
  state.task_queue[1].q4_lift = toSigned(r[352]);
  state.task_queue[1].q4_sink = toSigned(r[353]);
  state.task_queue[1]._q4_start_hi = r[354];
  state.task_queue[1]._q4_start_lo = r[355];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[1].q4_start_time = ((state.task_queue[1]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_start_lo & 0xFFFF);
  state.task_queue[1]._q4_fin_hi = r[356];
  state.task_queue[1]._q4_fin_lo = r[357];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[1].q4_finish_time = ((state.task_queue[1]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_fin_lo & 0xFFFF);
  state.task_queue[1].q4_calc_time = toSigned(r[358]) * 0.1;
  state.task_queue[1].q4_min_time = toSigned(r[359]) * 0.1;
  state.task_queue[1].q4_max_time = toSigned(r[360]) * 0.1;
  state.task_queue[1].q5_unit = toSigned(r[361]);
  state.task_queue[1].q5_stage = toSigned(r[362]);
  state.task_queue[1].q5_lift = toSigned(r[363]);
  state.task_queue[1].q5_sink = toSigned(r[364]);
  state.task_queue[1]._q5_start_hi = r[365];
  state.task_queue[1]._q5_start_lo = r[366];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[1].q5_start_time = ((state.task_queue[1]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_start_lo & 0xFFFF);
  state.task_queue[1]._q5_fin_hi = r[367];
  state.task_queue[1]._q5_fin_lo = r[368];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[1].q5_finish_time = ((state.task_queue[1]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_fin_lo & 0xFFFF);
  state.task_queue[1].q5_calc_time = toSigned(r[369]) * 0.1;
  state.task_queue[1].q5_min_time = toSigned(r[370]) * 0.1;
  state.task_queue[1].q5_max_time = toSigned(r[371]) * 0.1;
  state.task_queue[1].q6_unit = toSigned(r[372]);
  state.task_queue[1].q6_stage = toSigned(r[373]);
  state.task_queue[1].q6_lift = toSigned(r[374]);
  state.task_queue[1].q6_sink = toSigned(r[375]);
  state.task_queue[1]._q6_start_hi = r[376];
  state.task_queue[1]._q6_start_lo = r[377];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[1].q6_start_time = ((state.task_queue[1]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_start_lo & 0xFFFF);
  state.task_queue[1]._q6_fin_hi = r[378];
  state.task_queue[1]._q6_fin_lo = r[379];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[1].q6_finish_time = ((state.task_queue[1]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_fin_lo & 0xFFFF);
  state.task_queue[1].q6_calc_time = toSigned(r[380]) * 0.1;
  state.task_queue[1].q6_min_time = toSigned(r[381]) * 0.1;
  state.task_queue[1].q6_max_time = toSigned(r[382]) * 0.1;
  state.task_queue[1].q7_unit = toSigned(r[383]);
  state.task_queue[1].q7_stage = toSigned(r[384]);
  state.task_queue[1].q7_lift = toSigned(r[385]);
  state.task_queue[1].q7_sink = toSigned(r[386]);
  state.task_queue[1]._q7_start_hi = r[387];
  state.task_queue[1]._q7_start_lo = r[388];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[1].q7_start_time = ((state.task_queue[1]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_start_lo & 0xFFFF);
  state.task_queue[1]._q7_fin_hi = r[389];
  state.task_queue[1]._q7_fin_lo = r[390];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[1].q7_finish_time = ((state.task_queue[1]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_fin_lo & 0xFFFF);
  state.task_queue[1].q7_calc_time = toSigned(r[391]) * 0.1;
  state.task_queue[1].q7_min_time = toSigned(r[392]) * 0.1;
  state.task_queue[1].q7_max_time = toSigned(r[393]) * 0.1;
  state.task_queue[1].q8_unit = toSigned(r[394]);
  state.task_queue[1].q8_stage = toSigned(r[395]);
  state.task_queue[1].q8_lift = toSigned(r[396]);
  state.task_queue[1].q8_sink = toSigned(r[397]);
  state.task_queue[1]._q8_start_hi = r[398];
  state.task_queue[1]._q8_start_lo = r[399];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[1].q8_start_time = ((state.task_queue[1]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_start_lo & 0xFFFF);
  state.task_queue[1]._q8_fin_hi = r[400];
  state.task_queue[1]._q8_fin_lo = r[401];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[1].q8_finish_time = ((state.task_queue[1]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_fin_lo & 0xFFFF);
  state.task_queue[1].q8_calc_time = toSigned(r[402]) * 0.1;
  state.task_queue[1].q8_min_time = toSigned(r[403]) * 0.1;
  state.task_queue[1].q8_max_time = toSigned(r[404]) * 0.1;
  state.task_queue[1].q9_unit = toSigned(r[405]);
  state.task_queue[1].q9_stage = toSigned(r[406]);
  state.task_queue[1].q9_lift = toSigned(r[407]);
  state.task_queue[1].q9_sink = toSigned(r[408]);
  state.task_queue[1]._q9_start_hi = r[409];
  state.task_queue[1]._q9_start_lo = r[410];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[1].q9_start_time = ((state.task_queue[1]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_start_lo & 0xFFFF);
  state.task_queue[1]._q9_fin_hi = r[411];
  state.task_queue[1]._q9_fin_lo = r[412];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[1].q9_finish_time = ((state.task_queue[1]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_fin_lo & 0xFFFF);
  state.task_queue[1].q9_calc_time = toSigned(r[413]) * 0.1;
  state.task_queue[1].q9_min_time = toSigned(r[414]) * 0.1;
  state.task_queue[1].q9_max_time = toSigned(r[415]) * 0.1;
  state.task_queue[1].q10_unit = toSigned(r[416]);
  state.task_queue[1].q10_stage = toSigned(r[417]);
  state.task_queue[1].q10_lift = toSigned(r[418]);
  state.task_queue[1].q10_sink = toSigned(r[419]);
  state.task_queue[1]._q10_start_hi = r[420];
  state.task_queue[1]._q10_start_lo = r[421];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[1].q10_start_time = ((state.task_queue[1]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_start_lo & 0xFFFF);
  state.task_queue[1]._q10_fin_hi = r[422];
  state.task_queue[1]._q10_fin_lo = r[423];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[1].q10_finish_time = ((state.task_queue[1]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_fin_lo & 0xFFFF);
  state.task_queue[1].q10_calc_time = toSigned(r[424]) * 0.1;
  state.task_queue[1].q10_min_time = toSigned(r[425]) * 0.1;
  state.task_queue[1].q10_max_time = toSigned(r[426]) * 0.1;
  state.task_queue[2] = {};
  state.task_queue[2].task_count = toSigned(r[427]);
  state.task_queue[2].q1_unit = toSigned(r[428]);
  state.task_queue[2].q1_stage = toSigned(r[429]);
  state.task_queue[2].q1_lift = toSigned(r[430]);
  state.task_queue[2].q1_sink = toSigned(r[431]);
  state.task_queue[2]._q1_start_hi = r[432];
  state.task_queue[2]._q1_start_lo = r[433];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[2].q1_start_time = ((state.task_queue[2]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_start_lo & 0xFFFF);
  state.task_queue[2]._q1_fin_hi = r[434];
  state.task_queue[2]._q1_fin_lo = r[435];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[2].q1_finish_time = ((state.task_queue[2]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_fin_lo & 0xFFFF);
  state.task_queue[2].q1_calc_time = toSigned(r[436]) * 0.1;
  state.task_queue[2].q1_min_time = toSigned(r[437]) * 0.1;
  state.task_queue[2].q1_max_time = toSigned(r[438]) * 0.1;
  state.task_queue[2].q2_unit = toSigned(r[439]);
  state.task_queue[2].q2_stage = toSigned(r[440]);
  state.task_queue[2].q2_lift = toSigned(r[441]);
  state.task_queue[2].q2_sink = toSigned(r[442]);
  state.task_queue[2]._q2_start_hi = r[443];
  state.task_queue[2]._q2_start_lo = r[444];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[2].q2_start_time = ((state.task_queue[2]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_start_lo & 0xFFFF);
  state.task_queue[2]._q2_fin_hi = r[445];
  state.task_queue[2]._q2_fin_lo = r[446];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[2].q2_finish_time = ((state.task_queue[2]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_fin_lo & 0xFFFF);
  state.task_queue[2].q2_calc_time = toSigned(r[447]) * 0.1;
  state.task_queue[2].q2_min_time = toSigned(r[448]) * 0.1;
  state.task_queue[2].q2_max_time = toSigned(r[449]) * 0.1;
  state.task_queue[2].q3_unit = toSigned(r[450]);
  state.task_queue[2].q3_stage = toSigned(r[451]);
  state.task_queue[2].q3_lift = toSigned(r[452]);
  state.task_queue[2].q3_sink = toSigned(r[453]);
  state.task_queue[2]._q3_start_hi = r[454];
  state.task_queue[2]._q3_start_lo = r[455];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[2].q3_start_time = ((state.task_queue[2]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_start_lo & 0xFFFF);
  state.task_queue[2]._q3_fin_hi = r[456];
  state.task_queue[2]._q3_fin_lo = r[457];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[2].q3_finish_time = ((state.task_queue[2]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_fin_lo & 0xFFFF);
  state.task_queue[2].q3_calc_time = toSigned(r[458]) * 0.1;
  state.task_queue[2].q3_min_time = toSigned(r[459]) * 0.1;
  state.task_queue[2].q3_max_time = toSigned(r[460]) * 0.1;
  state.task_queue[2].q4_unit = toSigned(r[461]);
  state.task_queue[2].q4_stage = toSigned(r[462]);
  state.task_queue[2].q4_lift = toSigned(r[463]);
  state.task_queue[2].q4_sink = toSigned(r[464]);
  state.task_queue[2]._q4_start_hi = r[465];
  state.task_queue[2]._q4_start_lo = r[466];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[2].q4_start_time = ((state.task_queue[2]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_start_lo & 0xFFFF);
  state.task_queue[2]._q4_fin_hi = r[467];
  state.task_queue[2]._q4_fin_lo = r[468];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[2].q4_finish_time = ((state.task_queue[2]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_fin_lo & 0xFFFF);
  state.task_queue[2].q4_calc_time = toSigned(r[469]) * 0.1;
  state.task_queue[2].q4_min_time = toSigned(r[470]) * 0.1;
  state.task_queue[2].q4_max_time = toSigned(r[471]) * 0.1;
  state.task_queue[2].q5_unit = toSigned(r[472]);
  state.task_queue[2].q5_stage = toSigned(r[473]);
  state.task_queue[2].q5_lift = toSigned(r[474]);
  state.task_queue[2].q5_sink = toSigned(r[475]);
  state.task_queue[2]._q5_start_hi = r[476];
  state.task_queue[2]._q5_start_lo = r[477];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[2].q5_start_time = ((state.task_queue[2]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_start_lo & 0xFFFF);
  state.task_queue[2]._q5_fin_hi = r[478];
  state.task_queue[2]._q5_fin_lo = r[479];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[2].q5_finish_time = ((state.task_queue[2]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_fin_lo & 0xFFFF);
  state.task_queue[2].q5_calc_time = toSigned(r[480]) * 0.1;
  state.task_queue[2].q5_min_time = toSigned(r[481]) * 0.1;
  state.task_queue[2].q5_max_time = toSigned(r[482]) * 0.1;
  state.task_queue[2].q6_unit = toSigned(r[483]);
  state.task_queue[2].q6_stage = toSigned(r[484]);
  state.task_queue[2].q6_lift = toSigned(r[485]);
  state.task_queue[2].q6_sink = toSigned(r[486]);
  state.task_queue[2]._q6_start_hi = r[487];
  state.task_queue[2]._q6_start_lo = r[488];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[2].q6_start_time = ((state.task_queue[2]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_start_lo & 0xFFFF);
  state.task_queue[2]._q6_fin_hi = r[489];
  state.task_queue[2]._q6_fin_lo = r[490];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[2].q6_finish_time = ((state.task_queue[2]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_fin_lo & 0xFFFF);
  state.task_queue[2].q6_calc_time = toSigned(r[491]) * 0.1;
  state.task_queue[2].q6_min_time = toSigned(r[492]) * 0.1;
  state.task_queue[2].q6_max_time = toSigned(r[493]) * 0.1;
  state.task_queue[2].q7_unit = toSigned(r[494]);
  state.task_queue[2].q7_stage = toSigned(r[495]);
  state.task_queue[2].q7_lift = toSigned(r[496]);
  state.task_queue[2].q7_sink = toSigned(r[497]);
  state.task_queue[2]._q7_start_hi = r[498];
  state.task_queue[2]._q7_start_lo = r[499];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[2].q7_start_time = ((state.task_queue[2]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_start_lo & 0xFFFF);
  state.task_queue[2]._q7_fin_hi = r[500];
  state.task_queue[2]._q7_fin_lo = r[501];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[2].q7_finish_time = ((state.task_queue[2]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_fin_lo & 0xFFFF);
  state.task_queue[2].q7_calc_time = toSigned(r[502]) * 0.1;
  state.task_queue[2].q7_min_time = toSigned(r[503]) * 0.1;
  state.task_queue[2].q7_max_time = toSigned(r[504]) * 0.1;
  state.task_queue[2].q8_unit = toSigned(r[505]);
  state.task_queue[2].q8_stage = toSigned(r[506]);
  state.task_queue[2].q8_lift = toSigned(r[507]);
  state.task_queue[2].q8_sink = toSigned(r[508]);
  state.task_queue[2]._q8_start_hi = r[509];
  state.task_queue[2]._q8_start_lo = r[510];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[2].q8_start_time = ((state.task_queue[2]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_start_lo & 0xFFFF);
  state.task_queue[2]._q8_fin_hi = r[511];
  state.task_queue[2]._q8_fin_lo = r[512];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[2].q8_finish_time = ((state.task_queue[2]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_fin_lo & 0xFFFF);
  state.task_queue[2].q8_calc_time = toSigned(r[513]) * 0.1;
  state.task_queue[2].q8_min_time = toSigned(r[514]) * 0.1;
  state.task_queue[2].q8_max_time = toSigned(r[515]) * 0.1;
  state.task_queue[2].q9_unit = toSigned(r[516]);
  state.task_queue[2].q9_stage = toSigned(r[517]);
  state.task_queue[2].q9_lift = toSigned(r[518]);
  state.task_queue[2].q9_sink = toSigned(r[519]);
  state.task_queue[2]._q9_start_hi = r[520];
  state.task_queue[2]._q9_start_lo = r[521];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[2].q9_start_time = ((state.task_queue[2]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_start_lo & 0xFFFF);
  state.task_queue[2]._q9_fin_hi = r[522];
  state.task_queue[2]._q9_fin_lo = r[523];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[2].q9_finish_time = ((state.task_queue[2]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_fin_lo & 0xFFFF);
  state.task_queue[2].q9_calc_time = toSigned(r[524]) * 0.1;
  state.task_queue[2].q9_min_time = toSigned(r[525]) * 0.1;
  state.task_queue[2].q9_max_time = toSigned(r[526]) * 0.1;
  state.task_queue[2].q10_unit = toSigned(r[527]);
  state.task_queue[2].q10_stage = toSigned(r[528]);
  state.task_queue[2].q10_lift = toSigned(r[529]);
  state.task_queue[2].q10_sink = toSigned(r[530]);
  state.task_queue[2]._q10_start_hi = r[531];
  state.task_queue[2]._q10_start_lo = r[532];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[2].q10_start_time = ((state.task_queue[2]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_start_lo & 0xFFFF);
  state.task_queue[2]._q10_fin_hi = r[533];
  state.task_queue[2]._q10_fin_lo = r[534];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[2].q10_finish_time = ((state.task_queue[2]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_fin_lo & 0xFFFF);
  state.task_queue[2].q10_calc_time = toSigned(r[535]) * 0.1;
  state.task_queue[2].q10_min_time = toSigned(r[536]) * 0.1;
  state.task_queue[2].q10_max_time = toSigned(r[537]) * 0.1;
  state.task_queue[3] = {};
  state.task_queue[3].task_count = toSigned(r[538]);
  state.task_queue[3].q1_unit = toSigned(r[539]);
  state.task_queue[3].q1_stage = toSigned(r[540]);
  state.task_queue[3].q1_lift = toSigned(r[541]);
  state.task_queue[3].q1_sink = toSigned(r[542]);
  state.task_queue[3]._q1_start_hi = r[543];
  state.task_queue[3]._q1_start_lo = r[544];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[3].q1_start_time = ((state.task_queue[3]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_start_lo & 0xFFFF);
  state.task_queue[3]._q1_fin_hi = r[545];
  state.task_queue[3]._q1_fin_lo = r[546];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[3].q1_finish_time = ((state.task_queue[3]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_fin_lo & 0xFFFF);
  state.task_queue[3].q1_calc_time = toSigned(r[547]) * 0.1;
  state.task_queue[3].q1_min_time = toSigned(r[548]) * 0.1;
  state.task_queue[3].q1_max_time = toSigned(r[549]) * 0.1;
  state.task_queue[3].q2_unit = toSigned(r[550]);
  state.task_queue[3].q2_stage = toSigned(r[551]);
  state.task_queue[3].q2_lift = toSigned(r[552]);
  state.task_queue[3].q2_sink = toSigned(r[553]);
  state.task_queue[3]._q2_start_hi = r[554];
  state.task_queue[3]._q2_start_lo = r[555];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[3].q2_start_time = ((state.task_queue[3]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_start_lo & 0xFFFF);
  state.task_queue[3]._q2_fin_hi = r[556];
  state.task_queue[3]._q2_fin_lo = r[557];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[3].q2_finish_time = ((state.task_queue[3]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_fin_lo & 0xFFFF);
  state.task_queue[3].q2_calc_time = toSigned(r[558]) * 0.1;
  state.task_queue[3].q2_min_time = toSigned(r[559]) * 0.1;
  state.task_queue[3].q2_max_time = toSigned(r[560]) * 0.1;
  state.task_queue[3].q3_unit = toSigned(r[561]);
  state.task_queue[3].q3_stage = toSigned(r[562]);
  state.task_queue[3].q3_lift = toSigned(r[563]);
  state.task_queue[3].q3_sink = toSigned(r[564]);
  state.task_queue[3]._q3_start_hi = r[565];
  state.task_queue[3]._q3_start_lo = r[566];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[3].q3_start_time = ((state.task_queue[3]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_start_lo & 0xFFFF);
  state.task_queue[3]._q3_fin_hi = r[567];
  state.task_queue[3]._q3_fin_lo = r[568];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[3].q3_finish_time = ((state.task_queue[3]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_fin_lo & 0xFFFF);
  state.task_queue[3].q3_calc_time = toSigned(r[569]) * 0.1;
  state.task_queue[3].q3_min_time = toSigned(r[570]) * 0.1;
  state.task_queue[3].q3_max_time = toSigned(r[571]) * 0.1;
  state.task_queue[3].q4_unit = toSigned(r[572]);
  state.task_queue[3].q4_stage = toSigned(r[573]);
  state.task_queue[3].q4_lift = toSigned(r[574]);
  state.task_queue[3].q4_sink = toSigned(r[575]);
  state.task_queue[3]._q4_start_hi = r[576];
  state.task_queue[3]._q4_start_lo = r[577];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[3].q4_start_time = ((state.task_queue[3]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_start_lo & 0xFFFF);
  state.task_queue[3]._q4_fin_hi = r[578];
  state.task_queue[3]._q4_fin_lo = r[579];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[3].q4_finish_time = ((state.task_queue[3]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_fin_lo & 0xFFFF);
  state.task_queue[3].q4_calc_time = toSigned(r[580]) * 0.1;
  state.task_queue[3].q4_min_time = toSigned(r[581]) * 0.1;
  state.task_queue[3].q4_max_time = toSigned(r[582]) * 0.1;
  state.task_queue[3].q5_unit = toSigned(r[583]);
  state.task_queue[3].q5_stage = toSigned(r[584]);
  state.task_queue[3].q5_lift = toSigned(r[585]);
  state.task_queue[3].q5_sink = toSigned(r[586]);
  state.task_queue[3]._q5_start_hi = r[587];
  state.task_queue[3]._q5_start_lo = r[588];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[3].q5_start_time = ((state.task_queue[3]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_start_lo & 0xFFFF);
  state.task_queue[3]._q5_fin_hi = r[589];
  state.task_queue[3]._q5_fin_lo = r[590];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[3].q5_finish_time = ((state.task_queue[3]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_fin_lo & 0xFFFF);
  state.task_queue[3].q5_calc_time = toSigned(r[591]) * 0.1;
  state.task_queue[3].q5_min_time = toSigned(r[592]) * 0.1;
  state.task_queue[3].q5_max_time = toSigned(r[593]) * 0.1;
  state.task_queue[3].q6_unit = toSigned(r[594]);
  state.task_queue[3].q6_stage = toSigned(r[595]);
  state.task_queue[3].q6_lift = toSigned(r[596]);
  state.task_queue[3].q6_sink = toSigned(r[597]);
  state.task_queue[3]._q6_start_hi = r[598];
  state.task_queue[3]._q6_start_lo = r[599];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[3].q6_start_time = ((state.task_queue[3]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_start_lo & 0xFFFF);
  state.task_queue[3]._q6_fin_hi = r[600];
  state.task_queue[3]._q6_fin_lo = r[601];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[3].q6_finish_time = ((state.task_queue[3]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_fin_lo & 0xFFFF);
  state.task_queue[3].q6_calc_time = toSigned(r[602]) * 0.1;
  state.task_queue[3].q6_min_time = toSigned(r[603]) * 0.1;
  state.task_queue[3].q6_max_time = toSigned(r[604]) * 0.1;
  state.task_queue[3].q7_unit = toSigned(r[605]);
  state.task_queue[3].q7_stage = toSigned(r[606]);
  state.task_queue[3].q7_lift = toSigned(r[607]);
  state.task_queue[3].q7_sink = toSigned(r[608]);
  state.task_queue[3]._q7_start_hi = r[609];
  state.task_queue[3]._q7_start_lo = r[610];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[3].q7_start_time = ((state.task_queue[3]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_start_lo & 0xFFFF);
  state.task_queue[3]._q7_fin_hi = r[611];
  state.task_queue[3]._q7_fin_lo = r[612];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[3].q7_finish_time = ((state.task_queue[3]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_fin_lo & 0xFFFF);
  state.task_queue[3].q7_calc_time = toSigned(r[613]) * 0.1;
  state.task_queue[3].q7_min_time = toSigned(r[614]) * 0.1;
  state.task_queue[3].q7_max_time = toSigned(r[615]) * 0.1;
  state.task_queue[3].q8_unit = toSigned(r[616]);
  state.task_queue[3].q8_stage = toSigned(r[617]);
  state.task_queue[3].q8_lift = toSigned(r[618]);
  state.task_queue[3].q8_sink = toSigned(r[619]);
  state.task_queue[3]._q8_start_hi = r[620];
  state.task_queue[3]._q8_start_lo = r[621];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[3].q8_start_time = ((state.task_queue[3]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_start_lo & 0xFFFF);
  state.task_queue[3]._q8_fin_hi = r[622];
  state.task_queue[3]._q8_fin_lo = r[623];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[3].q8_finish_time = ((state.task_queue[3]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_fin_lo & 0xFFFF);
  state.task_queue[3].q8_calc_time = toSigned(r[624]) * 0.1;
  state.task_queue[3].q8_min_time = toSigned(r[625]) * 0.1;
  state.task_queue[3].q8_max_time = toSigned(r[626]) * 0.1;
  state.task_queue[3].q9_unit = toSigned(r[627]);
  state.task_queue[3].q9_stage = toSigned(r[628]);
  state.task_queue[3].q9_lift = toSigned(r[629]);
  state.task_queue[3].q9_sink = toSigned(r[630]);
  state.task_queue[3]._q9_start_hi = r[631];
  state.task_queue[3]._q9_start_lo = r[632];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[3].q9_start_time = ((state.task_queue[3]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_start_lo & 0xFFFF);
  state.task_queue[3]._q9_fin_hi = r[633];
  state.task_queue[3]._q9_fin_lo = r[634];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[3].q9_finish_time = ((state.task_queue[3]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_fin_lo & 0xFFFF);
  state.task_queue[3].q9_calc_time = toSigned(r[635]) * 0.1;
  state.task_queue[3].q9_min_time = toSigned(r[636]) * 0.1;
  state.task_queue[3].q9_max_time = toSigned(r[637]) * 0.1;
  state.task_queue[3].q10_unit = toSigned(r[638]);
  state.task_queue[3].q10_stage = toSigned(r[639]);
  state.task_queue[3].q10_lift = toSigned(r[640]);
  state.task_queue[3].q10_sink = toSigned(r[641]);
  state.task_queue[3]._q10_start_hi = r[642];
  state.task_queue[3]._q10_start_lo = r[643];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[3].q10_start_time = ((state.task_queue[3]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_start_lo & 0xFFFF);
  state.task_queue[3]._q10_fin_hi = r[644];
  state.task_queue[3]._q10_fin_lo = r[645];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[3].q10_finish_time = ((state.task_queue[3]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_fin_lo & 0xFFFF);
  state.task_queue[3].q10_calc_time = toSigned(r[646]) * 0.1;
  state.task_queue[3].q10_min_time = toSigned(r[647]) * 0.1;
  state.task_queue[3].q10_max_time = toSigned(r[648]) * 0.1;
  // --- dep_state ---
  state.dep_state = {};
  state.dep_state.dep_activated = toSigned(r[649]);
  state.dep_state.dep_stable = toSigned(r[650]);
  state.dep_state.dep_waiting_count = toSigned(r[651]);
  state.dep_state.dep_overlap_count = toSigned(r[652]);
  state.dep_state.dep_pending_valid = toSigned(r[653]);
  state.dep_state.dep_pending_unit = toSigned(r[654]);
  state.dep_state.dep_pending_stage = toSigned(r[655]);
  state.dep_state._dep_pend_time_hi = r[656];
  state.dep_state._dep_pend_time_lo = r[657];
  // Combined uint32: dep_pending_time = (hi << 16) | lo
  state.dep_state.dep_pending_time = ((state.dep_state._pend_time_hi & 0xFFFF) * 65536) + (state.dep_state._pend_time_lo & 0xFFFF);
  // --- dep_waiting ---
  if (!state.dep_waiting) state.dep_waiting = {};
  state.dep_waiting[1] = {};
  state.dep_waiting[1].waiting_unit = toSigned(r[658]);
  state.dep_waiting[2] = {};
  state.dep_waiting[2].waiting_unit = toSigned(r[659]);
  state.dep_waiting[3] = {};
  state.dep_waiting[3].waiting_unit = toSigned(r[660]);
  state.dep_waiting[4] = {};
  state.dep_waiting[4].waiting_unit = toSigned(r[661]);
  state.dep_waiting[5] = {};
  state.dep_waiting[5].waiting_unit = toSigned(r[662]);
  state.dep_overlap[101] = {};
  state.dep_overlap[101].overlap_flag = toSigned(r[663]);
  state.dep_overlap[102] = {};
  state.dep_overlap[102].overlap_flag = toSigned(r[664]);
  state.dep_overlap[103] = {};
  state.dep_overlap[103].overlap_flag = toSigned(r[665]);
  state.dep_overlap[104] = {};
  state.dep_overlap[104].overlap_flag = toSigned(r[666]);
  state.dep_overlap[105] = {};
  state.dep_overlap[105].overlap_flag = toSigned(r[667]);
  state.dep_overlap[106] = {};
  state.dep_overlap[106].overlap_flag = toSigned(r[668]);
  state.dep_overlap[107] = {};
  state.dep_overlap[107].overlap_flag = toSigned(r[669]);
  state.dep_overlap[108] = {};
  state.dep_overlap[108].overlap_flag = toSigned(r[670]);
  state.dep_overlap[109] = {};
  state.dep_overlap[109].overlap_flag = toSigned(r[671]);
  state.dep_overlap[110] = {};
  state.dep_overlap[110].overlap_flag = toSigned(r[672]);
  state.dep_overlap[111] = {};
  state.dep_overlap[111].overlap_flag = toSigned(r[673]);
  state.dep_overlap[112] = {};
  state.dep_overlap[112].overlap_flag = toSigned(r[674]);
  state.dep_overlap[113] = {};
  state.dep_overlap[113].overlap_flag = toSigned(r[675]);
  state.dep_overlap[114] = {};
  state.dep_overlap[114].overlap_flag = toSigned(r[676]);
  state.dep_overlap[115] = {};
  state.dep_overlap[115].overlap_flag = toSigned(r[677]);
  state.dep_overlap[116] = {};
  state.dep_overlap[116].overlap_flag = toSigned(r[678]);
  state.dep_overlap[117] = {};
  state.dep_overlap[117].overlap_flag = toSigned(r[679]);
  state.dep_overlap[118] = {};
  state.dep_overlap[118].overlap_flag = toSigned(r[680]);
  state.dep_overlap[119] = {};
  state.dep_overlap[119].overlap_flag = toSigned(r[681]);
  state.dep_overlap[120] = {};
  state.dep_overlap[120].overlap_flag = toSigned(r[682]);
  state.dep_overlap[121] = {};
  state.dep_overlap[121].overlap_flag = toSigned(r[683]);
  state.dep_overlap[122] = {};
  state.dep_overlap[122].overlap_flag = toSigned(r[684]);
  state.dep_overlap[123] = {};
  state.dep_overlap[123].overlap_flag = toSigned(r[685]);
  state.dep_overlap[124] = {};
  state.dep_overlap[124].overlap_flag = toSigned(r[686]);
  state.dep_overlap[125] = {};
  state.dep_overlap[125].overlap_flag = toSigned(r[687]);
  state.dep_overlap[126] = {};
  state.dep_overlap[126].overlap_flag = toSigned(r[688]);
  state.dep_overlap[127] = {};
  state.dep_overlap[127].overlap_flag = toSigned(r[689]);
  state.dep_overlap[128] = {};
  state.dep_overlap[128].overlap_flag = toSigned(r[690]);
  state.dep_overlap[129] = {};
  state.dep_overlap[129].overlap_flag = toSigned(r[691]);
  state.dep_overlap[130] = {};
  state.dep_overlap[130].overlap_flag = toSigned(r[692]);

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
    'iw_cmd_t1_start': 693,
    'iw_cmd_t1_lift': 694,
    'iw_cmd_t1_sink': 695,
    'iw_cmd_t2_start': 696,
    'iw_cmd_t2_lift': 697,
    'iw_cmd_t2_sink': 698,
    'iw_cfg_seq': 699,
    'iw_cfg_cmd': 700,
    'iw_cfg_param': 701,
    'iw_cfg_d0': 702,
    'iw_cfg_d1': 703,
    'iw_cfg_d2': 704,
    'iw_cfg_d3': 705,
    'iw_cfg_d4': 706,
    'iw_cfg_d5': 707,
    'iw_cfg_d6': 708,
    'iw_cfg_d7': 709,
    'iw_unit_seq': 710,
    'iw_unit_id': 711,
    'iw_unit_loc': 712,
    'iw_unit_status': 713,
    'iw_unit_target': 714,
    'iw_batch_seq': 715,
    'iw_batch_unit': 716,
    'iw_batch_code': 717,
    'iw_batch_state': 718,
    'iw_batch_prog_id': 719,
    'iw_prog_seq': 720,
    'iw_prog_unit': 721,
    'iw_prog_stage': 722,
    'iw_prog_s1': 723,
    'iw_prog_s2': 724,
    'iw_prog_s3': 725,
    'iw_prog_s4': 726,
    'iw_prog_s5': 727,
    'iw_prog_min_time': 728,
    'iw_prog_max_time': 729,
    'iw_prog_cal_time': 730,
    'iw_avoid_seq': 731,
    'iw_avoid_station': 732,
    'iw_avoid_value': 733,
    'iw_production_queue': 734,
    'iw_time_hi': 735,
    'iw_time_lo': 736,
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
  cmd_transport: { start: 693, fields: ["cmd_start", "cmd_lift", "cmd_sink", "cmd_start", "cmd_lift", "cmd_sink"] },
  cfg: { start: 699, fields: ["cfg_seq", "cfg_cmd", "cfg_param", "cfg_d0", "cfg_d1", "cfg_d2", "cfg_d3", "cfg_d4", "cfg_d5", "cfg_d6", "cfg_d7"] },
  unit: { start: 710, fields: ["unit_seq", "unit_id", "unit_loc", "unit_status", "unit_target"] },
  batch: { start: 715, fields: ["batch_seq", "batch_unit", "batch_code", "batch_state", "batch_prog_id"] },
  prog: { start: 720, fields: ["prog_seq", "prog_unit", "prog_stage", "prog_s1", "prog_s2", "prog_s3", "prog_s4", "prog_s5", "prog_min_time", "prog_max_time", "prog_cal_time"] },
  avoid: { start: 731, fields: ["avoid_seq", "avoid_station", "avoid_value"] },
  production: { start: 734, fields: ["production_queue"] },
  time: { start: 735, fields: ["time_hi", "time_lo"] },
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
