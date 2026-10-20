class_name Gallery
extends Node3D
## The finished panels hanging on the back wall: a framed picture per collection entry (last 12).

var baker: TextureBaker
var _generation: int = 0


func rebuild() -> void:
	_generation += 1
	var gen: int = _generation
	for c in get_children():
		c.queue_free()
	var list: Array = GameState.wall_entries()
	for i in list.size():
		var entry: Dictionary = list[i]
		var p: Vector3 = WorldBuilder.gallery_slot_pos(i)
		var piece := Node3D.new()
		piece.name = "Piece%d" % i
		piece.position = p
		var frame := MeshInstance3D.new()
		frame.name = "Frame"
		var fm := BoxMesh.new()
		fm.size = Vector3(WorldBuilder.GALLERY_SIZE + 0.12, WorldBuilder.GALLERY_SIZE + 0.12, 0.06)
		frame.mesh = fm
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color("#c8923a") if int(entry["stars"]) == 3 else Color("#8a5a32")
		fmat.roughness = 0.8
		frame.material_override = fmat
		piece.add_child(frame)
		var nail := MeshInstance3D.new()
		nail.name = "Nail"
		var nm := BoxMesh.new()
		nm.size = Vector3(0.02, 0.02, 0.012)
		nail.mesh = nm
		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = Color("#6e4526")
		nail.material_override = nmat
		nail.position = Vector3(0, WorldBuilder.GALLERY_SIZE / 2 + 0.16, 0)
		piece.add_child(nail)
		var pic := MeshInstance3D.new()
		pic.name = "Picture"
		var qm := QuadMesh.new()
		qm.size = Vector2(WorldBuilder.GALLERY_SIZE, WorldBuilder.GALLERY_SIZE)
		pic.mesh = qm
		var pmat := StandardMaterial3D.new()
		pmat.roughness = 1.0
		pmat.albedo_color = Color(BoardPicture.BACKGROUND)
		pic.material_override = pmat
		pic.position = Vector3(0, 0, 0.035)
		pic.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.add_child(pic)
		add_child(piece)
		_assign_picture(pmat, entry, gen)


func _assign_picture(mat: StandardMaterial3D, entry: Dictionary, gen: int) -> void:
	var pz: Puzzle = GameState.puzzle_for_entry(entry)
	pz.key = str(entry["key"])
	var tex: Texture2D = await baker.bake_board_picture(pz, 128 if Settings.is_low_quality() else 256)
	if gen != _generation:
		return
	mat.albedo_texture = tex
	mat.albedo_color = Color.WHITE
