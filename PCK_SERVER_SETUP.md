# PCK-Based Update Server Setup Guide

## Overview

This guide shows you how to set up the server infrastructure for hosting PCK files and the version manifest for Fusion Rush's update system.

**Repository:** `fusion-rush/fusion-rush.github.io`
**Hosting:** GitHub Pages (automatically serves from `main` branch)

---

## File Structure

Create the following structure in your `fusion-rush.github.io` repository:

```
fusion-rush.github.io/
├── version.json                    # Version manifest (REQUIRED)
├── pck/                            # PCK files directory
│   ├── fusion-rush-content-v0.1.pck
│   ├── fusion-rush-content-v0.2.pck
│   └── ... (future versions)
└── apk/                            # Base APK files (optional)
    └── Fusion-Rush-Base-v0.1.apk
```

---

## Step 1: Export the Content PCK

### From Godot Editor:

1. Open your Godot project
2. Go to **Project > Export...**
3. Select **"Content Pack"** preset (Linux/X11)
4. Click **"Export Project"**
5. **IMPORTANT:** Uncheck "Export With Debug"
6. Save as: `fusion-rush-content-v0.1.pck`
7. Note the file size (should be ~31-32 MB)

### Verify the Export:

```bash
# Check file size
ls -lh fusion-rush-content-v0.1.pck

# Expected: ~31-32 MB
# If significantly different, check export filters in export_presets.cfg
```

---

## Step 2: Upload PCK to GitHub Pages

### Create Directory Structure:

```bash
cd fusion-rush.github.io
mkdir -p pck
```

### Upload PCK File:

```bash
# Copy exported PCK to repository
cp /path/to/fusion-rush-content-v0.1.pck pck/

# Add to git
git add pck/fusion-rush-content-v0.1.pck

# Commit
git commit -m "Add initial PCK v0.1"

# Push to GitHub
git push origin main
```

### Verify Upload:

After pushing, wait 1-2 minutes for GitHub Pages to deploy, then test the URL:

```
https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck
```

Opening this URL in a browser should download the PCK file.

---

## Step 3: Create/Update version.json

### NEW Format (PCK-based):

Create or update `version.json` in the repository root:

```json
{
  "version": "0.1",
  "pck_url": "https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck",
  "pck_size": 32505856,
  "header": "Content Available",
  "changelog": "- Initial release\n- 6 difficulty levels\n- Tutorial system\n- Boolean logic gameplay",
  "message": "Download content to start playing Fusion Rush!"
}
```

### Field Descriptions:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | String | ✅ Yes | PCK version (e.g., "0.1", "0.2") |
| `pck_url` | String | ✅ Yes | Direct URL to PCK file, must end with `.pck` |
| `pck_size` | Number | ❌ Optional | File size in bytes (for UI display) |
| `header` | String | ✅ Yes | Header text shown in update dialog |
| `changelog` | String | ✅ Yes | What's new (supports `\n` for newlines) |
| `message` | String | ✅ Yes | Additional message to user |

### Breaking Change from Old Format:

**OLD (APK-based):**
```json
{
  "version": "0.1",
  "download_url": "https://example.com/app.apk",  // ❌ No longer used
  "header": "...",
  "changelog": "...",
  "message": "..."
}
```

**NEW (PCK-based):**
```json
{
  "version": "0.1",
  "pck_url": "https://fusion-rush.github.io/pck/content.pck",  // ✅ Required
  "pck_size": 32505856,  // ✅ Optional but recommended
  "header": "...",
  "changelog": "...",
  "message": "..."
}
```

---

## Step 4: Commit and Deploy version.json

```bash
# Create/update version.json
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

# Add to git
git add version.json

# Commit
git commit -m "Update version.json for PCK-based updates v0.1"

# Push
git push origin main
```

### Verify Deployment:

Wait 1-2 minutes, then test:

```bash
curl https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json
```

You should see your JSON content returned.

---

## Step 5: Verify Complete Setup

### Test Checklist:

1. **PCK URL is accessible:**
   ```bash
   curl -I https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck
   # Should return: HTTP/2 200
   ```

2. **version.json is accessible:**
   ```bash
   curl https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json
   # Should return valid JSON
   ```

3. **PCK URL ends with .pck:**
   - Check that `pck_url` field ends with `.pck`
   - UpdateCheckerService validates this

4. **File size matches:**
   ```bash
   # Get remote file size
   curl -sI https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck | grep -i content-length

   # Compare with pck_size in version.json
   ```

---

## Releasing Updates (v0.2, v0.3, etc.)

### 1. Export New PCK:

```bash
# In Godot, export with new version number
# Save as: fusion-rush-content-v0.2.pck
```

### 2. Upload to GitHub:

```bash
cp fusion-rush-content-v0.2.pck pck/
git add pck/fusion-rush-content-v0.2.pck
git commit -m "Add PCK v0.2 - New levels and features"
git push
```

### 3. Update version.json:

```json
{
  "version": "0.2",
  "pck_url": "https://fusion-rush.github.io/pck/fusion-rush-content-v0.2.pck",
  "pck_size": 33123456,
  "header": "NEW UPDATE AVAILABLE",
  "changelog": "- Added 3 new difficulty levels\n- Fixed tutorial bugs\n- Improved UI animations",
  "message": "Update now to get the latest content!"
}
```

```bash
git add version.json
git commit -m "Release v0.2"
git push
```

### 4. Users Auto-Update:

- Users launch the app
- UpdateCheckerService checks version.json
- Sees local PCK is v0.1, remote is v0.2
- Shows update dialog
- Downloads new PCK on user confirmation

---

## Bandwidth Considerations

