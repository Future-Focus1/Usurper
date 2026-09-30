class_name CodexView
extends Control

signal dismissed

func present(db: ContentDB) -> void:
	UiFactory.backdrop(self, "map", 0.85)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column := UiFactory.vbox(12)
	margin.add_child(column)
	var header := UiFactory.hbox()
	column.add_child(header)
	header.add_child(UiFactory.title("The World of Nezrel", 30))
	var close := UiFactory.chip("Close")
	close.pressed.connect(func(): dismissed.emit())
	header.add_child(close)
	column.add_child(UiFactory.muted("The history people agree upon. Secrets must still be discovered in your campaign."))
	var body := UiFactory.hbox(20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var entries := UiFactory.vbox(6)
	var entry_scroll := UiFactory.scroll(entries)
	entry_scroll.custom_minimum_size.x = 260
	entry_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(entry_scroll)
	var detail := UiFactory.vbox(12)
	var frame := UiFactory.panel()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(UiFactory.scroll(detail))
	body.add_child(frame)
	var first := true
	for category in db.lore.get("categories", []):
		entries.add_child(UiFactory.title(str(category.get("title", "")), 18))
		for entry in category.get("entries", []):
			var button := UiFactory.button(str(entry.get("title", "")))
			button.pressed.connect(_show.bind(detail, entry))
			entries.add_child(button)
			if first:
				_show(detail, entry)
				first = false
		entries.add_child(UiFactory.rule())

func _show(detail: VBoxContainer, entry: Dictionary) -> void:
	UiFactory.clear(detail)
	detail.add_child(UiFactory.muted("THE ATLAS OF NEZREL", 13))
	detail.add_child(UiFactory.title(str(entry.get("title", "")), 28))
	detail.add_child(UiFactory.rule())
	detail.add_child(UiFactory.rich(str(entry.get("text", "")), 18))
