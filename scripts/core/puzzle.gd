class_name Puzzle
extends RefCounted
## A generated level: the tiles, the mechanics it uses, the scrambled start position and its par.

var n: int = 3
var tiles: Array[TileDef] = []
var allow_swap: bool = false
var allow_flip: bool = false
var has_fixed: bool = false
var palette: PackedInt32Array = PackedInt32Array()
var seed_value: int = 0
var def: LevelDef = null
var par: int = 0
var start: Array[SlotState] = []
## Progress key, e.g. "L12" or "D2026-10-20".
var key: String = ""


func slot_count() -> int:
	return n * n


func solution() -> Array[SlotState]:
	var sol: Array[SlotState] = []
	for i in tiles.size():
		sol.append(SlotState.new(i, 0, 0))
	return sol


func tile_kind(tile: TileDef) -> int:
	if tile.fixed:
		return PuzzleCore.KIND_FIXED
	if tile.is_two_sided():
		return PuzzleCore.KIND_FLIP
	return PuzzleCore.KIND_PLAIN
