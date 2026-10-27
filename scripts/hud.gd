class_name Hud
extends CanvasLayer
## Oberfläche im Stil einer Burg: Holz mit Messingrand und Pergamentknöpfe. Oben Gold, Leben, Welle und Zeit mit
## Symbolen, rechts Pause, Tempo, nächste Welle und das Zahnrad (Ton, Musik, Menü). Unten die Bauleiste mit
## Bildern und Preisen, darüber eine Infozeile. Die Turm-Karte steht neben dem gewählten Turm. Lebensbalken der
## Gegner zeichnet `_bars`.

signal build_selected(id: StringName)
signal next_wave_pressed
signal speed_pressed
signal upgrade_pressed
signal sell_pressed
signal deselect_pressed
signal restart_pressed
signal menu_pressed
signal pause_pressed
signal endless_pressed
signal ability_pressed(id: StringName)
signal target_pressed
signal spec_pressed(spec_id: StringName)
signal turn_pressed(steps: int)
## Turm aus der Bauleiste aufs Feld ziehen (`at` in Bildschirmkoordinaten wie bei `blocks`).
signal build_dragged(id: StringName, at: Vector2, touch: bool)
signal build_dropped(id: StringName, at: Vector2, touch: bool, keep: bool)

const FONT := preload("res://assets/fonts/MedievalSharp.ttf")
const WOOD := Color("#3b2a1e")
const WOOD_LIGHT := Color("#5a4030")
const PARCHMENT := Color("#efe2c0")
const INK := Color("#2b1d12")
const GOLD := Color("#f2c14e")
const BRASS := Color("#a07a3a")
const BLOOD := Color("#c0392b")
## Tasten für die Bauleiste: 1 bis 9, dann 0. Ab dem elften Turm mit Umschalt: Umschalt+1 ist der elfte.
const BUILD_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
## Fähigkeiten nach Lage auf der Tastatur (unterste Reihe links, WASD und Q E gehören der Kamera).
const ABILITY_KEYS := [KEY_Z, KEY_X, KEY_C]

var main: Node
var selected_build: StringName = &""
var _gold_label := Label.new()
var _lives_label := Label.new()
var _wave_label := Label.new()
var _timer_label := Label.new()
var _timer_glyph := Glyph.make("hourglass")
var _stat_glyphs: Array[Glyph] = []
var _stat_labels: Array[Label] = []
var _top_bar := PanelContainer.new()
var _top_row := HBoxContainer.new()
var _top_row2 := HBoxContainer.new()
var _top_buttons: Array[Button] = []
var _pause_button: Button
var _speed_button: Button
var _next_button: Button
var _gear_button: Button
var _gear_panel := PanelContainer.new()
var _sound_button := Button.new()
var _edge_button := Button.new()
var _bar_drag: StringName = &""  # Turm, der gerade aus der Bauleiste gezogen wird
var _bar_press := Vector2.ZERO
var _music_button := Button.new()
var _preview := Label.new()
var _preview_wave := -1
var _bottom_bar := PanelContainer.new()
var _build_info := Label.new()
var _build_grid := GridContainer.new()
var _build_buttons: Dictionary = {}
var _card := PanelContainer.new()
var _card_title := Label.new()
var _card_text := Label.new()
var _card_buttons := HBoxContainer.new()
var _upgrade_button := Button.new()
var _sell_button := Button.new()
var _target_button := Button.new()
var _spec_buttons: Array[Button] = []
var _spec_ids: Array[StringName] = [&"", &""]
var _toast := Label.new()
var _toast_tween: Tween
var _pause_panel := PanelContainer.new()
var _end_panel := PanelContainer.new()
var _end_title := Label.new()
var _end_text := Label.new()
var _endless_button := Button.new()
var _ability_buttons: Dictionary = {}
var _bars := Control.new()
var _root := Control.new()
var _icons: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # bedienbar, auch wenn das Spiel pausiert
	# Lebensbalken liegen über der ganzen Fläche, die Bedienelemente rücken vom Notch weg (siehe _layout).
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	add_child(_bars)
	var root := _root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = make_theme()
	add_child(root)
	_build_top(root)
	_build_gear(root)
	_build_bottom(root)
	_build_card(root)
	_build_abilities(root)
	_build_end(root)
	_build_pause(root)
	_toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_left = 16
	_toast.offset_right = -16
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_color_override("font_color", PARCHMENT)
	_toast.add_theme_color_override("font_outline_color", INK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)
	for button in root.find_children("*", "Button", true, false):
		# Ohne Fokus: sonst löst die Leertaste den zuletzt geklickten Knopf noch einmal aus.
		(button as Button).focus_mode = Control.FOCUS_NONE
		if not button in [_upgrade_button, _sell_button] and not button in _spec_buttons:
			(button as Button).pressed.connect(Sfx.play.bind(&"click"))
	UiScale.changed.connect(_layout)
	_layout()


