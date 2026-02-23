/**
 * OpenPLC Modbus Gateway
 * 
 * Thin Node.js gateway that reads PLC state via Modbus TCP
 * and serves REST API compatible with the existing React/Vite UI.
 * 
 * Modbus Register Map (matches plc.xml):
 *   %QW0..8   = Transporter 1 state (Holding Registers, FC3)
 *   %QW9..17  = Transporter 2 state
 *   %QW18     = station_count
 *   %QW19     = init_done (1/0)
 *   %QW20     = cycle_count (heartbeat)
 *   %QW21     = cfg_ack (echoes last processed cfg_seq)
 *   %QW22..61 = Units 1-10 (4 regs each: location, status, state, target)
 *   %QW62     = unit_ack (echoes last processed unit write seq)
 *   %QW63     = batch_ack (echoes last processed batch write seq)
 *   %QW64     = prog_ack (echoes last processed program stage seq)
 *   %QW65..104 = Batch data 1-10 (4 regs each: batch_code, state, program, stage)
 *   %QW200..205 = Commands for T1/T2
 * 
 * OpenPLC Modbus mapping:
 *   Holding Registers (FC3, FC6, FC16) → %QW  (PLC writes, we read)
 *   Input Registers   (FC4)            → %IW  (PLC reads, we write via FC6 to holding offset)
 *   
 * Note: OpenPLC maps %IW to input_regs[] read by FC4, but to WRITE to them
 * from external, we write to holding registers at offset 1024+addr (OpenPLC convention).
 */

const express = require('express');
const ModbusRTU = require('modbus-serial');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const https = require('https');

// --- Configuration ---
const PLC_HOST = process.env.PLC_HOST || 'localhost';
const PLC_PORT = parseInt(process.env.PLC_PORT || '502');
const API_PORT = parseInt(process.env.API_PORT || '3001');
const POLL_MS = parseInt(process.env.POLL_MS || '100');

// OpenPLC REST API (HTTPS on port 8443)
const PLC_API_HOST = process.env.PLC_API_HOST || PLC_HOST;
const PLC_API_PORT = parseInt(process.env.PLC_API_PORT || '8443');
const PLC_API_USER = process.env.PLC_API_USER || 'PiiJar';
const PLC_API_PASS = process.env.PLC_API_PASS || '!T0s1v41k33!';

// Customers root directory
// In Docker: /data/customers mounted from host
// Local dev: relative path
const CUSTOMERS_ROOT = process.env.CUSTOMERS_ROOT || 
  (fs.existsSync('/data/customers') 
    ? '/data/customers'
    : path.join(__dirname, '..', '..', 'customers'));

// Current selection — empty on startup, set by user via RESET
let currentCustomer = '';
let currentPlant = '';

// Dynamic customer path based on current selection
function getCustomerPath(customer, plant) {
  return path.join(CUSTOMERS_ROOT, customer || currentCustomer, plant || currentPlant);
}
function getCurrentCustomerPath() {
  return getCustomerPath(currentCustomer, currentPlant);
}

// --- Unit state/target mappings (INT ↔ string) ---
const STATE_INT_TO_STR = { 0: 'empty', 1: 'full' };
const TARGET_INT_TO_STR = { 0: 'none', 1: 'to_loading', 2: 'to_buffer', 3: 'to_process', 4: 'to_unload', 5: 'to_avoid' };
const BATCH_STATE_INT_TO_STR = { 0: 'not_processed', 1: 'in_process', 2: 'processed' };
const STATE_STR_TO_INT = Object.fromEntries(Object.entries(STATE_INT_TO_STR).map(([k,v]) => [v, parseInt(k)]));
const TARGET_STR_TO_INT = Object.fromEntries(Object.entries(TARGET_INT_TO_STR).map(([k,v]) => [v, parseInt(k)]));

// --- Phase name mapping (matches server.js convention) ---
const PHASE_NAMES = {
  0: 'idle',
  1: 'move_to_lift',
  2: 'lifting',
  3: 'move_to_sink',
  4: 'sinking'
};

const OPERATION_NAMES = {
  0: 'idle',
  1: 'moving',
  2: 'lifting',
  3: 'moving',
  4: 'sinking'
};

// Z-stage names for UI
const Z_STAGE_NAMES = {
  0: 'idle',
  1: 'waiting_device',   // lift: wait for device delay + drop
  2: 'slow_start',       // lift: slow descend
  3: 'fast_middle',      // lift: fast descend
  4: 'slow_end',         // lift: slow to bottom
  5: 'drip_wait',        // lift: drip delay
  6: 'waiting_device',   // sink: wait for device delay
  7: 'fast_rise',        // sink: fast rise
  8: 'slow_top'          // sink: slow to top
};

// --- Modbus client ---
const client = new ModbusRTU();
let connected = false;
let reconnecting = false;

// --- State cache (updated by polling loop) ---
let plcState = {
  timestamp: new Date().toISOString(),
  transporters: []
};
let plcMeta = { station_count: 0, init_done: false, cycle_count: 0 };
let lastCycleCount = -1;
let plcAlive = false;
let simStartTime = Date.now();
let simRunning = false;

// --- Calibration state (updated from QW170..QW192) ---
let calibrationState = {
  step: 0,
  tid: 0,
  results: [
    { id: 1, lift_wet: 0, sink_wet: 0, lift_dry: 0, sink_dry: 0, x_acc: 0, x_dec: 0, x_max: 0 },
    { id: 2, lift_wet: 0, sink_wet: 0, lift_dry: 0, sink_dry: 0, x_acc: 0, x_dec: 0, x_max: 0 },
    { id: 3, lift_wet: 0, sink_wet: 0, lift_dry: 0, sink_dry: 0, x_acc: 0, x_dec: 0, x_max: 0 }
  ]
};

// --- PLC Runtime API state ---
let plcJwtToken = null;
let plcRuntimeStatus = 'unknown'; // 'running' | 'stopped' | 'unknown'
let plcRuntimeLogs = '';
let plcExecTime = 'N/A';

// --- PLC REST API helpers ---
function plcApiRequest(method, apiPath, body, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: PLC_API_HOST,
      port: PLC_API_PORT,
      path: `/api/${apiPath}`,
      method,
      rejectUnauthorized: false, // self-signed cert
      headers: { 'Content-Type': 'application/json' }
    };
    if (plcJwtToken) {
      options.headers['Authorization'] = `Bearer ${plcJwtToken}`;
    }
    const payload = body ? JSON.stringify(body) : null;
    if (payload) {
      options.headers['Content-Length'] = Buffer.byteLength(payload);
    }
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, data });
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(timeoutMs, () => { req.destroy(); reject(new Error('timeout')); });
    if (payload) req.write(payload);
    req.end();
  });
}

