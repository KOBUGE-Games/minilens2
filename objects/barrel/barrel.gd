extends "res://objects/shared/physics_entity.gd"

var was_in_acid = false
export var sink_speed := 384.0
export var fall_speed := 768.0

func _ready():
	Goals.add_goal(self, Goals.GoalType.BARREL)
	node_to_move = $subnode

func get_mass() -> float:
	return 1.0

func calculate_move() -> void:
	var is_acid_below = Grid.has_entity_at_position(get_grid_position() + Vector2(0, 1), Grid.Flag.ACID)
	var is_acid = Grid.has_entity_at_position(get_grid_position(), Grid.Flag.ACID)
	
	if is_acid:
		if !was_in_acid:
			Goals.remove_goal(self)
		was_in_acid = true
	
	if was_in_acid and !is_acid:
		queue_free()
		return
	
	move(DOWN, Priority.FALL, sink_speed if is_acid_below or is_acid else fall_speed)

func explode():
	queue_free()
