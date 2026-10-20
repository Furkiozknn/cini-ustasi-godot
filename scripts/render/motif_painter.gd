class_name MotifPainter
extends RefCounted
## Draws Iznik tile faces with CanvasItem draw calls. Each edge shows one complete motif growing
## inward from the edge midpoint, so two matching edges meet stem to stem as one medallion.
## All shapes are defined in a 256-unit tile space and scaled by a transform.

const PALETTE: PaletteDef = preload("res://resources/palette.tres")
const UNIT: float = 256.0
const INK_WIDTH: float = 4.5
const BRASS_DARK: Color = Color("#7a5214")
const BRASS: Color = Color("#d9a441")
const BRASS_LIGHT: Color = Color("#fff2c0")


## Paints a whole tile face at `origin` with side length `size` (pixels).
static func paint_tile(ci: CanvasItem, origin: Vector2, size: float, edges: PackedInt32Array, kind: int, seed_value: int) -> void:
	var u: float = size / UNIT
	var base := Transform2D(0.0, origin).scaled_local(Vector2(u, u))
	ci.draw_set_transform_matrix(base)
	_glaze_background(ci, seed_value)
	for k in 4:
		var xf := base.translated_local(Vector2(128.0, 128.0)).rotated_local(k * PI / 2.0).translated_local(Vector2(0.0, -128.0))
		ci.draw_set_transform_matrix(xf)
		_edge_motif(ci, edges[k])
	ci.draw_set_transform_matrix(base)
	_center_ornament(ci, kind)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## The frame band pattern (same lozenge chain as the border edge), `w` x `h` pixels.
static func paint_band(ci: CanvasItem, w: float, h: float) -> void:
	ci.draw_rect(Rect2(0, 0, w, h), PALETTE.cobalt)
	var strip: float = h * 0.125
	ci.draw_rect(Rect2(0, 0, w, strip), PALETTE.turquoise)
	ci.draw_rect(Rect2(0, h - strip, w, strip), PALETTE.turquoise)
	var step: float = h * 36.0 / 64.0
	var mid: float = h / 2.0
	var x: float = step / 2.0
	while x < w:
		var pts := PackedVector2Array([Vector2(x, mid - h * 0.28), Vector2(x + h * 0.17, mid), Vector2(x, mid + h * 0.28), Vector2(x - h * 0.17, mid)])
		ci.draw_colored_polygon(pts, PALETTE.cream)
		x += step
	x = 0.0
	while x <= w:
		ci.draw_circle(Vector2(x, mid), h * 0.055, PALETTE.cobalt_light)
		x += step


# ---------------------------------------------------------------- helpers

static func _quad(from: Vector2, ctrl: Vector2, to: Vector2, segs: int = 10) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(1, segs + 1):
		var t: float = float(i) / segs
		var a := from.lerp(ctrl, t)
		var b := ctrl.lerp(to, t)
		out.append(a.lerp(b, t))
	return out


static func _cubic(from: Vector2, c1: Vector2, c2: Vector2, to: Vector2, segs: int = 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(1, segs + 1):
		var t: float = float(i) / segs
		out.append(from.bezier_interpolate(c1, c2, to, t))
	return out


static func _ellipse(center: Vector2, rx: float, ry: float, rot: float, segs: int = 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in segs:
		var a: float = TAU * i / segs
		var p := Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)
		out.append(center + p)
	return out


## Filled shape with an ink outline. Two draw calls per shape: every 2D polygon is its own GPU draw
## call in the Compatibility renderer, so the painter stays frugal.
static func _fill_stroke(ci: CanvasItem, pts: PackedVector2Array, fill: Color, width: float = INK_WIDTH) -> void:
	ci.draw_colored_polygon(pts, fill)
	if width > 0.0:
		var closed := PackedVector2Array(pts)
		closed.append(pts[0])
		closed.append(pts[1])
		ci.draw_polyline(closed, PALETTE.ink, width, true)


static func _append(pts: PackedVector2Array, more: PackedVector2Array) -> void:
	for p in more:
		pts.append(p)


# ---------------------------------------------------------------- motifs (edge-local: x along the edge, y inward)

static func _tulip(ci: CanvasItem, c: int) -> void:
	var fill := PALETTE.fill(c)
	var dark := PALETTE.dark(c)
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(s * 26, 2)])
		_append(pts, _quad(Vector2(s * 26, 2), Vector2(s * 56, -2), Vector2(s * 74, 16)))
		_append(pts, _quad(Vector2(s * 74, 16), Vector2(s * 52, 26), Vector2(s * 28, 18)))
		_fill_stroke(ci, pts, dark)
	var bud := PackedVector2Array([Vector2(-32, -2)])
	_append(bud, _quad(Vector2(-32, -2), Vector2(-44, 30), Vector2(-31, 60)))
	_append(bud, _quad(Vector2(-31, 60), Vector2(-31, 74), Vector2(-29, 86), 5))
	_append(bud, _quad(Vector2(-29, 86), Vector2(-15, 72), Vector2(-9, 58), 6))
	_append(bud, _quad(Vector2(-9, 58), Vector2(-4, 90), Vector2(0, 108)))
	_append(bud, _quad(Vector2(0, 108), Vector2(4, 90), Vector2(9, 58)))
	_append(bud, _quad(Vector2(9, 58), Vector2(15, 72), Vector2(29, 86), 6))
	_append(bud, _quad(Vector2(29, 86), Vector2(31, 74), Vector2(31, 60), 5))
	_append(bud, _quad(Vector2(31, 60), Vector2(44, 30), Vector2(32, -2)))
	_fill_stroke(ci, bud, fill)
	ci.draw_colored_polygon(_ellipse(Vector2(-15, 30), 5, 15, 0.12), Color(1, 1, 1, 0.5))


