extends "res://objects/shared/pickup.gd"

func try_pickup(entity: Object) -> bool:
	queue_free()
	return true
