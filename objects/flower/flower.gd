extends "res://objects/shared/pickup.gd"

func try_pickup(_entity: Object) -> bool:
	queue_free()
	return true
