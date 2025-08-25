extends CharacterBody2D

@export var move_speed := 200
@export var jump_force := -400
var is_grounded :=  false

func _physics_process(delta):
	handle_movement(delta)
	apply_gravity(delta)

func handle_movement(delta):
	var input_dir = Input.get_axis("move_left","move_right")
	velocity.x = input_dir * move_speed
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta
