extends Button

# warning-ignore:unused_signal
signal move_to(to_id)

func get_drag_data(position: Vector2):
	var preview = Control.new()
	preview.add_child(duplicate(0))
	preview.get_child(0).rect_position = -position
	set_drag_preview(preview)
	return {level_button = self}

func can_drop_data(_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("level_button")

func drop_data(position: Vector2, data):
	if position.y < rect_size.y / 2:
		data.level_button.emit_signal("move_to", get_position_in_parent())
	else:
		data.level_button.emit_signal("move_to", get_position_in_parent() + 1)
