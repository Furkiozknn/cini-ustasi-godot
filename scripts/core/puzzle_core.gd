class_name PuzzleCore
extends RefCounted
## Pure puzzle rules: motif ids, level generation, evaluation, move planning and scoring.
## No nodes, no rendering, so the headless tests can exercise everything here.

const SHAPES: PackedStringArray = ["tulip", "carnation", "saz", "rumi", "rosette"]
const COLORS: PackedStringArray = ["cobalt", "turquoise", "coral", "emerald"]
const BORDER: int = 0

const KIND_PLAIN: int = 0
const KIND_FIXED: int = 1
const KIND_FLIP: int = 2

const LEVEL_COUNT: int = 30
const DAILY_INDEX: int = -1


## Motif id 0 is the border band; inner motif id = 1 + shape * 4 + colour.
static func motif_shape(id: int) -> int:
	return (id - 1) >> 2


static func motif_color(id: int) -> int:
	return (id - 1) % 4


static func rot_edges(base: PackedInt32Array, rot: int) -> PackedInt32Array:
	var e := PackedInt32Array([0, 0, 0, 0])
	for k in 4:
		e[k] = base[(k - rot + 4) % 4]
	return e


## Smallest rotation key of a face: equal keys mean the faces are rotations of each other.
static func canon_key(edges: PackedInt32Array) -> String:
	var best: String = ""
	for r in 4:
		var rotated := rot_edges(edges, r)
		var k: String = "%d,%d,%d,%d" % [rotated[0], rotated[1], rotated[2], rotated[3]]
		if best == "" or k < best:
			best = k
	return best


static func is_symmetric(e: PackedInt32Array) -> bool:
	return e[0] == e[2] and e[1] == e[3]


## Pick m motif ids: colours spread round-robin so small palettes have one shape per colour.
static func pick_palette(rng: Mulberry32, m: int) -> PackedInt32Array:
	var colors: Array = rng.shuffle([0, 1, 2, 3])
	var per_color: Array = []
	for i in 4:
		per_color.append(rng.shuffle([0, 1, 2, 3, 4]))
	var pal := PackedInt32Array()
	for i in m:
		var c: int = colors[i % 4]
		var s: int = per_color[i % 4][i >> 2]
		pal.append(1 + s * 4 + c)
	return pal


## Build a level: solved board first, then scramble. Deterministic for a given seed.
static func generate_level(def: LevelDef, seed_value: int) -> Puzzle:
	var rng := Mulberry32.new(seed_value)
	var n: int = def.n
	var total: int = n * n
	var palette := pick_palette(rng, def.m)
	var tiles: Array[TileDef] = []
	for attempt in 400:
		var h: Array[PackedInt32Array] = []
		var v: Array[PackedInt32Array] = []
		for r in n + 1:
			var row := PackedInt32Array()
			for c in n:
				row.append(BORDER if (r == 0 or r == n) else palette[rng.next_int(palette.size())])
			h.append(row)
		for r in n:
			var row := PackedInt32Array()
			for c in n + 1:
				row.append(BORDER if (c == 0 or c == n) else palette[rng.next_int(palette.size())])
			v.append(row)
		var t: Array[TileDef] = []
		var keys: Dictionary = {}
		var ok := true
		for r in n:
			if not ok:
				break
			for c in n:
				var e := PackedInt32Array([h[r][c], v[r][c + 1], h[r + 1][c], v[r][c]])
				if is_symmetric(e):
					ok = false # 180-degree symmetric: ambiguous rotation
					break
				var k := canon_key(e)
				if keys.has(k):
					ok = false # duplicate tile up to rotation
					break
				keys[k] = true
				var td := TileDef.new()
				td.id = r * n + c
				td.home = td.id
				td.faces = [e]
				t.append(td)
		if ok:
			tiles = t
			break
		if attempt == 399:
			tiles = t
	var pz := Puzzle.new()
	pz.n = n
	pz.tiles = tiles
	pz.allow_swap = def.shuf > 0.0
	pz.allow_flip = def.flip > 0
	pz.has_fixed = def.fix > 0
	pz.palette = palette
	pz.seed_value = seed_value
	pz.def = def
	var slots: Array[SlotState] = []
	for i in tiles.size():
		slots.append(SlotState.new(i, 0, 0))
	# fixed tiles
	if def.fix > 0:
		var ids: Array = []
		for td in tiles:
			ids.append(td.id)
		var order: Array = rng.shuffle(ids)
		for i in def.fix:
			tiles[order[i]].fixed = true
	var movable: Array = []
	for td in tiles:
		if not td.fixed:
			movable.append(td.id)
	# double-sided tiles: decoy back face (not a rotation of the front, not symmetric)
	if def.flip > 0:
		var order: Array = rng.shuffle(movable.duplicate())
		for i in mini(def.flip, order.size()):
			var td: TileDef = tiles[order[i]]
			var back := PackedInt32Array()
			for k in 50:
				back = PackedInt32Array([
					palette[rng.next_int(palette.size())], palette[rng.next_int(palette.size())],
					palette[rng.next_int(palette.size())], palette[rng.next_int(palette.size())]])
				var nb: int = rng.next_int(3) # 0..2 border edges allowed on the decoy
				for b in nb:
					back[rng.next_int(4)] = BORDER
				if canon_key(back) != canon_key(td.faces[0]) and not is_symmetric(back):
					break
			td.faces.append(back)
	# scramble: permutation of a subset of the movable tiles
	if def.shuf > 0.0:
		var k: int = maxi(2, roundi(def.shuf * movable.size()))
		var chosen: Array = rng.shuffle(movable.duplicate()).slice(0, k)
		var perm: Array = rng.shuffle(chosen.duplicate())
		var copy := SlotState.clone_list(slots)
		for i in k:
			slots[chosen[i]] = copy[perm[i]]
	# scramble: rotations and flips
	for p in total:
		var s: SlotState = slots[p]
		var td: TileDef = tiles[s.t]
		if td.fixed:
			continue
		if rng.next() < 0.88:
			s.rot = 1 + rng.next_int(3)
		if td.is_two_sided() and rng.next() < 0.8:
			s.face = 1
	# make sure at least one thing is wrong
	if is_solved(pz, slots):
		var first: int = movable[0]
		for s in slots:
			if s.t == first:
				s.rot = (s.rot + 1) % 4
				break
	pz.par = plan_moves(pz, slots, pz.solution()).size()
	pz.start = SlotState.clone_list(slots)
	return pz


