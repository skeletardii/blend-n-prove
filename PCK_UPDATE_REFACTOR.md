# Comprehensive Guide to Refactoring for Godot PCK Updates

This guide provides a detailed, step-by-step process for refactoring a Godot project to support in-game updates using a PCK (Godot Pack) file delivery system. This method allows for smaller initial application sizes and enables developers to push content updates without requiring users to reinstall the application.

## 1. Core Strategy: Base Package + Content Pack

The fundamental approach is to decouple the core application from its updatable content.

-   **Base Package (APK/IPA/EXE):** This is the minimal application installed by the user. It contains only the essential components:
    -   The Godot engine runtime.
    -   Core scripts, especially `autoload` singletons (`UpdateCheckerService.gd`, etc.).
    -   A minimal loading scene to manage the update process.
    -   Any assets required by the loading scene itself.

-   **Content PCK (`.pck` file):** This is a separate archive containing the bulk of the game's content. It is downloaded by the base application after the initial installation.
    -   All game assets: `assets/` (sprites, sounds, music, fonts).
    -   Game data: `data/` (level definitions, configurations).
    -   All scenes and their associated scripts that are not essential for the initial boot.

Updates are performed by downloading a new version of the `.pck` file.

## 2. Step-by-Step Refactoring Plan

### Step 2.1: Configure Export Presets (`export_presets.cfg`)

This is the most critical part of the process. You must define two distinct export presets in the `Project > Export...` menu.

#### a) Preset 1: The Base Application (e.g., "Android Base")

This preset builds the main application package that users will install from an app store.

1.  **Create Preset:** Add a new preset for your target platform (e.g., Android).
2.  **Name it:** Give it a clear name like `Android Base`.
3.  **Set Export Path:** Define the export path for your final `.apk` file.
4.  **Configure Resources:**
    -   Navigate to the **Resources** tab.
    -   Set **Export Mode** to **"Export selected resources (and their dependencies)"**. This is crucial. It ensures that only the resources you explicitly select, plus any scripts or assets they directly depend on, are included.
    -   **Crucially, you must now select what to include.** Since your main scene is likely `src/ui/MainMenu.tscn` and your autoloads are in `src/game/autoloads/`, these will be included by dependency. The most robust way to configure this is to **uncheck the folders that will be in the PCK**.
    -   **Action:** Uncheck the `assets/` and `data/` directories. This explicitly excludes them from the base APK. The rest of the project files (`project.godot`, scripts in `src/`, etc.) will be included because they are dependencies of the main scene and autoloads.

#### b) Preset 2: The Content PCK (e.g., "Content Pack")

This preset generates the `.pck` file that will be downloaded.

1.  **Create Preset:** Add a new **"Linux/X11"** preset. This platform is a convenient choice for exporting a bare PCK file.
2.  **Name it:** Give it a descriptive name like `Content Pack`.
3.  **Configure Resources:**
    -   Navigate to the **Resources** tab.
    -   Set **Export Mode** to **"Export selected resources (and their dependencies)"**.
    -   **Action:** This time, explicitly **check only the directories you want in the PCK file.** Select `assets/` and `data/`. Do not select anything else.
4.  **Export the PCK:**
    -   Click **"Export Project"**.
    -   In the file-saving dialog, **uncheck "Export With Debug"**.
    -   Name the file `game.pck` (or a versioned name like `content-v1.1.pck`). **Ensure the file extension is `.pck`**.

### Step 2.2: Enhance the Update Logic (`UpdateCheckerService.gd`)

Modify your `UpdateCheckerService.gd` singleton to handle the download and loading of the PCK file. The implementation should be robust, providing user feedback and handling potential errors.

