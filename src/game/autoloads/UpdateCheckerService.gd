extends Node

## Service for checking app updates from remote server

signal update_available(update_info: Dictionary)
signal update_check_failed(error_message: String)
signal no_update_available()

var http_request: HTTPRequest = null
const REQUEST_TIMEOUT: float = 10.0

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.timeout = REQUEST_TIMEOUT
	http_request.request_completed.connect(_on_request_completed)

func check_for_updates() -> void:
	# Platform check - Android only (but allow in editor for testing)
	var is_editor = OS.has_feature("editor")
	if not is_editor and OS.get_name() != "Android":
		print("UpdateChecker: Skipping update check (platform: ", OS.get_name(), ")")
		no_update_available.emit()
		return

	if is_editor:
		print("UpdateChecker: Running in editor mode - check enabled for testing")

	print("UpdateChecker: Checking for updates at ", AppConstants.VERSION_CHECK_URL)
	var error = http_request.request(AppConstants.VERSION_CHECK_URL)

	if error != OK:
		var error_msg = "Network request failed with error code: " + str(error)
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	# Handle network errors
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "Network connection failed (result: " + str(result) + ")"
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	# Handle HTTP errors
	if response_code != 200:
		var error_msg = "Server returned error code: " + str(response_code)
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	# Parse JSON
	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(json_string)

	if parse_error != OK:
		var error_msg = "Invalid JSON response from server"
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	var data = json.data

	# Validate required fields
	if not _validate_json_data(data):
		var error_msg = "Invalid or missing fields in version data"
		print("UpdateChecker ERROR: ", error_msg)
		update_check_failed.emit(error_msg)
		return

	# Compare versions
	var remote_version = data.version
	var current_version = AppConstants.APP_VERSION

	print("UpdateChecker: Current version: ", current_version, ", Remote version: ", remote_version)

	if _is_newer_version(remote_version, current_version):
		print("UpdateChecker: Update available!")
		update_available.emit(data)
	else:
		print("UpdateChecker: No update available")
		no_update_available.emit()

func _validate_json_data(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		print("UpdateChecker: Data is not a Dictionary")
		return false

	var required_fields = ["version", "download_url", "header", "changelog", "message"]
	for field in required_fields:
		if not data.has(field):
			print("UpdateChecker: Missing required field: ", field)
			return false

		if typeof(data[field]) != TYPE_STRING:
			print("UpdateChecker: Field '", field, "' is not a String")
			return false

	return true

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

	# Versions are equal
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
