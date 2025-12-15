extends Control

const ProgressTrackerTypes = preload("res://src/managers/ProgressTrackerTypes.gd")
const GradeBadge = preload("res://src/ui/GradeBadge.gd")
const FONT_HEAVY = preload("res://assets/fonts/MuseoSansRounded900.otf")

@onready var content_container: VBoxContainer = $GameOverPanel/GameOverContainer/ContentContainer

# Store leaderboard qualification status
var qualifies_for_leaderboard: bool = false
var leaderboard_button: Button = null

func _ready() -> void:
	# Create fade overlay for fade-in transition
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.modulate.a = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.z_index = 100
	add_child(fade_overlay)

	# Fade in from black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 1.0)
	await tween.finished
	fade_overlay.queue_free()

	# Start game over music after fade-in
	AudioManager.start_game_over_music()

	# Connect to game manager for state changes
	GameManager.game_state_changed.connect(_on_game_state_changed)

	# Check for leaderboard qualification FIRST
	await check_leaderboard_qualification()

func _on_play_again_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.reset_game()
	SceneManager.change_scene("res://src/scenes/GameplayScene.tscn")
	GameManager.start_new_game()

func _on_main_menu_button_pressed() -> void:
	AudioManager.play_button_click()
	GameManager.reset_game()
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	# Handle any state changes if needed
	pass

func add_progress_context() -> void:
	var stats = ProgressTracker.statistics
	var current_score = GameManager.current_score

	# Add progress information labels
	var progress_info = VBoxContainer.new()
	progress_info.name = "ProgressInfo"
	progress_info.add_theme_constant_override("separation", 15)
	content_container.add_child(progress_info)

	# High Score Display - Emphasized
	var high_score_section = VBoxContainer.new()
	high_score_section.add_theme_constant_override("separation", 10)
	progress_info.add_child(high_score_section)

	# Current Score - Emphasized
	var current_score_label = RichTextLabel.new()
	current_score_label.bbcode_enabled = true
	# Score first (BIG), then label (smaller)
	current_score_label.text = "[center][font_size=96]" + str(current_score) + "[/font_size]\n[font_size=32]FINAL SCORE[/font_size][/center]"
	current_score_label.add_theme_font_override("normal_font", FONT_HEAVY)
	current_score_label.add_theme_font_override("bold_font", FONT_HEAVY)
	current_score_label.add_theme_color_override("default_color", Color.BLACK)
	current_score_label.fit_content = true
	current_score_label.scroll_active = false
	current_score_label.custom_minimum_size = Vector2(400, 150)
	high_score_section.add_child(current_score_label)

	# Local High Score - using RichTextLabel for bold support
	var local_high_score_label = RichTextLabel.new()
	local_high_score_label.bbcode_enabled = true
	local_high_score_label.text = "[center][b]Local Best: " + str(stats.high_score_overall) + "[/b][/center]"
	local_high_score_label.add_theme_font_size_override("normal_font_size", 32)
	local_high_score_label.add_theme_font_size_override("bold_font_size", 32)
	local_high_score_label.fit_content = true
	local_high_score_label.scroll_active = false
	local_high_score_label.custom_minimum_size = Vector2(400, 50)

	# High Score Comparison Message
	var high_score_comparison = Label.new()
	high_score_comparison.add_theme_font_size_override("font_size", 28)
	high_score_comparison.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Check if this is a high score (allowing for == if stats already updated)
	if current_score >= stats.high_score_overall and current_score > 0:
		high_score_comparison.text = "🎉 NEW LOCAL HIGH SCORE! 🎉"
		high_score_comparison.modulate = Color(0.9, 0.6, 0.0, 1)  # Gold
		local_high_score_label.modulate = Color(0.9, 0.6, 0.0, 1)  # Gold for new high score
		
		# RGB Glow Animation for Current Score
		var tween = create_tween().set_loops()
		tween.tween_property(current_score_label, "modulate", Color(1, 0.2, 0.2), 0.5) # Red
		tween.tween_property(current_score_label, "modulate", Color(0.2, 1, 0.2), 0.5) # Green
		tween.tween_property(current_score_label, "modulate", Color(0.2, 0.2, 1), 0.5) # Blue
		tween.tween_property(current_score_label, "modulate", Color(1, 1, 0.2), 0.5)   # Yellow
		
	elif current_score > stats.high_score_overall * 0.8:
		high_score_comparison.text = "Great performance! Close to your best!"
		high_score_comparison.modulate = Color.BLACK
		local_high_score_label.modulate = Color.BLACK
	else:
		high_score_comparison.text = "Keep trying to beat your best!"
		high_score_comparison.modulate = Color.BLACK
		local_high_score_label.modulate = Color.BLACK

	high_score_section.add_child(local_high_score_label)
	high_score_section.add_child(high_score_comparison)
	
	# Spacer below local best
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	progress_info.add_child(spacer)

func get_recent_achievements() -> Array[String]:
	# Get achievements that were unlocked in recent sessions
	# This is a simplified version - could be enhanced to track "new" achievements
	var recent_sessions = ProgressTracker.get_recent_sessions(1)
	if recent_sessions.size() > 0:
		# For now, just return the latest achievement names if any exist
		var stats = ProgressTracker.statistics
		if stats.achievements_unlocked.size() > 0:
			var latest_achievement = stats.achievements_unlocked[-1]
			return [ProgressTracker.get_achievement_name(latest_achievement)]
	return []

