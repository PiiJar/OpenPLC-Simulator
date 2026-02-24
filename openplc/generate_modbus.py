#!/usr/bin/env python3
"""
generate_modbus.py — Generate PLC + Gateway Modbus code from modbus_map.json

Reads modbus_map.json (single source of truth) and generates:
  1. OpenPLC/src/globals_modbus.st  — VAR_GLOBAL AT %QW declarations
  2. OpenPLC/src/plc_prg_modbus.st  — output write assignments for PLC program body
  3. gateway/modbus_map.js          — register map + decode/encode helpers for Node.js

Usage:
  python3 generate_modbus.py [--map modbus_map.json] [--dry-run]

The generated .st snippets are included in globals.st and plc_prg.st via
  (* --- BEGIN GENERATED MODBUS --- *)
  ...
  (* --- END GENERATED MODBUS --- *)
markers. This script replaces content between those markers.

Register allocation:
  All blocks get sequential addresses with no gaps.
  Block order in JSON = allocation order.
  Each field = 1 register (INT, 16-bit).
  uint32 values use 2 consecutive registers (hi, lo).
"""

import json
import os
import sys
import argparse
import textwrap


def load_map(map_path):
    with open(map_path, 'r') as f:
        return json.load(f)


def _replace_var_in_obj(obj, var, value):
    """Deep-replace {var} with value in all string values of a dict/list."""
    placeholder = '{' + var + '}'
    if isinstance(obj, str):
        return obj.replace(placeholder, value)
    if isinstance(obj, dict):
        return {k: _replace_var_in_obj(v, var, value) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_replace_var_in_obj(item, var, value) for item in obj]
    return obj


def expand_blocks(blocks):
    """Expand repeat blocks and assign sequential QW addresses.

    Supports:
      - repeat.start: first index (default 1)
      - template_fields: nested repeat within a repeated block
        {
          "repeat": { "count": N, "var": "q" },
          "fields": [ ... fields with {q} placeholders ... ]
        }
        Template fields are expanded BEFORE the outer repeat, so both
        {outer_var} and {inner_var} placeholders work correctly.

    Returns list of register dicts."""
    registers = []
    addr = 0  # next free QW address

    for block in blocks:
        name = block['name']
        direction = block['direction']
        fields = list(block.get('fields', []))
        template = block.get('template_fields')
        repeat = block.get('repeat')
        comment = block.get('comment', '')
        prefix = 'qw' if direction == 'out' else 'iw'

        # Expand template_fields (inner repeat) into the field list
        if template:
            t_rep = template['repeat']
            t_count = t_rep['count']
            t_var = t_rep['var']
            t_start = t_rep.get('start', 1)
            for t_idx in range(t_start, t_start + t_count):
                for tf in template['fields']:
                    fields.append(_replace_var_in_obj(tf, t_var, str(t_idx)))

        if repeat:
            count = repeat['count']
            var_t = repeat['var']  # e.g. 'i'
            label_t = repeat['label']  # e.g. 't{i}'
            start = repeat.get('start', 1)
            for idx in range(start, start + count):
                label = label_t.replace('{' + var_t + '}', str(idx))
                for field in fields:
                    source_raw = field.get('source', '')
                    source = source_raw.replace('{' + var_t + '}', str(idx)) if source_raw else None
                    api_combine = field.get('api_combine')
                    reg = {
                        'block': name,
                        'label': label,
                        'instance': idx,
                        'suffix': field['suffix'],
                        'var_name': f"{prefix}_{label}_{field['suffix']}",
                        'qw': addr,
                        'direction': direction,
                        'source': source,
                        'convert': field.get('convert'),
                        'api': field.get('api', field['suffix']),
                        'api_scale': field.get('api_scale'),
                        'api_combine': api_combine,
                        'field_type': field.get('type', 'int16'),
                        'comment': field.get('comment', ''),
                        'block_comment': comment,
                    }
                    registers.append(reg)
                    addr += 1
        else:
            for field in fields:
                reg = {
                    'block': name,
                    'label': name,
                    'instance': 0,
                    'suffix': field['suffix'],
                    'var_name': f"{prefix}_{name}_{field['suffix']}",
                    'qw': addr,
                    'direction': direction,
                    'source': field.get('source') if field.get('source') else None,
                    'convert': field.get('convert'),
                    'api': field.get('api', field['suffix']),
                    'api_scale': field.get('api_scale'),
                    'api_combine': field.get('api_combine'),
                    'field_type': field.get('type', 'int16'),
                    'comment': field.get('comment', ''),
                    'block_comment': comment,
                }
                registers.append(reg)
                addr += 1

    return registers


