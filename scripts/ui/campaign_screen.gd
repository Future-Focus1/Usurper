extends Control

var _busy := false
var _selected: Dictionary = {}
var _category := "Economy"
var _center: VBoxContainer
var _left: VBoxContainer
var _right: VBoxContainer
var _gold: Label
var _rations: Label
var _forces: Label
var _claim: Label
var _claim_bar: ProgressBar
var _fear: Label
var _date: Label
var _phase: Label
var _primary: Button
var _throne: Button
var _overlay: Control
var _debug: DebugPanel
var _scene_art: TextureRect


func _ready() -> void:
	GameTheme.mount(self)
	if GameManager.state == null:
		call_deferred("_leave")
		return
	_build()
	call_deferred("_resume")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _overlay != null and _overlay.visible:
			_close_overlay()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F12 and Balance.DEBUG_ENABLED:
		_toggle_debug()
		get_viewport().set_input_as_handled()


func _leave() -> void:
	GameManager.to_menu()


func _resume() -> void:
	var state := GameManager.state
	if state == null:
		return
	if not state.ending_data.is_empty():
		GameManager.show_ending(state.ending_data)
		return
	if not state.pending_battle.is_empty():
		GameManager.launch_battle()
		return
	if state.defeat_reason != "":
		var reason := state.defeat_reason
		state.defeat_reason = ""
		GameManager.show_ending(EndingDirector.resolve_defeat(state, GameManager.db, reason))
		return
	if state.post_battle != "":
		var mode := state.post_battle
		state.post_battle = ""
		if mode == "advance_event":
			_advance_event()
			return
		if mode == "close_week":
			_close_and_respond()
			return
		if mode == "throne":
			var route := state.pending_throne_route
			state.pending_throne_route = ""
			GameManager.show_ending(EndingDirector.resolve(state, GameManager.db, route, state.last_battle))
			return
	_refresh()


func _build() -> void:
	UiFactory.backdrop(self, "throne", 0.85)
	_scene_art = get_child(0) as TextureRect
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var root := UiFactory.vbox(8)
	margin.add_child(root)
	root.add_child(_header())
	var mid := UiFactory.hbox(10)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(mid)
	_left = UiFactory.vbox(6)
	var left_scroll := UiFactory.scroll(_left)
	left_scroll.custom_minimum_size = Vector2(168, 0)
	left_scroll.size_flags_stretch_ratio = 0.85
	mid.add_child(left_scroll)
	var center_panel := UiFactory.panel()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_stretch_ratio = 2.5
	mid.add_child(center_panel)
	_center = UiFactory.vbox(8)
	center_panel.add_child(UiFactory.scroll(_center))
	_right = UiFactory.vbox(6)
	var right_scroll := UiFactory.scroll(_right)
	right_scroll.custom_minimum_size = Vector2(180, 0)
	right_scroll.size_flags_stretch_ratio = 0.95
	mid.add_child(right_scroll)
	root.add_child(_footer())
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)
	if Balance.DEBUG_ENABLED:
		_debug = DebugPanel.new()
		_debug.set_anchors_preset(Control.PRESET_FULL_RECT)
		_debug.visible = false
		_debug.changed.connect(_refresh)
		_debug.launch_battle.connect(_debug_battle)
		_debug.force_route.connect(_debug_route)
		_debug.play_event.connect(_debug_event)
		add_child(_debug)


