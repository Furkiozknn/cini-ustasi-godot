class_name BandFace
extends Control
## Paints the frame band pattern (tiled along the board frame bars).


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	MotifPainter.paint_band(self, size.x, size.y)
