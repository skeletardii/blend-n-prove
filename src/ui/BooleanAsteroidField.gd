extends Control

# Configuration
const SYMBOLS = ["P", "Q", "R", "S", "T", "∧", "∨", "¬", "→", "↔", "⊕"]
const SYMBOL_COUNT = 50
const BASE_SPEED = 30.0
const MAX_SPEED = 100.0
const MIN_SCALE = 0.2
const MAX_SCALE = 2.5
const ROTATION_SPEED_RANGE = 0.5
const Z_SPEED_RANGE = 0.1 # Speed of moving towards/away from camera

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
		
		# Center pivot for rotation
		label.pivot_offset = Vector2(20, 20)
		
		add_child(label)
		
		# Initial Random depth (0.1 to 1.5)
		# 0.1 = very far, 1.5 = very close (past screen)
		var depth = randf_range(0.1, 1.2)
		
		# Initial position (random on screen)
		label.position = Vector2(
			randf() * viewport_size.x,
			randf() * viewport_size.y
		)
		
		update_asteroid_visuals(label, depth)
		
		# Store data for movement
		asteroids.append({
			"node": label,
			"velocity": Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * BASE_SPEED,
			"rotation_speed": randf_range(-ROTATION_SPEED_RANGE, ROTATION_SPEED_RANGE),
			"depth": depth,
			"z_velocity": randf_range(-Z_SPEED_RANGE, Z_SPEED_RANGE)
		})

func update_asteroid_visuals(label: Label, depth: float) -> void:
	# Scale based on depth
	var scale_val = lerp(MIN_SCALE, MAX_SCALE, depth)
	label.scale = Vector2(scale_val, scale_val)
	
	# Color/Opacity based on depth (fog effect)
	# Far (0.0): Dark, transparent
	# Close (1.0): Bright, opaque
	var brightness = clamp(lerp(0.2, 1.0, depth), 0.2, 1.0)
	var alpha = clamp(lerp(0.3, 1.0, depth), 0.0, 1.0)
	label.modulate = Color(brightness, brightness, brightness, alpha)
	
	# Z-Sorting: Higher depth should appear on top
	# We can use z_index, but simpler to just use move_to_front if we wanted perfect sorting
	# For asteroids, simple z_index based on depth bucket is enough
	label.z_index = int(depth * 10)

func _process(delta: float) -> void:
	for asteroid in asteroids:
		var node = asteroid["node"]
		var depth = asteroid["depth"]
		
		# Update depth (Z-movement)
		depth += asteroid["z_velocity"] * delta
		
		# Respawn if out of depth bounds (too close or too far)
		if depth < 0.1 or depth > 1.5:
			# Reset to opposite side
			if asteroid["z_velocity"] > 0: # Was coming towards, now too close
				depth = 0.1 # Send to back
			else: # Was going away, now too far
				depth = 1.2 # Send to front
			
			# Randomize position on respawn
			node.position = Vector2(
				randf() * viewport_size.x,
				randf() * viewport_size.y
			)
			# Pick new symbol
			node.text = SYMBOLS[randi() % SYMBOLS.size()]
		
		asteroid["depth"] = depth
		
		# Update rotation
		node.rotation += asteroid["rotation_speed"] * delta
		
		# Update position (parallax effect: speed depends on depth)
		var parallax_speed = asteroid["velocity"] * depth
		node.position += parallax_speed * delta
		
		# Wrap around screen X/Y
		# Use margin based on scale to avoid popping
		var margin = 50 * node.scale.x
		
		if node.position.x > viewport_size.x + margin:
			node.position.x = -margin
		elif node.position.x < -margin:
			node.position.x = viewport_size.x + margin
			
		if node.position.y > viewport_size.y + margin:
			node.position.y = -margin
		elif node.position.y < -margin:
			node.position.y = viewport_size.y + margin
			
		# Update visuals (scale, color) based on new depth
		update_asteroid_visuals(node, depth)