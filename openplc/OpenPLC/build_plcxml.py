#!/usr/bin/env python3
"""
build_plcxml.py — Convert src/*.st files → PLCopen XML (plc.xml)

Reads IEC 61131-3 Structured Text source files from  src/  and
produces a single  plc.xml  that OpenPLC Editor / Runtime accepts.

Source files expected:
  src/types.st           TYPE … END_TYPE
  src/globals.st         VAR_GLOBAL … END_VAR
  src/config.st          CONFIGURATION … END_CONFIGURATION
  src/<pou>.st           FUNCTION / FUNCTION_BLOCK / PROGRAM

Usage:
  python3 build_plcxml.py                       # writes plc.xml
  python3 build_plcxml.py -o to_editor/plc.xml  # custom output
"""

import argparse
import os
import re
import sys
import textwrap
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
PLCOPEN_NS = "http://www.plcopen.org/xml/tc6_0201"
XHTML_NS = "http://www.w3.org/1999/xhtml"
XSD_NS = "http://www.w3.org/2001/XMLSchema"

# IEC simple types recognised by the converter
SIMPLE_TYPES = {
    "BOOL", "INT", "DINT", "LINT", "SINT", "USINT",
    "UINT", "UDINT", "ULINT", "REAL", "LREAL",
    "BYTE", "WORD", "DWORD", "LWORD",
    "STRING", "WSTRING", "TIME", "DATE", "TOD", "DT",
}

SRC_DIR = Path(__file__).parent / "src"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _strip_comments(text: str) -> str:
    """Remove (* … *) block comments (non-nested)."""
    return re.sub(r'\(\*.*?\*\)', '', text, flags=re.DOTALL)


def _xml_escape(text: str) -> str:
    """Escape &, <, > for XML attribute / text content."""
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _indent(xml: str, level: int) -> str:
    """Indent every line of *xml* by *level* × 2 spaces."""
    prefix = "  " * level
    return "\n".join(prefix + line if line.strip() else "" for line in xml.splitlines())

# ---------------------------------------------------------------------------
# TYPE parser  →  list of (name, [(field_name, type_str), …])
# ---------------------------------------------------------------------------

def parse_types(text: str):
    """Return list of (type_name, [field …]) from TYPE … END_TYPE blocks."""
    results = []
    clean = _strip_comments(text)
    blocks = re.finditer(
        r'TYPE\s+(\w+)\s*:\s*STRUCT\b(.*?)END_STRUCT\s*;\s*END_TYPE',
        clean, re.DOTALL | re.IGNORECASE)
    for m in blocks:
        name = m.group(1)
        body = m.group(2)
        fields = []
        for fld in re.finditer(r'(\w+)\s*:\s*([^;]+);', body):
            fields.append((fld.group(1).strip(), fld.group(2).strip()))
        results.append((name, fields))
    return results


def type_to_xml(type_str: str) -> str:
    """Convert a type string like 'INT', 'REAL', 'ARRAY[1..21] OF STATION_T',
       'PHYSICS_2D_T' to PLCopen XML fragment."""
    type_str = type_str.strip()
    upper = type_str.upper()

    # Array?
    arr_m = re.match(
        r'ARRAY\s*\[\s*(\d+)\s*\.\.\s*(\d+)\s*\]\s+OF\s+(.+)',
        type_str, re.IGNORECASE)
    if arr_m:
        lo, hi, base = arr_m.group(1), arr_m.group(2), arr_m.group(3).strip()
        inner = type_to_xml(base)
        return (f'<array>\n'
                f'  <dimension lower="{lo}" upper="{hi}"/>\n'
                f'  <baseType>{inner}</baseType>\n'
                f'</array>')

    # Simple type?
    for st in SIMPLE_TYPES:
        if upper == st:
            return f'<{st}/>'

    # Derived (struct / FB)
    return f'<derived name="{type_str}"/>'

# ---------------------------------------------------------------------------
# VAR_GLOBAL parser
# ---------------------------------------------------------------------------

class GlobalVar:
    __slots__ = ('name', 'type_str', 'address', 'initial')

    def __init__(self, name, type_str, address=None, initial=None):
        self.name = name
        self.type_str = type_str
        self.address = address
        self.initial = initial


