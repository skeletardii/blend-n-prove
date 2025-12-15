extends Control

# Explicit preload to ensure BooleanExpression type is available
const BooleanExpression = preload("res://src/game/expressions/BooleanExpression.gd")

# Preload score popup scene
const score_popup_scene = preload("res://src/ui/ScorePopup.tscn")

# UI References
@onready var work_container: VBoxContainer = $WorkContainer
@onready var phase_label: Label = $WorkContainer/PhaseLabel
@onready var premise_grid: GridContainer = $WorkContainer/InventoryArea/InventoryContainer/InventoryScroll/MarginContainer/PremiseGrid
@onready var target_expression: Label = $WorkContainer/TargetArea/ChatBubble/TargetContainer/TargetExpression
@onready var addition_dialog: Control = $AdditionDialog
@onready var rocket: TextureRect = $WorkContainer/TargetArea/Rocket
@onready var flame_core: CPUParticles2D = $WorkContainer/TargetArea/Rocket/ExhaustContainer/FlameCore
@onready var smoke_trail: CPUParticles2D = $WorkContainer/TargetArea/Rocket/ExhaustContainer/SmokeTrail
@onready var feedback_label: Label = $WorkContainer/InventoryArea/InventoryContainer/FeedbackLabel
@onready var space_bg1: TextureRect = $WorkContainer/TargetArea/SpaceBG1
@onready var space_bg2: TextureRect = $WorkContainer/TargetArea/SpaceBG2
@onready var black_hole: TextureRect = $WorkContainer/TargetArea/BlackHole
@onready var asteroid1: CPUParticles2D = $WorkContainer/TargetArea/Asteroid1
@onready var asteroid2: CPUParticles2D = $WorkContainer/TargetArea/Asteroid2
@onready var asteroid3: CPUParticles2D = $WorkContainer/TargetArea/Asteroid3
@onready var asteroid4: CPUParticles2D = $WorkContainer/TargetArea/Asteroid4
@onready var asteroid5: CPUParticles2D = $WorkContainer/TargetArea/Asteroid5

@onready var combo_container: VBoxContainer = $ComboContainer
@onready var combo_label: Label = $ComboContainer/ComboLabel
@onready var combo_line: ColorRect = $ComboContainer/ComboLine
@onready var combo_sparkles: CPUParticles2D = $ComboContainer/ComboLabel/Sparkles
@onready var combo_sparks: CPUParticles2D = $ComboContainer/ComboLabel/FallingSparks
@onready var combo_fire: CPUParticles2D = $ComboContainer/ComboLabel/Fire

# Card Styles
var card_style_normal: StyleBoxFlat
var card_style_pressed: StyleBoxFlat
var card_style_hover: StyleBoxFlat

# Particle State
var normal_flame_gradient: Gradient
var normal_smoke_gradient: Gradient
var boost_gradient: Gradient # 3x (Red/Orange)
var blue_gradient: Gradient # 5x
var cyan_gradient: Gradient # 8x
var purple_gradient: Gradient # 10x

# Combo State
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_max_time: float = 30.0 # Generous time to keep combo
var glow_tween: Tween

# References passed from GameplayScene
var score_display: Label = null
var patience_timer: float = 0.0

# Operations Panel
@onready var operations_panel: Panel = $OperationsPanel
@onready var operations_close_button: Button = $OperationsPanel/MainContainer/Header/CloseButton
@onready var double_ops_tab: Button = $OperationsPanel/MainContainer/TabContainer/DoubleOpsTab
@onready var single_ops_tab: Button = $OperationsPanel/MainContainer/TabContainer/SingleOpsTab
@onready var double_ops_container: VBoxContainer = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer
@onready var single_ops_container: VBoxContainer = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer

# Double Operation Buttons
@onready var mp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/MPButton
@onready var mt_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/MTButton
@onready var hs_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/HSButton
@onready var ds_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/DSButton
@onready var cd_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/CDButton
@onready var dn_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/DNButton
@onready var conj_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/CONJButton
@onready var eq_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/EQButton
@onready var res_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/DoubleOpsContainer/RESButton

# Single Operation Buttons
@onready var simp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/SIMPButton
@onready var imp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/IMPButton
@onready var add_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/ADDButton
@onready var dm_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/DMButton
@onready var dneg_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/DNEGButton
@onready var dist_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/DISTButton
@onready var comm_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/COMMButton
@onready var assoc_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/ASSOCButton
@onready var idemp_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/IDEMPButton
@onready var abs_button: Button = $OperationsPanel/MainContainer/ButtonsScroll/SingleOpsContainer/ABSButton

# Game State
var available_premises: Array[BooleanExpression] = []
var selected_premises: Array[BooleanExpression] = []
var target_conclusion: String = ""
var selected_rule: String = ""
var premise_cards: Array[Control] = []
var target_reached_triggered: bool = false  # Prevent multiple target animations

# Animation State
var panel_height: float = 800.0
var panel_closed_height: float = 70.0
var is_animating_panel: bool = false
var current_tab: String = "double"  # "double" or "single"

# Parallax Background State
var bg_scroll_speed: float = 60.0  # Base scroll speed in pixels per second
var bg_offset1: float = 0.0
var bg_offset2: float = 0.0
var blur_shader = preload("res://src/shaders/motion_blur.gdshader")
var rocket_speed_multiplier: float = 1.0  # Syncs with rocket ship speed

# Black hole rotation
var black_hole_rotation_speed: float = PI / 5.0  # Radians per second (36 degrees/sec = 10 sec per full rotation)
var black_hole_target_pos: Vector2 = Vector2.ZERO # Original position to move to on failure

# Rocket Animation State
var rocket_base_x: float = 0.0  # Base X position (2/5 of width)
var rocket_bobbing_time: float = 0.0  # Time accumulator for bobbing
var rocket_target_offset: float = 0.0  # Target horizontal offset when speeding up
var rocket_current_offset: float = 0.0  # Current smooth offset
var rocket_wobble_offset: float = 0.0   # Wobble offset for damage
var is_failing: bool = false # Flag to stop normal animation during failure

# Signals for parent communication
signal rule_applied(result: BooleanExpression)
signal target_reached(result: BooleanExpression)
signal feedback_message(message: String, color: Color)
signal premise_selected(premise: String)  # For tutorial detection

# Rule definitions
enum RuleType {
	SINGLE,
	DOUBLE
}

