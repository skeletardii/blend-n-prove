extends CanvasLayer

# References to child nodes
@onready var center_container: Control = $CenterContainer
@onready var background_panel: Panel = $CenterContainer/BackgroundPanel
@onready var container: VBoxContainer = $CenterContainer/VBoxContainer
@onready var base_score_label: Label = $CenterContainer/VBoxContainer/BaseScoreLabel
@onready var bonus_label: Label = $CenterContainer/VBoxContainer/BonusLabel
@onready var multiplier_label: Label = $CenterContainer/VBoxContainer/MultiplierLabel
@onready var total_score_label: Label = $CenterContainer/VBoxContainer/TotalScoreLabel
@onready var particles: CPUParticles2D = $CenterContainer/Particles
@onready var flash_rect: ColorRect = $FlashRect

# Animation constants
const SCALE_DURATION: float = 0.3
const BREAKDOWN_DISPLAY_TIME: float = 1.2  # How long to show the breakdown
const BREAKDOWN_FADE_TIME: float = 0.3  # How long to fade out breakdown
const FLY_DURATION: float = 0.6  # How long for score to fly to display
const COUNT_UP_DURATION: float = 0.5  # How long to count up the score
const PARTICLE_LIFETIME: float = 0.8

# Reference to score display (passed in)
var score_display_label: Label = null
var old_score: int = 0
var total_score: int = 0

# Color thresholds for multiplier (green = low, purple = high)
const COLOR_GREEN: Color = Color(0.0, 1.0, 0.0)  # 1.0x - worst
const COLOR_CYAN: Color = Color(0.0, 1.0, 1.0)  # 1.5x
const COLOR_BLUE: Color = Color(0.3, 0.3, 1.0)  # 2.0x
const COLOR_PURPLE: Color = Color(0.7, 0.0, 1.0)  # 2.5x+ - best

func _ready() -> void:
	# Start invisible
	center_container.modulate.a = 0.0
	container.scale = Vector2.ZERO
	flash_rect.modulate.a = 0.0
	total_score_label.modulate.a = 0.0  # Hidden initially

func show_score_popup(base_score: int, time_bonus: int, score_display: Label, current_score: int) -> void:
	# Store references
	score_display_label = score_display
	old_score = current_score
	total_score = base_score + time_bonus
	# Calculate multiplier
	var multiplier: float = 1.0
	if base_score > 0:
		multiplier = 1.0 + (float(time_bonus) / float(base_score))

	# Determine color based on multiplier
	var popup_color: Color = _calculate_color_from_multiplier(multiplier)

	# Set label texts
	base_score_label.text = "Base: +" + str(base_score)
	bonus_label.text = "Time Bonus: +" + str(time_bonus)
	multiplier_label.text = "×%.1f" % multiplier
	total_score_label.text = "+" + str(total_score)

	# Apply colors
	base_score_label.modulate = Color.WHITE
	bonus_label.modulate = popup_color
	multiplier_label.modulate = popup_color
	total_score_label.modulate = popup_color

	# Configure particles
	particles.color = popup_color
	particles.emitting = true

	# Play sound effect
	AudioManager.play_score_popup(multiplier)

	# Position popup to the right of the score display
	_position_popup_near_score()

	# Start animations
	_animate_popup(multiplier, popup_color)

func show_score_popup_phase2(added_score: int, time_bonus: int, base_score: int, explosion_pos: Vector2, score_display: Label, current_score: int) -> void:
	"""Show score popup for Phase 2 - simplified format with just the added score and multiplier"""
	# Store references
	score_display_label = score_display
	old_score = current_score
	total_score = added_score

	# Calculate multiplier
	var multiplier: float = 1.0
	if base_score > 0:
		multiplier = 1.0 + (float(time_bonus) / float(base_score))

	# Determine color based on multiplier
	var popup_color: Color = _calculate_color_from_multiplier(multiplier)

	# Set simplified label text - just the total with multiplier in parenthesis
	total_score_label.text = "+%d (×%.1f)" % [added_score, multiplier]
	total_score_label.modulate = popup_color
	total_score_label.modulate.a = 1.0  # Make visible immediately

	# Hide the breakdown labels for Phase 2
	base_score_label.visible = false
	bonus_label.visible = false
	multiplier_label.visible = false

	# Position at explosion location
	center_container.offset_left = explosion_pos.x - 100
	center_container.offset_top = explosion_pos.y - 50
	center_container.offset_right = explosion_pos.x + 100
	center_container.offset_bottom = explosion_pos.y + 50

	# Configure particles
	particles.color = popup_color
	particles.emitting = true

	# Play sound effect
	AudioManager.play_score_popup(multiplier)

	# Start simplified animation
	_animate_popup_phase2(multiplier, popup_color)

