extends VBoxContainer

func set_tile_properties(values):
	$group.value = int(values[0]) if values.size() > 0 else 1
	$target_group.value = int(values[1]) if values.size() > 1 else $group.value

func get_tile_properties():
	return [str($group.value), str($target_group.value)]
