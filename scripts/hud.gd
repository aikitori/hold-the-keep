class_name Hud
extends CanvasLayer
## Oberfläche im Stil einer Burg: Holz und Pergament. Oben Gold, Leben, Welle; unten die Bauleiste;
## rechts die Turm-Karte zum Ausbauen und Verkaufen. Lebensbalken der Gegner zeichnet `_bars`.

signal build_selected(id: StringName)
signal next_wave_pressed
signal speed_pressed
signal upgrade_pressed
signal sell_pressed
signal deselect_pressed
signal restart_pressed

const FONT := preload("res://assets/fonts/MedievalSharp.ttf")
const WOOD := Color("#3b2a1e")
const WOOD_LIGHT := Color("#5a4030")
const PARCHMENT := Color("#efe2c0")
const INK := Color("#2b1d12")
const GOLD := Color("#f2c14e")
const BLOOD := Color("#c0392b")

var main: Node
var selected_build: StringName = &""
var _gold_label := Label.new()
var _lives_label := Label.new()
var _wave_label := Label.new()
var _timer_label := Label.new()
var _next_button := Button.new()
var _speed_button := Button.new()
var _build_buttons: Dictionary = {}
var _card := PanelContainer.new()
var _card_title := Label.new()
var _card_text := Label.new()
var _upgrade_button := Button.new()
var _sell_button := Button.new()
var _toast := Label.new()
var _toast_tween: Tween
var _end_panel := PanelContainer.new()
var _end_title := Label.new()
var _end_text := Label.new()
var _bars := Control.new()
var _icons: Dictionary = {}


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	add_child(root)
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	root.add_child(_bars)
	_build_top(root)
	_build_bottom(root)
	_build_card(root)
	_build_end(root)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y = 70
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_color", PARCHMENT)
	_toast.add_theme_color_override("font_outline_color", INK)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 20
	var panel := StyleBoxFlat.new()
	panel.bg_color = WOOD
	panel.border_color = Color("#1e140d")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(10)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 6
	theme.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = {"normal": PARCHMENT, "hover": Color("#fff3d6"), "pressed": GOLD,
				"disabled": Color("#8d7f66"), "focus": PARCHMENT}[state]
		box.border_color = Color("#7a5a2e") if state != "pressed" else Color("#8a5a10")
		box.set_border_width_all(2)
		box.set_corner_radius_all(4)
		box.set_content_margin_all(6)
		if state == "focus":
			box.draw_center = false
			box.border_color = GOLD
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("#3f362b"))
	theme.set_color("font_color", "Label", PARCHMENT)
	return theme


func _build_top(root: Control) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 8
	bar.offset_right = -8
	bar.offset_top = 8
	root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)
	_gold_label.add_theme_color_override("font_color", GOLD)
	_lives_label.add_theme_color_override("font_color", Color("#f08a7a"))
	for label in [_gold_label, _lives_label, _wave_label, _timer_label]:
		label.add_theme_font_size_override("font_size", 22)
		row.add_child(label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var title := Label.new()
	title.text = "Hold the Keep"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GOLD)
	row.add_child(title)
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer2)
	_speed_button.text = "Tempo 1x"
	_speed_button.pressed.connect(func() -> void: speed_pressed.emit())
	row.add_child(_speed_button)
	_next_button.text = "Nächste Welle"
	_next_button.pressed.connect(func() -> void: next_wave_pressed.emit())
	row.add_child(_next_button)


func _build_bottom(root: Control) -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -8
	root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	for id: StringName in Defs.BUILD_ORDER:
		var def: Dictionary = Defs.TOWERS[id]
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(118, 112)
		button.tooltip_text = def["info"]
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.add_theme_constant_override("separation", 0)
		button.add_child(box)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(110, 66)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = _icon(id)
		box.add_child(icon)
		var name_label := Label.new()
		name_label.text = "%s  %d" % [def["name"], def["cost"]]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 17)
		name_label.add_theme_color_override("font_color", INK)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(name_label)
		button.toggled.connect(func(on: bool) -> void: _on_build_toggled(id, on))
		row.add_child(button)
		_build_buttons[id] = button