func _header() -> Control:
	var box := UiFactory.vbox(4)
	var top := UiFactory.hbox(10)
	box.add_child(top)
	var brand := UiFactory.title("USURPER", 20)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top.add_child(brand)
	_date = UiFactory.single("", 14, GameTheme.MUTED)
	top.add_child(_date)
	_phase = UiFactory.single("", 14, GameTheme.MUTED)
	_phase.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(_phase)
	var save := UiFactory.chip("Save")
	save.pressed.connect(_open_save)
	top.add_child(save)
	var menu := UiFactory.chip("Menu")
	menu.pressed.connect(_open_pause)
	top.add_child(menu)
	if Balance.DEBUG_ENABLED:
		var dev := UiFactory.chip("Dev")
		dev.pressed.connect(_toggle_debug)
		top.add_child(dev)
	var stats := UiFactory.flow(10)
	box.add_child(stats)
	_gold = UiFactory.single("", 15, GameTheme.GOLD)
	_rations = UiFactory.single("", 15, GameTheme.GOLD)
	_forces = UiFactory.single("", 15, GameTheme.GOLD)
	_claim = UiFactory.single("", 15, GameTheme.CLAIM)
	_fear = UiFactory.single("", 15)
	for node in [_gold, _rations, _forces, _claim, _fear]:
		node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		stats.add_child(node)
	_claim_bar = ProgressBar.new()
	_claim_bar.max_value = 100
	_claim_bar.show_percentage = false
	_claim_bar.custom_minimum_size = Vector2(120, 14)
	_claim_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(_claim_bar)
	_throne = UiFactory.chip("Take the Throne")
	_throne.pressed.connect(_open_throne)
	stats.add_child(_throne)
	return box


func _footer() -> Control:
	var row := UiFactory.flow(8)
	row.add_child(_nav("Map", _open_map))
	row.add_child(_nav("Court", _open_court))
	row.add_child(_nav("Ledger", _open_ledger))
	row.add_child(_nav("Army", _open_army))
	row.add_child(_nav("World", _open_world))
	row.add_child(_nav("Chronicle", func(): GameManager.open_chronicle()))
	_primary = UiFactory.primary("Continue")
	_primary.pressed.connect(_on_primary)
	row.add_child(_primary)
	return row


func _nav(text: String, callback: Callable) -> Button:
	var button := UiFactory.chip(text)
	button.pressed.connect(callback)
	return button


func _refresh() -> void:
	var state := GameManager.state
	if state == null:
		return
	_gold.text = "Gold %s" % Balance.comma(state.gold)
	_rations.text = "Rations %s" % Balance.comma(state.rations)
	_forces.text = "Forces %s" % Balance.comma(state.forces)
	_claim.text = "Claim %d/100" % state.claim
	_claim_bar.value = state.claim
	var fear := Balance.fear_label(state.fear)
	_fear.text = "Fear %s" % fear
	for stat in [_gold, _rations, _forces, _claim, _fear]:
		stat.custom_minimum_size = Vector2(UiFactory._text_width(stat.text, 15) + 8, 24)
	_fear.add_theme_color_override("font_color", UiFactory.support_color(fear))
	_date.text = "%s  ·  %s" % [Balance.date_line(state.turn), Balance.act_name(state.turn)]
	_throne.visible = true
	_throne.text = "Take the Throne" if state.claim >= 100 else "Paths to the crown"
	_fill_left(state)
	_fill_right(state)
	UiFactory.clear(_center)
	var scene := "throne"
	if state.claimant_id == "arlo":
		scene = "maren"
	elif state.claimant_id == "alistair":
		scene = "stormhold"
	elif state.claimant_id == "ethan":
		scene = "battle"
	if state.phase == "event":
		var event := EventDirector.current(state, GameManager.db)
		var setting := str(event.get("scene", ""))
		if setting in ["maren", "stormhold", "temple", "coast", "battle"]:
			scene = setting
		elif setting in ["caerlyn", "court"]:
			scene = "throne"
	if _scene_art != null and ArtLibrary.texture(scene) != null:
		_scene_art.texture = ArtLibrary.texture(scene)
	_phase.text = WeekLoop.phase_title(state.phase)
	_phase.custom_minimum_size.x = UiFactory._text_width(_phase.text, 14) + 8
	match state.phase:
		"event":
			_show_event(state)
		"action":
			_show_action(state)
		"response":
			_show_lines(state.week_title, state.week_report, WeekLoop.primary_label("response", true))
		_:
			_show_overview(state)


