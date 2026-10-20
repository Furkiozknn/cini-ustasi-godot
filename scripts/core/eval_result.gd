class_name EvalResult
extends RefCounted
## Result of PuzzleCore.evaluate(): matched edges encoded as slot * 4 + edge index.

var matched: PackedInt32Array = PackedInt32Array()
var solved: bool = false


func count() -> int:
	return matched.size()
