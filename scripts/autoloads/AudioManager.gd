extends Node

signal audio_settings_changed

var master_volume: float = 1.0
var music_volume: float = 0.1
var sfx_volume: float = 0.8
var is_muted: bool = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Audio file paths - Updated to use 8-bit .wav files
var audio_paths: Dictionary = {
	"button_click": "res://resources/audio/8bit/Click.wav",
	"success": "res://resources/audio/8bit/Confirm.wav",
	"error": "res://resources/audio/8bit/Cancel.wav",
	"customer_arrive": "res://resources/audio/8bit/Notso_Confirm.wav",
	"customer_leave": "res://resources/audio/8bit/Steps.wav",
	"logic_success": "res://resources/audio/8bit/Powerup.wav",
	"premise_complete": "res://resources/audio/8bit/Confirm.wav",
	"background_music": "res://resources/audio/Pinball Spring.mp3",
	# "menu_music": "res://resources/audio/8bit/Menu_In.wav" # Commented out - no music in main menu
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

func play_sfx(sound_name: String) -> void:
	if is_muted:
		return
	
	if sound_name in loaded_sounds:
		sfx_player.stream = loaded_sounds[sound_name]
		sfx_player.play()
	else:
		# Try to load the sound if it wasn't loaded before
		var path: String = audio_paths.get(sound_name, "")
		if not path.is_empty() and ResourceLoader.exists(path):
			var audio_stream = load(path)
			if audio_stream:
				loaded_sounds[sound_name] = audio_stream
				sfx_player.stream = audio_stream
				sfx_player.play()

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
	else:
		update_volumes()
	audio_settings_changed.emit()

func update_volumes() -> void:
	if not is_muted:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
		sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
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

func start_background_music() -> void:
	play_music("background_music", true)

func start_menu_music() -> void:
	play_music("menu_music", true)
