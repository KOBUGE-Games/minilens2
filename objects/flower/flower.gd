extends "res://objects/shared/pickup.gd"

func _ready() -> void:
	Goals.add_goal(self, Goals.GoalType.FLOWER)

func try_pickup(_entity: Object) -> bool:
	queue_free()
	return true
