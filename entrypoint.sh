#!/bin/bash
# ============================================================
# OpenPLC entrypoint — patches config.py, seeds REST API user,
# and AUTO-DEPLOYS the PLC program so it survives container
# restarts without manual deploy_plc.sh.
# ============================================================
set -e

OPENPLC_DIR="/home/openplc/OpenPLC_v3"
VENV_PY="${OPENPLC_DIR}/.venv/bin/python3"
CONFIG_PY="${OPENPLC_DIR}/webserver/config.py"
ENV_FILE="${OPENPLC_DIR}/.env"
DB_FILE="${OPENPLC_DIR}/restapi.db"
PLC_HOME="${OPENPLC_DIR}/webserver"
PLC_ST_MOUNT="/home/openplc/plc_program/plc.st"
ACTIVE_PROG="blank_program.st"

# ── 1. Patch config.py: fix missing f-string on URI line ──
if grep -q 'uri = "sqlite:///{DB_PATH}"' "$CONFIG_PY" 2>/dev/null; then
  sed -i 's|uri = "sqlite:///{DB_PATH}"|uri = f"sqlite:///{DB_PATH}"|' "$CONFIG_PY"
  echo "[ENTRYPOINT] Patched config.py f-string bug"
  rm -f "$ENV_FILE" "$DB_FILE"
fi

# ── 2. Auto-deploy PLC program from mounted volume ──
if [ -f "$PLC_ST_MOUNT" ]; then
  echo "[ENTRYPOINT] Found PLC program at $PLC_ST_MOUNT ($(wc -l < "$PLC_ST_MOUNT") lines)"
  
  # Copy to st_files
  cp "$PLC_ST_MOUNT" "$PLC_HOME/st_files/$ACTIVE_PROG"
  echo "$ACTIVE_PROG" > "$PLC_HOME/active_program"
  
  # Compile
  echo "[ENTRYPOINT] Compiling PLC program..."
  cd "$PLC_HOME"
  if bash scripts/compile_program.sh "$ACTIVE_PROG" 2>&1; then
    echo "[ENTRYPOINT] PLC program compiled successfully"
  else
    echo "[ENTRYPOINT] WARNING: PLC compilation failed — check logs"
  fi
else
  echo "[ENTRYPOINT] No PLC program mounted at $PLC_ST_MOUNT — using blank program"
fi

# ── 3. Start the OpenPLC webserver in background ──
cd "${OPENPLC_DIR}/webserver"
"$VENV_PY" webserver.py &
OPENPLC_PID=$!
echo "[ENTRYPOINT] OpenPLC webserver started (PID=$OPENPLC_PID)"

# ── 4. Wait for REST API to be ready ──
echo "[ENTRYPOINT] Waiting for REST API..."
for i in $(seq 1 30); do
  if curl -sk https://localhost:8443/api/login -X POST \
       -H "Content-Type: application/json" \
       -d '{"username":"_probe","password":"_probe"}' >/dev/null 2>&1; then
    echo "[ENTRYPOINT] REST API is up (attempt $i)"
    break
  fi
  sleep 2
done

# ── 5. Seed REST API user if not present ──
PLC_API_USER="${PLC_API_USER:-PiiJar}"
PLC_API_PASS="${PLC_API_PASS:-!T0s1v41k33!}"

"$VENV_PY" - <<PYEOF
import sqlite3, os, sys
sys.path.insert(0, "${OPENPLC_DIR}/webserver")

# Read PEPPER from .env
pepper = ''
env_path = "${ENV_FILE}"
if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            if line.startswith('PEPPER='):
                pepper = line.strip().split('=', 1)[1]

if not pepper:
    print("[ENTRYPOINT] WARNING: No PEPPER found in .env, skipping user seed")
    sys.exit(0)

from werkzeug.security import generate_password_hash

db_path = "${DB_FILE}"
conn = sqlite3.connect(db_path)

conn.execute('''CREATE TABLE IF NOT EXISTS user
    (id INTEGER PRIMARY KEY, username TEXT NOT NULL,
     password_hash TEXT NOT NULL, role VARCHAR(20))''')

row = conn.execute('SELECT id FROM user WHERE username=?', ('${PLC_API_USER}',)).fetchone()
if row:
    print(f"[ENTRYPOINT] REST API user '${PLC_API_USER}' already exists (id={row[0]})")
else:
    pw = generate_password_hash('${PLC_API_PASS}' + pepper)
    conn.execute('INSERT INTO user (username, password_hash, role) VALUES (?,?,?)',
                 ('${PLC_API_USER}', pw, 'admin'))
    conn.commit()
    print(f"[ENTRYPOINT] REST API user '${PLC_API_USER}' created")

conn.close()
PYEOF

# ── 6. Auto-start PLC runtime via REST API ──
if [ -f "$PLC_ST_MOUNT" ]; then
  echo "[ENTRYPOINT] Starting PLC runtime via REST API..."
  
  # Login
  JWT=$(curl -sk https://localhost:8443/api/login -X POST \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${PLC_API_USER}\",\"password\":\"${PLC_API_PASS}\"}" \
    2>/dev/null | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
  
  if [ -n "$JWT" ]; then
    # Start PLC
    START_RES=$(curl -sk https://localhost:8443/api/start-plc \
      -H "Authorization: Bearer $JWT" 2>/dev/null)
    echo "[ENTRYPOINT] PLC start response: $START_RES"
    
    sleep 2
    # Verify
    STATUS_RES=$(curl -sk https://localhost:8443/api/status \
      -H "Authorization: Bearer $JWT" 2>/dev/null)
    echo "[ENTRYPOINT] PLC status: $STATUS_RES"
  else
    echo "[ENTRYPOINT] WARNING: Could not get JWT token — PLC not auto-started"
  fi
fi

echo "[ENTRYPOINT] Init complete — keeping OpenPLC running"

# ── 7. Keep container alive with the webserver process ──
wait $OPENPLC_PID
