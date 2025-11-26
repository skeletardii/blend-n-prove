extends CanvasLayer

# References to child nodes
@onready var center_container: CenterContainer = $CenterContainer
@onready var container: VBoxContainer = $CenterContainer/VBoxContainer
@onready var base_score_label: Label = $CenterContainer/VBoxContainer/BaseScoreLabel
@onready var bonus_label: Label = $CenterContainer/VBoxContainer/BonusLabel
@onready var multiplier_label: Label = $CenterContainer/VBoxContainer/MultiplierLabel
@onready var particles: CPUParticles2D = $CenterContainer/Particles
@onready var flash_rect: ColorRect = $FlashRect

# Animation constants
const SCALE_DURATION: float = 0.3
const FADE_DELAY: float = 1.5
const FADE_DURATION: float = 0.5
const PARTICLE_LIFETIME: float = 0.8

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

func show_score_popup(base_score: int, time_bonus: int) -> void:
	# Calculate multiplier
	var multiplier: float = 1.0
	if base_score > 0:
		multiplier = 1.0 + (float(time_bonus) / float(base_score))

	# Determine color based on multiplier
	var popup_color: Color = _calculate_color_from_multiplier(multiplier)

	# Set label texts
	base_score_label.text = "+" + str(base_score)
	bonus_label.text = "+" + str(time_bonus)
	multiplier_label.text = "×%.1f" % multiplier

	# Apply colors
	base_score_label.modulate = Color.WHITE
	bonus_label.modulate = popup_color
	multiplier_label.modulate = popup_color

	# Configure particles
	particles.color = popup_color
	particles.emitting = true

	# Play sound effect
	AudioManager.play_score_popup(multiplier)

	# Start animations
	_animate_popup(multiplier, popup_color)

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

func _animate_popup(multiplier: float, popup_color: Color) -> void:
	# Create tween for explosive scale animation
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

	# Screen flash for high multipliers (2x and above)
	if multiplier >= 2.0:
		var flash_intensity: float = min((multiplier - 2.0) * 0.15, 0.3)
		flash_rect.modulate = popup_color
		var flash_tween: Tween = create_tween()
		flash_tween.tween_property(flash_rect, "modulate:a", flash_intensity, 0.1)
		flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.3)

	# Fade out after delay
	var fade_tween: Tween = create_tween()
	fade_tween.tween_interval(FADE_DELAY)
	fade_tween.tween_property(center_container, "modulate:a", 0.0, FADE_DURATION)

	# Cleanup
	fade_tween.finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	queue_free()
