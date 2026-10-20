class_name TileFace
extends Control
## A Control that paints one tile face. Used inside the texture baker's viewports and directly in the UI.

var edges: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
var kind: int = PuzzleCore.KIND_PLAIN
var seed_value: int = 7


func _init(face_edges: PackedInt32Array = PackedInt32Array([0, 0, 0, 0]), face_kind: int = PuzzleCore.KIND_PLAIN, face_seed: int = 7) -> void:
	edges = face_edges
	kind = face_kind
	seed_value = face_seed
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	MotifPainter.paint_tile(self, Vector2.ZERO, minf(size.x, size.y), edges, kind, seed_value)


## The logo tile: tulip, carnation, rosette and rumi in four colours.
static func logo(px: float) -> TileFace:
	var f := TileFace.new(PackedInt32Array([1 + 0 * 4 + 2, 1 + 1 * 4 + 1, 1 + 4 * 4 + 0, 1 + 3 * 4 + 3]), PuzzleCore.KIND_PLAIN, 3)
	f.custom_minimum_size = Vector2(px, px)
	f.size = Vector2(px, px)
	return f


## A `px`-sized rect for the baked logo texture (TextureBaker.bake_logo): one draw call instead of
## the vector drawing above being re-issued every frame.
static func logo_rect(px: float) -> TextureRect:
	var r := TextureRect.new()
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
