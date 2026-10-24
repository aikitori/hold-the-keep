extends Control
## Startmenü: Titel und eine Kachel pro Spielfeld mit Vorschau und Beschreibung. Ein Klick startet das Spiel.
## Quer stehen die Kacheln nebeneinander, im Hochformat zwei mal zwei. Passt das nicht auf den Bildschirm,
## wird alles verkleinert: das Menü scrollt nie.

const MAIN_SCENE := "res://scenes/main.tscn"
const CARD := 290.0
const MARGIN := 16.0

var _cards: Array[PanelContainer] = []
var _column := VBoxContainer.new()
var _grid := GridContainer.new()
var _best_labels: Dictionary = {}  # Karte -> Label


func _ready() -> void:
	Engine.time_scale = 1.0
	Sfx.music(&"build")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Hud.make_theme()
	var background := ColorRect.new()
	background.color = Color("#1d2a24")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# Kein Container darüber: Container setzen den Maßstab ihrer Kinder zurück, _fit platziert selbst.
	var column := _column
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var title := Label.new()
	title.text = "Hold the Keep"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Hud.GOLD)
	title.add_theme_color_override("font_outline_color", Hud.INK)
	title.add_theme_constant_override("outline_size", 12)
	column.add_child(title)
	var tagline := Label.new()
	tagline.text = tr("Die Toten ziehen vom Friedhof zur Burg. Baue Türme, lege Labyrinthe, halte die Burg.")
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.custom_minimum_size.x = 420
	column.add_child(tagline)
	column.add_child(_options())
	var saved := Settings.saved_game()
	if not saved.is_empty() and MapData.MAPS.has(saved.get("map", &"")):
		var resume := Button.new()
		resume.text = tr("Weiterspielen: %s, Welle %d (%s)") % [tr(MapData.MAPS[saved["map"]]["name"]), int(saved["wave"]) + 1,
				tr(Defs.DIFFICULTIES[saved["difficulty"]]["name"])]
		resume.custom_minimum_size = Vector2(420, 52)
		resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		resume.pressed.connect(func() -> void:
			Sfx.play(&"click")
			Main.map_id = saved["map"]
			Main.resume = saved
			get_tree().change_scene_to_file(MAIN_SCENE))
		column.add_child(resume)
	var grid := _grid
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	column.add_child(grid)
	for id: StringName in MapData.ORDER:
		_cards.append(_card(id))
		grid.add_child(_cards[-1])
	Settings.changed.connect(_show_best)
	_show_best()
	UiScale.changed.connect(_layout)
	_column.minimum_size_changed.connect(_fit)
	get_viewport().size_changed.connect(_fit)
	_layout()


func _layout() -> void:
	_grid.columns = 2 if UiScale.narrow else _cards.size()
	_fit.call_deferred()


## Verkleinern, bis alles auf den Bildschirm passt (Größer wird es nie).
func _fit() -> void:
	var need := _column.get_combined_minimum_size()
	var room := get_viewport_rect().size - Vector2.ONE * MARGIN * 2.0
	if need.x <= 0.0 or need.y <= 0.0:
		return
	var fit := minf(1.0, minf(room.x / need.x, room.y / need.y))
	_column.size = need
	_column.scale = Vector2(fit, fit)
	_column.position = (get_viewport_rect().size - need * fit) / 2.0


