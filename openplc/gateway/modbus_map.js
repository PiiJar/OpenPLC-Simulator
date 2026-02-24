/**
 * Auto-generated Modbus register map — DO NOT EDIT
 * Generated from modbus_map.json (742 registers)
 */

const TOTAL_REGISTERS = 742;

// Block address ranges
const BLOCKS = {
  transporter_state: { start: 0, end: 35, count: 36, direction: 'out' },
  transporter_extended: { start: 36, end: 74, count: 39, direction: 'out' },
  twa_limits: { start: 75, end: 80, count: 6, direction: 'out' },
  plc_status: { start: 81, end: 91, count: 11, direction: 'out' },
  unit_state: { start: 92, end: 131, count: 40, direction: 'out' },
  batch_state: { start: 132, end: 171, count: 40, direction: 'out' },
  calibration: { start: 172, end: 173, count: 2, direction: 'out' },
  calibration_results: { start: 174, end: 194, count: 21, direction: 'out' },
  transporter_config: { start: 195, end: 281, count: 87, direction: 'out' },
  avoid_status: { start: 282, end: 311, count: 30, direction: 'out' },
  schedule_summary: { start: 312, end: 321, count: 10, direction: 'out' },
  task_queue: { start: 322, end: 654, count: 333, direction: 'out' },
  dep_state: { start: 655, end: 663, count: 9, direction: 'out' },
  dep_waiting: { start: 664, end: 668, count: 5, direction: 'out' },
  dep_overlap: { start: 669, end: 698, count: 30, direction: 'out' },
  cmd_transport: { start: 699, end: 704, count: 6, direction: 'in' },
  cfg: { start: 705, end: 714, count: 10, direction: 'in' },
  unit: { start: 715, end: 720, count: 6, direction: 'in' },
  batch: { start: 721, end: 725, count: 5, direction: 'in' },
  prog: { start: 726, end: 736, count: 11, direction: 'in' },
  avoid: { start: 737, end: 739, count: 3, direction: 'in' },
  time: { start: 740, end: 741, count: 2, direction: 'in' },
};

