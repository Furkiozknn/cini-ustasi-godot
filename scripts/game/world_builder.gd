class_name WorldBuilder
extends RefCounted
## Builds the static workshop: floor, walls, window, shelves, plates and vases, the kiln, the table
## with its props, and the effect nodes (kiln glow, sparks, dust). Returns the nodes other systems animate.
## Generated assets (models and textures in res://assets, shared with the browser version) replace their
## procedural counterparts; anything missing, and everything with `--noassets`, keeps the procedural version.

const TABLE_Y: float = 1.0
const WALL_Z: float = -4.2
const KILN_POS: Vector3 = Vector3(4.55, 0.0, -3.0)
const KILN_MOUTH: Vector3 = Vector3(4.55, 0.95, -2.1)
const GALLERY_COLS: int = 6
const GALLERY_ROWS: int = 2
const GALLERY_X0: float = -1.75
const GALLERY_DX: float = 0.92
const GALLERY_Y: Array[float] = [2.08, 1.32]
const GALLERY_SIZE: float = 0.62
const GALLERY_Z: float = WALL_Z + 0.03
const WINDOW_POS: Vector3 = Vector3(-4.0, 2.85, WALL_Z)
const WINDOW_SIZE: Vector2 = Vector2(2.6, 1.7)
## Stool seat top: the cat model sits here.
const STOOL_TOP: Vector3 = Vector3(-4.2, 0.63, 1.4)
## Model placement: yaw turns the file's front to +Z, the size fixes one dimension (metres), pos is the base centre.
const KILN_FIT: Dictionary = {"file": "models/kiln.glb", "yaw": -PI / 2, "depth": 2.4, "pos": Vector3(4.55, 0.0, -2.95)}
const PAINT_FIT: Dictionary = {"file": "models/paint-set.glb", "yaw": 0.0, "depth": 0.6, "pos": Vector3(2.68, TABLE_Y, 1.5)}
const CAT_FIT: Dictionary = {"file": "models/cat.glb", "yaw": 0.0, "height": 0.46, "pos": Vector3.ZERO}


static func use_assets() -> bool:
	return not Args.has("noassets")


## A generated texture from res://assets, or null (procedural fallback).
static func asset_texture(rel: String) -> Texture2D:
	var path: String = "res://assets/" + rel
	if not use_assets() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## Instances a generated model, turned by fit.yaw and uniformly scaled to fit.depth (z) or fit.height (y),
## with its base centre at the returned holder's origin (placed at fit.pos). Null when it is missing.
static func asset_model(fit: Dictionary) -> Node3D:
	var path: String = "res://assets/" + str(fit["file"])
	if not use_assets() or not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var model: Node3D = scene.instantiate() as Node3D
	var turn := Basis(Vector3.UP, float(fit["yaw"]))
	var box: Variant = _model_aabb(model, Transform3D(turn, Vector3.ZERO))
	if box == null:
		model.free()
		return null
	var b: AABB = box
	var sc: float = float(fit["depth"]) / b.size.z if fit.has("depth") else float(fit["height"]) / b.size.y
	var base := Vector3(b.position.x + b.size.x / 2.0, b.position.y, b.position.z + b.size.z / 2.0)
	model.transform = Transform3D(turn.scaled(Vector3.ONE * sc), -base * sc) * model.transform
	var holder := Node3D.new()
	holder.name = str(fit["file"]).get_file().get_basename().capitalize().replace(" ", "")
	holder.position = fit["pos"]
	holder.add_child(model)
	holder.set_meta("size", b.size * sc)
	return holder


## AABB of every mesh below `n`, in the space `xf` maps n's parent space into.
static func _model_aabb(n: Node, xf: Transform3D) -> Variant:
	var t: Transform3D = xf * (n as Node3D).transform if n is Node3D else xf
	var out: Variant = null
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
	for c in n.get_children():
		var a: Variant = _model_aabb(c, t)
		if a != null:
			out = a if out == null else (out as AABB).merge(a)
	return out


