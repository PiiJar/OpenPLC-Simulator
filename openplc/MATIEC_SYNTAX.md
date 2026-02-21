# matiec/iec2c — Syntaksisäännöt ja rajoitukset

**Testattu:** 2026-02-21  
**Versio:** matiec (OpenPLC Editor, /opt/openplc-editor/matiec/iec2c)  
**Lähde:** Testikäännökset + iec_bison.yy -parserin analyysi

> matiec toteuttaa IEC 61131-3 -standardin **osajoukon**.
> Tämä dokumentti kuvaa mitä **toimii** ja mitä **ei toimi**.

---

## 1. Tietotyypit (TYPE)

### ✅ Toimii: Struct-määrittely

```iecst
TYPE
  STATION_T : STRUCT
    number : INT;
    x_mm : REAL;
    station_type : INT;
  END_STRUCT;
END_TYPE
```

### ✅ Toimii: Sisäkkäinen struct (struct structin sisällä)

```iecst
TYPE
  PHYSICS_2D_T : STRUCT
    x_accel_s : REAL;
    z_total_mm : REAL;
  END_STRUCT;

  CONFIG_T : STRUCT
    id : INT;
    phys2d : PHYSICS_2D_T;    (* struct jäsenenä *)
  END_STRUCT;
END_TYPE
```

---

## 2. Muuttujadeklaraatiot

### ✅ Toimii: Perustyypit

```iecst
VAR
  i : INT;
  x : REAL;
  done : BOOL;
END_VAR
```

### ✅ Toimii: Struct-muuttuja

```iecst
VAR
  station : STATION_T;
END_VAR
```

### ✅ Toimii: Taulukko perustyypistä

```iecst
VAR
  values : ARRAY [1..10] OF INT;
  flags : ARRAY [1..5] OF BOOL;
END_VAR
```

### ✅ Toimii: Taulukko structeista

```iecst
VAR
  stations : ARRAY [1..21] OF STATION_T;
END_VAR
```

### ❌ EI TOIMI: Taulukko FUNCTION_BLOCKeista

```iecst
(* VIRHE: "invalid item data type in array specification" *)
VAR
  motors : ARRAY [1..3] OF FB_Motor;
END_VAR
```

**Kiertotapa:** Erilliset instanssit:

```iecst
VAR
  motor1 : FB_Motor;
  motor2 : FB_Motor;
  motor3 : FB_Motor;
END_VAR
```

### ✅ Toimii: FB-instanssi yksittäin

```iecst
VAR
  fb_x1 : FB_XMotion;
  fb_x2 : FB_XMotion;
END_VAR
```

---

## 3. Globaalit muuttujat ja näkyvyys

### ✅ Toimii: Globaalien määrittely CONFIGURATIONissa

```iecst
CONFIGURATION Config0
  VAR_GLOBAL
    g_stations : ARRAY [1..21] OF STATION_T;
    g_count : INT;
  END_VAR
  ...
END_CONFIGURATION
```

### ✅ Toimii: Vakiot (CONSTANT)

```iecst
CONFIGURATION Config0
  VAR_GLOBAL CONSTANT
    MAX_STATIONS : INT := 21;
    DT_S : REAL := 0.02;
  END_VAR
  ...
END_CONFIGURATION
```

### ❌ EI TOIMI: Globaalin käyttö ilman VAR_EXTERNAL

```iecst
(* VIRHE: "invalid variable before ':='" *)
PROGRAM PLC_PRG
  VAR
    i : INT;
  END_VAR
  g_count := 5;          (* EI TOIMI — g_count ei näy *)
  g_stations[1].x := 0;  (* EI TOIMI *)
END_PROGRAM
```

### ✅ Toimii: VAR_EXTERNAL PROGRAMissa

```iecst
PROGRAM PLC_PRG
  VAR_EXTERNAL
    g_count : INT;
    g_stations : ARRAY [1..21] OF STATION_T;
  END_VAR
  VAR
    i : INT;
  END_VAR

  g_count := 5;                  (* TOIMII *)
  g_stations[1].x_mm := 100.0;  (* TOIMII *)
END_PROGRAM
```

> **TÄRKEÄÄ:** VAR_EXTERNAL-deklaraation tyypin PITÄÄ vastata täsmälleen
> VAR_GLOBAL-deklaraatiota.

### ✅ Toimii: VAR_EXTERNAL FUNCTION_BLOCKissa

```iecst
FUNCTION_BLOCK FB_Helper
  VAR_EXTERNAL
    g_stations : ARRAY [1..21] OF STATION_T;
  END_VAR
  ...
END_FUNCTION_BLOCK
```

### ❌ EI TOIMI: VAR_EXTERNAL FUNCTIONissa

```iecst
(* VIRHE: "unexpected external variable(s) declaration in function" *)
FUNCTION MyFunc : INT
  VAR_EXTERNAL
    g_arr : ARRAY [1..5] OF INT;
  END_VAR
  ...
END_FUNCTION
```

**Kiertotapa:** Välitä data parametrina:

