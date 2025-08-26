extends Node

# Player slot → device ("keyboard" or joypad ID)
var player_devices: Dictionary = {}
# Queue of unassigned player slots
var unassigned_players: Array = []

const MAX_PLAYERS := 2

func _ready():
	_setup_actions()
	_init_players()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

signal player_input(player_number: int, action: String, value: float)

# ACTION SETUP
static func _setup_actions():
	# Actions to create
	var actions = ["move_left", "move_right", "move_up", "move_down", "jump", "attack"]
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	# Keyboard bindings
	var key_bindings := {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_W,
		"move_down": KEY_S,
		"jump": KEY_SPACE,
		"attack": KEY_F
	}
	for action in key_bindings:
		var ev := InputEventKey.new()
		ev.keycode = key_bindings[action]
		InputMap.action_add_event(action, ev)

	# Gamepad button bindings
	var button_bindings := {
		"jump": JOY_BUTTON_A,
		"attack": JOY_BUTTON_X,
		"move_left": JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up": JOY_BUTTON_DPAD_UP,
		"move_down": JOY_BUTTON_DPAD_DOWN
	}
	for action in button_bindings:
		var btn := InputEventJoypadButton.new()
		btn.button_index = button_bindings[action]
		InputMap.action_add_event(action, btn)

	# Gamepad analog stick bindings
	var axis_bindings := {
		"move_left":  [JOY_AXIS_LEFT_X, -1],
		"move_right": [JOY_AXIS_LEFT_X,  1],
		"move_up":    [JOY_AXIS_LEFT_Y, -1],
		"move_down":  [JOY_AXIS_LEFT_Y,  1]
	}
	for action in axis_bindings:
		var axis := InputEventJoypadMotion.new()
		axis.axis = axis_bindings[action][0]
		axis.axis_value = axis_bindings[action][1]
		InputMap.action_add_event(action, axis)


# PLAYER ASSIGNMENT
func _init_players():
	player_devices.clear()
	unassigned_players.clear()
	for i in range(1, MAX_PLAYERS + 1):
		player_devices[i] = null
		unassigned_players.append(i)

func _input(event):
	if unassigned_players.is_empty():
		return
	if event is InputEventKey or event is InputEventMouseButton:
		_assign_next_player("keyboard", 0)
	elif event is InputEventJoypadButton:
		_assign_next_player("gamepad", event.device)
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		_assign_next_player("gamepad", event.device)
	if event is InputEventJoypadButton:
		print("Joypad button from device:", event.device, "button:", event.button_index)
	elif event is InputEventJoypadMotion:
		print("Joypad motion from device:", event.device, "axis:", event.axis, "value:", event.axis_value)


func _assign_next_player(device_type: String, device_id: int):
	# Prevent duplicate keyboard assignment
	if device_type == "keyboard":
		if player_devices.values().has("keyboard"):
			return
	
	# Prevent duplicate gamepad assignment
	if device_type == "gamepad":
		for assigned_device in player_devices.values():
			if typeof(assigned_device) == TYPE_INT and assigned_device == device_id:
				return
	
	if unassigned_players.is_empty():
		return
	
	var player_num = unassigned_players.pop_front()
	assign_player(player_num, device_type, device_id)
	print("Assigned Player %d to %s (ID: %d)" % [player_num, device_type, device_id])


func assign_player(player_num: int, device_type: String, device_id: int):
	player_devices[player_num] = "keyboard" if device_type == "keyboard" else device_id


# HOT-SWAP HANDLING
func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		return
	for player_num in player_devices:
		var assigned_device = player_devices[player_num]
		if typeof(assigned_device) == TYPE_INT and assigned_device == device_id:
			print("Player %d's controller disconnected (ID: %d)" % [player_num, device_id])
			player_devices[player_num] = null
			if not unassigned_players.has(player_num):
				unassigned_players.append(player_num)


# HELPER
func get_device_for_player(player_num: int):
	return player_devices.get(player_num, null)
