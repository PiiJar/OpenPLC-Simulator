# Station Operations

Aseman `operation`-kenttä (`stations.json`) määrittää aseman toiminnallisen roolin linjassa.
Kenttä `kind` on itsenäinen: **1 = wet** (märkä), **0 = dry** (kuiva). Kind ei riipu operaatiosta.

## Operation-koodit

### 1–9: Esikäsittely (pre-treatment)

| Operation | Nimi | Kuvaus |
|-----------|------|--------|
| 1 | Rasvanpoisto (degreasing) | Emäksinen tai liuotinrasvanpoisto |
| 2 | Sähkökemiallinen rasvanpoisto (electrolytic degreasing) | Elektrolyyttinen puhdistus |
| 3 | Happopeittaus (acid pickling) | Oksidien ja hilseen poisto |
| 4 | Aktivointi (activation) | Pinnan aktivointi ennen pinnoitusta |

### 10–19: Pääkäsittely (main treatment)

| Operation | Nimi | Kuvaus |
|-----------|------|--------|
| 10 | Galvanointi (electroplating) | Sähkökemiallinen pinnoitus (Zn, Ni, Cr, Cu, Sn...) |
| 11 | Kemiallinen pinnoitus (electroless plating) | Elektroditon pinnoitus (esim. kemiallinen nikkeli) |
| 12 | Anodisointi (anodizing) | Anodinen oksidointi |
| 13 | Fosfatointi (phosphating) | Fosfaattikonversiopinnoite |
| 14 | Kromaattikäsittely (chromate conversion) | Kromaattikonversiopinnoite |

### 20–29: Jälkikäsittely (post-treatment)

| Operation | Nimi | Kuvaus |
|-----------|------|--------|
| 20 | Passivointi (passivation) | Korroosionsuojakäsittely |
| 21 | Tiivistys (sealing) | Anodisointikerroksen tiivistys |
| 22 | Kuivaus (drying) | Kuumailma- tai linkouskuivaus |
| 23 | Jäähdytys (cooling) | Jäähdytysasema |

### 30–39: Huuhtelu (rinsing)

| Operation | Nimi | Kuvaus |
|-----------|------|--------|
| 30 | Vesihuuhtelu (water rinse) | Vakiohuuhtelu prosessivaiheiden välissä |
| 31 | Kuumahuuhtelu (hot water rinse) | Lämpimän veden huuhtelu |
| 32 | DI-vesihuuhtelu (DI water rinse) | Deionisoidun veden huuhtelu |
| 33 | Kaskadhuuhtelu (cascade rinse) | Monivaiheinen kaskadhuuhtelu |

### 40–49: Logistiikka (logistics)

| Operation | Nimi | Kuvaus |
|-----------|------|--------|
| 40 | Lastaus (loading) | Erät tuodaan linjalle |
| 41 | Purku (unloading) | Valmiit erät poistetaan linjalta |
| 42 | Lastaus/Purku (loading/unloading) | Yhdistetty lastaus- ja purkuasema |
| 43 | Poikittaissiirto (cross-transporter) | Siirto linjojen/osien välillä |
| 44 | Varasto (buffer) | Yleinen varastoasema |
| 45 | Tyhjien unittien varasto (empty unit buffer) | Varasto tyhjille uniteille |
| 46 | Käsittelemättömien erien varasto (unprocessed batch buffer) | Varasto käsittelemättömille erille |
| 47 | Käsiteltyjen erien varasto (processed batch buffer) | Varasto käsitellyille erille |

## Kind (kuiva/märkä)

`kind` vaikuttaa nostimen Z-liikenopeuteen:

- **kind = 1 (wet):** hidas nosto/lasku altaan pinnan läpi → käytetään `z_slow_wet_mm` ja `z_speed_change_limit_wet_mm`
- **kind = 0 (dry):** normaali nosto/lasku → käytetään `z_slow_dry_mm` ja `z_speed_change_limit_dry_mm`

Kind on itsenäinen kenttä `stations.json`-tiedostossa, ei johdettu operaatiosta.

## Luokittelufunktiot (JS)

| Funktio / vakio | Logiikka | Käyttö |
|-----------------|----------|--------|
| `isWetStation(station)` | `station.kind === 1` | Z-liikenopeuden valinta (server.js) |
| `isWetStation(stationKind)` | `stationKind === 1` | Z-liikenopeuden valinta (transporterTaskScheduler.js) |
| `isCrossTransporterOp(op)` | `op === 10` | Poikittaissiirron tunnistus |
| `LOADING_STATION_OPS` | `{20, 22}` | Lastausasemien tunnistus |
| `UNLOADING_STATION_OPS` | `{21, 22}` | Purkuasemien tunnistus |
| `BUFFER_STATION_OPS` | `{30, 31, 32, 33}` | Puskuriasemien tunnistus |
| `SAFE_STATION_OPS` | `[20, 21, 22, 30, 31, 32, 33]` | Asemat joista ei tarvitse väistää |

## PLC-vakiot (globals.st)

| Vakio | Arvo | Kuvaus |
|-------|------|--------|
| `KIND_DRY` | 0 | Kuiva asema |
| `KIND_WET` | 1 | Märkä asema |

## Tietorakenne (stations.json)

```json
{
  "number": 103,
  "tank": 103,
  "group": 103,
  "name": "Alkaline degreasing",
  "x_position": 3000,
  "y_position": 0,
  "z_position": 0,
  "dropping_time": 3.0,
  "kind": 1,
  "operation": 0,
  "device_delay": 0.5,
  "start_station": false
}
```

## Tiedonkulku

1. **stations.json** → `kind` + `operation` kentät (itsenäiset)
2. **Gateway** (`index.js`) → lähettää `kind` rekisteriin `iw_cfg_d7` ja `operation` rekisteriin `iw_cfg_d4`
3. **PLC** (`plc_prg.st`) → lukee `g_station[n].kind` suoraan d7:stä ja `g_station[n].operation` d4:stä
4. **Simulator** (`server.js`, `transporterTaskScheduler.js`) → lukee `station.kind` ja `station.operation` suoraan JSON:sta
