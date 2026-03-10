#!/usr/bin/env python3
"""
generate_types.py — Build src/types.st from individual UDT files in UDTs/

This script reads all *.st files from the UDTs/ directory, resolves
inter-type dependencies (topological sort), and writes a single
concatenated types.st into src/.

Usage:
    python3 generate_types.py          # from openplc/OpenPLC/
    python3 generate_types.py --check  # verify types.st is up-to-date (CI mode)

The UDT files are the single source of truth for all type definitions.
"""

import os
import re
import sys
from collections import defaultdict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UDT_DIR = os.path.join(SCRIPT_DIR, "UDTs")
OUTPUT  = os.path.join(SCRIPT_DIR, "src", "types.st")

# Regex to extract the type name from  "TYPE SomeName :"
RE_TYPE_DEF = re.compile(r"^TYPE\s+(\w+)\s*:", re.MULTILINE)

# Regex to find type references in field declarations (not in comments)
# Matches:  ": SomeType"  or  "OF SomeType"
RE_TYPE_REF = re.compile(
    r"(?::\s*(?:ARRAY\s*\[.*?\]\s+OF\s+)?|OF\s+)"  # ": " or ": ARRAY[...] OF " or "OF "
    r"(UDT_\w+|[A-Z][A-Z0-9_]*_T)\b"
)


def parse_udt_file(filepath):
    """Return (type_name, content, set_of_referenced_types)."""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the TYPE name defined in this file
    m = RE_TYPE_DEF.search(content)
    if not m:
        raise ValueError(f"No TYPE definition found in {filepath}")
    type_name = m.group(1)

    # Find referenced types (exclude self-references and primitives)
    refs = set()
    for line in content.splitlines():
        stripped = line.strip()
        # Skip pure comment lines
        if stripped.startswith("(*") or stripped.startswith("*"):
            continue
        for match in RE_TYPE_REF.finditer(line):
            ref = match.group(1)
            if ref != type_name:
                refs.add(ref)

    return type_name, content, refs


def topological_sort(type_map, deps):
    """
    Kahn's algorithm — returns a list of type names in dependency order.
    type_map: {type_name: (filepath, content)}
    deps:     {type_name: set_of_required_types}
    """
    all_types = set(type_map.keys())

    # Filter deps to only include types we actually define
    filtered_deps = {}
    for t in all_types:
        filtered_deps[t] = deps.get(t, set()) & all_types

    # Build in-degree map
    in_degree = defaultdict(int)
    reverse = defaultdict(list)  # who depends on me
    for t in all_types:
        if t not in in_degree:
            in_degree[t] = 0
        for dep in filtered_deps[t]:
            in_degree[t] += 1
            reverse[dep].append(t)

    # Start with nodes that have no dependencies
    queue = sorted([t for t in all_types if in_degree[t] == 0])
    result = []

    while queue:
        node = queue.pop(0)
        result.append(node)
        for dependent in sorted(reverse[node]):
            in_degree[dependent] -= 1
            if in_degree[dependent] == 0:
                queue.append(dependent)
        queue.sort()  # deterministic alphabetical within each level

    if len(result) != len(all_types):
        missing = all_types - set(result)
        raise ValueError(
            f"Circular dependency detected among: {missing}\n"
            f"Dependencies: { {t: filtered_deps[t] for t in missing} }"
        )

    return result


def main():
    check_mode = "--check" in sys.argv

    if not os.path.isdir(UDT_DIR):
        print(f"ERROR: UDTs directory not found: {UDT_DIR}", file=sys.stderr)
        sys.exit(1)

    # Collect all UDT files
    udt_files = sorted(
        f for f in os.listdir(UDT_DIR) if f.endswith(".st")
    )

    if not udt_files:
        print("ERROR: No .st files found in UDTs/", file=sys.stderr)
        sys.exit(1)

    # Parse each file
    type_map = {}   # type_name -> (filepath, content)
    deps = {}       # type_name -> set of dependencies

    for filename in udt_files:
        filepath = os.path.join(UDT_DIR, filename)
        try:
            type_name, content, refs = parse_udt_file(filepath)
        except ValueError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            sys.exit(1)

        if type_name in type_map:
            prev_file = type_map[type_name][0]
            print(
                f"ERROR: Duplicate type '{type_name}' defined in:\n"
                f"  {prev_file}\n  {filepath}",
                file=sys.stderr,
            )
            sys.exit(1)

        type_map[type_name] = (filepath, content)
        deps[type_name] = refs

    # Topological sort
    try:
        order = topological_sort(type_map, deps)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    # Build output
    header = (
        "(* ============================================================\n"
        "   types.st — Auto-generated from UDTs/*.st\n"
        "   DO NOT EDIT — modify UDT files in UDTs/ directory instead\n"
        "   ============================================================ *)\n"
    )

    parts = [header]
    for type_name in order:
        filepath, content = type_map[type_name]
        # Ensure content ends with exactly one newline
        parts.append(content.rstrip("\n") + "\n")

    output = "\n".join(parts)

    if check_mode:
        # Compare with existing file
        if os.path.exists(OUTPUT):
            with open(OUTPUT, "r", encoding="utf-8") as f:
                existing = f.read()
            if existing == output:
                print("✓ types.st is up-to-date")
                sys.exit(0)
            else:
                print(
                    "✗ types.st is out of date — run generate_types.py to update",
                    file=sys.stderr,
                )
                sys.exit(1)
        else:
            print(f"✗ {OUTPUT} does not exist", file=sys.stderr)
            sys.exit(1)

    # Write output
    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write(output)

    print(f"✓ Generated {OUTPUT}")
    print(f"  {len(order)} types from {len(udt_files)} UDT files")
    print(f"  Order: {', '.join(order)}")


if __name__ == "__main__":
    main()
