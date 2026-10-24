extends Node
## Größe der Oberfläche (Autoload "UiScale"): Auf Geräten mit Touchscreen wird alles so vergrößert, dass die
## kurze Bildschirmseite etwa 560 Einheiten hat (am Rechner 720). Im Hochformat ordnen HUD und Menü sich
## schmal an (`narrow`). Quer auf niedrigen Bildschirmen (Handy) wird die Oberfläche kompakt (`compact`), damit
## mehr Spielfeld frei bleibt.

signal changed

const TOUCH_SHORT_SIDE := 600.0
const DESKTOP_SHORT_SIDE := 720.0
const NARROW_WIDTH := 900.0
const COMPACT_HEIGHT := 650.0

var narrow := false
var compact := false
## Zum Ausprobieren am Rechner: tut so, als gäbe es einen Touchscreen.
var force_touch := false


func _ready() -> void:
	force_touch = OS.get_cmdline_user_args().has("--touch-ui")
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
	changed.emit()
