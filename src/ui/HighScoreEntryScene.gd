extends Control

## High Score Entry Scene
## Allows players to enter their 3-letter name when they achieve a top 10 score

const HEADER_FONT = preload("res://assets/fonts/MuseoSansRounded900.otf")
const BODY_FONT = preload("res://assets/fonts/MuseoSansRounded300.otf")

# Character data
var current_name: Array[String] = ["A", "A", "A"]  # Default to AAA
var current_position: int = 0
var achieved_score: int = 0
var session_duration: float = 0.0
var difficulty_level: int = 1

# Virtual keyboard characters
const LETTERS_ROW1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
const LETTERS_ROW2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
const LETTERS_ROW3 = ["Z", "X", "C", "V", "B", "N", "M"]
const NUMBERS_ROW4 = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

# UI References
@onready var new_high_score_title: Label = $EntryPanel/EntryContainer/NewHighScoreTitle
@onready var score_display: Label = $EntryPanel/EntryContainer/ScoreDisplay
@onready var instructions_label: Label = $EntryPanel/EntryContainer/InstructionsLabel
@onready var letter_labels: Array[Label] = [
	$EntryPanel/EntryContainer/NameDisplay/LetterContainer/Letter1Panel/Letter1,
	$EntryPanel/EntryContainer/NameDisplay/LetterContainer/Letter2Panel/Letter2,
	$EntryPanel/EntryContainer/NameDisplay/LetterContainer/Letter3Panel/Letter3
]
@onready var letter_panels: Array[Panel] = [
	$EntryPanel/EntryContainer/NameDisplay/LetterContainer/Letter1Panel,
	$EntryPanel/EntryContainer/NameDisplay/LetterContainer/Letter2Panel,
	$EntryPanel/EntryContainer/NameDisplay/LetterContainer/Letter3Panel
]
@onready var submit_button: Button = $EntryPanel/EntryContainer/ActionButtons/SubmitButton
@onready var backspace_button: Button = $EntryPanel/EntryContainer/ActionButtons/BackspaceButton

# Keyboard row containers
@onready var row1: HBoxContainer = $EntryPanel/EntryContainer/VirtualKeyboard/LetterRows/Row1
@onready var row2: HBoxContainer = $EntryPanel/EntryContainer/VirtualKeyboard/LetterRows/Row2
@onready var row3: HBoxContainer = $EntryPanel/EntryContainer/VirtualKeyboard/LetterRows/Row3
@onready var row4: HBoxContainer = $EntryPanel/EntryContainer/VirtualKeyboard/LetterRows/Row4
@onready var row5: HBoxContainer = $EntryPanel/EntryContainer/VirtualKeyboard/LetterRows/Row5

# State tracking
var is_submitting: bool = false

func _ready() -> void:
	# Load pending score data
	if LeaderboardData.is_pending:
		var data = LeaderboardData.get_pending_data()
		achieved_score = data.score
		session_duration = data.duration
		difficulty_level = data.difficulty
		LeaderboardData.clear_pending()
	else:
		# Fallback if no pending data
		achieved_score = GameManager.current_score if GameManager else 0
		session_duration = 0.0
		difficulty_level = 1

	# Display score
	score_display.text = str(achieved_score)
	
	# Apply fonts
	new_high_score_title.add_theme_font_override("font", HEADER_FONT)
	score_display.add_theme_font_override("font", HEADER_FONT)
	instructions_label.add_theme_font_override("font", BODY_FONT)

	# Setup virtual keyboard
	create_keyboard()

	# Connect button signals
	submit_button.pressed.connect(_on_submit_pressed)
	backspace_button.pressed.connect(_on_backspace_pressed)

	# Initialize display
	update_display()

func create_keyboard() -> void:
	# Create buttons for each row
	create_row_buttons(row1, LETTERS_ROW1)
	create_row_buttons(row2, LETTERS_ROW2)
	create_row_buttons(row3, LETTERS_ROW3)
	create_row_buttons(row4, NUMBERS_ROW4)
	# Row 5 is unused in QWERTY layout with numbers on row 4

func create_row_buttons(row: HBoxContainer, characters: Array) -> void:
	for character in characters:
		var button = Button.new()
		button.text = character
		button.custom_minimum_size = Vector2(50, 50)
		button.add_theme_font_size_override("font_size", 28)
		button.pressed.connect(_on_character_pressed.bind(character))
		row.add_child(button)

func _on_character_pressed(character: String) -> void:
	if current_position < 3:
		current_name[current_position] = character
		current_position += 1
		update_display()
		AudioManager.play_button_click()

func _on_backspace_pressed() -> void:
	if current_position > 0:
		current_position -= 1
		current_name[current_position] = "A"  # Reset to A
		update_display()
		AudioManager.play_button_click()

func _on_submit_pressed() -> void:
	if is_submitting:
		return

	# Ensure we have 3 characters
	if current_position < 3:
		return

	is_submitting = true
	submit_button.disabled = true
	submit_button.text = "SUBMITTING..."

	var name_string = "".join(current_name)

	# Submit to Supabase
	var success = await SupabaseService.submit_score(
		name_string,
		achieved_score,
		session_duration,
		difficulty_level
	)

	if success:
		print("Score submitted successfully!")
		AudioManager.play_button_click()
		await get_tree().create_timer(0.3).timeout
		SceneManager.change_scene("res://src/ui/MainMenu.tscn")
	else:
		print("Failed to submit score")
		submit_button.text = "RETRY"
		submit_button.disabled = false
		is_submitting = false

func update_display() -> void:
	# Update letter displays
	for i in range(3):
		letter_labels[i].text = current_name[i]

		# Highlight active position with cyan border
		var style = letter_panels[i].get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			var new_style = style.duplicate()
			if i == current_position and current_position < 3:
				new_style.border_color = Color(0, 1, 1, 1)  # Cyan
				new_style.border_width_left = 3
				new_style.border_width_top = 3
				new_style.border_width_right = 3
				new_style.border_width_bottom = 3
			else:
				new_style.border_color = Color(0.5, 0.5, 0.5, 1)  # Gray
				new_style.border_width_left = 2
				new_style.border_width_top = 2
				new_style.border_width_right = 2
				new_style.border_width_bottom = 2
			letter_panels[i].add_theme_stylebox_override("panel", new_style)

	# Enable/disable submit button
	submit_button.disabled = (current_position < 3) or is_submitting
