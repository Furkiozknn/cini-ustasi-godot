class_name Move
extends RefCounted
## A player action. HINT wraps several primitive moves that count as one history entry.

enum Type { ROT, SWAP, FLIP, HINT }

var type: Type = Type.ROT
var p: int = 0
var a: int = 0
var b: int = 0
var moves: Array[Move] = []


static func rot(slot: int) -> Move:
	var m := Move.new()
	m.type = Type.ROT
	m.p = slot
	return m


static func swap(slot_a: int, slot_b: int) -> Move:
	var m := Move.new()
	m.type = Type.SWAP
	m.a = slot_a
	m.b = slot_b
	return m


static func flip(slot: int) -> Move:
	var m := Move.new()
	m.type = Type.FLIP
	m.p = slot
	return m


static func hint(list: Array[Move]) -> Move:
	var m := Move.new()
	m.type = Type.HINT
	m.moves = list
	return m


## Number of primitive moves this entry counts for.
func count() -> int:
	return moves.size() if type == Type.HINT else 1


func to_dict() -> Dictionary:
	match type:
		Type.ROT:
			return {"type": "rot", "p": p}
		Type.SWAP:
			return {"type": "swap", "a": a, "b": b}
		Type.FLIP:
			return {"type": "flip", "p": p}
		_:
			var sub: Array = []
			for m in moves:
				sub.append(m.to_dict())
			return {"type": "hint", "moves": sub}
