# Nostimien työalueiden laskenta ja käyttö (PLC Simulator)

## Tarkoitus
Kuvaa, miten PLC-simulaattori laskee ja hyödyntää nostimien työalueet (X-rajoitukset) sekä kuinka tehtävät rajataan vain sallituille nostimille.

## Keskeiset lähteet
- Työalueiden laskenta: [PLC Simulator/sim-core/transporterWorkingArea.js](../sim-core/transporterWorkingArea.js)
- Tehtävälistan suodatus työalueilla: [PLC Simulator/sim-core/transporterTaskScheduler.js](../sim-core/transporterTaskScheduler.js#L347-L458)
- Tilakoneen integrointi (kutsut joka tikillä): [PLC Simulator/sim-core/server.js](../sim-core/server.js#L140-L260) ja reset-ajon alkuarvot [PLC Simulator/sim-core/server.js](../sim-core/server.js#L360-L470)

## Syötteet
- `transporters.json`:
  - `x_min_drive_limit`, `x_max_drive_limit` (alkaa näistä; fallback = nykyinen x jos puuttuu)
  - `physics_2D.avoid_distance_mm` (perusetäisyys muihin nostimiin ja asemiin)
  - `task_areas` (min/max lift- ja sink-asemat per linja)
- `station_avoid_status.json`: `avoid_status` per asema (0=normaali, 1=pass-through, 2=vältä)
- `stations.json`: asemien koordinaatit ja numerot
- `transporterStates`: nostimien tilat (päivitetään paikan päällä)

## Laskennan vaiheet (transporterWorkingArea)
1) **Alustus konfiguraatiosta + asemien vältöt**
   - Aloittaa `x_min_drive_limit` ja `x_max_drive_limit` arvoista.
   - Hakee vasemmalta/oikealta lähimmän `avoid_status` 1 tai 2 aseman ja supistaa rajoja `avoid_distance_mm` mukaan.
   - Jos jää loukkuun kahden status 2 aseman väliin (min ≥ max), keskittää alueen niiden väliin (±5 mm).
2) **Perusetäisyys nykyisestä sijainnista (Step 2.0)**
   - Jokainen 2D-nostin pakottaa muille samalla linjalla perusetäisyyden oman nykyisen x-sijaintinsa ympärille ("minä olen tässä, älä tule lähemmäs kuin avoid_distance").
3) **Prioriteettipohjainen törmäyksenesto (Step 2, v2-spec)**
   - Ryhmittelee nostimet linjoittain (start_station / 100).
   - Lajittelee nostimet x-sijainnin mukaan.
   - Laskee `canEvade` (automaattimoodi, ei Z-liikettä, työalue riittävän leveä) ja prioriteetin:
     - ei voi väistää → 100000
     - phase 3 (to_sink) → 200000 + (99999 - etäisyys kohteeseen)
     - phase 1 (to_source) → 100000 + (99999 - etäisyys kohteeseen)
     - idle → 1; tasatilanteessa pienempi ID voittaa
   - Korkeamman prioriteetin nostin asettaa rajoja matalamman prioriteetin nostimelle oman kohdeasemansa mukaan, kunnes turvallinen väli syntyy.
4) **Tulokset tilaan**
   - Päivittää `state.x_min_drive_limit` ja `state.x_max_drive_limit` joka nostimelle (transporterStates). Näitä käyttää ohjaus.

## Tehtävien rajaus työalueisiin (transporterTaskScheduler)
- `canTransporterHandleTask(transporter, liftStation, sinkStation)` käy läpi `task_areas` ja sallii tehtävän vain, jos sekä nosto- että laskuasema osuvat samaan alueeseen.
- `createTaskListFromSchedule` käyttää tätä ja asettaa `transporter_id` vain jos täsmälleen yksi nostin kelpaa; muutoin jää määrittämättä ja tilakone voi valita myöhemmin.

## Tilakoneen integraatio (server.js)
- Jokaisella tikillä lasketaan työalueet uudelleen kutsulla `calculateWorkingAreas(...)`, joka päivittää transporterStatesin rajoja ja joita ohjaus käyttää liikkeen rajaukseen.
- `updateCurrentStation` suodattaa asemahakuun vain ne asemat, jotka kuuluvat nostimen `task_areas`-alueisiin, jolloin 2D-nostin pysyy oikealla linjalla.
- Resetissä (alkutila) rajoitukset alustetaan suoraan konfiguraatioarvoista; ajon aikana dynamiikka tulee edellä kuvatusta laskennasta.

## Käytön huomioita
- Jos konfiguroidut rajat puuttuvat (0), nostin lukitaan nykyiseen x-sijaintiinsa, kunnes konfiguraatio korjataan.
- `avoid_status` 1 estää ylityksen vain jos asema on noston/laskun kohde; status 2 estää aina.
- 3D-nostimet eivät saa X-alueiden laskennassa linjakohtaista prioriteettihierarkiaa; niille käytetään perusrajat + asema- ja nostinkohtaiset rajoitukset.
- Tarkista, että `task_areas` kattavat kaikki suunnitellut siirrot; muuten tehtävä jää ilman nostinta (transporter_id = null).
