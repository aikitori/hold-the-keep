extends Node
## Größe der Oberfläche (Autoload "UiScale"): Auf Geräten mit Touchscreen wird alles so vergrößert, dass die
## kurze Bildschirmseite etwa 600 Einheiten hat (am Rechner 720). Im Hochformat ordnen HUD und Menü sich
## schmal an (`narrow`). Quer auf niedrigen Bildschirmen (Handy) wird die Oberfläche kompakt (`compact`), damit
## mehr Spielfeld frei bleibt. `safe` hält die Ränder frei, die Kameraloch (Notch) und runde Ecken verdecken.

signal changed

const TOUCH_SHORT_SIDE := 600.0
const DESKTOP_SHORT_SIDE := 720.0
const NARROW_WIDTH := 900.0
const COMPACT_HEIGHT := 650.0
## Mindestrand auf Touch-Geräten in Bildschirmpunkten: runde Ecken meldet Android meist nicht als unsicher.
const CORNER := 28.0

var narrow := false
var compact := false
## Freizuhaltende Ränder in Oberflächen-Einheiten: links, oben, rechts, unten.
var safe := Vector4.ZERO
## Zum Ausprobieren am Rechner: tut so, als gäbe es einen Touchscreen (--touch-ui) oder links ein
## Kameraloch (--notch).
var force_touch := false
var force_notch := false


func _ready() -> void:
	force_touch = OS.get_cmdline_user_args().has("--touch-ui")
	force_notch = OS.get_cmdline_user_args().has("--notch")
	get_tree().root.size_changed.connect(apply)
	apply()


func apply() -> void:
	var window := get_tree().root
	var size := Vector2(window.size)
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var touch := force_touch or DisplayServer.is_touchscreen_available()
	# Grundmaßstab durch stretch "expand" bei 1280x720, darauf der Zusatzfaktor.
	var base := minf(size.x / 1280.0, size.y / 720.0)
	var wanted := minf(size.x, size.y) / (TOUCH_SHORT_SIDE if touch else DESKTOP_SHORT_SIDE)
	var factor := maxf(1.0, wanted / base)
	if not is_equal_approx(window.content_scale_factor, factor):
		window.content_scale_factor = factor
	narrow = size.x / (base * factor) < NARROW_WIDTH
	compact = not narrow and size.y / (base * factor) < COMPACT_HEIGHT
	var insets := _safe_insets()
	if touch:
		insets = Vector4(maxf(insets.x, CORNER), maxf(insets.y, CORNER * 0.5), maxf(insets.z, CORNER), maxf(insets.w, CORNER * 0.5))
	safe = insets / (base * factor)
	changed.emit()


## Ränder in Bildschirmpunkten, die außerhalb des sicheren Bereichs liegen (Notch, runde Ecken).
func _safe_insets() -> Vector4:
	if force_notch:
		return Vector4(90, 0, 0, 0)
	var area := Rect2(DisplayServer.get_display_safe_area())
	var window := Rect2(DisplayServer.window_get_position(), DisplayServer.window_get_size())
	if area.size.x <= 0.0 or area.size.y <= 0.0 or not area.intersects(window):
		return Vector4.ZERO
	return Vector4(maxf(0.0, area.position.x - window.position.x), maxf(0.0, area.position.y - window.position.y),
			maxf(0.0, window.end.x - area.end.x), maxf(0.0, window.end.y - area.end.y))
