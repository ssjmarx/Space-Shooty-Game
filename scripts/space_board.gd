extends Node2D

# Space Board - Large game area for space shooter
# Black background, 10x default screen size (8000 x 6000)

# Board properties
var board_size: Vector2
var default_screen_size: Vector2 = Vector2(800, 600)
var camera: Camera2D
var screen_manager: Node

func _ready():
	"""Initialize space board"""
	# Get screen manager reference
	screen_manager = get_node_or_null("../screen_manager")
	if not screen_manager:
		screen_manager = get_node_or_null("../../screen_manager")
	
	# Calculate board size based on default screen size (10x)
	if screen_manager:
		default_screen_size = screen_manager.get_default_resolution()
		board_size = default_screen_size * 10.0
	else:
		# Fallback to hardcoded values
		board_size = Vector2(8000, 6000)
	
	print("SPACE BOARD: Initializing space board with size: ", board_size)
	
	# Set up the board background
	setup_background()
	
	# Find and setup camera
	setup_camera()
	
	# Connect to player movement signals
	connect_to_player_signals()

func setup_background():
	"""Create black background for space"""
	
	# Create a large black rectangle as background, centered on origin
	var background = ColorRect.new()
	background.name = "SpaceBackground"
	background.size = board_size
	background.color = Color.BLACK
	background.position = -board_size / 2.0  # Center on origin (0,0)
	add_child(background)
	
	print("SPACE BOARD: Black background created at size: ", board_size, " centered at: ", background.position)

func setup_camera():
	"""Setup camera to follow player within board bounds"""
	
	# Find the camera node
	camera = get_node_or_null("../Camera2D")
	if not camera:
		camera = get_node_or_null("../../Camera2D")
	if not camera:
		camera = get_tree().current_scene.get_node_or_null("Camera2D")
	
	if camera:
		print("SPACE BOARD: Camera found and configured")
		# Camera will be set to follow player by master script
	else:
		print("SPACE BOARD: Warning - No camera found")

func connect_to_player_signals():
	"""Connect to player movement signals for coordinate tracking"""
	
	# Get signal manager
	var signal_manager = get_node_or_null("../signal_manager")
	if not signal_manager:
		signal_manager = get_node_or_null("../../signal_manager")
	
	if signal_manager and signal_manager.has_signal("player_moved_signal"):
		signal_manager.connect("player_moved_signal", _on_player_moved)
		print("SPACE BOARD: Connected to player movement signals")
	else:
		print("SPACE BOARD: Could not connect to player movement signals")

func _on_player_moved(position: Vector2, direction: Vector2):
	"""Handle player movement - update coordinate display"""
	
	# Update coordinate display in debug UI
	update_coordinate_display(position)

func update_coordinate_display(player_position: Vector2):
	"""Update the coordinate display in debug UI"""
	
	# Find debug UI
	var debug_ui = get_debug_ui()
	if debug_ui and debug_ui.has_method("update_player_coordinates"):
		debug_ui.update_player_coordinates(player_position)

func get_debug_ui() -> Node:
	"""Get reference to debug UI"""
	
	# Try multiple paths to find debug UI
	var debug_ui = get_node_or_null("../UI/DebugUI")
	if not debug_ui:
		debug_ui = get_node_or_null("../../UI/DebugUI")
	if not debug_ui:
		debug_ui = get_node_or_null("../debug/DebugUI")
	if not debug_ui:
		debug_ui = get_tree().current_scene.get_node_or_null("UI/DebugUI")
	
	return debug_ui

func get_board_size() -> Vector2:
	"""Get the board size"""
	return board_size

func get_screen_size() -> Vector2:
	"""Get the screen size"""
	if screen_manager:
		return screen_manager.get_default_resolution()
	else:
		return default_screen_size

func is_position_in_bounds(position: Vector2) -> bool:
	"""Check if a position is within board bounds (centered on origin)"""
	var half_size = board_size / 2.0
	return position.x >= -half_size.x and position.x <= half_size.x and \
		   position.y >= -half_size.y and position.y <= half_size.y

func clamp_position_to_bounds(position: Vector2) -> Vector2:
	"""Clamp a position to stay within board bounds (centered on origin)"""
	var half_size = board_size / 2.0
	return Vector2(
		clamp(position.x, -half_size.x, half_size.x),
		clamp(position.y, -half_size.y, half_size.y)
	)

func get_board_center() -> Vector2:
	"""Get the center position of the board"""
	return Vector2.ZERO  # Origin is now the center

func _draw():
	"""Draw debug grid lines (optional - can be enabled for debugging)"""
	
	# Uncomment to draw grid lines for debugging
	# draw_debug_grid()
	pass

func draw_debug_grid():
	"""Draw grid lines for visual reference"""
	
	var grid_size = 100  # Grid lines every 100 pixels
	var grid_color = Color(0.2, 0.2, 0.2, 0.5)  # Dark gray, semi-transparent
	
	# Draw vertical lines
	for x in range(0, int(board_size.x) + 1, grid_size):
		draw_line(Vector2(x, 0), Vector2(x, board_size.y), grid_color)
	
	# Draw horizontal lines
	for y in range(0, int(board_size.y) + 1, grid_size):
		draw_line(Vector2(0, y), Vector2(board_size.x, y), grid_color)
