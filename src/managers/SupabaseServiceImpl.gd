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

## Load environment variables from .env file
func load_env_variables() -> void:
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

	# Create HTTP request node
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
	var status_code = response[1]
	var body = response[3]

	if status_code != 200:
		print("Error: HTTP status " + str(status_code))
		var error_message = "Server error: " + str(status_code)
		leaderboard_error.emit(error_message)
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

	# Create HTTP request node
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
