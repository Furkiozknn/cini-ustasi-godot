class_name BoardPicture
extends Control
## Paints a solved board as one square picture (kiln output, wall gallery, collection, complete card).

const BACKGROUND: Color = Color("#1c2a44")

var puzzle: Puzzle = null


func _init(pz: Puzzle = null, px: float = 128.0) -> void:
	puzzle = pz
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_puzzle(pz: Puzzle) -> void:
	puzzle = pz
	queue_redraw()


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	draw_rect(Rect2(0, 0, s, s), BACKGROUND)
	if puzzle == null:
		return
	var n: int = puzzle.n
	var cell: float = s / n
	var gap: float = maxf(1.0, cell * 0.03)
	for p in n * n:
		var td: TileDef = puzzle.tiles[p]
		@warning_ignore("integer_division")
		var r: int = p / n
		var c: int = p % n
		MotifPainter.paint_tile(self, Vector2(c * cell + gap / 2.0, r * cell + gap / 2.0), cell - gap, td.faces[0], puzzle.tile_kind(td), 11 + p)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	# thin grout lines on top so motif overshoot never bleeds into a neighbour
	for i in range(1, n):
		draw_rect(Rect2(i * cell - gap / 2.0, 0, gap, s), BACKGROUND)
		draw_rect(Rect2(0, i * cell - gap / 2.0, s, gap), BACKGROUND)
