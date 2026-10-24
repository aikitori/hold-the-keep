class_name Main
extends Node3D
## Hauptszene: baut die Karte aus Kenney-Kacheln, steuert Wellen, Gold, Leben und die Eingabe.
## Tippen oder Klicken baut (mit Gerät: erst Vorschau, zweiter Tipp baut), Ziehen verschiebt die Karte,
## Mausrad oder zwei Finger zoomen.

const DRAG_THRESHOLD := 12.0
## Karte für das nächste Spiel (setzt das Menü).
static var map_id: StringName = &"vier_felder"

var map: MapData
var board: Board
var rig := CameraRig.new()
var hud := Hud.new()
var enemies: Array[Enemy] = []
var gold := 0
var lives := 0
## Faktor der Schwierigkeit auf die Lebenspunkte der Gegner.
var hp_factor := 1.0
var wave := 0
var countdown := Defs.FIRST_WAVE_DELAY
var game_over := false
var kills := 0
## Nach dem Sieg weiterspielen: die Wellen gehen ohne Ende weiter.
var endless := false
## Restliche Abklingzeit je Fähigkeit, 0 = bereit.
var ability_wait: Dictionary = {}
## Kriegshorn: so lange schießen alle Türme doppelt so schnell.
var horn_time := 0.0
var _aiming: StringName = &""  # Fähigkeit, die noch ein Ziel auf der Karte braucht
var _queue: Array[StringName] = []
var _spawn_timer := 0.0
var _spawned := 0  # bei mehreren Friedhöfen kommen die Gegner abwechselnd
var _speed := 1.0
var _selected: Tower = null
var _ghost: Node3D
var _ghost_id: StringName = &""
var _ghost_cell := Vector2i(-99, -99)
var _ring := MeshInstance3D.new()
var _path_view := PathView.new()
var _down_pos := Vector2.ZERO
var _dragging := false
var _pressed := false
var _touches: Dictionary = {}
var _pinch_distance := 0.0