func _fill_left(state: CampaignState) -> void:
	UiFactory.clear(_left)
	_left.add_child(UiFactory.portrait(state.claimant_id, 132))
	_left.add_child(UiFactory.title(str(GameManager.db.claimants[state.claimant_id].get("short", "")), 20))
	_left.add_child(UiFactory.rule())
	_left.add_child(UiFactory.muted("SUPPORT"))
	for bloc in Balance.BLOCS:
		var value := int(state.blocs.get(bloc, 0))
		var word := Balance.bloc_label(value)
		var line := UiFactory.label("%s\n%s" % [Balance.bloc_title(str(bloc)), word], 14)
		line.add_theme_color_override("font_color", UiFactory.support_color(word))
		_left.add_child(line)
		var bar := ProgressBar.new()
		bar.min_value = -100
		bar.max_value = 100
		bar.value = value
		bar.show_percentage = false
		bar.custom_minimum_size.y = 4
		_left.add_child(bar)
	_left.add_child(UiFactory.rule())
	_left.add_child(UiFactory.muted("HOUSES"))
	for hid in GameManager.db.house_order:
		var house: Dictionary = GameManager.db.houses[hid]
		var declared := str(state.houses[hid].get("declared", ""))
		var who := "uncommitted" if declared == "" else GameManager.db.controller_name(declared, state.claimant_id)
		_left.add_child(UiFactory.muted("%s — %s" % [house.get("short", house.get("name", hid)), who], 13))


func _fill_right(state: CampaignState) -> void:
	UiFactory.clear(_right)
	_right.add_child(UiFactory.muted("RIVALS"))
	for rid in state.rivals:
		var rival: Dictionary = state.rivals[rid]
		var name := str(GameManager.db.claimants[rid].get("short", rid))
		var living := "gone" if not bool(rival.get("alive", false)) else "claim %d · %s" % [int(rival.get("claim", 0)), Balance.comma(int(rival.get("forces", 0)))]
		_right.add_child(UiFactory.label("%s — %s" % [name, living], 14))
	_right.add_child(UiFactory.rule())
	_right.add_child(UiFactory.muted("WARNINGS"))
	var warnings := _warnings(state)
	if warnings.is_empty():
		_right.add_child(UiFactory.muted("No fresh alarm."))
	for line in warnings:
		_right.add_child(UiFactory.label(line, 14, GameTheme.BAD))
	_right.add_child(UiFactory.rule())
	_right.add_child(UiFactory.muted("DUE THIS WEEK"))
	_right.add_child(UiFactory.muted("%d rations · %s gold" % [Balance.ration_need(state.forces), Balance.comma(Balance.gold_upkeep(state.forces))]))


func _warnings(state: CampaignState) -> Array:
	var lines: Array = []
	var need := Balance.ration_need(state.forces)
	if state.rations <= 0 and state.forces > 0:
		lines.append("The army is starving.")
	elif state.rations < need * 2 and need > 0:
		lines.append("The stores are thin.")
	if bool(state.flags.get("UNPAID", false)):
		lines.append("The host has not been paid.")
	if state.fear >= 60:
		lines.append("Fear is breeding plots.")
	if state.foreign >= 14:
		lines.append("Varos is watching the fracture.")
	if state.turn > 4 and str(state.npcs.get("nessa_grey", {}).get("state", "")) == "missing":
		lines.append("Nessa Grey is still missing.")
	for rid in state.rivals:
		if bool(state.rivals[rid].get("alive", false)) and int(state.rivals[rid].get("claim", 0)) > state.claim + 8:
			lines.append("%s's claim is ahead of yours." % GameManager.db.claimants[rid].get("short", rid))
	return lines


