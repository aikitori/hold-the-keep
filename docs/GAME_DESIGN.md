# Hold the Keep – Spielregeln

## Idee

Tower Defense wie in den Warcraft-III-Karten: große Karte, Gegner laufen vom Friedhof zur Burg, teils über
feste Wege, teils über freie Felder, auf denen man mit Türmen und Mauern Labyrinthe baut. Isometrische Sicht,
mittelalterlicher Stil (Kenney Castle Kit, Untote aus dem Graveyard Kit).

## Ablauf

- Schwierigkeit (im Menü): Leicht 130 Gold, 30 Leben, Gegner mit 80 % Leben; Normal 90 Gold, 20 Leben;
  Schwer 70 Gold, 10 Leben, Gegner mit 125 % Leben.
- Start (Normal): 90 Gold, 20 Leben, 30 Wellen. Erste Welle nach 45 s, danach 25 s Pause, sobald der letzte Gegner einer
  Welle besiegt ist oder die Burg erreicht hat. "Nächste Welle" startet sofort und gibt die halbe Restzeit in Sekunden als Gold.
- Ist eine Welle besiegt, gibt es 5 % Zinsen auf das Gold (höchstens 25).
- Nach dem Sieg (Welle 30) kann man endlos weiterspielen: die Wellen gehen nach denselben Regeln weiter, der
  Bestwert zählt die überstandenen Wellen.
- Gegner, die die Burg erreichen, kosten 1 Leben, Bosse 5. Bei 0 Leben fällt die Burg.
- Gold gibt es für jeden besiegten Gegner (Grundwert plus 1 je 6 Wellen).
- Lebenspunkte der Gegner wachsen je Welle um 15 %.
- Bodenwellen: 12 Plätze plus 4 je 5 Wellen, Luftwellen 10 Geister plus 1 je 2 Wellen, Bosse mit 10 plus 1 je
  5 Wellen Begleitern. Abstand beim Erscheinen 0,6 s.

## Wellen

- Wellen 1 bis 5 haben je eine Art: Skelett, Räuber, Zombie, Luftwelle, Boss mit Skeletten.
- Ab Welle 6 kommen gemischte Gruppen (je 3 bis 5 gleiche Gegner abwechselnd): 2 Arten, ab Welle 11 drei, ab
  Welle 21 vier. Ab Welle 16 sind Flieger dazwischen. Ab Welle 15 sind auch die Bossbegleiter gemischt. Eine
  neue Art kommt in ihrer ersten Welle sicher vor. Die Zusammenstellung hängt nur von der Wellennummer ab.
- Arten (ab Welle):

  | Art | ab | Eigenschaft |
  |---|---|---|
  | Skelett | 1 | schnell, schwach |
  | Räuber | 2 | ausgewogen |
  | Zombie | 3 | langsam, zäh |
  | Ork | 6 | stark |
  | Dieb | 7 | sehr schnell, wenig Leben (grün) |
  | Knochenwicht | 8 | klein, kommt im Rudel zu zweit |
  | Ghul | 11 | heilt 5 % je Sekunde, außer wenn er brennt (hellgrün) |
  | Schwarzer Ritter | 12 | Rüstung 6 (dunkel) |
  | Irrlicht | 14 | Flieger, schnell, schwach (blau) |
  | Gräber | 13 | gräbt sich unter Türmen durch: folgt dem Grundweg wie Flieger, bleibt Bodengegner (braun, halb im Boden) |
  | Schildträger | 16 | Gegner im Umkreis von 1,5 Feldern erhalten Rüstung 3 (blau, mit Schild) |
  | Orkhäuptling | 17 | groß, zäh, Rüstung 4 (rot) |
  | Seuchenzombie | 18 | zerfällt beim Tod in drei Knochenwichte (gelb) |
  | Nekromant | 21 | ruft alle 5 s zwei Skelette, die kein Gold geben (lila) |

- Rüstung zieht von jedem Treffer ab, höchstens 75 %. Magie und Feuer gehen durch. Gegen Rüstung helfen
  schwere Treffer (Balliste, Katapult) oder der Magierturm.
- Luftwellen 4, 9, 14, ...: Geister, ab Welle 14 auch Irrlichter. Sie folgen dem Grundweg der Karte (ohne
  Türme, gerade zwischen den Knicken) über alles hinweg, auch über die Kontrollpunkte, und werfen einen Schatten.
  Bauen ändert ihre Route nicht.
