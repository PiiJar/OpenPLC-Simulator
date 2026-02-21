# DEPARTURE – tavoitetilan kuvaus (luonnos)

Tämä kuvaa toivotun toiminnan käyttäjän hahmotuksen mukaan. Ei ole toteutuksen kuvaus, vaan tavoite, jota vasten kehitetään.

## Tavoite
- Sovitella odottava erä nostimien tyhjäkäynti-ikkunoihin niin, että linjalla jo olevien erien aikataulu säilyy muuttumattomana.
- Varmistaa, että lähtöluvan saaneen erän käsittelyohjelman min/max-aikaikkunat pysyvät asetetun parametrirajan sisällä.

## Parametrit
- `max_initial_wait_s` (default 120 s): suurin sallittu odotus ennen odottavan erän 1. tehtävän alkua.
- `flex_up_factor` (default 0.5): kerroin, jolla tehtävän oma `MaxTime - CalcTime` jousto on käytettävissä viivästykseen (koskee kaikkia soviteltavia tehtäviä).

## Syöte ja synkronointi

### Stabiililippu (`tasksStableFlag`)
Server ylläpitää `tasksStableFlag`-lippua, joka kertoo DEPARTURE:lle onko linja stabiilissa tilassa:
1. **Alkutila = `true`** — tyhjä linja on stabiili, DEPARTURE voi aloittaa heti.
2. **DEPARTURE aktivoi erän → `false`** — uusi erä muuttaa linjan tilaa, TASKS ei ole vielä huomioinut sitä.
3. **TASKS stabiloi → `true`** — TASKS käsittelee uuden erän, ratkaisee mahdolliset konfliktit ja asettaa `conflictResolved = true`. Server lukee tämän TASKS-tikin tuloksesta ja palauttaa `tasksStableFlag = true`.

DEPARTURE ei siis aseta lippua itse. Se ainoastaan lukee lipun arvon kontekstistaan (`tasksConflictResolved`).

### TASKS-puolen nollaus
TASKS nollaa oman `conflictResolved`-tilansa jokaisessa INIT-vaiheessa (`false`). ANALYZE-vaihe asettaa sen `true`:ksi kun konflikteja ei ole (tai ne on ratkaistu). Tämä tarkoittaa, että TASKS-syklissä lippu on hetkellisesti `false` ennen ANALYZE-vaihetta, mutta tämä ei vaikuta server-tason `tasksStableFlag`-lippuun, koska server asettaa lipun `false`:ksi **vain** DEPARTURE-aktivoinnin yhteydessä.

### Synkronointi
- DEPARTURE odottaa `WAITING_FOR_TASKS`-tilassa, kunnes `tasksConflictResolved === true` ja `tasksPhase >= READY (10000)`.
- Stabiilin lähtötilanteen ansiosta DEPARTURE saa luotettavat idle-slotit eikä tarvitse omaa swap-logiikkaa (TASKS on jo järjestänyt tehtävät oikein).
- DEPARTURE lukee runtime-tiedostoista:
  - Erätiedot (batches): sijainti, stage, ajat.
  - Käsittelyohjelmat (programs).
  - Nostimien tiedot (transporters) ja esilasketut siirtoajat.
  - Asematiedot (stations) ja mahdolliset avoid-statukset.

### Sandboxin pysyvyys kierrosten välillä
- Kun samaa erää jatketaan seuraavalla DEPARTURE-kierroksella (round > 0), INIT päivittää linja-erien tiedot kontekstista, mutta **odottavan erän sandboxin ohjelmatiedot (joihin stage 1+ viiveet on kirjattu) säilytetään**.
- CALC käyttää odottavalle erälle sandboxin ohjelmaa (jossa edellisten kierrosten viiveet ovat), ei tuoretta kontekstista kopioitua ohjelmaa.
- **Batch-tiedot (calc_time_s, min_time_s, max_time_s)** ladataan joka kierroksella tuoreena kontekstista. Stage 0:n offset (nosturin matka-aika) lasketaan uudelleen joka kierroksella nykyhetkestä — se ei kumuloidu.
- Näin edellisten kierrosten ohjelmaviivekirjaukset (stage 1+) näkyvät aikataulun uudelleenlaskennassa, mutta stage 0 on aina puhdas.

