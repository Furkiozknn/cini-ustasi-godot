class_name Board
extends Node3D
## The puzzle board on the table: dark base, patterned frame, the tiles, the golden glow on matched
## edges and the glaze sweep used by the kiln sequence.

const BOARD_SIZE: float = 3.6

var baker: TextureBaker = null
var pitch: float = 1.0
var tile_size: float = 1.0
var tile_h: float = 0.1
var tiles: Array[TileNode] = []
var tile_by_slot: Array[TileNode] = []
var drag: TileNode = null
var hover: TileNode = null
var glow_count: int = 0
var ready_for_input: bool = false

var _tiles_root: Node3D
var _base: MeshInstance3D
var _frame_top: MeshInstance3D
var _glow: MultiMeshInstance3D
var _glow_mat: StandardMaterial3D
var _sweep: MeshInstance3D
var _sweep_mat: StandardMaterial3D
var _shared_mesh: ArrayMesh = null
var _shared_key: String = ""
var _side_mat: StandardMaterial3D
var _generation: int = 0
## The last level's tile atlas: a restart or replay reuses it, so the tiles never vanish while a new one bakes.
var _atlas: Dictionary = {}
var _atlas_key: String = ""
var _time: float = 0.0
var _pulse_enabled: bool = true


func _ready() -> void:
	_tiles_root = Node3D.new()
	_tiles_root.name = "Tiles"
	add_child(_tiles_root)
	_side_mat = StandardMaterial3D.new()
	_side_mat.albedo_color = Color("#f4f0e4")
	_side_mat.roughness = 0.5
	# base and frame body (one merged mesh)
	var mb := MeshBuilder.new(3)
	mb.box(Vector3(BOARD_SIZE + 0.64, 0.06, BOARD_SIZE + 0.64), Vector3(0, 0.03, 0), Color("#3b2a1e"))
	var w: float = 0.3
	var off: float = BOARD_SIZE / 2 + w / 2
	mb.box(Vector3(BOARD_SIZE + 2 * w, 0.075, w), Vector3(0, 0.1, -off), Color("#2b4f8f"))
	mb.box(Vector3(BOARD_SIZE + 2 * w, 0.075, w), Vector3(0, 0.1, off), Color("#2b4f8f"))
	mb.box(Vector3(w, 0.075, BOARD_SIZE), Vector3(-off, 0.1, 0), Color("#2b4f8f"))
	mb.box(Vector3(w, 0.075, BOARD_SIZE), Vector3(off, 0.1, 0), Color("#2b4f8f"))
	_base = mb.instance(MeshBuilder.vertex_material(0.6), "Base", true)
	add_child(_base)
	_frame_top = MeshInstance3D.new()
	_frame_top.name = "FrameTop"
	_frame_top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_frame_top)
	# glow bars
	_glow = MultiMeshInstance3D.new()
	_glow.name = "Glow"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	mm.mesh = quad
	mm.instance_count = 128
	mm.visible_instance_count = 0
	_glow.multimesh = mm
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glow_mat.albedo_texture = _glow_texture()
	_glow_mat.albedo_color = Color(1.0, 0.82, 0.48, 0.85)
	_glow_mat.render_priority = 2
	_glow.material_override = _glow_mat
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)
	# glaze sweep
	_sweep = MeshInstance3D.new()
	_sweep.name = "Sweep"
	var sq := QuadMesh.new()
	sq.size = Vector2(0.7, BOARD_SIZE * 1.7)
	_sweep.mesh = sq
	_sweep_mat = WorldBuilder.additive_material(_glow_texture(), Color(1, 1, 1, 0.0))
	_sweep_mat.render_priority = 3
	_sweep.material_override = _sweep_mat
	_sweep.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sweep.basis = Basis(Vector3.UP, 0.5) * Basis(Vector3.RIGHT, -PI / 2)
	_sweep.position = Vector3(0, 0.25, 0)
	_sweep.visible = false
	add_child(_sweep)


func _glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.78, 0.35, 0.0))
	g.set_color(1, Color(1.0, 0.78, 0.35, 0.0))
	g.add_point(0.28, Color(1.0, 0.78, 0.35, 0.5))
	g.add_point(0.4, Color(1.0, 0.93, 0.6, 1.0))
	g.add_point(0.6, Color(1.0, 0.93, 0.6, 1.0))
	g.add_point(0.72, Color(1.0, 0.78, 0.35, 0.5))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 64
	return tex


