extends Node

# Screen Manager - Handles dynamic screen sizing and scaling
# Calculates optimal 4:3 resolution and manages viewport scaling

# Default reference resolution (all game logic uses this)
var default_resolution: Vector2 = Vector2(800, 600)

# Actual screen properties
var monitor_size: Vector2
var viewport_size: Vector2
var scale_factor: float = 1.0

# Viewport positioning for centering
var viewport_offset: Vector2 = Vector2.ZERO

func _ready():
	"""Initialize screen manager"""
	print("SCREEN MANAGER: Initializing screen system...")
	
	# Calculate screen dimensions
	calculate_screen_dimensions()
	
	# Setup window and viewport
	setup_window_and_viewport()
	
	print("SCREEN MANAGER: Screen system ready!")
	print("  Monitor size: ", monitor_size)
	print("  Viewport size: ", viewport_size)
	print("  Scale factor: ", scale_factor)
	print("  Viewport offset: ", viewport_offset)

func calculate_screen_dimensions():
	"""Calculate optimal 4:3 viewport size for current monitor"""
	
	# Get monitor size
	var screen = get_tree().current_scene.get_window()
	monitor_size = screen.get_size()
	
	# Calculate largest 4:3 resolution that fits in monitor
	var aspect_ratio = 4.0 / 3.0
	
	# Try fitting by width first
	var test_width = monitor_size.x
	var test_height = test_width / aspect_ratio
	
	# If height exceeds monitor, fit by height instead
	if test_height > monitor_size.y:
		test_height = monitor_size.y
		test_width = test_height * aspect_ratio
	
	# Round to even numbers for better compatibility
	viewport_size = Vector2(
		int(test_width / 2.0) * 2,
		int(test_height / 2.0) * 2
	)
	
	# Calculate scale factor
	scale_factor = viewport_size.x / default_resolution.x
	
	# Calculate viewport offset for centering
	viewport_offset = (monitor_size - viewport_size) / 2.0
	
	print("SCREEN MANAGER: Calculated dimensions:")
	print("  Monitor: ", monitor_size)
	print("  Viewport: ", viewport_size)
	print("  Scale factor: ", scale_factor)

func setup_window_and_viewport():
	"""Setup borderless window and centered viewport"""
	
	var screen = get_tree().current_scene.get_window()
	
	# Set window to borderless fullscreen
	screen.mode = Window.MODE_FULLSCREEN
	screen.borderless = true
	
	# Set window size to monitor size
	screen.size = monitor_size
	
	# Setup viewport
	var viewport = get_viewport()
	viewport.size = viewport_size
	
	# Create black background for letterboxing
	create_letterbox_background()

func create_letterbox_background():
	"""Create black background to fill unused screen space"""
	
	# This will be handled by the space board background
	# The space board will create a full-screen black background
	# and the viewport will be centered on top of it
	pass

func get_default_resolution() -> Vector2:
	"""Get the default reference resolution"""
	return default_resolution

func get_viewport_size() -> Vector2:
	"""Get the actual viewport size"""
	return viewport_size

func get_monitor_size() -> Vector2:
	"""Get the monitor size"""
	return monitor_size

func get_scale_factor() -> float:
	"""Get the scale factor from default to actual resolution"""
	return scale_factor

func get_viewport_offset() -> Vector2:
	"""Get the viewport offset for centering"""
	return viewport_offset

func scale_position(position: Vector2) -> Vector2:
	"""Scale a position from default resolution to actual resolution"""
	return position * scale_factor

func unscale_position(position: Vector2) -> Vector2:
	"""Unscale a position from actual resolution to default resolution"""
	return position / scale_factor

func scale_vector(vector: Vector2) -> Vector2:
	"""Scale a vector from default resolution to actual resolution"""
	return vector * scale_factor

func unscale_vector(vector: Vector2) -> Vector2:
	"""Unscale a vector from actual resolution to default resolution"""
	return vector / scale_factor

func scale_float(value: float) -> float:
	"""Scale a float value from default resolution to actual resolution"""
	return value * scale_factor

func unscale_float(value: float) -> float:
	"""Unscale a float value from actual resolution to default resolution"""
	return value / scale_factor

func get_screen_bounds() -> Rect2:
	"""Get the screen bounds in default resolution coordinates"""
	return Rect2(Vector2.ZERO, default_resolution)

func get_viewport_bounds() -> Rect2:
	"""Get the viewport bounds in actual screen coordinates"""
	return Rect2(viewport_offset, viewport_size)

func is_position_in_viewport(position: Vector2) -> bool:
	"""Check if a position is within the viewport"""
	var relative_pos = position - viewport_offset
	return relative_pos.x >= 0 and relative_pos.x < viewport_size.x and \
		   relative_pos.y >= 0 and relative_pos.y < viewport_size.y

func center_position_on_screen(position: Vector2) -> Vector2:
	"""Center a position on the screen"""
	return position + viewport_offset