var rule_definitions = {
	# Double operations (2-input rules)
	"MP": {"type": RuleType.DOUBLE, "name": "Modus Ponens"},
	"MT": {"type": RuleType.DOUBLE, "name": "Modus Tollens"},
	"HS": {"type": RuleType.DOUBLE, "name": "Hypothetical Syllogism"},
	"DS": {"type": RuleType.DOUBLE, "name": "Disjunctive Syllogism"},
	"CD": {"type": RuleType.DOUBLE, "name": "Constructive Dilemma"},
	"DN": {"type": RuleType.DOUBLE, "name": "Destructive Dilemma"},
	"CONJ": {"type": RuleType.DOUBLE, "name": "Conjunction"},
	"EQ": {"type": RuleType.DOUBLE, "name": "Equivalence"},
	"RES": {"type": RuleType.DOUBLE, "name": "Resolution"},

	# Single operations (1-input rules)
	"SIMP": {"type": RuleType.SINGLE, "name": "Simplification"},
	"IMP": {"type": RuleType.SINGLE, "name": "Implication"},
	"CONV": {"type": RuleType.SINGLE, "name": "Conversion"},
	"ADD": {"type": RuleType.SINGLE, "name": "Addition"},
	"DM": {"type": RuleType.SINGLE, "name": "De Morgan's Laws"},
	"DIST": {"type": RuleType.SINGLE, "name": "Distributivity"},
	"COMM": {"type": RuleType.SINGLE, "name": "Commutativity"},
	"ASSOC": {"type": RuleType.SINGLE, "name": "Associativity"},
	"IDEMP": {"type": RuleType.SINGLE, "name": "Idempotent Laws"},
	"ABS": {"type": RuleType.SINGLE, "name": "Absorption"},
	"DNEG": {"type": RuleType.SINGLE, "name": "Double Negation"}
}

func setup_dynamic_spacing() -> void:
	"""Set dynamic spacing between UI modules based on viewport height"""
	var viewport_height: float = get_viewport_rect().size.y

	# Calculate spacing as a percentage of viewport height
	# For 1280px height, use 10px spacing (0.78%)
	var dynamic_spacing: int = max(5, int(viewport_height * 0.0078))

	# Apply to work container
	if work_container:
		work_container.add_theme_constant_override("separation", dynamic_spacing)

func _ready() -> void:
	setup_dynamic_spacing()
	connect_rule_buttons()
	connect_addition_dialog()
	connect_toggle_buttons()
	initialize_parallax_background()
	initialize_rocket()
	start_black_hole_rotation()
	
	if black_hole:
		black_hole_target_pos = black_hole.position
		black_hole.position.x = -400 # Start far left

	# Initialize operations panel (starts collapsed)
	operations_panel.visible = true

	# Show double ops by default
	double_ops_container.visible = true
	single_ops_container.visible = false
	double_ops_tab.button_pressed = true
	single_ops_tab.button_pressed = false

	# Initialize particle gradients
	if flame_core:
		normal_flame_gradient = flame_core.color_ramp
		flame_core.emitting = true
	if smoke_trail:
		normal_smoke_gradient = smoke_trail.color_ramp
		smoke_trail.emitting = true
		
	# Create boost gradient (Reddish-Orange to Transparent)
	boost_gradient = Gradient.new()
	boost_gradient.add_point(0.0, Color(1, 0.27, 0, 1))
	boost_gradient.add_point(1.0, Color(1, 0.27, 0, 0))
	
	# Blue Gradient (5x)
	blue_gradient = Gradient.new()
	blue_gradient.add_point(0.0, Color(0, 0.5, 1, 1))
	blue_gradient.add_point(1.0, Color(0, 0.5, 1, 0))

	# Cyan Gradient (8x)
	cyan_gradient = Gradient.new()
	cyan_gradient.add_point(0.0, Color(0, 1, 1, 1))
	cyan_gradient.add_point(1.0, Color(0, 1, 1, 0))

	# Purple Gradient (10x)
	purple_gradient = Gradient.new()
	purple_gradient.add_point(0.0, Color(0.8, 0, 1, 1))
	purple_gradient.add_point(1.0, Color(0.8, 0, 1, 0))
	
	# Initialize particle size/speed
	set_rocket_speed(1.0)
	
	# Initialize combo timer color
	if combo_line:
		combo_line.color = Color.WHITE

	# Setup blur shader
	if space_bg1:
		space_bg1.material = ShaderMaterial.new()
		space_bg1.material.shader = blur_shader
	if space_bg2:
		space_bg2.material = ShaderMaterial.new()
		space_bg2.material.shader = blur_shader
	
	_init_styles()

func _init_styles() -> void:
	# Card Styles
	card_style_normal = StyleBoxFlat.new()
	card_style_normal.bg_color = Color(0.9, 0.9, 0.9)
	card_style_normal.border_color = Color(0.2, 0.2, 0.2)
	card_style_normal.set_border_width_all(2)
	card_style_normal.set_corner_radius_all(0)
	
	card_style_hover = card_style_normal.duplicate()
	card_style_hover.bg_color = Color(0.95, 0.95, 0.95)
	
	card_style_pressed = card_style_normal.duplicate()
	card_style_pressed.bg_color = Color(0.8, 0.8, 0.8)
	
	# Combo Bar Styles
	# Combo line uses scale.x animation (ColorRect approach)
	# No need for ProgressBar-specific theme overrides

func initialize_parallax_background() -> void:
	"""Initialize the parallax scrolling background"""
	if not space_bg1 or not space_bg2:
		return

	# Get the width of the background texture to calculate seamless looping
	await get_tree().process_frame  # Wait for layout to update
	var bg_width = space_bg1.size.x

	# Position the second background to the right of the first
	bg_offset1 = 0.0
	bg_offset2 = bg_width

	space_bg1.position.x = bg_offset1
	space_bg2.position.x = bg_offset2

	# Position asteroid particles at right edge
	var target_area = $WorkContainer/TargetArea as Control
	if target_area:
		var right_edge = target_area.size.x + 50
		if asteroid1: asteroid1.position.x = right_edge
		if asteroid2: asteroid2.position.x = right_edge
		if asteroid3: asteroid3.position.x = right_edge
		if asteroid4: asteroid4.position.x = right_edge
		if asteroid5: asteroid5.position.x = right_edge

func _process(delta: float) -> void:
	"""Update parallax background scrolling and rocket animation every frame"""
	update_parallax_background(delta)
	update_rocket_animation(delta)
	update_asteroid_speed()

	# Rotate black hole continuously
	if black_hole:
		black_hole.rotation += black_hole_rotation_speed * delta

	# Update combo timer
	if combo_count >= 2:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo_penalty()
		else:
			# Update bar width based on percentage
			if combo_line:
				combo_line.scale.x = combo_timer / combo_max_time

func update_parallax_background(delta: float) -> void:
	"""Scroll the background from right to left in a seamless loop"""
	if not space_bg1 or not space_bg2:
		return

	# Calculate effective scroll speed (base speed * rocket speed multiplier)
	var effective_speed = bg_scroll_speed * rocket_speed_multiplier

	# Move both backgrounds to the left
	bg_offset1 -= effective_speed * delta
	bg_offset2 -= effective_speed * delta

	# Get the width for seamless wrapping
	var bg_width = space_bg1.size.x

	# Wrap around when a background goes off-screen to the left
	if bg_offset1 <= -bg_width:
		bg_offset1 = bg_offset2 + bg_width
	if bg_offset2 <= -bg_width:
		bg_offset2 = bg_offset1 + bg_width

	# Apply the positions
	space_bg1.position.x = bg_offset1
	space_bg2.position.x = bg_offset2