def generate_globals_st(registers):
    """Generate AT %QW declarations for globals.st."""
    lines = []
    lines.append('  (* --- BEGIN GENERATED MODBUS --- *)')
    lines.append(f'  (* Total registers: {len(registers)} (QW0..QW{len(registers)-1}) *)')
    lines.append('')

    current_block = None
    for reg in registers:
        # Block header
        block_key = (reg['block'], reg.get('block_comment', ''))
        if block_key != current_block:
            current_block = block_key
            lines.append(f"  (* --- {reg['block_comment'] or reg['block']} --- *)")

        prefix = 'qw' if reg['direction'] == 'out' else 'iw'
        var = reg['var_name']
        qw = reg['qw']
        comment = reg['comment']
        # Pad for alignment
        decl = f"  {var:30s} AT %QW{qw:<4d} : INT;"
        if comment:
            decl += f"  (* {comment} *)"
        lines.append(decl)

    lines.append('')
    lines.append('  (* --- END GENERATED MODBUS --- *)')
    return '\n'.join(lines)


def generate_plc_prg_st(registers):
    """Generate output write assignments for plc_prg.st body."""
    lines = []
    lines.append('(* --- BEGIN GENERATED MODBUS OUTPUT --- *)')
    lines.append(f'(* Auto-generated from modbus_map.json — {len([r for r in registers if r["direction"] == "out"])} output registers *)')
    lines.append('')

    out_regs = [r for r in registers if r['direction'] == 'out']

    current_block = None
    for reg in out_regs:
        if reg['block'] != current_block:
            current_block = reg['block']
            lines.append(f"(* === {reg['block_comment'] or reg['block']} === *)")

        var = reg['var_name']
        source = reg['source']
        convert = reg['convert']

        if not source:
            lines.append(f"(* {var} — no source (manual) *)")
            continue

        if convert == 'REAL_TO_INT':
            lines.append(f"{var} := REAL_TO_INT({source});")
        elif convert == 'BOOL_TO_INT':
            lines.append(f"IF {source} THEN {var} := 1; ELSE {var} := 0; END_IF;")
        elif convert == 'LINT_HI':
            # Upper 16 bits of LINT: divide by 65536, take INT
            # ST: var := INT_val of (source / 65536)
            # Since LINT / LINT gives LINT, we need careful conversion
            lines.append(f"{var} := LINT_TO_INT({source} / 65536);")
        elif convert == 'LINT_LO':
            # Lower 16 bits of LINT: modulo 65536
            lines.append(f"{var} := LINT_TO_INT({source} MOD 65536);")
        elif convert is None:
            lines.append(f"{var} := {source};")
        else:
            lines.append(f"(* UNKNOWN convert '{convert}' for {var} *)")

    lines.append('')
    lines.append('(* --- END GENERATED MODBUS OUTPUT --- *)')
    return '\n'.join(lines)


def generate_plc_prg_externals(registers):
    """Generate VAR_EXTERNAL declarations for plc_prg.st."""
    lines = []
    lines.append('  (* --- BEGIN GENERATED MODBUS EXTERNALS --- *)')
    for reg in registers:
        lines.append(f"  {reg['var_name']:30s} : INT;")
    lines.append('  (* --- END GENERATED MODBUS EXTERNALS --- *)')
    return '\n'.join(lines)


