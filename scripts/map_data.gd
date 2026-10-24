class_name MapData
extends RefCounted
## Karten als Text. Zeichen: . Gras (bebaubar, begehbar), ^ Hochfläche (bebaubar, nicht begehbar),
## = Weg (begehbar, nicht bebaubar), # Wald und Fels am Rand, r Fels im Feld, g Grabsteine,
## S Friedhof (Start, auch mehrere), K Burg (Ziel), 1 bis 9 Kontrollpunkte, die die Gegner der Reihe nach
## ablaufen, ~ Wasser (weder begehbar noch bebaubar), b Brücke (begehbar, nicht bebaubar).
## Jede Zelle ist ein Feld von 1 x 1 Welteinheiten.

enum Cell { GRASS, ROAD, BLOCKED, SPAWN, KEEP, HIGH, CHECKPOINT, WATER }

const ORDER: Array[StringName] = [&"vier_felder", &"rundlauf", &"schlangenpfad", &"weites_feld", &"zwei_friedhoefe"]

const MAPS := {
	&"vier_felder": {
		"name": "Vier Felder",
		"info": "Vier große Felder, verbunden durch feste Wege. Jedes Feld will sein eigenes Labyrinth.",
		"rows": [
		"########################################",
		"#gg#####################################",
		"gS=...............####................##",
		"g==...............####................##",
		"#gg...............####......r.........##",
		"###......rr.......####................##",
		"###...............####................##",
		"###...............####................##",
		"###...............####........rr......##",
		"###.........r.....####................##",
		"###...............====................##",
		"###...............====................##",
		"####################################==##",
		"####################################==##",
		"#K=...............####................##",
		"#==...............####................##",
		"###...............####................##",
		"###...............####................##",
		"###.....rr........####.....r..........##",
		"###...............####................##",
		"###...............####...........r....##",
		"###..........r....####................##",
		"###...............====................##",
		"###...............====................##",
		"########################################",
		"########################################",
		],
	},
	&"rundlauf": {
		"name": "Rundlauf",
		"info": "Eine Runde um die Hochfläche, über vier Kontrollpunkte. Türme auf der Hochfläche stören den Weg nicht.",
		"rows": [
			"####################################",
			"####################################",
			"##..............K##S..............##",
			"##...............##...............##",
			"##...4...........##....r......1...##",
			"##...............##...............##",
			"##...............##...............##",
			"##...............##...............##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##....r..^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.r.....##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##.......^^^^^^^^^^^^^^^^^^.......##",
			"##................................##",
			"##................................##",
			"##..........r.....................##",
			"##...3........................2...##",
			"##................................##",
			"##................................##",
			"####################################",
			"####################################",
		],
	},
	&"schlangenpfad": {
		"name": "Schlangenpfad",
		"info": "Klassisch: ein fester Weg in Schleifen. Kein Labyrinth, dafür überall Platz für Türme.",
		"rows": [
			"################################",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"S==========================^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^=^^^^#",
			"#^^^^^^^^^r^^^^^^^^^^^^^^^=^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^=^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^=^^^^#",
			"#^^^^======================^^^^#",
			"#^^^^=^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"#^^^^=^^^^^^^^^^^^^^r^^^^^^^^^^#",
			"#^^^^=^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"#^^^^=^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"#^^^^======================^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^=^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^=^r^^#",
			"#^^^^^^^^^^^^^r^^^^^^^^^^^=^^^^#",
			"#^^r^^^^^^^^^^^^^^^^^^^^^^=^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^=====K",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^#",
			"################################",
		],
	},
	&"weites_feld": {
		"name": "Weites Feld",
		"info": "Ein offenes Feld und drei Kontrollpunkte: die Gegner müssen mehrmals quer hindurch.",
		"rows": [
			"######################################",
			"######################################",
			"##..................................##",
			"##..........1.............3.........##",
			"##..................................##",
			"##..................................##",
			"##..................................##",
			"##..................................##",
			"##......r.....................r.....##",
			"##..................................##",
			"##..................................##",
			"##.................r................##",
			"#S.................r................K#",
			"##..................................##",
			"##..................................##",
			"##..................................##",
			"##......r.....................r.....##",
			"##..................................##",
			"##..................................##",
			"##..................................##",
			"##.................2................##",
			"##..................................##",
			"######################################",
			"######################################",
		],
	},
	&"zwei_friedhoefe": {
		"name": "Zwei Friedhöfe",
		"info": "Die Toten kommen von zwei Seiten und müssen über eine der zwei Brücken. Wer eine zubaut, lenkt sie zur anderen.",
		"rows": [
			"####################################",
			"####################################",
			"##..............~~................##",
			"gg..............~~................##",
			"gS=.............~~................##",
			"gg..............~~................##",
			"##..............bb........r.......##",
			"##..............bb................##",
			"##...............~~...............##",
			"##......rr.......~~...............##",
			"##...............~~.....r.........##",
			"##...............~~..............=##",
			"##...r...........~~..............=K#",
			"##...............~~..............=##",
			"##...............~~...............##",
			"##........r......~~........r......##",
			"##..............bbb...............##",
			"##..............bbb...............##",
			"gg..............~~............r...##",
			"gS=.............~~................##",
			"gg..............~~................##",
			"##..............~~................##",
			"####################################",
			"####################################",
		],
	},
}