async function plcApiLogin() {
  try {
    const res = await plcApiRequest('POST', 'login', {
      username: PLC_API_USER,
      password: PLC_API_PASS
    });
    if (res.status === 200 && res.data.access_token) {
      plcJwtToken = res.data.access_token;
      console.log('[PLC-API] JWT login OK');
      return true;
    }
    console.error('[PLC-API] Login failed:', res.status, res.data);
    return false;
  } catch (err) {
    console.error('[PLC-API] Login error:', err.message);
    return false;
  }
}

async function plcApiGet(command, timeoutMs) {
  if (!plcJwtToken) await plcApiLogin();
  try {
    const res = await plcApiRequest('GET', command, null, timeoutMs);
    if (res.status === 401) {
      // Token expired, re-login
      if (await plcApiLogin()) {
        return plcApiRequest('GET', command, null, timeoutMs);
      }
    }
    return res;
  } catch (err) {
    console.error(`[PLC-API] GET ${command} error:`, err.message);
    return { status: 0, data: { error: err.message } };
  }
}

async function pollPlcRuntimeStatus() {
  try {
    const res = await plcApiGet('status');
    if (res.status === 200 && res.data.status) {
      const s = res.data.status;
      if (s === 'STATUS:RUNNING') plcRuntimeStatus = 'running';
      else if (s === 'STATUS:STOPPED') plcRuntimeStatus = 'stopped';
      else plcRuntimeStatus = 'unknown';
    }
  } catch (err) {
    plcRuntimeStatus = 'unknown';
  }
}

// Poll PLC runtime status every 3 seconds
function startPlcStatusPolling() {
  pollPlcRuntimeStatus();
  setInterval(pollPlcRuntimeStatus, 3000);
}

// --- Transporter config (loaded from customer JSON) ---
let transporterConfig = { transporters: [] };
let stationsConfig = { stations: [] };

function loadConfigs() {
  if (!currentCustomer || !currentPlant) {
    console.log('[CONFIG] No customer/plant selected yet — skipping config load');
    transporterConfig = { transporters: [] };
    stationsConfig = { stations: [] };
    return;
  }
  const cp = getCurrentCustomerPath();
  try {
    transporterConfig = JSON.parse(fs.readFileSync(path.join(cp, 'transporters.json'), 'utf8'));
    stationsConfig = JSON.parse(fs.readFileSync(path.join(cp, 'stations.json'), 'utf8'));
    console.log(`[CONFIG] Loaded ${transporterConfig.transporters.length} transporters, ${stationsConfig.stations.length} stations from ${cp}`);
  } catch (err) {
    console.error('[CONFIG] Failed to load configs:', err.message);
  }
}

// --- Modbus connection ---
async function connectModbus() {
  if (reconnecting) return;
  reconnecting = true;
  try {
    if (client.isOpen) {
      try { client.close(); } catch (_) {}
    }
    await client.connectTCP(PLC_HOST, { port: PLC_PORT });
    client.setID(1);
    client.setTimeout(2000);
    connected = true;
    console.log(`[MODBUS] Connected to ${PLC_HOST}:${PLC_PORT}`);
  } catch (err) {
    connected = false;
    console.error(`[MODBUS] Connection failed: ${err.message}`);
  }
  reconnecting = false;
}

// Read holding registers (PLC outputs %QW)
async function readPLCState() {
  if (!connected) return null;
  try {
    // Read QW0..QW104 = 105 holding registers starting at address 0
    const result = await client.readHoldingRegisters(0, 105);
    const r = result.data;
    
    // Convert unsigned 16-bit to signed if needed (for velocities etc.)
    const toSigned = (v) => v > 32767 ? v - 65536 : v;
    
    const transporters = [];
    
    // Transporter 1: QW0..QW8
    const t1cfg = transporterConfig.transporters.find(t => t.id === 1) || {};
    transporters.push(buildTransporterState(1, t1cfg, {
      x_mm: toSigned(r[0]),
      z_mm: toSigned(r[1]),
      vel_x10: toSigned(r[2]),
      phase: r[3],
      z_stage: r[4],
      cur_st: toSigned(r[5]),
      lift_tgt: toSigned(r[6]),
      sink_tgt: toSigned(r[7]),
      active: r[8]
    }));
    
    // Transporter 2: QW9..QW17
    const t2cfg = transporterConfig.transporters.find(t => t.id === 2) || {};
    transporters.push(buildTransporterState(2, t2cfg, {
      x_mm: toSigned(r[9]),
      z_mm: toSigned(r[10]),
      vel_x10: toSigned(r[11]),
      phase: r[12],
      z_stage: r[13],
      cur_st: toSigned(r[14]),
      lift_tgt: toSigned(r[15]),
      sink_tgt: toSigned(r[16]),
      active: r[17]
    }));
    
    plcMeta = {
      station_count: r[18],
      init_done: r[19] !== 0,
      cycle_count: r[20]
    };

    // Parse unit data from QW22..QW61 (10 units x 4 fields)
    plcUnits = [];
    for (let u = 0; u < 10; u++) {
      const base = 22 + u * 4;
      const stateInt = toSigned(r[base + 2]);
      const targetInt = toSigned(r[base + 3]);
      // Batch data from QW65..QW104 (10 units x 4 fields)
      const bBase = 65 + u * 4;
      const batchCode = toSigned(r[bBase]);
      const batchState = toSigned(r[bBase + 1]);
      const batchProg = toSigned(r[bBase + 2]);
      const batchStage = toSigned(r[bBase + 3]);
      plcUnits.push({
        unit_id: u + 1,
        location: toSigned(r[base]),
        status: toSigned(r[base + 1]),
        state: STATE_INT_TO_STR[stateInt] || 'empty',
        target: TARGET_INT_TO_STR[targetInt] || 'none',
        batch_code: batchCode,
        batch_state: BATCH_STATE_INT_TO_STR[batchState] || 'not_processed',
        batch_state_int: batchState,
        batch_program: batchProg,
        batch_stage: batchStage
      });
    }
    
    // Check heartbeat
    if (plcMeta.cycle_count !== lastCycleCount) {
      plcAlive = true;
      lastCycleCount = plcMeta.cycle_count;
    }
    
    if (plcMeta.init_done && !simRunning) {
      simRunning = true;
      simStartTime = Date.now();
      console.log('[PLC] Init done, simulation running');
    }
    
    plcState = {
      timestamp: new Date().toISOString(),
      transporters
    };
    
    // Read calibration registers QW170..QW192 (23 registers)
    try {
      const calResult = await client.readHoldingRegisters(170, 23);
      const c = calResult.data;
      calibrationState.step = c[0];
      calibrationState.tid = c[1];
      for (let t = 0; t < 3; t++) {
        const base = 2 + t * 7;
        calibrationState.results[t].lift_wet = c[base]     / 10.0;
        calibrationState.results[t].sink_wet = c[base + 1] / 10.0;
        calibrationState.results[t].lift_dry = c[base + 2] / 10.0;
        calibrationState.results[t].sink_dry = c[base + 3] / 10.0;
        calibrationState.results[t].x_acc    = c[base + 4] / 10.0;
        calibrationState.results[t].x_dec    = c[base + 5] / 10.0;
        calibrationState.results[t].x_max    = c[base + 6];
      }
    } catch (calErr) {
      // Calibration registers not critical — ignore read errors
    }
    
    return plcState;
  } catch (err) {
    connected = false;
    console.error(`[MODBUS] Read error: ${err.message}`);
    return null;
  }
}

