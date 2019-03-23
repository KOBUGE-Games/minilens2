extends KinematicBody2D

export var gravity = Vector2(0, 768)
const FLOOR_NORMAL = Vector2(0, -1)
export var walk_speed = 192 # pixels/sec
var target_speed = 0
var scale_direction = 1
var direction: String # "left" or "right"

var velocity = Vector2()

var timer: Timer

func _physics_process(delta):
		
	# flip x-axis of nodes with normal direction
	if target_speed != 0:
		scale_direction = target_speed
		
	### PHYSICS ###

	# Horizontal force
	target_speed *= walk_speed
	velocity.x = lerp(velocity.x, target_speed, 1)
	# Apply gravity
	velocity += delta * gravity
	
	# Move and Slide
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	# reset x-speed in case button is no longer pressed
	if timer.is_stopped():
		target_speed = 0
	else:
		move(direction)
	print(timer.get_time_left())

func start_moving(dir):
	timer.start()
	move(dir)

func move(dir):
	direction = dir
	if dir == "left":
		target_speed = -1
	elif dir == "right":
		target_speed = 1