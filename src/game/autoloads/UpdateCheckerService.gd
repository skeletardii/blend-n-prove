extends Node

## UpdateCheckerService Proxy - Delegates to implementation loaded from PCK

# Signals
signal update_available(update_info: Dictionary)
signal update_check_failed(error_message: String)
signal no_update_available()
signal pck_download_started(total_bytes: int)
signal pck_download_progress(downloaded_bytes: int, total_bytes: int, percent: float)
signal pck_download_completed(success: bool)
signal pck_loaded(success: bool)
signal first_launch_detected()

# Implementation reference
var _impl: Node = null

func _set_impl(impl: Node) -> void:
	_impl = impl
	# Forward signals
	if _impl.has_signal("update_available"):
		#_impl.update_available.connect(func(info): update_available.emit(info))
		print("update")
	if _impl.has_signal("update_check_failed"):
		_impl.update_check_failed.connect(func(err): update_check_failed.emit(err))
	if _impl.has_signal("no_update_available"):
		_impl.no_update_available.connect(func(): no_update_available.emit())
	if _impl.has_signal("pck_download_started"):
		_impl.pck_download_started.connect(func(total): pck_download_started.emit(total))
	if _impl.has_signal("pck_download_progress"):
		_impl.pck_download_progress.connect(func(down, total, pct): pck_download_progress.emit(down, total, pct))
	if _impl.has_signal("pck_download_completed"):
		_impl.pck_download_completed.connect(func(success): pck_download_completed.emit(success))
	if _impl.has_signal("pck_loaded"):
		_impl.pck_loaded.connect(func(success): pck_loaded.emit(success))
	if _impl.has_signal("first_launch_detected"):
		_impl.first_launch_detected.connect(func(): first_launch_detected.emit())

func _ready() -> void:
	pass  # Wait for impl injection

# Property forwarding
func _get(property: StringName) -> Variant:
	if _impl:
		return _impl.get(property)
	return null

func _set(property: StringName, value: Variant) -> bool:
	if _impl:
		_impl.set(property, value)
		return true
	return false

# Method forwarding
func is_first_launch() -> bool:
	if _impl: return _impl.is_first_launch()
	return false

func mark_first_launch_complete() -> void:
	if _impl: _impl.mark_first_launch_complete()

func get_loaded_pck_version() -> String:
	if _impl: return _impl.get_loaded_pck_version()
	return ""

func save_pck_version(version: String) -> void:
	if _impl: _impl.save_pck_version(version)

func check_for_updates() -> void:
	if _impl: _impl.check_for_updates()

func download_pck(pck_url: String) -> void:
	if _impl: _impl.download_pck(pck_url)

func load_pck() -> bool:
	if _impl: return _impl.load_pck()
	return false
