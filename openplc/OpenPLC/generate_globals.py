#!/usr/bin/env python3
"""
generate_globals.py — Build src/globals.st from GVLs/*.st + Modbus mapping

This script reads GVL files from GVLs/ directory, converts them to
OpenPLC-compatible globals.st format (resolving cross-GVL references),
and injects the Modbus register declarations from generate_modbus.py.

The GVL files are the single source of truth for global variable definitions.

Usage:
    python3 generate_globals.py          # from openplc/OpenPLC/
    python3 generate_globals.py --check  # verify globals.st is up-to-date (CI mode)
"""

import os
import re
import sys
import importlib.util

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
GVL_DIR = os.path.join(SCRIPT_DIR, "GVLs")
OUTPUT = os.path.join(SCRIPT_DIR, "src", "globals.st")
MODBUS_SCRIPT = os.path.join(SCRIPT_DIR, "..", "generate_modbus.py")
MODBUS_MAP = os.path.join(SCRIPT_DIR, "..", "modbus_map.json")

# Mapping from GVL PascalCase names → globals.st legacy names
# This ensures the generated globals.st is compatible with existing src/*.st code
# Key = "GVL variable name", Value = "globals.st variable name"
VAR_NAME_MAP = {
    # GVL_JC_Constants — constant names map to legacy globals.st names
    "MaxLines": "MAX_LINES",
    "MaxStationsPerLine": "MAX_STATIONS_PER_LINE",
    "MaxTransportersPerLine": "MAX_Transporters_PER_LINE",
    "MinStationIndex": "MIN_StationIndex",
    "MaxStationIndex": "MAX_StationIndex",
    "MaxTransporters": "MAX_Transporters",
    "MaxUnits": "MAX_Units",
    "MaxStationsPerStep": "MAX_STATIONS_PER_STEP",
    "MaxStepsPerProgram": "MAX_STEPS_PER_PROGRAM",
    "MaxTaskQueue": "MAX_TASK_QUEUE",
    "DepMaxIdleSlots": "DEP_MAX_IDLE_SLOTS",
    "DepMaxDelayActions": "DEP_MAX_DELAY_ACTS",
    "DepMaxWaiting": "DEP_MAX_WAITING",
    "MinWorkingArea": "MIN_WorkingArea",
    "UnitUsed": "USED",
    "UnitNotUsed": "NOT_USED",
    "UnitEmpty": "EMPTY",
    "UnitFull": "FULL",
    "TargetNone": "TO_NONE",
    "TargetLoading": "TO_LOADING",
    "TargetBuffer": "TO_BUFFER",
    "TargetProcess": "TO_PROCESS",
    "TargetUnload": "TO_UNLOAD",
    "TargetAvoid": "TO_AVOID",
    "KindDry": "KIND_DRY",
    "KindWet": "KIND_WET",
    "OpLoading": "OP_LOADING",
    "OpUnloading": "OP_UNLOADING",
    "OpLoadingUnloading": "OP_LOADING_UNLOADING",
    "BatchNotProcessed": "NOT_PROCESSED",
    "BatchInProcess": "IN_PROCESS",
    "BatchProcessed": "PROCESSED",
    "AvoidNone": "AVOID_None",
    "AvoidPassable": "AVOID_Passable",
    "AvoidBlock": "AVOID_Block",

    # GVL_Parameters — production data
    "StationCount": "g_station_count",
    "Stations": "g_station",
    "StationLocations": "g_station_loc",
    "Transporters": "g_cfg",
    "TransporterStatus": "g_transporter",
    "Units": "g_unit",
    "Batches": "g_batch",
    "TreatmentPrograms": "g_program",
    "AvoidStatus": "g_avoid_status",

    # GVL_JC_Scheduler — simulator-internal
    "SimTransporter": "g_sim_trans",
    "NttTransporter": "g_ntt",
    "MoveTimes": "g_move",
    "Schedule": "g_schedule",
    "TaskQueue": "g_task",
    "DepSandbox": "g_dep_sandbox",
    "DepIdleSlot": "g_dep_idle_slot",
    "DepWaiting": "g_dep_waiting",
    "DepWaitingCount": "g_dep_waiting_count",
    "DepOverlap": "g_dep_overlap",
    "DepPending": "g_dep_pending",
    "DepActivated": "g_dep_activated",
    "DepStable": "g_dep_stable",
    "DepWaitSched": "g_dep_wait_sched",
    "DepWaitUnit": "g_dep_wait_unit",
    "Calibration": "g_cal",
    "CalibrationActive": "g_cal_active",
    "ProductionQueue": "g_production_queue",
    "TimeSeconds": "g_time_s",
    "EventQueue": "g_event",
    "EventPending": "g_event_pending",
    "EventPendingValid": "g_event_pending_valid",
}

