extends Node

# Physics Manager - Handles collision damage calculations
# Listens for collision signals and calculates damage based on speed, direction, and weight

# Physics properties
var gravity: float = 0.0  # No gravity in space shooter
var friction: float = 0.95  # Space friction (minimal)

func _ready():
	"""Initialize physics manager"""
	print("PHYSICS: Physics manager initialized")
	
	# Connect to collision signals from signal manager
	var signal_manager = get_signal_manager()
	if signal_manager:
		if signal_manager.has_signal("collision_signal"):
			signal_manager.connect("collision_signal", _on_collision_signal_received)
			print("PHYSICS: Connected to collision signals")
		else:
			print("PHYSICS: Signal manager has no collision_signal")
	else:
		print("PHYSICS: Could not find signal manager")

func get_signal_manager() -> Node:
	"""Get reference to signal manager"""
	# Try multiple paths to find signal manager
	var signal_manager = get_node_or_null("../signal_manager")
	if not signal_manager:
		signal_manager = get_node_or_null("../../signal_manager")
	if not signal_manager:
		var main_node = get_node_or_null("../..")
		if main_node and main_node.has_method("get"):
			signal_manager = main_node.get("signal_manager")
		elif main_node:
			# Try accessing as a property
			signal_manager = main_node.signal_manager
	
	return signal_manager

func _on_collision_signal_received(entity_a: Node, entity_b: Node, damage_vector: Vector2):
	"""Handle collision signal from signal manager"""
	
	print("PHYSICS: Calculating collision between ", entity_a.name, " and ", entity_b.name)
	
	# Get physics properties of both entities
	var velocity_a = get_entity_velocity(entity_a)
	var velocity_b = get_entity_velocity(entity_b)
	var weight_a = get_entity_weight(entity_a)
	var weight_b = get_entity_weight(entity_b)
	
	print("PHYSICS: Entity A (", entity_a.name, ") - Velocity: ", velocity_a, ", Weight: ", weight_a)
	print("PHYSICS: Entity B (", entity_b.name, ") - Velocity: ", velocity_b, ", Weight: ", weight_b)
	
	# Calculate relative velocity (difference between velocity vectors)
	var relative_velocity = velocity_a - velocity_b
	var impact_speed = relative_velocity.length()
	
	# Calculate total damage based on impact speed and total weight
	var total_weight = weight_a + weight_b
	var total_damage = impact_speed * total_weight * 0.1  # Scale factor for balance
	
	print("PHYSICS: Relative velocity: ", relative_velocity, ", Impact speed: ", impact_speed)
	print("PHYSICS: Total weight: ", total_weight, ", Calculated total damage: ", total_damage)
	
	# Split damage proportionally based on weight (lighter object takes more damage)
	var damage_a = total_damage * (weight_b / total_weight)  # A takes damage proportional to B's weight
	var damage_b = total_damage * (weight_a / total_weight)  # B takes damage proportional to A's weight
	
	print("PHYSICS: Damage assignment - ", entity_a.name, " takes: ", damage_a, ", ", entity_b.name, " takes: ", damage_b)
	
	# Apply damage to entities
	apply_damage_to_entity(entity_a, damage_a, entity_b)
	apply_damage_to_entity(entity_b, damage_b, entity_a)

func get_entity_velocity(entity: Node) -> Vector2:
	"""Get the velocity vector of an entity"""
	
	# Try to get velocity from entity
	if entity.has_method("get_linear_velocity"):
		return entity.get_linear_velocity()
	elif entity.has_method("get_velocity"):
		return entity.get_velocity()
	elif "velocity" in entity:
		return entity.velocity
	else:
		# Default velocity if entity has no velocity
		return Vector2.ZERO

func get_entity_speed(entity: Node) -> float:
	"""Get the speed of an entity"""
	
	# Use the velocity function to get speed
	var velocity = get_entity_velocity(entity)
	return velocity.length()

func get_entity_direction(entity: Node) -> Vector2:
	"""Get the movement direction of an entity"""
	
	# Try to get velocity from entity
	if entity.has_method("get_linear_velocity"):
		var velocity = entity.get_linear_velocity()
		return velocity.normalized()
	elif entity.has_method("get_velocity"):
		var velocity = entity.get_velocity()
		return velocity.normalized()
	elif "velocity" in entity:
		var velocity = entity.velocity
		return velocity.normalized()
	elif entity.has_method("get_movement_direction"):
		return entity.get_movement_direction()
	elif entity.has_method("get_facing_direction"):
		return entity.get_facing_direction()
	else:
		# Default direction if entity has no direction
		return Vector2.UP

func get_entity_weight(entity: Node) -> float:
	"""Get the weight of an entity"""
	
	if entity.has_method("get_weight"):
		return entity.get_weight()
	elif "weight" in entity:
		return entity.weight
	else:
		# Default weight if entity has no weight
		return 1.0

func apply_damage_to_entity(entity: Node, damage: float, source: Node):
	"""Apply calculated damage to an entity"""
	
	if entity and entity.has_method("take_damage"):
		entity.take_damage(damage, source)
		print("PHYSICS: Applied ", damage, " damage to ", entity.name, " from ", source.name)
	else:
		print("PHYSICS: Could not apply damage to ", entity.name, " - no take_damage method")

func set_gravity(new_gravity: float):
	"""Set gravity value"""
	gravity = new_gravity

func set_friction(new_friction: float):
	"""Set friction value"""
	friction = new_friction

func get_gravity() -> float:
	"""Get current gravity value"""
	return gravity

func get_friction() -> float:
	"""Get current friction value"""
	return friction
