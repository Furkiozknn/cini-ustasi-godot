class_name Mulberry32
extends RefCounted
## Deterministic 32-bit PRNG (same algorithm as the round-1 browser version),
## so a level seed always produces the same board.

var _a: int = 0


func _init(seed_value: int) -> void:
	_a = seed_value & 0xFFFFFFFF


## 32-bit multiply with wrap-around (JavaScript Math.imul semantics).
static func imul(x: int, y: int) -> int:
	x &= 0xFFFFFFFF
	y &= 0xFFFFFFFF
	var lo: int = (x & 0xFFFF) * y
	var hi: int = (((x >> 16) & 0xFFFF) * y) & 0xFFFF
	return (lo + (hi << 16)) & 0xFFFFFFFF


## FNV-1a hash of a string, 32-bit.
static func hash_str(s: String) -> int:
	var h: int = 2166136261
	for i in s.length():
		h ^= s.unicode_at(i)
		h = imul(h, 16777619)
	return h & 0xFFFFFFFF


## Next float in [0, 1).
func next() -> float:
	_a = (_a + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = _a
	t = imul(t ^ (t >> 15), t | 1)
	t = (t ^ ((t + imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


## Integer in [0, n).
func next_int(n: int) -> int:
	return int(next() * n)


## Fisher-Yates shuffle in place; returns the same array for chaining.
func shuffle(arr: Array) -> Array:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = int(next() * (i + 1))
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr
