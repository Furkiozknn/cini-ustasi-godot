class_name Hud
extends PanelContainer
## Top bar while playing: logo, level name, moves / par / stars and the action buttons.

var _name_label: Label
var _level_name: Label
var _level_sub: Label
var _moves: VBoxContainer
var _par: VBoxContainer
var _stars: StarRow
var _stars_box: VBoxContainer
var _mid: HBoxContainer
var _row1: HBoxContainer
var _row2: HBoxContainer
var _hint: IconButton
var _undo: IconButton
var _restart: IconButton
var _help: IconButton
var _settings: IconButton
var _lang: Button
var _menu: IconButton
var _narrow: bool = false
## The logo tile as one baked texture (filled in by Ui once the baker is done).
var logo: TextureRect


func _init() -> void:
	theme_type_variation = &"Glass"
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_left = 10
	offset_right = -10
	offset_top = 10
	grow_vertical = Control.GROW_DIRECTION_END


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	add_child(v)
	_row1 = HBoxContainer.new()
	_row1.add_theme_constant_override("separation", 10)
	v.add_child(_row1)
	_row2 = HBoxContainer.new()
	_row2.add_theme_constant_override("separation", 10)
	_row2.visible = false
	v.add_child(_row2)
	# logo + name
	var logo_box := HBoxContainer.new()
	logo_box.add_theme_constant_override("separation", 8)
	logo = TileFace.logo_rect(30)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_box.add_child(logo)
	_name_label = UiTheme.label("Çini Ustası", 17, UiTheme.COBALT_DEEP, true)
	_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_box.add_child(_name_label)
	_row1.add_child(logo_box)
	# middle stats
	_mid = HBoxContainer.new()
	_mid.add_theme_constant_override("separation", 14)
	_mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 0)
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_name = UiTheme.label("—", 15, UiTheme.INK, true)
	_level_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_level_sub = UiTheme.label("", 12, UiTheme.INK_SOFT)
	lv.add_child(_level_name)
	lv.add_child(_level_sub)
	_mid.add_child(lv)
	_moves = UiTheme.stat("0", "")
	_par = UiTheme.stat("0", "")
	_stars_box = VBoxContainer.new()
	_stars_box.add_theme_constant_override("separation", 0)
	_stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var sc := CenterContainer.new()
	_stars = StarRow.new(3, 15)
	sc.add_child(_stars)
	sc.custom_minimum_size = Vector2(0, 21)
	_stars_box.add_child(sc)
	var cap := UiTheme.label("", 11, UiTheme.INK_SOFT, false, HORIZONTAL_ALIGNMENT_CENTER)
	cap.name = "Caption"
	_stars_box.add_child(cap)
	_mid.add_child(_moves)
	_mid.add_child(_par)
	_mid.add_child(_stars_box)
	_row1.add_child(_mid)
	# right buttons
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	_hint = IconButton.new("hint")
	_hint.pressed.connect(func() -> void: GameState.use_hint())
	_undo = IconButton.new("undo")
	_undo.pressed.connect(func() -> void: GameState.undo())
	_restart = IconButton.new("restart")
	_restart.pressed.connect(func() -> void:
		if GameState.screen == GameState.SCREEN_PLAYING:
			GameState.restart_level())
	_help = IconButton.new("help")
	_help.pressed.connect(func() -> void:
		if GameState.screen == GameState.SCREEN_PLAYING:
			GameState.show_howto(GameState.chapter_of(GameState.level_index)))
	_settings = IconButton.new("settings")
	_settings.pressed.connect(func() -> void:
		if GameState.screen == GameState.SCREEN_PLAYING:
			GameState.show_settings())
	_lang = UiTheme.button("EN", "IconButton", 40)
	_lang.custom_minimum_size = Vector2(40, 40)
	_lang.pressed.connect(func() -> void: Settings.toggle_language())
	_menu = IconButton.new("menu")
	_menu.pressed.connect(func() -> void: GameState.show_menu())
	for b in [_hint, _undo, _restart, _help, _settings, _lang, _menu]:
		right.add_child(b)
	_row1.add_child(right)
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	refresh()


func _on_resize() -> void:
	var narrow: bool = get_viewport().get_visible_rect().size.x < 640.0
	if narrow == _narrow and _mid.get_parent() != null:
		return
	_narrow = narrow
	_name_label.visible = not narrow
	if _mid.get_parent() != null:
		_mid.get_parent().remove_child(_mid)
	if narrow:
		_row2.add_child(_mid)
		_row2.visible = true
	else:
		_row1.add_child(_mid)
		_row1.move_child(_mid, 1)
		_row2.visible = false


func refresh() -> void:
	_moves.get_node("Caption").text = Loc.t("moves").to_upper()
	_par.get_node("Caption").text = Loc.t("par").to_upper()
	_stars_box.get_node("Caption").text = Loc.t("stars").to_upper()
	_lang.text = Loc.other_language().to_upper()
	_hint.tooltip_text = Loc.t("hintTip")
	_undo.tooltip_text = Loc.t("undoTip")
	_restart.tooltip_text = Loc.t("restartTip")
	_help.tooltip_text = Loc.t("howToPlay")
	_settings.tooltip_text = Loc.t("settings")
	_menu.tooltip_text = Loc.t("menuTip")
	update_stats()


func update_stats() -> void:
	if GameState.puzzle == null:
		return
	var idx: int = GameState.level_index
	_level_name.text = GameState.level_display_name(idx)
	if idx == GameState.DAILY:
		_level_sub.text = PuzzleCore.daily_key()
	else:
		_level_sub.text = "%s %d · %s %d · %d×%d" % [Loc.t("chapter"), GameState.chapter_of(idx) + 1, Loc.t("level"), idx + 1, GameState.puzzle.n, GameState.puzzle.n]
	_moves.get_node("Value").text = str(GameState.move_count())
	_par.get_node("Value").text = str(GameState.puzzle.par)
	_stars.set_filled(GameState.live_stars())
	_hint.set_badge(GameState.hints)
	_hint.slashed = GameState.hints <= 0
