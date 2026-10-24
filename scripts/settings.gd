extends Node
## Einstellungen und Fortschritt (Autoload "Settings"): Schwierigkeit, Grafikstufe und die Bestwerte je Karte
## und Schwierigkeit. Alles liegt in user://settings.cfg (dieselbe Datei wie der Ton in `Sfx`).

signal changed

## Tests leiten auf eine eigene Datei um, damit echte Bestwerte unberührt bleiben.
var file := "user://settings.cfg"

var difficulty: StringName = &"normal"
## Schatten und Kantenglättung aus, für schwache Handys.
var low_graphics := false


func _ready() -> void:
	var config := _config()
	difficulty = StringName(config.get_value("game", "difficulty", "normal"))
	if not Defs.DIFFICULTIES.has(difficulty):
		difficulty = &"normal"
	low_graphics = config.get_value("graphics", "low", false)
	apply_graphics()


func set_difficulty(value: StringName) -> void:
	difficulty = value
	_store("game", "difficulty", String(value))
	changed.emit()


func set_low_graphics(value: bool) -> void:
	low_graphics = value
	_store("graphics", "low", value)
	apply_graphics()
	changed.emit()


func apply_graphics() -> void:
	get_tree().root.msaa_3d = Viewport.MSAA_DISABLED if low_graphics else Viewport.MSAA_2X


## Bestwert auf einer Karte: {"wave": überstandene Wellen, "won": Burg bis zum Ende gehalten}.
func best(map_id: StringName, level: StringName = difficulty) -> Dictionary:
	return _config().get_value("progress", "%s/%s" % [map_id, level], {"wave": 0, "won": false})


## Nur Verbesserungen werden gespeichert.
func record(map_id: StringName, wave: int, won: bool) -> void:
	var old := best(map_id)
	if wave <= int(old["wave"]) and (not won or old["won"]):
		return
	_store("progress", "%s/%s" % [map_id, difficulty], {"wave": maxi(wave, int(old["wave"])), "won": won or old["won"]})


func _config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(file)
	return config


func _store(section: String, key: String, value: Variant) -> void:
	var config := _config()
	config.set_value(section, key, value)
	config.save(file)
