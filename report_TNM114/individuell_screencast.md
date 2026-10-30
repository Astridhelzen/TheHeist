# Individuell screencast – The Heist

Underlag granskat 30 oktober 2026, revision `e1fd90e`. Förslag: cirka 12 minuter, på svenska. Tiderna inkluderar demonstration och växling mellan spel och kod; replikerna är stödord att utveckla, inte ett manus som måste läsas ordagrant.

Uppgiften på bilden kräver 5–15 minuter, egen röst och en förklaring av teknik och design som visar förståelse för implementationen. Ansikte som picture-in-picture är rekommenderat. Den fullständiga bedömningsmatrisen har inte ingått i underlaget, så kontrollera även den. Deadline i bilden är 31 oktober.

Din individuella arbetsfördelning är ännu inte angiven. Säg därför ”vi” om gemensamma lösningar. Fyll i ditt eget bidrag där det står hakparenteser; tillskriv dig inte automatiskt allt i projektet. Att förklara kod du förstår är något annat än att påstå att du ensam har skrivit den.

## Körschema

| Tid | Visa på skärmen | Förklara |
|---|---|---|
| 0:00–0:45 | Startmenyn och några sekunder gameplay | Idé, mål och ditt eget bidrag |
| 0:45–1:30 | Scenpanelen i Godot | Hur projektet är uppbyggt |
| 1:30–2:30 | Gå, spring och smyg; ljudringen | Spelarens val och återkoppling |
| 2:30–4:15 | Vakt patrullerar; `guard.gd` | FSM och tillståndsbyten |
| 4:15–5:45 | Ficklampan och ett gömställe; synfunktionerna | Synfält, avstånd och fri sikt |
| 5:45–6:45 | Ljud bakom en vakt; `hear_noise()` | Händelsebaserad hörsel och prioritering |
| 6:45–8:00 | Navigation och en trappa | Skillnaden mellan beslut, väg och fysisk rörelse |
| 8:00–9:00 | Passerkort, valv, larm och flykt | Signaler och ändrade AI-förutsättningar |
| 9:00–10:00 | Sittande vakten och en ny visuell detalj | Återanvändning och tekniska designval |
| 10:00–11:15 | Ett konkret fel och dess kod/test | Felsökning och verifiering |
| 11:15–12:00 | Eget bidrag och förbättringsidé | Reflektion och begränsningar |

## 0:00–0:45 – Idé och individuellt ansvar

**Visa:** startmenyn och kort gameplay. Spela inte igenom hela introt här.

**Du kan säga:**

> The Heist är ett tredjepersonsspel där spelaren ska hitta ett passerkort, öppna bankvalvet, ta pengarna och fly tillbaka till bilen. Utmaningen är att undvika vakter som reagerar på syn, fotsteg och larm. Mynten ger ett extra skäl att utforska och ta risker. Jag har framför allt arbetat med [dina faktiska delar]. Jag kommer att visa hur spelbeteendet hänger ihop med koden och varför vi har valt de här lösningarna.

Nämn ett konkret eget beslut, exempelvis en interaktion, en AI-regel, en banändring eller ett fel du själv felsökt. Undvik en lång uppräkning av funktioner.

## 0:45–1:30 – Projektets struktur

**Visa:** en bans scenhierarki och `Guard/guard.tscn`.

**Du kan säga:**

> Vi har delat upp spelet i återanvändbara scener och skript. Spelaren och vakterna är CharacterBody3D-noder. Vaktens scen innehåller bland annat en NavigationAgent3D, en RayCast3D och en AnimationPlayer. Banorna placerar ut instanser och anger patrullpunkter. Därför kan flera vakter använda samma logik utan att vi kopierar hela implementationen.

> Vi använder också grupper och signaler. Gruppen guards gör att andra system kan hitta vakterna. Signalen taken från bytet kopplar ihop stölden med exempelvis larm och flyktmöjlighet.

**Källor:** `Guard/guard.tscn`, `Guard/guard.gd`, `Assets/Models/Money/money.gd`, `Levels/Level_1/exit.gd`.

## 1:30–2:30 – Spelarens val och ljudringen

**Visa:** samma korta sträcka gående, springande med Shift och smygande med Ctrl/C. Stanna också stilla i hukad position.

**Du kan säga:**

> Spelaren kan välja mellan olika rörelsehastigheter. Att springa är snabbare men ger ett större hörselområde. När jag smyger blir cirkeln mindre, och när jag står still skapas inget fotstegsljud för AI:n. Det gör valet mellan fart och försiktighet synligt för spelaren.

