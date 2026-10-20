class_name TileDef
extends RefCounted
## One physical tile of a puzzle: its faces (edge motif ids, clockwise from the top)
## and whether it is nailed down.

var id: int = 0
var home: int = 0
## faces[0] is the real face; faces[1] (if present) is the decoy back of a double-sided tile.
var faces: Array[PackedInt32Array] = []
var fixed: bool = false


func is_two_sided() -> bool:
	return faces.size() > 1