def parse_globals(text: str) -> list:
    """Parse VAR_GLOBAL … END_VAR block(s)."""
    results = []
    clean = _strip_comments(text)
    blocks = re.finditer(
        r'VAR_GLOBAL\b(.*?)END_VAR',
        clean, re.DOTALL | re.IGNORECASE)
    for m in blocks:
        body = m.group(1)
        for line in body.splitlines():
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            # pattern:  name [AT %addr] : type [:= init] ;
            vm = re.match(
                r'(\w+)\s*(?:AT\s+(%[A-Za-z]+\d+))?\s*:\s*([^;:]+?)(?::=\s*([^;]+?))?\s*;',
                line, re.IGNORECASE)
            if vm:
                results.append(GlobalVar(
                    name=vm.group(1),
                    type_str=vm.group(3).strip(),
                    address=vm.group(2),
                    initial=vm.group(4).strip() if vm.group(4) else None,
                ))
    return results

# ---------------------------------------------------------------------------
# CONFIGURATION parser
# ---------------------------------------------------------------------------

class ConfigInfo:
    __slots__ = ('cfg_name', 'res_name', 'task_name',
                 'interval', 'priority', 'instance_name', 'program_type')

    def __init__(self):
        self.cfg_name = 'Config0'
        self.res_name = 'Res0'
        self.task_name = 'task0'
        self.interval = 'T#20ms'
        self.priority = '0'
        self.instance_name = 'instance0'
        self.program_type = 'PLC_PRG'


def parse_config(text: str) -> ConfigInfo:
    """Parse CONFIGURATION … END_CONFIGURATION."""
    ci = ConfigInfo()
    clean = _strip_comments(text)

    cm = re.search(r'CONFIGURATION\s+(\w+)', clean, re.IGNORECASE)
    if cm:
        ci.cfg_name = cm.group(1)

    rm = re.search(r'RESOURCE\s+(\w+)', clean, re.IGNORECASE)
    if rm:
        ci.res_name = rm.group(1)

    tm = re.search(
        r'TASK\s+(\w+)\s*\(\s*INTERVAL\s*:=\s*([^,)]+)\s*,\s*PRIORITY\s*:=\s*(\d+)',
        clean, re.IGNORECASE)
    if tm:
        ci.task_name = tm.group(1)
        ci.interval = tm.group(2).strip()
        ci.priority = tm.group(3).strip()

    pm = re.search(
        r'PROGRAM\s+(\w+)\s+WITH\s+\w+\s*:\s*(\w+)',
        clean, re.IGNORECASE)
    if pm:
        ci.instance_name = pm.group(1)
        ci.program_type = pm.group(2)

    return ci

# ---------------------------------------------------------------------------
# POU parser  (FUNCTION / FUNCTION_BLOCK / PROGRAM)
# ---------------------------------------------------------------------------

class VarDecl:
    __slots__ = ('name', 'type_str', 'initial')

    def __init__(self, name, type_str, initial=None):
        self.name = name
        self.type_str = type_str
        self.initial = initial


class POU:
    __slots__ = ('name', 'pou_type', 'return_type',
                 'input_vars', 'output_vars', 'inout_vars',
                 'external_vars', 'local_vars', 'body')

    def __init__(self):
        self.name = ''
        self.pou_type = ''       # function | functionBlock | program
        self.return_type = None  # only for FUNCTION
        self.input_vars = []
        self.output_vars = []
        self.inout_vars = []
        self.external_vars = []
        self.local_vars = []
        self.body = ''


def _parse_var_section(section_body: str) -> list:
    """Parse variable declarations inside a VAR_xxx … END_VAR section."""
    results = []
    for line in section_body.splitlines():
        line = line.strip()
        if not line or line.startswith('//'):
            continue
        vm = re.match(
            r'(\w+)\s*:\s*([^;:]+?)(?::=\s*([^;]+?))?\s*;',
            line, re.IGNORECASE)
        if vm:
            results.append(VarDecl(
                name=vm.group(1),
                type_str=vm.group(2).strip(),
                initial=vm.group(3).strip() if vm.group(3) else None,
            ))
    return results


