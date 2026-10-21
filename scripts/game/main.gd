extends Node3D
## Main scene: builds the workshop, wires the board, camera, kiln sequence, gallery, UI and bot to
## GameState, and handles the user arguments (see README).

var baker: TextureBaker
var board: Board
var camera_rig: CameraRig
var sequence: KilnSequence
var gallery: Gallery
var cat: Cat
var input_ctl: InputController
var bot: Bot
var ui: Node
var world: Dictionary = {}
var sun: DirectionalLight3D
var fill_light: DirectionalLight3D
var environment: WorldEnvironment
var _time: float = 0.0
var _debug_label: Label = null
var _restart_at: float = -1.0
var _stats: bool = false
var _stats_frames: int = 0
var _stats_time: float = 0.0
var _stats_worst: float = 0.0


func _ready() -> void:
	if Args.has("speed"):
		Engine.time_scale = clampf(Args.number("speed", 1.0), 0.1, 20.0)
	_restart_at = Args.number("restart-at", -1.0)
	baker = TextureBaker.new()
	baker.name = "TextureBaker"
	add_child(baker)
	# world
	var world_root := Node3D.new()
	world_root.name = "World"
	add_child(world_root)
	world = WorldBuilder.build(world_root)
	gallery = Gallery.new()
	gallery.name = "Gallery"
	gallery.baker = baker
	world_root.add_child(gallery)
	cat = Cat.new()
	cat.name = "Cat"
	world_root.add_child(cat)
	# lights and environment
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color("#ffd9a6")
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 18.0
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.5
	sun.position = Vector3(-5.5, 8.0, -2.5)
	add_child(sun)
	sun.look_at(Vector3(0.5, 1.0, 0.5), Vector3.UP)
	fill_light = DirectionalLight3D.new()
	fill_light.name = "Fill"
	fill_light.light_color = Color("#c9b7a3")
	fill_light.light_energy = 0.18
	fill_light.shadow_enabled = false
	fill_light.position = Vector3(4.0, 3.0, 6.0)
	add_child(fill_light)
	fill_light.look_at(Vector3(0.0, 1.5, -1.0), Vector3.UP)
	environment = WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	environment.environment = _make_environment()
	add_child(environment)
	# board
	board = Board.new()
	board.name = "Board"
	board.baker = baker
	board.position = Vector3(0, WorldBuilder.TABLE_Y, 0)
	add_child(board)
	# camera
	camera_rig = CameraRig.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)
	# kiln sequence
	sequence = KilnSequence.new()
	sequence.name = "KilnSequence"
	sequence.board = board
	sequence.kiln_light = world["kiln_light"]
	sequence.kiln_glow = world["kiln_glow"]
	sequence.sparks = world["sparks"]
	sequence.gallery = gallery
	sequence.camera_rig = camera_rig
	sequence.baker = baker
	sequence.finished.connect(_on_sequence_finished)
	add_child(sequence)
	# input
	input_ctl = InputController.new()
	input_ctl.name = "InputController"
	input_ctl.board = board
	input_ctl.camera_rig = camera_rig
	add_child(input_ctl)
	# ui
	ui = load("res://scripts/ui/ui.gd").new()
	ui.name = "UI"
	ui.baker = baker
	add_child(ui)
	# bot
	bot = Bot.new()
	bot.name = "Bot"
	add_child(bot)
	# signals
	GameState.level_started.connect(_on_level_started)
	GameState.primitive_applied.connect(_on_primitive)
	GameState.board_changed.connect(_on_board_changed)
	GameState.puzzle_solved.connect(_on_solved)
	GameState.hint_sparkle.connect(_on_hint_sparkle)
	GameState.tile_denied.connect(_on_tile_denied)
	GameState.screen_changed.connect(_on_screen_changed)
	Settings.changed.connect(_apply_quality)
	_apply_quality()
	_bake_static_textures()
	gallery.rebuild()
	_perf_experiments()
	if Args.has("debug"):
		_make_debug_overlay()
	_stats = Args.has("stats")
	if _stats:
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		print("STATS quality=%s web=%s window=%s scale=%.2f args=%s" % [Settings.quality, Settings.is_web(), get_window().size, get_window().content_scale_factor, OS.get_cmdline_user_args() + Args._list()])
	_boot()


