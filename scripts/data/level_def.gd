@tool
class_name LevelDef
extends Resource
## Data for one level. Boards are generated from these numbers plus a seed, so a level is tiny on disk.

## Board size (n x n).
@export_range(3, 6) var n: int = 3
## Number of motifs in the palette.
@export_range(2, 10) var m: int = 3
## Fraction of movable tiles that get permuted (0 = rotate-only level).
@export_range(0.0, 1.0) var shuf: float = 0.0
## Number of fixed (nailed) tiles.
@export_range(0, 8) var fix: int = 0
## Number of double-sided tiles.
@export_range(0, 10) var flip: int = 0
@export var name_tr: String = ""
@export var name_en: String = ""


func display_name(lang: String) -> String:
	return name_tr if lang == "tr" else name_en
