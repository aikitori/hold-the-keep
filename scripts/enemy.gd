class_name Enemy
extends Node3D
## Ein Gegner: läuft Feld für Feld zur Burg und sucht sich einen neuen Weg, wenn gebaut wird.

const GROUND := 0.2

var kind: StringName
var max_hp := 1.0
var hp := 1.0
var speed := 1.0
var gold := 1
var is_boss := false
var alive := true
## Restweg bis zur Burg in Feldern (für die Zielwahl der Türme).
var distance_left := 0.0
var game: Node
var board: Board
var _path: Array[Vector2i] = []
var _next := 0
var _slow := 0.0
var _slow_time := 0.0
var _lift := 0.0
var _anim: AnimationPlayer
var _bob := randf() * TAU


func setup(enemy_kind: StringName, wave: int, main: Node, field: Board) -> void:
	kind = enemy_kind
	game = main
	board = field
	var def: Dictionary = Defs.ENEMIES[kind]
	max_hp = def["hp"] * Defs.health_factor(wave)
	hp = max_hp
	speed = def["speed"]
	gold = def["gold"] + wave / 6
	is_boss = def.get("boss", false)
	_lift = def["lift"]
	var model := Models.make(def["model"])
	var size: float = def.get("size", 1.0) * 1.15
	model.scale = Vector3(size, size, size)
	add_child(model)
	for node in model.find_children("*", "AnimationPlayer", true, false):
		_anim = node
		break
	if _anim != null and _anim.has_animation("walk"):
		_anim.play("walk")
		_anim.speed_scale = speed * 1.4
	position = Board.world_of(board.map.spawn, GROUND + _lift)
	repath()


func current_cell() -> Vector2i:
	return Board.cell_of(position)


## Neuen Weg ab der aktuellen Zelle (nach jedem Bau).
func repath() -> void:
	_path = board.path_from(current_cell())
	_next = 1 if _path.size() > 1 else 0
	distance_left = board.path_length(_path)


func take_damage(amount: float) -> void:
	if not alive:
		return
	hp -= amount
	if hp <= 0.0:
		_die()


func apply_slow(factor: float, seconds: float) -> void:
	_slow = maxf(_slow, factor)
	_slow_time = maxf(_slow_time, seconds)


func _die() -> void:
	alive = false
	game.enemy_killed(self)
	if _anim != null and _anim.has_animation("die"):
		_anim.speed_scale = 1.0
		_anim.play("die")
	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.25)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	if not alive:
		return
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow = 0.0
	var step := speed * (1.0 - _slow) * delta
	while step > 0.0 and _next < _path.size():
		var target := Board.world_of(_path[_next], GROUND + _lift)
		var to := target - Vector3(position.x, GROUND + _lift, position.z)
		var dist := to.length()
		if dist > 0.001:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 0.3)
		if dist <= step:
			position = target
			step -= dist
			distance_left = maxf(0.0, distance_left - dist)
			_next += 1
		else:
			position += to / dist * step
			distance_left = maxf(0.0, distance_left - step)
			step = 0.0
	if _lift > 0.3:  # Geister schweben
		_bob += delta * 3.0
		position.y = GROUND + _lift + sin(_bob) * 0.08
	if _next >= _path.size():
		alive = false
		game.enemy_reached_keep(self)
		queue_free()