func update_asteroid_speed() -> void:
	"""Update asteroid particle velocity based on ship speed"""
	# Base asteroid speed scales with rocket speed
	var base_speed = 80.0 * rocket_speed_multiplier
	var max_speed = base_speed * 1.8

	if asteroid1:
		asteroid1.initial_velocity_min = base_speed
		asteroid1.initial_velocity_max = max_speed
	if asteroid2:
		asteroid2.initial_velocity_min = base_speed
		asteroid2.initial_velocity_max = max_speed
	if asteroid3:
		asteroid3.initial_velocity_min = base_speed
		asteroid3.initial_velocity_max = max_speed
	if asteroid4:
		asteroid4.initial_velocity_min = base_speed
		asteroid4.initial_velocity_max = max_speed
	if asteroid5:
		asteroid5.initial_velocity_min = base_speed
		asteroid5.initial_velocity_max = max_speed

func set_rocket_speed(speed_multiplier: float) -> void:
	"""Update the background scroll speed based on rocket ship velocity"""
	# Base cruising speed derived from combo (persistent)
	var combo_cruising_speed = 1.0 + (float(combo_count) * 0.5)
	
	# Use MAX of decaying boost (speed_multiplier) and persistent combo speed
	var effective_base = max(speed_multiplier, combo_cruising_speed)

	# Apply artificial visual speed boost for higher impact (1x intervals)
	var visual_multiplier = effective_base
	if combo_count >= 5: visual_multiplier *= 3.0
	elif combo_count >= 4: visual_multiplier *= 2.5
	elif combo_count >= 3: visual_multiplier *= 2.0
	elif combo_count >= 2: visual_multiplier *= 1.5
	
	rocket_speed_multiplier = visual_multiplier
	
	# Update Motion Blur strength based on speed/combo
	var blur_strength: float = 0.0
	if combo_count >= 10: blur_strength = 0.12 # Intense
	elif combo_count >= 8: blur_strength = 0.08
	elif combo_count >= 5: blur_strength = 0.05
	elif combo_count >= 3: blur_strength = 0.02
	
	if space_bg1 and space_bg1.material:
		space_bg1.material.set_shader_parameter("strength", blur_strength)
	if space_bg2 and space_bg2.material:
		space_bg2.material.set_shader_parameter("strength", blur_strength)

	# Calculate target offset based on speed boost (visual)
	if speed_multiplier > 1.0:
		rocket_target_offset = min((speed_multiplier - 1.0) * 80.0, 150.0) # More movement
	else:
		rocket_target_offset = 0.0

	# Update Smoke Trail Logic - Drastic Changes
	if smoke_trail:
		if combo_count >= 10: # Purple (Laser Beam)
			smoke_trail.amount = 300
			smoke_trail.lifetime = 0.8
			smoke_trail.gravity = Vector2(0, 0)
			smoke_trail.spread = 0.0 # Perfectly straight
			smoke_trail.initial_velocity_min = 1500.0
			smoke_trail.initial_velocity_max = 1800.0
			smoke_trail.scale_amount_min = 5.0
			smoke_trail.scale_amount_max = 8.0
			
		elif combo_count >= 8: # Blue (High Speed Stream)
			smoke_trail.amount = 200
			smoke_trail.lifetime = 1.5
			smoke_trail.gravity = Vector2(-50, 0)
			smoke_trail.spread = 5.0 # Very tight
			smoke_trail.initial_velocity_min = 1000.0
			smoke_trail.initial_velocity_max = 1200.0
			smoke_trail.scale_amount_min = 10.0
			smoke_trail.scale_amount_max = 15.0

		elif combo_count >= 5: # Blue (Engine Boost)
			smoke_trail.amount = 150
			smoke_trail.lifetime = 1.0
			smoke_trail.gravity = Vector2(-100, 0)
			smoke_trail.spread = 15.0
			smoke_trail.initial_velocity_min = 600.0
			smoke_trail.initial_velocity_max = 800.0
			smoke_trail.scale_amount_min = 15.0
			smoke_trail.scale_amount_max = 25.0
			
		elif combo_count >= 3: # Red (Big Chaotic Puffs)
			smoke_trail.amount = 100
			smoke_trail.lifetime = 0.8
			smoke_trail.gravity = Vector2(-200, 0)
			smoke_trail.spread = 45.0 # Wide
			smoke_trail.initial_velocity_min = 400.0
			smoke_trail.initial_velocity_max = 500.0
			smoke_trail.scale_amount_min = 25.0
			smoke_trail.scale_amount_max = 40.0
			
		else: # Normal (Weak Drift)
			smoke_trail.amount = 40
			smoke_trail.lifetime = 0.4
			smoke_trail.gravity = Vector2(-100, 100) # Drifts down
			smoke_trail.spread = 30.0
			smoke_trail.initial_velocity_min = 200.0
			smoke_trail.initial_velocity_max = 300.0
			smoke_trail.scale_amount_min = 5.0
			smoke_trail.scale_amount_max = 10.0

	# Flame core logic
	if flame_core:
		var intensity_mult = min(float(combo_count) / 10.0, 1.5)
		flame_core.initial_velocity_min = 500.0 + (400.0 * intensity_mult)
		flame_core.initial_velocity_max = 700.0 + (500.0 * intensity_mult)
		flame_core.scale_amount_min = 6.0 + (6.0 * intensity_mult)
		flame_core.scale_amount_max = 12.0 + (8.0 * intensity_mult)
	
	# Update color
	update_particle_color()

func initialize_rocket() -> void:
	"""Initialize rocket position at 2/5 of the horizontal width, vertically centered"""
	if not rocket:
		return

	# Wait for layout to be calculated
	await get_tree().process_frame

	# Get the TargetArea size to calculate 2/5 position
	var target_area = rocket.get_parent() as Control
	if target_area:
		var area_width = target_area.size.x
		# Position at 2/5 (40%) of the width from left
		rocket_base_x = area_width * 0.4

		# Set initial position (will be centered due to anchors)
		# Offset from center to move to 2/5 position
		var center_to_base = rocket_base_x - (area_width * 0.5)
		rocket.offset_left = center_to_base - 50.0
		rocket.offset_right = center_to_base + 50.0

