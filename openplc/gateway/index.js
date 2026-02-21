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
 *   %IW0..2   = Commands for T1 (Input Registers written via FC6/FC16)
 *   %IW3..5   = Commands for T2
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

// --- Configuration ---
const PLC_HOST = process.env.PLC_HOST || 'localhost';
const PLC_PORT = parseInt(process.env.PLC_PORT || '502');
const API_PORT = parseInt(process.env.API_PORT || '3001');
const POLL_MS = parseInt(process.env.POLL_MS || '100');

// Customers root directory
// In Docker: /data/customers mounted from host
// Local dev: relative path
const CUSTOMERS_ROOT = process.env.CUSTOMERS_ROOT || 
  (fs.existsSync('/data/customers') 
    ? '/data/customers'
    : path.join(__dirname, '..', '..', 'customers'));

// Current selection (persisted in memory, changeable via API)
let currentCustomer = process.env.DEFAULT_CUSTOMER || 'Nammo Lapua Oy';
let currentPlant = process.env.DEFAULT_PLANT || 'Factory X Zinc Phosphating';

// Dynamic customer path based on current selection
function getCustomerPath(customer, plant) {
  return path.join(CUSTOMERS_ROOT, customer || currentCustomer, plant || currentPlant);
}
function getCurrentCustomerPath() {
  return getCustomerPath(currentCustomer, currentPlant);
}

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

// --- Transporter config (loaded from customer JSON) ---
let transporterConfig = { transporters: [] };
let stationsConfig = { stations: [] };

