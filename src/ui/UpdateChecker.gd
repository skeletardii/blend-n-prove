extends Panel

## Popup dialog for displaying app update information

signal popup_closed()
signal update_accepted(download_url: String)

@onready var header_label: Label = $MarginContainer/VBoxContainer/HeaderLabel
@onready var version_label: Label = $MarginContainer/VBoxContainer/VersionLabel
@onready var content_text: RichTextLabel = $MarginContainer/VBoxContainer/ContentScrollContainer/ContentText
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/CancelButton
@onready var update_button: Button = $MarginContainer/VBoxContainer/ButtonContainer/UpdateButton

var current_download_url: String = ""

func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	update_button.pressed.connect(_on_update_pressed)
	hide()

func show_update(update_info: Dictionary) -> void:
	var version = update_info.get("version", "Unknown")
	var download_url = update_info.get("download_url", "")
	var header = update_info.get("header", "UPDATE AVAILABLE")
	var changelog = update_info.get("changelog", "")
	var message = update_info.get("message", "")

	current_download_url = download_url

	header_label.text = header
	version_label.text = "Version " + version + " is available!"

	var content = ""
	if changelog != "":
		content += "[b]What's New:[/b]\n" + changelog + "\n\n"
	if message != "":
		content += message

	content_text.bbcode_enabled = true
	content_text.text = content.strip_edges()

	show()

	if AudioManager:
		AudioManager.play_button_click()

func _on_cancel_pressed() -> void:
	if AudioManager:
		AudioManager.play_button_click()

	hide()
	popup_closed.emit()

func _on_update_pressed() -> void:
	if AudioManager:
		AudioManager.play_button_click()

	if current_download_url != "":
		print("UpdateChecker: Opening download URL: ", current_download_url)
		var error = OS.shell_open(current_download_url)
		if error != OK:
			print("UpdateChecker ERROR: Failed to open URL, error code: ", error)

	hide()
	update_accepted.emit(current_download_url)