func update_rocket_animation(delta: float) -> void:
	"""Update rocket bobbing and speed-based movement"""
	if not rocket or is_failing:
		return

	# Accumulate time for bobbing animation
	rocket_bobbing_time += delta

	# Bobbing left-right motion using sine wave (subtle movement, ±15px)
	var bobbing_offset = sin(rocket_bobbing_time * 1.5) * 15.0

	# Smoothly interpolate current offset towards target offset (ease in/out)
	var ease_speed = 2.0  # Adjust for faster/slower easing
	rocket_current_offset = lerp(rocket_current_offset, rocket_target_offset, delta * ease_speed)

	# Get the TargetArea size to recalculate base position (in case of resize)
	var target_area = rocket.get_parent() as Control
	if target_area:
		var area_width = target_area.size.x
		rocket_base_x = area_width * 0.4
		var center_to_base = rocket_base_x - (area_width * 0.5)

		# Apply combined offset: base position + bobbing + speed offset + wobble
		var total_offset = center_to_base + bobbing_offset + rocket_current_offset + rocket_wobble_offset
		rocket.offset_left = total_offset - 50.0
		rocket.offset_right = total_offset + 50.0
		
		# Vertical Shaking
		var shake_y = 0.0
		var shake_intensity = 0.0
		if combo_count >= 10: shake_intensity = 5.0
		elif combo_count >= 8: shake_intensity = 4.0
		elif combo_count >= 5: shake_intensity = 3.0
		elif combo_count >= 3: shake_intensity = 1.0
		
		if shake_intensity > 0.0:
			shake_y = randf_range(-shake_intensity, shake_intensity)
			
		# Lower rocket by 50px
		var base_y_offset = 50.0
		rocket.offset_top = -50.0 + base_y_offset + shake_y
		rocket.offset_bottom = 50.0 + base_y_offset + shake_y

func increment_combo() -> void:
	combo_count += 1
	if combo_count < 2:
		combo_count = 2 # Start streak at 2x
	
	combo_timer = combo_max_time
	
	# Update UI
	if combo_container:
		combo_container.visible = true
		combo_label.text = str(combo_count) + "x"
		if not glow_tween or not glow_tween.is_valid():
			combo_label.modulate = Color.WHITE
		combo_line.color = Color.WHITE
		combo_line.scale.x = 1.0 # Reset bar to full width
		
		# Pop animation
		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Update Effects
	update_particle_color()
	update_combo_effects()
	
	# Update Speed
	var new_speed = 1.0 + (float(combo_count) * 0.1)
	set_rocket_speed(new_speed)
	
	# Notify GameplayScene to update global multiplier
	var root = get_tree().current_scene
	if root.has_method("increment_combo"):
		root.increment_combo()
	else:
		# Fallback search up the tree
		var p = get_parent()
		while p:
			if p.has_method("increment_combo"):
				p.increment_combo()
				break
			p = p.get_parent()

func reset_combo_penalty() -> void:
	if combo_count < 2:
		return # Already reset or low
		
	# Kill glow
	if glow_tween:
		glow_tween.kill()
		
	# Visual fail feedback
	if combo_container:
		combo_label.modulate = Color.RED
		combo_line.color = Color.RED
		
		var tween = create_tween()
		tween.tween_property(combo_container, "modulate:a", 0.0, 0.5)
		var on_finished = func(): 
			combo_container.visible = false
			combo_container.modulate.a = 1.0
			combo_count = 0 # Reset logic
			update_combo_effects()
		tween.finished.connect(on_finished)
	
	combo_count = 0 # Reset locally for UI, GameManager handles actual combo value
	set_rocket_speed(1.0)
	update_particle_color()
	
	# Delegate mistake recording and combo reset to GameManager
	GameManager.record_mistake()
	trigger_damage_wobble()

func restore_combo_state(count: int) -> void:
	combo_count = count
	# Update visuals
	if combo_container:
		if combo_count >= 2:
			combo_container.visible = true
			combo_label.text = str(combo_count) + "x"
	
	update_particle_color()
	update_combo_effects()
	
	var new_speed = 1.0 + (float(combo_count) * 0.1)
	set_rocket_speed(new_speed)

func trigger_damage_wobble() -> void:
	var tween = create_tween()
	# Move left quickly
	tween.tween_property(self, "rocket_wobble_offset", -30.0, 0.1).set_trans(Tween.TRANS_ELASTIC)
	# Shake/Wobble back to 0
	tween.tween_property(self, "rocket_wobble_offset", 10.0, 0.1)
	tween.tween_property(self, "rocket_wobble_offset", -5.0, 0.1)
	tween.tween_property(self, "rocket_wobble_offset", 0.0, 0.2).set_ease(Tween.EASE_OUT)

func update_particle_color() -> void:
	var target_gradient = normal_smoke_gradient
	
	if combo_count >= 10:
		target_gradient = purple_gradient
	elif combo_count >= 8:
		target_gradient = cyan_gradient
	elif combo_count >= 5:
		target_gradient = blue_gradient
	elif combo_count >= 3:
		target_gradient = boost_gradient
	
	if smoke_trail:
		smoke_trail.color_ramp = target_gradient
	if flame_core:
		flame_core.color_ramp = target_gradient

func update_combo_effects() -> void:
	if not combo_label: return
	
	# Reset all first if combo dropped
	if combo_count < 2:
		if combo_sparkles: combo_sparkles.emitting = false
		if combo_sparks: combo_sparks.emitting = false
		if combo_fire: combo_fire.emitting = false
		if glow_tween: glow_tween.kill()
		combo_label.modulate = Color.WHITE
		return
	
	# Stage 1: Sparkles (3x+)
	if combo_count >= 3:
		if combo_sparkles: combo_sparkles.emitting = true
		
	# Stage 2: Sparks (5x+)
	if combo_count >= 5:
		if combo_sparks: combo_sparks.emitting = true
		
	# Stage 3: Glow (8x+)
	if combo_count >= 8:
		if not glow_tween or not glow_tween.is_valid():
			glow_tween = create_tween().set_loops()
			glow_tween.tween_property(combo_label, "modulate", Color(1, 0.5, 0.5), 0.2)
			glow_tween.tween_property(combo_label, "modulate", Color(1, 1, 0.5), 0.2)
			glow_tween.tween_property(combo_label, "modulate", Color(0.5, 1, 1), 0.2)
			glow_tween.tween_property(combo_label, "modulate", Color(1, 0.5, 1), 0.2)
	
	# Stage 4: Fire (10x+)
	if combo_count >= 10:
		if combo_fire: combo_fire.emitting = true

func connect_rule_buttons() -> void:
	# Double operation buttons
	mp_button.pressed.connect(_on_rule_button_pressed.bind("MP"))
	mt_button.pressed.connect(_on_rule_button_pressed.bind("MT"))
	hs_button.pressed.connect(_on_rule_button_pressed.bind("HS"))
	ds_button.pressed.connect(_on_rule_button_pressed.bind("DS"))
	cd_button.pressed.connect(_on_rule_button_pressed.bind("CD"))
	dn_button.pressed.connect(_on_rule_button_pressed.bind("DN"))
	conj_button.pressed.connect(_on_rule_button_pressed.bind("CONJ"))
	eq_button.pressed.connect(_on_rule_button_pressed.bind("EQ"))
	res_button.pressed.connect(_on_rule_button_pressed.bind("RES"))

	# Single operation buttons
	simp_button.pressed.connect(_on_rule_button_pressed.bind("SIMP"))
	imp_button.pressed.connect(_on_rule_button_pressed.bind("IMP"))
	add_button.pressed.connect(_on_rule_button_pressed.bind("ADD"))
	dm_button.pressed.connect(_on_rule_button_pressed.bind("DM"))
	dist_button.pressed.connect(_on_rule_button_pressed.bind("DIST"))
	comm_button.pressed.connect(_on_rule_button_pressed.bind("COMM"))
	assoc_button.pressed.connect(_on_rule_button_pressed.bind("ASSOC"))
	idemp_button.pressed.connect(_on_rule_button_pressed.bind("IDEMP"))
	abs_button.pressed.connect(_on_rule_button_pressed.bind("ABS"))
	dneg_button.pressed.connect(_on_rule_button_pressed.bind("DNEG"))