```gdscript
# /src/game/autoloads/UpdateCheckerService.gd
extends Node

signal update_progress(percent)
signal update_finished(success)

# Assume you have a UI scene for showing update progress
var update_popup

func _on_update_available(version_info):
    """
    Called when the server confirms a new version is available.
    """
    var pck_url = version_info.get("download_url")
    if not pck_url or not pck_url.ends_with(".pck"):
        print_error("Invalid PCK URL from server.")
        emit_signal("update_finished", false)
        return

    var pck_path = "user://downloaded_content.pck"

    # Instantiate and show the update progress UI
    # update_popup = preload("res://src/ui/UpdatePopup.tscn").instance()
    # get_tree().get_root().add_child(update_popup)

    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.connect("request_completed", self, "_on_pck_download_completed", [http_request, pck_path])
    
    # Custom signal to handle download progress
    http_request.connect("body_chunk_received", self, "_on_download_progress")

    print("Starting PCK download from: ", pck_url)
    var error = http_request.download_file(pck_url, pck_path, true) # `true` for use_threads
    if error != OK:
        print_error("Failed to start PCK download.")
        emit_signal("update_finished", false)
        http_request.queue_free()

func _on_download_progress(chunk_size, total_size):
    """
    Emits a signal with the download progress percentage.
    Connect this to a ProgressBar in your UI.
    """
    if total_size > 0:
        var percent = (float(chunk_size) / total_size) * 100.0
        emit_signal("update_progress", percent)

func _on_pck_download_completed(result, response_code, headers, body, http_request, pck_path):
    """
    Handles the result of the PCK file download.
    """
    if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
        print_error("PCK download failed with response code: " + str(response_code))
        emit_signal("update_finished", false)
        http_request.queue_free()
        return

    print("PCK downloaded successfully. Attempting to load.")
    
    # Load the pack.
    if ProjectSettings.load_resource_pack(pck_path):
        print("PCK loaded successfully!")
        
        # Best practice: After loading, restart the game or reload the main scene
        # to ensure all new resources and scripts are correctly initialized.
        emit_signal("update_finished", true)
        get_tree().reload_current_scene() 
    else:
        print_error("Failed to load downloaded PCK pack at: " + pck_path)
        emit_signal("update_finished", false)
        
    http_request.queue_free()

```

### Step 2.3: Server-Side Requirements

1.  **Host the PCK file:** The `game.pck` file generated from your "Content Pack" export preset must be accessible via a public URL.
2.  **Update the Version JSON:** The JSON file that `UpdateCheckerService.gd` queries must be updated:
    -   Increment the `version` number.
    -   Set the `download_url` to the direct URL of the new `game.pck` file.

**Example `version.json`:**
```json
{
  "version": "1.1.0",
  "release_date": "2025-11-28",
  "notes": "New levels and bug fixes!",
  "download_url": "https://your-server.com/path/to/content-v1.1.0.pck"
}
```

## 3. Best Practices and Considerations

-   **Versioning:** Version your PCK files (e.g., `content-v1.1.0.pck`). This helps in managing downloads and caching. The base application can store the version of the currently loaded PCK and only download a new one if the server's version is different.
-   **User Experience:** Always provide clear feedback to the user. Use a dedicated loading/update screen with a progress bar. Handle download failures gracefully and allow the user to retry.
-   **Atomic Updates:** The download and replacement of PCK files should be an atomic operation. Download to a temporary file (`.pck_temp`) first. Only after a successful download, delete the old PCK and rename the temp file to the final name (`downloaded_content.pck`). This prevents a corrupted update if the download is interrupted.
-   **Restarting the Game:** The most reliable way to apply an update after loading a PCK is to restart the game or reload the main scene (`get_tree().reload_current_scene()`). This ensures that any newly loaded scripts or modified resources are correctly instantiated and initialized.
-   **Initial PCK:** For the very first launch, the application won't have a PCK file. You have two options:
    1.  **Include a PCK in the Base APK:** Bundle a version 1.0 PCK file in the `assets` of the APK itself, extract it on first launch, and load it locally. The updater then replaces this with newer versions.
    2.  **Force Download on First Launch:** Design your application to be a simple "downloader" on first launch. It must download the initial PCK before the user can play. This is simpler to implement but requires an internet connection for the first-time user experience.

This comprehensive guide provides a robust framework for implementing a PCK-based update system in your Godot project.
