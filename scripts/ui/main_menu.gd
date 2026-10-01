extends Control

var _settings: Control

func _ready() -> void:
	GameTheme.mount(self)
	_build()

func _build() -> void:
	UiFactory.backdrop(self, "throne", 0.1)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 64)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var row := UiFactory.hbox(40)
	margin.add_child(row)
	var column := UiFactory.vbox(8)
	column.custom_minimum_size.x = 460
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(column)
	column.add_child(UiFactory.muted("N E Z R E L   •   A   K I N G D O M   D I V I D E D", 13))
	column.add_child(UiFactory.filler())
	column.add_child(UiFactory.title("USURPER", 64))
	column.add_child(UiFactory.label("THE CROWN IS EMPTY", 16, GameTheme.GOLD))
	column.add_child(UiFactory.rule())
	column.add_child(UiFactory.label("Four lives. One crown.\nA kingdom that will remember.", 23))
	column.add_child(UiFactory.muted("Build your claim through alliances, evidence and steel. Decide what the throne will cost you.", 16))
	column.add_child(UiFactory.filler())
	var new_game := UiFactory.primary("Begin a new chronicle")
	new_game.pressed.connect(func(): GameManager.to_select())
	column.add_child(new_game)
	var slots := SaveManager.list_slots()
	var continue_game := UiFactory.button("Continue campaign")
	continue_game.disabled = slots.is_empty()
	if not slots.is_empty():
		continue_game.tooltip_text = str(slots[0].get("summary", "Latest saved campaign"))
		continue_game.pressed.connect(func(): GameManager.continue_latest())
	column.add_child(continue_game)
	var links := UiFactory.flow(8)
	column.add_child(links)
	for pair in [["Chronicle", _chronicle], ["World of Nezrel", _world], ["Settings", _open_settings], ["Quit", _quit]]:
		var button := UiFactory.chip(str(pair[0]))
		button.pressed.connect(pair[1])
		links.add_child(button)
	column.add_child(UiFactory.filler())
	column.add_child(UiFactory.muted("“A king fears the battlefield. A wise king fears his bedroom.”", 14))
	column.add_child(UiFactory.muted("A political chronicle in four acts", 12))
	row.add_child(UiFactory.filler())
	new_game.grab_focus()

func _chronicle() -> void:
	GameManager.open_chronicle()

func _quit() -> void:
	get_tree().quit()

func _world() -> void:
	if _settings != null:
		_settings.queue_free()
	var view := CodexView.new()
	_settings = view
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	view.present(GameManager.db)
	view.dismissed.connect(func(): view.queue_free(); _settings = null)

func _open_settings() -> void:
	if _settings != null:
		_settings.queue_free()
	_settings = UiFactory.panel()
	_settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_settings)
	var column := UiFactory.vbox(18)
	_settings.add_child(UiFactory.scroll(column))
	column.add_child(UiFactory.title("Settings", 36))
	var full := CheckButton.new()
	full.text = "Fullscreen"
	full.button_pressed = bool(MetaProgress.settings.get("fullscreen", false))
	full.toggled.connect(func(on):
		MetaProgress.settings["fullscreen"] = on
		MetaProgress.save_settings()
		AudioManager.apply_settings()
	)
	column.add_child(full)
	column.add_child(UiFactory.title("Audio", 24))
	for channel in [["Master", "volume", "muted"], ["Background music", "music_volume", "music_muted"], ["Menu tone", "tone_volume", "tone_muted"], ["Menu click", "click_volume", "click_muted"]]:
		_add_audio_control(column, str(channel[0]), str(channel[1]), str(channel[2]))
	column.add_child(UiFactory.title("How to play", 24))
	for line in ["A week has four steps: review your position, answer petitions, issue one decree, then read the realm’s response.", "Gold pays your soldiers. Rations keep them alive. Read the weekly forecast before expanding your army.", "Claim opens the path to the throne at 100. Each route still needs its own allies, evidence or military strength.", "The map, court, ledger and army can be consulted at any time. They do not spend your weekly decree.", "In battle, select a lane, assign an order, and commit reserves where they matter. Retreat can preserve an army you will need again.", "Press Esc to pause. Campaigns autosave each week; three manual slots let you keep turning points."]:
		column.add_child(UiFactory.label(line, 17))
	column.add_child(UiFactory.rule())
	column.add_child(UiFactory.muted("Story themes: political violence, bereavement, disputed assault allegations and end-of-life mercy. No graphic depictions."))
	column.add_child(UiFactory.muted("Created for Usurper: original illustrated environments and portraits. Interface typefaces: Cinzel and Source Sans 3, SIL Open Font License."))
	var back := UiFactory.primary("Return to the hall")
	back.pressed.connect(func(): _settings.queue_free(); _settings = null)
	column.add_child(back)

func _add_audio_control(column: VBoxContainer, caption: String, volume_key: String, mute_key: String) -> void:
	var row := UiFactory.hbox(12)
	column.add_child(row)
	var value := UiFactory.single("%s: %d%%" % [caption, roundi(float(MetaProgress.settings[volume_key]) * 100)])
	value.custom_minimum_size.x = 230
	row.add_child(value)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = float(MetaProgress.settings[volume_key]) * 100
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 200
	slider.tooltip_text = caption + " volume"
	row.add_child(slider)
	slider.value_changed.connect(func(level: float):
		MetaProgress.settings[volume_key] = level / 100.0
		value.text = "%s: %d%%" % [caption, roundi(level)]
		AudioManager.apply_settings()
		MetaProgress.save_settings()
	)
	var mute := CheckButton.new()
	mute.text = "Mute"
	mute.tooltip_text = "Mute " + caption.to_lower()
	mute.button_pressed = bool(MetaProgress.settings[mute_key])
	row.add_child(mute)
	mute.toggled.connect(func(on: bool):
		MetaProgress.settings[mute_key] = on
		AudioManager.apply_settings()
		MetaProgress.save_settings()
	)