func _calculate_color_from_multiplier(multiplier: float) -> Color:
	# Green (1.0x - worst) → Cyan (1.5x) → Blue (2.0x) → Purple (2.5x+ - best)
	if multiplier < 1.5:
		# Interpolate between Green and Cyan
		var t: float = (multiplier - 1.0) / 0.5
		return COLOR_GREEN.lerp(COLOR_CYAN, t)
	elif multiplier < 2.0:
		# Interpolate between Cyan and Blue
		var t: float = (multiplier - 1.5) / 0.5
		return COLOR_CYAN.lerp(COLOR_BLUE, t)
	elif multiplier < 2.5:
		# Interpolate between Blue and Purple
		var t: float = (multiplier - 2.0) / 0.5
		return COLOR_BLUE.lerp(COLOR_PURPLE, t)
	else:
		# Max color (Purple - best)
		return COLOR_PURPLE

func _position_popup_near_score() -> void:
	"""Position the popup in the left 1/3 of the screen"""
	# Get the screen width
	var screen_width: float = get_viewport().get_visible_rect().size.x
	var screen_height: float = get_viewport().get_visible_rect().size.y

	# Position in the left third of the screen, centered vertically
	var popup_x: float = screen_width / 6  # Center of left 1/3
	var popup_y: float = screen_height / 2 - 100  # Centered vertically

	# Update center container position
	center_container.offset_left = popup_x - 200  # Center the 400px container
	center_container.offset_top = popup_y
	center_container.offset_right = popup_x + 200
	center_container.offset_bottom = popup_y + 200

