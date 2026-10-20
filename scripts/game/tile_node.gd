class_name TileNode
extends Node3D
## One tile on the board: a pivot that eases toward its slot, lifts when hovered or dragged,
## turns smoothly, hops on a swap and flips over to show its other face.

var id: int = 0
var slot: int = 0
var fixed: bool = false
var has_back: bool = false
var angle: float = 0.0
var vis_angle: float = 0.0
var x: float = 0.0
var z: float = 0.0
var lift: float = 0.0
var jump: float = 1.0
var intro: float = 1.0
var shake: float = 0.0
var sparkle: float = 0.0
var flip_t: float = -1.0
var flip_to_face: int = 0
var flip_swapped: bool = false
var mesh: MeshInstance3D = null
var mat: StandardMaterial3D = null
var uv_a: Vector3 = Vector3.ZERO
var uv_b: Vector3 = Vector3.ZERO
var tile_size: float = 1.0


func setup(shared_mesh: ArrayMesh, atlas: Texture2D, uv_scale: Vector3, offset_a: Vector3, offset_b: Vector3, face: int, side_mat: Material) -> void:
	mesh = MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = shared_mesh
	mat = StandardMaterial3D.new()
	mat.albedo_texture = atlas
	mat.uv1_scale = uv_scale
	mat.roughness = 0.32
	mat.metallic = 0.02
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.45)
	mat.emission_energy_multiplier = 0.0
	mesh.set_surface_override_material(0, mat)
	mesh.set_surface_override_material(1, side_mat)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh)
	uv_a = offset_a
	uv_b = offset_b
	mat.uv1_offset = uv_b if face == 1 else uv_a


func start_flip(to_face: int) -> void:
	flip_t = 0.0
	flip_to_face = to_face
	flip_swapped = false


func set_emission(e: float) -> void:
	mat.emission_energy_multiplier = e


static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


static func ease_in_out(t: float) -> float:
	return 4.0 * t * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0


func update(dt: float, target: Vector2, dragging: bool, hovered: bool) -> void:
	var k: float = 1.0 - exp(-dt * 14.0)
	var kp: float = 1.0 - exp(-dt * 11.0)
	vis_angle += (angle - vis_angle) * k
	if not dragging:
		x += (target.x - x) * kp
		z += (target.y - z) * kp
	if jump < 1.0:
		jump = minf(1.0, jump + dt / 0.5)
	var target_lift: float = 0.0
	if dragging:
		target_lift = 0.3
	elif hovered:
		target_lift = 0.03
	target_lift += sin(jump * PI) * 0.32
	if intro < 1.0:
		intro = minf(1.0, intro + dt / 0.5)
		var u: float = maxf(0.0, intro)
		target_lift += (1.0 - ease_out(u)) * 0.9
		mesh.scale = Vector3.ONE * (0.6 + 0.4 * ease_out(u))
	elif mesh.scale.x != 1.0:
		mesh.scale = Vector3.ONE
	var fx: float = 0.0
	if flip_t >= 0.0:
		flip_t = minf(1.0, flip_t + dt / 0.42)
		if flip_t < 0.5:
			fx = ease_in_out(flip_t * 2.0) * PI / 2.0
		else:
			if not flip_swapped:
				flip_swapped = true
				mat.uv1_offset = uv_b if flip_to_face == 1 else uv_a
			fx = -PI / 2.0 + ease_in_out((flip_t - 0.5) * 2.0) * PI / 2.0
		target_lift += sin(flip_t * PI) * tile_size * 0.55
		if flip_t >= 1.0:
			flip_t = -1.0
			fx = 0.0
	if shake > 0.0:
		shake -= dt
		fx += sin(shake * 60.0) * 0.08 * (shake / 0.35)
	if sparkle > 0.0:
		sparkle -= dt * 1.2
		mat.emission_energy_multiplier = maxf(0.0, sparkle) * 1.2
	lift += (target_lift - lift) * (1.0 - exp(-dt * 16.0))
	position = Vector3(x, 0.06 + lift, z)
	mesh.rotation = Vector3(fx, vis_angle, 0.0)
