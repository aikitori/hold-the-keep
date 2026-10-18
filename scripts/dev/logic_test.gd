extends Node
## Test ohne Fenster: Wegfindung, Bauregeln, Wellen und ein kurzer Spielablauf mit Türmen.
## Start: godot --headless res://scenes/dev/logic_test.tscn

var _failed := false


func _check(ok: bool, text: String) -> void:
	print(("ok:   " if ok else "FAIL: ") + text)
	if not ok:
		_failed = true


func _ready() -> void:
	var map := MapData.load_map(&"vier_felder")
	_check(map.spawn != Vector2i(-1, -1) and map.keep != Vector2i(-1, -1), "Karte hat Friedhof und Burg")
	var board := Board.new(map)
	var path := board.path_from(map.spawn)
	_check(path.size() > 40 and path[-1] == map.keep, "Weg vom Friedhof zur Burg führt durch alle Felder (%d Schritte)" % path.size())
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
	var longer := maze.path_from(map.spawn)
	_check(maze.path_length(longer) > board.path_length(path) + 10.0,
			"Mauern machen den Weg länger (%.1f statt %.1f)" % [maze.path_length(longer), board.path_length(path)])
	_check(board.check_build(Vector2i(5, 5), [Vector2i(5, 5)]) == Board.BuildCheck.ENEMY_THERE, "Nicht auf Gegnern bauen")
	var boss_wave := Defs.wave(5)
	_check(boss_wave[0] == &"vampire" and Defs.wave(10)[0] == &"keeper", "Bosse in Welle 5 und 10")
	_check(Defs.upgrade_cost(&"archer", 3) == -1 and Defs.upgrade_cost(&"wall", 1) == -1, "Ausbau endet bei Stufe 3, Mauern nie")
	await _play()
	print("LOGIC-TEST ", "FEHLGESCHLAGEN" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


## Kurzer Ablauf: Türme an den Ausgang von Feld A, drei Wellen im Zeitraffer.
func _play() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
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
	main.select_tower(tower)
	main.upgrade_selected()
	_check(tower.level == 2, "Ausbau auf Stufe 2")
	Engine.time_scale = 8.0
	main.countdown = 0.1
	var waited := 0.0
	while main.wave < 3 and waited < 240.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
		if main.countdown > 0.0 and main.wave < 3:
			main.call_next_wave()
	for i in 600:
		if main.enemies.is_empty() and main._queue.is_empty():
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	_check(main.kills > 10, "Türme töten Gegner (%d, Leben %d)" % [main.kills, main.lives])
	_check(main.wave >= 3, "Mindestens drei Wellen gespielt (%d)" % main.wave)
	var gold_before: int = main.gold
	main.select_tower(tower)
	main.sell_selected()
	_check(main.gold > gold_before and not main.board.towers.has(tower.cell), "Abreißen gibt Gold zurück")
	main.queue_free()
	await get_tree().process_frame
