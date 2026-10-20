@tool
class_name ChapterDef
extends Resource
## A chapter: a name, a one-line description and ten levels.

@export var name_tr: String = ""
@export var name_en: String = ""
@export var desc_tr: String = ""
@export var desc_en: String = ""
@export var levels: Array[LevelDef] = []


func display_name(lang: String) -> String:
	return name_tr if lang == "tr" else name_en


func description(lang: String) -> String:
	return desc_tr if lang == "tr" else desc_en
