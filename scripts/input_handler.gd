extends Node

# Input Handler - Processes all player input
# Handles movement, shooting, and UI interactions

# Input states
var movement_input: Vector2 = Vector2.ZERO
var shooting_input: Vector2 = Vector2.ZERO
var ui_input: String = ""
var mouse_position: Vector2 = Vector2.ZERO
var mouse_world_position: Vector2 = Vector2.ZERO

# Input signals
signal movement_input_changed(direction)
signal shooting_input_changed(direction)
signal key_pressed(key_name)
signal key_released(key_name)
signal mouse_moved(position)
signal mouse_clicked(position)
signal ui_action(action)

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

# Escape key tracking for double-press exit
var escape_press_count: int = 0
var last_key_pressed: String = ""
var escape_double_press_threshold: float = 1.0  # 1 second window for double press
var last_escape_time: float = 0.0

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
	
	# Track key state and emit signals
	if event.pressed:
		key_states[key_name] = true
		emit_signal("key_pressed", key_name)
		
		# Reset escape count if any other key is pressed
		if key_name != "escape":
			escape_press_count = 0
			last_key_pressed = key_name
	else:
		key_states[key_name] = false
		emit_signal("key_released", key_name)
	
	# Handle UI actions
	if event.pressed:
		if key_name == "escape":
			_handle_escape_key()
		elif key_name == "space":
			ui_input = "look_ahead"
			emit_signal("ui_action", "look_ahead")
		elif key_name == "tab":
			ui_input = "debug_test"
			emit_signal("ui_action", "debug_test")

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
		emit_signal("ui_action", "shoot")

func _handle_mouse_motion(event: InputEventMouseMotion):
	"""Handle mouse motion events"""
	
	mouse_position = event.position

func _update_movement_input():
	"""Update movement input vector"""
	
	var old_movement_input = movement_input
	movement_input = Vector2.ZERO
	
	# Check movement keys using proper input checking
	if Input.is_action_pressed(movement_keys.up) or Input.is_key_pressed(KEY_W):
		movement_input.y -= 1
	if Input.is_action_pressed(movement_keys.down) or Input.is_key_pressed(KEY_S):
		movement_input.y += 1
	if Input.is_action_pressed(movement_keys.left) or Input.is_key_pressed(KEY_A):
		movement_input.x -= 1
	if Input.is_action_pressed(movement_keys.right) or Input.is_key_pressed(KEY_D):
		movement_input.x += 1
	
	# Normalize diagonal movement
	if movement_input.length() > 0:
		movement_input = movement_input.normalized()
	
	# Emit signal if movement changed
	if old_movement_input != movement_input:
		emit_signal("movement_input_changed", movement_input)

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
	
	return Input.is_key_pressed(KEY_SHIFT)

func is_looking_ahead() -> bool:
	"""Check if player is looking ahead"""
	
	return Input.is_key_pressed(KEY_SPACE)

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

func _handle_escape_key():
	"""Handle escape key with double-press functionality"""
	
	var current_time = Time.get_ticks_msec() / 1000.0  # Convert to seconds
	
	# Check if the last key pressed was escape and within time window
	if last_key_pressed == "escape" and (current_time - last_escape_time) <= escape_double_press_threshold:
		# This is the second consecutive escape press
		escape_press_count += 1
		print("INPUT: Escape press #", escape_press_count)
		
		if escape_press_count >= 2:
			# Two consecutive escapes - quit game
			print("INPUT: Double escape pressed - quitting game")
			get_tree().quit()
			return
	else:
		# Reset count if this is the first escape or too much time passed
		escape_press_count = 1
		print("INPUT: First escape press - press escape again to quit")
	
	# Update tracking variables
	last_key_pressed = "escape"
	last_escape_time = current_time
	
	# Emit pause signal for first escape
	ui_input = "pause"
	emit_signal("ui_action", "pause")
