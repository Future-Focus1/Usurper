extends Control

var _settings: Control


func _ready() -> void:
	GameTheme.mount(self)
	_build()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = GameTheme.INK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)
	var column := UiFactory.vbox(14)
	margin.add_child(column)
	column.add_child(UiFactory.muted("THE KINGDOM OF NEZREL", 13))
	column.add_child(UiFactory.title("USURPER", 52))
	column.add_child(UiFactory.rule())
	column.add_child(UiFactory.label("The crown is empty. Four people can make the kingdom believe it was always theirs.", 20))
	column.add_child(UiFactory.muted("\"A king fears the battlefield. A wise king fears his bedroom.\"", 16))
	column.add_child(UiFactory.filler())
	var holder := CenterContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(holder)
	var buttons := UiFactory.vbox(10)
	buttons.custom_minimum_size = Vector2(420, 0)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.add_child(buttons)
	var new_game := UiFactory.button("New Game")
	new_game.pressed.connect(func(): AudioManager.click(); GameManager.to_select())
	buttons.add_child(new_game)
	var continue_game := UiFactory.button("Continue")
	var slots := SaveManager.list_slots()
	if slots.is_empty():
		continue_game.disabled = true
		continue_game.text = "Continue — no campaign yet"
	else:
		continue_game.text = "Continue — %s" % str(slots[0].get("summary", "saved campaign"))
		continue_game.pressed.connect(func(): AudioManager.click(); GameManager.continue_latest())
	buttons.add_child(continue_game)
	var chronicle := UiFactory.button("Chronicle of Nezrel")
	chronicle.pressed.connect(func(): AudioManager.click(); GameManager.open_chronicle())
	buttons.add_child(chronicle)
	var settings := UiFactory.button("Settings")
	settings.pressed.connect(_open_settings)
	buttons.add_child(settings)
	var quit := UiFactory.button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	buttons.add_child(quit)
	column.add_child(UiFactory.muted("Godot 4.6  ·  placeholders stand in until the final art arrives", 13))


func _open_settings() -> void:
	if _settings != null:
		_settings.queue_free()
	_settings = PanelContainer.new()
	_settings.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_settings)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	_settings.add_child(margin)
	var column := UiFactory.vbox(12)
	margin.add_child(UiFactory.scroll(column))
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
	column.add_child(UiFactory.muted("Volume"))
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = float(MetaProgress.settings.get("volume", 0.8))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value):
		MetaProgress.settings["volume"] = value
		MetaProgress.save_settings()
		AudioManager.apply_settings()
	)
	column.add_child(slider)
	column.add_child(UiFactory.muted("Usurper keeps campaign saves and the Chronicle on this machine, apart from each other."))
	var back := UiFactory.button("Back")
	back.pressed.connect(func(): _settings.queue_free(); _settings = null)
	column.add_child(back)