def parse_pou(text: str) -> POU | None:
    """Parse a single FUNCTION / FUNCTION_BLOCK / PROGRAM from *text*.

    Comments are stripped only from structure (header + VAR sections).
    The ST body is taken from the RAW (original) text so that inline
    comments like (* === MODBUS OUTPUT … === *) are preserved.
    """
    clean = _strip_comments(text)
    raw = text  # keep original for body extraction

    pou = POU()

    # Detect POU kind (from cleaned text)
    fm = re.match(r'\s*FUNCTION_BLOCK\s+(\w+)', clean, re.IGNORECASE)
    if fm:
        pou.name = fm.group(1)
        pou.pou_type = 'functionBlock'
        end_kw = 'END_FUNCTION_BLOCK'
    else:
        fm = re.match(r'\s*FUNCTION\s+(\w+)\s*:\s*(\w+)', clean, re.IGNORECASE)
        if fm:
            pou.name = fm.group(1)
            pou.pou_type = 'function'
            pou.return_type = fm.group(2)
            end_kw = 'END_FUNCTION'
        else:
            fm = re.match(r'\s*PROGRAM\s+(\w+)', clean, re.IGNORECASE)
            if fm:
                pou.name = fm.group(1)
                pou.pou_type = 'program'
                end_kw = 'END_PROGRAM'
            else:
                return None

    # ----- Work on CLEAN text for VAR sections -----
    rest_clean = clean[fm.end():]
    end_pat = re.compile(re.escape(end_kw) + r'\s*$', re.IGNORECASE)
    rest_clean = end_pat.sub('', rest_clean)

    var_section_map = {
        'VAR_INPUT':    'input_vars',
        'VAR_OUTPUT':   'output_vars',
        'VAR_IN_OUT':   'inout_vars',
        'VAR_EXTERNAL': 'external_vars',
        'VAR':          'local_vars',
    }

    var_spans_clean = []
    for kw, attr in var_section_map.items():
        if kw == 'VAR':
            pat = re.compile(r'\bVAR\b(?!_)(.*?)END_VAR', re.DOTALL | re.IGNORECASE)
        else:
            pat = re.compile(re.escape(kw) + r'\b(.*?)END_VAR', re.DOTALL | re.IGNORECASE)
        for vm in pat.finditer(rest_clean):
            setattr(pou, attr, _parse_var_section(vm.group(1)))
            var_spans_clean.append((vm.start(), vm.end()))

    # ----- Extract body from RAW text (preserves comments) -----
    # Find the last END_VAR in the raw text, body starts after it.
    # Then remove trailing END_FUNCTION / END_FUNCTION_BLOCK / END_PROGRAM.
    raw_header_m = re.match(
        r'\s*(?:FUNCTION_BLOCK\s+\w+|FUNCTION\s+\w+\s*:\s*\w+|PROGRAM\s+\w+)',
        raw, re.IGNORECASE)
    rest_raw = raw[raw_header_m.end():] if raw_header_m else raw

    # Find all END_VAR positions in raw text
    end_var_positions = [m.end() for m in re.finditer(r'END_VAR', rest_raw, re.IGNORECASE)]
    if end_var_positions:
        body_start = max(end_var_positions)
        body_raw = rest_raw[body_start:]
    else:
        body_raw = rest_raw

    # Remove trailing END_xxx
    body_raw = re.sub(re.escape(end_kw) + r'\s*$', '', body_raw, flags=re.IGNORECASE)

    # Dedent: remove common leading whitespace
    body_lines = body_raw.split('\n')
    # Strip leading/trailing blank lines
    while body_lines and not body_lines[0].strip():
        body_lines.pop(0)
    while body_lines and not body_lines[-1].strip():
        body_lines.pop()

    pou.body = textwrap.dedent('\n'.join(body_lines))

    return pou

# ---------------------------------------------------------------------------
# XML generation
# ---------------------------------------------------------------------------

