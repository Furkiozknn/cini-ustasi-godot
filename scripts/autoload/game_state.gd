extends Node
## The game's state machine and progress store. Everything visual listens to its signals.
## get_state_text() returns the whole state as JSON for tools and the autoplay bot.

signal screen_changed(screen: StringName, prev: StringName)
signal level_started(with_intro: bool)
signal primitive_applied(move: Move, inverse: bool)
signal board_changed(is_undo: bool, newly_matched: int)
signal puzzle_solved(result: Dictionary)
## kind: "" (info), "good" or "bad"; the toast stack colours its edge accordingly.
signal toast(msg: String, kind: String)
signal progress_changed
signal hint_sparkle(slot: int)
signal tile_denied(slot: int)

const SCREEN_LOADING: StringName = &"loading"
const SCREEN_TITLE: StringName = &"title"
const SCREEN_LEVELS: StringName = &"levels"
const SCREEN_COLLECTION: StringName = &"collection"
const SCREEN_HOWTO: StringName = &"howto"
const SCREEN_PLAYING: StringName = &"playing"
const SCREEN_MENU: StringName = &"menu"
const SCREEN_SETTINGS: StringName = &"settings"
const SCREEN_COMPLETING: StringName = &"completing"
const SCREEN_COMPLETE: StringName = &"complete"

const OVERLAYS: Array[StringName] = [SCREEN_LEVELS, SCREEN_COLLECTION, SCREEN_HOWTO, SCREEN_MENU, SCREEN_SETTINGS]

const PROGRESS_PATH: String = "user://progress.json"
const HINTS_PER_LEVEL: int = 3
const DAILY: int = PuzzleCore.DAILY_INDEX
const MAX_WALL: int = 12

var level_set: LevelSet
var screen: StringName = SCREEN_LOADING
var prev_screen: StringName = SCREEN_LOADING
var level_index: int = 0
var puzzle: Puzzle = null
var slots: Array[SlotState] = []
var history: Array[Move] = []
var hints: int = HINTS_PER_LEVEL
var matched_count: int = 0
var result: Dictionary = {}
var new_piece: bool = false
var pending_daily: bool = false
var howto_chapter: int = 0
var no_save: bool = false
var progress: Dictionary = {}
## Free-form status written by the bot so it shows up in get_state_text().
var bot_info: Dictionary = {}
var play_time: float = 0.0

var _return_screen: StringName = SCREEN_TITLE


func _ready() -> void:
	level_set = load("res://resources/level_set.tres") as LevelSet
	no_save = Args.has("no-save")
	progress = _empty_progress()
	if not no_save:
		load_progress()
	if Args.has("fill"):
		_fill_progress()


func _process(delta: float) -> void:
	play_time += delta


# ---------------------------------------------------------------- progress

func _empty_progress() -> Dictionary:
	return {"best": {}, "collection": [], "seen_howto": {}, "daily_toast_shown": false}


func load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var f := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		progress = merge_progress(_empty_progress(), parsed)