func _animate_popup(multiplier: float, popup_color: Color) -> void:
	# Phase 1: Pop in with breakdown (0.0 - 0.3s)
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Fade in
	tween.tween_property(center_container, "modulate:a", 1.0, SCALE_DURATION * 0.5)

	# Explosive scale with overshoot
	tween.tween_property(container, "scale", Vector2(1.3, 1.3), SCALE_DURATION * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Settle back to normal size
	tween.chain().tween_property(container, "scale", Vector2.ONE, SCALE_DURATION * 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Add pulsing effect to multiplier label for emphasis
	var pulse_tween: Tween = create_tween()
	pulse_tween.set_loops(3)
	pulse_tween.tween_property(multiplier_label, "scale", Vector2(1.2, 1.2), 0.25) \
		.set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(multiplier_label, "scale", Vector2.ONE, 0.25) \
		.set_ease(Tween.EASE_IN)

	# Screen flash for high multipliers (1.5x and above) - made more dramatic
	if multiplier >= 1.5:
		var flash_intensity: float = min((multiplier - 1.5) * 0.2, 0.5)
		flash_rect.modulate = popup_color
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(flash_rect, "modulate:a", flash_intensity, 0.1)
		flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.3)

	# Phase 2: Wait to display breakdown (0.3 - 1.5s)
	await get_tree().create_timer(BREAKDOWN_DISPLAY_TIME).timeout

	# Phase 3: Fade out breakdown, show total (1.5 - 1.8s)
	var fade_breakdown: Tween = create_tween()
	fade_breakdown.set_parallel(true)
	fade_breakdown.tween_property(base_score_label, "modulate:a", 0.0, BREAKDOWN_FADE_TIME)
	fade_breakdown.tween_property(bonus_label, "modulate:a", 0.0, BREAKDOWN_FADE_TIME)
	fade_breakdown.tween_property(multiplier_label, "modulate:a", 0.0, BREAKDOWN_FADE_TIME)
	fade_breakdown.tween_property(total_score_label, "modulate:a", 1.0, BREAKDOWN_FADE_TIME)

	await fade_breakdown.finished

	# Phase 4: Fly total score to score display (1.8 - 2.4s)
	if score_display_label:
		var start_pos: Vector2 = total_score_label.global_position + total_score_label.size / 2
		var end_pos: Vector2 = score_display_label.global_position + score_display_label.size / 2

		# Create a duplicate label that will fly
		var flying_label: Label = Label.new()
		flying_label.text = total_score_label.text
		flying_label.label_settings = total_score_label.label_settings
		flying_label.modulate = total_score_label.modulate
		flying_label.position = start_pos
		flying_label.z_index = 200
		get_tree().root.add_child(flying_label)

		# Hide the original total label
		total_score_label.modulate.a = 0.0

		# Animate flying label
		var fly_tween: Tween = create_tween()
		fly_tween.set_parallel(true)
		fly_tween.tween_property(flying_label, "position", end_pos, FLY_DURATION) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		fly_tween.tween_property(flying_label, "scale", Vector2(0.5, 0.5), FLY_DURATION) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

		await fly_tween.finished

		# Remove flying label
		flying_label.queue_free()

		# Phase 5: Count up the score display (2.4 - 2.9s)
		_animate_score_count_up()

	# Cleanup after all animations
	await get_tree().create_timer(COUNT_UP_DURATION + 0.2).timeout
	queue_free()

func _animate_score_count_up() -> void:
	"""Rapidly count up the score display from old to new value"""
	if not score_display_label:
		return

	var count_tween: Tween = create_tween()
	var temp_score: int = old_score

	# Use a custom method to interpolate integer values
	count_tween.tween_method(
		func(value: float):
			score_display_label.text = str(int(value)),
		float(old_score),
		float(old_score + total_score),
		COUNT_UP_DURATION
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Add a slight pulse to the score display
	var pulse_tween: Tween = create_tween()
	pulse_tween.tween_property(score_display_label, "scale", Vector2(1.2, 1.2), COUNT_UP_DURATION * 0.5) \
		.set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(score_display_label, "scale", Vector2.ONE, COUNT_UP_DURATION * 0.5) \
		.set_ease(Tween.EASE_IN)

func _animate_popup_phase2(multiplier: float, popup_color: Color) -> void:
	"""Simplified animation for Phase 2 - just show, wait, then fly to score"""
	# Phase 1: Pop in (0.0 - 0.3s)
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# Fade in
	tween.tween_property(center_container, "modulate:a", 1.0, SCALE_DURATION * 0.5)

	# Explosive scale with overshoot
	tween.tween_property(container, "scale", Vector2(1.3, 1.3), SCALE_DURATION * 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Settle back to normal size
	tween.chain().tween_property(container, "scale", Vector2.ONE, SCALE_DURATION * 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Phase 2: Wait briefly (0.3 - 0.9s)
	await get_tree().create_timer(0.6).timeout

	# Phase 3: Fly score to score display (0.9 - 1.4s)
	if score_display_label:
		var start_pos: Vector2 = total_score_label.global_position + total_score_label.size / 2
		var end_pos: Vector2 = score_display_label.global_position + score_display_label.size / 2

		# Create a duplicate label that will fly
		var flying_label: Label = Label.new()
		flying_label.text = total_score_label.text
		flying_label.label_settings = total_score_label.label_settings
		flying_label.modulate = total_score_label.modulate
		flying_label.position = start_pos
		flying_label.z_index = 200
		get_tree().root.add_child(flying_label)

		# Hide the original total label
		total_score_label.modulate.a = 0.0
		center_container.modulate.a = 0.0  # Hide container

		# Animate flying label
		var fly_tween: Tween = create_tween()
		fly_tween.set_parallel(true)
		fly_tween.tween_property(flying_label, "position", end_pos, FLY_DURATION) \
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		fly_tween.tween_property(flying_label, "scale", Vector2(0.5, 0.5), FLY_DURATION) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

		await fly_tween.finished

		# Remove flying label
		flying_label.queue_free()

		# Phase 4: Count up the score display
		_animate_score_count_up()

	# Cleanup after all animations
	await get_tree().create_timer(COUNT_UP_DURATION + 0.2).timeout
	queue_free()
