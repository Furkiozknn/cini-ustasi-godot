@tool
class_name LevelSet
extends Resource
## The whole campaign: chapters in order plus the daily board definition.

@export var chapters: Array[ChapterDef] = []
@export var daily: LevelDef = null


func level_count() -> int:
	var c: int = 0
	for ch in chapters:
		c += ch.levels.size()
	return c


## Flat level index (0-based) -> LevelDef.
func level(index: int) -> LevelDef:
	var i: int = index
	for ch in chapters:
		if i < ch.levels.size():
			return ch.levels[i]
		i -= ch.levels.size()
	return null


func chapter_of(index: int) -> int:
	var i: int = index
	for c in chapters.size():
		if i < chapters[c].levels.size():
			return c
		i -= chapters[c].levels.size()
	return chapters.size() - 1


func first_index_of_chapter(chapter: int) -> int:
	var i: int = 0
	for c in chapter:
		i += chapters[c].levels.size()
	return i
