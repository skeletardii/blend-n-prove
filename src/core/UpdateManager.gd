extends Node

## UpdateManager - Coordinates application boot and PCK loading
##
## This node orchestrates the entire boot sequence:
## 1. Check for PCK updates
## 2. Download PCK if needed
## 3. Load PCK
## 4. Trigger ManagerBootstrap
## 5. Transition to MainMenu

signal boot_started()
signal pck_check_started()
signal pck_downloading(downloaded_bytes: int, total_bytes: int, percent: float)
signal pck_download_completed(success: bool)
signal pck_loaded()
signal managers_loading()
signal managers_ready()
signal boot_failed(error: String)

enum BootState {
	INITIALIZING,
	CHECKING_PCK,
	DOWNLOADING_PCK,
	LOADING_PCK,
	LOADING_MANAGERS,
	READY,
	FAILED
}

var current_state: BootState = BootState.INITIALIZING
var pck_path: String = "user://fusion-rush-content.pck"
var pck_temp_path: String = "user://fusion-rush-content.pck.tmp"
var version_check_url: String = ""

# HTTP request for version checking
var http_request: HTTPRequest = null
var download_http_request: HTTPRequest = null

var is_downloading: bool = false
var current_version_info: Dictionary = {}

func _ready() -> void:
	boot_started.emit()
	current_state = BootState.INITIALIZING

	# Get version check URL from AppConstants
	version_check_url = AppConstants.VERSION_CHECK_URL

	print("UpdateManager: Starting boot sequence...")

	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = 10.0
	http_request.request_completed.connect(_on_version_check_completed)

	# Start boot sequence
	_check_pck_status()

func _check_pck_status() -> void:
	current_state = BootState.CHECKING_PCK
	pck_check_started.emit()

	print("UpdateManager: Checking PCK status...")

	# Check if PCK exists locally
	if FileAccess.file_exists(pck_path):
		print("UpdateManager: Local PCK found")
		# Check if update available
		_check_for_updates()
	else:
		print("UpdateManager: No local PCK - first launch")
		# Must download
		_check_for_updates()

func _check_for_updates() -> void:
	print("UpdateManager: Checking version.json at: ", version_check_url)
	var err = http_request.request(version_check_url)
	if err != OK:
		_handle_version_check_error("Failed to start version check: " + str(err))

func _on_version_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		# If version check fails but we have local PCK, use it
		if FileAccess.file_exists(pck_path):
			print("UpdateManager: Version check failed, using local PCK")
			_load_pck()
		else:
			_handle_error("Version check failed and no local PCK available")
		return

	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		_handle_error("Invalid version.json")
		return

	var version_data = json.data

	# Validate required fields
	if not _validate_version_data(version_data):
		_handle_error("Invalid version.json format")
		return

	current_version_info = version_data

	var remote_version = version_data.get("version", "")
	var pck_url = version_data.get("pck_url", "")

	# Check if we need to download
	var local_version = _get_local_pck_version()

	if not FileAccess.file_exists(pck_path) or local_version == "" or _is_newer_version(remote_version, local_version):
		print("UpdateManager: Update needed - downloading PCK from: ", pck_url)
		_download_pck(pck_url, remote_version)
	else:
		print("UpdateManager: Local PCK is up to date (version ", local_version, ")")
		_load_pck()

