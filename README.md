# The Heist

Öppna `project.godot` i Godot 4.7 och kör projektet (F6 kör bara den öppna scenen).
Startmenyn väljer bana och spelar bilintrot innan spelaren får kontroll.

## Projektets struktur

- `UI/main_menu.tscn`: startmenyn.
- `Levels/Level_1/Level_1.tscn`: den spelbara första banan. `Level1.tscn` i roten är en äldre wrapper som finns kvar för kompatibilitet.
- `Level2.tscn`: den spelbara andra banan; dess miljödelar finns i `Levels/Level_2/`.
- `Levels/All_Levels/`: gemensamma saker, bland annat mynt, passerkort och gatuförlängningen som används i båda banorna.
- `Player/`, `Guard/`, `Movement/`, `Managers/`: spelare, vakt-AI, rörelse och gemensam spelstatus.
- `Cinematics/`: bilintrot.
- `Assets/`: modeller, ljud och animationskällor. Blender-original och alternativa modellversioner är sparade för fortsatt redigering.
- `Tests/`: automatiska kontroller. `Tests/Scenes/` innehåller två manuella testbanor för vakterna.
- `Tools/` och `Levels/Level_2/Tools/`: utvecklingsverktyg. De äldre Python-generatorerna återskapar ursprungliga scener och ska inte köras över handredigerade scener utan att först kontrollera skillnaderna.
- `report_TNM114/`: kursrapporten, separat från spelets innehåll.

## Kontrollera ändringar

Kör från projektmappen, med sökvägen till din Godot-installation:

```powershell
& 'sökväg/till/Godot.exe' --headless --path . --script Tests/check_seated_guard.gd
& 'sökväg/till/Godot.exe' --headless --path . --script Tests/check_arrival_intro.gd
```

Övriga `check_*.gd` testar bland annat trappor, passage mellan möbler, bankutgångar och attacker genom väggar.
`Tools/bake_guard_navigation.gd` uppdaterar navigeringen för stängt och öppet valv efter ändringar av kollisionsgeometrin.

## Importfiler och original

`.godot/` är Godots genererade cache och ska inte versionshanteras. Filer som slutar på `.import` och `.uid` bredvid projektfilerna hör däremot till importinställningar och resursidentiteter och ska behållas.

Typsnittsmappen innehåller de tre typsnittsfiler som menyerna använder samt deras licenser. Modellernas original, texturer, licenser och rapporten ska inte tas bort enbart för att de saknar en direkt scenreferens. Se `CREDITS.md` för upphovspersoner och licenser.
