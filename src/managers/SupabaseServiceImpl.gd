extends Node

## Supabase Service Implementation
## Handles all HTTP requests to Supabase REST API for daily leaderboard functionality

signal leaderboard_loaded(entries: Array)
signal leaderboard_error(error_message: String)
signal score_submitted(success: bool)

var supabase_url: String = ""
var supabase_key: String = ""
var is_initialized: bool = false

# Cache to prevent excessive API calls
var cached_leaderboard: Array = []
var cache_timestamp: float = 0.0
const CACHE_DURATION: float = 30.0  # 30 seconds

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_env_variables()

## Load environment variables from .env file or web config
func load_env_variables() -> void:
	# Check if running on web platform
	if OS.get_name() == "Web":
		load_web_config()
		return

	# Load from .env file for desktop/mobile platforms
	var env_path = "res://.env"

	# Check if .env file exists
	if not FileAccess.file_exists(env_path):
		print("Warning: .env file not found. Using fallback configuration.")
		print("Please create .env file with SUPABASE_URL and SUPABASE_ANON_KEY")
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

			if key == "SUPABASE_URL":
				supabase_url = value
			elif key == "SUPABASE_ANON_KEY":
				supabase_key = value

	file.close()

	# Validate that we have the required credentials
	if supabase_url.is_empty() or supabase_key.is_empty():
		print("Error: Missing Supabase credentials in .env file")
		is_initialized = false
		return

	is_initialized = true
	print("Supabase service initialized successfully")

## Load configuration from JavaScript window variables (for web builds)
func load_web_config() -> void:
	if not OS.has_feature("web"):
		print("Error: load_web_config called on non-web platform")
		is_initialized = false
		return

	# Access JavaScript window variables using JavaScriptBridge
	var js_bridge = JavaScriptBridge

	# Read SUPABASE_URL from window.SUPABASE_URL
	var url_result = js_bridge.eval("window.SUPABASE_URL")
	if url_result != null and url_result != "":
		supabase_url = str(url_result)

	# Read SUPABASE_ANON_KEY from window.SUPABASE_ANON_KEY
	var key_result = js_bridge.eval("window.SUPABASE_ANON_KEY")
	if key_result != null and key_result != "":
		supabase_key = str(key_result)

	# Validate that we have the required credentials
	if supabase_url.is_empty() or supabase_key.is_empty():
		print("Error: Missing Supabase credentials in web_config.js")
		print("Please ensure web_config.js sets window.SUPABASE_URL and window.SUPABASE_ANON_KEY")
		is_initialized = false
		return

	is_initialized = true
	print("Supabase service initialized successfully from web_config.js")

## Get timestamp for 24 hours ago in ISO 8601 format
func get_timestamp_24h_ago() -> String:
	var now_unix = Time.get_unix_time_from_system()
	var timestamp_24h_ago_unix = now_unix - 86400  # 86400 seconds = 24 hours
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp_24h_ago_unix)

	return "%04d-%02d-%02dT%02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

