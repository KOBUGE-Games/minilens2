extends "res://objects/shared/physics_movement.gd"

onready var subnode = $subnode

func _ready():
	timer = $Timer

func _physics_process(delta):
	
	subnode.scale.x = scale_direction
	
	if Input.is_action_pressed("ui_left") and !Input.is_action_pressed("ui_right") and timer.is_stopped():
		start_moving("left")
	if Input.is_action_pressed("ui_right") and !Input.is_action_pressed("ui_left") and timer.is_stopped():
		start_moving("right")