static func set_model_shadows(n: Node, cast: bool) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		set_model_shadows(c, cast)


static func _textured(tex: Texture2D, uv_scale: Vector2, tint: Color = Color.WHITE, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.roughness = roughness
	m.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


static func gallery_slot_pos(i: int) -> Vector3:
	@warning_ignore("integer_division")
	var r: int = i / GALLERY_COLS
	var c: int = i % GALLERY_COLS
	return Vector3(GALLERY_X0 + c * GALLERY_DX, GALLERY_Y[r], GALLERY_Z)


static func soft_texture(size: int = 64) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.4, Color(1, 1, 1, 0.5))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = size
	tex.height = size
	return tex


static func additive_material(tex: Texture2D, color: Color, billboard: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.albedo_texture = tex
	m.albedo_color = color
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	return m


static func build(parent: Node3D) -> Dictionary:
	var refs: Dictionary = {}
	var floor_tex := asset_texture("textures/floor-terracotta.webp")
	var plaster_tex := asset_texture("textures/plaster.webp")
	var kilim_tex := asset_texture("textures/kilim.webp")
	var kiln := asset_model(KILN_FIT)
	var paint := asset_model(PAINT_FIT)
	refs["room"] = _build_room(floor_tex == null, plaster_tex == null, kilim_tex == null, kiln == null)
	parent.add_child(refs["room"])
	refs["props"] = _build_props(paint == null)
	parent.add_child(refs["props"])
	var assets: PackedStringArray = []
	if floor_tex != null:
		# one 16 x 12 plane instead of 192 vertex-coloured quads and 30 grout strips
		var fl := MeshInstance3D.new()
		fl.name = "Floor"
		var pm := PlaneMesh.new()
		pm.size = Vector2(16, 12)
		fl.mesh = pm
		fl.position = Vector3(0, 0, 1)
		fl.material_override = _textured(floor_tex, Vector2(8, 6))
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(fl)
		assets.append("floor")
	if plaster_tex != null:
		# the three inner wall faces as one mesh, plaster repeated (4, 1.7) on each
		var wb := MeshBuilder.new(2)
		wb.quad(Vector3(-6.2, 5.2, WALL_Z), Vector3(6.2, 5.2, WALL_Z), Vector3(6.2, 0, WALL_Z), Vector3(-6.2, 0, WALL_Z), Vector2(4, 1.7))
		wb.quad(Vector3(-6.0, 5.2, 7), Vector3(-6.0, 5.2, -5), Vector3(-6.0, 0, -5), Vector3(-6.0, 0, 7), Vector2(4, 1.7))
		wb.quad(Vector3(6.0, 5.2, -5), Vector3(6.0, 5.2, 7), Vector3(6.0, 0, 7), Vector3(6.0, 0, -5), Vector2(4, 1.7))
		parent.add_child(wb.instance(_textured(plaster_tex, Vector2.ONE, Color("#fbf3e3"), 0.95), "Walls", false))
		assets.append("plaster")
	if kilim_tex != null:
		# a plane facing +X just in front of the left wall; its +u runs toward -z (left to right from the room)
		var rug := MeshInstance3D.new()
		rug.name = "Kilim"
		var qm := QuadMesh.new()
		qm.size = Vector2(1.6, 1.8)
		rug.mesh = qm
		rug.position = Vector3(-5.975, 2.4, -3.1)
		rug.rotation.y = PI / 2
		rug.material_override = _textured(kilim_tex, Vector2.ONE)
		rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(rug)
		assets.append("kilim")
	var glow_z: float = KILN_MOUTH.z + 0.1
	if kiln != null:
		set_model_shadows(kiln, true)
		parent.add_child(kiln)
		# the glow quad sits just inside the model's arched mouth
		glow_z = float(KILN_FIT["pos"].z) + (kiln.get_meta("size") as Vector3).z / 2.0 - 0.18
		assets.append("kiln")
	if paint != null:
		set_model_shadows(paint, true)
		parent.add_child(paint)
		assets.append("paint-set")
	refs["assets"] = assets
	refs["kiln_model"] = kiln != null
	# table top (textured later by Main once the wood texture is baked, or with the generated wood)
	var table := MeshInstance3D.new()
	table.name = "TableTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(6.4, 0.16, 4.6)
	table.mesh = tm
	table.position = Vector3(0, TABLE_Y - 0.08, 0)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#9c6a3e")
	wood.roughness = 0.75
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3(0.32, 0.32, 0.32)
	var wood_tex := asset_texture("textures/wood.webp")
	if wood_tex != null:
		# triplanar top projection: repeat (1.5, 1) over the 6.4 x 4.6 m top, as in the browser version
		wood.albedo_texture = wood_tex
		wood.albedo_color = Color.WHITE
		wood.uv1_scale = Vector3(1.5 / 6.4, 1.0, 1.0 / 4.6)
		wood.uv1_offset = Vector3(0.5, 0.0, 0.5)
		wood.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		assets.append("wood")
	table.material_override = wood
	table.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(table)
	refs["table"] = table
	refs["table_generated"] = wood_tex != null
	# window glass: the generated lake view, or a warm sky gradient
	var glass := MeshInstance3D.new()
	glass.name = "WindowGlass"
	var gm := QuadMesh.new()
	gm.size = WINDOW_SIZE
	glass.mesh = gm
	var glass_mat := StandardMaterial3D.new()
	glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var view := asset_texture("textures/window-view.webp")
	if view != null:
		glass_mat.albedo_texture = view
		glass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		assets.append("window")
	else:
		var sky := Gradient.new()
		sky.set_color(0, Color("#dcecff"))
		sky.add_point(0.55, Color("#fff3d2"))
		sky.set_color(2, Color("#ffd9a0"))
		var sky_tex := GradientTexture2D.new()
		sky_tex.gradient = sky
		sky_tex.fill_from = Vector2(0, 0)
		sky_tex.fill_to = Vector2(0, 1)
		sky_tex.width = 8
		sky_tex.height = 64
		glass_mat.albedo_texture = sky_tex
	glass.material_override = glass_mat
	# just in front of the wall face (it used to sit 4 cm inside the wall, so only the wall showed)
	glass.position = WINDOW_POS + Vector3(0, 0, 0.005)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(glass)
	# soft light shaft from the window toward the table
	var shaft := MeshInstance3D.new()
	shaft.name = "LightShaft"
	var sm := QuadMesh.new()
	sm.size = Vector2(2.4, 7.5)
	shaft.mesh = sm
	shaft.material_override = additive_material(null, Color(1.0, 227.0 / 255.0, 176.0 / 255.0, 0.045))
	shaft.position = Vector3(-2.2, 2.4, -1.6)
	shaft.basis = Basis.from_euler(Vector3(-0.9, 0.35, 0.3), EULER_ORDER_XYZ)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shaft)
	# kiln glow sprite
	var soft := soft_texture(64)
	var glow := MeshInstance3D.new()
	glow.name = "KilnGlow"
	var km := QuadMesh.new()
	km.size = Vector2(1.0, 0.8)
	glow.mesh = km
	glow.material_override = additive_material(soft, Color(1.0, 0.6, 0.23, 0.75))
	glow.position = Vector3(KILN_MOUTH.x, KILN_MOUTH.y, glow_z)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(glow)
	refs["kiln_glow"] = glow
	# kiln light
	var light := OmniLight3D.new()
	light.name = "KilnLight"
	light.light_color = Color("#ff8a2a")
	light.light_energy = 1.4
	light.omni_range = 7.0
	light.omni_attenuation = 1.6
	light.shadow_enabled = false
	light.position = KILN_MOUTH + Vector3(0, 0.1, 0.5)
	parent.add_child(light)
	refs["kiln_light"] = light
	# sparks
	var sparks := CPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.emitting = false
	sparks.amount = 50
	sparks.lifetime = 1.2
	sparks.one_shot = false
	sparks.explosiveness = 0.0
	sparks.randomness = 0.6
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparks.emission_box_extents = Vector3(0.25, 0.15, 0.05)
	sparks.direction = Vector3(0, 1, 0.7)
	sparks.spread = 35.0
	sparks.initial_velocity_min = 1.2
	sparks.initial_velocity_max = 2.8
	sparks.gravity = Vector3(0, -2.5, 0)
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.0
	var spark_mesh := QuadMesh.new()
	spark_mesh.size = Vector2(0.09, 0.09)
	spark_mesh.material = additive_material(soft_texture(32), Color("#ffb060"), true)
	sparks.mesh = spark_mesh
	sparks.position = Vector3(KILN_MOUTH.x, KILN_MOUTH.y, glow_z + 0.1)
	parent.add_child(sparks)
	refs["sparks"] = sparks
	# dust motes in the window light
	var dust := CPUParticles3D.new()
	dust.name = "Dust"
	dust.amount = 60 if Settings.is_low_quality() else 170
	dust.lifetime = 14.0
	dust.preprocess = 14.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(3.6, 1.7, 2.75)
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 180.0
	dust.initial_velocity_min = 0.04
	dust.initial_velocity_max = 0.12
	dust.gravity = Vector3.ZERO
	dust.randomness = 1.0
	var dust_mesh := QuadMesh.new()
	dust_mesh.size = Vector2(0.07, 0.07)
	dust_mesh.material = additive_material(soft_texture(32), Color(1.0, 233.0 / 255.0, 187.0 / 255.0, 0.55), true)
	dust.mesh = dust_mesh
	dust.position = Vector3(-0.2, 2.8, -0.75)
	parent.add_child(dust)
	refs["dust"] = dust
	return refs