func _ready() -> void:
	Engine.time_scale = 1.0
	var level: Dictionary = Defs.DIFFICULTIES[Settings.difficulty]
	gold = level["gold"]
	lives = level["lives"]
	hp_factor = level["hp"]
	map = MapData.load_map(map_id)
	board = Board.new(map)
	board.changed.connect(_on_board_changed)
	_build_lighting()
	_build_terrain()
	_build_landmarks()
	rig.bounds = Rect2(0, 0, map.size.x - 1, map.size.y - 1)
	add_child(rig)
	rig.position = Board.world_of(map.spawn).lerp(Board.world_of(map.size / 2), 0.4)
	add_child(_path_view)
	_path_view.show_paths(board.full_paths())
	_ring.mesh = _ring_mesh()
	_ring.visible = false
	add_child(_ring)
	hud.main = self
	add_child(hud)
	hud.build_selected.connect(_on_build_selected)
	hud.next_wave_pressed.connect(call_next_wave)
	hud.speed_pressed.connect(_cycle_speed)
	hud.upgrade_pressed.connect(upgrade_selected)
	hud.sell_pressed.connect(sell_selected)
	hud.deselect_pressed.connect(func() -> void: select_tower(null))
	hud.spec_pressed.connect(specialize_selected)
	hud.target_pressed.connect(func() -> void:
		if _selected != null:
			_selected.cycle_target())
	hud.restart_pressed.connect(func() -> void:
		_leave()
		get_tree().reload_current_scene())
	hud.menu_pressed.connect(func() -> void:
		_leave()
		get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	hud.endless_pressed.connect(continue_endless)
	hud.ability_pressed.connect(use_ability)
	for id: StringName in Defs.ABILITY_ORDER:
		ability_wait[id] = 0.0
	hud.pause_pressed.connect(func() -> void: set_paused(not get_tree().paused))
	hud.toast("Baue Türme und lege ein Labyrinth: die Toten kommen vom Friedhof!")


# --- Welt -------------------------------------------------------------------------

func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -25, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = not Settings.low_graphics
	# Schatten müssen das ganze Bild abdecken (Kameraabstand plus Bildtiefe bei weitestem Zoom).
	sun.directional_shadow_max_distance = CameraRig.DISTANCE + 60.0
	sun.directional_shadow_blend_splits = true
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#1d2a24")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#c9c2b4")
	env.environment.ambient_light_energy = 0.48
	add_child(env)


func _hash(at: Vector2i, salt := 0) -> int:
	return absi(hash(Vector3i(at.x, at.y, salt)))


## Boden und Rand. Gleiche Kacheln laufen über MultiMesh, damit auch große Karten flüssig bleiben.
func _build_terrain() -> void:
	var groups: Dictionary = {}  # Modell -> Array[Transform3D]
	var near_keep := func(at: Vector2i) -> bool: return (at - map.keep).length() <= 1.5
	var near_spawn := func(at: Vector2i) -> bool: return map.spawns.any(func(s: Vector2i) -> bool: return (at - s).length() <= 1.5)
	for y in map.size.y:
		for x in map.size.x:
			var at := Vector2i(x, y)
			var base := Transform3D(Basis.IDENTITY, Board.world_of(at))
			var kind := map.cell(at)
			var road := kind in [MapData.Cell.ROAD, MapData.Cell.SPAWN, MapData.Cell.KEEP, MapData.Cell.CHECKPOINT]
			if kind == MapData.Cell.HIGH:
				# Hochfläche: etwas höhere Kachel, Kante sieht man an den Nachbarn
				_add(groups, "td/tile", Transform3D(Basis.IDENTITY.scaled(Vector3(1, Tower.HIGH / 0.2, 1)), base.origin))
			elif kind == MapData.Cell.WATER:
				_add(groups, "td/tile#water", base.translated(Vector3(0, -0.08, 0)))
			elif map.glyph(at) == "b":
				_add(groups, "td/tile-dirt#bridge", base.translated(Vector3(0, 0.03, 0)))
			else:
				_add(groups, "td/tile-dirt" if road else "td/tile", base)
			if kind != MapData.Cell.BLOCKED or near_keep.call(at) or near_spawn.call(at):
				continue
			var top := base.translated(Vector3(0, 0.2, 0))
			var turn := Basis(Vector3.UP, (_hash(at, 1) % 4) * PI / 2)
			match map.glyph(at):
				"r":
					_add(groups, "castle/rocks-large", Transform3D(turn.scaled(Vector3.ONE * 0.8), top.origin))
				"g":
					_add(groups, ["graveyard/gravestone-cross", "graveyard/gravestone-round", "graveyard/gravestone-broken"][_hash(at) % 3],
							Transform3D(turn, top.origin))
				_:
					# Dichter Wald am Rand, ab und zu ein Fels
					var pick := _hash(at, 2) % 10
					if pick < 4:
						_add(groups, "castle/tree-small", Transform3D(turn.scaled(Vector3.ONE * (0.8 + (_hash(at, 3) % 5) * 0.08)), top.origin))
					elif pick < 7:
						_add(groups, "graveyard/pine", Transform3D(turn.scaled(Vector3.ONE * 1.3), top.origin))
					elif pick < 9:
						_add(groups, "castle/tree-large", Transform3D(turn.scaled(Vector3.ONE * 0.7), top.origin))
					else:
						_add(groups, "castle/rocks-small", Transform3D(turn, top.origin))
	for key: String in groups:
		var info := Models.mesh(key.get_slice("#", 0))  # "#..." unterscheidet Gruppen mit eigener Farbe
		var list: Array = groups[key]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = info[0]
		multi.instance_count = list.size()
		for i in list.size():
			multi.set_instance_transform(i, (list[i] as Transform3D) * (info[1] as Transform3D))
		var node := MultiMeshInstance3D.new()
		node.multimesh = multi
		if key.begins_with("td/tile"):
			# Flacher Boden wirft keinen Schatten: sonst beschattet er sich selbst (Streifen und Dreiecke).
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tint: Variant = {"td/tile": Color(0.9, 0.74, 0.52), "td/tile#water": Color(0.35, 0.55, 1.0),
				"td/tile-dirt#bridge": Color(0.5, 0.33, 0.2)}.get(key)
		if tint != null:
			# Kenney-Gras ist sehr hell mintgrün, etwas satter und dunkler wirkt es mehr wie Wiese. Wasser und
			# Brücken sind umgefärbte Kacheln.
			var material: StandardMaterial3D = (info[0] as Mesh).surface_get_material(0).duplicate()
			material.albedo_color = tint
			node.material_override = material
		add_child(node)


func _add(groups: Dictionary, key: String, t: Transform3D) -> void:
	if not groups.has(key):
		groups[key] = []
	groups[key].append(t)


## Burg am Ziel, Friedhof mit Gruft am Start.
func _build_landmarks() -> void:
	var keep := Node3D.new()
	keep.position = Board.world_of(map.keep, 0.2)
	add_child(keep)
	var y := 0.0
	for key in ["castle/tower-square-base", "castle/tower-square-mid-windows", "castle/tower-square-roof"]:
		var part := Models.make(key)
		part.position.y = y
		keep.add_child(part)
		y += Models.height(part)
	for offset in [Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(0, -1)]:
		var at: Vector2i = map.keep + offset
		if map.cell(at) != MapData.Cell.BLOCKED:
			continue
		var side := Node3D.new()
		side.position = Board.world_of(at, 0.2)
		add_child(side)
		var h := 0.0
		for key in ["castle/tower-hexagon-base", "castle/tower-hexagon-roof"]:
			var part := Models.make(key)
			part.position.y = h
			part.scale = Vector3.ONE * 0.8
			side.add_child(part)
			h += Models.height(part) * 0.8
	var banner := Models.make("castle/flag-banner-long")
	banner.position = Board.world_of(map.keep + Vector2i(1, -1), 0.2)
	add_child(banner)
	for i in map.waypoints.size() - 1:
		var marker := Models.make("castle/flag")
		marker.position = Board.world_of(map.waypoints[i], 0.2)
		add_child(marker)
		var number := Label3D.new()
		number.text = str(i + 1)
		number.font = Hud.FONT
		number.font_size = 96
		number.outline_size = 18
		number.modulate = Hud.GOLD
		number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number.pixel_size = 0.009
		number.no_depth_test = true
		number.position = Board.world_of(map.waypoints[i], 1.4)
		add_child(number)
	for spawn in map.spawns:
		var crypt := Models.make("graveyard/crypt")
		crypt.position = Board.world_of(spawn + Vector2i(-1, 0), 0.2)
		crypt.rotation.y = PI / 2
		add_child(crypt)
		for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(0, 2), Vector2i(-1, 2)]:
			var at: Vector2i = spawn + offset
			if map.cell(at) == MapData.Cell.BLOCKED:
				var stone := Models.make(["graveyard/gravestone-cross", "graveyard/gravestone-round", "graveyard/lantern-candle"][_hash(at) % 3])
				stone.position = Board.world_of(at, 0.2)
				add_child(stone)
		_beacon(spawn, "Start", Color("#e0533d"), 2.2)
	_beacon(map.keep, "Ziel", Hud.GOLD, y + 0.6)


