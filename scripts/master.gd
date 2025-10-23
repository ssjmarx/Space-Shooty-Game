extends Node2D

# Master script - Central game controller
# Manages loading/unloading of nodes and handles player input

# Component references
var signal_manager: Node
var input_handler: Node
var physics_manager: Node
var sound_manager: Node
var current_board: Node
var player_entity: Node

# Game state
var game_running: bool = false
var components_loaded: Dictionary = {}

# Signals
signal game_started
signal game_paused
signal game_stopped
signal component_loaded(component_name)
signal component_unloaded(component_name)

func _ready():
	"""Initialize game systems"""
	# print("Master script initializing...")
	
	# Load screen manager first (required by other components)
	load_component("screen_manager")
	
	# Load core components in order
	load_component("signal_manager")
	load_component("input_handler")
	load_component("physics_manager")
	
	# Load space board
	load_space_board()
	
	# Load camera component
	load_camera_component()
	
	# Load debug component for testing
	load_debug_component()
	
	# Spawn player immediately
	spawn_player()
	
	# Connect to signals
	if signal_manager:
		_connect_signals()
	
	# Connect to input handler signals
	if input_handler:
		_connect_input_signals()
	
	# Connect player to mouse click signals after all components are loaded
	if player_entity and signal_manager:
		if signal_manager.has_signal("mouse_clicked_signal"):
			signal_manager.connect("mouse_clicked_signal", player_entity._on_mouse_clicked)
			# print("MASTER: Connected player to mouse click signal")
	
	# print("Master script ready!")

func _process(delta):
	"""Main game loop"""
	if not game_running:
		return
	
	# Handle input
	handle_input()
	
	# Process game logic
	process_game_logic(delta)

func load_component(component_name: String) -> Node:
	"""Load a game component dynamically"""
	
	# Check if already loaded
	if components_loaded.has(component_name):
		print("Component ", component_name, " already loaded")
		return components_loaded[component_name]
	
	# Determine component path and script
	var component_path = ""
	var component_script = ""
	
	match component_name:
		"screen_manager":
			component_path = "res://scripts/screen_manager.gd"
			component_script = "res://scripts/screen_manager.gd"
		"signal_manager":
			component_path = "res://scripts/signal_manager.gd"
			component_script = "res://scripts/signal_manager.gd"
		"input_handler":
			component_path = "res://scripts/input_handler.gd"
			component_script = "res://scripts/input_handler.gd"
		"physics_manager":
			component_path = "res://scripts/physics.gd"
			component_script = "res://scripts/physics.gd"
		"sound_manager":
			component_path = "res://scripts/sound_manager.gd"
			component_script = "res://scripts/sound_manager.gd"
		_:
			print("Unknown component: ", component_name)
			return null
	
	# Create component node
	var component_node = Node.new()
	component_node.name = component_name
	component_node.set_script(load(component_script))
	
	# Add to scene tree
	add_child(component_node)
	components_loaded[component_name] = component_node
	
	# Store reference
	match component_name:
		"signal_manager":
			signal_manager = component_node
		"input_handler":
			input_handler = component_node
		"physics_manager":
			physics_manager = component_node
		"sound_manager":
			sound_manager = component_node
	
	# print("Loaded component: ", component_name)
	emit_signal("component_loaded", component_name)
	return component_node

func unload_component(component_name: String):
	"""Unload a game component"""
	
	if not components_loaded.has(component_name):
		print("Component ", component_name, " not loaded")
		return
	
	var component_node = components_loaded[component_name]
	
	# Remove from scene tree
	if is_instance_valid(component_node):
		component_node.queue_free()
	
	# Remove from loaded components
	components_loaded.erase(component_name)
	
	# Clear reference
	match component_name:
		"signal_manager":
			signal_manager = null
		"input_handler":
			input_handler = null
		"physics_manager":
			physics_manager = null
		"sound_manager":
			sound_manager = null
	
	print("Unloaded component: ", component_name)
	emit_signal("component_unloaded", component_name)

func handle_input():
	"""Process player input"""
	if not input_handler:
		return
	
	# Get input from handler
	var movement_input = input_handler.get_movement_input()
	var ui_input = input_handler.get_ui_input()
	
	# Process input based on game state
	if player_entity and game_running:
		# Send movement input to player
		if movement_input != Vector2.ZERO:
			player_entity.move(movement_input)
		
		# Handle shooting input separately
		if input_handler.is_shooting():
			var shooting_direction = input_handler.get_shooting_input_from_position(player_entity.global_position)
			if shooting_direction != Vector2.ZERO:
				player_entity.shoot(shooting_direction)
	
	# Handle UI input
	if ui_input:
		_process_ui_input(ui_input)

