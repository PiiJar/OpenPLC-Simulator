# Transporter Event Database — Toteutusehdotus

## Yleiskuva

PostgreSQL-tietokanta omassa Docker-kontissa. PLC kerää tapahtumat sisäiseen viestijonoon. Gateway lukee ylimmän viestin Modbusista, tallentaa kantaan ja kuittaa. PLC-tarkka aikaleima, ei menetettyjä tapahtumia.

## Arkkitehtuuri

```
┌──────────┐    Modbus    ┌──────────┐      SQL      ┌──────────┐
│  OpenPLC  │◄──────────►│  Gateway  │──────────────►│ Postgres │
│ (PLC)     │   TCP:502   │ (Node.js)│   TCP:5432    │ (Docker) │
│           │             │          │               │          │
│ event_queue             │          │               │          │
│ [1..10]   │──── QW ───►│ read top │               │          │
│           │◄─── IW ────│ ack_seq  │               │          │
└──────────┘              └──────────┘               └──────────┘
```

## Viestijonon rakenne (PLC)

### Tyypit (`types.st`)

```
EVENT_MSG_T:
  seq      : INT          — juokseva järjestysnumero
  msg_type : INT          — 1=task, 2=lift, ...
  ts_hi    : INT          — aikaleima ylempi 16-bit
  ts_lo    : INT          — aikaleima alempi 16-bit
  f[1..12] : INT          — hyötykuorma (merkitys riippuu msg_type)

EVENT_QUEUE_T:
  count    : INT          — viestejä jonossa (0..10)
  head     : INT          — vanhin viesti (1-pohjainen indeksi)
  next_seq : INT          — seuraava sekvenssunumero
  buf[1..10] : EVENT_MSG_T — kiertävä puskuri
```

### Kättelymekanismi

```
Modbus output (PLC → Gateway):  16 rekisteriä
  [0] count          — montako viestiä jonossa
  [1] seq            — ylimmän viestin sekvenssunumero
  [2] msg_type       — viestin tyyppi
  [3] ts_hi          — aikaleima hi
  [4] ts_lo          — aikaleima lo
  [5..16] f[1..12]   — hyötykuorma

Modbus input (Gateway → PLC):   1 rekisteri
  [0] ack_seq        — kuittaus: gatewayn viimeksi käsittelemä seq

Sykli:
  1. PLC: tapahtuma syntyy → enqueue(msg_type, f1..f12)
     - tail := ((head - 1 + count) MOD 10) + 1
     - buf[tail].seq := next_seq; next_seq++; count++
     - Kopioi buf[head] kentät QW-rekistereihin

  2. Gateway: lukee Modbus, näkee count > 0
     - Lukee seq, msg_type, ts, f[1..12]
     - INSERT INTO tasks/lifts kantaan
     - Kirjoittaa ack_seq := seq Modbusiin

  3. PLC: näkee ack_seq = buf[head].seq
     - head := (head MOD 10) + 1
     - count--
     - Kopioi uusi buf[head] QW-rekistereihin (tai count=0 → nollat)

  Jos jono täynnä (count=10): uusi tapahtuma hylätään (tai ylikirjoitetaan vanhin).
```

### Viestityyppi: TASK_DISPATCHED (msg_type=1)

Tallennetaan kun DispatchTask asettaa tehtävän nostimelle.

| field | sisältö |
|-------|---------|
| f[1]  | transporter_id |
| f[2]  | unit_id |
| f[3]  | lift_station |
| f[4]  | sink_station |
| f[5]  | stage (0=NTT) |
| f[6]  | batch_code |
| f[7]  | batch_state |
| f[8]  | batch_program |
| f[9]  | target |
| f[10] | calc_time ×10 |
| f[11] | min_time ×10 |
| f[12] | max_time ×10 |

### Viestityyppi: LIFT (msg_type=2)

Tallennetaan kun nostin aloittaa noston (phase → 2).

| field | sisältö |
|-------|---------|
| f[1]  | transporter_id |
| f[2]  | unit_id |
| f[3]  | station |
| f[4]  | batch_code |
| f[5]  | batch_state |
| f[6]  | batch_program |
| f[7]  | stage |
| f[8]  | actual_time ×10 (g_time_s - change_time) |
| f[9]  | calc_time ×10 |
| f[10] | min_time ×10 |
| f[11] | max_time ×10 |
| f[12] | varattu |

## Modbus-rekisterit

Tarvitaan:
- **Output (PLC → Gateway):** 16 rekisteriä (count + seq + msg_type + ts_hi + ts_lo + f[1..12] = 17, pyöristetään 17)
- **Input (Gateway → PLC):** 1 rekisteri (ack_seq)
- **Yhteensä:** 18 rekisteriä

Nykyinen käyttö: 737 / 1024. Jälkeen: 755 / 1024. Vapaata jää 269.

## Toteutusvaiheet

### 1. Modbus-kartta (`modbus_map.json`)
- Lisää output-blokki `event_out` (17 rekisteriä)
- Lisää input-blokki `event_ack` (1 rekisteri)
- Aja `generate_modbus.py`

### 2. PLC: Globaalit (`globals.st`)
- `g_event : EVENT_QUEUE_T;` — sisäinen jono
- QW-output: event-kentät
- IW-input: ack_seq

### 3. PLC: Jonon hallinta (`STC_FB_EventQueue.st`)
Uusi function block:
- `enqueue(msg_type, ts, f1..f12)` — lisää jonoon
- Joka sykli: tarkista ack, kopioi head → QW
- Kutsu: MainScheduler kutsuu joka syklillä

### 4. PLC: Tapahtumien luonti
- **DispatchTask**: enqueue(1, ...) kun tehtävä asetetaan nostimelle
- **RunTasks**: enqueue(2, ...) kun phase muuttuu 2:ksi (nosto)

### 5. Docker: PostgreSQL
- `plc_db` service docker-compose.yml:ään
- `openplc/db/init.sql` taulujen luonti

### 6. Gateway: DB-kirjoitus
- `pg`-kirjasto, `db.js`-moduuli
- Pollausloopissa: lue event-rekisterit, jos count > 0 → INSERT → kirjoita ack_seq

## Avoimet kysymykset

1. **Jonon ylivuoto (count=10)**: hylätäänkö uusi viesti vai ylikirjoitetaanko vanhin?
2. **Pitääkö sink-tapahtuma (phase→4) tallentaa myös?**
3. **REST-rajapinta** kantadatan kyselyyn?
4. **Retention**: pidetäänkö data ikuisesti vai siivolaanko?
