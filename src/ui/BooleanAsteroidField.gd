extends Control

# Configuration
const SYMBOLS = ["P", "Q", "R", "S", "T", "∧", "∨", "¬", "→", "↔", "⊕"]
const SYMBOL_COUNT = 15
const BASE_SPEED = 30.0
const MAX_SPEED = 100.0
const MIN_SCALE = 0.2
const MAX_SCALE = 2.5
const ROTATION_SPEED_RANGE = 0.5
const Z_SPEED_RANGE = 0.1 # Speed of moving towards/away from camera
const SPAWN_MARGIN = 100.0 # Spawning distance from screen edge
const KILL_MARGIN = 200.0 # Despawn distance (Increased to ensure fully off-screen)

# Array to store symbol data objects
var asteroids: Array[Dictionary] = []
var viewport_size: Vector2

func _ready() -> void:
	# Set to full rect to cover background
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Wait for layout
	await get_tree().process_frame
	viewport_size = get_viewport_rect().size
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	
	spawn_asteroids()

func _on_viewport_size_changed() -> void:
	viewport_size = get_viewport_rect().size

func spawn_asteroids() -> void:
	# Load font resource for labels
	var font = load("res://assets/fonts/MuseoSansRounded700.otf")
	
	for i in range(SYMBOL_COUNT):
		var label = Label.new()
		label.text = SYMBOLS[randi() % SYMBOLS.size()]
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 40)
		
		# Set base color to White so modulate works correctly
		label.add_theme_color_override("font_color", Color.WHITE)
		# Add a soft white outline for a "glowing" effect
		label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.3))
		label.add_theme_constant_override("outline_size", 8)
		
		# Center pivot for rotation
		label.pivot_offset = Vector2(20, 20)
		
		add_child(label)
		
		# Initialize asteroid data
		var data = {
			"node": label,
			"velocity": Vector2.ZERO,
			"rotation_speed": 0.0,
			"depth": 1.0,
			"z_velocity": 0.0
		}
		
		# Respawn off-screen with random delay (distance)
		respawn_asteroid(data, true)
		
		asteroids.append(data)

func respawn_asteroid(data: Dictionary, initial_spawn: bool = false) -> void:
	var label = data["node"]
	
	# Random depth (0.1 to 1.5)
	var depth = randf_range(0.1, 1.5)
	data["depth"] = depth
	data["z_velocity"] = randf_range(-Z_SPEED_RANGE, Z_SPEED_RANGE)
	
	# Random rotation speed
	data["rotation_speed"] = randf_range(-ROTATION_SPEED_RANGE, ROTATION_SPEED_RANGE)
	
	# New Random Symbol
	label.text = SYMBOLS[randi() % SYMBOLS.size()]
	
	# Pick a random side to spawn from (0: Top, 1: Bottom, 2: Left, 3: Right)
	var side = randi() % 4
	var pos = Vector2.ZERO
	# Use SPAWN_MARGIN. Initial spawns can be spread further out to avoid clumping.
	var current_margin = SPAWN_MARGIN * (1.0 if not initial_spawn else randf_range(1.0, 3.0))
	
	match side:
		0: # Top - spawn above
			pos.x = randf_range(0, viewport_size.x)
			pos.y = -current_margin
		1: # Bottom - spawn below
			pos.x = randf_range(0, viewport_size.x)
			pos.y = viewport_size.y + current_margin
		2: # Left - spawn left
			pos.x = -current_margin
			pos.y = randf_range(0, viewport_size.y)
		3: # Right - spawn right
			pos.x = viewport_size.x + current_margin
			pos.y = randf_range(0, viewport_size.y)
			
	label.position = pos
	
	# Calculate velocity to move across screen
	# Target a random point within the central area of the screen to ensure it crosses
	var target = Vector2(
		randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8),
		randf_range(viewport_size.y * 0.2, viewport_size.y * 0.8)
	)
	
	var direction = (target - pos).normalized()
	data["velocity"] = direction * randf_range(BASE_SPEED, MAX_SPEED)
	
	update_asteroid_visuals(label, depth)

func update_asteroid_visuals(label: Label, depth: float) -> void:
	# Scale based on depth
	var scale_val = lerp(MIN_SCALE, MAX_SCALE, depth)
	label.scale = Vector2(scale_val, scale_val)
	
	# Color/Opacity based on depth (fog effect)
	# Always white, just change alpha
	var alpha = clamp(lerp(0.2, 1.0, depth), 0.0, 1.0)
	label.modulate = Color(1.0, 1.0, 1.0, alpha)
	
	# Z-Sorting: Higher depth should appear on top
	# Ensure z_index is strictly less than 10 (MenuContainer is 10)
	# Map depth 0.1-1.5 to z_index 1-9
	label.z_index = int(clamp(depth * 6, 1, 9))

func _process(delta: float) -> void:
	# Define a kill rect larger than the viewport
	# Using KILL_MARGIN which is slightly larger than SPAWN_MARGIN
	var kill_rect = Rect2(
		-KILL_MARGIN, 
		-KILL_MARGIN, 
		viewport_size.x + KILL_MARGIN * 2, 
		viewport_size.y + KILL_MARGIN * 2
	)
	
	for asteroid in asteroids:
		var node = asteroid["node"]
		var depth = asteroid["depth"]
		
		# Update depth (Z-movement)
		depth += asteroid["z_velocity"] * delta
		
		# Check depth bounds (Z-clipping)
		# DO NOT RESPAWN on Z-bounds, as this causes popping in the middle of the screen.
		# Instead, bounce the Z-velocity or clamp depth.
		if depth < 0.1:
			depth = 0.1
			asteroid["z_velocity"] = abs(asteroid["z_velocity"]) # Move forward
		elif depth > 1.5:
			depth = 1.5
			asteroid["z_velocity"] = -abs(asteroid["z_velocity"]) # Move back
			
		asteroid["depth"] = depth
		
		# Update rotation
		node.rotation += asteroid["rotation_speed"] * delta
		
		# Update position (parallax effect)
		var parallax_speed = asteroid["velocity"] * depth
		node.position += parallax_speed * delta
		
		# Check if moved completely out of the kill zone
		# This is the ONLY condition that should trigger a full respawn/reset
		if not kill_rect.has_point(node.position):
			respawn_asteroid(asteroid)
			continue
			
		# Update visuals
		update_asteroid_visuals(node, depth)