def generate_gateway_js(registers):
    """Generate gateway/modbus_map.js — addresses, decoder, encoder."""
    lines = []
    lines.append("/**")
    lines.append(" * Auto-generated Modbus register map — DO NOT EDIT")
    lines.append(f" * Generated from modbus_map.json ({len(registers)} registers)")
    lines.append(" */")
    lines.append("")
    lines.append(f"const TOTAL_REGISTERS = {len(registers)};")
    lines.append("")

    # --- Block address ranges ---
    lines.append("// Block address ranges")
    blocks_seen = {}
    for reg in registers:
        bname = reg['block']
        if bname not in blocks_seen:
            blocks_seen[bname] = {'start': reg['qw'], 'end': reg['qw'], 'direction': reg['direction']}
        else:
            blocks_seen[bname]['end'] = reg['qw']

    lines.append("const BLOCKS = {")
    for bname, info in blocks_seen.items():
        lines.append(f"  {bname}: {{ start: {info['start']}, end: {info['end']}, count: {info['end'] - info['start'] + 1}, direction: '{info['direction']}' }},")
    lines.append("};")
    lines.append("")

    # --- Individual register addresses ---
    lines.append("// Register addresses")
    lines.append("const REG = {")
    for reg in registers:
        lines.append(f"  {reg['var_name']}: {reg['qw']},  // {reg['comment']}")
    lines.append("};")
    lines.append("")

    # --- toSigned helper ---
    lines.append("// Convert unsigned 16-bit to signed")
    lines.append("const toSigned = (v) => v > 32767 ? v - 65536 : v;")
    lines.append("")

    # --- Decode output registers (PLC → Gateway) ---
    lines.append("/**")
    lines.append(" * Decode holding register array into structured objects.")
    lines.append(" * @param {number[]} r - Array of register values, r[0] = QW0")
    lines.append(" * @returns {object} Decoded state")
    lines.append(" */")
    lines.append("function decodeRegisters(r) {")
    lines.append("  const state = {};")
    lines.append("")

    out_regs = [reg for reg in registers if reg['direction'] == 'out']

    # Group by block+instance
    groups = {}
    for reg in out_regs:
        key = (reg['block'], reg['instance'], reg['label'])
        if key not in groups:
            groups[key] = []
        groups[key].append(reg)

    for (block, instance, label), regs in groups.items():
        obj_name = f"state.{block}" if instance == 0 else f"state.{block}"

        if instance == 0:
            # Singleton block
            lines.append(f"  // --- {block} ---")
            if block not in [k[0] for k in list(groups.keys())[:list(groups.keys()).index((block, instance, label))]]:
                lines.append(f"  state.{block} = {{}};")
            for reg in regs:
                _emit_decode_field(lines, f"state.{block}", reg)
        else:
            # Array block
            if instance == 1:
                lines.append(f"  // --- {block} ---")
                lines.append(f"  if (!state.{block}) state.{block} = {{}};")
            lines.append(f"  state.{block}[{instance}] = {{}};")
            for reg in regs:
                _emit_decode_field(lines, f"state.{block}[{instance}]", reg)

    lines.append("")
    lines.append("  return state;")
    lines.append("}")
    lines.append("")

    # --- Encode input registers (Gateway → PLC) ---
    in_regs = [reg for reg in registers if reg['direction'] == 'in']
    lines.append("/**")
    lines.append(" * Get the QW address for an input register by api name.")
    lines.append(" * @param {string} blockName")
    lines.append(" * @param {string} apiName")
    lines.append(" * @param {number} [instance] - For repeat blocks")
    lines.append(" * @returns {number|null} QW address")
    lines.append(" */")
    lines.append("function getInputAddress(blockName, apiName, instance) {")
    lines.append("  const key = instance ? `iw_${blockName.replace('_write','')}_t${instance}_${apiName}` : null;")
    lines.append("  // lookup table")
    lines.append("  const lookup = {")
    for reg in in_regs:
        lines.append(f"    '{reg['var_name']}': {reg['qw']},")
    lines.append("  };")
    lines.append("  // Try direct var name match")
    lines.append("  const varName = `iw_${blockName}_${apiName}`;")
    lines.append("  if (lookup[varName] !== undefined) return lookup[varName];")
    lines.append("  // Try with instance label")
    lines.append("  for (const [k, v] of Object.entries(lookup)) {")
    lines.append("    if (k.includes(blockName) && k.endsWith('_' + apiName)) return v;")
    lines.append("  }")
    lines.append("  return null;")
    lines.append("}")
    lines.append("")

    # --- Input block helpers ---
    in_groups = {}
    for reg in in_regs:
        key = (reg['block'], reg['instance'], reg['label'])
        if key not in in_groups:
            in_groups[key] = []
        in_groups[key].append(reg)

    lines.append("// Input block info (gateway → PLC)")
    lines.append("const INPUT_BLOCKS = {")
    for bname, info in blocks_seen.items():
        if info['direction'] == 'in':
            block_regs = [r for r in in_regs if r['block'] == bname]
            if block_regs:
                apis = [r['api'] for r in block_regs if not r['api'].startswith('_')]
                lines.append(f"  {bname}: {{ start: {info['start']}, fields: {json.dumps(apis)} }},")
    lines.append("};")
    lines.append("")

    lines.append("module.exports = {")
    lines.append("  TOTAL_REGISTERS,")
    lines.append("  BLOCKS,")
    lines.append("  REG,")
    lines.append("  toSigned,")
    lines.append("  decodeRegisters,")
    lines.append("  getInputAddress,")
    lines.append("  INPUT_BLOCKS,")
    lines.append("};")

    return '\n'.join(lines)