func _show_overview(state: CampaignState) -> void:
	_primary.visible = true
	_primary.disabled = false
	_primary.text = WeekLoop.primary_label("overview", false)
	if state.banner != "":
		_center.add_child(UiFactory.label(state.banner, 15, GameTheme.CLAIM))
	_center.add_child(UiFactory.title("The week ahead", 24))
	_center.add_child(UiFactory.artwork("map", 136))
	_center.add_child(UiFactory.muted("%d lands held. Hear the petitioners, then issue one decree." % state.player_territories().size()))
	if state.turn == 1:
		var hint := str(GameManager.db.claimants[state.claimant_id].get("hint", ""))
		if hint != "":
			_center.add_child(UiFactory.label(hint))
		for line in state.week_report:
			_center.add_child(UiFactory.label("· " + str(line)))
	_center.add_child(UiFactory.muted("WHAT THIS WEEK WILL COST"))
	for line in WeekLoop.forecast(state, GameManager.db):
		_center.add_child(UiFactory.label(line))
	if not state.modifiers.is_empty():
		_center.add_child(UiFactory.muted("STILL IN FORCE"))
		for modifier in state.modifiers:
			_center.add_child(UiFactory.label("%s (%d weeks left)" % [modifier.get("name", ""), int(modifier.get("turns", 0))], 14))


func _show_event(state: CampaignState) -> void:
	_primary.visible = false
	var event := EventDirector.current(state, GameManager.db)
	if event.is_empty():
		state.phase = "action"
		_show_action(state)
		return
	if state.banner != "":
		_center.add_child(UiFactory.muted(state.banner))
	var place := str(event.get("place", "NEZREL")).to_upper()
	_center.add_child(UiFactory.muted(place))
	var heading := UiFactory.hbox(16)
	_center.add_child(heading)
	var speaker_id := ArtLibrary.speaker(event, GameManager.db)
	if ArtLibrary.texture(speaker_id) != null:
		var portrait := UiFactory.portrait(speaker_id, 112, 104)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		heading.add_child(portrait)
	var title_column := UiFactory.vbox(6)
	heading.add_child(title_column)
	title_column.add_child(UiFactory.title(str(event.get("title", "Audience")), 26))
	title_column.add_child(UiFactory.muted(str(event.get("speaker", "")), 16))
	title_column.add_child(UiFactory.muted("Petition %d of %d" % [state.event_index + 1, state.event_queue.size()], 13))
	_center.add_child(UiFactory.rule())
	_center.add_child(UiFactory.rich(str(event.get("text", ""))))
	var any_open := false
	var index := 0
	for choice in event.get("choices", []):
		var fails := ConditionChecker.choice_failures(choice, state, GameManager.db)
		var button := UiFactory.button(str(choice.get("text", "...")))
		button.disabled = not fails.is_empty()
		if fails.is_empty():
			any_open = true
			button.pressed.connect(_choose.bind(index))
		_center.add_child(button)
		var preview := EffectResolver.preview(choice.get("effects", []), GameManager.db)
		if not fails.is_empty():
			preview = fails[0] if preview == "" else fails[0] + " · " + preview
		if preview != "":
			_center.add_child(UiFactory.muted(preview, 13))
		index += 1
	if not any_open:
		var leave := UiFactory.button("There is nothing you can do about this today.")
		leave.pressed.connect(_choose.bind(-1))
		_center.add_child(leave)


func _show_action(state: CampaignState) -> void:
	_primary.visible = true
	_primary.text = WeekLoop.primary_label("action", not _selected.is_empty())
	_primary.disabled = _selected.is_empty()
	_center.add_child(UiFactory.title("One decree", 24))
	_center.add_child(UiFactory.muted("You get one. The others wait until next week."))
	var tabs := UiFactory.flow(6)
	_center.add_child(tabs)
	for category in ["Economy", "Diplomacy", "Intrigue", "Military", "Personal"]:
		var button := UiFactory.chip(category)
		if category == _category:
			button.add_theme_color_override("font_color", GameTheme.GOLD)
		button.pressed.connect(_set_category.bind(category))
		tabs.add_child(button)
	var shown := 0
	for row in ActionBoard.column(state, GameManager.db, _category):
		var action: Dictionary = row["action"]
		var open := bool(row["open"])
		shown += 1
		var picked := open and str(action.get("id", "")) == str(_selected.get("id", ""))
		var button := UiFactory.button(("▸ " if picked else "") + str(action.get("title", "Action")))
		button.disabled = not open
		if open:
			button.pressed.connect(_select_action.bind(action))
		_center.add_child(button)
		if not open:
			_center.add_child(UiFactory.muted(str(row["reason"]), 13))
	if shown == 0:
		_center.add_child(UiFactory.muted("Nothing in this column is yours to order. Try another."))
	if not _selected.is_empty():
		_center.add_child(UiFactory.rule())
		_center.add_child(UiFactory.label(str(_selected.get("summary", "")), 15))
		var preview := EffectResolver.preview(_selected.get("effects", []), GameManager.db)
		if preview != "":
			_center.add_child(UiFactory.muted(preview))


