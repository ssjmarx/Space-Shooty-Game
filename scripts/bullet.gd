extends "res://scripts/entity.gd"

# Bullet Entity - Phase 2 Step 2
# Generic projectile with low weight but high explosives stat

# Bullet-specific properties
var movement_direction: Vector2 = Vector2.UP
var movement_speed: float = 1500.0  # pixels per second (tripled from 500)
var spawn_offset: float = 20.0  # Distance from player when spawned (halved from 40)
var lifetime: float = 3.0  # Seconds before auto-despawn
var play_area_bounds: Rect2 = Rect2(-4000, -3000, 8000, 6000)  # Match space board size

# Visual properties
var bullet_length: float = 20.0
var bullet_width: float = 8.0

func _ready():
	"""Initialize bullet"""
	super._ready()
	
	# Set entity type
	set_entity_type("bullet")
	
	# Set physics properties
	weight = 0.1  # Very light weight
	explosives = 100.0  # High explosives for collision damage
	
	# Set collision radius for bullets (match visual size)
	collision_radius = max(bullet_length, bullet_width) * 0.5  # Half of larger dimension
	
	# Set default health (bullets are fragile)
	max_health = 1.0
	health = max_health
	
	# Visual properties
	bullet_length = 20.0
	bullet_width = 8.0
	
	# Connect to universal teleport signal
	var signal_manager = get_signal_manager()
	if signal_manager and signal_manager.has_signal("universal_teleport_signal"):
		signal_manager.connect("universal_teleport_signal", _on_universal_teleport)
		print("BULLET: Connected to universal teleport signal")
	
	# print("BULLET: Bullet initialized at position: ", global_position)

func _process(delta):
	"""Update bullet movement and lifetime"""
	
	# Move bullet in set direction
	global_position += movement_direction * movement_speed * delta
	
	# Update velocity for physics calculations
	velocity = movement_direction * movement_speed
	
	# Update lifetime
	lifetime -= delta
	if lifetime <= 0:
		despawn_bullet()
		return
	
	# Check if bullet is outside play area
	if not play_area_bounds.has_point(global_position):
		despawn_bullet()

func _draw():
	"""Draw bullet as a yellow oval pointing in movement direction"""
	
	# Debug: Print current direction being used for drawing
	# print("DEBUG: Drawing bullet with direction: ", movement_direction, " angle: ", movement_direction.angle())
	
	# Calculate angle of movement
	var angle = movement_direction.angle()
	
	# Create oval points directly without Transform2D scaling
	var points = PackedVector2Array()
	var num_points = 16  # More points for smoother circle
	var half_length = bullet_length / 2.0
	var half_width = bullet_width / 2.0
	
	for i in range(num_points):
		var angle_step = (2.0 * PI * i) / num_points
		
		# Create ellipse point
		var x = cos(angle_step) * half_length
		var y = sin(angle_step) * half_width
		
		# Rotate point to align with movement direction
		var rotated_x = x * cos(angle) - y * sin(angle)
		var rotated_y = x * sin(angle) + y * cos(angle)
		
		points.append(Vector2(rotated_x, rotated_y))
	
	# Draw yellow oval
	draw_colored_polygon(points, Color.YELLOW)

func _on_universal_teleport(teleport_distance: Vector2, teleport_direction: Vector2):
	"""Handle universal teleport signal - move all entities when player wraps"""
	
	print("BULLET: Received universal teleport signal - distance: ", teleport_distance, " direction: ", teleport_direction)
	print("BULLET: Position before teleport: ", global_position)
	
	# Apply teleport to bullet
	global_position += teleport_distance
	
	print("BULLET: Position after teleport: ", global_position)

func setup_bullet(spawn_position: Vector2, direction: Vector2, offset_distance: float = 40.0):
	"""Setup bullet with position and direction"""
	
	# Set movement direction
	movement_direction = direction.normalized()
	
	# Set spawn position with offset
	global_position = spawn_position + (movement_direction * offset_distance)
	
	# Reset lifetime
	lifetime = 3.0
	
	# Trigger redraw to update rotation
	queue_redraw()
	
	# print("BULLET: Setup at ", global_position, " moving ", movement_direction)

func despawn_bullet():
	"""Despawn bullet"""
	
	# print("BULLET: Despawning bullet at ", global_position)
	
	# Emit destruction signal
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_entity_destroyed_signal(self, 0.0)  # No explosion for bullets
	
	# Remove from scene tree
	queue_free()

func set_play_area(bounds: Rect2):
	"""Set play area bounds for despawn checking"""
	
	play_area_bounds = bounds

func get_movement_direction() -> Vector2:
	"""Get current movement direction"""
	
	return movement_direction

func set_movement_direction(direction: Vector2):
	"""Set movement direction"""
	
	movement_direction = direction.normalized()
	
	# Trigger redraw to update visual rotation
	queue_redraw()

func get_movement_speed() -> float:
	"""Get current movement speed"""
	
	return movement_speed

func set_movement_speed(speed: float):
	"""Set movement speed"""
	
	movement_speed = speed

# Override collision behavior for bullets
func on_collision(other_entity: Node, damage_vector: Vector2):
	"""Handle bullet collision - bullets despawn on impact"""
	
	# print("BULLET: Collision with ", other_entity.name, " - despawning")
	
	# Emit collision signal for damage application
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_collision_signal(self, other_entity)
	
	# Despawn bullet on impact
	despawn_bullet()

# Override take_damage for bullets
func take_damage(amount: float, source: Node = null):
	"""Bullets are destroyed by any damage"""
	
	# print("BULLET: Taking damage - despawning")
	
	# Emit destruction signal
	var signal_manager = get_signal_manager()
	if signal_manager:
		signal_manager.emit_entity_destroyed_signal(self, 0.0)
	
	# Remove from scene tree
	queue_free()
