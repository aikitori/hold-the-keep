class_name Tower
extends Node3D
## Ein Turm auf einem Feld: Modell aus Burgteilen oder eine Figur, sucht sich die Gegner, die der Burg am
## nächsten sind. Drei Ausbaustufen, auf Stufe 3 eine von zwei Spezialisierungen.

const GROUND := 0.2  # Oberkante der Bodenkachel
const HIGH := 0.6    # Oberkante der Hochfläche

var id: StringName
var level := 1
var spec_id: StringName = &""
var cell: Vector2i
var invested := 0
var target_mode: StringName = &"first"
var kills := 0
## In derselben Bauzeit gebaut und noch nie geschossen: Abriss gibt alles zurück.
var refundable := true
var game: Node  # Main
var _cooldown := 0.0
var _model: Node3D
var _weapon: Node3D
var _muzzle_height := 1.0


func setup(tower_id: StringName, at: Vector2i, main: Node, base_height := GROUND) -> void:
	id = tower_id
	cell = at
	game = main
	invested = Defs.TOWERS[id]["cost"]
	position = Board.world_of(at, base_height - GROUND)
	_build_model()


func _build_model() -> void:
	if _model != null:
		_model.queue_free()
	_model = build_model(id, level, spec_id)
	add_child(_model)
	_weapon = _model.get_node_or_null("Weapon")
	_muzzle_height = _model.get_meta("muzzle", 1.0)


## Modell eines Turms (auch für die Bauvorschau und die Bilder der Bauleiste).
static func build_model(tower_id: StringName, tower_level: int, spec := &"") -> Node3D:
	var def: Dictionary = Defs.TOWERS[tower_id]
	var root := Node3D.new()
	var parts: Array = (def["parts"] as Array).duplicate()
	var extra: Array = def.get("level_parts", [])
	if not extra.is_empty() and parts.size() > 0:
		for i in tower_level - 1:
			parts.insert(1, extra[i % extra.size()])
	var y := GROUND
	for key: String in parts:
		var part := Models.make(key)
		part.position.y = y
		if key == "castle/wall":
			part.scale = Vector3(0.9, 0.7, 0.9)
		root.add_child(part)
		y += Models.height(part) * part.scale.y
	var weapon := Node3D.new()
	weapon.name = "Weapon"
	weapon.position.y = y
	root.add_child(weapon)
	var grow := 1.0 + 0.12 * (tower_level - 1) + (0.15 if spec != &"" else 0.0)
	if def.has("unit"):
		var unit := Figure.create(def["unit"])
		unit.scale = Vector3.ONE * 1.1 * grow
		weapon.add_child(unit)
		unit.play("idle")
		var side := 1.0
		var props: Array = def.get("props", [])
		if spec in [&"knight", &"pike"]:
			props = ["dungeon/weapon-sword", "dungeon/shield-round"] if spec == &"knight" else ["dungeon/weapon-spear", "dungeon/weapon-spear"]
		for key: String in props:
			var prop := Models.make(key)
			prop.position = Vector3(0.28 * side, 0.32, 0.12)
			prop.rotation.x = -0.35 if key.ends_with("spear") else 0.0
			unit.add_child(prop)
			side = -side
		y += 0.7
	if def.get("barrel", false):
		# Kanonenrohr: dunkles Eisen, zeigt nach vorn (+z) und leicht nach oben.
		var barrel := MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = 0.09 * grow
		tube.bottom_radius = 0.13 * grow
		tube.height = 0.62 * grow
		var iron := StandardMaterial3D.new()
		iron.albedo_color = Color(0.22, 0.22, 0.25)
		iron.metallic = 0.6
		iron.roughness = 0.45
		tube.material = iron
		barrel.mesh = tube
		barrel.rotation.x = PI / 2 - 0.3
		barrel.position = Vector3(0, 0.16, 0.12)
		weapon.add_child(barrel)
		var mount := MeshInstance3D.new()
		var block := BoxMesh.new()
		block.size = Vector3(0.36, 0.14, 0.4) * grow
		var wood := StandardMaterial3D.new()
		wood.albedo_color = Color(0.45, 0.3, 0.18)
		block.material = wood
		mount.mesh = block
		mount.position.y = 0.07
		weapon.add_child(mount)
		y += 0.3
	if def.has("top"):
		var top := Models.make(def["top"])
		top.scale = Vector3.ONE * grow
		weapon.add_child(top)
		y += Models.height(top) * grow
	if def.has("weapon"):
		var model := Models.make(def["weapon"])
		var s: float = def["scale"] * grow
		model.scale = Vector3(s, s, s)
		model.position.y = 0.2 * s  # Belagerungswaffen stehen 0,2 tiefer im Modell
		model.rotation.y = PI / 2  # Front der Kenney-Waffen zeigt nach -x
		weapon.add_child(model)
		y += 0.5
	if tower_level > 1 and def["damage"] > 0:
		var flag := Models.make("castle/flag-pennant")
		flag.position = Vector3(0.3, y - 0.1, 0.3)
		flag.scale = Vector3.ONE * (0.5 + 0.15 * tower_level)
		root.add_child(flag)
	if spec != &"":
		# Spezialisiert: Banner am Turm
		var banner := Models.make("castle/flag-banner-long")
		banner.position = Vector3(-0.35, GROUND, 0.35)
		banner.scale = Vector3.ONE * 0.7
		root.add_child(banner)
	root.set_meta("muzzle", y)
	return root


## Sichtbare Höhe über dem Boden (für die Auswahl per Tipp).
func height() -> float:
	return _muzzle_height


