#!/usr/bin/env python3
"""
apply_plant_config.py — Patch globals.st and types.st from plant_config.json

Reads plant_config.json (same directory as this script) and rewrites the
constant values in globals.st and the array literal bounds in types.st so
that they are always in sync.

Run BEFORE build_plcxml.py in the deploy pipeline.

Usage:
  python3 apply_plant_config.py              # uses ./plant_config.json
  python3 apply_plant_config.py -c other.json
"""

import argparse
import json
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
SRC_DIR = SCRIPT_DIR / "src"


def load_config(path: Path) -> dict:
    """Load and validate plant_config.json."""
    with open(path) as f:
        cfg = json.load(f)

    required = [
        "MAX_LINES", "MAX_STATIONS_PER_LINE", "MAX_TRANSPORTERS_PER_LINE",
        "MAX_TRANSPORTERS", "MAX_UNITS", "MAX_PARALLELS", "MAX_STAGES",
        "DEP_MAX_IDLE_SLOTS", "DEP_MAX_DELAY_ACTS", "DEP_MAX_WAITING",
    ]
    missing = [k for k in required if k not in cfg]
    if missing:
        print(f"ERROR: plant_config.json missing keys: {missing}", file=sys.stderr)
        sys.exit(1)

    # Derive computed constants
    cfg["STATION_ARRAY_START"] = 101  # always fixed
    cfg["STATION_ARRAY_END"] = cfg["MAX_LINES"] * 100 + cfg["MAX_STATIONS_PER_LINE"]

    return cfg


# ── globals.st patching ──────────────────────────────────────────────

# Map of constant name → config key (all INT)
GLOBALS_CONSTANTS = {
    "MAX_LINES":              "MAX_LINES",
    "MAX_STATIONS_PER_LINE":  "MAX_STATIONS_PER_LINE",
    "MAX_Transporters_PER_LINE": "MAX_TRANSPORTERS_PER_LINE",
    "MAX_StationIndex":       "STATION_ARRAY_END",
    "MAX_Transporters":       "MAX_TRANSPORTERS",
    "MAX_Units":              "MAX_UNITS",
    "MAX_STATIONS_PER_STEP":  "MAX_PARALLELS",
    "MAX_STEPS_PER_PROGRAM":  "MAX_STAGES",
    "DEP_MAX_IDLE_SLOTS":     "DEP_MAX_IDLE_SLOTS",
    "DEP_MAX_DELAY_ACTS":     "DEP_MAX_DELAY_ACTS",
    "DEP_MAX_WAITING":        "DEP_MAX_WAITING",
}


def patch_globals(cfg: dict) -> int:
    """Patch globals.st constant values. Returns number of replacements."""
    path = SRC_DIR / "globals.st"
    text = path.read_text()
    count = 0

    for const_name, cfg_key in GLOBALS_CONSTANTS.items():
        value = cfg[cfg_key]
        # Match:  CONST_NAME  : INT := <number>;
        # Preserve surrounding whitespace and comment
        pattern = rf'(\b{const_name}\s*:\s*INT\s*:=\s*)\d+(\s*;)'
        new = rf'\g<1>{value}\2'
        text_new, n = re.subn(pattern, new, text)
        if n == 0:
            print(f"  WARNING: '{const_name}' not found in globals.st", file=sys.stderr)
        else:
            count += n
        text = text_new

    path.write_text(text)
    return count


# ── types.st patching ───────────────────────────────────────────────

