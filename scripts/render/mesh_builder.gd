class_name MeshBuilder
extends RefCounted
## Merges many vertex-coloured primitives into one ArrayMesh (one draw call per material).
## Mirrors the round-1 approach: tiny per-vertex colour jitter gives a hand-made feel.

var _verts := PackedVector3Array()
var _normals := PackedVector3Array()
var _colors := PackedColorArray()
var _uvs := PackedVector2Array()
var _indices := PackedInt32Array()
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value


func add_mesh(mesh: Mesh, xf: Transform3D, color: Color, jitter: float = 0.0, surface: int = 0) -> void:
	var arrays: Array = mesh.surface_get_arrays(surface)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var base: int = _verts.size()
	var nb: Basis = xf.basis.inverse().transposed()
	for i in v.size():
		_verts.append(xf * v[i])
		_normals.append((nb * n[i]).normalized() if i < n.size() else Vector3.UP)
		_uvs.append(uv[i] if i < uv.size() else Vector2.ZERO)
		var j: float = 1.0 + (_rng.randf() - 0.5) * jitter if jitter > 0.0 else 1.0
		_colors.append(Color(color.r * j, color.g * j, color.b * j, 1.0))
	if idx.is_empty():
		for i in v.size():
			_indices.append(base + i)
	else:
		for i in idx.size():
			_indices.append(base + idx[i])


## Adds a transformed point list directly (already triangulated, clockwise front faces).
func add_raw(verts: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, color: Color, uvs: PackedVector2Array = PackedVector2Array()) -> void:
	var base: int = _verts.size()
	for i in verts.size():
		_verts.append(verts[i])
		_normals.append(normals[i])
		_uvs.append(uvs[i] if i < uvs.size() else Vector2.ZERO)
		_colors.append(color)
	for i in indices.size():
		_indices.append(base + indices[i])


static func _basis(rot: Vector3) -> Basis:
	# boxes and tori: y, then x, then z (the round-1 order; only cylinders differ, see cylinder())
	var b := Basis.IDENTITY
	if rot.y != 0.0:
		b = Basis(Vector3.UP, rot.y) * b
	if rot.x != 0.0:
		b = Basis(Vector3.RIGHT, rot.x) * b
	if rot.z != 0.0:
		b = Basis(Vector3.BACK, rot.z) * b
	return b


func box(size: Vector3, pos: Vector3, color: Color, jitter: float = 0.0, rot: Vector3 = Vector3.ZERO) -> void:
	var m := BoxMesh.new()
	m.size = size
	add_mesh(m, Transform3D(_basis(rot), pos), color, jitter)


## Cylinders apply X first, then Z, then Y (like the browser version's cyl()): a handle laid flat with
## rot.x = PI/2 then points along (sin rot.y, 0, cos rot.y). With Y first, the Y turn would only spin the
## cylinder about its own axis.
func cylinder(top_r: float, bottom_r: float, h: float, pos: Vector3, color: Color, jitter: float = 0.0, rot: Vector3 = Vector3.ZERO, segments: int = 14) -> void:
	var m := CylinderMesh.new()
	m.top_radius = top_r
	m.bottom_radius = bottom_r
	m.height = h
	m.radial_segments = segments
	m.rings = 1
	var b := Basis(Vector3.UP, rot.y) * Basis(Vector3.BACK, rot.z) * Basis(Vector3.RIGHT, rot.x)
	add_mesh(m, Transform3D(b, pos), color, jitter)


func dome(r: float, pos: Vector3, color: Color, jitter: float = 0.0) -> void:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r
	m.is_hemisphere = true
	m.radial_segments = 18
	m.rings = 8
	add_mesh(m, Transform3D(Basis.IDENTITY, pos), color, jitter)


func torus(inner: float, outer: float, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> void:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 24
	m.ring_segments = 6
	add_mesh(m, Transform3D(_basis(rot), pos), color)


## A quad from four corners given clockwise as seen from the front (top-left first), UVs 0..uv_size.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv_size: Vector2, color: Color = Color.WHITE) -> void:
	var n: Vector3 = (d - a).cross(b - a).normalized()
	add_raw(PackedVector3Array([a, b, c, d]), PackedVector3Array([n, n, n, n]), PackedInt32Array([0, 1, 2, 0, 2, 3]), color,
		PackedVector2Array([Vector2.ZERO, Vector2(uv_size.x, 0), uv_size, Vector2(0, uv_size.y)]))


func plane(size: Vector2, pos: Vector3, color: Color, jitter: float = 0.0) -> void:
	var m := PlaneMesh.new()
	m.size = size
	add_mesh(m, Transform3D(Basis.IDENTITY, pos), color, jitter)


## Lathe: revolves a profile (x = radius, y = height) around Y. `band_h` > 0 alternates two colours by height.
func lathe(profile: Array[Vector2], pos: Vector3, color: Color, color2: Color = Color.WHITE, band_h: float = 0.0, segments: int = 18) -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()
	for i in profile.size():
		var p: Vector2 = profile[i]
		# approximate normal from neighbours
		var prev: Vector2 = profile[maxi(i - 1, 0)]
		var next: Vector2 = profile[mini(i + 1, profile.size() - 1)]
		var tangent: Vector2 = (next - prev).normalized()
		var n2 := Vector2(tangent.y, -tangent.x)
		for s in range(segments + 1):
			var a: float = TAU * s / segments
			verts.append(pos + Vector3(cos(a) * p.x, p.y, sin(a) * p.x))
			normals.append(Vector3(cos(a) * n2.x, n2.y, sin(a) * n2.x).normalized())
			var band: bool = band_h > 0.0 and int(floor(p.y / band_h)) % 2 == 1
			colors.append(color2 if band else color)
	for i in profile.size() - 1:
		for s in segments:
			var a: int = i * (segments + 1) + s
			var b: int = a + 1
			var c: int = a + segments + 1
			var d: int = c + 1
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var base: int = _verts.size()
	for i in verts.size():
		_verts.append(verts[i])
		_normals.append(normals[i])
		_uvs.append(Vector2.ZERO)
		_colors.append(colors[i])
	for i in indices.size():
		_indices.append(base + indices[i])


func commit() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if _verts.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_INDEX] = _indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func vertex_material(roughness: float = 0.95) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = roughness
	mat.metallic = 0.0
	return mat


func instance(material: Material, name: String, cast_shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
