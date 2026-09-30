extends Control

var _battle: BattleResolver
var _commands := {"left": "advance", "center": "advance", "right": "advance"}
var _selected_lane := "center"
var _commit_uid := ""
var _board: HBoxContainer
var _log: VBoxContainer
var _status: Label
var _player_bar: ProgressBar
var _enemy_bar: ProgressBar
var _resolve: Button
var _retreat: Button


func _ready() -> void:
	GameTheme.mount(self)
	if GameManager.battle_setup.is_empty():
		call_deferred("_abort")
		return
	_battle = BattleResolver.new()
	_battle.setup(GameManager.battle_setup)
	_build()
	_refresh()


func _abort() -> void:
	GameManager.finish_battle({"outcome": "retreat", "forces_lost": 0, "enemy_lost": 0, "log": [], "commanders": [], "elites_lost": []})


func _build() -> void:
	UiFactory.backdrop(self, "battle", 0.35)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var root := UiFactory.vbox(8)
	margin.add_child(root)
	root.add_child(UiFactory.title(str(GameManager.battle_setup.get("title", "Battle")), 24))
	_status = UiFactory.muted("Deploy, then give each lane an order. Retreat is always open.")
	root.add_child(_status)
	var morale := UiFactory.hbox(12)
	root.add_child(morale)
	_enemy_bar = _bar()
	_player_bar = _bar()
	morale.add_child(UiFactory.muted("Enemy"))
	morale.add_child(_enemy_bar)
	morale.add_child(UiFactory.muted("You"))
	morale.add_child(_player_bar)
	_board = UiFactory.hbox(8)
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_board)
	var commands := UiFactory.flow(6)
	root.add_child(commands)
	for command in BattleResolver.COMMANDS:
		var button := UiFactory.chip(command.capitalize())
		button.tooltip_text = _hint(command)
		button.pressed.connect(_set_command.bind(command))
		commands.add_child(button)
	var bottom := UiFactory.flow(8)
	root.add_child(bottom)
	_retreat = UiFactory.chip("Retreat")
	_retreat.pressed.connect(_on_retreat)
	bottom.add_child(_retreat)
	_resolve = UiFactory.chip("Fight this round")
	_resolve.pressed.connect(_on_resolve)
	bottom.add_child(_resolve)
	var log_panel := UiFactory.panel()
	log_panel.custom_minimum_size = Vector2(0, 88)
	root.add_child(log_panel)
	_log = UiFactory.vbox(2)
	log_panel.add_child(UiFactory.scroll(_log))


func _bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(80, 16)
	return bar


func _refresh() -> void:
	var snap := _battle.snapshot()
	_player_bar.value = int(snap["player_morale"])
	_enemy_bar.value = int(snap["enemy_morale"])
	_status.text = "Round %d  ·  %s vs %s  ·  lane: %s  ·  order %s" % [
		int(snap["round"]),
		snap["player_name"],
		snap["enemy_name"],
		_selected_lane,
		str(_commands.get(_selected_lane, "advance")),
	]
	if bool(snap["deployment_open"]):
		_status.text += "  ·  click your companies to move them before the first clash"
	UiFactory.clear(_board)
	for lane in ["left", "center", "right"]:
		_board.add_child(_lane(lane, snap))
	_board.add_child(_reserve(snap))
	UiFactory.clear(_log)
	var lines: Array = snap["log"]
	var start := maxi(0, lines.size() - 8)
	for index in range(start, lines.size()):
		_log.add_child(UiFactory.label(str(lines[index]), 14))
	var finished := bool(snap["finished"])
	_resolve.text = "Return to the realm" if finished else "Fight this round"
	_retreat.disabled = finished
	for command_button in []:
		pass


