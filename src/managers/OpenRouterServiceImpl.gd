extends Node

## OpenRouter Service Implementation
## Handles all HTTP requests to OpenRouter API for AI Tutor functionality

signal response_received(content: String)
signal error_occurred(error_message: String)

var api_key: String = ""
var base_url: String = ""
var is_initialized: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_env_variables()

## Load environment variables from .env file or web config
func load_env_variables() -> void:
	# Check if running on web platform
	if OS.get_name() == "Web":
		load_web_config()
		return

	# Try loading from project settings first (for exported builds)
	if ProjectSettings.has_setting("api_config/openrouter_api_key"):
		api_key = ProjectSettings.get_setting("api_config/openrouter_api_key")
		base_url = ProjectSettings.get_setting("api_config/openrouter_base_url")

		# Set default base URL if not specified
		if base_url.is_empty():
			base_url = "https://openrouter.ai/api/v1"

		if not api_key.is_empty():
			is_initialized = true
			print("OpenRouter service initialized from project settings")
			return

	# Fallback to .env file for desktop/mobile platforms (development)
	var env_path = "res://.env"

	# Check if .env file exists
	if not FileAccess.file_exists(env_path):
		print("Warning: .env file not found and no project settings configured.")
		print("Please create .env file with OPENROUTER_API_KEY and OPENROUTER_BASE_URL")
		is_initialized = false
		return

	# Read and parse .env file
	var file = FileAccess.open(env_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open .env file")
		is_initialized = false
		return

	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		# Skip comments and empty lines
		if line.begins_with("#") or line.is_empty():
			continue

		# Parse KEY=VALUE format
		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()

			if key == "OPENROUTER_API_KEY":
				api_key = value
			elif key == "OPENROUTER_BASE_URL":
				base_url = value

	file.close()

	# Set default base URL if not specified
	if base_url.is_empty():
		base_url = "https://openrouter.ai/api/v1"

	# Validate that we have the required API key
	if api_key.is_empty():
		print("Error: Missing OPENROUTER_API_KEY in .env file")
		is_initialized = false
		return

	is_initialized = true
	print("OpenRouter service initialized from .env file")

## Load configuration from JavaScript window variables (for web builds)
func load_web_config() -> void:
	if not OS.has_feature("web"):
		print("Error: load_web_config called on non-web platform")
		is_initialized = false
		return

	# Access JavaScript window variables using JavaScriptBridge
	var js_bridge = JavaScriptBridge

	# Read OPENROUTER_API_KEY from window.OPENROUTER_API_KEY
	var key_result = js_bridge.eval("window.OPENROUTER_API_KEY")
	if key_result != null and key_result != "":
		api_key = str(key_result)

	# Read OPENROUTER_BASE_URL from window.OPENROUTER_BASE_URL
	var url_result = js_bridge.eval("window.OPENROUTER_BASE_URL")
	if url_result != null and url_result != "":
		base_url = str(url_result)
	else:
		base_url = "https://openrouter.ai/api/v1"

	# Validate that we have the required API key
	if api_key.is_empty():
		print("Error: Missing OPENROUTER_API_KEY in web_config.js")
		print("Please ensure web_config.js sets window.OPENROUTER_API_KEY")
		is_initialized = false
		return

	is_initialized = true
	print("OpenRouter service initialized successfully from web_config.js")

## Send a chat completion request to OpenRouter API
## @param messages: Array of message dictionaries with 'role' and 'content' keys
## @param http_request: HTTPRequest node to use for the request
## @return: String containing the AI response content, or empty string on error
func send_chat_request(messages: Array, http_request: HTTPRequest) -> String:
	if not is_initialized:
		var error_msg = "OpenRouter service not initialized. Please check .env file."
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	# Use JavaScript fetch on web platform
	if OS.has_feature("web"):
		return await send_chat_request_web(messages)

	# Build request body
	var request_body = {
		"model": "nvidia/nemotron-3-nano-30b-a3b:free",
		"messages": messages
	}

	var body_json = JSON.stringify(request_body)

	# Set headers
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
		"HTTP-Referer: https://fusion-rush.app",
		"X-Title: Fusion Rush AI Tutor"
	]

	# Build URL
	var url = base_url + "/chat/completions"

	print("Sending chat request to OpenRouter...")

	# Make request
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body_json)
	if error != OK:
		var error_msg = "Failed to send request: " + str(error)
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	# Wait for response
	var response = await http_request.request_completed

	# Parse response
	var result = response[0]
	var status_code = response[1]
	var body = response[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		var error_msg = "HTTP request failed with result: " + str(result)
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	if status_code != 200:
		var error_msg = "Server returned status " + str(status_code)
		print("Error: " + error_msg)
		var body_text = body.get_string_from_utf8()
		print("Response body: " + body_text)
		error_occurred.emit(error_msg)
		return ""

	# Parse JSON response
	var json_string = body.get_string_from_utf8()
	var json = JSON.parse_string(json_string)

	if json == null:
		var error_msg = "Failed to parse JSON response"
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	# Extract content from response
	if not json.has("choices") or json.choices.size() == 0:
		var error_msg = "No response from AI"
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	var content = json.choices[0].message.content

	print("Successfully received AI response (" + str(content.length()) + " characters)")
	response_received.emit(content)
	return content

## Send chat request using JavaScript fetch API (web platform only)
func send_chat_request_web(messages: Array) -> String:
	var url = base_url + "/chat/completions"

	print("Sending chat request via JavaScript to: " + url)

	# Build request body
	var request_body = {
		"model": "amazon/nova-lite-v2",
		"messages": messages
	}
	var body_json = JSON.stringify(request_body)

	# Create unique callback name
	var callback_name = "godot_openrouter_callback_" + str(Time.get_ticks_msec())

	# Create JavaScript fetch request
	var js_code = """
	(async function() {
		console.log('Starting OpenRouter POST to: %s');
		try {
			const response = await fetch('%s', {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer %s',
					'HTTP-Referer': 'https://fusion-rush.app',
					'X-Title': 'Fusion Rush AI Tutor'
				},
				body: %s
			});

			console.log('OpenRouter response status:', response.status);

			if (!response.ok) {
				const errorText = await response.text();
				console.error('OpenRouter error:', errorText);
				window['%s'] = JSON.stringify({
					error: true,
					status: response.status,
					message: errorText
				});
				return;
			}

			const data = await response.json();
			console.log('OpenRouter success');
			window['%s'] = JSON.stringify({ error: false, data: data });
		} catch (e) {
			console.error('OpenRouter exception:', e);
			window['%s'] = JSON.stringify({ error: true, message: e.toString() });
		}
	})();
	""" % [url, url, api_key, body_json, callback_name, callback_name, callback_name]

	# Execute the JavaScript
	JavaScriptBridge.eval(js_code)
	print("JavaScript executed, polling for result with callback: " + callback_name)

	# Poll for result (with timeout)
	var max_attempts = 100  # 10 seconds max
	var attempt = 0
	var result_json = null

	while attempt < max_attempts:
		await get_tree().create_timer(0.1).timeout
		var check_code = "window['%s']" % callback_name
		result_json = JavaScriptBridge.eval(check_code)

		if result_json != null:
			print("Result JSON received after " + str(attempt) + " attempts")
			# Clean up
			JavaScriptBridge.eval("delete window['%s']" % callback_name)
			break

		attempt += 1

		# Log every 20 attempts (every 2 seconds)
		if attempt % 20 == 0:
			print("Still waiting for OpenRouter result... attempt " + str(attempt))

	if result_json == null:
		var error_msg = "Request timed out after " + str(attempt) + " attempts"
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	# Parse JSON string to dictionary
	print("Parsing OpenRouter JSON result")
	var result = JSON.parse_string(result_json)

	if result == null:
		var error_msg = "Failed to parse JSON result"
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	if result.has("error") and result["error"]:
		var error_msg = result.get("message", "Unknown error")
		print("Error: JavaScript request failed: " + str(error_msg))
		error_occurred.emit("Network error: " + str(error_msg))
		return ""

	if not result.has("data"):
		var error_msg = "Response missing data field"
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	var data = result["data"]

	# Extract content from response
	if not data.has("choices") or data.choices.size() == 0:
		var error_msg = "No response from AI"
		print("Error: " + error_msg)
		error_occurred.emit(error_msg)
		return ""

	var content = data.choices[0].message.content

	print("Successfully received AI response via JavaScript (" + str(content.length()) + " characters)")
	response_received.emit(content)
	return content
