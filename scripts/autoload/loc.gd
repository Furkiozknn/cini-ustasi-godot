extends Node
## Localisation: Turkish (default) and English strings. Use Loc.t("key").

signal language_changed(lang: String)

var lang: String = "tr"

const STRINGS: Dictionary = {
	"tr": {
		"loading": "Atölye hazırlanıyor…", "title": "Çini Ustası", "subtitle": "İznik çini bulmacası",
		"intro": "Kenarlardaki motifleri eşleştir, panoyu fırınla, duvarını doldur.",
		"play": "Oyna", "continue": "Devam et", "levels": "Bölümler", "collection": "Koleksiyon",
		"daily": "Günün Çinisi", "dailyLocked": "1. bölüm bitince açılır",
		"chapter": "Bölüm", "level": "Seviye", "moves": "Hamle", "par": "Par", "stars": "Yıldız",
		"hint": "İpucu", "undo": "Geri al", "restart": "Yeniden", "menu": "Menü", "paused": "Mola",
		"resume": "Devam", "backToTitle": "Ana ekran", "start": "Başla", "next": "Sonraki", "replay": "Tekrar",
		"best": "En iyi", "complete": "Çini tamamlandı!", "fired": "Fırından çıktı ve duvara asıldı.",
		"noHints": "İpucu kalmadı", "hintUsed": "Bir çini yerine oturdu", "hintNone": "Pano zaten doğru görünüyor",
		"undone": "Geri alındı", "nothingToUndo": "Geri alınacak hamle yok",
		"fixedTile": "Bu çini sabit, oynamaz", "notTwoSided": "Bu çini tek yüzlü",
		"noSwapHere": "Bu bölümde çiniler yer değiştirmez", "restarted": "Pano baştan başladı",
		"dailyUnlocked": "Günün Çinisi açıldı!", "allDone": "Tüm panolar tamamlandı. Tebrikler, usta!",
		"emptyCollection": "Duvar henüz boş. İlk panoyu bitir, fırından çıksın!",
		"locked": "Kilitli", "newPiece": "Yeni parça koleksiyona eklendi",
		"dailyName": "Günün Çinisi", "dailyBest": "Bugünkü en iyi", "close": "Kapat",
		"settings": "Ayarlar", "masterVolume": "Ana ses", "musicVolume": "Müzik", "sfxVolume": "Efektler",
		"language": "Dil", "quality": "Grafik", "qualityLow": "Düşük", "qualityHigh": "Yüksek",
		"fullscreen": "Tam ekran", "on": "Açık", "off": "Kapalı", "howToPlay": "Nasıl oynanır?",
		"progressLine": "%d/%d · %d", "firing": "Fırınlanıyor…", "glazing": "Sırlanıyor…",
		"hintTip": "İpucu (H)", "undoTip": "Geri al (Z)", "restartTip": "Yeniden (R)", "menuTip": "Mola (P / Esc)",
		"edges": "Kenar", "newRecord": "Yeni rekor!", "soundTip": "Ses (X)", "musicTip": "Müzik (M)", "langTip": "Dil (L)",
		"soundOn": "Ses açık", "soundOff": "Ses kapalı", "musicOn": "Müzik açık", "musicOff": "Müzik kapalı",
		"credit": "Claude Game Arena · built by Claude Fable 5.1 · assets remastered",
	},
	"en": {
		"loading": "Preparing the workshop…", "title": "Çini Ustası", "subtitle": "Iznik tile puzzle",
		"intro": "Match the motifs on the edges, fire the panel, fill your wall.",
		"play": "Play", "continue": "Continue", "levels": "Levels", "collection": "Collection",
		"daily": "Daily Tile", "dailyLocked": "Unlocks after chapter 1",
		"chapter": "Chapter", "level": "Level", "moves": "Moves", "par": "Par", "stars": "Stars",
		"hint": "Hint", "undo": "Undo", "restart": "Restart", "menu": "Menu", "paused": "Paused",
		"resume": "Resume", "backToTitle": "Title screen", "start": "Start", "next": "Next", "replay": "Replay",
		"best": "Best", "complete": "Panel complete!", "fired": "Fired in the kiln and hung on the wall.",
		"noHints": "No hints left", "hintUsed": "One tile set right", "hintNone": "The board already looks right",
		"undone": "Undone", "nothingToUndo": "Nothing to undo",
		"fixedTile": "This tile is fixed", "notTwoSided": "This tile has one side",
		"noSwapHere": "Tiles cannot be swapped in this chapter", "restarted": "Board reset",
		"dailyUnlocked": "Daily Tile unlocked!", "allDone": "All panels complete. Congratulations, master!",
		"emptyCollection": "The wall is empty. Finish your first panel and fire it!",
		"locked": "Locked", "newPiece": "New piece added to the collection",
		"dailyName": "Daily Tile", "dailyBest": "Today's best", "close": "Close",
		"settings": "Settings", "masterVolume": "Master volume", "musicVolume": "Music", "sfxVolume": "Effects",
		"language": "Language", "quality": "Graphics", "qualityLow": "Low", "qualityHigh": "High",
		"fullscreen": "Fullscreen", "on": "On", "off": "Off", "howToPlay": "How to play",
		"progressLine": "%d/%d · %d", "firing": "Firing…", "glazing": "Glazing…",
		"hintTip": "Hint (H)", "undoTip": "Undo (Z)", "restartTip": "Restart (R)", "menuTip": "Pause (P / Esc)",
		"edges": "Edges", "newRecord": "New record!", "soundTip": "Sound (X)", "musicTip": "Music (M)", "langTip": "Language (L)",
		"soundOn": "Sound on", "soundOff": "Sound off", "musicOn": "Music on", "musicOff": "Music off",
		"credit": "Claude Game Arena · built by Claude Fable 5.1 · assets remastered",
	},
}

