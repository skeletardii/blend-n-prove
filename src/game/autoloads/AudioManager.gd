extends Node

signal audio_settings_changed

var master_volume: float = 1.0
var music_volume: float = 0.5
var sfx_volume: float = 0.8
var is_muted: bool = false
var is_music_muted: bool = false
var is_sfx_muted: bool = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var rocket_engine_player: AudioStreamPlayer
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
	"background_music": "res://assets/music/Kubbi - Up In My Jam  NO COPYRIGHT 8-bit Music.mp3",
	"game_over_music": "res://assets/music/Game Over (8-Bit Music).mp3",
	"blackhole_intro_music": "res://assets/music/blackholeintrosound.mp3",
	"power_on_music": "res://assets/music/power-on-39172.mp3",
	"multiplier_increase": "res://assets/music/mixkit-arcade-bonus-alert-767.wav",
	"rocket_launch": "res://assets/sound/Explosion.wav",
	"rocket_engine": "res://assets/music/rocket-engine-90835.mp3",
	"losing_horn": "res://assets/music/losing-horn-313723.mp3",
	"fail_trumpet": "res://assets/music/cartoon-fail-trumpet-278822.mp3",
	"fail_sound": "res://assets/music/fail-234710.mp3",
	"invalid_rule": "res://assets/music/error-08-206492.mp3"
	# "menu_music": "res://assets/sound/Menu_In.wav" # Commented out - no music in main menu
}

# ...

func play_game_over_fail_sound() -> void:
	if is_muted or is_sfx_muted: return
	var fail_sounds = ["losing_horn", "fail_trumpet"]
	play_sfx(fail_sounds.pick_random())

func play_multiplier_lost_sound() -> void:
	play_sfx("invalid_rule")

# Loaded audio streams
var loaded_sounds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Create audio players
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	rocket_engine_player = AudioStreamPlayer.new()

	add_child(music_player)
	add_child(sfx_player)
	add_child(rocket_engine_player)

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
	if is_muted or is_sfx_muted:
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
	if is_muted or is_music_muted:
		print("DEBUG: Music muted, skipping playback start: ", music_name)
		# We allow it to 'play' but volume will be 0 if we remove this return, 
		# OR we keep it and it won't start.
		# If we want unmuting to resume music that *should* be playing, we should probably let it play at 0 volume.
		# But the current implementation returns.
		# Let's respect the current pattern: if muted, don't start. 
		# But wait, if I mute music, then enter game, music won't start. If I unmute, nothing happens?
		# That might be a bug in existing logic or intended. 
		# For now, I'll just add the check to match existing behavior.
		# Ideally, we should play it at -80db so unmuting works.
		# But let's stick to the current pattern to avoid side effects, just adding the flag.
		# Actually, if I modify update_volumes, that handles the volume.
		# If I return here, the stream player never starts.
		# So if user unmutes, silence.
		# I will REMOVE the early return so it starts playing (silently) and can be unmuted.
		pass 
		# Continued execution...

	print("DEBUG: Attempting to play music: ", music_name, " (loop: ", loop, ")")

	if music_name in loaded_sounds:
		var stream = loaded_sounds[music_name]
		# Check if already playing this stream
		if music_player.playing and music_player.stream == stream:
			print("DEBUG: Music already playing, skipping restart")
			return

		music_player.stream = stream
		print("DEBUG: Stream loaded from cache, type: ", music_player.stream.get_class())
		# Handle different audio stream types
		if music_player.stream is AudioStreamMP3:
			music_player.stream.loop = loop
			print("DEBUG: Set MP3 loop to: ", loop)
		elif music_player.stream and music_player.stream.has_method("set_loop_mode"):
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
			print("DEBUG: Set WAV loop_mode")
		elif music_player.stream and music_player.stream.has_method("set_loop"):
			music_player.stream.loop = loop
			print("DEBUG: Set loop property")
		music_player.play()
		print("DEBUG: Music player.play() called")
	else:
		# Try to load the music if it wasn't loaded before
		var path: String = audio_paths.get(music_name, "")
		print("DEBUG: Music not in cache, loading from: ", path)
		if not path.is_empty() and ResourceLoader.exists(path):
			var audio_stream = load(path)
			if audio_stream:
				print("DEBUG: Stream loaded successfully, type: ", audio_stream.get_class())
				loaded_sounds[music_name] = audio_stream
				music_player.stream = audio_stream
				# Handle different audio stream types
				if music_player.stream is AudioStreamMP3:
					music_player.stream.loop = loop
					print("DEBUG: Set MP3 loop to: ", loop)
				elif music_player.stream and music_player.stream.has_method("set_loop_mode"):
					music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
					print("DEBUG: Set WAV loop_mode")
				elif music_player.stream and music_player.stream.has_method("set_loop"):
					music_player.stream.loop = loop
					print("DEBUG: Set loop property")
				music_player.play()
				print("DEBUG: Music player.play() called")
			else:
				print("ERROR: Failed to load audio stream from: ", path)
		else:
			print("ERROR: Path empty or doesn't exist: ", path)

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
	update_volumes()
	audio_settings_changed.emit()

