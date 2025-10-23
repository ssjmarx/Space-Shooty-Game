extends Node

# Signal Manager - Central hub for all game signals
# Handles universal collision, visibility, and entity management signals

# Universal Signals
signal collision_signal(entity_a, entity_b, damage_vector)
signal visibility_signal(entity, viewer, is_visible)
signal entity_spawned_signal(entity_type, position)
signal entity_destroyed_signal(entity, explosion_radius)
signal damage_signal(entity, amount, source)
signal explosion_signal(position, radius, damage)
signal player_moved_signal(position, direction)

# Game State Signals
signal game_state_changed(new_state)
signal player_health_changed(health, max_health)
signal player_score_changed(score)
signal wave_completed(wave_number)

# Input Signals
signal movement_input_detected(direction)
signal shooting_input_detected(direction)
signal ui_input_detected(action)
signal mouse_clicked_signal(position, world_position)

# Entity tracking
var active_entities: Array = []
var visibility_ranges: Dictionary = {}

func _ready():
	"""Initialize signal manager"""
	print("Signal Manager initialized")
	
	# Connect to global collision system if available
	var master = get_parent().get_node_or_null("Master")
	if master and master.has_signal("component_loaded"):
		master.connect("component_loaded", _on_component_loaded)

func emit_collision_signal(entity_a: Node, entity_b: Node):
	"""Emit universal collision signal between two entities"""
	
	if not entity_a or not entity_b:
		return
	
	# Calculate collision damage vector
	var damage_vector = calculate_collision_damage_vector(entity_a, entity_b)
	
	# Emit the collision signal
	emit_signal("collision_signal", entity_a, entity_b, damage_vector)
	
	print("Collision signal emitted: ", entity_a.name, " <-> ", entity_b.name)

func emit_visibility_signal(entity: Node, viewer: Node, is_visible: bool):
	"""Emit visibility signal for entity detection"""
	
	emit_signal("visibility_signal", entity, viewer, is_visible)
	
	if is_visible:
		print("Visibility: ", entity.name, " detected by ", viewer.name)
	else:
		print("Visibility: ", entity.name, " lost by ", viewer.name)

func emit_entity_spawned_signal(entity_type: String, position: Vector2):
	"""Emit signal when entity is spawned"""
	
	emit_signal("entity_spawned_signal", entity_type, position)
	print("Entity spawned signal: ", entity_type, " at ", position)

func emit_entity_destroyed_signal(entity: Node, explosion_radius: float = 0.0):
	"""Emit signal when entity is destroyed"""
	
	# Remove from active entities
	if entity in active_entities:
		active_entities.erase(entity)
	
	# Remove from visibility ranges
	if entity in visibility_ranges:
		visibility_ranges.erase(entity)
	
	emit_signal("entity_destroyed_signal", entity, explosion_radius)
	print("Entity destroyed signal: ", entity.name, " explosion radius: ", explosion_radius)

func emit_damage_signal(entity: Node, amount: float, source: Node):
	"""Emit damage signal for entity"""
	
	emit_signal("damage_signal", entity, amount, source)
	print("Damage signal: ", entity.name, " took ", amount, " damage from ", source.name)

func emit_explosion_signal(position: Vector2, radius: float, damage: float):
	"""Emit explosion signal for area damage"""
	
	emit_signal("explosion_signal", position, radius, damage)
	print("Explosion signal at ", position, " radius: ", radius, " damage: ", damage)

func register_entity(entity: Node):
	"""Register an entity with the signal manager"""
	
	if entity not in active_entities:
		active_entities.append(entity)
		print("Registered entity: ", entity.name)

func unregister_entity(entity: Node):
	"""Unregister an entity from the signal manager"""
	
	if entity in active_entities:
		active_entities.erase(entity)
		print("Unregistered entity: ", entity.name)

func set_visibility_range(entity: Node, range_value: float):
	"""Set visibility range for an entity"""
	
	visibility_ranges[entity] = range_value
	print("Set visibility range for ", entity.name, ": ", range_value)

func get_visibility_range(entity: Node) -> float:
	"""Get visibility range for an entity"""
	
	if entity in visibility_ranges:
		return visibility_ranges[entity]
	return 0.0

func check_visibility(entity: Node, viewer: Node) -> bool:
	"""Check if entity is visible to viewer"""
	
	if not entity or not viewer:
		return false
	
	var distance = entity.global_position.distance_to(viewer.global_position)
	var viewer_range = get_visibility_range(viewer)
	
	var is_visible = distance <= viewer_range
	
	# Emit visibility signal
	emit_visibility_signal(entity, viewer, is_visible)
	
	return is_visible