func connect_addition_dialog() -> void:
	addition_dialog.expression_confirmed.connect(_on_addition_dialog_confirmed)
	addition_dialog.dialog_cancelled.connect(_on_addition_dialog_cancelled)

func connect_toggle_buttons() -> void:
	operations_close_button.pressed.connect(_on_operations_panel_toggle)
	double_ops_tab.pressed.connect(_on_double_tab_pressed)
	single_ops_tab.pressed.connect(_on_single_tab_pressed)

func _on_operations_panel_toggle() -> void:
	toggle_operations_panel()

func _on_double_tab_pressed() -> void:
	switch_to_tab("double")

func _on_single_tab_pressed() -> void:
	switch_to_tab("single")

func toggle_operations_panel() -> void:
	if is_animating_panel:
		return

	# Check if panel is currently closed
	var is_closed: bool = abs(operations_panel.offset_top + panel_closed_height) < 10.0

	if is_closed:
		open_operations_panel()
	else:
		close_operations_panel()

func open_operations_panel() -> void:
	if is_animating_panel:
		return

	is_animating_panel = true
	operations_close_button.text = "▼"

	# Animate from closed to open
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(operations_panel, "offset_top", -panel_height, 0.3)
	var on_finished = func(): is_animating_panel = false
	tween.finished.connect(on_finished)

func close_operations_panel() -> void:
	if is_animating_panel:
		return

	is_animating_panel = true
	operations_close_button.text = "▲"

	# Animate from open to closed
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(operations_panel, "offset_top", -panel_closed_height, 0.3)
	var on_finished = func(): is_animating_panel = false
	tween.finished.connect(on_finished)

func switch_to_tab(tab: String) -> void:
	current_tab = tab

	if tab == "double":
		double_ops_container.visible = true
		single_ops_container.visible = false
		double_ops_tab.button_pressed = true
		single_ops_tab.button_pressed = false
	else:
		double_ops_container.visible = false
		single_ops_container.visible = true
		double_ops_tab.button_pressed = false
		single_ops_tab.button_pressed = true

func set_premises_and_target(premises: Array[BooleanExpression], target: String) -> void:
	# Clean all premises before adding to inventory
	available_premises.clear()
	for premise in premises:
		var cleaned = clean_expression(premise)
		available_premises.append(cleaned)

	target_conclusion = target
	target_expression.text = "Prove: " + target
	adjust_target_font_size()
	create_premise_cards()

	# Reset target reached flag for new problem
	target_reached_triggered = false

# Extended version for Level 6 natural language problems
func set_premises_and_target_with_display(
	premises: Array[BooleanExpression],
	logical_target: String,
	display_target: String
) -> void:
	# Clean all premises before adding to inventory
	available_premises.clear()
	for premise in premises:
		var cleaned = clean_expression(premise)
		available_premises.append(cleaned)

	target_conclusion = logical_target  # Validate against this
	target_expression.text = "Prove: " + display_target  # Display this to player
	adjust_target_font_size()
	create_premise_cards()

	# Reset target reached flag for new problem
	target_reached_triggered = false

func adjust_target_font_size() -> void:
	"""Dynamically adjust font size to fit text within the chat bubble"""
	# Start with maximum font size
	var max_font_size = 30
	var min_font_size = 12
	var current_font_size = max_font_size

	# Get the available width/height from the parent container
	await get_tree().process_frame  # Wait for layout to update

	var available_size = target_expression.get_parent().size

	# Try decreasing font sizes until text fits
	while current_font_size >= min_font_size:
		target_expression.add_theme_font_size_override("font_size", current_font_size)
		await get_tree().process_frame  # Let label recalculate size

		# Check if text fits within bounds
		var text_size = target_expression.get_minimum_size()
		if text_size.x <= available_size.x and text_size.y <= available_size.y:
			break

		current_font_size -= 2  # Decrease by 2px each iteration

func create_premise_cards() -> void:
	# Clear existing cards
	for card in premise_cards:
		card.queue_free()
	premise_cards.clear()

	# Create new cards
	for i in range(available_premises.size()):
		var premise = available_premises[i]
		var card = create_premise_card(premise, i)
		premise_grid.add_child(card)
		premise_cards.append(card)

func create_premise_card(premise: BooleanExpression, index: int) -> Control:
	var card = Button.new()
	# Remove numbering - just show the premise expression
	card.text = premise.expression_string

	# Use reasonable minimum size - let the theme handle the rest
	card.custom_minimum_size = Vector2(280, 70)
	card.toggle_mode = true
	card.alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Load MuseoSansRounded500 font to match Phase1
	var museo_font = load("res://assets/fonts/MuseoSansRounded500.otf")
	card.add_theme_font_override("font", museo_font)

	# Increased font size from 20 to 28 for better readability
	card.add_theme_font_size_override("font_size", 28)

	# Use default theme styling - don't override colors or styleboxes
	# This allows the Wenrexa theme to properly style the buttons

	card.pressed.connect(_on_premise_card_pressed.bind(premise, card))
	return card

func _on_premise_card_pressed(premise: BooleanExpression, card: Button) -> void:
	# Only allow premise selection if a rule is selected
	if selected_rule.is_empty():
		card.button_pressed = false  # Reset button state
		show_feedback("Select operation first", Color.ORANGE, false)
		# Don't auto-open remotes - let user choose which one
		return

	if card.button_pressed:
		# Select premise
		if premise not in selected_premises:
			selected_premises.append(premise)
			# Emit signal for tutorial detection
			premise_selected.emit(premise.expression_string)
			# spawn_premise_explosion(card) # Removed per user request
	else:
		# Deselect premise
		if premise in selected_premises:
			selected_premises.erase(premise)

	# Check if we can apply the selected rule
	check_rule_application()

func spawn_premise_explosion(card: Control) -> void:
	"""Create an explosion particle effect centered on a premise card"""
	if not card:
		return

	# Create particle emitter
	var explosion = CPUParticles2D.new()

	# Position at card center in global coordinates
	# CPUParticles2D with local_coords = false uses global space, so we can use global position directly
	var card_center = card.global_position + card.size / 2
	explosion.global_position = card_center

	# Explosion settings
	explosion.amount = 30
	explosion.lifetime = 0.8
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	explosion.local_coords = false

	# Radial burst
	explosion.direction = Vector2(0, 0)
	explosion.spread = 180.0
	explosion.gravity = Vector2(0, 200)
	explosion.initial_velocity_min = 100.0
	explosion.initial_velocity_max = 300.0

	# Particle appearance
	explosion.scale_amount_min = 8.0
	explosion.scale_amount_max = 15.0

	# Orange/yellow colors for explosion
	var explosion_gradient = Gradient.new()
	explosion_gradient.add_point(0.0, Color(1.0, 0.8, 0.2, 1.0))  # Bright yellow-orange
	explosion_gradient.add_point(0.5, Color(1.0, 0.4, 0.0, 0.8))  # Orange
	explosion_gradient.add_point(1.0, Color(0.5, 0.2, 0.0, 0.0))  # Dark orange fade
	explosion.color_ramp = explosion_gradient

	# Add to scene
	add_child(explosion)
	explosion.emitting = true

	# Auto-cleanup after lifetime
	var on_timeout = func():
		explosion.queue_free()
	get_tree().create_timer(explosion.lifetime + 0.1).timeout.connect(on_timeout)

