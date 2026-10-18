class_name Projectile
extends Node3D
## Geschoss: Pfeile und Bolzen fliegen geradeaus hinter dem Ziel her, Felsbrocken im Bogen auf die Stelle,
## an der das Ziel beim Abschuss stand. Magie verlangsamt.

var kind: String
var target: Enemy
var damage := 0.0
var splash := 0.0
var slow := 0.0
var slow_time := 0.0
var speed := 10.0
var _from: Vector3
var _to: Vector3
var _t := 0.0
var _duration := 1.0
var _model: Node3D


func launch(shot_kind: String, from: Vector3, enemy: Enemy, amount: float, splash_radius: float,
		slow_factor: float, slow_seconds: float, fly_speed: float) -> void:
	kind = shot_kind
	target = enemy
	damage = amount
	splash = splash_radius
	slow = slow_factor
	slow_time = slow_seconds
	speed = fly_speed
	_from = from
	position = from
	_to = enemy.global_position + Vector3(0, 0.3, 0)
	_duration = maxf(0.15, _from.distance_to(_to) / speed)
	match kind:
		"arrow", "bolt":
			_model = Models.make("td/weapon-ammo-arrow")
			_model.scale = Vector3.ONE * (0.5 if kind == "arrow" else 0.8)
		"boulder":
			_model = Models.make("td/weapon-ammo-boulder")
			_model.scale = Vector3.ONE * (0.5 if splash < 1.5 else 0.8)
		_:
			var orb := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.12
			sphere.height = 0.24
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.7, 0.45, 1.0)
			material.emission_enabled = true
			material.emission = Color(0.6, 0.3, 1.0)
			material.emission_energy_multiplier = 2.0
			sphere.material = material
			orb.mesh = sphere
			_model = orb
	add_child(_model)


func _process(delta: float) -> void:
	_t += delta
	var arc := kind == "boulder"
	if not arc and is_instance_valid(target) and target.alive:
		_to = target.global_position + Vector3(0, 0.3, 0)
	var f := clampf(_t / _duration, 0.0, 1.0)
	var pos := _from.lerp(_to, f)
	if arc:
		pos.y += sin(f * PI) * maxf(1.0, _from.distance_to(_to) * 0.35)
	if pos.distance_squared_to(position) > 0.0001:
		look_at(pos, Vector3.UP, true)
	position = pos
	if f >= 1.0:
		_hit()


func _hit() -> void:
	if splash > 0.0:
		for enemy: Enemy in get_parent().enemies:
			if enemy.alive and Vector2(enemy.position.x - _to.x, enemy.position.z - _to.z).length() <= splash:
				enemy.take_damage(damage)
		get_parent().call("puff", _to)
	elif is_instance_valid(target) and target.alive:
		if slow > 0.0:
			target.apply_slow(slow, slow_time)
		target.take_damage(damage)
	queue_free()