### GitHub Pages Limits:

- **Soft limit:** 100 GB/month bandwidth
- **File size limit:** 100 MB per file (your PCK is ~31 MB, safe)
- **Recommended users:** Up to ~3,000 downloads/month

### Monitoring:

GitHub doesn't provide real-time bandwidth metrics. If you approach limits:

1. **Use a CDN:**
   - Cloudflare (free tier)
   - jsDelivr (automatically mirrors GitHub releases)
   - AWS CloudFront

2. **Host on GitHub Releases:**
   ```bash
   gh release create v0.1 \
     --title "Fusion Rush v0.1" \
     --notes "Initial release" \
     pck/fusion-rush-content-v0.1.pck
   ```

   Then update `pck_url`:
   ```
   https://github.com/fusion-rush/fusion-rush/releases/download/v0.1/fusion-rush-content-v0.1.pck
   ```

3. **Alternative Hosting:**
   - Google Cloud Storage
   - AWS S3
   - DigitalOcean Spaces

---

## Troubleshooting

### Issue: "PCK download failed"

**Cause:** 404 error or CORS issue

**Solution:**
```bash
# Test URL manually
curl -v https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck

# Check for typos in version.json pck_url
# Ensure file is committed and pushed
# Wait 2-3 minutes for GitHub Pages deployment
```

### Issue: "Invalid or missing fields in version data"

**Cause:** Missing required field in version.json

**Solution:**
```bash
# Validate JSON syntax
cat version.json | jq .

# Ensure all required fields present:
# - version
# - pck_url
# - header
# - changelog
# - message

# Check pck_url ends with .pck
```

### Issue: "Downloaded PCK is too small"

**Cause:** Partial download or wrong file exported

**Solution:**
1. Re-export PCK from Godot with correct preset
2. Verify local PCK file size is ~31 MB
3. Re-upload to GitHub
4. Clear GitHub Pages cache (wait 5 minutes)

### Issue: "PCK loaded successfully but assets missing"

**Cause:** Export filters excluded assets from PCK

**Solution:**
1. Check `export_presets.cfg` preset 2 (Content Pack)
2. Verify `include_filter="*.json,res://assets/*,res://data/*"`
3. Re-export PCK
4. Test locally by loading PCK in Godot editor

---

## Testing Locally

### Test PCK Download Without Publishing:

1. **Run local web server:**
   ```bash
   cd fusion-rush.github.io
   python3 -m http.server 8000
   ```

2. **Update local version.json:**
   ```json
   {
     "version": "0.1",
     "pck_url": "http://localhost:8000/pck/fusion-rush-content-v0.1.pck",
     ...
   }
   ```

3. **Test in Godot editor:**
   - Temporarily change `VERSION_CHECK_URL` in AppConstants.gd to:
     ```
     http://localhost:8000/version.json
     ```
   - Run project
   - Verify download works

4. **Revert changes before deploying**

---

## Version Naming Convention

### Recommended Format:

```
fusion-rush-content-v{MAJOR}.{MINOR}.pck
```

### Examples:

- `fusion-rush-content-v0.1.pck` - Initial release
- `fusion-rush-content-v0.2.pck` - Minor update (new levels)
- `fusion-rush-content-v1.0.pck` - Major release
- `fusion-rush-content-v1.1.pck` - Minor update after major

### Benefits:

- Version in filename matches `version` field in JSON
- Easy to track which PCK corresponds to which release
- CDNs cache based on URL (new version = new URL = no stale cache)

---

## Security Considerations

### HTTPS Only:

- ✅ GitHub Pages serves over HTTPS by default
- ✅ Godot's HTTPRequest validates SSL certificates
- ❌ Do NOT use `http://` URLs in production

### File Integrity (Future Enhancement):

Consider adding MD5/SHA256 hash to version.json:

```json
{
  "version": "0.1",
  "pck_url": "...",
  "pck_md5": "a1b2c3d4e5f6...",
  ...
}
```

Then verify in UpdateCheckerService before loading.

---

## Quick Reference

### URLs:

- **Version manifest:** `https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json`
- **PCK download:** `https://fusion-rush.github.io/pck/fusion-rush-content-v{VERSION}.pck`

### Commands:

```bash
# Export PCK (in Godot UI, preset "Content Pack")
# Upload PCK
git add pck/fusion-rush-content-v0.X.pck
git commit -m "Add PCK vX.X"
git push

# Update version.json
# (edit file manually)
git add version.json
git commit -m "Release vX.X"
git push
```

### Testing:

```bash
# Test PCK URL
curl -I https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck

# Test version.json
curl https://raw.githubusercontent.com/fusion-rush/fusion-rush.github.io/refs/heads/main/version.json | jq .

# Test file size
curl -sI https://fusion-rush.github.io/pck/fusion-rush-content-v0.1.pck | grep -i content-length
```

---

## Complete Deployment Checklist

Before releasing an update:

- [ ] PCK exported from Godot with correct preset
- [ ] PCK file size is reasonable (~31 MB)
- [ ] PCK uploaded to `pck/` directory
- [ ] version.json updated with new version number
- [ ] version.json `pck_url` points to correct PCK file
- [ ] version.json `pck_url` ends with `.pck`
- [ ] All required JSON fields present
- [ ] Changes committed and pushed to GitHub
- [ ] Waited 2-3 minutes for GitHub Pages deployment
- [ ] Tested PCK URL in browser (downloads file)
- [ ] Tested version.json URL (returns JSON)
- [ ] Tested update flow on Android device (if possible)

---

**Setup is complete!** Your PCK-based update system is now ready to serve updates to Fusion Rush users.
