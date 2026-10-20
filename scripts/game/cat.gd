class_name Cat
extends Node3D
## The workshop cat. With the generated model it sits on the stool by the table: it appears, breathes,
## turns its head now and then and leaves again (a static mesh walking would look wrong). Without the
## model (`--noassets`) the procedural box cat strolls along the upper shelf, sits a while and walks back.

const SHELF_Y: float = 2.58
const Z_HIDDEN: float = -3.5
const Z_SIT: float = -1.55
const WALK: float = 6.0
const SIT: float = 6.0
## Yaw that turns the +X-facing model toward the board and the camera.
const FACE_YAW: float = -0.54

var phase: String = "hidden"
var t: float = 0.0
var next_in: float = 3.0
var stay: float = 20.0
var _time: float = 0.0
var _tail: MeshInstance3D
var _model: Node3D = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	_model = WorldBuilder.asset_model(WorldBuilder.CAT_FIT)
	if _model != null:
		WorldBuilder.set_model_shadows(_model, true)
		add_child(_model)
		next_in = 4.0
		visible = false
		return
	var fur := Color("#3a3744")
	var fur2 := Color("#4a4656")
	var mb := MeshBuilder.new(5)
	mb.box(Vector3(0.42, 0.2, 0.18), Vector3(0, 0.19, 0), fur, 0.05)
	mb.box(Vector3(0.2, 0.18, 0.17), Vector3(0.26, 0.3, 0), fur2)
	mb.box(Vector3(0.05, 0.08, 0.05), Vector3(0.3, 0.42, 0.05), fur)
	mb.box(Vector3(0.05, 0.08, 0.05), Vector3(0.3, 0.42, -0.05), fur)
	mb.box(Vector3(0.04, 0.02, 0.03), Vector3(0.37, 0.28, 0), Color("#e9a3a3"))
	for leg in [[-0.14, 0.06], [-0.14, -0.06], [0.12, 0.06], [0.12, -0.06]]:
		mb.box(Vector3(0.07, 0.14, 0.06), Vector3(leg[0], 0.07, leg[1]), fur)
	mb.box(Vector3(0.02, 0.03, 0.03), Vector3(0.365, 0.33, 0.045), Color("#d9c25a"))
	mb.box(Vector3(0.02, 0.03, 0.03), Vector3(0.365, 0.33, -0.045), Color("#d9c25a"))
	add_child(mb.instance(MeshBuilder.vertex_material(0.95), "Body", true))
	var tb := MeshBuilder.new(6)
	tb.cylinder(0.025, 0.035, 0.36, Vector3(0, 0.18, 0), fur, 0.0, Vector3.ZERO, 6)
	_tail = tb.instance(MeshBuilder.vertex_material(0.95), "Tail", true)
	_tail.position = Vector3(-0.22, 0.2, 0)
	_tail.rotation.z = 1.1
	add_child(_tail)
	position = Vector3(5.55, SHELF_Y, -2.5)
	visible = false


func _process(delta: float) -> void:
	t += delta
	_time += delta
	if _model != null:
		_process_model()
	else:
		_process_walk()


func _process_model() -> void:
	if phase == "hidden":
		if t < next_in:
			return
		phase = "in"
		t = 0.0
		visible = true
	var s: float = 1.0
	var y: float = WorldBuilder.STOOL_TOP.y
	match phase:
		"in":
			var u: float = minf(1.0, t / 0.6)
			s = 0.6 + 0.4 * TileNode.ease_out(u)
			y += (1.0 - TileNode.ease_out(u)) * 0.35
			if u >= 1.0:
				phase = "sit"
				t = 0.0
				stay = 18.0 + _rng.randf() * 14.0
		"sit":
			if t >= stay:
				phase = "out"
				t = 0.0
		"out":
			var u: float = minf(1.0, t / 0.5)
			s = 1.0 - 0.4 * u
			y += TileNode.ease_in_out(u) * 0.3
			if u >= 1.0:
				phase = "hidden"
				t = 0.0
				next_in = 25.0 + _rng.randf() * 30.0
				visible = false
	var breathe: float = 1.0 + sin(_time * TAU * 0.3) * 0.015
	var look: float = sin(_time * 0.45) * 0.3 * maxf(0.0, sin(_time * 0.13))
	position = Vector3(WorldBuilder.STOOL_TOP.x, y, WorldBuilder.STOOL_TOP.z)
	rotation.y = FACE_YAW + look
	scale = Vector3(s, s * breathe, s)


func _process_walk() -> void:
	match phase:
		"hidden":
			if t >= next_in:
				phase = "walk"
				t = 0.0
				visible = true
				position.z = Z_HIDDEN
				rotation.y = -PI / 2
		"walk":
			var u: float = minf(1.0, t / WALK)
			position.z = lerpf(Z_HIDDEN, Z_SIT, u)
			position.y = SHELF_Y + absf(sin(t * 7.0)) * 0.02
			_tail.rotation.x = sin(t * 5.0) * 0.4
			if u >= 1.0:
				phase = "sit"
				t = 0.0
		"sit":
			_tail.rotation.x = sin(t * 2.5) * 0.7
			position.y = SHELF_Y
			if t >= SIT:
				phase = "back"
				t = 0.0
				rotation.y = PI / 2
		"back":
			var u: float = minf(1.0, t / WALK)
			position.z = lerpf(Z_SIT, Z_HIDDEN, u)
			position.y = SHELF_Y + absf(sin(t * 7.0)) * 0.02
			_tail.rotation.x = sin(t * 5.0) * 0.4
			if u >= 1.0:
				phase = "hidden"
				t = 0.0
				next_in = 28.0 + _rng.randf() * 30.0
				visible = false
