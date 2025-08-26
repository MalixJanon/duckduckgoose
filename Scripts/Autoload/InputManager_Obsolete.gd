extends Node

# Maps player number → device ID (or "keyboard")
var player_devices := {}
# Queue of player slots waiting for assignment
var unassigned_players := []

# Example: 2‑player setup
const MAX_PLAYERS := 2

func _ready():
	_setup_actions()
	_init_players()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _setup_actions():
	# Define your core actions here
	var actions = [
		"move_left", "move_right", "move_up", "move_down",
		"jump", "attack"
	]
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	# Keyboard bindings
var left_key := InputEventKey.new()
	left_key.keycode = KEY_A
	InputMap.action_add_event("move_left", left_key)

	var right_key := InputEventKey.new()
	right_key.keycode = KEY_D
	InputMap.action_add_event("move_right", right_key)

	var up_key := InputEventKey.new()
	up_key.keycode = KEY_W
	InputMap.action_add_event("move_up", up_key)

	var down_key := InputEventKey.new()
	down_key.keycode = KEY_S
	InputMap.action_add_event("move_down", down_key)

	var jump_key := InputEventKey.new()
	jump_key.keycode = KEY_SPACE
	InputMap.action_add_event("jump", jump_key)

	var attack_key := InputEventKey.new()
	attack_key.keycode = KEY_F
	InputMap.action_add_event("attack", attack_key)


	# Gamepad bindings (buttons)
	var jump_btn := InputEventJoypadButton.new()
	jump_btn.button_index = JOY_BUTTON_A
	InputMap.action_add_event("jump", jump_btn)

	var attack_btn := InputEventJoypadButton.new()
	attack_btn.button_index = JOY_BUTTON_X
	InputMap.action_add_event("attack", attack_btn)

	# Gamepad bindings (D‑pad)
	var left_btn := InputEventJoypadButton.new()
	left_btn.button_index = JOY_BUTTON_DPAD_LEFT
	InputMap.action_add_event("move_left", left_btn)

	var right_btn := InputEventJoypadButton.new()
	right_btn.button_index = JOY_BUTTON_DPAD_RIGHT
	InputMap.action_add_event("move_right", right_btn)

	var up_btn := InputEventJoypadButton.new()
	up_btn.button_index = JOY_BUTTON_DPAD_UP
	InputMap.action_add_event("move_up", up_btn)

	var down_btn := InputEventJoypadButton.new()
	down_btn.button_index = JOY_BUTTON_DPAD_DOWN
	InputMap.action_add_event("move_down", down_btn)

	# Gamepad bindings (analog stick)
	var left_axis := InputEventJoypadMotion.new()
	left_axis.axis = JOY_AXIS_LEFT_X
	left_axis.axis_value = -1
	InputMap.action_add_event("move_left", left_axis)

	var right_axis := InputEventJoypadMotion.new()
	right_axis.axis = JOY_AXIS_LEFT_X
	right_axis.axis_value = 1
	InputMap.action_add_event("move_right", right_axis)

	var up_axis := InputEventJoypadMotion.new()
	up_axis.axis = JOY_AXIS_LEFT_Y
	up_axis.axis_value = -1
	InputMap.action_add_event("move_up", up_axis)

	var down_axis := InputEventJoypadMotion.new()
	down_axis.axis = JOY_AXIS_LEFT_Y
	down_axis.axis_value = 1
	InputMap.action_add_event("move_down", down_axis)

func _init_players():
	player_devices.clear()
	unassigned_players.clear()
	for i in range(1, MAX_PLAYERS + 1):
		player_devices[i] = null
		unassigned_players.append(i)

func _input(event):
	if unassigned_players.is_empty():
		return  # All players assigned

	# Keyboard or mouse
	if event is InputEventKey or event is InputEventMouseButton:
		_assign_next_player("keyboard", 0)

	# Gamepad button
	elif event is InputEventJoypadButton:
		_assign_next_player("gamepad", event.device)

	# Gamepad axis (stick movement)
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		_assign_next_player("gamepad", event.device)

func _assign_next_player(device_type: String, device_id: int):
	if unassigned_players.is_empty():
		return

	var player_num = unassigned_players.pop_front()
	assign_player(player_num, device_type, device_id)
	print("Assigned Player %d to %s (ID: %d)" % [player_num, device_type, device_id])

func assign_player(player_num: int, device_type: String, device_id: int):
	if device_type == "keyboard":
		player_devices[player_num] = "keyboard"
	else:
		player_devices[player_num] = device_id

func _on_joy_connection_changed(device_id: int, connected: bool):
	if not connected:
		# Find which player was using this device
		for player_num in player_devices.keys():
			if player_devices[player_num] == device_id:
				print("Player %d's controller disconnected (ID: %d)" % [player_num, device_id])
				player_devices[player_num] = null
				if not unassigned_players.has(player_num):
					unassigned_players.append(player_num)

# Optional helper: get device for a player
func get_device_for_player(player_num: int):
	return player_devices.get(player_num, null)
