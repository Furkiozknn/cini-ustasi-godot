class_name PauseScreen
extends UiScreen
## Pause menu ("Mola").

var _title: Label
var _resume: Button
var _restart: Button
var _levels: Button
var _collection: Button
var _home: Button
var _settings: Button


func build() -> void:
	card_max_width = 440.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	_title = UiTheme.label("", 26, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	v.add_child(UiTheme.spacer(4))
	var r0 := UiTheme.row()
	_resume = UiTheme.button("", "")
	_resume.pressed.connect(func() -> void: GameState.close_overlays())
	r0.add_child(_resume)
	v.add_child(r0)
	var r1 := UiTheme.row()
	_restart = UiTheme.button("", "AltButton")
	_restart.pressed.connect(func() -> void:
		GameState.close_overlays()
		GameState.restart_level())
	_levels = UiTheme.button("", "AltButton")
	_levels.pressed.connect(func() -> void: GameState.show_levels())
	r1.add_child(_restart)
	r1.add_child(_levels)
	v.add_child(r1)
	var r2 := UiTheme.row()
	_collection = UiTheme.button("", "AltButton")
	_collection.pressed.connect(func() -> void: GameState.show_collection())
	_home = UiTheme.button("", "AltButton")
	_home.pressed.connect(func() -> void: GameState.show_title())
	r2.add_child(_collection)
	r2.add_child(_home)
	v.add_child(r2)
	var r3 := UiTheme.row()
	_settings = UiTheme.button("", "AltButton")
	_settings.pressed.connect(func() -> void: GameState.show_settings())
	r3.add_child(_settings)
	v.add_child(r3)


func refresh() -> void:
	_title.text = Loc.t("paused")
	_resume.text = Loc.t("resume")
	_restart.text = Loc.t("restart")
	_levels.text = Loc.t("levels")
	_collection.text = Loc.t("collection")
	_home.text = Loc.t("backToTitle")
	_settings.text = Loc.t("settings")
