extends Control

signal start_requested(tutorial_data)
signal cancel_requested

var current_tutorial_data = null

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var description_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ContentScroll/VBox/DescriptionLabel
@onready var rule_pattern_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/ContentScroll/VBox/RulePatternLabel
@onready var progress_label: Label = $Panel/MarginContainer/VBoxContainer/ProgressContainer/ProgressLabel
@onready var start_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/StartButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func setup(tutorial_data, progress: int, total: int) -> void:
	current_tutorial_data = tutorial_data
	
	title_label.text = tutorial_data.rule_name
	description_label.text = "[center][b]How It Works[/b][/center]\n\n" + tutorial_data.description
	
	rule_pattern_label.text = "\n[center][b]" + tutorial_data.rule_pattern + "[/b][/center]"
	
	progress_label.text = "Progress: " + str(progress) + "/" + str(total) + " problems completed"
	
	if progress == total:
		progress_label.text += " (Completed!)"
		progress_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	else:
		progress_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

func _on_start_pressed() -> void:
	start_requested.emit(current_tutorial_data)

func _on_cancel_pressed() -> void:
	cancel_requested.emit()
