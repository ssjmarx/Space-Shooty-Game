extends Node

# Wrap-Around System - Phase 2 Step 4
# Creates illusion of infinite flight by wrapping entities around board edges
# Handles player, bullets, and other entities seamlessly

# Board properties
var board_size: Vector2 = Vector2(8000, 6000)  # Will be updated from space board
var half_board: Vector2
var wrap_margin: float = 100.0  # Extra margin for smooth wrapping

# Entity tracking
var wrapped_entities: Dictionary = {}  # entity_id -> original_position

func _ready():
	"""Initialize wrap-around system"""
	print("WRAP-AROUND: Initializing wrap-around system...")
	
	# Get board size from parent space board
	var space_board = get_parent()
	if space_board and space_board.has_method("get_board_size"):
		board_size = space_board.get_board_size()
		half_board = board_size / 2.0
		print("WRAP-AROUND: Board size set to: ", board_size)
	else:
		# Fallback to hardcoded values
		board_size = Vector2(8000, 6000)
		half_board = board_size / 2.0
		print("WRAP-AROUND: Using fallback board size: ", board_size)
	
	# Connect to entity signals
	connect_to_signals()
	
	print("WRAP-AROUND: Wrap-around system ready")

func connect_to_signals():
	"""Connect to entity movement signals"""
	
	var signal_manager = get_node_or_null("../signal_manager")
	if not signal_manager:
		signal_manager = get_node_or_null("../../signal_manager")
	
	if signal_manager:
		# Connect to player movement
		if signal_manager.has_signal("player_moved_signal"):
			signal_manager.connect("player_moved_signal", _on_entity_moved)
			print("WRAP-AROUND: Connected to player movement signals")
		
		# Connect to entity spawned signals
		if signal_manager.has_signal("entity_spawned_signal"):
			signal_manager.connect("entity_spawned_signal", _on_entity_spawned)
			print("WRAP-AROUND: Connected to entity spawn signals")
		
		# Connect to entity destroyed signals
		if signal_manager.has_signal("entity_destroyed_signal"):
			signal_manager.connect("entity_destroyed_signal", _on_entity_destroyed)
			print("WRAP-AROUND: Connected to entity destroy signals")
	else:
		print("WRAP-AROUND: Could not find signal manager")

func _on_entity_moved(entity: Node, position: Vector2, direction: Vector2):
	"""Handle entity movement - check for wrap-around"""
	
	if not entity:
		return
	
	# Only wrap the player - other entities should only be affected by universal teleport
	if entity.name != "Player":
		return
	
	# Check if entity needs wrapping
	var wrapped_position = check_wrap_around(position)
	
	if wrapped_position != position:
		# Entity needs wrapping
		perform_wrap_around(entity, position, wrapped_position)
		
		print("WRAP-AROUND: ", entity.name, " wrapped from ", position, " to ", wrapped_position)

func _on_entity_spawned(entity_type: String, entity: Node, position: Vector2):
	"""Handle entity spawn - register for wrapping"""
	
	if not entity:
		return
	
	# Register entity for wrapping
	var entity_id = entity.get_instance_id()
	wrapped_entities[entity_id] = position
	
	print("WRAP-AROUND: Registered ", entity.name, " for wrapping")

func _on_entity_destroyed(entity: Node, explosion_radius: float):
	"""Handle entity destruction - unregister from wrapping"""
	
	if not entity:
		return
	
	# Unregister entity
	var entity_id = entity.get_instance_id()
	if wrapped_entities.has(entity_id):
		wrapped_entities.erase(entity_id)
		print("WRAP-AROUND: Unregistered ", entity.name, " from wrapping")

func check_wrap_around(position: Vector2) -> Vector2:
	"""Check if position needs wrapping and return wrapped position"""
	
	var wrapped_position = position
	
	# Check X-axis wrapping
	if position.x > half_board.x + wrap_margin:
		# Wrap to left side
		wrapped_position.x = -half_board.x + wrap_margin
	elif position.x < -half_board.x - wrap_margin:
		# Wrap to right side
		wrapped_position.x = half_board.x - wrap_margin
	
	# Check Y-axis wrapping
	if position.y > half_board.y + wrap_margin:
		# Wrap to top
		wrapped_position.y = -half_board.y + wrap_margin
	elif position.y < -half_board.y - wrap_margin:
		# Wrap to bottom
		wrapped_position.y = half_board.y - wrap_margin
	
	return wrapped_position

