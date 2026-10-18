class_name MapData
extends RefCounted
## Karten als Text. Zeichen: . Gras (bebaubar, begehbar), = Weg (begehbar, nicht bebaubar),
## # Wald und Fels am Rand, r Fels im Feld, g Grabsteine (blockiert), S Friedhof (Start der Gegner),
## K Burg (Ziel der Gegner). Jede Zelle ist ein Feld von 1 x 1 Welteinheiten.

enum Cell { GRASS, ROAD, BLOCKED, SPAWN, KEEP }

const MAPS := {
	&"vier_felder": {
		"name": "Vier Felder",
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
}

var id: StringName
var title: String
var size: Vector2i
var cells: PackedByteArray
## Zeichen der Karte, damit die Darstellung Fels, Grabstein und Wald unterscheiden kann.
var glyphs: PackedStringArray
var spawn := Vector2i(-1, -1)
var keep := Vector2i(-1, -1)


static func load_map(map_id: StringName) -> MapData:
	var data := MapData.new()
	var rows: Array = MAPS[map_id]["rows"]
	data.id = map_id
	data.title = MAPS[map_id]["name"]
	data.size = Vector2i((rows[0] as String).length(), rows.size())
	data.cells.resize(data.size.x * data.size.y)
	for y in data.size.y:
		var row: String = rows[y]
		assert(row.length() == data.size.x, "Zeile %d hat die falsche Länge" % y)
		for x in data.size.x:
			var glyph := row[x]
			data.glyphs.append(glyph)
			var cell := Cell.BLOCKED
			match glyph:
				".": cell = Cell.GRASS
				"=": cell = Cell.ROAD
				"S":
					cell = Cell.SPAWN
					data.spawn = Vector2i(x, y)
				"K":
					cell = Cell.KEEP
					data.keep = Vector2i(x, y)
			data.cells[y * data.size.x + x] = cell
	return data


func cell(at: Vector2i) -> Cell:
	if at.x < 0 or at.y < 0 or at.x >= size.x or at.y >= size.y:
		return Cell.BLOCKED
	return cells[at.y * size.x + at.x] as Cell


func glyph(at: Vector2i) -> String:
	return glyphs[at.y * size.x + at.x]