## Deutliche Marke: Schild über dem Feld (immer sichtbar, auch hinter Türmen) und ein pulsierender Ring.
func _beacon(at: Vector2i, text: String, color: Color, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = Hud.FONT
	label.font_size = 120
	label.outline_size = 26
	label.outline_modulate = Hud.INK
	label.modulate = color
	label.pixel_size = 0.011
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 2
	label.outline_render_priority = 1
	label.position = Board.world_of(at, height)
	add_child(label)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.0
	torus.rings = 48
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, 0.8)
	torus.material = material
	ring.mesh = torus
	ring.scale = Vector3(1, 0.05, 1)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Board.world_of(at, 0.23)
	add_child(ring)
	var pulse := ring.create_tween().set_loops()
	pulse.tween_property(ring, "scale", Vector3(1.5, 0.05, 1.5), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(material, "albedo_color:a", 0.15, 0.9)
	pulse.tween_property(ring, "scale", Vector3(1, 0.05, 1), 0.0)
	pulse.parallel().tween_property(material, "albedo_color:a", 0.8, 0.0)
	var bob := label.create_tween().set_loops()
	bob.tween_property(label, "position:y", height + 0.25, 0.8).set_trans(Tween.TRANS_SINE)
	bob.tween_property(label, "position:y", height, 0.8).set_trans(Tween.TRANS_SINE)


func _ring_mesh() -> Mesh:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.96
	torus.outer_radius = 1.0
	torus.rings = 64
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.9, 0.5, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = material
	return torus


func _show_ring(center: Vector3, radius: float) -> void:
	_ring.visible = radius > 0.0
	_ring.position = Vector3(center.x, center.y + 0.27, center.z)
	_ring.scale = Vector3(radius, 0.05, radius)


# --- Ablauf -----------------------------------------------------------------------

func _process(delta: float) -> void:
	if game_over:
		return
	horn_time = maxf(0.0, horn_time - delta)
	for id: StringName in ability_wait:
		ability_wait[id] = maxf(0.0, ability_wait[id] - delta)
	hud.update_abilities(ability_wait, _aiming)
	if not _queue.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn(_queue.pop_front())
			_spawn_timer = Defs.SPAWN_GAP
	elif countdown > 0.0:
		countdown -= delta
		if countdown <= 0.0:
			_start_wave()
	elif enemies.is_empty():
		# Die Pause beginnt erst, wenn der letzte Gegner der Welle besiegt ist oder die Burg erreicht hat.
		Settings.record(map_id, wave, false)
		if wave >= Defs.WAVES and not endless:
			_finish(true)
		else:
			countdown = Defs.WAVE_BREAK
			_pay_interest()
	hud.update_stats(gold, lives, wave, countdown if _queue.is_empty() else 0.0, _speed, endless)
	if _selected != null:
		hud.show_tower(_selected, gold)


func _start_wave() -> void:
	wave += 1
	countdown = 0.0
	_queue = Defs.wave(wave)
	_spawn_timer = 0.0
	var boss: bool = Defs.ENEMIES[_queue[0]].get("boss", false)
	var label: String = ("Boss! %s mit " % Defs.ENEMIES[_queue[0]]["name"] if boss else "") + Defs.wave_names(_queue)
	if Defs.is_air_wave(wave):
		label = "Luftangriff! Geister fliegen über das Labyrinth"
	hud.toast("Welle %d: %s" % [wave, label])
	Sfx.play(&"wave")


func _pay_interest() -> void:
	var interest := mini(int(gold * Defs.INTEREST), Defs.INTEREST_MAX)
	if interest <= 0:
		return
	gold += interest
	hud.toast("Welle %d besiegt! Zinsen: +%d Gold" % [wave, interest])
	Sfx.play(&"coins")


## Nach dem Sieg: weiter im Endlosmodus.
func continue_endless() -> void:
	endless = true
	game_over = false
	countdown = Defs.WAVE_BREAK
	hud.hide_end()
	hud.toast("Endlosmodus: wie lange hält die Burg?")


## Fähigkeit auslösen. Pechregen wartet auf einen Tipp auf die Karte (nochmal drücken bricht ab).
func use_ability(id: StringName) -> void:
	if game_over or ability_wait[id] > 0.0:
		return
	if id == &"pitch":
		_aiming = &"" if _aiming == id else id
		if _aiming != &"":
			hud.clear_build()
			_on_build_selected(&"")
			hud.toast("Tippe auf die Stelle für den Pechregen")
		else:
			_ring.visible = false
		return
	var def: Dictionary = Defs.ABILITIES[id]
	ability_wait[id] = def["cooldown"]
	match id:
		&"bell":
			for enemy in enemies:
				if enemy.alive:
					enemy.apply_slow(def["slow"], def["time"])
			Sfx.play(&"wave")
		&"horn":
			horn_time = def["time"]
			Sfx.play(&"upgrade")
	hud.toast("%s!" % def["name"])


func cast_pitch(at: Vector3) -> void:
	var def: Dictionary = Defs.ABILITIES[&"pitch"]
	_aiming = &""
	_ring.visible = false
	ability_wait[&"pitch"] = def["cooldown"]
	var damage: float = def["damage"] * Defs.health_factor(maxi(wave, 1)) * hp_factor
	for enemy in enemies.duplicate():
		if enemy.alive and not enemy.air and Vector2(enemy.position.x - at.x, enemy.position.z - at.z).length() <= def["radius"]:
			enemy.take_damage(damage, true)
			if enemy.alive:
				enemy.apply_burn(damage * 0.2, 3.0)
	for i in 6:
		var spot: Vector3 = at + Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)) * def["radius"] * 0.7
		puff(spot, Color(0.15, 0.1, 0.05, 0.8))
	puff(at, Color(1.0, 0.45, 0.1, 0.7))
	Sfx.play_at(&"crash", at)


