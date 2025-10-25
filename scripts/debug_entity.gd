extends "res://scripts/entity.gd"

# Debug Entity - Phase 2 Step 3
# Red square that moves in a slow circle for collision testing

# Movement properties
var movement_direction: Vector2 = Vector2.RIGHT  # Simple rightward movement
var movement_speed: float = 50.0  # Pixels per second (slow and obvious)
var start_position: Vector2  # Starting position for reference

# Visual properties
var square_size: float = 40.0  # Size of the red square

func _ready():
	"""Initialize debug entity"""
	super._ready()
	
	# Set entity type
	set_entity_type("debug_entity")
	
	# Set physics properties
	weight = 2.0  # Medium weight
	explosives = 10.0  # Low explosives
	
	# Set collision radius to match visual size
	collision_radius = square_size * 0.5  # Half of square size
	
	# Set health
	max_health = 50.0
	health = max_health
	
	# Set initial position
	start_position = global_position
	
	# Connect to universal teleport signal
	var signal_manager = get_signal_manager()
	if signal_manager and signal_manager.has_signal("universal_teleport_signal"):
		signal_manager.connect("universal_teleport_signal", _on_universal_teleport)
		print("DEBUG ENTITY: Connected to universal teleport signal")
	
	print("DEBUG ENTITY: Debug entity initialized at position: ", global_position)

func _process(delta):
	"""Move debug entity in a straight line"""
	
	# Calculate new position
	var new_position = global_position + (movement_direction * movement_speed * delta)
	
	# Update velocity for physics
	velocity = movement_direction * movement_speed
	
	# Update position
	global_position = new_position
	
	# Emit movement signal for debugging
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_player_moved_signal(self, global_position, movement_direction)

func _draw():
	"""Draw the debug entity as a red square"""
	
	# Define square corners
	var half_size = square_size / 2.0
	var points = PackedVector2Array()
	points.append(Vector2(-half_size, -half_size))
	points.append(Vector2(half_size, -half_size))
	points.append(Vector2(half_size, half_size))
	points.append(Vector2(-half_size, half_size))
	
	# Draw red square
	draw_colored_polygon(points, Color.RED)
	
	# Draw black outline
	for i in range(points.size()):
		var start_point = points[i]
		var end_point = points[(i + 1) % points.size()]
		draw_line(start_point, end_point, Color.BLACK, 2.0)

func setup_debug_entity(center: Vector2, radius: float, speed: float):
	"""Setup debug entity with custom parameters"""
	
	# For simple linear movement, just set speed and position
	movement_speed = speed
	global_position = center
	start_position = center
	
	print("DEBUG ENTITY: Setup with position ", center, " speed ", speed)

func _on_universal_teleport(teleport_distance: Vector2, teleport_direction: Vector2):
	"""Handle universal teleport signal - move all entities when player wraps"""
	
	print("DEBUG ENTITY: Received universal teleport signal - distance: ", teleport_distance, " direction: ", teleport_direction)
	print("DEBUG ENTITY: Position before teleport: ", global_position)
	
	# Apply teleport to debug entity
	global_position += teleport_distance
	
	# Also update start position to maintain relative position
	start_position += teleport_distance
	
	print("DEBUG ENTITY: Position after teleport: ", global_position)

# Override collision behavior for debug entity
func on_collision(other_entity: Node, damage_vector: Vector2):
	"""Handle collision - debug entity takes damage and changes color"""
	
	print("DEBUG ENTITY: Collision with ", other_entity.name, " - taking damage")
	
	# Apply damage based on collision force
	var damage_amount = damage_vector.length()
	take_damage(damage_amount, other_entity)
	
	# Flash effect - change color temporarily
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

# Override take_damage for debug entity
func take_damage(amount: float, source: Node = null):
	"""Handle taking damage"""
	super.take_damage(amount, source)
	
	# Visual feedback
	if is_alive:
		# Flash red
		modulate = Color.RED.lightened(0.5)
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE
	else:
		# Turn dark red when destroyed
		modulate = Color.DARK_RED
