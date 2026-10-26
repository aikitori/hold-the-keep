extends Node
## Test ohne Fenster: Wegfindung, Bauregeln, Wellen und ein kurzer Spielablauf mit Türmen.
## Start: godot --headless res://scenes/dev/logic_test.tscn

var _failed := false


func _check(ok: bool, text: String) -> void:
	print(("ok:   " if ok else "FAIL: ") + text)
	if not ok:
		_failed = true


func _ready() -> void:
	for id: StringName in Sfx.VOLUME:
		_check(Sfx._streams[id] is AudioStream, "Klang %s geladen" % id)
	Sfx.muted = true  # Wiedergaben, die beim Beenden noch laufen, meldet Godot als hängend.
	Settings.file = "user://logic_test.cfg"
	Settings.save_file = "user://logic_test_save.cfg"
	DirAccess.remove_absolute(Settings.file)
	Settings.difficulty = &"normal"
	Lang.apply("de")  # Prüfungen erwarten deutsche Texte, egal welche Sprache eingestellt ist
	_test_settings()
	_test_translations()
	var map := MapData.load_map(&"vier_felder")
	_check(map.spawn != Vector2i(-1, -1) and map.keep != Vector2i(-1, -1), "Karte hat Friedhof und Burg")
	var board := Board.new(map)
	var path := board.full_path()
	_check(path.size() > 40 and path[-1] == map.keep, "Weg vom Friedhof zur Burg führt durch alle Felder (%d Schritte)" % path.size())
	var grass_step := Vector2i(-1, -1)
	for cell in path:
		if map.cell(cell) == MapData.Cell.GRASS:
			grass_step = cell
			break
	var preview: Array[Vector2i] = board.full_paths_with(grass_step)[0]
	_check(not preview.has(grass_step) and preview[-1] == map.keep and board.full_path() == path,
			"Wegvorschau umgeht das geplante Feld und ändert den Weg nicht")
	_check(board.check_build(Vector2i(19, 10)) == Board.BuildCheck.NOT_GRASS, "Auf dem festen Weg kann nicht gebaut werden")
	_check(board.check_build(Vector2i(0, 0)) == Board.BuildCheck.NOT_GRASS, "Im Wald kann nicht gebaut werden")
	# Ausgang von Feld A (x 17, y 2..11) zumauern: der letzte Stein muss abgelehnt werden.
	var refused := -1
	for y in range(2, 12):
		var at := Vector2i(17, y)
		if board.check_build(at) == Board.BuildCheck.OK:
			board.place(at, true)
		else:
			refused = y
	_check(refused >= 0 and board.check_build(Vector2i(17, refused)) == Board.BuildCheck.BLOCKS_PATH,
			"Der Weg lässt sich nicht ganz versperren (abgelehnt bei y=%d)" % refused)
	# Zickzack in Feld A: zwei Riegel mit Lücke unten und oben.
	var maze := Board.new(map)
	for y in range(2, 11):
		maze.place(Vector2i(7, y), true)
	for y in range(3, 12):
		maze.place(Vector2i(13, y), true)
	var longer := maze.full_path()
	_check(maze.path_length(longer) > board.path_length(path) + 10.0,
			"Mauern machen den Weg länger (%.1f statt %.1f)" % [maze.path_length(longer), board.path_length(path)])
	_check(board.check_build(Vector2i(5, 5), [[Vector2i(5, 5), map.keep]]) == Board.BuildCheck.ENEMY_THERE, "Nicht auf Gegnern bauen")
	var flight: Array = maze.flight_legs[-1]
	_check(flight[0] == map.spawn and flight[-1] == map.keep and maze.flight_lengths[-1] > 40.0
			and maze.flight_legs == board.flight_legs,
			"Flieger folgen dem Grundweg durch alle Felder, Türme ändern die Route nicht (%.1f)" % maze.flight_lengths[-1])
	_test_maps()
	_check(Defs.wave_preview(12).contains("Schwarzer Ritter (Rüstung") and Defs.wave_preview(4).contains("fliegt")
			and Defs.wave_preview(5).contains("Boss"), "Wellenvorschau nennt Arten und Besonderheiten: %s" % Defs.wave_preview(12))
	var boss_wave := Defs.wave(5)
	_check(boss_wave[0] == &"vampire" and Defs.wave(10)[0] == &"keeper", "Bosse in Welle 5 und 10")
	var seen := {}
	for n in range(1, Defs.WAVES + 1):
		for kind in Defs.wave(n):
			seen[kind] = true
	_check(seen.size() == Defs.ENEMIES.size(), "Alle %d Gegnerarten kommen vor (%d)" % [Defs.ENEMIES.size(), seen.size()])
	var mixed := {}
	for kind in Defs.wave(12):
		mixed[kind] = true
	_check(mixed.size() >= 3 and Defs.wave(12) == Defs.wave(12), "Welle 12 gemischt und immer gleich")
	_check(Defs.upgrade_cost(&"archer", 3) == -1 and Defs.upgrade_cost(&"wall", 1) == -1, "Ausbau endet bei Stufe 3, Mauern nie")
	await _play()
	await _test_difficulty()
	print("LOGIC-TEST ", "FEHLGESCHLAGEN" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Alle Karten: Weg über alle Kontrollpunkte, Hochfläche bebaubar ohne den Weg zu ändern.
## Zwei Friedhöfe, Fluss mit zwei Brücken: eine Brücke zubauen lenkt beide Wege zur anderen, beide nicht.
func _test_two_graveyards() -> void:
	var map := MapData.load_map(&"zwei_friedhoefe")
	var board := Board.new(map)
	var paths := board.full_paths()
	var crosses := func(path: Array) -> bool: return path.any(func(at: Vector2i) -> bool: return map.glyph(at) == "b")
	_check(map.spawns.size() == 2 and paths.all(func(p: Array) -> bool: return p[-1] == map.keep and crosses.call(p))
			and paths.all(func(p: Array) -> bool: return not p.any(func(at: Vector2i) -> bool: return map.cell(at) == MapData.Cell.WATER)),
			"Zwei Friedhöfe: beide Wege führen über eine Brücke zur Burg")
	_check(board.check_build(Vector2i(17, 10)) == Board.BuildCheck.NOT_GRASS, "Im Fluss kann nicht gebaut werden")
	# Westlich vor der oberen Brücke zumauern.
	for at: Vector2i in [Vector2i(15, 2), Vector2i(15, 3), Vector2i(15, 4), Vector2i(15, 5), Vector2i(15, 6), Vector2i(15, 7),
			Vector2i(15, 8), Vector2i(16, 8)]:
		board.place(at, true)
	var upper := func(at: Vector2i) -> bool: return map.glyph(at) == "b" and at.y < 12
	var lower := func(at: Vector2i) -> bool: return map.glyph(at) == "b" and at.y > 12
	_check(board.full_paths().all(func(p: Array) -> bool: return not p.any(upper) and p.any(lower)), "Obere Brücke zu: alle nehmen die untere")
	var refused := false
	for at: Vector2i in [Vector2i(16, 15), Vector2i(15, 15), Vector2i(15, 16), Vector2i(15, 17), Vector2i(15, 18)]:
		if board.check_build(at) == Board.BuildCheck.OK:
			board.place(at, true)
		else:
			refused = true
	_check(refused, "Beide Brücken lassen sich nicht zubauen")


func _test_maps() -> void:
	for id: StringName in MapData.ORDER:
		var map := MapData.load_map(id)
		var board := Board.new(map)
		var path := board.full_path()
		var visits := true
		for point in map.waypoints:
			visits = visits and path.has(point)
		_check(map.spawn.x >= 0 and path.size() > 20 and visits and path[-1] == map.keep,
				"Karte %s: Weg über %d Ziele, %d Schritte" % [id, map.waypoints.size(), path.size()])
		var high := Vector2i(-1, -1)
		for y in map.size.y:
			for x in map.size.x:
				if high.x < 0 and map.cell(Vector2i(x, y)) == MapData.Cell.HIGH:
					high = Vector2i(x, y)
		if high.x >= 0:
			var before := board.full_path().size()
			_check(board.check_build(high) == Board.BuildCheck.OK, "Karte %s: Hochfläche bebaubar" % id)
			board.place(high, true)
			_check(board.full_path().size() == before, "Karte %s: Turm auf der Hochfläche ändert den Weg nicht" % id)
	_test_two_graveyards()
	_check(Defs.is_air_wave(4) and Defs.wave(4).all(func(k: StringName) -> bool: return Defs.ENEMIES[k].get("air", false)),
			"Welle 4 ist eine Luftwelle")
	for id: StringName in Defs.SPECS:
		_check((Defs.SPECS[id] as Array).size() == 2, "%s hat zwei Spezialisierungen" % id)


## Spielstand: speichern in der Bauzeit, ein zweites Spiel setzt mit denselben Türmen und Werten fort.
func _test_resume(main: Main) -> void:
	main.wave = 3
	main.autosave()
	var saved := Settings.saved_game()
	Main.resume = saved
	var copy: Main = load("res://scenes/main.tscn").instantiate()
	add_child(copy)
	await get_tree().process_frame
	var same := copy.board.towers.size() == main.board.towers.size()
	for cell: Vector2i in main.board.towers:
		var a: Tower = main.board.towers[cell]
		var b: Tower = copy.board.towers.get(cell)
		same = same and b != null and b.id == a.id and b.level == a.level and b.spec_id == a.spec_id \
				and b.invested == a.invested and not b.refundable
	_check(not saved.is_empty() and same and copy.gold == main.gold and copy.wave == 3 and copy.countdown > 0.0
			and Main.resume.is_empty(), "Spielstand: Türme, Stufen, Gold und Welle kommen wieder (%d Türme)" % copy.board.towers.size())
	copy.queue_free()
	await get_tree().process_frame
	var stale := saved.duplicate()
	stale["version"] = 0
	Settings.save_game(stale)
	_check(Settings.saved_game().is_empty(), "Spielstand einer anderen Version wird verworfen")
	main.wave = 0


## Glocke verlangsamt, Pechregen trifft am Ziel, Kriegshorn läuft ab, Abklingzeiten sperren.
func _test_abilities(main: Main) -> void:
	var center := Board.world_of(Vector2i(8, 6))
	var near := _enemy(main, &"orc", center)
	var far := _enemy(main, &"orc", center + Vector3(6, 0, 0))
	main.use_ability(&"bell")
	_check(near._slow == 0.5 and main.ability_wait[&"bell"] > 0.0, "Glocke verlangsamt alle Gegner")
	main.use_ability(&"pitch")
	var screen := main.rig.camera.unproject_position(center)
	main.tap(screen, true)
	_check(near.hp == near.max_hp and main.ability_wait[&"pitch"] == 0.0, "Pechregen per Touch: erster Tipp zeigt nur den Umkreis")
	main.tap(screen, true)
	_check(near.hp < near.max_hp and far.hp == far.max_hp and main.ability_wait[&"pitch"] > 0.0, "Pechregen trifft nur am Ziel")
	main.use_ability(&"horn")
	_check(main.horn_time > 0.0, "Kriegshorn beschleunigt die Türme")
	var wait: float = main.ability_wait[&"horn"]
	main.use_ability(&"horn")
	_check(main.ability_wait[&"horn"] == wait, "Während der Abklingzeit nicht nochmal")
	for enemy in [near, far]:
		main.enemies.erase(enemy)
		enemy.queue_free()
	for id: StringName in main.ability_wait:
		main.ability_wait[id] = 0.0
	main.horn_time = 0.0
	await get_tree().process_frame


func _enemy(main: Main, kind: StringName, at: Vector3) -> Enemy:
	var enemy := Enemy.new()
	main.add_child(enemy)
	enemy.setup(kind, 1, main, main.board)
	enemy.position = Vector3(at.x, enemy.position.y, at.z)
	main.enemies.append(enemy)
	return enemy


## Bombarde schießt Kanonenkugeln, Gift stapelt und geht durch Rüstung, Banner verstärkt, Zollhaus bringt Gold.
func _test_new_towers(main: Main) -> void:
	main.gold = 1000
	var archer: Tower = main.try_build(&"archer", Vector2i(11, 7))
	var plain := archer.damage()
	var banner: Tower = main.try_build(&"banner", Vector2i(12, 7))
	_check(banner != null and is_equal_approx(archer.damage(), plain * 1.25), "Kriegsbanner: +25 % Schaden im Umkreis")
	var toll: Tower = main.try_build(&"tollhouse", Vector2i(10, 9))
	main.gold = 100
	main._pay_interest()
	_check(toll != null and main.gold == 100 + 5 + 6, "Zollhaus: 6 Gold nach der Welle, dazu Zinsen (%d)" % main.gold)
	var knight := _enemy(main, &"knight", Board.world_of(Vector2i(8, 6)))
	for i in 4:
		knight.apply_poison(5.0, 3)
	var hp := knight.hp
	knight._process(1.0)
	_check(knight.poison_stacks() == 3 and hp - knight.hp > 14.0, "Gift stapelt bis drei und geht durch Rüstung (%.0f Schaden)" % (hp - knight.hp))
	var bombard: Tower = main.try_build(&"bombard", Vector2i(9, 7))
	var target := _enemy(main, &"orc", bombard.position + Vector3(1, 0, 0))
	bombard._cooldown = 0.0
	bombard._process(0.016)
	var shots := main.get_children().filter(func(n: Node) -> bool: return n is Projectile and n.kind == "cannonball")
	_check(bombard != null and shots.size() == 1 and shots[0].hit["splash"] > 0.0, "Bombarde schießt Kanonenkugeln mit Flächenschaden")
	for shot in shots:
		shot.queue_free()
	for enemy in [knight, target]:
		main.enemies.erase(enemy)
		enemy.queue_free()
	for tower in [archer, banner, toll, bombard]:
		main.select_tower(tower)
		main.sell_selected()
	await get_tree().process_frame


## Gräber, Schildträger, Seuchenzombie und Nekromant.
func _test_new_enemies(main: Main) -> void:
	var digger := _enemy(main, &"burrower", Board.world_of(main.map.spawn))
	_check(digger._path == main.board.flight_route(0) and not main.walkers().any(func(w: Array) -> bool: return w[0] == digger.current_cell()),
			"Gräber folgt der festen Route und sperrt keinen Bauplatz")
	var center := Board.world_of(Vector2i(8, 6))
	var knight := _enemy(main, &"knight", center)
	var hp := knight.hp
	knight.take_damage(20.0)
	var plain := hp - knight.hp
	var shield := _enemy(main, &"shieldbearer", center + Vector3(0.5, 0, 0))
	hp = knight.hp
	knight.take_damage(20.0)
	_check(hp - knight.hp < plain, "Schildträger schützt Nachbarn (%.0f statt %.0f Schaden)" % [hp - knight.hp, plain])
	var before := main.enemies.size()
	var plague := _enemy(main, &"plague", center)
	plague.take_damage(10000.0)
	var parts := main.enemies.filter(func(e: Enemy) -> bool: return e.kind == &"swarm")
	_check(parts.size() == 3 and main.enemies.size() == before + 3 and parts[0].position.distance_to(center) < 1.0,
			"Seuchenzombie zerfällt in drei Knochenwichte")
	var necro := _enemy(main, &"necromancer", center)
	necro._summon_time = 0.01
	await get_tree().process_frame
	await get_tree().process_frame
	var helpers := main.enemies.filter(func(e: Enemy) -> bool: return e.kind == &"skeleton")
	_check(helpers.size() == 2 and helpers.all(func(e: Enemy) -> bool: return e.gold == 0), "Nekromant ruft zwei Skelette ohne Gold")
	for enemy in main.enemies.duplicate():
		main.enemies.erase(enemy)
		enemy.queue_free()
	await get_tree().process_frame


## Zielwahl: zwei Gegner neben dem Turm, einer stark und vorne, einer schwach und fliegend.
func _test_targeting(main: Main, tower: Tower) -> void:
	var strong := Enemy.new()
	var weak := Enemy.new()
	for pair: Array in [[strong, &"orc"], [weak, &"ghost"]]:
		var enemy: Enemy = pair[0]
		main.add_child(enemy)
		enemy.setup(pair[1], 1, main, main.board)
		enemy.position = tower.position + Vector3(0.5, 0, 0)
		main.enemies.append(enemy)
	strong.distance_left = 5.0
	weak.distance_left = 9.0
	var picks: Array[String] = []
	for mode: StringName in [&"first", &"strong", &"weak", &"air"]:
		tower.target_mode = mode
		picks.append(String(tower._pick_targets(1)[0].kind))
	_check(picks == ["orc", "orc", "ghost", "ghost"], "Zielwahl: Vorderster, Stärkster, Schwächster, Flieger (%s)" % ", ".join(picks))
	tower.target_mode = &"first"
	var seen: Array[StringName] = []
	for i in 4:
		tower.cycle_target()
		seen.append(tower.target_mode)
	_check(seen.has(&"air") == (tower.targets() == "both") and seen[-1] == &"first", "Zielwahl schaltet reihum")
	for enemy in [strong, weak]:
		main.enemies.erase(enemy)
		enemy.queue_free()


## Leicht: mehr Gold und Leben, Gegner mit weniger Lebenspunkten.
func _test_difficulty() -> void:
	Settings.difficulty = &"easy"
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var enemy := Enemy.new()
	main.add_child(enemy)
	enemy.setup(&"skeleton", 1, main, main.board)
	_check(main.gold == 130 and main.lives == 30 and is_equal_approx(enemy.max_hp, Defs.ENEMIES[&"skeleton"]["hp"] * 0.8),
			"Leicht: 130 Gold, 30 Leben, Gegner mit 80 % Leben")
	main.queue_free()
	await get_tree().process_frame
	Settings.difficulty = &"normal"


## Jeder Text, der übersetzt wird, steht in Lang.EN: Literale in tr()/Lang.t() und alle Namen der Spieldaten.
func _test_translations() -> void:
	var missing: Array[String] = []
	var count := 0
	var literal := RegEx.create_from_string("(?:\\btr|Lang\\.t)\\(\"((?:[^\"\\\\]|\\\\.)*)\"\\)")
	for file in DirAccess.get_files_at("res://scripts"):
		if not file.ends_with(".gd") or file == "lang.gd":
			continue
		var code := FileAccess.get_file_as_string("res://scripts/" + file)
		for found in literal.search_all(code):
			var text := found.get_string(1).replace("\\n", "\n")
			count += 1
			if not Lang.EN.has(text):
				missing.append(text)
	var texts: Array = []
	for table: Dictionary in [Defs.TOWERS, Defs.ENEMIES, Defs.ABILITIES, Defs.DIFFICULTIES, MapData.MAPS]:
		for key in table:
			texts.append(table[key]["name"])
			if table[key].has("info"):
				texts.append(table[key]["info"])
	for options: Array in Defs.SPECS.values():
		for option: Dictionary in options:
			texts.append_array([option["name"], option["info"]])
	texts.append_array(Defs.TARGET_NAMES.values())
	texts.append_array(MapData.LEVELS)
	texts.append_array(Main.BUILD_MESSAGES.values())
	for text: String in texts:
		if not Lang.EN.has(text):
			missing.append(text)
	Lang.apply("en")
	var english: Array = Lang.EN.values()
	for n in range(1, Defs.WAVES + 1):
		for part in Defs.wave_preview(n).split(" · ")[0].split("), "):
			var inner := part.get_slice("(", 1).trim_suffix(")")
			for word in inner.split(", ", false):
				if not english.has(word):
					missing.append(word)
	Lang.apply("de")
	_check(count > 60 and missing.is_empty() and Lang.t("Spielen") == "Spielen",
			"Alle %d Texte übersetzt%s" % [count, "" if missing.is_empty() else ", es fehlt: " + " | ".join(missing)])


## Bestwerte: nur Verbesserungen zählen, je Schwierigkeit getrennt.
func _test_settings() -> void:
	_check(Settings.best(&"rundlauf")["wave"] == 0, "Ohne Spielstand kein Bestwert")
	Settings.record(&"rundlauf", 7, false)
	Settings.record(&"rundlauf", 3, false)
	_check(Settings.best(&"rundlauf") == {"wave": 7, "won": false}, "Bestwert bleibt beim besseren Ergebnis")
	Settings.record(&"rundlauf", 30, true)
	_check(Settings.best(&"rundlauf")["won"] and Settings.best(&"rundlauf", &"hard")["wave"] == 0,
			"Sieg gespeichert, andere Schwierigkeit getrennt")
	DirAccess.remove_absolute(Settings.file)


## Ziehen mit einem Finger: der gegriffene Bodenpunkt bleibt unter dem Finger, auch in kleinen Schritten.
## Zwei Finger zoomen, danach zieht der übrige Finger ohne Sprung weiter.
func _test_touch_drag(main: Main) -> void:
	var rig := main.rig
	var start := Vector2(640, 360)
	var grabbed := rig.ground_point(start, 0.0)
	var before := rig.position
	var pointer := Vector2(900, 250)
	var under := rig.ground_point(pointer, 0.0)
	var size_before: float = rig.camera.size
	rig.zoom_at(0.8, pointer)
	_check(rig.camera.size < size_before and rig.ground_point(pointer, 0.0).distance_to(under) < 0.01,
			"Mausrad zoomt zum Zeiger, der Punkt darunter bleibt stehen")
	rig.camera.size = size_before
	rig.position = before
	main._unhandled_input(_touch(0, start, true))
	var at := start
	for i in 40:
		at += Vector2(-3, 2)
		main._unhandled_input(_drag_event(0, at))
	var slip := Vector2(rig.ground_point(at, 0.0).x - grabbed.x, rig.ground_point(at, 0.0).z - grabbed.z).length()
	_check(rig.position.distance_to(before) > 1.0 and slip < 0.01,
			"Karte folgt dem Finger (%.2f Felder bewegt, Abweichung %.3f)" % [rig.position.distance_to(before), slip])
	# Weit über den Rand hinaus, dann ein kleines Stück zurück: die Kamera muss sofort folgen.
	for i in 100:
		at += Vector2(-40, -40)
		main._unhandled_input(_drag_event(0, at))
	var corner := rig.position
	at += Vector2(30, 30)
	main._unhandled_input(_drag_event(0, at))
	_check(rig.position.distance_to(corner) > 0.5, "Am Rand festgefahren, zurückziehen geht sofort (%.2f)" % rig.position.distance_to(corner))
	var size: float = rig.camera.size
	main._unhandled_input(_touch(1, at + Vector2(100, 0), true))
	main._unhandled_input(_drag_event(1, at + Vector2(200, 0)))
	_check(rig.camera.size < size, "Zwei Finger auseinander zoomen hinein")
	main._unhandled_input(_touch(1, at + Vector2(200, 0), false))
	var regrab := rig.ground_point(at, 0.0)
	main._unhandled_input(_drag_event(0, at + Vector2(1, 0)))
	main._unhandled_input(_drag_event(0, at))
	_check(rig.ground_point(at, 0.0).distance_to(regrab) < 0.01, "Nach dem Zoomen springt die Karte nicht")
	main._unhandled_input(_touch(0, at, false))
	_check(main.board.towers.is_empty() and not main._dragging, "Ziehen baut nichts")
	rig.camera.size = size
	# Schneller Wisch: nach dem Loslassen gleitet die Karte weiter, ein neuer Finger hält sie an.
	rig.position = before
	main._unhandled_input(_touch(0, start, true))
	for i in 5:
		main._unhandled_input(_drag_event(0, start + Vector2(-20 * (i + 1), 0)))
	var released := rig.position
	main._unhandled_input(_touch(0, start + Vector2(-100, 0), false))
	rig._process(0.1)
	_check(rig.position.distance_to(released) > 0.1, "Nach einem Wisch gleitet die Karte nach")
	main._unhandled_input(_touch(0, start, true))
	main._unhandled_input(_touch(0, start, false))
	var held := rig.position
	rig._process(0.1)
	_check(rig.position == held, "Aufsetzen hält die gleitende Karte an")
	rig.position = before


## Massenbau: im Baumodus baut Ziehen eine Reihe. Tipp auf den Turmkörper wählt den Turm, auch im Baumodus.
func _test_mass_build(main: Main) -> void:
	var camera := main.rig.camera
	var screen := func(cell: Vector2i) -> Vector2: return camera.unproject_position(Board.world_of(cell, Tower.GROUND))
	main.rig.position = Board.world_of(Vector2i(6, 4))
	main.gold = 100
	main._on_build_selected(&"wall")
	var before: int = main.board.towers.size()
	main._unhandled_input(_touch(0, screen.call(Vector2i(3, 3)), true))
	main._unhandled_input(_touch(0, screen.call(Vector2i(3, 3)), false))
	_check(main.board.towers.size() == before and main._ghost_cell == Vector2i(3, 3),
			"Touch: erster Tipp im Baumodus zeigt nur die Vorschau")
	var rig_at := main.rig.position
	main._unhandled_input(_touch(0, screen.call(Vector2i(6, 6)), true))
	main._unhandled_input(_drag_event(0, screen.call(Vector2i(6, 6)) + Vector2(0, 60)))
	main._unhandled_input(_touch(0, screen.call(Vector2i(6, 6)) + Vector2(0, 60), false))
	_check(main.board.towers.size() == before and main.rig.position != rig_at,
			"Touch: Ziehen abseits der Vorschau verschiebt die Karte statt zu bauen")
	main.rig.position = rig_at
	main._unhandled_input(_touch(0, screen.call(Vector2i(3, 3)), true))
	main._unhandled_input(_drag_event(0, screen.call(Vector2i(4, 3))))
	main._unhandled_input(_drag_event(0, screen.call(Vector2i(8, 3))))  # Sprung: Lücke wird gefüllt
	main._unhandled_input(_touch(0, screen.call(Vector2i(8, 3)), false))
	var row := range(3, 9).filter(func(x: int) -> bool: return main.board.towers.has(Vector2i(x, 3)))
	_check(main.board.towers.size() - before == 6 and row.size() == 6 and main.gold == 70,
			"Massenbau: Ziehen baut eine lückenlose Reihe (%d Mauern)" % (main.board.towers.size() - before))
	main.tap(screen.call(Vector2i(7, 5)), true)
	main.tap(screen.call(Vector2i(7, 5)), true)
	_check(main.board.towers.has(Vector2i(7, 5)), "Touch: zweiter Tipp auf dieselbe Stelle baut")
	# Maus wie in Strategiespielen: ein Klick baut und beendet den Baumodus, mit Umschalt bleibt er.
	main.tap(screen.call(Vector2i(6, 6)), false, true)
	_check(main.board.towers.has(Vector2i(6, 6)) and main._ghost_id == &"wall", "Maus: Umschalt+Klick baut, der Baumodus bleibt")
	main.tap(screen.call(Vector2i(7, 6)))
	_check(main.board.towers.has(Vector2i(7, 6)) and main._ghost_id == &"" and main.hud.selected_build == &"",
			"Maus: Klick baut und beendet den Baumodus")
	# Aus der Bauleiste aufs Feld ziehen: mit Touch schwebt die Vorschau über dem Finger, Loslassen baut.
	main._on_build_selected(&"wall")
	var drop: Vector2 = screen.call(Vector2i(8, 6)) + Vector2(0, Main.DRAG_LIFT)
	main._on_build_dragged(&"wall", drop, true)
	_check(main._ghost_cell == Vector2i(8, 6), "Ziehen aus der Bauleiste: Vorschau über dem Finger")
	main._on_build_dropped(&"wall", drop, true, false)
	_check(main.board.towers.has(Vector2i(8, 6)) and main._ghost_id == &"wall", "Touch: Loslassen über dem Feld baut, Baumodus bleibt")
	for cell: Vector2i in [Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6)]:
		main.select_tower(main.board.towers[cell])
		main.sell_selected()
	main._on_build_selected(&"wall")
	# Ein Turm vor der Vorschau (näher zur Kamera) wird durchsichtig und ist nicht wählbar, von hinten nicht.
	var front: Tower = main.try_build(&"archer", Vector2i(5, 5))
	main._move_ghost(Vector2i(4, 4))
	var spot := camera.unproject_position(Board.world_of(Vector2i(4, 4), Tower.GROUND + 0.3))
	_check(front in main._faded and main.tower_at(spot) == null, "Turm vor der Bauvorschau wird durchsichtig")
	main.rig.turn(2)
	main.rig.rotation.y = PI
	main._move_ghost(Vector2i(4, 4))
	_check(not front in main._faded, "Kamera gedreht: derselbe Turm steht dahinter und bleibt sichtbar")
	main.rig.turn(-2)
	main.rig.rotation.y = 0.0
	main._move_ghost(Vector2i(4, 4))
	main.select_tower(front)
	main.sell_selected()
	main._on_build_selected(&"wall")
	var wall: Tower = main.board.towers[Vector2i(5, 3)]
	main.tap(screen.call(Vector2i(5, 3)), true)
	_check(main._selected == wall and main._ghost_id == &"", "Tipp auf einen Turm im Baumodus wählt ihn aus")
	main.select_tower(null)
	var archer: Tower = main.try_build(&"archer", Vector2i(6, 5))
	var body := camera.unproject_position(archer.global_position + Vector3(0, Tower.GROUND + archer.height() * 0.8, 0))
	main.tap(body)
	_check(main._selected == archer and Board.cell_of(main.rig.ground_point(body)) != archer.cell,
			"Tipp auf den sichtbaren Turmkörper wählt den Turm, nicht das Feld dahinter")
	main.select_tower(null)
	for cell: Vector2i in main.board.towers.keys():
		if cell.y in [3, 5] and cell.x < 10:
			main.select_tower(main.board.towers[cell])
			main.sell_selected()
	main.gold = 90


