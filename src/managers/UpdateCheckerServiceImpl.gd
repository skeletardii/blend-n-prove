extends Node

## Service for checking app updates and managing PCK downloads

# Existing signals (KEEP for backward compatibility)
signal update_available(update_info: Dictionary)
signal update_check_failed(error_message: String)
signal no_update_available()

# NEW signals for PCK download
signal pck_download_started(total_bytes: int)
signal pck_download_progress(downloaded_bytes: int, total_bytes: int, percent: float)
signal pck_download_completed(success: bool)
signal pck_loaded(success: bool)
signal first_launch_detected()

var http_request: HTTPRequest = null
var download_http_request: HTTPRequest = null
const REQUEST_TIMEOUT: float = 10.0

var is_downloading: bool = false
var current_version_info: Dictionary = {}

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = REQUEST_TIMEOUT
	http_request.request_completed.connect(_on_request_completed)

# ===== FIRST LAUNCH DETECTION =====

func is_first_launch() -> bool:
	"""Check if this is the first time the app is running"""
	var config = ConfigFile.new()
	var err = config.load("user://preferences.cfg")

	if err != OK:
		# No preferences file = first launch
		return true

	return config.get_value("app", AppConstants.FIRST_LAUNCH_KEY, true)

func mark_first_launch_complete() -> void:
	"""Mark first launch as complete in preferences"""
	var config = ConfigFile.new()
	config.load("user://preferences.cfg")  # Load existing or create new
	config.set_value("app", AppConstants.FIRST_LAUNCH_KEY, false)
	config.save("user://preferences.cfg")

func get_loaded_pck_version() -> String:
	"""Get the version of the currently loaded PCK"""
	var config = ConfigFile.new()
	var err = config.load("user://preferences.cfg")

	if err != OK:
		return ""

	return config.get_value("app", AppConstants.PCK_VERSION_KEY, "")

func save_pck_version(version: String) -> void:
	"""Save the version of the loaded PCK"""
	var config = ConfigFile.new()
	config.load("user://preferences.cfg")
	config.set_value("app", AppConstants.PCK_VERSION_KEY, version)
	config.save("user://preferences.cfg")

# ===== VERSION CHECKING (Enhanced) =====

func check_for_updates() -> void:
	"""Check for updates - works for both version check and first launch"""
	var is_editor = OS.has_feature("editor")
	if not is_editor and OS.get_name() != "Android":
		print("UpdateChecker: Skipping update check (platform: ", OS.get_name(), ")")
		no_update_available.emit()
		return

	if is_editor:
		print("UpdateChecker: Running in editor mode - check enabled for testing")

	# Check if first launch
	if is_first_launch():
		print("UpdateChecker: FIRST LAUNCH DETECTED")
		first_launch_detected.emit()
		# Still check for updates to get PCK URL

	print("UpdateChecker: Checking for updates at ", AppConstants.VERSION_CHECK_URL)
	var error = http_request.request(AppConstants.VERSION_CHECK_URL)

	if error != OK:
		var error_msg = "Network request failed with error code: " + str(error)
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "Network connection failed (result: " + str(result) + ")"
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	if response_code != 200:
		var error_msg = "Server returned error code: " + str(response_code)
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(json_string)

	if parse_error != OK:
		var error_msg = "Invalid JSON response from server"
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	var data = json.data

	# Enhanced validation to require pck_url
	if not _validate_json_data(data):
		var error_msg = "Invalid or missing fields in version data"
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	current_version_info = data

	# Check if PCK update needed
	var remote_pck_version = data.get("version", "")
	var local_pck_version = get_loaded_pck_version()

	print("UpdateChecker: Local PCK version: ", local_pck_version, ", Remote PCK version: ", remote_pck_version)

	# First launch OR PCK version mismatch
	if is_first_launch() or local_pck_version == "" or _is_newer_version(remote_pck_version, local_pck_version):
		print("UpdateChecker: PCK update needed!")
		update_available.emit(data)
	else:
		print("UpdateChecker: No PCK update needed")
		no_update_available.emit()

