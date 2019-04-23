extends Camera2D

const ZOOM_AMOUNT = 1.1

func handle_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if event.button_mask & (BUTTON_MASK_MIDDLE) != 0:
			var local := make_input_local(event) as InputEventMouseMotion
			position -= local.relative
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_DOWN:
			zoom *= ZOOM_AMOUNT
		if event.button_index == BUTTON_WHEEL_UP:
			zoom /= ZOOM_AMOUNT