def _emit_decode_field(lines, obj, reg):
    """Emit one decode line for a register."""
    qw = reg['qw']
    api = reg['api']
    scale = reg.get('api_scale')
    combine = reg.get('api_combine')

    if api.startswith('_'):
        # Internal field (part of uint32 combine), store raw
        lines.append(f"  {obj}.{api} = r[{qw}];")
    elif scale:
        lines.append(f"  {obj}.{api} = toSigned(r[{qw}]) * {scale};")
    else:
        lines.append(f"  {obj}.{api} = toSigned(r[{qw}]);")

    # Emit combined uint32 field
    if combine:
        hi_api = '_' + combine['hi_suffix'] if not combine['hi_suffix'].startswith('_') else combine['hi_suffix']
        lo_api = '_' + combine['lo_suffix'] if not combine['lo_suffix'].startswith('_') else combine['lo_suffix']
        # Need to find the hi register QW
        # Build from the same label
        lines.append(f"  // Combined uint32: {combine['name']} = (hi << 16) | lo")
        lines.append(f"  {obj}.{combine['name']} = (({obj}._{combine['hi_suffix']} & 0xFFFF) * 65536) + ({obj}._{combine['lo_suffix']} & 0xFFFF);")


def generate_register_table(registers):
    """Generate human-readable register allocation table."""
    lines = []
    lines.append(f"{'QW':>5} {'Direction':>4} {'Variable':<35} {'API':>25}  {'Comment'}")
    lines.append('-' * 100)
    for reg in registers:
        d = '←' if reg['direction'] == 'out' else '→'
        lines.append(f"QW{reg['qw']:<3d} {d:>4} {reg['var_name']:<35} {reg['api']:>25}  {reg['comment']}")
    return '\n'.join(lines)


def inject_between_markers(content, begin_marker, end_marker, new_content):
    """Replace content between markers in a file."""
    begin_idx = content.find(begin_marker)
    end_idx = content.find(end_marker)
    if begin_idx == -1 or end_idx == -1:
        return None  # markers not found
    end_idx += len(end_marker)
    return content[:begin_idx] + new_content + '\n' + content[end_idx:]


