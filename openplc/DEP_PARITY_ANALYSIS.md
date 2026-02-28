# DepartureScheduler JS ↔ ST parity-analyysi

**Päiväys:** 2026-02-28  
**Tavoite:** ST-toteutuksen tulee olla toiminnallisesti *täsmälleen* JS-referenssin kaltainen (`PLC Simulator/sim-core/departureScheduler.js`).  
**Käyttötarkoitus:** Muutossuunnitelman ja vaiheistuksen pohjadokumentti.

---

## 1) Yhteenveto

Nykyinen ST-Departure (`openplc/OpenPLC/src/DEP_FB_*.st`) vastaa JS:ää perusrakenteessa (sandbox, waiting-loop, ACTIVATE→WAIT_SAVE), mutta siinä on useita parity-kriittisiä eroja päätöksenteossa.

Suurin tekninen riski on, että ST hylkää eriä tilanteissa joissa JS ratkaisee tapauksen backward chainingilla, sekä että DEP→TSK pending write -rajapinta ei käsittele samoja tietoja kuin JS.

---

## 2) Koodipohja analyysille

### JS-referenssi
- `PLC Simulator/sim-core/departureScheduler.js`
- `PLC Simulator/sim-core/transporterTaskScheduler.js` (idle-slot fit / flex overflow)

### ST-toteutus
- `openplc/OpenPLC/src/DEP_FB_Scheduler.st`
- `openplc/OpenPLC/src/DEP_FB_CalcIdleSlots.st`
- `openplc/OpenPLC/src/DEP_FB_FitTaskToSlot.st`
- `openplc/OpenPLC/src/DEP_FB_CalcOverlap.st`
- `openplc/OpenPLC/src/DEP_FB_OverlapDelay.st`
- `openplc/OpenPLC/src/DEP_FB_Sandbox.st`
- `openplc/OpenPLC/src/TSK_FB_Scheduler.st` (DEP pending write kulutus)
- `openplc/OpenPLC/src/types.st` (DEP-tyypit)

### Tavoitekuvaus
- `PLC Simulator/documentation/departure_target_description.md`

---

## 3) Parity-gapit (JS vs nykyinen ST)

## G01 — Pending write -payload ei ole semanttisesti sama
**Vakavuus:** CRITICAL

**JS:** ACTIVATE tallentaa pending write -payloadin, jossa on mm. `programsByBatchId`, `schedulesByBatchId`, `batchCalcUpdates`, `currentTimeSec`; tämän jälkeen odottaa TASKS SAVE -vahvistusta (`WAIT_FOR_SAVE`).  
**ST:** DEP kirjoittaa `g_dep_pending`-rakenteeseen ohjelmat + aikataulut + aktivoitava batch/stage/time, mutta TSK kuluttaa siitä vain ohjelmat + stage-muutoksen; schedule/time-puoli jää käyttämättä.

**Vaikutus:** JS/ST eivät tee samaa write-boundary -päätöstä eikä samaa datan handoffia DEP→TSK-polussa.

**Viitteet:**
- JS: `departureScheduler.js` (ACTIVATE, pendingWriteData)
- ST: `DEP_FB_Scheduler.st` (phase 8000), `TSK_FB_Scheduler.st` (phase 10100), `types.st` (`DEP_PENDING_WRITE_T`)

---

## G02 — Backward chaining puuttuu ST:stä
**Vakavuus:** CRITICAL

**JS:** Jos stage 1+ ei mahdu idle-slottiin, käytetään backward chainingia (`needExtra` → aiempien stagejen flex_up) ennen REJECTiä.  
**ST:** `FIT_TASK` menee suoraan REJECTiin jos `fb_fit.o_result.fits = FALSE` (kommentti: "simplified: no backward chaining").

**Vaikutus:** ST hylkää tapauksia, jotka JS hyväksyy viiveketjulla.

**Viitteet:**
- JS: `departureScheduler.js` (CHECK_ANALYZE / backward chaining)
- ST: `DEP_FB_Scheduler.st` (phase 2001)

---

## G03 — `needExtra`-laskenta ei vastaa JS flex-overflow -logiikkaa
**Vakavuus:** HIGH

**JS (`fitSingleTaskToIdleSlots`)**: flex overflow palauttaa `fits:false`, `needExtra = delay - cappedFlex`.  
**ST (`DEP_FB_FitTaskToSlot`)**: `need_extra_s` jää usein nollaksi overflow-polussa, koska `best_delay` päivittyy vain hyväksytyistä (`delay <= capped_flex + margin`) ehdokkaista.