function buildTransporterState(id, cfg, regs) {
  const phase = regs.phase;
  const z_total = cfg.physics_2D ? cfg.physics_2D.z_total_distance_mm : 2500;
  
  return {
    id: id,
    model: cfg.model || '2D',
    state: {
      x_position: regs.x_mm,
      y_position: 0,
      z_position: regs.z_mm,
      operation: OPERATION_NAMES[phase] || 'idle',
      current_station: regs.cur_st || null,
      load: null,
      velocity_x: regs.vel_x10 / 10.0,
      velocity_y: 0,
      status: regs.active ? 4 : 3,
      phase: phase,
      target_x: 0,
      target_y: 0,
      z_stage: Z_STAGE_NAMES[regs.z_stage] || 'idle',
      z_timer: 0,
      velocity_z: 0,
      pending_batch_id: null,
      current_task_batch_id: null,
      current_task_lift_station_id: regs.lift_tgt || null,
      current_task_sink_station_id: regs.sink_tgt || null,
      current_task_est_finish_s: null,
      initial_delay: 0,
      lift_station_target: regs.lift_tgt || null,
      sink_station_target: regs.sink_tgt || null,
      x_drive_target: 0,
      x_final_target: 0,
      y_drive_target: 0,
      y_final_target: 0,
      x_min_drive_limit: cfg.x_min_drive_limit || 0,
      x_max_drive_limit: cfg.x_max_drive_limit || 0,
      y_min_drive_limit: 0,
      y_max_drive_limit: 0,
      z_min_drive_limit: 0,
      z_max_drive_limit: z_total,
      // Phase statistics (accumulated locally)
      phase_stats_idle_ms: 0,
      phase_stats_move_to_lift_ms: 0,
      phase_stats_lifting_ms: 0,
      phase_stats_move_to_sink_ms: 0,
      phase_stats_sinking_ms: 0,
      phase_stats_last_phase: phase,
      phase_stats_last_time_ms: Date.now()
    }
  };
}

// Write command to PLC via Modbus
// OpenPLC %QW maps to holding registers directly.
// Commands at QW100-105, config at QW110-119, units at QW120-126.
async function writePLCCommand(transporterId, liftStation, sinkStation) {
  if (!connected) throw new Error('Not connected to PLC');
  
  const baseAddr = transporterId === 1 ? 200 : 203; // QW200 for T1, QW203 for T2
  
  // Write lift station, sink station, then start command
  await client.writeRegisters(baseAddr + 1, [liftStation]);  // iw_cmd_lift
  await client.writeRegisters(baseAddr + 2, [sinkStation]);  // iw_cmd_sink
  await client.writeRegisters(baseAddr, [1]);                 // iw_cmd_start = 1 (trigger)
  
  // Clear start after a short delay (PLC reads it, then we clear)
  setTimeout(async () => {
    try {
      await client.writeRegisters(baseAddr, [0]);
    } catch (_) {}
  }, 200);
  
  console.log(`[CMD] T${transporterId}: lift=${liftStation} sink=${sinkStation}`);
}

// --- Polling loop ---
let pollTimer = null;
function startPolling() {
  pollTimer = setInterval(async () => {
    if (!connected) {
      await connectModbus();
      return;
    }
    await readPLCState();
  }, POLL_MS);
}

// --- Express server ---
const app = express();
app.use(cors());
app.use(express.json());

// Serve static config files from current customer/plant
app.get('/api/config/:filename', (req, res) => {
  const filePath = path.join(getCurrentCustomerPath(), req.params.filename);
  if (fs.existsSync(filePath)) {
    res.json(JSON.parse(fs.readFileSync(filePath, 'utf8')));
  } else {
    res.status(404).json({ error: `Config file not found: ${req.params.filename}` });
  }
});

// Main state endpoint (polled every 400ms by UI)
app.get('/api/transporter-states', (req, res) => {
  res.json(plcState);
});

// POST transporter states (UI compatibility — ignore, PLC owns state)
app.post('/api/transporter-states', (req, res) => {
  res.json(plcState);
});

