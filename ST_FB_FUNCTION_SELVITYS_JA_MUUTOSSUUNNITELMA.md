# ST FB → FUNCTION -selvitys ja muutossuunnitelma

Päiväys: 2026-03-03

## 1) Tarkoitus
Tämä dokumentti kokoaa nykytilan:
- mitkä `*_FB_`-tiedostot oikeasti tarvitsevat kutsujen välisen sisäisen tilan
- mitkä ovat käytännössä stateless-laskureita/wrappereita
- mitä muutoksia tarvitaan, jos osaa FB:istä halutaan konvertoida `FUNCTION`-muotoon

---

## 2) Yhteenveto (nykyinen toteutus)

### 2.1 FB:t, jotka **pitää säilyttää FB:nä** (tila säilyy yli kutsun)

1. `DEP_FB_Scheduler.st`
2. `TSK_FB_Scheduler.st`
3. `STC_FB_MainScheduler.st`
4. `STC_FB_Calibrate.st`
5. `STC_FB_MeasureMoveTimes.st`
6. `STC_FB_CalcMoveTimes.st` (edge detection `prev_run`)

Peruste: niissä on vaihe-/sekvenssitila, laskureita, reunaehdotusta tai kalibrointisekvenssiä, joka jatkuu skannista toiseen.

### 2.2 FB:t, jotka ovat käytännössä stateless (teknisesti konvertoitavissa)

Näissä sisäiset muuttujat ovat per-kutsu väliaikaisia, eikä FB:llä ole omaa välitilan tarvetta:
- `DEP_FB_CalcIdleSlots.st`
- `DEP_FB_CalcOverlap.st`
- `DEP_FB_FitTaskToSlot.st`
- `DEP_FB_OverlapDelay.st`
- `DEP_FB_Sandbox.st`
- `SIM_FB_ClearConfig.st`
- `SIM_FB_RunTasks.st`
- `SIM_FB_XMotion.st`
- `SIM_FB_ZMotion.st`
- `STC_FB_CalcHorizontalTravel.st`
- `STC_FB_CalcTransferTime.st`
- `STC_FB_ClearTaskQueues.st`
- `STC_FB_CollectActiveBatches.st`
- `STC_FB_DispatchTask.st`
- `STC_FB_EventQueue.st`
- `STC_FB_FindStation.st`
- `STC_FB_FindTransporter.st`
- `STC_FB_NoTreatmentStates.st`
- `STC_FB_ShiftSchedule.st`
- `STC_FB_SortTaskQueue.st`
- `STC_FB_UpdateUnitLocation.st`
- `TSK_FB_Analyze.st`
- `TSK_FB_CalcSchedule.st`
- `TSK_FB_CreateTasks.st`
- `TSK_FB_NoTreatment.st`
- `TSK_FB_Resolve.st`
- `TSK_FB_SwapTasks.st`
- `TWA_FB_CalcLimits.st`

Huomio: osa näistä käyttää globaaleja (`VAR_EXTERNAL`) tai FB-instansseja vain ympäristörajoitteen takia.

---

## 3) Vastaus kysymykseen “onko tämä vain nimien vaihto?”

Ei ole.

`FUNCTION_BLOCK` → `FUNCTION` konversio vaatii yleensä:
1. Rajapinnan uudelleenmäärittelyn (input/output)
2. Kutsujen muuttamisen (instanssikutsuista funktiokutsuiksi)
3. `VAR_EXTERNAL`-riippuvuuksien ratkaisemisen (parametrisointi tai wrapper)
4. Alifb-kutsujen mahdollisen uudelleenrakennuksen
5. Testauksen, koska ajoitus-/sivuvaikutuspolut voivat muuttua

---

## 4) Muutossuunnitelma

## Vaihe 0 — päätös linjasta
Päätetään tavoite:
- A) Minimoida muutokset (pidetään valtaosa FB:nä)
- B) Maksimoida “puhdas FUNCTION”-rakenne stateless-osille

Suositus: A + valikoitu B (vain matalariskiset utilityt).

## Vaihe 1 — No-regret refaktorointi (matalin riski)
Tee ensin utility-ryhmä, joissa ei ole tilaa eikä monimutkaisia riippuvuuksia:
- `STC_FB_FindStation.st`
- `STC_FB_FindTransporter.st`
- `STC_FB_CalcHorizontalTravel.st`
- `STC_FB_ShiftSchedule.st`
- `STC_FB_SortTaskQueue.st` (vain jos kutsupaikat yksinkertaiset)

Toimenpiteet:
- Lisää vastaavat `FUNCTION`-versiot (älä poista FB:tä heti)
- Käännä 1–2 kutsupaikkaa kerrallaan
- Varmista saman syklin tulosvertailu

## Vaihe 2 — Algoritmiset stateless-FB:t
Seuraavaksi keskivaikeat:
- `DEP_FB_CalcOverlap.st`
- `DEP_FB_OverlapDelay.st`
- `DEP_FB_CalcIdleSlots.st`
- `DEP_FB_FitTaskToSlot.st`

Toimenpiteet:
- Eristä globaalit riippuvuudet parametreiksi tai pidä ohut FB-wrapper
- Tee rinnakkaisajovertailu (FB vs FUNCTION) samoilla syötteillä

## Vaihe 3 — Käyttötapojen yhtenäistys
- Päivitä kutsukonventiot projektissa
- Pidä tarvittaessa “compat wrapper” vanhoille kutsuille
- Dokumentoi standardi: milloin `FUNCTION`, milloin `FB`

## Vaihe 4 — Ei konvertoida (stateful-ydin)
Nämä jätetään FB:ksi:
- `DEP_FB_Scheduler.st`
- `TSK_FB_Scheduler.st`
- `STC_FB_MainScheduler.st`
- `STC_FB_Calibrate.st`
- `STC_FB_MeasureMoveTimes.st`
- `STC_FB_CalcMoveTimes.st` (ellei edge-detektio siirretä ulos)

---

## 5) Riskit

1. **Semantiikkariski**: sama laskenta, eri sivuvaikutusjärjestys.
2. **Globaaliriippuvuusriski**: `VAR_EXTERNAL`-käyttö FUNCTIONissa ei ole suora drop-in.
3. **Ajallinen riski**: PLC-syklin käyttäytyminen voi muuttua, jos kutsupolku muuttuu.
4. **Ylläpitoriski**: sekakäyttö (FB + FUNCTION) ilman selkeää standardia.

---

## 6) Testauskriteerit (hyväksyntä)

Konversion jälkeen vähintään:
1. Kääntyy ilman uusia virheitä.
2. Saman input-jakson tulokset identtiset (tai erot dokumentoitu):
   - task queue
   - schedule
   - conflict flags
   - departure activation
3. Ei muutosta stateful-FB:iden vaihekäyttäytymiseen.
4. Regressiotesti vähintään 3 skenaariolla:
   - normaali virtaus
   - overlap-konflikti
   - waiting batch + stage 0 sovitus

---

## 7) Suositus

Tee **valikoiva konversio**:
- Konvertoi vain utility/stateless-osat, joissa hyöty > riski.
- Jätä scheduler- ja kalibrointiydin FB:ksi.
- Käytä wrapper-strategiaa, jos globaaliriippuvuudet tekevät suorasta konversiosta hankalan.

Näin saadaan selkeämpi rakenne ilman että ajonaikainen käyttäytyminen rikkoutuu.