**Vaikutus:** vaikka backward chaining lisättäisiin, ST ei saa oikeaa jäljelle jäävää viivetarvetta.

**Viitteet:**
- JS: `transporterTaskScheduler.js` (`fitSingleTaskToIdleSlots`)
- ST: `DEP_FB_FitTaskToSlot.st`

---

## G04 — Stage 0 -viiveen käsittely poikkeaa
**Vakavuus:** HIGH

**JS:** Stage 0 offset voidaan kirjata, mutta analyysi jatkuu saman kierroksen aikana stage 1+ tehtäviin; vain stage 1+ viive päättää kierroksen RECALCiin.  
**ST:** Stage 0 delay `> MARGIN_S` laukaisee välittömän RECALCin (`next_phase := 1010`) ilman stage 1+ jatkoa samalla kierroksella.

**Vaikutus:** eri kierrosdynamiikka, eri hyväksyntä/hylkäys sekä eri viivekonvergenssi.

**Viitteet:**
- JS: `departureScheduler.js` (CHECK_ANALYZE, Stage 0 branch)
- ST: `DEP_FB_Scheduler.st` (phase 2000)

---

## G05 — Ensimmäisen idle-slotin lähtöankkuri ei vastaa JS:ää
**Vakavuus:** HIGH

**JS:** `slot.prevTask` puuttuessa käytetään stage 0 -pickupiin nostimen todellista sijaintia (`transporterStates`) tai fallbackina `start_station`.  
**ST:** ensimmäisen slotin `lift_station := 0`, ja fitissä `travel_to` lasketaan vain kun `from_stn > 0` → alkuperäinen siirtymä voi jäädä 0:ksi.

**Vaikutus:** stage 0 odotusaika aliarvioidaan; batch voi aktivoitua liian aikaisin.

**Viitteet:**
- JS: `departureScheduler.js` (CALC waiting stage 0 pre-calc)
- ST: `DEP_FB_CalcIdleSlots.st`, `DEP_FB_FitTaskToSlot.st`

---

## G06 — Waiting-järjestys (FIFO loaded_s) puuttuu ST:stä
**Vakavuus:** HIGH

**JS:** waiting-lista lajitellaan `loaded_s` mukaan (FIFO) ennen CHECK-vaiheita.  
**ST:** waiting-lista käytetään collect-järjestyksessä ilman sorttausta.

**Vaikutus:** eri batch-järjestys → eri aktivoitava erä saman syklin aikana.

**Viitteet:**
- JS: `departureScheduler.js` (WAITING_SORT_LOADED)
- ST: `DEP_FB_Scheduler.st` (phase 100, 1000)

---

## G07 — Waiting batch transporterissa (`location < 100`) käsitellään eri tavalla
**Vakavuus:** HIGH

**JS:** tukee odottavaa erää myös nostimessa (calcTransporterState-polku).  
**ST:** `FIT_STAGE0` hylkää suoraan kun `loading_stn < 100`.

**Vaikutus:** ST voi hylätä validin tapauksen jonka JS käsittelee.

**Viitteet:**
- JS: `departureScheduler.js` (CALC, isOnTransporter)
- ST: `DEP_FB_Scheduler.st` (phase 2000)

---

## G08 — Overlap-konfliktin ehto on ST:ssä tiukempi kuin JS:ssä
**Vakavuus:** MEDIUM

**JS:** overlap-delay tarkistaa ajallisen päällekkäisyyden kaikkiin toisen nostimen tehtäviin, jotka käyttävät overlap-alueen asemia.  
**ST:** vaatii lisäksi station-equalityn (`e_lift/e_sink == i_lift/i_sink`).

**Vaikutus:** ST voi jättää overlap-viiveen lisäämättä tilanteessa jossa JS viivästää.

**Viitteet:**
- JS: `departureScheduler.js` (`calculateOverlapDelay`)
- ST: `DEP_FB_OverlapDelay.st`

---

## G09 — Overlap-flagien domain on eri
**Vakavuus:** MEDIUM

**JS:** overlap flags `0..MAX_STATIONS` (`MAX_STATIONS=200` JS-puolella).  
**ST:** `DEP_OVERLAP_T.flags` on `ARRAY[101..130]`.

