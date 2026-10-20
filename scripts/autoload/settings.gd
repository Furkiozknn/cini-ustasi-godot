extends Node
## Player settings (volumes, language, quality, fullscreen) saved in user://settings.cfg.
## With `--no-save` nothing is read from or written to disk.

signal changed

const PATH: String = "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var lang: String = "tr"
var quality: String = "high"
## True once the player picked a quality in Settings; until then the platform default applies.
var quality_chosen: bool = false
var fullscreen: bool = false
var no_save: bool = false


func _ready() -> void:
	no_save = Args.has("no-save")
	quality = default_quality()
	if not no_save:
		_load()
	if Args.has("lang"):
		lang = Args.value("lang", lang)
	if Args.has("quality"):
		quality = Args.value("quality", quality)
	if Args.has("mute"):
		master_volume = 0.0
	Loc.set_language(lang)
	_apply_window()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = clampf(float(cfg.get_value("audio", "master", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(cfg.get_value("audio", "music", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx", sfx_volume)), 0.0, 1.0)
	lang = str(cfg.get_value("game", "lang", lang))
	# Older saves wrote the "high" default on every save; only an explicit choice overrides the platform default.
	quality_chosen = bool(cfg.get_value("video", "quality_chosen", false))
	if quality_chosen:
		quality = str(cfg.get_value("video", "quality", quality))
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))


func save() -> void:
	if no_save:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("game", "lang", lang)
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "quality_chosen", quality_chosen)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)


func set_volume(bus: String, v: float) -> void:
	v = clampf(v, 0.0, 1.0)
	match bus:
		"master": master_volume = v
		"music": music_volume = v
		"sfx": sfx_volume = v
	changed.emit()
	save()


func set_language(new_lang: String) -> void:
	lang = new_lang
	Loc.set_language(lang)
	changed.emit()
	save()


func toggle_language() -> void:
	set_language(Loc.other_language())


func set_quality(q: String) -> void:
	quality = "low" if q == "low" else "high"
	quality_chosen = true
	changed.emit()
	save()


## The browser build (WebGL2, no threads) gets the cheap tier; `--web-sim` forces the same defaults natively.
static func is_web() -> bool:
	return OS.has_feature("web") or Args.has("web-sim")


static func default_quality() -> String:
	return "low" if is_web() else "high"


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_window()
	changed.emit()
	save()


func _apply_window() -> void:
	# Never touch the window during tool runs (tests, movie maker, headless bot).
	if DisplayServer.get_name() == "headless" or Args.has("no-save"):
		return
	var mode := DisplayServer.window_get_mode()
	if fullscreen and mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fullscreen and mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func is_low_quality() -> bool:
	return quality == "low"
