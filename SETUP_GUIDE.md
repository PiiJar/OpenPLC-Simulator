# OpenPLC Simulator — Projektin kokoonpano-ohje

> Tämä ohje kuvaa koko järjestelmän asennuksen tyhjältä koneelta.
> Tarkoitettu AI-agentille tai kehittäjälle, joka haluaa pystyttää identtisen ympäristön.

---

## 1. Yleiskuva

Järjestelmä simuloi Galvatekin pintakäsittelylinjan PLC-ohjausta. Se koostuu neljästä Docker-kontista:

| Kontti | Portti | Tehtävä |
|--------|--------|---------|
| `openplc_v3` | 8080 | OpenPLC v3 Runtime — ajaa IEC 61131-3 ST-ohjelmaa, tarjoaa Modbus TCP (502) |
| `plc_gateway` | 3001 | Node.js Gateway — REST API + Modbus-master, ohjaa PLC:tä, palvelee UI:ta |
| `plc_db` | 5432 | PostgreSQL 16 — tapahtumaloki (events, sim_log) |
| `plc_ui` | 5173 | React/Vite UI — visualisoi laitteiston reaaliaikaisesti (nginx) |

```
┌──────────┐    REST    ┌──────────┐  Modbus TCP  ┌──────────┐
│  Browser  │ ───3001──→ │  Gateway │ ────502────→ │  OpenPLC │
│  (UI)     │ ←──json──  │  (Node)  │ ←─registers─ │  (ST)    │
└──────────┘            └──────────┘              └──────────┘
     │                       │
     └──5173 (nginx)         └──5432──→ PostgreSQL
```

### Docker-verkko

Docker Compose luo automaattisesti bridge-verkon (`openplcsimulator_default`). Kontit näkevät toisensa nimillä:
- Gateway → PLC: `openplc:502` (Modbus) ja `openplc:8443` (HTTPS API)
- Gateway → DB: `plc_db:5432`

Hostilta suoraan PLC:hen (esim. debug_read.py): käytä kontin IP:tä (tyypillisesti `172.22.0.4`).

---

## 2. Edellytykset

### Kone
- Linux (Ubuntu 22.04+ suositeltu) tai macOS
- 4 GB RAM minimi (OpenPLC-kontin build vie ~1 GB)
- Docker Engine 24+ ja Docker Compose v2

### Ohjelmistot
```bash
# Docker
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
# Uudelleenkirjautuminen tarvitaan

# Python 3.10+ (ST-koodigeneraattoreille ja debug-skripteille)
sudo apt-get install -y python3 python3-pip python3-venv

# pyModbusTCP (debug_read.py tarvitsee)
pip3 install pyModbusTCP
```

---

## 3. Repositorion kloonaus

```bash
git clone https://github.com/PiiJar/OpenPLC-Simulator.git
cd OpenPLC-Simulator
```

