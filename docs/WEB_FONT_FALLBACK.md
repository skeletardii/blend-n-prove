# Web Font Fallback System

## Overview
This project includes an automatic font fallback system for web deployments to ensure text renders correctly even if custom fonts fail to load.

## How It Works

### Automatic Detection
The `WebFontManager` autoload automatically detects when the game is running on a web platform and switches to web-safe fonts.

### Font Resources

1. **main_font_with_fallback.tres** - FontVariation (currently configured with custom font only)
   - Primary: TT Octosquares Trial DemiBold
2. **main_theme_web.tres** - Web-specific theme using fonts with fallback

### Files Added

- `assets/fonts/main_font_with_fallback.tres` - Custom font resource
- `assets/themes/main_theme_web.tres` - Web-optimized theme
- `src/game/autoloads/WebFontManager.gd` - Automatic platform detection

## Testing

### Desktop
Run normally - uses standard theme with custom fonts.

### Web
When running on web platform:
1. WebFontManager detects the web platform
2. Automatically switches to `main_theme_web.tres`
3. If custom font fails, falls back to Arial/Helvetica/sans-serif

## Manual Override

To manually test web fonts in the editor:
```gdscript
ThemeDB.set_project_theme(preload("res://assets/themes/main_theme_web.tres"))
```

## Build Notes

No special export configuration needed - the system works automatically based on platform detection using `OS.has_feature("web")`.
