extends Node
## Schaden pro Sekunde je Turm (Stufe 1) gegen ein stehendes Ziel, 10 s Spielzeit. Zeigt, wie stark ein Turm für
## sein Gold ist; Fläche, Verlangsamen und Unterstützung zählen hier nicht.
## Start: godot --headless res://scenes/dev/dps.tscn

func _ready() -> void:
	Settings.save_file = "user://dps_save.cfg"
	Sfx.muted = true
	Main.map_id = &"weites_feld"
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.countdown = 100000.0
	main.gold = 100000
	Engine.time_scale = 4.0
	for id: StringName in [&"archer", &"bowman", &"spearman", &"bombard", &"poison", &"ballista", &"catapult", &"mage", &"trebuchet"]:
		var tower: Tower = main.try_build(id, Vector2i(10, 8))
		var target := Enemy.new()
		main.add_child(target)
		target.setup(&"orc", 1, main, main.board)
		target.max_hp = 1e9
		target.hp = 1e9
		target.speed = 0.0
		target.position = Vector3(11, target.position.y, 9)
		main.enemies.append(target)
		var start := Time.get_ticks_msec()
		while Time.get_ticks_msec() - start < 2500:  # 10 s Spielzeit bei Tempo 4
			await get_tree().process_frame
		var dps := (1e9 - target.hp) / 10.0
		print("%-10s %3d Gold: %5.1f Schaden/s, %.2f je Gold" % [id, Defs.TOWERS[id]["cost"], dps, dps / Defs.TOWERS[id]["cost"]])
		main.enemies.erase(target)
		target.queue_free()
		main.select_tower(tower)
		main.sell_selected()
		for shot in main.get_children().filter(func(n: Node) -> bool: return n is Projectile):
			shot.queue_free()
		await get_tree().process_frame
	get_tree().quit()
