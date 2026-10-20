class_name Toasts
extends Control
## Short pill messages in a stack under the top bar (at most three at a time); "good" and "bad" ones get
## an emerald or coral edge. Ui moves the stack below the HUD while it is visible.

const KINDS: Dictionary = {"": &"ToastInfo", "good": &"ToastGood", "bad": &"ToastBad"}
const TEXT: Dictionary = {"": UiTheme.COBALT_DEEP, "good": Color("#1d5c38"), "bad": Color("#8f2a17")}

var _box: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_top = 16
	offset_bottom = 16 + 140
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_box.add_theme_constant_override("separation", 6)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)


## Puts the top of the stack at `y` (just under the HUD, or near the top of the screen).
func set_top(y: float) -> void:
	offset_top = y
	offset_bottom = y + 140


func show_toast(msg: String, kind: String = "") -> void:
	while _box.get_child_count() >= 3:
		var old: Node = _box.get_child(0)
		_box.remove_child(old)
		old.queue_free()
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := PanelContainer.new()
	pill.theme_type_variation = KINDS.get(kind, &"ToastInfo")
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiTheme.label(msg, 14, TEXT.get(kind, UiTheme.COBALT_DEEP), true, HORIZONTAL_ALIGNMENT_CENTER)
	pill.add_child(l)
	holder.add_child(pill)
	_box.add_child(holder)
	holder.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(holder, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.2)
	tw.tween_property(holder, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void:
		if is_instance_valid(holder):
			holder.queue_free())
