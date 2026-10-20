class_name SettingsScreen
extends UiScreen
## Settings: master / music / effects volume, language, graphics quality, fullscreen.

var _title: Label
var _labels: Dictionary = {}
var _sliders: Dictionary = {}
var _lang_tr: Button
var _lang_en: Button
var _q_low: Button
var _q_high: Button
var _fullscreen: CheckButton
var _close: Button
var _syncing: bool = false


func build() -> void:
	card_max_width = 460.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	_title = UiTheme.label("", 26, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	v.add_child(UiTheme.spacer(2))
	for key in ["master", "music", "sfx"]:
		var l := UiTheme.label("", 14, UiTheme.INK, true)
		_labels[key] = l
		v.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.custom_minimum_size = Vector2(0, 30)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.focus_mode = Control.FOCUS_ALL
		s.value_changed.connect(func(val: float) -> void:
			if not _syncing:
				Settings.set_volume(key, val))
		s.drag_ended.connect(func(_changed: bool) -> void: Audio.play("ui"))
		_sliders[key] = s
		v.add_child(s)
	v.add_child(UiTheme.spacer(2))
	var lang_row := HBoxContainer.new()
	lang_row.add_theme_constant_override("separation", 8)
	var ll := UiTheme.label("", 14, UiTheme.INK, true)
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_labels["lang"] = ll
	lang_row.add_child(ll)
	_lang_tr = UiTheme.button("Türkçe", "ToggleButton", 90)
	_lang_tr.pressed.connect(func() -> void: Settings.set_language("tr"))
	_lang_en = UiTheme.button("English", "ToggleButton", 90)
	_lang_en.pressed.connect(func() -> void: Settings.set_language("en"))
	lang_row.add_child(_lang_tr)
	lang_row.add_child(_lang_en)
	v.add_child(lang_row)
	var q_row := HBoxContainer.new()
	q_row.add_theme_constant_override("separation", 8)
	var ql := UiTheme.label("", 14, UiTheme.INK, true)
	ql.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_labels["quality"] = ql
	q_row.add_child(ql)
	_q_low = UiTheme.button("", "ToggleButton", 90)
	_q_low.pressed.connect(func() -> void: Settings.set_quality("low"))
	_q_high = UiTheme.button("", "ToggleButton", 90)
	_q_high.pressed.connect(func() -> void: Settings.set_quality("high"))
	q_row.add_child(_q_low)
	q_row.add_child(_q_high)
	v.add_child(q_row)
	_fullscreen = CheckButton.new()
	_fullscreen.focus_mode = Control.FOCUS_ALL
	_fullscreen.toggled.connect(func(on: bool) -> void:
		if not _syncing:
			Audio.play("ui")
			Settings.set_fullscreen(on))
	v.add_child(_fullscreen)
	v.add_child(UiTheme.spacer(4))
	var r := UiTheme.row()
	_close = UiTheme.button("", "")
	_close.pressed.connect(func() -> void: GameState.back())
	primary = _close
	r.add_child(_close)
	v.add_child(r)
	Settings.changed.connect(_sync)


func refresh() -> void:
	_title.text = Loc.t("settings")
	_labels["master"].text = Loc.t("masterVolume")
	_labels["music"].text = Loc.t("musicVolume")
	_labels["sfx"].text = Loc.t("sfxVolume")
	_labels["lang"].text = Loc.t("language")
	_labels["quality"].text = Loc.t("quality")
	_q_low.text = Loc.t("qualityLow")
	_q_high.text = Loc.t("qualityHigh")
	_fullscreen.text = Loc.t("fullscreen")
	_close.text = Loc.t("close")
	_sync()


func _sync() -> void:
	_syncing = true
	_sliders["master"].value = Settings.master_volume
	_sliders["music"].value = Settings.music_volume
	_sliders["sfx"].value = Settings.sfx_volume
	_fullscreen.button_pressed = Settings.fullscreen
	_mark(_lang_tr, Settings.lang == "tr")
	_mark(_lang_en, Settings.lang == "en")
	_mark(_q_low, Settings.is_low_quality())
	_mark(_q_high, not Settings.is_low_quality())
	_syncing = false


func _mark(b: Button, on: bool) -> void:
	if on:
		var sb := UiTheme.flat(Color("#2a5fb8"), 14.0)
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		sb.content_margin_top = 11
		sb.content_margin_bottom = 11
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")
		b.remove_theme_color_override("font_color")
		b.remove_theme_color_override("font_hover_color")
