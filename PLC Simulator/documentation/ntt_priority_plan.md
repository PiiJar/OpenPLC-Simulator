# NTT-tehtävien priorisointi — Suunnitelma

## Tausta

NoTreatment-tehtäviä (NTT) syntyy kun unitilla on target mutta ei käsittelyohjelman mukaista siirtotehtävää. Yhdellä kierroksella voi olla useita kelpaavia tehtäviä (kohde vapaa, ei nostinkonfliktia). Tällä hetkellä ensimmäinen löydetty kelpaava tehtävä luodaan — ei priorisoida.

## Prioriteettiin vaikuttavat tekijät

| Tekijä | Lähde | Tyyppi |
|--------|-------|--------|
| Unit target | `g_unit[ui].target` | INT (1-5) |
| Batch-tila | `g_batch[ui].state` | INT (0=NOT_PROCESSED, 1=IN_PROCESS, 2=PROCESSED) |
| Asema missä unit on | `g_unit[ui].location` | INT |
| Aika asemalla | `g_station[loc].change_time` vs `g_time_s` | LINT (sekunteja) |
| Tuotantovaihe | (tuleva) `g_phase` tms. | INT (0=ramp_up, 1=steady, 2=ramp_down) |

## Karkea prioriteettijärjestys (arvio)

### 1. TO_AVOID (target=5) — korkein prioriteetti

**Syy:** Unit on jonkun toisen tiellä. Riippumatta muista ehdoista, jos kohde löytyy → AVOID voittaa.

**Avoin kysymys:** Jos useammalla unitilla on TO_AVOID ja kaikilla on vapaa kohde?
- Vaihtoehto A: Valitaan se joka on ollut pisimpään asemalla (suurin elapsed_time)
- Vaihtoehto B: Valitaan se jonka sijainti on lähinnä nostinta (lyhin matka)
- Vaihtoehto C: Valitaan se joka estää kriittisimmän tehtävän (vaikea laskea)

### 2. TO_UNLOAD (target=4) + PROCESSED (state=2)

**Syy:** Valmis erä pitää purkaa pois linjalta, vapauttaa asema.

### 3. TO_BUFFER (target=2)

Riippuu batch-tilasta:
- `state=0` (no batch) → tyhjä buffer-siirto → matala prioriteetti?
- `state=1` (in_process) → loaded buffer → keskitaso?
- `state=2` (processed) → processed buffer → korkeampi?

### 4. TO_LOADING (target=1)

**Syy:** Uusi erä linjalle. Ramp_up-vaiheessa tärkeämpi, steady-vaiheessa vähemmän kriittinen.

### 5. Tuotantovaiheen vaikutus

#### Määritelmät

**ramp_up** — Tuotannon alusta siihen, kun ensimmäinen erä valmistuu (PROCESSED).
- Linjaa täytetään, asemat ovat vielä tyhjiä
- TO_LOADING on tärkeä (uusia eriä sisään)

**steady_state** — Ensimmäisen erän valmistumisesta siihen, kun viimeinen erä lähtee latauksesta.
- Linja on "täynnä", eriä tulee ja menee tasaisesti
- Kaikki target-tyypit ovat tasapainossa

**ramp_down** — Viimeisen erän lähtemisestä (ei enää uusia latauksia) siihen, kun viimeinen erä valmistuu.
- Linjaa tyhjennetään, uusia eriä ei tule
- TO_UNLOAD ja TO_BUFFER (processed) korostuvat

**Huom:** steady_state-vaihetta ei välttämättä ole lainkaan. Jos tuotantojono on lyhyt (vähän eriä), viimeinen erä voi lähteä latauksesta ennen kuin ensimmäinen erä valmistuu. Tällöin siirrytään suoraan ramp_up → ramp_down.

```
Aikajana:

Vähän eriä (ei steady_state):
|-- ramp_up --|-- ramp_down --|
              ^               ^
    viim. erä lähtee    viim. erä valmis
    (ennen 1. valmistumista)

Normaali tuotanto:
|-- ramp_up --|---- steady_state ----|-- ramp_down --|
              ^                      ^               ^
     1. erä valmis          viim. erä lähtee   viim. erä valmis
```

