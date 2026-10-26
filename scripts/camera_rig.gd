class_name CameraRig
extends Node3D
## Isometrische Kamera ohne Perspektive. Der Rig steht auf dem Boden, die Kamera schaut schräg von oben.
## Verschieben per Ziehen (der gegriffene Bodenpunkt bleibt unter dem Finger, mit Touch gleitet die Karte nach),
## mit WASD, Pfeiltasten oder am Bildschirmrand. Zoomen zum Mauszeiger oder zur Mitte der Finger, Drehen in
## Vierteldrehungen um die Bildmitte.

const MIN_SIZE := 7.0
const MAX_SIZE := 26.0
const DISTANCE := 25.0
## Randscrollen: so nah am Fensterrand (in Einheiten) schiebt die Maus die Karte.
const EDGE := 6.0
## Tasten und Rand: Anteil der kurzen Bildschirmseite pro Sekunde.
const SCROLL_SPEED := 0.9
## Nachgleiten: Abbremsen pro Sekunde und höchstes Tempo in Feldern pro Sekunde.
const FRICTION := 5.0
const MAX_FLING := 30.0

var camera := Camera3D.new()
var bounds := Rect2(0, 0, 40, 26)
var _anchor := Vector3.ZERO
var _yaw := 0.0  # Ziel der Drehung, die Kamera folgt mit kurzer Animation
var _turn: Tween
var _velocity := Vector3.ZERO  # Tempo des letzten Ziehens, nach dem Loslassen gleitet die Karte so weiter
var _flinging := false
var _last_drag := 0  # Zeit des letzten Ziehens in Mikrosekunden
var _mouse_inside := false  # erst nach einer echten Mausbewegung, sonst scrollt eine alte Position am Rand


func _ready() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0
	camera.near = 0.1
	camera.far = 200.0
	add_child(camera)
	# Klassische Isometrie: 45° gedreht, Blick 35,26° von oben.
	camera.position = Vector3(1, 1, 1).normalized() * DISTANCE
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	camera.current = true
	get_viewport().size_changed.connect(_fit_aspect)
	_fit_aspect()


## Im Hochformat gilt die Zoomgröße für die Breite, sonst wäre nur ein schmaler Streifen der Karte zu sehen.
func _fit_aspect() -> void:
	var view := get_viewport().get_visible_rect().size
	camera.keep_aspect = Camera3D.KEEP_WIDTH if view.x < view.y else Camera3D.KEEP_HEIGHT


func _process(delta: float) -> void:
	var move := _key_direction() + _edge_direction()
	if move != Vector2.ZERO:
		_flinging = false
		var view := get_viewport().get_visible_rect().size
		pan(-move.normalized() * minf(view.x, view.y) * SCROLL_SPEED * delta)
	elif _flinging:
		_shift(_velocity * delta)
		_velocity *= exp(-FRICTION * delta)
		_flinging = _velocity.length() > 0.3


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		_mouse_inside = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_mouse_inside = false


## WASD (nach Lage auf der Tastatur) und Pfeiltasten, in Bildschirmrichtung.
func _key_direction() -> Vector2:
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT):
		return Vector2.ZERO
	var held := func(physical: Key, arrow: Key) -> float:
		return 1.0 if Input.is_physical_key_pressed(physical) or Input.is_key_pressed(arrow) else 0.0
	return Vector2(held.call(KEY_D, KEY_RIGHT) - held.call(KEY_A, KEY_LEFT), held.call(KEY_S, KEY_DOWN) - held.call(KEY_W, KEY_UP))


func _edge_direction() -> Vector2:
	if not _mouse_inside or not Settings.edge_scroll or UiScale.touch:
		return Vector2.ZERO
	# Im Browser meldet nicht jeder, wenn die Maus die Seite verlässt: dort nur im Vollbild.
	if OS.has_feature("web") and DisplayServer.window_get_mode() < DisplayServer.WINDOW_MODE_FULLSCREEN:
		return Vector2.ZERO
	var view := get_viewport().get_visible_rect().size
	var mouse := get_viewport().get_mouse_position()
	return Vector2((1.0 if mouse.x > view.x - EDGE else 0.0) - (1.0 if mouse.x < EDGE else 0.0),
			(1.0 if mouse.y > view.y - EDGE else 0.0) - (1.0 if mouse.y < EDGE else 0.0))


