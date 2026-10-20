extends Node
## Headless unit tests for the core rules. Prints "TESTS PASSED n/n" or "TESTS FAILED k/n" and exits 0/1.
## Run: godot_console --headless --path <project> --scene res://tests/run_tests.tscn

var _passed: int = 0
var _failed: int = 0
var _current: String = ""


func _ready() -> void:
	# Tests never touch the player's save data.
	GameState.no_save = true
	Settings.no_save = true
	GameState.progress = GameState._empty_progress()
	var t0: int = Time.get_ticks_msec()
	_run("rng_is_deterministic", test_rng_is_deterministic)
	_run("rng_matches_reference_values", test_rng_reference)
	_run("hash_str_reference", test_hash_reference)
	_run("rot_edges_and_canon_key", test_rot_edges)
	_run("motif_ids", test_motif_ids)
	_run("level_resources_load", test_level_resources)
	_run("generate_level_is_deterministic", test_generate_deterministic)
	_run("generated_levels_are_valid", test_generated_levels_valid)
	_run("evaluate_detects_solution", test_evaluate)
	_run("plan_moves_reaches_solution", test_plan_moves)
	_run("apply_primitive_inverse", test_apply_inverse)
	_run("solver_solves_all_levels", test_solver_all_levels)
	_run("solver_respects_fixed_tiles", test_solver_fixed)
	_run("hint_fixes_one_slot", test_hint)
	_run("stars_for", test_stars)
	_run("daily_key_and_seed", test_daily)
	_run("progress_merge", test_progress_merge)
	_run("game_state_flow", test_game_state_flow)
	_run("game_state_undo_and_hint", test_game_state_undo_hint)
	_run("game_state_text_is_json", test_state_text)
	_run("synth_produces_audio", test_synth)
	_run("home_plan_solves_every_level", test_home_plan_all_levels)
	_run("hint_uses_home_solution_and_undo_returns_it", test_hint_home_and_undo)
	_run("edge_total_matches_solved_board", test_edge_total)
	_run("record_flag_and_replay_returns_to_wall", test_record_and_wall)
	_run("toast_kinds", test_toast_kinds)
	_run("cylinder_points_along_its_yaw", test_cylinder_axis)
	_run("generated_models_fit", test_model_fit)
	_run("generated_models_are_opaque", test_model_materials)
	_run("web_defaults_to_low_quality", test_web_low)
	var total: int = _passed + _failed
	print("Tests took %d ms" % (Time.get_ticks_msec() - t0))
	if _failed == 0:
		print("TESTS PASSED %d/%d" % [_passed, total])
		get_tree().quit(0)
	else:
		print("TESTS FAILED %d/%d" % [_failed, total])
		get_tree().quit(1)


func _run(name: String, fn: Callable) -> void:
	_current = name
	var before_failed: int = _failed
	fn.call()
	if _failed == before_failed:
		_passed += 1
		print("  ok   %s" % name)
	else:
		print("  FAIL %s" % name)


func check(cond: bool, msg: String) -> void:
	if not cond:
		_failed += 1
		printerr("    assertion failed in %s: %s" % [_current, msg])


func check_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		_failed += 1
		printerr("    assertion failed in %s: %s (got %s, expected %s)" % [_current, msg, str(a), str(b)])


# ---------------------------------------------------------------- tests

func test_rng_is_deterministic() -> void:
	var a := Mulberry32.new(42)
	var b := Mulberry32.new(42)
	for i in 50:
		check_eq(a.next(), b.next(), "same seed, same sequence")
	var c := Mulberry32.new(43)
	check(a.next() != c.next(), "different seeds differ")
	for i in 200:
		var v: float = a.next()
		check(v >= 0.0 and v < 1.0, "value in [0,1)")


func test_rng_reference() -> void:
	# Reference values of mulberry32(1) computed with the JavaScript original.
	var r := Mulberry32.new(1)
	var expected: Array[float] = [0.6270739405881613, 0.002735721180215478, 0.5274470399599522]
	for e in expected:
		check(absf(r.next() - e) < 1e-12, "mulberry32(1) reference value %f" % e)
	check_eq(Mulberry32.imul(0xFFFFFFFF, 0xFFFFFFFF), 1, "imul wraps like Math.imul")
	check_eq(Mulberry32.imul(123456789, 987654321), (123456789 * 987654321) & 0xFFFFFFFF, "imul low bits")


