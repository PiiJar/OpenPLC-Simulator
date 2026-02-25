# Unit Data Model

## Overview

A **Unit** is the physical carrier (e.g., barrel, rack, jig) that holds a batch during surface treatment. The transporter moves Units — not batches directly. A batch is always associated with a Unit when it is in the system.

## Data Structure

```json
{
  "unit_id": 1,
  "location": 101,
  "batch_id": null,
  "status": "used",
  "state": "empty",
  "target": "none"
}
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `unit_id` | `number` | Unique identifier (1, 2, 3, …). Displayed as zero-padded 3-digit string in UI (e.g., `001`, `012`). |
| `location` | `number` | Current physical location. `≥ 100` = station number, `< 100` = transporter ID. |
| `batch_id` | `number \| null` | The batch loaded in this Unit, or `null` if empty. |
| `status` | `string` | Whether the Unit is active in the system. See [Status](#status). |
| `state` | `string` | What the Unit currently contains / its processing state. See [State](#state). |
| `target` | `string` | Where the Unit is heading next. See [Target](#target). |

---

## Status

The `status` field indicates whether a Unit is active and available for use.

| Value | Description |
|-------|-------------|
| `used` | Unit is active and part of the production cycle. **Default.** |
| `not_used` | Unit is taken out of service (maintenance, damaged, spare). It will not be scheduled for transport. |

**UI:** Displayed as a checkbox ("Used") in the batch/unit form. In the station/transporter visualization the unit box border is:
- **Blue** (`#1565c0`) when `used`
- **Dark grey** (`#616161`) when `not_used`

---

## State

The `state` field describes what the Unit currently holds and its processing stage. It changes at loading/unloading/processing events.

| Value | Description |
|-------|-------------|
| `empty` | Unit has no batch (`batch_id = null`). Ready to be loaded. **Default.** |
| `loaded` | Unit has been loaded with a batch. Waiting for or undergoing treatment. |
| `processed` | Treatment is complete. Unit is ready to be unloaded. |

### State Transitions

```
empty ──[loading]──► loaded ──[treatment complete]──► processed ──[unloading]──► empty
```

**UI visualization:** The state is shown as a 4-character abbreviation at the bottom of the unit box:
- `EMPT` — empty
- `LOAD` — loaded
- `PROC` — processed

---

## Target

The `target` field indicates the next destination for the Unit. It is set by the scheduler when a transport task is assigned and cleared when the Unit arrives.

| Value | Description |
|-------|-------------|
| `none` | Unit is stationary, no pending movement. **Default.** |
| `to_loading` | Heading to a loading station to receive a batch. |
| `to_process` | Heading to the treatment line for processing. |
| `to_unloading` | Heading to an unloading station to release the batch. |
| `to_empty_buffer` | Heading to the empty units buffer/storage area. |
| `to_loaded_buffer` | Heading to the loaded units buffer/storage area. |
| `to_processed_buffer` | Heading to the processed units buffer/storage area. |

### Target Transitions (typical lifecycle)

```
                    ┌──────────────────────────────────────────────────────┐
                    │                                                      │
                    ▼                                                      │
  ┌─────────────────────────────────┐                                     │
  │  empty + none                   │  Idle in empty buffer               │
  │  (Unit at empty buffer station) │                                     │
  └──────────┬──────────────────────┘                                     │
             │ Scheduler assigns transport                                │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  empty + to_loading             │  Transporter picks up               │
  │  (Moving to loading station)    │                                     │
  └──────────┬──────────────────────┘                                     │
             │ Arrives at loading station, batch loaded                   │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  loaded + none                  │  At loading station                 │
  └──────────┬──────────────────────┘                                     │
             │ Line has capacity                                          │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  loaded + to_process            │  Transporter moves to line          │
  └──────────┬──────────────────────┘                                     │
             │ Arrives, treatment begins                                  │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  loaded + none                  │  In treatment (on line)             │
  │  (batch running through stages) │                                     │
  └──────────┬──────────────────────┘                                     │
             │ Treatment complete                                         │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  processed + none               │  Waiting for transport              │
  └──────────┬──────────────────────┘                                     │
             │ Scheduler assigns transport                                │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  processed + to_unloading       │  Moving to unloading station        │
  └──────────┬──────────────────────┘                                     │
             │ Arrives, batch unloaded                                    │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  empty + none                   │  At unloading station               │
  └──────────┬──────────────────────┘                                     │
             │ Scheduler sends to buffer                                  │
             ▼                                                            │
  ┌─────────────────────────────────┐                                     │
  │  empty + to_empty_buffer        │─────────────────────────────────────┘
  │  (Returning to empty buffer)    │
  └─────────────────────────────────┘
```