## Kleines Bild des Turms, gerendert in einem eigenen Viewport mit derselben Schrägsicht wie das Spiel.
func _icon(id: StringName) -> Texture2D:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(220, 132)
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
	cam.look_at_from_position(center + Vector3(1, 1, 1).normalized() * 10.0, center, Vector3.UP)
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


func _on_build_toggled(id: StringName, on: bool) -> void:
	if on:
		for other: StringName in _build_buttons:
			if other != id:
				(_build_buttons[other] as Button).set_pressed_no_signal(false)
		selected_build = id
	elif selected_build == id:
		selected_build = &""
	build_selected.emit(selected_build)


func clear_build() -> void:
	for id: StringName in _build_buttons:
		(_build_buttons[id] as Button).set_pressed_no_signal(false)
	selected_build = &""


func _build_card(root: Control) -> void:
	_card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card.offset_right = -10
	_card.custom_minimum_size = Vector2(250, 0)
	_card.visible = false
	root.add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_card.add_child(box)
	_card_title.add_theme_font_size_override("font_size", 26)
	_card_title.add_theme_color_override("font_color", GOLD)
	box.add_child(_card_title)
	_card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_text.custom_minimum_size = Vector2(230, 0)
	box.add_child(_card_text)
	_upgrade_button.pressed.connect(func() -> void: upgrade_pressed.emit())
	box.add_child(_upgrade_button)
	_sell_button.pressed.connect(func() -> void: sell_pressed.emit())
	box.add_child(_sell_button)
	var close := Button.new()
	close.text = "Schließen"
	close.pressed.connect(func() -> void: deselect_pressed.emit())
	box.add_child(close)


func show_tower(tower: Tower, gold: int) -> void:
	if tower == null:
		_card.visible = false
		return
	var def: Dictionary = Defs.TOWERS[tower.id]
	_card.visible = true
	_card_title.text = "%s · Stufe %d" % [def["name"], tower.level] if def["damage"] > 0 else def["name"]
	var lines: Array[String] = [def["info"]]
	if def["damage"] > 0:
		lines.append("Schaden %d · Reichweite %.1f" % [roundi(tower.damage()), tower.reach()])
		lines.append("Schüsse pro Sekunde %.1f" % (1.0 / Defs.tower_cooldown(tower.id, tower.level)))
	_card_text.text = "\n".join(lines)
	var cost := Defs.upgrade_cost(tower.id, tower.level)
	_upgrade_button.visible = cost > 0
	_upgrade_button.text = "Ausbauen  %d Gold" % cost
	_upgrade_button.disabled = cost > gold
	_sell_button.text = "Abreißen  +%d Gold" % roundi(tower.invested * Defs.SELL_SHARE)


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
	var again := Button.new()
	again.text = "Neues Spiel"
	again.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(again)


func show_end(won: bool, wave: int) -> void:
	_end_panel.visible = true
	_end_title.text = "Die Burg hält!" if won else "Die Burg ist gefallen"
	_end_text.text = "Alle %d Wellen abgewehrt." % Defs.WAVES if won else "Bis Welle %d durchgehalten." % wave


func update_stats(gold: int, lives: int, wave: int, countdown: float, speed: float) -> void:
	_gold_label.text = "Gold %d" % gold
	_lives_label.text = "Leben %d" % lives
	_wave_label.text = "Welle %d / %d" % [wave, Defs.WAVES]
	_timer_label.text = "nächste in %d s" % ceili(countdown) if countdown > 0.0 else ""
	_next_button.disabled = countdown <= 0.0
	_next_button.text = "Nächste Welle  +%d" % (int(countdown) / 2) if countdown > 0.0 else "Welle läuft"
	_speed_button.text = "Tempo %dx" % int(speed)
	for id: StringName in _build_buttons:
		(_build_buttons[id] as Button).disabled = Defs.TOWERS[id]["cost"] > gold and selected_build != id
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
	for control: Control in [_card, _end_panel]:
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
