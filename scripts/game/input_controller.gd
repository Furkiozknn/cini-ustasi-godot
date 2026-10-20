class_name InputController
extends Node
## Pointer and key input on the table: tap = rotate, drag tile = swap, right-click / long-press = flip,
## drag the table = tilt the view, wheel / pinch = zoom. Keys come through the Input Map.

const DRAG_THRESHOLD: float = 9.0
const LONG_PRESS: float = 0.52

var board: Board
var camera_rig: CameraRig

var _down: bool = false
var _tile: TileNode = null
var _start: Vector2 = Vector2.ZERO
var _last: Vector2 = Vector2.ZERO
var _moved: bool = false
var _dragging: bool = false
var _cam_drag: bool = false
var _is_touch: bool = false
var _press_time: float = 0.0
var _long_fired: bool = false
var _no_swap_toasted: bool = false
var _touches: Dictionary = {}
var _pinch_dist: float = 0.0


func _plane_y() -> float:
	return WorldBuilder.TABLE_Y + 0.06 + board.tile_h


func _point_on_board(screen_pos: Vector2) -> Vector3:
	var cam: Camera3D = camera_rig.camera
	var origin: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, _plane_y())
	var hit: Variant = plane.intersects_ray(origin, dir)
	if hit == null:
		return Vector3(INF, INF, INF)
	return hit


func _pick_tile(screen_pos: Vector2) -> TileNode:
	if GameState.screen != GameState.SCREEN_PLAYING or GameState.puzzle == null or not board.ready_for_input:
		return null
	var p: Vector3 = _point_on_board(screen_pos)
	if p.x == INF:
		return null
	var local: Vector3 = p - board.position
	var slot: int = board.slot_at_local(local.x, local.z)
	if slot < 0:
		return null
	return board.tile_by_slot[slot]


func _mouse_pos() -> Vector2:
	return get_viewport().get_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventMagnifyGesture:
		_zoom_by(1.0 / (event as InputEventMagnifyGesture).factor)
	elif event.is_action_pressed("undo"):
		GameState.undo()
	elif event.is_action_pressed("hint"):
		GameState.use_hint()
	elif event.is_action_pressed("restart"):
		if GameState.screen == GameState.SCREEN_PLAYING:
			GameState.restart_level()
	elif event.is_action_pressed("pause"):
		GameState.back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_language"):
		Settings.toggle_language()
	elif event.is_action_pressed("flip_tile") and event is InputEventKey:
		var t := _pick_tile(_mouse_pos())
		if t != null:
			GameState.try_flip(t.slot)


func _zoom_by(factor: float) -> void:
	camera_rig.zoom = clampf(camera_rig.zoom * factor, 0.78, 1.3)


func _handle_touch(e: InputEventScreenTouch) -> void:
	if e.pressed:
		_touches[e.index] = e.position
	else:
		_touches.erase(e.index)
	if _touches.size() == 2:
		var pts: Array = _touches.values()
		_pinch_dist = pts[0].distance_to(pts[1])
		# a second finger cancels any tile or camera drag
		_down = false
		_tile = null
		_cam_drag = false
		if _dragging:
			_dragging = false
			board.drag = null
	elif _touches.size() < 2:
		_pinch_dist = 0.0


func _handle_touch_drag(e: InputEventScreenDrag) -> void:
	if _touches.has(e.index):
		_touches[e.index] = e.position
	if _touches.size() == 2:
		var pts: Array = _touches.values()
		var d: float = pts[0].distance_to(pts[1])
		if _pinch_dist > 0.0 and d > 0.0:
			_zoom_by(_pinch_dist / d)
		_pinch_dist = d


func _handle_mouse_button(e: InputEventMouseButton) -> void:
	if _touches.size() >= 2:
		return
	var pos: Vector2 = _mouse_pos()
	if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
		_zoom_by(1.0 - 0.08)
		return
	if e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
		_zoom_by(1.0 + 0.08)
		return
	if e.button_index == MOUSE_BUTTON_RIGHT:
		if e.pressed:
			var t := _pick_tile(pos)
			if t != null:
				GameState.try_flip(t.slot)
		return
	if e.button_index != MOUSE_BUTTON_LEFT:
		return
	if e.pressed:
		_down = true
		_start = pos
		_last = pos
		_moved = false
		_dragging = false
		_long_fired = false
		_cam_drag = false
		_no_swap_toasted = false
		_is_touch = e.device == InputEvent.DEVICE_ID_EMULATION
		_press_time = 0.0
		_tile = _pick_tile(pos)
		if _tile == null:
			_cam_drag = GameState.screen == GameState.SCREEN_PLAYING or GameState.screen == GameState.SCREEN_TITLE
	else:
		_end_pointer(pos)


func _handle_mouse_motion(e: InputEventMouseMotion) -> void:
	if _touches.size() >= 2:
		return
	var pos: Vector2 = _mouse_pos()
	if not _down:
		if e.device != InputEvent.DEVICE_ID_EMULATION:
			board.hover = _pick_tile(pos)
		return
	var delta: Vector2 = pos - _start
	if not _moved and delta.length() > DRAG_THRESHOLD:
		_moved = true
	if _cam_drag:
		var m: Vector2 = pos - _last
		camera_rig.azim = clampf(camera_rig.azim - m.x * 0.004, -0.38, 0.38)
		camera_rig.polar = clampf(camera_rig.polar - m.y * 0.004, deg_to_rad(36.0), deg_to_rad(64.0))
	elif _tile != null and _moved:
		if not _dragging:
			if not GameState.puzzle.allow_swap:
				if not _no_swap_toasted:
					GameState.toast.emit(Loc.t("noSwapHere"))
					_no_swap_toasted = true
			elif _tile.fixed:
				GameState.toast.emit(Loc.t("fixedTile"))
				GameState.tile_denied.emit(_tile.slot)
				_tile = null
			else:
				_dragging = true
				board.drag = _tile
				Audio.play("lift")
		if _dragging and _tile != null:
			var p: Vector3 = _point_on_board(pos)
			if p.x != INF:
				_tile.x = p.x - board.position.x
				_tile.z = p.z - board.position.z
	_last = pos


func _process(delta: float) -> void:
	# long-press to flip on touch screens
	if _down and _is_touch and _tile != null and not _moved and not _long_fired:
		_press_time += delta
		if _press_time >= LONG_PRESS:
			_long_fired = true
			GameState.try_flip(_tile.slot)
			_tile = null


func _end_pointer(pos: Vector2) -> void:
	if not _down:
		return
	_down = false
	if _dragging and board.drag != null:
		var t: TileNode = board.drag
		board.drag = null
		_dragging = false
		var p: Vector3 = _point_on_board(pos)
		var q: int = -1
		if p.x != INF:
			q = board.slot_at_local(p.x - board.position.x, p.z - board.position.z)
		if q >= 0 and q != t.slot:
			GameState.try_swap(t.slot, q)
	elif _tile != null and not _moved and not _long_fired and GameState.screen == GameState.SCREEN_PLAYING:
		GameState.try_rotate(_tile.slot)
	_tile = null
	_cam_drag = false
	_dragging = false
