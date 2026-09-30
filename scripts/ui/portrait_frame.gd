class_name PortraitFrame
extends Control

var texture: Texture2D

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if texture == null or size.x <= 0 or size.y <= 0:
		return
	var source := texture.get_size()
	var ratio := size.x / size.y
	var crop := source
	var offset := Vector2.ZERO
	if source.x / source.y < ratio:
		crop.y = source.x / ratio
		offset.y = (source.y - crop.y) * 0.14
	else:
		crop.x = source.y * ratio
		offset.x = (source.x - crop.x) * 0.5
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, size), Rect2(offset, crop))
