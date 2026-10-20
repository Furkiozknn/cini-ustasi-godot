class_name WoodFace
extends Control
## Paints a wood grain texture for the table top: streaks with a little waviness, a few light bands.


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s: float = size.x
	draw_rect(Rect2(0, 0, s, size.y), Color("#9c6a3e"))
	var rng := Mulberry32.new(99)
	for i in 90:
		var y: float = rng.next() * size.y
		var col := Color((60.0 + rng.next() * 40.0) / 255.0, (30.0 + rng.next() * 25.0) / 255.0, (10.0 + rng.next() * 15.0) / 255.0, 0.12 + rng.next() * 0.2)
		var width: float = 1.0 + rng.next() * 3.0
		var pts := PackedVector2Array()
		var x: float = 0.0
		var amp: float = 4.0 * rng.next()
		while x <= s:
			pts.append(Vector2(x, y + sin(x / 50.0 + i) * amp))
			x += 32.0
		draw_polyline(pts, col, width, true)
	for i in 6:
		draw_rect(Rect2(0, rng.next() * size.y, s, 20.0 + rng.next() * 40.0), Color(1.0, 220.0 / 255.0, 170.0 / 255.0, 0.06))