func _show_lines(title: String, lines: Array, button_text: String) -> void:
	_primary.visible = true
	_primary.disabled = false
	_primary.text = button_text
	_center.add_child(UiFactory.title(title if title != "" else "The week turns", 24))
	if lines.is_empty():
		_center.add_child(UiFactory.label("The realm is quiet, which is its own kind of news."))
	for line in lines:
		_center.add_child(UiFactory.label("· " + str(line)))


func _on_primary() -> void:
	if _busy:
		return
	var state := GameManager.state
	match state.phase:
		"overview":
			if state.event_queue.is_empty():
				EventDirector.pick_audience(state, GameManager.db)
			state.phase = "event"
			state.banner = ""
			_refresh()
		"action":
			if _selected.is_empty():
				return
			_commit_action(_selected)
		"response":
			if state.defeat_reason != "":
				GameManager.show_ending(EndingDirector.resolve_defeat(state, GameManager.db, state.defeat_reason))
				return
			state.phase = "overview"
			state.banner = ""
			state.week_report = []
			state.week_title = ""
			_selected = {}
			_refresh()


func _choose(index: int) -> void:
	if _busy:
		return
	var state := GameManager.state
	var event := EventDirector.current(state, GameManager.db)
	if index < 0:
		state.add_decision({"turn": state.turn, "event": event.get("id", ""), "choice": "step_back", "label": "Stepped back"})
		_advance_event()
		return
	var choices: Array = event.get("choices", [])
	if index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if not ConditionChecker.choice_failures(choice, state, GameManager.db).is_empty():
		return
	_busy = true
	var result := EffectResolver.apply(state, choice.get("effects", []), GameManager.db)
	state.add_decision({
		"turn": state.turn,
		"event": str(event.get("id", "")),
		"choice": str(choice.get("id", index)),
		"label": str(choice.get("text", "")),
	})
	if str(result.get("defeat", "")) != "":
		GameManager.show_ending(EndingDirector.resolve_defeat(state, GameManager.db, str(result["defeat"])))
		return
	if not result.get("battle", {}).is_empty():
		state.post_battle = "advance_event"
		GameManager.launch_battle()
		return
	_busy = false
	_show_choice_result(choice, result)


func _show_choice_result(choice: Dictionary, result: Dictionary) -> void:
	var state := GameManager.state
	# Commit the decision before showing its receipt, so a save cannot repeat it.
	state.event_index += 1
	if state.event_index >= state.event_queue.size():
		state.phase = "action"
		_selected = {}
	UiFactory.clear(_center)
	_primary.visible = false
	_center.add_child(UiFactory.muted("YOUR WORD BECOMES POLICY", 13))
	_center.add_child(UiFactory.title("The court remembers", 26))
	_center.add_child(UiFactory.rule())
	_center.add_child(UiFactory.label(str(choice.get("text", "")), 19, GameTheme.GOLD))
	var outcome := str(choice.get("outcome", ""))
	if outcome != "":
		_center.add_child(UiFactory.rich(outcome, 18))
	for line in result.get("log", []):
		_center.add_child(UiFactory.label(str(line), 16))
	var next := UiFactory.primary("Continue the audience")
	next.pressed.connect(_refresh)
	_center.add_child(next)