## Builds the patterned top faces of the four frame bars with the band texture.
func setup_frame(band: Texture2D) -> void:
	var w: float = 0.3
	var off: float = BOARD_SIZE / 2 + w / 2
	var len_h: float = BOARD_SIZE + 2 * w
	var mb := MeshBuilder.new(1)
	var y: float = 0.1 + 0.075 / 2 + 0.002
	_frame_quad(mb, Vector3(0, y, -off), len_h, w, true)
	_frame_quad(mb, Vector3(0, y, off), len_h, w, true)
	_frame_quad(mb, Vector3(-off, y, 0), BOARD_SIZE, w, false)
	_frame_quad(mb, Vector3(off, y, 0), BOARD_SIZE, w, false)
	_frame_top.mesh = mb.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = band
	mat.roughness = 0.4
	_frame_top.material_override = mat


func _frame_quad(mb: MeshBuilder, centre: Vector3, length: float, width: float, along_x: bool) -> void:
	var hl: float = length / 2
	var hw: float = width / 2
	var reps: float = length / 0.55
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	if along_x:
		verts = PackedVector3Array([centre + Vector3(-hl, 0, -hw), centre + Vector3(hl, 0, -hw), centre + Vector3(hl, 0, hw), centre + Vector3(-hl, 0, hw)])
	else:
		verts = PackedVector3Array([centre + Vector3(-hw, 0, -hl), centre + Vector3(hw, 0, -hl), centre + Vector3(hw, 0, hl), centre + Vector3(-hw, 0, hl)])
	if along_x:
		uvs = PackedVector2Array([Vector2(0, 0), Vector2(reps, 0), Vector2(reps, 1), Vector2(0, 1)])
	else:
		uvs = PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(reps, 1), Vector2(reps, 0)])
	var normals := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	mb.add_raw(verts, normals, PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE, uvs)


func reset_transform() -> void:
	position = Vector3(0, WorldBuilder.TABLE_Y, 0)
	scale = Vector3.ONE
	rotation = Vector3.ZERO
	visible = true


func slot_local(p: int) -> Vector2:
	var n: int = GameState.puzzle.n
	@warning_ignore("integer_division")
	var r: int = p / n
	var c: int = p % n
	return Vector2((c - (n - 1) / 2.0) * pitch, (r - (n - 1) / 2.0) * pitch)


func slot_at_local(lx: float, lz: float) -> int:
	if GameState.puzzle == null:
		return -1
	var n: int = GameState.puzzle.n
	var c: int = roundi(lx / pitch + (n - 1) / 2.0)
	var r: int = roundi(lz / pitch + (n - 1) / 2.0)
	if c < 0 or c >= n or r < 0 or r >= n:
		return -1
	var centre := slot_local(r * n + c)
	if absf(lx - centre.x) > pitch * 0.5 or absf(lz - centre.y) > pitch * 0.5:
		return -1
	return r * n + c


func clear_tiles() -> void:
	for t in _tiles_root.get_children():
		t.queue_free()
	tiles = []
	tile_by_slot = []
	drag = null
	hover = null
	ready_for_input = false


## Bakes the level's atlas (or reuses it on a restart) and creates the tile nodes. Safe to call again
## while a bake is pending.
func build_tiles(with_intro: bool) -> void:
	_generation += 1
	var gen: int = _generation
	clear_tiles()
	var pz: Puzzle = GameState.puzzle
	if pz == null:
		return
	var n: int = pz.n
	pitch = BOARD_SIZE / n
	tile_size = pitch * 0.93
	tile_h = clampf(pitch * 0.11, 0.06, 0.11)
	var key: String = "%d" % n
	if _shared_key != key:
		_shared_mesh = TileMesh.build(tile_size, tile_h, tile_size * 0.07)
		_shared_key = key
	var atlas_key: String = "%s|%d|%d" % [pz.key, pz.seed_value, baker.cell_px]
	var atlas: Dictionary = _atlas
	if atlas_key != _atlas_key:
		atlas = await baker.bake_tile_atlas(pz)
		if gen != _generation or GameState.puzzle != pz:
			return
		_atlas = atlas
		_atlas_key = atlas_key
	var cols: int = atlas["cols"]
	var rows: int = atlas["rows"]
	var cells: Dictionary = atlas["cells"]
	var uv_scale := Vector3(1.0 / cols, 1.0 / rows, 1.0)
	tiles.resize(n * n)
	tile_by_slot.resize(n * n)
	for p in n * n:
		var s: SlotState = GameState.slots[p]
		var td: TileDef = pz.tiles[s.t]
		var tn := TileNode.new()
		tn.name = "Tile%d" % td.id
		tn.id = td.id
		tn.slot = p
		tn.fixed = td.fixed
		tn.has_back = td.is_two_sided()
		tn.tile_size = tile_size
		var ia: int = cells[td.id * 2]
		var ib: int = cells[td.id * 2 + 1] if td.is_two_sided() else ia
		var offset_a := Vector3(float(ia % cols) / cols, floorf(float(ia) / cols) / rows, 0.0)
		var offset_b := Vector3(float(ib % cols) / cols, floorf(float(ib) / cols) / rows, 0.0)
		tn.setup(_shared_mesh, atlas["texture"], uv_scale, offset_a, offset_b, s.face, _side_mat)
		var loc := slot_local(p)
		tn.x = loc.x
		tn.z = loc.y
		tn.angle = -s.rot * PI / 2.0
		tn.vis_angle = tn.angle
		tn.intro = -(p * 0.03) if with_intro else 1.0
		tn.position = Vector3(loc.x, 0.06, loc.y)
		tn.mesh.rotation.y = tn.angle
		_tiles_root.add_child(tn)
		tiles[td.id] = tn
		tile_by_slot[p] = tn
	update_glow()
	ready_for_input = true


