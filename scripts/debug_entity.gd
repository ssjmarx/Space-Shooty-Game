extends "res://scripts/entity.gd"

# Debug Entity - Phase 2 Step 3
# Red square that moves in a slow circle for collision testing

# Movement properties
var circle_center: Vector2 = Vector2(512, 384)  # Center of play area
var circle_radius: float = 200.0  # Radius of circular movement
var movement_speed: float = 1.0  # Radians per second
var current_angle: float = 0.0  # Current angle in circular path

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
	collision_radius = square_size * 0.5  # Half the square size
	
	# Set health
	max_health = 50.0
	health = max_health
	
	# Set initial position at circle start
	global_position = circle_center + Vector2(circle_radius, 0)
	
	print("DEBUG ENTITY: Debug entity initialized at position: ", global_position)

func _process(delta):
	"""Move debug entity in a circle"""
	
	# Update angle
	current_angle += movement_speed * delta
	
	# Calculate new position on circle
	var new_position = Vector2(
		circle_center.x + cos(current_angle) * circle_radius,
		circle_center.y + sin(current_angle) * circle_radius
	)
	
	# Calculate velocity for physics (tangent to circle)
	var movement_direction = Vector2.RIGHT.rotated(current_angle + PI/2)  # Perpendicular to radius
	var actual_speed = movement_speed * circle_radius  # Angular speed converted to linear
	velocity = movement_direction * actual_speed
	
	# Update position
	global_position = new_position
	
	# Emit movement signal for debugging
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_player_moved_signal(global_position, movement_direction)

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
	
	circle_center = center
	circle_radius = radius
	movement_speed = speed
	
	# Reset to starting position
	current_angle = 0.0
	global_position = circle_center + Vector2(circle_radius, 0)
	
	print("DEBUG ENTITY: Setup with center ", center, " radius ", radius, " speed ", speed)

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