## The merged vertex-coloured room; the parts a generated asset replaces are only built when it is missing.
static func _build_room(with_floor: bool, with_walls: bool, with_kilim: bool, with_kiln: bool) -> MeshInstance3D:
	var mb := MeshBuilder.new(7)
	if with_floor:
		# floor: terracotta tiles with slight variation
		for x in range(-8, 8):
			for z in range(-5, 7):
				var col := Color("#a9603f") if (x + z) % 2 != 0 else Color("#b56b47")
				mb.plane(Vector2(1, 1), Vector3(x + 0.5, 0, z + 0.5), col, 0.1)
		for x in range(-8, 9):
			mb.box(Vector3(0.03, 0.005, 12), Vector3(x, 0.003, 1), Color("#7a4530"))
		for z in range(-5, 8):
			mb.box(Vector3(16, 0.005, 0.03), Vector3(0, 0.003, z), Color("#7a4530"))
	if with_walls:
		mb.box(Vector3(12.4, 5.2, 0.2), Vector3(0, 2.6, WALL_Z - 0.1), Color("#ecdfc3"), 0.03)
		mb.box(Vector3(0.2, 5.2, 12), Vector3(-6.1, 2.6, 1), Color("#dfd0b0"), 0.03)
		mb.box(Vector3(0.2, 5.2, 12), Vector3(6.1, 2.6, 1), Color("#e4d5b6"), 0.03)
	# skirting
	mb.box(Vector3(12.4, 0.18, 0.06), Vector3(0, 0.09, WALL_Z + 0.03), Color("#6e4a2e"))
	mb.box(Vector3(0.06, 0.18, 12), Vector3(-5.97, 0.09, 1), Color("#6e4a2e"))
	mb.box(Vector3(0.06, 0.18, 12), Vector3(5.97, 0.09, 1), Color("#6e4a2e"))
	# window frame, sill and mullions
	var wx: float = WINDOW_POS.x
	var wy: float = WINDOW_POS.y
	var ww: float = WINDOW_SIZE.x
	var wh: float = WINDOW_SIZE.y
	var wz: float = WALL_Z + 0.02
	var frame := Color("#f7f0e0")
	mb.box(Vector3(ww + 0.3, 0.14, 0.16), Vector3(wx, wy + wh / 2 + 0.07, wz), frame)
	mb.box(Vector3(ww + 0.3, 0.16, 0.26), Vector3(wx, wy - wh / 2 - 0.08, wz + 0.06), frame)
	mb.box(Vector3(0.14, wh, 0.16), Vector3(wx - ww / 2 - 0.07, wy, wz), frame)
	mb.box(Vector3(0.14, wh, 0.16), Vector3(wx + ww / 2 + 0.07, wy, wz), frame)
	mb.box(Vector3(0.07, wh, 0.1), Vector3(wx, wy, wz + 0.02), frame)
	mb.box(Vector3(ww, 0.07, 0.1), Vector3(wx, wy, wz + 0.02), frame)
	# potted plant on the sill
	mb.cylinder(0.12, 0.09, 0.2, Vector3(wx - 0.9, wy - wh / 2 + 0.1, wz + 0.1), Color("#b86a45"))
	for i in 5:
		var a: float = float(i) / 5.0 * TAU
		mb.box(Vector3(0.16, 0.05, 0.08), Vector3(wx - 0.9 + cos(a) * 0.1, wy - wh / 2 + 0.26 + (i % 2) * 0.05, wz + 0.1 + sin(a) * 0.08), Color("#4f8a4a"), 0.0, Vector3(0, a, 0))
	# two wooden ledges on the back wall for the finished panels
	for gy in GALLERY_Y:
		mb.box(Vector3(5.9, 0.05, 0.14), Vector3(0.55, gy - GALLERY_SIZE / 2 - 0.1, WALL_Z + 0.07), Color("#8a5a32"), 0.05)
		for bx in [-2.1, 0.55, 3.2]:
			mb.box(Vector3(0.08, 0.14, 0.1), Vector3(bx, gy - GALLERY_SIZE / 2 - 0.2, WALL_Z + 0.05), Color("#6e4526"))
	if with_kilim:
		# kilim rug on the left wall
		var rz: float = -3.1
		var ry0: float = 1.5
		var rug: Array[Color] = [Color("#a33b2a"), Color("#e0b85a"), Color("#1f4e9c"), Color("#a33b2a"), Color("#f1e7d0")]
		for i in 9:
			mb.box(Vector3(0.04, 0.2, 1.6), Vector3(-5.95, ry0 + i * 0.2, rz), rug[i % 5])
		for i in 4:
			mb.box(Vector3(0.05, 1.8, 0.05), Vector3(-5.94, ry0 + 0.8, rz - 0.7 + i * 0.47), Color("#f1e7d0"))
	# shelves on the right wall with brackets
	for sy in [2.55, 3.45]:
		mb.box(Vector3(0.62, 0.06, 3.0), Vector3(5.69, sy, -2.5), Color("#8a5a32"), 0.05)
		for bz in [-3.7, -1.3]:
			mb.box(Vector3(0.5, 0.06, 0.08), Vector3(5.72, sy - 0.2, bz), Color("#6e4526"), 0.0, Vector3(0, 0, 0.5))
	# plates standing on the shelves (white with coloured rims); the rims share the disc's tilt and sit on its
	# front face (x 5.533), not inside the disc
	var plates: Array = [[-3.6, 3.45, "#1f4e9c"], [-2.8, 3.45, "#1fa3a3"], [-2.0, 3.45, "#d9452b"], [-1.25, 3.45, "#2e8b57"], [-3.85, 2.55, "#2e8b57"]]
	for p in plates:
		var pz: float = p[0]
		var py: float = p[1]
		var rim := Color(p[2])
		mb.cylinder(0.3, 0.3, 0.035, Vector3(5.55, py + 0.33, pz), Color("#f6f1e4"), 0.0, Vector3(0, 0, PI / 2 - 0.22), 24)
		mb.torus(0.255, 0.305, Vector3(5.52, py + 0.33, pz), rim, Vector3(0, 0, PI / 2 - 0.22))
		mb.torus(0.12, 0.16, Vector3(5.515, py + 0.33, pz), rim, Vector3(0, 0, PI / 2 - 0.22))
	# vases: banded colours
	var profile: Array = [[0, 0], [0.16, 0], [0.22, 0.08], [0.2, 0.3], [0.1, 0.42], [0.12, 0.52], [0, 0.53]]
	var vases: Array = [[-1.15, 2.55, "#1f4e9c", 1.0], [-1.6, 3.45, "#1fa3a3", 0.7], [-3.95, 3.45, "#d9452b", 0.75], [-0.95, 3.45, "#f6f1e4", 0.9]]
	for v in vases:
		var sc: float = v[3]
		var pts: Array[Vector2] = []
		for p in profile:
			pts.append(Vector2(p[0] * sc, p[1] * sc))
		mb.lathe(pts, Vector3(5.6, v[1] + 0.03, v[0]), Color(v[2]), Color("#f6f1e4"), 0.09 * sc)
	var k: Vector3 = KILN_POS
	if with_kiln:
		# kiln: stone base, brick body, dome, chimney, mouth
		mb.box(Vector3(2.1, 0.2, 2.1), Vector3(k.x, 0.1, k.z), Color("#6f5a4c"), 0.06)
		mb.box(Vector3(1.7, 1.9, 1.7), Vector3(k.x, 1.15, k.z), Color("#a4583a"), 0.08)
		for i in 6:
			mb.box(Vector3(1.72, 0.02, 1.72), Vector3(k.x, 0.45 + i * 0.28, k.z), Color("#7b3f28"))
		mb.dome(0.86, Vector3(k.x, 2.1, k.z), Color("#9a5234"), 0.06)
		mb.cylinder(0.16, 0.2, 1.3, Vector3(k.x - 0.3, 3.1, k.z - 0.35), Color("#5c3a2a"))
		mb.box(Vector3(0.9, 0.7, 0.3), Vector3(k.x, 0.95, k.z + 0.75), Color("#1a0c06"))
		for i in 7:
			var a: float = PI * i / 6.0
			mb.box(Vector3(0.16, 0.14, 0.12), Vector3(k.x + cos(a) * 0.52, 0.95 + sin(a) * 0.42 + 0.05, k.z + 0.86), Color("#c98a62"), 0.0, Vector3(0, 0, a - PI / 2))
		mb.box(Vector3(1.2, 0.08, 0.5), Vector3(k.x, 0.56, k.z + 1.0), Color("#6f5a4c"))
	# log pile next to the kiln (the kiln model is wider than the procedural one: keep the logs clear of it)
	var logs_x: float = k.x - (1.35 if with_kiln else 1.62)
	for i in 5:
		@warning_ignore("integer_division")
		var row: int = i / 3
		mb.cylinder(0.1, 0.1, 0.9, Vector3(logs_x + (i % 3) * 0.22, 0.1 + row * 0.19, k.z + 0.3), Color("#7a5236"), 0.0, Vector3(PI / 2, 0, 0), 8)
	# table legs + apron
	for leg in [[-2.95, -2.0], [2.95, -2.0], [-2.95, 2.0], [2.95, 2.0]]:
		mb.box(Vector3(0.16, 0.92, 0.16), Vector3(leg[0], 0.46, leg[1]), Color("#6e4526"), 0.05)
	mb.box(Vector3(6.1, 0.14, 0.08), Vector3(0, 0.84, 2.07), Color("#6e4526"))
	mb.box(Vector3(6.1, 0.14, 0.08), Vector3(0, 0.84, -2.07), Color("#6e4526"))
	mb.box(Vector3(0.08, 0.14, 4.1), Vector3(-3.0, 0.84, 0), Color("#6e4526"))
	mb.box(Vector3(0.08, 0.14, 4.1), Vector3(3.0, 0.84, 0), Color("#6e4526"))
	# a stool at the front
	var st: Vector3 = STOOL_TOP
	mb.cylinder(0.3, 0.26, 0.06, Vector3(st.x, st.y - 0.03, st.z), Color("#8a5a32"), 0.0, Vector3.ZERO, 12)
	for i in 3:
		var a: float = float(i) / 3.0 * TAU + 0.4
		mb.cylinder(0.04, 0.04, 0.6, Vector3(st.x + cos(a) * 0.2, 0.3, st.z + sin(a) * 0.2), Color("#6e4526"), 0.0, Vector3.ZERO, 6)
	return mb.instance(MeshBuilder.vertex_material(0.95), "Room", false)