func update_glow() -> void:
	var mm: MultiMesh = _glow.multimesh
	if GameState.puzzle == null or tiles.is_empty():
		mm.visible_instance_count = 0
		glow_count = 0
		return
	var ev := PuzzleCore.evaluate(GameState.puzzle, GameState.slots)
	var s: float = tile_size
	var w: float = maxf(0.1, pitch * 0.26)
	var count: int = mini(ev.matched.size(), mm.instance_count)
	var y: float = 0.06 + tile_h + 0.006
	for i in count:
		var code: int = ev.matched[i]
		var p: int = code >> 2
		var k: int = code & 3
		var c := slot_local(p)
		var ex: float = c.x
		var ez: float = c.y
		var along_x: bool = true
		match k:
			0:
				ez = c.y - s / 2
			2:
				ez = c.y + s / 2
			3:
				ex = c.x - s / 2
				along_x = false
			_:
				ex = c.x + s / 2
				along_x = false
		# quad lies flat; its local y (gradient axis) runs across the edge
		var basis := Basis(Vector3.RIGHT, -PI / 2)
		if not along_x:
			basis = Basis(Vector3.UP, PI / 2) * basis
		basis = Basis(basis.x * s * 0.98, basis.y * w, basis.z)
		mm.set_instance_transform(i, Transform3D(basis, Vector3(ex, y, ez)))
	mm.visible_instance_count = count
	glow_count = count


func apply_primitive(m: Move, inverse: bool) -> void:
	if tiles.is_empty():
		return
	match m.type:
		Move.Type.ROT:
			var t: TileNode = tile_by_slot[m.p]
			t.angle += PI / 2.0 if inverse else -PI / 2.0
		Move.Type.SWAP:
			var ta: TileNode = tile_by_slot[m.a]
			var tb: TileNode = tile_by_slot[m.b]
			tile_by_slot[m.a] = tb
			tile_by_slot[m.b] = ta
			ta.slot = m.b
			tb.slot = m.a
			ta.jump = 0.0
			tb.jump = 0.0
		Move.Type.FLIP:
			var t: TileNode = tile_by_slot[m.p]
			t.start_flip(GameState.slots[m.p].face)
		_:
			pass


func shake_slot(slot: int) -> void:
	if slot >= 0 and slot < tile_by_slot.size() and tile_by_slot[slot] != null:
		tile_by_slot[slot].shake = 0.35


func sparkle_slot(slot: int) -> void:
	if slot >= 0 and slot < tile_by_slot.size() and tile_by_slot[slot] != null:
		tile_by_slot[slot].sparkle = 1.0


func set_pulse(enabled: bool) -> void:
	_pulse_enabled = enabled


func set_glow_alpha(a: float) -> void:
	_glow_mat.albedo_color.a = a


func set_sweep(x: float, alpha: float) -> void:
	_sweep.visible = alpha > 0.0
	_sweep.position = Vector3(x, 0.25, x * 0.3)
	_sweep_mat.albedo_color.a = alpha
	for t in tiles:
		if t == null:
			continue
		var d: float = absf((t.x + t.z * 0.3) - x)
		t.set_emission(maxf(0.0, 0.35 - d * 0.6) * 2.5 if alpha > 0.0 else 0.0)


func _process(delta: float) -> void:
	_time += delta
	if _pulse_enabled:
		_glow_mat.albedo_color.a = 0.72 + sin(_time * 2.2) * 0.12
	var playing: bool = GameState.screen == GameState.SCREEN_PLAYING
	for t in tiles:
		if t == null:
			continue
		var target := slot_local(t.slot) if GameState.puzzle != null else Vector2(t.x, t.z)
		t.update(delta, target, drag == t, hover == t and playing)