## Echte Mausereignisse: vom Mauer-Knopf aufs Feld ziehen und loslassen baut. Braucht ein Fenster (headless
## kommen keine Ereignisse bei der Oberfläche an): `xvfb-run godot res://scenes/dev/logic_test.tscn`.
func _test_bar_drag(main: Main) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var button: Button = main.hud._build_buttons[&"wall"]
	var cell := Vector2i(6, 8)
	var camera_at := main.rig.position
	main.rig.position = Board.world_of(cell)
	var target := main.rig.camera.unproject_position(Board.world_of(cell, Tower.GROUND))
	if main.board.check_build(cell, main.walkers()) != Board.BuildCheck.OK:
		_check(false, "Ziehen aus der Bauleiste: Feld %s ist nicht frei" % cell)
		main.rig.position = camera_at
		return
	main.gold += 10
	var start := button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	press.global_position = start
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	for i in 6:
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = start.lerp(target, (i + 1) / 6.0)
		motion.global_position = motion.position
		Input.parse_input_event(motion)
	Input.flush_buffered_events()
	var moved := main._ghost_id == &"wall" and main._ghost_cell == cell
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	release.position = target
	release.global_position = target
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await get_tree().process_frame
	_check(moved and main.board.towers.has(cell) and main._ghost_id == &"" and main.hud.selected_build == &"",
			"Maus: Turm aus der Bauleiste aufs Feld ziehen baut ihn (Vorschau folgte: %s)" % moved)
	if main.board.towers.has(cell):
		main.select_tower(main.board.towers[cell])
		main.sell_selected()
	# Dasselbe mit dem Finger: die Vorschau schwebt über ihm, der Baumodus bleibt, es wird nur einmal gebaut.
	var finger := target + Vector2(0, Main.DRAG_LIFT)
	var count := main.board.towers.size()
	Input.parse_input_event(_touch(0, start, true))
	for i in 6:
		Input.parse_input_event(_drag_event(0, start.lerp(finger, (i + 1) / 6.0)))
	Input.parse_input_event(_touch(0, finger, false))
	Input.flush_buffered_events()
	await get_tree().process_frame
	_check(main.board.towers.has(cell) and main.board.towers.size() == count + 1 and main._ghost_id == &"wall",
			"Touch: Turm aus der Bauleiste aufs Feld ziehen baut genau einen, der Baumodus bleibt")
	if main.board.towers.has(cell):
		main.select_tower(main.board.towers[cell])
		main.sell_selected()
	main._stop_building()
	main.gold -= 10
	main.rig.position = camera_at


