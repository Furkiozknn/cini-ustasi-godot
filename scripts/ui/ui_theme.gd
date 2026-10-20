class_name UiTheme
extends RefCounted
## Builds the game's Theme in code: cream glass cards, cobalt buttons, warm accents. Also small
## factories for buttons and labels so every screen looks the same.

const INK: Color = Color("#2b2a3d")
const INK_SOFT: Color = Color("#5b5a70")
const COBALT: Color = Color("#1f4e9c")
const COBALT_DEEP: Color = Color("#16356d")
const TURQ: Color = Color("#1fa3a3")
const CORAL: Color = Color("#d9452b")
const GOLD: Color = Color("#d9a441")
const CREAM: Color = Color("#fbf7ee")
const CARD_BG: Color = Color(253.0 / 255.0, 249.0 / 255.0, 240.0 / 255.0, 0.88)
const GLASS_BG: Color = Color(253.0 / 255.0, 249.0 / 255.0, 240.0 / 255.0, 0.72)

static var _theme: Theme = null
static var _bold: FontVariation = null
static var _regular: Font = null


## Drops the cached resources so nothing is reported as leaked at exit.
static func release() -> void:
	_theme = null
	_bold = null
	_regular = null


static func bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.75
	return _bold


static func regular_font() -> Font:
	if _regular == null:
		_regular = ThemeDB.fallback_font
	return _regular


