# Hold the Keep

Isometrisches Tower Defense im Mittelalter in **Godot 4.7.2** (GDScript, 3D mit Orthokamera), Renderer
`gl_compatibility`, 1280x720 (stretch `canvas_items`, `expand`). Ziele: Android (Debug-APK als Alpha-Release),
Browser (GitHub Pages). Sprache im Code: Deutsch, Oberfläche Deutsch und Englisch, Titel Englisch. Lizenz: GPL v3.

Spielregeln und Werte: `docs/GAME_DESIGN.md`.

## Aufbau

- `scenes/menu.tscn` (`scripts/menu.gd`): Kartenwahl, setzt `Main.map_id`. Hauptszene ist das Menü.
  Kartenvorschau gezeichnet in `scripts/map_preview.gd` (`MapPreview`).
- `scenes/main.tscn` (`scripts/main.gd`, `class_name Main`): baut die Karte (Kacheln per MultiMesh), Wellen,
  Gold, Leben, Eingabe (Maus und Touch getrennt, emulierte Mausereignisse werden ignoriert).
- `scripts/map_data.gd`: Karten als Text (`MAPS`, Reihenfolge im Menü `ORDER`). Zeichen siehe Kopfkommentar.
  Kontrollpunkte 1 bis 9 laufen die Gegner der Reihe nach ab, dann die Burg (`waypoints`).
- `scripts/board.gd`: Wegfindung (AStarGrid2D, schräg nur ohne Ecken schneiden), Bauregeln (`check_build`:
  kein Abschnitt darf versperrt, kein Gegner eingesperrt werden), Abschnittslängen für die Zielwahl.
- `scripts/defs.gd`: alle Werte: `TOWERS`, `SPECS` (zwei Spezialisierungen je Turm auf Stufe 3), `ENEMIES`
  (Varianten derselben Figur über `tint`, `size`, `armor`, `regen`, `pack`), Wellen (`wave`, gemischt ab Welle 6).
- `scripts/tower.gd`, `enemy.gd`, `projectile.gd`: Türme (Modell aus Teilen oder Figur), Gegner (Abschnitt für
  Abschnitt, Fliegende auf fester Flugroute), Geschosse (Pfeil, Bolzen, Fels im Bogen, Magie, Feuer, Kettenblitz).
- `scripts/hud.gd`: Oberfläche im Code gebaut (Holz mit Messingrand, Pergamentknöpfe, `Hud.make_theme()`),
  Turmbilder per SubViewport, Turm-Karte neben dem Turm, Lebensbalken als 2D-Overlay. Symbole zeichnet
  `scripts/glyph.gd` (`Glyph.make("coin")`) als Vektoren, weil die Schrift nur Latein-1 kann.
- `scripts/sfx.gd` (Autoload `Sfx`): Klänge aus `assets/audio/`, `Sfx.play(id)` / `Sfx.play_at(id, pos)`,
  Lautstärke je Klang in `VOLUME`, Ton aus in `user://settings.cfg`. Klänge neu erzeugen: Auswahl in
  `tools/import_sfx.py` (`SOUNDS`), Rohdateien in `tools/sfx_src/` (mit `.gdignore`), `python3 tools/import_sfx.py`
  (mit Paketordner als Argument werden die Rohdateien vorher kopiert).
  Musik: `Sfx.music(&"build"|&"battle"|&"")`, Schleifen neu erzeugen mit `python3 tools/make_music.py` (reines
  Python), Import mit QOA-Kompression und Schleife (`edit/loop_mode=2` in den `.import`-Dateien).
- `scripts/settings.gd` (Autoload `Settings`): Schwierigkeit, Grafikstufe, Bestwerte je Karte und Schwierigkeit
  in `user://settings.cfg`, laufendes Spiel in `user://savegame.cfg` (`Main.snapshot`/`_restore`, nur zwischen
  Wellen). Test, Bot und Screenshots leiten `Settings.file` und `Settings.save_file` auf eigene Dateien um.
- `scripts/ui_scale.gd` (Autoload `UiScale`): vergrößert die Oberfläche auf Touch-Geräten, `narrow` im
  Hochformat, `compact` quer auf Handys (Am Rechner: `--resolution 1920x864 -- --touch-ui`), `safe` für Notch und
  runde Ecken (vortäuschen mit `--notch`). HUD und Menü hängen an `UiScale.changed`. Am Rechner testen mit `-- --touch-ui` und
  `--resolution 864x1920`.
- `scripts/figure.gd` (`Figure.create(key)`): animierte Figur. Skelett-Figuren werden beim ersten Gebrauch
  in Einzelbilder umgerechnet (Autoload `FigureStage` als Platz im Szenenbaum), weil Skinning auf manchen
  Handy-Browsern unsichtbar bleibt. Headless bleibt das Originalmodell.
