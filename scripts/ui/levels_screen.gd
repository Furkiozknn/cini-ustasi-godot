class_name LevelsScreen
extends UiScreen
## Level select: three chapters of ten cards (number, stars, name) plus the daily card.

var _header: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _close: IconButton


func build() -> void:
	card_max_width = 920.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var head := HBoxContainer.new()
	_header = UiTheme.label("", 26, UiTheme.COBALT_DEEP, true)
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_header)
	_close = IconButton.new("close")
	_close.pressed.connect(func() -> void: GameState.close_overlays())
	head.add_child(_close)
	v.add_child(head)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)


func refresh() -> void:
	_header.text = Loc.t("levels")
	_close.tooltip_text = Loc.t("close")
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var narrow: bool = is_narrow()
	var cols: int = 5 if narrow else 10
	var inner_w: float = card.custom_minimum_size.x - 48.0 - 12.0
	var gap: int = 7 if narrow else 10
	var cell: float = floorf((inner_w - (cols - 1) * gap) / cols)
	var set: LevelSet = GameState.level_set
	for ch in set.chapters.size():
		var chapter: ChapterDef = set.chapters[ch]
		var sec := VBoxContainer.new()
		sec.add_theme_constant_override("separation", 2)
		var h := UiTheme.label("%s %d · %s" % [Loc.t("chapter"), ch + 1, chapter.display_name(Loc.lang)], 17, UiTheme.COBALT_DEEP, true)
		sec.add_child(h)
		var d := UiTheme.label(chapter.description(Loc.lang), 13, UiTheme.INK_SOFT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sec.add_child(d)
		sec.add_child(UiTheme.spacer(4))
		var grid := GridContainer.new()
		grid.columns = cols
		grid.add_theme_constant_override("h_separation", gap)
		grid.add_theme_constant_override("v_separation", gap)
		var first: int = set.first_index_of_chapter(ch)
		for i in chapter.levels.size():
			grid.add_child(_level_card(first + i, cell, narrow))
		sec.add_child(grid)
		if ch == 0:
			sec.add_child(UiTheme.spacer(2))
			sec.add_child(_daily_card(cell))
		_list.add_child(sec)


func _level_card(idx: int, cell: float, narrow: bool) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"LevelCard"
	b.custom_minimum_size = Vector2(cell, cell)
	b.focus_mode = Control.FOCUS_NONE
	var unlocked: bool = GameState.is_unlocked(idx)
	var best: Dictionary = GameState.best_for("L%d" % (idx + 1))
	b.disabled = not unlocked
	b.tooltip_text = ("%d. %s" % [idx + 1, GameState.level_display_name(idx)]) if unlocked else Loc.t("locked")
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unlocked:
		v.add_child(UiTheme.label(str(idx + 1), 16 if narrow else 20, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		var lock := LockIcon.new()
		lock.custom_minimum_size = Vector2(22, 22)
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(lock)
		v.add_child(holder)
	var stars := StarRow.new(int(best.get("stars", 0)), 11)
	var sh := CenterContainer.new()
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sh.add_child(stars)
	v.add_child(sh)
	if unlocked and not narrow:
		var nm := UiTheme.label(GameState.level_display_name(idx), 10, UiTheme.INK_SOFT, false, HORIZONTAL_ALIGNMENT_CENTER)
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.clip_text = true
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(nm)
	b.add_child(v)
	if GameState.puzzle != null and GameState.level_index == idx:
		var ring := StyleBoxFlat.new()
		ring.bg_color = Color(1, 1, 1, 0.85)
		ring.set_corner_radius_all(14)
		ring.set_border_width_all(3)
		ring.border_color = UiTheme.TURQ
		ring.set_content_margin_all(4)
		b.add_theme_stylebox_override("normal", ring)
		b.add_theme_stylebox_override("hover", ring)
	if unlocked:
		b.pressed.connect(func() -> void:
			Audio.play("ui")
			GameState.start_level(idx))
	return b


func _daily_card(cell: float) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"LevelCard"
	var unlocked: bool = GameState.daily_unlocked()
	b.custom_minimum_size = Vector2(cell * 2.0 + 10.0, maxf(cell, 78.0))
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not unlocked
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#cdeeea") if unlocked else Color("#d7f3f1")
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(6)
	b.add_theme_stylebox_override("normal", sb)
	var hover: StyleBoxFlat = sb.duplicate()
	hover.bg_color = Color("#dff8f5")
	b.add_theme_stylebox_override("hover", hover)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(UiTheme.label(Loc.t("dailyName"), 14, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER))
	var best: Dictionary = GameState.best_for("D" + PuzzleCore.daily_key())
	var sh := CenterContainer.new()
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sh.add_child(StarRow.new(int(best.get("stars", 0)), 11))
	v.add_child(sh)
	v.add_child(UiTheme.label(PuzzleCore.daily_key() if unlocked else Loc.t("dailyLocked"), 10, UiTheme.INK_SOFT, false, HORIZONTAL_ALIGNMENT_CENTER))
	b.add_child(v)
	if unlocked:
		b.pressed.connect(func() -> void:
			Audio.play("ui")
			GameState.start_level(GameState.DAILY))
	return b


func _layout(vp: Vector2) -> void:
	_scroll.custom_minimum_size = Vector2(0, minf(vp.y - 20.0 - 100.0, 640.0))
	if visible:
		refresh()


class LockIcon:
	extends Control

	func _draw() -> void:
		var col := Color("#8a8a98")
		draw_rect(Rect2(3, 10, 16, 11), col, false, 2.0)
		draw_arc(Vector2(11, 10), 5.0, PI, TAU, 10, col, 2.0, true)
