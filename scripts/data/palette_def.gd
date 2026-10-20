@tool
class_name PaletteDef
extends Resource
## Colours of the four glaze families and the ink, kept as data so the look can be tuned without code.

@export var cobalt: Color = Color("#1f4e9c")
@export var cobalt_dark: Color = Color("#143a78")
@export var cobalt_light: Color = Color("#5e86c8")
@export var turquoise: Color = Color("#17a6b2")
@export var turquoise_dark: Color = Color("#107a84")
@export var turquoise_light: Color = Color("#7fd9dc")
@export var coral: Color = Color("#d9452b")
@export var coral_dark: Color = Color("#a3301c")
@export var coral_light: Color = Color("#f08a6c")
@export var emerald: Color = Color("#2f9a52")
@export var emerald_dark: Color = Color("#1f6b38")
@export var emerald_light: Color = Color("#8ad4a0")
@export var ink: Color = Color("#17315f")
@export var glaze: Color = Color("#fdfbf4")
@export var glaze_edge: Color = Color("#efe9d8")
@export var cream: Color = Color("#fbf7ee")


func fill(color_index: int) -> Color:
	match color_index:
		0: return cobalt
		1: return turquoise
		2: return coral
		_: return emerald


func dark(color_index: int) -> Color:
	match color_index:
		0: return cobalt_dark
		1: return turquoise_dark
		2: return coral_dark
		_: return emerald_dark


func light(color_index: int) -> Color:
	match color_index:
		0: return cobalt_light
		1: return turquoise_light
		2: return coral_light
		_: return emerald_light