```iecst
FUNCTION MyFunc : INT
  VAR_INPUT
    arr_element : STATION_T;    (* kopioi tarvittava elementti *)
  END_VAR
  MyFunc := arr_element.number;
END_FUNCTION
```

Tai muuta FUNCTION_BLOCKiksi.

---

## 4. Struct-kenttien käsittely

### ✅ Toimii: Yksinkertainen kenttäkäsittely

```iecst
station.number := 101;
station.x_mm := 100.0;
x := station.x_mm;
```

### ✅ Toimii: Taulukko + kenttäkäsittely

```iecst
stations[1].number := 101;
stations[i].x_mm := 100.0;
x := stations[i].x_mm;
```

### ✅ Toimii: Ketjutettu struct-käsittely (2+ tasoa)

```iecst
cfg[1].phys2d.x_accel_s := 1.5;
x := cfg[i].phys2d.z_total_mm;
```

### ✅ Toimii: Struct-kopiointi kokonaan

```iecst
VAR
  tmp : STATION_T;
END_VAR
tmp := stations[i];           (* kopioi koko structin *)
x := tmp.x_mm;               (* lue kopiosta *)
```

### ❌ EI TOIMI: Struct-literaali (inline-alustus)

```iecst
(* VIRHE: "')' missing at the end of expression" *)
station := (number := 101, x_mm := 100.0, station_type := 1);

(* EI MYÖSKÄÄN TOIMI: *)
stations[1] := (number := 101, x_mm := 100.0);
```

**Kiertotapa:** Kenttä kerrallaan:

```iecst
stations[1].number := 101;
stations[1].x_mm := 100.0;
stations[1].station_type := 1;
stations[1].device_delay_s := 0.0;
stations[1].dropping_time_s := 0.0;
```

---

## 5. FUNCTION

### ✅ Toimii: Perusfunktio

```iecst
FUNCTION IsWetStation : BOOL
  VAR_INPUT
    station_type : INT;
  END_VAR
  IsWetStation := (station_type = 1) OR (station_type = 11);
END_FUNCTION
```

### ✅ Toimii: Funktio lokaalien muuttujien kanssa

```iecst
FUNCTION FindIndex : INT
  VAR_INPUT
    target : INT;
    arr : ARRAY [1..21] OF STATION_T;
    count : INT;
  END_VAR
  VAR
    i : INT;
    tmp : STATION_T;
  END_VAR

  FindIndex := 0;
  FOR i := 1 TO count DO
    tmp := arr[i];
    IF tmp.number = target THEN
      FindIndex := i;
      RETURN;
    END_IF;
  END_FOR;
END_FUNCTION
```

### ❌ EI TOIMI: Funktio ei voi käyttää globaaleja

Funktio ei voi sisältää `VAR_EXTERNAL`-lohkoa.
Vaihtoehdot:
- Välitä tarvittava data `VAR_INPUT`:ina
- Käytä `FUNCTION_BLOCK`:ia sen sijaan

---

## 6. FUNCTION_BLOCK

### ✅ Toimii: Perus-FB

```iecst
FUNCTION_BLOCK FB_XMotion
  VAR_INPUT
    delta_t : REAL;
    x_target : REAL;
  END_VAR
  VAR_IN_OUT
    x_pos : REAL;
    v_x : REAL;
  END_VAR
  VAR_OUTPUT
    arrived : BOOL;
  END_VAR
  VAR
    distance : REAL;
  END_VAR

  distance := ABS(x_pos - x_target);
  IF distance <= 3.0 THEN
    arrived := TRUE;
    v_x := 0.0;
  ELSE
    arrived := FALSE;
    (* ... liikefysiikka ... *)
  END_IF;
END_FUNCTION_BLOCK
```

### ✅ Toimii: FB-kutsu

```iecst
fb_x1(delta_t := 0.02, x_target := 5000.0, x_pos := my_x, v_x := my_v);
arrived := fb_x1.arrived;
```

### ✅ Toimii: VAR_EXTERNAL FB:ssä

```iecst
FUNCTION_BLOCK FB_Helper
  VAR_EXTERNAL
    g_stations : ARRAY [1..21] OF STATION_T;
  END_VAR
  ...
END_FUNCTION_BLOCK
```

---

## 7. Ohjausrakenteet

### ✅ Toimii: IF / ELSIF / ELSE

```iecst
IF x > 10.0 THEN
  y := 1;
ELSIF x > 5.0 THEN
  y := 2;
ELSE
  y := 3;
END_IF;
```

> **HUOM:** matiec **vaatii** puolipisteen `END_IF`-jälkeen.
> iec2c-wrapper lisää sen automaattisesti.

### ✅ Toimii: FOR

```iecst
FOR i := 1 TO 21 DO
  stations[i].number := 100 + i;
END_FOR;
```

### ✅ Toimii: WHILE

```iecst
WHILE x > 0.0 DO
  x := x - 1.0;
END_WHILE;
```

### ✅ Toimii: CASE

```iecst
CASE phase OF
  0: (* idle *)
    x := 0;
  1: (* moving *)
    x := x + v * dt;
  2: (* lifting *)
    z := z - speed * dt;
ELSE
  x := 0;
END_CASE;
```

