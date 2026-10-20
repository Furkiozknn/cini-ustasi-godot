class_name CollectionScreen
extends UiScreen
## The player's collection: every fired panel in a wooden frame with its name and stars.

var baker: TextureBaker
var _header: Label
var _scroll: ScrollContainer
var _grid: GridContainer
var _empty: Label
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
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(inner)
	_empty = UiTheme.wrapped("", 15)
	_empty.custom_minimum_size = Vector2(0, 80)
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inner.add_child(_empty)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_grid)


func refresh() -> void:
	_header.text = Loc.t("collection")
	_close.tooltip_text = Loc.t("close")
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var list: Array = GameState.progress["collection"].duplicate()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["ts"]) < int(b["ts"]))
	_empty.visible = list.is_empty()
	_empty.text = Loc.t("emptyCollection")
	var inner_w: float = card.custom_minimum_size.x - 48.0 - 12.0
	var cols: int = maxi(2, int(inner_w / 144.0))
	_grid.columns = cols
	var px: float = floorf(minf(112.0, (inner_w - (cols - 1) * 14.0) / cols - 16.0))
	for e in list:
		_grid.add_child(_piece(e, px))


func _piece(e: Dictionary, px: float) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var holder := CenterContainer.new()
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"PictureFrame"
	# baked texture rather than a live drawing: thirty live board paintings would mean tens of
	# thousands of 2D draw calls per frame
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(px, px)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(pic)
	holder.add_child(frame)
	v.add_child(holder)
	_load_picture(pic, e)
	var idx: int = int(e["idx"])
	var caption: String = ("%s %s" % [Loc.t("dailyName"), str(e["key"]).substr(1)]) if idx == GameState.DAILY else ("%d. %s" % [idx + 1, GameState.level_display_name(idx)])
	var cap := UiTheme.label(caption, 12, UiTheme.INK, true, HORIZONTAL_ALIGNMENT_CENTER)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(cap)
	var sh := CenterContainer.new()
	sh.add_child(StarRow.new(int(e["stars"]), 12))
	v.add_child(sh)
	return v


func _load_picture(rect: TextureRect, e: Dictionary) -> void:
	var pz: Puzzle = GameState.puzzle_for_entry(e)
	pz.key = str(e["key"])
	var tex: Texture2D = await baker.bake_board_picture(pz, 128 if Settings.is_low_quality() else 256)
	if is_instance_valid(rect):
		rect.texture = tex


func _layout(vp: Vector2) -> void:
	_scroll.custom_minimum_size = Vector2(0, minf(vp.y - 20.0 - 100.0, 640.0))
	if visible:
		refresh()
