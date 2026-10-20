class_name StarRow
extends Control
## Draws up to three gold stars (and grey placeholders) in code; can pop them in one by one.

var count: int = 3
var filled: int = 0
var star_px: float = 16.0
var gap: float = 3.0
var _pop: Array[float] = [1.0, 1.0, 1.0]


func _init(filled_stars: int = 0, px: float = 16.0, total: int = 3) -> void:
	filled = filled_stars
	star_px = px
	count = total
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_size()


func _update_size() -> void:
	custom_minimum_size = Vector2(count * star_px + (count - 1) * gap, star_px)


func set_filled(n: int) -> void:
	filled = n
	queue_redraw()


func animate() -> void:
	_pop = [0.0, 0.0, 0.0]
	queue_redraw()
	var tw := create_tween()
	tw.set_parallel(true)
	for i in count:
		tw.tween_method(func(v: float) -> void: _pop[i] = v; queue_redraw(), 0.0, 1.0, 0.45).set_delay(i * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var total_w: float = count * star_px + (count - 1) * gap
	var x0: float = (size.x - total_w) / 2.0
	for i in count:
		var centre := Vector2(x0 + i * (star_px + gap) + star_px / 2.0, size.y / 2.0)
		var r: float = star_px / 2.0 * _pop[i]
		if r <= 0.01:
			continue
		var pts := PackedVector2Array()
		for k in 10:
			var a: float = TAU * k / 10.0 - PI / 2
			var rr: float = r if k % 2 == 0 else r * 0.45
			pts.append(centre + Vector2(cos(a), sin(a)) * rr)
		if i < filled:
			var shadow := PackedVector2Array()
			for p in pts:
				shadow.append(p + Vector2(0, star_px * 0.08))
			draw_colored_polygon(shadow, Color(UiTheme.GOLD, 0.35))
			draw_colored_polygon(pts, UiTheme.GOLD)
		else:
			draw_colored_polygon(pts, Color(90.0 / 255.0, 80.0 / 255.0, 70.0 / 255.0, 0.25))
