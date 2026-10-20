class_name Bot
extends Node
## Autoplay bot (`--auto`): solves the live puzzle with the real solver and performs the moves one by
## one through the same GameState API a player uses, from the title screen to the last level.
## `--solve` applies the whole plan at once (jump straight to the kiln animation),
## `--quit-on-done` exits with code 0 (1 if anything went wrong) when the run is over.

var active: bool = false
var done: bool = false
var plan: Array[Move] = []
var plan_index: int = 0
var timer: float = 0.6
var levels_done: int = 0
var stars_total: int = 0
var errors: int = 0
var solve_ms: float = 0.0
var instant: bool = false
var quit_on_done: bool = false
var stop_after_level: int = -2 # -2 = play everything


func _ready() -> void:
	active = Args.has("auto")
	instant = Args.has("solve")
	quit_on_done = Args.has("quit-on-done")
	if Args.has("stop-after"):
		stop_after_level = int(Args.number("stop-after", -2))
	_publish()


func _publish() -> void:
	GameState.bot_info = {
		"active": active, "done": done, "levels_done": levels_done, "stars": stars_total,
		"errors": errors, "plan": "%d/%d" % [plan_index, plan.size()], "solve_ms": snappedf(solve_ms, 0.1),
	}


func _fail(msg: String) -> void:
	errors += 1
	push_error("BOT: " + msg)
	_finish()


func _finish() -> void:
	done = true
	_publish()
	print("BOT DONE levels=%d stars=%d errors=%d" % [levels_done, stars_total, errors])
	print("STATE " + GameState.get_state_text())
	if quit_on_done:
		get_tree().quit(0 if errors == 0 else 1)


func _process(delta: float) -> void:
	if not active or done:
		return
	timer -= delta
	if timer > 0.0:
		return
	match GameState.screen:
		GameState.SCREEN_TITLE:
			GameState.start_level(GameState.next_unfinished())
			timer = 0.6
		GameState.SCREEN_HOWTO:
			GameState.dismiss_howto()
			timer = 0.3
		GameState.SCREEN_MENU, GameState.SCREEN_LEVELS, GameState.SCREEN_COLLECTION, GameState.SCREEN_SETTINGS:
			GameState.close_overlays()
			timer = 0.3
		GameState.SCREEN_PLAYING:
			_play_step()
		GameState.SCREEN_COMPLETE:
			plan = []
			levels_done += 1
			stars_total += int(GameState.result.get("stars", 0))
			_publish()
			var idx: int = GameState.level_index
			if idx == stop_after_level:
				_finish() # stay on the complete screen
			elif idx == GameState.DAILY or idx >= PuzzleCore.LEVEL_COUNT - 1:
				GameState.show_collection()
				_finish()
			else:
				GameState.next_level()
			timer = 0.9
		_:
			pass


func _play_step() -> void:
	if plan.is_empty():
		var t0: int = Time.get_ticks_usec()
		var solver := Solver.new()
		var sol := solver.solve(GameState.puzzle, GameState.slots)
		solve_ms = (Time.get_ticks_usec() - t0) / 1000.0
		if sol.is_empty():
			_fail("solver failed on level %s" % GameState.puzzle.key)
			return
		plan = PuzzleCore.plan_moves(GameState.puzzle, GameState.slots, sol)
		plan_index = 0
		timer = 0.4
		_publish()
		if instant:
			for m in plan:
				GameState.perform_move(m)
			plan_index = plan.size()
			if GameState.screen == GameState.SCREEN_PLAYING:
				_fail("instant plan finished but board not solved (%s)" % GameState.puzzle.key)
		return
	if plan_index < plan.size():
		var m: Move = plan[plan_index]
		plan_index += 1
		GameState.perform_move(m)
		match m.type:
			Move.Type.ROT:
				timer = 0.14
			Move.Type.SWAP:
				timer = 0.34
			_:
				timer = 0.3
		_publish()
	else:
		_fail("plan finished but board not solved (%s)" % GameState.puzzle.key)