## Prosessi (tavoitetila)
1) Laske aikataulu sekä linjalla oleville että odottaville erille, käyttäen erä- ja ohjelmatietoja, nostimien esilaskettuja siirtoaikoja ja asemadataa.
2) Muodosta tehtävälista **odottavan erän** kuljetustehtävistä; huomioi linjalla jo olevien erien tehtävät referenssinä (tilanvara), mutta niiden konfliktien ratkaisu kuuluu TASKS:lle.
3) Johda idle-taulu nostimille (vapaat aikaikkunat) linjalla olevien tehtävien perusteella.
4) Sovita odottavan erän tehtävälista idle-tauluun sääntöjen mukaan:
  - Kun odottavan erän tehtävä sovitetaan idle-slottiin, **slotin kokoa typistetään** välittömästi sovitetun tehtävän verran. Slottia ei jaeta osiin, vaan sitä lyhennetään siitä päästä, johon tehtävä sovitettiin. Näin seuraavat saman nostimen tehtävät näkevät pienentyneen slotin ja sovitustarkistus huomioi jo varatun ajan.
  - Sovitus hyväksytään vain, jos taskin **kesto + siirtymä ennen taskia + siirtymä taskin jälkeen** mahtuu idle-slotin aikarajaan.
  - Idle-slotin alkuankkuri (idle_start_pos):
    - jos slotilla on edellinen tehtävä, idle_start_pos = edellisen tehtävän sink-asema.
    - jos edellistä tehtävää ei ole, idle_start_pos = nostimen `start_station` (transporters.json).
  - Idle-slotin loppuankkuri (idle_end_pos):
    - jos slotilla on seuraava tehtävä, idle_end_pos = seuraavan tehtävän lift-asema.
    - jos seuraavaa tehtävää ei ole (viimeinen idle), loppupään siirtymää ei vaadita.
  - Sovitusehto voidaan ajatella näin: task_start >= idle_start + travel(idle_start_pos → lift_station) ja task_end + travel(sink_station → idle_end_pos) <= idle_end, jos idle_end_pos on määritelty.
  - Jos kaikki tehtävät sopivat ilman konflikteja → erä aktivoidaan välittömästi linjalle (stage 0) ja julkaistaan kyseisen erän batch- ja ohjelmatiedot.
  - Jos sovitus epäonnistuu → erä hylätään tällä kierroksella ja jatketaan seuraavaan odottavaan.

## Ensimmäisen tehtävän ajoitus (odottava erä)
- Ei käytetä käsittelyohjelman min/max-aikoja tälle tehtävälle, vaan aikarajat johdetaan nostimen ensimmäisestä sopivasta idle-slotista.
- `start_time = currentTimeSec`: aikataulun laskennan tarkasteluhetki, asetetaan jokaisella DEPARTURE-kierroksella nykyhetkeen. Tämä on stage 0:n `entry_time` — hetki josta odotusaika mitataan.
- Etsi nostimelle (jonka alueeseen tehtävä kuuluu) aikajärjestyksessä lähin tuleva idle-slot. `idle_start` on slotin alkuhetki, joka huomioi milloin nostin vapautuu edellisestä tehtävästä.
- Lasketaan nostimen saapumishetki noutopaikalle: `pickup_time = idle_start + travel(idle_start_pos → pickup_station)`.
  - Jos idle-slotin alussa ei ole edellistä tehtävää, `idle_start_pos` on nostimen `start_station` (transporters.json).
- Stage 0:n ajat (kestoja, eivät absoluuttisia aikoja):
  - `CalcTime = MinTime = pickup_time - start_time` (kuinka kauan erä odottaa noutoa)
  - `MaxTime = 2 × MinTime`
- Nämä ajat asetetaan jo **aikataulun laskentavaiheessa** (CALC) — ei vasta sovitusvaiheessa. Näin stage 0:n kesto vaikuttaa oikein myös seuraavien stagejen ajoitukseen aikataulussa.
- Sovituksen tulee mahtua idle-slotin sisään myös loppupäästä: tehtävän päättymisen jälkeen on oltava riittävästi aikaa siirtyä idle-slotin loppuikkunan aloituspositioon (idle_end_pos), jos idle_end_pos on määritelty.
- Käyttäjäparametri `max_initial_wait_s` (oletus 120 s) rajaa odotuksen: jos `pickup_time - start_time > max_initial_wait_s`, sovitus hylätään tältä kierrokselta.
- Jos sopivaa idle-slottia ei löydy parametrirajan sisällä, erä hylätään kierroksella.
- Jos ensimmäinen tehtävä ei mahdu yhteenkään parametrirajan sisällä olevaan idle-slot + travel -ikkunaan → odottava erä hylätään tällä kierroksella.
- Kun ensimmäinen tehtävä mahtuu, lasketut min/calc/max-ajat kirjoitetaan sandboxissa kyseisen erän batch-tietoihin. Käsittelyohjelmaa ei päivitetä tälle tehtävälle (sille ei ole ohjelmapaikkaa).
- Stage 0:n offset on nosturin matka-aika (fysiikka), ei konfliktiratkaisu. Se ei päätä kierrosta, vaan sovitus jatkaa seuraavaan tehtävään (stage 1+) samalla kierroksella käyttäen `cumulativeShift`-kertymää.
- Tehtävälistaa ei missään vaiheessa järjestetä (sort) tai swapata; tehtäväjärjestys pysyy laskennan mukaisena.

