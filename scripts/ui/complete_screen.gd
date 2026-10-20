class_name CompleteScreen
extends UiScreen
## Level complete card: stars pop in, the fired panel is previewed, moves vs par vs best, next/replay.

var baker: TextureBaker
var _title: Label
var _stars: StarRow
var _preview: TextureRect
var _moves: VBoxContainer
var _par: VBoxContainer
var _best: VBoxContainer
var _best_stars: StarRow
var _note: Label
var _next: Button
var _replay: Button
var _levels: Button


func build() -> void:
	clear_backdrop = true
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	_title = UiTheme.label("", 26, UiTheme.COBALT_DEEP, true, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_title)
	var sh := CenterContainer.new()
	_stars = StarRow.new(0, 48)
	_stars.gap = 8.0
	_stars._update_size()
	sh.add_child(_stars)
	v.add_child(sh)
	var ph := CenterContainer.new()
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"PictureFrame"
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(150, 150)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_SCALE
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_preview)
	ph.add_child(frame)
	v.add_child(ph)
	v.add_child(UiTheme.spacer(4))
	var score := UiTheme.row(28)
	_moves = UiTheme.stat("0", "", 24)
	_par = UiTheme.stat("0", "", 24)
	_best = UiTheme.stat("—", "", 24)
	_best_stars = StarRow.new(0, 11)
	var bs := CenterContainer.new()
	bs.add_child(_best_stars)
	_best.add_child(bs)
	_best.move_child(bs, 1)
	score.add_child(_moves)
	score.add_child(_par)
	score.add_child(_best)
	v.add_child(score)
	_note = UiTheme.wrapped("", 15)
	v.add_child(_note)
	v.add_child(UiTheme.spacer(4))
	var r := UiTheme.row()
	_next = UiTheme.button("", "")
	_next.pressed.connect(func() -> void: GameState.next_level())
	_replay = UiTheme.button("", "AltButton")
	_replay.pressed.connect(func() -> void: GameState.replay_level())
	_levels = UiTheme.button("", "AltButton")
	_levels.pressed.connect(func() -> void: GameState.show_levels())
	r.add_child(_next)
	r.add_child(_replay)
	r.add_child(_levels)
	v.add_child(r)


func refresh() -> void:
	var res: Dictionary = GameState.result
	_title.text = Loc.t("complete")
	_stars.set_filled(int(res.get("stars", 0)))
	_load_preview(GameState.puzzle)
	_moves.get_node("Value").text = str(res.get("moves", 0))
	_moves.get_node("Caption").text = Loc.t("moves").to_upper()
	_par.get_node("Value").text = str(res.get("par", 0))
	_par.get_node("Caption").text = Loc.t("par").to_upper()
	var best: Dictionary = res.get("best", {})
	_best.get_node("Value").text = str(int(best["moves"])) if not best.is_empty() else "—"
	_best_stars.set_filled(int(best["stars"]) if not best.is_empty() else 0)
	_best.get_node("Caption").text = Loc.t("best").to_upper()
	_note.text = (Loc.t("newPiece") + ". " if bool(res.get("new_piece", false)) else "") + Loc.t("fired")
	_next.text = Loc.t("next")
	_replay.text = Loc.t("replay")
	_levels.text = Loc.t("levels")
	_next.visible = GameState.has_next_level()


func _load_preview(pz: Puzzle) -> void:
	if pz == null:
		return
	# the kiln sequence already baked this picture, so this is a cache hit
	var tex: Texture2D = await baker.bake_board_picture(pz, 256)
	if GameState.puzzle == pz:
		_preview.texture = tex


func show_screen() -> void:
	super.show_screen()
	_stars.animate()
	var stars: int = int(GameState.result.get("stars", 0))
	for i in stars:
		get_tree().create_timer(0.15 + i * 0.18).timeout.connect(func() -> void: Audio.play("star", 1.0, 1.0 + i * 0.12))