func _validate_json_data(data) -> bool:
	"""Enhanced validation with optional pck_hash field"""
	if typeof(data) != TYPE_DICTIONARY:
		print("UpdateChecker: Data is not a Dictionary")
		return false

	# Required fields for PCK system
	var required_fields = ["version", "pck_url", "header", "changelog", "message"]
	for field in required_fields:
		if not data.has(field):
			print("UpdateChecker: Missing required field: ", field)
			return false

		if typeof(data[field]) != TYPE_STRING:
			print("UpdateChecker: Field '", field, "' is not a String")
			return false

	# Validate pck_url ends with .pck
	if not data["pck_url"].ends_with(".pck"):
		print("UpdateChecker: pck_url must end with .pck")
		return false

	# Optional: pck_hash validation
	if data.has("pck_hash") and data["pck_hash"] != "":
		var hash_str = data["pck_hash"]
		if typeof(hash_str) != TYPE_STRING:
			print("UpdateChecker: pck_hash must be a String")
			return false

		if hash_str.length() != 64:
			print("UpdateChecker: pck_hash must be exactly 64 hex characters")
			return false

		# Validate hex format
		for char in hash_str:
			if not char.to_lower() in "0123456789abcdef":
				print("UpdateChecker: pck_hash contains invalid characters")
				return false

	return true

# ===== PCK DOWNLOAD MANAGEMENT =====

func download_pck(pck_url: String) -> void:
	"""Start downloading the PCK file"""
	if is_downloading:
		print("UpdateChecker: Already downloading, ignoring request")
		return

	is_downloading = true
	print("UpdateChecker: Starting PCK download from: ", pck_url)

	# Clean up old temp file if exists
	if FileAccess.file_exists(AppConstants.PCK_TEMP_PATH):
		DirAccess.remove_absolute(AppConstants.PCK_TEMP_PATH)

	# Create new HTTP request for download
	download_http_request = HTTPRequest.new()
	add_child(download_http_request)
	download_http_request.timeout = 300.0  # 5 minutes for large file
	download_http_request.download_file = AppConstants.PCK_TEMP_PATH
	download_http_request.request_completed.connect(_on_pck_download_completed)

	# Start download
	var error = download_http_request.request(pck_url)

	if error != OK:
		print("UpdateChecker ERROR: Failed to start download, error: ", error)
		is_downloading = false
		pck_download_completed.emit(false)
		if download_http_request:
			download_http_request.queue_free()
			download_http_request = null
		return

	pck_download_started.emit(0)  # Total bytes unknown until headers received

	# Start progress monitoring
	_monitor_download_progress()

func _monitor_download_progress() -> void:
	"""Monitor download progress using a timer"""
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
			pck_download_progress.emit(downloaded, total, percent)
	)
	progress_timer.start()

func _on_pck_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	"""Handle completed PCK download"""
	is_downloading = false

	if download_http_request:
		download_http_request.queue_free()
		download_http_request = null

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		print("UpdateChecker ERROR: PCK download failed with code: ", response_code)
		pck_download_completed.emit(false)

		# Clean up temp file
		if FileAccess.file_exists(AppConstants.PCK_TEMP_PATH):
			DirAccess.remove_absolute(AppConstants.PCK_TEMP_PATH)
		return

	print("UpdateChecker: PCK download completed, verifying file...")

	# Verify temp file exists and has size
	if not FileAccess.file_exists(AppConstants.PCK_TEMP_PATH):
		print("UpdateChecker ERROR: Downloaded PCK temp file not found!")
		pck_download_completed.emit(false)
		return

	var file = FileAccess.open(AppConstants.PCK_TEMP_PATH, FileAccess.READ)
	if not file:
		print("UpdateChecker ERROR: Cannot open temp PCK file!")
		pck_download_completed.emit(false)
		return

	var file_size = file.get_length()
	file.close()

	if file_size < 1000000:  # Less than 1 MB is suspicious
		print("UpdateChecker ERROR: Downloaded PCK is too small: ", file_size, " bytes")
		pck_download_completed.emit(false)
		DirAccess.remove_absolute(AppConstants.PCK_TEMP_PATH)
		return

	# Hash verification before atomic swap
	var expected_hash = current_version_info.get("pck_hash", "")

	if expected_hash != "":
		print("UpdateChecker: Verifying PCK hash...")

		var computed_hash = _compute_file_hash(AppConstants.PCK_TEMP_PATH)

		if computed_hash == "":
			print("UpdateChecker ERROR: Failed to compute file hash")
			pck_download_completed.emit(false)
			DirAccess.remove_absolute(AppConstants.PCK_TEMP_PATH)
			return

		print("UpdateChecker: Expected: ", expected_hash)
		print("UpdateChecker: Computed: ", computed_hash)

		if computed_hash.to_lower() != expected_hash.to_lower():
			print("UpdateChecker ERROR: Hash mismatch! File may be corrupted or tampered.")
			pck_download_completed.emit(false)
			DirAccess.remove_absolute(AppConstants.PCK_TEMP_PATH)
			return

		print("UpdateChecker: Hash verification PASSED ✓")
		# Save hash for future verification
		_save_pck_hash(computed_hash)
	else:
		print("UpdateChecker WARNING: No hash in version.json - skipping verification")

	print("UpdateChecker: PCK file verified (", file_size, " bytes), performing atomic swap...")

	# ATOMIC UPDATE: Rename temp to final
	# If final exists, delete it first (keep old one as backup during rename)
	var old_backup_path = AppConstants.PCK_FILE_PATH + ".old"

	# If current PCK exists, rename it to backup
	if FileAccess.file_exists(AppConstants.PCK_FILE_PATH):
		print("UpdateChecker: Backing up current PCK...")
		if FileAccess.file_exists(old_backup_path):
			DirAccess.remove_absolute(old_backup_path)

		var err = DirAccess.rename_absolute(AppConstants.PCK_FILE_PATH, old_backup_path)
		if err != OK:
			print("UpdateChecker ERROR: Failed to backup current PCK, error: ", err)
			pck_download_completed.emit(false)
			return

	# Rename temp to final
	var err = DirAccess.rename_absolute(AppConstants.PCK_TEMP_PATH, AppConstants.PCK_FILE_PATH)
	if err != OK:
		print("UpdateChecker ERROR: Failed to rename temp PCK, error: ", err)

		# Restore backup if rename failed
		if FileAccess.file_exists(old_backup_path):
			DirAccess.rename_absolute(old_backup_path, AppConstants.PCK_FILE_PATH)

		pck_download_completed.emit(false)
		return

	# Success! Clean up old backup
	if FileAccess.file_exists(old_backup_path):
		DirAccess.remove_absolute(old_backup_path)

	print("UpdateChecker: PCK file successfully installed")

	# Save version to preferences
	var version = current_version_info.get("version", "")
	save_pck_version(version)
	mark_first_launch_complete()

	pck_download_completed.emit(true)