var id: StringName
var title: String
var size: Vector2i
var cells: PackedByteArray
## Zeichen der Karte, damit die Darstellung Fels, Grabstein und Wald unterscheiden kann.
var glyphs: PackedStringArray
## Erster Friedhof; alle stehen in `spawns`, die Gegner kommen abwechselnd.
var spawn := Vector2i(-1, -1)
var spawns: Array[Vector2i] = []
var keep := Vector2i(-1, -1)
## Ziele der Gegner der Reihe nach: Kontrollpunkte 1, 2, ... und zuletzt die Burg.
var waypoints: Array[Vector2i] = []


static func load_map(map_id: StringName) -> MapData:
	var data := MapData.new()
	var rows: Array = MAPS[map_id]["rows"]
	data.id = map_id
	data.title = MAPS[map_id]["name"]
	data.size = Vector2i((rows[0] as String).length(), rows.size())
	data.cells.resize(data.size.x * data.size.y)
	var checkpoints: Dictionary = {}
	for y in data.size.y:
		var row: String = rows[y]
		assert(row.length() == data.size.x, "Zeile %d hat die falsche Länge" % y)
		for x in data.size.x:
			var glyph := row[x]
			data.glyphs.append(glyph)
			var cell := Cell.BLOCKED
			match glyph:
				".": cell = Cell.GRASS
				"=", "b": cell = Cell.ROAD
				"~": cell = Cell.WATER
				"^": cell = Cell.HIGH
				"S":
					cell = Cell.SPAWN
					data.spawns.append(Vector2i(x, y))
				"K":
					cell = Cell.KEEP
					data.keep = Vector2i(x, y)
				_:
					if glyph >= "1" and glyph <= "9":
						cell = Cell.CHECKPOINT
						checkpoints[int(glyph)] = Vector2i(x, y)
			data.cells[y * data.size.x + x] = cell
	data.spawn = data.spawns[0]
	var numbers := checkpoints.keys()
	numbers.sort()
	for n in numbers:
		data.waypoints.append(checkpoints[n])
	data.waypoints.append(data.keep)
	return data


func cell(at: Vector2i) -> Cell:
	if at.x < 0 or at.y < 0 or at.x >= size.x or at.y >= size.y:
		return Cell.BLOCKED
	return cells[at.y * size.x + at.x] as Cell


func glyph(at: Vector2i) -> String:
	return glyphs[at.y * size.x + at.x]


func buildable(at: Vector2i) -> bool:
	return cell(at) == Cell.GRASS or cell(at) == Cell.HIGH
