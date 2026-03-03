# Departure JS vs ST — eroanalyysi (luokittelu)

Päiväys: 2026-03-03

## Tavoite
Tämä dokumentti erottaa kaksi asiaa:
1. **Suunnitellut erot** (arkkitehtuuri-/PLC-rajoitteista johtuvat, hyväksyttävät)
2. **Toiminnalliset poikkeamat** (muuttavat käytöstä tai aiheuttavat riskejä)

Vertailun kohde:
- JS: PLC Simulator/sim-core/departureScheduler.js (+ transporterTaskScheduler.js)
- ST: openplc/OpenPLC/src/DEP_FB_*.st (+ TSK_FB_*.st)

---

## A) Todennäköisesti suunnitellut erot

### A1. Datamallin nimeäminen ja rakenne
- JS käyttää batch_id, stage, treatment_program, jne.
- ST käyttää batch_code, cur_stage, prog_id, state, jne.
- Tämä on selvästi porttaus-/integraatiokerrosero.

**Luokitus:** suunniteltu.

### A2. Kapasiteettirajat (MAX_UNITS / MAX_TRANSPORTERS / queue-koot)
- JS ympäristö on mitoitettu selvästi suuremmaksi.
- ST on sidottu PLC-tyyppien kiinteisiin taulukoihin (10 yksikköä, 3 nostinta, 10 taskia/jono).

**Luokitus:** suunniteltu (PLC-resurssirajoite).

### A3. Vaihenumerointi ja ajo vuorotellen (TSK/DEP)
- JS: omat phase-alueet, save-alivaiheet, async I/O.
- ST: erillinen master-orchestrator (STC_FB_MainScheduler), vuorottelu skannisyklillä.

**Luokitus:** suunniteltu (eri ajomalli).

### A4. JSON/hashmap ↔ kiinteät arrayt
- JS käyttää hash map -tyylisiä rakenteita ja dynaamisia listoja.
- ST käyttää kiinteitä tyyppitauluja.

**Luokitus:** suunniteltu (IEC61131-3 + PLC-muistimalli).

### A5. Recalc-loopin rakenne
- JS: eksplisiittiset vaiheet CHECK_RECALC_SCHEDULE + CHECK_RECALC_TASKS.
- ST: lyhyempi silmukka (paluu CALC_SCHED/CREATE_TASKS/FIT-polkuun).

**Luokitus:** todennäköisesti suunniteltu, **jos** lopputulos säilyy.

---

## B) Toiminnalliset poikkeamat (ei pelkkä arkkitehtuuriero)

### B1. Stage 0:n lopullinen tallennus aktivoinnissa
- JS: aktivoinnissa stage 0:n calc/min/max luetaan sandboxin lopullisista arvoista.
- ST: pendingiin kirjoitetaan stage0_pending_delay (viive), ei välttämättä sama kuin stage 0:n lopullinen calc.

**Vaikutus:** aktivoidun erän stage 0 aikaparametrit voivat poiketa JS:stä.

**Luokitus:** toiminnallinen poikkeama.

### B2. Idle-slot fitin marginaalilogiiikka (stage 1+)
- JS: conflictMarginSec rajaa slotin geometriaa; marginSec toimii viiveen kirjauskynnyksenä.
- ST: sama i_margin_s käytössä sekä slotin aikarajoissa että joustokynnyksessä.

**Vaikutus:** ST on tiukempi; voi hylätä/viivästää tapauksia jotka JS hyväksyy.

**Luokitus:** toiminnallinen poikkeama.

### B3. In-flight taskien käsittely
- JS muodostaa erikseen in-flight taskit reaaliaikaisesta transporter-tilasta ja lisää ne fit-laskentaan.
- ST nojaa task-jonoihin + current_station-ankkuriin; ei vastaavaa eksplisiittistä in-flight rikastusta.

**Vaikutus:** aktiivisen siirron aikana syntyvät slotit/konfliktit voivat erota.