## Nächste Welle sofort: Bonus-Gold für die gesparte Zeit.
func call_next_wave() -> void:
	if game_over or not _queue.is_empty() or countdown <= 0.0:
		return
	gold += int(countdown) / 2
	if int(countdown) >= 2:
		Sfx.play(&"coins")
	_start_wave()


func _spawn(kind: StringName) -> void:
	var enemy := Enemy.new()
	add_child(enemy)
	enemy.setup(kind, wave, self, board, _spawned % map.spawns.size())
	_spawned += 1
	enemies.append(enemy)
	if enemy.is_boss:
		Sfx.play(&"boss")


## Neuer Gegner an der Stelle eines anderen (Seuchenzombie zerfällt, Nekromant ruft). Gerufene Helfer geben
## kein Gold, sonst ließe sich am Nekromanten unbegrenzt verdienen.
func spawn_from(parent: Enemy, kind: StringName, with_gold: bool) -> void:
	var enemy := Enemy.new()
	add_child(enemy)
	enemy.setup(kind, wave, self, board)
	enemy.start_at(parent)
	if not with_gold:
		enemy.gold = 0
	enemies.append(enemy)


## Zusätzliche Rüstung durch Schildträger in der Nähe (der stärkste zählt, nicht für ihn selbst).
func aura_armor(enemy: Enemy) -> float:
	var best := 0.0
	for other in enemies:
		var aura: float = Defs.ENEMIES[other.kind].get("aura", 0.0)
		if aura > best and other != enemy and other.alive \
				and other.position.distance_to(enemy.position) <= Defs.AURA_RADIUS:
			best = aura
	return best