func _advance_event() -> void:
	var state := GameManager.state
	state.event_index += 1
	if state.event_index >= state.event_queue.size():
		state.phase = "action"
		_selected = {}
	_busy = false
	_refresh()


func _commit_action(action: Dictionary) -> void:
	var state := GameManager.state
	if state.action_taken != "":
		return
	if not ConditionChecker.choice_failures(action, state, GameManager.db).is_empty():
		_selected = {}
		_refresh()
		return
	var available := false
	for fresh in ActionBoard.available(state, GameManager.db):
		if str(fresh.get("id", "")) == str(action.get("id", "")):
			available = true
			break
	if not available:
		_selected = {}
		_refresh()
		return
	_busy = true
	state.action_taken = str(action.get("id", "action"))
	var result := EffectResolver.apply(state, action.get("effects", []), GameManager.db)
	state.add_decision({"turn": state.turn, "event": "action", "choice": state.action_taken, "label": str(action.get("title", ""))})
	_selected = {}
	if str(result.get("defeat", "")) != "":
		GameManager.show_ending(EndingDirector.resolve_defeat(state, GameManager.db, str(result["defeat"])))
		return
	if not result.get("battle", {}).is_empty():
		state.post_battle = "close_week"
		GameManager.launch_battle()
		return
	_close_and_respond()


func _close_and_respond() -> void:
	_busy = false
	CampaignRules.close_week(GameManager.state, GameManager.db)
	_refresh()


func _set_category(category: String) -> void:
	_category = category
	_refresh()


func _select_action(action: Dictionary) -> void:
	_selected = action
	_refresh()


func _open_map() -> void:
	var view := MapView.new()
	view.dismissed.connect(_close_overlay)
	_show_overlay(view)
	view.present(GameManager.state, GameManager.db)


func _open_court() -> void:
	var view := CourtView.new()
	view.dismissed.connect(_close_overlay)
	_show_overlay(view)
	view.present(GameManager.state, GameManager.db)


func _open_ledger() -> void:
	var view := LedgerView.new()
	view.dismissed.connect(_close_overlay)
	_show_overlay(view)
	view.present(GameManager.state, GameManager.db, false)


func _open_army() -> void:
	var view := ArmyView.new()
	view.dismissed.connect(_close_overlay)
	_show_overlay(view)
	view.present(GameManager.state, GameManager.db)


func _show_overlay(view: Control) -> void:
	UiFactory.clear(_overlay)
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(view)


func _close_overlay() -> void:
	UiFactory.clear(_overlay)
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _open_throne() -> void:
	var state := GameManager.state
	var panel := UiFactory.panel()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_show_overlay(panel)
	var margin := _overlay_margin()
	panel.add_child(margin)
	var column := UiFactory.vbox(8)
	margin.add_child(UiFactory.scroll(column))
	var header := UiFactory.hbox()
	header.add_child(UiFactory.title("Take the Throne", 28))
	header.add_child(UiFactory.filler())
	var close := UiFactory.chip("Not yet")
	close.pressed.connect(_close_overlay)
	header.add_child(close)
	column.add_child(header)
	column.add_child(UiFactory.muted("Claim is not victory. The method has to survive the kingdom you actually built."))
	if state.claim < 100:
		column.add_child(UiFactory.label("Your claim is %d/100. Build it to 100 before attempting a settlement." % state.claim, 17, GameTheme.GOLD))
	for row in EndingDirector.list_routes(state, GameManager.db):
		var route: Dictionary = row["route"]
		var open := bool(row["open"])
		var button := UiFactory.button(str(route.get("title", "Route")))
		button.disabled = not open or state.claim < 100
		if open:
			button.pressed.connect(_attempt_route.bind(str(route.get("id", ""))))
		column.add_child(button)
		column.add_child(UiFactory.muted(str(route.get("summary", ""))))
		if not open:
			column.add_child(UiFactory.label(str(row["reason"]), 13, GameTheme.BAD))


