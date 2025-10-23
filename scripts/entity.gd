extends Node2D

# Basic Entity Class - Foundation for all game entities
# Provides common properties and signal handling functionality

# Core properties (using Node2D's built-in position/velocity where possible)
var health: float = 100.0
var max_health: float = 100.0
var weight: float = 1.0
var explosives: float = 0.0  # Explosive damage potential, default 0
var entity_type: String = "basic_entity"
var is_alive: bool = true

# Collision detection
var collision_area: Area2D
var collision_shape: CollisionShape2D
var collision_radius: float = 20.0
var collision_enabled: bool = false
var collision_delay_timer: Timer

# Signal connections
var connected_signals: Array = []

func _ready():
	"""Initialize entity"""
	# print("Entity '", entity_type, "' spawned at position: ", global_position)
	
	# Setup collision detection
	setup_collision_detection()
	
	# Register with signal manager if available
	register_with_signal_manager()

func _exit_tree():
	"""Clean up when entity is removed"""
	unregister_from_signal_manager()

# Health management
func take_damage(amount: float, source: Node = null):
	"""Apply damage to entity"""
	if not is_alive:
		return
	
	health -= amount
	# print("Entity '", entity_type, "' took ", amount, " damage. Health: ", health, "/", max_health)
	
	# Emit damage signal if available
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_damage_signal(self, amount, source if source else self)
	
	# Check if destroyed
	if health <= 0:
		destroy()

func heal(amount: float):
	"""Restore health to entity"""
	if not is_alive:
		return
	
	health = min(health + amount, max_health)
	# print("Entity '", entity_type, "' healed for ", amount, ". Health: ", health, "/", max_health)

func destroy():
	"""Destroy the entity"""
	if not is_alive:
		return
	
	is_alive = false
	# print("Entity '", entity_type, "' destroyed at position: ", global_position)
	
	# Emit destruction signal
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_entity_destroyed_signal(self, weight * 10)  # Explosion radius based on weight
	
	# Remove from scene tree
	queue_free()

# Signal management
func register_with_signal_manager():
	"""Register entity with signal manager"""
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.register_entity(self)

func unregister_from_signal_manager():
	"""Unregister entity from signal manager"""
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.unregister_entity(self)

func get_signal_manager() -> Node:
	"""Get reference to signal manager"""
	# Try multiple paths to find signal manager
	var signal_manager = get_node_or_null("../SignalManager")
	if not signal_manager:
		signal_manager = get_node_or_null("../../SignalManager")
	if not signal_manager:
		signal_manager = get_node_or_null("../signal_manager")
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

# Signal connection helpers
func connect_to_signal(signal_name: String, callable: Callable):
	"""Connect to a signal from the signal manager"""
	var signal_manager = get_signal_manager()
	if signal_manager and signal_manager.has_signal(signal_name):
		if not signal_manager.is_connected(signal_name, callable):
			signal_manager.connect(signal_name, callable)
			connected_signals.append({"signal": signal_name, "callable": callable})
			# print("Entity '", entity_type, "' connected to signal: ", signal_name)

func disconnect_from_signal(signal_name: String, callable: Callable):
	"""Disconnect from a signal"""
	var signal_manager = get_signal_manager()
	if signal_manager and signal_manager.has_signal(signal_name):
		if signal_manager.is_connected(signal_name, callable):
			signal_manager.disconnect(signal_name, callable)
			# Remove from connected signals
			for i in range(connected_signals.size() - 1, -1, -1):
				if connected_signals[i].signal == signal_name:
					connected_signals.remove_at(i)
			# print("Entity '", entity_type, "' disconnected from signal: ", signal_name)

func disconnect_all_signals():
	"""Disconnect from all connected signals"""
	var signal_manager = get_signal_manager()
	if signal_manager:
		for connection in connected_signals:
			if signal_manager.has_signal(connection.signal):
				if signal_manager.is_connected(connection.signal, connection.callable):
					signal_manager.disconnect(connection.signal, connection.callable)
		connected_signals.clear()

