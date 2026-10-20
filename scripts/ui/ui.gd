extends CanvasLayer
## Assembles the HUD, every overlay screen and the toasts; switches screens on GameState signals.

var baker: TextureBaker
var hud: Hud
var toasts: Toasts
var screens: Dictionary = {}
var _root: Control
var _hud_on: bool = false


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.name = "Root"
	_root.theme = UiTheme.build()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	hud = Hud.new()
	hud.name = "Hud"
	hud.visible = false
	_root.add_child(hud)
	_add_screen(GameState.SCREEN_TITLE, TitleScreen.new())
	_add_screen(GameState.SCREEN_LEVELS, LevelsScreen.new())
	var collection := CollectionScreen.new()
	collection.baker = baker
	_add_screen(GameState.SCREEN_COLLECTION, collection)
	_add_screen(GameState.SCREEN_HOWTO, HowtoScreen.new())
	_add_screen(GameState.SCREEN_MENU, PauseScreen.new())
	_add_screen(GameState.SCREEN_SETTINGS, SettingsScreen.new())
	var complete := CompleteScreen.new()
	complete.baker = baker
	_add_screen(GameState.SCREEN_COMPLETE, complete)
	toasts = Toasts.new()
	toasts.name = "Toasts"
	_root.add_child(toasts)
	GameState.screen_changed.connect(_on_screen_changed)
	GameState.toast.connect(toasts.show_toast)
	GameState.board_changed.connect(func(_u: bool, _n: int) -> void: hud.update_stats())
	GameState.level_started.connect(func(_i: bool) -> void: hud.update_stats())
	GameState.progress_changed.connect(_refresh_all)
	Loc.language_changed.connect(func(_l: String) -> void: _refresh_all())
	get_viewport().size_changed.connect(_apply_scale)
	_apply_scale()
	_on_screen_changed(GameState.screen, GameState.SCREEN_LOADING)
	_bake_logo()


## The logo tile is drawn once into a texture instead of as ~60 vector commands every frame
## (that was most of the title screen's draw calls).
func _bake_logo() -> void:
	var tex: Texture2D = await baker.bake_logo()
	hud.logo.texture = tex
	screens[GameState.SCREEN_TITLE].logo.texture = tex


func _exit_tree() -> void:
	UiTheme.release()


func _add_screen(key: StringName, screen: UiScreen) -> void:
	screen.name = String(key).capitalize() + "Screen"
	_root.add_child(screen)
	screens[key] = screen


func _apply_scale() -> void:
	var win: Vector2 = Vector2(get_window().size)
	var factor: float = clampf(minf(win.x, win.y) / 720.0, 1.0, 1.6)
	get_window().content_scale_factor = factor


func _refresh_all() -> void:
	hud.refresh()
	for s in screens.values():
		if s.visible:
			s.refresh()


func _on_screen_changed(screen: StringName, prev: StringName) -> void:
	if screen == GameState.SCREEN_TITLE:
		_hud_on = false
	elif screen == GameState.SCREEN_PLAYING:
		_hud_on = true
	hud.visible = _hud_on and GameState.puzzle != null
	if _hud_on:
		hud.update_stats()
	for key in screens:
		var s: UiScreen = screens[key]
		if key == screen:
			continue
		if s.visible:
			if prev == key:
				s.hide_screen()
			else:
				s.hide_now()
	if screens.has(screen):
		var s: UiScreen = screens[screen]
		s.show_screen()
