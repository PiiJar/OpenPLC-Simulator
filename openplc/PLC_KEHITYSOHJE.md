# PLC-koodin kehitys, tarkistus ja deploy

**Projekti:** OpenPLC Simulator  
**Päivitetty:** 2026-02-22

---

## Hakemistorakenne

```
openplc/
├── MATIEC_SYNTAX.md          ← syntaksisäännöt (vertailudokumentti)
├── PLC_KEHITYSOHJE.md        ← tämä ohje
├── OpenPLC/
│   ├── src/                  ← LÄHDEKOODI (muokkaa vain näitä)
│   │   ├── types.st          ← tietotyyppimäärittelyt (TYPE..END_TYPE)
│   │   ├── globals.st        ← globaalit muuttujat + Modbus-osoitteet
│   │   ├── config.st         ← CONFIGURATION/RESOURCE/TASK
│   │   ├── is_wet_station.st ← FUNCTION
│   │   ├── fb_station_lookup.st  ← FUNCTION_BLOCK
│   │   ├── fb_xmotion.st        ← FUNCTION_BLOCK
│   │   ├── clear_config.st      ← FUNCTION_BLOCK
│   │   └── plc_prg.st           ← PROGRAM (pääohjelma)
│   ├── build_plcxml.py       ← konvertteri: src/*.st → plc.xml + flat plc.st
│   └── to_editor/
│       ├── plc.xml           ← generoitu PLCopen XML (OpenPLC Editorille)
│       └── build/
│           └── plc.st        ← generoitu flat ST (PLC runtimelle)
└── gateway/
    └── index.js              ← Modbus gateway (Node.js)
```

> **Tärkeä sääntö:** Muokkaa AINA vain `src/`-hakemiston tiedostoja.
> `to_editor/`-hakemiston tiedostot generoituvat automaattisesti.

---

## Työvaiheet

### Vaihe 1: Muokkaa lähdekoodia (`src/*.st`)

Avaa ja muokkaa tarvittavaa `.st`-tiedostoa `src/`-hakemistossa.

**Tiedostojen roolit:**

| Tiedosto | Sisältö | Milloin muokata |
|----------|---------|-----------------|
| `types.st` | Struct-tyypit (STATION_T, UNIT_T, ...) | Kun lisäät/muutat data-rakenteita |
| `globals.st` | Globaalit muuttujat, vakiot, Modbus AT-osoitteet | Kun lisäät muuttujia tai Modbus-rekistereitä |
| `config.st` | CONFIGURATION / RESOURCE / TASK | Harvoin — vain jos vaihdat task-intervallia |
| `plc_prg.st` | Pääohjelma PLC_PRG | Kun muutat ohjelmalogiikkaa |
| `fb_*.st` | Function blockit | Kun muutat/lisäät FB:tä |
| `is_wet_station.st` | Funktio | Kun muutat/lisäät funktioita |
| `clear_config.st` | FB_ClearConfig — nollaa konfiguraation | Kun muutat nollauslogiikkaa |

> **HUOM: Vakiomuutokset vaikuttavat koko järjestelmään!**
> Jos muutat `globals.st`:n vakioita (esim. unit state/target arvot),
> päivitä myös:
> 1. **`gateway/index.js`** — STATE_MAP, TARGET_MAP yms. mappaukset
> 2. **Asiakastiedostot** (`customers/*/unit_setup.json`) — tarkista
>    merkkijonoarvojen yhteensopivuus uusien vakioiden kanssa
> 3. **Rebuild gateway** — `docker compose build gateway && docker compose up -d gateway`

---

### Vaihe 2: Tarkista syntaksi MATIEC_SYNTAX.md:tä vasten

Ennen konvertointia käy läpi seuraava tarkistuslista. Kaikki säännöt
löytyvät tiedostosta `openplc/MATIEC_SYNTAX.md`.

#### Pikatarkistuslista

- [ ] **Tyhjät VAR-lohkot poistettu** — `VAR_INPUT END_VAR` ilman muuttujia → poista koko lohko
- [ ] **VAR_EXTERNAL jokaisessa POU:ssa** joka käyttää globaaleja — PROGRAM ja FUNCTION_BLOCK vaativat VAR_EXTERNAL-lohkon
- [ ] **FUNCTION ei sisällä VAR_EXTERNAL** — funktioissa globaalit välitetään VAR_INPUT:ina
- [ ] **Ei ARRAY OF FUNCTION_BLOCK** — erillisiä instansseja sen sijaan
- [ ] **Ei struct-literaaleja** — kenttä kerrallaan: `s.field := val;`
- [ ] **Varatut sanat tarkistettu** — ei `dt`, `date`, `time`, `in`, `at`, `on` muuttujaniminä
- [ ] **Puolipisteet END_-avainsanojen jälkeen** — `END_IF;`, `END_FOR;`, `END_CASE;`
- [ ] **Modbus-osoitteet oikein:**
  - Gateway kirjoittaa → käytä `%QW` (holding registers)
  - PLC kirjoittaa, gateway vain lukee → voi käyttää `%QW` tai `%IW`
  - **ÄLÄ käytä `%IW` jos gateway tarvitsee kirjoittaa!**