func test_hash_reference() -> void:
	# FNV-1a 32-bit reference values.
	check_eq(Mulberry32.hash_str(""), 2166136261, "fnv1a empty")
	check_eq(Mulberry32.hash_str("a"), 0xe40c292c, "fnv1a 'a'")
	check_eq(Mulberry32.hash_str("foobar"), 0xbf9cf968, "fnv1a 'foobar'")
	check_eq(PuzzleCore.level_seed(0), Mulberry32.hash_str("cini-level-1-v1"), "level seed uses v1 key")


func test_rot_edges() -> void:
	var e := PackedInt32Array([1, 2, 3, 4])
	check_eq(PuzzleCore.rot_edges(e, 0), PackedInt32Array([1, 2, 3, 4]), "rot 0")
	check_eq(PuzzleCore.rot_edges(e, 1), PackedInt32Array([4, 1, 2, 3]), "rot 1 moves top to right")
	check_eq(PuzzleCore.rot_edges(e, 2), PackedInt32Array([3, 4, 1, 2]), "rot 2")
	check_eq(PuzzleCore.rot_edges(e, 3), PackedInt32Array([2, 3, 4, 1]), "rot 3")
	check_eq(PuzzleCore.canon_key(e), PuzzleCore.canon_key(PuzzleCore.rot_edges(e, 2)), "canon key is rotation invariant")
	check(PuzzleCore.canon_key(e) != PuzzleCore.canon_key(PackedInt32Array([1, 3, 2, 4])), "different tiles differ")
	check(PuzzleCore.is_symmetric(PackedInt32Array([1, 2, 1, 2])), "symmetric detection")
	check(not PuzzleCore.is_symmetric(e), "asymmetric detection")


func test_motif_ids() -> void:
	for s in 5:
		for c in 4:
			var id: int = 1 + s * 4 + c
			check_eq(PuzzleCore.motif_shape(id), s, "shape of id %d" % id)
			check_eq(PuzzleCore.motif_color(id), c, "colour of id %d" % id)


func test_level_resources() -> void:
	var set := load("res://resources/level_set.tres") as LevelSet
	check(set != null, "level set loads")
	if set == null:
		return
	check_eq(set.chapters.size(), 3, "three chapters")
	check_eq(set.level_count(), 30, "thirty levels")
	check(set.daily != null and set.daily.n == 4, "daily definition")
	for i in 30:
		var def := set.level(i)
		check(def != null, "level %d exists" % i)
		check(def.name_tr != "" and def.name_en != "", "level %d has names" % i)
		check(def.n >= 3 and def.n <= 6, "level %d size" % i)
	check_eq(set.chapter_of(0), 0, "chapter of level 1")
	check_eq(set.chapter_of(15), 1, "chapter of level 16")
	check_eq(set.chapter_of(29), 2, "chapter of level 30")
	check_eq(set.level(0).name_en, "First Brush", "first level name")
	check_eq(set.level(29).name_tr, "Büyük Pano", "last level name")
	check_eq(set.chapters[2].display_name("en"), "Master", "chapter name")


func test_generate_deterministic() -> void:
	var def := GameState.level_set.level(12)
	var a := PuzzleCore.generate_level(def, PuzzleCore.level_seed(12))
	var b := PuzzleCore.generate_level(def, PuzzleCore.level_seed(12))
	check_eq(a.par, b.par, "same par")
	for p in a.slot_count():
		check(a.start[p].equals(b.start[p]), "same start slot %d" % p)
		check_eq(a.tiles[p].faces[0], b.tiles[p].faces[0], "same tile %d" % p)


