extends Node

## Sound is optional. Missing files stay silent so art and audio can arrive later.


func _ready() -> void:
	apply_settings()


func apply_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var linear := clampf(float(MetaProgress.settings.get("volume", 0.8)), 0.0, 1.0)
	var db := -40.0 if linear <= 0.001 else linear_to_db(linear)
	AudioServer.set_bus_volume_db(0, db)
	if bool(MetaProgress.settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func click() -> void:
	_play("res://assets/audio/click.ogg")


func _play(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = load(path)
	player.finished.connect(player.queue_free)
	player.play()
