-- ============================================================
-- init.sql — PLC event database schema
-- ============================================================
-- Automatically executed by PostgreSQL Docker on first start.
-- Stores all PLC events in a single generic table.
-- Decoded views provide msg_type-specific column names.
-- ============================================================

CREATE TABLE IF NOT EXISTS events (
  id          SERIAL PRIMARY KEY,
  seq         INT NOT NULL,                     -- PLC sequence number (1..32000)
  msg_type    INT NOT NULL,                     -- 1=TASK_DISPATCHED, 2=LIFT
  plc_ts      TIMESTAMPTZ NOT NULL,             -- PLC-side unix timestamp
  f1          INT, f2  INT, f3  INT, f4  INT,
  f5          INT, f6  INT, f7  INT, f8  INT,
  f9          INT, f10 INT, f11 INT, f12 INT,
  received_at TIMESTAMPTZ DEFAULT NOW()         -- gateway receive time
);

-- Index for fast time-range queries
CREATE INDEX IF NOT EXISTS idx_events_plc_ts ON events (plc_ts);
CREATE INDEX IF NOT EXISTS idx_events_msg_type ON events (msg_type);

-- ============================================================
-- VIEW: task_dispatched
-- msg_type = 1: Task assigned to transporter by DispatchTask FB
-- ============================================================
CREATE OR REPLACE VIEW task_dispatched AS
SELECT
  id, seq, plc_ts, received_at,
  f1              AS transporter_id,
  f2              AS unit_id,
  f3              AS lift_station,
  f4              AS sink_station,
  f5              AS stage,            -- 0 = NTT (no-treatment task)
  f6              AS batch_code,
  f7              AS batch_state,      -- 0=not_processed, 1=in_process, 2=processed
  f8              AS batch_program,
  f9              AS target,           -- 0=none,1=loading,2=buffer,3=process,4=unload,5=avoid
  f10             AS calc_time_s,
  f11             AS min_time_s,
  f12             AS max_time_s
FROM events
WHERE msg_type = 1;

-- ============================================================
-- VIEW: lift_events
-- msg_type = 2: Transporter lifts unit from station
-- ============================================================
CREATE OR REPLACE VIEW lift_events AS
SELECT
  id, seq, plc_ts, received_at,
  f1              AS transporter_id,
  f2              AS unit_id,
  f3              AS station,
  f4              AS batch_code,
  f5              AS batch_state,
  f6              AS batch_program,
  f7              AS stage,
  f8              AS actual_time_s,   -- how long unit was at station (seconds)
  f9              AS calc_time_s,
  f10             AS min_time_s,
  f11             AS max_time_s
FROM events
WHERE msg_type = 2;

-- ============================================================
-- TABLE: sim_log
-- Simulation lifecycle log (reset, start, stop, etc.)
-- Used to correlate PLC events with production runs.
-- ============================================================
CREATE TABLE IF NOT EXISTS sim_log (
  id          SERIAL PRIMARY KEY,
  event       TEXT NOT NULL,           -- 'RESET', 'PRODUCTION_START', 'PRODUCTION_STOP', ...
  customer    TEXT,
  plant       TEXT,
  detail      JSONB,                   -- optional extra data (e.g. queue status)
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sim_log_created ON sim_log (created_at);
CREATE INDEX IF NOT EXISTS idx_sim_log_event   ON sim_log (event);