static func _carnation(ci: CanvasItem, c: int) -> void:
	var fill := PALETTE.fill(c)
	var dark := PALETTE.dark(c)
	var cy: float = -14.0
	var r: float = 62.0
	var teeth: int = 11
	var pts := PackedVector2Array()
	for i in range(teeth + 1):
		var a: float = PI - (float(i) / teeth) * PI
		var rr: float = r if i % 2 == 1 else r - 10.0
		pts.append(Vector2(cos(a) * rr, cy + sin(a) * rr))
	_fill_stroke(ci, pts, fill)
	for a in [-0.7, -0.35, 0.0, 0.35, 0.7]:
		ci.draw_line(Vector2(sin(a) * 10.0, 2.0), Vector2(sin(a) * 46.0, cy + cos(a) * 54.0), Color(1, 1, 1, 0.75), 3.0, true)
	_fill_stroke(ci, PackedVector2Array([Vector2(-17, 40), Vector2(17, 40), Vector2(11, 70), Vector2(-11, 70)]), dark)
	ci.draw_line(Vector2(0, 70), Vector2(0, 98), dark, 7.0, true)
	ci.draw_circle(Vector2(0, 98), 3.5, dark)


static func _saz_w(y: float) -> float:
	return 42.0 * pow(maxf(0.0, 1.0 - y / 104.0), 0.75)


static func _saz(ci: CanvasItem, c: int) -> void:
	var fill := PALETTE.fill(c)
	var pts := PackedVector2Array([Vector2(-44, -2)])
	for i in range(1, 7):
		var y: float = i * 16.0
		var w: float = _saz_w(y)
		pts.append(Vector2(-w - 9.0, y - 7.0))
		pts.append(Vector2(-w, y))
	pts.append(Vector2(0, 106))
	for i in range(6, 0, -1):
		var y: float = i * 16.0
		var w: float = _saz_w(y)
		pts.append(Vector2(w, y))
		pts.append(Vector2(w + 9.0, y - 7.0))
	pts.append(Vector2(44, -2))
	_fill_stroke(ci, pts, fill)
	ci.draw_line(Vector2(0, 4), Vector2(0, 88), Color(1, 1, 1, 0.8), 3.5, true)
	for i in range(1, 5):
		var y: float = i * 18.0
		var w: float = _saz_w(y) * 0.6
		ci.draw_polyline(PackedVector2Array([Vector2(-w, y - 10.0), Vector2(0, y), Vector2(w, y - 10.0)]), Color(1, 1, 1, 0.8), 2.5, true)


static func _rumi(ci: CanvasItem, c: int) -> void:
	var fill := PALETTE.fill(c)
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(0, 4)])
		_append(pts, _cubic(Vector2(0, 4), Vector2(s * 30, -4), Vector2(s * 66, -2), Vector2(s * 70, 22)))
		_append(pts, _cubic(Vector2(s * 70, 22), Vector2(s * 72, 40), Vector2(s * 54, 48), Vector2(s * 48, 36), 8))
		_append(pts, _cubic(Vector2(s * 48, 36), Vector2(s * 46, 28), Vector2(s * 56, 24), Vector2(s * 58, 30), 6))
		_append(pts, _cubic(Vector2(s * 58, 30), Vector2(s * 54, 14), Vector2(s * 30, 14), Vector2(0, 26)))
		_fill_stroke(ci, pts, fill)
	var bud := PackedVector2Array([Vector2(-19, 8)])
	_append(bud, _quad(Vector2(-19, 8), Vector2(-26, 52), Vector2(0, 102)))
	_append(bud, _quad(Vector2(0, 102), Vector2(26, 52), Vector2(19, 8)))
	_append(bud, _quad(Vector2(19, 8), Vector2(0, -2), Vector2(-19, 8), 6))
	_fill_stroke(ci, bud, fill)
	ci.draw_colored_polygon(_ellipse(Vector2(-5, 40), 4, 18, 0.1), Color(1, 1, 1, 0.6))