## Table props. The pots and brushes are only built when the generated paint set is missing.
static func _build_props(with_paint: bool) -> MeshInstance3D:
	var mb := MeshBuilder.new(11)
	if with_paint:
		# paint pots: ceramic body, paint disc on top (pot 1 clears the board frame, x <= 3.05 stays on the table)
		var pots: Array = [["#1f4e9c", 2.4, 1.45], ["#1fa3a3", 2.75, 1.65], ["#d9452b", 3.0, 1.3], ["#2e8b57", 2.7, 1.1]]
		for p in pots:
			mb.cylinder(0.15, 0.13, 0.24, Vector3(p[1], TABLE_Y + 0.12, p[2]), Color("#e8dcc4"), 0.0, Vector3.ZERO, 14)
			mb.cylinder(0.12, 0.12, 0.02, Vector3(p[1], TABLE_Y + 0.245, p[2]), Color(p[0]), 0.0, Vector3.ZERO, 14)
		# brushes on the free strip left of the board: each handle points along (sin a, 0, cos a) and
		# the collar and tip sit on that same axis
		var handles: Array[Color] = [Color("#c69a5a"), Color("#8a5a32"), Color("#d9b67a")]
		var tips: Array[Color] = [Color("#1f4e9c"), Color("#d9452b"), Color("#2b2a3d")]
		for i in 3:
			var bx: float = -2.9 + i * 0.17
			var bz: float = 1.45
			var a: float = -0.1 + i * 0.1
			mb.cylinder(0.022, 0.03, 0.9, Vector3(bx, TABLE_Y + 0.03, bz), handles[i], 0.0, Vector3(PI / 2, a, 0), 8)
			mb.cylinder(0.026, 0.026, 0.1, Vector3(bx + sin(a) * 0.5, TABLE_Y + 0.03, bz + cos(a) * 0.5), Color("#c9c9c9"), 0.0, Vector3(PI / 2, a, 0), 8)
			mb.cylinder(0.006, 0.026, 0.14, Vector3(bx + sin(a) * 0.62, TABLE_Y + 0.03, bz + cos(a) * 0.62), tips[i], 0.0, Vector3(PI / 2, a, 0), 8)
	# water bowl
	mb.cylinder(0.3, 0.22, 0.16, Vector3(2.5, TABLE_Y + 0.08, -1.45), Color("#dcd2bb"), 0.0, Vector3.ZERO, 18)
	mb.cylinder(0.26, 0.26, 0.02, Vector3(2.5, TABLE_Y + 0.15, -1.45), Color("#9fcfe0"), 0.0, Vector3.ZERO, 18)
	# stack of blank tiles + a folded cloth (clear of the board base edge at x -2.12)
	for i in 4:
		mb.box(Vector3(0.5, 0.05, 0.5), Vector3(-2.65 + i * 0.01, TABLE_Y + 0.03 + i * 0.052, -1.3 - i * 0.015), Color("#f3eee0"), 0.0, Vector3(0, i * 0.06, 0))
	mb.box(Vector3(0.5, 0.04, 0.5), Vector3(-2.65, TABLE_Y + 0.02, 0.5), Color("#3f5a9c"), 0.08)
	mb.box(Vector3(0.4, 0.04, 0.4), Vector3(-2.62, TABLE_Y + 0.06, 0.48), Color("#4b67ac"), 0.08)
	return mb.instance(MeshBuilder.vertex_material(0.9), "Props", true)
