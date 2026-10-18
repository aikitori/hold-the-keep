# Hold the Keep – Spielregeln

## Idee

Tower Defense wie in den Warcraft-III-Karten: große Karte, Gegner laufen vom Friedhof zur Burg, teils über
feste Wege, teils über freie Felder, auf denen man mit Türmen und Mauern Labyrinthe baut. Isometrische Sicht,
mittelalterlicher Stil (Kenney Castle Kit, Untote aus dem Graveyard Kit).

## Ablauf

- Start: 90 Gold, 20 Leben, 30 Wellen. Erste Welle nach 25 s, danach 15 s Pause nach dem letzten Gegner einer
  Welle. "Nächste Welle" startet sofort und gibt die halbe Restzeit in Sekunden als Gold.
- Gegner, die die Burg erreichen, kosten 1 Leben, Bosse 5. Bei 0 Leben fällt die Burg.
- Gold gibt es für jeden besiegten Gegner (Grundwert plus 1 je 6 Wellen).
- Lebenspunkte der Gegner wachsen je Welle um 13 %.

## Wellen

- Bodenwellen wechseln reihum: Skelett (schnell, schwach), Räuber, Zombie (langsam, zäh), Ork (stark).
  Ab Welle 11 mischt sich die nächste Art dazu, ab Welle 16 ein paar Geister.
- Luftwellen 4, 9, 14, ...: nur Geister. Sie fliegen geradeaus von Kontrollpunkt zu Kontrollpunkt über alles
  hinweg und werfen einen Schatten.
- Bosse: Vampir in Welle 5, 15, 25, Totengräber in Welle 10, 20, 30, jeweils mit Begleitung.

## Bauen

- Gebaut wird auf Gras (begehbar, also Teil des Labyrinths) und auf Hochflächen (nicht begehbar, Türme dort
  ändern den Weg nie). Feste Wege, Kontrollpunkte und Wald sind tabu.
- Kein Bau darf einen Abschnitt des Wegs (Start, Kontrollpunkte, Burg) ganz versperren oder einen Gegner
  einsperren, und nicht auf einem Feld mit Gegner. Gegner gehen schräg, aber nie zwischen zwei Türmen hindurch.
- Abreißen gibt 70 % des Eingesetzten zurück.

## Türme

| Turm | Gold | Trifft | Art |
|---|---|---|---|
| Mauer | 5 | – | blockiert nur |
| Schütze | 10 | Boden + Luft | Figur mit Bogen |
| Speerträger | 20 | Boden | Figur, Nahkampf, sofortiger Treffer |
| Bogenturm | 15 | Boden + Luft | schnelle Pfeile |
| Balliste | 35 | Boden | weit, stark, ein Ziel |
| Katapult | 45 | Boden | Fels im Bogen, Flächenschaden |
| Magierturm | 40 | Boden + Luft | verlangsamt |
| Himmelswacht | 30 | nur Luft | Feuerpfeile |
| Trebuchet | 90 | Boden | sehr weit, großer Einschlag |

Ziel ist immer der Gegner in Reichweite mit dem kürzesten Restweg zur Burg.

## Ausbau und Spezialisierung

- Stufe 2 und 3: Schaden x1,7, Reichweite +0,4, Nachladen x0,9 je Stufe. Kosten 80 % und 130 % des Grundpreises.
  Türme wachsen sichtbar (weitere Turmteile, größere Waffen, Wimpel).
- Auf Stufe 3 wählt man eine von zwei Spezialisierungen (Banner am Turm):

| Turm | Spezialisierung A | Spezialisierung B |
|---|---|---|
| Schütze | Langbogen (weiter, stärker) | Salve (3 Ziele) |
| Speerträger | Ritter (schwerer Stoß) | Pikenier (trifft alle rundherum) |
| Bogenturm | Feuerpfeile (Brand) | Salventurm (4 Ziele) |
| Balliste | Riesenbolzen (doppelter Schaden) | Flakballiste (trifft auch Luft) |
| Katapult | Brandtöpfe (brennender Einschlag) | Steinhagel (doppelt so schnell) |
| Magierturm | Frostmagier (starkes Verlangsamen) | Blitzmagier (Kette über 4 Gegner) |
| Himmelswacht | Sturmturm (3 Ziele) | Adlerhorst (weiter, stärker) |
| Trebuchet | Verheerung (riesiger Einschlag) | Präzision (weiter, dreifacher Schaden) |

## Karten

- **Vier Felder** (40x26): vier Baufelder, verbunden durch feste Wege.
- **Rundlauf** (36x26): Ring um eine bebaubare Hochfläche, vier Kontrollpunkte erzwingen eine Runde.
- **Schlangenpfad** (32x22): fester Weg in Schleifen durch die Hochfläche, kein Labyrinth.
- **Weites Feld** (38x24): offenes Feld, drei Kontrollpunkte oben und unten.

## Klänge

Jeder Turm hat einen Schussklang (Pfeil, Bolzen, Wurf, Feuer, Magie, Blitz, Stoß), dazu Einschläge,
Gegner-Tod (Skelette klappern, Geister heulen, Bosse brüllen beim Auftauchen), Glocke bei Schaden an der Burg,
Gong zu jeder Welle und ein Jingle bei Sieg oder Niederlage. Klänge auf der Karte sind nur zu hören, wenn die
Stelle im Bild ist; gleiche Klänge sind begrenzt (höchstens 2 bis 3 gleichzeitig, 70 ms Abstand).

## Bedienung auf Touch-Geräten

Mit Touchscreen wird die Oberfläche so skaliert, dass die kurze Bildschirmseite etwa 560 Einheiten hat
(am Rechner 720). Im Hochformat: zweite Zeile für die Knöpfe oben, Bauleiste in zwei Reihen, Menü einspaltig,
die Kamera-Zoomgröße gilt dann für die Breite.

## Ideen für später

- Mehr Karten (mehrere Startpunkte, Brücken über Flüsse), Schwierigkeitsgrade, Endlosmodus.
- Musik, Englisch als zweite Sprache, Spielstand speichern.