## Merges a loaded dictionary over the defaults, ignoring unknown or malformed values.
static func merge_progress(base: Dictionary, loaded: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	if loaded.get("best") is Dictionary:
		for k in loaded["best"]:
			var b: Variant = loaded["best"][k]
			if b is Dictionary and b.has("stars") and b.has("moves"):
				out["best"][str(k)] = {"stars": int(b["stars"]), "moves": int(b["moves"])}
	if loaded.get("collection") is Array:
		for e in loaded["collection"]:
			if e is Dictionary and e.has("key") and e.has("seed"):
				out["collection"].append({
					"key": str(e["key"]), "idx": int(e.get("idx", 0)), "seed": int(e["seed"]),
					"stars": int(e.get("stars", 1)), "ts": int(e.get("ts", 0))})
	if loaded.get("seen_howto") is Dictionary:
		for k in loaded["seen_howto"]:
			out["seen_howto"][str(k)] = true
	out["daily_toast_shown"] = bool(loaded.get("daily_toast_shown", false))
	return out


## Writes the progress (not with `--no-save`) and tells the UI it changed (always, once).
func save_progress() -> void:
	if not no_save:
		var f := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
		if f == null:
			push_warning("Could not write progress to %s" % PROGRESS_PATH)
		else:
			f.store_string(JSON.stringify(progress))
	progress_changed.emit()


func _fill_progress() -> void:
	for i in PuzzleCore.LEVEL_COUNT:
		var key: String = "L%d" % (i + 1)
		var stars: int = 1 + ((i * 7) % 3)
		progress["best"][key] = {"stars": stars, "moves": 20 + i}
		if find_collection_entry(key).is_empty():
			progress["collection"].append({"key": key, "idx": i, "seed": PuzzleCore.level_seed(i), "stars": stars, "ts": 1700000000 + i})


func find_collection_entry(key: String) -> Dictionary:
	for e in progress["collection"]:
		if e["key"] == key:
			return e
	return {}


func best_for(key: String) -> Dictionary:
	return progress["best"].get(key, {})


func level_key(idx: int) -> String:
	return "D" + PuzzleCore.daily_key() if idx == DAILY else "L%d" % (idx + 1)


func is_unlocked(idx: int) -> bool:
	if idx == DAILY:
		return daily_unlocked()
	return idx == 0 or progress["best"].has("L%d" % idx)


func daily_unlocked() -> bool:
	for i in 10:
		if not progress["best"].has("L%d" % (i + 1)):
			return false
	return true


func total_stars() -> int:
	var s: int = 0
	for i in PuzzleCore.LEVEL_COUNT:
		var b: Dictionary = best_for("L%d" % (i + 1))
		if not b.is_empty():
			s += int(b["stars"])
	return s


func completed_count() -> int:
	var c: int = 0
	for i in PuzzleCore.LEVEL_COUNT:
		if progress["best"].has("L%d" % (i + 1)):
			c += 1
	return c


func next_unfinished() -> int:
	for i in PuzzleCore.LEVEL_COUNT:
		if not progress["best"].has("L%d" % (i + 1)):
			return i
	return PuzzleCore.LEVEL_COUNT - 1


func level_display_name(idx: int) -> String:
	if idx == DAILY:
		return Loc.t("dailyName")
	var def: LevelDef = level_set.level(idx)
	return def.display_name(Loc.lang) if def != null else ""


func chapter_of(idx: int) -> int:
	return 3 if idx == DAILY else level_set.chapter_of(idx)


## Last MAX_WALL finished panels, oldest first: these hang on the workshop wall.
func wall_entries() -> Array:
	var list: Array = progress["collection"].duplicate()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["ts"]) < int(b["ts"]))
	if list.size() > MAX_WALL:
		list = list.slice(list.size() - MAX_WALL)
	return list


func _on_wall(key: String) -> bool:
	for e in wall_entries():
		if e["key"] == key:
			return true
	return false


func wall_slot_for(key: String) -> int:
	var list := wall_entries()
	for i in list.size():
		if list[i]["key"] == key:
			return i
	return list.size() - 1


func puzzle_for_entry(entry: Dictionary) -> Puzzle:
	var idx: int = int(entry["idx"])
	var def: LevelDef = level_set.daily if idx == DAILY else level_set.level(idx)
	return PuzzleCore.generate_level(def, int(entry["seed"]))


# ---------------------------------------------------------------- screens

func set_screen(s: StringName) -> void:
	if s == screen:
		return
	prev_screen = screen
	screen = s
	screen_changed.emit(screen, prev_screen)


func is_overlay(s: StringName) -> bool:
	return OVERLAYS.has(s)


func open_overlay(s: StringName) -> void:
	if not is_overlay(screen):
		_return_screen = SCREEN_PLAYING if screen == SCREEN_COMPLETING else screen
	set_screen(s)


func close_overlays() -> void:
	if _return_screen == SCREEN_PLAYING and puzzle == null:
		_return_screen = SCREEN_TITLE
	if _return_screen == SCREEN_LOADING:
		_return_screen = SCREEN_TITLE
	set_screen(_return_screen)


func show_title() -> void:
	_return_screen = SCREEN_TITLE
	set_screen(SCREEN_TITLE)


func show_levels() -> void:
	open_overlay(SCREEN_LEVELS)


func show_collection() -> void:
	open_overlay(SCREEN_COLLECTION)


func show_settings() -> void:
	open_overlay(SCREEN_SETTINGS)


func show_menu() -> void:
	if screen == SCREEN_PLAYING:
		open_overlay(SCREEN_MENU)


func show_howto(chapter: int) -> void:
	howto_chapter = chapter
	open_overlay(SCREEN_HOWTO)


func dismiss_howto() -> void:
	if screen == SCREEN_HOWTO:
		close_overlays()


