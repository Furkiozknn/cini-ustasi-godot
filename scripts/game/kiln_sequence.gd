class_name KilnSequence
extends Node
## The completion show: the board glows, a glaze sweep shines across it, it lifts off the table and
## slides into the kiln, fires with sparks, and the finished panel flies out to the gallery wall.

signal finished

const DURATIONS: Dictionary = {"glow": 1.0, "shine": 1.3, "tokiln": 1.7, "fire": 1.5, "out": 1.9}

var board: Board
var kiln_light: OmniLight3D
var kiln_glow: MeshInstance3D
var sparks: CPUParticles3D
var gallery: Gallery
var camera_rig: CameraRig
var baker: TextureBaker

var active: bool = false
var phase: String = ""
var t: float = 0.0
var _transit: Node3D
var _transit_pic: MeshInstance3D
var _transit_mat: StandardMaterial3D
var _picture: Texture2D = null
var _key: String = ""


func _ready() -> void:
	_transit = Node3D.new()
	_transit.name = "Transit"
	_transit.visible = false
	var frame := MeshInstance3D.new()
	frame.name = "Frame"
	var fm := BoxMesh.new()
	fm.size = Vector3(WorldBuilder.GALLERY_SIZE + 0.12, WorldBuilder.GALLERY_SIZE + 0.12, 0.06)
	frame.mesh = fm
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color("#b07a35")
	frame_mat.roughness = 0.8
	frame.material_override = frame_mat
	_transit.add_child(frame)
	_transit_pic = MeshInstance3D.new()
	_transit_pic.name = "Picture"
	var pm := QuadMesh.new()
	pm.size = Vector2(WorldBuilder.GALLERY_SIZE, WorldBuilder.GALLERY_SIZE)
	_transit_pic.mesh = pm
	_transit_mat = StandardMaterial3D.new()
	_transit_mat.roughness = 1.0
	_transit_pic.material_override = _transit_mat
	_transit_pic.position = Vector3(0, 0, 0.035)
	_transit.add_child(_transit_pic)
	add_child(_transit)


func start() -> void:
	active = true
	phase = "glow"
	t = 0.0
	_key = GameState.puzzle.key
	board.set_pulse(false)
	board.drag = null
	board.hover = null
	_picture = null
	_bake_picture(GameState.puzzle)


func _bake_picture(pz: Puzzle) -> void:
	var tex: Texture2D = await baker.bake_board_picture(pz, 256)
	if pz.key == _key:
		_picture = tex


static func ease_in_out(u: float) -> float:
	return TileNode.ease_in_out(u)


func _process(delta: float) -> void:
	if not active:
		return
	t += delta
	var dur: float = DURATIONS[phase]
	var u: float = clampf(t / dur, 0.0, 1.0)
	var mouth: Vector3 = WorldBuilder.KILN_MOUTH
	match phase:
		"glow":
			board.set_glow_alpha(0.85 + 0.15 * sin(t * 12.0))
			if u >= 1.0:
				_next("shine")
		"shine":
			var x: float = lerpf(-Board.BOARD_SIZE * 1.1, Board.BOARD_SIZE * 1.1, ease_in_out(u))
			board.set_sweep(x, 0.75)
			if u >= 1.0:
				board.set_sweep(0.0, 0.0)
				_next("tokiln")
				camera_rig.focus = Vector3(mouth.x * 0.55, 0.0, 0.0)
				Audio.play("whoosh")
		"tokiln":
			var e: float = ease_in_out(u)
			var target := Vector3(mouth.x, mouth.y - 0.1, mouth.z - 0.3)
			# lift straight up first, travel and shrink, tilt only once clear of the table top
			var lift: float = sin(u * PI) * 1.5
			board.position = Vector3(lerpf(0.0, target.x, e), WorldBuilder.TABLE_Y + lift + e * (target.y - WorldBuilder.TABLE_Y), lerpf(0.0, target.z, e))
			board.scale = Vector3.ONE * lerpf(1.0, 0.22, e)
			var tilt: float = ease_in_out(clampf((u - 0.3) / 0.45, 0.0, 1.0))
			board.rotation = Vector3(0.4 * tilt, 0.0, sin(u * PI) * 0.15 * tilt)
			kiln_light.light_energy = 1.4 + u * 2.5
			kiln_glow.scale = Vector3.ONE * (1.0 + u * 0.6)
			if u >= 1.0:
				_next("fire")
				board.visible = false
				sparks.emitting = true
				camera_rig.shake(0.5)
				Audio.play("fire")
		"fire":
			kiln_light.light_energy = 3.5 + sin(t * 40.0) * 0.8 + sin(t * 23.0) * 0.5
			kiln_glow.scale = Vector3.ONE * (1.6 + sin(t * 30.0) * 0.15)
			if u >= 1.0:
				_next("out")
				camera_rig.focus = Vector3.ZERO
				_transit.visible = true
				_transit.position = mouth + Vector3(0, 0, 0.3)
				_transit.scale = Vector3.ONE * 0.3
				_transit.rotation = Vector3.ZERO
				_transit_mat.albedo_texture = _picture
				Audio.play("fanfare")
		"out":
			var e: float = ease_in_out(u)
			var slot_idx: int = GameState.wall_slot_for(_key)
			var dest: Vector3 = WorldBuilder.gallery_slot_pos(maxi(slot_idx, 0)) + Vector3(0, 0, 0.03)
			var start: Vector3 = mouth + Vector3(0, 0, 0.3)
			var dip: float = (u - 0.9) * 8.0 if u > 0.9 else 0.0
			# swing slightly down and towards the camera, then up onto the hook; a high arc would pass
			# behind the HUD bar at the top of the screen
			_transit.position = Vector3(lerpf(start.x, dest.x, e), lerpf(start.y, dest.y, e) - sin(u * PI) * 0.35, lerpf(start.z, dest.z + 0.6, e) - dip)
			_transit.scale = Vector3.ONE * lerpf(0.3, 1.0, e)
			_transit.rotation = Vector3(sin(u * PI) * 0.2, sin(u * PI) * 0.6, 0.0)
			kiln_light.light_energy = lerpf(3.5, 1.4, e)
			kiln_glow.scale = Vector3.ONE * lerpf(1.6, 1.0, e)
			if u >= 1.0:
				_finish()


func _next(p: String) -> void:
	phase = p
	t = 0.0


func _finish() -> void:
	active = false
	phase = ""
	_transit.visible = false
	sparks.emitting = false
	board.set_pulse(true)
	gallery.rebuild()
	finished.emit()


## Stops the show immediately (e.g. the player started another level mid-animation).
func cancel() -> void:
	if not active:
		return
	active = false
	phase = ""
	_transit.visible = false
	sparks.emitting = false
	kiln_light.light_energy = 1.4
	kiln_glow.scale = Vector3.ONE
	camera_rig.focus = Vector3.ZERO
	board.set_sweep(0.0, 0.0)
	board.set_pulse(true)