- Solange Bauzeit ist, zeigt die obere Leiste die nächste Welle: Arten mit Besonderheiten (Boss, fliegt,
  Rüstung, heilt, schnell, langsam, Rudel) und die Zahl der Gegner.
- Bosse: Vampir in Welle 5, 15, 25, Totengräber in Welle 10, 20, 30, jeweils mit Begleitung.

## Bauen

- Turm in der Bauleiste wählen, dann baut jeder Tipp oder Klick einen. Gedrückt halten und ziehen baut auf jedem
  überstrichenen Feld (Massenbau, auch für Mauerreihen); Felder, die nicht gehen, werden übersprungen. Im Baumodus
  verschieben zwei Finger, die rechte oder mittlere Maustaste die Karte. Ein Tipp auf einen Turm wählt ihn aus.
- Ausgewählt wird, was man sieht: ein Tipp auf den Turmkörper trifft den Turm, auch wenn darunter am Boden schon
  das Feld dahinter liegt.

- Gebaut wird auf Gras (begehbar, also Teil des Labyrinths) und auf Hochflächen (nicht begehbar, Türme dort
  ändern den Weg nie). Feste Wege, Kontrollpunkte und Wald sind tabu.
- Kein Bau darf einen Abschnitt des Wegs (Start, Kontrollpunkte, Burg) ganz versperren oder einen Gegner
  einsperren, und nicht auf einem Feld mit Gegner. Gegner gehen schräg, aber nie zwischen zwei Türmen hindurch.
- Abreißen gibt 70 % des Eingesetzten zurück, in derselben Bauzeit (noch kein Schuss, keine neue Welle) alles.

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

Zielwahl je Turm (Knopf auf der Turm-Karte): Vorderster (kürzester Restweg zur Burg, Standard), Stärkster,
Schwächster, bei Türmen für Boden und Luft auch Flieger zuerst. Bei Gleichstand der näher an der Burg.

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

Im Menü von leicht nach schwer, mit Einstufung (gemessen mit dem Balance-Bot): Schlangenpfad Einsteiger,
Vier Felder und Weites Feld Mittel, Rundlauf und Zwei Friedhöfe Anspruchsvoll.

- **Vier Felder** (40x26): vier Baufelder, verbunden durch feste Wege.
- **Rundlauf** (36x26): Ring um eine bebaubare Hochfläche, vier Kontrollpunkte erzwingen eine Runde.
- **Schlangenpfad** (32x22): fester Weg in Schleifen durch die Hochfläche, kein Labyrinth.
- **Weites Feld** (38x24): offenes Feld, drei Kontrollpunkte oben und unten.
- **Zwei Friedhöfe** (36x24): zwei Startpunkte links, die Burg dazwischen, die Gegner kommen abwechselnd. Ein
  Fluss (nicht begehbar, nicht bebaubar) teilt das Feld, zwei Brücken führen hinüber. Der Kontrollpunkt liegt am
  Ostufer: hin und zurück über den Fluss. Eine Brücke zubauen lenkt alle zur anderen, beide zu geht nicht.

## Anzeige

- Der Weg der Bodengegner liegt als gelbe Pfeilspur mit dunklem Rand auf dem Boden, ein Lichtlauf zeigt die
  Laufrichtung.
- Beim Bauen zeigt eine helle Spur den Weg, der mit dem Turm an dieser Stelle entstehen würde.
- Start (Friedhof) und Ziel (Burg) tragen große Schilder, die nie verdeckt werden, und pulsierende Ringe.
- Figuren mit Skelett (Mini Dungeon) werden als Daumenkino aus vorab umgerechneten Meshes gezeigt
  (`scripts/figure.gd`), weil manche Handy-Browser kein Skinning zeichnen.

## Klänge

Jeder Turm hat einen Schussklang (Pfeil, Bolzen, Wurf, Feuer, Magie, Blitz, Stoß), dazu Einschläge,
Gegner-Tod (Skelette klappern, Geister heulen, Bosse brüllen beim Auftauchen), Glocke bei Schaden an der Burg,
Gong zu jeder Welle und ein Jingle bei Sieg oder Niederlage. Klänge auf der Karte sind nur zu hören, wenn die
Stelle im Bild ist; gleiche Klänge sind begrenzt (höchstens 2 bis 3 gleichzeitig, 70 ms Abstand).

## Fähigkeiten

Links am Rand, jede mit Abklingzeit (zu Beginn bereit, läuft nur, solange gespielt wird):

