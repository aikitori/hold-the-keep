extends Node
## Einstellungen und Fortschritt (Autoload "Settings"): Schwierigkeit, Grafikstufe und die Bestwerte je Karte
## und Schwierigkeit. Alles liegt in user://settings.cfg (dieselbe Datei wie der Ton in `Sfx`).

signal changed

## Tests leiten auf eine eigene Datei um, damit echte Bestwerte unberührt bleiben.
var file := "user://settings.cfg"
## Laufendes Spiel (ein Platz), getrennt von den Einstellungen.
var save_file := "user://savegame.cfg"

var difficulty: StringName = &"normal"
## Beim ersten Start die Sprache des Systems (Deutsch, sonst Englisch).
var language := "de"
## Schatten und Kantenglättung aus, für schwache Handys.
var low_graphics := false


func _ready() -> void:
	var config := _config()
	difficulty = StringName(config.get_value("game", "difficulty", "normal"))
	if not Defs.DIFFICULTIES.has(difficulty):
		difficulty = &"normal"
	low_graphics = config.get_value("graphics", "low", false)
	var system := "de" if OS.get_locale_language() == "de" else "en"
	language = config.get_value("game", "language", system)
	if not Lang.LANGUAGES.has(language):
		language = "en"
	Lang.apply(language)
	apply_graphics()


func set_difficulty(value: StringName) -> void:
	difficulty = value
	_store("game", "difficulty", String(value))
	changed.emit()


func set_language(value: String) -> void:
	language = value
	_store("game", "language", value)
	Lang.apply(value)
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
func record(map_id: StringName, wave: int, won: bool, level: StringName = difficulty) -> void:
	var old := best(map_id, level)
	if wave <= int(old["wave"]) and (not won or old["won"]):
		return
	_store("progress", "%s/%s" % [map_id, level], {"wave": maxi(wave, int(old["wave"])), "won": won or old["won"]})


## Laufendes Spiel: Stand zwischen zwei Wellen (siehe Main.snapshot), leer wenn keins.
func saved_game() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(save_file) != OK:
		return {}
	var state: Dictionary = config.get_value("game", "state", {})
	return state if state.get("version", 0) == Main.SAVE_VERSION else {}


func save_game(state: Dictionary) -> void:
	var config := ConfigFile.new()
	config.set_value("game", "state", state)
	config.save(save_file)


func clear_game() -> void:
	DirAccess.remove_absolute(save_file)


func _config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(file)
	return config


func _store(section: String, key: String, value: Variant) -> void:
	var config := _config()
	config.set_value(section, key, value)
	config.save(file)