## Esc / back behaviour.
func back() -> void:
	match screen:
		SCREEN_PLAYING:
			show_menu()
		SCREEN_MENU:
			close_overlays()
		SCREEN_SETTINGS:
			# settings opened from the pause menu returns to the pause menu
			if _return_screen == SCREEN_PLAYING and puzzle != null and prev_screen == SCREEN_MENU:
				set_screen(SCREEN_MENU)
			else:
				close_overlays()
		SCREEN_LEVELS, SCREEN_COLLECTION, SCREEN_HOWTO:
			close_overlays()
		SCREEN_COMPLETE:
			show_title()


# ---------------------------------------------------------------- level flow

func start_level(idx: int, with_intro: bool = true) -> void:
	var def: LevelDef = level_set.daily if idx == DAILY else level_set.level(idx)
	if def == null:
		push_error("No level with index %d" % idx)
		return
	var seed_value: int = PuzzleCore.daily_seed(PuzzleCore.daily_key()) if idx == DAILY else PuzzleCore.level_seed(idx)
	level_index = idx
	puzzle = PuzzleCore.generate_level(def, seed_value)
	puzzle.key = level_key(idx)
	slots = SlotState.clone_list(puzzle.start)
	history = []
	hints = HINTS_PER_LEVEL
	result = {}
	matched_count = PuzzleCore.evaluate(puzzle, slots).count()
	_return_screen = SCREEN_PLAYING
	set_screen(SCREEN_PLAYING)
	level_started.emit(with_intro)
	var ch: int = chapter_of(idx)
	var first: bool = idx == DAILY or idx % 10 == 0
	if first and not progress["seen_howto"].has(str(ch)) and not Args.has("nohowto"):
		progress["seen_howto"][str(ch)] = true
		save_progress()
		show_howto(ch)


func restart_level() -> void:
	if puzzle == null:
		return
	slots = SlotState.clone_list(puzzle.start)
	history = []
	hints = HINTS_PER_LEVEL
	matched_count = PuzzleCore.evaluate(puzzle, slots).count()
	level_started.emit(true)
	toast.emit(Loc.t("restarted"), "")


func next_level() -> void:
	if level_index == DAILY or level_index >= PuzzleCore.LEVEL_COUNT - 1:
		show_title()
		return
	start_level(level_index + 1)


func replay_level() -> void:
	start_level(level_index)


func move_count() -> int:
	var m: int = 0
	for h in history:
		m += h.count()
	return m


func live_stars() -> int:
	if puzzle == null:
		return 0
	return PuzzleCore.stars_for(move_count(), puzzle.par)


func tile_at_slot(p: int) -> TileDef:
	return puzzle.tiles[slots[p].t]


# ---------------------------------------------------------------- moves

func _apply(m: Move, inverse: bool) -> void:
	if m.type == Move.Type.HINT:
		if inverse:
			for i in range(m.moves.size() - 1, -1, -1):
				_apply(m.moves[i], true)
		else:
			for sub in m.moves:
				_apply(sub, false)
		return
	PuzzleCore.apply_primitive(slots, m, inverse)
	primitive_applied.emit(m, inverse)


func perform_move(m: Move) -> bool:
	if screen != SCREEN_PLAYING or puzzle == null:
		return false
	_apply(m, false)
	history.append(m)
	_after_change(false)
	return true


func undo() -> void:
	if screen != SCREEN_PLAYING:
		return
	if history.is_empty():
		toast.emit(Loc.t("nothingToUndo"), "")
		return
	var m: Move = history.pop_back()
	_apply(m, true)
	# undoing a hint gives the hint back
	if m.type == Move.Type.HINT:
		hints = mini(hints + 1, HINTS_PER_LEVEL)
	toast.emit(Loc.t("undone"), "")
	_after_change(true)


func _after_change(is_undo: bool) -> void:
	var before: int = matched_count
	var ev := PuzzleCore.evaluate(puzzle, slots)
	matched_count = ev.count()
	board_changed.emit(is_undo, matched_count - before)
	if not is_undo and ev.solved:
		_on_solved()


func try_rotate(slot: int) -> void:
	if screen != SCREEN_PLAYING:
		return
	if tile_at_slot(slot).fixed:
		toast.emit(Loc.t("fixedTile"), "bad")
		tile_denied.emit(slot)
		return
	perform_move(Move.rot(slot))


func try_flip(slot: int) -> void:
	if screen != SCREEN_PLAYING:
		return
	var td := tile_at_slot(slot)
	if td.fixed:
		toast.emit(Loc.t("fixedTile"), "bad")
		tile_denied.emit(slot)
		return
	if not td.is_two_sided():
		toast.emit(Loc.t("notTwoSided"), "bad")
		tile_denied.emit(slot)
		return
	perform_move(Move.flip(slot))


