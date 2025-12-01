extends Node

signal audio_settings_changed

var master_volume: float = 1.0
var music_volume: float = 0.1
var sfx_volume: float = 0.8
var is_muted: bool = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_players_pool: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS: int = 8  # Allow up to 8 simultaneous sound effects

# Audio file paths - Updated to use 8-bit .wav files
var audio_paths: Dictionary = {
	"button_click": "res://assets/sound/Click.wav",
	"success": "res://assets/sound/Confirm.wav",
	"error": "res://assets/sound/Cancel.wav",
	"customer_arrive": "res://assets/sound/Notso_Confirm.wav",
	"customer_leave": "res://assets/sound/Steps.wav",
	"logic_success": "res://assets/sound/Powerup.wav",
	"premise_complete": "res://assets/sound/Confirm.wav",
	"score_popup": "res://assets/sound/Powerup.wav",  # Reusing powerup sound with pitch variation
	"background_music": "res://assets/music/Pinball Spring.mp3",
	# "menu_music": "res://assets/sound/Menu_In.wav" # Commented out - no music in main menu
}

# Loaded audio streams
var loaded_sounds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()

	add_child(music_player)
	add_child(sfx_player)

	# Create pool of additional SFX players for simultaneous sounds
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(player)
		sfx_players_pool.append(player)

	# Configure players
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)

	# Try to load audio files (they may not exist yet)
	load_audio_files()

func load_audio_files() -> void:
	for sound_name in audio_paths:
		var path: String = audio_paths[sound_name]
		if ResourceLoader.exists(path):
			var audio_stream = load(path)
			if audio_stream:
				loaded_sounds[sound_name] = audio_stream
		# If file doesn't exist, we'll just skip it (no error)

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player from the pool, or the first one if all are busy"""
	for player in sfx_players_pool:
		if not player.playing:
			return player
	# If all players are busy, use the first one (will interrupt)
	return sfx_players_pool[0]

func play_sfx(sound_name: String) -> void:
	if is_muted:
		return

	# Get an available player from the pool
	var player = get_available_sfx_player()

	if sound_name in loaded_sounds:
		player.stream = loaded_sounds[sound_name]
		player.play()
	else:
		# Try to load the sound if it wasn't loaded before
		var path: String = audio_paths.get(sound_name, "")
		if not path.is_empty() and ResourceLoader.exists(path):
			var audio_stream = load(path)
			if audio_stream:
				loaded_sounds[sound_name] = audio_stream
				player.stream = audio_stream
				player.play()

func play_music(music_name: String, loop: bool = true) -> void:
	if is_muted:
		return
	
	if music_name in loaded_sounds:
		music_player.stream = loaded_sounds[music_name]
		if music_player.stream and music_player.stream.has_method("set_loop_mode"):
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		elif music_player.stream and music_player.stream.has_method("set_loop"):
			music_player.stream.loop = loop
		music_player.play()
	else:
		# Try to load the music if it wasn't loaded before
		var path: String = audio_paths.get(music_name, "")
		if not path.is_empty() and ResourceLoader.exists(path):
			var audio_stream = load(path)
			if audio_stream:
				loaded_sounds[music_name] = audio_stream
				music_player.stream = audio_stream
				if music_player.stream and music_player.stream.has_method("set_loop_mode"):
					music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
				elif music_player.stream and music_player.stream.has_method("set_loop"):
					music_player.stream.loop = loop
				music_player.play()

func stop_music() -> void:
	music_player.stop()

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	update_volumes()

func toggle_mute() -> void:
	is_muted = !is_muted
	if is_muted:
		music_player.volume_db = -80.0  # Effectively mute
		sfx_player.volume_db = -80.0
		# Mute all players in the pool
		for player in sfx_players_pool:
			player.volume_db = -80.0
	else:
		update_volumes()
	audio_settings_changed.emit()

func update_volumes() -> void:
	if not is_muted:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
		# Update all players in the pool
		for player in sfx_players_pool:
			player.volume_db = linear_to_db(sfx_volume * master_volume)
	audio_settings_changed.emit()

func play_button_click() -> void:
	play_sfx("button_click")

func play_success() -> void:
	play_sfx("success")

func play_error() -> void:
	play_sfx("error")

func play_customer_arrive() -> void:
	play_sfx("customer_arrive")

func play_customer_leave() -> void:
	play_sfx("customer_leave")

func play_logic_success() -> void:
	play_sfx("logic_success")

func play_premise_complete() -> void:
	play_sfx("premise_complete")

func play_score_popup(multiplier: float) -> void:
	if is_muted:
		return

	# Get an available player from the pool
	var player = get_available_sfx_player()

	if "score_popup" in loaded_sounds:
		player.stream = loaded_sounds["score_popup"]
		# Adjust pitch based on multiplier (1.0x = normal, 2.5x+ = higher pitch)
		# Pitch range: 1.0 to 1.5
		var pitch: float = 1.0 + (clamp(multiplier - 1.0, 0.0, 1.5) * 0.33)
		player.pitch_scale = pitch
		player.play()
		# Reset pitch after playing
		await get_tree().create_timer(0.1).timeout
		player.pitch_scale = 1.0
	else:
		play_sfx("score_popup")

func start_background_music() -> void:
	play_music("background_music", true)

func start_menu_music() -> void:
	play_music("menu_music", true)
