class_name TitleScreen
extends UiScreen
## Title card: crest, name, subtitle, intro line, Play (or Continue) / Levels / Collection / Daily, sound,
## music, settings and language, progress and the arena credit.

var _title: Label
var _subtitle: Label
var _intro: Label
var _play: Button
var _levels: Button
var _collection: Button
var _daily: Button
var _settings: IconButton
var _sound: IconButton
var _music: IconButton
var _credit: Label
var _lang: Button
var _progress: Label
var _progress_star: StarRow
## The crest (generated) or the baked logo tile (filled in by Ui; see TileFace.logo_rect).
var logo: TextureRect


func build() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var logo_holder := CenterContainer.new()
	logo = TileFace.logo_rect(120)
	logo_holder.add_child(logo)
	v.add_child(logo_holder)
	_title = UiTheme.label("Çini Ustası", 42, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	var deco := UiTheme.row(10)
	for i in 2:
		if i == 1:
			_subtitle = UiTheme.label("", 12, UiTheme.TURQ, true, HORIZONTAL_ALIGNMENT_CENTER)
			deco.add_child(_subtitle)
		var line := ColorRect.new()
		line.color = UiTheme.TURQ
		line.custom_minimum_size = Vector2(46, 2)
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		deco.add_child(line)
	v.add_child(deco)
	_intro = UiTheme.wrapped("", 15)
	v.add_child(_intro)
	v.add_child(UiTheme.spacer(6))
	var r1 := UiTheme.row(8)
	_play = UiTheme.button("", "")
	_play.pressed.connect(func() -> void: GameState.start_level(GameState.next_unfinished()))
	primary = _play
	_levels = UiTheme.button("", "AltButton")
	_levels.pressed.connect(func() -> void: GameState.show_levels())
	r1.add_child(_play)
	r1.add_child(_levels)
	v.add_child(r1)
	var r2 := UiTheme.row(8)
	_collection = UiTheme.button("", "AltButton")
	_collection.pressed.connect(func() -> void: GameState.show_collection())
	_daily = UiTheme.button("", "TurqButton")
	_daily.pressed.connect(func() -> void:
		if GameState.daily_unlocked():
			GameState.start_level(GameState.DAILY))
	r2.add_child(_collection)
	r2.add_child(_daily)
	v.add_child(r2)
	v.add_child(UiTheme.spacer(4))
	var foot := UiTheme.row(8)
	_sound = IconButton.new("sound")
	_sound.pressed.connect(func() -> void: Settings.toggle_sfx())
	_music = IconButton.new("music")
	_music.pressed.connect(func() -> void: Settings.toggle_music())
	_settings = IconButton.new("settings")
	_settings.pressed.connect(func() -> void: GameState.show_settings())
	_lang = UiTheme.button("EN", "IconButton", UiTheme.MIN_TOUCH)
	_lang.custom_minimum_size = Vector2(UiTheme.MIN_TOUCH, UiTheme.MIN_TOUCH)
	_lang.pressed.connect(func() -> void: Settings.toggle_language())
	foot.add_child(_sound)
	foot.add_child(_music)
	foot.add_child(_settings)
	foot.add_child(_lang)
	Settings.changed.connect(_sync_toggles)
	v.add_child(foot)
	# "12/30 · 36" followed by a drawn star: the bundled font has no ★ and the web build has no
	# system fonts to fall back on.
	var progress_row := UiTheme.row(4)
	_progress = UiTheme.label("", 12, UiTheme.INK_SOFT, false, HORIZONTAL_ALIGNMENT_CENTER)
	progress_row.add_child(_progress)
	_progress_star = StarRow.new(1, 11, 1)
	_progress_star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progress_row.add_child(_progress_star)
	v.add_child(progress_row)
	_credit = UiTheme.label("", 11, UiTheme.INK_SOFT, false, HORIZONTAL_ALIGNMENT_CENTER)
	_credit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credit.modulate.a = 0.8
	v.add_child(_credit)


func refresh() -> void:
	_title.text = Loc.t("title")
	_subtitle.text = Loc.t("subtitle").to_upper()
	_intro.text = Loc.t("intro")
	_play.text = Loc.t("continue") if GameState.completed_count() > 0 else Loc.t("play")
	_levels.text = Loc.t("levels")
	_collection.text = Loc.t("collection")
	_daily.text = Loc.t("daily")
	_daily.disabled = not GameState.daily_unlocked()
	_daily.tooltip_text = "" if GameState.daily_unlocked() else Loc.t("dailyLocked")
	_lang.text = Loc.other_language().to_upper()
	_settings.tooltip_text = Loc.t("settings")
	_sound.tooltip_text = Loc.t("soundTip")
	_music.tooltip_text = Loc.t("musicTip")
	_lang.tooltip_text = Loc.t("langTip")
	_credit.text = Loc.t("credit")
	_sync_toggles()
	_progress.text = Loc.t("progressLine") % [GameState.completed_count(), PuzzleCore.LEVEL_COUNT, GameState.total_stars()]


func _sync_toggles() -> void:
	_sound.slashed = not Settings.sfx_on
	_music.slashed = not Settings.music_on
	_sound.queue_redraw()
	_music.queue_redraw()


func _layout(vp: Vector2) -> void:
	_title.add_theme_font_size_override("font_size", 30 if vp.y < 520.0 else (34 if is_narrow() else 42))
