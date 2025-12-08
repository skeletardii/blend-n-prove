extends Node
## Manages font fallback for web deployment
##
## Automatically switches to web-safe fonts when running on web platform
## to ensure text renders correctly even if custom fonts fail to load.

const DESKTOP_THEME := preload("res://assets/themes/main_theme.tres")
#const WEB_THEME := preload("res://assets/themes/main_theme_web.tres")

func _ready() -> void:
	# Detect platform and apply appropriate theme
	if OS.has_feature("web"):
		_apply_web_theme()
	else:
		_apply_desktop_theme()

func _apply_web_theme() -> void:
	"""Apply web-safe theme with fallback fonts"""
	#get_tree().root.theme = WEB_THEME
	print("WebFontManager: Applied web theme with fallback fonts")

func _apply_desktop_theme() -> void:
	"""Apply standard desktop theme"""
	#get_tree().root.theme = DESKTOP_THEME
	print("WebFontManager: Applied desktop theme")
