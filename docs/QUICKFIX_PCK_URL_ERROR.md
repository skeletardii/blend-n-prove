# Quick Fix: "Missing required field: pck_url" Error

## Problem

You're seeing this error when launching the game:

```
UpdateChecker: Missing required field: pck_url
UpdateChecker ERROR: Invalid or missing fields in version data
MainMenu: Update check failed: Invalid or missing fields in version data
```

## Root Cause

Your `version.json` file on the server still has the **old format** with `download_url` instead of the **new required field** `pck_url`.

The updated `UpdateCheckerService.gd` now requires `pck_url` as part of the PCK-based update system.

---

## Solution 1: Update version.json on Server (Production Fix)

### Current version.json (OLD format):
```json
{
  "version": "0.2",
  "download_url": "https://github.com/fusion-rush/fusion-rush.github.io/raw/main/...",
  "header": "NEW UPDATE",
  "changelog": "...",
  "message": "hello hahaha"
}
```

### Required version.json (NEW format):
```json
{
  "version": "0.1",
  "pck_url": "https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck",
  "pck_size": 32505856,
  "header": "Content Available",
  "changelog": "- Initial release\n- 6 difficulty levels\n- Tutorial system",
  "message": "Download content to start playing Fusion Rush!"
}
```

### Steps to Fix:

1. **Create the PCK file first** (if you haven't already):
   - Open Godot
   - Go to Project > Export...
   - Select "Content Pack" preset
   - Export as `fusion-rush-content-v0.1.pck`

2. **Upload to GitHub Pages:**
   ```bash
   cd fusion-rush.github.io
   mkdir -p pck
   cp /path/to/fusion-rush-content-v0.1.pck pck/
   git add pck/
   git commit -m "Add initial PCK v0.1"
   git push
   ```

3. **Update version.json:**
   ```bash
   cd fusion-rush.github.io

   # Create new version.json
   cat > version.json << 'EOF'
   {
     "version": "0.1",
     "pck_url": "https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck",
     "pck_size": 32505856,
     "header": "Content Available",
     "changelog": "- Initial release\n- 6 difficulty levels\n- Tutorial system\n- Boolean logic gameplay",
     "message": "Download content to start playing Fusion Rush!"
   }
   EOF

   git add version.json
   git commit -m "Update version.json for PCK-based system"
   git push
   ```

4. **Wait 2-3 minutes** for GitHub Pages to deploy

5. **Verify:**
   ```bash
   curl https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json
   # Should show new JSON with pck_url
   ```

---

## Solution 2: Temporary Testing Fix (Disable Update Check)

If you want to test locally without setting up the server first:

### Option A: Comment out update check in MainMenu.gd

**File:** `src/ui/MainMenu.gd` (line ~33)

```gdscript
func _ready() -> void:
    # FIRST: Check if PCK is loaded
    if not _is_pck_loaded():
        print("MainMenu: PCK not loaded, checking for first launch...")
        _handle_first_launch_or_update()
        return

    AudioManager.start_menu_music()
    GameManager.game_state_changed.connect(_on_game_state_changed)

    # Temporarily disable update check for testing
    # _check_for_app_updates()  # <-- Comment this out

    # Rest of code...
```

### Option B: Make pck_url optional (temporary workaround)

**File:** `src/game/autoloads/UpdateCheckerService.gd` (line ~149)

Change validation to make `pck_url` optional temporarily:

```gdscript
func _validate_json_data(data) -> bool:
    """Enhanced validation requiring pck_url"""
    if typeof(data) != TYPE_DICTIONARY:
        print("UpdateChecker: Data is not a Dictionary")
        return false

    # Required fields for PCK system
    # TEMPORARY: Make pck_url optional for backward compatibility
    var required_fields = ["version", "header", "changelog", "message"]  # Removed "pck_url"
    for field in required_fields:
        if not data.has(field):
            print("UpdateChecker: Missing required field: ", field)
            return false

        if typeof(data[field]) != TYPE_STRING:
            print("UpdateChecker: Field '", field, "' is not a String")
            return false

    # Optional: Validate pck_url if present
    if data.has("pck_url"):
        if not data["pck_url"].ends_with(".pck"):
            print("UpdateChecker: pck_url must end with .pck")
            return false

    return true
```

**⚠️ Warning:** This is only for testing. Revert this change before production!

---

## Solution 3: Test with Local Server

Set up a local test server while you prepare the production setup:

### 1. Create local test directory:

```bash
mkdir -p test-server/pck
cd test-server

# Copy your exported PCK
cp /path/to/fusion-rush-content-v0.1.pck pck/

# Create local version.json
cat > version.json << 'EOF'
{
  "version": "0.1",
  "pck_url": "http://localhost:8000/pck/fusion-rush-content-v0.1.pck",
  "pck_size": 32505856,
  "header": "Local Test",
  "changelog": "- Testing PCK system",
  "message": "Local test version"
}
EOF
```

### 2. Start local server:

```bash
# Python 3
python3 -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

### 3. Temporarily change URL in AppConstants.gd:

```gdscript
const VERSION_CHECK_URL: String = "http://localhost:8000/version.json"
// Instead of: https://raw.githubusercontent.com/fusion-rush/...
```

### 4. Test in editor

Launch the game and verify it downloads from localhost.

### 5. Revert AppConstants.gd before building for production!

---

## Recommended Approach

**For immediate testing:**
1. Use Solution 2, Option A (comment out update check)
2. This lets you test the rest of the game without server setup

**For production:**
1. Follow Solution 1 completely
2. Export base APK + content PCK
3. Upload PCK to GitHub Pages
4. Update version.json with `pck_url` field
5. Test on actual device

---

## Verification Checklist

After applying the fix:

- [ ] version.json on server has `pck_url` field
- [ ] `pck_url` ends with `.pck`
- [ ] PCK file is uploaded and accessible at `pck_url`
- [ ] All required fields present: version, pck_url, header, changelog, message
- [ ] JSON is valid (test with `curl ... | jq .`)
- [ ] App launches without "Missing required field" error

---

## Quick Test Command

```bash
# Test your version.json
curl https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json | jq .

# Should output valid JSON with pck_url field
# Example:
# {
#   "version": "0.1",
#   "pck_url": "https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck",
#   ...
# }
```

---

## Still Having Issues?

### Error persists after updating version.json?

1. **Clear local cache:**
   ```bash
   # On Android device
   adb shell pm clear com.example.fusionrush
   ```

2. **Verify GitHub Pages deployed:**
   - Wait 2-3 minutes after pushing
   - Check repository Settings > Pages for deployment status

3. **Check URL is correct:**
   ```bash
   # The URL in AppConstants.gd should be:
   const VERSION_CHECK_URL: String = "https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json"
   ```

4. **Verify PCK exists:**
   ```bash
   curl -I https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck
   # Should return: HTTP/2 200
   ```

### Need help debugging?

Check logs:
```bash
adb logcat | grep -E "(UpdateChecker|MainMenu|version|pck_url)"
```

Look for:
- `UpdateChecker: Checking for updates at ...` (verifying URL)
- `UpdateChecker: Missing required field: ...` (field validation)
- Response body printed by UpdateCheckerService

---

## Summary

**The error occurs because:** Your server's `version.json` still has `download_url` instead of `pck_url`.

**Quick fix:** Update `version.json` on your server to include `pck_url` field pointing to your PCK file.

**Production fix:** Follow Solution 1 to properly set up the PCK-based update system.
