class_name HowtoScreen
extends UiScreen
## "How to play" card shown at the start of each chapter (and from the help button).

const ICON_COLORS: Array[Color] = [UiTheme.COBALT, UiTheme.TURQ, UiTheme.CORAL, UiTheme.GOLD]

var _title: Label
var _lines: VBoxContainer
var _ok: Button


func build() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	_title = UiTheme.label("", 26, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 6)
	v.add_child(_lines)
	var row := UiTheme.row()
	_ok = UiTheme.button("", "")
	_ok.pressed.connect(func() -> void: GameState.dismiss_howto())
	row.add_child(_ok)
	v.add_child(row)


func refresh() -> void:
	var h: Dictionary = Loc.howto(GameState.howto_chapter)
	_title.text = h["title"]
	_ok.text = Loc.t("start")
	for c in _lines.get_children():
		_lines.remove_child(c)
		c.queue_free()
	var lines: Array = h["lines"]
	for i in lines.size():
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 12)
		var ic := Icon.new()
		ic.index = i
		ic.color = ICON_COLORS[i % ICON_COLORS.size()]
		ic.custom_minimum_size = Vector2(42, 42)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(ic)
		var l := UiTheme.wrapped(lines[i], 15, UiTheme.INK, HORIZONTAL_ALIGNMENT_LEFT)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item.add_child(l)
		_lines.add_child(item)
		if i < lines.size() - 1:
			var sep := ColorRect.new()
			sep.color = Color(UiTheme.COBALT, 0.15)
			sep.custom_minimum_size = Vector2(0, 1)
			_lines.add_child(sep)


class Icon:
	extends Control
	var index: int = 0
	var color: Color = UiTheme.COBALT

	func _draw() -> void:
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(color, 0.12)
		bg.set_corner_radius_all(12)
		draw_style_box(bg, Rect2(Vector2.ZERO, size))
		var c: Vector2 = size / 2.0
		match index % 4:
			0:
				draw_arc(c, 10.0, -PI * 0.6, PI * 1.2, 18, color, 2.5, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(4, -12), c + Vector2(11, -8), c + Vector2(4, -3)]), color)
			1:
				draw_rect(Rect2(c + Vector2(-12, -12), Vector2(10, 10)), color, false, 2.0)
				draw_rect(Rect2(c + Vector2(2, 2), Vector2(10, 10)), color, false, 2.0)
				draw_line(c + Vector2(-2, -7), c + Vector2(7, -7), color, 2.0, true)
				draw_line(c + Vector2(7, -7), c + Vector2(7, -1), color, 2.0, true)
			2:
				draw_rect(Rect2(c + Vector2(-12, -12), Vector2(24, 24)), color, false, 2.0)
				draw_line(c + Vector2(-12, 0), c + Vector2(12, 0), color, 2.0, true)
			_:
				var pts := PackedVector2Array()
				for k in 8:
					var a: float = TAU * k / 8.0 - PI / 2
					var r: float = 12.0 if k % 2 == 0 else 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * r)
				draw_colored_polygon(pts, color)