# Common entity functions
func set_entity_type(type: String):
	"""Set the entity type"""
	entity_type = type

func get_entity_type() -> String:
	"""Get the entity type"""
	return entity_type

func set_weight(new_weight: float):
	"""Set entity weight"""
	weight = new_weight

func get_weight() -> float:
	"""Get entity weight"""
	return weight

func get_health_percentage() -> float:
	"""Get health as percentage (0-1)"""
	return health / max_health

func is_at_full_health() -> bool:
	"""Check if entity is at full health"""
	return health >= max_health

# Collision detection functions
func setup_collision_detection():
	"""Setup collision detection for this entity"""
	
	# Create collision area
	collision_area = Area2D.new()
	collision_area.name = "CollisionArea"
	add_child(collision_area)
	
	# Create collision shape
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape"
	
	# Create circle shape for collision
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = collision_radius
	collision_shape.shape = circle_shape
	
	# Add shape to area
	collision_area.add_child(collision_shape)
	
	# Create collision delay timer
	collision_delay_timer = Timer.new()
	collision_delay_timer.wait_time = 0.033  # ~1/30th of a second
	collision_delay_timer.one_shot = true
	collision_delay_timer.timeout.connect(_enable_collision_detection)
	add_child(collision_delay_timer)
	
	# Start collision delay timer
	collision_delay_timer.start()
	
	# Connect collision signals
	collision_area.connect("area_entered", _on_area_entered)
	collision_area.connect("body_entered", _on_body_entered)
	
	print("ENTITY: ", entity_type, " collision detection setup with radius: ", collision_radius, " (delayed 1/30s)")

func _enable_collision_detection():
	"""Enable collision detection after delay"""
	collision_enabled = true
	print("ENTITY: ", entity_type, " collision detection enabled")

func _on_area_entered(area: Area2D):
	"""Handle collision with another area"""
	
	# Check if collision detection is enabled
	if not collision_enabled:
		return
	
	# Get the parent entity of the area
	var other_entity = area.get_parent()
	if other_entity and other_entity != self and other_entity.has_method("get_entity_type"):
		handle_collision_with_entity(other_entity)

func _on_body_entered(body: Node):
	"""Handle collision with a body"""
	
	# Check if collision detection is enabled
	if not collision_enabled:
		return
	
	if body and body != self and body.has_method("get_entity_type"):
		handle_collision_with_entity(body)

func handle_collision_with_entity(other_entity: Node):
	"""Handle collision with another entity"""
	
	# Check if both entities have collision enabled
	if not other_entity.has_method("is_collision_enabled") or not other_entity.is_collision_enabled():
		return
	
	print("ENTITY: ", entity_type, " detected collision with ", other_entity.get_entity_type())
	
	# Get signal manager
	var signal_manager = get_signal_manager()
	if signal_manager:
		# Emit collision signal through signal manager
		signal_manager.emit_collision_signal(self, other_entity)
		
		# Call entity's collision handler
		on_collision(other_entity, Vector2.ZERO)
	else:
		print("ENTITY: Could not find signal manager to emit collision signal")

func is_collision_enabled() -> bool:
	"""Check if collision detection is enabled for this entity"""
	return collision_enabled

# Overrideable functions for specific entity types
func on_collision(other_entity: Node, damage_vector: Vector2):
	"""Handle collision with another entity"""
	print("ENTITY: ", entity_type, " handling collision with ", other_entity.get_entity_type())
	# Default behavior: take damage based on collision force
	var damage_amount = damage_vector.length()
	take_damage(damage_amount)

func on_visibility_changed(visibility_state: bool, viewer: Node):
	"""Handle visibility change"""
	# print("Entity '", entity_type, "' visibility to '", viewer.name, "': ", visibility_state)

func on_game_state_changed(new_state: String):
	"""Handle game state changes"""
	# print("Entity '", entity_type, "' responding to game state: ", new_state)
