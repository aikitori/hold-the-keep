extends Node
## Klänge (Autoload "Sfx"): Sfx.play(&"click") oder Sfx.play_at(&"arrow", position) für Geräusche auf der
## Karte, die nur zu hören sind, wenn die Stelle im Bild ist. Häufige Klänge werden begrenzt, damit viele
## Türme nicht zu einem Dauerrauschen werden. Ton an/aus wird in user://settings.cfg gespeichert.
## Musik: Sfx.music(&"build") / Sfx.music(&"battle") blendet über, Sfx.music(&"") blendet aus. Die Schleifen
## erzeugt tools/make_music.py.

const SETTINGS := "user://settings.cfg"
const VOICES := 24
## Lautstärke in dB je Klang (alle Dateien sind auf gleiche Spitze angeglichen).
const VOLUME := {
	&"arrow": -11.0, &"bolt": -9.0, &"throw": -8.0, &"fire": -12.0, &"magic": -13.0, &"lightning": -10.0,
	&"stab": -10.0, &"hit": -16.0, &"crash": -7.0, &"burst": -9.0,
	&"die": -12.0, &"bones": -11.0, &"ghost": -11.0, &"boss": -3.0, &"boss_die": -3.0, &"keep_hit": -5.0,
	&"build": -6.0, &"upgrade": -5.0, &"spec": -5.0, &"sell": -6.0, &"coins": -6.0, &"error": -8.0,
	&"click": -10.0, &"wave": -6.0, &"victory": -3.0, &"defeat": -3.0,
}
## Höchstens so viele gleiche Klänge gleichzeitig (sonst 2).
const MAX_SAME := {&"arrow": 3, &"hit": 3, &"die": 3, &"bones": 3, &"magic": 2, &"crash": 2}
## Mindestabstand in Sekunden Echtzeit zwischen zwei gleichen Klängen.
const MIN_GAP := 0.07
## Ohne Tonhöhen-Streuung (Musik und Oberfläche).
const STEADY: Array[StringName] = [&"wave", &"victory", &"defeat", &"click", &"error"]

const MUSIC := {&"build": preload("res://assets/audio/music_build.wav"), &"battle": preload("res://assets/audio/music_battle.wav")}
const MUSIC_DB := -13.0
const SILENT_DB := -40.0
const FADE := 1.5

var muted := false
var music_on := true
var _music: Array[AudioStreamPlayer] = []
var _music_id: StringName = &""
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id: StringName in VOLUME:
		_streams[id] = load("res://assets/audio/%s.ogg" % id)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	for i in 2:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_music.append(player)
	var config := ConfigFile.new()
	if config.load(SETTINGS) == OK:
		muted = config.get_value("audio", "muted", false)
		music_on = config.get_value("audio", "music", true)
	_apply_mute()


func play(id: StringName) -> void:
	if muted or not _streams.has(id):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(id, -1.0)) < MIN_GAP:
		return
	var same := 0
	var free: AudioStreamPlayer = null
	for player in _players:
		if player.playing:
			if player.stream == _streams[id]:
				same += 1
		elif free == null:
			free = player
	if free == null or same >= int(MAX_SAME.get(id, 2)):
		return
	_last[id] = now
	free.stream = _streams[id]
	free.volume_db = VOLUME[id]
	free.pitch_scale = 1.0 if id in STEADY else randf_range(0.9, 1.1)
	free.play()


## Geräusch auf der Karte: nur, wenn die Stelle gerade zu sehen ist.
func play_at(id: StringName, at: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and not camera.is_position_in_frustum(at):
		return
	play(id)


## Musik wechseln: der neue Titel blendet ein, der alte aus. Gleicher Titel läuft einfach weiter.
func music(id: StringName) -> void:
	if id == _music_id:
		return
	_music_id = id
	_play_music()


func set_music_on(value: bool) -> void:
	music_on = value
	var config := ConfigFile.new()
	config.load(SETTINGS)
	config.set_value("audio", "music", music_on)
	config.save(SETTINGS)
	_play_music()


func _play_music() -> void:
	var old := _music[0] if _music[0].playing else _music[1]
	var fresh := _music[1] if old == _music[0] else _music[0]
	if old.playing:
		var out := create_tween()
		out.tween_property(old, "volume_db", SILENT_DB, FADE)
		out.tween_callback(old.stop)
	if not music_on or muted or _music_id == &"":
		return
	fresh.stream = MUSIC[_music_id]
	fresh.volume_db = SILENT_DB
	fresh.play()
	create_tween().tween_property(fresh, "volume_db", MUSIC_DB, FADE)


func set_muted(value: bool) -> void:
	muted = value
	_apply_mute()
	_play_music()
	var config := ConfigFile.new()
	config.load(SETTINGS)
	config.set_value("audio", "muted", muted)
	config.save(SETTINGS)


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)
	if muted:
		for player in _players:
			player.stop()

