class_name Toasts
extends Control
## Short pill messages at the bottom of the screen (at most three at a time).

var _box: VBoxContainer


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_top = -140
	offset_bottom = -22
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = VBoxContainer.new()
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.alignment = BoxContainer.ALIGNMENT_END
	_box.add_theme_constant_override("separation", 6)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)


func show_toast(msg: String) -> void:
	while _box.get_child_count() >= 3:
		var old: Node = _box.get_child(0)
		_box.remove_child(old)
		old.queue_free()
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill := PanelContainer.new()
	pill.theme_type_variation = &"Toast"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiTheme.label(msg, 14, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
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
