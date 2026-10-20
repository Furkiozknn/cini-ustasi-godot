class_name Gallery
extends Node3D
## The finished panels hanging on the back wall (the last 12 collection entries). Two draw calls: one
## merged vertex-coloured mesh for every frame and nail, and one mesh for all pictures, which sample a
## 6 x 2 atlas composed from the cached board pictures.

## Same size as the kiln's transit picture, so the newest panel is a cache hit.
const PICTURE_PX: int = 256

var baker: TextureBaker
var _generation: int = 0
var _frames: MeshInstance3D
var _pictures: MeshInstance3D
var _pic_mat: StandardMaterial3D


func _ready() -> void:
	_frames = MeshInstance3D.new()
	_frames.name = "Frames"
	_frames.material_override = MeshBuilder.vertex_material(0.8)
	add_child(_frames)
	_pictures = MeshInstance3D.new()
	_pictures.name = "Pictures"
	_pictures.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pic_mat = StandardMaterial3D.new()
	_pic_mat.roughness = 1.0
	_pic_mat.albedo_color = BoardPicture.BACKGROUND
	_pic_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_pictures.material_override = _pic_mat
	add_child(_pictures)


func rebuild() -> void:
	_generation += 1
	var gen: int = _generation
	var list: Array = GameState.wall_entries()
	var cols: int = WorldBuilder.GALLERY_COLS
	var rows: int = WorldBuilder.GALLERY_ROWS
	var s: float = WorldBuilder.GALLERY_SIZE
	var h: float = s / 2.0
	var fb := MeshBuilder.new(9)
	var pb := MeshBuilder.new(10)
	var puzzles: Array = []
	for i in list.size():
		var entry: Dictionary = list[i]
		var p: Vector3 = WorldBuilder.gallery_slot_pos(i)
		var gold: bool = int(entry["stars"]) == 3
		fb.box(Vector3(s + 0.12, s + 0.12, 0.06), p, Color("#c8923a") if gold else Color("#8a5a32"))
		fb.box(Vector3(0.02, 0.02, 0.012), p + Vector3(0, h + 0.16, 0), Color("#6e4526"))
		@warning_ignore("integer_division")
		var uv := Vector2(float(i % cols) / cols, float(i / cols) / rows)
		var cell := Vector2(1.0 / cols, 1.0 / rows)
		var z: float = p.z + 0.035
		pb.add_raw(
			PackedVector3Array([Vector3(p.x - h, p.y + h, z), Vector3(p.x + h, p.y + h, z), Vector3(p.x + h, p.y - h, z), Vector3(p.x - h, p.y - h, z)]),
			PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK]),
			PackedInt32Array([0, 1, 2, 0, 2, 3]), Color.WHITE,
			PackedVector2Array([uv, uv + Vector2(cell.x, 0), uv + cell, uv + Vector2(0, cell.y)]))
		var pz: Puzzle = GameState.puzzle_for_entry(entry)
		pz.key = str(entry["key"])
		puzzles.append(pz)
	var frames: ArrayMesh = fb.commit()
	var pictures: ArrayMesh = pb.commit()
	if list.is_empty():
		_frames.mesh = frames
		_pictures.mesh = pictures
		return
	# keep the old wall until the new atlas is ready, so no picture shows in the wrong frame
	var tex: Texture2D = await baker.bake_gallery_atlas(puzzles, cols, rows, PICTURE_PX)
	if gen != _generation:
		return
	_frames.mesh = frames
	_pictures.mesh = pictures
	_pic_mat.albedo_texture = tex
	_pic_mat.albedo_color = Color.WHITE