func _make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#5a3b26")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e9c9a2")
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("#5a3b26")
	env.fog_depth_begin = 16.0
	env.fog_depth_end = 30.0
	env.fog_depth_curve = 1.0
	env.glow_enabled = false
	env.glow_intensity = 0.35
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	return env


## High only: the generated workshop panorama feeds the glaze reflections (static sky, radiance computed
## once); the background and the ambient light stay the flat room colours. Low (the browser default) has
## no sky at all, so no radiance map is ever built or sampled.
func _apply_reflections(on: bool) -> void:
	var env: Environment = environment.environment
	if not on:
		env.sky = null
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		return
	if env.sky != null:
		return
	var pano := WorldBuilder.asset_texture("textures/workshop-pano.webp")
	if pano == null:
		return
	var mat := PanoramaSkyMaterial.new()
	mat.panorama = pano
	mat.energy_multiplier = 0.45
	var sky := Sky.new()
	sky.sky_material = mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY


func _apply_quality() -> void:
	var low: bool = Settings.is_low_quality()
	# One 16-bit 2048 (high) / 1024 (low) directional map is plenty for an 18 m orthogonal split and
	# costs a fraction of the engine's 4096 default; "low" samples it with a single hard tap instead
	# of the 13-tap soft filter. MSAA and glow are the two most expensive extras, so "low" drops them.
	sun.shadow_enabled = true
	RenderingServer.directional_shadow_atlas_set_size(1024 if low else 2048, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_HARD if low else RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	environment.environment.glow_enabled = not low
	_apply_reflections(not low)
	# on Low only the board and its tiles cast shadows; the generated props do not
	for m: Node3D in world["models"]:
		WorldBuilder.set_model_shadows(m, not low)
	cat.set_shadows(not low)
	baker.cell_px = 128 if low else 256
	var dust: CPUParticles3D = world["dust"]
	dust.amount = 60 if low else 170


## Temporary `--perf-*` switches for browser A/B measurements.
func _perf_experiments() -> void:
	if Args.has("perf-nocat"):
		cat.process_mode = Node.PROCESS_MODE_DISABLED
		cat.visible = false
	if Args.has("perf-noshadow"):
		sun.shadow_enabled = false
	if Args.has("perf-noui"):
		ui.visible = false
	if Args.has("perf-nodust"):
		(world["dust"] as CPUParticles3D).visible = false
	if Args.has("perf-nofx"):
		for k in ["dust", "kiln_glow", "sparks"]:
			(world[k] as Node3D).visible = false
		(world["kiln_light"] as Light3D).visible = false
	if Args.has("perf-no3d"):
		get_node("World").visible = false
		board.visible = false
	if Args.has("perf-nocredit"):
		var title: Node = ui.screens[GameState.SCREEN_TITLE]
		(title.get("_credit") as Control).visible = false
	if Args.has("perf-nofocus"):
		get_viewport().gui_release_focus()
		UiScreen.focus_disabled = true


func _bake_static_textures() -> void:
	var band: Texture2D = await baker.bake_band()
	board.setup_frame(band)
	if world["table_generated"]:
		return
	var wood: Texture2D = await baker.bake_wood()
	var table: MeshInstance3D = world["table"]
	var mat: StandardMaterial3D = table.material_override
	mat.albedo_texture = wood
	mat.albedo_color = Color.WHITE


func _boot() -> void:
	# `--keyboard`: behave as if the last input came from the keyboard (focus rings show), for screenshots
	if Args.has("keyboard"):
		UiScreen.keyboard_mode = true
	var lv: String = Args.value("level", "")
	if lv == "daily":
		GameState.start_level(GameState.DAILY)
	elif lv != "" and lv.is_valid_int():
		GameState.start_level(clampi(lv.to_int() - 1, 0, PuzzleCore.LEVEL_COUNT - 1))
	else:
		GameState.show_title()
	match Args.value("screen", ""):
		"levels":
			GameState.show_levels()
		"collection":
			GameState.show_collection()
		"settings":
			GameState.show_settings()
		"howto":
			GameState.show_howto(int(Args.number("ch", 0)))
		"pause", "menu":
			GameState.show_menu()


func _on_level_started(with_intro: bool) -> void:
	sequence.cancel()
	board.reset_transform()
	camera_rig.reset_view()
	board.build_tiles(with_intro)


func _on_primitive(m: Move, inverse: bool) -> void:
	board.apply_primitive(m, inverse)
	if inverse:
		return
	match m.type:
		Move.Type.ROT:
			Audio.play("rotate")
		Move.Type.SWAP:
			Audio.play("swap")
		Move.Type.FLIP:
			Audio.play("flip")
		_:
			pass


func _on_board_changed(is_undo: bool, newly_matched: int) -> void:
	board.update_glow()
	if not is_undo and newly_matched > 0:
		Audio.match_sound(newly_matched)


func _on_hint_sparkle(slot: int) -> void:
	board.sparkle_slot(slot)
	Audio.play("star")


func _on_tile_denied(slot: int) -> void:
	board.shake_slot(slot)
	Audio.play("deny")


func _on_solved(_result: Dictionary) -> void:
	Audio.match_sound(3)
	sequence.start()


func _on_sequence_finished() -> void:
	GameState.show_complete()


func _on_screen_changed(screen: StringName, _prev: StringName) -> void:
	if screen == GameState.SCREEN_TITLE:
		camera_rig.reset_view()
		if sequence.active:
			sequence.cancel()


func _process(delta: float) -> void:
	_time += delta
	var kiln_light: OmniLight3D = world["kiln_light"]
	var kiln_glow: MeshInstance3D = world["kiln_glow"]
	if not sequence.active:
		kiln_light.light_energy = 1.3 + sin(_time * 9.1) * 0.12 + sin(_time * 23.7) * 0.08 + sin(_time * 3.3) * 0.1
		var mat: StandardMaterial3D = kiln_glow.material_override
		mat.albedo_color.a = 0.75 + sin(_time * 11.0) * 0.1
	if _debug_label != null and Engine.get_process_frames() % 10 == 0:
		_update_debug()
	if _stats:
		_update_stats(delta)
	# test helper: `--restart-at SECONDS` reshuffles the board once at that time
	if _restart_at > 0.0 and _time >= _restart_at:
		_restart_at = -1.0
		GameState.restart_level()


func _make_debug_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugLayer"
	layer.layer = 50
	add_child(layer)
	_debug_label = Label.new()
	_debug_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_debug_label.offset_left = 10
	_debug_label.offset_bottom = -10
	_debug_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_debug_label.add_theme_color_override("font_color", Color.WHITE)
	_debug_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_debug_label.add_theme_font_size_override("font_size", 12)
	layer.add_child(_debug_label)


## `--stats`: one line per 60 frames with the frame time (avg / worst, ms), draw calls and primitives.
func _update_stats(delta: float) -> void:
	var real_delta: float = delta / maxf(Engine.time_scale, 0.001)
	_stats_frames += 1
	_stats_time += real_delta
	_stats_worst = maxf(_stats_worst, real_delta)
	if _stats_frames < 60:
		return
	var rid: RID = get_viewport().get_viewport_rid()
	print("STATS frame=%d fps=%d avg_ms=%.1f worst_ms=%.1f process_ms=%.2f cpu_ms=%.1f gpu_ms=%.1f draw_calls=%d prims=%d objects=%d screen=%s" % [
		Engine.get_process_frames(), Engine.get_frames_per_second(), _stats_time / _stats_frames * 1000.0, _stats_worst * 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(rid), RenderingServer.viewport_get_measured_render_time_gpu(rid),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), String(GameState.screen)])
	_stats_frames = 0
	_stats_time = 0.0
	_stats_worst = 0.0


func _update_debug() -> void:
	var calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var level: String = GameState.puzzle.key if GameState.puzzle != null else "-"
	_debug_label.text = "fps %d  draw calls %d  prims %d\nscreen %s  level %s  moves %d/%d  glow %d\nbot %s" % [
		Engine.get_frames_per_second(), calls, prims, String(GameState.screen), level,
		GameState.move_count() if GameState.puzzle != null else 0, GameState.puzzle.par if GameState.puzzle != null else 0,
		board.glow_count, JSON.stringify(GameState.bot_info)]