## Breit: alles in einer Zeile oben, Bauleiste einreihig. Schmal (Hochformat): Knöpfe in zweiter Zeile,
## Bauleiste in zwei Reihen. Kompakt (Handy quer): alles kleiner, die Bauleiste weicht der Turm-Karte.
func _layout() -> void:
	var narrow: bool = UiScale.narrow
	var compact: bool = UiScale.compact
	_root.offset_left = UiScale.safe.x
	_root.offset_top = UiScale.safe.y
	_root.offset_right = -UiScale.safe.z
	_root.offset_bottom = -UiScale.safe.w
	for label in _stat_labels:
		label.add_theme_font_size_override("font_size", 18 if compact else 22)
	for glyph in _stat_glyphs:
		glyph.custom_minimum_size = Vector2.ONE * (18.0 if compact else 22.0)
	for button in _top_buttons:
		button.custom_minimum_size.y = 34 if compact else 42
		button.add_theme_font_size_override("font_size", 16 if compact else 19)
		var glyph: Glyph = button.get_meta("glyph")
		glyph.custom_minimum_size = Vector2.ONE * (16.0 if compact else 20.0)
	_preview.add_theme_font_size_override("font_size", 14 if compact else 16)
	_toast.add_theme_font_size_override("font_size", 20 if compact else 26)
	for id: StringName in _ability_buttons:
		var ability: Button = _ability_buttons[id]
		ability.custom_minimum_size = Vector2(100, 38) if compact else Vector2(120, 48)
		ability.add_theme_font_size_override("font_size", 14 if compact else 17)
	_card.custom_minimum_size.x = 200 if compact else 240
	_card_title.add_theme_font_size_override("font_size", 18 if compact else 22)
	_card_text.add_theme_font_size_override("font_size", 14 if compact else 17)
	for button: Button in _card.find_children("*", "Button", true, false):
		button.add_theme_font_size_override("font_size", 14 if compact else 17)
	_build_info.add_theme_font_size_override("font_size", 14 if compact else 16)
	_top_row2.visible = narrow
	_top_row.add_theme_constant_override("separation", 12 if narrow else 18)
	for button in _top_buttons:
		button.reparent(_top_row2 if narrow else _top_row)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
	var count := Defs.BUILD_ORDER.size()
	_build_grid.columns = ceili(count / 2.0) if narrow else count
	for id: StringName in _build_buttons:
		var button: Button = _build_buttons[id]
		button.custom_minimum_size = Vector2(70, 74) if narrow or compact else Vector2(84, 88)
		var icon: TextureRect = button.get_meta("icon")
		icon.custom_minimum_size = Vector2(58, 42) if narrow or compact else Vector2(72, 54)
		(button.get_meta("cost") as Label).add_theme_font_size_override("font_size", 14 if narrow or compact else 16)