### Buffer Variants

Plants may have separate storage areas for different Unit states:

| Target | Used when |
|--------|-----------|
| `to_empty_buffer` | Returning an empty Unit to storage after unloading. |
| `to_loaded_buffer` | Parking a loaded Unit in a queue when the line is full. |
| `to_processed_buffer` | Parking a processed Unit when the unloading station is busy. |

**UI visualization:** When `target ≠ none`, an orange arrow and 4-character abbreviation is displayed next to the unit box:
- `→load` — to_loading
- `→proc` — to_process
- `→unlo` — to_unloading
- `→empt` — to_empty_buffer
- `→load` — to_loaded_buffer
- `→proc` — to_processed_buffer

---

## Location Convention

The `location` field uses the same numbering as `batch.location`:

| Range | Meaning | Example |
|-------|---------|---------|
| `≥ 100` | Station number | `101` = station 101 |
| `< 100` | Transporter ID | `1` = transporter 1 |

When a Unit moves, its `location` is updated and the associated `batch.location` shadow field is synchronized automatically.

---

## Setup File

Units are initialized from `unit_setup.json` in the plant directory. On system reset, this file is loaded and all Units are restored to their setup state.

Example (`unit_setup.json`):
```json
{
  "units": [
    { "unit_id": 1, "location": 101, "batch_id": null, "status": "used", "state": "empty", "target": "none" },
    { "unit_id": 2, "location": 102, "batch_id": null, "status": "used", "state": "empty", "target": "none" },
    { "unit_id": 3, "location": 103, "batch_id": null, "status": "used", "state": "empty", "target": "none" }
  ]
}
```

---

## API

### GET /api/units

Returns all current Units.

**Response:**
```json
{
  "units": [
    { "unit_id": 1, "location": 101, "batch_id": null, "status": "used", "state": "empty", "target": "none" },
    ...
  ]
}
```

### PUT /api/units/:id

Update a Unit's `location`, `status`, `state`, and/or `target`.

**Request body** (all fields optional):
```json
{
  "location": 114,
  "status": "used",
  "state": "loaded",
  "target": "to_process"
}
```

**Validation:**
- `status`: must be `"used"` or `"not_used"`
- `state`: must be `"empty"`, `"loaded"`, or `"processed"`
- `target`: must be `"none"`, `"to_loading"`, `"to_process"`, `"to_unloading"`, `"to_empty_buffer"`, `"to_loaded_buffer"`, or `"to_processed_buffer"`
- `location`: must be a finite number; target location must not be occupied by another Unit

**Response:**
```json
{
  "success": true,
  "unit": { "unit_id": 1, "location": 114, "batch_id": 5, "status": "used", "state": "loaded", "target": "to_process" }
}
```

---

## Relationship to Batch

- A Unit with `batch_id = null` is empty and available for loading.
- A Unit with `batch_id = N` carries batch N. The batch's `location` field is kept in sync as a shadow copy of the Unit's `location`.
- The transporter only interacts with Units. Batch movement is always implicit through Unit movement.

### Adapter Functions (server.js)

| Function | Purpose |
|----------|---------|
| `getUnitByBatchId(units, batchId)` | Find which Unit carries a given batch |
| `getUnitAtLocation(units, location)` | Find which Unit is at a given location |
| `isLocationOccupied(units, location)` | Check if a location has a Unit |
| `getBatchLocation(units, batchId)` | Get batch location via its Unit |
| `setUnitLocation(units, unitId, newLocation)` | Move a Unit to a new location |
| `attachBatchToUnit(units, unitId, batchId)` | Load a batch into a Unit |
| `detachBatchFromUnit(units, unitId)` | Unload a batch from a Unit |

