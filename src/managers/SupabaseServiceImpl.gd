extends Node

## Supabase Service Implementation
## Handles all HTTP requests to Supabase (Auth, Database, Edge Functions)
## Implements the "Hybrid Architecture" (Arcade + Auth)

# --- SIGNALS ---
signal leaderboard_loaded(entries: Array)
signal leaderboard_error(error_message: String)
signal score_submitted(rank: int)
signal login_completed(user: Dictionary, error: String)
signal save_uploaded(success: bool)
signal save_downloaded(data: Dictionary)

# --- CONFIGURATION ---
var supabase_url: String = ""
var supabase_key: String = "" # This is the Anon Key
var is_initialized: bool = false

# --- STATE ---
var session_token: String = ""
var user_id: String = ""

# --- CACHE ---
var cached_leaderboard: Array = []
var cache_timestamp: float = 0.0
const CACHE_DURATION: float = 30.0

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
	if not FileAccess.file_exists(env_path):
		print("Warning: .env file not found.")
		is_initialized = false
		return

	var file = FileAccess.open(env_path, FileAccess.READ)
	if file == null:
		is_initialized = false
		return

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("#") or line.is_empty():
			continue
		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			if key == "SUPABASE_URL":
				supabase_url = value
			elif key == "SUPABASE_ANON_KEY":
				supabase_key = value
	file.close()

	if supabase_url.is_empty() or supabase_key.is_empty():
		print("Error: Missing Supabase credentials in .env")
		is_initialized = false
		return

	is_initialized = true
	print("Supabase service initialized successfully.")

## Load configuration from JavaScript window variables (for web builds)
func load_web_config() -> void:
	if not OS.has_feature("web"):
		return
	
	var js_bridge = JavaScriptBridge
	var url_result = js_bridge.eval("window.SUPABASE_URL")
	if url_result != null:
		supabase_url = str(url_result)
		
	var key_result = js_bridge.eval("window.SUPABASE_ANON_KEY")
	if key_result != null:
		supabase_key = str(key_result)

	if supabase_url.is_empty() or supabase_key.is_empty():
		print("Error: Missing Supabase credentials in web_config.js")
		is_initialized = false
		return
		
	is_initialized = true
	print("Supabase service initialized from web config.")

# --- HELPER: HEADERS ---
func _get_headers(auth_token = null, upsert = false) -> PackedStringArray:
	var headers = PackedStringArray()
	headers.append("Content-Type: application/json")
	headers.append("apikey: " + supabase_key)
	
	if auth_token:
		headers.append("Authorization: Bearer " + auth_token)
	else:
		headers.append("Authorization: Bearer " + supabase_key)
	
	if upsert:
		headers.append("Prefer: resolution=merge-duplicates")
		
	return headers

# --- ARCADE LEADERBOARD ---

## Submit score via Edge Function
func submit_score_arcade(initials: String, score: int, level: int, duration: float) -> void:
	if not is_initialized:
		print("Supabase not initialized.")
		return

	var url = supabase_url + "/functions/v1/submit-leaderboard-score"
	var body = JSON.stringify({
		"three_name": initials,
		"score": score,
		"level": level,
		"duration": duration
	})
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		var json = JSON.parse_string(body.get_string_from_utf8())
		if code == 200 and json != null and json.has("rank"):
			score_submitted.emit(int(json.rank))
			print("Score Submitted! Rank: ", json.rank)
			# Invalidate cache
			cached_leaderboard.clear()
		else:
			print("Error submitting score: ", body.get_string_from_utf8())
		http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

## Fetch Top 10 from REST API
func fetch_leaderboard() -> void:
	if not is_initialized:
		return

	# Check cache
	var current_time = Time.get_unix_time_from_system()
	if cached_leaderboard.size() > 0 and (current_time - cache_timestamp) < CACHE_DURATION:
		leaderboard_loaded.emit(cached_leaderboard)
		return

	var url = supabase_url + "/rest/v1/leaderboard?select=three_name,game_score,game_level&order=game_score.desc&limit=10"
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		if code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json != null:
				cached_leaderboard = json
				cache_timestamp = Time.get_unix_time_from_system()
				leaderboard_loaded.emit(json)
			else:
				leaderboard_error.emit("Failed to parse response")
		else:
			leaderboard_error.emit("HTTP Error: " + str(code))
		http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_GET)

# --- AUTHENTICATION & CLOUD SAVES ---

## Log in using Email/Password
func login(email, password) -> void:
	if not is_initialized:
		login_completed.emit(null, "Not initialized")
		return

	var url = supabase_url + "/auth/v1/token?grant_type=password"
	var body = JSON.stringify({"email": email, "password": password})
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		var json = JSON.parse_string(body.get_string_from_utf8())
		if code == 200 and json != null:
			session_token = json.get("access_token", "")
			var user = json.get("user", {})
			if user.has("id"):
				user_id = user.id
			login_completed.emit(user, "")
			print("Login successful.")
		else:
			var err_msg = "Login Failed"
			if json != null and json.has("error_description"):
				err_msg = json.error_description
			login_completed.emit(null, err_msg)
			print("Login error: ", err_msg)
		http.queue_free()
	)
	http.request(url, _get_headers(), HTTPClient.METHOD_POST, body)

## Upload Save to Cloud (UPSERT)
func save_game_cloud(slot: int, data: Dictionary) -> void:
	if not is_initialized or session_token == "":
		print("Cannot save: Not logged in.")
		save_uploaded.emit(false)
		return

	var url = supabase_url + "/rest/v1/saves"
	var headers = _get_headers(session_token, true) # Enable Upsert
	
	var body = JSON.stringify({
		"user_id": user_id,
		"slot": slot,
		"data": data
	})
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		if code == 201 or code == 200 or code == 204:
			print("Cloud save uploaded successfully.")
			save_uploaded.emit(true)
		else:
			print("Cloud save failed. Code: ", code)
			print("Response: ", body.get_string_from_utf8())
			save_uploaded.emit(false)
		http.queue_free()
	)
	http.request(url, headers, HTTPClient.METHOD_POST, body)

## Download Save from Cloud
func download_game_cloud(slot: int) -> void:
	if not is_initialized or session_token == "":
		print("Cannot download: Not logged in.")
		save_downloaded.emit({})
		return
		
	var url = supabase_url + "/rest/v1/saves?slot=eq." + str(slot) + "&select=data"
	var headers = _get_headers(session_token)
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		if code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json is Array and json.size() > 0:
				var save_data = json[0].get("data", {})
				save_downloaded.emit(save_data)
				print("Cloud save downloaded.")
			else:
				print("No save found for slot ", slot)
				save_downloaded.emit({})
		else:
			print("Download failed. Code: ", code)
			save_downloaded.emit({})
		http.queue_free()
	)
	http.request(url, headers, HTTPClient.METHOD_GET)