func _attempt_route(route_id: String) -> void:
	var state := GameManager.state
	var route := EndingDirector._route(GameManager.db, route_id)
	if state.claim < 100 or route.is_empty() or not ConditionChecker.met(route.get("requires", {}), state, GameManager.db):
		return
	_close_overlay()
	var battle_id := str(route.get("battle_id", ""))
	if battle_id != "":
		state.pending_throne_route = route_id
		state.pending_battle = {"battle_id": battle_id, "on_victory": [], "on_defeat": [], "on_retreat": []}
		state.post_battle = "throne"
		GameManager.launch_battle()
		return
	GameManager.show_ending(EndingDirector.resolve(state, GameManager.db, route_id))


func _open_world() -> void:
	var view := CodexView.new()
	view.dismissed.connect(_close_overlay)
	_show_overlay(view)
	view.present(GameManager.db)


func _overlay_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	return margin


func _open_pause() -> void:
	var panel := UiFactory.panel()
	_show_overlay(panel)
	var column := UiFactory.vbox(10)
	var margin := _overlay_margin()
	panel.add_child(margin)
	margin.add_child(UiFactory.scroll(column))
	column.add_child(UiFactory.title("Paused", 28))
	column.add_child(UiFactory.muted(Balance.date_line(GameManager.state.turn)))
	var resume := UiFactory.button("Resume")
	resume.pressed.connect(_close_overlay)
	column.add_child(resume)
	var save := UiFactory.button("Save campaign")
	save.pressed.connect(_open_save)
	column.add_child(save)
	var chronicle := UiFactory.button("Chronicle")
	chronicle.pressed.connect(func(): GameManager.open_chronicle())
	column.add_child(chronicle)
	var menu := UiFactory.button("Main menu")
	menu.pressed.connect(func(): GameManager.to_menu())
	column.add_child(menu)


func _open_save() -> void:
	var panel := UiFactory.panel()
	_show_overlay(panel)
	var column := UiFactory.vbox(8)
	var margin := _overlay_margin()
	panel.add_child(margin)
	margin.add_child(UiFactory.scroll(column))
	column.add_child(UiFactory.title("Save", 28))
	column.add_child(UiFactory.muted("The end of every week also writes an autosave."))
	for slot in [1, 2, 3]:
		var button := UiFactory.button("Save slot %d" % slot)
		button.pressed.connect(_write_slot.bind(slot))
		column.add_child(button)
	var back := UiFactory.button("Back")
	back.pressed.connect(_close_overlay)
	column.add_child(back)


func _write_slot(slot: int) -> void:
	SaveManager.save_campaign(GameManager.state, slot, "Manual")
	_close_overlay()
	GameManager.state.banner = "Saved to slot %d." % slot
	_refresh()


func _toggle_debug() -> void:
	if _debug == null:
		return
	_debug.visible = not _debug.visible
	if _debug.visible:
		_debug.present(GameManager.state, GameManager.db)


func _debug_battle(battle_id: String) -> void:
	var state := GameManager.state
	state.pending_battle = {"battle_id": battle_id, "on_victory": [], "on_defeat": [], "on_retreat": []}
	state.post_battle = ""
	if GameManager.db.battles.has(battle_id):
		GameManager.launch_battle()


func _debug_route(route_id: String) -> void:
	GameManager.show_ending(EndingDirector.resolve(GameManager.state, GameManager.db, route_id, {}, "triumph"))


func _debug_event(event_id: String) -> void:
	if not GameManager.db.events_by_id.has(event_id):
		GameManager.state.banner = "No event called %s." % event_id
		_refresh()
		return
	var state := GameManager.state
	state.phase = "event"
	state.event_queue = [event_id]
	state.event_index = 0
	state.seen_events[event_id] = int(state.seen_events.get(event_id, 0)) + 1
	_debug.visible = false
	_refresh()
