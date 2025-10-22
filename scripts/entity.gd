extends Node2D

# Basic Entity Class - Foundation for all game entities
# Provides common properties and signal handling functionality

# Core properties (using Node2D's built-in position/velocity where possible)
var health: float = 100.0
var max_health: float = 100.0
var weight: float = 1.0
var entity_type: String = "basic_entity"
var is_alive: bool = true

# Signal connections
var connected_signals: Array = []

func _ready():
	"""Initialize entity"""
	print("Entity '", entity_type, "' spawned at position: ", global_position)
	
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
	print("Entity '", entity_type, "' took ", amount, " damage. Health: ", health, "/", max_health)
	
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
	print("Entity '", entity_type, "' healed for ", amount, ". Health: ", health, "/", max_health)

func destroy():
	"""Destroy the entity"""
	if not is_alive:
		return
	
	is_alive = false
	print("Entity '", entity_type, "' destroyed at position: ", global_position)
	
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
		var main_node = get_node_or_null("../..")
		if main_node and main_node.has_method("get"):
			signal_manager = main_node.get("signal_manager")
	
	return signal_manager

# Signal connection helpers
func connect_to_signal(signal_name: String, callable: Callable):
	"""Connect to a signal from the signal manager"""
	var signal_manager = get_signal_manager()
	if signal_manager and signal_manager.has_signal(signal_name):
		if not signal_manager.is_connected(signal_name, callable):
			signal_manager.connect(signal_name, callable)
			connected_signals.append({"signal": signal_name, "callable": callable})
			print("Entity '", entity_type, "' connected to signal: ", signal_name)

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
			print("Entity '", entity_type, "' disconnected from signal: ", signal_name)

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

# Overrideable functions for specific entity types
func on_collision(other_entity: Node, damage_vector: Vector2):
	"""Handle collision with another entity"""
	print("Entity '", entity_type, "' collided with '", other_entity.name, "'")
	# Default behavior: take damage based on collision force
	var damage_amount = damage_vector.length()
	take_damage(damage_amount)

func on_visibility_changed(visibility_state: bool, viewer: Node):
	"""Handle visibility change"""
	print("Entity '", entity_type, "' visibility to '", viewer.name, "': ", visibility_state)

func on_game_state_changed(new_state: String):
	"""Handle game state changes"""
	print("Entity '", entity_type, "' responding to game state: ", new_state)
