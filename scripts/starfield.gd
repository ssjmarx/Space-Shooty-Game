extends Node2D

# Starfield Generator - Phase 2 Step 4
# Efficient starfield with multiple colors, shapes, and twinkle effects
# Fills the entire space board with procedurally generated stars

# Star properties
var stars: Array = []
var star_count: int = 150  # Reduced to 150
var board_size: Vector2 = Vector2(8000, 6000)  # Will be updated from space board
var is_main_starfield: bool = true  # Whether this is the main starfield or a tiled copy
var grid_offset: Vector2 = Vector2.ZERO  # Offset for tiled copies
var main_starfield: Node2D  # Reference to main starfield for shared data

# Star types and properties
enum StarType {
	SMALL,
	MEDIUM,
	LARGE
}

# Star configuration with randomized colors - smaller circles, larger stars
var star_config = {
	StarType.SMALL: {"size": 1.5},  # Half of previous 3.0
	StarType.MEDIUM: {"size": 2.5},  # Half of previous 5.0
	StarType.LARGE: {"size": 3.5}   # Half of previous 7.0
}

# Static starfield - no viewport culling for simplicity
var visible_stars: Array = []

func _ready():
	"""Initialize starfield"""
	print("STARFIELD: Initializing starfield system...")
	
	# Get board size from parent space board
	var space_board = get_parent()
	if space_board and space_board.has_method("get_board_size"):
		board_size = space_board.get_board_size()
		print("STARFIELD: Board size set to: ", board_size)
	
	# Generate stars
	generate_stars()
	
	print("STARFIELD: Starfield initialized with ", stars.size(), " stars")

func generate_stars():
	"""Generate all stars for the starfield"""
	
	stars.clear()
	var half_board = board_size / 2.0
	
	# Generate stars across the entire board
	for i in range(star_count):
		var star = create_star(half_board)
		stars.append(star)
	
	print("STARFIELD: Generated ", stars.size(), " stars across ", board_size, " area")

func create_star(half_board: Vector2) -> Dictionary:
	"""Create a single star with random properties"""
	
	# Random position across board
	var position = Vector2(
		randf_range(-half_board.x, half_board.x),
		randf_range(-half_board.y, half_board.y)
	)
	
	# Random star type with weighted distribution
	var star_type = get_weighted_star_type()
	var config = star_config[star_type]
	
	# Generate random star color
	var random_color = generate_random_star_color()
	
	# Create star data
	var star = {
		"position": position,
		"type": star_type,
		"size": config.size,
		"base_color": random_color,
		"shape": get_random_star_shape(),
		"rotation": randf() * TAU  # Static random rotation only
	}
	
	return star

func generate_random_star_color() -> Color:
	"""Generate star color with restricted palette: 75% white, rest split between red, orange, light blue"""
	
	# Weighted distribution: 75% white, 8.33% each for red, orange, light blue
	var random_value = randf()
	
	if random_value < 0.75:
		# 75% white
		return Color.WHITE.darkened(randf() * 0.3)
	elif random_value < 0.833:
		# 8.33% red
		return Color.RED.lightened(randf() * 0.3)
	elif random_value < 0.917:
		# 8.33% orange
		return Color.ORANGE.lightened(randf() * 0.1)
	else:
		# 8.33% light blue
		return Color.CYAN.lightened(randf() * 0.4)

func get_weighted_star_type() -> StarType:
	"""Get a weighted random star type"""
	
	# Weight distribution: more small stars, fewer large stars
	var weights = [70, 25, 5]  # SMALL, MEDIUM, LARGE
	
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i as StarType
	
	return StarType.SMALL  # Fallback

