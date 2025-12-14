# App Icon Setup Instructions

## Icon Created ✅

I've created a new icon design for your Secure BDRS app:
- **SVG File**: `assets/icon/secure_bdrs_icon.svg`
- **Design**: Green padlock with circuit board on purple shield background

## To Generate App Icons:

### Option 1: Online Converter (Easiest)
1. Go to https://convertio.co/svg-png/ or https://cloudconvert.com/svg-to-png
2. Upload `assets/icon/secure_bdrs_icon.svg`
3. Set output size to **1024x1024** pixels
4. Download the PNG file
5. Save it as `assets/icon/secure_bdrs_icon.png`

### Option 2: Using Graphics Software
1. Open `assets/icon/secure_bdrs_icon.svg` in:
   - **Inkscape** (free): File → Export PNG → Set 1024x1024 → Export
   - **Adobe Illustrator**: File → Export → Export As → PNG → 1024x1024
   - **GIMP**: Open SVG → Scale to 1024x1024 → Export as PNG
2. Save as `assets/icon/secure_bdrs_icon.png`

### Option 3: Using Python (if you have Python installed)
```bash
pip install cairosvg pillow
python convert_icon.py
```

## After Converting to PNG:

Once you have `assets/icon/secure_bdrs_icon.png`:

1. **Generate app icons**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

2. **Rebuild your app** to see the new icon:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Icon Design Details:
- **Colors**: Bright green (#00FF88) on deep purple (#2D1B4E)
- **Elements**: Padlock (security) + Circuit board (technology) + Shield (protection)
- **Size**: 1024x1024 pixels (for app launcher icons)

---

**Note**: The `pubspec.yaml` is already configured to use `secure_bdrs_icon.png` once you create it.