# Each entry: (regex_to_match, replacement_template)
# replacement_template uses {key} placeholders resolved from cfg
TYPES_PATCHES = [
    # TRANSPORTER_CFG_T.task_area ARRAY[1..N]
    (r'(task_area\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TASK_AREA_T)',
     r'\g<1>{MAX_TRANSPORTERS_PER_LINE}\2'),

    # PROGRAM_STAGE_T.stations ARRAY[1..N]  (also matches NTT_DEST_T.stations)
    (r'(stations\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*INT)',
     r'\g<1>{MAX_PARALLELS}\2'),

    # NTT_DEST_T.fallback_stations ARRAY[1..N]
    (r'(fallback_stations\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*INT)',
     r'\g<1>{MAX_PARALLELS}\2'),

    # TREATMENT_PROGRAM_T.stages ARRAY[1..N] OF PROGRAM_STAGE_T
    (r'(stages\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*PROGRAM_STAGE_T)',
     r'\g<1>{MAX_STAGES}\2'),

    # TSK_SCHEDULE_T.stages ARRAY[1..N] OF TSK_STAGE_T
    (r'(stages\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TSK_STAGE_T)',
     r'\g<1>{MAX_STAGES}\2'),

    # TSK_QUEUE_T.queue ARRAY[1..N] OF TSK_TASK_T
    (r'(queue\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TSK_TASK_T)',
     r'\g<1>{MAX_UNITS}\2'),

    # TRAVEL_FROM_T.to_s ARRAY[1..N] OF REAL
    (r'(to_s\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*REAL)',
     r'\g<1>{MAX_STATIONS_PER_LINE}\2'),

    # MOVE_TIMES_T.lift_s ARRAY[1..N] OF REAL
    (r'(lift_s\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*REAL)',
     r'\g<1>{MAX_STATIONS_PER_LINE}\2'),

    # MOVE_TIMES_T.sink_s ARRAY[1..N] OF REAL
    (r'(sink_s\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*REAL)',
     r'\g<1>{MAX_STATIONS_PER_LINE}\2'),

    # MOVE_TIMES_T.travel ARRAY[1..N] OF TRAVEL_FROM_T
    (r'(travel\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TRAVEL_FROM_T)',
     r'\g<1>{MAX_STATIONS_PER_LINE}\2'),

    # DEP_IDLE_SLOT_SET_T.slots ARRAY[1..N] OF DEP_IDLE_SLOT_T
    (r'(slots\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*DEP_IDLE_SLOT_T)',
     r'\g<1>{DEP_MAX_IDLE_SLOTS}\2'),

    # DEP_OVERLAP_T.flags ARRAY[101..N] OF BOOL
    (r'(flags\s*:\s*ARRAY\[)\d+\.\.\d+(\]\s*OF\s*BOOL)',
     r'\g<1>{STATION_ARRAY_START}..{STATION_ARRAY_END}\2'),

    # DEP_SANDBOX_T.schedule ARRAY[1..N] OF TSK_SCHEDULE_T
    (r'(schedule\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TSK_SCHEDULE_T)',
     r'\g<1>{MAX_UNITS}\2'),

    # DEP_SANDBOX_T.batches ARRAY[1..N] OF BATCH_T
    (r'(batches\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*BATCH_T)',
     r'\g<1>{MAX_UNITS}\2'),

    # DEP_SANDBOX_T.programs ARRAY[1..N] OF TREATMENT_PROGRAM_T
    (r'(programs\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TREATMENT_PROGRAM_T)',
     r'\g<1>{MAX_UNITS}\2'),

    # DEP_SANDBOX_T.tasks ARRAY[1..N] OF TSK_QUEUE_T
    (r'(tasks\s*:\s*ARRAY\[1\.\.)\d+(\]\s*OF\s*TSK_QUEUE_T)',
     r'\g<1>{MAX_TRANSPORTERS}\2'),

    # DEP_PENDING_WRITE_T.schedule ARRAY[1..N] OF TSK_SCHEDULE_T
    # (same pattern as sandbox schedule — handled by the global 'schedule' match above)
    # DEP_PENDING_WRITE_T.programs — handled by global 'programs' match above
]


def patch_types(cfg: dict) -> int:
    """Patch types.st array literal bounds. Returns number of replacements."""
    path = SRC_DIR / "types.st"
    text = path.read_text()
    count = 0

    for pattern, template in TYPES_PATCHES:
        # Resolve {key} placeholders in the replacement template
        replacement = template.format(**cfg)
        text_new, n = re.subn(pattern, replacement, text)
        if n == 0:
            print(f"  WARNING: pattern not matched in types.st: {pattern[:60]}...", file=sys.stderr)
        count += n
        text = text_new

    path.write_text(text)
    return count


# ── Main ────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Apply plant_config.json to ST sources")
    parser.add_argument("-c", "--config", default=str(SCRIPT_DIR / "plant_config.json"),
                        help="Path to plant_config.json")
    args = parser.parse_args()

    config_path = Path(args.config)
    if not config_path.exists():
        print(f"ERROR: Config file not found: {config_path}", file=sys.stderr)
        sys.exit(1)

    cfg = load_config(config_path)
    plant = cfg.get("plant_name", "unknown")
    print(f"Applying plant config: {plant}")
    print(f"  MAX_LINES={cfg['MAX_LINES']}  STN/LINE={cfg['MAX_STATIONS_PER_LINE']}  "
          f"TRANSPORTERS={cfg['MAX_TRANSPORTERS']}  UNITS={cfg['MAX_UNITS']}  "
          f"STAGES={cfg['MAX_STAGES']}")
    print(f"  STATION_ARRAY: {cfg['STATION_ARRAY_START']}..{cfg['STATION_ARRAY_END']}")
    print(f"  DEP: idle_slots={cfg['DEP_MAX_IDLE_SLOTS']}  "
          f"delay_acts={cfg['DEP_MAX_DELAY_ACTS']}  waiting={cfg['DEP_MAX_WAITING']}")

    g_count = patch_globals(cfg)
    print(f"  globals.st: {g_count} constants patched")

    t_count = patch_types(cfg)
    print(f"  types.st:   {t_count} array literals patched")

    if g_count < len(GLOBALS_CONSTANTS):
        print("  ⚠ Some globals constants were not found!", file=sys.stderr)
        sys.exit(1)

    print("✓ Plant config applied successfully")


if __name__ == "__main__":
    main()