func toggle_music_mute() -> void:
	is_music_muted = !is_music_muted
	update_volumes()
	audio_settings_changed.emit()

func toggle_sfx_mute() -> void:
	is_sfx_muted = !is_sfx_muted
	update_volumes()
	audio_settings_changed.emit()

func update_volumes() -> void:
	if is_muted:
		music_player.volume_db = -80.0
		sfx_player.volume_db = -80.0
		rocket_engine_player.volume_db = -80.0
		for player in sfx_players_pool:
			player.volume_db = -80.0
	else:
		# Music volume
		if is_music_muted:
			music_player.volume_db = -80.0
		else:
			music_player.volume_db = linear_to_db(music_volume * master_volume)
		
		# SFX volume
		var sfx_db = -80.0
		if not is_sfx_muted:
			sfx_db = linear_to_db(sfx_volume * master_volume)
			
		sfx_player.volume_db = sfx_db
		rocket_engine_player.volume_db = sfx_db
		for player in sfx_players_pool:
			player.volume_db = sfx_db
	
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
	if is_muted or is_sfx_muted:
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

func play_multiplier_increase(combo_count: int) -> void:
	if is_muted or is_sfx_muted:
		return

	# Get an available player from the pool
	var player = get_available_sfx_player()

	if "multiplier_increase" in loaded_sounds:
		player.stream = loaded_sounds["multiplier_increase"]
		# Pitch goes up with combo (1.0 to 2.0 range)
		var pitch: float = 1.0 + min(float(combo_count) * 0.1, 1.0)
		player.pitch_scale = pitch
		player.play()
		# Reset pitch after playing (approximate duration of sound is short)
		await get_tree().create_timer(1.0).timeout
		player.pitch_scale = 1.0
	else:
		# Fallback - try to load it
		var path = audio_paths.get("multiplier_increase", "")
		if not path.is_empty() and ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				loaded_sounds["multiplier_increase"] = stream
				player.stream = stream
				var pitch: float = 1.0 + min(float(combo_count) * 0.1, 1.0)
				player.pitch_scale = pitch
				player.play()
				# Reset pitch
				await get_tree().create_timer(1.0).timeout
				player.pitch_scale = 1.0

func play_rocket_launch() -> void:
	play_sfx("rocket_launch")

func play_rocket_engine(pitch_scale: float = 1.0) -> void:
	if is_muted or is_sfx_muted:
		return
		
	if not rocket_engine_player.playing:
		if "rocket_engine" in loaded_sounds:
			rocket_engine_player.stream = loaded_sounds["rocket_engine"]
			# Set loop mode for WAV
			if rocket_engine_player.stream and rocket_engine_player.stream.has_method("set_loop_mode"):
				rocket_engine_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			# Load on demand
			var path = audio_paths.get("rocket_engine", "")
			if not path.is_empty() and ResourceLoader.exists(path):
				var stream = load(path)
				loaded_sounds["rocket_engine"] = stream
				rocket_engine_player.stream = stream
				# Set loop mode for WAV
				if rocket_engine_player.stream and rocket_engine_player.stream.has_method("set_loop_mode"):
					rocket_engine_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		
		if rocket_engine_player.stream:
			rocket_engine_player.play()
	
	# Update pitch
	rocket_engine_player.pitch_scale = pitch_scale

func stop_rocket_engine() -> void:
	if rocket_engine_player:
		rocket_engine_player.stop()

func set_rocket_engine_volume(db: float) -> void:
	# Allows stutter effect
	if rocket_engine_player:
		rocket_engine_player.volume_db = db

func stop_all_sfx() -> void:
	sfx_player.stop()
	for player in sfx_players_pool:
		player.stop()

func start_background_music() -> void:
	play_music("background_music", true)

func start_menu_music() -> void:
	play_music("menu_music", true)

func start_game_over_music() -> void:
	# Stop any currently playing music and SFX first
	stop_music()
	stop_all_sfx()
	
	# Small delay to ensure music player is fully stopped
	await get_tree().create_timer(0.1).timeout
	# Play game over music with looping
	play_music("game_over_music", true)
	print("DEBUG: Game over music started (looping)")