func enemy_killed(enemy: Enemy) -> void:
	enemies.erase(enemy)
	gold += enemy.gold
	kills += 1
	if enemy.is_boss:
		hud.toast("%s besiegt! +%d Gold" % [Defs.ENEMIES[enemy.kind]["name"], enemy.gold])


func enemy_reached_keep(enemy: Enemy) -> void:
	enemies.erase(enemy)
	lives -= 5 if enemy.is_boss else 1
	Sfx.play(&"keep_hit")
	if lives <= 0:
		lives = 0
		_finish(false)


func _finish(won: bool) -> void:
	game_over = true
	Engine.time_scale = 1.0
	if won:
		Settings.record(map_id, wave, true)
	hud.show_end(won, wave)
	Sfx.play(&"victory" if won else &"defeat")


func set_paused(on: bool) -> void:
	if on and game_over:
		return
	get_tree().paused = on
	hud.show_pause(on)


## Handy: App in den Hintergrund (Anruf, anderer Tab) hält das Spiel an.
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and is_inside_tree():
		set_paused(true)


func _leave() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


func _cycle_speed() -> void:
	_speed = 1.0 if _speed >= 3.0 else _speed + 1.0
	Engine.time_scale = _speed


func _on_board_changed() -> void:
	_path_view.show_paths(board.full_paths())
	for enemy in enemies:
		if enemy.alive:
			enemy.repath()


## Kleine Staubwolke beim Einschlag.
func puff(at: Vector3, color := Color(0.85, 0.75, 0.6, 0.6)) -> void:
	var dust := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = material
	dust.mesh = sphere
	dust.position = Vector3(at.x, 0.3, at.z)
	dust.scale = Vector3.ONE * 0.3
	add_child(dust)
	var tween := dust.create_tween()
	tween.set_parallel()
	tween.tween_property(dust, "scale", Vector3(2.2, 0.8, 2.2), 0.35)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.35)
	tween.chain().tween_callback(dust.queue_free)


