class_name TileMesh
extends RefCounted
## Bevelled tile geometry: surface 0 = top + bevel ring (textured with the atlas cell),
## surface 1 = sides + bottom (plain glaze colour).


static func build(s: float, h: float, b: float) -> ArrayMesh:
	var half: float = s / 2.0
	var inner: float = half - b
	var yb: float = h - b * 0.8
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	# top face
	var t0: int = _add(pos, nor, uv, Vector3(-inner, h, -inner), Vector3.UP, _uv_top(-inner, -inner, s))
	var t1: int = _add(pos, nor, uv, Vector3(inner, h, -inner), Vector3.UP, _uv_top(inner, -inner, s))
	var t2: int = _add(pos, nor, uv, Vector3(inner, h, inner), Vector3.UP, _uv_top(inner, inner, s))
	var t3: int = _add(pos, nor, uv, Vector3(-inner, h, inner), Vector3.UP, _uv_top(-inner, inner, s))
	idx.append_array(PackedInt32Array([t0, t1, t2, t0, t2, t3]))
	# bevel ring
	for i in 4:
		var a: Vector2 = corners[i]
		var c: Vector2 = corners[(i + 1) % 4]
		var n := Vector3((a.x + c.x) / 2.0, 1.2, (a.y + c.y) / 2.0).normalized()
		var i0: int = _add(pos, nor, uv, Vector3(a.x * inner, h, a.y * inner), n, _uv_top(a.x * inner, a.y * inner, s))
		var i1: int = _add(pos, nor, uv, Vector3(c.x * inner, h, c.y * inner), n, _uv_top(c.x * inner, c.y * inner, s))
		var o0: int = _add(pos, nor, uv, Vector3(a.x * half, yb, a.y * half), n, _uv_top(a.x * half, a.y * half, s))
		var o1: int = _add(pos, nor, uv, Vector3(c.x * half, yb, c.y * half), n, _uv_top(c.x * half, c.y * half, s))
		idx.append_array(PackedInt32Array([i0, o1, o0, i0, i1, o1]))
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pos
	arrays[Mesh.ARRAY_NORMAL] = nor
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# sides + bottom
	var pos2 := PackedVector3Array()
	var nor2 := PackedVector3Array()
	var uv2 := PackedVector2Array()
	var idx2 := PackedInt32Array()
	for i in 4:
		var a: Vector2 = corners[i]
		var c: Vector2 = corners[(i + 1) % 4]
		var n := Vector3((a.x + c.x) / 2.0, 0.0, (a.y + c.y) / 2.0)
		var p0: int = _add(pos2, nor2, uv2, Vector3(a.x * half, yb, a.y * half), n, Vector2(0, 0))
		var p1: int = _add(pos2, nor2, uv2, Vector3(c.x * half, yb, c.y * half), n, Vector2(1, 0))
		var p2: int = _add(pos2, nor2, uv2, Vector3(c.x * half, 0, c.y * half), n, Vector2(1, 1))
		var p3: int = _add(pos2, nor2, uv2, Vector3(a.x * half, 0, a.y * half), n, Vector2(0, 1))
		idx2.append_array(PackedInt32Array([p0, p1, p2, p0, p2, p3]))
	var b0: int = _add(pos2, nor2, uv2, Vector3(-half, 0, -half), Vector3.DOWN, Vector2(0, 0))
	var b1: int = _add(pos2, nor2, uv2, Vector3(half, 0, -half), Vector3.DOWN, Vector2(1, 0))
	var b2: int = _add(pos2, nor2, uv2, Vector3(half, 0, half), Vector3.DOWN, Vector2(1, 1))
	var b3: int = _add(pos2, nor2, uv2, Vector3(-half, 0, half), Vector3.DOWN, Vector2(0, 1))
	idx2.append_array(PackedInt32Array([b0, b3, b2, b0, b2, b1]))
	var arrays2: Array = []
	arrays2.resize(Mesh.ARRAY_MAX)
	arrays2[Mesh.ARRAY_VERTEX] = pos2
	arrays2[Mesh.ARRAY_NORMAL] = nor2
	arrays2[Mesh.ARRAY_TEX_UV] = uv2
	arrays2[Mesh.ARRAY_INDEX] = idx2
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays2)
	return mesh


static func _uv_top(x: float, z: float, s: float) -> Vector2:
	return Vector2(0.5 + x / s, 0.5 + z / s)


static func _add(pos: PackedVector3Array, nor: PackedVector3Array, uv: PackedVector2Array, p: Vector3, n: Vector3, t: Vector2) -> int:
	pos.append(p)
	nor.append(n)
	uv.append(t)
	return pos.size() - 1