def main():
    parser = argparse.ArgumentParser(description='Generate Modbus code from modbus_map.json')
    parser.add_argument('--map', default=None, help='Path to modbus_map.json')
    parser.add_argument('--dry-run', action='store_true', help='Print generated code without writing files')
    parser.add_argument('--table', action='store_true', help='Print register allocation table')
    args = parser.parse_args()

    # Find paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    map_path = args.map or os.path.join(script_dir, 'modbus_map.json')

    if not os.path.exists(map_path):
        print(f"Error: {map_path} not found", file=sys.stderr)
        sys.exit(1)

    data = load_map(map_path)
    registers = expand_blocks(data['blocks'])

    print(f"[MODBUS] Loaded {len(data['blocks'])} blocks → {len(registers)} registers (QW0..QW{len(registers)-1})")

    if args.table:
        print()
        print(generate_register_table(registers))
        print()
        return

    # Generate all outputs
    globals_st = generate_globals_st(registers)
    plc_prg_st = generate_plc_prg_st(registers)
    plc_prg_ext = generate_plc_prg_externals(registers)
    gateway_js = generate_gateway_js(registers)

    if args.dry_run:
        print("\n=== globals_modbus.st ===")
        print(globals_st)
        print("\n=== plc_prg_modbus.st (externals) ===")
        print(plc_prg_ext)
        print("\n=== plc_prg_modbus.st (body) ===")
        print(plc_prg_st)
        print("\n=== gateway/modbus_map.js ===")
        print(gateway_js)
        return

    # Write gateway/modbus_map.js
    gw_path = os.path.join(script_dir, 'gateway', 'modbus_map.js')
    with open(gw_path, 'w') as f:
        f.write(gateway_js + '\n')
    print(f"[MODBUS] Wrote {gw_path}")

    # Inject into globals.st
    globals_path = os.path.join(script_dir, 'OpenPLC', 'src', 'globals.st')
    if os.path.exists(globals_path):
        content = open(globals_path, 'r').read()
        result = inject_between_markers(
            content,
            '  (* --- BEGIN GENERATED MODBUS --- *)',
            '  (* --- END GENERATED MODBUS --- *)',
            globals_st
        )
        if result:
            with open(globals_path, 'w') as f:
                f.write(result)
            print(f"[MODBUS] Updated {globals_path}")
        else:
            print(f"[MODBUS] WARNING: markers not found in {globals_path} — writing standalone file")
            standalone = os.path.join(script_dir, 'OpenPLC', 'src', 'globals_modbus.st')
            with open(standalone, 'w') as f:
                f.write(globals_st + '\n')
            print(f"[MODBUS] Wrote {standalone}")
    else:
        print(f"[MODBUS] WARNING: {globals_path} not found")

    # Inject into plc_prg.st (externals + body)
    prg_path = os.path.join(script_dir, 'OpenPLC', 'src', 'plc_prg.st')
    if os.path.exists(prg_path):
        content = open(prg_path, 'r').read()

        # Externals
        result = inject_between_markers(
            content,
            '  (* --- BEGIN GENERATED MODBUS EXTERNALS --- *)',
            '  (* --- END GENERATED MODBUS EXTERNALS --- *)',
            plc_prg_ext
        )
        if result:
            content = result
            print(f"[MODBUS] Updated externals in {prg_path}")
        else:
            print(f"[MODBUS] WARNING: external markers not found in {prg_path}")

        # Body (output writes)
        result = inject_between_markers(
            content,
            '(* --- BEGIN GENERATED MODBUS OUTPUT --- *)',
            '(* --- END GENERATED MODBUS OUTPUT --- *)',
            plc_prg_st
        )
        if result:
            content = result
            print(f"[MODBUS] Updated output writes in {prg_path}")
        else:
            print(f"[MODBUS] WARNING: output markers not found in {prg_path}")

        with open(prg_path, 'w') as f:
            f.write(content)
    else:
        print(f"[MODBUS] WARNING: {prg_path} not found")

    # Print register table
    print()
    print(generate_register_table(registers))
    print()
    print(f"[MODBUS] Done. {len(registers)} registers mapped.")


if __name__ == '__main__':
    main()
