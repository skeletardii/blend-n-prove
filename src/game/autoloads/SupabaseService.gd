extends Node

## Supabase Service Proxy
## This is a proxy autoload that forwards calls to SupabaseServiceImpl
## Following the proxy pattern used in this project

# --- SIGNALS ---
signal leaderboard_loaded(entries: Array)
signal leaderboard_error(error_message: String)
signal score_submitted(rank: int)
signal login_completed(user: Dictionary, error: String)
signal save_uploaded(success: bool)
signal save_downloaded(data: Dictionary)

var _impl: Node = null

func _ready() -> void:
	# Implementation will be loaded by ManagerBootstrap
	pass

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	_connect_signal("leaderboard_loaded", _on_leaderboard_loaded)
	_connect_signal("leaderboard_error", _on_leaderboard_error)
	_connect_signal("score_submitted", _on_score_submitted)
	_connect_signal("login_completed", _on_login_completed)
	_connect_signal("save_uploaded", _on_save_uploaded)
	_connect_signal("save_downloaded", _on_save_downloaded)
	
	print("SupabaseService Proxy connected to implementation.")

func _connect_signal(sig_name: String, callable: Callable) -> void:
	if _impl.has_signal(sig_name):
		if _impl.connect(sig_name, callable) != OK:
			print("Warning: Could not connect " + sig_name + " signal")
	else:
		print("Warning: Implementation missing signal " + sig_name)

# --- SIGNAL HANDLERS ---
func _on_leaderboard_loaded(entries: Array) -> void:
	leaderboard_loaded.emit(entries)

func _on_leaderboard_error(error_message: String) -> void:
	leaderboard_error.emit(error_message)

func _on_score_submitted(rank: int) -> void:
	score_submitted.emit(rank)

func _on_login_completed(user: Dictionary, error: String) -> void:
	login_completed.emit(user, error)

func _on_save_uploaded(success: bool) -> void:
	save_uploaded.emit(success)

func _on_save_downloaded(data: Dictionary) -> void:
	save_downloaded.emit(data)

# --- PUBLIC METHODS ---

## Submit score via Edge Function (Arcade Mode)
func submit_score_arcade(initials: String, score: int, level: int, duration: float) -> void:
	if _impl:
		_impl.submit_score_arcade(initials, score, level, duration)
	else:
		print("Error: SupabaseService implementation not loaded")

## Fetch Top 10 from REST API
func fetch_leaderboard() -> void:
	if _impl:
		_impl.fetch_leaderboard()
	else:
		print("Error: SupabaseService implementation not loaded")

## Log in using Email/Password
func login(email, password) -> void:
	if _impl:
		_impl.login(email, password)
	else:
		login_completed.emit(null, "Implementation not loaded")

## Upload Save to Cloud
func save_game_cloud(slot: int, data: Dictionary) -> void:
	if _impl:
		_impl.save_game_cloud(slot, data)
	else:
		save_uploaded.emit(false)

## Download Save from Cloud
func download_game_cloud(slot: int) -> void:
	if _impl:
		_impl.download_game_cloud(slot)
	else:
		save_downloaded.emit({})

## Helper to check if logged in (if impl exposes it)
func is_logged_in() -> bool:
	if _impl and "session_token" in _impl:
		return _impl.session_token != ""
	return false