func test_generated_levels_valid() -> void:
	for i in 30:
		var def := GameState.level_set.level(i)
		var pz := PuzzleCore.generate_level(def, PuzzleCore.level_seed(i))
		check_eq(pz.tiles.size(), def.n * def.n, "level %d tile count" % (i + 1))
		check(PuzzleCore.is_solved(pz, pz.solution()), "level %d home position is solved" % (i + 1))
		check(not PuzzleCore.is_solved(pz, pz.start), "level %d start is scrambled" % (i + 1))
		check(pz.par > 0, "level %d has a positive par" % (i + 1))
		var keys: Dictionary = {}
		var fixed: int = 0
		var flips: int = 0
		for td in pz.tiles:
			var k := PuzzleCore.canon_key(td.faces[0])
			check(not keys.has(k), "level %d tiles unique up to rotation" % (i + 1))
			keys[k] = true
			check(not PuzzleCore.is_symmetric(td.faces[0]), "level %d tiles not symmetric" % (i + 1))
			if td.fixed:
				fixed += 1
				var s: SlotState = pz.start[td.home]
				check(s.t == td.id and s.rot == 0 and s.face == 0, "fixed tile stays home")
			if td.is_two_sided():
				flips += 1
				check(PuzzleCore.canon_key(td.faces[1]) != k, "decoy face differs from the front")
		check_eq(fixed, def.fix, "level %d fixed count" % (i + 1))
		check_eq(flips, def.flip, "level %d flip count" % (i + 1))
		check_eq(pz.palette.size(), def.m, "level %d palette size" % (i + 1))
		if def.shuf == 0.0:
			for p in pz.slot_count():
				check_eq(pz.start[p].t, p, "rotate-only level keeps positions")


func test_evaluate() -> void:
	var pz := PuzzleCore.generate_level(GameState.level_set.level(0), PuzzleCore.level_seed(0))
	var ev := PuzzleCore.evaluate(pz, pz.solution())
	check(ev.solved, "solution evaluates as solved")
	# each slot reports its top and left edge, plus the right and bottom borders of the last column/row
	check_eq(ev.count(), 2 * pz.slot_count() + 2 * pz.n, "matched edge count of a solved board")
	var slots := SlotState.clone_list(pz.solution())
	slots[4].rot = 1
	var ev2 := PuzzleCore.evaluate(pz, slots)
	check(not ev2.solved, "rotated centre breaks the solution")
	check(ev2.count() < ev.count(), "fewer matches after a wrong rotation")


func test_plan_moves() -> void:
	for i in [0, 11, 21, 29]:
		var def := GameState.level_set.level(i)
		var pz := PuzzleCore.generate_level(def, PuzzleCore.level_seed(i))
		var slots := SlotState.clone_list(pz.start)
		var moves := PuzzleCore.plan_moves(pz, slots, pz.solution())
		check_eq(moves.size(), pz.par, "par equals the planned move count")
		for m in moves:
			PuzzleCore.apply_primitive(slots, m, false)
		check(PuzzleCore.is_solved(pz, slots), "level %d plan reaches the solution" % (i + 1))


func test_apply_inverse() -> void:
	var pz := PuzzleCore.generate_level(GameState.level_set.level(25), PuzzleCore.level_seed(25))
	var slots := SlotState.clone_list(pz.start)
	var before := SlotState.clone_list(slots)
	var moves: Array[Move] = [Move.rot(3), Move.swap(2, 7), Move.flip(_first_two_sided_slot(pz, slots)), Move.hint([Move.rot(5), Move.swap(5, 9)])]
	for m in moves:
		PuzzleCore.apply_primitive(slots, m, false)
	for i in range(moves.size() - 1, -1, -1):
		PuzzleCore.apply_primitive(slots, moves[i], true)
	for p in slots.size():
		check(slots[p].equals(before[p]), "inverse restores slot %d" % p)


func _first_two_sided_slot(pz: Puzzle, slots: Array[SlotState]) -> int:
	for p in slots.size():
		if pz.tiles[slots[p].t].is_two_sided():
			return p
	return 0


