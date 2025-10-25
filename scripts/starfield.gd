extends Node2D

# Starfield Generator - Phase 2 Step 4
# Efficient starfield with multiple colors, shapes, and twinkle effects
# Fills the entire space board with procedurally generated stars

# Star properties
var stars: Array = []
var star_count: int = 500  # Reduced number of stars for performance
var board_size: Vector2 = Vector2(8000, 6000)  # Will be updated from space board
var is_main_starfield: bool = true  # Whether this is the main starfield or a tiled copy
var grid_offset: Vector2 = Vector2.ZERO  # Offset for tiled copies
var main_starfield: Node2D  # Reference to main starfield for shared data

# Star types and properties
enum StarType {
	SMALL_WHITE,
	MEDIUM_WHITE,
	LARGE_WHITE,
	SMALL_YELLOW,
	MEDIUM_YELLOW,
	LARGE_YELLOW,
	SMALL_BLUE,
	MEDIUM_BLUE,
	LARGE_BLUE,
	SMALL_RED,
	MEDIUM_RED,
	LARGE_RED
}

# Star configuration
var star_config = {
	StarType.SMALL_WHITE: {"size": 1.0, "color": Color.WHITE, "twinkle_speed": 3.0, "twinkle_range": 0.3},
	StarType.MEDIUM_WHITE: {"size": 2.0, "color": Color.WHITE, "twinkle_speed": 2.5, "twinkle_range": 0.4},
	StarType.LARGE_WHITE: {"size": 3.0, "color": Color.WHITE, "twinkle_speed": 2.0, "twinkle_range": 0.5},
	StarType.SMALL_YELLOW: {"size": 1.0, "color": Color.YELLOW, "twinkle_speed": 3.5, "twinkle_range": 0.4},
	StarType.MEDIUM_YELLOW: {"size": 2.0, "color": Color.YELLOW, "twinkle_speed": 3.0, "twinkle_range": 0.5},
	StarType.LARGE_YELLOW: {"size": 3.0, "color": Color.YELLOW, "twinkle_speed": 2.5, "twinkle_range": 0.6},
	StarType.SMALL_BLUE: {"size": 1.0, "color": Color.CYAN, "twinkle_speed": 4.0, "twinkle_range": 0.3},
	StarType.MEDIUM_BLUE: {"size": 2.0, "color": Color.CYAN, "twinkle_speed": 3.5, "twinkle_range": 0.4},
	StarType.LARGE_BLUE: {"size": 3.0, "color": Color.CYAN, "twinkle_speed": 3.0, "twinkle_range": 0.5},
	StarType.SMALL_RED: {"size": 1.0, "color": Color.RED, "twinkle_speed": 2.5, "twinkle_range": 0.2},
	StarType.MEDIUM_RED: {"size": 2.0, "color": Color.RED, "twinkle_speed": 2.0, "twinkle_range": 0.3},
	StarType.LARGE_RED: {"size": 3.0, "color": Color.RED, "twinkle_speed": 1.5, "twinkle_range": 0.4}
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
	
	# Random position across the board
	var position = Vector2(
		randf_range(-half_board.x, half_board.x),
		randf_range(-half_board.y, half_board.y)
	)
	
	# Random star type with weighted distribution
	var star_type = get_weighted_star_type()
	var config = star_config[star_type]
	
	# Create star data
	var star = {
		"position": position,
		"type": star_type,
		"size": config.size,
		"base_color": config.color,
		"twinkle_speed": config.twinkle_speed,
		"twinkle_range": config.twinkle_range,
		"twinkle_offset": randf() * TAU,  # Random phase offset
		"twinkle_time": 0.0,
		"current_brightness": 1.0,
		"shape": get_random_star_shape(),
		"rotation": randf() * TAU,
		"rotation_speed": randf_range(-1.0, 1.0)
	}
	
	return star

func get_weighted_star_type() -> StarType:
	"""Get a weighted random star type"""
	
	# Weight distribution: more small stars, fewer large stars
	var weights = [
		30,  # SMALL_WHITE
		15,  # MEDIUM_WHITE
		5,   # LARGE_WHITE
		20,  # SMALL_YELLOW
		10,  # MEDIUM_YELLOW
		3,   # LARGE_YELLOW
		15,  # SMALL_BLUE
		8,   # MEDIUM_BLUE
		2,   # LARGE_BLUE
		10,  # SMALL_RED
		5,   # MEDIUM_RED
	 1    # LARGE_RED
	]
	
	var total_weight = 0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i as StarType
	
	return StarType.SMALL_WHITE  # Fallback

func get_random_star_shape() -> String:
	"""Get a random star shape"""
	
	var shapes = ["circle", "cross", "diamond", "star"]
	var weights = [50, 25, 15, 10]  # Weighted distribution
	
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

func _process(delta):
	"""Static starfield - no updates needed"""
	
	# Only main starfield handles updates
	if not is_main_starfield:
		return
	
	# Static starfield - no animation, just queue redraw occasionally
	if randf() < 0.01:  # Redraw 1% of the time for any changes
		queue_redraw()

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
	"""Draw a single star"""
	
	var color = star.base_color
	color.a *= star.current_brightness  # Apply twinkle brightness
	
	# Apply grid offset for tiled copies
	var draw_position = star.position + grid_offset
	
	# Debug: Print first few star positions for each starfield
	if Engine.get_frames_drawn() < 5 and star == stars[0]:
		print("STARFIELD: Drawing star at original pos: ", star.position, " draw pos: ", draw_position, " for ", name)
	
	match star.shape:
		"circle":
			draw_circle(draw_position, star.size, color)
		"cross":
			draw_cross(draw_position, star.size, color)
		"diamond":
			draw_diamond(draw_position, star.size, color)
		"star":
			draw_star_shape(draw_position, star.size, color, star.rotation)

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

func draw_star_shape(position: Vector2, size: float, color: Color, rotation: float):
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
