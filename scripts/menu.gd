extends Control
## Startmenü: Titel und eine Karte pro Spielfeld mit Beschreibung. Ein Klick startet das Spiel.

const MAIN_SCENE := "res://scenes/main.tscn"


func _ready() -> void:
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Hud.make_theme()
	var background := ColorRect.new()
	background.color = Color("#1d2a24")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var title := Label.new()
	title.text = "Hold the Keep"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Hud.GOLD)
	title.add_theme_color_override("font_outline_color", Hud.INK)
	title.add_theme_constant_override("outline_size", 12)
	column.add_child(title)
	var tagline := Label.new()
	tagline.text = "Die Toten ziehen vom Friedhof zur Burg. Baue Türme, lege Labyrinthe, halte die Burg."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.custom_minimum_size.x = 420
	column.add_child(tagline)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	column.add_child(grid)
	for id: StringName in MapData.ORDER:
		grid.add_child(_card(id))
	var layout := func() -> void: grid.columns = 1 if UiScale.narrow else 2
	UiScale.changed.connect(layout)
	layout.call()


func _card(id: StringName) -> Control:
	var def: Dictionary = MapData.MAPS[id]
	var map := MapData.load_map(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var name := Label.new()
	name.text = def["name"]
	name.add_theme_font_size_override("font_size", 30)
	name.add_theme_color_override("font_color", Hud.GOLD)
	box.add_child(name)
	var info := Label.new()
	info.text = def["info"]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(400, 0)
	box.add_child(info)
	var facts := Label.new()
	var checkpoints := map.waypoints.size() - 1
	facts.text = "%d x %d Felder · %s" % [map.size.x, map.size.y,
			"%d Kontrollpunkte" % checkpoints if checkpoints > 0 else "ohne Kontrollpunkte"]
	facts.add_theme_font_size_override("font_size", 16)
	facts.add_theme_color_override("font_color", Color("#c9b994"))
	box.add_child(facts)
	var play := Button.new()
	play.text = "Spielen"
	play.custom_minimum_size.y = 48
	play.pressed.connect(func() -> void:
		Sfx.play(&"click")
		Main.map_id = id
		get_tree().change_scene_to_file(MAIN_SCENE))
	box.add_child(play)
	return panel
