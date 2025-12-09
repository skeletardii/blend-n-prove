extends Control

## Leaderboard Scene
## Displays the top 10 scores from the last 24 hours

# Rank colors
const GOLD = Color(1.0, 0.84, 0.0, 1)
const SILVER = Color(0.75, 0.75, 0.75, 1)
const BRONZE = Color(0.8, 0.5, 0.2, 1)
const DEFAULT_RANK_COLOR = Color(0, 0, 0, 1)

# State
var is_loading: bool = false
var leaderboard_data: Array = []

# UI References
@onready var entries_container: VBoxContainer = $MainContainer/LeaderboardPanel/MarginContainer/LeaderboardContainer/EntriesContainer
@onready var loading_label: Label = $MainContainer/LoadingLabel
@onready var empty_label: Label = $MainContainer/EmptyLabel
@onready var error_label: Label = $MainContainer/ErrorLabel
@onready var refresh_button: Button = $MainContainer/ButtonContainer/RefreshButton
@onready var back_button: Button = $MainContainer/ButtonContainer/BackButton

func _ready() -> void:
	# Connect button signals
	refresh_button.pressed.connect(_on_refresh_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Load leaderboard
	load_leaderboard()

func load_leaderboard() -> void:
	if is_loading:
		return

	is_loading = true
	show_loading()

	# Fetch from Supabase
	var data = await SupabaseService.fetch_top_10_today()

	is_loading = false

	if data == null:
		show_error("Failed to load leaderboard")
		return

	leaderboard_data = data
	populate_leaderboard(data)

func show_loading() -> void:
	loading_label.visible = true
	empty_label.visible = false
	error_label.visible = false

	# Clear existing entries
	for child in entries_container.get_children():
		child.queue_free()

func show_error(message: String) -> void:
	loading_label.visible = false
	empty_label.visible = false
	error_label.visible = true
	error_label.text = message

func populate_leaderboard(data: Array) -> void:
	loading_label.visible = false
	error_label.visible = false

	# Clear existing entries
	for child in entries_container.get_children():
		child.queue_free()

	if data.is_empty():
		empty_label.visible = true
		return

	empty_label.visible = false

	# Create entry rows
	for i in range(data.size()):
		var entry_data = data[i]
		var entry_row = create_entry_row(i + 1, entry_data)
		entries_container.add_child(entry_row)

func create_entry_row(rank: int, entry_data: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 60)
	row.add_theme_constant_override("separation", 10)

	# Rank panel
	var rank_panel = create_mini_panel(80)
	var rank_label = Label.new()
	rank_label.text = "#" + str(rank)
	rank_label.add_theme_font_size_override("font_size", 40)
	rank_label.add_theme_color_override("font_color", get_rank_color(rank))
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rank_panel.add_child(rank_label)
	row.add_child(rank_panel)

	# Name panel
	var name_panel = create_mini_panel(150)
	var name_label = Label.new()
	name_label.text = entry_data.get("three_name", "???")
	name_label.add_theme_font_size_override("font_size", 36)
	name_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_panel.add_child(name_label)
	row.add_child(name_panel)

	# Score panel
	var score_panel = create_mini_panel(0)
	score_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var score_label = Label.new()
	score_label.text = format_score(entry_data.get("game_score", 0))
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	score_panel.add_child(score_label)
	row.add_child(score_panel)

	return row

func create_mini_panel(min_width: int) -> PanelContainer:
	var panel = PanelContainer.new()
	if min_width > 0:
		panel.custom_minimum_size = Vector2(min_width, 0)

	# Create mini version of card style
	var mini_style = StyleBoxFlat.new()
	mini_style.bg_color = Color(0.95, 0.95, 0.95, 1)
	mini_style.border_width_left = 2
	mini_style.border_width_top = 2
	mini_style.border_width_right = 2
	mini_style.border_width_bottom = 2
	mini_style.border_color = Color(0.3, 0.3, 0.3, 1)
	mini_style.corner_radius_top_left = 8
	mini_style.corner_radius_top_right = 8
	mini_style.corner_radius_bottom_right = 8
	mini_style.corner_radius_bottom_left = 8
	mini_style.shadow_size = 3
	mini_style.shadow_offset = Vector2(1, 2)
	mini_style.shadow_color = Color(0, 0, 0, 0.2)

	panel.add_theme_stylebox_override("panel", mini_style)
	return panel

func get_rank_color(rank: int) -> Color:
	match rank:
		1: return GOLD
		2: return SILVER
		3: return BRONZE
		_: return DEFAULT_RANK_COLOR

func format_score(score: int) -> String:
	# Add comma separators for thousands
	var score_str = str(score)
	var result = ""
	var count = 0
	for i in range(score_str.length() - 1, -1, -1):
		if count == 3:
			result = "," + result
			count = 0
		result = score_str[i] + result
		count += 1
	return result

func _on_refresh_pressed() -> void:
	AudioManager.play_button_click()
	SupabaseService.clear_cache()
	load_leaderboard()

func _on_back_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")