## Fetch top 10 scores from the last 24 hours
func fetch_top_10_today() -> Array:
	if not is_initialized:
		print("Error: Supabase service not initialized")
		leaderboard_error.emit("Service not configured. Please check .env file.")
		return []

	# Check cache first
	var current_time = Time.get_unix_time_from_system()
	if cached_leaderboard.size() > 0 and (current_time - cache_timestamp) < CACHE_DURATION:
		print("Returning cached leaderboard data")
		leaderboard_loaded.emit(cached_leaderboard)
		return cached_leaderboard

	# Use JavaScript fetch on web platform to avoid decompression issues
	if OS.has_feature("web"):
		return await fetch_top_10_today_web()

	# Create HTTP request node for desktop/mobile
	var http = HTTPRequest.new()
	add_child(http)

	# Build query URL
	var timestamp_24h_ago = get_timestamp_24h_ago()
	var url = supabase_url + "/rest/v1/leaderboard"
	url += "?select=*"
	url += "&created_at=gte." + timestamp_24h_ago
	url += "&order=game_score.desc"
	url += "&limit=10"

	# Set headers
	var headers = [
		"apikey: " + supabase_key,
		"Authorization: Bearer " + supabase_key,
		"Content-Type: application/json"
	]

	print("Fetching leaderboard from: " + url)

	# Make request
	var error = http.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("Error making HTTP request: " + str(error))
		http.queue_free()
		leaderboard_error.emit("Failed to connect to server")
		return []

	# Wait for response
	var response = await http.request_completed
	http.queue_free()

	# Parse response
	var result = response[0]
	var status_code = response[1]
	var body = response[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		print("Error: HTTP request failed with result: " + str(result))
		leaderboard_error.emit("Network error: " + str(result))
		return []

	if status_code != 200:
		print("Error: HTTP status " + str(status_code))
		leaderboard_error.emit("Server error: " + str(status_code))
		return []

	# Parse JSON
	var json_string = body.get_string_from_utf8()
	var json = JSON.parse_string(json_string)

	if json == null:
		print("Error: Failed to parse JSON response")
		leaderboard_error.emit("Invalid server response")
		return []

	# Update cache
	cached_leaderboard = json
	cache_timestamp = current_time

	print("Successfully fetched " + str(json.size()) + " leaderboard entries")
	leaderboard_loaded.emit(json)
	return json

## Fetch leaderboard using JavaScript fetch API (web platform only)
func fetch_top_10_today_web() -> Array:
	var timestamp_24h_ago = get_timestamp_24h_ago()
	var url = supabase_url + "/rest/v1/leaderboard"
	url += "?select=*"
	url += "&created_at=gte." + timestamp_24h_ago
	url += "&order=game_score.desc"
	url += "&limit=10"

	print("Fetching leaderboard from web: " + url)

	# Create unique callback name
	var callback_name = "godot_fetch_callback_" + str(Time.get_ticks_msec())

	# Set up JavaScript code that calls back to Godot
	var js_code = """
	(async function() {
		console.log('Starting fetch to: %s');
		try {
			const response = await fetch('%s', {
				method: 'GET',
				headers: {
					'apikey': '%s',
					'Authorization': 'Bearer %s',
					'Content-Type': 'application/json'
				}
			});

			console.log('Fetch response status:', response.status);

			if (!response.ok) {
				console.error('Fetch error - status:', response.status);
				window['%s'] = JSON.stringify({ error: true, status: response.status, message: 'HTTP error' });
				return;
			}

			const data = await response.json();
			console.log('Fetch success - data length:', data.length);
			window['%s'] = JSON.stringify({ error: false, data: data });
		} catch (e) {
			console.error('Fetch exception:', e);
			window['%s'] = JSON.stringify({ error: true, message: e.toString() });
		}
	})();
	""" % [url, url, supabase_key, supabase_key, callback_name, callback_name, callback_name]

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
			print("Still waiting for result... attempt " + str(attempt))

	if result_json == null:
		print("Error: JavaScript fetch timed out after " + str(attempt) + " attempts")
		# Check if callback exists in window
		var check_exists = JavaScriptBridge.eval("typeof window['%s']" % callback_name)
		print("Callback variable type: " + str(check_exists))
		leaderboard_error.emit("Request timed out")
		return []

	# Parse JSON string to dictionary
	print("Parsing JSON result: " + str(result_json))
	var result = JSON.parse_string(result_json)

	if result == null:
		print("Error: Failed to parse JSON result")
		leaderboard_error.emit("Invalid response format")
		return []

	if result.has("error") and result["error"]:
		var error_msg = result.get("message", "Unknown error")
		print("Error: JavaScript fetch failed: " + str(error_msg))
		leaderboard_error.emit("Network error: " + str(error_msg))
		return []

	if not result.has("data"):
		print("Error: Response missing data field")
		leaderboard_error.emit("Invalid server response")
		return []

	var data = result["data"]

	# Update cache
	var current_time = Time.get_unix_time_from_system()
	cached_leaderboard = data
	cache_timestamp = current_time

	print("Successfully fetched " + str(data.size()) + " leaderboard entries via JavaScript")
	leaderboard_loaded.emit(data)
	return data

## Submit a new score to the leaderboard
func submit_score(player_name: String, score: int, duration: float, difficulty: int) -> bool:
	if not is_initialized:
		print("Error: Supabase service not initialized")
		score_submitted.emit(false)
		return false

	# Validate inputs
	if player_name.length() != 3:
		print("Error: Player name must be exactly 3 characters")
		score_submitted.emit(false)
		return false

	if score <= 0:
		print("Error: Score must be greater than 0")
		score_submitted.emit(false)
		return false

	# Use JavaScript fetch on web platform to avoid decompression issues
	if OS.has_feature("web"):
		return await submit_score_web(player_name, score, duration, difficulty)

	# Create HTTP request node for desktop/mobile
	var http = HTTPRequest.new()
	add_child(http)

	# Build request body
	var game_time_string = "PT" + str(duration) + "S"

	var body_dict = {
		"three_name": player_name.to_upper(),
		"game_score": score,
		"game_time": game_time_string,
		"game_level": difficulty
	}
	var body_json = JSON.stringify(body_dict)

	# Build URL
	var url = supabase_url + "/rest/v1/leaderboard"

	# Set headers
	var headers = [
		"apikey: " + supabase_key,
		"Authorization: Bearer " + supabase_key,
		"Content-Type: application/json",
		"Prefer: return=minimal"
	]

	print("Submitting score: " + player_name + " - " + str(score))

	# Make request
	var error = http.request(url, headers, HTTPClient.METHOD_POST, body_json)
	if error != OK:
		print("Error making HTTP request: " + str(error))
		http.queue_free()
		score_submitted.emit(false)
		return false

	# Wait for response
	var response = await http.request_completed
	http.queue_free()

	# Parse response
	var status_code = response[1]

	if status_code == 201:  # Created
		print("Score submitted successfully!")
		# Invalidate cache
		cached_leaderboard.clear()
		cache_timestamp = 0.0
		score_submitted.emit(true)
		return true
	else:
		print("Error: HTTP status " + str(status_code))
		var body = response[3].get_string_from_utf8()
		print("Response body: " + body)
		score_submitted.emit(false)
		return false

## Submit score using JavaScript fetch API (web platform only)
func submit_score_web(player_name: String, score: int, duration: float, difficulty: int) -> bool:
	var game_time_string = "PT" + str(duration) + "S"
	var url = supabase_url + "/rest/v1/leaderboard"

	print("Submitting score via JavaScript: " + player_name + " - " + str(score))

	# Build request body
	var body_dict = {
		"three_name": player_name.to_upper(),
		"game_score": score,
		"game_time": game_time_string,
		"game_level": difficulty
	}
	var body_json = JSON.stringify(body_dict)

	# Create unique callback name
	var callback_name = "godot_submit_callback_" + str(Time.get_ticks_msec())

	# Create JavaScript fetch request
	var js_code = """
	(async function() {
		console.log('Starting POST to: %s');
		try {
			const response = await fetch('%s', {
				method: 'POST',
				headers: {
					'apikey': '%s',
					'Authorization': 'Bearer %s',
					'Content-Type': 'application/json',
					'Prefer': 'return=minimal'
				},
				body: %s
			});

			console.log('POST response status:', response.status);

			if (response.status === 201) {
				console.log('Score submitted successfully');
				window['%s'] = JSON.stringify({ error: false, status: 201 });
			} else {
				const text = await response.text();
				console.error('POST error:', text);
				window['%s'] = JSON.stringify({ error: true, status: response.status, message: text });
			}
		} catch (e) {
			console.error('POST exception:', e);
			window['%s'] = JSON.stringify({ error: true, message: e.toString() });
		}
	})();
	""" % [url, url, supabase_key, supabase_key, body_json, callback_name, callback_name, callback_name]

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
			print("Still waiting for submit result... attempt " + str(attempt))

	if result_json == null:
		print("Error: JavaScript submit timed out after " + str(attempt) + " attempts")
		var check_exists = JavaScriptBridge.eval("typeof window['%s']" % callback_name)
		print("Callback variable type: " + str(check_exists))
		score_submitted.emit(false)
		return false

	# Parse JSON string to dictionary
	print("Parsing submit JSON result: " + str(result_json))
	var result = JSON.parse_string(result_json)

	if result == null:
		print("Error: Failed to parse JSON result")
		score_submitted.emit(false)
		return false

	if result.has("error") and result["error"]:
		var error_msg = result.get("message", "Unknown error")
		print("Error: JavaScript submit failed: " + str(error_msg))
		score_submitted.emit(false)
		return false

	# Success!
	print("Score submitted successfully via JavaScript!")
	# Invalidate cache
	cached_leaderboard.clear()
	cache_timestamp = 0.0
	score_submitted.emit(true)
	return true

## Check if a score qualifies for the top 10
func check_qualifies_for_top_10(score: int) -> bool:
	if score <= 0:
		return false

	# Fetch current top 10
	var top_10 = await fetch_top_10_today()

	# If there are fewer than 10 entries, automatically qualifies
	if top_10.size() < 10:
		print("Score qualifies: Less than 10 entries")
		return true

	# Check if score is higher than the lowest in top 10
	if top_10.size() > 0:
		var lowest_score = top_10[top_10.size() - 1].get("game_score", 0)
		if score > lowest_score:
			print("Score qualifies: " + str(score) + " > " + str(lowest_score))
			return true

	print("Score does not qualify for top 10")
	return false

## Clear the cache (useful for refresh button)
func clear_cache() -> void:
	cached_leaderboard.clear()
	cache_timestamp = 0.0
	print("Leaderboard cache cleared")