### ✅ Toimii: RETURN

```iecst
IF idx = 0 THEN
  MyFunc := -1;
  RETURN;
END_IF;
```

### ✅ Toimii: CONTINUE (FOR-silmukassa)

```iecst
FOR i := 1 TO 10 DO
  IF NOT active[i] THEN
    CONTINUE;
  END_IF;
  (* käsittele aktiivinen *)
END_FOR;
```

---

## 8. Matemaattiset funktiot

### ✅ Toimii

```iecst
x := ABS(distance);          (* itseisarvo *)
x := SQRT(value);            (* neliöjuuri *)
x := MIN(a, b);              (* pienempi — HUOM: tarkista versio *)
x := MAX(a, b);              (* suurempi — HUOM: tarkista versio *)
```

### ✅ Toimii: Aritmetiikka

```iecst
x := a + b;
x := a - b;
x := a * b;
x := a / b;
x := -a;                     (* negaatio *)
```

### ✅ Toimii: Vertailut

```iecst
IF x > 0.0 THEN ...
IF x >= limit THEN ...
IF x = target THEN ...
IF x <> 0 THEN ...
IF x <= max AND x >= min THEN ...
```

### ✅ Toimii: Loogiset operaattorit

```iecst
IF a AND b THEN ...
IF a OR b THEN ...
IF NOT a THEN ...
```

---

## 9. Varatut sanat (HUOMIO!)

Seuraavat ovat IEC 61131-3 varattuja sanoja joita **EI voi käyttää** muuttujaniminä:

```
DT          → käytä: delta_t
DATE        → käytä: date_val
TIME        → käytä: time_val
IN          → käytä: input_val
AT          → käytä: at_pos
ON          → käytä: on_flag
OR, AND, NOT, XOR
TRUE, FALSE
INT, REAL, BOOL, BYTE, WORD, DWORD, STRING
ARRAY, OF, STRUCT
```

> iec2c-wrapper muuttaa automaattisesti `dt` → `delta_t`.

---

## 10. Puolipisteet (END_-avainsanat)

matiec **vaatii** puolipisteen jokaisen `END_`-avainsanan jälkeen:

```iecst
END_IF;         (* pakollinen *)
END_FOR;        (* pakollinen *)
END_WHILE;      (* pakollinen *)
END_CASE;       (* pakollinen *)
END_REPEAT;     (* pakollinen *)
```

> iec2c-wrapper lisää nämä automaattisesti.

---

## 11. Kokonainen minimiohjelma (toimiva template)

```iecst
TYPE
  MY_STRUCT : STRUCT
    value : INT;
    factor : REAL;
  END_STRUCT;
END_TYPE

FUNCTION_BLOCK FB_Worker
  VAR_INPUT
    target : REAL;
  END_VAR
  VAR_OUTPUT
    done : BOOL;
  END_VAR
  VAR
    pos : REAL;
  END_VAR

  IF ABS(pos - target) < 1.0 THEN
    done := TRUE;
  ELSE
    pos := pos + 1.0;
    done := FALSE;
  END_IF;
END_FUNCTION_BLOCK

PROGRAM PLC_PRG
  VAR_EXTERNAL
    g_data : ARRAY [1..5] OF MY_STRUCT;
    g_count : INT;
  END_VAR
  VAR
    worker1 : FB_Worker;
    worker2 : FB_Worker;
    i : INT;
    init_done : BOOL := FALSE;
  END_VAR

  IF NOT init_done THEN
    g_count := 3;
    g_data[1].value := 10;
    g_data[1].factor := 1.5;
    g_data[2].value := 20;
    g_data[2].factor := 2.0;
    g_data[3].value := 30;
    g_data[3].factor := 0.5;
    init_done := TRUE;
  END_IF;

  worker1(target := 100.0);
  worker2(target := 200.0);
END_PROGRAM

CONFIGURATION Config0
  VAR_GLOBAL
    g_data : ARRAY [1..5] OF MY_STRUCT;
    g_count : INT;
  END_VAR
  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM instance0 WITH task0 : PLC_PRG;
  END_RESOURCE
END_CONFIGURATION
```

---

## 12. Yhteenveto rajoituksista

| # | Rajoitus | Kiertotapa |
|---|----------|------------|
| 1 | `ARRAY OF FUNCTION_BLOCK` ei tuettu | Erilliset instanssit: `fb1`, `fb2` |
| 2 | Struct-literaalit `(field := val)` ei tuettu | Kenttä kerrallaan: `s.field := val` |
| 3 | `VAR_EXTERNAL` ei sallittu FUNCTIONissa | Välitä `VAR_INPUT`:ina tai käytä FB:tä |
| 4 | Globaalit eivät näy ilman `VAR_EXTERNAL` | Lisää `VAR_EXTERNAL`-lohko jokaiseen POU:hun |
| 5 | `dt` on varattu sana (DATE_AND_TIME) | Käytä `delta_t` |
| 6 | `END_IF` jne. vaatii puolipisteen | iec2c-wrapper hoitaa automaattisesti |
