#!/usr/bin/env python3
"""Read debug registers directly from PLC via Modbus TCP."""
import sys, time
from pyModbusTCP.client import ModbusClient

PLC_IP = "172.22.0.4"
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
print("sched=schedule_u1 dep_ph=DEP_phase tsk_ph=TSK_phase pend=pending.valid b1_st=batch1.state")
print("-" * 80)

for i in range(iterations):
    # schedule_summary(306-315) - u7-u10 are debug: dep_phase, tsk_phase, pend_valid, batch1_state
    sched = read_regs(306, 10)
    # batch_state block for unit 1: code@126, state@127, prog@128, stage@129
    batch = read_regs(126, 4)
    # dep_state: activated@649, stable@650, waiting_cnt@651, overlap_cnt@652, pend_valid@653, pend_unit@654
    dep = read_regs(649, 9)
    
    if sched and batch and dep:
        s_vals = [to_signed(v) for v in sched]
        b_vals = [to_signed(v) for v in batch]
        d_vals = [to_signed(v) for v in dep]
        print(f"[{i:2d}] sched_u1={s_vals[0]:3d} dep_ph={s_vals[6]:5d} tsk_ph={s_vals[7]:5d} "
              f"pend={s_vals[8]} b1_st_dbg={s_vals[9]} | "
              f"b1=[code={b_vals[0]} state={b_vals[1]} prog={b_vals[2]} stg={b_vals[3]}] | "
              f"dep=[act={d_vals[0]} stab={d_vals[1]} wait={d_vals[2]} ovl={d_vals[3]} pv={d_vals[4]} pu={d_vals[5]}]")
    else:
        print(f"[{i:2d}] READ ERROR")
    
    time.sleep(delay)

c.close()
print("Done.")
