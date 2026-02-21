# TASKS Scheduler – toiminnallinen kuvaus (PLC Simulator)

## Tarkoitus
Kuvaa TASKS-tilakoneen (taskScheduler.js) toiminnan, datavirrat ja tärkeimmät säännöt. Tämä tilakone pyörii joka tikillä, luo kuljetustehtävät, järjestää ne, ratkaisee tehtävien väliset konfliktit ja valmistaa sandboxin DEPARTURE-tilakonetta varten.

## Syötteet (INIT-vaihe)
- `batches.json` (runtime): erien tilat, sijainnit, ajat.
- `transporter_states.json` (runtime): nostimien tilat.
- Konteksti `ctx` (server.js): `stations`, `transporters`, `programs`, `movementTimes`, `stationIdleSince`, `pendingBatches`, kellot (`currentTimeSec`, `simTick`, `tickPeriodMs`).
- Käsittelyohjelmat: ladataan kaikille erille (`ctx.programs` tai `ctx.loadTreatmentProgram`).

## Vaihejako (phase-counter)
- 0 STOPPED, 1 INIT.
- 1000…1899 SCHEDULE: aikatauluta jokainen erä (ei stage 90), pidä olemassa oleva aikataulu jos erä on kuljetuksessa.
- 1900 SCHEDULE_SAVE: siirtymä TASKS:iin.
- 2000…2199 TASKS: rakenna tehtävät erä kerrallaan (stage 90 ei luo tehtäviä).
- 2200 SORT: järjestä tehtävät (nostin, emergency >1.0 max_time -suhde, sitten task_start_time).
- 2201 SWAP: sama asema → lift ennen sink.
- 2202 ANALYZE: ensimmäinen konflikti (analyzeTaskConflicts).
- 2203 RESOLVE: yksi konflikti / sykli (resolveConflict v3.4, lockedStages värähtelyn estoon).
- 2900 TASKS_SAVE: kerää päätökset candidateStretches ja tee departureSandbox.
- 10000 READY → 10001 SAVE (kaikki tallennukset) → END_DELAY → RESTART.

## Keskeiset säännöt ja logiikka
- **justActivated**: Kun DEPARTURE aktivoi erän, TASKS ensimmäisellä käsittelykerralla asettaa `start_time = now`, `calc_time_s = calc - elapsed`, `min_time_s = calc`, `max_time_s = 2×min`.
- **Stage 90**: ei tehtäviä TASKS:ssa; aikataulu on olemassa, mutta DEPARTURE päättää linjalle pääsyn.
- **Taskien muodostus**: `createTaskListFromSchedule` ohittaa jo suoritetut staget (paitsi stage 90), huomioi cross-transfer (lift = cross_end_station) ja rajaa nostimen `task_areas`-kelpoisuuteen; asettaa `transporter_id` vain jos täsmälleen yksi nostin kelpaa.
- **Emergency-järjestys**: jos erä on nostoasemalla ja ylittää max_time, sen tehtävä nostetaan jonon kärkeen (suurempi ylitys ensin) nostinkohtaisesti.
- **Swap**: sama asema peräkkäin samalla nostimella → vaihda, jotta nosto edeltää laskua.
- **Konfliktin analyysi**: pysähtyy ensimmäiseen konfliktiin; jos ei konfliktia → suoraan SAVE.
- **Konfliktin ratkaisu**: delay-first, yksi konflikti per sykli; lockedStages estää ristiriitaiset päätökset. Tulokset (delay/advance) talletetaan resolveHistory → candidateStretches.
- **CandidateStretches**: muutokset `calc_time`-arvoihin (±delayS) siirtyvät ohjelmiin ja, jos erä on kyseisellä stagella, myös batchiin (`updateBatchCalcTimes`).
- **Sandbox DEPARTURElle**: TASKS_SAVE luo syväkopion tilasta, poistaa stage 90 erien tehtävät, leimaa `created_s`. DEPARTURE tekee muutokset sandboxiin; SAVE-vaiheessa DEPARTUREn pendingWriteData yhdistetään.

## Tallennukset (SAVE, phase 10001)
- `schedules.json` (kaikki uudet aikataulut).
- `transporter_tasks.json` (tehtävälista).
- `task_analysis.json` (konfliktien yhteenveto; vain todelliset konfliktit).
- Käsittelyohjelmat: kirjoitetaan `programsByBatchId` (sis. DEPARTUREn muutokset).
- Stage 0 batch CSV:t: kirjoitetaan kerran / batch (overwrite: false), huomioi justActivated siirto.
- DEPARTUREn batch calc -päivitykset ja aikataulut yhdistetään ennen kirjoitusta.

## Tuotokset / seuraavat vaiheet
- Päivitetyt aikataulut ja tehtävät runtime-tiedostoihin → UI ja tilakoneen seuraava sykli.
- Departure sandbox → DEPARTURE-tilakone päättää jonosta linjalle.
- Päivitetyt ohjelmat (calc_time muutokset) tallennettu.

## Datan rajaukset ja vaikutukset
- Yksi konflikti per TASKS-sykli → nopea silmukka, mutta voi vaatia useita syklejä.
- Kuljetuksessa oleva erä säilyttää edellisen aikataulun (ei uudelleenlaskentaa kesken siirron).
- Jos `x_min/max_drive_limit` puuttuu (0) nostimelta, transporterWorkingArea lukitsee sen nykyiseen x:ään; tehtävät voivat jäädä ilman kelpo nostinta, jos `task_areas` ei kata siirtoa.

## Liittyvät moduulit
- `departureScheduler.js`: käsittelee stage 90 jonon, conflict resolution DEPARTURE-syklissä ja aktivoinnin.
- `transporterTaskScheduler.js`: aikataulutus, siirtoajat, konfliktien resoluutio, task_areas-suodatus, swap.
- `transporterWorkingArea.js`: nostimien työalueiden laskenta, drive limitit.
- `server.js`: kutsuu TASKS-tilakonetta joka tikillä, välittää ctx:n, lukee/kirjoittaa runtime-tiedostot ja yhdistää DEPARTUREn pending write -datan.
