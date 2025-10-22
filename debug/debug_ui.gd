extends Control

# Debug UI - Testing component for Phase 1 Step 1
# Shows current input state and receives collision signals for testing

# UI Elements
@onready var keys_label: Label
@onready var signals_label: Label
@onready var status_label: Label

# Debug state
var current_movement_input: Vector2 = Vector2.ZERO
var current_keys: Array = []
var collision_count: int = 0
var last_collision_time: float = 0.0

func _ready():
	"""Initialize debug UI"""
	print("DEBUG UI: Initializing...")
	
	# Create UI elements if not set
	if not keys_label:
		keys_label = create_label("Keys Pressed: None", Vector2(10, 10))
	if not signals_label:
		signals_label = create_label("Signals: None", Vector2(10, 50))
	if not status_label:
		status_label = create_label("Status: Ready", Vector2(10, 90))
	
	print("DEBUG UI: Ready!")
	update_status("DEBUG UI: Ready and connected")

func _process(delta):
	"""Update debug display"""
	
	# Update keys display
	update_keys_display()
	
	# Update signals display
	update_signals_display()

func create_label(text: String, position: Vector2) -> Label:
	"""Create a debug label"""
	var label = Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	return label

func on_movement_input_changed(direction: Vector2):
	"""Handle movement input signal from master"""
	
	current_movement_input = direction
	update_display()

func on_key_pressed(key_name: String):
	"""Handle key press signal from master"""
	
	if key_name not in current_keys:
		current_keys.append(key_name)
	update_display()

func on_key_released(key_name: String):
	"""Handle key release signal from master"""
	
	if key_name in current_keys:
		current_keys.erase(key_name)
	update_display()

func update_display():
	"""Update the debug display"""
	
	var display_text = "Keys: "
	if current_keys.size() > 0:
		display_text += ", ".join(current_keys)
	else:
		display_text += "None"
	
	display_text += "\nMovement: "
	if current_movement_input != Vector2.ZERO:
		display_text += "(" + str(current_movement_input.x) + ", " + str(current_movement_input.y) + ")"
	else:
		display_text += "None"
	
	if keys_label:
		keys_label.text = display_text

func update_movement_display():
	"""Update the movement input display (deprecated - use update_display)"""
	
	update_display()

func update_keys_display():
	"""Update the keys pressed display"""
	
	# This is now handled by movement signals
	pass

func update_signals_display():
	"""Update the signals display"""
	
	var signal_text = "Collision Signals: " + str(collision_count)
	if last_collision_time > 0:
		var time_since = Time.get_ticks_msec() - last_collision_time
		signal_text += " (Last: " + str(time_since) + "ms ago)"
	
	signals_label.text = signal_text

func update_status(message: String):
	"""Update status message"""
	
	status_label.text = "Status: " + message
	print("DEBUG UI: ", message)

func on_collision_signal_received(entity_a: Node, entity_b: Node, damage_vector: Vector2):
	"""Handle collision signal from signal manager"""
	
	collision_count += 1
	last_collision_time = Time.get_ticks_msec()
	
	var collision_info = "Collision #" + str(collision_count) + ": " + entity_a.name + " <-> " + entity_b.name
	update_status(collision_info)
	
	print("DEBUG UI: Received collision signal - ", collision_info)
	
	# Flash effect
	flash_background()

func flash_background():
	"""Create a brief flash effect"""
	
	var original_color = modulate
	modulate = Color.YELLOW
	
	# Create timer to reset color
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(func(): modulate = original_color; timer.queue_free())
	add_child(timer)
	timer.start()

func on_debug_key_pressed():
	"""Handle debug key press for testing collision signal"""
	
	print("DEBUG UI: Debug key pressed - sending test collision signal")
	update_status("Debug: Sending test collision signal")
	
	# Create test entities
	var entity_a = Node.new()
	entity_a.name = "TestEntity_A"
	
	var entity_b = Node.new()
	entity_b.name = "TestEntity_B"
	
	# Send collision signal through signal manager
	var signal_manager = get_node_or_null("../SignalManager")
	print("DEBUG UI: Looking for SignalManager at '../SignalManager', found: ", signal_manager != null)
	
	if signal_manager:
		print("DEBUG UI: Found SignalManager, emitting collision signal")
		signal_manager.emit_collision_signal(entity_a, entity_b, Vector2(10, 5))
		update_status("Debug: Test collision signal sent!")
	else:
		# Try alternative paths
		print("DEBUG UI: Trying alternative paths...")
		signal_manager = get_node_or_null("../../SignalManager")
		print("DEBUG UI: Looking for SignalManager at '../../SignalManager', found: ", signal_manager != null)
		
		if signal_manager:
			print("DEBUG UI: Found SignalManager at alternative path, emitting collision signal")
			signal_manager.emit_collision_signal(entity_a, entity_b, Vector2(10, 5))
			update_status("Debug: Test collision signal sent!")
		else:
			# Try getting it from the main node directly
			var main_node = get_node_or_null("../..")
			if main_node and main_node.has_method("get"):
				signal_manager = main_node.get("signal_manager")
				print("DEBUG UI: Found SignalManager through main_node.signal_manager: ", signal_manager != null)
				
				if signal_manager:
					print("DEBUG UI: Found SignalManager through main node, emitting collision signal")
					signal_manager.emit_collision_signal(entity_a, entity_b, Vector2(10, 5))
					update_status("Debug: Test collision signal sent!")
				else:
					update_status("Debug: Signal Manager not found!")
			else:
				update_status("Debug: Signal Manager not found!")
	
	# Clean up test entities
	entity_a.queue_free()
	entity_b.queue_free()

func cleanup():
	"""Clean up debug UI before unloading"""
	
	print("DEBUG UI: Cleaning up...")
	update_status("DEBUG UI: Cleaning up...")
	
	# Clear all children
	for child in get_children():
		child.queue_free()
	
	print("DEBUG UI: Cleanup complete!")

func _exit_tree():
	"""Called when node is about to be removed from scene tree"""
	
	cleanup()