func test_solver_all_levels() -> void:
	var total_nodes: int = 0
	for i in 30:
		var def := GameState.level_set.level(i)
		var pz := PuzzleCore.generate_level(def, PuzzleCore.level_seed(i))
		var solver := Solver.new()
		var t0: int = Time.get_ticks_msec()
		var sol := solver.solve(pz, pz.start)
		var ms: int = Time.get_ticks_msec() - t0
		total_nodes += solver.nodes
		check(not sol.is_empty(), "level %d solvable" % (i + 1))
		if sol.is_empty():
			continue
		check(PuzzleCore.is_solved(pz, sol), "level %d solver output is solved" % (i + 1))
		check(ms < 15000, "level %d solved in reasonable time (%d ms)" % [i + 1, ms])
	# daily boards for a few dates
	for day in ["2026-10-20", "2026-01-01", "2027-07-15"]:
		var pz := PuzzleCore.generate_level(GameState.level_set.daily, PuzzleCore.daily_seed(day))
		var sol := Solver.new().solve(pz, pz.start)
		check(not sol.is_empty() and PuzzleCore.is_solved(pz, sol), "daily %s solvable" % day)
	print("    solver nodes over 30 levels: %d" % total_nodes)


func test_solver_fixed() -> void:
	var pz := PuzzleCore.generate_level(GameState.level_set.level(25), PuzzleCore.level_seed(25))
	var sol := Solver.new().solve(pz, pz.start)
	check(not sol.is_empty(), "level 26 solvable")
	if sol.is_empty():
		return
	for td in pz.tiles:
		if td.fixed:
			check_eq(sol[td.home].t, td.id, "fixed tile stays in place in the solution")
	# position-locked (rotate-only) solver never moves tiles
	var pz1 := PuzzleCore.generate_level(GameState.level_set.level(7), PuzzleCore.level_seed(7))
	var sol1 := Solver.new().solve(pz1, pz1.start)
	for p in sol1.size():
		check_eq(sol1[p].t, pz1.start[p].t, "rotate-only solution keeps tile positions")


func test_hint() -> void:
	var pz := PuzzleCore.generate_level(GameState.level_set.level(22), PuzzleCore.level_seed(22))
	var slots := SlotState.clone_list(pz.start)
	var sol := Solver.new().solve(pz, slots)
	check(not sol.is_empty(), "solvable")
	var hints_used: int = 0
	while not PuzzleCore.is_solved(pz, slots) and hints_used < 200:
		var moves := PuzzleCore.plan_hint(pz, slots, sol)
		check(not moves.is_empty(), "hint finds something to fix")
		if moves.is_empty():
			break
		var wrong_before: int = _wrong_count(slots, sol)
		for m in moves:
			PuzzleCore.apply_primitive(slots, m, false)
		check(_wrong_count(slots, sol) < wrong_before, "each hint reduces the number of wrong slots")
		hints_used += 1
	check(PuzzleCore.is_solved(pz, slots), "repeated hints solve the board")
	check(PuzzleCore.plan_hint(pz, slots, sol).is_empty(), "no hint on a solved board")


func _wrong_count(slots: Array[SlotState], sol: Array[SlotState]) -> int:
	var w: int = 0
	for p in slots.size():
		if not slots[p].equals(sol[p]):
			w += 1
	return w


func test_stars() -> void:
	check_eq(PuzzleCore.stars_for(10, 10), 3, "at par = 3 stars")
	check_eq(PuzzleCore.stars_for(11, 10), 2, "just over par = 2 stars")
	check_eq(PuzzleCore.stars_for(18, 10), 2, "ceil(16)+2 = 18 still 2 stars")
	check_eq(PuzzleCore.stars_for(19, 10), 1, "19 moves = 1 star")
	check_eq(PuzzleCore.stars_for(0, 5), 3, "zero moves")


func test_daily() -> void:
	var key := PuzzleCore.daily_key_for({"year": 2026, "month": 3, "day": 7})
	check_eq(key, "2026-03-07", "daily key format")
	check_eq(PuzzleCore.daily_seed(key), Mulberry32.hash_str("cini-daily-2026-03-07"), "daily seed")
	check(PuzzleCore.daily_seed("2026-03-07") != PuzzleCore.daily_seed("2026-03-08"), "daily seeds differ by day")
	check(PuzzleCore.daily_key().length() == 10, "today's key has the right length")