func spawn_entity(entity_type: String, position: Vector2) -> Node:
	"""Spawn a game entity at specified position"""
	
	# print("Spawning entity: ", entity_type, " at ", position)
	
	# Determine entity scene and script
	var entity_scene_path = ""
	var entity_script_path = ""
	
	match entity_type:
		"player":
			entity_scene_path = "res://scenes/player.tscn"
		"bullet":
			# Create bullet entity directly from script
			var bullet = Node2D.new()
			bullet.name = "Bullet"
			bullet.set_script(load("res://scripts/bullet.gd"))
			bullet.global_position = position
			add_child(bullet)
			
			# Register bullet with signal manager
			if signal_manager:
				signal_manager.register_entity(bullet)
			
			# print("MASTER: Bullet entity created at ", position)
			return bullet
		"asteroid":
			entity_scene_path = "res://scenes/asteroid.tscn"
		"hunter":
			entity_scene_path = "res://scenes/hunter.tscn"
		"player_bullet":
			entity_scene_path = "res://scenes/player_bullet.tscn"
		"hunter_bullet":
			entity_scene_path = "res://scenes/hunter_bullet.tscn"
		_:
			print("Unknown entity type: ", entity_type)
			return null
	
	# Load and instantiate entity
	var entity_scene = load(entity_scene_path)
	if not entity_scene:
		print("Failed to load entity scene: ", entity_scene_path)
		return null
	
	var entity_instance = entity_scene.instantiate()
	entity_instance.global_position = position
	
	# Add to current board or directly to scene tree
	if current_board:
		current_board.add_child(entity_instance)
	else:
		add_child(entity_instance)
	
	# Store reference if it's the player
	if entity_type == "player":
		player_entity = entity_instance
	
	# Emit spawn signal
	if signal_manager:
		signal_manager.emit_signal("entity_spawned_signal", entity_type, position)
	
	return entity_instance

func despawn_entity(entity_id: int):
	"""Remove an entity from the game"""
	
	# Find entity by ID (implementation depends on entity ID system)
	print("Despawning entity ID: ", entity_id)
	
	# This would need to be implemented based on how we track entities
	# For now, this is a placeholder

func spawn_player():
	"""Spawn the player entity"""
	
	# print("MASTER: Spawning player...")
	
	# Create player entity directly (no scene file needed yet)
	var player = Node2D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player.gd"))
	player.position = Vector2(0, 0)  # Origin point (0,0)
	
	# Add to scene tree
	add_child(player)
	player_entity = player
	
	# Set camera to follow player
	var camera = get_node_or_null("Camera2D")
	if camera and camera.has_method("set_player_target"):
		camera.set_player_target(player)
		# print("MASTER: Camera set to follow player")
	
	# Emit spawn signal
	if signal_manager:
		signal_manager.emit_entity_spawned_signal("player", player.position)
	
	# print("MASTER: Player spawned at origin: ", player.position)

func start_game():
	"""Start the game"""
	# print("Starting game...")
	game_running = true
	
	emit_signal("game_started")

func pause_game():
	"""Pause the game"""
	# print("Pausing game...")
	game_running = false
	emit_signal("game_paused")

func stop_game():
	"""Stop the game"""
	# print("Stopping game...")
	game_running = false
	emit_signal("game_stopped")

func process_game_logic(delta: float):
	"""Process main game logic"""
	
	# Update board
	if current_board and current_board.has_method("_process"):
		current_board._process(delta)
	
	# Update physics
	if physics_manager and physics_manager.has_method("_process"):
		physics_manager._process(delta)

func _connect_signals():
	"""Connect to signal manager signals"""
	
	if not signal_manager:
		return
	
	# Connect universal signals
	if signal_manager.has_signal("collision_signal"):
		signal_manager.connect("collision_signal", _on_collision_signal)
	
	if signal_manager.has_signal("entity_destroyed_signal"):
		signal_manager.connect("entity_destroyed_signal", _on_entity_destroyed_signal)

func _connect_input_signals():
	"""Connect to input handler signals"""
	
	if not input_handler:
		return
	
	# Connect input signals
	if input_handler.has_signal("movement_input_changed"):
		input_handler.connect("movement_input_changed", _on_movement_input_changed)
	
	if input_handler.has_signal("key_pressed"):
		input_handler.connect("key_pressed", _on_key_pressed)
	
	if input_handler.has_signal("key_released"):
		input_handler.connect("key_released", _on_key_released)
	
	if input_handler.has_signal("ui_action"):
		input_handler.connect("ui_action", _on_ui_action)
	
	# print("MASTER: Input signals connected!")

func _on_movement_input_changed(direction: Vector2):
	"""Handle movement input changes"""
	
	# print("MASTER: Movement input changed: ", direction)
	
	# Broadcast movement input to interested components
	var ui_node = get_node_or_null("UI")
	if ui_node:
		var debug_ui = ui_node.get_node_or_null("DebugUI")
		if debug_ui and debug_ui.has_method("on_movement_input_changed"):
			debug_ui.on_movement_input_changed(direction)

