#!/bin/bash
# ============================================================
# OpenPLC entrypoint — patches config.py f-string bug and
# seeds the REST API user so they survive container restarts.
# ============================================================
set -e

OPENPLC_DIR="/home/openplc/OpenPLC_v3"
VENV_PY="${OPENPLC_DIR}/.venv/bin/python3"
CONFIG_PY="${OPENPLC_DIR}/webserver/config.py"
ENV_FILE="${OPENPLC_DIR}/.env"
DB_FILE="${OPENPLC_DIR}/restapi.db"

# ── 1. Patch config.py: fix missing f-string on URI line ──
if grep -q 'uri = "sqlite:///{DB_PATH}"' "$CONFIG_PY" 2>/dev/null; then
  sed -i 's|uri = "sqlite:///{DB_PATH}"|uri = f"sqlite:///{DB_PATH}"|' "$CONFIG_PY"
  echo "[ENTRYPOINT] Patched config.py f-string bug"
  # Remove stale .env so it regenerates with correct URI
  rm -f "$ENV_FILE" "$DB_FILE"
fi

# ── 2. Start the OpenPLC webserver in background ──
cd "${OPENPLC_DIR}/webserver"
"$VENV_PY" webserver.py &
OPENPLC_PID=$!
echo "[ENTRYPOINT] OpenPLC webserver started (PID=$OPENPLC_PID)"

# ── 3. Wait for REST API to be ready ──
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

# ── 4. Seed REST API user if not present ──
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

# Ensure table exists (SQLAlchemy may have created it)
conn.execute('''CREATE TABLE IF NOT EXISTS user
    (id INTEGER PRIMARY KEY, username TEXT NOT NULL,
     password_hash TEXT NOT NULL, role VARCHAR(20))''')

# Check if user already exists
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

echo "[ENTRYPOINT] Init complete — keeping OpenPLC running"

# ── 5. Keep container alive with the webserver process ──
wait $OPENPLC_PID
