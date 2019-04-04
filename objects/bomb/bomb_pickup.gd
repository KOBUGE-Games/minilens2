extends "res://objects/shared/pickup.gd"

func try_pickup(entity: Object) -> bool:
	if entity.has_method("add_bombs"):
		entity.add_bombs(1)
		queue_free()
		return true
	else:
		return false
