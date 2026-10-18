extends Node
## Screenshots (braucht ein Fenster oder Xvfb): godot res://scenes/dev/shot.tscn -- <Ordner>
## Baut ein paar Türme, startet zwei Wellen und speichert Übersicht und Nahansicht.

func _ready() -> void:
	var folder: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	main.gold = 3000
	var plan := {
		Vector2i(7, 2): &"wall", Vector2i(7, 3): &"wall", Vector2i(7, 4): &"wall", Vector2i(7, 5): &"wall",
		Vector2i(7, 6): &"wall", Vector2i(7, 7): &"archer", Vector2i(7, 8): &"wall", Vector2i(7, 9): &"mage",
		Vector2i(6, 6): &"bowman", Vector2i(8, 9): &"spearman", Vector2i(5, 10): &"catapult", Vector2i(10, 4): &"ballista",
		Vector2i(13, 11): &"wall", Vector2i(13, 10): &"wall", Vector2i(13, 9): &"archer", Vector2i(13, 8): &"wall",
		Vector2i(13, 7): &"wall", Vector2i(13, 6): &"trebuchet", Vector2i(13, 5): &"wall", Vector2i(13, 4): &"bowman",
		Vector2i(12, 7): &"spearman", Vector2i(15, 3): &"archer",
	}
	for at: Vector2i in plan:
		var tower: Tower = main.try_build(plan[at], at)
		if tower != null and (at.x + at.y) % 3 == 0 and tower.can_upgrade():
			tower.upgrade()
	main.countdown = 0.1
	Engine.time_scale = 30.0
	await _frames(12)
	main.call_next_wave()
	Engine.time_scale = 10.0
	await _frames(8)
	Engine.time_scale = 0.0
	main.rig.position = Vector3(10, 0, 7)
	main.rig.camera.size = 12.0
	await _frames(2)
	get_viewport().get_texture().get_image().save_png(folder + "/nah.png")
	main.rig.position = Vector3(19.5, 0, 12.5)
	main.rig.camera.size = 26.0
	await _frames(2)
	get_viewport().get_texture().get_image().save_png(folder + "/karte.png")
	main.select_tower(main.board.towers[Vector2i(13, 9)])
	main.rig.position = Vector3(12, 0, 8)
	main.rig.camera.size = 8.0
	await _frames(2)
	get_viewport().get_texture().get_image().save_png(folder + "/turm.png")
	Engine.time_scale = 1.0
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