# Constant name references that need resolving in array bounds
# GVL reference → globals.st constant name
CONST_REF_MAP = {
    "GVL_JC_Constants.MinStationIndex": "MIN_StationIndex",
    "GVL_JC_Constants.MaxStationIndex": "MAX_StationIndex",
    "GVL_JC_Constants.MaxTransporters": "MAX_Transporters",
    "GVL_JC_Constants.MaxUnits": "MAX_Units",
    "GVL_JC_Constants.MaxTaskQueue": "MAX_TASK_QUEUE",
    "GVL_JC_Constants.MaxStepsPerProgram": "MAX_STEPS_PER_PROGRAM",
    "GVL_JC_Constants.MaxStationsPerStep": "MAX_STATIONS_PER_STEP",
    # Legacy direct references (used in some GVLs)
    "MAX_Transporters": "MAX_Transporters",
    "MAX_Units": "MAX_Units",
    "DEP_MAX_WAITING": "DEP_MAX_WAITING",
    "DEP_MAX_IDLE_SLOTS": "DEP_MAX_IDLE_SLOTS",
}

# Regex patterns
RE_VAR_DECL = re.compile(
    r"^\s+"                  # leading whitespace
    r"(\w+)"                 # variable name
    r"\s*:\s*"               # colon
    r"(.+?)"                 # type declaration
    r"\s*;\s*"               # semicolon
    r"(.*?)"                 # optional trailing (comment etc.)
    r"\s*$"
)
RE_SECTION_COMMENT = re.compile(r"^\s*\(\*.*\*\)\s*$")
RE_BLANK = re.compile(r"^\s*$")


def parse_gvl_file(filepath):
    """Parse a GVL file, return (block_type, variables).
    block_type: 'CONSTANT' or 'VARIABLE'
    variables: list of (name, type_decl, comment, is_section_comment)
    """
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Determine if CONSTANT
    is_constant = "VAR_GLOBAL CONSTANT" in content

    entries = []
    in_var = False

    for line in content.splitlines():
        stripped = line.strip()

        if stripped.startswith("VAR_GLOBAL"):
            in_var = True
            continue
        if stripped == "END_VAR":
            in_var = False
            continue

        if not in_var:
            continue

        # Blank line
        if RE_BLANK.match(line):
            entries.append(("blank", None, None, None))
            continue

        # Section comment
        if RE_SECTION_COMMENT.match(line):
            entries.append(("comment", stripped, None, None))
            continue

        # Variable declaration
        m = RE_VAR_DECL.match(line)
        if m:
            name = m.group(1)
            type_decl = m.group(2).strip()
            trailing = m.group(3).strip()
            entries.append(("var", name, type_decl, trailing))
            continue

        # Fallback — might be multi-line comment continuation
        if stripped.startswith("(*") or stripped.startswith("*"):
            entries.append(("comment", stripped, None, None))

    return ("CONSTANT" if is_constant else "VARIABLE"), entries


def resolve_type_decl(type_decl):
    """Resolve GVL cross-references in type declarations.
    E.g. ARRAY[GVL_JC_Constants.MinStationIndex..GVL_JC_Constants.MaxStationIndex] OF UDT_StationType
    → ARRAY[MIN_StationIndex..MAX_StationIndex] OF UDT_StationType
    """
    result = type_decl
    # Sort by length descending to avoid partial matches
    for gvl_ref, legacy_name in sorted(CONST_REF_MAP.items(), key=lambda x: -len(x[0])):
        result = result.replace(gvl_ref, legacy_name)
    return result


def format_var_block(block_type, entries, indent="  "):
    """Format a VAR_GLOBAL block with aligned columns."""
    # Collect variable entries for alignment calculation
    var_entries = []
    for kind, *rest in entries:
        if kind == "var":
            name, type_decl, trailing = rest
            legacy_name = VAR_NAME_MAP.get(name, name)
            resolved_type = resolve_type_decl(type_decl)
            var_entries.append((legacy_name, resolved_type, trailing))

    if not var_entries:
        return ""

    # Calculate alignment columns
    max_name_len = max(len(n) for n, _, _ in var_entries)
    colon_col = max_name_len + 1  # name + at least 1 space

    lines = []
    var_idx = 0

    for entry in entries:
        kind = entry[0]

        if kind == "blank":
            lines.append("")
            continue

        if kind == "comment":
            text = entry[1]
            lines.append(f"{indent}{text}")
            continue

        if kind == "var":
            legacy_name, resolved_type, trailing = var_entries[var_idx]
            var_idx += 1

            name_part = f"{indent}{legacy_name}".ljust(len(indent) + colon_col)

            # Include init value for constants
            type_with_init = resolved_type
            line = f"{name_part}: {type_with_init};"
            if trailing:
                line += f"  {trailing}"
            lines.append(line)

    return lines