| Vaihe | Alkaa | Päättyy |
|-------|-------|---------|
| **ramp_up** | Tuotannon alku | Ensimmäinen erä valmistuu (state→PROCESSED) |
| **steady_state** | Ensimmäinen erä valmistuu | Viimeinen erä lähtee latauksesta (ei uusia TO_LOADING) |
| **ramp_down** | Viimeinen erä lähtee latauksesta | Viimeinen erä valmistuu |

| Vaihe | Painotus |
|-------|----------|
| **ramp_up** | TO_LOADING korkeammalle (linjaa pitää täyttää) |
| **steady_state** | TO_AVOID ja TO_UNLOAD tärkeimpiä (pidä linja liikkeessä) |
| **ramp_down** | TO_UNLOAD korkein (tyhjennä linja), TO_LOADING ei relevantti |

## Toteutusvaihtoehdot

### A: Kiinteä IF-ketju (yksinkertaisin)

```
IF target = 5 THEN score := 500;
ELSIF target = 4 AND state = 2 THEN score := 400;
ELSIF target = 2 AND state = 2 THEN score := 350;
...
```
Tasapeli ratkaistaan `change_time`:llä (pisin aika voittaa).

**+** Yksinkertainen, nopea, helppo debugata
**−** Tuotantovaihe ja laitoskohtaisuus vaatii koodimuutoksia

### B: Painotaulukko PLC:ssä

```
g_ntt_priority[phase][rule_idx] : NTT_PRIORITY_RULE_T
```
Konfiguroitu `plant_config.json` → `apply_plant_config.py` generoi.

**+** Laitoskohtainen ilman koodimuutosta
**−** Monimutkaisempi PLC-koodi, taulukkojen hallinta

### C: Generoitu ST-koodi (hybridi)

JSON-konfiguraatio → Python generoi laitoskohtaisen IF-ketjun suoraan `.st`-tiedostoon.

**+** Kevyt ajossa, konfiguroitavissa JSON:sta, ei taulukoita PLC:ssä
**−** Vaatii uudelleengeneroinnin ja deployn muutoksissa

## Ehdotus: Vaiheittainen toteutus

### Vaihe 1 — Kiinteä priorisointi (nyt)

Toteutetaan yksinkertainen pisteytys NoTreatment-looppiin:

1. Käy kaikki unitit läpi, laske pistearvo kelpaavalle tehtävälle
2. Pidä muistissa paras (best_score, best_unit, best_dest...)
3. Loopin jälkeen luo tehtävä vain parhaalle kandidaatille

Pisteytys (karkea esimerkki):
```
score = base_score(target, batch_state) + time_bonus(elapsed)
```

Missä `base_score`:
| target | batch_state | score |
|--------|-------------|-------|
| TO_AVOID (5) | mikä tahansa | 500 |
| TO_UNLOAD (4) | PROCESSED (2) | 400 |
| TO_UNLOAD (4) | muu | 350 |
| TO_BUFFER (2) | PROCESSED (2) | 300 |
| TO_BUFFER (2) | IN_PROCESS (1) | 250 |
| TO_BUFFER (2) | NOT_PROCESSED (0) | 200 |
| TO_LOADING (1) | mikä tahansa | 100 |

`time_bonus`: esim. `MIN(elapsed_minutes, 50)` → max 50 pistettä lisää.

### Vaihe 2 — Tuotantovaihe (myöhemmin)

Lisätään `g_production_phase` globaali (0/1/2) ja valitaan eri base_score-taulukko vaiheen mukaan.

### Vaihe 3 — Laitoskohtainen konfiguraatio (tarvittaessa)

Siirretään pisteytys JSON-konfiguraatioon, generoidaan Python-skriptillä.

## Avoimet kysymykset

1. **Onko TO_AVOID aina ehdoton ykkönen?** Vai voiko jokin muu tilanne ohittaa sen?
2. **Useamman AVOID-unitin valinta** — aika asemalla vai jokin muu kriteeri?
3. **TO_LOADING ramp_up-vaiheessa** — kuinka paljon korkeammalle sen pitäisi nousta?
4. **Nostimikohtainen priorisointi** — sama priorisointi kaikille nostimille vai eri?
5. **Mistä tuotantovaihe (ramp_up/steady/ramp_down) saadaan?** Onko se manuaalinen asetus, vai lasketaanko automaattisesti (esim. kaikki asemat täynnä = steady)?
6. **Pitääkö priorisoinnin olla eri eri transportereille?** T1 ja T2 voivat kattaa eri alueen.