> Tekniskt är ringen återkoppling. Själva upptäckten sker när ett fotsteg skickar en signal. NoiseEmitter kontrollerar avståndet till varje vakt och anropar hear_noise för dem som befinner sig inom radien. Vakten behöver alltså inte kollidera med själva cirkeln.

**Kod att visa:** `Player/noise_emitter.gd`: `_physics_process()` och `_make_noise()`. Visa kopplingen från `Player/footsteps.gd` om tid finns.

**Aktuella standardvärden:** smyg 0,5, gång 2 och löpning 4 enheter i ljudradie. Spelarens hastigheter är 1,0 / 1,7 / 5,0. Det är avståndet mellan kropparnas positioner i 3D som kontrolleras, inte enbart avstånd på golvplanet.

## 2:30–4:15 – Vaktens finite-state machine

**Visa:** en vakt som patrullerar. Öppna sedan `enum State`, `_physics_process()` och ett par korta state-funktioner i `Guard/guard.gd`.

**Du kan säga:**

> Vaktens beslutsfattande är en finite-state machine, alltså en tillståndsmaskin. Den har åtta namngivna tillstånd, och varje tillstånd beskriver vad vakten gör just nu. Det här är regelbaserad spel-AI, inte en maskininlärningsmodell.

> Under PATROL går vakten mellan markerade punkter och stannar för att titta runt. Om den hör ett ljud kan den börja undersöka platsen i INVESTIGATE. Om den ser spelaren byter den till CHASE. Tappar den sikten fortsätter den en kort stund i PURSUE. Därefter undersöker den en position och kan gå tillbaka via RETURN. IDLE används när det inte finns någon patrullrunda. ATTACK hanterar fångandet, och RUSH används när larmet skickar vakten mot valvet.

> Vi valde den här strukturen eftersom beteendena är tydliga och det går att följa varför ett tillståndsbyte sker. En nackdel är att fler specialfall kräver tydliga prioriteringsregler för att inte olika reaktioner ska störa varandra.

Visa exempelvis villkoret för `CHASE → PURSUE` och förklara villkoret med egna ord. Läs inte upp hela skriptet.

**Viktigt:** PURSUE uppdateras fortfarande mot spelarens aktuella position även utan sikt. Beskriv det inte som korrekt minne av den senast sedda positionen. När tiden löper ut sparas spelarens position då som undersökningsmål.

## 4:15–5:45 – Hur vakten ser spelaren

**Visa:** ficklampans kon. Jämför en synlig spelare med en spelare bakom en vägg. Smyg för att minska risken att hörseln blandas ihop med synen.

**Du kan säga:**

> Upptäckt kräver både att spelaren ligger inom vaktens synområde och att det finns fri sikt. Före larmet utgår synområdet från ficklampans riktning, vinkel och räckvidd. RayCast3D kontrollerar sedan om den första kroppen längs strålen är spelaren. En vägg kan därför blockera upptäckten även om spelaren är nära.

> Efter larmet aktiveras ett bredare synfält, men kontrollen av fri sikt finns kvar. Ficklampans färg ändras också när spelaren är i ljuset och synlig, vilket hjälper spelaren att förstå upptäckten.

**Kod:** `_can_see_player()`, `_is_in_flashlight()`, `_has_line_of_sight()` och `_is_in_lit_view()` i `Guard/guard.gd`.

Ficklampan har 6,5 enheters räckvidd och 30 graders halvvinkel, alltså 60 graders total kon. Larmsynen har 20 enheters räckvidd och 75 grader åt varje sida, totalt 150 grader horisontellt. Du behöver inte säga alla tal; förklara hellre vad testerna gör.

Det är explicit kod som kontrollerar synområdet. AI:n analyserar inte bildpixlar eller all faktisk belysning i scenen.

## 5:45–6:45 – Hur vakten reagerar på ljud

**Visa:** gå eller spring bakom en vakt, inom ljudradien men utanför dess ursprungliga synfält. Visa `hear_noise()` och `_turn_towards_sound()`.

**Du kan säga:**

> Ett ljud ger vakten en position att reagera på. Om ljudet kommer mer än ungefär 30 grader från det håll vakten tittar åt stannar den och vrider sig mot ljudet under en kort reaktionstid. Om den då får syn på spelaren går den till CHASE. Annars undersöker den ljudets position.

> Under CHASE, PURSUE och ATTACK ignoreras nya ljud, så att vakten inte avbryter en pågående konfrontation för varje fotsteg. Under RUSH kan den reagera genom att titta mot ljudet, men behåller målet vid valvet.

**Begränsning att kunna förklara:** hörseln har inget test för väggar. Den är en avståndsmodell, inte en simulering av hur ljud sprids genom rum. Ringen visar också närhet till vakter, inte ett säkert besked om vilket state varje vakt har.