// Register addresses
const REG = {
  qw_t1_x_mm: 0,  // X position mm
  qw_t1_z_mm: 1,  // Z position mm
  qw_t1_vel_x10: 2,  // X velocity ×10
  qw_t1_phase: 3,  // 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking
  qw_t1_z_stage: 4,  // Z motion sub-phase
  qw_t1_cur_st: 5,  // nearest station
  qw_t1_lift_tgt: 6,  // pickup station
  qw_t1_sink_tgt: 7,  // putdown station
  qw_t1_active: 8,  // 1=active 0=inactive
  qw_t1_status: 9,  // 0=not_used 1=manual 2=half 3=auto_idle 4=auto_run
  qw_t1_rtask_hi: 10,  // running task_id upper 16 bits
  qw_t1_rtask_lo: 11,  // running task_id lower 16 bits
  qw_t2_x_mm: 12,  // X position mm
  qw_t2_z_mm: 13,  // Z position mm
  qw_t2_vel_x10: 14,  // X velocity ×10
  qw_t2_phase: 15,  // 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking
  qw_t2_z_stage: 16,  // Z motion sub-phase
  qw_t2_cur_st: 17,  // nearest station
  qw_t2_lift_tgt: 18,  // pickup station
  qw_t2_sink_tgt: 19,  // putdown station
  qw_t2_active: 20,  // 1=active 0=inactive
  qw_t2_status: 21,  // 0=not_used 1=manual 2=half 3=auto_idle 4=auto_run
  qw_t2_rtask_hi: 22,  // running task_id upper 16 bits
  qw_t2_rtask_lo: 23,  // running task_id lower 16 bits
  qw_t3_x_mm: 24,  // X position mm
  qw_t3_z_mm: 25,  // Z position mm
  qw_t3_vel_x10: 26,  // X velocity ×10
  qw_t3_phase: 27,  // 0=idle 1=to_lift 2=lifting 3=to_sink 4=sinking
  qw_t3_z_stage: 28,  // Z motion sub-phase
  qw_t3_cur_st: 29,  // nearest station
  qw_t3_lift_tgt: 30,  // pickup station
  qw_t3_sink_tgt: 31,  // putdown station
  qw_t3_active: 32,  // 1=active 0=inactive
  qw_t3_status: 33,  // 0=not_used 1=manual 2=half 3=auto_idle 4=auto_run
  qw_t3_rtask_hi: 34,  // running task_id upper 16 bits
  qw_t3_rtask_lo: 35,  // running task_id lower 16 bits
  qw_t1_remain_x10: 36,  // remaining treatment time ×10 (0.1s)
  qw_t1_treat_time: 37,  // treatment duration (s)
  qw_t1_fintgt_x: 38,  // destination X mm
  qw_t1_drvtgt_x: 39,  // TWA-clamped X mm
  qw_t1_fintgt_y: 40,  // destination Y mm (3D)
  qw_t1_drvtgt_y: 41,  // TWA-clamped Y mm (3D)
  qw_t1_y_mm: 42,  // Y position mm (3D)
  qw_t1_ztimer_x10: 43,  // Z motion timer ×10 (0.1s)
  qw_t1_ctask_hi: 44,  // command task_id upper 16
  qw_t1_ctask_lo: 45,  // command task_id lower 16
  qw_t1_ldev_x10: 46,  // lift device delay ×10 (0.1s)
  qw_t1_sdev_x10: 47,  // sink device delay ×10 (0.1s)
  qw_t1_drop_x10: 48,  // dropping time ×10 (0.1s)
  qw_t2_remain_x10: 49,  // remaining treatment time ×10 (0.1s)
  qw_t2_treat_time: 50,  // treatment duration (s)
  qw_t2_fintgt_x: 51,  // destination X mm
  qw_t2_drvtgt_x: 52,  // TWA-clamped X mm
  qw_t2_fintgt_y: 53,  // destination Y mm (3D)
  qw_t2_drvtgt_y: 54,  // TWA-clamped Y mm (3D)
  qw_t2_y_mm: 55,  // Y position mm (3D)
  qw_t2_ztimer_x10: 56,  // Z motion timer ×10 (0.1s)
  qw_t2_ctask_hi: 57,  // command task_id upper 16
  qw_t2_ctask_lo: 58,  // command task_id lower 16
  qw_t2_ldev_x10: 59,  // lift device delay ×10 (0.1s)
  qw_t2_sdev_x10: 60,  // sink device delay ×10 (0.1s)
  qw_t2_drop_x10: 61,  // dropping time ×10 (0.1s)
  qw_t3_remain_x10: 62,  // remaining treatment time ×10 (0.1s)
  qw_t3_treat_time: 63,  // treatment duration (s)
  qw_t3_fintgt_x: 64,  // destination X mm
  qw_t3_drvtgt_x: 65,  // TWA-clamped X mm
  qw_t3_fintgt_y: 66,  // destination Y mm (3D)
  qw_t3_drvtgt_y: 67,  // TWA-clamped Y mm (3D)
  qw_t3_y_mm: 68,  // Y position mm (3D)
  qw_t3_ztimer_x10: 69,  // Z motion timer ×10 (0.1s)
  qw_t3_ctask_hi: 70,  // command task_id upper 16
  qw_t3_ctask_lo: 71,  // command task_id lower 16
  qw_t3_ldev_x10: 72,  // lift device delay ×10 (0.1s)
  qw_t3_sdev_x10: 73,  // sink device delay ×10 (0.1s)
  qw_t3_drop_x10: 74,  // dropping time ×10 (0.1s)
  qw_t1_xmin: 75,  // TWA lower X limit mm
  qw_t1_xmax: 76,  // TWA upper X limit mm
  qw_t2_xmin: 77,  // TWA lower X limit mm
  qw_t2_xmax: 78,  // TWA upper X limit mm
  qw_t3_xmin: 79,  // TWA lower X limit mm
  qw_t3_xmax: 80,  // TWA upper X limit mm
  qw_plc_status_station_cnt: 81,  // configured station count
  qw_plc_status_init_done: 82,  // 1=initialized
  qw_plc_status_cycle_cnt: 83,  // heartbeat counter
  qw_plc_status_cfg_ack: 84,  // last processed cfg seq
  qw_plc_status_unit_ack: 85,  // last processed unit write seq
  qw_plc_status_batch_ack: 86,  // last processed batch write seq
  qw_plc_status_prog_ack: 87,  // last processed program stage seq
  qw_plc_status_avoid_ack: 88,  // last processed avoid write seq
  qw_plc_status_cal_active: 89,  // 1=calibration in progress
  qw_plc_status_time_hi: 90,  // PLC unix time upper 16 bits
  qw_plc_status_time_lo: 91,  // PLC unix time lower 16 bits
  qw_u1_loc: 92,  // station number
  qw_u1_status: 93,  // NOT_USED=0, USED=1
  qw_u1_state: 94,  // EMPTY=0, FULL=1
  qw_u1_target: 95,  // TO_NONE=0..TO_AVOID=5
  qw_u2_loc: 96,  // station number
  qw_u2_status: 97,  // NOT_USED=0, USED=1
  qw_u2_state: 98,  // EMPTY=0, FULL=1
  qw_u2_target: 99,  // TO_NONE=0..TO_AVOID=5
  qw_u3_loc: 100,  // station number
  qw_u3_status: 101,  // NOT_USED=0, USED=1
  qw_u3_state: 102,  // EMPTY=0, FULL=1
  qw_u3_target: 103,  // TO_NONE=0..TO_AVOID=5
  qw_u4_loc: 104,  // station number
  qw_u4_status: 105,  // NOT_USED=0, USED=1
  qw_u4_state: 106,  // EMPTY=0, FULL=1
  qw_u4_target: 107,  // TO_NONE=0..TO_AVOID=5
  qw_u5_loc: 108,  // station number
  qw_u5_status: 109,  // NOT_USED=0, USED=1
  qw_u5_state: 110,  // EMPTY=0, FULL=1
  qw_u5_target: 111,  // TO_NONE=0..TO_AVOID=5
  qw_u6_loc: 112,  // station number
  qw_u6_status: 113,  // NOT_USED=0, USED=1
  qw_u6_state: 114,  // EMPTY=0, FULL=1
  qw_u6_target: 115,  // TO_NONE=0..TO_AVOID=5
  qw_u7_loc: 116,  // station number
  qw_u7_status: 117,  // NOT_USED=0, USED=1
  qw_u7_state: 118,  // EMPTY=0, FULL=1
  qw_u7_target: 119,  // TO_NONE=0..TO_AVOID=5
  qw_u8_loc: 120,  // station number
  qw_u8_status: 121,  // NOT_USED=0, USED=1
  qw_u8_state: 122,  // EMPTY=0, FULL=1
  qw_u8_target: 123,  // TO_NONE=0..TO_AVOID=5
  qw_u9_loc: 124,  // station number
  qw_u9_status: 125,  // NOT_USED=0, USED=1
  qw_u9_state: 126,  // EMPTY=0, FULL=1
  qw_u9_target: 127,  // TO_NONE=0..TO_AVOID=5
  qw_u10_loc: 128,  // station number
  qw_u10_status: 129,  // NOT_USED=0, USED=1
  qw_u10_state: 130,  // EMPTY=0, FULL=1
  qw_u10_target: 131,  // TO_NONE=0..TO_AVOID=5
  qw_b1_code: 132,  // numeric batch code
  qw_b1_state: 133,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b1_prog: 134,  // treatment program ID
  qw_b1_stage: 135,  // current stage number
  qw_b2_code: 136,  // numeric batch code
  qw_b2_state: 137,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b2_prog: 138,  // treatment program ID
  qw_b2_stage: 139,  // current stage number
  qw_b3_code: 140,  // numeric batch code
  qw_b3_state: 141,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b3_prog: 142,  // treatment program ID
  qw_b3_stage: 143,  // current stage number
  qw_b4_code: 144,  // numeric batch code
  qw_b4_state: 145,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b4_prog: 146,  // treatment program ID
  qw_b4_stage: 147,  // current stage number
  qw_b5_code: 148,  // numeric batch code
  qw_b5_state: 149,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b5_prog: 150,  // treatment program ID
  qw_b5_stage: 151,  // current stage number
  qw_b6_code: 152,  // numeric batch code
  qw_b6_state: 153,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b6_prog: 154,  // treatment program ID
  qw_b6_stage: 155,  // current stage number
  qw_b7_code: 156,  // numeric batch code
  qw_b7_state: 157,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b7_prog: 158,  // treatment program ID
  qw_b7_stage: 159,  // current stage number
  qw_b8_code: 160,  // numeric batch code
  qw_b8_state: 161,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b8_prog: 162,  // treatment program ID
  qw_b8_stage: 163,  // current stage number
  qw_b9_code: 164,  // numeric batch code
  qw_b9_state: 165,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b9_prog: 166,  // treatment program ID
  qw_b9_stage: 167,  // current stage number
  qw_b10_code: 168,  // numeric batch code
  qw_b10_state: 169,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  qw_b10_prog: 170,  // treatment program ID
  qw_b10_stage: 171,  // current stage number
  qw_calibration_step: 172,  // 0=idle, 100=done, 999=complete
  qw_calibration_tid: 173,  // transporter being calibrated
  qw_cal_t1_lift_wet: 174,  // lift wet time ×10
  qw_cal_t1_sink_wet: 175,  // sink wet time ×10
  qw_cal_t1_lift_dry: 176,  // lift dry time ×10
  qw_cal_t1_sink_dry: 177,  // sink dry time ×10
  qw_cal_t1_x_acc: 178,  // X accel time ×10
  qw_cal_t1_x_dec: 179,  // X decel time ×10
  qw_cal_t1_x_max: 180,  // X max speed mm/s
  qw_cal_t2_lift_wet: 181,  // lift wet time ×10
  qw_cal_t2_sink_wet: 182,  // sink wet time ×10
  qw_cal_t2_lift_dry: 183,  // lift dry time ×10
  qw_cal_t2_sink_dry: 184,  // sink dry time ×10
  qw_cal_t2_x_acc: 185,  // X accel time ×10
  qw_cal_t2_x_dec: 186,  // X decel time ×10
  qw_cal_t2_x_max: 187,  // X max speed mm/s
  qw_cal_t3_lift_wet: 188,  // lift wet time ×10
  qw_cal_t3_sink_wet: 189,  // sink wet time ×10
  qw_cal_t3_lift_dry: 190,  // lift dry time ×10
  qw_cal_t3_sink_dry: 191,  // sink dry time ×10
  qw_cal_t3_x_acc: 192,  // X accel time ×10
  qw_cal_t3_x_dec: 193,  // X decel time ×10
  qw_cal_t3_x_max: 194,  // X max speed mm/s
  qw_cfg_t1_x_min: 195,  // config X min limit mm
  qw_cfg_t1_x_max: 196,  // config X max limit mm
  qw_cfg_t1_y_min: 197,  // config Y min limit mm
  qw_cfg_t1_y_max: 198,  // config Y max limit mm
  qw_cfg_t1_x_avoid: 199,  // X avoid distance mm
  qw_cfg_t1_y_avoid: 200,  // Y avoid distance mm
  qw_cfg_t1_ph_xacc_x100: 201,  // X accel ×100 (0.01s)
  qw_cfg_t1_ph_xdec_x100: 202,  // X decel ×100 (0.01s)
  qw_cfg_t1_ph_xmax: 203,  // X max speed mm/s
  qw_cfg_t1_ph_ztot: 204,  // Z total travel mm
  qw_cfg_t1_ph_zsdry: 205,  // Z slow zone dry mm
  qw_cfg_t1_ph_zswet: 206,  // Z slow zone wet mm
  qw_cfg_t1_ph_zsend: 207,  // Z slow zone end mm
  qw_cfg_t1_ph_zslow: 208,  // Z slow speed mm/s
  qw_cfg_t1_ph_zfast: 209,  // Z fast speed mm/s
  qw_cfg_t1_ph_drip_x10: 210,  // drip delay ×10 (0.1s)
  qw_cfg_t1_ph_avoid: 211,  // physics avoid mm
  qw_cfg_t1_ta1_min_lift: 212,  // task area 1 min lift station
  qw_cfg_t1_ta1_max_lift: 213,  // task area 1 max lift station
  qw_cfg_t1_ta1_min_sink: 214,  // task area 1 min sink station
  qw_cfg_t1_ta1_max_sink: 215,  // task area 1 max sink station
  qw_cfg_t1_ta2_min_lift: 216,  // task area 2 min lift station
  qw_cfg_t1_ta2_max_lift: 217,  // task area 2 max lift station
  qw_cfg_t1_ta2_min_sink: 218,  // task area 2 min sink station
  qw_cfg_t1_ta2_max_sink: 219,  // task area 2 max sink station
  qw_cfg_t1_ta3_min_lift: 220,  // task area 3 min lift station
  qw_cfg_t1_ta3_max_lift: 221,  // task area 3 max lift station
  qw_cfg_t1_ta3_min_sink: 222,  // task area 3 min sink station
  qw_cfg_t1_ta3_max_sink: 223,  // task area 3 max sink station
  qw_cfg_t2_x_min: 224,  // config X min limit mm
  qw_cfg_t2_x_max: 225,  // config X max limit mm
  qw_cfg_t2_y_min: 226,  // config Y min limit mm
  qw_cfg_t2_y_max: 227,  // config Y max limit mm
  qw_cfg_t2_x_avoid: 228,  // X avoid distance mm
  qw_cfg_t2_y_avoid: 229,  // Y avoid distance mm
  qw_cfg_t2_ph_xacc_x100: 230,  // X accel ×100 (0.01s)
  qw_cfg_t2_ph_xdec_x100: 231,  // X decel ×100 (0.01s)
  qw_cfg_t2_ph_xmax: 232,  // X max speed mm/s
  qw_cfg_t2_ph_ztot: 233,  // Z total travel mm
  qw_cfg_t2_ph_zsdry: 234,  // Z slow zone dry mm
  qw_cfg_t2_ph_zswet: 235,  // Z slow zone wet mm
  qw_cfg_t2_ph_zsend: 236,  // Z slow zone end mm
  qw_cfg_t2_ph_zslow: 237,  // Z slow speed mm/s
  qw_cfg_t2_ph_zfast: 238,  // Z fast speed mm/s
  qw_cfg_t2_ph_drip_x10: 239,  // drip delay ×10 (0.1s)
  qw_cfg_t2_ph_avoid: 240,  // physics avoid mm
  qw_cfg_t2_ta1_min_lift: 241,  // task area 1 min lift station
  qw_cfg_t2_ta1_max_lift: 242,  // task area 1 max lift station
  qw_cfg_t2_ta1_min_sink: 243,  // task area 1 min sink station
  qw_cfg_t2_ta1_max_sink: 244,  // task area 1 max sink station
  qw_cfg_t2_ta2_min_lift: 245,  // task area 2 min lift station
  qw_cfg_t2_ta2_max_lift: 246,  // task area 2 max lift station
  qw_cfg_t2_ta2_min_sink: 247,  // task area 2 min sink station
  qw_cfg_t2_ta2_max_sink: 248,  // task area 2 max sink station
  qw_cfg_t2_ta3_min_lift: 249,  // task area 3 min lift station
  qw_cfg_t2_ta3_max_lift: 250,  // task area 3 max lift station
  qw_cfg_t2_ta3_min_sink: 251,  // task area 3 min sink station
  qw_cfg_t2_ta3_max_sink: 252,  // task area 3 max sink station
  qw_cfg_t3_x_min: 253,  // config X min limit mm
  qw_cfg_t3_x_max: 254,  // config X max limit mm
  qw_cfg_t3_y_min: 255,  // config Y min limit mm
  qw_cfg_t3_y_max: 256,  // config Y max limit mm
  qw_cfg_t3_x_avoid: 257,  // X avoid distance mm
  qw_cfg_t3_y_avoid: 258,  // Y avoid distance mm
  qw_cfg_t3_ph_xacc_x100: 259,  // X accel ×100 (0.01s)
  qw_cfg_t3_ph_xdec_x100: 260,  // X decel ×100 (0.01s)
  qw_cfg_t3_ph_xmax: 261,  // X max speed mm/s
  qw_cfg_t3_ph_ztot: 262,  // Z total travel mm
  qw_cfg_t3_ph_zsdry: 263,  // Z slow zone dry mm
  qw_cfg_t3_ph_zswet: 264,  // Z slow zone wet mm
  qw_cfg_t3_ph_zsend: 265,  // Z slow zone end mm
  qw_cfg_t3_ph_zslow: 266,  // Z slow speed mm/s
  qw_cfg_t3_ph_zfast: 267,  // Z fast speed mm/s
  qw_cfg_t3_ph_drip_x10: 268,  // drip delay ×10 (0.1s)
  qw_cfg_t3_ph_avoid: 269,  // physics avoid mm
  qw_cfg_t3_ta1_min_lift: 270,  // task area 1 min lift station
  qw_cfg_t3_ta1_max_lift: 271,  // task area 1 max lift station
  qw_cfg_t3_ta1_min_sink: 272,  // task area 1 min sink station
  qw_cfg_t3_ta1_max_sink: 273,  // task area 1 max sink station
  qw_cfg_t3_ta2_min_lift: 274,  // task area 2 min lift station
  qw_cfg_t3_ta2_max_lift: 275,  // task area 2 max lift station
  qw_cfg_t3_ta2_min_sink: 276,  // task area 2 min sink station
  qw_cfg_t3_ta2_max_sink: 277,  // task area 2 max sink station
  qw_cfg_t3_ta3_min_lift: 278,  // task area 3 min lift station
  qw_cfg_t3_ta3_max_lift: 279,  // task area 3 max lift station
  qw_cfg_t3_ta3_min_sink: 280,  // task area 3 min sink station
  qw_cfg_t3_ta3_max_sink: 281,  // task area 3 max sink station
  qw_s101_val: 282,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s102_val: 283,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s103_val: 284,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s104_val: 285,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s105_val: 286,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s106_val: 287,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s107_val: 288,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s108_val: 289,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s109_val: 290,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s110_val: 291,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s111_val: 292,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s112_val: 293,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s113_val: 294,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s114_val: 295,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s115_val: 296,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s116_val: 297,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s117_val: 298,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s118_val: 299,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s119_val: 300,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s120_val: 301,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s121_val: 302,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s122_val: 303,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s123_val: 304,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s124_val: 305,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s125_val: 306,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s126_val: 307,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s127_val: 308,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s128_val: 309,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s129_val: 310,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_s130_val: 311,  // AVOID_NONE=0, PASS=1, BLOCK=2
  qw_sched_u1_stage_cnt: 312,  // number of active stages
  qw_sched_u2_stage_cnt: 313,  // number of active stages
  qw_sched_u3_stage_cnt: 314,  // number of active stages
  qw_sched_u4_stage_cnt: 315,  // number of active stages
  qw_sched_u5_stage_cnt: 316,  // number of active stages
  qw_sched_u6_stage_cnt: 317,  // number of active stages
  qw_sched_u7_stage_cnt: 318,  // number of active stages
  qw_sched_u8_stage_cnt: 319,  // number of active stages
  qw_sched_u9_stage_cnt: 320,  // number of active stages
  qw_sched_u10_stage_cnt: 321,  // number of active stages
  qw_tq1_count: 322,  // number of active tasks
  qw_tq1_q1_unit: 323,  // task 1 unit index (0=empty)
  qw_tq1_q1_stage: 324,  // task 1 program stage
  qw_tq1_q1_lift: 325,  // task 1 pickup station
  qw_tq1_q1_sink: 326,  // task 1 putdown station
  qw_tq1_q1_start_hi: 327,  // task 1 start time upper 16
  qw_tq1_q1_start_lo: 328,  // task 1 start time lower 16
  qw_tq1_q1_fin_hi: 329,  // task 1 finish time upper 16
  qw_tq1_q1_fin_lo: 330,  // task 1 finish time lower 16
  qw_tq1_q1_calc_x10: 331,  // task 1 calc time ×10
  qw_tq1_q1_min_x10: 332,  // task 1 min time ×10
  qw_tq1_q1_max_x10: 333,  // task 1 max time ×10
  qw_tq1_q2_unit: 334,  // task 2 unit index (0=empty)
  qw_tq1_q2_stage: 335,  // task 2 program stage
  qw_tq1_q2_lift: 336,  // task 2 pickup station
  qw_tq1_q2_sink: 337,  // task 2 putdown station
  qw_tq1_q2_start_hi: 338,  // task 2 start time upper 16
  qw_tq1_q2_start_lo: 339,  // task 2 start time lower 16
  qw_tq1_q2_fin_hi: 340,  // task 2 finish time upper 16
  qw_tq1_q2_fin_lo: 341,  // task 2 finish time lower 16
  qw_tq1_q2_calc_x10: 342,  // task 2 calc time ×10
  qw_tq1_q2_min_x10: 343,  // task 2 min time ×10
  qw_tq1_q2_max_x10: 344,  // task 2 max time ×10
  qw_tq1_q3_unit: 345,  // task 3 unit index (0=empty)
  qw_tq1_q3_stage: 346,  // task 3 program stage
  qw_tq1_q3_lift: 347,  // task 3 pickup station
  qw_tq1_q3_sink: 348,  // task 3 putdown station
  qw_tq1_q3_start_hi: 349,  // task 3 start time upper 16
  qw_tq1_q3_start_lo: 350,  // task 3 start time lower 16
  qw_tq1_q3_fin_hi: 351,  // task 3 finish time upper 16
  qw_tq1_q3_fin_lo: 352,  // task 3 finish time lower 16
  qw_tq1_q3_calc_x10: 353,  // task 3 calc time ×10
  qw_tq1_q3_min_x10: 354,  // task 3 min time ×10
  qw_tq1_q3_max_x10: 355,  // task 3 max time ×10
  qw_tq1_q4_unit: 356,  // task 4 unit index (0=empty)
  qw_tq1_q4_stage: 357,  // task 4 program stage
  qw_tq1_q4_lift: 358,  // task 4 pickup station
  qw_tq1_q4_sink: 359,  // task 4 putdown station
  qw_tq1_q4_start_hi: 360,  // task 4 start time upper 16
  qw_tq1_q4_start_lo: 361,  // task 4 start time lower 16
  qw_tq1_q4_fin_hi: 362,  // task 4 finish time upper 16
  qw_tq1_q4_fin_lo: 363,  // task 4 finish time lower 16
  qw_tq1_q4_calc_x10: 364,  // task 4 calc time ×10
  qw_tq1_q4_min_x10: 365,  // task 4 min time ×10
  qw_tq1_q4_max_x10: 366,  // task 4 max time ×10
  qw_tq1_q5_unit: 367,  // task 5 unit index (0=empty)
  qw_tq1_q5_stage: 368,  // task 5 program stage
  qw_tq1_q5_lift: 369,  // task 5 pickup station
  qw_tq1_q5_sink: 370,  // task 5 putdown station
  qw_tq1_q5_start_hi: 371,  // task 5 start time upper 16
  qw_tq1_q5_start_lo: 372,  // task 5 start time lower 16
  qw_tq1_q5_fin_hi: 373,  // task 5 finish time upper 16
  qw_tq1_q5_fin_lo: 374,  // task 5 finish time lower 16
  qw_tq1_q5_calc_x10: 375,  // task 5 calc time ×10
  qw_tq1_q5_min_x10: 376,  // task 5 min time ×10
  qw_tq1_q5_max_x10: 377,  // task 5 max time ×10
  qw_tq1_q6_unit: 378,  // task 6 unit index (0=empty)
  qw_tq1_q6_stage: 379,  // task 6 program stage
  qw_tq1_q6_lift: 380,  // task 6 pickup station
  qw_tq1_q6_sink: 381,  // task 6 putdown station
  qw_tq1_q6_start_hi: 382,  // task 6 start time upper 16
  qw_tq1_q6_start_lo: 383,  // task 6 start time lower 16
  qw_tq1_q6_fin_hi: 384,  // task 6 finish time upper 16
  qw_tq1_q6_fin_lo: 385,  // task 6 finish time lower 16
  qw_tq1_q6_calc_x10: 386,  // task 6 calc time ×10
  qw_tq1_q6_min_x10: 387,  // task 6 min time ×10
  qw_tq1_q6_max_x10: 388,  // task 6 max time ×10
  qw_tq1_q7_unit: 389,  // task 7 unit index (0=empty)
  qw_tq1_q7_stage: 390,  // task 7 program stage
  qw_tq1_q7_lift: 391,  // task 7 pickup station
  qw_tq1_q7_sink: 392,  // task 7 putdown station
  qw_tq1_q7_start_hi: 393,  // task 7 start time upper 16
  qw_tq1_q7_start_lo: 394,  // task 7 start time lower 16
  qw_tq1_q7_fin_hi: 395,  // task 7 finish time upper 16
  qw_tq1_q7_fin_lo: 396,  // task 7 finish time lower 16
  qw_tq1_q7_calc_x10: 397,  // task 7 calc time ×10
  qw_tq1_q7_min_x10: 398,  // task 7 min time ×10
  qw_tq1_q7_max_x10: 399,  // task 7 max time ×10
  qw_tq1_q8_unit: 400,  // task 8 unit index (0=empty)
  qw_tq1_q8_stage: 401,  // task 8 program stage
  qw_tq1_q8_lift: 402,  // task 8 pickup station
  qw_tq1_q8_sink: 403,  // task 8 putdown station
  qw_tq1_q8_start_hi: 404,  // task 8 start time upper 16
  qw_tq1_q8_start_lo: 405,  // task 8 start time lower 16
  qw_tq1_q8_fin_hi: 406,  // task 8 finish time upper 16
  qw_tq1_q8_fin_lo: 407,  // task 8 finish time lower 16
  qw_tq1_q8_calc_x10: 408,  // task 8 calc time ×10
  qw_tq1_q8_min_x10: 409,  // task 8 min time ×10
  qw_tq1_q8_max_x10: 410,  // task 8 max time ×10
  qw_tq1_q9_unit: 411,  // task 9 unit index (0=empty)
  qw_tq1_q9_stage: 412,  // task 9 program stage
  qw_tq1_q9_lift: 413,  // task 9 pickup station
  qw_tq1_q9_sink: 414,  // task 9 putdown station
  qw_tq1_q9_start_hi: 415,  // task 9 start time upper 16
  qw_tq1_q9_start_lo: 416,  // task 9 start time lower 16
  qw_tq1_q9_fin_hi: 417,  // task 9 finish time upper 16
  qw_tq1_q9_fin_lo: 418,  // task 9 finish time lower 16
  qw_tq1_q9_calc_x10: 419,  // task 9 calc time ×10
  qw_tq1_q9_min_x10: 420,  // task 9 min time ×10
  qw_tq1_q9_max_x10: 421,  // task 9 max time ×10
  qw_tq1_q10_unit: 422,  // task 10 unit index (0=empty)
  qw_tq1_q10_stage: 423,  // task 10 program stage
  qw_tq1_q10_lift: 424,  // task 10 pickup station
  qw_tq1_q10_sink: 425,  // task 10 putdown station
  qw_tq1_q10_start_hi: 426,  // task 10 start time upper 16
  qw_tq1_q10_start_lo: 427,  // task 10 start time lower 16
  qw_tq1_q10_fin_hi: 428,  // task 10 finish time upper 16
  qw_tq1_q10_fin_lo: 429,  // task 10 finish time lower 16
  qw_tq1_q10_calc_x10: 430,  // task 10 calc time ×10
  qw_tq1_q10_min_x10: 431,  // task 10 min time ×10
  qw_tq1_q10_max_x10: 432,  // task 10 max time ×10
  qw_tq2_count: 433,  // number of active tasks
  qw_tq2_q1_unit: 434,  // task 1 unit index (0=empty)
  qw_tq2_q1_stage: 435,  // task 1 program stage
  qw_tq2_q1_lift: 436,  // task 1 pickup station
  qw_tq2_q1_sink: 437,  // task 1 putdown station
  qw_tq2_q1_start_hi: 438,  // task 1 start time upper 16
  qw_tq2_q1_start_lo: 439,  // task 1 start time lower 16
  qw_tq2_q1_fin_hi: 440,  // task 1 finish time upper 16
  qw_tq2_q1_fin_lo: 441,  // task 1 finish time lower 16
  qw_tq2_q1_calc_x10: 442,  // task 1 calc time ×10
  qw_tq2_q1_min_x10: 443,  // task 1 min time ×10
  qw_tq2_q1_max_x10: 444,  // task 1 max time ×10
  qw_tq2_q2_unit: 445,  // task 2 unit index (0=empty)
  qw_tq2_q2_stage: 446,  // task 2 program stage
  qw_tq2_q2_lift: 447,  // task 2 pickup station
  qw_tq2_q2_sink: 448,  // task 2 putdown station
  qw_tq2_q2_start_hi: 449,  // task 2 start time upper 16
  qw_tq2_q2_start_lo: 450,  // task 2 start time lower 16
  qw_tq2_q2_fin_hi: 451,  // task 2 finish time upper 16
  qw_tq2_q2_fin_lo: 452,  // task 2 finish time lower 16
  qw_tq2_q2_calc_x10: 453,  // task 2 calc time ×10
  qw_tq2_q2_min_x10: 454,  // task 2 min time ×10
  qw_tq2_q2_max_x10: 455,  // task 2 max time ×10
  qw_tq2_q3_unit: 456,  // task 3 unit index (0=empty)
  qw_tq2_q3_stage: 457,  // task 3 program stage
  qw_tq2_q3_lift: 458,  // task 3 pickup station
  qw_tq2_q3_sink: 459,  // task 3 putdown station
  qw_tq2_q3_start_hi: 460,  // task 3 start time upper 16
  qw_tq2_q3_start_lo: 461,  // task 3 start time lower 16
  qw_tq2_q3_fin_hi: 462,  // task 3 finish time upper 16
  qw_tq2_q3_fin_lo: 463,  // task 3 finish time lower 16
  qw_tq2_q3_calc_x10: 464,  // task 3 calc time ×10
  qw_tq2_q3_min_x10: 465,  // task 3 min time ×10
  qw_tq2_q3_max_x10: 466,  // task 3 max time ×10
  qw_tq2_q4_unit: 467,  // task 4 unit index (0=empty)
  qw_tq2_q4_stage: 468,  // task 4 program stage
  qw_tq2_q4_lift: 469,  // task 4 pickup station
  qw_tq2_q4_sink: 470,  // task 4 putdown station
  qw_tq2_q4_start_hi: 471,  // task 4 start time upper 16
  qw_tq2_q4_start_lo: 472,  // task 4 start time lower 16
  qw_tq2_q4_fin_hi: 473,  // task 4 finish time upper 16
  qw_tq2_q4_fin_lo: 474,  // task 4 finish time lower 16
  qw_tq2_q4_calc_x10: 475,  // task 4 calc time ×10
  qw_tq2_q4_min_x10: 476,  // task 4 min time ×10
  qw_tq2_q4_max_x10: 477,  // task 4 max time ×10
  qw_tq2_q5_unit: 478,  // task 5 unit index (0=empty)
  qw_tq2_q5_stage: 479,  // task 5 program stage
  qw_tq2_q5_lift: 480,  // task 5 pickup station
  qw_tq2_q5_sink: 481,  // task 5 putdown station
  qw_tq2_q5_start_hi: 482,  // task 5 start time upper 16
  qw_tq2_q5_start_lo: 483,  // task 5 start time lower 16
  qw_tq2_q5_fin_hi: 484,  // task 5 finish time upper 16
  qw_tq2_q5_fin_lo: 485,  // task 5 finish time lower 16
  qw_tq2_q5_calc_x10: 486,  // task 5 calc time ×10
  qw_tq2_q5_min_x10: 487,  // task 5 min time ×10
  qw_tq2_q5_max_x10: 488,  // task 5 max time ×10
  qw_tq2_q6_unit: 489,  // task 6 unit index (0=empty)
  qw_tq2_q6_stage: 490,  // task 6 program stage
  qw_tq2_q6_lift: 491,  // task 6 pickup station
  qw_tq2_q6_sink: 492,  // task 6 putdown station
  qw_tq2_q6_start_hi: 493,  // task 6 start time upper 16
  qw_tq2_q6_start_lo: 494,  // task 6 start time lower 16
  qw_tq2_q6_fin_hi: 495,  // task 6 finish time upper 16
  qw_tq2_q6_fin_lo: 496,  // task 6 finish time lower 16
  qw_tq2_q6_calc_x10: 497,  // task 6 calc time ×10
  qw_tq2_q6_min_x10: 498,  // task 6 min time ×10
  qw_tq2_q6_max_x10: 499,  // task 6 max time ×10
  qw_tq2_q7_unit: 500,  // task 7 unit index (0=empty)
  qw_tq2_q7_stage: 501,  // task 7 program stage
  qw_tq2_q7_lift: 502,  // task 7 pickup station
  qw_tq2_q7_sink: 503,  // task 7 putdown station
  qw_tq2_q7_start_hi: 504,  // task 7 start time upper 16
  qw_tq2_q7_start_lo: 505,  // task 7 start time lower 16
  qw_tq2_q7_fin_hi: 506,  // task 7 finish time upper 16
  qw_tq2_q7_fin_lo: 507,  // task 7 finish time lower 16
  qw_tq2_q7_calc_x10: 508,  // task 7 calc time ×10
  qw_tq2_q7_min_x10: 509,  // task 7 min time ×10
  qw_tq2_q7_max_x10: 510,  // task 7 max time ×10
  qw_tq2_q8_unit: 511,  // task 8 unit index (0=empty)
  qw_tq2_q8_stage: 512,  // task 8 program stage
  qw_tq2_q8_lift: 513,  // task 8 pickup station
  qw_tq2_q8_sink: 514,  // task 8 putdown station
  qw_tq2_q8_start_hi: 515,  // task 8 start time upper 16
  qw_tq2_q8_start_lo: 516,  // task 8 start time lower 16
  qw_tq2_q8_fin_hi: 517,  // task 8 finish time upper 16
  qw_tq2_q8_fin_lo: 518,  // task 8 finish time lower 16
  qw_tq2_q8_calc_x10: 519,  // task 8 calc time ×10
  qw_tq2_q8_min_x10: 520,  // task 8 min time ×10
  qw_tq2_q8_max_x10: 521,  // task 8 max time ×10
  qw_tq2_q9_unit: 522,  // task 9 unit index (0=empty)
  qw_tq2_q9_stage: 523,  // task 9 program stage
  qw_tq2_q9_lift: 524,  // task 9 pickup station
  qw_tq2_q9_sink: 525,  // task 9 putdown station
  qw_tq2_q9_start_hi: 526,  // task 9 start time upper 16
  qw_tq2_q9_start_lo: 527,  // task 9 start time lower 16
  qw_tq2_q9_fin_hi: 528,  // task 9 finish time upper 16
  qw_tq2_q9_fin_lo: 529,  // task 9 finish time lower 16
  qw_tq2_q9_calc_x10: 530,  // task 9 calc time ×10
  qw_tq2_q9_min_x10: 531,  // task 9 min time ×10
  qw_tq2_q9_max_x10: 532,  // task 9 max time ×10
  qw_tq2_q10_unit: 533,  // task 10 unit index (0=empty)
  qw_tq2_q10_stage: 534,  // task 10 program stage
  qw_tq2_q10_lift: 535,  // task 10 pickup station
  qw_tq2_q10_sink: 536,  // task 10 putdown station
  qw_tq2_q10_start_hi: 537,  // task 10 start time upper 16
  qw_tq2_q10_start_lo: 538,  // task 10 start time lower 16
  qw_tq2_q10_fin_hi: 539,  // task 10 finish time upper 16
  qw_tq2_q10_fin_lo: 540,  // task 10 finish time lower 16
  qw_tq2_q10_calc_x10: 541,  // task 10 calc time ×10
  qw_tq2_q10_min_x10: 542,  // task 10 min time ×10
  qw_tq2_q10_max_x10: 543,  // task 10 max time ×10
  qw_tq3_count: 544,  // number of active tasks
  qw_tq3_q1_unit: 545,  // task 1 unit index (0=empty)
  qw_tq3_q1_stage: 546,  // task 1 program stage
  qw_tq3_q1_lift: 547,  // task 1 pickup station
  qw_tq3_q1_sink: 548,  // task 1 putdown station
  qw_tq3_q1_start_hi: 549,  // task 1 start time upper 16
  qw_tq3_q1_start_lo: 550,  // task 1 start time lower 16
  qw_tq3_q1_fin_hi: 551,  // task 1 finish time upper 16
  qw_tq3_q1_fin_lo: 552,  // task 1 finish time lower 16
  qw_tq3_q1_calc_x10: 553,  // task 1 calc time ×10
  qw_tq3_q1_min_x10: 554,  // task 1 min time ×10
  qw_tq3_q1_max_x10: 555,  // task 1 max time ×10
  qw_tq3_q2_unit: 556,  // task 2 unit index (0=empty)
  qw_tq3_q2_stage: 557,  // task 2 program stage
  qw_tq3_q2_lift: 558,  // task 2 pickup station
  qw_tq3_q2_sink: 559,  // task 2 putdown station
  qw_tq3_q2_start_hi: 560,  // task 2 start time upper 16
  qw_tq3_q2_start_lo: 561,  // task 2 start time lower 16
  qw_tq3_q2_fin_hi: 562,  // task 2 finish time upper 16
  qw_tq3_q2_fin_lo: 563,  // task 2 finish time lower 16
  qw_tq3_q2_calc_x10: 564,  // task 2 calc time ×10
  qw_tq3_q2_min_x10: 565,  // task 2 min time ×10
  qw_tq3_q2_max_x10: 566,  // task 2 max time ×10
  qw_tq3_q3_unit: 567,  // task 3 unit index (0=empty)
  qw_tq3_q3_stage: 568,  // task 3 program stage
  qw_tq3_q3_lift: 569,  // task 3 pickup station
  qw_tq3_q3_sink: 570,  // task 3 putdown station
  qw_tq3_q3_start_hi: 571,  // task 3 start time upper 16
  qw_tq3_q3_start_lo: 572,  // task 3 start time lower 16
  qw_tq3_q3_fin_hi: 573,  // task 3 finish time upper 16
  qw_tq3_q3_fin_lo: 574,  // task 3 finish time lower 16
  qw_tq3_q3_calc_x10: 575,  // task 3 calc time ×10
  qw_tq3_q3_min_x10: 576,  // task 3 min time ×10
  qw_tq3_q3_max_x10: 577,  // task 3 max time ×10
  qw_tq3_q4_unit: 578,  // task 4 unit index (0=empty)
  qw_tq3_q4_stage: 579,  // task 4 program stage
  qw_tq3_q4_lift: 580,  // task 4 pickup station
  qw_tq3_q4_sink: 581,  // task 4 putdown station
  qw_tq3_q4_start_hi: 582,  // task 4 start time upper 16
  qw_tq3_q4_start_lo: 583,  // task 4 start time lower 16
  qw_tq3_q4_fin_hi: 584,  // task 4 finish time upper 16
  qw_tq3_q4_fin_lo: 585,  // task 4 finish time lower 16
  qw_tq3_q4_calc_x10: 586,  // task 4 calc time ×10
  qw_tq3_q4_min_x10: 587,  // task 4 min time ×10
  qw_tq3_q4_max_x10: 588,  // task 4 max time ×10
  qw_tq3_q5_unit: 589,  // task 5 unit index (0=empty)
  qw_tq3_q5_stage: 590,  // task 5 program stage
  qw_tq3_q5_lift: 591,  // task 5 pickup station
  qw_tq3_q5_sink: 592,  // task 5 putdown station
  qw_tq3_q5_start_hi: 593,  // task 5 start time upper 16
  qw_tq3_q5_start_lo: 594,  // task 5 start time lower 16
  qw_tq3_q5_fin_hi: 595,  // task 5 finish time upper 16
  qw_tq3_q5_fin_lo: 596,  // task 5 finish time lower 16
  qw_tq3_q5_calc_x10: 597,  // task 5 calc time ×10
  qw_tq3_q5_min_x10: 598,  // task 5 min time ×10
  qw_tq3_q5_max_x10: 599,  // task 5 max time ×10
  qw_tq3_q6_unit: 600,  // task 6 unit index (0=empty)
  qw_tq3_q6_stage: 601,  // task 6 program stage
  qw_tq3_q6_lift: 602,  // task 6 pickup station
  qw_tq3_q6_sink: 603,  // task 6 putdown station
  qw_tq3_q6_start_hi: 604,  // task 6 start time upper 16
  qw_tq3_q6_start_lo: 605,  // task 6 start time lower 16
  qw_tq3_q6_fin_hi: 606,  // task 6 finish time upper 16
  qw_tq3_q6_fin_lo: 607,  // task 6 finish time lower 16
  qw_tq3_q6_calc_x10: 608,  // task 6 calc time ×10
  qw_tq3_q6_min_x10: 609,  // task 6 min time ×10
  qw_tq3_q6_max_x10: 610,  // task 6 max time ×10
  qw_tq3_q7_unit: 611,  // task 7 unit index (0=empty)
  qw_tq3_q7_stage: 612,  // task 7 program stage
  qw_tq3_q7_lift: 613,  // task 7 pickup station
  qw_tq3_q7_sink: 614,  // task 7 putdown station
  qw_tq3_q7_start_hi: 615,  // task 7 start time upper 16
  qw_tq3_q7_start_lo: 616,  // task 7 start time lower 16
  qw_tq3_q7_fin_hi: 617,  // task 7 finish time upper 16
  qw_tq3_q7_fin_lo: 618,  // task 7 finish time lower 16
  qw_tq3_q7_calc_x10: 619,  // task 7 calc time ×10
  qw_tq3_q7_min_x10: 620,  // task 7 min time ×10
  qw_tq3_q7_max_x10: 621,  // task 7 max time ×10
  qw_tq3_q8_unit: 622,  // task 8 unit index (0=empty)
  qw_tq3_q8_stage: 623,  // task 8 program stage
  qw_tq3_q8_lift: 624,  // task 8 pickup station
  qw_tq3_q8_sink: 625,  // task 8 putdown station
  qw_tq3_q8_start_hi: 626,  // task 8 start time upper 16
  qw_tq3_q8_start_lo: 627,  // task 8 start time lower 16
  qw_tq3_q8_fin_hi: 628,  // task 8 finish time upper 16
  qw_tq3_q8_fin_lo: 629,  // task 8 finish time lower 16
  qw_tq3_q8_calc_x10: 630,  // task 8 calc time ×10
  qw_tq3_q8_min_x10: 631,  // task 8 min time ×10
  qw_tq3_q8_max_x10: 632,  // task 8 max time ×10
  qw_tq3_q9_unit: 633,  // task 9 unit index (0=empty)
  qw_tq3_q9_stage: 634,  // task 9 program stage
  qw_tq3_q9_lift: 635,  // task 9 pickup station
  qw_tq3_q9_sink: 636,  // task 9 putdown station
  qw_tq3_q9_start_hi: 637,  // task 9 start time upper 16
  qw_tq3_q9_start_lo: 638,  // task 9 start time lower 16
  qw_tq3_q9_fin_hi: 639,  // task 9 finish time upper 16
  qw_tq3_q9_fin_lo: 640,  // task 9 finish time lower 16
  qw_tq3_q9_calc_x10: 641,  // task 9 calc time ×10
  qw_tq3_q9_min_x10: 642,  // task 9 min time ×10
  qw_tq3_q9_max_x10: 643,  // task 9 max time ×10
  qw_tq3_q10_unit: 644,  // task 10 unit index (0=empty)
  qw_tq3_q10_stage: 645,  // task 10 program stage
  qw_tq3_q10_lift: 646,  // task 10 pickup station
  qw_tq3_q10_sink: 647,  // task 10 putdown station
  qw_tq3_q10_start_hi: 648,  // task 10 start time upper 16
  qw_tq3_q10_start_lo: 649,  // task 10 start time lower 16
  qw_tq3_q10_fin_hi: 650,  // task 10 finish time upper 16
  qw_tq3_q10_fin_lo: 651,  // task 10 finish time lower 16
  qw_tq3_q10_calc_x10: 652,  // task 10 calc time ×10
  qw_tq3_q10_min_x10: 653,  // task 10 min time ×10
  qw_tq3_q10_max_x10: 654,  // task 10 max time ×10
  qw_dep_state_activated: 655,  // 1=departure activated handshake
  qw_dep_state_stable: 656,  // 1=task list stable for DEP
  qw_dep_state_waiting_cnt: 657,  // waiting batch count
  qw_dep_state_overlap_cnt: 658,  // overlap station count
  qw_dep_state_pend_valid: 659,  // 1=pending write valid
  qw_dep_state_pend_unit: 660,  // pending activated unit
  qw_dep_state_pend_stage: 661,  // pending activated stage
  qw_dep_state_pend_time_hi: 662,  // pending activation time upper 16
  qw_dep_state_pend_time_lo: 663,  // pending activation time lower 16
  qw_dw1_unit: 664,  // waiting batch unit index (0=empty)
  qw_dw2_unit: 665,  // waiting batch unit index (0=empty)
  qw_dw3_unit: 666,  // waiting batch unit index (0=empty)
  qw_dw4_unit: 667,  // waiting batch unit index (0=empty)
  qw_dw5_unit: 668,  // waiting batch unit index (0=empty)
  qw_ov_s101_flag: 669,  // 1=station in overlap zone
  qw_ov_s102_flag: 670,  // 1=station in overlap zone
  qw_ov_s103_flag: 671,  // 1=station in overlap zone
  qw_ov_s104_flag: 672,  // 1=station in overlap zone
  qw_ov_s105_flag: 673,  // 1=station in overlap zone
  qw_ov_s106_flag: 674,  // 1=station in overlap zone
  qw_ov_s107_flag: 675,  // 1=station in overlap zone
  qw_ov_s108_flag: 676,  // 1=station in overlap zone
  qw_ov_s109_flag: 677,  // 1=station in overlap zone
  qw_ov_s110_flag: 678,  // 1=station in overlap zone
  qw_ov_s111_flag: 679,  // 1=station in overlap zone
  qw_ov_s112_flag: 680,  // 1=station in overlap zone
  qw_ov_s113_flag: 681,  // 1=station in overlap zone
  qw_ov_s114_flag: 682,  // 1=station in overlap zone
  qw_ov_s115_flag: 683,  // 1=station in overlap zone
  qw_ov_s116_flag: 684,  // 1=station in overlap zone
  qw_ov_s117_flag: 685,  // 1=station in overlap zone
  qw_ov_s118_flag: 686,  // 1=station in overlap zone
  qw_ov_s119_flag: 687,  // 1=station in overlap zone
  qw_ov_s120_flag: 688,  // 1=station in overlap zone
  qw_ov_s121_flag: 689,  // 1=station in overlap zone
  qw_ov_s122_flag: 690,  // 1=station in overlap zone
  qw_ov_s123_flag: 691,  // 1=station in overlap zone
  qw_ov_s124_flag: 692,  // 1=station in overlap zone
  qw_ov_s125_flag: 693,  // 1=station in overlap zone
  qw_ov_s126_flag: 694,  // 1=station in overlap zone
  qw_ov_s127_flag: 695,  // 1=station in overlap zone
  qw_ov_s128_flag: 696,  // 1=station in overlap zone
  qw_ov_s129_flag: 697,  // 1=station in overlap zone
  qw_ov_s130_flag: 698,  // 1=station in overlap zone
  iw_cmd_t1_start: 699,  // 1=trigger command
  iw_cmd_t1_lift: 700,  // lift station number
  iw_cmd_t1_sink: 701,  // sink station number
  iw_cmd_t2_start: 702,  // 1=trigger command
  iw_cmd_t2_lift: 703,  // lift station number
  iw_cmd_t2_sink: 704,  // sink station number
  iw_cfg_seq: 705,  // sequence — triggers on change
  iw_cfg_cmd: 706,  // 1=write_station, 2=init, 3=clear_all
  iw_cfg_param: 707,  // station_number or station_count
  iw_cfg_d0: 708,  // tank_id
  iw_cfg_d1: 709,  // x_position mm
  iw_cfg_d2: 710,  // y_position mm
  iw_cfg_d3: 711,  // z_position mm
  iw_cfg_d4: 712,  // type
  iw_cfg_d5: 713,  // dropping_time ×10
  iw_cfg_d6: 714,  // device_delay ×10
  iw_unit_seq: 715,  // sequence — triggers on change
  iw_unit_id: 716,  // unit number 1..10
  iw_unit_loc: 717,  // location (station number)
  iw_unit_status: 718,  // NOT_USED=0, USED=1
  iw_unit_state: 719,  // EMPTY=0, FULL=1
  iw_unit_target: 720,  // TO_NONE=0..TO_AVOID=5
  iw_batch_seq: 721,  // sequence — triggers on change
  iw_batch_unit: 722,  // unit index 1..10
  iw_batch_code: 723,  // numeric batch code
  iw_batch_state: 724,  // NOT_PROCESSED=0, IN_PROCESS=1, PROCESSED=2
  iw_batch_prog_id: 725,  // treatment program ID
  iw_prog_seq: 726,  // sequence — triggers on change
  iw_prog_unit: 727,  // unit index 1..10
  iw_prog_stage: 728,  // stage index 1..30
  iw_prog_s1: 729,  // station 1 (0=unused)
  iw_prog_s2: 730,  // station 2
  iw_prog_s3: 731,  // station 3
  iw_prog_s4: 732,  // station 4
  iw_prog_s5: 733,  // station 5
  iw_prog_min_time: 734,  // min processing time seconds
  iw_prog_max_time: 735,  // max processing time seconds
  iw_prog_cal_time: 736,  // calculated time seconds
  iw_avoid_seq: 737,  // sequence — triggers on change
  iw_avoid_station: 738,  // station number
  iw_avoid_value: 739,  // AVOID_NONE=0, PASS=1, BLOCK=2
  iw_time_hi: 740,  // unix seconds upper 16 bits
  iw_time_lo: 741,  // unix seconds lower 16 bits
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
  state.transporter_state[1].z_stage = toSigned(r[4]);
  state.transporter_state[1].current_station = toSigned(r[5]);
  state.transporter_state[1].lift_station_target = toSigned(r[6]);
  state.transporter_state[1].sink_station_target = toSigned(r[7]);
  state.transporter_state[1].active = toSigned(r[8]);
  state.transporter_state[1].status_raw = toSigned(r[9]);
  state.transporter_state[1]._rtask_id_hi = r[10];
  state.transporter_state[1]._rtask_id_lo = r[11];
  // Combined uint32: running_task_id = (hi << 16) | lo
  state.transporter_state[1].running_task_id = ((state.transporter_state[1]._rtask_hi & 0xFFFF) * 65536) + (state.transporter_state[1]._rtask_lo & 0xFFFF);
  state.transporter_state[2] = {};
  state.transporter_state[2].x_position = toSigned(r[12]);
  state.transporter_state[2].z_position = toSigned(r[13]);
  state.transporter_state[2].velocity_x = toSigned(r[14]) * 0.1;
  state.transporter_state[2].phase = toSigned(r[15]);
  state.transporter_state[2].z_stage = toSigned(r[16]);
  state.transporter_state[2].current_station = toSigned(r[17]);
  state.transporter_state[2].lift_station_target = toSigned(r[18]);
  state.transporter_state[2].sink_station_target = toSigned(r[19]);
  state.transporter_state[2].active = toSigned(r[20]);
  state.transporter_state[2].status_raw = toSigned(r[21]);
  state.transporter_state[2]._rtask_id_hi = r[22];
  state.transporter_state[2]._rtask_id_lo = r[23];
  // Combined uint32: running_task_id = (hi << 16) | lo
  state.transporter_state[2].running_task_id = ((state.transporter_state[2]._rtask_hi & 0xFFFF) * 65536) + (state.transporter_state[2]._rtask_lo & 0xFFFF);
  state.transporter_state[3] = {};
  state.transporter_state[3].x_position = toSigned(r[24]);
  state.transporter_state[3].z_position = toSigned(r[25]);
  state.transporter_state[3].velocity_x = toSigned(r[26]) * 0.1;
  state.transporter_state[3].phase = toSigned(r[27]);
  state.transporter_state[3].z_stage = toSigned(r[28]);
  state.transporter_state[3].current_station = toSigned(r[29]);
  state.transporter_state[3].lift_station_target = toSigned(r[30]);
  state.transporter_state[3].sink_station_target = toSigned(r[31]);
  state.transporter_state[3].active = toSigned(r[32]);
  state.transporter_state[3].status_raw = toSigned(r[33]);
  state.transporter_state[3]._rtask_id_hi = r[34];
  state.transporter_state[3]._rtask_id_lo = r[35];
  // Combined uint32: running_task_id = (hi << 16) | lo
  state.transporter_state[3].running_task_id = ((state.transporter_state[3]._rtask_hi & 0xFFFF) * 65536) + (state.transporter_state[3]._rtask_lo & 0xFFFF);
  // --- transporter_extended ---
  if (!state.transporter_extended) state.transporter_extended = {};
  state.transporter_extended[1] = {};
  state.transporter_extended[1].remaining_time = toSigned(r[36]) * 0.1;
  state.transporter_extended[1].treatment_time = toSigned(r[37]);
  state.transporter_extended[1].final_target_x = toSigned(r[38]);
  state.transporter_extended[1].drive_target_x = toSigned(r[39]);
  state.transporter_extended[1].final_target_y = toSigned(r[40]);
  state.transporter_extended[1].drive_target_y = toSigned(r[41]);
  state.transporter_extended[1].y_position = toSigned(r[42]);
  state.transporter_extended[1].z_timer = toSigned(r[43]) * 0.1;
  state.transporter_extended[1]._cmd_task_hi = r[44];
  state.transporter_extended[1]._cmd_task_lo = r[45];
  // Combined uint32: cmd_task_id = (hi << 16) | lo
  state.transporter_extended[1].cmd_task_id = ((state.transporter_extended[1]._ctask_hi & 0xFFFF) * 65536) + (state.transporter_extended[1]._ctask_lo & 0xFFFF);
  state.transporter_extended[1].lift_device_delay = toSigned(r[46]) * 0.1;
  state.transporter_extended[1].sink_device_delay = toSigned(r[47]) * 0.1;
  state.transporter_extended[1].dropping_time = toSigned(r[48]) * 0.1;
  state.transporter_extended[2] = {};
  state.transporter_extended[2].remaining_time = toSigned(r[49]) * 0.1;
  state.transporter_extended[2].treatment_time = toSigned(r[50]);
  state.transporter_extended[2].final_target_x = toSigned(r[51]);
  state.transporter_extended[2].drive_target_x = toSigned(r[52]);
  state.transporter_extended[2].final_target_y = toSigned(r[53]);
  state.transporter_extended[2].drive_target_y = toSigned(r[54]);
  state.transporter_extended[2].y_position = toSigned(r[55]);
  state.transporter_extended[2].z_timer = toSigned(r[56]) * 0.1;
  state.transporter_extended[2]._cmd_task_hi = r[57];
  state.transporter_extended[2]._cmd_task_lo = r[58];
  // Combined uint32: cmd_task_id = (hi << 16) | lo
  state.transporter_extended[2].cmd_task_id = ((state.transporter_extended[2]._ctask_hi & 0xFFFF) * 65536) + (state.transporter_extended[2]._ctask_lo & 0xFFFF);
  state.transporter_extended[2].lift_device_delay = toSigned(r[59]) * 0.1;
  state.transporter_extended[2].sink_device_delay = toSigned(r[60]) * 0.1;
  state.transporter_extended[2].dropping_time = toSigned(r[61]) * 0.1;
  state.transporter_extended[3] = {};
  state.transporter_extended[3].remaining_time = toSigned(r[62]) * 0.1;
  state.transporter_extended[3].treatment_time = toSigned(r[63]);
  state.transporter_extended[3].final_target_x = toSigned(r[64]);
  state.transporter_extended[3].drive_target_x = toSigned(r[65]);
  state.transporter_extended[3].final_target_y = toSigned(r[66]);
  state.transporter_extended[3].drive_target_y = toSigned(r[67]);
  state.transporter_extended[3].y_position = toSigned(r[68]);
  state.transporter_extended[3].z_timer = toSigned(r[69]) * 0.1;
  state.transporter_extended[3]._cmd_task_hi = r[70];
  state.transporter_extended[3]._cmd_task_lo = r[71];
  // Combined uint32: cmd_task_id = (hi << 16) | lo
  state.transporter_extended[3].cmd_task_id = ((state.transporter_extended[3]._ctask_hi & 0xFFFF) * 65536) + (state.transporter_extended[3]._ctask_lo & 0xFFFF);
  state.transporter_extended[3].lift_device_delay = toSigned(r[72]) * 0.1;
  state.transporter_extended[3].sink_device_delay = toSigned(r[73]) * 0.1;
  state.transporter_extended[3].dropping_time = toSigned(r[74]) * 0.1;
  // --- twa_limits ---
  if (!state.twa_limits) state.twa_limits = {};
  state.twa_limits[1] = {};
  state.twa_limits[1].x_min_drive_limit = toSigned(r[75]);
  state.twa_limits[1].x_max_drive_limit = toSigned(r[76]);
  state.twa_limits[2] = {};
  state.twa_limits[2].x_min_drive_limit = toSigned(r[77]);
  state.twa_limits[2].x_max_drive_limit = toSigned(r[78]);
  state.twa_limits[3] = {};
  state.twa_limits[3].x_min_drive_limit = toSigned(r[79]);
  state.twa_limits[3].x_max_drive_limit = toSigned(r[80]);
  // --- plc_status ---
  state.plc_status = {};
  state.plc_status.station_count = toSigned(r[81]);
  state.plc_status.init_done = toSigned(r[82]);
  state.plc_status.cycle_count = toSigned(r[83]);
  state.plc_status.cfg_ack = toSigned(r[84]);
  state.plc_status.unit_ack = toSigned(r[85]);
  state.plc_status.batch_ack = toSigned(r[86]);
  state.plc_status.prog_ack = toSigned(r[87]);
  state.plc_status.avoid_ack = toSigned(r[88]);
  state.plc_status.cal_active = toSigned(r[89]);
  state.plc_status._plc_time_hi = r[90];
  state.plc_status._plc_time_lo = r[91];
  // Combined uint32: plc_time_s = (hi << 16) | lo
  state.plc_status.plc_time_s = ((state.plc_status._time_hi & 0xFFFF) * 65536) + (state.plc_status._time_lo & 0xFFFF);
  // --- unit_state ---
  if (!state.unit_state) state.unit_state = {};
  state.unit_state[1] = {};
  state.unit_state[1].location = toSigned(r[92]);
  state.unit_state[1].status = toSigned(r[93]);
  state.unit_state[1].state = toSigned(r[94]);
  state.unit_state[1].target = toSigned(r[95]);
  state.unit_state[2] = {};
  state.unit_state[2].location = toSigned(r[96]);
  state.unit_state[2].status = toSigned(r[97]);
  state.unit_state[2].state = toSigned(r[98]);
  state.unit_state[2].target = toSigned(r[99]);
  state.unit_state[3] = {};
  state.unit_state[3].location = toSigned(r[100]);
  state.unit_state[3].status = toSigned(r[101]);
  state.unit_state[3].state = toSigned(r[102]);
  state.unit_state[3].target = toSigned(r[103]);
  state.unit_state[4] = {};
  state.unit_state[4].location = toSigned(r[104]);
  state.unit_state[4].status = toSigned(r[105]);
  state.unit_state[4].state = toSigned(r[106]);
  state.unit_state[4].target = toSigned(r[107]);
  state.unit_state[5] = {};
  state.unit_state[5].location = toSigned(r[108]);
  state.unit_state[5].status = toSigned(r[109]);
  state.unit_state[5].state = toSigned(r[110]);
  state.unit_state[5].target = toSigned(r[111]);
  state.unit_state[6] = {};
  state.unit_state[6].location = toSigned(r[112]);
  state.unit_state[6].status = toSigned(r[113]);
  state.unit_state[6].state = toSigned(r[114]);
  state.unit_state[6].target = toSigned(r[115]);
  state.unit_state[7] = {};
  state.unit_state[7].location = toSigned(r[116]);
  state.unit_state[7].status = toSigned(r[117]);
  state.unit_state[7].state = toSigned(r[118]);
  state.unit_state[7].target = toSigned(r[119]);
  state.unit_state[8] = {};
  state.unit_state[8].location = toSigned(r[120]);
  state.unit_state[8].status = toSigned(r[121]);
  state.unit_state[8].state = toSigned(r[122]);
  state.unit_state[8].target = toSigned(r[123]);
  state.unit_state[9] = {};
  state.unit_state[9].location = toSigned(r[124]);
  state.unit_state[9].status = toSigned(r[125]);
  state.unit_state[9].state = toSigned(r[126]);
  state.unit_state[9].target = toSigned(r[127]);
  state.unit_state[10] = {};
  state.unit_state[10].location = toSigned(r[128]);
  state.unit_state[10].status = toSigned(r[129]);
  state.unit_state[10].state = toSigned(r[130]);
  state.unit_state[10].target = toSigned(r[131]);
  // --- batch_state ---
  if (!state.batch_state) state.batch_state = {};
  state.batch_state[1] = {};
  state.batch_state[1].batch_code = toSigned(r[132]);
  state.batch_state[1].batch_state = toSigned(r[133]);
  state.batch_state[1].batch_program = toSigned(r[134]);
  state.batch_state[1].batch_stage = toSigned(r[135]);
  state.batch_state[2] = {};
  state.batch_state[2].batch_code = toSigned(r[136]);
  state.batch_state[2].batch_state = toSigned(r[137]);
  state.batch_state[2].batch_program = toSigned(r[138]);
  state.batch_state[2].batch_stage = toSigned(r[139]);
  state.batch_state[3] = {};
  state.batch_state[3].batch_code = toSigned(r[140]);
  state.batch_state[3].batch_state = toSigned(r[141]);
  state.batch_state[3].batch_program = toSigned(r[142]);
  state.batch_state[3].batch_stage = toSigned(r[143]);
  state.batch_state[4] = {};
  state.batch_state[4].batch_code = toSigned(r[144]);
  state.batch_state[4].batch_state = toSigned(r[145]);
  state.batch_state[4].batch_program = toSigned(r[146]);
  state.batch_state[4].batch_stage = toSigned(r[147]);
  state.batch_state[5] = {};
  state.batch_state[5].batch_code = toSigned(r[148]);
  state.batch_state[5].batch_state = toSigned(r[149]);
  state.batch_state[5].batch_program = toSigned(r[150]);
  state.batch_state[5].batch_stage = toSigned(r[151]);
  state.batch_state[6] = {};
  state.batch_state[6].batch_code = toSigned(r[152]);
  state.batch_state[6].batch_state = toSigned(r[153]);
  state.batch_state[6].batch_program = toSigned(r[154]);
  state.batch_state[6].batch_stage = toSigned(r[155]);
  state.batch_state[7] = {};
  state.batch_state[7].batch_code = toSigned(r[156]);
  state.batch_state[7].batch_state = toSigned(r[157]);
  state.batch_state[7].batch_program = toSigned(r[158]);
  state.batch_state[7].batch_stage = toSigned(r[159]);
  state.batch_state[8] = {};
  state.batch_state[8].batch_code = toSigned(r[160]);
  state.batch_state[8].batch_state = toSigned(r[161]);
  state.batch_state[8].batch_program = toSigned(r[162]);
  state.batch_state[8].batch_stage = toSigned(r[163]);
  state.batch_state[9] = {};
  state.batch_state[9].batch_code = toSigned(r[164]);
  state.batch_state[9].batch_state = toSigned(r[165]);
  state.batch_state[9].batch_program = toSigned(r[166]);
  state.batch_state[9].batch_stage = toSigned(r[167]);
  state.batch_state[10] = {};
  state.batch_state[10].batch_code = toSigned(r[168]);
  state.batch_state[10].batch_state = toSigned(r[169]);
  state.batch_state[10].batch_program = toSigned(r[170]);
  state.batch_state[10].batch_stage = toSigned(r[171]);
  // --- calibration ---
  state.calibration = {};
  state.calibration.cal_step = toSigned(r[172]);
  state.calibration.cal_tid = toSigned(r[173]);
  // --- calibration_results ---
  if (!state.calibration_results) state.calibration_results = {};
  state.calibration_results[1] = {};
  state.calibration_results[1].lift_wet = toSigned(r[174]) * 0.1;
  state.calibration_results[1].sink_wet = toSigned(r[175]) * 0.1;
  state.calibration_results[1].lift_dry = toSigned(r[176]) * 0.1;
  state.calibration_results[1].sink_dry = toSigned(r[177]) * 0.1;
  state.calibration_results[1].x_acc = toSigned(r[178]) * 0.1;
  state.calibration_results[1].x_dec = toSigned(r[179]) * 0.1;
  state.calibration_results[1].x_max = toSigned(r[180]);
  state.calibration_results[2] = {};
  state.calibration_results[2].lift_wet = toSigned(r[181]) * 0.1;
  state.calibration_results[2].sink_wet = toSigned(r[182]) * 0.1;
  state.calibration_results[2].lift_dry = toSigned(r[183]) * 0.1;
  state.calibration_results[2].sink_dry = toSigned(r[184]) * 0.1;
  state.calibration_results[2].x_acc = toSigned(r[185]) * 0.1;
  state.calibration_results[2].x_dec = toSigned(r[186]) * 0.1;
  state.calibration_results[2].x_max = toSigned(r[187]);
  state.calibration_results[3] = {};
  state.calibration_results[3].lift_wet = toSigned(r[188]) * 0.1;
  state.calibration_results[3].sink_wet = toSigned(r[189]) * 0.1;
  state.calibration_results[3].lift_dry = toSigned(r[190]) * 0.1;
  state.calibration_results[3].sink_dry = toSigned(r[191]) * 0.1;
  state.calibration_results[3].x_acc = toSigned(r[192]) * 0.1;
  state.calibration_results[3].x_dec = toSigned(r[193]) * 0.1;
  state.calibration_results[3].x_max = toSigned(r[194]);
  // --- transporter_config ---
  if (!state.transporter_config) state.transporter_config = {};
  state.transporter_config[1] = {};
  state.transporter_config[1].x_min_limit = toSigned(r[195]);
  state.transporter_config[1].x_max_limit = toSigned(r[196]);
  state.transporter_config[1].y_min_limit = toSigned(r[197]);
  state.transporter_config[1].y_max_limit = toSigned(r[198]);
  state.transporter_config[1].x_avoid_mm = toSigned(r[199]);
  state.transporter_config[1].y_avoid_mm = toSigned(r[200]);
  state.transporter_config[1].phys_x_accel = toSigned(r[201]) * 0.01;
  state.transporter_config[1].phys_x_decel = toSigned(r[202]) * 0.01;
  state.transporter_config[1].phys_x_max = toSigned(r[203]);
  state.transporter_config[1].phys_z_total = toSigned(r[204]);
  state.transporter_config[1].phys_z_sdry = toSigned(r[205]);
  state.transporter_config[1].phys_z_swet = toSigned(r[206]);
  state.transporter_config[1].phys_z_send = toSigned(r[207]);
  state.transporter_config[1].phys_z_slow = toSigned(r[208]);
  state.transporter_config[1].phys_z_fast = toSigned(r[209]);
  state.transporter_config[1].phys_drip = toSigned(r[210]) * 0.1;
  state.transporter_config[1].phys_avoid = toSigned(r[211]);
  state.transporter_config[1].ta1_min_lift = toSigned(r[212]);
  state.transporter_config[1].ta1_max_lift = toSigned(r[213]);
  state.transporter_config[1].ta1_min_sink = toSigned(r[214]);
  state.transporter_config[1].ta1_max_sink = toSigned(r[215]);
  state.transporter_config[1].ta2_min_lift = toSigned(r[216]);
  state.transporter_config[1].ta2_max_lift = toSigned(r[217]);
  state.transporter_config[1].ta2_min_sink = toSigned(r[218]);
  state.transporter_config[1].ta2_max_sink = toSigned(r[219]);
  state.transporter_config[1].ta3_min_lift = toSigned(r[220]);
  state.transporter_config[1].ta3_max_lift = toSigned(r[221]);
  state.transporter_config[1].ta3_min_sink = toSigned(r[222]);
  state.transporter_config[1].ta3_max_sink = toSigned(r[223]);
  state.transporter_config[2] = {};
  state.transporter_config[2].x_min_limit = toSigned(r[224]);
  state.transporter_config[2].x_max_limit = toSigned(r[225]);
  state.transporter_config[2].y_min_limit = toSigned(r[226]);
  state.transporter_config[2].y_max_limit = toSigned(r[227]);
  state.transporter_config[2].x_avoid_mm = toSigned(r[228]);
  state.transporter_config[2].y_avoid_mm = toSigned(r[229]);
  state.transporter_config[2].phys_x_accel = toSigned(r[230]) * 0.01;
  state.transporter_config[2].phys_x_decel = toSigned(r[231]) * 0.01;
  state.transporter_config[2].phys_x_max = toSigned(r[232]);
  state.transporter_config[2].phys_z_total = toSigned(r[233]);
  state.transporter_config[2].phys_z_sdry = toSigned(r[234]);
  state.transporter_config[2].phys_z_swet = toSigned(r[235]);
  state.transporter_config[2].phys_z_send = toSigned(r[236]);
  state.transporter_config[2].phys_z_slow = toSigned(r[237]);
  state.transporter_config[2].phys_z_fast = toSigned(r[238]);
  state.transporter_config[2].phys_drip = toSigned(r[239]) * 0.1;
  state.transporter_config[2].phys_avoid = toSigned(r[240]);
  state.transporter_config[2].ta1_min_lift = toSigned(r[241]);
  state.transporter_config[2].ta1_max_lift = toSigned(r[242]);
  state.transporter_config[2].ta1_min_sink = toSigned(r[243]);
  state.transporter_config[2].ta1_max_sink = toSigned(r[244]);
  state.transporter_config[2].ta2_min_lift = toSigned(r[245]);
  state.transporter_config[2].ta2_max_lift = toSigned(r[246]);
  state.transporter_config[2].ta2_min_sink = toSigned(r[247]);
  state.transporter_config[2].ta2_max_sink = toSigned(r[248]);
  state.transporter_config[2].ta3_min_lift = toSigned(r[249]);
  state.transporter_config[2].ta3_max_lift = toSigned(r[250]);
  state.transporter_config[2].ta3_min_sink = toSigned(r[251]);
  state.transporter_config[2].ta3_max_sink = toSigned(r[252]);
  state.transporter_config[3] = {};
  state.transporter_config[3].x_min_limit = toSigned(r[253]);
  state.transporter_config[3].x_max_limit = toSigned(r[254]);
  state.transporter_config[3].y_min_limit = toSigned(r[255]);
  state.transporter_config[3].y_max_limit = toSigned(r[256]);
  state.transporter_config[3].x_avoid_mm = toSigned(r[257]);
  state.transporter_config[3].y_avoid_mm = toSigned(r[258]);
  state.transporter_config[3].phys_x_accel = toSigned(r[259]) * 0.01;
  state.transporter_config[3].phys_x_decel = toSigned(r[260]) * 0.01;
  state.transporter_config[3].phys_x_max = toSigned(r[261]);
  state.transporter_config[3].phys_z_total = toSigned(r[262]);
  state.transporter_config[3].phys_z_sdry = toSigned(r[263]);
  state.transporter_config[3].phys_z_swet = toSigned(r[264]);
  state.transporter_config[3].phys_z_send = toSigned(r[265]);
  state.transporter_config[3].phys_z_slow = toSigned(r[266]);
  state.transporter_config[3].phys_z_fast = toSigned(r[267]);
  state.transporter_config[3].phys_drip = toSigned(r[268]) * 0.1;
  state.transporter_config[3].phys_avoid = toSigned(r[269]);
  state.transporter_config[3].ta1_min_lift = toSigned(r[270]);
  state.transporter_config[3].ta1_max_lift = toSigned(r[271]);
  state.transporter_config[3].ta1_min_sink = toSigned(r[272]);
  state.transporter_config[3].ta1_max_sink = toSigned(r[273]);
  state.transporter_config[3].ta2_min_lift = toSigned(r[274]);
  state.transporter_config[3].ta2_max_lift = toSigned(r[275]);
  state.transporter_config[3].ta2_min_sink = toSigned(r[276]);
  state.transporter_config[3].ta2_max_sink = toSigned(r[277]);
  state.transporter_config[3].ta3_min_lift = toSigned(r[278]);
  state.transporter_config[3].ta3_max_lift = toSigned(r[279]);
  state.transporter_config[3].ta3_min_sink = toSigned(r[280]);
  state.transporter_config[3].ta3_max_sink = toSigned(r[281]);
  state.avoid_status[101] = {};
  state.avoid_status[101].avoid_val = toSigned(r[282]);
  state.avoid_status[102] = {};
  state.avoid_status[102].avoid_val = toSigned(r[283]);
  state.avoid_status[103] = {};
  state.avoid_status[103].avoid_val = toSigned(r[284]);
  state.avoid_status[104] = {};
  state.avoid_status[104].avoid_val = toSigned(r[285]);
  state.avoid_status[105] = {};
  state.avoid_status[105].avoid_val = toSigned(r[286]);
  state.avoid_status[106] = {};
  state.avoid_status[106].avoid_val = toSigned(r[287]);
  state.avoid_status[107] = {};
  state.avoid_status[107].avoid_val = toSigned(r[288]);
  state.avoid_status[108] = {};
  state.avoid_status[108].avoid_val = toSigned(r[289]);
  state.avoid_status[109] = {};
  state.avoid_status[109].avoid_val = toSigned(r[290]);
  state.avoid_status[110] = {};
  state.avoid_status[110].avoid_val = toSigned(r[291]);
  state.avoid_status[111] = {};
  state.avoid_status[111].avoid_val = toSigned(r[292]);
  state.avoid_status[112] = {};
  state.avoid_status[112].avoid_val = toSigned(r[293]);
  state.avoid_status[113] = {};
  state.avoid_status[113].avoid_val = toSigned(r[294]);
  state.avoid_status[114] = {};
  state.avoid_status[114].avoid_val = toSigned(r[295]);
  state.avoid_status[115] = {};
  state.avoid_status[115].avoid_val = toSigned(r[296]);
  state.avoid_status[116] = {};
  state.avoid_status[116].avoid_val = toSigned(r[297]);
  state.avoid_status[117] = {};
  state.avoid_status[117].avoid_val = toSigned(r[298]);
  state.avoid_status[118] = {};
  state.avoid_status[118].avoid_val = toSigned(r[299]);
  state.avoid_status[119] = {};
  state.avoid_status[119].avoid_val = toSigned(r[300]);
  state.avoid_status[120] = {};
  state.avoid_status[120].avoid_val = toSigned(r[301]);
  state.avoid_status[121] = {};
  state.avoid_status[121].avoid_val = toSigned(r[302]);
  state.avoid_status[122] = {};
  state.avoid_status[122].avoid_val = toSigned(r[303]);
  state.avoid_status[123] = {};
  state.avoid_status[123].avoid_val = toSigned(r[304]);
  state.avoid_status[124] = {};
  state.avoid_status[124].avoid_val = toSigned(r[305]);
  state.avoid_status[125] = {};
  state.avoid_status[125].avoid_val = toSigned(r[306]);
  state.avoid_status[126] = {};
  state.avoid_status[126].avoid_val = toSigned(r[307]);
  state.avoid_status[127] = {};
  state.avoid_status[127].avoid_val = toSigned(r[308]);
  state.avoid_status[128] = {};
  state.avoid_status[128].avoid_val = toSigned(r[309]);
  state.avoid_status[129] = {};
  state.avoid_status[129].avoid_val = toSigned(r[310]);
  state.avoid_status[130] = {};
  state.avoid_status[130].avoid_val = toSigned(r[311]);
  // --- schedule_summary ---
  if (!state.schedule_summary) state.schedule_summary = {};
  state.schedule_summary[1] = {};
  state.schedule_summary[1].stage_count = toSigned(r[312]);
  state.schedule_summary[2] = {};
  state.schedule_summary[2].stage_count = toSigned(r[313]);
  state.schedule_summary[3] = {};
  state.schedule_summary[3].stage_count = toSigned(r[314]);
  state.schedule_summary[4] = {};
  state.schedule_summary[4].stage_count = toSigned(r[315]);
  state.schedule_summary[5] = {};
  state.schedule_summary[5].stage_count = toSigned(r[316]);
  state.schedule_summary[6] = {};
  state.schedule_summary[6].stage_count = toSigned(r[317]);
  state.schedule_summary[7] = {};
  state.schedule_summary[7].stage_count = toSigned(r[318]);
  state.schedule_summary[8] = {};
  state.schedule_summary[8].stage_count = toSigned(r[319]);
  state.schedule_summary[9] = {};
  state.schedule_summary[9].stage_count = toSigned(r[320]);
  state.schedule_summary[10] = {};
  state.schedule_summary[10].stage_count = toSigned(r[321]);
  // --- task_queue ---
  if (!state.task_queue) state.task_queue = {};
  state.task_queue[1] = {};
  state.task_queue[1].task_count = toSigned(r[322]);
  state.task_queue[1].q1_unit = toSigned(r[323]);
  state.task_queue[1].q1_stage = toSigned(r[324]);
  state.task_queue[1].q1_lift = toSigned(r[325]);
  state.task_queue[1].q1_sink = toSigned(r[326]);
  state.task_queue[1]._q1_start_hi = r[327];
  state.task_queue[1]._q1_start_lo = r[328];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[1].q1_start_time = ((state.task_queue[1]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_start_lo & 0xFFFF);
  state.task_queue[1]._q1_fin_hi = r[329];
  state.task_queue[1]._q1_fin_lo = r[330];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[1].q1_finish_time = ((state.task_queue[1]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q1_fin_lo & 0xFFFF);
  state.task_queue[1].q1_calc_time = toSigned(r[331]) * 0.1;
  state.task_queue[1].q1_min_time = toSigned(r[332]) * 0.1;
  state.task_queue[1].q1_max_time = toSigned(r[333]) * 0.1;
  state.task_queue[1].q2_unit = toSigned(r[334]);
  state.task_queue[1].q2_stage = toSigned(r[335]);
  state.task_queue[1].q2_lift = toSigned(r[336]);
  state.task_queue[1].q2_sink = toSigned(r[337]);
  state.task_queue[1]._q2_start_hi = r[338];
  state.task_queue[1]._q2_start_lo = r[339];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[1].q2_start_time = ((state.task_queue[1]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_start_lo & 0xFFFF);
  state.task_queue[1]._q2_fin_hi = r[340];
  state.task_queue[1]._q2_fin_lo = r[341];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[1].q2_finish_time = ((state.task_queue[1]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q2_fin_lo & 0xFFFF);
  state.task_queue[1].q2_calc_time = toSigned(r[342]) * 0.1;
  state.task_queue[1].q2_min_time = toSigned(r[343]) * 0.1;
  state.task_queue[1].q2_max_time = toSigned(r[344]) * 0.1;
  state.task_queue[1].q3_unit = toSigned(r[345]);
  state.task_queue[1].q3_stage = toSigned(r[346]);
  state.task_queue[1].q3_lift = toSigned(r[347]);
  state.task_queue[1].q3_sink = toSigned(r[348]);
  state.task_queue[1]._q3_start_hi = r[349];
  state.task_queue[1]._q3_start_lo = r[350];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[1].q3_start_time = ((state.task_queue[1]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_start_lo & 0xFFFF);
  state.task_queue[1]._q3_fin_hi = r[351];
  state.task_queue[1]._q3_fin_lo = r[352];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[1].q3_finish_time = ((state.task_queue[1]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q3_fin_lo & 0xFFFF);
  state.task_queue[1].q3_calc_time = toSigned(r[353]) * 0.1;
  state.task_queue[1].q3_min_time = toSigned(r[354]) * 0.1;
  state.task_queue[1].q3_max_time = toSigned(r[355]) * 0.1;
  state.task_queue[1].q4_unit = toSigned(r[356]);
  state.task_queue[1].q4_stage = toSigned(r[357]);
  state.task_queue[1].q4_lift = toSigned(r[358]);
  state.task_queue[1].q4_sink = toSigned(r[359]);
  state.task_queue[1]._q4_start_hi = r[360];
  state.task_queue[1]._q4_start_lo = r[361];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[1].q4_start_time = ((state.task_queue[1]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_start_lo & 0xFFFF);
  state.task_queue[1]._q4_fin_hi = r[362];
  state.task_queue[1]._q4_fin_lo = r[363];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[1].q4_finish_time = ((state.task_queue[1]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q4_fin_lo & 0xFFFF);
  state.task_queue[1].q4_calc_time = toSigned(r[364]) * 0.1;
  state.task_queue[1].q4_min_time = toSigned(r[365]) * 0.1;
  state.task_queue[1].q4_max_time = toSigned(r[366]) * 0.1;
  state.task_queue[1].q5_unit = toSigned(r[367]);
  state.task_queue[1].q5_stage = toSigned(r[368]);
  state.task_queue[1].q5_lift = toSigned(r[369]);
  state.task_queue[1].q5_sink = toSigned(r[370]);
  state.task_queue[1]._q5_start_hi = r[371];
  state.task_queue[1]._q5_start_lo = r[372];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[1].q5_start_time = ((state.task_queue[1]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_start_lo & 0xFFFF);
  state.task_queue[1]._q5_fin_hi = r[373];
  state.task_queue[1]._q5_fin_lo = r[374];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[1].q5_finish_time = ((state.task_queue[1]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q5_fin_lo & 0xFFFF);
  state.task_queue[1].q5_calc_time = toSigned(r[375]) * 0.1;
  state.task_queue[1].q5_min_time = toSigned(r[376]) * 0.1;
  state.task_queue[1].q5_max_time = toSigned(r[377]) * 0.1;
  state.task_queue[1].q6_unit = toSigned(r[378]);
  state.task_queue[1].q6_stage = toSigned(r[379]);
  state.task_queue[1].q6_lift = toSigned(r[380]);
  state.task_queue[1].q6_sink = toSigned(r[381]);
  state.task_queue[1]._q6_start_hi = r[382];
  state.task_queue[1]._q6_start_lo = r[383];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[1].q6_start_time = ((state.task_queue[1]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_start_lo & 0xFFFF);
  state.task_queue[1]._q6_fin_hi = r[384];
  state.task_queue[1]._q6_fin_lo = r[385];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[1].q6_finish_time = ((state.task_queue[1]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q6_fin_lo & 0xFFFF);
  state.task_queue[1].q6_calc_time = toSigned(r[386]) * 0.1;
  state.task_queue[1].q6_min_time = toSigned(r[387]) * 0.1;
  state.task_queue[1].q6_max_time = toSigned(r[388]) * 0.1;
  state.task_queue[1].q7_unit = toSigned(r[389]);
  state.task_queue[1].q7_stage = toSigned(r[390]);
  state.task_queue[1].q7_lift = toSigned(r[391]);
  state.task_queue[1].q7_sink = toSigned(r[392]);
  state.task_queue[1]._q7_start_hi = r[393];
  state.task_queue[1]._q7_start_lo = r[394];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[1].q7_start_time = ((state.task_queue[1]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_start_lo & 0xFFFF);
  state.task_queue[1]._q7_fin_hi = r[395];
  state.task_queue[1]._q7_fin_lo = r[396];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[1].q7_finish_time = ((state.task_queue[1]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q7_fin_lo & 0xFFFF);
  state.task_queue[1].q7_calc_time = toSigned(r[397]) * 0.1;
  state.task_queue[1].q7_min_time = toSigned(r[398]) * 0.1;
  state.task_queue[1].q7_max_time = toSigned(r[399]) * 0.1;
  state.task_queue[1].q8_unit = toSigned(r[400]);
  state.task_queue[1].q8_stage = toSigned(r[401]);
  state.task_queue[1].q8_lift = toSigned(r[402]);
  state.task_queue[1].q8_sink = toSigned(r[403]);
  state.task_queue[1]._q8_start_hi = r[404];
  state.task_queue[1]._q8_start_lo = r[405];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[1].q8_start_time = ((state.task_queue[1]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_start_lo & 0xFFFF);
  state.task_queue[1]._q8_fin_hi = r[406];
  state.task_queue[1]._q8_fin_lo = r[407];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[1].q8_finish_time = ((state.task_queue[1]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q8_fin_lo & 0xFFFF);
  state.task_queue[1].q8_calc_time = toSigned(r[408]) * 0.1;
  state.task_queue[1].q8_min_time = toSigned(r[409]) * 0.1;
  state.task_queue[1].q8_max_time = toSigned(r[410]) * 0.1;
  state.task_queue[1].q9_unit = toSigned(r[411]);
  state.task_queue[1].q9_stage = toSigned(r[412]);
  state.task_queue[1].q9_lift = toSigned(r[413]);
  state.task_queue[1].q9_sink = toSigned(r[414]);
  state.task_queue[1]._q9_start_hi = r[415];
  state.task_queue[1]._q9_start_lo = r[416];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[1].q9_start_time = ((state.task_queue[1]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_start_lo & 0xFFFF);
  state.task_queue[1]._q9_fin_hi = r[417];
  state.task_queue[1]._q9_fin_lo = r[418];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[1].q9_finish_time = ((state.task_queue[1]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q9_fin_lo & 0xFFFF);
  state.task_queue[1].q9_calc_time = toSigned(r[419]) * 0.1;
  state.task_queue[1].q9_min_time = toSigned(r[420]) * 0.1;
  state.task_queue[1].q9_max_time = toSigned(r[421]) * 0.1;
  state.task_queue[1].q10_unit = toSigned(r[422]);
  state.task_queue[1].q10_stage = toSigned(r[423]);
  state.task_queue[1].q10_lift = toSigned(r[424]);
  state.task_queue[1].q10_sink = toSigned(r[425]);
  state.task_queue[1]._q10_start_hi = r[426];
  state.task_queue[1]._q10_start_lo = r[427];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[1].q10_start_time = ((state.task_queue[1]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_start_lo & 0xFFFF);
  state.task_queue[1]._q10_fin_hi = r[428];
  state.task_queue[1]._q10_fin_lo = r[429];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[1].q10_finish_time = ((state.task_queue[1]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[1]._q10_fin_lo & 0xFFFF);
  state.task_queue[1].q10_calc_time = toSigned(r[430]) * 0.1;
  state.task_queue[1].q10_min_time = toSigned(r[431]) * 0.1;
  state.task_queue[1].q10_max_time = toSigned(r[432]) * 0.1;
  state.task_queue[2] = {};
  state.task_queue[2].task_count = toSigned(r[433]);
  state.task_queue[2].q1_unit = toSigned(r[434]);
  state.task_queue[2].q1_stage = toSigned(r[435]);
  state.task_queue[2].q1_lift = toSigned(r[436]);
  state.task_queue[2].q1_sink = toSigned(r[437]);
  state.task_queue[2]._q1_start_hi = r[438];
  state.task_queue[2]._q1_start_lo = r[439];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[2].q1_start_time = ((state.task_queue[2]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_start_lo & 0xFFFF);
  state.task_queue[2]._q1_fin_hi = r[440];
  state.task_queue[2]._q1_fin_lo = r[441];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[2].q1_finish_time = ((state.task_queue[2]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q1_fin_lo & 0xFFFF);
  state.task_queue[2].q1_calc_time = toSigned(r[442]) * 0.1;
  state.task_queue[2].q1_min_time = toSigned(r[443]) * 0.1;
  state.task_queue[2].q1_max_time = toSigned(r[444]) * 0.1;
  state.task_queue[2].q2_unit = toSigned(r[445]);
  state.task_queue[2].q2_stage = toSigned(r[446]);
  state.task_queue[2].q2_lift = toSigned(r[447]);
  state.task_queue[2].q2_sink = toSigned(r[448]);
  state.task_queue[2]._q2_start_hi = r[449];
  state.task_queue[2]._q2_start_lo = r[450];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[2].q2_start_time = ((state.task_queue[2]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_start_lo & 0xFFFF);
  state.task_queue[2]._q2_fin_hi = r[451];
  state.task_queue[2]._q2_fin_lo = r[452];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[2].q2_finish_time = ((state.task_queue[2]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q2_fin_lo & 0xFFFF);
  state.task_queue[2].q2_calc_time = toSigned(r[453]) * 0.1;
  state.task_queue[2].q2_min_time = toSigned(r[454]) * 0.1;
  state.task_queue[2].q2_max_time = toSigned(r[455]) * 0.1;
  state.task_queue[2].q3_unit = toSigned(r[456]);
  state.task_queue[2].q3_stage = toSigned(r[457]);
  state.task_queue[2].q3_lift = toSigned(r[458]);
  state.task_queue[2].q3_sink = toSigned(r[459]);
  state.task_queue[2]._q3_start_hi = r[460];
  state.task_queue[2]._q3_start_lo = r[461];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[2].q3_start_time = ((state.task_queue[2]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_start_lo & 0xFFFF);
  state.task_queue[2]._q3_fin_hi = r[462];
  state.task_queue[2]._q3_fin_lo = r[463];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[2].q3_finish_time = ((state.task_queue[2]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q3_fin_lo & 0xFFFF);
  state.task_queue[2].q3_calc_time = toSigned(r[464]) * 0.1;
  state.task_queue[2].q3_min_time = toSigned(r[465]) * 0.1;
  state.task_queue[2].q3_max_time = toSigned(r[466]) * 0.1;
  state.task_queue[2].q4_unit = toSigned(r[467]);
  state.task_queue[2].q4_stage = toSigned(r[468]);
  state.task_queue[2].q4_lift = toSigned(r[469]);
  state.task_queue[2].q4_sink = toSigned(r[470]);
  state.task_queue[2]._q4_start_hi = r[471];
  state.task_queue[2]._q4_start_lo = r[472];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[2].q4_start_time = ((state.task_queue[2]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_start_lo & 0xFFFF);
  state.task_queue[2]._q4_fin_hi = r[473];
  state.task_queue[2]._q4_fin_lo = r[474];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[2].q4_finish_time = ((state.task_queue[2]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q4_fin_lo & 0xFFFF);
  state.task_queue[2].q4_calc_time = toSigned(r[475]) * 0.1;
  state.task_queue[2].q4_min_time = toSigned(r[476]) * 0.1;
  state.task_queue[2].q4_max_time = toSigned(r[477]) * 0.1;
  state.task_queue[2].q5_unit = toSigned(r[478]);
  state.task_queue[2].q5_stage = toSigned(r[479]);
  state.task_queue[2].q5_lift = toSigned(r[480]);
  state.task_queue[2].q5_sink = toSigned(r[481]);
  state.task_queue[2]._q5_start_hi = r[482];
  state.task_queue[2]._q5_start_lo = r[483];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[2].q5_start_time = ((state.task_queue[2]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_start_lo & 0xFFFF);
  state.task_queue[2]._q5_fin_hi = r[484];
  state.task_queue[2]._q5_fin_lo = r[485];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[2].q5_finish_time = ((state.task_queue[2]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q5_fin_lo & 0xFFFF);
  state.task_queue[2].q5_calc_time = toSigned(r[486]) * 0.1;
  state.task_queue[2].q5_min_time = toSigned(r[487]) * 0.1;
  state.task_queue[2].q5_max_time = toSigned(r[488]) * 0.1;
  state.task_queue[2].q6_unit = toSigned(r[489]);
  state.task_queue[2].q6_stage = toSigned(r[490]);
  state.task_queue[2].q6_lift = toSigned(r[491]);
  state.task_queue[2].q6_sink = toSigned(r[492]);
  state.task_queue[2]._q6_start_hi = r[493];
  state.task_queue[2]._q6_start_lo = r[494];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[2].q6_start_time = ((state.task_queue[2]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_start_lo & 0xFFFF);
  state.task_queue[2]._q6_fin_hi = r[495];
  state.task_queue[2]._q6_fin_lo = r[496];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[2].q6_finish_time = ((state.task_queue[2]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q6_fin_lo & 0xFFFF);
  state.task_queue[2].q6_calc_time = toSigned(r[497]) * 0.1;
  state.task_queue[2].q6_min_time = toSigned(r[498]) * 0.1;
  state.task_queue[2].q6_max_time = toSigned(r[499]) * 0.1;
  state.task_queue[2].q7_unit = toSigned(r[500]);
  state.task_queue[2].q7_stage = toSigned(r[501]);
  state.task_queue[2].q7_lift = toSigned(r[502]);
  state.task_queue[2].q7_sink = toSigned(r[503]);
  state.task_queue[2]._q7_start_hi = r[504];
  state.task_queue[2]._q7_start_lo = r[505];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[2].q7_start_time = ((state.task_queue[2]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_start_lo & 0xFFFF);
  state.task_queue[2]._q7_fin_hi = r[506];
  state.task_queue[2]._q7_fin_lo = r[507];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[2].q7_finish_time = ((state.task_queue[2]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q7_fin_lo & 0xFFFF);
  state.task_queue[2].q7_calc_time = toSigned(r[508]) * 0.1;
  state.task_queue[2].q7_min_time = toSigned(r[509]) * 0.1;
  state.task_queue[2].q7_max_time = toSigned(r[510]) * 0.1;
  state.task_queue[2].q8_unit = toSigned(r[511]);
  state.task_queue[2].q8_stage = toSigned(r[512]);
  state.task_queue[2].q8_lift = toSigned(r[513]);
  state.task_queue[2].q8_sink = toSigned(r[514]);
  state.task_queue[2]._q8_start_hi = r[515];
  state.task_queue[2]._q8_start_lo = r[516];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[2].q8_start_time = ((state.task_queue[2]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_start_lo & 0xFFFF);
  state.task_queue[2]._q8_fin_hi = r[517];
  state.task_queue[2]._q8_fin_lo = r[518];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[2].q8_finish_time = ((state.task_queue[2]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q8_fin_lo & 0xFFFF);
  state.task_queue[2].q8_calc_time = toSigned(r[519]) * 0.1;
  state.task_queue[2].q8_min_time = toSigned(r[520]) * 0.1;
  state.task_queue[2].q8_max_time = toSigned(r[521]) * 0.1;
  state.task_queue[2].q9_unit = toSigned(r[522]);
  state.task_queue[2].q9_stage = toSigned(r[523]);
  state.task_queue[2].q9_lift = toSigned(r[524]);
  state.task_queue[2].q9_sink = toSigned(r[525]);
  state.task_queue[2]._q9_start_hi = r[526];
  state.task_queue[2]._q9_start_lo = r[527];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[2].q9_start_time = ((state.task_queue[2]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_start_lo & 0xFFFF);
  state.task_queue[2]._q9_fin_hi = r[528];
  state.task_queue[2]._q9_fin_lo = r[529];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[2].q9_finish_time = ((state.task_queue[2]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q9_fin_lo & 0xFFFF);
  state.task_queue[2].q9_calc_time = toSigned(r[530]) * 0.1;
  state.task_queue[2].q9_min_time = toSigned(r[531]) * 0.1;
  state.task_queue[2].q9_max_time = toSigned(r[532]) * 0.1;
  state.task_queue[2].q10_unit = toSigned(r[533]);
  state.task_queue[2].q10_stage = toSigned(r[534]);
  state.task_queue[2].q10_lift = toSigned(r[535]);
  state.task_queue[2].q10_sink = toSigned(r[536]);
  state.task_queue[2]._q10_start_hi = r[537];
  state.task_queue[2]._q10_start_lo = r[538];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[2].q10_start_time = ((state.task_queue[2]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_start_lo & 0xFFFF);
  state.task_queue[2]._q10_fin_hi = r[539];
  state.task_queue[2]._q10_fin_lo = r[540];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[2].q10_finish_time = ((state.task_queue[2]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[2]._q10_fin_lo & 0xFFFF);
  state.task_queue[2].q10_calc_time = toSigned(r[541]) * 0.1;
  state.task_queue[2].q10_min_time = toSigned(r[542]) * 0.1;
  state.task_queue[2].q10_max_time = toSigned(r[543]) * 0.1;
  state.task_queue[3] = {};
  state.task_queue[3].task_count = toSigned(r[544]);
  state.task_queue[3].q1_unit = toSigned(r[545]);
  state.task_queue[3].q1_stage = toSigned(r[546]);
  state.task_queue[3].q1_lift = toSigned(r[547]);
  state.task_queue[3].q1_sink = toSigned(r[548]);
  state.task_queue[3]._q1_start_hi = r[549];
  state.task_queue[3]._q1_start_lo = r[550];
  // Combined uint32: q1_start_time = (hi << 16) | lo
  state.task_queue[3].q1_start_time = ((state.task_queue[3]._q1_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_start_lo & 0xFFFF);
  state.task_queue[3]._q1_fin_hi = r[551];
  state.task_queue[3]._q1_fin_lo = r[552];
  // Combined uint32: q1_finish_time = (hi << 16) | lo
  state.task_queue[3].q1_finish_time = ((state.task_queue[3]._q1_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q1_fin_lo & 0xFFFF);
  state.task_queue[3].q1_calc_time = toSigned(r[553]) * 0.1;
  state.task_queue[3].q1_min_time = toSigned(r[554]) * 0.1;
  state.task_queue[3].q1_max_time = toSigned(r[555]) * 0.1;
  state.task_queue[3].q2_unit = toSigned(r[556]);
  state.task_queue[3].q2_stage = toSigned(r[557]);
  state.task_queue[3].q2_lift = toSigned(r[558]);
  state.task_queue[3].q2_sink = toSigned(r[559]);
  state.task_queue[3]._q2_start_hi = r[560];
  state.task_queue[3]._q2_start_lo = r[561];
  // Combined uint32: q2_start_time = (hi << 16) | lo
  state.task_queue[3].q2_start_time = ((state.task_queue[3]._q2_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_start_lo & 0xFFFF);
  state.task_queue[3]._q2_fin_hi = r[562];
  state.task_queue[3]._q2_fin_lo = r[563];
  // Combined uint32: q2_finish_time = (hi << 16) | lo
  state.task_queue[3].q2_finish_time = ((state.task_queue[3]._q2_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q2_fin_lo & 0xFFFF);
  state.task_queue[3].q2_calc_time = toSigned(r[564]) * 0.1;
  state.task_queue[3].q2_min_time = toSigned(r[565]) * 0.1;
  state.task_queue[3].q2_max_time = toSigned(r[566]) * 0.1;
  state.task_queue[3].q3_unit = toSigned(r[567]);
  state.task_queue[3].q3_stage = toSigned(r[568]);
  state.task_queue[3].q3_lift = toSigned(r[569]);
  state.task_queue[3].q3_sink = toSigned(r[570]);
  state.task_queue[3]._q3_start_hi = r[571];
  state.task_queue[3]._q3_start_lo = r[572];
  // Combined uint32: q3_start_time = (hi << 16) | lo
  state.task_queue[3].q3_start_time = ((state.task_queue[3]._q3_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_start_lo & 0xFFFF);
  state.task_queue[3]._q3_fin_hi = r[573];
  state.task_queue[3]._q3_fin_lo = r[574];
  // Combined uint32: q3_finish_time = (hi << 16) | lo
  state.task_queue[3].q3_finish_time = ((state.task_queue[3]._q3_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q3_fin_lo & 0xFFFF);
  state.task_queue[3].q3_calc_time = toSigned(r[575]) * 0.1;
  state.task_queue[3].q3_min_time = toSigned(r[576]) * 0.1;
  state.task_queue[3].q3_max_time = toSigned(r[577]) * 0.1;
  state.task_queue[3].q4_unit = toSigned(r[578]);
  state.task_queue[3].q4_stage = toSigned(r[579]);
  state.task_queue[3].q4_lift = toSigned(r[580]);
  state.task_queue[3].q4_sink = toSigned(r[581]);
  state.task_queue[3]._q4_start_hi = r[582];
  state.task_queue[3]._q4_start_lo = r[583];
  // Combined uint32: q4_start_time = (hi << 16) | lo
  state.task_queue[3].q4_start_time = ((state.task_queue[3]._q4_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_start_lo & 0xFFFF);
  state.task_queue[3]._q4_fin_hi = r[584];
  state.task_queue[3]._q4_fin_lo = r[585];
  // Combined uint32: q4_finish_time = (hi << 16) | lo
  state.task_queue[3].q4_finish_time = ((state.task_queue[3]._q4_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q4_fin_lo & 0xFFFF);
  state.task_queue[3].q4_calc_time = toSigned(r[586]) * 0.1;
  state.task_queue[3].q4_min_time = toSigned(r[587]) * 0.1;
  state.task_queue[3].q4_max_time = toSigned(r[588]) * 0.1;
  state.task_queue[3].q5_unit = toSigned(r[589]);
  state.task_queue[3].q5_stage = toSigned(r[590]);
  state.task_queue[3].q5_lift = toSigned(r[591]);
  state.task_queue[3].q5_sink = toSigned(r[592]);
  state.task_queue[3]._q5_start_hi = r[593];
  state.task_queue[3]._q5_start_lo = r[594];
  // Combined uint32: q5_start_time = (hi << 16) | lo
  state.task_queue[3].q5_start_time = ((state.task_queue[3]._q5_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_start_lo & 0xFFFF);
  state.task_queue[3]._q5_fin_hi = r[595];
  state.task_queue[3]._q5_fin_lo = r[596];
  // Combined uint32: q5_finish_time = (hi << 16) | lo
  state.task_queue[3].q5_finish_time = ((state.task_queue[3]._q5_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q5_fin_lo & 0xFFFF);
  state.task_queue[3].q5_calc_time = toSigned(r[597]) * 0.1;
  state.task_queue[3].q5_min_time = toSigned(r[598]) * 0.1;
  state.task_queue[3].q5_max_time = toSigned(r[599]) * 0.1;
  state.task_queue[3].q6_unit = toSigned(r[600]);
  state.task_queue[3].q6_stage = toSigned(r[601]);
  state.task_queue[3].q6_lift = toSigned(r[602]);
  state.task_queue[3].q6_sink = toSigned(r[603]);
  state.task_queue[3]._q6_start_hi = r[604];
  state.task_queue[3]._q6_start_lo = r[605];
  // Combined uint32: q6_start_time = (hi << 16) | lo
  state.task_queue[3].q6_start_time = ((state.task_queue[3]._q6_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_start_lo & 0xFFFF);
  state.task_queue[3]._q6_fin_hi = r[606];
  state.task_queue[3]._q6_fin_lo = r[607];
  // Combined uint32: q6_finish_time = (hi << 16) | lo
  state.task_queue[3].q6_finish_time = ((state.task_queue[3]._q6_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q6_fin_lo & 0xFFFF);
  state.task_queue[3].q6_calc_time = toSigned(r[608]) * 0.1;
  state.task_queue[3].q6_min_time = toSigned(r[609]) * 0.1;
  state.task_queue[3].q6_max_time = toSigned(r[610]) * 0.1;
  state.task_queue[3].q7_unit = toSigned(r[611]);
  state.task_queue[3].q7_stage = toSigned(r[612]);
  state.task_queue[3].q7_lift = toSigned(r[613]);
  state.task_queue[3].q7_sink = toSigned(r[614]);
  state.task_queue[3]._q7_start_hi = r[615];
  state.task_queue[3]._q7_start_lo = r[616];
  // Combined uint32: q7_start_time = (hi << 16) | lo
  state.task_queue[3].q7_start_time = ((state.task_queue[3]._q7_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_start_lo & 0xFFFF);
  state.task_queue[3]._q7_fin_hi = r[617];
  state.task_queue[3]._q7_fin_lo = r[618];
  // Combined uint32: q7_finish_time = (hi << 16) | lo
  state.task_queue[3].q7_finish_time = ((state.task_queue[3]._q7_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q7_fin_lo & 0xFFFF);
  state.task_queue[3].q7_calc_time = toSigned(r[619]) * 0.1;
  state.task_queue[3].q7_min_time = toSigned(r[620]) * 0.1;
  state.task_queue[3].q7_max_time = toSigned(r[621]) * 0.1;
  state.task_queue[3].q8_unit = toSigned(r[622]);
  state.task_queue[3].q8_stage = toSigned(r[623]);
  state.task_queue[3].q8_lift = toSigned(r[624]);
  state.task_queue[3].q8_sink = toSigned(r[625]);
  state.task_queue[3]._q8_start_hi = r[626];
  state.task_queue[3]._q8_start_lo = r[627];
  // Combined uint32: q8_start_time = (hi << 16) | lo
  state.task_queue[3].q8_start_time = ((state.task_queue[3]._q8_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_start_lo & 0xFFFF);
  state.task_queue[3]._q8_fin_hi = r[628];
  state.task_queue[3]._q8_fin_lo = r[629];
  // Combined uint32: q8_finish_time = (hi << 16) | lo
  state.task_queue[3].q8_finish_time = ((state.task_queue[3]._q8_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q8_fin_lo & 0xFFFF);
  state.task_queue[3].q8_calc_time = toSigned(r[630]) * 0.1;
  state.task_queue[3].q8_min_time = toSigned(r[631]) * 0.1;
  state.task_queue[3].q8_max_time = toSigned(r[632]) * 0.1;
  state.task_queue[3].q9_unit = toSigned(r[633]);
  state.task_queue[3].q9_stage = toSigned(r[634]);
  state.task_queue[3].q9_lift = toSigned(r[635]);
  state.task_queue[3].q9_sink = toSigned(r[636]);
  state.task_queue[3]._q9_start_hi = r[637];
  state.task_queue[3]._q9_start_lo = r[638];
  // Combined uint32: q9_start_time = (hi << 16) | lo
  state.task_queue[3].q9_start_time = ((state.task_queue[3]._q9_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_start_lo & 0xFFFF);
  state.task_queue[3]._q9_fin_hi = r[639];
  state.task_queue[3]._q9_fin_lo = r[640];
  // Combined uint32: q9_finish_time = (hi << 16) | lo
  state.task_queue[3].q9_finish_time = ((state.task_queue[3]._q9_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q9_fin_lo & 0xFFFF);
  state.task_queue[3].q9_calc_time = toSigned(r[641]) * 0.1;
  state.task_queue[3].q9_min_time = toSigned(r[642]) * 0.1;
  state.task_queue[3].q9_max_time = toSigned(r[643]) * 0.1;
  state.task_queue[3].q10_unit = toSigned(r[644]);
  state.task_queue[3].q10_stage = toSigned(r[645]);
  state.task_queue[3].q10_lift = toSigned(r[646]);
  state.task_queue[3].q10_sink = toSigned(r[647]);
  state.task_queue[3]._q10_start_hi = r[648];
  state.task_queue[3]._q10_start_lo = r[649];
  // Combined uint32: q10_start_time = (hi << 16) | lo
  state.task_queue[3].q10_start_time = ((state.task_queue[3]._q10_start_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_start_lo & 0xFFFF);
  state.task_queue[3]._q10_fin_hi = r[650];
  state.task_queue[3]._q10_fin_lo = r[651];
  // Combined uint32: q10_finish_time = (hi << 16) | lo
  state.task_queue[3].q10_finish_time = ((state.task_queue[3]._q10_fin_hi & 0xFFFF) * 65536) + (state.task_queue[3]._q10_fin_lo & 0xFFFF);
  state.task_queue[3].q10_calc_time = toSigned(r[652]) * 0.1;
  state.task_queue[3].q10_min_time = toSigned(r[653]) * 0.1;
  state.task_queue[3].q10_max_time = toSigned(r[654]) * 0.1;
  // --- dep_state ---
  state.dep_state = {};
  state.dep_state.dep_activated = toSigned(r[655]);
  state.dep_state.dep_stable = toSigned(r[656]);
  state.dep_state.dep_waiting_count = toSigned(r[657]);
  state.dep_state.dep_overlap_count = toSigned(r[658]);
  state.dep_state.dep_pending_valid = toSigned(r[659]);
  state.dep_state.dep_pending_unit = toSigned(r[660]);
  state.dep_state.dep_pending_stage = toSigned(r[661]);
  state.dep_state._dep_pend_time_hi = r[662];
  state.dep_state._dep_pend_time_lo = r[663];
  // Combined uint32: dep_pending_time = (hi << 16) | lo
  state.dep_state.dep_pending_time = ((state.dep_state._pend_time_hi & 0xFFFF) * 65536) + (state.dep_state._pend_time_lo & 0xFFFF);
  // --- dep_waiting ---
  if (!state.dep_waiting) state.dep_waiting = {};
  state.dep_waiting[1] = {};
  state.dep_waiting[1].waiting_unit = toSigned(r[664]);
  state.dep_waiting[2] = {};
  state.dep_waiting[2].waiting_unit = toSigned(r[665]);
  state.dep_waiting[3] = {};
  state.dep_waiting[3].waiting_unit = toSigned(r[666]);
  state.dep_waiting[4] = {};
  state.dep_waiting[4].waiting_unit = toSigned(r[667]);
  state.dep_waiting[5] = {};
  state.dep_waiting[5].waiting_unit = toSigned(r[668]);
  state.dep_overlap[101] = {};
  state.dep_overlap[101].overlap_flag = toSigned(r[669]);
  state.dep_overlap[102] = {};
  state.dep_overlap[102].overlap_flag = toSigned(r[670]);
  state.dep_overlap[103] = {};
  state.dep_overlap[103].overlap_flag = toSigned(r[671]);
  state.dep_overlap[104] = {};
  state.dep_overlap[104].overlap_flag = toSigned(r[672]);
  state.dep_overlap[105] = {};
  state.dep_overlap[105].overlap_flag = toSigned(r[673]);
  state.dep_overlap[106] = {};
  state.dep_overlap[106].overlap_flag = toSigned(r[674]);
  state.dep_overlap[107] = {};
  state.dep_overlap[107].overlap_flag = toSigned(r[675]);
  state.dep_overlap[108] = {};
  state.dep_overlap[108].overlap_flag = toSigned(r[676]);
  state.dep_overlap[109] = {};
  state.dep_overlap[109].overlap_flag = toSigned(r[677]);
  state.dep_overlap[110] = {};
  state.dep_overlap[110].overlap_flag = toSigned(r[678]);
  state.dep_overlap[111] = {};
  state.dep_overlap[111].overlap_flag = toSigned(r[679]);
  state.dep_overlap[112] = {};
  state.dep_overlap[112].overlap_flag = toSigned(r[680]);
  state.dep_overlap[113] = {};
  state.dep_overlap[113].overlap_flag = toSigned(r[681]);
  state.dep_overlap[114] = {};
  state.dep_overlap[114].overlap_flag = toSigned(r[682]);
  state.dep_overlap[115] = {};
  state.dep_overlap[115].overlap_flag = toSigned(r[683]);
  state.dep_overlap[116] = {};
  state.dep_overlap[116].overlap_flag = toSigned(r[684]);
  state.dep_overlap[117] = {};
  state.dep_overlap[117].overlap_flag = toSigned(r[685]);
  state.dep_overlap[118] = {};
  state.dep_overlap[118].overlap_flag = toSigned(r[686]);
  state.dep_overlap[119] = {};
  state.dep_overlap[119].overlap_flag = toSigned(r[687]);
  state.dep_overlap[120] = {};
  state.dep_overlap[120].overlap_flag = toSigned(r[688]);
  state.dep_overlap[121] = {};
  state.dep_overlap[121].overlap_flag = toSigned(r[689]);
  state.dep_overlap[122] = {};
  state.dep_overlap[122].overlap_flag = toSigned(r[690]);
  state.dep_overlap[123] = {};
  state.dep_overlap[123].overlap_flag = toSigned(r[691]);
  state.dep_overlap[124] = {};
  state.dep_overlap[124].overlap_flag = toSigned(r[692]);
  state.dep_overlap[125] = {};
  state.dep_overlap[125].overlap_flag = toSigned(r[693]);
  state.dep_overlap[126] = {};
  state.dep_overlap[126].overlap_flag = toSigned(r[694]);
  state.dep_overlap[127] = {};
  state.dep_overlap[127].overlap_flag = toSigned(r[695]);
  state.dep_overlap[128] = {};
  state.dep_overlap[128].overlap_flag = toSigned(r[696]);
  state.dep_overlap[129] = {};
  state.dep_overlap[129].overlap_flag = toSigned(r[697]);
  state.dep_overlap[130] = {};
  state.dep_overlap[130].overlap_flag = toSigned(r[698]);

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
    'iw_cmd_t1_start': 699,
    'iw_cmd_t1_lift': 700,
    'iw_cmd_t1_sink': 701,
    'iw_cmd_t2_start': 702,
    'iw_cmd_t2_lift': 703,
    'iw_cmd_t2_sink': 704,
    'iw_cfg_seq': 705,
    'iw_cfg_cmd': 706,
    'iw_cfg_param': 707,
    'iw_cfg_d0': 708,
    'iw_cfg_d1': 709,
    'iw_cfg_d2': 710,
    'iw_cfg_d3': 711,
    'iw_cfg_d4': 712,
    'iw_cfg_d5': 713,
    'iw_cfg_d6': 714,
    'iw_unit_seq': 715,
    'iw_unit_id': 716,
    'iw_unit_loc': 717,
    'iw_unit_status': 718,
    'iw_unit_state': 719,
    'iw_unit_target': 720,
    'iw_batch_seq': 721,
    'iw_batch_unit': 722,
    'iw_batch_code': 723,
    'iw_batch_state': 724,
    'iw_batch_prog_id': 725,
    'iw_prog_seq': 726,
    'iw_prog_unit': 727,
    'iw_prog_stage': 728,
    'iw_prog_s1': 729,
    'iw_prog_s2': 730,
    'iw_prog_s3': 731,
    'iw_prog_s4': 732,
    'iw_prog_s5': 733,
    'iw_prog_min_time': 734,
    'iw_prog_max_time': 735,
    'iw_prog_cal_time': 736,
    'iw_avoid_seq': 737,
    'iw_avoid_station': 738,
    'iw_avoid_value': 739,
    'iw_time_hi': 740,
    'iw_time_lo': 741,
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
  cmd_transport: { start: 699, fields: ["cmd_start", "cmd_lift", "cmd_sink", "cmd_start", "cmd_lift", "cmd_sink"] },
  cfg: { start: 705, fields: ["cfg_seq", "cfg_cmd", "cfg_param", "cfg_d0", "cfg_d1", "cfg_d2", "cfg_d3", "cfg_d4", "cfg_d5", "cfg_d6"] },
  unit: { start: 715, fields: ["unit_seq", "unit_id", "unit_loc", "unit_status", "unit_state", "unit_target"] },
  batch: { start: 721, fields: ["batch_seq", "batch_unit", "batch_code", "batch_state", "batch_prog_id"] },
  prog: { start: 726, fields: ["prog_seq", "prog_unit", "prog_stage", "prog_s1", "prog_s2", "prog_s3", "prog_s4", "prog_s5", "prog_min_time", "prog_max_time", "prog_cal_time"] },
  avoid: { start: 737, fields: ["avoid_seq", "avoid_station", "avoid_value"] },
  time: { start: 740, fields: ["time_hi", "time_lo"] },
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