static func _touch(index: int, at: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	return event


static func _drag_event(index: int, at: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	return event


## Kurzer Ablauf: Türme an den Ausgang von Feld A, drei Wellen im Zeitraffer.
func _play() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	_check(main.gold == Defs.DIFFICULTIES[&"normal"]["gold"] and main.lives == 20, "Normal: 90 Gold, 20 Leben")
	_check(Sfx._music_id == &"build" and Sfx.MUSIC[&"battle"].loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"Baumusik gewählt, Musik läuft als Schleife")
	_test_touch_drag(main)
	_test_mass_build(main)
	main.set_paused(true)
	main.call_next_wave()
	main.use_ability(&"bell")
	_check(main.wave == 0 and main.ability_wait[&"bell"] == 0.0, "In der Pause keine Welle und keine Fähigkeit")
	var before: float = main.countdown
	for i in 5:
		await get_tree().process_frame
	_check(get_tree().paused and main.countdown == before, "Pause hält den Countdown an")
	main.set_paused(false)
	main.gold = 2000
	var built := 0
	for at in [Vector2i(16, 9), Vector2i(16, 12 - 4), Vector2i(15, 10), Vector2i(14, 8), Vector2i(16, 6), Vector2i(13, 10)]:
		for id in [&"archer", &"bowman", &"spearman", &"mage", &"catapult", &"ballista"]:
			if main.board.towers.has(at):
				break
			if main.try_build(id, at) != null:
				built += 1
				break
	_check(built >= 5, "Türme gebaut (%d)" % built)
	var tower: Tower = main.board.towers.values()[0]
	_test_targeting(main, tower)
	var gold_now: int = main.gold
	var quick: Tower = main.try_build(&"archer", Vector2i(10, 4))
	main.select_tower(quick)
	main.sell_selected()
	_check(main.gold == gold_now, "Abriss in derselben Bauzeit gibt alles zurück")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_2
	main.hud._unhandled_key_input(key)
	var picked: StringName = main.hud.selected_build
	main.hud._unhandled_key_input(key)
	_check(picked == Defs.BUILD_ORDER[1] and main.hud.selected_build == &"", "Taste 2 wählt den zweiten Turm und wieder ab")
	var turn_key := InputEventKey.new()
	turn_key.pressed = true
	turn_key.keycode = KEY_E
	turn_key.physical_keycode = KEY_E
	var yaw: float = main.rig._yaw
	main.hud._unhandled_key_input(turn_key)
	main._unhandled_input(turn_key)
	_check(main.rig._yaw > yaw, "Taste E dreht die Kamera")
	main.rig._turn.kill()
	main.rig._yaw = yaw
	main.rig.rotation.y = yaw
	var pan_key := InputEventKey.new()
	pan_key.pressed = true
	pan_key.physical_keycode = KEY_D
	Input.parse_input_event(pan_key)
	Input.flush_buffered_events()
	var from: Vector3 = main.rig.position
	main.rig._process(0.1)
	pan_key.pressed = false
	Input.parse_input_event(pan_key)
	Input.flush_buffered_events()
	_check(main.rig.position != from, "Taste D verschiebt die Karte")
	main.rig.position = from
	await _test_bar_drag(main)
	await _test_abilities(main)
	await _test_new_enemies(main)
	await _test_new_towers(main)
	main.select_tower(tower)
	main.upgrade_selected()
	_check(tower.level == 2, "Ausbau auf Stufe 2")
	main.upgrade_selected()
	var options := tower.spec_options()
	_check(tower.level == 3 and options.size() == 2, "Auf Stufe 3 zwei Spezialisierungen")
	main.specialize_selected(options[1]["id"])
	_check(tower.spec_id == options[1]["id"] and tower.spec_options().is_empty(), "Spezialisiert: %s" % tower.title())
	var sky: Tower = main.try_build(&"skyguard", Vector2i(15, 8))
	_check(sky != null and sky.targets() == "air", "Himmelswacht trifft nur Luft")
	await _test_resume(main)
	Engine.time_scale = 8.0
	main.countdown = 0.1
	var waited := 0.0
	var early := false
	while main.wave < 4 and waited < 300.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		early = early or (main.countdown > 0.0 and not main.enemies.is_empty())
		if main.countdown > 0.0 and main.wave < 4:
			main.call_next_wave()
	for i in 600:
		if main.enemies.is_empty() and main._queue.is_empty():
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	_check(main.kills > 10, "Türme töten Gegner (%d, Leben %d)" % [main.kills, main.lives])
	_check(not early, "Pause erst, wenn die Welle besiegt ist")
	_check(main.wave >= 4, "Vier Wellen gespielt, auch eine Luftwelle (%d)" % main.wave)
	var credited := 0
	for placed: Tower in main.board.towers.values():
		credited += placed.kills
	_check(credited > 0 and credited <= main.kills and main._stats().contains("Bester Turm") and main.gold_earned > 0,
			"Siege werden Türmen gutgeschrieben (%d von %d)" % [credited, main.kills])
	var gold_before: int = main.gold
	main.select_tower(tower)
	main.sell_selected()
	_check(main.gold > gold_before and not main.board.towers.has(tower.cell), "Abreißen gibt Gold zurück")
	main.gold = 200
	main._pay_interest()
	var small: int = main.gold - 200
	main.gold = 2000
	main._pay_interest()
	_check(small == 10 and main.gold == 2025, "Zinsen 5 %%, höchstens 25 (%d)" % small)
	main.wave = Defs.WAVES
	main._finish(true)
	_check(Settings.saved_game().is_empty(), "Nach dem Ende ist der Spielstand gelöscht")
	main.continue_endless()
	_check(not main.game_over and main.endless and main.countdown > 0.0 and not Defs.wave(Defs.WAVES + 5).is_empty(),
			"Nach dem Sieg geht es endlos weiter")
	main.queue_free()
	await get_tree().process_frame