func get_random_star_shape() -> String:
	"""Get a random star shape - 75% circles"""
	
	var shapes = ["circle", "star4", "star6"]  # Circle, 4-point star, 6-point star
	var weights = [75, 12.5, 12.5]  # 75% circles, rest split evenly
	
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for i in range(shapes.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return shapes[i]
	
	return "circle"  # Fallback

# No animation - static vector starfield

# Viewport culling removed - static starfield draws all stars

func _draw():
	"""Draw all stars - static starfield with no culling"""
	
	# Debug: Print drawing info for first few frames (commented out for readability)
	# if Engine.get_frames_drawn() < 10:
	#	print("STARFIELD: Drawing ", stars.size(), " stars for ", name, " at offset ", grid_offset)
	
	# Draw all stars for complete coverage
	for star in stars:
		draw_star(star)

func setup_tiled_copy(offset: Vector2, main_starfield_ref: Node2D = null):
	"""Setup this starfield as a tiled copy with given offset"""
	
	is_main_starfield = false
	grid_offset = offset
	main_starfield = main_starfield_ref
	name = "Starfield_Tiled_" + str(offset.x) + "_" + str(offset.y)
	
	# Share star data with main starfield
	if main_starfield_ref:
		stars = main_starfield_ref.stars
		visible_stars = main_starfield_ref.visible_stars
	
	print("STARFIELD: Created tiled copy with offset: ", offset)

func create_tiled_copies(parent_node: Node):
	"""Create tiled copies around the main starfield"""
	
	if not is_main_starfield:
		return  # Only main starfield creates copies
	
	# Create a 3x3 grid of starfield copies around the main one
	var copy_positions = [
		Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(-1, 0),                     Vector2(1, 0),
		Vector2(-1, 1),  Vector2(0, 1),  Vector2(1, 1)
	]
	
	for offset in copy_positions:
		var copy = Node2D.new()
		copy.set_script(load("res://scripts/starfield.gd"))
		copy.setup_tiled_copy(offset * board_size, self)
		parent_node.add_child(copy)
		
		print("STARFIELD: Created tiled copy at offset: ", copy.grid_offset)

func draw_star(star: Dictionary):
	"""Draw a single star with vector graphics (colored outline, black fill)"""
	
	var outline_color = star.base_color
	
	# Apply grid offset for tiled copies
	var draw_position = star.position + grid_offset
	
	# Use base size
	var current_size = star.size
	
	# Debug: Print first few star positions for each starfield
	if Engine.get_frames_drawn() < 5 and star == stars[0]:
		print("STARFIELD: Drawing star at original pos: ", star.position, " draw pos: ", draw_position, " for ", name)
	
	match star.shape:
		"circle":
			draw_vector_circle(draw_position, current_size, outline_color)
		"star4":
			draw_vector_4_point_star(draw_position, current_size, outline_color, star.rotation)
		"star6":
			draw_vector_6_point_star(draw_position, current_size, outline_color, star.rotation)

func draw_vector_circle(position: Vector2, size: float, outline_color: Color):
	"""Draw a circle with colored outline and black fill (vector style)"""
	
	# Draw black fill
	draw_circle(position, size, Color.BLACK)
	
	# Draw colored outline
	draw_circle(position, size, outline_color, false, 1.0)

func draw_vector_4_point_star(position: Vector2, size: float, outline_color: Color, rotation: float):
	"""Draw a 4-pointed star made of 2 full line segments (vector style)"""
	
	var outer_radius = size * 3.0  # Made 3x larger for visibility
	
	# Draw 2 full lines extending through center (cross pattern)
	var angle1 = rotation
	var angle2 = rotation + PI/2  # 90 degrees
	
	# Calculate points extending in both directions from center
	var point1a = position + Vector2(cos(angle1) * outer_radius, sin(angle1) * outer_radius)
	var point1b = position - Vector2(cos(angle1) * outer_radius, sin(angle1) * outer_radius)
	var point2a = position + Vector2(cos(angle2) * outer_radius, sin(angle2) * outer_radius)
	var point2b = position - Vector2(cos(angle2) * outer_radius, sin(angle2) * outer_radius)
	
	# Draw the 2 full line segments extending through center
	draw_line(point1a, point1b, outline_color, 1.0)
	draw_line(point2a, point2b, outline_color, 1.0)

func draw_vector_6_point_star(position: Vector2, size: float, outline_color: Color, rotation: float):
	"""Draw a 6-pointed star made of 3 full line segments (vector style)"""
	
	var outer_radius = size * 3.0  # Made 3x larger for visibility
	
	# Draw 3 full lines extending through center (60 degrees apart)
	for i in range(3):
		var angle = (PI * 2.0 * i / 3.0) + rotation  # 120 degrees apart for 3 lines
		var point_a = position + Vector2(cos(angle) * outer_radius, sin(angle) * outer_radius)
		var point_b = position - Vector2(cos(angle) * outer_radius, sin(angle) * outer_radius)
		draw_line(point_a, point_b, outline_color, 1.0)

func draw_cross(position: Vector2, size: float, color: Color):
	"""Draw a cross-shaped star"""
	
	var half_size = size / 2.0
	draw_line(position + Vector2(-half_size, 0), position + Vector2(half_size, 0), color, size * 0.3)
	draw_line(position + Vector2(0, -half_size), position + Vector2(0, half_size), color, size * 0.3)

func draw_diamond(position: Vector2, size: float, color: Color):
	"""Draw a diamond-shaped star"""
	
	var points = PackedVector2Array()
	points.append(position + Vector2(0, -size))
	points.append(position + Vector2(size, 0))
	points.append(position + Vector2(0, size))
	points.append(position + Vector2(-size, 0))
	draw_colored_polygon(points, color)

func draw_4_point_star(position: Vector2, size: float, color: Color, rotation: float):
	"""Draw a 4-pointed star shape"""
	
	var points = PackedVector2Array()
	var inner_radius = size * 0.4
	var outer_radius = size
	
	# Create 8 points (4 outer, 4 inner) for 4-pointed star
	for i in range(8):
		var angle = (PI * 2.0 * i / 8.0) + rotation
		var radius = inner_radius if i % 2 == 1 else outer_radius
		var point = position + Vector2(cos(angle) * radius, sin(angle) * radius)
		points.append(point)
	
	draw_colored_polygon(points, color)

func draw_6_point_star(position: Vector2, size: float, color: Color, rotation: float):
	"""Draw a 6-pointed star shape"""
	
	var points = PackedVector2Array()
	var inner_radius = size * 0.4
	var outer_radius = size
	
	# Create 12 points (6 outer, 6 inner) for 6-pointed star
	for i in range(12):
		var angle = (PI * 2.0 * i / 12.0) + rotation
		var radius = inner_radius if i % 2 == 1 else outer_radius
		var point = position + Vector2(cos(angle) * radius, sin(angle) * radius)
		points.append(point)
	
	draw_colored_polygon(points, color)

func draw_star_shape(position: Vector2, size: float, color: Color, rotation: float):
	"""Draw a 4-pointed star shape (legacy function)"""
	draw_4_point_star(position, size, color, rotation)

func get_star_count() -> int:
	"""Get the total number of stars"""
	return stars.size()

func get_visible_star_count() -> int:
	"""Get the number of currently visible stars"""
	return visible_stars.size()

func set_star_density(density_multiplier: float):
	"""Adjust star density"""
	
	var new_count = int(star_count * density_multiplier)
	if new_count != star_count:
		star_count = new_count
		generate_stars()
		print("STARFIELD: Star density adjusted to ", star_count, " stars")

func regenerate_starfield():
	"""Regenerate the entire starfield"""
	print("STARFIELD: Regenerating starfield...")
	generate_stars()
