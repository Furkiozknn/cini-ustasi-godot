class_name UiScreen
extends Control
## Base for every overlay screen: a dimmed backdrop, a centred card and fade/pop transitions.

var dim: ColorRect
var center: CenterContainer
var card: PanelContainer
var card_max_width: float = 520.0
var clear_backdrop: bool = false
## The button that takes the keyboard focus when the card opens (Enter / Space presses it).
var primary: Control = null
var _tween: Tween = null

## True after a key or gamepad press, false after a mouse click or touch: decides whether the focus
## ring shows when a card opens (pointer users get the focus without the ring).
static var keyboard_mode: bool = false
## Temporary (`--perf-nofocus`): never grab the focus.
static var focus_disabled: bool = false


static func note_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed():
			keyboard_mode = true
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			keyboard_mode = false


## Gives `c` the focus; the ring only shows for keyboard / gamepad users.
static func focus(c: Control) -> void:
	if not focus_disabled and c != null and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
		c.grab_focus(not keyboard_mode)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(40.0 / 255.0, 25.0 / 255.0, 10.0 / 255.0, 0.42)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	center = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	card = PanelContainer.new()
	card.name = "Card"
	card.theme_type_variation = &"Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(card)


func _ready() -> void:
	dim.visible = not clear_backdrop
	build()
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()


## Override: create the card contents.
func build() -> void:
	pass


## Override: update texts and data (called on show and on language change).
func refresh() -> void:
	pass


func is_narrow() -> bool:
	return get_viewport().get_visible_rect().size.x < 640.0


func _on_resize() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	card.custom_minimum_size = Vector2(minf(card_max_width, vp.x - 24.0), 0)
	_layout(vp)


## Override for size-dependent layout.
func _layout(_vp: Vector2) -> void:
	pass


func show_screen() -> void:
	refresh()
	visible = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate.a = 0.0
	# let the container lay the card out once so the pivot sits in its centre
	await get_tree().process_frame
	if not visible:
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.94, 0.94)
	focus_primary()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.26).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(card, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func focus_primary() -> void:
	var c: Control = primary
	if c == null or not c.is_visible_in_tree() or (c is BaseButton and (c as BaseButton).disabled):
		c = card.find_next_valid_focus()
	focus(c)


func hide_screen() -> void:
	if not visible:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.18)
	_tween.tween_callback(func() -> void: visible = false)


func hide_now() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
