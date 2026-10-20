class_name TextureBaker
extends Node
## Renders Control drawings into textures with throw-away SubViewports: the tile atlas of a level,
## finished-board pictures and the frame band. In headless mode it returns flat placeholders.

var headless: bool = false
var cell_px: int = 256
var _picture_cache: Dictionary = {}
var _band: ImageTexture = null
var _wood: ImageTexture = null
var _logo: ImageTexture = null


func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"


func _placeholder(color: Color = Color.WHITE) -> ImageTexture:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _capture(vp: SubViewport, mipmaps: bool) -> ImageTexture:
	# Let the controls flush their draw commands first, only then render the target once, then
	# wait for that render to finish before reading it back.
	await get_tree().process_frame
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		push_warning("TextureBaker: empty capture")
		return _placeholder()
	if Args.has("debug"):
		print("bake %dx%d centre=%s corner=%s" % [img.get_width(), img.get_height(), img.get_pixel(img.get_width() / 2, img.get_height() / 2), img.get_pixel(8, 8)])
	if mipmaps:
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _make_viewport(w: int, h: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("#f4f0e4")
	bg.size = Vector2(w, h)
	vp.add_child(bg)
	return vp


## Bakes every face of a puzzle into one atlas. Returns {texture, cols, rows, cells: {tile_id * 2 + face: index}}.
func bake_tile_atlas(pz: Puzzle) -> Dictionary:
	var faces: Array = [] # [tile_id, face]
	for td in pz.tiles:
		for f in td.faces.size():
			faces.append([td.id, f])
	var cols: int = ceili(sqrt(float(faces.size())))
	var rows: int = ceili(float(faces.size()) / cols)
	var cells: Dictionary = {}
	for i in faces.size():
		cells[faces[i][0] * 2 + faces[i][1]] = i
	if headless:
		return {"texture": _placeholder(), "cols": cols, "rows": rows, "cells": cells}
	var cell: int = cell_px
	var vp := _make_viewport(cols * cell, rows * cell)
	for i in faces.size():
		var td: TileDef = pz.tiles[faces[i][0]]
		var f: int = faces[i][1]
		var face := TileFace.new(td.faces[f], pz.tile_kind(td), 100 + td.id + f * 100)
		face.position = Vector2((i % cols) * cell, floori(float(i) / cols) * cell)
		face.size = Vector2(cell, cell)
		vp.add_child(face)
	var tex: ImageTexture = await _capture(vp, true)
	return {"texture": tex, "cols": cols, "rows": rows, "cells": cells}


## Picture of a solved board, cached by progress key and size.
func bake_board_picture(pz: Puzzle, px: int) -> ImageTexture:
	var key: String = "%s|%d|%d" % [pz.key, pz.seed_value, px]
	if _picture_cache.has(key):
		return _picture_cache[key]
	if headless:
		return _placeholder(BoardPicture.BACKGROUND)
	var vp := _make_viewport(px, px)
	var pic := BoardPicture.new(pz, px)
	vp.add_child(pic)
	var tex: ImageTexture = await _capture(vp, true)
	if _picture_cache.size() > 40:
		_picture_cache.clear()
	_picture_cache[key] = tex
	return tex


func bake_band() -> ImageTexture:
	if _band != null:
		return _band
	if headless:
		_band = _placeholder(MotifPainter.PALETTE.cobalt)
		return _band
	var vp := _make_viewport(512, 64)
	var ctl := BandFace.new()
	ctl.size = Vector2(512, 64)
	vp.add_child(ctl)
	_band = await _capture(vp, true)
	return _band


## The logo tile for the UI (title card and HUD), 256 px with mipmaps.
func bake_logo() -> ImageTexture:
	if _logo != null:
		return _logo
	if headless:
		_logo = _placeholder(MotifPainter.PALETTE.glaze)
		return _logo
	var vp := _make_viewport(256, 256)
	vp.add_child(TileFace.logo(256))
	_logo = await _capture(vp, true)
	return _logo


func bake_wood() -> ImageTexture:
	if _wood != null:
		return _wood
	if headless:
		_wood = _placeholder(Color("#9c6a3e"))
		return _wood
	var px: int = 256 if Settings.is_low_quality() else 512
	var vp := _make_viewport(px, px)
	var ctl := WoodFace.new()
	ctl.size = Vector2(px, px)
	vp.add_child(ctl)
	_wood = await _capture(vp, true)
	return _wood
