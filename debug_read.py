#!/usr/bin/env python3
"""Read scheduler debug registers directly from PLC via Modbus TCP.

Register map (from modbus_map.json generate_modbus.py output):
  schedule_summary : 356-365  (10 units × stage_count)
  batch_state      : 126-215  (10 units × 9 fields)
  dep_state        : 699-707  (activated, stable, waiting_cnt, overlap_cnt, pend_valid, pend_unit, pend_stage, pend_time_hi, pend_time_lo)
  scheduler_debug  : 743-752  (tsk_phase, dep_phase, turn, skip_cnt, conflict_resolved, dep_reject_cnt, dep_fit_round, dep_cur_wait_unit, dep_wait_cnt, batch_cnt)
"""
import sys, time
from pyModbusTCP.client import ModbusClient

PLC_IP = "172.22.0.2"
PLC_PORT = 502

c = ModbusClient(host=PLC_IP, port=PLC_PORT, auto_open=True, auto_close=False, timeout=2)

def read_regs(start, count):
    result = c.read_holding_registers(start, count)
    if result is None:
        return [None]*count
    return result

def to_signed(v):
    return v - 65536 if v > 32767 else v

iterations = int(sys.argv[1]) if len(sys.argv) > 1 else 30
delay = float(sys.argv[2]) if len(sys.argv) > 2 else 0.3

print(f"Reading {iterations} samples, {delay}s apart")
print("tsk_ph=TSK_phase dep_ph=DEP_phase turn=scheduler_turn confl=conflict_resolved")
print("-" * 100)

for i in range(iterations):
    # scheduler_debug block: 743-752
    sdbg = read_regs(743, 10)
    # batch_state block for unit 1: code@126, state@127, prog@128, stage@129
    batch = read_regs(126, 4)
    # dep_state: 699-707
    dep = read_regs(699, 9)
    
    if sdbg and batch and dep:
        sd = [to_signed(v) for v in sdbg]
        b_vals = [to_signed(v) for v in batch]
        d_vals = [to_signed(v) for v in dep]
        # sd: [0]=tsk_phase [1]=dep_phase [2]=turn [3]=skip_cnt [4]=conflict_resolved
        #     [5]=dep_reject_cnt [6]=dep_fit_round [7]=dep_cur_wait_unit [8]=dep_wait_cnt [9]=batch_cnt
        print(f"[{i:2d}] tsk_ph={sd[0]:5d} dep_ph={sd[1]:5d} turn={sd[2]} skip={sd[3]:3d} "
              f"confl={sd[4]} rej={sd[5]} fit={sd[6]} wait_u={sd[7]} wait_n={sd[8]} bat={sd[9]} | "
              f"b1=[code={b_vals[0]} state={b_vals[1]} prog={b_vals[2]} stg={b_vals[3]}] | "
              f"dep=[act={d_vals[0]} stab={d_vals[1]} wait={d_vals[2]} ovl={d_vals[3]} pv={d_vals[4]} pu={d_vals[5]}]")
    else:
        print(f"[{i:2d}] READ ERROR")
    
    time.sleep(delay)

c.close()
print("Done.")
