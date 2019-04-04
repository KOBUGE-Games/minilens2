extends "res://objects/shared/physics_entity.gd"

func _ready():
	node_to_move = $subnode

func get_mass() -> float:
	return 1.0

func calculate_move():
	move(DOWN, get_mass())

func explode():
	queue_free()
