#!/usr/bin/env python3
"""
format_udts.py — Format all UDT files to consistent style.

Style rules (matching UDT_TransporterStatusType.st):
  1. ':' aligned to same column (based on longest field name + 1 space)
  2. '(*' comments aligned to same column (based on longest type decl)
  3. Empty line before section comments (lines starting with '(*' inside STRUCT)
  4. 4-space indent for all fields and section comments
"""

import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UDT_DIR = os.path.join(SCRIPT_DIR, "UDTs")

# Matches a field declaration:  "    FieldName  : TYPE;  (* comment *)"
# Also handles ARRAY: "    Field  : ARRAY[1..N] OF TYPE;  (* comment *)"
RE_FIELD = re.compile(
    r"^\s+"                         # leading whitespace
    r"(\w+)"                        # field name
    r"\s*:\s*"                      # colon with optional spaces
    r"([^(]+?)"                     # type declaration (up to comment or end)
    r"\s*"                          # optional trailing spaces
    r"(\(\*.*?\*\))?"               # optional comment
    r"\s*$"                         # end of line
)

# Section comment inside STRUCT: "    (* some text *)" or multi-line header
RE_SECTION_COMMENT = re.compile(r"^\s*\(\*.*\*\)\s*$")

# "(*" at start of line (file-level comments, not indented or indented)
RE_COMMENT_LINE = re.compile(r"^\s*\(\*")

# Blank / whitespace-only line
RE_BLANK = re.compile(r"^\s*$")


def parse_udt_file(filepath):
    """Parse a UDT file into structured sections."""
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Find structural boundaries
    header_comments = []      # Lines before TYPE
    type_line = None          # "TYPE name :"
    struct_line = None        # "STRUCT"
    body_lines = []           # Everything between STRUCT and END_STRUCT
    end_struct_line = None    # "END_STRUCT;"
    end_type_line = None      # "END_TYPE"
    trailer = []              # Anything after END_TYPE

    state = "header"
    for line in lines:
        raw = line.rstrip("\n").rstrip("\r")

        if state == "header":
            if re.match(r"^\s*TYPE\s+\w+\s*:", raw):
                type_line = raw
                state = "expect_struct"
            else:
                header_comments.append(raw)

        elif state == "expect_struct":
            if raw.strip() == "STRUCT":
                struct_line = raw
                state = "body"
            else:
                # Might be multi-line TYPE declaration, treat as header
                header_comments.append(raw)

        elif state == "body":
            if raw.strip().startswith("END_STRUCT"):
                end_struct_line = raw.strip()
                state = "expect_end_type"
            else:
                body_lines.append(raw)

        elif state == "expect_end_type":
            if raw.strip().startswith("END_TYPE"):
                end_type_line = raw.strip()
                state = "done"
            else:
                trailer.append(raw)

        elif state == "done":
            trailer.append(raw)

    return header_comments, type_line, struct_line, body_lines, end_struct_line, end_type_line, trailer


def classify_body_lines(body_lines):
    """Classify body lines as fields, section comments, or blank lines.
    Returns list of tuples: ('field', name, type_decl, comment) or
                            ('comment', text) or ('blank',)
    """
    result = []
    for line in body_lines:
        stripped = line.strip()
        if not stripped:
            result.append(("blank",))
            continue

        # Try field match
        m = RE_FIELD.match(line)
        if m:
            name = m.group(1)
            type_decl = m.group(2).strip().rstrip(";").strip() + ";"
            comment = m.group(3) or ""
            result.append(("field", name, type_decl, comment.strip()))
            continue

        # Section comment or other comment line
        if RE_COMMENT_LINE.match(line):
            result.append(("comment", stripped))
            continue

        # Fallback — keep as-is (shouldn't happen in well-formed UDTs)
        result.append(("other", stripped))

    return result


def format_udt(filepath):
    """Format a single UDT file."""
    header_comments, type_line, struct_line, body_lines, end_struct_line, end_type_line, trailer = parse_udt_file(filepath)

    if type_line is None:
        print(f"  SKIP {os.path.basename(filepath)}: no TYPE line found")
        return False

    classified = classify_body_lines(body_lines)

    # Collect all field names and type declarations for alignment calculation
    fields = [(name, tdecl, comment) for kind, *rest in classified
              if kind == "field" for name, tdecl, comment in [rest]]

    if not fields:
        print(f"  SKIP {os.path.basename(filepath)}: no fields found")
        return False

    # Calculate alignment columns
    max_name_len = max(len(name) for name, _, _ in fields)
    colon_col = 4 + max_name_len + 1  # 4 indent + name + at least 1 space

    max_type_len = max(len(tdecl) for _, tdecl, _ in fields)
    comment_col = colon_col + 2 + max_type_len + 1  # ": " + type + at least 1 space

    # Build output
    out = []

    # Header comments
    for line in header_comments:
        out.append(line)

    # TYPE line — no extra blank line before it if header is non-empty
    out.append(type_line)
    out.append("STRUCT")

    # Body — format fields and comments
    prev_kind = None
    for entry in classified:
        kind = entry[0]

        if kind == "blank":
            # Skip — we'll add blanks before comments ourselves
            prev_kind = "blank"
            continue

        if kind == "comment":
            text = entry[1]
            # Add empty line before section comment (unless first item)
            if prev_kind is not None and prev_kind != "comment":
                out.append("")
            out.append(f"    {text}")
            prev_kind = "comment"
            continue

        if kind == "field":
            _, name, tdecl, comment = entry
            # Build formatted line
            name_part = f"    {name}".ljust(colon_col)
            type_part = f": {tdecl}"
            if comment:
                full_type = type_part.ljust(comment_col - colon_col)
                line = f"{name_part}{full_type}{comment}"
            else:
                line = f"{name_part}{type_part}"
            out.append(line)
            prev_kind = "field"
            continue

        if kind == "other":
            text = entry[1]
            out.append(f"    {text}")
            prev_kind = "other"

    # END_STRUCT; and END_TYPE
    out.append("END_STRUCT;")
    out.append("END_TYPE")
    out.append("")  # trailing newline

    result = "\n".join(out)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(result)

    return True


def main():
    if not os.path.isdir(UDT_DIR):
        print(f"ERROR: UDTs directory not found: {UDT_DIR}", file=sys.stderr)
        sys.exit(1)

    udt_files = sorted(f for f in os.listdir(UDT_DIR) if f.endswith(".st"))

    print(f"Formatting {len(udt_files)} UDT files...")

    formatted = 0
    for filename in udt_files:
        filepath = os.path.join(UDT_DIR, filename)
        if format_udt(filepath):
            formatted += 1
            print(f"  ✓ {filename}")

    print(f"\nFormatted {formatted}/{len(udt_files)} files")


if __name__ == "__main__":
    main()
