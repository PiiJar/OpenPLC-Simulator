# ST-koodin nimeämiskäytäntö

**Projekti:** Surface Treatment Line — PLC-kirjasto  
**Päivitetty:** 2026-02-23  
**Kohdeympäristöt:** OpenPLC, TwinCAT, TIA Portal, TIS

---

## Arkkitehtuurikerrokset

```
┌─────────────────────────────────────────────────────────────┐
│                    Sovelluskerros                            │
│                                                             │
│   TSK_          DEP_          TWA_          (tuleva?)       │
│   Task          Departure     Transporter   ...             │
│   Scheduler     Scheduler     Working Area                  │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                 Jaettu infrakerros                           │
│                                                             │
│                      STC_                                   │
│              (Surface Treatment Common)                     │
│                                                             │
│   STC_CalcTransferTime    STC_FindStation                   │
│   STC_CalcHorizontalTravel    STC_CanTransporterHandle      │
│   STC_FB_MeasureMoveTimes     STC_InsertionSort             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│              Tyypit & globaalit & konfiguraatio              │
│                                                             │
│   types.st        globals.st        config.st               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Moduuliprefiksit

| Prefiksi | Nimi | Kuvaus |
|----------|------|--------|
| **STC_** | Surface Treatment Common | Jaetut funktiot ja FB:t joita usea moduuli käyttää |
| **TSK_** | Task Scheduler | Tehtävien aikataulutus ja konfliktiratkaisu |
| **DEP_** | Departure Scheduler | Lähtöerien aikataulutus ja idle-slot-sovitus |
| **TWA_** | Transporter Working Area | Nostimien X-rajojen laskenta ja törmäyksenesto |

Uudet moduulit nimetään samalla periaatteella: 3-kirjaiminen prefiksi + alaviiva.

---

## POU-tyyppien nimeäminen

### Sääntö: prefiksi + tyyppi-infix + kuvaus

```
<MODUULI>_[FB_]<Kuvaus>
```

| POU-tyyppi | Infix | Milloin | Esimerkki |
|------------|-------|---------|-----------|
| **FUNCTION** | *(ei infixiä)* | Tilaton, puhdas laskenta, ei VAR-muistia | `STC_CalcTransferTime` |
| **FUNCTION_BLOCK** | `FB_` | Tilallinen, VAR-muisti, tilakone | `TSK_FB_Scheduler` |
| **PROGRAM** | *(ei prefiksiä)* | Vain pääohjelma | `PLC_PRG` |

### Esimerkkejä

```
FUNCTION:
  STC_CalcTransferTime        ← Jaettu, tilaton
  STC_CalcHorizontalTravel    ← Jaettu, tilaton
  STC_CanTransporterHandle    ← Jaettu, tilaton
  STC_FindStation             ← Jaettu, tilaton
  TWA_CalcPriority            ← TWA-spesifinen, tilaton

FUNCTION_BLOCK:
  STC_FB_MeasureMoveTimes     ← Jaettu, tilallinen (mittaa siirtoaikoja)
  TSK_FB_Scheduler            ← Task scheduler päätilakone
  TSK_FB_CalcSchedule         ← Task: aikataulun laskenta
  TSK_FB_CreateTasks          ← Task: tehtävälistan rakennus
  TSK_FB_Analyze              ← Task: konfliktianalyysi
  TSK_FB_Resolve              ← Task: konfliktin ratkaisu
  TSK_FB_SwapTasks            ← Task: same-station swap
  TSK_FB_NoTreatment          ← Task: no-treatment siirtotehtävät
  DEP_FB_Scheduler            ← Departure päätilakone
  DEP_FB_CalcIdleSlots        ← Departure: idle-slotit tehtävistä
  DEP_FB_FitTaskToSlot        ← Departure: tehtävän sovitus slottiin
  DEP_FB_CalcOverlap          ← Departure: overlap-asemien laskenta
  DEP_FB_OverlapDelay         ← Departure: overlap-viive
  DEP_FB_BackwardChain        ← Departure: ketjutettu viivästys
  DEP_FB_Sandbox              ← Departure: sandbox-hallinta
  TWA_FB_CalcLimits           ← TWA: nostimien X-rajojen laskenta