- [ ] **globals.st: VAR_GLOBAL CONSTANT** vakioille, **VAR_GLOBAL** muuttujille
- [ ] **config.st: muoto ei muutu** — CONFIGURATION/RESOURCE/TASK

---

### Vaihe 3: Konvertoi (build)

```bash
cd openplc/OpenPLC
python3 build_plcxml.py
```

Tämä tekee kaksi asiaa:
1. **`to_editor/plc.xml`** — PLCopen XML (OpenPLC Editorille avattavaksi)
2. **`to_editor/build/plc.st`** — Flat ST (yksi tiedosto PLC runtimelle)

Flat ST -generaattori hoitaa automaattisesti:
- Oikea järjestys: types → functions → function_blocks → programs → CONFIGURATION
- VAR_GLOBAL-lohkot siirretään CONFIGURATION-osion sisälle (MATIEC-vaatimus)
- Kommentit säilyvät

**Tarkista tuloste:**
```
  ✓ Written to_editor/plc.xml  (N bytes)
  ✓ Written to_editor/build/plc.st  (N bytes)
```

Jos tulosteessa on `WARNING`, tarkista kyseinen lähdetiedosto.

**Verifiointi konvertoinnin jälkeen:**

Tarkista generoitu koodi manuaalisesti varsinkin jos muutit vakioita tai rekistereitä:

```bash
# Tarkista että vanhat arvot eivät jääneet generoiduun koodiin
grep -n "VANHA_ARVO" to_editor/build/plc.st

# Tarkista että uudet arvot löytyvät
grep -n "UUSI_ARVO" to_editor/build/plc.st

# Tarkista ettei %IW-osoitteita ole (paitsi kommenteissa)
grep "%IW" to_editor/build/plc.st
```

---

### Vaihe 4: Deploy PLC runtimeen

Aja projektin juuresta:

```bash
bash deploy_plc.sh
```

Skripti tekee automaattisesti:
1. Ajaa `build_plcxml.py` (vaihe 3 uudestaan)
2. Pysäyttää PLC runtimen (web API)
3. Kopioi `build/plc.st` → konttiin (`openplc_v3`)
4. Kääntää `iec2c`-kääntäjällä kontin sisällä
5. Käynnistää PLC runtimen

**Onnistunut deploy:**
```
═══ Step 4: Compile PLC program ═══
Generating C files...
POUS.c
POUS.h
...
Compilation finished successfully!

═══ Step 5: Start PLC runtime ═══
PLC status: Running
✓ Deploy complete! PLC is running with updated program.
```

**Epäonnistunut käännös:**
```
./st_files/526436.st:106-9..107-1: error: no variable declared in input variable(s) declaration.
Error generating C files
Compilation finished with errors!
```

→ Virheilmoituksessa on rivi:sarake. Tarkista `to_editor/build/plc.st`
vastaavalta riviltä ja korjaa `src/`-lähdetiedosto.

---

### Vaihe 5: Testaa

Deployn jälkeen testaa gateway-yhteys:

```bash
# Tarkista PLC status
curl -s http://localhost:8080/dashboard | grep -oi "Running\|Stopped"

# Tarkista gateway-yhteys
docker logs plc_gateway --tail 5

# Testaa reset (lataa asemat PLC:lle)
curl -s -X POST http://localhost:3001/api/reset \
  -H 'Content-Type: application/json' \
  -d '{"customer":"Nammo Lapua Oy","plant":"Factory X Zinc Phosphating"}'
```

---

## Yleisimmät virhetilanteet

### Käännösvirhe: "no variable declared"
**Syy:** Tyhjä `VAR_INPUT END_VAR` tai `VAR_OUTPUT END_VAR` lohko.  
**Korjaus:** Poista tyhjä VAR-lohko kokonaan lähdetiedostosta.

### Käännösvirhe: "unknown syntax error" riveillä joissa VAR_GLOBAL
**Syy:** `build_flat_st()` ei siirtänyt VAR_GLOBAL CONFIGURATIONin sisälle.  
**Korjaus:** Tarkista `build_plcxml.py` — globals.st:n VAR_GLOBAL-lohkojen pitää päätyä CONFIGURATION-osion sisälle generoidussa flat ST:ssä.

### Käännösvirhe: "unexpected external variable(s) declaration in function"
**Syy:** FUNCTION sisältää VAR_EXTERNAL-lohkon.  
**Korjaus:** Muuta funktio FUNCTION_BLOCKiksi tai välitä data VAR_INPUT:ina.

