# DEPARTURE – nykytila (2026-02-15)

Tämä kuvaa nykyisen toteutuksen sellaisena kuin se toimii nyt (ei tavoitetila). Lähteet: nykyinen koodi (departureScheduler.js, transporterTaskScheduler.js), aiempi dokumentaatio (departure_cycle_operations.md) ja löydökset (conflict_resolution_findings.md). 

## Ydinrakenne
- TASKS ja DEPARTURE vuorottelevat tikki kerrallaan (TASKS parillinen, DEPARTURE pariton). DEPARTURE käyttää TASKS:n tuoreinta dataa sandboxissa, eikä kirjoita tuotantoon ennen ACTIVATE:a.
- Sandbox: snapshot -> muutokset sandboxissa -> REJECT palauttaa snapshotin -> ACTIVATE kirjoittaa tuotantotilaan (batches, programs, schedules, tasks) ja luovuttaa erän linjalle (stage 0).

## Vaihejako (DEPARTURE)
1) CHECK_CREATE_TASKS: kopioi departureSandboxin snapshotin ja rakentaa combinedTasks odottavalle erälle.
2) CHECK_SORT: järjestää combinedTasks ajan mukaan, iteraatioraja departureMaxIterations (default 50).
3) CHECK_SWAP: sama asema peräkkäin samalla nostimella → vaihto (lift ennen sink).
4) CHECK_ANALYZE: etsi ensimmäinen konflikti (päällekkäiset tehtävät samalla nostimella, deficit = travel + margin – gap).
5) CHECK_RESOLVE: resolveConflict neljällä menetelmällä (ADVANCE prev, DELAY next, DELAY next-1, DELAY prev ohi). lockedStages estää vastakkaisen strategian samalle stagelle saman syklin aikana.
6) CHECK_UPDATE_PROGRAM / CHECK_RECALC_SCHEDULE / CHECK_RECALC_TASKS: sovella actions → päivitä programit/batchit → laske aikataulut uudelleen → rakenna tehtävät uudelleen → palaa CHECK_SORT:iin, kunnes ei konflikteja tai iteraatioraja.
7) ACTIVATE: jos ei konflikteja, erä linjalle (stage 0), pendingWriteData TASKS:lle, ohjelmamuutokset jäävät voimaan.
8) REJECT: jos ei ratkea, palauta snapshot, nollaa lukitukset, siirry seuraavaan jonossa.

## Cap- ja lukituslogiikan todellinen käyttäytyminen
- Cap (capFactor): asemalla oleva stage 90 %, tuleva stage 50 %. Toteutus soveltaa capin jokaisessa CHECK_RESOLVE-iteraatiossa jäljellä olevaan flexiin → geometrinen kulutus monessa iteraatiossa (50 % jäljellä olevasta → käytännössä ~100 % kuluu useissa kierroksissa). Tämä poikkeaa dokumentoidusta “kerran per stage” -tarkoituksesta.
- lockedStages: jos stage lukitaan DELAY:lle, ADVANCE estyy myöhemmissä iteraatioissa (myös eri konfliktipareissa), mikä voi jättää suuren flex_downin käyttämättä.
- Konfliktien käsittelyjärjestys: CHECK_SORT aikajärjestyksessä; pienet konfliktit voivat kuluttaa joustot ennen kriittistä deficitiä.

## Tiedon hierarkia ja päivitys
- batch.calc_time_s = vain nykyinen stage; muut staget programissa (program[stage].calc_time). 
- resolveConflict actions → propagateDelayToBatch (stage=nyt) + CHECK_UPDATE_PROGRAM (kirjoittaa ohjelmaan ja synkronoi batchin, stage 0 poikkeus). 
- CHECK_RECALC_SCHEDULE lukee batch.calc_time_s nykyiseen stageen ja ohjelman tuleviin stageihin; synkronoi min/max vain kun erä on asemalla.
- CHECK_RECALC_TASKS rakentaa tehtävät aikatauluista, poistaa in-flight-duplikaatit, ottaa huomioon cross_transfer.

## Tunnetut ongelmat (havaittu lokien ja analyysin perusteella)
1) Cap geometrinen kulutus: useat iteraatiot syövät lähes kaiken flexin (esim. B13s9: ~96 % käytetty). 
2) Lukitus estää strategianvaihdon: DELAY-lukko blokkaa ADVANCE:n, vaikka se olisi ainoa toimiva ratkaisu (B11s12:n 300s flex_down jäi käyttämättä → B13s9 ei ratkea). 
3) Priorisointi aikajärjestyksessä: pienet konfliktit kuluttavat flexin ennen kriittistä deficitiä (79s tapaus). 
4) gap_to_prev rajoittaa flex_down=0, jos edeltävä tehtävä kiinni → teoriassa 60s, käytännössä 0s. 

## Mitä tämä dokumentti ei tee
- Ei määritä tavoitetilaa tai korjauksia; kuvaa vain nykyisen käyttäytymisen ja havaitut puutteet. 
- Ei muuta Toimintakuvausta. Korjaukset vaativat erillisen suunnitelman/RFC:n ja toteutuksen.

## Suositeltu jatkopolku (erilliseen RFC:hen)
- Cap: tee cap absoluuttisena (orig_flex * factor) tai yksi sovellus per stage/menetelmä per DEPARTURE-sykli.
- Lukitus: salli fallback-strategia, kun muut keinot eivät riitä (soft lock). 
- Konfliktiprioriteetti: käsittele deficit-suurusjärjestyksessä tai tee kaksivaiheinen priorisointi.
- gap_to_prev: tarkenna, pitäisikö sallia osa flex_downista, jos edeltävä tehtävä on pysyvä pullonkaula.
