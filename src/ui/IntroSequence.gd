extends Control

@onready var planet: TextureRect = $CenterContainer/Planet
@onready var rocket: TextureRect = $Rocket
@onready var black_hole: TextureRect = $CenterContainer/BlackHole
@onready var black_hole_particles: CPUParticles2D = $BlackHoleParticles
@onready var asteroid1: CPUParticles2D = $Asteroid1
@onready var asteroid2: CPUParticles2D = $Asteroid2
@onready var asteroid3: CPUParticles2D = $Asteroid3
@onready var asteroid4: CPUParticles2D = $Asteroid4
@onready var asteroid5: CPUParticles2D = $Asteroid5
@onready var flash: ColorRect = $Flash
@onready var space_bg: TextureRect = $SpaceBG
@onready var exhaust_container: Node2D = $Rocket/ExhaustContainer
@onready var AudioManager = $"/root/AudioManager"
@onready var flame_core: CPUParticles2D = $Rocket/ExhaustContainer/FlameCore
@onready var smoke_trail: CPUParticles2D = $Rocket/ExhaustContainer/SmokeTrail

var black_hole_rotation_speed: float = 2.0  # radians per second

func _ready() -> void:
	# Setup initial state
	rocket.scale = Vector2(0.01, 0.01)
	rocket.position = get_viewport_rect().size / 2 - Vector2(0, 30)

	# Scale exhaust particles with rocket initial size
	exhaust_container.scale = Vector2(0.01, 0.01)

	# Position black hole and asteroid particles at screen center
	var screen_center = get_viewport_rect().size / 2
	black_hole_particles.position = screen_center
	asteroid1.position = screen_center
	asteroid2.position = screen_center
	asteroid3.position = screen_center
	asteroid4.position = screen_center
	asteroid5.position = screen_center

	# Ensure asteroid particles start off not emitting
	asteroid1.emitting = false
	asteroid2.emitting = false
	asteroid3.emitting = false
	asteroid4.emitting = false
	asteroid5.emitting = false

	black_hole.scale = Vector2(0.01, 0.01)
	black_hole.rotation = 0.0
	black_hole.visible = false
	planet.rotation = 0.0
	planet.scale = Vector2(1.0, 1.0)
	flash.modulate.a = 0.0

	# Start background music early
	AudioManager.start_background_music()

	# Start sequence
	play_intro()

func _process(delta: float) -> void:
	# Continuously rotate black hole when visible
	if black_hole.visible:
		black_hole.rotation += black_hole_rotation_speed * delta

func play_intro() -> void:
	AudioManager.play_rocket_launch()
	var tween = create_tween()
	var screen_center = get_viewport_rect().size / 2

	# 1. Rocket grows and moves away with smooth acceleration
	# Scale rocket and exhaust together
	tween.tween_property(rocket, "scale", Vector2(1.0, 1.0), 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(exhaust_container, "scale", Vector2(1.0, 1.0), 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Rocket accelerates to the right
	tween.parallel().tween_property(rocket, "position:x", get_viewport_rect().size.x + 200, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Motion blur: rocket shrinks and fades as it speeds up
	tween.parallel().tween_property(rocket, "scale", Vector2(0.6, 0.6), 2.0).set_delay(1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(exhaust_container, "scale", Vector2(0.6, 0.6), 2.0).set_delay(1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(rocket, "modulate:a", 0.3, 2.0).set_delay(1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# 2. Brief pause for dramatic effect
	tween.tween_interval(0.3)

	# 3. Black hole suddenly appears at planet center
	tween.tween_callback(func():
		black_hole.visible = true
		black_hole_particles.emitting = true
		AudioManager.play_music("power_on_music", false) # Play music here
	)

	# 4. Black hole starts rotating and growing slowly (ominous buildup)
	# Initial slow growth (rotation is continuous in _process)
	tween.tween_property(black_hole, "scale", Vector2(1.8, 1.8), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# 5. Planet shrinks uniformly and disappears into center
	tween.parallel().tween_property(planet, "scale", Vector2(0.01, 0.01), 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(planet, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


	# 7. Brief moment as planet is consumed
	tween.tween_interval(0.15)

	# 8. Black hole violently expands to consume everything
	tween.tween_property(black_hole, "scale", Vector2(60.0, 60.0), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# 9. Flash to white as reality breaks down
	tween.parallel().tween_property(flash, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# 10. Hold the white void
	tween.tween_interval(0.4)

	# 11. Transition to gameplay
	tween.tween_callback(func():
		SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")
)