func test_progress_merge() -> void:
	var base: Dictionary = {"best": {}, "collection": [], "seen_howto": {}, "daily_toast_shown": false}
	var loaded: Dictionary = {
		"best": {"L1": {"stars": 3, "moves": 4}, "L2": "broken"},
		"collection": [{"key": "L1", "idx": 0, "seed": 123, "stars": 3, "ts": 10}, {"nope": 1}],
		"seen_howto": {"0": true},
		"daily_toast_shown": true,
		"garbage": 7,
	}
	var merged := GameState.merge_progress(base, loaded)
	check_eq(merged["best"].size(), 1, "malformed best entry dropped")
	check_eq(int(merged["best"]["L1"]["stars"]), 3, "best stars kept")
	check_eq(merged["collection"].size(), 1, "malformed collection entry dropped")
	check(merged["seen_howto"].has("0"), "seen howto kept")
	check(bool(merged["daily_toast_shown"]), "flag kept")
	check(not merged.has("garbage"), "unknown keys ignored")
	# JSON round trip
	var again: Variant = JSON.parse_string(JSON.stringify(merged))
	check(again is Dictionary and GameState.merge_progress(base, again)["best"].has("L1"), "json round trip")


func test_game_state_flow() -> void:
	check(GameState.no_save, "tests run without touching the disk")
	GameState.progress = GameState._empty_progress()
	GameState.show_title()
	check_eq(String(GameState.screen), "title", "title screen")
	check(not GameState.is_unlocked(1), "level 2 locked at start")
	check(GameState.is_unlocked(0), "level 1 unlocked")
	GameState.start_level(0)
	check_eq(String(GameState.screen), "howto", "first level shows the how-to")
	GameState.dismiss_howto()
	check_eq(String(GameState.screen), "playing", "playing after how-to")
	check_eq(GameState.move_count(), 0, "no moves yet")
	# solve with the solver and play every move through the public API
	var sol := Solver.new().solve(GameState.puzzle, GameState.slots)
	var plan := PuzzleCore.plan_moves(GameState.puzzle, GameState.slots, sol)
	for m in plan:
		check(GameState.perform_move(m), "move accepted")
	check_eq(String(GameState.screen), "completing", "solved -> completing")
	check_eq(int(GameState.result["stars"]), 3, "par solution gives 3 stars")
	check(GameState.progress["best"].has("L1"), "best recorded")
	check_eq(GameState.progress["collection"].size(), 1, "collection has one piece")
	check(GameState.is_unlocked(1), "level 2 unlocked after finishing level 1")
	check(not GameState.perform_move(Move.rot(0)), "no moves while completing")
	GameState.show_complete()
	check_eq(String(GameState.screen), "complete", "complete screen")
	check(GameState.has_next_level(), "next level available")
	GameState.next_level()
	check_eq(String(GameState.screen), "playing", "second level has no how-to")
	check_eq(GameState.level_index, 1, "level index advanced")
	GameState.show_menu()
	check_eq(String(GameState.screen), "menu", "pause menu")
	GameState.show_settings()
	check_eq(String(GameState.screen), "settings", "settings from menu")
	GameState.back()
	check_eq(String(GameState.screen), "menu", "back from settings returns to the menu")
	GameState.close_overlays()
	check_eq(String(GameState.screen), "playing", "resume")
	GameState.show_title()
	GameState.show_levels()
	GameState.close_overlays()
	check_eq(String(GameState.screen), "title", "levels opened from the title returns to the title")
	GameState.progress = GameState._empty_progress()