## Schwierigkeit und Grafikstufe.
func _options() -> Control:
	# Bricht im Hochformat um, statt das Menü zu verbreitern.
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	var label := Label.new()
	label.text = tr("Schwierigkeit")
	row.add_child(label)
	var group := ButtonGroup.new()
	for level: StringName in Defs.DIFFICULTY_ORDER:
		var button := Button.new()
		button.text = tr(Defs.DIFFICULTIES[level]["name"])
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = Settings.difficulty == level
		button.custom_minimum_size = Vector2(96, 44)
		button.pressed.connect(func() -> void:
			Sfx.play(&"click")
			Settings.set_difficulty(level))
		row.add_child(button)
	var gap := Control.new()
	gap.custom_minimum_size.x = 24
	row.add_child(gap)
	var graphics := Button.new()
	graphics.custom_minimum_size = Vector2(170, 44)
	var show := func() -> void: graphics.text = tr("Grafik: niedrig") if Settings.low_graphics else tr("Grafik: hoch")
	show.call()
	graphics.pressed.connect(func() -> void:
		Sfx.play(&"click")
		Settings.set_low_graphics(not Settings.low_graphics)
		show.call())
	row.add_child(graphics)
	var music := Button.new()
	music.custom_minimum_size = Vector2(150, 44)
	music.text = tr("Musik: an") if Sfx.music_on else tr("Musik: aus")
	music.pressed.connect(func() -> void:
		Sfx.play(&"click")
		Sfx.set_music_on(not Sfx.music_on)
		music.text = tr("Musik: an") if Sfx.music_on else tr("Musik: aus"))
	row.add_child(music)
	# Sprache: Knopf zeigt die andere Sprache, das Menü baut sich danach neu auf.
	var language := Button.new()
	language.custom_minimum_size = Vector2(110, 44)
	var other: String = Lang.LANGUAGES[(Lang.LANGUAGES.find(Settings.language) + 1) % Lang.LANGUAGES.size()]
	language.text = Lang.NAMES[other]
	language.pressed.connect(func() -> void:
		Sfx.play(&"click")
		Settings.set_language(other)
		get_tree().reload_current_scene())
	row.add_child(language)
	return row


func _show_best() -> void:
	for id: StringName in _best_labels:
		var best := Settings.best(id)
		var label: Label = _best_labels[id]
		if best["won"]:
			label.text = tr("Gewonnen! Endlos bis Welle %d") % best["wave"] if best["wave"] > Defs.WAVES else tr("Gewonnen!")
		else:
			label.text = tr("Bestwert: Welle %d") % best["wave"] if best["wave"] > 0 else tr("Noch nicht gespielt")


func _card(id: StringName) -> PanelContainer:
	var def: Dictionary = MapData.MAPS[id]
	var map := MapData.load_map(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = CARD
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var name := Label.new()
	name.text = tr(def["name"])
	name.add_theme_font_size_override("font_size", 30)
	name.add_theme_color_override("font_color", Hud.GOLD)
	box.add_child(name)
	var level := Label.new()
	var rank: int = def["level"]
	level.text = tr(MapData.LEVELS[rank - 1])
	level.add_theme_font_size_override("font_size", 16)
	level.add_theme_color_override("font_color", [Color("#8fd16a"), Color("#e8c45a"), Color("#e8735a")][rank - 1])
	box.add_child(level)
	var preview := MapPreview.new(map)
	preview.set_width(CARD - 20)  # abzüglich Innenabstand der Kachel
	box.add_child(preview)
	var info := Label.new()
	info.text = tr(def["info"])
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size.x = CARD - 20
	box.add_child(info)
	var facts := Label.new()
	var checkpoints := map.waypoints.size() - 1
	facts.text = tr("%d x %d Felder · %s") % [map.size.x, map.size.y,
			tr("1 Kontrollpunkt") if checkpoints == 1 else tr("%d Kontrollpunkte") % checkpoints if checkpoints > 1
			else tr("ohne Kontrollpunkte")]
	facts.add_theme_font_size_override("font_size", 16)
	facts.add_theme_color_override("font_color", Color("#c9b994"))
	box.add_child(facts)
	var best := Label.new()
	best.add_theme_font_size_override("font_size", 18)
	best.add_theme_color_override("font_color", Hud.GOLD)
	box.add_child(best)
	_best_labels[id] = best
	var play := Button.new()
	play.text = tr("Spielen")
	play.custom_minimum_size.y = 48
	play.pressed.connect(func() -> void:
		Sfx.play(&"click")
		Main.map_id = id
		get_tree().change_scene_to_file(MAIN_SCENE))
	box.add_child(play)
	return panel
