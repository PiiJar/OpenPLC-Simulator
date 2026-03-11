/**
 * event_consumer.js — PLC event queue consumer
 *
 * Reads the head event message from Modbus output registers,
 * inserts it into PostgreSQL, and writes ack_seq back to PLC
 * via Modbus input register.
 *
 * Called every poll cycle from the main gateway loop.
 *
 * Register layout (from modbus_map.js):
 *   event_out: QW737..QW753 (17 regs, out)
 *     [0]  count     — messages in queue (0..10)
 *     [1]  seq       — head message sequence number (1..32000)
 *     [2]  type      — 1=TASK_DISPATCHED, 2=LIFT
 *     [3]  ts_hi     — unix timestamp upper 16 bits
 *     [4]  ts_lo     — unix timestamp lower 16 bits
 *     [5..16] f1..f12 — payload fields (meaning depends on type)
 *   event_ack: QW754 (1 reg, in)
 *     [0]  ack_seq   — last consumed sequence number
 */

const { BLOCKS, REG } = require('./modbus_map');

const EVENT_START = BLOCKS.event_out.start;   // 737
const EVENT_COUNT = BLOCKS.event_out.count;   // 17

const MSG_TYPE_NAMES = {
  1: 'TASK_DISPATCHED',
  2: 'LIFT',
  3: 'TASK_COMPLETE',
};

function toSigned(v) {
  return v > 32767 ? v - 65536 : v;
}

let lastAckedSeq = 0;
let dbReady = false;

/**
 * Try to verify database connectivity (called once on startup
 * and again if connection was lost).
 */
async function checkDb(pool) {
  try {
    await pool.query('SELECT 1');
    if (!dbReady) console.log('[EVENT] Database connection OK');
    dbReady = true;
  } catch (err) {
    if (dbReady) console.error('[EVENT] Database connection lost:', err.message);
    dbReady = false;
  }
}

/**
 * Main event processing — call from poll loop.
 * Reads event registers, inserts to DB, writes ack.
 *
 * @param {object} modbusClient  Connected modbus-serial client
 * @param {object} pool          pg Pool instance (or null if DB disabled)
 */
async function processEvents(modbusClient, pool) {
  if (!pool) return;

  // Ensure DB is reachable
  if (!dbReady) {
    await checkDb(pool);
    if (!dbReady) return;
  }

  try {
    // 1. Read event output block (17 registers)
    const result = await modbusClient.readHoldingRegisters(EVENT_START, EVENT_COUNT);
    const r = result.data;

    const count = toSigned(r[0]);
    if (count === 0) return;               // queue empty

    const seq = toSigned(r[1]);
    if (seq === 0) return;                  // no valid message
    if (seq === lastAckedSeq) return;       // already processed this one

    const msgType = toSigned(r[2]);

    // 2. Reconstruct 32-bit unix timestamp
    const tsHi = r[3] & 0xFFFF;            // unsigned 16-bit
    const tsLo = r[4] & 0xFFFF;
    const unixSeconds = tsHi * 65536 + tsLo;
    const plcTs = new Date(unixSeconds * 1000);

    // 3. Payload fields (signed)
    const f = [];
    for (let i = 0; i < 12; i++) {
      f.push(toSigned(r[5 + i]));
    }

    // 4. Insert into PostgreSQL
    await pool.query(
      `INSERT INTO events (seq, msg_type, plc_ts, f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)`,
      [seq, msgType, plcTs, ...f]
    );

    // 5. Write ack_seq back to PLC (unsigned Modbus value)
    await modbusClient.writeRegisters(REG.iw_event_ack_seq, [seq & 0xFFFF]);
    lastAckedSeq = seq;

    const typeName = MSG_TYPE_NAMES[msgType] || `TYPE_${msgType}`;
    console.log(`[EVENT] ${typeName} seq=${seq} f=[${f.join(',')}] ts=${plcTs.toISOString()}`);

  } catch (err) {
    if (err.message && (err.message.includes('Port Not Open') || err.message.includes('Modbus'))) {
      return;  // Modbus error — handled by main reconnect logic
    }
    console.error('[EVENT] Error:', err.message);
    dbReady = false;  // Will re-check DB on next cycle
  }
}

module.exports = { processEvents, checkDb };