const HOWTO: Dictionary = {
	"tr": [
		{"title": "Kenarları eşleştir", "lines": [
			"Bir çiniye dokun: 90° döner.",
			"Komşu kenarlardaki motifler aynı olmalı: aynı şekil, aynı renk.",
			"Kenar şeridi yalnızca dış çerçeveye bakar.",
			"Eşleşen kenarlar altın gibi parlar. Z geri al, H ipucu, R yeniden, P mola."]},
		{"title": "Yer değiştir", "lines": [
			"Bir çiniyi sürükleyip başka bir çininin üstüne bırak: yer değişirler.",
			"Dokunmak yine döndürür. Doğru çiniyi doğru yere koy, sonra çevir.",
			"Masaya sürükleyerek bakış açısını, tekerlekle yakınlığı ayarla."]},
		{"title": "Usta işi", "lines": [
			"Pirinç çivili çiniler sabittir: yerinde durur, dönmez.",
			"Ok işaretli çiniler çift yüzlüdür: sağ tık, uzun bas ya da üstündeyken F, ters yüz olur.",
			"Panolar 6×6'ya kadar büyür. Köşelerden başla, sabit çinileri rehber al."]},
		{"title": "Günün Çinisi", "lines": [
			"Her gün yeni bir 4×4 pano. Döndür, yer değiştir, en az hamleyle bitir.",
			"Bugünkü en iyi derecen kaydedilir."]},
	],
	"en": [
		{"title": "Match the edges", "lines": [
			"Tap a tile: it turns 90°.",
			"Motifs on neighbouring edges must be the same: same shape, same colour.",
			"The border band only faces the outer frame.",
			"Matching edges glow gold. Z undo, H hint, R restart, P pause."]},
		{"title": "Swap places", "lines": [
			"Drag a tile onto another tile: they swap places.",
			"Tapping still rotates. Put the right tile in the right place, then turn it.",
			"Drag on the table to tilt the view, scroll to zoom."]},
		{"title": "Master's work", "lines": [
			"Tiles with a brass nail are fixed: they stay put and do not turn.",
			"Tiles with an arrow mark are double-sided: right-click, long-press or F while hovering to flip.",
			"Boards grow up to 6×6. Start from the corners and use the fixed tiles as guides."]},
		{"title": "Daily Tile", "lines": [
			"A new 4×4 board every day. Rotate, swap, finish in as few moves as you can.",
			"Today's best result is saved."]},
	],
}


func t(key: String) -> String:
	var table: Dictionary = STRINGS[lang]
	if table.has(key):
		return table[key]
	var fallback: Dictionary = STRINGS["tr"]
	if fallback.has(key):
		return fallback[key]
	return key


func howto(chapter: int) -> Dictionary:
	var list: Array = HOWTO[lang]
	return list[clampi(chapter, 0, list.size() - 1)]


func set_language(new_lang: String) -> void:
	if not STRINGS.has(new_lang):
		new_lang = "tr"
	if new_lang == lang:
		return
	lang = new_lang
	language_changed.emit(lang)


func other_language() -> String:
	return "en" if lang == "tr" else "tr"
