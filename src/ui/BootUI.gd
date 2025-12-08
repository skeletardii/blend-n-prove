extends Control

## BootUI - Displays boot progress and status

@onready var status_label: Label = $VBox/StatusLabel
@onready var progress_bar: ProgressBar = $VBox/ProgressBar
@onready var update_manager: Node = null

func _ready() -> void:
	# Get UpdateManager from parent
	update_manager = get_parent().get_node_or_null("UpdateManager")

	if not update_manager:
		push_error("BootUI: UpdateManager not found!")
		return

	# Connect to UpdateManager signals
	update_manager.boot_started.connect(_on_boot_started)
	update_manager.pck_check_started.connect(_on_pck_check_started)
	update_manager.pck_downloading.connect(_on_pck_downloading)
	update_manager.pck_download_completed.connect(_on_pck_download_completed)
	update_manager.pck_loaded.connect(_on_pck_loaded)
	update_manager.managers_loading.connect(_on_managers_loading)
	update_manager.managers_ready.connect(_on_managers_ready)
	update_manager.boot_failed.connect(_on_boot_failed)

	# Initialize progress bar
	progress_bar.value = 0
	progress_bar.max_value = 100

func _on_boot_started() -> void:
	status_label.text = "Starting..."
	progress_bar.value = 0

func _on_pck_check_started() -> void:
	status_label.text = "Checking for updates..."
	progress_bar.value = 10

func _on_pck_downloading(downloaded_bytes: int, total_bytes: int, percent: float) -> void:
	status_label.text = "Downloading content..."
	progress_bar.value = 10 + (percent * 0.5)  # 10-60% range

	# Show download size
	var downloaded_mb = downloaded_bytes / 1048576.0
	var total_mb = total_bytes / 1048576.0
	status_label.text = "Downloading content... %.1f / %.1f MB" % [downloaded_mb, total_mb]

func _on_pck_download_completed(success: bool) -> void:
	if success:
		status_label.text = "Download complete!"
		progress_bar.value = 60
	else:
		status_label.text = "Download failed!"
		progress_bar.value = 0

func _on_pck_loaded() -> void:
	status_label.text = "Loading content..."
	progress_bar.value = 70

func _on_managers_loading() -> void:
	status_label.text = "Loading game systems..."
	progress_bar.value = 80

func _on_managers_ready() -> void:
	status_label.text = "Ready!"
	progress_bar.value = 100

func _on_boot_failed(error: String) -> void:
	status_label.text = "Boot failed: " + error
	progress_bar.value = 0

	# Show error in red
	status_label.add_theme_color_override("font_color", Color.RED)