func _lane(lane: String, snap: Dictionary) -> Control:
	var panel := UiFactory.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	var column := UiFactory.vbox(4)
	panel.add_child(UiFactory.scroll(column))
	var title := lane.to_upper() + " — " + str(_commands.get(lane, "advance"))
	var heading := UiFactory.label(title, 14, GameTheme.GOLD if lane == _selected_lane else GameTheme.CREAM)
	column.add_child(heading)
	var pick := UiFactory.button("Orders")
	pick.pressed.connect(_select_lane.bind(lane))
	column.add_child(pick)
	column.add_child(UiFactory.muted(str(snap["enemy_name"])))
	for unit in snap["lanes"][lane]["enemy"]:
		column.add_child(_token(unit, false))
	column.add_child(UiFactory.filler())
	column.add_child(UiFactory.muted("You"))
	for unit in snap["lanes"][lane]["player"]:
		var button := _token(unit, true)
		if bool(snap["deployment_open"]):
			button.pressed.connect(_arm_commit.bind(str(unit.get("uid", ""))))
		column.add_child(button)
	if bool(snap["deployment_open"]):
		var drop := UiFactory.button("Move here")
		drop.pressed.connect(_drop.bind(lane))
		column.add_child(drop)
	return panel


func _reserve(snap: Dictionary) -> Control:
	var panel := UiFactory.panel()
	panel.custom_minimum_size = Vector2(150, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.85
	var column := UiFactory.vbox(4)
	panel.add_child(UiFactory.scroll(column))
	column.add_child(UiFactory.title("Reserve", 18))
	for unit in snap["player_reserve"]:
		var button := _token(unit, true)
		var uid := str(unit.get("uid", ""))
		button.pressed.connect(_arm_commit.bind(uid))
		column.add_child(button)
	if str(_commit_uid) != "":
		column.add_child(UiFactory.muted("Will commit on the next round into the selected lane."))
	if bool(snap["deployment_open"]):
		var drop := UiFactory.button("To reserve")
		drop.pressed.connect(_drop.bind("reserve"))
		column.add_child(drop)
	return panel


func _token(unit: Dictionary, yours: bool) -> Button:
	var button := UiFactory.button("%s\n%s" % [unit.get("name", "Company"), Balance.comma(int(unit.get("strength", 0)))])
	var type_id := str(unit.get("elite_id", ""))
	if type_id == "":
		type_id = str(unit.get("type", "infantry"))
	button.icon = ArtLibrary.texture(type_id)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 54)
	button.custom_minimum_size.y = 68
	button.tooltip_text = "Attack %s • Defence %s • %s" % [unit.get("attack", 0), unit.get("defense", 0), "ranged" if bool(unit.get("ranged", false)) else "melee"]
	button.disabled = not yours or _battle.finished
	button.add_theme_color_override("font_disabled_color", GameTheme.CREAM)
	button.add_theme_color_override("icon_disabled_color", Color(0.85, 0.85, 0.85))
	if yours and str(unit.get("uid", "")) == _commit_uid:
		button.add_theme_color_override("font_color", GameTheme.GOLD)
	return button


func _select_lane(lane: String) -> void:
	_selected_lane = lane
	_refresh()


func _set_command(command: String) -> void:
	if _battle.finished:
		return
	_commands[_selected_lane] = command
	_refresh()


func _arm_commit(uid: String) -> void:
	_commit_uid = uid
	_refresh()


func _drop(lane: String) -> void:
	if _commit_uid == "":
		return
	_battle.move_player(_commit_uid, lane)
	_commit_uid = ""
	_refresh()


func _on_resolve() -> void:
	if _battle.finished:
		GameManager.finish_battle(_battle.result())
		return
	var commit_lane := _selected_lane if _commit_uid != "" else ""
	_battle.resolve_round(_commands, _commit_uid, commit_lane)
	_commit_uid = ""
	_refresh()


func _on_retreat() -> void:
	_battle.retreat()
	_refresh()


func _hint(command: String) -> String:
	match command:
		"advance":
			return "Meet them straight on."
		"hold":
			return "Take less ground and fewer losses."
		"charge":
			return "Hard strike. Costly if they are braced."
		"flank":
			return "Punishes a weak neighbour. Weak if the line is solid."
		"volley":
			return "Archers and skirmishers hurt them before the push."
		"rally":
			return "Restore morale instead of killing."
		_:
			return "Pull the lane back into reserve. Some will fall as they go."
