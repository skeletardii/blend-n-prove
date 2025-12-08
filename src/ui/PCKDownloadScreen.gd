extends Control

## UI for displaying PCK download progress and handling errors

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var size_label: Label = $CenterContainer/VBoxContainer/SizeLabel
@onready var percent_label: Label = $CenterContainer/VBoxContainer/PercentLabel
@onready var retry_button: Button = $CenterContainer/VBoxContainer/RetryButton

var is_first_launch: bool = false
var version_info: Dictionary = {}

func _ready() -> void:
	# Guard: Only initialize if UpdateCheckerService is loaded
	if not has_node("/root/UpdateCheckerService"):
		push_warning("PCKDownloadScreen: UpdateCheckerService not loaded - this UI is disabled")
		hide()  # Hide the entire screen since it can't function
		return

	retry_button.pressed.connect(_on_retry_pressed)
	retry_button.hide()

	# Connect to UpdateCheckerService signals
	UpdateCheckerService.pck_download_started.connect(_on_download_started)
	UpdateCheckerService.pck_download_progress.connect(_on_download_progress)
	UpdateCheckerService.pck_download_completed.connect(_on_download_completed)
	UpdateCheckerService.pck_loaded.connect(_on_pck_loaded)

func start_download(version_data: Dictionary, first_launch: bool = false) -> void:
	"""Initiate PCK download"""
	is_first_launch = first_launch
	version_info = version_data

	var pck_url = version_data.get("pck_url", "")

	if pck_url == "":
		_show_error("Invalid download URL")
		return

	status_label.text = "Preparing download..."
	progress_bar.value = 0
	size_label.text = ""
	percent_label.text = "0%"

	UpdateCheckerService.download_pck(pck_url)

func _on_download_started(total_bytes: int) -> void:
	status_label.text = "Downloading content..."

	if total_bytes > 0:
		progress_bar.max_value = total_bytes
	else:
		progress_bar.max_value = 100  # Fallback to percentage mode

func _on_download_progress(downloaded_bytes: int, total_bytes: int, percent: float) -> void:
	progress_bar.value = downloaded_bytes
	percent_label.text = str(round(percent)) + "%"

	# Format size nicely
	var downloaded_mb = downloaded_bytes / 1048576.0
	var total_mb = total_bytes / 1048576.0
	size_label.text = "%.1f MB / %.1f MB" % [downloaded_mb, total_mb]

func _on_download_completed(success: bool) -> void:
	if success:
		status_label.text = "Download complete! Loading content..."
		progress_bar.value = progress_bar.max_value
		percent_label.text = "100%"

		# Load the PCK
		UpdateCheckerService.load_pck()
	else:
		_show_error("Download failed!")

func _on_pck_loaded(success: bool) -> void:
	if success:
		status_label.text = "Success! Starting game..."

		# Wait a moment then transition to main menu
		await get_tree().create_timer(1.0).timeout

		if is_first_launch:
			# Load main menu for first time
			SceneManager.change_scene("res://src/ui/MainMenu.tscn")
		else:
			# For updates, reload current scene
			get_tree().reload_current_scene()
	else:
		_show_error("Failed to load content!")

func _show_error(message: String) -> void:
	status_label.text = message
	retry_button.show()

	if AudioManager:
		# Note: Can't play sound if PCK not loaded yet on first launch
		# Only play error sound if not first launch
		if not is_first_launch:
			AudioManager.play_button_click()  # Use available sound

func _on_retry_pressed() -> void:
	if AudioManager and not is_first_launch:
		AudioManager.play_button_click()

	retry_button.hide()
	start_download(version_info, is_first_launch)
