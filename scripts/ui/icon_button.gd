class_name IconButton
extends Button
## A 44x44 glass button with a vector icon drawn in code (no font glyph dependency) and an optional badge.

var kind: String = "menu"
var badge: int = -1
var slashed: bool = false


func _init(icon_kind: String, tooltip: String = "") -> void:
	kind = icon_kind
	theme_type_variation = &"IconButton"
	custom_minimum_size = Vector2(UiTheme.MIN_TOUCH, UiTheme.MIN_TOUCH)
	focus_mode = Control.FOCUS_ALL
	tooltip_text = tooltip
	pressed.connect(func() -> void:
		Audio.play("ui")
		UiTheme.release_pointer_focus(self))


func set_badge(n: int) -> void:
	badge = n
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var col: Color = get_theme_color("font_disabled_color") if disabled else get_theme_color("font_color")
	var w: float = 2.0
	match kind:
		"hint":
			_star4(c + Vector2(-2, 1), 8.0, col)
			_star4(c + Vector2(7, -7), 3.5, col)
		"undo":
			draw_arc(c + Vector2(1, 1), 6.5, -PI / 2, PI * 0.85, 16, col, w, true)
			var tip := c + Vector2(1, 1) + Vector2(cos(-PI / 2), sin(-PI / 2)) * 6.5
			draw_polyline(PackedVector2Array([tip + Vector2(0, -4), tip + Vector2(-4, 0), tip + Vector2(0, 4)]), col, w, true)
		"restart":
			draw_arc(c, 7.0, -PI * 0.75, PI * 1.05, 18, col, w, true)
			var tip := c + Vector2(cos(-PI * 0.75), sin(-PI * 0.75)) * 7.0
			draw_polyline(PackedVector2Array([tip + Vector2(-4, 0), tip + Vector2(0, 0), tip + Vector2(0, 4)]), col, w, true)
		"help":
			draw_arc(c, 9.0, 0, TAU, 24, col, w, true)
			var font: Font = UiTheme.bold_font()
			draw_string(font, c + Vector2(-9, 5), "?", HORIZONTAL_ALIGNMENT_CENTER, 18, 14, col)
		"settings":
			for i in 8:
				var a: float = TAU * i / 8.0
				var dir := Vector2(cos(a), sin(a))
				draw_line(c + dir * 5.0, c + dir * 10.0, col, 3.0, true)
			draw_arc(c, 6.5, 0, TAU, 24, col, 2.5, true)
			draw_circle(c, 2.5, col)
		"menu":
			for dy in [-6.0, 0.0, 6.0]:
				draw_line(c + Vector2(-8, dy), c + Vector2(8, dy), col, w, true)
		"close":
			draw_line(c + Vector2(-6, -6), c + Vector2(6, 6), col, w, true)
			draw_line(c + Vector2(6, -6), c + Vector2(-6, 6), col, w, true)
		"back":
			draw_polyline(PackedVector2Array([c + Vector2(3, -7), c + Vector2(-4, 0), c + Vector2(3, 7)]), col, w, true)
		"sound":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -3), c + Vector2(-5, -3), c + Vector2(0, -8), c + Vector2(0, 8), c + Vector2(-5, 3), c + Vector2(-9, 3)]), col)
			draw_arc(c + Vector2(1, 0), 5.0, -0.9, 0.9, 8, col, w, true)
			draw_arc(c + Vector2(1, 0), 9.0, -0.9, 0.9, 10, col, w, true)
		"music":
			draw_line(c + Vector2(-3, 6), c + Vector2(-3, -7), col, w, true)
			draw_line(c + Vector2(7, 4), c + Vector2(7, -9), col, w, true)
			draw_line(c + Vector2(-3, -7), c + Vector2(7, -9), col, 3.0, true)
			draw_circle(c + Vector2(-6, 6), 3.2, col)
			draw_circle(c + Vector2(4, 4), 3.2, col)
		_:
			draw_circle(c, 6.0, col)
	if slashed:
		draw_line(c + Vector2(-9, 7), c + Vector2(9, -7), Color("#c1444a"), 2.5, true)
	if badge >= 0:
		var bc := Vector2(size.x - 4, 4)
		draw_circle(bc, 9.0, UiTheme.CORAL)
		draw_string(UiTheme.bold_font(), bc + Vector2(-9, 4), str(badge), HORIZONTAL_ALIGNMENT_CENTER, 18, 11, Color.WHITE)


func _star4(centre: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a: float = TAU * i / 8.0 - PI / 2
		var rr: float = r if i % 2 == 0 else r * 0.38
		pts.append(centre + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