func _on_rule_button_pressed(rule: String) -> void:
	# If clicking the same rule that's already selected, deselect everything
	if selected_rule == rule:
		clear_selections()
		show_feedback("Deselected", Color.WHITE, false)
		return

	# Clear previous rule selection
	clear_rule_selection()

	selected_rule = rule
	var rule_def = rule_definitions[rule]

	var premise_count = "1 premise" if rule_def.type == RuleType.SINGLE else "2 premises"
	show_feedback(rule_def.name + " - Select " + premise_count, Color.YELLOW, false)

	# Highlight the selected button
	highlight_rule_button(rule)

	# Close operations panel after selecting a rule
	close_operations_panel()

func check_rule_application() -> void:
	if selected_rule.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]
	var required_count = 1 if rule_def.type == RuleType.SINGLE else 2

	if selected_premises.size() == required_count:
		# Special handling for Addition rule - needs user input via dialog
		if selected_rule == "ADD":
			addition_dialog.show_dialog(selected_premises[0])
			return

		apply_rule()

func clean_expression(expr: BooleanExpression) -> BooleanExpression:
	# DON'T auto-clean! Preserve structure so users can see what they built
	# Users can explicitly use PAREN_REMOVE button if they want to clean up
	# This preserves expressions like (P ∧ Q) instead of converting to P ∧ Q
	return expr

	# OLD AUTO-CLEAN CODE (disabled to preserve structure):
	# var cleaned = BooleanLogicEngine.apply_parenthesis_removal(expr)
	# if cleaned.is_valid:
	#	return cleaned
	# return expr

func apply_rule() -> void:
	if selected_rule.is_empty() or selected_premises.is_empty():
		return

	var rule_def = rule_definitions[selected_rule]

	# Check if this is a multi-result operation
	var multi_results = apply_logical_rule_multi(selected_rule, selected_premises)

	if multi_results != null and multi_results.size() > 1:
		# Multi-result operation - add valid results to inventory (after cleaning)
		var added_results: Array = []
		for result in multi_results:
			if result.is_valid:
				var cleaned_result = clean_expression(result)
				available_premises.append(cleaned_result)
				added_results.append(cleaned_result)

		# Only proceed if at least one result was added
		if added_results.size() > 0:
			create_premise_cards()
			ProgressTracker.record_operation_used(rule_def.name, true)
			clear_selections()
			
			increment_combo()

			var result_text = str(added_results.size()) + " result" + ("s" if added_results.size() > 1 else "")
			show_feedback("✓ " + rule_def.name + ": " + result_text, Color.GREEN, false)

			# Emit signal for each valid result
			for cleaned_result in added_results:
				rule_applied.emit(cleaned_result)
				# Check if any result is the target (only trigger once)
				if not target_reached_triggered and cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
					target_reached_triggered = true
					show_feedback("✓ Proof complete!", Color.CYAN)
					# Find the card that matches the result and animate it
					animate_target_reached(cleaned_result)
					# Emit signal after animation delay
					var on_timeout = func(): target_reached.emit(cleaned_result)
					get_tree().create_timer(1.0).timeout.connect(on_timeout)
		else:
			# No valid results - show error
			clear_selections()
			show_feedback("✗ No valid results", Color.RED, false)
			# Penalty: lose fuel and reset combo
			reset_combo_penalty()
			# Don't auto-open remotes on failure
		return

	# Single-result operation (original behavior)
	var result = apply_logical_rule(selected_rule, selected_premises)

	if result != null and result.is_valid:
		# Clean the result before adding to inventory
		var cleaned_result = clean_expression(result)

		# Add result to inventory
		available_premises.append(cleaned_result)
		create_premise_cards()

		# Track successful operation usage
		ProgressTracker.record_operation_used(rule_def.name, true)

		# Clear selections
		clear_selections()
		
		increment_combo()

		show_feedback("✓ " + rule_def.name, Color.GREEN, false)
		rule_applied.emit(cleaned_result)

		# Check if target is reached (only trigger once)
		if not target_reached_triggered and cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
			target_reached_triggered = true
			show_feedback("✓ Proof complete!", Color.CYAN)
			# Find the card that matches the result and animate it
			animate_target_reached(cleaned_result)
			# Emit signal after animation delay
			get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
	else:
		# Clear selections when rule fails
		clear_selections()
		show_feedback("✗ Cannot apply " + rule_def.name, Color.RED, false)
		# Penalty: lose fuel and reset combo
		reset_combo_penalty()
		# Don't auto-open remotes on failure

func apply_logical_rule_multi(rule: String, premises: Array[BooleanExpression]) -> Array:
	# Returns an array of results for operations that can produce multiple statements
	# Returns empty array if this is not a multi-result operation
	match rule:
		"SIMP":  # Simplification: P∧Q ⊢ P and Q (both)
			if premises.size() == 1:
				var results = BooleanLogicEngine.apply_simplification_both(premises)
				if results.size() == 2:
					return results
			return []
		"IMP":  # Biconditional to Implications: P↔Q ⊢ [P→Q, Q→P] (both)
			if premises.size() == 1:
				var results = BooleanLogicEngine.apply_biconditional_to_implications_both(premises[0])
				if results.size() == 2:
					return results
			return []
		"CONV":  # Biconditional to Equivalence: P↔Q ⊢ [P∧Q, ¬P∧¬Q] (both)
			if premises.size() == 1:
				var results = BooleanLogicEngine.apply_biconditional_to_equivalence_both(premises[0])
				if results.size() == 2:
					return results
			return []
		_:
			# Not a multi-result operation
			return []

