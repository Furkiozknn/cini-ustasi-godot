class_name SlotState
extends RefCounted
## What sits in one board slot: which tile, its rotation (quarter turns clockwise) and which face is up.

var t: int = 0
var rot: int = 0
var face: int = 0


func _init(tile: int = 0, rotation: int = 0, face_index: int = 0) -> void:
	t = tile
	rot = rotation
	face = face_index


func clone() -> SlotState:
	return SlotState.new(t, rot, face)


func equals(other: SlotState) -> bool:
	return t == other.t and rot == other.rot and face == other.face


static func clone_list(list: Array[SlotState]) -> Array[SlotState]:
	var out: Array[SlotState] = []
	for s in list:
		out.append(s.clone())
	return out