func perform_wrap_around(entity: Node, old_position: Vector2, new_position: Vector2):
	"""Perform actual wrap-around for an entity"""
	
	if not entity:
		return
	
	# Store original position for smooth transition
	var entity_id = entity.get_instance_id()
	
	# Update entity position
	entity.global_position = new_position
	
	# Update wrapped entities tracking
	wrapped_entities[entity_id] = new_position
	
	# Calculate teleport distance and direction for universal signal
	var teleport_distance = new_position - old_position
	var teleport_direction = teleport_distance.normalized()
	
	# Emit universal teleport signal for all entities when player wraps
	if entity.name == "Player":
		var signal_manager = get_node_or_null("../signal_manager")
		if not signal_manager:
			signal_manager = get_node_or_null("../../signal_manager")
		
		if signal_manager and signal_manager.has_method("emit_universal_teleport_signal"):
			signal_manager.emit_universal_teleport_signal(teleport_distance, teleport_direction)
			print("WRAP-AROUND: Emitted universal teleport signal - distance: ", teleport_distance, " direction: ", teleport_direction)
	
	# Emit wrap signal for visual effects
	var signal_manager = get_node_or_null("../signal_manager")
	if not signal_manager:
		signal_manager = get_node_or_null("../../signal_manager")
	
	if signal_manager and signal_manager.has_signal("entity_wrapped_signal"):
		signal_manager.emit_entity_wrapped_signal(entity, old_position, new_position)

func wrap_position(position: Vector2) -> Vector2:
	"""Public function to wrap any position"""
	return check_wrap_around(position)

func is_near_edge(position: Vector2, threshold: float = 200.0) -> bool:
	"""Check if position is near board edge"""
	
	return position.x > half_board.x - threshold or \
		   position.x < -half_board.x + threshold or \
		   position.y > half_board.y - threshold or \
		   position.y < -half_board.y + threshold

func get_wrap_direction(position: Vector2) -> Vector2:
	"""Get the direction an entity would wrap if at this position"""
	
	var wrap_direction = Vector2.ZERO
	
	if position.x > half_board.x:
		wrap_direction.x = -1.0
	elif position.x < -half_board.x:
		wrap_direction.x = 1.0
	
	if position.y > half_board.y:
		wrap_direction.y = -1.0
	elif position.y < -half_board.y:
		wrap_direction.y = 1.0
	
	return wrap_direction.normalized()

func get_opposite_position(position: Vector2) -> Vector2:
	"""Get the opposite position on the board"""
	
	var opposite = position
	
	if position.x > 0:
		opposite.x = -half_board.x + (half_board.x - position.x)
	else:
		opposite.x = half_board.x + (half_board.x + position.x)
	
	if position.y > 0:
		opposite.y = -half_board.y + (half_board.y - position.y)
	else:
		opposite.y = half_board.y + (half_board.y + position.y)
	
	return opposite

func update_board_size(new_size: Vector2):
	"""Update board size (call if board size changes)"""
	
	board_size = new_size
	half_board = new_size / 2.0
	print("WRAP-AROUND: Board size updated to: ", board_size)

func get_wrapped_entity_count() -> int:
	"""Get the number of registered entities"""
	return wrapped_entities.size()

func clear_wrapped_entities():
	"""Clear all wrapped entities (useful for level reset)"""
	wrapped_entities.clear()
	print("WRAP-AROUND: Cleared all wrapped entities")

func _process(delta):
	"""Process continuous wrap checks for all entities"""
	
	# DISABLED: Signal-based wrapping is working correctly
	# This fallback was causing double-wrapping of debug entities
	# Only player should be wrapped by signal-based system
	
	pass
