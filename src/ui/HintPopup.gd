extends Panel

signal popup_closed()

# UI References
@onready var hint_title: Label = $MarginContainer/VBoxContainer/HintTitle
@onready var hint_text: RichTextLabel = $MarginContainer/VBoxContainer/HintScrollContainer/HintText
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

# Blur overlay
var blur_overlay: ColorRect = null

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	hide()

func show_hint(solution_text: String) -> void:
	hint_text.bbcode_enabled = true
	hint_text.text = "[color=black][b]Solution:[/b][/color]\n" + solution_text
	_create_blur_overlay()
	show()

func _on_close_button_pressed() -> void:
	_remove_blur_overlay()
	hide()
	popup_closed.emit()

func _create_blur_overlay() -> void:
	# Create semi-transparent overlay behind the popup
	if blur_overlay == null:
		blur_overlay = ColorRect.new()
		blur_overlay.color = Color(0, 0, 0, 0.5)  # Semi-transparent black
		blur_overlay.z_index = 99  # Just behind the popup (popup is z_index 100)

		# Make it fullscreen
		blur_overlay.anchor_left = 0.0
		blur_overlay.anchor_top = 0.0
		blur_overlay.anchor_right = 1.0
		blur_overlay.anchor_bottom = 1.0

		get_parent().add_child(blur_overlay)
		get_parent().move_child(blur_overlay, get_index())  # Place just before this popup

func _remove_blur_overlay() -> void:
	if blur_overlay != null:
		blur_overlay.queue_free()
		blur_overlay = null