def _var_xml(var: VarDecl | GlobalVar, indent_lvl: int) -> str:
    """Generate <variable> XML for a single variable declaration."""
    pad = "  " * indent_lvl
    addr_attr = ''
    if isinstance(var, GlobalVar) and var.address:
        addr_attr = f' address="{var.address}"'

    lines = [f'{pad}<variable name="{var.name}"{addr_attr}>']

    type_xml = type_to_xml(var.type_str)
    if '\n' in type_xml:
        lines.append(f'{pad}  <type>')
        lines.append(_indent(type_xml, indent_lvl + 2))
        lines.append(f'{pad}  </type>')
    else:
        lines.append(f'{pad}  <type>{type_xml}</type>')

    if var.initial is not None:
        lines.append(f'{pad}  <initialValue><simpleValue value="{_xml_escape(var.initial)}"/></initialValue>')

    lines.append(f'{pad}</variable>')
    return '\n'.join(lines)


def _var_section_xml(tag: str, vars_list: list, indent_lvl: int) -> str:
    """Wrap a list of VarDecl in <inputVars>, <localVars>, etc."""
    if not vars_list:
        return ''
    pad = "  " * indent_lvl
    lines = [f'{pad}<{tag}>']
    for v in vars_list:
        lines.append(_var_xml(v, indent_lvl + 1))
    lines.append(f'{pad}</{tag}>')
    return '\n'.join(lines)


def _datatype_xml(name: str, fields: list, indent_lvl: int) -> str:
    """Generate <dataType> XML for a struct."""
    pad = "  " * indent_lvl
    lines = [f'{pad}<dataType name="{name}">']
    lines.append(f'{pad}  <baseType>')
    lines.append(f'{pad}    <struct>')
    for fname, ftype in fields:
        type_xml = type_to_xml(ftype)
        lines.append(f'{pad}      <variable name="{fname}">')
        if '\n' in type_xml:
            lines.append(f'{pad}        <type>')
            lines.append(_indent(type_xml, indent_lvl + 5))
            lines.append(f'{pad}        </type>')
        else:
            lines.append(f'{pad}        <type>{type_xml}</type>')
        lines.append(f'{pad}      </variable>')
    lines.append(f'{pad}    </struct>')
    lines.append(f'{pad}  </baseType>')
    lines.append(f'{pad}</dataType>')
    return '\n'.join(lines)


def _pou_xml(pou: POU, indent_lvl: int) -> str:
    """Generate <pou> XML for a function / function_block / program."""
    pad = "  " * indent_lvl
    lines = [f'{pad}<pou name="{pou.name}" pouType="{pou.pou_type}">']

    # -- interface --
    lines.append(f'{pad}  <interface>')

    if pou.return_type:
        rt = type_to_xml(pou.return_type)
        lines.append(f'{pad}    <returnType>')
        lines.append(f'{pad}      {rt}')
        lines.append(f'{pad}    </returnType>')

    section_map = [
        ('inputVars',    pou.input_vars),
        ('outputVars',   pou.output_vars),
        ('inOutVars',    pou.inout_vars),
        ('externalVars', pou.external_vars),
        ('localVars',    pou.local_vars),
    ]
    for tag, vlist in section_map:
        xml = _var_section_xml(tag, vlist, indent_lvl + 2)
        if xml:
            lines.append(xml)

    lines.append(f'{pad}  </interface>')

    # -- body (ST) --
    lines.append(f'{pad}  <body>')
    lines.append(f'{pad}    <ST>')
    lines.append(f'{pad}      <xhtml:p><![CDATA[{pou.body}]]></xhtml:p>')
    lines.append(f'{pad}    </ST>')
    lines.append(f'{pad}  </body>')

    lines.append(f'{pad}</pou>')
    return '\n'.join(lines)