# ===== PCK LOADING =====

func load_pck() -> bool:
	"""Load the PCK file from user:// directory"""
	if not FileAccess.file_exists(AppConstants.PCK_FILE_PATH):
		print("UpdateChecker ERROR: PCK file not found at: ", AppConstants.PCK_FILE_PATH)
		pck_loaded.emit(false)
		return false

	print("UpdateChecker: Loading PCK from: ", AppConstants.PCK_FILE_PATH)

	var success = ProjectSettings.load_resource_pack(AppConstants.PCK_FILE_PATH)

	if success:
		print("UpdateChecker: PCK loaded successfully!")
		pck_loaded.emit(true)
		return true
	else:
		print("UpdateChecker ERROR: Failed to load PCK!")
		pck_loaded.emit(false)
		return false

# ===== UTILITY FUNCTIONS (Keep existing) =====

func _compute_file_hash(file_path: String) -> String:
	"""Compute SHA-256 hash of a file and return as hex string"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("UpdateChecker ERROR: Cannot open file for hashing: ", file_path)
		return ""

	var hash_ctx = HashingContext.new()
	hash_ctx.start(HashingContext.HASH_SHA256)

	# Read file in chunks (1 MB) to handle large PCK files efficiently
	var chunk_size = 1024 * 1024
	var total_read = 0
	var file_size = file.get_length()

	while total_read < file_size:
		var chunk = file.get_buffer(chunk_size)
		if chunk.size() == 0:
			break
		hash_ctx.update(chunk)
		total_read += chunk.size()

	file.close()

	# Convert hash bytes to hex string
	var hash_bytes = hash_ctx.finish()
	var hash_hex = ""
	for byte in hash_bytes:
		hash_hex += "%02x" % byte

	return hash_hex

func _save_pck_hash(hash: String) -> void:
	"""Save PCK hash to preferences for future verification"""
	var config = ConfigFile.new()
	config.load("user://preferences.cfg")
	config.set_value("app", "pck_hash", hash)
	config.save("user://preferences.cfg")

func _get_saved_pck_hash() -> String:
	"""Retrieve saved PCK hash from preferences"""
	var config = ConfigFile.new()
	var err = config.load("user://preferences.cfg")
	if err != OK:
		return ""
	return config.get_value("app", "pck_hash", "")

func _is_newer_version(remote_version: String, current_version: String) -> bool:
	var remote_parts = _parse_version(remote_version)
	var current_parts = _parse_version(current_version)

	var max_length = max(remote_parts.size(), current_parts.size())

	for i in range(max_length):
		var remote_part = remote_parts[i] if i < remote_parts.size() else 0
		var current_part = current_parts[i] if i < current_parts.size() else 0

		if remote_part > current_part:
			return true
		elif remote_part < current_part:
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
			print("UpdateChecker WARNING: Invalid version part '", part, "', using 0")
			parts.append(0)

	return parts