**Luokitus:** toiminnallinen poikkeama.

### B4. Waiting-erien valintakriteeri
- JS: waiting käytännössä stage 90 + unit.target='none'.
- ST: waiting = state NOT_PROCESSED + target TO_NONE + valid program.

**Vaikutus:** eri erä voi tulla sovitukseen riippuen data-tilasta.

**Luokitus:** toiminnallinen poikkeama (ellei tietomalli ole tarkoituksella muunnettu 1:1-vastaavaksi).

### B5. FIFO-lajittelun avain
- JS: loaded_s/start_time_s.
- ST: batch.start_time.

**Vaikutus:** lähtöjärjestys voi poiketa.

**Luokitus:** toiminnallinen poikkeama.

### B6. Poikittaissiirron (cross-transfer) huomiointi
- JS: schedule+task generation huomioi cross_transfer/cross_end_station.
- ST taskien muodostus ei käytä vastaavaa cross-end semantiikkaa.

**Vaikutus:** nostinvalinta/siirtoaika voi erota cross-tapauksissa.

**Luokitus:** toiminnallinen poikkeama.

### B7. Aikaresoluutio (float vs integer sekunnit)
- JS käyttää laajalti desimaalitarkkuutta.
- ST pyöristää useissa kohdissa kokonaissekunneiksi.

**Vaikutus:** rajatapaukset (juuri mahtuu / ei mahdu) voivat erota.

**Luokitus:** toiminnallinen poikkeama (osin väistämätön).

### B8. Idle-slot horisontti
- JS: oletus 10h horizon.
- ST: käytännössä avoin horizon loppuslotissa.

**Vaikutus:** ST voi löytää sovituksen myöhemmältä aikaväliltä, jossa JS ei enää etsi.

**Luokitus:** toiminnallinen poikkeama.

### B9. Synkronointiehto “stable”
- JS odottaa READY + conflictResolved.
- ST odottaa i_tsk_phase>=10000 + g_dep_stable (joka tällä hetkellä sidottu käytännössä samaan phase-ehtoon).

**Vaikutus:** DEP voi käynnistyä eri hetkellä kuin JS:ssä, jos "conflictResolved" ja "phase>=10000" divergoivat.

**Luokitus:** toiminnallinen poikkeama.

### B10. Overlap-flagien indeksialue (kriittinen)
- DEP_OVERLAP_T.flags on määritelty [101..130], mutta käyttölogiikka käsittelee 0..200.

**Vaikutus:** potentiaalinen out-of-range-tilanne tai virheellinen overlap-käyttäytyminen.

**Luokitus:** bugi/korjattava poikkeama.

---

## C) Luokittelu: mitä ei tarvitse harmonisoida 1:1

Seuraavat erot voidaan hyväksyä, jos regressiotesteissä käyttäytyminen säilyy:
- Datakenttien nimeäminen ja sisäinen representaatio
- Vaihenumeroinnin ja alavaiheiden erilainen järjestys
- Datan kopiointi/hashmap-vs-array toteutustapa
- Vuorottelu TSK/DEP skannisyklillä

---

## D) Luokittelu: mitä pitää harmonisoida 1:1-tavoitteessa

Ensisijaiset korjattavat kohdat:
1. Stage 0 tallennus aktivoinnissa (B1)
2. Fit-marginaalien semantiikka (B2)
3. In-flight taskien vaikutus idle-slotteihin (B3)
4. Waiting-valintaehto + FIFO-avain (B4, B5)
5. Cross-transfer tehtävämuodostuksessa (B6)
6. Overlap flags indeksialue (B10, kriittinen)

---

## E) Huomio “suunnitellut erot”

Kyllä — osa aiemmin listatuista kohdista on selvästi suunniteltuja (PLC-porttausmalli). Tämä dokumentti erottaa ne erikseen kohdassa A. Kohdassa B ovat ne erot, jotka vaikuttavat itse lähtölupasovituksen lopputulokseen tai turvallisuuteen.
