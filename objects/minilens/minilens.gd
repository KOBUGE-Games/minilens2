extends "res://objects/shared/physics_entity.gd"

export var sink_speed = 384
var strength = 1.0
var bombs_available = 0
var moved_after_bomb = true
onready var subnode = $subnode

func _ready():
	node_to_move = $subnode

func calculate_move():
	var is_acid_below = Grid.has_entity_at_position(get_grid_position() + Vector2(0, 1), Grid.Flag.ACID)
	var is_acid = Grid.has_entity_at_position(get_grid_position(), Grid.Flag.ACID)
	var is_ladder_below = Grid.has_entity_at_position(get_grid_position() + Vector2(0, 1), Grid.Flag.LADDER)
	var is_ladder = Grid.has_entity_at_position(get_grid_position(), Grid.Flag.LADDER)
	
	# Sink
	if is_acid:
		queue_free()
		return
	
	# Fall / climb
	if is_ladder or is_ladder_below:
		if Input.is_action_pressed("ui_down") and !Input.is_action_pressed("ui_up"):
			move(DOWN, strength + get_mass())
	else:
		move(DOWN, get_mass(), sink_speed if is_acid_below else fall_speed)
	
	if is_ladder and Input.is_action_pressed("ui_up") and !Input.is_action_pressed("ui_down"):
		move(UP, strength + get_mass())
	
	# Walk
	if Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
		if !_moving:
			subnode.scale.x = -1
		move(LEFT, strength + get_mass())
	
	if Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left"):
		if !_moving:
			subnode.scale.x = 1
		move(RIGHT, strength + get_mass())
	
	# Bomb
	if Input.is_action_pressed("ui_select") and bombs_available > 0 and moved_after_bomb:
		bombs_available -= 1
		
		var bomb_instance = preload("res://objects/bomb/bomb.tscn").instance()
		bomb_instance.position = position
		get_parent().add_child(bomb_instance)
	
	if _moving:
		moved_after_bomb = true

func add_bombs(amount: int):
	bombs_available += amount

func explode():
	queue_free()