func _validate_version_data(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	var required_fields = ["version", "pck_url"]
	for field in required_fields:
		if not data.has(field):
			print("UpdateManager: Missing required field: ", field)
			return false
		if typeof(data[field]) != TYPE_STRING:
			return false

	if not data["pck_url"].ends_with(".pck"):
		print("UpdateManager: pck_url must end with .pck")
		return false

	return true

func _handle_version_check_error(error: String) -> void:
	# If we have a local PCK, use it despite version check failure
	if FileAccess.file_exists(pck_path):
		print("UpdateManager: ", error, " - using local PCK")
		_load_pck()
	else:
		_handle_error(error)

func _download_pck(url: String, version: String) -> void:
	current_state = BootState.DOWNLOADING_PCK

	if is_downloading:
		print("UpdateManager: Already downloading, ignoring request")
		return

	is_downloading = true
	print("UpdateManager: Starting PCK download...")

	# Clean up old temp file if exists
	if FileAccess.file_exists(pck_temp_path):
		DirAccess.remove_absolute(pck_temp_path)

	# Create HTTP request for download
	download_http_request = HTTPRequest.new()
	add_child(download_http_request)
	download_http_request.timeout = 300.0  # 5 minutes for large file
	download_http_request.download_file = pck_temp_path
	download_http_request.request_completed.connect(
		func(r: int, c: int, h: PackedStringArray, b: PackedByteArray):
			_on_pck_download_completed(r, c, h, b, version)
	)

	# Start download
	var error = download_http_request.request(url)

	if error != OK:
		print("UpdateManager ERROR: Failed to start download, error: ", error)
		is_downloading = false
		pck_download_completed.emit(false)
		if download_http_request:
			download_http_request.queue_free()
			download_http_request = null
		_handle_error("Failed to start PCK download")
		return

	# Start progress monitoring
	_monitor_download_progress()

func _monitor_download_progress() -> void:
	var progress_timer = Timer.new()
	add_child(progress_timer)
	progress_timer.wait_time = 0.1  # Update every 100ms
	progress_timer.timeout.connect(func():
		if not is_downloading or not download_http_request:
			progress_timer.queue_free()
			return

		var downloaded = download_http_request.get_downloaded_bytes()
		var total = download_http_request.get_body_size()

		if total > 0:
			var percent = (float(downloaded) / float(total)) * 100.0
			pck_downloading.emit(downloaded, total, percent)
	)
	progress_timer.start()

func _on_pck_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, version: String) -> void:
	is_downloading = false

	if download_http_request:
		download_http_request.queue_free()
		download_http_request = null

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		print("UpdateManager ERROR: PCK download failed with code: ", response_code)
		pck_download_completed.emit(false)

		# Clean up temp file
		if FileAccess.file_exists(pck_temp_path):
			DirAccess.remove_absolute(pck_temp_path)

		_handle_error("PCK download failed")
		return

	print("UpdateManager: PCK download completed, verifying file...")

	# Verify temp file exists and has size
	if not FileAccess.file_exists(pck_temp_path):
		print("UpdateManager ERROR: Downloaded PCK temp file not found!")
		pck_download_completed.emit(false)
		_handle_error("Downloaded PCK file not found")
		return

	var file = FileAccess.open(pck_temp_path, FileAccess.READ)
	if not file:
		print("UpdateManager ERROR: Cannot open temp PCK file!")
		pck_download_completed.emit(false)
		_handle_error("Cannot open downloaded PCK")
		return

	var file_size = file.get_length()
	file.close()

	if file_size < 1000000:  # Less than 1 MB is suspicious
		print("UpdateManager ERROR: Downloaded PCK is too small: ", file_size, " bytes")
		pck_download_completed.emit(false)
		DirAccess.remove_absolute(pck_temp_path)
		_handle_error("Downloaded PCK file is corrupted")
		return

	print("UpdateManager: PCK file verified (", file_size, " bytes), performing atomic swap...")

	# ATOMIC UPDATE: Rename temp to final
	var old_backup_path = pck_path + ".old"

	# If current PCK exists, rename it to backup
	if FileAccess.file_exists(pck_path):
		print("UpdateManager: Backing up current PCK...")
		if FileAccess.file_exists(old_backup_path):
			DirAccess.remove_absolute(old_backup_path)

		var err = DirAccess.rename_absolute(pck_path, old_backup_path)
		if err != OK:
			print("UpdateManager ERROR: Failed to backup current PCK, error: ", err)
			pck_download_completed.emit(false)
			_handle_error("Failed to backup existing PCK")
			return

	# Rename temp to final
	var err = DirAccess.rename_absolute(pck_temp_path, pck_path)
	if err != OK:
		print("UpdateManager ERROR: Failed to rename temp PCK, error: ", err)

		# Restore backup if rename failed
		if FileAccess.file_exists(old_backup_path):
			DirAccess.rename_absolute(old_backup_path, pck_path)

		pck_download_completed.emit(false)
		_handle_error("Failed to install PCK")
		return

	# Success! Clean up old backup
	if FileAccess.file_exists(old_backup_path):
		DirAccess.remove_absolute(old_backup_path)

	print("UpdateManager: PCK file successfully installed")

	# Save version to preferences
	_save_pck_version(version)

	pck_download_completed.emit(true)

	# Now load the PCK
	_load_pck()

