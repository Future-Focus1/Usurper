extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	get_tree().current_scene = null
	var expected := OS.get_environment("USURPER_QA_USER_ROOT").replace("\\", "/").to_lower()
	assert(expected != "" and OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(expected + "/"))
	assert(AudioManager._players["music"].stream.loop)
	assert(AudioManager._players["music"].playing)
	for key in AudioManager.CHANNELS:
		assert(AudioManager._players[key].stream.get_length() > 0)
	var button := Button.new()
	add_child(button)
	assert(button.pressed.is_connected(AudioManager.click))
	AudioManager._wire_button(button)
	assert(button.pressed.get_connections().size() == 1)
	button.mouse_entered.emit()
	assert(AudioManager._players["tone"].playing)
	button.pressed.emit()
	assert(AudioManager._players["click"].playing)
	for key in AudioManager.CHANNELS:
		MetaProgress.settings[key + "_volume"] = 0.25
		AudioManager.apply_settings()
		var bus := AudioServer.get_bus_index(AudioManager.CHANNELS[key])
		assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.25))
		MetaProgress.settings[key + "_muted"] = true
		AudioManager.apply_settings()
		assert(AudioServer.is_bus_mute(bus))
		MetaProgress.settings[key + "_muted"] = false
		MetaProgress.settings[key + "_volume"] = 0.0
		AudioManager.apply_settings()
		assert(AudioServer.is_bus_mute(bus))
		MetaProgress.settings[key + "_volume"] = 0.25
		AudioManager.apply_settings()
		assert(not AudioServer.is_bus_mute(bus))
	MetaProgress.settings["muted"] = true
	AudioManager.apply_settings()
	assert(AudioServer.is_bus_mute(0))
	MetaProgress.save_settings()
	var prefs := SaveManager.read_json("user://settings.json")
	assert(prefs["muted"] and is_equal_approx(prefs["music_volume"], 0.25))
	MetaProgress.settings["music_volume"] = 0.9
	MetaProgress._ready()
	assert(is_equal_approx(MetaProgress.settings["music_volume"], 0.25))
	var menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	add_child(menu)
	menu._open_settings()
	await get_tree().process_frame
	var sliders: Array[Node] = menu.find_children("*", "HSlider", true, false)
	assert(sliders.size() == 4)
	sliders[1].value = 50
	assert(is_equal_approx(MetaProgress.settings["music_volume"], 0.5))
	GameManager.to_select()
	await get_tree().process_frame
	assert(AudioManager._players["music"].playing)
	print("PASS: audio streams, button wiring, channel volume/mute, saved settings, menu controls and continuous music")
	menu.queue_free()
	button.queue_free()
	AudioManager._exit_tree()
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()