func apply_logical_rule(rule: String, premises: Array[BooleanExpression]) -> BooleanExpression:
	# Use actual BooleanLogicEngine functions to apply logical rules
	match rule:
		# Double operation rules (require 2 premises)
		"MP":  # Modus Ponens: P→Q, P ⊢ Q
			return BooleanLogicEngine.apply_modus_ponens(premises)
		"MT":  # Modus Tollens: P→Q, ¬Q ⊢ ¬P
			return BooleanLogicEngine.apply_modus_tollens(premises)
		"HS":  # Hypothetical Syllogism: P→Q, Q→R ⊢ P→R
			return BooleanLogicEngine.apply_hypothetical_syllogism(premises)
		"DS":  # Disjunctive Syllogism: P∨Q, ¬P ⊢ Q
			return BooleanLogicEngine.apply_disjunctive_syllogism(premises)
		"CD":  # Constructive Dilemma
			return BooleanLogicEngine.apply_constructive_dilemma(premises)
		"DN":  # Destructive Dilemma
			return BooleanLogicEngine.apply_destructive_dilemma(premises)
		"CONJ":  # Conjunction: P, Q ⊢ P∧Q
			return BooleanLogicEngine.apply_conjunction(premises)

		# Single operation rules (require 1 premise)
		"SIMP":  # Simplification: P∧Q ⊢ P
			return BooleanLogicEngine.apply_simplification(premises)
		"DM":  # De Morgan's Laws: ¬(P∧Q) ⊢ ¬P∨¬Q or ¬(P∨Q) ⊢ ¬P∧¬Q
			if premises.size() == 1:
				var premise = premises[0]
				var normalized = premise.normalized_string
				# Check if it's a negated expression: ¬(...)
				if normalized.begins_with("¬(") and normalized.ends_with(")"):
					# Extract the inner expression
					var inner = normalized.substr(2, normalized.length() - 3).strip_edges()
					var inner_expr = BooleanExpression.new(inner)
					if inner_expr.is_conjunction():
						return BooleanLogicEngine.apply_de_morgan_and(premise)
					elif inner_expr.is_disjunction():
						return BooleanLogicEngine.apply_de_morgan_or(premise)
			return BooleanExpression.new("")
		"DOUBLE_NEG":  # Double Negation: ¬¬P ⊢ P
			if premises.size() == 1:
				return BooleanLogicEngine.apply_double_negation(premises[0])
			return BooleanExpression.new("")

		# Biconditional rules
		"IMP":  # Biconditional to Implications: P↔Q ⊢ (P→Q)∧(Q→P)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_biconditional_to_implications(premises[0])
			return BooleanExpression.new("")
		"CONV":  # Biconditional to Equivalence: P↔Q ⊢ (P∧Q)∨(¬P∧¬Q)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_biconditional_to_equivalence(premises[0])
			return BooleanExpression.new("")

		# XOR rules
		"XOR_ELIM":  # XOR Elimination: P⊕Q ⊢ (P∨Q)∧¬(P∧Q)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_xor_elimination(premises[0])
			return BooleanExpression.new("")

		# New double operation rules
		"EQ":  # Equivalence: P↔Q, P ⊢ Q (or similar equivalence rule)
			if premises.size() == 2:
				return BooleanLogicEngine.apply_equivalence(premises)
			return BooleanExpression.new("")
		"RES":  # Resolution: P∨Q, ¬P∨R ⊢ Q∨R
			if premises.size() == 2:
				return BooleanLogicEngine.apply_resolution(premises)
			return BooleanExpression.new("")

		# Double negation (moved to single operations section)
		"DNEG":  # Double Negation: ¬¬P ⊢ P
			if premises.size() == 1:
				return BooleanLogicEngine.apply_double_negation(premises[0])
			return BooleanExpression.new("")

		# Single operation rules - now fully implemented
		"DIST":  # Distributivity Laws: A∧(B∨C) ≡ (A∧B)∨(A∧C)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_distributivity(premises[0])
			return BooleanExpression.new("")
		"COMM":  # Commutativity Laws: A∧B ≡ B∧A
			if premises.size() == 1:
				return BooleanLogicEngine.apply_commutativity(premises[0])
			return BooleanExpression.new("")
		"ASSOC":  # Associativity Laws: (A∧B)∧C ≡ A∧(B∧C)
			if premises.size() == 1:
				return BooleanLogicEngine.apply_associativity(premises[0])
			return BooleanExpression.new("")
		"IDEMP":  # Idempotent Laws: A∧A ≡ A
			if premises.size() == 1:
				return BooleanLogicEngine.apply_idempotent(premises[0])
			return BooleanExpression.new("")
		"ABS":  # Absorption Laws: A∧(A∨B) ≡ A
			if premises.size() == 1:
				return BooleanLogicEngine.apply_absorption(premises[0])
			return BooleanExpression.new("")
		"NEG":  # Negation Laws: A∧¬A ≡ FALSE
			if premises.size() == 1:
				return BooleanLogicEngine.apply_negation_laws(premises[0])
			return BooleanExpression.new("")
		"TAUT":  # Tautology Laws: A∨TRUE ≡ TRUE
			if premises.size() == 1:
				return BooleanLogicEngine.apply_tautology_laws(premises[0])
			return BooleanExpression.new("")
		"CONTR":  # Contradiction Laws: A∧FALSE ≡ FALSE
			if premises.size() == 1:
				return BooleanLogicEngine.apply_contradiction_laws(premises[0])
			return BooleanExpression.new("")
		"PAREN_REMOVE":  # Remove Parentheses: (P) ≡ P
			if premises.size() == 1:
				return BooleanLogicEngine.apply_parenthesis_removal(premises[0])
			return BooleanExpression.new("")

		# Other single operation rules (special cases)
		"ADD":  # Addition: P ⊢ P∨Q (needs additional expression)
			# For ADD rule, we need to ask user for the additional expression
			# For now, return empty to indicate this rule needs special handling
			return BooleanExpression.new("")
		_:
			return BooleanExpression.new("")

func animate_target_reached(result: BooleanExpression) -> void:
	"""Animate the newly created winning card flying into the target box with a flash effect"""
	# Find the LAST (most recently added) card that matches the result
	var winning_card: Control = null
	for i in range(premise_cards.size() - 1, -1, -1):  # Search backwards
		var card = premise_cards[i]
		var button = card as Button
		if button and button.text.contains(result.expression_string):
			winning_card = card
			break

	if not winning_card:
		return

	# Play success sound
	AudioManager.play_logic_success()

	# Create green glow effect
	var tween = create_tween()
	tween.set_loops(3)  # Pulse 3 times
	tween.tween_property(winning_card, "modulate", Color.GREEN, 0.3)
	tween.tween_property(winning_card, "modulate", Color.WHITE, 0.3)

	# Show score popup at the card's position after glow animation
	var on_finished = func():
		winning_card.modulate = Color.GREEN  # Keep final green color
		show_score_popup_at_card(winning_card)
	tween.finished.connect(on_finished)


func show_feedback(message: String, color: Color, emit_to_parent: bool = true) -> void:
	"""Show shortened feedback at the bottom of the premise box"""
	feedback_label.text = message
	feedback_label.modulate = color

	# Emit to parent for any global handling if needed
	if emit_to_parent:
		feedback_message.emit(message, color)

	# Auto-clear feedback after 3 seconds
	var on_timeout = func():
		if feedback_label.text == message:  # Only clear if message hasn't changed
			feedback_label.text = ""
	get_tree().create_timer(3.0).timeout.connect(on_timeout)

func apply_fuel_penalty() -> void:
	"""Records a mistake and triggers visual penalty effects."""
	# Delegate mistake recording to GameManager
	GameManager.record_mistake()