def build_plcxml(
    data_types: list,
    global_vars: list,
    config: ConfigInfo,
    pous: list[POU],
    company: str = "Nammo",
    product: str = "OpenPLC",
    product_version: str = "1",
    project_name: str = "PhysicsSimulator",
) -> str:
    """Assemble the full PLCopen XML string."""

    now = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

    lines = [
        "<?xml version='1.0' encoding='utf-8'?>",
        f'<project xmlns:ns1="{PLCOPEN_NS}" xmlns:xhtml="{XHTML_NS}" '
        f'xmlns:xsd="{XSD_NS}" xmlns="{PLCOPEN_NS}">',
        f'  <fileHeader companyName="{company}" productName="{product}" '
        f'productVersion="{product_version}" creationDateTime="{now}"/>',
        f'  <contentHeader name="{project_name}" modificationDateTime="{now}">',
        '    <coordinateInfo>',
        '      <fbd>',
        '        <scaling x="0" y="0"/>',
        '      </fbd>',
        '      <ld>',
        '        <scaling x="0" y="0"/>',
        '      </ld>',
        '      <sfc>',
        '        <scaling x="0" y="0"/>',
        '      </sfc>',
        '    </coordinateInfo>',
        '  </contentHeader>',
        '  <types>',
        '    <dataTypes>',
    ]

    # -- dataTypes --
    for dt_name, dt_fields in data_types:
        lines.append(_datatype_xml(dt_name, dt_fields, 3))

    lines.append('    </dataTypes>')
    lines.append('    <pous>')

    # -- POUs --
    for pou in pous:
        lines.append(_pou_xml(pou, 3))

    lines.append('    </pous>')
    lines.append('  </types>')

    # -- instances / configuration --
    lines.append('  <instances>')
    lines.append('    <configurations>')
    lines.append(f'      <configuration name="{config.cfg_name}">')
    lines.append(f'        <resource name="{config.res_name}">')
    lines.append(f'          <task name="{config.task_name}" priority="{config.priority}" interval="{config.interval}">')
    lines.append(f'            <pouInstance name="{config.instance_name}" typeName="{config.program_type}"/>')
    lines.append(f'          </task>')
    lines.append(f'        </resource>')

    # -- globalVars --
    lines.append('        <globalVars>')
    for gv in global_vars:
        lines.append(_var_xml(gv, 5))
    lines.append('        </globalVars>')

    lines.append(f'      </configuration>')
    lines.append('    </configurations>')
    lines.append('  </instances>')
    lines.append('</project>')

    return '\n'.join(lines) + '\n'

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Convert src/*.st → PLCopen plc.xml')
    parser.add_argument('-s', '--src', default=str(SRC_DIR),
                        help='Source directory (default: src/)')
    parser.add_argument('-o', '--output', default='to_editor/plc.xml',
                        help='Output file (default: to_editor/plc.xml)')
    args = parser.parse_args()

    src = Path(args.src)
    if not src.is_dir():
        print(f"ERROR: Source directory '{src}' not found.", file=sys.stderr)
        sys.exit(1)

    # -- Read all .st files --
    st_files = {}
    for p in sorted(src.glob('*.st')):
        st_files[p.stem] = p.read_text(encoding='utf-8')
        print(f"  read  {p.name}")

    # -- Parse types --
    data_types = []
    if 'types' in st_files:
        data_types = parse_types(st_files['types'])
        print(f"  types: {[dt[0] for dt in data_types]}")

    # -- Parse globals --
    global_vars = []
    if 'globals' in st_files:
        global_vars = parse_globals(st_files['globals'])
        print(f"  globals: {len(global_vars)} variables")

    # -- Parse config --
    config = ConfigInfo()
    if 'config' in st_files:
        config = parse_config(st_files['config'])
        print(f"  config: {config.cfg_name}/{config.res_name} "
              f"task={config.task_name} interval={config.interval}")

    # -- Parse POUs --
    pous = []
    skip = {'types', 'globals', 'config'}
    # Ensure a deterministic order: functions first, then FBs, then programs
    pou_order = {'function': 0, 'functionBlock': 1, 'program': 2}
    raw_pous = []
    for stem, text in st_files.items():
        if stem in skip:
            continue
        pou = parse_pou(text)
        if pou:
            raw_pous.append(pou)
            print(f"  POU: {pou.name} ({pou.pou_type})")
        else:
            print(f"  WARNING: could not parse POU from {stem}.st",
                  file=sys.stderr)

    pous = sorted(raw_pous, key=lambda p: pou_order.get(p.pou_type, 9))

    # -- Generate XML --
    xml = build_plcxml(data_types, global_vars, config, pous)

    out = Path(args.output)
    out.write_text(xml, encoding='utf-8')
    print(f"\n  ✓ Written {out}  ({len(xml)} bytes)")


if __name__ == '__main__':
    main()