---

## Station Operations Related to Units

The `station.operation` field in `stations.json` is an integer. In addition to the existing process-line operations (0 = dry, 1 = wet, 10 = dry cross-transfer, 11 = wet cross-transfer), the following operations are defined for unit handling and buffer stations.

**All unit-related station operations are dry** — the transporter uses dry z-movement parameters (slow distance, speed change limits) when lifting from or sinking to these stations.

### Complete Station Operation Table

| Operation | Name | Wet/Dry | Description |
|------|------|---------|-------------|
| 0 | Normal dry | Dry | Standard dry process station (buffer, dryer, etc.) |
| 1 | Normal wet | Wet | Standard wet process station (treatment tank) |
| 10 | Cross-transfer dry | Dry | Dry cross-transfer conveyor station |
| 11 | Cross-transfer wet | Wet | Wet cross-transfer conveyor station |
| **20** | **Loading** | **Dry** | **Station where batches are loaded into Units** |
| **21** | **Unloading** | **Dry** | **Station where batches are unloaded from Units** |
| **22** | **Loading/Unloading** | **Dry** | **Combined loading and unloading station** |
| **30** | **Buffer** | **Dry** | **Generic buffer / waiting area** |
| **31** | **Empty buffer** | **Dry** | **Storage area for empty Units (no batch)** |
| **32** | **Loaded buffer** | **Dry** | **Storage area for loaded Units waiting for line access** |
| **33** | **Processed buffer** | **Dry** | **Storage area for processed Units waiting for unloading** |

### Unit-Related Types Detail

#### Loading (type 20)

Station where an operator or automated system places a batch into an empty Unit.

- Unit arrives with `state: "empty"`, `batch_id: null`
- Unit departs with `state: "loaded"`, `batch_id: N`

#### Unloading (type 21)

Station where a batch is removed from a processed Unit.

- Unit arrives with `state: "processed"`, `batch_id: N`
- Unit departs with `state: "empty"`, `batch_id: null`

#### Loading/Unloading (type 22)

Combined station that can perform both loading and unloading. Common in smaller plants where a single station serves as both entry and exit point.

- Can accept empty Units for loading **or** processed Units for unloading

#### Buffer (type 30)

Generic buffer/parking station with no specific role. Used when a Unit needs to wait but doesn't fall into a specific category.

#### Empty buffer (type 31)

Dedicated storage for empty Units. After a Unit is unloaded, it can be returned here to wait for the next loading assignment.

- Expected Unit state: `state: "empty"`, `batch_id: null`
- Corresponds to Unit target: `to_empty_buffer`

#### Loaded buffer (type 32)

Dedicated storage for loaded Units that are waiting for the treatment line to become available.

- Expected Unit state: `state: "loaded"`, `batch_id: N`
- Corresponds to Unit target: `to_loaded_buffer`

#### Processed buffer (type 33)

Dedicated storage for processed Units that are waiting for the unloading station to become available.

- Expected Unit state: `state: "processed"`, `batch_id: N`
- Corresponds to Unit target: `to_processed_buffer`

### Mapping: Unit Target → Station Type

| Unit target | Destination station type |
|-------------|------------------------|
| `to_loading` | 20 (Loading) or 22 (Loading/Unloading) |
| `to_unloading` | 21 (Unloading) or 22 (Loading/Unloading) |
| `to_process` | 0 (process line stations) |
| `to_empty_buffer` | 31 (Empty buffer) |
| `to_loaded_buffer` | 32 (Loaded buffer) |
| `to_processed_buffer` | 33 (Processed buffer) |

### Z-Movement Classification

The `isWetStation()` function determines z-movement speed parameters based on station `kind`:

```javascript
// Wet stations (kind === 1): use z_slow_distance_wet_mm, z_speed_change_limit_wet_mm
const isWetStation = (station) => (Number(station.kind) || 0) === 1;

// Dry stations (kind === 0): use z_slow_distance_dry_mm, z_speed_change_limit_dry_mm
```

The `kind` field is independent of `operation` — it is set directly in `stations.json`.