## Holz mit Messingrand, Pergamentknöpfe mit Kante unten (gedrückt: Kante oben, wie eingedrückt).
static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 20
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(WOOD, 0.95)
	panel.border_color = BRASS
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.set_content_margin_all(9)
	panel.shadow_color = Color(0, 0, 0, 0.4)
	panel.shadow_size = 8
	panel.shadow_offset = Vector2(0, 3)
	theme.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": PARCHMENT, "hover": Color("#fff6de"), "pressed": GOLD,
				"disabled": Color("#8d7f66"), "focus": PARCHMENT}[state]
		box.border_color = Color("#7a5a2e") if state != "pressed" else Color("#8a5a10")
		box.set_border_width_all(2)
		box.border_width_bottom = 2 if state == "pressed" else 4
		box.border_width_top = 4 if state == "pressed" else 2
		box.set_corner_radius_all(6)
		box.set_content_margin_all(6)
		if state == "focus":
			box.draw_center = false
			box.border_color = GOLD
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_hover_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("#3f362b"))
	theme.set_color("font_color", "Label", PARCHMENT)
	return theme


## Knopf mit Symbol und optionalem Text, Größe aus dem Inhalt.
func _icon_button(kind: String, text := "") -> Button:
	var button := Button.new()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 6)
	button.add_child(row)
	var glyph := Glyph.make(kind, 20.0, INK)
	row.add_child(glyph)
	var label := Label.new()
	label.text = text
	label.visible = text != ""
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	button.set_meta("glyph", glyph)
	button.set_meta("label", label)
	# Breite folgt dem Inhalt (Kinder eines Knopfs zählen nicht von selbst mit).
	row.minimum_size_changed.connect(func() -> void: button.custom_minimum_size.x = row.get_combined_minimum_size().x + 18)
	return button


func _set_button_text(button: Button, text: String) -> void:
	var label: Label = button.get_meta("label")
	label.text = text
	label.visible = text != ""


