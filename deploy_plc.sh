#!/bin/bash
# deploy_plc.sh — Build ST sources, upload to PLC container, compile and restart
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/openplc/OpenPLC"
BUILD_ST="$SRC_DIR/to_editor/build/plc.st"
CONTAINER=$(docker ps --format '{{.Names}}' | grep 'openplc_v3' | head -1)
if [ -z "$CONTAINER" ]; then
  echo "ERROR: No running openplc_v3 container found"
  exit 1
fi
echo "Using container: $CONTAINER"
PLC_HOME="/home/openplc/OpenPLC_v3/webserver"

# Active program filename (read from container)
ACTIVE_PROG=$(docker exec "$CONTAINER" cat "$PLC_HOME/active_program" 2>/dev/null || echo "")
if [ -z "$ACTIVE_PROG" ]; then
  echo "ERROR: Cannot read active program name from container"
  exit 1
fi
echo "Active program in runtime: $ACTIVE_PROG"

# ─── Step 0a: Generate types.st from UDT files ───
echo ""
echo "═══ Step 0a: generate_types.py ═══"
cd "$SRC_DIR"
python3 "$SRC_DIR/generate_types.py"

# ─── Step 0b: Generate globals.st from GVL files + Modbus ───
echo ""
echo "═══ Step 0b: generate_globals.py ═══"
cd "$SRC_DIR"
python3 "$SRC_DIR/generate_globals.py"

# ─── Step 0c: Apply plant_config.json → globals.st + types.st ───
echo ""
echo "═══ Step 0c: apply_plant_config.py ═══"
cd "$SRC_DIR"
python3 "$SRC_DIR/apply_plant_config.py"

# ─── Step 1: Convert src/*.st → plc.xml + build/plc.st ───
echo ""
echo "═══ Step 1: build_plcxml.py ═══"
cd "$SRC_DIR"
python3 build_plcxml.py
echo ""

# Verify unit handler is in build output
if ! grep -q "iw_unit_seq" "$BUILD_ST"; then
  echo "ERROR: build/plc.st does not contain unit handler code!"
  exit 1
fi
echo "✓ build/plc.st contains unit handler ($(wc -l < "$BUILD_ST") lines)"

# ─── Step 2: Stop PLC runtime ───
echo ""
echo "═══ Step 2: Stop PLC runtime ═══"
# Login and stop via web API
CSRF=$(curl -s -c /tmp/deploy_cookies.txt http://localhost:8080/login \
  | grep -oP "value='\K[^']+(?='  name='csrf_token')")
curl -s -b /tmp/deploy_cookies.txt -c /tmp/deploy_cookies.txt \
  -X POST http://localhost:8080/login \
  --data-urlencode "username=${PLC_WEB_USER:-openplc}" \
  --data-urlencode "password=${PLC_WEB_PASS:-openplc}" \
  --data-urlencode "csrf_token=$CSRF" \
  -o /dev/null -D /tmp/deploy_headers.txt

# Check if login succeeded (should redirect to /dashboard)
if ! grep -q "Location: /dashboard" /tmp/deploy_headers.txt 2>/dev/null; then
  echo "ERROR: Failed to login to OpenPLC web UI"
  exit 1
fi
echo "✓ Logged in to OpenPLC"

curl -s --max-time 10 -b /tmp/deploy_cookies.txt http://localhost:8080/stop_plc -o /dev/null &
sleep 3
echo "✓ PLC runtime stopped"

# ─── Step 3: Copy plc.st to container ───
echo ""
echo "═══ Step 3: Upload to container ═══"
docker cp "$BUILD_ST" "$CONTAINER:$PLC_HOME/st_files/$ACTIVE_PROG"
echo "✓ Copied build/plc.st → container st_files/$ACTIVE_PROG"

# Verify
MATCH=$(docker exec "$CONTAINER" grep -c "iw_unit_seq" "$PLC_HOME/st_files/$ACTIVE_PROG")
echo "  Unit handler references in container: $MATCH"

# ─── Step 4: Compile inside container ───
echo ""
echo "═══ Step 4: Compile PLC program ═══"
docker exec -w "$PLC_HOME" "$CONTAINER" \
  bash scripts/compile_program.sh "$ACTIVE_PROG" 2>&1
echo ""

# ─── Step 5: Restart PLC runtime ───
echo ""
echo "═══ Step 5: Restart PLC runtime ═══"
# Stop first (in case already running with old binary)
curl -s --max-time 10 -b /tmp/deploy_cookies.txt http://localhost:8080/stop_plc -o /dev/null &
sleep 3
# Start with newly compiled binary (may block — use timeout + background)
curl -s --max-time 15 -b /tmp/deploy_cookies.txt http://localhost:8080/start_plc -o /dev/null &
sleep 8

# Verify PLC is running
STATUS=$(curl -s --max-time 5 -b /tmp/deploy_cookies.txt http://localhost:8080/dashboard \
  | grep -oi "Running\|Stopped" | head -1)
echo "PLC status: $STATUS"

if [ "$STATUS" = "Running" ]; then
  echo ""
  echo "✓ Deploy complete! PLC is running with updated program."
else
  echo ""
  echo "⚠ PLC may not have started. Check http://localhost:8080"
fi

rm -f /tmp/deploy_cookies.txt /tmp/deploy_headers.txt
