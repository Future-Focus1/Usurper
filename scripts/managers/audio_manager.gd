extends Node

const CHANNELS := {"music": "Music", "tone": "Menu Tone", "click": "Menu Click"}
var _players: Dictionary = {}

func _ready() -> void:
	for key in CHANNELS:
		var bus_name: String = CHANNELS[key]
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
		var player := AudioStreamPlayer.new()
		player.bus = bus_name
		add_child(player)
		_players[key] = player
	_players["music"].stream = load("res://assets/audio/Recording 2026-10-01 180336.mp3")
	_players["music"].stream.loop = true
	_players["tone"].stream = load("res://assets/audio/menu tone.mp3")
	_players["click"].stream = load("res://assets/audio/menu click.mp3")
	apply_settings()
	_players["music"].play()
	get_tree().node_added.connect(_wire_button)
	_wire_existing(get_tree().root)

func _wire_existing(node: Node) -> void:
	_wire_button(node)
	for child in node.get_children():
		_wire_existing(child)

func _wire_button(node: Node) -> void:
	if not node is BaseButton or node.has_meta("audio_wired"):
		return
	node.set_meta("audio_wired", true)
	node.pressed.connect(click)
	node.mouse_entered.connect(func():
		if not node.disabled:
			tone()
	)
	node.focus_entered.connect(func():
		if not node.disabled:
			tone()
	)

func apply_settings() -> void:
	_apply_bus("Master", "volume", "muted")
	for key in CHANNELS:
		_apply_bus(CHANNELS[key], key + "_volume", key + "_muted")
	if DisplayServer.get_name() == "headless":
		return
	if bool(MetaProgress.settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_bus(bus_name: String, volume_key: String, mute_key: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var volume := clampf(float(MetaProgress.settings.get(volume_key, 0.8)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume == 0.0 or bool(MetaProgress.settings.get(mute_key, false)))

func click() -> void:
	_players["click"].play()

func tone() -> void:
	_players["tone"].play()

func _exit_tree() -> void:
	for player in _players.values():
		player.stop()
		player.stream = null
	_players.clear()
