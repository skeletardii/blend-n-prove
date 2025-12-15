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
signal signup_completed(user: Dictionary, error: String)
signal name_rank_received(rank: int, score: int)
signal stats_updated(success: bool)
signal stats_fetched(data: Dictionary)

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
	_connect_signal("signup_completed", _on_signup_completed)
	_connect_signal("name_rank_received", _on_name_rank_received)
	_connect_signal("stats_updated", _on_stats_updated)
	_connect_signal("stats_fetched", _on_stats_fetched)
	
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

func _on_signup_completed(user: Dictionary, error: String) -> void:
	signup_completed.emit(user, error)

func _on_name_rank_received(rank: int, score: int) -> void:
	name_rank_received.emit(rank, score)

func _on_stats_updated(success: bool) -> void:
	stats_updated.emit(success)

func _on_stats_fetched(data: Dictionary) -> void:
	stats_fetched.emit(data)

# --- PUBLIC METHODS ---

## Submit score via Edge Function (Arcade Mode)
func submit_score_arcade(initials: String, score: int, level: int, duration: float) -> void:
	if _impl:
		_impl.submit_score_arcade(initials, score, level, duration)
	else:
		print("Error: SupabaseService implementation not loaded")

## Submit score (Awaitable)
func submit_score(initials: String, score: int, duration: float, level: int) -> bool:
	if _impl:
		return await _impl.submit_score(initials, score, duration, level)
	else:
		print("Error: SupabaseService implementation not loaded")
		return false

## Fetch Top 10 from REST API
func fetch_leaderboard() -> void:
	if _impl:
		_impl.fetch_leaderboard()
	else:
		print("Error: SupabaseService implementation not loaded")

## Fetch Top 10 from last 24h
func fetch_top_10_today() -> Variant:
	if _impl:
		return await _impl.fetch_top_10_today()
	return null

## Clear Leaderboard Cache
func clear_cache() -> void:
	if _impl:
		_impl.clear_cache()

## Check if score qualifies for top 10
func check_qualifies_for_top_10(score: int) -> bool:
	if _impl:
		return await _impl.check_qualifies_for_top_10(score)
	else:
		print("Error: SupabaseService implementation not loaded")
		return false

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

## Sign up using Email/Password
func signup(email, password) -> void:
	if _impl:
		_impl.signup(email, password)
	else:
		signup_completed.emit(null, "Implementation not loaded")

## Get best rank for initials
func get_name_rank(initials: String) -> void:
	if _impl:
		_impl.get_name_rank(initials)
	else:
		name_rank_received.emit(0, 0)

## Upload Stats
func update_stats(data: Dictionary) -> void:
	if _impl:
		_impl.update_stats(data)
	else:
		stats_updated.emit(false)

## Get Stats
func get_stats() -> void:
	if _impl:
		_impl.get_stats()
	else:
		stats_fetched.emit({})

## Helper to check if logged in (if impl exposes it)
func is_logged_in() -> bool:
	if _impl and "session_token" in _impl:
		return _impl.session_token != ""
	return false