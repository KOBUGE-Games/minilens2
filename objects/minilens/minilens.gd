extends "res://objects/shared/physics_entity.gd"

var strength = 1.0
onready var subnode = $subnode

func _ready():
	node_to_move = $subnode
	tween = $tween

func calculate_move():
	move(DOWN, get_mass())
	
	if Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right"):
		if !_moving:
			subnode.scale.x = -1
		move(LEFT, strength + get_mass())
	
	if Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left"):
		if !_moving:
			subnode.scale.x = 1
		move(RIGHT, strength + get_mass())
	
	if Input.is_action_pressed("ui_select") and !_moving:
		var bomb_instance = preload("res://objects/bomb/bomb.tscn").instance()
		bomb_instance.position = position
		get_parent().add_child(bomb_instance)

func explode():
	queue_free()