### Hakemistorakenne (tärkeimmät)
```
.
├── docker-compose.yml          # 4 kontin määritys
├── Dockerfile                  # OpenPLC-kontin build (Ubuntu 22.04)
├── deploy_plc.sh               # ST-koodin rakennus + upload + käännös + uudelleenkäynnistys
├── debug_read.py               # Modbus TCP debug-lukija (suoraan PLC:ltä)
│
├── openplc/
│   ├── OpenPLC/
│   │   ├── src/                # ← IEC 61131-3 ST-lähdekoodi (kaikki .st-tiedostot)
│   │   ├── to_editor/          # ← build_plcxml.py:n tuottama plc.xml + build/plc.st
│   │   ├── build_plcxml.py     # src/*.st → plc.xml → build/plc.st (yhdistäjä)
│   │   ├── apply_plant_config.py  # plant_config.json → globals.st + types.st patchaus
│   │   └── plant_config.json   # laitteiston rajoitteet (MAX_UNITS, MAX_TRANSPORTERS jne.)
│   │
│   ├── gateway/                # Node.js Gateway -palvelimen lähdekoodi
│   │   ├── Dockerfile
│   │   ├── package.json        # express, modbus-serial, pg, cors
│   │   ├── index.js            # Pääohjelma: REST API + Modbus polling
│   │   ├── modbus_map.js       # Auto-generoitu rekisterikartta
│   │   ├── production_dispatcher.js  # Erien ajastus tuotantojonosta
│   │   ├── event_consumer.js   # PLC-tapahtumien tallennus PostgreSQL:ään
│   │   ├── file_routes.js      # Tiedostopohjainen API (customers, plants)
│   │   ├── legacy_stubs.js     # Vanhojen API-päätepisteiden tyngät
│   │   └── db.js               # PostgreSQL pool
│   │
│   ├── db/
│   │   └── init.sql            # Tietokannan skeema (events, sim_log, viewit)
│   │
│   ├── generate_modbus.py      # modbus_map.json → globals.st + plc_prg.st + modbus_map.js
│   └── modbus_map.json         # Modbus-rekisterien lähdetotuus (755 rekisteriä)
│
├── customers/                  # Asiakaslaitteistojen konfiguraatiot
│   └── <Asiakas>/
│       └── <Tehdas>/
│           ├── customer.json           # Asiakastiedot
│           ├── stations.json           # Asemat (numero, sijainti, tyyppi)
│           ├── transporters.json       # Kuljettimien fysiikka
│           ├── tanks.json              # Tankkien data
│           ├── unit_setup.json         # Yksiköiden alkuasetelma
│           ├── no_treatment_tasks.json # Ei-tuotanto kuljetustehtävät
│           ├── movement_times.json     # Esikalkuloidut matka-ajat
│           ├── treatment_program_001.csv  # Käsittelyohjelma (CSV)
│           └── layout_config.json      # UI-asettelukonfiguraatio
│
├── plant_templates/            # Geneeristen laitteistojen pohjat
│   ├── 1_One_Line_One_2D_Transporter/
│   ├── 2_One_Line_Two_2D_Transporters/
│   └── ...
│
├── runtime/                    # Ajonaikainen tila (generoituu, .gitignore)
│   ├── production_queue.json   # Tuotantojono
│   ├── production_setup.json   # Tuotantoasetukset
│   ├── batches.json            # Aktiiviset erät
│   └── Batch_*.csv             # Kopioidut käsittelyohjelmat
│
└── PLC Simulator/              # Vanha JS-simulaattori (referenssi)
    ├── sim-core/               # taskScheduler.js, departureScheduler.js
    └── visualization/          # React/Vite UI (oma Dockerfile)
```

---

## 4. Kontit: rakentaminen ja käynnistys

### 4.1 Ensimmäinen käynnistys

```bash
cd OpenPLC-Simulator
docker compose up -d --build
```

Tämä:
1. **Rakentaa OpenPLC-kontin** (`Dockerfile`):
   - Ubuntu 22.04 + git + python3 + build-essential
   - Kloonaa `thiagoralves/OpenPLC_v3` ja ajaa `install.sh linux`
   - Kesto: ~5–10 min ensimmäisellä kerralla (käännös)
2. **Rakentaa Gateway-kontin** (`openplc/gateway/Dockerfile`):
   - Node.js 20 Alpine + npm ci
3. **Vetää PostgreSQL** (`postgres:16-alpine`)
4. **Rakentaa UI-kontin** (`PLC Simulator/visualization/Dockerfile`):
   - Vite build → nginx

### 4.2 Tarkistus

```bash
docker ps
# Pitäisi näkyä 4 konttia: openplc_v3, plc_gateway, plc_db, plc_ui

# OpenPLC web UI:
curl -s http://localhost:8080/login | head -5

# Gateway API:
curl -s http://localhost:3001/api/status | python3 -m json.tool
```

### 4.3 OpenPLC-kirjautumistiedot

| Kenttä | Arvo |
|--------|------|
| Username | `PiiJar` |
| Password | `!T0s1v41k33!` |

