extends Control

# Debug UI - Testing component for Phase 1 Step 1
# Shows current input state and receives collision signals for testing

# UI Elements
@onready var keys_label: Label
@onready var signals_label: Label
@onready var status_label: Label
@onready var coordinates_label: Label

# Debug state
var current_movement_input: Vector2 = Vector2.ZERO
var current_keys: Array = []
var collision_count: int = 0
var last_collision_time: float = 0.0
var spawned_entities: Array = []
var entity_spawn_count: int = 0

func _ready():
	"""Initialize debug UI"""
	# print("DEBUG UI: Initializing...")
	
	# Create UI elements if not set
	if not keys_label:
		keys_label = create_label("Keys Pressed: None", Vector2(10, 10))
	if not signals_label:
		signals_label = create_label("Signals: None", Vector2(10, 50))
	if not status_label:
		status_label = create_label("Status: Ready", Vector2(10, 90))
	if not coordinates_label:
		coordinates_label = create_label("Player Position: (0, 0)", Vector2(10, 130))
	
	# Spawn debug entity for collision testing
	spawn_debug_entity()
	
	# print("DEBUG UI: Ready!")
	update_status("DEBUG UI: Ready and connected")

func _process(delta):
	"""Update debug display"""
	
	# Update keys display
	update_keys_display()
	
	# Update signals display
	update_signals_display()

func create_label(text: String, label_position: Vector2) -> Label:
	"""Create a debug label"""
	var label = Label.new()
	label.text = text
	label.position = label_position
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
	
	signal_text += "\nEntities: " + str(spawned_entities.size()) + " loaded"
	
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

func spawn_debug_entity():
	"""Spawn debug entity for collision testing"""
	
	# print("DEBUG UI: Spawning debug entity for collision testing")
	
	# Create debug entity
	var debug_entity = Node2D.new()
	debug_entity.name = "DebugEntity"
	debug_entity.set_script(load("res://scripts/debug_entity.gd"))
	
	# Add to scene tree
	var main_node = get_node_or_null("../..")
	if main_node:
		main_node.add_child(debug_entity)
		spawned_entities.append(debug_entity)
		
		# Register with signal manager
		var signal_manager = main_node.get("signal_manager")
		if signal_manager:
			signal_manager.register_entity(debug_entity)
		
		update_status("Debug entity spawned for collision testing")
		# print("DEBUG UI: Debug entity spawned successfully")
	else:
		print("DEBUG UI: Could not find main node to add debug entity")

func spawn_basic_entity():
	"""Spawn a basic entity for testing"""
	
	entity_spawn_count += 1
	var entity_name = "BasicEntity_" + str(entity_spawn_count)
	
	print("DEBUG UI: Spawning basic entity: ", entity_name)
	
	# Create basic entity
	var entity = Node2D.new()
	entity.name = entity_name
	entity.set_script(load("res://scripts/entity.gd"))
	entity.position = Vector2(randi() % 600 + 100, randi() % 400 + 100)  # Random position
	
	# Add to scene tree
	var main_node = get_node_or_null("../..")
	if main_node:
		main_node.add_child(entity)
		spawned_entities.append(entity)
	else:
		print("DEBUG UI: Could not find main node to add entity")
	
	update_status("Spawned " + entity_name + " at " + str(entity.position))
	print("DEBUG UI: ", entity_name, " spawned. Total entities: ", spawned_entities.size())

func unload_all_entities():
	"""Unload all spawned entities"""
	
	print("DEBUG UI: Unloading all entities (", spawned_entities.size(), " total)")
	
	for entity in spawned_entities:
		if is_instance_valid(entity):
			print("DEBUG UI: Removing entity: ", entity.name)
			entity.queue_free()
	
	spawned_entities.clear()
	update_status("All entities unloaded")

func on_debug_key_pressed():
	"""Handle debug key press for testing"""
	
	print("DEBUG UI: Debug key pressed - cycling through debug functions")
	
	# Cycle through different debug functions
	if spawned_entities.size() == 0:
		# No entities - spawn one
		spawn_basic_entity()
	elif spawned_entities.size() < 5:
		# Less than 5 entities - spawn another
		spawn_basic_entity()
	else:
		# 5 or more entities - unload all
		unload_all_entities()

func update_player_coordinates(position: Vector2):
	"""Update the player coordinates display"""
	
	if coordinates_label:
		coordinates_label.text = "Player Position: (" + str(int(position.x)) + ", " + str(int(position.y)) + ")"

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
