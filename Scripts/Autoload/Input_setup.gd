extends Node

# Base action names (no player suffix)
const BASE_ACTIONS = ["move_left", "move_right", "jump", "shoot", "slide"]

# Default bindings for each player
var default_bindings := {
	1: { # Player 1: Keyboard
		"move_left": [KEY_A],
		"move_right": [KEY_D],
		"jump": [KEY_SPACE],
		"shoot": [MOUSE_BUTTON_LEFT],
		"slide": [KEY_S]
	},
	2: { # Player 2: Gamepad 0
		"move_left": [
			{"joy_axis": JOY_AXIS_LEFT_X, "axis_value": -1},
			{"joy_button": JOY_BUTTON_DPAD_LEFT}],
		"move_right": [
			{"joy_axis": JOY_AXIS_RIGHT_X, "axis_value": 1},
			{"joy_button": JOY_BUTTON_DPAD_RIGHT}],
		"jump": [JOY_BUTTON_A],
		"shoot": [JOY_AXIS_TRIGGER_RIGHT],
		"slide": [
			{"joy_axis": JOY_AXIS_LEFT_Y, "axis_value": 1},
			{"joy_button": JOY_BUTTON_DPAD_DOWN}]
	}
}

# Tracks which device each player is using (0 = keyboard/mouse, >0 = gamepad ID)
var player_devices := {1: 0, 2: 0}
var unassigned_players := [1, 2]

func _ready():
	_setup_actions()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _setup_actions():
	for player_num in [1, 2]:
		for base_action in BASE_ACTIONS:
			var action_name = "%s_%d" % [base_action, player_num]
			if not InputMap.has_action(action_name):
				InputMap.add_action(action_name)
			# Add bindings
			for bind in default_bindings[player_num][base_action]:
				if typeof(bind) == TYPE_DICTIONARY:
					if bind.has("joy_axis"):
						var ev := InputEventJoypadMotion.new()
						ev.axis = bind.joy_axis
						ev.axis_value = bind.axis_value
						InputMap.action_add_event(action_name, ev)
					elif bind.has("joy_button"):
						var ev := InputEventJoypadButton.new()
						ev.button_index = bind.joy_button
						InputMap.action_add_event(action_name, ev)
				elif typeof(bind) == TYPE_INT:
					if bind >= MOUSE_BUTTON_LEFT and bind <= MOUSE_BUTTON_RIGHT:
						var ev := InputEventMouseButton.new()
						ev.button_index = bind
						InputMap.action_add_event(action_name, ev)
					else:
						var ev := InputEventKey.new()
						ev.physical_keycode = bind
						InputMap.action_add_event(action_name, ev)

func _input(event):
	if unassigned_players.is_empty():
		return # Everyone is already assigned
	
	# Keyboard/mouse
	if event is InputEventKey or event is InputEventMouseButton:
		_assign_next_player("keyboard", 0)
	
	# Gamepad button
	if event is InputEventJoypadButton or (InputEventJoypadMotion and abs(event.axis_value) > 0.5):
		_assign_next_player("gamepad", event.device)

# --- Input helper methods ---
func assign_player(player_num: int, device_type: String, device_id: int = 0):
	if device_type == "keyboard":
		player_devices[player_num] = 0
	elif device_type == "gamepad":
		player_devices[player_num] = device_id

func _assign_next_player(device_type: String, device_id: int):
	if unassigned_players.is_empty():
		return
	
	var player_num = unassigned_players.pop_front()
	assign_player(player_num, device_type, device_id)
	print("Assigned Player %d to %s (ID: %d)" % [player_num, device_type, device_id])

func _on_joy_connection_changed(device_id: int, connected: bool):
	if not connected:
		# Find which player was using this device
		for player_num in player_devices.keys():
			if player_devices[player_num] == device_id:
				print("Player %'s controller has disconnected (ID: %d)" % [player_num, device_id])
				player_devices[player_num] = null
				if not unassigned_players.has(player_num):
					unassigned_players.append(player_num)

func get_axis(player_num: int, left_action: String, right_action: String) -> float:
	return Input.get_action_strength(left_action + "_" + str(player_num)) - \
		Input.get_action_strength(right_action + "_" + str(player_num))

func is_pressed(player_num: int, action: String) -> bool:
	return Input.is_action_pressed(action + "_" + str(player_num))

func is_just_pressed(player_num: int, action: String) -> bool:
	return Input.is_action_just_pressed(action + "_" + str(player_num))