func test_game_state_undo_hint() -> void:
	GameState.progress = GameState._empty_progress()
	GameState.start_level(21, false) # chapter 3, has fixed and two-sided tiles
	GameState.dismiss_howto()
	check_eq(String(GameState.screen), "playing", "playing level 22")
	var pz: Puzzle = GameState.puzzle
	var fixed_slot: int = -1
	var two_sided_slot: int = -1
	var plain_slot: int = -1
	for p in pz.slot_count():
		var td: TileDef = GameState.tile_at_slot(p)
		if td.fixed and fixed_slot < 0:
			fixed_slot = p
		elif td.is_two_sided() and two_sided_slot < 0:
			two_sided_slot = p
		elif not td.fixed and not td.is_two_sided() and plain_slot < 0:
			plain_slot = p
	GameState.try_rotate(fixed_slot)
	check_eq(GameState.move_count(), 0, "fixed tile does not rotate")
	GameState.try_flip(plain_slot)
	check_eq(GameState.move_count(), 0, "single-sided tile does not flip")
	var face_before: int = GameState.slots[two_sided_slot].face
	GameState.try_flip(two_sided_slot)
	check_eq(GameState.move_count(), 1, "flip counts as a move")
	check(GameState.slots[two_sided_slot].face != face_before, "face changed")
	GameState.try_swap(plain_slot, fixed_slot)
	check_eq(GameState.move_count(), 1, "cannot swap with a fixed tile")
	GameState.try_rotate(plain_slot)
	check_eq(GameState.move_count(), 2, "rotation counts")
	GameState.undo()
	GameState.undo()
	check_eq(GameState.move_count(), 0, "two undos")
	check_eq(GameState.slots[two_sided_slot].face, face_before, "undo restored the face")
	check_eq(GameState.hints, 3, "three hints")
	GameState.use_hint()
	check_eq(GameState.hints, 2, "hint consumed")
	check_eq(GameState.history.size(), 1, "hint is one history entry")
	check(GameState.move_count() >= 1, "hint moves count toward the total")
	GameState.undo()
	check_eq(GameState.move_count(), 0, "hint undone")
	check_eq(GameState.hints, 3, "undoing a hint gives it back")
	GameState.restart_level()
	check_eq(GameState.hints, 3, "restart refills hints")
	for p in pz.slot_count():
		check(GameState.slots[p].equals(pz.start[p]), "restart resets slot %d" % p)
	GameState.show_title()
	GameState.puzzle = null
	GameState.progress = GameState._empty_progress()


func test_state_text() -> void:
	GameState.progress = GameState._empty_progress()
	GameState.start_level(3, false)
	GameState.dismiss_howto()
	var txt := GameState.get_state_text()
	var parsed: Variant = JSON.parse_string(txt)
	check(parsed is Dictionary, "state text parses as JSON")
	if parsed is Dictionary:
		check_eq(String(parsed["screen"]), "playing", "screen in state")
		check_eq(String(parsed["level"]["key"]), "L4", "level key in state")
		check_eq(int(parsed["level"]["n"]), 4, "board size in state")
		check(parsed["progress"].has("completed"), "progress summary in state")
	GameState.show_title()
	GameState.puzzle = null
	GameState.progress = GameState._empty_progress()


func test_synth() -> void:
	var s := Synth.new(0.3, 5)
	s.tone(440.0, 0.0, 0.2, 0.5)
	var peak: float = 0.0
	for v in s.data:
		peak = maxf(peak, absf(v))
	check(peak > 0.3 and peak <= 1.0, "tone has a sensible peak (%f)" % peak)
	var wav := s.to_wav()
	check_eq(wav.data.size(), s.data.size() * 2, "16-bit wav size")
	check_eq(wav.mix_rate, Synth.RATE, "mix rate")
	var n := Synth.new(0.2, 6)
	n.noise(0.0, 0.1, Synth.Filter.BANDPASS, 1000.0, 1.0, 0.3, 2000.0)
	var energy: float = 0.0
	for v in n.data:
		energy += v * v
	check(energy > 0.0, "noise produces signal")
	var p := Synth.new(1.0, 7)
	p.pluck(293.66, 0.0, 0.5, 0.9)
	check(absf(p.data[int(0.02 * Synth.RATE)]) > 0.0, "pluck produces signal")


func _solve_live() -> void:
	for m in PuzzleCore.plan_moves(GameState.puzzle, GameState.slots, GameState.puzzle.solution()):
		GameState.perform_move(m)


func test_home_plan_all_levels() -> void:
	# the bot and the hints plan against the generated solution: it must reach a solved board everywhere
	var defs: Array = []
	for i in 30:
		defs.append([GameState.level_set.level(i), PuzzleCore.level_seed(i), "level %d" % (i + 1)])
	for day in ["2026-10-20", "2026-10-21", "2027-02-28"]:
		defs.append([GameState.level_set.daily, PuzzleCore.daily_seed(day), "daily " + day])
	for d in defs:
		var pz := PuzzleCore.generate_level(d[0], d[1])
		var slots := SlotState.clone_list(pz.start)
		var plan := PuzzleCore.plan_moves(pz, slots, pz.solution())
		check_eq(plan.size(), pz.par, "%s plan length is par" % d[2])
		for m in plan:
			PuzzleCore.apply_primitive(slots, m, false)
		check(PuzzleCore.is_solved(pz, slots), "%s home plan solves it" % d[2])
		for td in pz.tiles:
			if td.fixed:
				check(pz.start[td.home].t == td.id, "%s fixed tile starts at home" % d[2])