- `scripts/path_view.gd`: Pfeilspur des Gegnerwegs, Vorschau beim Bauen über `Board.full_path_with`.
- `scripts/camera_rig.gd`: isometrische Orthokamera (45°, 35,26° von oben), Verschieben, Zoomen, Drehen in
  Vierteldrehungen. Türme vor der Bauvorschau blendet `Main._fade_cover` aus (`Models.fade`, über
  `material_override`, weil `GeometryInstance3D.transparency` im Compatibility-Renderer nicht wirkt).

## Inhalte

- 3D-Modelle von Kenney (CC0) in `assets/models/<paket>/` mit eigener `Textures/colormap.png` je Paket.
  Neue Modelle: Liste in `tools/import_kenney.py` ergänzen, Pakete von kenney.nl entpacken,
  `python3 tools/import_kenney.py <Ordner>`. Modelle laden über `Models.make("castle/wall")`.
- Belagerungswaffen schauen im Modell nach -x und stehen 0,2 tiefer, Graveyard-Figuren ebenfalls (`lift`).
- Schrift `assets/fonts/MedievalSharp.ttf` (OFL). App-Icons in `assets/icon/` (gerendert mit
  `scenes/dev/shot.tscn -- <Ordner> icon`, dann verkleinert).

## Fallstricke

- **Texte immer übersetzen:** `tr("...")` in Knoten, `Lang.t("...")` in statischen Funktionen, Englisch in
  `Lang.EN` (`scripts/lang.gd`). Erst übersetzen, dann füllen: `tr("Welle %d") % wave`. Der Test meldet fehlende.
- **Browser hat keine Systemschrift.** Nur Zeichen aus Latein-1 plus Gedankenstrich und Mittelpunkt.
- **Web-Export ohne Threads.** Schatten und MSAA sind an, auf schwachen Geräten ggf. abschalten.
- Headless-Tests rendern nichts. Screenshots brauchen ein Fenster oder Xvfb, Software-Rendering ist langsam:
  im Screenshot-Skript mit `Engine.time_scale` vorspulen statt viele Bilder abzuwarten.
- **Kein Skinning im Handy-Browser.** Neue Figuren mit Skelett immer über `Figure.create` laden.
- **Boden wirft keinen Schatten** (sonst Schatten-Akne: Streifen und helle Dreiecke).
- Freigegebene Gegner gelten in Godot 4 nicht als `null`: `is_instance_valid` oder `alive` prüfen.
- Versionsnummer: `project.godot` (`config/version`) und `export_presets.cfg` (`version/name`, `version/code`)
  gemeinsam erhöhen.

## Tests

```bash
godot --headless res://scenes/dev/logic_test.tscn   # Wege, Bauregeln, Karten, Ausbau, vier Wellen im Zeitraffer
godot --headless res://scenes/dev/balance.tscn -- <karte> [easy|normal|hard] [turm,turm,...]   # Bot spielt 30 Wellen
godot --headless res://scenes/dev/dps.tscn   # Schaden pro Sekunde und pro Gold je Turm
godot res://scenes/dev/shot.tscn -- <Ordner> <menu|hud|icon|gegner|vier_felder|rundlauf|schlangenpfad|weites_feld>
```

Ausgabe prüfen auf `LOGIC-TEST OK`, keine Zeilen mit `FAIL` oder `SCRIPT ERROR`. Die CI führt den Test aus.
Der Balance-Bot baut nur neben den Weg (kein Labyrinth): auf Normal soll er knapp gewinnen oder spät verlieren.
Einen Turm vergleichen: im dritten Argument einen Platz der Standardmischung tauschen (siehe `balance.gd`).

## Release

1. Version in `project.godot` und `export_presets.cfg` erhöhen (Code +1).
2. Test laufen lassen, committen, pushen.
3. Annotierten Tag mit der Notiz pushen: `git tag -a alpha-X.Y.Z -m "<Änderungen>"`, `git push origin alpha-X.Y.Z`.
   `.github/workflows/release.yml` prüft die Version, testet, baut die APK und legt das Prerelease an. Gleicher
   Schlüssel für alle APKs nur mit Secret `DEBUG_KEYSTORE_BASE64`. Keine `v*`-Tags.
4. Lokal bauen geht weiter: `ANDROID_HOME=~/.local/opt/android-sdk tools/build_android.sh` (JDK 17).
5. Die Web-Version baut `.github/workflows/pages.yml` bei jedem Push auf `main`.

## Konventionen

- Commits von `aikitori <88290076+aikitori@users.noreply.github.com>`, Nachrichten auf Deutsch.
- Nie Keystores, Passwörter oder Geheimnisse einchecken. Keine Modellnamen in Code, Dokumenten oder Releases.
- Code-Kommentare auf Deutsch, knapp, nur wo das Warum nicht offensichtlich ist.
- Neue Funktionen in `docs/GAME_DESIGN.md` festhalten.