static func edges_at(pz: Puzzle, s: SlotState) -> PackedInt32Array:
	return rot_edges(pz.tiles[s.t].faces[s.face], s.rot)


## Matched edges (encoded as slot * 4 + edge) and whether the board is complete.
static func evaluate(pz: Puzzle, slots: Array[SlotState]) -> EvalResult:
	var n: int = pz.n
	var e_all: Array[PackedInt32Array] = []
	for s in slots:
		e_all.append(edges_at(pz, s))
	var res := EvalResult.new()
	var all := true
	for r in n:
		for c in n:
			var p: int = r * n + c
			var e: PackedInt32Array = e_all[p]
			# top
			if r == 0:
				if e[0] == BORDER:
					res.matched.append(p * 4)
				else:
					all = false
			else:
				var u: PackedInt32Array = e_all[p - n]
				if e[0] != BORDER and u[2] == e[0]:
					res.matched.append(p * 4)
				else:
					all = false
			# left
			if c == 0:
				if e[3] == BORDER:
					res.matched.append(p * 4 + 3)
				else:
					all = false
			else:
				var l: PackedInt32Array = e_all[p - 1]
				if e[3] != BORDER and l[1] == e[3]:
					res.matched.append(p * 4 + 3)
				else:
					all = false
			if c == n - 1:
				if e[1] == BORDER:
					res.matched.append(p * 4 + 1)
				else:
					all = false
			if r == n - 1:
				if e[2] == BORDER:
					res.matched.append(p * 4 + 2)
				else:
					all = false
	res.solved = all
	return res


static func is_solved(pz: Puzzle, slots: Array[SlotState]) -> bool:
	return evaluate(pz, slots).solved


## Moves to transform `slots` into `sol`: swaps first (whole slot records travel), then flips and 90-degree turns.
static func plan_moves(pz: Puzzle, slots: Array[SlotState], sol: Array[SlotState]) -> Array[Move]:
	var cur := SlotState.clone_list(slots)
	var moves: Array[Move] = []
	for p in cur.size():
		if cur[p].t != sol[p].t:
			var q: int = -1
			for i in cur.size():
				if cur[i].t == sol[p].t:
					q = i
					break
			var tmp: SlotState = cur[p]
			cur[p] = cur[q]
			cur[q] = tmp
			moves.append(Move.swap(p, q))
	for p in cur.size():
		if cur[p].face != sol[p].face:
			moves.append(Move.flip(p))
		var k: int = (sol[p].rot - cur[p].rot + 4) % 4
		for i in k:
			moves.append(Move.rot(p))
	return moves


## Moves that fix exactly one slot (the first wrong one) toward `sol`. Returns [] if nothing is wrong.
static func plan_hint(pz: Puzzle, slots: Array[SlotState], sol: Array[SlotState]) -> Array[Move]:
	var p: int = -1
	for i in sol.size():
		if not slots[i].equals(sol[i]):
			p = i
			break
	if p < 0:
		return []
	var moves: Array[Move] = []
	var cur := SlotState.clone_list(slots)
	if cur[p].t != sol[p].t:
		var q: int = -1
		for i in cur.size():
			if cur[i].t == sol[p].t:
				q = i
				break
		var tmp: SlotState = cur[p]
		cur[p] = cur[q]
		cur[q] = tmp
		moves.append(Move.swap(p, q))
	if cur[p].face != sol[p].face:
		moves.append(Move.flip(p))
	var k: int = (sol[p].rot - cur[p].rot + 4) % 4
	for i in k:
		moves.append(Move.rot(p))
	return moves


static func stars_for(moves: int, par: int) -> int:
	if moves <= par:
		return 3
	if moves <= ceili(par * 1.6) + 2:
		return 2
	return 1


static func level_seed(index: int) -> int:
	return Mulberry32.hash_str("cini-level-%d-v1" % (index + 1))


static func daily_seed(key: String) -> int:
	return Mulberry32.hash_str("cini-daily-" + key)


static func daily_key_for(date: Dictionary) -> String:
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]


static func daily_key() -> String:
	return daily_key_for(Time.get_date_dict_from_system())


## Applies one primitive move (or its inverse) to a slot list. Pure, used by the state and the tests.
static func apply_primitive(slots: Array[SlotState], m: Move, inverse: bool) -> void:
	match m.type:
		Move.Type.ROT:
			var s: SlotState = slots[m.p]
			s.rot = (s.rot + (3 if inverse else 1)) % 4
		Move.Type.SWAP:
			var tmp: SlotState = slots[m.a]
			slots[m.a] = slots[m.b]
			slots[m.b] = tmp
		Move.Type.FLIP:
			var s: SlotState = slots[m.p]
			s.face = 0 if s.face == 1 else 1
		Move.Type.HINT:
			if inverse:
				for i in range(m.moves.size() - 1, -1, -1):
					apply_primitive(slots, m.moves[i], true)
			else:
				for sub in m.moves:
					apply_primitive(slots, sub, false)