func _stat(kind: String, label: Label, color: Color, glyph: Glyph = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if glyph == null:
		glyph = Glyph.make(kind, 22.0)
	row.add_child(glyph)
	_stat_glyphs.append(glyph)
	label.add_theme_color_override("font_color", color)
	row.add_child(label)
	_stat_labels.append(label)
	return row


func _build_top(root: Control) -> void:
	var bar := _top_bar
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 8
	bar.offset_right = -8
	bar.offset_top = 8
	root.add_child(bar)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	bar.add_child(rows)
	rows.add_child(_top_row)
	_top_row2.add_theme_constant_override("separation", 8)
	rows.add_child(_top_row2)
	# Was als Nächstes kommt, solange Zeit zum Bauen ist.
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview.add_theme_color_override("font_color", Color("#d9c9a0"))
	_preview.visible = false
	rows.add_child(_preview)
	_top_row.add_child(_stat("coin", _gold_label, GOLD))
	_top_row.add_child(_stat("heart", _lives_label, Color("#f08a7a")))
	_top_row.add_child(_stat("skull", _wave_label, PARCHMENT))
	_top_row.add_child(_stat("hourglass", _timer_label, Color("#d9c9a0"), _timer_glyph))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_row.add_child(spacer)
	var turn_button := _icon_button("turn")
	turn_button.tooltip_text = tr("Kamera drehen") + " (Q / E)"
	turn_button.pressed.connect(func() -> void: turn_pressed.emit(1))
	_pause_button = _icon_button("pause")
	_pause_button.tooltip_text = tr("Pause") + " (P)"
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_speed_button = _icon_button("fast", "1x")
	_speed_button.pressed.connect(func() -> void: speed_pressed.emit())
	_next_button = _icon_button("play", tr("Nächste Welle"))
	_next_button.pressed.connect(func() -> void: next_wave_pressed.emit())
	_gear_button = _icon_button("gear")
	(_gear_button.get_meta("glyph") as Glyph).color = INK
	_gear_button.pressed.connect(func() -> void: _gear_panel.visible = not _gear_panel.visible)
	_top_buttons = [turn_button, _pause_button, _speed_button, _next_button, _gear_button]
	for button: Button in _top_buttons:
		_top_row.add_child(button)


## Zahnrad-Menü: Ton, Musik, zurück ins Menü. Klappt unter der oberen Leiste rechts auf.
func _build_gear(root: Control) -> void:
	_gear_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gear_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_gear_panel.offset_right = -8
	_gear_panel.visible = false
	root.add_child(_gear_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_gear_panel.add_child(box)
	var show_sound := func() -> void: _sound_button.text = tr("Ton aus") if Sfx.muted else tr("Ton an")
	var show_music := func() -> void: _music_button.text = tr("Musik: an") if Sfx.music_on else tr("Musik: aus")
	var show_edge := func() -> void: _edge_button.text = tr("Randscrollen: an") if Settings.edge_scroll else tr("Randscrollen: aus")
	show_sound.call()
	show_music.call()
	show_edge.call()
	_edge_button.tooltip_text = tr("Maus am Fensterrand verschiebt die Karte")
	_edge_button.visible = not UiScale.touch
	_edge_button.pressed.connect(func() -> void:
		Settings.set_edge_scroll(not Settings.edge_scroll)
		show_edge.call())
	_sound_button.pressed.connect(func() -> void:
		Sfx.set_muted(not Sfx.muted)
		show_sound.call())
	_music_button.pressed.connect(func() -> void:
		Sfx.set_music_on(not Sfx.music_on)
		show_music.call())
	var menu := Button.new()
	menu.text = tr("Zum Menü")
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	for button: Button in [_sound_button, _music_button, _edge_button, menu]:
		button.custom_minimum_size = Vector2(180, 42)
		box.add_child(button)


func _build_bottom(root: Control) -> void:
	var bar := _bottom_bar
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -8
	root.add_child(bar)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	bar.add_child(rows)
	# Name und Beschreibung des gewählten (oder überfahrenen) Turms.
	_build_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_info.custom_minimum_size.x = 300
	_build_info.visible = false
	rows.add_child(_build_info)
	_build_grid.columns = Defs.BUILD_ORDER.size()
	_build_grid.add_theme_constant_override("h_separation", 6)
	_build_grid.add_theme_constant_override("v_separation", 6)
	rows.add_child(_build_grid)
	for id: StringName in Defs.BUILD_ORDER:
		var def: Dictionary = Defs.TOWERS[id]
		var button := Button.new()
		button.toggle_mode = true
		var key: int = Defs.BUILD_ORDER.find(id)
		var key_name := OS.get_keycode_string(BUILD_KEYS[key % BUILD_KEYS.size()])
		if key >= BUILD_KEYS.size():
			key_name = tr("Umschalt+%s") % key_name
		button.tooltip_text = tr(def["info"]) + "\n" + tr("Taste %s") % key_name \
				+ "\n" + tr("Umschalt+Klick baut mehrere, oder aufs Feld ziehen")
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.add_theme_constant_override("separation", 0)
		button.add_child(box)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon.texture = _icon(id)
		box.add_child(icon)
		var price := HBoxContainer.new()
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price.add_theme_constant_override("separation", 3)
		price.add_child(Glyph.make("coin", 14.0))
		var cost := Label.new()
		cost.text = str(def["cost"])
		cost.add_theme_color_override("font_color", INK)
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price.add_child(cost)
		box.add_child(price)
		button.set_meta("icon", icon)
		button.set_meta("cost", cost)
		button.toggled.connect(func(on: bool) -> void: _on_build_toggled(id, on))
		button.gui_input.connect(func(event: InputEvent) -> void: _on_build_button_input(id, button, event))
		button.mouse_entered.connect(func() -> void: _show_build_info(id))
		button.mouse_exited.connect(func() -> void: _show_build_info(selected_build))
		_build_grid.add_child(button)
		_build_buttons[id] = button


func _show_build_info(id: StringName) -> void:
	_build_info.visible = id != &""
	if id != &"":
		var def: Dictionary = Defs.TOWERS[id]
		_build_info.text = "%s  ·  %s" % [tr(def["name"]), tr(def["info"])]


## Kleines Bild des Turms, gerendert in einem eigenen Viewport mit derselben Schrägsicht wie das Spiel.
func _icon(id: StringName) -> Texture2D:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(176, 132)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var model := Tower.build_model(id, 1)
	viewport.add_child(model)
	var height: float = model.get_meta("muzzle", 1.0)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(1.6, height + 0.6)
	viewport.add_child(cam)
	var center := Vector3(0, height * 0.5, 0)
	cam.look_at_from_position(center + Vector3(1, 0.8, 1).normalized() * 10.0, center, Vector3.UP)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 30, 0)
	viewport.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.78, 0.75)
	env.environment.ambient_light_energy = 0.6
	viewport.add_child(env)
	_icons[id] = viewport
	return viewport.get_texture()