# --- Bauen ------------------------------------------------------------------------

## [Zelle, Ziel] aller Bodengegner: auf ihnen darf nicht gebaut und sie dürfen nicht eingesperrt werden.
## Gräber zählen nicht, sie gehen unter Türmen durch.
func walkers() -> Array:
	var out: Array = []
	for enemy in enemies:
		if enemy.alive and not enemy.air and not enemy.burrow:
			out.append([enemy.current_cell(), enemy.goal()])
	return out


const BUILD_MESSAGES := {
	Board.BuildCheck.NOT_GRASS: "Nur auf Gras kann gebaut werden",
	Board.BuildCheck.OCCUPIED: "Hier steht schon etwas",
	Board.BuildCheck.ENEMY_THERE: "Ein Gegner steht im Weg",
	Board.BuildCheck.BLOCKS_PATH: "Der Weg zur Burg darf nicht ganz versperrt werden",
}


func try_build(id: StringName, at: Vector2i) -> Tower:
	var cost: int = Defs.TOWERS[id]["cost"]
	if gold < cost:
		_refuse("Zu wenig Gold")
		return null
	var check := board.check_build(at, walkers())
	if check != Board.BuildCheck.OK:
		_refuse(BUILD_MESSAGES[check])
		return null
	gold -= cost
	var tower := Tower.new()
	add_child(tower)
	tower.setup(id, at, self, Tower.HIGH if map.cell(at) == MapData.Cell.HIGH else Tower.GROUND)
	board.place(at, tower)
	Sfx.play(&"build")
	return tower


func _refuse(message: String) -> void:
	hud.toast(message)
	Sfx.play(&"error")


func select_tower(tower: Tower) -> void:
	_selected = tower
	hud.show_tower(tower, gold)
	if tower != null:
		_show_ring(tower.position, tower.reach())
	elif _ghost == null:
		_ring.visible = false


func upgrade_selected() -> void:
	if _selected == null or not _selected.can_upgrade():
		return
	var cost := Defs.upgrade_cost(_selected.id, _selected.level)
	if gold < cost:
		_refuse("Zu wenig Gold")
		return
	gold -= cost
	_selected.upgrade()
	Sfx.play(&"upgrade")
	_show_ring(_selected.position, _selected.reach())


func specialize_selected(spec_id: StringName) -> void:
	if _selected == null or _selected.spec_options().is_empty():
		return
	var cost: int = Defs.spec(_selected.id, spec_id)["cost"]
	if gold < cost:
		_refuse("Zu wenig Gold")
		return
	gold -= cost
	_selected.specialize(spec_id)
	Sfx.play(&"spec")
	_show_ring(_selected.position, _selected.reach())
	hud.toast("%s: %s" % [Defs.TOWERS[_selected.id]["name"], Defs.spec(_selected.id, spec_id)["name"]])


func sell_selected() -> void:
	if _selected == null:
		return
	gold += roundi(_selected.invested * Defs.SELL_SHARE)
	Sfx.play(&"sell")
	board.remove(_selected.cell)
	_selected.queue_free()
	select_tower(null)


func _on_build_selected(id: StringName) -> void:
	select_tower(null)
	if id != &"":
		_aiming = &""
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	_ghost_id = id
	_ghost_cell = Vector2i(-99, -99)
	_ring.visible = false
	_path_view.show_paths(board.full_paths())
	if id == &"":
		return
	_ghost = Tower.build_model(id, 1)
	Models.tint(_ghost, Color(0.4, 1.0, 0.5, 0.55))
	_ghost.visible = false
	add_child(_ghost)


