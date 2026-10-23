extends Control
## Startmenü: Titel und eine Kachel pro Spielfeld mit Vorschau und Beschreibung. Ein Klick startet das Spiel.
## Breit stehen die Kacheln nebeneinander, sonst zu zweit, im Hochformat untereinander.

const MAIN_SCENE := "res://scenes/main.tscn"
const WIDE_CARD := 290.0
const CARD := 420.0

var _cards: Array[PanelContainer] = []


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
		_cards.append(_card(id))
		grid.add_child(_cards[-1])
	var layout := func() -> void:
		var count := _cards.size()
		var wide := get_viewport_rect().size.x >= count * (WIDE_CARD + 16) + 40
		grid.columns = 1 if UiScale.narrow else count if wide else 2
		_set_card_width(WIDE_CARD if wide and not UiScale.narrow else CARD)
	UiScale.changed.connect(layout)
	layout.call()


func _set_card_width(width: float) -> void:
	for panel in _cards:
		panel.custom_minimum_size.x = width
		var inner := width - 20  # Innenabstand der Kachel
		(panel.get_meta("preview") as MapPreview).set_width(inner)
		(panel.get_meta("info") as Label).custom_minimum_size.x = inner


func _card(id: StringName) -> PanelContainer:
	var def: Dictionary = MapData.MAPS[id]
	var map := MapData.load_map(id)
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var name := Label.new()
	name.text = def["name"]
	name.add_theme_font_size_override("font_size", 30)
	name.add_theme_color_override("font_color", Hud.GOLD)
	box.add_child(name)
	var preview := MapPreview.new(map)
	box.add_child(preview)
	panel.set_meta("preview", preview)
	var info := Label.new()
	info.text = def["info"]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(info)
	panel.set_meta("info", info)
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