### Gateway: "PLC ack timeout"
**Syy 1:** PLC ei ole käynnissä → käynnistä PLC.  
**Syy 2:** Modbus-osoitteet eivät täsmää → tarkista globals.st:n AT-osoitteet ja gateway/index.js:n rekisteriosoitteet.  
**Syy 3:** Käytetty `%IW` kirjoitettaville rekistereille → vaihda `%QW`:ksi.

### Deploy: glueVars näyttää __IW vaikka koodissa QW
**Syy:** `to_editor/build/plc.st` on vanhentunut (edellinen generointi).  
**Korjaus:** Aja `python3 build_plcxml.py` uudelleen ja tarkista `grep "%IW" to_editor/build/plc.st`.

---

## Modbus-rekisterikartta (nykytila)

| Rekisterialue | AT-osoite | Suunta | Käyttö |
|---------------|-----------|--------|--------|
| QW0–QW8 | `%QW0`–`%QW8` | PLC → Gateway | Transporter 1 tila |
| QW9–QW17 | `%QW9`–`%QW17` | PLC → Gateway | Transporter 2 tila |
| QW18–QW20 | `%QW18`–`%QW20` | PLC → Gateway | Status (station_cnt, init_done, cycle_cnt) |
| QW21 | `%QW21` | PLC → Gateway | Config upload ack |
| QW22–QW71 | `%QW22`–`%QW71` | PLC → Gateway | Unit-tiedot (10 × 5 kenttää) |
| QW72 | `%QW72` | PLC → Gateway | Unit write ack |
| QW100–QW105 | `%QW100`–`%QW105` | Gateway → PLC | Transporter-komennot |
| QW110–QW119 | `%QW110`–`%QW119` | Gateway → PLC | Config upload -protokolla |
| QW120–QW126 | `%QW120`–`%QW126` | Gateway → PLC | Unit write -protokolla |

> Kaikki rekisterit ovat `%QW` (holding registers) koska gateway tarvitsee
> sekä lukea että kirjoittaa. Gateway-koodissa osoite = AT-numeron arvo
> (esim. `%QW110` → `client.writeRegisters(110, [value])`).

---

## Uuden POU:n lisääminen

### Uusi FUNCTION_BLOCK

1. Luo tiedosto `src/fb_uusinimi.st`
2. Kirjoita FB-koodi:
   ```iecst
   FUNCTION_BLOCK FB_UusiNimi
   VAR_EXTERNAL
     g_stations : ARRAY[101..125] OF STATION_T;  (* jos tarvitset globaaleja *)
   END_VAR
   VAR_INPUT
     param1 : INT;
   END_VAR
   VAR
     i : INT;
   END_VAR
     (* logiikka *)
   END_FUNCTION_BLOCK
   ```
3. Lisää instanssi `plc_prg.st`:n `VAR`-lohkoon: `my_fb : FB_UusiNimi;`
4. Kutsu: `my_fb(param1 := 42);`
5. Aja `python3 build_plcxml.py` → `bash deploy_plc.sh`

### Uusi FUNCTION

1. Luo tiedosto `src/uusifunktio.st`
2. Kirjoita funktio:
   ```iecst
   FUNCTION UusiFunktio : INT
   VAR_INPUT
     arvo : INT;
   END_VAR
     UusiFunktio := arvo * 2;
   END_FUNCTION
   ```
3. Kutsu `plc_prg.st`:ssä: `tulos := UusiFunktio(arvo := 5);`
4. Aja `python3 build_plcxml.py` → `bash deploy_plc.sh`

> Uusia tiedostoja ei tarvitse rekisteröidä mihinkään — `build_plcxml.py`
> lukee automaattisesti kaikki `src/*.st`-tiedostot.

### Uusi globaali muuttuja

1. Lisää `src/globals.st`:iin sopivaan VAR_GLOBAL-lohkoon
2. Lisää VAR_EXTERNAL-lohkoon **jokaiseen** POU:hun joka tarvitsee sitä
3. Jos Modbus AT-osoite, valitse vapaa `%QW`-numero (katso rekisterikartta yllä)
4. Jos gateway käyttää uutta rekisteriä, päivitä myös `gateway/index.js`

---

## Pikakomennot

```bash
# Pelkkä konvertointi (ei deployta)
cd openplc/OpenPLC && python3 build_plcxml.py

# Konvertointi + deploy
bash deploy_plc.sh

# Tarkista generoitu koodi
grep "%IW" openplc/OpenPLC/to_editor/build/plc.st   # pitäisi olla vain kommenteissa
grep -c "%QW" openplc/OpenPLC/to_editor/build/plc.st # rekisterien lukumäärä

# Gateway rebuild (jos muokkaat gateway/index.js)
docker compose build gateway && docker compose up -d gateway

# UI rebuild (jos muokkaat visualization/)
docker compose build visualization && docker compose up -d visualization

# PLC logit
docker exec openplc_v3 tail -20 /home/openplc/OpenPLC_v3/webserver/scripts/../logs/openplc_log.log

# Gateway logit
docker logs plc_gateway --tail 20
```