static func flat(bg: Color, radius: float, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.corner_detail = 8
	sb.anti_aliasing = true
	if border_w > 0:
		sb.set_border_width_all(border_w)
		sb.border_color = border
	return sb


static func _button_styles(theme: Theme, type: String, bg: Color, hover: Color, pressed: Color, text: Color, shadow: Color) -> void:
	var n := flat(bg, 14.0)
	n.shadow_size = 6
	n.shadow_color = shadow
	n.shadow_offset = Vector2(0, 4)
	n.content_margin_left = 22
	n.content_margin_right = 22
	n.content_margin_top = 11
	n.content_margin_bottom = 11
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = hover
	h.shadow_size = 9
	var p: StyleBoxFlat = n.duplicate()
	p.bg_color = pressed
	p.shadow_size = 2
	var d: StyleBoxFlat = n.duplicate()
	d.bg_color = Color(bg, 0.45)
	d.shadow_size = 0
	theme.set_stylebox("normal", type, n)
	theme.set_stylebox("hover", type, h)
	theme.set_stylebox("pressed", type, p)
	theme.set_stylebox("disabled", type, d)
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_color("font_color", type, text)
	theme.set_color("font_hover_color", type, text)
	theme.set_color("font_pressed_color", type, text)
	theme.set_color("font_focus_color", type, text)
	theme.set_color("font_disabled_color", type, Color(text, 0.6))
	theme.set_font("font", type, bold_font())
	theme.set_font_size("font_size", type, 16)


static func build() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = regular_font()
	t.default_font_size = 15
	t.set_color("font_color", "Label", INK)
	# cards and panels
	var card := flat(CARD_BG, 18.0, Color(1, 1, 1, 0.7), 1)
	card.shadow_size = 18
	card.shadow_color = Color(70.0 / 255.0, 40.0 / 255.0, 15.0 / 255.0, 0.22)
	card.shadow_offset = Vector2(0, 8)
	card.set_content_margin_all(24)
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", card)
	var glass := flat(GLASS_BG, 16.0, Color(1, 1, 1, 0.7), 1)
	glass.shadow_size = 10
	glass.shadow_color = Color(70.0 / 255.0, 40.0 / 255.0, 15.0 / 255.0, 0.18)
	glass.shadow_offset = Vector2(0, 4)
	glass.content_margin_left = 12
	glass.content_margin_right = 12
	glass.content_margin_top = 6
	glass.content_margin_bottom = 6
	t.set_type_variation("Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", glass)
	var toast := flat(Color(253.0 / 255.0, 249.0 / 255.0, 240.0 / 255.0, 0.9), 999.0, Color(1, 1, 1, 0.7), 1)
	toast.content_margin_left = 16
	toast.content_margin_right = 16
	toast.content_margin_top = 8
	toast.content_margin_bottom = 8
	toast.shadow_size = 8
	toast.shadow_color = Color(70.0 / 255.0, 40.0 / 255.0, 15.0 / 255.0, 0.2)
	t.set_type_variation("Toast", "PanelContainer")
	t.set_stylebox("panel", "Toast", toast)
	var frame := flat(Color("#a4742f"), 4.0, Color("#e2bd7e"), 2)
	frame.set_content_margin_all(7)
	t.set_type_variation("PictureFrame", "PanelContainer")
	t.set_stylebox("panel", "PictureFrame", frame)
	var tile_card := flat(Color(1, 1, 1, 0.7), 14.0, Color(1, 1, 1, 0.75), 1)
	tile_card.shadow_size = 4
	tile_card.shadow_color = Color(60.0 / 255.0, 40.0 / 255.0, 10.0 / 255.0, 0.12)
	tile_card.shadow_offset = Vector2(0, 3)
	tile_card.set_content_margin_all(4)
	t.set_type_variation("LevelCard", "Button")
	t.set_stylebox("normal", "LevelCard", tile_card)
	var tile_hover: StyleBoxFlat = tile_card.duplicate()
	tile_hover.bg_color = Color(1, 1, 1, 0.95)
	tile_hover.shadow_size = 10
	t.set_stylebox("hover", "LevelCard", tile_hover)
	var tile_pressed: StyleBoxFlat = tile_card.duplicate()
	tile_pressed.bg_color = Color(0.95, 0.93, 0.88, 0.95)
	t.set_stylebox("pressed", "LevelCard", tile_pressed)
	var tile_disabled: StyleBoxFlat = tile_card.duplicate()
	tile_disabled.bg_color = Color(1, 1, 1, 0.35)
	tile_disabled.shadow_size = 0
	t.set_stylebox("disabled", "LevelCard", tile_disabled)
	t.set_stylebox("focus", "LevelCard", StyleBoxEmpty.new())
	t.set_color("font_color", "LevelCard", COBALT_DEEP)
	t.set_color("font_hover_color", "LevelCard", COBALT_DEEP)
	t.set_color("font_pressed_color", "LevelCard", COBALT_DEEP)
	t.set_color("font_disabled_color", "LevelCard", Color("#8a8a98"))
	t.set_font("font", "LevelCard", bold_font())
	t.set_font_size("font_size", "LevelCard", 20)
	# buttons
	_button_styles(t, "Button", Color("#2a5fb8"), Color("#3570cc"), Color("#1f4e9c"), Color.WHITE, Color(31.0 / 255.0, 78.0 / 255.0, 156.0 / 255.0, 0.35))
	t.set_type_variation("AltButton", "Button")
	_button_styles(t, "AltButton", Color("#f6f1e6"), Color.WHITE, Color("#ece4d2"), COBALT_DEEP, Color(60.0 / 255.0, 40.0 / 255.0, 10.0 / 255.0, 0.15))
	t.set_type_variation("TurqButton", "Button")
	_button_styles(t, "TurqButton", Color("#25b0b0"), Color("#2fc2c2"), TURQ, Color.WHITE, Color(31.0 / 255.0, 163.0 / 255.0, 163.0 / 255.0, 0.35))
	t.set_type_variation("CoralButton", "Button")
	_button_styles(t, "CoralButton", Color("#e25a3f"), Color("#ec6a4f"), CORAL, Color.WHITE, Color(217.0 / 255.0, 69.0 / 255.0, 43.0 / 255.0, 0.35))
	t.set_type_variation("ToggleButton", "Button")
	_button_styles(t, "ToggleButton", Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.9), Color("#2a5fb8"), COBALT_DEEP, Color(0, 0, 0, 0.08))
	t.set_font_size("font_size", "ToggleButton", 14)
	# icon buttons
	var ib := flat(Color(1, 1, 1, 0.55), 12.0, Color(1, 1, 1, 0.65), 1)
	ib.set_content_margin_all(0)
	t.set_type_variation("IconButton", "Button")
	t.set_stylebox("normal", "IconButton", ib)
	var ibh: StyleBoxFlat = ib.duplicate()
	ibh.bg_color = Color(1, 1, 1, 0.9)
	t.set_stylebox("hover", "IconButton", ibh)
	var ibp: StyleBoxFlat = ib.duplicate()
	ibp.bg_color = Color(0.9, 0.9, 0.95, 0.95)
	t.set_stylebox("pressed", "IconButton", ibp)
	var ibd: StyleBoxFlat = ib.duplicate()
	ibd.bg_color = Color(1, 1, 1, 0.3)
	t.set_stylebox("disabled", "IconButton", ibd)
	t.set_stylebox("focus", "IconButton", StyleBoxEmpty.new())
	t.set_color("font_color", "IconButton", COBALT_DEEP)
	t.set_color("font_hover_color", "IconButton", COBALT_DEEP)
	t.set_color("font_pressed_color", "IconButton", COBALT_DEEP)
	t.set_color("font_disabled_color", "IconButton", Color("#9a9aa8"))
	t.set_font("font", "IconButton", bold_font())
	t.set_font_size("font_size", "IconButton", 13)
	# sliders
	var track := flat(Color(0, 0, 0, 0.08), 4.0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	t.set_stylebox("slider", "HSlider", track)
	var fill := flat(COBALT, 4.0)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grabber := GradientTexture2D.new()
	var gg := Gradient.new()
	gg.set_color(0, COBALT)
	gg.set_color(1, COBALT)
	grabber.gradient = gg
	grabber.width = 18
	grabber.height = 18
	grabber.fill = GradientTexture2D.FILL_RADIAL
	grabber.fill_from = Vector2(0.5, 0.5)
	grabber.fill_to = Vector2(0.5, 0.0)
	gg.add_point(0.92, COBALT)
	gg.set_color(2, Color(COBALT, 0.0))
	t.set_icon("grabber", "HSlider", grabber)
	t.set_icon("grabber_highlight", "HSlider", grabber)
	t.set_icon("grabber_disabled", "HSlider", grabber)
	# check button: plain text row with the switch, no button panel
	var cb := StyleBoxEmpty.new()
	cb.content_margin_left = 4
	cb.content_margin_top = 6
	cb.content_margin_bottom = 6
	for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		t.set_stylebox(state, "CheckButton", cb)
	t.set_font("font", "CheckButton", bold_font())
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", INK)
	t.set_color("font_pressed_color", "CheckButton", INK)
	t.set_color("font_focus_color", "CheckButton", INK)
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	# scroll
	var sc := flat(Color(0, 0, 0, 0.05), 4.0)
	t.set_stylebox("scroll", "VScrollBar", sc)
	t.set_stylebox("grabber", "VScrollBar", flat(Color(COBALT, 0.35), 4.0))
	t.set_stylebox("grabber_highlight", "VScrollBar", flat(Color(COBALT, 0.5), 4.0))
	t.set_stylebox("grabber_pressed", "VScrollBar", flat(Color(COBALT, 0.6), 4.0))
	_theme = t
	return t


# ---------------------------------------------------------------- factories

static func button(text: String, variation: String = "", min_w: float = 140.0) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(min_w, 0)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: Audio.play("ui"))
	return b


static func label(text: String, size: int = 15, color: Color = INK, bold: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", bold_font())
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrapped(text: String, size: int = 15, color: Color = INK_SOFT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, false, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func row(gap: int = 8, centered: bool = true) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	if centered:
		h.alignment = BoxContainer.ALIGNMENT_CENTER
	return h


static func spacer(h: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func stat(value: String, caption: String, value_size: int = 17) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var val := label(value, value_size, COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
	val.name = "Value"
	var cap := label(caption.to_upper(), 11, INK_SOFT, false, HORIZONTAL_ALIGNMENT_CENTER)
	cap.name = "Caption"
	v.add_child(val)
	v.add_child(cap)
	return v