def generate_modbus_section():
    """Call generate_modbus.py to get the Modbus declarations."""
    if not os.path.exists(MODBUS_SCRIPT):
        print(f"WARNING: {MODBUS_SCRIPT} not found, skipping Modbus section")
        return None

    if not os.path.exists(MODBUS_MAP):
        print(f"WARNING: {MODBUS_MAP} not found, skipping Modbus section")
        return None

    # Import generate_modbus dynamically
    spec = importlib.util.spec_from_file_location("generate_modbus", MODBUS_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    data = mod.load_map(MODBUS_MAP)
    registers = mod.expand_blocks(data["blocks"])
    modbus_st = mod.generate_globals_st(registers)

    return modbus_st, registers


def main():
    check_mode = "--check" in sys.argv

    if not os.path.isdir(GVL_DIR):
        print(f"ERROR: GVLs directory not found: {GVL_DIR}", file=sys.stderr)
        sys.exit(1)

    # Define processing order (constants first, then production, then JC)
    gvl_order = [
        "GVL_JC_Constants.st",
        "GVL_Parameters.st",
        "GVL_JC_Scheduler.st",
    ]

    # Verify all files exist
    for filename in gvl_order:
        filepath = os.path.join(GVL_DIR, filename)
        if not os.path.exists(filepath):
            print(f"ERROR: {filepath} not found", file=sys.stderr)
            sys.exit(1)

    # Build output
    header = (
        "(* ============================================================\n"
        "   globals.st — Auto-generated from GVLs/*.st + Modbus mapping\n"
        "   DO NOT EDIT — modify GVL files in GVLs/ directory instead\n"
        "   ============================================================ *)\n"
    )

    out_lines = [header]

    # Process each GVL file
    constant_entries = None
    variable_entries = []

    for filename in gvl_order:
        filepath = os.path.join(GVL_DIR, filename)
        block_type, entries = parse_gvl_file(filepath)

        if block_type == "CONSTANT":
            constant_entries = entries
        else:
            variable_entries.extend(entries)
            # Add blank line between GVL file contents
            variable_entries.append(("blank", None, None, None))

    # Write CONSTANT block
    if constant_entries:
        out_lines.append("VAR_GLOBAL CONSTANT")
        const_lines = format_var_block("CONSTANT", constant_entries)
        out_lines.extend(const_lines)
        out_lines.append("END_VAR")
        out_lines.append("")

    # Write VARIABLE block (includes Modbus)
    out_lines.append("VAR_GLOBAL")
    var_lines = format_var_block("VARIABLE", variable_entries)
    out_lines.extend(var_lines)

    # Add Modbus section
    modbus_result = generate_modbus_section()
    if modbus_result:
        modbus_st, registers = modbus_result
        out_lines.append(modbus_st)
        reg_count = len(registers)
    else:
        out_lines.append("  (* --- BEGIN GENERATED MODBUS --- *)")
        out_lines.append("  (* Modbus section not generated — modbus_map.json or generate_modbus.py missing *)")
        out_lines.append("  (* --- END GENERATED MODBUS --- *)")
        reg_count = 0

    out_lines.append("")
    out_lines.append("END_VAR")
    out_lines.append("")

    output = "\n".join(out_lines)

    if check_mode:
        if os.path.exists(OUTPUT):
            with open(OUTPUT, "r", encoding="utf-8") as f:
                existing = f.read()
            if existing == output:
                print("✓ globals.st is up-to-date")
                sys.exit(0)
            else:
                print("✗ globals.st is out of date — run generate_globals.py", file=sys.stderr)
                sys.exit(1)
        else:
            print(f"✗ {OUTPUT} does not exist", file=sys.stderr)
            sys.exit(1)

    # Write output
    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(output)

    print(f"✓ Generated {OUTPUT}")
    print(f"  {len(gvl_order)} GVL files, {reg_count} Modbus registers")


if __name__ == "__main__":
    main()