function loadConfigs() {
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
    // Read QW0..QW20 = 21 holding registers starting at address 0
    const result = await client.readHoldingRegisters(0, 21);
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
// OpenPLC maps %IW to modbus input registers. To write to them externally,
// we write to holding registers at offset 1024 + address.
async function writePLCCommand(transporterId, liftStation, sinkStation) {
  if (!connected) throw new Error('Not connected to PLC');
  
  const baseAddr = transporterId === 1 ? 0 : 3;
  const holdingBase = 1024 + baseAddr; // OpenPLC convention for writing to %IW
  
  // Write lift station, sink station, then start command
  await client.writeRegisters(holdingBase + 1, [liftStation]);  // iw_cmd_lift
  await client.writeRegisters(holdingBase + 2, [sinkStation]);  // iw_cmd_sink
  await client.writeRegisters(holdingBase, [1]);                 // iw_cmd_start = 1 (trigger)
  
  // Clear start after a short delay (PLC reads it, then we clear)
  setTimeout(async () => {
    try {
      await client.writeRegisters(holdingBase, [0]);
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

// Reset transporters (restart PLC cycle)
app.post('/api/reset-transporters', (req, res) => {
  // PLC handles init on startup; this is a no-op for now
  res.json({ ok: true, message: 'PLC handles initialization' });
});

// Simulation time
app.get('/api/sim/time', (req, res) => {
  const elapsed = simRunning ? (Date.now() - simStartTime) / 1000 : 0;
  res.json({
    elapsed_s: elapsed,
    speed: 1.0,
    running: simRunning,
    plc_alive: plcAlive,
    plc_cycle: plcMeta.cycle_count
  });
});

// Sim control stubs
app.post('/api/sim/start', (req, res) => res.json({ ok: true }));
app.post('/api/sim/speed', (req, res) => res.json({ ok: true, speed: 1.0 }));

// Customer/plant selection — reads from customers folder
app.get('/api/current-selection', (req, res) => {
  res.json({ success: true, customer: currentCustomer, plant: currentPlant });
});

app.post('/api/current-selection', (req, res) => {
  const { customer, plant } = req.body;
  if (customer) currentCustomer = customer;
  if (plant) currentPlant = plant;
  // Reload configs for new selection
  loadConfigs();
  console.log(`[SELECT] ${currentCustomer} / ${currentPlant}`);
  res.json({ ok: true, customer: currentCustomer, plant: currentPlant });
});

// List customers — read directory names from CUSTOMERS_ROOT
app.get('/api/customers', (req, res) => {
  try {
    const dirs = fs.readdirSync(CUSTOMERS_ROOT, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .map(d => d.name)
      .sort();
    res.json({ success: true, customers: dirs });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// List plants for a customer — subdirectories that contain stations.json
app.get('/api/customers/:customer/plants', (req, res) => {
  try {
    const customerDir = path.join(CUSTOMERS_ROOT, req.params.customer);
    if (!fs.existsSync(customerDir)) {
      return res.status(404).json({ success: false, error: 'Customer not found' });
    }
    const dirs = fs.readdirSync(customerDir, { withFileTypes: true })
      .filter(d => d.isDirectory())
      .filter(d => {
        // Only include dirs that have stations.json (real plant configs)
        return fs.existsSync(path.join(customerDir, d.name, 'stations.json'));
      })
      .map(d => d.name)
      .sort();
    res.json({ success: true, plants: dirs });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/customers/:customer/plants/:plant/simulation-purpose', (req, res) => {
  const filePath = path.join(getCustomerPath(req.params.customer, req.params.plant), 'simulation_purpose.json');
  if (fs.existsSync(filePath)) {
    res.json({ success: true, data: JSON.parse(fs.readFileSync(filePath, 'utf8')) });
  } else {
    res.json({ success: true, data: { purpose: 'PLC Simulation' } });
  }
});

app.get('/api/customers/:customer/plants/:plant/status', (req, res) => {
  res.json({ success: true, status: simRunning ? 'running' : 'stopped', plc_alive: plcAlive });
});

// Transporter tasks (stub — scheduler not yet in PLC)
app.get('/api/transporter-tasks', (req, res) => {
  res.json([]);
});

app.get('/api/manual-tasks', (req, res) => {
  res.json([]);
});
app.post('/api/manual-tasks', (req, res) => {
  res.json({ ok: true, id: Date.now() });
});
app.delete('/api/manual-tasks/:id', (req, res) => {
  res.json({ ok: true });
});

// Scheduler state (stub)
app.get('/api/scheduler/state', (req, res) => {
  res.json({ mode: 'plc', running: simRunning });
});

// Batches (stub — not yet in PLC)
app.get('/api/batches', (req, res) => {
  res.json([]);
});
app.post('/api/batches', (req, res) => {
  res.json({ ok: true });
});
app.put('/api/batches/:id', (req, res) => {
  res.json({ ok: true });
});
app.delete('/api/batches/:id', (req, res) => {
  res.json({ ok: true });
});

// Units (stub)
app.get('/api/units', (req, res) => {
  res.json([]);
});
app.put('/api/units/:id', (req, res) => {
  res.json({ ok: true });
});

// Avoid statuses
app.get('/api/avoid-statuses', (req, res) => {
  res.json({});
});
app.post('/api/avoid-statuses', (req, res) => {
  res.json({ ok: true });
});

// Plant setups & production
app.get('/api/plant-setups', (req, res) => {
  res.json([]);
});
app.get('/api/production-setup', (req, res) => {
  res.json({});
});
app.post('/api/production', (req, res) => {
  res.json({ ok: true });
});

// Treatment programs
app.get('/api/treatment-programs', (req, res) => {
  const csvPath = path.join(getCurrentCustomerPath(), 'treatment_program_001.csv');
  if (fs.existsSync(csvPath)) {
    res.json([{ id: 1, name: 'treatment_program_001', file: 'treatment_program_001.csv' }]);
  } else {
    res.json([]);
  }
});

// Copy customer/plant (stub)
app.post('/api/copy-customer-plant', (req, res) => {
  res.json({ ok: true });
});
app.post('/api/customers/:customer/plants/:plant/copy-template', (req, res) => {
  res.json({ ok: true });
});

// PLC info endpoint
app.get('/api/plc/status', (req, res) => {
  res.json({
    connected,
    plc_alive: plcAlive,
    init_done: plcMeta.init_done,
    station_count: plcMeta.station_count,
    cycle_count: plcMeta.cycle_count,
    sim_running: simRunning,
    host: PLC_HOST,
    port: PLC_PORT
  });
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
  
  startPolling();
  
  app.listen(API_PORT, () => {
    console.log(`[GATEWAY] REST API on http://localhost:${API_PORT}`);
    console.log(`[GATEWAY] PLC polling every ${POLL_MS}ms`);
    console.log(`[GATEWAY] Customers root: ${CUSTOMERS_ROOT}`);
    console.log(`[GATEWAY] Default: ${currentCustomer} / ${currentPlant}`);
  });
}

main().catch(err => {
  console.error('[FATAL]', err);
  process.exit(1);
});
