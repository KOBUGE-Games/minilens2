extends VBoxContainer

func get_tile_properties():
	return [str($group.value), str($target_group.value)]