static func _rosette(ci: CanvasItem, c: int) -> void:
	var fill := PALETTE.fill(c)
	var dark := PALETTE.dark(c)
	var cy: float = 34.0
	var r: float = 30.0
	var petals: int = 8
	var leaf := PackedVector2Array([Vector2(-10, 62)])
	_append(leaf, _quad(Vector2(-10, 62), Vector2(-11, 86), Vector2(0, 100)))
	_append(leaf, _quad(Vector2(0, 100), Vector2(11, 86), Vector2(10, 62)))
	_fill_stroke(ci, leaf, dark)
	var pts := PackedVector2Array()
	for i in petals:
		var a0: float = TAU * i / petals
		var a1: float = TAU * (i + 0.5) / petals
		var a2: float = TAU * (i + 1) / petals
		var p0 := Vector2(cos(a0) * r * 0.84, cy + sin(a0) * r * 0.84)
		var p1 := Vector2(cos(a1) * r * 1.3, cy + sin(a1) * r * 1.3)
		var p2 := Vector2(cos(a2) * r * 0.84, cy + sin(a2) * r * 0.84)
		if i == 0:
			pts.append(p0)
		_append(pts, _quad(p0, p1, p2, 6))
	_fill_stroke(ci, pts, fill)
	ci.draw_arc(Vector2(0, cy), r * 0.52, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 3.5, true)
	ci.draw_circle(Vector2(0, cy), r * 0.26, dark)


static func _border_band(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(-128, 0, 256, 32), PALETTE.cobalt)
	ci.draw_rect(Rect2(-128, 32, 256, 6), PALETTE.turquoise)
	var x: float = -128.0 + 18.0
	while x < 128.0:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, 5), Vector2(x + 11, 16), Vector2(x, 27), Vector2(x - 11, 16)]), PALETTE.cream)
		x += 36.0
	var dots := PackedVector2Array()
	x = -128.0
	while x < 128.0:
		dots.append(Vector2(x - 3.0, 16))
		dots.append(Vector2(x + 3.0, 16))
		x += 36.0
	ci.draw_multiline(dots, PALETTE.cobalt_light, 6.0)


static func _edge_motif(ci: CanvasItem, id: int) -> void:
	if id == PuzzleCore.BORDER:
		_border_band(ci)
		return
	var c: int = PuzzleCore.motif_color(id)
	match PuzzleCore.motif_shape(id):
		0: _tulip(ci, c)
		1: _carnation(ci, c)
		2: _saz(ci, c)
		3: _rumi(ci, c)
		_: _rosette(ci, c)


# ---------------------------------------------------------------- background and centre

static func _glaze_background(ci: CanvasItem, seed_value: int) -> void:
	ci.draw_rect(Rect2(0, 0, 256, 256), PALETTE.glaze_edge)
	# soft radial highlight faked with three concentric discs
	var centre := Vector2(256 * 0.45, 256 * 0.4)
	var steps: int = 3
	for i in steps:
		var t: float = float(i + 1) / steps
		var rad: float = lerpf(190.0, 60.0, t)
		var col: Color = PALETTE.glaze_edge.lerp(PALETTE.glaze, t)
		ci.draw_circle(centre, rad, col)
	# a few glaze speckles, drawn as one multi-segment line (one draw call)
	var rng := Mulberry32.new(seed_value if seed_value != 0 else 7)
	var speck := Color(80.0 / 255.0, 70.0 / 255.0, 50.0 / 255.0, 0.09)
	var segs := PackedVector2Array()
	for i in 14:
		var x: float = rng.next() * 256.0
		var y: float = rng.next() * 256.0
		var r: float = rng.next() * 1.4 + 0.6
		segs.append(Vector2(x - r, y))
		segs.append(Vector2(x + r, y))
	ci.draw_multiline(segs, speck, 2.0)


static func _center_ornament(ci: CanvasItem, kind: int) -> void:
	var c := Vector2(128, 128)
	if kind == PuzzleCore.KIND_FIXED:
		ci.draw_circle(c + Vector2(2, 3), 15.0, Color(0, 0, 0, 0.25))
		ci.draw_circle(c, 14.0, BRASS_DARK)
		ci.draw_circle(c - Vector2(1.5, 1.5), 11.0, BRASS)
		ci.draw_circle(c - Vector2(4, 4), 6.0, BRASS_LIGHT)
		ci.draw_line(c - Vector2(7, 0), c + Vector2(7, 0), Color("#5a3a0c"), 2.0, true)
		return
	if kind == PuzzleCore.KIND_FLIP:
		var r: float = 13.0
		for s in [0.0, PI]:
			ci.draw_arc(c, r, s + 0.35, s + PI - 0.5, 14, PALETTE.ink, 3.5, true)
			var a: float = s + PI - 0.5
			var tip := c + Vector2(cos(a), sin(a)) * r
			var head := PackedVector2Array([tip, tip + Vector2(cos(a + 1.9), sin(a + 1.9)) * 7.0, tip + Vector2(cos(a + 0.6), sin(a + 0.6)) * 8.0])
			ci.draw_colored_polygon(head, PALETTE.ink)
		return
	var star := PackedVector2Array()
	for i in 16:
		var a: float = TAU * i / 16.0
		var rr: float = 3.0 if i % 2 == 1 else 8.0
		star.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(star, Color(PALETTE.turquoise, 0.55))