// Move command (UI sends manual commands)
app.post('/api/command/move', async (req, res) => {
  try {
    const { transporterId, liftStation, sinkStation } = req.body;
    if (!transporterId || !liftStation || !sinkStation) {
      return res.status(400).json({ error: 'Missing transporterId, liftStation, sinkStation' });
    }
    await writePLCCommand(transporterId, liftStation, sinkStation);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Legacy alias
app.post('/api/reset-transporters', (req, res) => {
  res.json({ ok: true, message: 'Use /api/reset instead' });
});

// ============================================================
// RESET — Upload station config to PLC via Modbus, return data
// ============================================================
app.post('/api/reset', async (req, res) => {
  try {
    const { customer, plant } = req.body;
    if (!customer || !plant) {
      return res.status(400).json({ success: false, error: 'customer and plant required' });
    }

    const plantPath = getCustomerPath(customer, plant);
    const stationsFile = path.join(plantPath, 'stations.json');
    const tanksFile = path.join(plantPath, 'tanks.json');
    const transportersFile = path.join(plantPath, 'transporters.json');

    if (!fs.existsSync(stationsFile)) {
      return res.status(404).json({ success: false, error: 'stations.json not found' });
    }

    const stationsRaw = JSON.parse(fs.readFileSync(stationsFile, 'utf8'));
    const stations = Array.isArray(stationsRaw) ? stationsRaw : (stationsRaw.stations || []);
    const tanksRaw = fs.existsSync(tanksFile) ? JSON.parse(fs.readFileSync(tanksFile, 'utf8')) : [];
    const tanks = Array.isArray(tanksRaw) ? tanksRaw : (tanksRaw.tanks || []);
    const transportersRaw = fs.existsSync(transportersFile) ? JSON.parse(fs.readFileSync(transportersFile, 'utf8')) : [];
    const transporters = Array.isArray(transportersRaw) ? transportersRaw : (transportersRaw.transporters || []);

    if (!connected) {
      return res.status(503).json({ success: false, error: 'PLC not connected' });
    }

    // --- Step 1: Send clear_all command (cmd=3) ---
    let seq = 1;
    const CFG_BASE = 110; // QW110-QW119 for config upload protocol

    await client.writeRegisters(CFG_BASE + 2, [0]);      // QW112 = param (unused)
    await client.writeRegisters(CFG_BASE + 1, [3]);       // QW111 = cmd (3=clear_all)
    await client.writeRegisters(CFG_BASE + 0, [seq]);     // QW110 = seq (triggers PLC)

    const clearAck = await waitForCfgAck(seq, 3000);
    if (!clearAck) {
      return res.status(504).json({ success: false, error: 'PLC ack timeout for clear command' });
    }
    console.log(`[RESET] Clear done`);
    seq++;

    // --- Step 2: Upload stations (cmd=1) ---
    for (const st of stations) {
      const stNum = st.number; // e.g. 101..125
      if (stNum < 101 || stNum > 125) continue;

      // Write data fields first (QW113..QW119 = d0..d6)
      await client.writeRegisters(CFG_BASE + 3, [
        st.tank || 0,                              // d0 = tank_id
        Math.round(st.x_position || 0),            // d1 = x_position mm
        Math.round(st.y_position || 0),            // d2 = y_position mm
        Math.round(st.z_position || 0),            // d3 = z_position mm
        st.type || 0,                              // d4 = type
        Math.round((st.dropping_time || 0) * 10),  // d5 = dropping_time × 10
        Math.round((st.device_delay || 0) * 10)    // d6 = device_delay × 10
      ]);

      // Write param (station number) and cmd
      await client.writeRegisters(CFG_BASE + 2, [stNum]);  // QW112 = param
      await client.writeRegisters(CFG_BASE + 1, [1]);       // QW111 = cmd (1=write_station)
      await client.writeRegisters(CFG_BASE + 0, [seq]);     // QW110 = seq (triggers PLC)

      // Wait for PLC ack (QW21 = cfg_ack matches seq)
      const ackOk = await waitForCfgAck(seq, 2000);
      if (!ackOk) {
        return res.status(504).json({ 
          success: false, 
          error: `PLC ack timeout for station ${stNum} (seq=${seq})` 
        });
      }
      seq++;
    }

    // --- Step 3: Upload transporter configs (cmd=4,5,6) ---
    const AREA_KEYS = ['line_100', 'line_200', 'line_300', 'line_400'];
    for (const tr of transporters) {
      const tid = tr.id;
      if (tid < 1 || tid > 3) continue;
      const p = tr.physics_2D || {};

      // cmd=4: physics page 1
      await client.writeRegisters(CFG_BASE + 3, [
        Math.round(tr.x_min_drive_limit || 0),               // d0 = x_min_limit mm
        Math.round(tr.x_max_drive_limit || 0),               // d1 = x_max_limit mm
        Math.round((p.x_acceleration_time_s || 0) * 10),     // d2 = x_accel_s × 10
        Math.round((p.x_deceleration_time_s || 0) * 10),     // d3 = x_decel_s × 10
        Math.round(p.x_max_speed_mm_s || 0),                 // d4 = x_max_mm_s
        Math.round(p.z_total_distance_mm || 0),              // d5 = z_total_mm
        Math.round(p.avoid_distance_mm || 0)                 // d6 = avoid_mm
      ]);
      await client.writeRegisters(CFG_BASE + 2, [tid]);
      await client.writeRegisters(CFG_BASE + 1, [4]);
      await client.writeRegisters(CFG_BASE + 0, [seq]);
      if (!await waitForCfgAck(seq, 2000)) {
        return res.status(504).json({ success: false, error: `PLC ack timeout for transporter ${tid} phys1 (seq=${seq})` });
      }
      seq++;

      // cmd=5: physics page 2
      await client.writeRegisters(CFG_BASE + 3, [
        Math.round(p.z_slow_distance_dry_mm || 0),           // d0 = z_slow_dry_mm
        Math.round(p.z_slow_distance_wet_mm || 0),           // d1 = z_slow_wet_mm
        Math.round(p.z_slow_end_distance_mm || 0),           // d2 = z_slow_end_mm
        Math.round(p.z_slow_speed_mm_s || 0),                // d3 = z_slow_mm_s
        Math.round(p.z_fast_speed_mm_s || 0),                // d4 = z_fast_mm_s
        Math.round((p.drip_tray_delay_s || 0) * 10),         // d5 = drip_delay_s × 10
        0                                                     // d6 = reserved
      ]);
      await client.writeRegisters(CFG_BASE + 2, [tid]);
      await client.writeRegisters(CFG_BASE + 1, [5]);
      await client.writeRegisters(CFG_BASE + 0, [seq]);
      if (!await waitForCfgAck(seq, 2000)) {
        return res.status(504).json({ success: false, error: `PLC ack timeout for transporter ${tid} phys2 (seq=${seq})` });
      }
      seq++;

      // cmd=6: task areas (up to 4 per transporter)
      const areas = tr.task_areas || {};
      for (let ai = 0; ai < AREA_KEYS.length; ai++) {
        const area = areas[AREA_KEYS[ai]];
        if (!area || !area.min_lift_station) continue;
        const areaIdx = ai + 1; // 1-based
        await client.writeRegisters(CFG_BASE + 3, [
          area.min_lift_station || 0,
          area.max_lift_station || 0,
          area.min_sink_station || 0,
          area.max_sink_station || 0,
          0, 0, 0
        ]);
        await client.writeRegisters(CFG_BASE + 2, [tid * 10 + areaIdx]);
        await client.writeRegisters(CFG_BASE + 1, [6]);
        await client.writeRegisters(CFG_BASE + 0, [seq]);
        if (!await waitForCfgAck(seq, 2000)) {
          return res.status(504).json({ success: false, error: `PLC ack timeout for transporter ${tid} area ${areaIdx} (seq=${seq})` });
        }
        seq++;
      }
      console.log(`[RESET] Uploaded transporter ${tid} config to PLC`);
    }

    // --- Step 4: Send init command (cmd=2, param=station_count) ---
    await client.writeRegisters(CFG_BASE + 2, [stations.length]); // QW112 = station_count
    await client.writeRegisters(CFG_BASE + 1, [2]);               // QW111 = cmd (2=init)
    await client.writeRegisters(CFG_BASE + 0, [seq]);             // QW110 = seq

    const initAck = await waitForCfgAck(seq, 3000);
    if (!initAck) {
      return res.status(504).json({ success: false, error: 'PLC ack timeout for init command' });
    }

    console.log(`[RESET] Uploaded ${stations.length} stations + ${transporters.length} transporters to PLC for ${customer}/${plant}`);

    // --- Step 4: Upload units from unit_setup.json (if exists) ---
    const unitSetupFile = path.join(plantPath, 'unit_setup.json');
    let units = [];
    if (fs.existsSync(unitSetupFile)) {
      const unitRaw = JSON.parse(fs.readFileSync(unitSetupFile, 'utf8'));
      units = Array.isArray(unitRaw) ? unitRaw : (unitRaw.units || []);

      // String → INT mappings matching PLC globals.st constants
      const STATUS_MAP = { 'not_used': 0, 'used': 1 };

      const UNIT_BASE = 120;
      for (const u of units) {
        const uid = u.unit_id;
        if (uid < 1 || uid > 10) continue;

        const statusInt = STATUS_MAP[u.status] ?? (typeof u.status === 'number' ? u.status : 0);
        const stateInt  = STATE_STR_TO_INT[u.state]   ?? (typeof u.state  === 'number' ? u.state  : 0);
        const targetInt = TARGET_STR_TO_INT[u.target]  ?? (typeof u.target === 'number' ? u.target : 0);
        const location  = u.location || 0;

        await client.writeRegisters(UNIT_BASE + 1, [uid]);         // QW121
        await client.writeRegisters(UNIT_BASE + 2, [location]);    // QW122
        await client.writeRegisters(UNIT_BASE + 3, [statusInt]);   // QW123
        await client.writeRegisters(UNIT_BASE + 4, [stateInt]);    // QW124
        await client.writeRegisters(UNIT_BASE + 5, [targetInt]);   // QW125

        unitWriteSeq = (unitWriteSeq % 30000) + 1;
        await client.writeRegisters(UNIT_BASE + 0, [unitWriteSeq]); // QW120 = seq

        const unitAck = await waitForUnitAck(unitWriteSeq, 2000);
        if (!unitAck) {
          return res.status(504).json({
            success: false,
            error: `PLC ack timeout for unit ${uid} (seq=${unitWriteSeq})`
          });
        }
      }
      console.log(`[RESET] Uploaded ${units.length} units to PLC`);
    } else {
      console.log(`[RESET] No unit_setup.json found, skipping unit upload`);
    }

    // Update current selection
    currentCustomer = customer;
    currentPlant = plant;
    loadConfigs();

    // Notify simulator of customer/plant selection
    try {
      const simRes = await fetch('http://simulator:3002/api/copy-customer-plant', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ customer, plant })
      });
      const simData = await simRes.json();
      console.log(`[RESET] Simulator notified: ${simData.success ? 'OK' : simData.error}`);
    } catch (simErr) {
      console.warn(`[RESET] Could not notify simulator: ${simErr.message}`);
    }

    // Reset simulation timer
    simRunning = true;
    simStartTime = Date.now();

    // Include layout_config if available
    let layoutConfig = null;
    const layoutFile = path.join(plantPath, 'layout_config.json');
    if (fs.existsSync(layoutFile)) {
      const raw = JSON.parse(fs.readFileSync(layoutFile, 'utf8'));
      layoutConfig = raw.layout || raw;
    }

    res.json({ success: true, stations, tanks, transporters, units, layoutConfig });
  } catch (err) {
    console.error(`[RESET] Error: ${err.message}`);
    res.status(500).json({ success: false, error: err.message });
  }
});