func title() -> String:
	var name: String = Defs.TOWERS[id]["name"]
	return Defs.spec(id, spec_id)["name"] if spec_id != &"" else name


## Mit Bonus durch Kriegsbanner in der Nähe.
func damage() -> float:
	return Defs.tower_damage(id, level, spec_id) * (1.0 + game.banner_bonus(self).x)


func reach() -> float:
	return Defs.tower_range(id, level, spec_id)


func cooldown() -> float:
	return Defs.tower_cooldown(id, level, spec_id) / (1.0 + game.banner_bonus(self).y)


func targets() -> String:
	return Defs.tower_targets(id, spec_id)


func stat(key: String, fallback: Variant) -> Variant:
	return Defs.spec(id, spec_id).get(key, Defs.TOWERS[id].get(key, fallback))


## Nächste Zielwahl; "Flieger zuerst" nur, wenn der Turm beides trifft.
func cycle_target() -> void:
	var modes := Defs.TARGET_MODES.filter(func(m: StringName) -> bool: return m != &"air" or targets() == "both")
	target_mode = modes[(modes.find(target_mode) + 1) % modes.size()]


## Gold beim Abriss: alles in derselben Bauzeit, sonst SELL_SHARE.
func sell_value() -> int:
	return invested if refundable else roundi(invested * Defs.SELL_SHARE)


func can_upgrade() -> bool:
	return Defs.upgrade_cost(id, level) > 0


## Spezialisierungen, die jetzt wählbar sind (nur auf Stufe 3 und nur einmal).
func spec_options() -> Array:
	if level < Defs.MAX_LEVEL or spec_id != &"":
		return []
	return Defs.SPECS.get(id, [])


func upgrade() -> void:
	if not can_upgrade():
		return
	invested += Defs.upgrade_cost(id, level)
	level += 1
	_build_model()


func specialize(new_spec: StringName) -> void:
	if spec_options().is_empty() or Defs.spec(id, new_spec).is_empty():
		return
	invested += Defs.spec(id, new_spec)["cost"]
	spec_id = new_spec
	_build_model()


func _process(delta: float) -> void:
	if Defs.TOWERS[id]["damage"] <= 0:
		return
	_cooldown -= delta * (2.0 if game.horn_time > 0.0 else 1.0)  # Kriegshorn
	var chosen := _pick_targets(int(stat("multishot", 1)))
	if chosen.is_empty():
		return
	if _weapon != null:
		var dir := chosen[0].global_position - global_position
		_weapon.rotation.y = atan2(dir.x, dir.z)
	if _cooldown > 0.0:
		return
	_cooldown = cooldown()
	refundable = false
	var def: Dictionary = Defs.TOWERS[id]
	var hit := {
		"damage": damage(), "splash": stat("splash", 0.0), "slow": stat("slow", 0.0),
		"slow_time": stat("slow_time", 1.6), "burn": stat("burn", 0.0), "chain": int(stat("chain", 0)),
		"poison": stat("poison", 0.0), "stacks": int(stat("stacks", 3)), "source": self,
	}
	Sfx.play_at(_shot_sound(def["projectile"], hit), global_position)
	if def["projectile"] == "melee":
		_lunge()
		var splash: float = hit["splash"]
		for enemy: Enemy in game.enemies.duplicate():
			if not enemy.alive:
				continue
			if enemy == chosen[0] or (splash > 0.0 and _ground_distance(enemy) <= splash and not enemy.air):
				enemy.take_damage(hit["damage"], false, self)
		return
	for target in chosen:
		var shot := Projectile.new()
		game.add_child(shot)
		shot.launch(def["projectile"], global_position + Vector3(0, _muzzle_height, 0), target, hit, def["speed"])


func _shot_sound(projectile: String, hit: Dictionary) -> StringName:
	match projectile:
		"melee": return &"stab"
		"boulder", "cannonball": return &"throw"
		"poison": return &"magic"
		"magic": return &"lightning" if hit["chain"] > 0 else &"magic"
	return StringName(projectile)  # arrow, bolt, fire


## Kurzer Ausfallschritt der Figur beim Nahkampf.
func _lunge() -> void:
	if _weapon == null:
		return
	var forward := Vector3(sin(_weapon.rotation.y), 0, cos(_weapon.rotation.y)) * 0.25
	var base := Vector3(0, _weapon.position.y, 0)
	var tween := create_tween()
	tween.tween_property(_weapon, "position", base + forward, 0.08)
	tween.tween_property(_weapon, "position", base, 0.15)


func _ground_distance(enemy: Enemy) -> float:
	return Vector2(enemy.position.x - position.x, enemy.position.z - position.z).length()


## Ziele in Reichweite (passend zu Boden/Luft), sortiert nach der Zielwahl. Gleichstand: näher an der Burg.
func _pick_targets(count: int) -> Array[Enemy]:
	var r := reach()
	var kind := targets()
	var inside: Array[Enemy] = []
	for enemy: Enemy in game.enemies:
		if not enemy.alive or (enemy.air and kind == "ground") or (not enemy.air and kind == "air"):
			continue
		if _ground_distance(enemy) <= r:
			inside.append(enemy)
	var mode := target_mode
	inside.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		match mode:
			&"strong":
				if a.hp != b.hp:
					return a.hp > b.hp
			&"weak":
				if a.hp != b.hp:
					return a.hp < b.hp
			&"air":
				if a.air != b.air:
					return a.air
		return a.distance_left < b.distance_left)
	return inside.slice(0, count)
