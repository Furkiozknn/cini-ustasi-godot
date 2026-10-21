class_name Args
extends RefCounted
## Reads the user arguments passed after "--" (e.g. `godot -- --auto --level 12`).
## Supports `--key value` and `--key=value`. In the browser build the page URL adds more:
## `?arg=stats&arg=quality=high` reads like `-- --stats --quality=high`.

static var _url_args: PackedStringArray = []
static var _url_read: bool = false


static func _list() -> PackedStringArray:
	var list: PackedStringArray = OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		if not _url_read:
			_url_read = true
			var raw: Variant = JavaScriptBridge.eval("new URLSearchParams(location.search).getAll('arg').join('\\n')", true)
			if raw is String and raw != "":
				for a in (raw as String).split("\n", false):
					_url_args.append("--" + a)
		list.append_array(_url_args)
	return list


static func has(flag: String) -> bool:
	var key: String = "--" + flag
	for a in _list():
		if a == key or a.begins_with(key + "="):
			return true
	return false


static func value(flag: String, default: String = "") -> String:
	var key: String = "--" + flag
	var list := _list()
	for i in list.size():
		var a: String = list[i]
		if a.begins_with(key + "="):
			return a.substr(key.length() + 1)
		if a == key and i + 1 < list.size() and not list[i + 1].begins_with("--"):
			return list[i + 1]
	return default


static func number(flag: String, default: float) -> float:
	var v := value(flag, "")
	if v == "" or not v.is_valid_float():
		return default
	return v.to_float()