func zoom(factor: float) -> void:
	camera.size = clampf(camera.size * factor, MIN_SIZE, MAX_SIZE)


## Zoomen, ohne dass sich der Bodenpunkt unter `screen` bewegt (Mausrad zielt auf den Zeiger).
func zoom_at(factor: float, screen: Vector2) -> void:
	var before := ground_point(screen, 0.0)
	zoom(factor)
	_shift(before - ground_point(screen, 0.0))


## Kamera auf einen Punkt am Boden fahren.
func center_on(point: Vector3) -> void:
	_flinging = false
	var target := Vector3(clampf(point.x, bounds.position.x, bounds.end.x), position.y, clampf(point.z, bounds.position.y, bounds.end.y))
	create_tween().tween_property(self, "position", target, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Um `steps` Vierteldrehungen drehen, `done` wird nach der Animation gerufen.
func turn(steps: int, done := Callable()) -> void:
	_yaw += steps * PI / 2.0
	if _turn != null:
		_turn.kill()
	_turn = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_turn.tween_property(self, "rotation:y", _yaw, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if done.is_valid():
		_turn.tween_callback(done)


func turning() -> bool:
	return _turn != null and _turn.is_running()


## Bodenpunkt unter `screen` festhalten (beim Aufsetzen eines Fingers).
func grab(screen: Vector2) -> void:
	_anchor = ground_point(screen, 0.0)
	_flinging = false
	_velocity = Vector3.ZERO
	_last_drag = Time.get_ticks_usec()


## So verschieben, dass der festgehaltene Bodenpunkt unter `screen` liegt. Rechnet über denselben Strahl wie
## das Tippen und braucht weder `relative` noch einen Pixelmaßstab.
func drag_to(screen: Vector2) -> void:
	if turning():
		_anchor = ground_point(screen, 0.0)  # während der Drehung nur mitführen, sonst springt die Karte
		return
	var before := position
	_shift(_anchor - ground_point(screen, 0.0))
	var now := Time.get_ticks_usec()
	var seconds := clampf((now - _last_drag) / 1000000.0, 1.0 / 120.0, 0.1)
	_velocity = _velocity.lerp((position - before) / seconds, 0.6)
	_last_drag = now
	# Am Rand rutscht der Punkt weg: neu greifen, sonst klebt die Kamera beim Zurückziehen in der Ecke.
	_anchor = ground_point(screen, 0.0)


## Nach dem Loslassen weitergleiten, wenn der Finger bis zuletzt in Bewegung war.
func fling() -> void:
	_flinging = Time.get_ticks_usec() - _last_drag < 80000 and _velocity.length() > 1.0
	_velocity = _velocity.limit_length(MAX_FLING)


func stop() -> void:
	_flinging = false
	_velocity = Vector3.ZERO


func _shift(offset: Vector3) -> void:
	position.x = clampf(position.x + offset.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z + offset.z, bounds.position.y, bounds.end.y)


## Bildschirmbewegung in Pixeln -> Bewegung auf dem Boden (Trackpad-Geste).
func pan(screen_delta: Vector2) -> void:
	var view := get_viewport().get_visible_rect().size
	var units := camera.size / (view.x if camera.keep_aspect == Camera3D.KEEP_WIDTH else view.y)
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var right_ground := Vector3(right.x, 0, right.z).normalized()
	var up_ground := Vector3(up.x, 0, up.z).normalized()
	# Auf dem Boden ist eine Bildschirmzeile wegen der Schräglage länger: 1 / sin(35,26°).
	_shift(-right_ground * screen_delta.x * units + up_ground * screen_delta.y * units / sin(deg_to_rad(35.264)))


## Punkt auf dem Boden (Höhe `height`) unter einer Bildschirmposition.
func ground_point(screen: Vector2, height := 0.2) -> Vector3:
	var origin := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return origin
	var t := (height - origin.y) / dir.y
	return origin + dir * t