func _load_pck() -> void:
	current_state = BootState.LOADING_PCK

	print("UpdateManager: Loading PCK from ", pck_path)

	if not FileAccess.file_exists(pck_path):
		_handle_error("PCK file not found at: " + pck_path)
		return

	var success = ProjectSettings.load_resource_pack(pck_path)
	if not success:
		_handle_error("Failed to load PCK")
		return

	pck_loaded.emit()
	print("UpdateManager: PCK loaded successfully")

	# Now load managers
	_load_managers()

func _load_managers() -> void:
	current_state = BootState.LOADING_MANAGERS
	managers_loading.emit()

	print("UpdateManager: Triggering ManagerBootstrap...")

	# Connect to ManagerBootstrap signals
	if not ManagerBootstrap.managers_ready.is_connected(_on_managers_ready):
		ManagerBootstrap.managers_ready.connect(_on_managers_ready)
	if not ManagerBootstrap.manager_load_failed.is_connected(_on_manager_load_failed):
		ManagerBootstrap.manager_load_failed.connect(_on_manager_load_failed)

	# Trigger manager loading
	ManagerBootstrap.load_managers()

func _on_managers_ready() -> void:
	current_state = BootState.READY
	managers_ready.emit()

	print("UpdateManager: Boot complete! Transitioning to MainMenu...")

	# Transition to main menu
	SceneManager.change_scene("res://src/ui/MainMenu.tscn")

func _on_manager_load_failed(manager_name: String, error: String) -> void:
	_handle_error("Manager load failed: " + manager_name + " - " + error)

func _handle_error(error: String) -> void:
	current_state = BootState.FAILED
	boot_failed.emit(error)
	push_error("UpdateManager: " + error)

	# TODO: Show error UI
	print("UpdateManager: BOOT FAILED - ", error)

# ===== UTILITY FUNCTIONS =====

func _get_local_pck_version() -> String:
	var config = ConfigFile.new()
	if config.load("user://preferences.cfg") == OK:
		return config.get_value("app", "pck_version", "")
	return ""

func _save_pck_version(version: String) -> void:
	var config = ConfigFile.new()
	config.load("user://preferences.cfg")
	config.set_value("app", "pck_version", version)
	config.set_value("app", "first_launch", false)
	config.save("user://preferences.cfg")

func _is_newer_version(remote: String, local: String) -> bool:
	var remote_parts = _parse_version(remote)
	var local_parts = _parse_version(local)

	var max_length = max(remote_parts.size(), local_parts.size())

	for i in range(max_length):
		var remote_part = remote_parts[i] if i < remote_parts.size() else 0
		var local_part = local_parts[i] if i < local_parts.size() else 0

		if remote_part > local_part:
			return true
		elif remote_part < local_part:
			return false

	return false

func _parse_version(version_string: String) -> Array[int]:
	var parts: Array[int] = []
	var split_parts = version_string.split(".")

	for part in split_parts:
		var cleaned = part.strip_edges()
		if cleaned.is_valid_int():
			parts.append(int(cleaned))
		else:
			parts.append(0)

	return parts
