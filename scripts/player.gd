extends "res://scripts/entity.gd"

# Player Entity - Phase 2 Step 1
# Green triangle with black fill, movement with WASD/arrow keys, faces movement direction

# Player-specific properties
var movement_speed: float = 200.0  # pixels per second
var current_direction: Vector2 = Vector2.UP  # Default facing up
var input_handler: Node

# Visual elements
var triangle_points: PackedVector2Array
var base_triangle_points: PackedVector2Array  # Original unrotated points
var triangle_size: float = 30.0

func _ready():
	"""Initialize player"""
	super._ready()
	
	# Set entity type
	set_entity_type("player")
	
	# Set default health
	max_health = 100.0
	health = max_health
	
	# Create triangle shape
	create_triangle_shape()
	
	# Get input handler reference
	input_handler = get_input_handler()
	
	# Connect to mouse click signal
	var signal_manager = get_signal_manager()
	if signal_manager and signal_manager.has_signal("mouse_clicked_signal"):
		signal_manager.connect("mouse_clicked_signal", _on_mouse_clicked)
		print("PLAYER: Connected to mouse click signal")
	
	print("PLAYER: Player initialized at position: ", global_position)

func _process(delta):
	"""Handle player movement and rotation"""
	
	# Get movement input
	var movement_input = get_movement_input()
	
	# Move player if there's input
	if movement_input != Vector2.ZERO:
		# Update position
		global_position += movement_input * movement_speed * delta
		
		# Update facing direction
		current_direction = movement_input.normalized()
		
		# Update triangle rotation to face movement direction
		update_triangle_rotation()
		
		# Emit movement signal for debugging
		var signal_manager = get_signal_manager()
		if signal_manager:
			signal_manager.emit_player_moved_signal(global_position, current_direction)

func _draw():
	"""Draw the player triangle"""
	
	# Draw black fill
	draw_colored_polygon(triangle_points, Color.BLACK)
	
	# Draw green outline
	for i in range(triangle_points.size()):
		var start_point = triangle_points[i]
		var end_point = triangle_points[(i + 1) % triangle_points.size()]
		draw_line(start_point, end_point, Color.GREEN, 2.0)

func create_triangle_shape():
	"""Create the triangle shape points"""
	
	triangle_points.clear()
	base_triangle_points.clear()
	
	# Create triangle pointing up with base half the size of height
	var top_point = Vector2(0, -triangle_size)
	var base_width = triangle_size * 0.5  # Base is half the height
	var left_point = Vector2(-base_width, triangle_size * 0.5)
	var right_point = Vector2(base_width, triangle_size * 0.5)
	
	# Store base points (unrotated)
	base_triangle_points.append(top_point)
	base_triangle_points.append(left_point)
	base_triangle_points.append(right_point)
	
	# Initialize triangle points with base points
	triangle_points = base_triangle_points.duplicate()

func update_triangle_rotation():
	"""Update triangle rotation to face current direction"""
	
	# Calculate rotation angle from direction vector
	var angle = current_direction.angle()
	
	# Add 90-degree clockwise rotation (PI/2 radians)
	angle += PI / 2
	
	# Create rotation matrix
	var rotation_matrix = Transform2D()
	rotation_matrix = rotation_matrix.rotated(angle)
	
	# Apply rotation to base triangle points (not the already rotated ones)
	var rotated_points = PackedVector2Array()
	for point in base_triangle_points:
		rotated_points.append(rotation_matrix * point)
	
	triangle_points = rotated_points
	
	# Trigger redraw
	queue_redraw()

func get_movement_input() -> Vector2:
	"""Get movement input from input handler"""
	
	if input_handler and input_handler.has_method("get_movement_input"):
		return input_handler.get_movement_input()
	
	# Fallback to direct input checking
	var movement = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		movement.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		movement.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		movement.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		movement.x += 1
	
	return movement.normalized()

func get_input_handler() -> Node:
	"""Get reference to input handler"""
	
	# Try multiple paths to find input handler
	var handler = get_node_or_null("../input_handler")
	if not handler:
		handler = get_node_or_null("../../input_handler")
	if not handler:
		var main_node = get_node_or_null("../..")
		if main_node:
			handler = main_node.get("input_handler")
	
	return handler

# Override entity functions for player-specific behavior
func take_damage(amount: float, source: Node = null):
	"""Handle player taking damage"""
	super.take_damage(amount, source)
	
	# Add player-specific damage effects (flash, sound, etc.)
	# This can be expanded later

func on_collision(other_entity: Node, damage_vector: Vector2):
	"""Handle player collision"""
	super.on_collision(other_entity, damage_vector)
	
	# Add player-specific collision behavior
	# This can be expanded later

# Player-specific functions
func get_movement_speed() -> float:
	"""Get current movement speed"""
	return movement_speed

func set_movement_speed(new_speed: float):
	"""Set movement speed"""
	movement_speed = new_speed

func get_facing_direction() -> Vector2:
	"""Get current facing direction"""
	return current_direction

func set_facing_direction(direction: Vector2):
	"""Set facing direction"""
	current_direction = direction.normalized()
	update_triangle_rotation()

func move(direction: Vector2):
	"""Move player in given direction (called by master)"""
	# This is handled in _process, but keeping for compatibility
	pass

func shoot(direction: Vector2):
	"""Shoot in given direction (called by master)"""
	# Placeholder for shooting functionality
	print("PLAYER: Shooting in direction: ", direction)
	# Shooting mechanics will be implemented in later phases

func _on_mouse_clicked(screen_position: Vector2, world_position: Vector2):
	"""Handle mouse click signal - spawn bullet"""
	
	print("PLAYER: Mouse clicked at screen: ", screen_position, " world: ", world_position)
	
	# Calculate shooting direction from player to mouse
	var shooting_direction = (world_position - global_position).normalized()
	
	if shooting_direction != Vector2.ZERO:
		# Spawn bullet through master
		spawn_bullet(shooting_direction)

func spawn_bullet(direction: Vector2):
	"""Spawn a bullet in the given direction"""
	
	print("PLAYER: Spawning bullet in direction: ", direction)
	
	# Get master script to spawn bullet - try multiple paths
	var master = get_node_or_null("..")  # Player is direct child of Main
	if not master:
		master = get_node_or_null("../..")  # Fallback
	if not master:
		master = get_node_or_null("/root/Main")
	if not master:
		master = get_tree().current_scene
	
	if master and master.has_method("spawn_entity"):
		# Calculate spawn position (offset from player)
		var spawn_offset = 20.0  # Halved from 40.0
		var spawn_position = global_position + (direction * spawn_offset)
		
		# Spawn bullet
		var bullet = master.spawn_entity("bullet", spawn_position)
		
		# Setup bullet with direction
		if bullet and bullet.has_method("setup_bullet"):
			bullet.setup_bullet(spawn_position, direction, spawn_offset)
			print("PLAYER: Bullet spawned and setup successfully")
	else:
		print("PLAYER: Could not find master to spawn bullet - tried .., ../.., /root/Main, and current scene")