func _on_key_pressed(key_name: String):
	"""Handle key press events"""
	
	# print("MASTER: Key pressed: ", key_name)
	
	# Broadcast key press to interested components
	var ui_node = get_node_or_null("UI")
	if ui_node:
		var debug_ui = ui_node.get_node_or_null("DebugUI")
		if debug_ui and debug_ui.has_method("on_key_pressed"):
			debug_ui.on_key_pressed(key_name)

func _on_key_released(key_name: String):
	"""Handle key release events"""
	
	# print("MASTER: Key released: ", key_name)
	
	# Broadcast key release to interested components
	var ui_node = get_node_or_null("UI")
	if ui_node:
		var debug_ui = ui_node.get_node_or_null("DebugUI")
		if debug_ui and debug_ui.has_method("on_key_released"):
			debug_ui.on_key_released(key_name)

func _on_ui_action(action: String):
	"""Handle UI action events"""
	
	# print("MASTER: UI action: ", action)
	
	# Handle debug test action
	if action == "debug_test":
		var ui_node = get_node_or_null("UI")
		if ui_node:
			var debug_ui = ui_node.get_node_or_null("DebugUI")
			if debug_ui and debug_ui.has_method("on_debug_key_pressed"):
				debug_ui.on_debug_key_pressed()
	else:
		_process_ui_input(action)

func _on_collision_signal(entity_a: Node, entity_b: Node, damage_vector: Vector2):
	"""Handle universal collision signal"""
	
	print("Collision detected between ", entity_a.name, " and ", entity_b.name)
	
	# Physics manager handles collision damage automatically through signal connections

func _on_entity_destroyed_signal(entity: Node, explosion_radius: float):
	"""Handle entity destruction"""
	
	print("Entity destroyed: ", entity.name, " with explosion radius: ", explosion_radius)
	
	# Physics manager handles explosion damage automatically through signal connections

func load_debug_component():
	"""Load debug UI component for testing"""
	
	# print("MASTER: Loading debug component...")
	
	# Load UI component from scene file
	var ui_scene = load("res://components/ui.tscn")
	if ui_scene:
		var ui_instance = ui_scene.instantiate()
		add_child(ui_instance)
		# print("MASTER: UI component loaded from scene file")
		
		# Connect debug UI to collision signals
		var debug_ui = ui_instance.get_node_or_null("DebugUI")
		if debug_ui and signal_manager:
			signal_manager.connect("collision_signal", debug_ui.on_collision_signal_received)
			# print("MASTER: Debug UI signals connected")
	else:
		print("MASTER: Failed to load UI scene file")
		return
	
	# print("MASTER: Debug component loaded successfully!")

func load_space_board():
	"""Load space board component"""
	
	print("MASTER: Loading space board...")
	
	# Create space board directly from script
	var space_board = Node2D.new()
	space_board.name = "SpaceBoard"
	space_board.set_script(load("res://scripts/space_board.gd"))
	
	# Add to scene tree
	add_child(space_board)
	current_board = space_board
	
	print("MASTER: Space board loaded successfully!")

func load_camera_component():
	"""Load camera component"""
	
	# print("MASTER: Loading camera component...")
	
	# Load camera component from scene file
	var camera_scene = load("res://components/camera2d.tscn")
	if camera_scene:
		var camera_instance = camera_scene.instantiate()
		add_child(camera_instance)
		# print("MASTER: Camera component loaded from scene file")
	else:
		print("MASTER: Failed to load camera scene file")

func unload_debug_component():
	"""Unload debug UI component before closing"""
	
	print("MASTER: Unloading debug component...")
	
	var ui_node = get_node_or_null("UI")
	if ui_node:
		var debug_ui = ui_node.get_node_or_null("DebugUI")
		if debug_ui:
			# Disconnect signals
			if signal_manager:
				signal_manager.disconnect("collision_signal", debug_ui.on_collision_signal_received)
			
			# Call cleanup
			if debug_ui.has_method("cleanup"):
				debug_ui.cleanup()
		
		# Remove entire UI node
		ui_node.queue_free()
		print("MASTER: Debug component unloaded successfully!")
	else:
		print("MASTER: Debug component not found!")

func _exit_tree():
	"""Called when the main node is about to be removed"""
	
	print("MASTER: Shutting down...")
	unload_debug_component()
	print("MASTER: Shutdown complete!")

func _process_ui_input(ui_input_action: String):
	"""Process UI input actions"""
	
	match ui_input_action:
		"pause":
			if game_running:
				pause_game()
			else:
				start_game()
		"look_ahead":
			print("Look ahead functionality - to be implemented")
		"shoot":
			# print("Shoot action - handled in main input processing")
			pass
		"debug_test":
			# Handle debug test key
			var ui_node = get_node_or_null("UI")
			if ui_node:
				var debug_ui = ui_node.get_node_or_null("DebugUI")
				if debug_ui and debug_ui.has_method("on_debug_key_pressed"):
					debug_ui.on_debug_key_pressed()
		_:
			print("Unknown UI input: ", ui_input_action)