## 6:45–8:00 – Navigation, kollision och trappor

**Visa:** navigationens yta i editorn och en kort passage runt ett hinder eller uppför en trappa.

**Du kan säga:**

> Tillståndsmaskinen bestämmer vart vakten vill gå. NavigationAgent3D ger nästa position på vägen dit, medan vårt rörelseskript faktiskt flyttar kroppen. Det är alltså tre olika saker: att välja ett mål, att hitta en väg och att ta sig fram utan att fastna i geometrin.

> Vägplaneringen använder Godots navigeringssystem och A* över navigationens förbindelser. Vi har inte skrivit en egen A*-implementation. Navigationens inställningar behöver passa figurens kollisionskapsel, annars kan en väg se möjlig ut i navigationen men vara för trång i fysiken.

> För låga kanter använder spelaren och vakterna samma rörelsehjälp. Den kontrollerar hindret framför kroppen, utrymmet ovanför och att det finns stöd efter steget innan kroppen lyfts. För trapporna använder vi också ramper och golvsnappning. Det skiljer den synliga trappan från den yta figuren faktiskt rör sig på.

**Kod:** `_update_agent_target()` och `_walk_to()` i `Guard/guard.gd`; `move()` och `_step_up()` i `Movement/ground_motion.gd`.

Den nyare steghjälpen undersöker minst 0,12 meter framför kroppen och accepterar att kroppen är nära golvet. Det hjälper när den rundade kapseln annars hänger på en kant. Den avsedda steghöjden är 0,25 meter. Höga bord och väggar ska fortfarande stoppa kroppen.

## 8:00–9:00 – Valvet och larmet

**Visa:** passerkortet, läsaren och öppningen av valvet. Använd en förberedd sekvens så att du inte måste spela om hela banan under inspelningen.

**Du kan säga:**

> Passerkortet och läsaren använder närhetskontroller och kontroll av blockerande geometri. När valvet öppnas byter vi till navigationen för öppet valv, så att vakterna kan planera en väg genom öppningen.

> När spelaren tar bytet skickas signalen taken. Den aktiverar flykten och larmet. Vakterna får bredare syn och lediga vakter kan springa till platsen där bytet fanns. Det är en känd händelseposition, inte att larmet automatiskt berättar exakt var spelaren är. En pågående jakt prioriteras framför att skickas tillbaka till valvet.

**Kod:** `_unlock()` i `Levels/All_Levels/access_card.gd`, motsvarigheten i `Levels/Level_2/vault_access.gd`, `taken` i `Assets/Models/Money/money.gd` och `alert()` i `Guard/guard.gd`.

## 9:00–10:00 – Återanvändning och nyare detaljer

**Visa:** den sittande vakten i Level 2. Välj sedan EN detalj till: handhållen ficklampa, introt eller poängsystemet.

**Du kan säga om vakten:**

> Den sittande vakten ärver den vanliga vaktlogiken. Det extra skriptet lägger till sittposen och en kort övergång när den reser sig. När den ser spelaren används samma CHASE som för de andra vakterna. Även ett ljud eller ett larm kan få den att lämna stolen. Vi återanvänder alltså perception och navigation i stället för att bygga en separat AI.

`Guard/seated_guard.gd`: `_stop_and_idle()` och `_enter_state()`. Det finns inte ett separat SITTING-state i grundmaskinens enum. Efter att ha rest sig återgår den inte automatiskt till sittposen.

**Alternativ – ficklampan:**

> Ficklampan är nu en modell i handen. En SkeletonModifier3D justerar arm och fingrar ovanpå animationen. Ljuskällans position följer lampan, medan riktningen behålls för att synbeteendet ska vara kontrollerbart.

Visa `Guard/guard_flashlight.gd`: `attach()` och `_process_modification()`.

**Alternativ – introt:**

> Under introt är banans spelprocesser avstängda och en separat kamera används. Efter sekvensen eller Skip återställs spelarkontroll, HUD och tidtagning. Mynten visas med en kort animation när spelandet börjar.

Visa `Cinematics/arrival_intro.gd`: `_ready()`, `_finish()` och `_show_coins()`.

**Alternativ – poäng:**

> Mynt och tid ger poäng, vilket skapar en avvägning mellan att utforska och att fly snabbt. Bästa resultat och upplåst Level 2 sparas separat från den aktuella scenen, så att de finns kvar när vi återvänder till menyn.

Visa `_calculate_score()` i `UI/heist_complete.gd` och `Managers/level_progress.gd`. Menyn har platshållare för fler banor, men två spelbara levlar.

## 10:00–11:15 – Ett konkret felsökningsfall