```

---

## Tiedostojen nimeäminen

ST-lähdetiedostot `openplc/OpenPLC/src/`-hakemistossa nimetään POU:n mukaan, pienillä kirjaimilla ja alaviivoin:

| POU | Tiedostonimi |
|-----|-------------|
| `STC_CalcTransferTime` | `STC_CalcTransferTime.st` |
| `STC_FB_MeasureMoveTimes` | `STC_FB_MeasureMoveTimes.st` |
| `TSK_FB_Scheduler` | `TSK_FB_Scheduler.st` |
| `TWA_FB_CalcLimits` | `TWA_FB_CalcLimits.st` |
| `DEP_FB_Scheduler` | `DEP_FB_Scheduler.st` |

Poikkeukset (ei moduuliprefiksiä):

| Tiedosto | Syy |
|----------|-----|
| `types.st` | Kaikki tietotyypit — yhteinen kaikille moduuleille |
| `globals.st` | Kaikki globaalit muuttujat |
| `config.st` | CONFIGURATION/RESOURCE/TASK-määrittely |
| `plc_prg.st` | Pääohjelma |
| `clear_config.st` | Konfiguraation nollaus (infra) |

---

## Tietotyyppien nimeäminen

Tietotyyppi-structeilla **ei käytetä moduuliprefiksiä** ellei tyyppi ole selkeästi moduulispesifinen:

| Tyyppi | Prefiksi | Esimerkki | Perustelu |
|--------|---------|-----------|-----------|
| Yleinen | *(ei)* | `STATION_T`, `UNIT_T`, `BATCH_T` | Usean moduulin käytössä |
| Moduulispesifinen | Moduuli + `_` | `TSK_TASK_T`, `TSK_QUEUE_T`, `TSK_SCHEDULE_T` | Vain TSK_ käyttää (tai TSK_ omistaa) |
| Moduulispesifinen | Moduuli + `_` | `DEP_IDLE_SLOT_T`, `DEP_FIT_RESULT_T` | Vain DEP_ käyttää |

Kaikki tyypit päättyvät `_T`-suffiksiin:

```
<[MODUULI_]>Kuvaus_T
```

---

## Globaalien muuttujien nimeäminen

Globaalit muuttujat käyttävät `g_`-prefiksiä + moduuliprefiksiä moduulispesifisille:

| Muuttuja | Moduuli | Esimerkki |
|----------|---------|-----------|
| Yleinen | `g_` | `g_stations`, `g_batches`, `g_units`, `g_time_s` |
| Nostimiin liittyvä | `g_` | `g_cfg`, `g_state`, `g_move`, `g_tasks`, `g_schedule` |
| TSK-spesifinen | `g_tsk_` | `g_tsk_phase`, `g_tsk_iteration` |
| DEP-spesifinen | `g_dep_` | `g_dep_phase`, `g_dep_sandbox_schedule`, `g_dep_idle_slots` |
| TWA-spesifinen | `g_twa_` | `g_twa_limits` |

---

## Vakioiden nimeäminen

Vakiot (VAR_GLOBAL CONSTANT) käyttävät ISOKIRJAIMIA ja alaviivoja:

```
<[MODUULI_]>KUVAUS
```

Esimerkkejä:
```
MAX_STATIONS          ← yleinen
MAX_TRANSPORTERS      ← yleinen
MAX_UNITS             ← yleinen
TSK_MAX_TASKS         ← TSK-spesifinen
DEP_MAX_IDLE_SLOTS    ← DEP-spesifinen
```

---

## Yhteenveto: nimen anatomia

```
TSK_FB_CalcSchedule
 │   │  └── Kuvaus: mitä tekee (CamelCase)
 │   └───── Tyyppi-infix: FB_ = Function Block (tilallinen)
 └───────── Moduuliprefiksi: TSK_ = Task Scheduler

STC_CalcTransferTime
 │   └── Kuvaus: mitä tekee
 └───── Moduuliprefiksi: STC_ = jaettu infrakerros
        (ei FB_-infixiä = FUNCTION, tilaton)

g_dep_sandbox_schedule
│ │   └── Kuvaus: mitä sisältää (snake_case)
│ └───── Moduuliprefiksi: dep_ = Departure-spesifinen
└─────── g_ = globaali muuttuja
```

---

## Ympäristökohtaiset huomiot

| Ympäristö | Namespace-tuki | Nimeäminen ST-koodissa |
|-----------|---------------|----------------------|
| **OpenPLC** | Ei | Prefiksit pakollisia → `TSK_FB_Scheduler` |
| **TwinCAT** | Kyllä (Library namespace) | Prefiksit silti käytössä → `STL.TSK_FB_Scheduler` |
| **TIA Portal** | Ei (vain kansiot) | Prefiksit pakollisia → `TSK_FB_Scheduler` |
| **TIS** | Rajoitettu | Prefiksit pakollisia → `TSK_FB_Scheduler` |

Prefiksit takaavat yhtenäisen nimeämisen kaikissa ympäristöissä. TwinCATissa Library-namespace (`STL`) lisää ylimääräisen tason mutta moduuliprefiksit säilyvät.

---

## Olemassa olevien tiedostojen siirtosuunnitelma

Nykyiset tiedostot jotka tulisi nimetä uudelleen uuden konvention mukaan:

| Nykyinen | Uusi nimi | Muutos |
|----------|----------|--------|
| `FB_TimeMoves.st` | `STC_FB_MeasureMoveTimes.st` | Jaettu → STC_ prefiksi |
| `fb_station_lookup.st` | `STC_FindStation.st` | Jaettu funktio → STC_ + ei FB_ (tilaton) |
| `TWA_CalcPriority.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TWA_FB_CalcLimits.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_Scheduler.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_CalcSchedule.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_CreateTasks.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_Analyze.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_Resolve.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_SwapTasks.st` | *(ei muutosta)* | Jo oikein nimetty |
| `TSK_FB_NoTreatment.st` | *(ei muutosta)* | Jo oikein nimetty |
| `SIM_FB_XMotion.st` | *(ei muutosta)* | SIM_ = simulaatiomoduuli |
| `SIM_FB_ZMotion.st` | *(ei muutosta)* | SIM_ = simulaatiomoduuli |
| `is_wet_station.st` | `STC_IsWetStation.st` | Jaettu funktio → STC_ prefiksi |

> **Nimeämismuutokset voi tehdä vaiheittain** — muista päivittää myös kaikki viittaukset (instanssinimet, kutsut) ja ajaa `build_plcxml.py` muutosten jälkeen.
