extends Node

# Input Handler - Processes all player input
# Handles movement, shooting, and UI interactions

# Input states
var movement_input: Vector2 = Vector2.ZERO
var shooting_input: Vector2 = Vector2.ZERO
var ui_input: String = ""
var mouse_position: Vector2 = Vector2.ZERO
var mouse_world_position: Vector2 = Vector2.ZERO

# Input settings
var movement_keys = {
	"up": "ui_up",
	"down": "ui_down", 
	"left": "ui_left",
	"right": "ui_right",
	"alt_up": "w",
	"alt_down": "s",
	"alt_left": "a",
	"alt_right": "d"
}

var action_keys = {
	"shoot": "mouse_left",
	"pause": "escape",
	"look_ahead": "space",
	"boost": "shift",
	"debug_test": "tab"
}

# Input states tracking
var key_states: Dictionary = {}
var mouse_button_states: Dictionary = {}

func _ready():
	"""Initialize input handler"""
	print("Input Handler initialized")
	
	# Set process input to true
	set_process_input(true)
	set_process(true)

func _input(event):
	"""Handle input events"""
	
	# Handle keyboard input
	if event is InputEventKey:
		_handle_keyboard_input(event)
	
	# Handle mouse input
	elif event is InputEventMouseButton:
		_handle_mouse_button_input(event)
	
	# Handle mouse motion
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _process(delta):
	"""Process continuous input"""
	
	# Update movement input
	_update_movement_input()
	
	# Update shooting input
	_update_shooting_input()
	
	# Update mouse positions
	_update_mouse_positions()

func _handle_keyboard_input(event: InputEventKey):
	"""Handle keyboard input events"""
	
	var key_scancode = event.get_keycode_with_modifiers()
	var key_name = OS.get_keycode_string(key_scancode).to_lower()
	
	# Track key state
	if event.pressed:
		key_states[key_name] = true
	else:
		key_states[key_name] = false
	
	# Handle UI actions
	if event.pressed:
		if key_name == "escape":
			ui_input = "pause"
		elif key_name == "space":
			ui_input = "look_ahead"
		elif key_name == "tab":
			ui_input = "debug_test"

func _handle_mouse_button_input(event: InputEventMouseButton):
	"""Handle mouse button input events"""
	
	var button_index = event.button_index
	
	# Track mouse button state
	if event.pressed:
		mouse_button_states[button_index] = true
	else:
		mouse_button_states[button_index] = false
	
	# Handle shooting
	if event.pressed and button_index == MOUSE_BUTTON_LEFT:
		ui_input = "shoot"

func _handle_mouse_motion(event: InputEventMouseMotion):
	"""Handle mouse motion events"""
	
	mouse_position = event.position

func _update_movement_input():
	"""Update movement input vector"""
	
	movement_input = Vector2.ZERO
	
	# Check movement keys
	if is_key_pressed(movement_keys.up) or is_key_pressed(movement_keys.alt_up):
		movement_input.y -= 1
	if is_key_pressed(movement_keys.down) or is_key_pressed(movement_keys.alt_down):
		movement_input.y += 1
	if is_key_pressed(movement_keys.left) or is_key_pressed(movement_keys.alt_left):
		movement_input.x -= 1
	if is_key_pressed(movement_keys.right) or is_key_pressed(movement_keys.alt_right):
		movement_input.x += 1
	
	# Normalize diagonal movement
	if movement_input.length() > 0:
		movement_input = movement_input.normalized()

func _update_shooting_input():
	"""Update shooting input vector"""
	
	# Shooting direction is based on mouse position relative to player
	# This will be calculated when we have player position
	shooting_input = Vector2.ZERO

func _update_mouse_positions():
	"""Update mouse positions"""
	
	# Get viewport to convert mouse position
	var viewport = get_viewport()
	if viewport:
		mouse_position = viewport.get_mouse_position()
		
		# Convert to world position (will need camera reference)
		var camera = viewport.get_camera_2d()
		if camera:
			mouse_world_position = camera.global_position + (mouse_position - viewport.get_visible_rect().size / 2)

func is_key_pressed(key_name: String) -> bool:
	"""Check if a key is currently pressed"""
	
	return Input.is_action_pressed(key_name)

func is_mouse_button_pressed(button: int) -> bool:
	"""Check if a mouse button is currently pressed"""
	
	return Input.is_mouse_button_pressed(button)

func get_movement_input() -> Vector2:
	"""Get current movement input vector"""
	
	return movement_input

func get_shooting_input() -> Vector2:
	"""Get current shooting input vector"""
	
	# Calculate shooting direction from player to mouse
	# This will need player position to work properly
	if mouse_world_position != Vector2.ZERO:
		# For now, return direction from origin to mouse
		# In actual implementation, this will be player position
		var player_pos = Vector2.ZERO  # Will be updated with actual player position
		var direction = (mouse_world_position - player_pos).normalized()
		return direction
	
	return Vector2.ZERO

func get_shooting_input_from_position(player_position: Vector2) -> Vector2:
	"""Get shooting input relative to player position"""
	
	if mouse_world_position != Vector2.ZERO:
		var direction = (mouse_world_position - player_position).normalized()
		return direction
	
	return Vector2.ZERO

func get_ui_input() -> String:
	"""Get current UI input action"""
	
	var current_ui_input = ui_input
	ui_input = ""  # Reset after reading
	return current_ui_input

func get_mouse_position() -> Vector2:
	"""Get current mouse screen position"""
	
	return mouse_position

func get_mouse_world_position() -> Vector2:
	"""Get current mouse world position"""
	
	return mouse_world_position

func is_shooting() -> bool:
	"""Check if player is currently shooting"""
	
	return is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func is_boosting() -> bool:
	"""Check if player is boosting"""
	
	return is_key_pressed(action_keys.boost)

func is_looking_ahead() -> bool:
	"""Check if player is looking ahead"""
	
	return is_key_pressed(action_keys.look_ahead)

func get_input_strength() -> float:
	"""Get overall input strength (for effects, etc.)"""
	
	var strength = 0.0
	
	# Movement strength
	strength += movement_input.length()
	
	# Shooting strength
	if is_shooting():
		strength += 0.5
	
	# Boost strength
	if is_boosting():
		strength += 0.3
	
	return min(strength, 1.0)

func reset_input():
	"""Reset all input states"""
	
	movement_input = Vector2.ZERO
	shooting_input = Vector2.ZERO
	ui_input = ""
	key_states.clear()
	mouse_button_states.clear()

func set_custom_movement_keys(new_keys: Dictionary):
	"""Set custom movement key mappings"""
	
	movement_keys = new_keys

func set_custom_action_keys(new_keys: Dictionary):
	"""Set custom action key mappings"""
	
	action_keys = new_keys

func get_key_name(action: String) -> String:
	"""Get the key name for an action"""
	
	if action in movement_keys:
		return movement_keys[action]
	elif action in action_keys:
		return action_keys[action]
	
	return ""

func is_any_key_pressed() -> bool:
	"""Check if any key is currently pressed"""
	
	return not key_states.is_empty()

func get_pressed_keys() -> Array:
	"""Get array of currently pressed keys"""
	
	var pressed_keys = []
	for key in key_states:
		if key_states[key]:
			pressed_keys.append(key)
	return pressed_keys