// Wait for PLC cfg_ack (QW21) to match expected sequence number
async function waitForCfgAck(expectedSeq, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const result = await client.readHoldingRegisters(21, 1);
      if (result.data[0] === expectedSeq) return true;
    } catch (_) {}
    await new Promise(r => setTimeout(r, 20));
  }
  return false;
}

// Units — read from PLC via Modbus
let plcUnits = [];
let unitWriteSeq = 0;

app.get('/api/units', (req, res) => {
  res.json({ units: plcUnits });
});

app.put('/api/units/:id', async (req, res) => {
  try {
    const uid = parseInt(req.params.id);
    if (uid < 1 || uid > 10) return res.status(400).json({ error: 'unit_id must be 1..10' });
    if (!connected) return res.status(503).json({ error: 'PLC not connected' });

    const { location, status, state, target } = req.body;
    const UNIT_BASE = 120; // QW120-QW125 for unit write protocol

    // Convert string state/target to INT if needed
    const stateInt  = typeof state  === 'string' ? (STATE_STR_TO_INT[state]   ?? 0) : (state  || 0);
    const targetInt = typeof target === 'string' ? (TARGET_STR_TO_INT[target]  ?? 0) : (target || 0);

    // Write data fields first
    await client.writeRegisters(UNIT_BASE + 1, [uid]);                    // QW121 = unit_id
    await client.writeRegisters(UNIT_BASE + 2, [location || 0]);          // QW122 = location
    await client.writeRegisters(UNIT_BASE + 3, [status || 0]);            // QW123 = status
    await client.writeRegisters(UNIT_BASE + 4, [stateInt]);               // QW124 = state
    await client.writeRegisters(UNIT_BASE + 5, [targetInt]);              // QW125 = target

    // Trigger with sequence number
    unitWriteSeq = (unitWriteSeq % 30000) + 1;
    console.log(`[UNIT] Writing QW120-125: seq=${unitWriteSeq}, id=${uid}, loc=${location||0}, status=${status||0}, state=${stateInt}, target=${targetInt}`);
    await client.writeRegisters(UNIT_BASE + 0, [unitWriteSeq]);           // QW120 = seq

    // Wait for PLC ack (QW62)
    const ackOk = await waitForUnitAck(unitWriteSeq, 3000);
    if (!ackOk) {
      return res.status(504).json({ error: `PLC ack timeout for unit ${uid}` });
    }

    console.log(`[UNIT] Written unit ${uid}: loc=${location}, status=${status}, state=${state}, target=${target}`);
    res.json({ ok: true });
  } catch (err) {
    console.error(`[UNIT] Write error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

async function waitForUnitAck(expectedSeq, timeoutMs) {
  const start = Date.now();
  let lastVal = -1;
  let readCount = 0;
  while (Date.now() - start < timeoutMs) {
    try {
      const result = await client.readHoldingRegisters(62, 1);
      readCount++;
      const val = result.data[0];
      if (val !== lastVal) {
        console.log(`[UNIT-ACK] QW62=${val}, expecting=${expectedSeq} (read #${readCount}, ${Date.now()-start}ms)`);
        lastVal = val;
      }
      if (val === expectedSeq) return true;
    } catch (err) {
      console.log(`[UNIT-ACK] Read error: ${err.message}`);
    }
    await new Promise(r => setTimeout(r, 50));
  }
  console.log(`[UNIT-ACK] TIMEOUT after ${timeoutMs}ms, lastVal=${lastVal}, expected=${expectedSeq}, reads=${readCount}`);
  return false;
}

// ============================================================
// Batch + Treatment Program write protocol
// ============================================================
let batchWriteSeq = 0;
let progStageSeq = 0;

async function waitForBatchAck(expectedSeq, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const result = await client.readHoldingRegisters(63, 1); // QW63
      if (result.data[0] === expectedSeq) return true;
    } catch (_) {}
    await new Promise(r => setTimeout(r, 20));
  }
  console.log(`[BATCH-ACK] TIMEOUT expecting seq=${expectedSeq}`);
  return false;
}