func try_swap(a: int, b: int) -> void:
	if screen != SCREEN_PLAYING or a == b:
		return
	if not puzzle.allow_swap:
		toast.emit(Loc.t("noSwapHere"), "")
		return
	if tile_at_slot(a).fixed:
		toast.emit(Loc.t("fixedTile"), "bad")
		tile_denied.emit(a)
		return
	if tile_at_slot(b).fixed:
		toast.emit(Loc.t("fixedTile"), "bad")
		tile_denied.emit(b)
		return
	perform_move(Move.swap(a, b))


func use_hint() -> void:
	if screen != SCREEN_PLAYING:
		return
	if hints <= 0:
		toast.emit(Loc.t("noHints"), "bad")
		tile_denied.emit(-1)
		return
	# Plan against the generated (home) solution: O(N), no search, always valid because fixed tiles
	# never leave home. The backtracking solver is only used by the tests.
	var moves := PuzzleCore.plan_hint(puzzle, slots, puzzle.solution())
	if moves.is_empty():
		return
	var p: int = moves[0].p if moves[0].type != Move.Type.SWAP else moves[0].a
	hints -= 1
	perform_move(Move.hint(moves))
	hint_sparkle.emit(p)
	toast.emit(Loc.t("hintUsed"), "good")


# ---------------------------------------------------------------- completion

func _on_solved() -> void:
	set_screen(SCREEN_COMPLETING)
	var moves: int = move_count()
	var par: int = puzzle.par
	var stars: int = PuzzleCore.stars_for(moves, par)
	var key: String = puzzle.key
	var prev: Dictionary = best_for(key)
	var improved: bool = prev.is_empty() or stars > int(prev["stars"]) or (stars == int(prev["stars"]) and moves < int(prev["moves"]))
	if improved:
		progress["best"][key] = {"stars": stars, "moves": moves}
	var entry := find_collection_entry(key)
	if entry.is_empty():
		progress["collection"].append({"key": key, "idx": level_index, "seed": puzzle.seed_value, "stars": stars, "ts": int(Time.get_unix_time_from_system())})
		new_piece = true
	else:
		entry["stars"] = maxi(int(entry["stars"]), stars)
		new_piece = false
		# a replayed panel that is no longer among the last MAX_WALL goes back up as the newest one
		if not _on_wall(key):
			entry["ts"] = int(Time.get_unix_time_from_system())
	save_progress()
	result = {"moves": moves, "par": par, "stars": stars, "best": best_for(key), "key": key, "new_piece": new_piece,
		"record": improved and not prev.is_empty()}
	if level_index == 9 and daily_unlocked() and not progress["daily_toast_shown"]:
		pending_daily = true
	puzzle_solved.emit(result)


## Called by the scene once the kiln sequence has finished.
func show_complete() -> void:
	_return_screen = SCREEN_COMPLETE
	set_screen(SCREEN_COMPLETE)
	if level_index == PuzzleCore.LEVEL_COUNT - 1 and completed_count() == PuzzleCore.LEVEL_COUNT:
		toast.emit(Loc.t("allDone"), "good")
	if pending_daily:
		pending_daily = false
		progress["daily_toast_shown"] = true
		save_progress()
		toast.emit(Loc.t("dailyUnlocked"), "good")


func has_next_level() -> bool:
	if level_index == DAILY or level_index >= PuzzleCore.LEVEL_COUNT - 1:
		return false
	return is_unlocked(level_index + 1)


# ---------------------------------------------------------------- state text

func get_state_text() -> String:
	var d: Dictionary = {
		"screen": String(screen),
		"prev_screen": String(prev_screen),
		"lang": Loc.lang,
		"time": snappedf(play_time, 0.01),
		"progress": {
			"completed": completed_count(),
			"total_stars": total_stars(),
			"collection": progress["collection"].size(),
			"daily_unlocked": daily_unlocked(),
		},
		"bot": bot_info,
	}
	if puzzle != null:
		var slot_list: Array = []
		for s in slots:
			slot_list.append([s.t, s.rot, s.face])
		d["level"] = {
			"key": puzzle.key,
			"index": level_index,
			"name": level_display_name(level_index),
			"n": puzzle.n,
			"moves": move_count(),
			"par": puzzle.par,
			"stars": live_stars(),
			"hints": hints,
			"matched": matched_count,
			"solved": PuzzleCore.is_solved(puzzle, slots),
			"history": history.size(),
			"slots": slot_list,
		}
	if not result.is_empty():
		d["result"] = result
	return JSON.stringify(d)
