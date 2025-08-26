extends CharacterBody2D

@export var player_number := 1  # Set this in the Inspector for each player
@export var move_speed := 200


func _physics_process(delta):
	
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("P%d_move_right" % [player_number]) - Input.get_action_strength("P%d_move_left" % [player_number])
	input_vector.y = Input.get_action_strength("P%d_move_down" % [player_number]) - Input.get_action_strength("P%d_move_up" % [player_number])
	
	# Normalize so diagonal movement isn't faster
	if input_vector.length() > 1:
		input_vector = input_vector.normalized()
	
	velocity = input_vector * move_speed
	move_and_slide()

func _process(delta):
	
	if Input.is_action_just_pressed("P%d_jump" % [player_number]):
		print("Player %d just jumped!" % [player_number])
	if Input.is_action_just_pressed("P%d_attack" % [player_number]):
		print("Player %d just attacked!" % [player_number])