Välj det fel du själv kan förklara bäst. Om du inte själv gjorde ändringen, säg ”ett fel vi löste” och beskriv din verkliga del.

**Exempel: attack genom vägg.** Visa `_state_attack()` och ett testfall i `Tests/check_guard_attack_walls.gd`.

> Ett problem var att avståndet kunde vara kort även om en vägg låg mellan spelaren och vakten. Därför räcker inte ett avståndsvillkor för att fånga spelaren. Nu krävs fri sikt både när attacken börjar och medan fångsttimern räknas. Om ett hinder kommer emellan nollställs timern och vakten går vidare till PURSUE.

> Testet kontrollerar både att väggen stoppar attacken och att fångandet fortfarande fungerar när det är fritt framför vakten. Det är viktigt att inte bara stoppa buggen genom att råka stänga av hela attackfunktionen.

Alternativ: visa kantproblemet, `_near_ground()`/`LOOK_AHEAD` och `Tests/check_ground_motion.gd`. Förklara symtom → orsak → ändring → kontroll. Även om en kontroll passerar är det inte bevis för att alla banor är helt buggfria.

## 11:15–12:00 – Egen reflektion

**Du kan säga:**

> Det viktigaste jag lärt mig är [en verklig lärdom från ditt arbete]. Ett beteende kan se enkelt ut i spelet men kräver att beslut, navigation, kollision och visuell återkoppling stämmer överens. Jag skulle vidareutveckla vaktens kunskap om spelaren. Just nu följer PURSUE fortfarande spelarens aktuella position även när sikten är bruten. Ett mer konsekvent stealthbeteende skulle spara positionen bara när vakten faktiskt ser spelaren och sedan söka där.

> Min konkreta del var [ditt bidrag], och den ändring jag helst vill lyfta är [beslut/felsökning och varför den hjälpte spelaren].

Välj EN förbättring att förklara ordentligt. Ljuddämpning genom väggar är ett annat bra exempel. Säg inte att en förbättring redan finns om den bara är en idé.

## Förbered skärmen före inspelning

1. Öppna `Guard/guard.gd`, `Player/noise_emitter.gd`, `Movement/ground_motion.gd` och den fil som bäst visar ditt eget bidrag. Sök fram funktionerna ovan; förstora kodtexten.
2. Förbered en kort demonstration av patrull, ljudreaktion och upptäckt. Använd Godots Remote-inspektör för att visa vaktens `state` om det underlättar; enumens ordning finns i koden.
3. Förbered Level 2 så att du snabbt kan visa skrivbordsvakten. F6 kan köra den öppna banscenen direkt utan menyns intro. Visa även den riktiga menyvägen kort om du pratar om hela spelflödet.
4. Gör en kort provtagning med mikrofon. Bilden i uppgiften rekommenderar PIP; placera ansiktsbilden så att den inte täcker kod eller HUD.
5. Gör en genomkörning med timer. Sikta på 11–13 minuter och lämna marginal till gränsen 15 minuter.
6. Öppna inlämningslänken i ett utloggat fönster och kontrollera att läraren kan se videon. Kontrollera separat eventuella språkkrav och den fullständiga bedömningsmatrisen.

## Vad i den gamla rapporten du inte ska upprepa

Rapporten `article.tex` beskriver en granskning från 23 oktober. Den har inte ändrats i detta arbete.

- Attack genom vägg beskrivs som en kvarvarande begränsning. Nu finns siktkontroller både före och under attack.
- Level 2 anges ha tre vakter. Nu finns fyra vanliga vaktinstanser och en sittande, totalt fem.
- Rapportens planerade tester är inte en uppdaterad lista över projektets faktiska testskript.
- PURSUE använder fortfarande liveposition och hörseln saknar väggdämpning: dessa begränsningar gäller däremot fortfarande.
- Guard/README.md förenklar också vissa beteenden. Utgå från implementationen när README och kod skiljer sig.

## Kontroller som kördes för detta underlag

Den 30 oktober kördes `check_guard_attack_walls.gd` (nio kontroller), `check_seated_guard.gd` och `check_ground_motion.gd`. Alla rapporterade noll misslyckade kontroller. Detta är avgränsade automatiska tester och källgranskning, inte en ny fullständig manuell genomspelning eller användarstudie.

## Om du måste korta till cirka 6 minuter

Behåll: 30 sekunder introduktion/eget bidrag, 90 sekunder FSM, 90 sekunder syn och ljud, 60 sekunder navigation, 60 sekunder konkret felsökning och 30 sekunder reflektion. Ta bort rundvisningen av menyer, introt och extrafunktionerna först. Behåll konkreta kopplingar mellan det du visar i spelet och villkoren i koden.