func calculate_collision_damage_vector(entity_a: Node, entity_b: Node) -> Vector2:
	"""Calculate damage vector for collision between two entities"""
	
	if not entity_a or not entity_b:
		return Vector2.ZERO
	
	# Debug: Check if entities have required properties
	var is_debug_entity = false
	
	# Get positions with error handling
	var pos_a = Vector2.ZERO
	var pos_b = Vector2.ZERO
	
	# Try to get position from entity_a
	if entity_a.has_method("get_global_position"):
		pos_a = entity_a.get_global_position()
	elif "global_position" in entity_a:
		pos_a = entity_a.global_position
	else:
		print("DEBUG: Entity_a '", entity_a.name, "' has no global_position, using default")
		pos_a = Vector2.ZERO
		is_debug_entity = true
	
	# Try to get position from entity_b
	if entity_b.has_method("get_global_position"):
		pos_b = entity_b.get_global_position()
	elif "global_position" in entity_b:
		pos_b = entity_b.global_position
	else:
		print("DEBUG: Entity_b '", entity_b.name, "' has no global_position, using default")
		pos_b = Vector2(10, 0)  # Offset so we have a direction
		is_debug_entity = true
	
	# If this is a debug collision, return a simple default damage vector
	if is_debug_entity:
		print("DEBUG: Using simple collision for debug entities")
		return Vector2(5, 0)  # Simple rightward force
	
	# Get velocities with error handling
	var vel_a = Vector2.ZERO
	var vel_b = Vector2.ZERO
	
	if entity_a.has_method("get_linear_velocity"):
		vel_a = entity_a.get_linear_velocity()
	elif "velocity" in entity_a:
		vel_a = entity_a.velocity
	
	if entity_b.has_method("get_linear_velocity"):
		vel_b = entity_b.get_linear_velocity()
	elif "velocity" in entity_b:
		vel_b = entity_b.velocity
	
	# Get weights (default to 1.0 if not specified)
	var weight_a = 1.0
	var weight_b = 1.0
	
	if "weight" in entity_a:
		weight_a = entity_a.weight
	if "weight" in entity_b:
		weight_b = entity_b.weight
	
	# Calculate relative velocity
	var relative_velocity = vel_a - vel_b
	
	# Calculate collision normal (from a to b)
	var collision_normal = (pos_b - pos_a).normalized()
	
	# Calculate impact force based on relative velocity and weights
	var impact_force = relative_velocity.length() * (weight_a + weight_b) * 0.5
	
	# Create damage vector (direction and magnitude)
	var damage_vector = collision_normal * impact_force
	
	return damage_vector

func get_entities_in_radius(center: Vector2, radius: float) -> Array:
	"""Get all entities within a certain radius"""
	
	var entities_in_range = []
	
	for entity in active_entities:
		if not is_instance_valid(entity):
			continue
		
		var distance = entity.global_position.distance_to(center)
		if distance <= radius:
			entities_in_range.append(entity)
	
	return entities_in_range

func get_entities_of_type(entity_type: String) -> Array:
	"""Get all entities of a specific type"""
	
	var entities_of_type = []
	
	for entity in active_entities:
		if not is_instance_valid(entity):
			continue
		
		# Check entity type (could be based on groups, class name, etc.)
		if entity.is_in_group(entity_type) or entity.get_class() == entity_type:
			entities_of_type.append(entity)
	
	return entities_of_type

func emit_game_state_signal(new_state: String):
	"""Emit game state change signal"""
	
	emit_signal("game_state_changed", new_state)
	print("Game state changed to: ", new_state)

func emit_player_health_signal(health: float, max_health: float):
	"""Emit player health change signal"""
	
	emit_signal("player_health_changed", health, max_health)

func emit_player_score_signal(score: int):
	"""Emit player score change signal"""
	
	emit_signal("player_score_changed", score)

func emit_movement_input_signal(direction: Vector2):
	"""Emit movement input signal"""
	
	emit_signal("movement_input_detected", direction)

func emit_shooting_input_signal(direction: Vector2):
	"""Emit shooting input signal"""
	
	emit_signal("shooting_input_detected", direction)

func emit_ui_input_signal(action: String):
	"""Emit UI input signal"""
	
	emit_signal("ui_input_detected", action)

func emit_player_moved_signal(position: Vector2, direction: Vector2):
	"""Emit player movement signal"""
	
	emit_signal("player_moved_signal", position, direction)

func emit_mouse_clicked_signal(screen_position: Vector2, world_position: Vector2):
	"""Emit mouse click signal"""
	
	emit_signal("mouse_clicked_signal", screen_position, world_position)
	print("Mouse clicked signal: screen=", screen_position, " world=", world_position)

func _on_component_loaded(component_name: String):
	"""Handle component loaded signal from master"""
	
	print("Signal manager detected component loaded: ", component_name)
	
	# Connect to component signals if needed
	match component_name:
		"input_handler":
			# Could connect to input handler signals here
			pass
		"physics_manager":
			# Could connect to physics manager signals here
			pass

func cleanup():
	"""Clean up signal manager"""
	
	active_entities.clear()
	visibility_ranges.clear()
	print("Signal manager cleaned up")