## Fähigkeiten links am Rand, jede mit Restzeit.
func _build_abilities(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = 8
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	for id: StringName in Defs.ABILITY_ORDER:
		var button := Button.new()
		var physical: Key = ABILITY_KEYS[_ability_buttons.size()]
		# Beschriftung der Taste an dieser Stelle (QWERTZ: Y X C), das können nur die Rechner-Fenster.
		if OS.has_feature("pc") and DisplayServer.get_name() != "headless":
			physical = DisplayServer.keyboard_get_keycode_from_physical(physical)
		button.tooltip_text = tr(Defs.ABILITIES[id]["info"]) + "\n" + tr("Taste %s") % OS.get_keycode_string(physical)
		button.pressed.connect(func() -> void: ability_pressed.emit(id))
		box.add_child(button)
		_ability_buttons[id] = button


func update_abilities(wait: Dictionary, aiming: StringName) -> void:
	for id: StringName in _ability_buttons:
		var button: Button = _ability_buttons[id]
		var name := tr(Defs.ABILITIES[id]["name"])
		var rest: float = wait[id]
		button.disabled = rest > 0.0
		button.text = "%s\n%d s" % [name, ceili(rest)] if rest > 0.0 else (tr("Ziel wählen") if aiming == id else name)


func _on_build_toggled(id: StringName, on: bool) -> void:
	if on:
		for other: StringName in _build_buttons:
			if other != id:
				(_build_buttons[other] as Button).set_pressed_no_signal(false)
		selected_build = id
	elif selected_build == id:
		selected_build = &""
	_show_build_info(selected_build)
	build_selected.emit(selected_build)


## Aus der Bauleiste ziehen: sobald der Zeiger die Leiste verlässt, wird der Turm gewählt und die Vorschau
## folgt; Loslassen über dem Feld baut. Die Ereignisse bleiben beim gedrückten Knopf, auch außerhalb.
func _on_build_button_input(id: StringName, button: Button, event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null:
		return
	var at := button.get_global_transform() * mouse.position
	var touch := mouse.device == InputEvent.DEVICE_ID_EMULATION
	if mouse is InputEventMouseButton and (mouse as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if (mouse as InputEventMouseButton).pressed:
			_bar_press = at
			_bar_drag = &""
		elif _bar_drag == id:
			_bar_drag = &""
			build_dropped.emit(id, at, touch, mouse.shift_pressed)
	elif mouse is InputEventMouseMotion and mouse.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if _bar_drag == &"" and not button.disabled and at.distance_to(_bar_press) > 16.0 \
				and not _bottom_bar.get_global_rect().has_point(at):
			_bar_drag = id
			if selected_build != id:
				button.button_pressed = true
		if _bar_drag == id:
			build_dragged.emit(id, at, touch)


func clear_build() -> void:
	for id: StringName in _build_buttons:
		(_build_buttons[id] as Button).set_pressed_no_signal(false)
	selected_build = &""
	_show_build_info(&"")


## Turm-Karte: Titel mit Schließen-Kreuz, knappe Werte, Ausbauen und Abreißen nebeneinander, Zielwahl,
## Spezialisierungen. Steht neben dem Turm (siehe _place_card).
func _build_card(root: Control) -> void:
	_card.visible = false
	root.add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_card.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	_card_title.add_theme_color_override("font_color", GOLD)
	_card_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(_card_title)
	var close := _icon_button("close")
	close.custom_minimum_size = Vector2(34, 34)
	(close.get_meta("glyph") as Glyph).custom_minimum_size = Vector2(14, 14)
	close.pressed.connect(func() -> void: deselect_pressed.emit())
	head.add_child(close)
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.add_theme_color_override("font_color", Color("#e8d9b0"))
	box.add_child(_card_text)
	_card_buttons.add_theme_constant_override("separation", 6)
	box.add_child(_card_buttons)
	for button: Button in [_upgrade_button, _sell_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 40
		_card_buttons.add_child(button)
	_upgrade_button.pressed.connect(func() -> void: upgrade_pressed.emit())
	_sell_button.pressed.connect(func() -> void: sell_pressed.emit())
	_target_button.pressed.connect(func() -> void: target_pressed.emit())
	box.add_child(_target_button)
	for i in 2:
		var spec := Button.new()
		spec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spec.pressed.connect(func() -> void: spec_pressed.emit(_spec_ids[i]))
		box.add_child(spec)
		_spec_buttons.append(spec)


func show_tower(tower: Tower, gold: int) -> void:
	_bottom_bar.visible = tower == null or not UiScale.compact
	if tower == null:
		_card.visible = false
		return
	var def: Dictionary = Defs.TOWERS[tower.id]
	_card.visible = true
	_card_title.text = tr("%s · Stufe %d") % [tr(tower.title()), tower.level] if tower.id != &"wall" else tr(def["name"])
	var lines: Array[String] = []
	if def["damage"] > 0:
		lines.append(tr("Schaden %d · Reichweite %.1f") % [roundi(tower.damage()), tower.reach()])
		lines.append(tr("Schüsse pro Sekunde %.1f") % (1.0 / tower.cooldown()))
		if tower.high:
			lines.append(tr("Hochfläche: +%.1f Reichweite") % Defs.HIGH_RANGE)
		lines.append(tr({"ground": "Trifft Bodengegner", "air": "Trifft nur Fliegende", "both": "Trifft Boden und Luft"}[tower.targets()]))
		if tower.kills > 0:
			lines.append(tr("Besiegt: %d") % tower.kills)
	elif not def.has("support") and not def.has("income"):
		lines.append(tr(def["info"]))
	if tower.spec_id != &"":
		lines.append(tr(Defs.spec(tower.id, tower.spec_id)["info"]))
	if def.has("support"):
		lines.append(tr("Türme im Umkreis: +%d %% Schaden") % roundi(Defs.tower_support(tower.id, tower.level) * 100))
		if tower.stat("haste", 0.0) > 0.0:
			lines.append(tr("und +%d %% Tempo") % roundi(tower.stat("haste", 0.0) * 100))
	if def.has("income"):
		lines.append(tr("Gold je Welle: %d") % Defs.tower_income(tower.id, tower.level, tower.spec_id))
		if tower.stat("bounty", 0) > 0:
			lines.append(tr("Kopfgeld: +%d Gold im Umkreis") % tower.stat("bounty", 0))
	_target_button.visible = def["damage"] > 0
	_target_button.text = tr("Ziel: %s") % tr(Defs.TARGET_NAMES[tower.target_mode])
	var options := tower.spec_options()
	for i in 2:
		var button := _spec_buttons[i]
		button.visible = i < options.size()
		if button.visible:
			var option: Dictionary = options[i]
			_spec_ids[i] = option["id"]
			button.text = tr("%s  %d Gold\n%s") % [tr(option["name"]), option["cost"], tr(option["info"])]
			button.disabled = option["cost"] > gold
	if not options.is_empty():
		lines.append(tr("Wähle eine Spezialisierung:"))
	_card_text.text = "\n".join(lines)
	var cost := Defs.upgrade_cost(tower.id, tower.level)
	_upgrade_button.visible = cost > 0
	_upgrade_button.text = tr("Ausbauen  %d Gold") % cost
	_upgrade_button.disabled = cost > gold
	_sell_button.text = tr("Abreißen  +%d Gold") % tower.sell_value()
	_place_card(tower)


## Karte neben den Turm: rechts davon, sonst links; senkrecht zwischen den Leisten gehalten.
func _place_card(tower: Tower) -> void:
	if main == null:
		return
	var camera: Camera3D = main.rig.camera
	var spot := camera.unproject_position(tower.global_position + Vector3(0, tower.height() * 0.5, 0)) - _root.global_position
	var card := _card.get_combined_minimum_size()
	var area := _root.size
	var gap := 44.0
	var x := spot.x + gap
	if x + card.x > area.x - 8.0:
		x = spot.x - gap - card.x
	var top := _top_bar.get_rect().end.y + 8.0
	var bottom := (_bottom_bar.get_rect().position.y if _bottom_bar.visible else area.y) - 8.0
	var y := clampf(spot.y - card.y / 2.0, top, maxf(top, bottom - card.y))
	_card.position = Vector2(clampf(x, 8.0, maxf(8.0, area.x - card.x - 8.0)), y)
	_card.size = card


func _build_end(root: Control) -> void:
	_end_panel.set_anchors_preset(Control.PRESET_CENTER)
	_end_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_end_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_end_panel.visible = false
	root.add_child(_end_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	_end_panel.add_child(box)
	_end_title.add_theme_font_size_override("font_size", 40)
	_end_title.add_theme_color_override("font_color", GOLD)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_end_title)
	_end_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_end_text)
	_endless_button.text = tr("Endlos weiterspielen")
	_endless_button.pressed.connect(func() -> void: endless_pressed.emit())
	box.add_child(_endless_button)
	var again := Button.new()
	again.text = tr("Neues Spiel")
	again.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(again)
	var menu := Button.new()
	menu.text = tr("Zum Menü")
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	box.add_child(menu)


func _build_pause(root: Control) -> void:
	_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	_pause_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause_panel.visible = false
	root.add_child(_pause_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_pause_panel.add_child(box)
	var title := Label.new()
	title.text = tr("Pause")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", GOLD)
	box.add_child(title)
	for entry: Array in [["Weiter", pause_pressed], ["Neu starten", restart_pressed], ["Zum Menü", menu_pressed]]:
		var button := Button.new()
		button.text = tr(entry[0])
		button.custom_minimum_size = Vector2(240, 48)
		button.pressed.connect((entry[1] as Signal).emit)
		box.add_child(button)


func show_pause(on: bool) -> void:
	_pause_panel.visible = on
	_gear_panel.visible = false
	(_pause_button.get_meta("glyph") as Glyph).set_kind("play" if on else "pause")


## Tasten am Rechner: 1-9 und 0 bauen, Z X C Fähigkeiten (nach Lage), U ausbauen, Entf abreißen, T Zielwahl,
## F Tempo, Leertaste nächste Welle, P Pause. Kamera und Esc erledigt Main.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var number := BUILD_KEYS.find(key.keycode)
	if number >= 0 and key.shift_pressed:
		number += BUILD_KEYS.size()
	if number >= 0 and number < Defs.BUILD_ORDER.size():
		var button: Button = _build_buttons[Defs.BUILD_ORDER[number]]
		if not button.disabled or button.button_pressed:
			button.button_pressed = not button.button_pressed
		return
	if key.keycode == KEY_ESCAPE and get_tree().paused and _pause_panel.visible:
		pause_pressed.emit()
		get_viewport().set_input_as_handled()
		return
	match key.keycode:
		KEY_P: pause_pressed.emit()
		KEY_SPACE: next_wave_pressed.emit()
		KEY_U: upgrade_pressed.emit()
		KEY_DELETE, KEY_BACKSPACE: sell_pressed.emit()
		KEY_T: target_pressed.emit()
		KEY_F: speed_pressed.emit()
		_:
			var ability := ABILITY_KEYS.find(key.physical_keycode)
			if ability < 0 or ability >= Defs.ABILITY_ORDER.size():
				return
			ability_pressed.emit(Defs.ABILITY_ORDER[ability])
	get_viewport().set_input_as_handled()


func show_end(won: bool, wave: int, stats := "") -> void:
	_end_panel.visible = true
	_gear_panel.visible = false
	_end_title.text = tr("Die Burg hält!") if won else tr("Die Burg ist gefallen")
	_end_text.text = tr("Alle %d Wellen abgewehrt.") % Defs.WAVES if won else tr("Bis Welle %d durchgehalten.") % wave
	if stats != "":
		_end_text.text += "\n\n" + stats
	_endless_button.visible = won


func hide_end() -> void:
	_end_panel.visible = false


func update_stats(gold: int, lives: int, wave: int, countdown: float, speed: float, endless := false, remaining := 0) -> void:
	_gold_label.text = str(gold)
	_lives_label.text = str(lives)
	_wave_label.text = tr("%d (endlos)") % wave if endless else "%d / %d" % [wave, Defs.WAVES]
	_timer_glyph.set_kind("hourglass" if countdown > 0.0 else "skull")
	_timer_label.text = "%d s" % ceili(countdown) if countdown > 0.0 else tr("noch %d") % remaining
	_next_button.disabled = countdown <= 0.0
	_set_button_text(_next_button, tr("Welle  +%d") % (int(countdown) / 2) if countdown > 0.0 else tr("Welle läuft"))
	_set_button_text(_speed_button, "%dx" % int(speed))
	_preview.visible = countdown > 0.0
	if _preview.visible and _preview_wave != wave + 1:
		_preview_wave = wave + 1
		_preview.text = tr("Als Nächstes, Welle %d: %s") % [_preview_wave, Defs.wave_preview(_preview_wave)]
	for id: StringName in _build_buttons:
		(_build_buttons[id] as Button).disabled = Defs.TOWERS[id]["cost"] > gold and selected_build != id
	var top := _top_bar.get_rect().end.y
	_toast.offset_top = top + 8  # die Leiste wächst mit der Wellenvorschau
	_gear_panel.offset_top = top + 6
	_bars.queue_redraw()


func toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


## Liegt die Bildschirmstelle auf einem Bedienelement? Dann ist ein Tipp nicht für das Spielfeld.
func blocks(point: Vector2) -> bool:
	for control: Control in [_card, _end_panel, _pause_panel, _gear_panel]:
		if control.visible and control.get_global_rect().has_point(point):
			return true
	for node in get_children():
		if node is Control:
			for panel in (node as Control).get_children():
				if panel is PanelContainer and panel.visible and (panel as Control).get_global_rect().has_point(point):
					return true
	return false


func _draw_bars() -> void:
	if main == null:
		return
	var camera: Camera3D = main.rig.camera
	for enemy: Enemy in main.enemies:
		if not enemy.alive or enemy.hp >= enemy.max_hp:
			continue
		var top := enemy.global_position + Vector3(0, 1.1 if enemy.is_boss else 0.85, 0)
		if camera.is_position_behind(top):
			continue
		var p := camera.unproject_position(top)
		var w := 46.0 if enemy.is_boss else 30.0
		var rect := Rect2(p - Vector2(w / 2, 0), Vector2(w, 5))
		_bars.draw_rect(rect.grow(1), INK)
		_bars.draw_rect(Rect2(rect.position, Vector2(w * enemy.hp / enemy.max_hp, 5)), BLOOD if enemy.is_boss else Color("#6ccf5a"))