func test_hint_home_and_undo() -> void:
	GameState.progress = GameState._empty_progress()
	GameState.start_level(29, false) # 6x6 with fixed and two-sided tiles: the old solver hint was slow here
	GameState.dismiss_howto()
	var t0: int = Time.get_ticks_msec()
	GameState.use_hint()
	var ms: int = Time.get_ticks_msec() - t0
	check(ms < 50, "hint on a 6x6 board is instant (%d ms)" % ms)
	check_eq(GameState.hints, 2, "hint used")
	var sol: Array[SlotState] = GameState.puzzle.solution()
	var first_wrong: int = -1
	for p in GameState.puzzle.start.size():
		if not GameState.puzzle.start[p].equals(sol[p]):
			first_wrong = p
			break
	check(GameState.slots[first_wrong].equals(sol[first_wrong]), "the hint fixed the first wrong slot")
	GameState.undo()
	check_eq(GameState.hints, 3, "undo gives the hint back")
	for p in GameState.slots.size():
		check(GameState.slots[p].equals(GameState.puzzle.start[p]), "undo restored slot %d" % p)
	# three hints, three undos: all three hints are back, never more
	for i in 3:
		GameState.use_hint()
	check_eq(GameState.hints, 0, "all hints used")
	for i in 3:
		GameState.undo()
	check_eq(GameState.hints, 3, "all hints back")
	GameState.show_title()
	GameState.puzzle = null
	GameState.progress = GameState._empty_progress()


func test_edge_total() -> void:
	for i in [0, 10, 25, 29]:
		var pz := PuzzleCore.generate_level(GameState.level_set.level(i), PuzzleCore.level_seed(i))
		check_eq(PuzzleCore.evaluate(pz, pz.solution()).count(), PuzzleCore.edge_total(pz.n), "level %d edge total" % (i + 1))


func test_record_and_wall() -> void:
	GameState.progress = GameState._empty_progress()
	# L1 is the oldest of 13 pieces, so it is not on the 12-piece wall
	GameState.progress["collection"].append({"key": "L1", "idx": 0, "seed": PuzzleCore.level_seed(0), "stars": 1, "ts": 1})
	for i in range(1, 13):
		GameState.progress["collection"].append({"key": "L%d" % (i + 1), "idx": i, "seed": PuzzleCore.level_seed(i), "stars": 2, "ts": 100 + i})
	check(not GameState._on_wall("L1"), "L1 starts off the wall")
	GameState.start_level(0, false)
	GameState.dismiss_howto()
	# a first, wasteful solve: four extra turns of one tile
	for i in 4:
		GameState.perform_move(Move.rot(0))
	_solve_live()
	check_eq(String(GameState.screen), "completing", "solved")
	check(not bool(GameState.result["record"]), "no record badge on the first result")
	check(GameState._on_wall("L1"), "the replayed piece goes back up on the wall")
	check_eq(GameState.wall_entries()[-1]["key"], "L1", "as the newest piece")
	GameState.show_complete()
	GameState.replay_level()
	GameState.dismiss_howto()
	_solve_live()
	check(bool(GameState.result["record"]), "a better result shows the record badge")
	check_eq(int(GameState.result["moves"]), GameState.puzzle.par, "par result")
	GameState.show_complete()
	GameState.back()
	check_eq(String(GameState.screen), "title", "Esc on the complete card goes to the title")
	GameState.puzzle = null
	GameState.progress = GameState._empty_progress()


