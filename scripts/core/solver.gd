class_name Solver
extends RefCounted
## Backtracking solver over the live board state. Used for hints, for the autoplay bot and by the tests.
## Candidate order keeps the tile already in a slot (and its current orientation) first, so hints stay
## close to what the player has done.

var nodes: int = 0
var aborted: bool = false

var _n: int = 0
var _total: int = 0
var _tile_count: int = 0
var _node_limit: int = 6000000
var _pos_locked: bool = false
var _orient_count: PackedInt32Array = PackedInt32Array()
var _orient_edges: PackedInt32Array = PackedInt32Array() # [(t * 8 + o) * 4 + k]
var _assign_t: PackedInt32Array = PackedInt32Array()
var _assign_o: PackedInt32Array = PackedInt32Array()
var _assign_e: PackedInt32Array = PackedInt32Array() # [p * 4 + k]
var _used: PackedByteArray = PackedByteArray()
var _fixed: PackedByteArray = PackedByteArray()
var _slot_t: PackedInt32Array = PackedInt32Array()
var _slot_o: PackedInt32Array = PackedInt32Array()


## Returns the solved slot list, or an empty array when no solution was found within the node limit.
func solve(pz: Puzzle, slots: Array[SlotState], node_limit: int = 6000000) -> Array[SlotState]:
	_n = pz.n
	_total = _n * _n
	_tile_count = pz.tiles.size()
	_node_limit = node_limit
	_pos_locked = not pz.allow_swap
	nodes = 0
	aborted = false
	_orient_count.resize(_tile_count)
	_orient_edges.resize(_tile_count * 8 * 4)
	_fixed.resize(_tile_count)
	for t in _tile_count:
		var td: TileDef = pz.tiles[t]
		_fixed[t] = 1 if td.fixed else 0
		_orient_count[t] = td.faces.size() * 4
		for f in td.faces.size():
			for r in 4:
				var e := PuzzleCore.rot_edges(td.faces[f], r)
				var base: int = (t * 8 + f * 4 + r) * 4
				for k in 4:
					_orient_edges[base + k] = e[k]
	_assign_t.resize(_total)
	_assign_o.resize(_total)
	_assign_e.resize(_total * 4)
	_used.resize(_tile_count)
	_slot_t.resize(_total)
	_slot_o.resize(_total)
	for p in _total:
		_assign_t[p] = -1
	for t in _tile_count:
		_used[t] = 0
	for p in _total:
		var s: SlotState = slots[p]
		_slot_t[p] = s.t
		_slot_o[p] = s.face * 4 + s.rot
		if pz.tiles[s.t].fixed:
			_place(p, s.t, s.face * 4 + s.rot)
	var ok: bool = _rec(0)
	var out: Array[SlotState] = []
	if not ok:
		return out
	for p in _total:
		out.append(SlotState.new(_assign_t[p], _assign_o[p] % 4, _assign_o[p] >> 2))
	return out


func _place(p: int, t: int, o: int) -> void:
	_assign_t[p] = t
	_assign_o[p] = o
	var base: int = (t * 8 + o) * 4
	for k in 4:
		_assign_e[p * 4 + k] = _orient_edges[base + k]
	_used[t] = 1


func _fits(p: int, base: int) -> bool:
	@warning_ignore("integer_division")
	var r: int = p / _n
	var c: int = p % _n
	var e0: int = _orient_edges[base]
	var e1: int = _orient_edges[base + 1]
	var e2: int = _orient_edges[base + 2]
	var e3: int = _orient_edges[base + 3]
	if r == 0:
		if e0 != 0:
			return false
	else:
		if e0 == 0:
			return false
		var up: int = p - _n
		if _assign_t[up] >= 0 and _assign_e[up * 4 + 2] != e0:
			return false
	if c == 0:
		if e3 != 0:
			return false
	else:
		if e3 == 0:
			return false
		var left: int = p - 1
		if _assign_t[left] >= 0 and _assign_e[left * 4 + 1] != e3:
			return false
	if c == _n - 1:
		if e1 != 0:
			return false
	else:
		if e1 == 0:
			return false
		var right: int = p + 1
		if _assign_t[right] >= 0 and _assign_e[right * 4 + 3] != e1:
			return false
	if r == _n - 1:
		if e2 != 0:
			return false
	else:
		if e2 == 0:
			return false
		var down: int = p + _n
		if _assign_t[down] >= 0 and _assign_e[down * 4 + 0] != e2:
			return false
	return true


func _try_tile(p: int, t: int) -> bool:
	var count: int = _orient_count[t]
	var start: int = _slot_o[p] if t == _slot_t[p] else 0
	if start >= count:
		start = 0
	for j in count:
		var o: int = (start + j) % count
		nodes += 1
		if nodes > _node_limit:
			aborted = true
			return false
		var base: int = (t * 8 + o) * 4
		if not _fits(p, base):
			continue
		_place(p, t, o)
		if _rec(p + 1):
			return true
		_assign_t[p] = -1
		_used[t] = 0
		if aborted:
			return false
	return false


func _rec(p: int) -> bool:
	if p == _total:
		return true
	if _assign_t[p] >= 0:
		return _rec(p + 1)
	var cur: int = _slot_t[p]
	if _pos_locked:
		return _try_tile(p, cur)
	if _used[cur] == 0 and _fixed[cur] == 0:
		if _try_tile(p, cur):
			return true
		if aborted:
			return false
	for t in _tile_count:
		if t == cur or _used[t] == 1 or _fixed[t] == 1:
			continue
		if _try_tile(p, t):
			return true
		if aborted:
			return false
	return false
