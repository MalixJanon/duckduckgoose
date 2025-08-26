extends Node
signal player_input(player_number: int, action: String, value: float)

@export var MAX_PLAYERS  := 4

var player_devices := {} # { player_number: device_id }

# --- Create per-player actions dynamically ---
static func create_player_input(player_number: int):
	var actions = ["move_left", "move_right", "move_up", "move_down", "jump", "attack"]
	for action in actions:
		var action_name = "P%d_%s" % [player_number, action]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

# --- Bind controller---
static func bind_controller_input(player_number: int, device_number: int):
	var bindings = {
		"move_left":  JOY_BUTTON_DPAD_LEFT,
		"move_right": JOY_BUTTON_DPAD_RIGHT,
		"move_up":    JOY_BUTTON_DPAD_UP,
		"move_down":  JOY_BUTTON_DPAD_DOWN,
		"jump":      JOY_BUTTON_A,
		"attack":    JOY_BUTTON_X
	}

	for action in bindings.keys():
		var action_name = "P%d_%s" % [player_number, action]
		InputMap.action_erase_events(action_name)

		var event = InputEventJoypadButton.new()
		event.device = device_number
		event.button_index = bindings[action]
		InputMap.action_add_event(action_name, event)

# --- Bind keyboard ---
static func bind_keyboard_input(player_number: int):
	var bindings = {
		"move_left":  KEY_A,
		"move_right": KEY_D,
		"move_up":    KEY_W,
		"move_down":  KEY_S,
		"jump":      KEY_SPACE,
		"attack":    KEY_F
	}

	for action in bindings.keys():
		var action_name = "P%d_%s" % [player_number, action]
		InputMap.action_erase_events(action_name)

		var event = InputEventKey.new()
		event.keycode = bindings[action]
		InputMap.action_add_event(action_name, event)

func _ready():
	# Keyboard always Player 1
	player_devices[1] = 0
	create_player_input(1)
	bind_keyboard_input(1)
	player_devices[2] = 1
	create_player_input(2)
	bind_controller_input(2, 1)

	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		var next_player = _get_next_free_player()
		if next_player != null:
			player_devices[next_player] = device_id
			create_player_input(next_player)
			bind_controller_input(next_player, device_id)

func _get_next_free_player():
	# Example: support up to 4 players
	for pn in range(1, MAX_PLAYERS + 1):
		if not player_devices.has(pn):
			return pn
	return null