func test_toast_kinds() -> void:
	var got: Array = []
	var cb := func(msg: String, kind: String) -> void: got.append([msg, kind])
	GameState.toast.connect(cb)
	GameState.progress = GameState._empty_progress()
	GameState.start_level(25, false)
	GameState.dismiss_howto()
	var fixed_slot: int = -1
	for s in GameState.puzzle.slot_count():
		if GameState.tile_at_slot(s).fixed:
			fixed_slot = s
			break
	GameState.try_rotate(fixed_slot)
	GameState.use_hint()
	GameState.hints = 0
	GameState.use_hint()
	GameState.restart_level()
	GameState.toast.disconnect(cb)
	var kinds: Array = got.map(func(e: Array) -> String: return e[1])
	check_eq(kinds, ["bad", "good", "bad", ""], "fixed tile bad, hint good, no hints bad, restart info")
	check_eq(got[-1][0], Loc.t("restarted"), "restart toast text")
	GameState.show_title()
	GameState.puzzle = null
	GameState.progress = GameState._empty_progress()


func test_cylinder_axis() -> void:
	# a brush handle laid flat (rot.x = PI/2) and turned by a must point along (sin a, 0, cos a)
	var a: float = 0.6
	var mb := MeshBuilder.new(1)
	mb.cylinder(0.02, 0.02, 1.0, Vector3.ZERO, Color.WHITE, 0.0, Vector3(PI / 2, a, 0), 8)
	var verts: PackedVector3Array = mb.commit().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var axis := Vector3(sin(a), 0, cos(a))
	var best: float = 0.0
	var max_y: float = 0.0
	for v in verts:
		best = maxf(best, v.dot(axis))
		max_y = maxf(max_y, absf(v.y))
	check(absf(best - 0.5) < 0.03, "handle end lies on the yaw axis (%f)" % best)
	check(max_y < 0.03, "handle lies flat (%f)" % max_y)


func test_model_fit() -> void:
	var kiln := WorldBuilder.asset_model(WorldBuilder.KILN_FIT)
	check(kiln != null, "kiln model loads")
	if kiln != null:
		var size: Vector3 = kiln.get_meta("size")
		check(absf(size.z - 2.4) < 0.01, "kiln depth 2.4 m (%s)" % size)
		check(absf(size.x - 2.16) < 0.05 and absf(size.y - 2.09) < 0.05, "kiln about 2.16 x 2.09 m (%s)" % size)
		check(kiln.position.is_equal_approx(Vector3(4.55, 0, -2.95)), "kiln base centre")
		kiln.free()
	var cat := WorldBuilder.asset_model(WorldBuilder.CAT_FIT)
	check(cat != null and absf((cat.get_meta("size") as Vector3).y - 0.46) < 0.01, "cat is 0.46 m tall")
	if cat != null:
		cat.free()
	var paint := WorldBuilder.asset_model(WorldBuilder.PAINT_FIT)
	check(paint != null and absf((paint.get_meta("size") as Vector3).z - 0.6) < 0.01, "paint set is 0.6 m deep")
	if paint != null:
		paint.free()


func _materials(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			out.append(mi.get_active_material(i))
	for c in n.get_children():
		_materials(c, out)


func test_model_materials() -> void:
	# one opaque pass per model: no alpha blending, no depth pre-pass, no second material
	for fit in [WorldBuilder.KILN_FIT, WorldBuilder.CAT_FIT, WorldBuilder.PAINT_FIT]:
		var m := WorldBuilder.asset_model(fit)
		if m == null:
			check(false, "%s loads" % fit["file"])
			continue
		var mats: Array = []
		_materials(m, mats)
		check_eq(mats.size(), 1, "%s has one surface" % fit["file"])
		for mat in mats:
			var sm := mat as BaseMaterial3D
			check(sm != null, "%s uses a standard material" % fit["file"])
			if sm != null:
				check_eq(sm.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED, "%s is opaque" % fit["file"])
				check(sm.next_pass == null, "%s has no extra pass" % fit["file"])
		m.free()


func test_web_low() -> void:
	# the browser build (OS feature "web") and --web-sim start on the Low tier
	check_eq(Settings.default_quality(), "low" if OS.has_feature("web") or Args.has("web-sim") else "high", "default tier")
	check(not OS.has_feature("web") or Settings.is_web(), "web feature means web defaults")