async function waitForProgAck(expectedSeq, timeoutMs) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const result = await client.readHoldingRegisters(64, 1); // QW64
      if (result.data[0] === expectedSeq) return true;
    } catch (_) {}
    await new Promise(r => setTimeout(r, 20));
  }
  console.log(`[PROG-ACK] TIMEOUT expecting seq=${expectedSeq}`);
  return false;
}

/**
 * Write batch data + program_id to PLC. Also clears all program stages.
 * @param {number} unitIndex - 1..10
 * @param {number} batchCode - numeric batch code
 * @param {number} batchState - 0=NOT_PROCESSED, 1=IN_PROCESS, 2=PROCESSED
 * @param {number} programId - treatment program ID
 */
async function writeBatchToPLC(unitIndex, batchCode, batchState, programId) {
  const BATCH_BASE = 130; // QW130..QW134
  await client.writeRegisters(BATCH_BASE + 1, [unitIndex]);   // QW131
  await client.writeRegisters(BATCH_BASE + 2, [batchCode]);   // QW132
  await client.writeRegisters(BATCH_BASE + 3, [batchState]);  // QW133
  await client.writeRegisters(BATCH_BASE + 4, [programId]);   // QW134

  batchWriteSeq = (batchWriteSeq % 30000) + 1;
  await client.writeRegisters(BATCH_BASE + 0, [batchWriteSeq]); // QW130 = seq

  const ack = await waitForBatchAck(batchWriteSeq, 3000);
  if (!ack) throw new Error(`PLC batch ack timeout (unit=${unitIndex}, seq=${batchWriteSeq})`);
  console.log(`[BATCH] Written unit=${unitIndex}: code=${batchCode}, state=${batchState}, prog=${programId}`);
}

/**
 * Write one treatment program stage to PLC.
 * @param {number} unitIndex - 1..10
 * @param {number} stageIndex - 1..30
 * @param {number[]} stations - array of up to 5 station numbers (padded with 0)
 * @param {number} minTime - seconds
 * @param {number} maxTime - seconds
 * @param {number} calTime - seconds
 */
async function writeProgramStageToPLC(unitIndex, stageIndex, stations, minTime, maxTime, calTime) {
  const PROG_BASE = 140; // QW140..QW150
  const s = [0, 0, 0, 0, 0];
  for (let i = 0; i < Math.min(stations.length, 5); i++) {
    s[i] = stations[i] || 0;
  }

  await client.writeRegisters(PROG_BASE + 1, [unitIndex]);   // QW141
  await client.writeRegisters(PROG_BASE + 2, [stageIndex]);  // QW142
  await client.writeRegisters(PROG_BASE + 3, [s[0]]);        // QW143 s1
  await client.writeRegisters(PROG_BASE + 4, [s[1]]);        // QW144 s2
  await client.writeRegisters(PROG_BASE + 5, [s[2]]);        // QW145 s3
  await client.writeRegisters(PROG_BASE + 6, [s[3]]);        // QW146 s4
  await client.writeRegisters(PROG_BASE + 7, [s[4]]);        // QW147 s5
  await client.writeRegisters(PROG_BASE + 8, [minTime]);     // QW148
  await client.writeRegisters(PROG_BASE + 9, [maxTime]);     // QW149
  await client.writeRegisters(PROG_BASE + 10, [calTime]);    // QW150

  progStageSeq = (progStageSeq % 30000) + 1;
  await client.writeRegisters(PROG_BASE + 0, [progStageSeq]); // QW140 = seq

  const ack = await waitForProgAck(progStageSeq, 3000);
  if (!ack) throw new Error(`PLC prog stage ack timeout (unit=${unitIndex}, stage=${stageIndex}, seq=${progStageSeq})`);
  console.log(`[PROG] Written unit=${unitIndex} stage=${stageIndex}: stations=[${s}], min=${minTime}s, max=${maxTime}s, cal=${calTime}s`);
}

/**
 * POST /api/batch — Upload batch + treatment program to PLC
 * Body: { unitIndex, batchCode, batchState, programId, stages: [ { stations: [101,102], minTime, maxTime, calTime }, ... ] }
 */
