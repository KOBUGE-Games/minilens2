extends VBoxContainer

func set_tile_properties(values):
	$bombs.value = int(values[0]) if values.size() > 0 else 0

func get_tile_properties():
	return [str($bombs.value)] if $bombs.value != 0 else []
