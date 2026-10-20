class_name CameraRig
extends Node3D
## Orbit camera over the table with smoothing, zoom, a portrait fit and a small shake.

const FOV: float = 46.0
const LANDSCAPE_FOCUS: float = 0.22

var target: Vector3 = Vector3(0, 1.25, -0.45)
var dist: float = 7.7
var polar: float = deg_to_rad(48.0)
var azim: float = 0.0
var zoom: float = 1.0
## Extra offset of the look target; the kiln sequence pans here so the kiln stays in view.
## Applied fully in portrait (the kiln is off-screen there) and at LANDSCAPE_FOCUS in landscape.
var focus: Vector3 = Vector3.ZERO

var camera: Camera3D
var _cur_polar: float = deg_to_rad(48.0)
var _cur_azim: float = 0.0
var _cur_zoom: float = 1.0
var _cur_focus: Vector3 = Vector3.ZERO
var _shake: float = 0.0
var _shake_time: float = 0.0
var _idle_time: float = 0.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = FOV
	camera.near = 0.1
	camera.far = 60.0
	camera.current = true
	add_child(camera)
	_cur_polar = polar
	_cur_azim = azim
	_cur_zoom = zoom
	_apply(0.0)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func is_portrait() -> bool:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	return vp_size.x < vp_size.y


func reset_view() -> void:
	polar = deg_to_rad(48.0)
	azim = 0.0
	zoom = 1.0
	focus = Vector3.ZERO


func _process(delta: float) -> void:
	_idle_time += delta
	var k: float = 1.0 - exp(-delta * 8.0)
	_cur_polar += (polar - _cur_polar) * k
	_cur_azim += (azim - _cur_azim) * k
	_cur_zoom += (zoom - _cur_zoom) * k
	_cur_focus += (focus - _cur_focus) * (1.0 - exp(-delta * 2.5))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 0.8)
		_shake_time += delta
	_apply(delta)


func _apply(_delta: float) -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = vp_size.x / maxf(vp_size.y, 1.0)
	# in portrait the board must still fit horizontally
	var h_tan: float = tan(deg_to_rad(FOV) / 2.0) * aspect
	var need: float = 2.75 / h_tan
	# while the camera pans to the kiln on a phone it also backs off a little, so the kiln and the wall fit
	var pan: float = clampf(_cur_focus.length() / 2.5, 0.0, 1.0) if aspect < 1.0 else 0.0
	var d: float = lerpf(maxf(dist, need), dist * 1.15, pan) * _cur_zoom
	var drift_a: float = sin(_idle_time * 0.21) * 0.012
	var drift_p: float = sin(_idle_time * 0.17) * 0.006
	var sp: float = sin(_cur_polar + drift_p)
	var cp: float = cos(_cur_polar + drift_p)
	var az: float = _cur_azim + drift_a
	var t: Vector3 = target + _cur_focus * (1.0 if aspect < 1.0 else LANDSCAPE_FOCUS)
	var pos := Vector3(t.x + d * sp * sin(az), t.y + d * cp, t.z + d * sp * cos(az))
	var look: Vector3 = t
	if _shake > 0.0:
		var s: float = _shake * 0.06
		look += Vector3(sin(_shake_time * 41.0) * s, sin(_shake_time * 57.0) * s, 0.0)
	camera.position = pos
	camera.look_at(look, Vector3.UP)