**Vaikutus:** parity voi rikkoutua, jos malli laajenee nykyisen station-alueen ulkopuolelle.

**Viitteet:**
- JS: `departureScheduler.js` (`computeOverlapStations`)
- ST: `types.st` (`DEP_OVERLAP_T`)

---

## 4) Vaiheistettu muutossuunnitelman pohja

## Phase D1 — Kriittinen handoff-pariteetti (G01)
1. Varmista, että DEP→TSK pending write -payloadin semantiikka vastaa JS:ää.
2. Päätä yksi kanoninen vastinmalli ST:lle (hash map ↔ kiinteät taulukot), mutta datasisältö säilyy funktionaalisesti samana.
3. Päivitä TSK phase 10100 kuluttamaan koko payload, ei vain osajoukkoa.

**Exit-kriteeri:** DEP activation aiheuttaa samat ohjelma/aikataulu/batch-tilapäivitykset kuin JS.

## Phase D2 — Fit/resolve-ytimen parity (G02, G03, G04, G05, G07)
1. Lisää backward chaining ST:hen (phase 2001) JS-logiikan mukaisesti.
2. Korjaa `need_extra_s`-laskenta vastaamaan JS flex-overflow -polkua.
3. Muuta stage 0 -haara niin, että analyysi jatkuu stage 1+ tehtäviin samalla kierroksella kuten JS:ssä.
4. Lisää stage 0 lähtöankkuriksi nostimen todellinen sijainti / `start_station` fallback.
5. Toteuta `location < 100` waiting-case ST:n CALC/FIT-polkuun JS:n mukaisesti.

**Exit-kriteeri:** Samat hyväksyntä/hylkäyspäätökset ja viiveketjut kuin JS testiskenaarioissa.

## Phase D3 — Ordering parity (G06)
1. Lisää waiting-listan FIFO-sorttaus (`loaded_s`) ennen batch-käsittelyä.

**Exit-kriteeri:** Aktivointijärjestys identtinen JS:n kanssa usean odottavan erän tapauksessa.

## Phase D4 — Overlap parity (G08, G09)
1. Yhdenmukaista overlap-delay ehto JS-malliin.
2. Yhdenmukaista overlap-flag domain (tai dokumentoi ja pakota sama rajaus myös JS-ajossa, jos päätetään pitää nykyraja).

**Exit-kriteeri:** Overlap-konfliktien delay-päätökset vastaavat JS:ää.

## Phase D5 — Parity-verifiointi
1. Rakenna skenaariokohtainen JS vs ST vertailuloki (samasta lähtötilasta).
2. Varmista vaihepolut, delay actions, activate/reject -päätökset ja pending write -payloadit.

**Exit-kriteeri:** Ei toiminnallisia eroja hyväksytyssä testimatriisissa.

---

## 5) Definition of Done (Departure parity)

Parity katsotaan valmiiksi vasta kun kaikki täyttyvät:

1. **Päätöspariteetti:** Samalla syötteellä JS ja ST tekevät saman `ACTIVATE`/`REJECT`-päätöksen jokaiselle odottavalle erälle.
2. **Viivepariteetti:** Delay action -joukko (stage, delay, writeTarget) on funktionaalisesti sama.
3. **Kierrospariteetti:** Kierrosten määrä ennen päätöstä on sama toleranssilla ±1 tick (PLC-scan-vuorottelu huomioiden).
4. **Handoff-pariteetti:** DEP→TSK pending write -sisältö tuottaa saman lopullisen `g_program` + `g_schedule` + `g_batch.cur_stage` -tilan.
5. **Stabiilisuus:** Ei loop-jumiutumista, ei kasvavaa driftiä toistuvissa departure-sykleissä.

---

## 6) Suositeltu toteutusjärjestys

1. **D1 (G01)** ensin: estää väärän datan commitoinnin.
2. **D2 (G02/G03/G04/G05/G07)** toiseksi: suurin vaikutus päätöksiin.
3. **D3 (G06)** kolmanneksi: aktivointijärjestyksen parity.
4. **D4 (G08/G09)** neljänneksi: overlap-käytöksen hienosäätö.
5. **D5** lopuksi: regressio- ja parity-acceptance.

Tällä järjestyksellä vältetään tilanne, jossa myöhemmät muutokset invalidioivat varhaiset testitulokset.