app.post('/api/batch', async (req, res) => {
  try {
    if (!connected) return res.status(503).json({ error: 'PLC not connected' });
    const { unitIndex, batchCode, batchState, programId, stages } = req.body;

    if (!unitIndex || unitIndex < 1 || unitIndex > 10) {
      return res.status(400).json({ error: 'unitIndex must be 1..10' });
    }

    // Step 1: Write batch data + program_id (clears all stages)
    await writeBatchToPLC(unitIndex, batchCode || 0, batchState || 0, programId || 0);

    // Step 2: Write each stage
    if (Array.isArray(stages)) {
      for (let i = 0; i < stages.length && i < 30; i++) {
        const st = stages[i];
        await writeProgramStageToPLC(
          unitIndex,
          i + 1,
          st.stations || [],
          st.minTime || 0,
          st.maxTime || 0,
          st.calTime || 0
        );
      }
    }

    console.log(`[BATCH] Complete: unit=${unitIndex}, prog=${programId}, ${(stages || []).length} stages`);
    res.json({ ok: true, stagesWritten: (stages || []).length });
  } catch (err) {
    console.error(`[BATCH] Error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

    console.log(`[BATCH] Complete: unit=${unitIndex}, prog=${programId}, ${(stages || []).length} stages`);
    res.json({ ok: true, stagesWritten: (stages || []).length });
  } catch (err) {
    console.error(`[BATCH] Error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// CALIBRATION — Teaching mode for measuring transporter kinematics
// ============================================================

// GET /api/calibrate/status — current calibration state + results
app.get('/api/calibrate/status', (req, res) => {
  res.json(calibrationState);
});

// POST /api/calibrate/plan — send calibration plan for all transporters
// Body: { transporters: [{ id:1, wet_station:103, dry_station:101 }, ...] }
app.post('/api/calibrate/plan', async (req, res) => {
  try {
    if (!connected) return res.status(503).json({ error: 'PLC not connected' });
    const { transporters: plans } = req.body;
    if (!Array.isArray(plans) || plans.length === 0) {
      return res.status(400).json({ error: 'transporters array required' });
    }

    const CFG_BASE = 110;
    let seq = (await readCfgSeq()) + 1;

    for (const plan of plans) {
      const tid = plan.id;
      if (tid < 1 || tid > 3) continue;

      // cfg_cmd=7: calibration plan (d0=wet_station, d1=dry_station)
      await client.writeRegisters(CFG_BASE + 3, [
        plan.wet_station || 0,
        plan.dry_station || 0,
        0, 0, 0, 0, 0
      ]);
      await client.writeRegisters(CFG_BASE + 2, [tid]);
      await client.writeRegisters(CFG_BASE + 1, [7]);
      await client.writeRegisters(CFG_BASE + 0, [seq]);
      if (!await waitForCfgAck(seq, 2000)) {
        return res.status(504).json({ error: `PLC ack timeout for calibration plan T${tid}` });
      }
      console.log(`[CAL] Plan uploaded for T${tid}: wet=${plan.wet_station} dry=${plan.dry_station}`);
      seq++;
    }

    res.json({ ok: true, plansWritten: plans.length });
  } catch (err) {
    console.error(`[CAL] Plan error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/calibrate/start — start calibration sequence
app.post('/api/calibrate/start', async (req, res) => {
  try {
    if (!connected) return res.status(503).json({ error: 'PLC not connected' });
    const CFG_BASE = 110;
    let seq = (await readCfgSeq()) + 1;

    // cfg_cmd=8, param=1 (start)
    await client.writeRegisters(CFG_BASE + 3, [0, 0, 0, 0, 0, 0, 0]);
    await client.writeRegisters(CFG_BASE + 2, [1]);
    await client.writeRegisters(CFG_BASE + 1, [8]);
    await client.writeRegisters(CFG_BASE + 0, [seq]);
    if (!await waitForCfgAck(seq, 2000)) {
      return res.status(504).json({ error: 'PLC ack timeout for calibration start' });
    }

    console.log(`[CAL] Calibration started`);
    res.json({ ok: true });
  } catch (err) {
    console.error(`[CAL] Start error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/calibrate/calculate — tell PLC to fill g_move from measurements
app.post('/api/calibrate/calculate', async (req, res) => {
  try {
    if (!connected) return res.status(503).json({ error: 'PLC not connected' });
    const CFG_BASE = 110;
    let seq = (await readCfgSeq()) + 1;

    // cfg_cmd=8, param=2 (calculate)
    await client.writeRegisters(CFG_BASE + 3, [0, 0, 0, 0, 0, 0, 0]);
    await client.writeRegisters(CFG_BASE + 2, [2]);
    await client.writeRegisters(CFG_BASE + 1, [8]);
    await client.writeRegisters(CFG_BASE + 0, [seq]);
    if (!await waitForCfgAck(seq, 2000)) {
      return res.status(504).json({ error: 'PLC ack timeout for calibration calculate' });
    }

    console.log(`[CAL] Calculate command sent`);
    res.json({ ok: true });
  } catch (err) {
    console.error(`[CAL] Calculate error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/calibrate/abort — stop calibration, return to idle
app.post('/api/calibrate/abort', async (req, res) => {
  try {
    if (!connected) return res.status(503).json({ error: 'PLC not connected' });
    const CFG_BASE = 110;
    let seq = (await readCfgSeq()) + 1;

    // cfg_cmd=8, param=3 (abort)
    await client.writeRegisters(CFG_BASE + 3, [0, 0, 0, 0, 0, 0, 0]);
    await client.writeRegisters(CFG_BASE + 2, [3]);
    await client.writeRegisters(CFG_BASE + 1, [8]);
    await client.writeRegisters(CFG_BASE + 0, [seq]);
    if (!await waitForCfgAck(seq, 2000)) {
      return res.status(504).json({ error: 'PLC ack timeout for calibration abort' });
    }

    console.log(`[CAL] Calibration aborted`);
    res.json({ ok: true });
  } catch (err) {
    console.error(`[CAL] Abort error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// POST /api/calibrate/save — save calibration results to customer folder
// Generates movement_times.json from measured kinematic parameters
app.post('/api/calibrate/save', async (req, res) => {
  try {
    if (!currentCustomer || !currentPlant) {
      return res.status(400).json({ error: 'No customer/plant selected' });
    }

    const plantPath = getCurrentCustomerPath();
    const stations = stationsConfig.stations || [];
    const transporters = transporterConfig.transporters || [];

    // Build movement_times for each active transporter from calibration results
    const movementTimes = {};

    for (const cal of calibrationState.results) {
      const tid = cal.id;
      const tr = transporters.find(t => t.id === tid);
      if (!tr || cal.x_max <= 0) continue;

      const vm = cal.x_max;       // mm/s
      const ta = cal.x_acc;       // s
      const td = cal.x_dec;       // s
      const dAcc = 0.5 * vm * ta; // mm
      const dDec = 0.5 * vm * td; // mm

      // Build lift_s, sink_s per station
      const liftS = {};
      const sinkS = {};
      for (const st of stations) {
        const idx = st.number - 100;
        if (idx < 1 || idx > 25) continue;
        if (st.type === 1) {
          // Wet station
          liftS[st.number] = Math.round(cal.lift_wet * 100) / 100;
          sinkS[st.number] = Math.round(cal.sink_wet * 100) / 100;
        } else {
          // Dry station
          liftS[st.number] = Math.round(cal.lift_dry * 100) / 100;
          sinkS[st.number] = Math.round(cal.sink_dry * 100) / 100;
        }
      }

      // Build travel time matrix
      const travel = {};
      for (const fromSt of stations) {
        travel[fromSt.number] = {};
        for (const toSt of stations) {
          if (fromSt.number === toSt.number) {
            travel[fromSt.number][toSt.number] = 0;
            continue;
          }
          const dist = Math.abs(fromSt.x_position - toSt.x_position);
          let travelTime;
          if (dist < 1) {
            travelTime = 0;
          } else if (dist >= dAcc + dDec) {
            travelTime = ta + (dist - dAcc - dDec) / vm + td;
          } else {
            // Triangle profile
            if (ta + td > 0) {
              const vPeak = Math.sqrt(2 * dist * vm / (ta + td));
              travelTime = vPeak * (ta + td) / vm;
            } else {
              travelTime = 0;
            }
          }
          travel[fromSt.number][toSt.number] = Math.round(travelTime * 100) / 100;
        }
      }

      movementTimes[`transporter_${tid}`] = {
        id: tid,
        kinematic_params: {
          x_max_mm_s: vm,
          x_accel_s: ta,
          x_decel_s: td,
          lift_wet_s: cal.lift_wet,
          sink_wet_s: cal.sink_wet,
          lift_dry_s: cal.lift_dry,
          sink_dry_s: cal.sink_dry
        },
        lift_s: liftS,
        sink_s: sinkS,
        travel
      };
    }

    // Save to customer folder
    const outPath = path.join(plantPath, 'movement_times.json');
    fs.writeFileSync(outPath, JSON.stringify(movementTimes, null, 2));
    console.log(`[CAL] Saved movement_times.json to ${outPath}`);

    res.json({ ok: true, path: outPath, transporters: Object.keys(movementTimes).length });
  } catch (err) {
    console.error(`[CAL] Save error: ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// GET /api/calibrate/file — download existing movement_times.json
app.get('/api/calibrate/file', (req, res) => {
  if (!currentCustomer || !currentPlant) {
    return res.status(400).json({ error: 'No customer/plant selected' });
  }
  const filePath = path.join(getCurrentCustomerPath(), 'movement_times.json');
  if (fs.existsSync(filePath)) {
    res.json(JSON.parse(fs.readFileSync(filePath, 'utf8')));
  } else {
    res.status(404).json({ error: 'No movement_times.json found' });
  }
});

// Helper: read current cfg_ack to determine next seq
async function readCfgSeq() {
  try {
    const result = await client.readHoldingRegisters(21, 1);
    return result.data[0] || 0;
  } catch (_) {
    return 0;
  }
}

// PLC info endpoint (combined Modbus + Runtime API state)
app.get('/api/plc/status', (req, res) => {
  res.json({
    connected,
    plc_alive: plcAlive,
    runtime_status: plcRuntimeStatus,  // 'running' | 'stopped' | 'unknown'
    init_done: plcMeta.init_done,
    station_count: plcMeta.station_count,
    cycle_count: plcMeta.cycle_count,
    sim_running: simRunning,
    host: PLC_HOST,
    port: PLC_PORT
  });
});

// PLC Runtime control endpoints
app.post('/api/plc/start', async (req, res) => {
  try {
    const result = await plcApiGet('start-plc');
    if (result.status === 200) {
      plcRuntimeStatus = 'running';
      res.json({ success: true, message: 'PLC started', data: result.data });
    } else {
      res.status(result.status || 500).json({ success: false, error: result.data });
    }
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/plc/stop', async (req, res) => {
  try {
    const result = await plcApiGet('stop-plc', 45000);
    if (result.status === 200) {
      plcRuntimeStatus = 'stopped';
      res.json({ success: true, message: 'PLC stopped', data: result.data });
    } else {
      res.status(result.status || 500).json({ success: false, error: result.data });
    }
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/plc/logs', async (req, res) => {
  try {
    const result = await plcApiGet('runtime-logs');
    if (result.status === 200) {
      res.json({ success: true, logs: result.data['runtime-logs'] || '' });
    } else {
      res.status(result.status || 500).json({ success: false, error: result.data });
    }
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ ok: true, uptime: process.uptime() });
});

// --- Startup ---
async function main() {
  loadConfigs();
  
  console.log(`[GATEWAY] Connecting to PLC at ${PLC_HOST}:${PLC_PORT}...`);
  await connectModbus();
  
  // Login to PLC REST API and start status polling
  console.log(`[GATEWAY] Connecting to PLC REST API at ${PLC_API_HOST}:${PLC_API_PORT}...`);
  await plcApiLogin();
  startPlcStatusPolling();
  
  startPolling();
  
  app.listen(API_PORT, () => {
    console.log(`[GATEWAY] REST API on http://localhost:${API_PORT}`);
    console.log(`[GATEWAY] PLC polling every ${POLL_MS}ms`);
    console.log(`[GATEWAY] PLC Runtime API: https://${PLC_API_HOST}:${PLC_API_PORT}`);
    console.log(`[GATEWAY] Customers root: ${CUSTOMERS_ROOT}`);
    console.log(`[GATEWAY] No customer/plant selected — waiting for RESET`);
  });
}

main().catch(err => {
  console.error('[FATAL]', err);
  process.exit(1);
});