Nämä asetetaan ensimmäisellä kirjautumisella OpenPLC web UI:ssa (http://localhost:8080).
Gateway käyttää samoja tunnuksia HTTPS API:ssa (`PLC_API_USER` / `PLC_API_PASS` docker-compose.yml:ssä).

---

## 5. PLC-ohjelman ensikäyttöönotto

OpenPLC-kontti käynnistyy tyhjänä. Sinne täytyy ladata ST-ohjelma.

### 5.1 Ensimmäinen ohjelma (manuaalisesti)

1. Avaa http://localhost:8080 selaimessa
2. Kirjaudu sisään (PiiJar / !T0s1v41k33!)
3. Klikkaa "Programs" → "Upload Program"
4. Lataa tiedosto `openplc/OpenPLC/to_editor/plc.xml`
   - (Tämä on XML-muoto, jonka OpenPLC Editor/Runtime ymmärtää)
5. Anna ohjelmalle nimi ja klikkaa "Upload"
6. Klikkaa "Dashboard" → "Start PLC"

### 5.2 Ohjelman generointi (build-pipeline)

ST-lähdekoodit ovat `openplc/OpenPLC/src/`-hakemistossa. Ne yhdistetään kahden Python-skriptin kautta:

```bash
cd openplc/OpenPLC

# 1. Patchaa globals.st + types.st plant_config.json:n mukaan
python3 apply_plant_config.py

# 2. Yhdistä kaikki .st-tiedostot → to_editor/plc.xml + to_editor/build/plc.st
python3 build_plcxml.py
```

Tuottaa:
- `to_editor/plc.xml` — PLCopen TC6 XML (ladattavissa OpenPLC editoriin)
- `to_editor/build/plc.st` — Yhdistetty ST-tiedosto (suoraan PLC:lle)

---

## 6. Deploy-prosessi (deploy_plc.sh)

Kun ST-koodia muutetaan, `deploy_plc.sh` hoitaa koko ketjun:

```bash
bash deploy_plc.sh
```

Skripti tekee automaattisesti:
1. `apply_plant_config.py` — patchaa rajoitteet
2. `build_plcxml.py` — generoi yhdistetty ST
3. Pysäyttää PLC runtimen (HTTP API: `/stop_plc`)
4. Kopioi `build/plc.st` → kontin `/home/openplc/OpenPLC_v3/webserver/st_files/<active>.st`
5. Ajaa `compile_program.sh` kontissa (ST → C → binary: matiec + gcc)
6. Käynnistää PLC runtimen (`/start_plc`)

### Vaatimukset
- OpenPLC-kontti käynnissä
- Vähintään yksi ohjelma ladattu aiemmin (active_program tiedosto olemassa)

---

## 7. Modbus-rekisterikartan generointi

Koko PLC ↔ Gateway -kommunikaatio perustuu yhteen totuuslähteeseen:

```bash
cd openplc
python3 generate_modbus.py
```

Lukee `modbus_map.json` ja tuottaa:
1. **`OpenPLC/src/globals.st`** — `%QW`/`%IW` Modbus-muuttujat (markers-väliin)
2. **`OpenPLC/src/plc_prg.st`** — output-kirjoitukset (markers-väliin)
3. **`gateway/modbus_map.js`** — rekisteriosoitteet + dekoodaus Node.js:lle

Generoidut osuudet merkitään kommenteilla:
```
(* --- BEGIN GENERATED MODBUS --- *)
...
(* --- END GENERATED MODBUS --- *)
```

**Tätä ajetaan vain kun modbus_map.json muuttuu** (uusia rekistereitä, lohkoja tms.).

---

## 8. Asiakaslaitteiston konfigurointi

### 8.1 Tiedostorakenne

Jokaisella asiakas/tehdas-yhdistelmällä on hakemisto `customers/<Asiakas>/<Tehdas>/`:

| Tiedosto | Kuvaus |
|----------|--------|
| `stations.json` | Asemat: numero (101–130), sijainti (x,y,z mm), tyyppi, operaatio |
| `transporters.json` | Kuljettimien fysiikka (nopeus, kiihtyvyys, Z-liike), task_areas |
| `tanks.json` | Tankkien fysiikka |
| `unit_setup.json` | Yksiköiden alkuasetelma (sijainti, tila) |
| `no_treatment_tasks.json` | Per-target kuljettimen valinta (to_loading, to_buffer jne.) |
| `movement_times.json` | Esikalkuloidut nosto/lasku/matka-ajat per asema-pari |
| `treatment_program_*.csv` | Käsittelyohjelma: Stage, MinStat, MaxStat, MinTime, MaxTime, CalcTime |
| `customer.json` | Asiakastiedot, tuotantoaikataulu |
| `simulation_purpose.json` | Simulaation tavoitteet ja rajoitteet |

### 8.2 Käsittelyohjelma CSV-formaatti

```csv
Stage,MinStat,MaxStat,MinTime,MaxTime,CalcTime
1,115,115,00:02:00,00:03:00,00:02:00
2,116,116,00:02:30,00:03:30,00:02:30
12,104,106,00:22:00,00:40:00,00:22:00
```

- **Stage**: Vaihenumero (1-pohjainen)
- **MinStat–MaxStat**: Vaihtoehtoisten asemien alue (jos 104–106 → asemat 104, 105, 106)
- **MinTime, MaxTime, CalcTime**: Aika-argumentit (HH:MM:SS tai sekunteja)

### 8.3 Reset (laitteiston lataus PLC:hen)

```bash
curl -X POST http://localhost:3001/api/reset \
  -H "Content-Type: application/json" \
  -d '{"customer":"Nammo Lapua Oy","plant":"Factory X Zinc Phosphating"}'
```

Gateway lukee customers-hakemiston ja kirjoittaa Modbusilla PLC:hen:
1. **clear_all** — tyhjentää PLC:n globaalit
2. **Upload stations** — asema kerrallaan (cmd=1)
3. **Upload transporters** — fysiikka-sivut (cmd=4,5) + task_areas (cmd=6)
4. **Upload units** — sijainti, tila
5. **Upload NTT** — ei-käsittely-tehtävien kohdeasemat
6. **Upload movement_times** — matka-aikataulukko
7. **Upload avoid_status** — asemien välttely

---

## 9. Tuotantojonon käynnistys

```bash
# Aktivoi tuotantojono (gateway alkaa lähettää eriä PLC:lle)
curl -X POST http://localhost:3001/api/production-queue \
  -H "Content-Type: application/json" \
  -d '{"value":1}'
```

Gateway:
1. Lukee `runtime/production_queue.json`
2. Etsii yksikön start_station-asemalla (USED, TO_NONE, ei erää)
3. Kirjoittaa erädatan PLC:hen (batch header + treatment program stages)
4. PLC:n TSK+DEP -ajastus aktivoi erän

---

## 10. Gateway REST API — tärkeimmät päätepisteet

| Metodi | Polku | Kuvaus |
|--------|-------|--------|
| `POST` | `/api/reset` | Lataa asiakaslaitteisto PLC:hen |
| `POST` | `/api/production-queue` | Käynnistä/pysäytä tuotantojono (`{value:1/0}`) |
| `GET` | `/api/status` | PLC:n tila (kuljettimen sijainnit, erät, ajastus) |
| `GET` | `/api/transporters` | Kuljettimien live-tila |
| `GET` | `/api/units` | Yksiköiden tila |
| `GET` | `/api/batches` | Erien tila |
| `GET` | `/api/schedule` | Ajastuksen tila |
| `GET` | `/api/tasks` | Tehtäväjonot |
| `GET` | `/api/dep-state` | Departure schedulerin tila |
| `GET` | `/api/customers` | Asiakaslistaus |
| `GET` | `/api/customers/:customer/plants` | Tehtaat |

---

## 11. ST-koodin arkkitehtuuri

### 11.1 Tiedostojen nimeämiskäytäntö

| Etuliite | Tarkoitus |
|----------|-----------|
| `STC_FB_` | **S**ha**T**ared **C**ommon — yhteiskäyttöiset FB:t |
| `TSK_FB_` | **T**a**SK** scheduler — tehtäväajastuksen FB:t |
| `DEP_FB_` | **DEP**arture scheduler — lähtöajastuksen FB:t |
| `SIM_FB_` | **SIM**ulation — fysiikkasimulaation FB:t |
| `TWA_`    | **T**ransporter **W**orking **A**rea — työalueen laskennat |

### 11.2 Erikoistiedostot

| Tiedosto | Rooli |
|----------|-------|
| `types.st` | Kaikki TYPE … END_TYPE -määrittelyt (STATION_T, BATCH_T, UNIT_T jne.) |
| `globals.st` | Globaalit muuttujat + Modbus I/O (%QW/%IW) |
| `config.st` | PLC konfiguraatio: TASK (20ms cycle), PROGRAM PLC_PRG |
| `plc_prg.st` | Pääohjelma: alustus, ajanlasku, write handlerit, Modbus output |

### 11.3 Ajastusarkkitehtuuri

```
PLC_PRG (20ms sykli)
  ├── SIM_FB_ClearConfig      — laitteiston alustus
  ├── STC_FB_CalcMoveTimes    — matka-aikojen laskenta
  ├── STC_FB_MainScheduler    — TSK + DEP vuorotteleva ajastus
  │     ├── TSK_FB_Scheduler  — pääajastus (aikataulut → tehtävät → ristiriidat)
  │     ├── DEP_FB_Scheduler  — lähtöajastus (erän aktivointi)
  │     └── STC_FB_DispatchTask — tehtävien jako kuljettimille
  ├── SIM_FB_RunTasks         — kuljettimien fysiikkasimulaatio (X/Z-liike)
  ├── STC_FB_Calibrate        — kalibrointifunktio
  └── STC_FB_EventQueue       — tapahtumien lähetys Modbusilla
```

MainScheduler vuorottelee TSK ja DEP -ajastimia eri PLC-sykleillä:
- **TSK** (Task Scheduler): laskee aikataulut, luo tehtävät, ratkaisee ristiriidat
- **DEP** (Departure Scheduler): aktivoi waiting-eriä idle-slotteihin

Kommunikaatio tapahtuu `g_dep_pending` -rakenteen kautta:
1. DEP asettaa `g_dep_pending.valid := TRUE` + erän tiedot
2. MainScheduler pidättää DEP:n kunnes TSK käsittelee pendingin
3. TSK kopioi pending-datan globaaleihin ja aloittaa uudelleenlaskennan

### 11.4 Tärkeimmät tietotyypit

| Tyyppi | Kuvaus |
|--------|--------|
| `BATCH_T` | Erä: batch_code, cur_stage, state (0=NOT_PROCESSED, 1=IN_PROCESS, 2=PROCESSED), prog_id, start_time, min_time, max_time, cal_time |
| `UNIT_T` | Yksikkö: location (asema), status (USED/NOT_USED), state, target |
| `STATION_T` | Asema: sijainti, tyyppi (dry/wet), operaatio, change_time |
| `TREATMENT_PROGRAM_T` | Käsittelyohjelma: program_id + stages[1..30] |
| `PROGRAM_STAGE_T` | Vaihe: stations[1..5], min_time, max_time, cal_time |
| `TSK_SCHEDULE_T` | Aikataulun vaihe: start_time, end_time, station |
| `TSK_TASK_T` | Kuljetustehtävä: start_time, lift/sink -asema, unit |
| `STC_TRANSPORTER_T` | Kuljetin: sijainti (x_mm, z_mm), nopeus, tila |

---

## 12. plant_config.json — laitteiston rajoitteet

```json
{
  "plant_name": "Galvatek 1-Line 2-Transporter",
  "MAX_LINES": 1,
  "MAX_STATIONS_PER_LINE": 30,
  "MAX_TRANSPORTERS_PER_LINE": 3,
  "MAX_TRANSPORTERS": 3,
  "MAX_UNITS": 10,
  "MAX_PARALLELS": 5,
  "MAX_STAGES": 30,
  "DEP_MAX_IDLE_SLOTS": 20,
  "DEP_MAX_DELAY_ACTS": 20,
  "DEP_MAX_WAITING": 5
}
```

`apply_plant_config.py` patchaa nämä arvot `globals.st`:n vakioihin ja `types.st`:n taulukkokokoihin.
Jos laitteisto vaihtuu (lisää linjoja, asemia), muuta `plant_config.json` ja aja deploy uudelleen.

---

## 13. Debug-työkalut

### 13.1 debug_read.py

Lukee PLC:n Modbus-rekistereitä suoraan (ohittaa gatewayn):

```bash
# Edellyttää: pip install pyModbusTCP
# PLC:n Docker-IP (tarkista: docker network inspect)
python3 debug_read.py          # 30 näytettä, 0.3s välein
python3 debug_read.py 100 0.5  # 100 näytettä, 0.5s välein
```

Näyttää:
- `dep_ph` — Departure scheduler phase (1=WAIT, 8000=ACTIVATE, 8100=DONE)
- `tsk_ph` — Task scheduler phase (10000=READY, 10100=CHECK_DEP)
- `pend` — onko pending-dataa (1/0)
- `b1_st_dbg` — batch 1 state
- `b1=[code, state, prog, stg]` — erän tiedot
- `dep=[act, stab, wait, ovl, pv, pu]` — DEP:n tila

### 13.2 Gateway-lokit

```bash
docker logs -f plc_gateway
```

### 13.3 OpenPLC-lokit

```bash
docker logs -f $(docker ps --format '{{.Names}}' | grep openplc_v3)
```

### 13.4 PLC Dashboard

http://localhost:8080 — Näyttää PLC-ohjelman tilan, monitorin, lokit.

### 13.5 Visualization UI

http://localhost:5173 — React/D3-pohjainen reaaliaikavisualisaatio.

---

## 14. Tyypillinen kehitystyönkulku

```bash
# 1. Muokkaa ST-koodia
vim openplc/OpenPLC/src/DEP_FB_Scheduler.st

# 2. Deploy PLC:hen (build + upload + compile + restart)
bash deploy_plc.sh

# 3. Lataa laitteisto
curl -s -X POST http://localhost:3001/api/reset \
  -H "Content-Type: application/json" \
  -d '{"customer":"Nammo Lapua Oy","plant":"Factory X Zinc Phosphating"}'

# 4. Käynnistä tuotanto
sleep 3
curl -s -X POST http://localhost:3001/api/production-queue \
  -H "Content-Type: application/json" \
  -d '{"value":1}'

# 5. Seuraa tilaa
sleep 5
python3 debug_read.py 30 0.5

# 6. Tai katso selaimesta
open http://localhost:5173
```

---

## 15. Modbus-rekisterikartan rakenne

`modbus_map.json` sisältää 755 rekisteriä seuraavissa lohkoissa:

| Lohko | Suunta | Osoite | Kpl | Kuvaus |
|-------|--------|--------|-----|--------|
| `transporter_state` | out | 0–38 | 39 | Kuljettimien x/z/nopeus/vaihe |
| `transporter_extended` | out | 39–77 | 39 | Tehtävä-/työskentelytiedot |
| `twa_limits` | out | 78–83 | 6 | Työalueen rajat |
| `plc_status` | out | 84–95 | 12 | PLC:n yleistila |
| `unit_state` | out | 96–125 | 30 | Yksiköiden tila |
| `batch_state` | out | 126–165 | 40 | Erien tila |
| `schedule_summary` | out | 306–315 | 10 | Aikataulu + debug |
| `task_queue` | out | 316–648 | 333 | Tehtäväjonot |
| `dep_state` | out | 649–657 | 9 | DEP:n tila |
| `cmd_transport` | **in** | 693–698 | 6 | Manuaaliset komennot |
| `cfg` | **in** | 699–709 | 11 | Konfigurointikomennot |
| `unit` | **in** | 710–714 | 5 | Yksikön kirjoitus |
| `batch` | **in** | 715–719 | 5 | Erän kirjoitus |
| `prog` | **in** | 720–730 | 11 | Ohjelmavaiheen kirjoitus |
| `event_out` | out | 737–753 | 17 | Tapahtumat (PLC → Gateway) |
| `event_ack` | **in** | 754 | 1 | Tapahtumien kuittaus |

- **out** = PLC kirjoittaa QW-rekisteriin, Gateway lukee Modbus holding registers
- **in** = Gateway kirjoittaa IW-rekisteriin, PLC lukee

---

## 16. Docker Compose -ympäristömuuttujat

Gateway-kontin ympäristömuuttujat (`docker-compose.yml`):

| Muuttuja | Oletus | Kuvaus |
|----------|--------|--------|
| `PLC_HOST` | `openplc` | Modbus TCP -kohde |
| `PLC_PORT` | `502` | Modbus TCP -portti |
| `PLC_API_HOST` | `openplc` | OpenPLC HTTPS API host |
| `PLC_API_PORT` | `8443` | OpenPLC HTTPS API portti |
| `PLC_API_USER` | `PiiJar` | OpenPLC-tunnus |
| `PLC_API_PASS` | `!T0s1v41k33!` | OpenPLC-salasana |
| `API_PORT` | `3001` | Gateway REST API portti |
| `POLL_MS` | `100` | Modbus-pollaus millisekunteina |
| `DB_HOST` | `plc_db` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL portti |
| `DB_USER` / `DB_PASS` | `plc` / `plc_pass` | DB-tunnukset |
| `DB_NAME` | `plc_events` | Tietokanta |
| `CUSTOMERS_ROOT` | `/data/customers` | Asiakasdatan polku |
| `PLANT_TEMPLATES_ROOT` | `/data/plant_templates` | Pohjien polku |
| `RUNTIME_ROOT` | `/data/runtime` | Ajonaikainen data |

---

## 17. Uuden laitteiston lisääminen

1. Luo hakemisto `customers/<Asiakas>/<Tehdas>/`
2. Kopioi pohja sopivasta `plant_templates/`-kansiosta tai olemassaolevasta asiakkaasta
3. Muokkaa JSON-tiedostot laitteiston mukaan
4. Tarvittaessa muokkaa `plant_config.json` (jos MAX-arvot eivät riitä)
5. Aja `bash deploy_plc.sh`
6. Resetoi: `POST /api/reset {"customer":"X","plant":"Y"}`

---

## 18. Vianetsintä

| Ongelma | Ratkaisu |
|---------|----------|
| `docker compose up` epäonnistuu | Tarkista Docker-versio (`docker compose version`), tarvitaan v2 |
| OpenPLC-kontin build kestää > 15 min | Normaali ensimmäisellä kerralla (C-kääntö) |
| Gateway ei yhdistä PLC:hen | Tarkista konttien nimet `docker ps`, verkon nimi `docker network ls` |
| `deploy_plc.sh` "ERROR: No running openplc_v3" | Kontin nimi sisältää ylimääräisen ID:n — grep-haku sopeutuu automaattisesti |
| PLC ei käynnisty deployn jälkeen | Tarkista OpenPLC-lokit: `docker logs <kontti>`, usein ST-syntaksivirhe |
| `debug_read.py` palauttaa None | PLC ei käynnissä tai IP muuttunut — tarkista `docker network inspect` |
| Erä ei aktivoidu (state=0) | Tarkista debug_read.py: DEP phase, pending, TSK phase |
| Gateway palauttaa 503 | Modbus-yhteys katkennut, tarkista `docker logs plc_gateway` |

---

## 19. Referenssiasennus (Nammo Lapua)

Esimerkki täydellisestä testauksesta:

```bash
# 1. Kontit käyntiin
docker compose up -d --build

# 2. Odota PLC käynnistymistä (~30s)
sleep 30

# 3. Lataa ensimmäinen PLC-ohjelma (OpenPLC web UI:sta)
#    http://localhost:8080 → Upload plc.xml → Start PLC

# 4. Deploy ST-koodi (myöhemmillä kerroilla)
bash deploy_plc.sh

# 5. Lataa Nammo Lapua -laitteisto
curl -X POST http://localhost:3001/api/reset \
  -H "Content-Type: application/json" \
  -d '{"customer":"Nammo Lapua Oy","plant":"Factory X Zinc Phosphating"}'

# 6. Käynnistä tuotanto
sleep 3
curl -X POST http://localhost:3001/api/production-queue \
  -H "Content-Type: application/json" -d '{"value":1}'

# 7. Seuraa erien aktivointia
sleep 5
python3 debug_read.py 30 0.5
```

Laitteisto: 21 asemaa (101–121), 2 kuljetinta (2D), 6 yksikköä, 12-vaiheinen käsittelyohjelma.