## Toinen kierros: tehtävien sovitus
- Odottavan erän tehtävälista käydään alusta alkaen järjestyksessä jokaisella DEPARTURE-kierroksella.
- Jos tarkasteltava tehtävä mahtuu sellaisenaan nostimen idle-slot + travel -ikkunaan, jatketaan seuraavaan tehtävään saman kierroksen aikana. Nostimen vaihtuminen peräkkäisissä tehtävissä ei vaadi erillistä tarkistusta: jokainen tehtävä sovitetaan oman nostimensa idle-slottiin automaattisesti, ja normaali viive + backward chaining hoitaa ajoituksen. (Nostimen vaihdon konfliktinratkaisu kuuluu TASKS:lle.)
- Jos tehtävä ei mahdu, yritetään viivästää sitä käyttämällä sen nostoaseman joustovaraa: `delay = (MaxTime - CalcTime) × flex_up_factor`, missä `flex_up_factor` on käyttäjän asettama kerroin (oletus 50 %).
- Jos tämä viive riittää ja tehtävä mahtuu idle-slottiin, viive kirjoitetaan odottavan erän kyseisen ohjelma-askeleen CalcTimeen (sandbox) ja kierros päätetään tähän (ei jatketa seuraaviin tehtäviin samalla kierroksella); odotetaan seuraavaa DEPARTURE-kierrosta.
- Jos viive ei riitä, lasketaan jäljelle jäävä viivästystarve ja kuljetaan tehtävälistaa taaksepäin yksi tehtävä kerrallaan:
  - Kullekin aiemmalle tehtävälle tarkistetaan sen oma idle-slot-ikkuna ja käytettävissä oleva jousto `flex_up = (MaxTime - CalcTime) × flex_up_factor`.
  - Joustoa käytetään tarpeen mukaan, kunnes tarkasteltava (myöhästynyt) tehtävä saadaan sopimaan idle-slottiinsa tai jousto loppuu.
  - Jos ketjutettu viivästys riittää, kaikki käytetyt viiveet kirjoitetaan erän käsittelyohjelmaan (program). Jos muutoksia tehtiin ensimmäiseen tehtävään asti, vastaavat ajat päivitetään myös batch-tietoihin. Kierros päätetään tähän (ei jatketa seuraaviin tehtäviin samalla kierroksella) ja odotetaan seuraavaa DEPARTURE-kierrosta.
  - Jos joustot eivät riitä koko ketjussa, erä hylätään tällä kierroksella.

## Seuraavat kierrokset ja aktivointi
- Jokainen myöhempi DEPARTURE-kierros noudattaa samaa logiikkaa kuin toinen kierros.
- Kun kierros päättyy onnistuneesti (tehtävät mahtuvat sääntöjen puitteissa), tehdään samat päivitykset kuin muilla kierroksilla: kirjataan muutokset odottavan erän batch-tietoihin (jos ensimmäinen tehtävä mukana) ja käsittelyohjelmaan.
- Kun sovittelut (ilman muutoksia tai muutoksilla) ovat saaneet kaikki odottavan erän tehtävät mahtumaan idle-slot + travel -ikkunoihin, erä aktivoidaan linjalle (stage 0) ja julkaistut batch- ja ohjelmamuutokset otetaan käyttöön.
- Linjalla jo olevien erien aikatauluja ei muuteta missään vaiheessa; kaikki toimenpiteet koskevat vain odottavaa erää.

## Kierroksen lopetus – päätöspuu
1) Kaikki tehtävät mahtuvat ilman muutoksia: aktivoi heti, julkaise batch/ohjelma.
2) Tehtävä mahtuu viiveellä (yksittäinen tai ketjutettu): kirjataan viiveet (program; myös batch jos 1. tehtävässä), päätetään kierros ja odotetaan seuraavaa kierrosta uuteen laskentaan.
3) Joustot eivät riitä: hylkäys tällä kierroksella, jatka seuraavaan odottavaan erään.

## Lopputulos
- Onnistunut sovitus: odottava erä aktivoidaan (stage 0) ja sen tehtävät lisätään tuotantoon.
- Epäonnistunut sovitus: erä jää jonoon, päätös hylätään nykyisessä kierrossa.

## Huomioita jatkotyölle
- Tämä kuvaus on tavoitetila; vertaa nykytilaan (departure_current_state.md) ja tee erillinen suunnitelma tarvittavista muutoksista.