func _move_ghost(at: Vector2i) -> void:
	if _ghost == null:
		return
	_ghost_cell = at
	_ghost.visible = map.cell(at) != MapData.Cell.BLOCKED
	_ghost.position = Board.world_of(at, Tower.HIGH - Tower.GROUND if map.cell(at) == MapData.Cell.HIGH else 0.0)
	var ok: bool = board.check_build(at, walkers()) == Board.BuildCheck.OK and gold >= Defs.TOWERS[_ghost_id]["cost"]
	Models.tint(_ghost, Color(0.4, 1.0, 0.5, 0.55) if ok else Color(1.0, 0.3, 0.25, 0.55))
	if ok:
		_path_view.show_paths(board.full_paths_with(at), true)
	else:
		_path_view.show_paths(board.full_paths())
	_show_ring(_ghost.position, Defs.tower_range(_ghost_id, 1))
	_ring.visible = _ghost.visible and Defs.tower_range(_ghost_id, 1) > 0.0


func _cancel() -> void:
	if _aiming != &"":
		_aiming = &""
		_ring.visible = false
	elif _ghost_id != &"":
		hud.clear_build()
		_on_build_selected(&"")
	else:
		select_tower(null)


# --- Eingabe ----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			rig.zoom(0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			rig.zoom(1.1)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_cancel()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_press(mb.position)
			else:
				_release(mb.position, false)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		var mm := event as InputEventMouseMotion
		if _pressed:
			_drag(mm.position)
		elif _aiming != &"":
			_show_ring(rig.ground_point(mm.position), Defs.ABILITIES[_aiming]["radius"])
		elif _ghost != null:
			_move_ghost(Board.cell_of(rig.ground_point(mm.position)))
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touches[touch.index] = touch.position
			if _touches.size() == 1:
				_press(touch.position)
			else:
				_dragging = true  # zwei Finger: nie als Tipp werten
				_pinch_distance = _finger_distance()
				rig.grab(_finger_center())
		else:
			_touches.erase(touch.index)
			if _touches.is_empty():
				_release(touch.position, true)
			else:
				# Der übrige Finger greift neu, sonst springt die Karte.
				_pinch_distance = _finger_distance()
				rig.grab(_finger_center())
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if not _touches.has(drag.index):
			return  # Finger, der auf der Oberfläche aufgesetzt hat
		_touches[drag.index] = drag.position
		if _touches.size() >= 2:
			var distance := _finger_distance()
			if _pinch_distance > 0.0 and distance > 0.0:
				rig.zoom(_pinch_distance / distance)
			_pinch_distance = distance
			rig.drag_to(_finger_center())
		else:
			_drag(drag.position)
	elif event is InputEventMagnifyGesture:
		rig.zoom(1.0 / (event as InputEventMagnifyGesture).factor)
	elif event is InputEventPanGesture:
		rig.pan(-(event as InputEventPanGesture).delta * 8.0)


func _finger_distance() -> float:
	var points: Array = _touches.values()
	return (points[0] as Vector2).distance_to(points[1]) if points.size() >= 2 else 0.0


func _finger_center() -> Vector2:
	var points: Array = _touches.values()
	return ((points[0] as Vector2) + (points[1] as Vector2)) / 2.0 if points.size() >= 2 else points[0]


func _press(at: Vector2) -> void:
	_pressed = true
	_dragging = false
	_down_pos = at
	rig.grab(at)


func _drag(at: Vector2) -> void:
	if not _dragging and at.distance_to(_down_pos) > DRAG_THRESHOLD:
		_dragging = true
	if _dragging:
		rig.drag_to(at)


func _release(at: Vector2, touch: bool) -> void:
	_pressed = false
	if _dragging or game_over or hud.blocks(at):
		_dragging = false
		return
	tap(at, touch)


## Ein Tipp auf das Spielfeld: bauen (mit Gerät erst Vorschau), Turm wählen oder Auswahl aufheben.
func tap(at: Vector2, touch := false) -> void:
	var cell := Board.cell_of(rig.ground_point(at))
	if _aiming != &"":
		cast_pitch(rig.ground_point(at))
		return
	if _ghost_id != &"":
		if touch and cell != _ghost_cell:
			_move_ghost(cell)
			return
		if try_build(_ghost_id, cell) != null:
			_move_ghost(cell)
		return
	if board.towers.has(cell):
		select_tower(board.towers[cell])
	else:
		select_tower(null)