func check_leaderboard_qualification() -> void:
	var current_score = GameManager.current_score

	# Always show progress context first
	# If score is 0, skip leaderboard check
	if current_score <= 0:
		qualifies_for_leaderboard = false
		add_progress_context()
		return

	# Show progress context immediately (with grade)
	add_progress_context()

	# Add checking message at the bottom
	var game_over_container = $GameOverPanel/GameOverContainer
	var checking_label = Label.new()
	checking_label.text = "Checking leaderboard..."
	checking_label.add_theme_font_size_override("font_size", 20)
	checking_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checking_label.modulate = Color(0.5, 0.5, 0.5, 1)
	game_over_container.add_child(checking_label)

	# Check if score qualifies for top 10
	var qualifies = await SupabaseService.check_qualifies_for_top_10(current_score)

	# Remove checking label
	checking_label.queue_free()

	# Store qualification status
	qualifies_for_leaderboard = qualifies

	# Add leaderboard button if qualified
	if qualifies:
		add_leaderboard_button()

func add_leaderboard_button() -> void:
	# Show separate popup for leaderboard submission
	show_leaderboard_popup()

func show_leaderboard_popup() -> void:
	# Create popup overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	add_child(overlay)

	# Create center container for proper centering
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)

	# Create popup panel
	var popup_panel = PanelContainer.new()
	popup_panel.custom_minimum_size = Vector2(650, 450)

	# Create StyleBox for popup
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.95, 0.95, 0.95, 1)
	style_box.border_width_left = 3
	style_box.border_width_top = 3
	style_box.border_width_right = 3
	style_box.border_width_bottom = 3
	style_box.border_color = Color(0.9, 0.6, 0.0, 1)  # Gold border
	style_box.corner_radius_top_left = 20
	style_box.corner_radius_top_right = 20
	style_box.corner_radius_bottom_right = 20
	style_box.corner_radius_bottom_left = 20
	style_box.shadow_size = 10
	style_box.shadow_offset = Vector2(5, 5)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	popup_panel.add_theme_stylebox_override("panel", style_box)
	center_container.add_child(popup_panel)

	# Create content container
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	popup_panel.add_child(content)

	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	popup_panel.add_child(margin)

	var inner_content = VBoxContainer.new()
	inner_content.add_theme_constant_override("separation", 30)
	inner_content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(inner_content)

	# Celebration title - EMPHASIZED
	var title_label = RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.text = "[center][b]🎉 CONGRATULATIONS! 🎉[/b][/center]"
	title_label.add_theme_font_size_override("normal_font_size", 52)
	title_label.add_theme_font_size_override("bold_font_size", 52)
	title_label.add_theme_color_override("default_color", Color(0.9, 0.6, 0.0, 1))  # Gold
	title_label.fit_content = true
	title_label.scroll_active = false
	title_label.custom_minimum_size = Vector2(550, 80)
	inner_content.add_child(title_label)

	# Message - EMPHASIZED
	var message_label = RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.text = "[center][b]You made the TOP 10![/b]\n\nWould you like to submit your score\nto the leaderboard?[/center]"
	message_label.add_theme_font_size_override("normal_font_size", 30)
	message_label.add_theme_font_size_override("bold_font_size", 32)
	message_label.add_theme_color_override("default_color", Color.BLACK)
	message_label.fit_content = true
	message_label.scroll_active = false
	message_label.custom_minimum_size = Vector2(550, 150)
	inner_content.add_child(message_label)

	# Button container
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_content.add_child(button_container)

	# Submit button
	var submit_button = Button.new()
	submit_button.custom_minimum_size = Vector2(200, 70)
	submit_button.add_theme_font_size_override("font_size", 28)
	submit_button.text = "SUBMIT"
	submit_button.pressed.connect(func():
		AudioManager.play_button_click()
		overlay.queue_free()
		transition_to_high_score_entry()
	)
	button_container.add_child(submit_button)

	# Skip button
	var skip_button = Button.new()
	skip_button.custom_minimum_size = Vector2(200, 70)
	skip_button.add_theme_font_size_override("font_size", 28)
	skip_button.text = "SKIP"
	skip_button.pressed.connect(func():
		AudioManager.play_button_click()
		overlay.queue_free()
	)
	button_container.add_child(skip_button)

func _on_submit_high_score_pressed() -> void:
	AudioManager.play_button_click()
	transition_to_high_score_entry()

func transition_to_high_score_entry() -> void:
	# Get session data
	var session_duration = 0.0
	var difficulty = GameManager.difficulty_level if GameManager else 1

	# Try to get session duration from ProgressTracker
	var recent_sessions = ProgressTracker.get_recent_sessions(1)
	if recent_sessions.size() > 0:
		session_duration = recent_sessions[0].session_duration

	# Store pending entry data
	LeaderboardData.set_pending_entry(
		GameManager.current_score,
		session_duration,
		difficulty
	)

	# Transition to high score entry scene
	await get_tree().create_timer(0.3).timeout
	SceneManager.change_scene("res://src/ui/HighScoreEntryScene.tscn")
