class_name Tower
extends Node3D
## Ein Turm auf einem Feld: Modell aus Burgteilen, sucht sich den Gegner, der der Burg am nächsten ist.

const GROUND := 0.2  # Oberkante der Bodenkachel

var id: StringName
var level := 1
var cell: Vector2i
var invested := 0
var game: Node  # Main
var _cooldown := 0.0
var _model: Node3D
var _weapon: Node3D
var _muzzle_height := 1.0


func setup(tower_id: StringName, at: Vector2i, main: Node) -> void:
	id = tower_id
	cell = at
	game = main
	invested = Defs.TOWERS[id]["cost"]
	position = Board.world_of(at)
	_build_model()


func _build_model() -> void:
	if _model != null:
		_model.queue_free()
	_model = build_model(id, level)
	add_child(_model)
	_weapon = _model.get_node_or_null("Weapon")
	_muzzle_height = _model.get_meta("muzzle", 1.0)


## Modell eines Turms (auch für die Bauvorschau): Teile übereinander, Waffe oben drauf.
static func build_model(tower_id: StringName, tower_level: int) -> Node3D:
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
	if def.has("unit"):
		var unit := Models.make(def["unit"])
		unit.scale = Vector3.ONE * (1.1 + 0.1 * (tower_level - 1))
		weapon.add_child(unit)
		for node in unit.find_children("*", "AnimationPlayer", true, false):
			if (node as AnimationPlayer).has_animation("idle"):
				(node as AnimationPlayer).play("idle")
		var side := 1.0
		for key: String in def.get("props", []):
			var prop := Models.make(key)
			prop.position = Vector3(0.28 * side, 0.32, 0.12)
			prop.rotation.x = -0.35 if key.ends_with("spear") else 0.0
			unit.add_child(prop)
			side = -side
		y += 0.7
	if def.has("weapon"):
		var model := Models.make(def["weapon"])
		var s: float = def["scale"] * (1.0 + 0.12 * (tower_level - 1))
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
	root.set_meta("muzzle", y)
	return root


func damage() -> float:
	return Defs.tower_damage(id, level)


func reach() -> float:
	return Defs.tower_range(id, level)


func can_upgrade() -> bool:
	return Defs.upgrade_cost(id, level) > 0


func upgrade() -> void:
	invested += Defs.upgrade_cost(id, level)
	level += 1
	_build_model()


func _process(delta: float) -> void:
	if Defs.TOWERS[id]["damage"] <= 0:
		return
	_cooldown -= delta
	var target: Enemy = _pick_target()
	if target == null:
		return
	if _weapon != null:
		var dir := target.global_position - global_position
		_weapon.rotation.y = atan2(dir.x, dir.z)
	if _cooldown > 0.0:
		return
	_cooldown = Defs.tower_cooldown(id, level)
	var def: Dictionary = Defs.TOWERS[id]
	if def["projectile"] == "melee":
		target.take_damage(damage())
		_lunge()
		return
	var shot := Projectile.new()
	game.add_child(shot)
	shot.launch(def["projectile"], global_position + Vector3(0, _muzzle_height, 0), target, damage(),
			def.get("splash", 0.0), def.get("slow", 0.0), def.get("slow_time", 0.0), def["speed"])


## Kurzer Ausfallschritt der Figur beim Nahkampf.
func _lunge() -> void:
	if _weapon == null:
		return
	var forward := Vector3(sin(_weapon.rotation.y), 0, cos(_weapon.rotation.y)) * 0.25
	var base := Vector3(0, _weapon.position.y, 0)
	var tween := create_tween()
	tween.tween_property(_weapon, "position", base + forward, 0.08)
	tween.tween_property(_weapon, "position", base, 0.15)


## Ziel: der Gegner in Reichweite, der den kürzesten Rest bis zur Burg hat.
func _pick_target() -> Enemy:
	var best: Enemy = null
	var best_left := INF
	var r := reach()
	for enemy: Enemy in game.enemies:
		if not enemy.alive:
			continue
		var d := Vector2(enemy.position.x - position.x, enemy.position.z - position.z).length()
		if d <= r and enemy.distance_left < best_left:
			best = enemy
			best_left = enemy.distance_left
	return best