| Fähigkeit | Abklingzeit | Wirkung |
|---|---|---|
| Glocke | 40 s | alle Gegner 4 s lang halb so schnell |
| Pechregen | 45 s | Ziel antippen (mit Touch: erster Tipp zeigt den Umkreis, zweiter löst aus): 30 Schaden (wächst wie die Lebenspunkte der Gegner) im Umkreis von 2 Feldern, geht durch Rüstung, danach Brand; trifft keine Flieger |
| Kriegshorn | 60 s | alle Türme schießen 8 s lang doppelt so schnell |

## Anzeige im Spiel

- Während einer Welle zeigt die obere Leiste, wie viele Gegner noch kommen oder unterwegs sind.
- Jeder Turm zählt seine Siege (letzter Treffer, auch durch Brand). Am Ende: besiegte Gegner, verdientes Gold,
  gebaute Türme und der Turm mit den meisten Siegen.

## Tasten am Rechner

1 bis 9 bauen (nochmal drücken wählt ab), Q W E Fähigkeiten, U ausbauen, Entf oder X abreißen, T Zielwahl,
Leertaste nächste Welle, P Pause, Esc oder rechte Maustaste bricht ab (gibt es nichts abzubrechen, öffnet Esc
die Pause, in der Pause geht es mit Esc weiter). Android-Zurück: im Spiel wie Esc, im Menü beendet es die App.

## Spielstand

Ein laufendes Spiel wird zwischen den Wellen gespeichert (nach jedem Bauen, Ausbauen und Abreißen in der Bauzeit,
am Ende jeder Welle und wenn die App in den Hintergrund geht). Das Menü bietet dann "Weiterspielen" an; wer
mitten in einer Welle geschlossen hat, beginnt diese Welle neu. Es gibt einen Platz: ein neues Spiel ersetzt ihn,
das Ende (Sieg oder Niederlage) löscht ihn. Die Schwierigkeit kommt aus dem Spielstand.

## Pause

"Pause" oben (oder Taste P) hält das Spiel an und zeigt Weiter, Neu starten und Zum Menü. Geht die App in den
Hintergrund (Anruf, anderer Tab), pausiert das Spiel von selbst.

## Musik

Zwei Schleifen in D-Dorisch, erzeugt von `tools/make_music.py` (Laute, Flöte, Bordun): ruhig in der Bauzeit,
mit Trommeln und Schellen während einer Welle. Beim Wechsel blendet die Musik über. Im Menü abschaltbar,
"Ton aus" schaltet auch die Musik stumm.

## Menü

Eine Kachel je Karte mit Vorschau von oben (Gelände, Grundweg der Gegner, Friedhof S, Burg B und
Kontrollpunkte), Beschreibung und Größe. Quer stehen alle Kacheln nebeneinander, im Hochformat zwei mal zwei.
Das Menü scrollt nicht: passt es nicht auf den Bildschirm, wird es als Ganzes verkleinert.
Darüber Schwierigkeit und Grafikstufe ("niedrig": ohne Schatten und Kantenglättung, für schwache Handys).
Jede Kachel zeigt den Bestwert auf der gewählten Schwierigkeit (überstandene Wellen oder "Gewonnen!").

## Sprachen

Deutsch und Englisch. Beim ersten Start gilt die Sprache des Systems (Deutsch, sonst Englisch), im Menü
umschaltbar. Die deutschen Texte im Code sind die Schlüssel, die englischen stehen in `scripts/lang.gd`.

## Bedienung auf Touch-Geräten

Mit Touchscreen wird die Oberfläche so skaliert, dass die kurze Bildschirmseite etwa 600 Einheiten hat
(am Rechner 720). Quer auf niedrigen Bildschirmen (unter 650 Einheiten Höhe, also Handys) ist die Oberfläche
kompakt: kleinere Leisten, Knöpfe und Turm-Karte, und die Bauleiste weicht, solange ein Turm gewählt ist. Im Hochformat: zweite Zeile für die Knöpfe oben, Bauleiste in zwei Reihen, Menü zwei mal zwei,
die Kamera-Zoomgröße gilt dann für die Breite.

Ziehen hält die Karte fest: der Punkt unter dem Finger bleibt unter dem Finger. Zwei Finger zoomen um ihre
Mitte und verschieben zugleich, danach zieht der übrige Finger ohne Sprung weiter.

## Ideen für später

- Mehr Karten.
- Mehrere Spielstände.
