extends Node
## Balance-Probe ohne Fenster: ein einfacher Bot spielt alle Wellen einer Karte und meldet je Welle Leben und Gold.
## Der Bot baut nur neben den Weg (kein Labyrinth), baut aus und spezialisiert: ein schwacher Spieler.
## Start: godot --headless res://scenes/dev/balance.tscn -- <karte> [easy|normal|hard]

const MIX: Array[StringName] = [&"archer", &"mage", &"ballista", &"catapult", &"archer", &"skyguard", &"trebuchet", &"spearman"]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	Main.map_id = StringName(args[0]) if args.size() > 0 else &"vier_felder"
	Settings.file = "user://balance.cfg"
	Settings.save_file = "user://balance_save.cfg"
	Settings.difficulty = StringName(args[1]) if args.size() > 1 else &"normal"
	Sfx.muted = true
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var spots := _spots(main)
	var built := 0
	Engine.time_scale = 10.0
	var last_wave := 0
	while not main.game_over:
		await get_tree().process_frame
		if main.countdown > 0.0 and main.wave > 0 and main.wave != _reported:
			_reported = main.wave
			print("Welle %2d: Leben %2d, Gold %4d, Türme %d" % [main.wave, main.lives, main.gold, main.board.towers.size()])
		if main.countdown > 0.0 and main._queue.is_empty():
			# Bauzeit: erst ausbauen, dann neue Türme, dann die Welle rufen.
			for tower: Tower in main.board.towers.values():
				if tower.can_upgrade() and main.gold >= Defs.upgrade_cost(tower.id, tower.level) + 20:
					main.select_tower(tower)
					main.upgrade_selected()
				elif not tower.spec_options().is_empty() and main.gold >= tower.spec_options()[0]["cost"] + 20:
					main.select_tower(tower)
					main.specialize_selected(tower.spec_options()[built % 2]["id"])
			main.select_tower(null)
			while built < spots.size() and main.gold >= Defs.TOWERS[MIX[built % MIX.size()]]["cost"]:
				main.try_build(MIX[built % MIX.size()], spots[built])
				built += 1
			if main.wave > last_wave or main.wave == 0:
				last_wave = main.wave
				main.call_next_wave()
		for id: StringName in main.ability_wait:
			if main.ability_wait[id] <= 0.0 and main.enemies.size() > 8 and id != &"pitch":
				main.use_ability(id)
	print("ERGEBNIS %s %s: %s bei Welle %d, Leben %d" % [Main.map_id, Settings.difficulty,
			"gewonnen" if main.lives > 0 else "verloren", main.wave, main.lives])
	DirAccess.remove_absolute(Settings.file)
	get_tree().quit()


var _reported := 0


## Bauplätze neben dem Weg, vom Friedhof aus gesehen, in Abständen.
func _spots(main: Main) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var paths: Array = main.board.full_paths()
	var on_path := {}
	for path: Array in paths:
		for at: Vector2i in path:
			on_path[at] = true
	var longest := 0
	for path: Array in paths:
		longest = maxi(longest, path.size())
	# Abwechselnd an allen Wegen, damit kein Friedhof unbewacht bleibt.
	for i in range(3, longest, 2):
		for path: Array in paths:
			if i >= path.size():
				continue
			for offset in [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(2, 0), Vector2i(0, 2)]:
				var at: Vector2i = path[i] + offset
				if main.map.buildable(at) and not on_path.has(at) and not out.has(at):
					out.append(at)
					break
	return out