func show_score_popup_at_card(card: Control) -> void:
	"""Show speed boost notification at the card's position"""
	if not score_display:
		return

	# Get card center position
	var card_pos: Vector2 = card.global_position + card.size / 2

	# Show speed boost popup animation at card position
	# (Score is now gained continuously over time, not in chunks)
	# This popup now just shows the speed boost being applied
	var gameplay_scene = get_parent().get_parent()
	if gameplay_scene and gameplay_scene.has_method("add_speed_boost"):
		# Clean solution gives speed boost
		gameplay_scene.add_speed_boost(2.0, false)

		# Show visual feedback
		show_feedback("🚀 Speed Boost Activated!", Color.CYAN, true)

func clear_selections() -> void:
	selected_premises.clear()
	selected_rule = ""

	# Reset card states
	for card in premise_cards:
		var button = card as Button
		if button:
			button.button_pressed = false

	# Clear rule button highlights
	clear_rule_selection()

func clear_rule_selection() -> void:
	# Reset all rule button colors
	for button in get_all_rule_buttons():
		button.modulate = Color.WHITE

func get_all_rule_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	# Add all rule buttons
	buttons.append_array([mp_button, mt_button, hs_button, ds_button, cd_button, dn_button, conj_button, eq_button, res_button])
	buttons.append_array([simp_button, imp_button, add_button, dm_button, dneg_button, dist_button, comm_button, assoc_button, idemp_button, abs_button])
	return buttons

func highlight_rule_button(rule: String) -> void:
	var button = get_rule_button(rule)
	if button:
		button.modulate = Color.YELLOW

func get_rule_button(rule: String) -> Button:
	match rule:
		"MP": return mp_button
		"MT": return mt_button
		"HS": return hs_button
		"DS": return ds_button
		"CD": return cd_button
		"DN": return dn_button
		"IMP": return imp_button
		"EQ": return eq_button
		"RES": return res_button
		"SIMP": return simp_button
		"CONJ": return conj_button
		"ADD": return add_button
		"DM": return dm_button
		"DIST": return dist_button
		"COMM": return comm_button
		"ASSOC": return assoc_button
		"IDEMP": return idemp_button
		"ABS": return abs_button
		"DNEG": return dneg_button
		_: return null


func add_premise_to_inventory(premise: BooleanExpression) -> void:
	# Clean expression before adding to inventory
	var cleaned_premise = clean_expression(premise)
	available_premises.append(cleaned_premise)
	create_premise_cards()

func _on_addition_dialog_confirmed(expr_text: String) -> void:
	# User confirmed the Addition dialog with an expression
	if selected_premises.size() != 1:
		show_feedback("✗ No premise selected", Color.RED, false)
		clear_selections()
		return

	# Create expression from user input
	var additional_expr = BooleanLogicEngine.create_expression(expr_text)

	if not additional_expr.is_valid:
		show_feedback("✗ Invalid expression", Color.RED, false)
		return

	# Apply addition rule: P ⊢ P ∨ Q
	var result = BooleanLogicEngine.apply_addition([selected_premises[0]], additional_expr)

	if result.is_valid:
		# Clean the result before adding to inventory
		var cleaned_result = clean_expression(result)

		# Add result to inventory
		available_premises.append(cleaned_result)
		create_premise_cards()

		# Track successful operation usage
		ProgressTracker.record_operation_used("Addition", true)

		# Clear selections
		clear_selections()
		
		increment_combo()

		show_feedback("✓ Addition", Color.GREEN, false)
		rule_applied.emit(cleaned_result)
		
		# Play multiplier increase sound (on GameplayScene)
		var root = get_tree().current_scene # Assumes GameplayScene is root
		if root.has_method("play_multiplier_increase_sound"):
			root.play_multiplier_increase_sound(combo_count)

		# Check if target is reached (only trigger once)
		if not target_reached_triggered and cleaned_result.expression_string.strip_edges() == target_conclusion.strip_edges():
			target_reached_triggered = true
			show_feedback("✓ Proof complete!", Color.CYAN)
			# Find the card that matches the result and animate it
			animate_target_reached(cleaned_result)
			# Emit signal after animation delay
			get_tree().create_timer(1.0).timeout.connect(func(): target_reached.emit(cleaned_result))
	else:
		clear_selections()
		show_feedback("✗ Addition failed", Color.RED, false)
		# Penalty: lose fuel and reset combo
		reset_combo_penalty()

func _on_addition_dialog_cancelled() -> void:
	# User cancelled the Addition dialog
	clear_selections()
	feedback_message.emit("Addition cancelled", Color.WHITE)

func trigger_failure_effect() -> void:
	# Stop scrolling gradually - background slows and stops
	var tween = create_tween()
	tween.tween_property(self, "rocket_speed_multiplier", 0.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Stop flames and smoke gradually (engine failure)
	if flame_core:
		tween.parallel().tween_property(flame_core, "amount", 0, 1.0)
		tween.parallel().tween_callback(func(): flame_core.emitting = false).set_delay(1.0)
	if smoke_trail:
		tween.parallel().tween_property(smoke_trail, "amount", 0, 1.0)
		tween.parallel().tween_callback(func(): smoke_trail.emitting = false).set_delay(1.0)

	# Stop asteroid particles
	tween.parallel().tween_callback(func():
		if asteroid1: asteroid1.emitting = false
		if asteroid2: asteroid2.emitting = false
		if asteroid3: asteroid3.emitting = false
		if asteroid4: asteroid4.emitting = false
		if asteroid5: asteroid5.emitting = false
	)

	is_failing = true
	
	# Rocket gets pulled into the black hole (center)
	# Calculate center position relative to parent (assuming siblings)
	# Use black_hole_target_pos as the destination
	var target_pos = black_hole_target_pos + (black_hole.size * black_hole.scale * 0.5) - (rocket.size * rocket.scale * 0.5)
	
	# Animate black hole moving right (catching up)
	tween.parallel().tween_property(black_hole, "position", black_hole_target_pos, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Gradually accelerate toward the black hole
	tween.tween_property(rocket, "position", target_pos, 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Rocket rotates as it's pulled in (losing control)
	tween.parallel().tween_property(rocket, "rotation", rocket.rotation + PI * 2, 3.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Rocket shrinks as it approaches the black hole (perspective)
	tween.parallel().tween_property(rocket, "scale", Vector2(0.3, 0.3), 3.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Fade out as it disappears into the black hole
	tween.parallel().tween_property(rocket, "modulate:a", 0.0, 2.5).set_delay(0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	# Black hole grows to devour the entire screen
	tween.tween_property(black_hole, "scale", Vector2(10.0, 10.0), 2.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Create fade to black overlay
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 0.0
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.z_index = 1000
	add_child(fade_overlay)

	# Fade to black
	tween.parallel().tween_property(fade_overlay, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func start_black_hole_rotation() -> void:
	"""Initialize black hole rotation (actual rotation happens in _process)"""
	if black_hole:
		black_hole.rotation = 0.0
		print("Black hole initialized for rotation: ", black_hole.name)
	else:
		print("ERROR: Black hole not found!")