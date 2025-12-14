"""
Script to convert SVG icon to PNG for Flutter launcher icons
Requires: pip install cairosvg pillow
"""

try:
    import cairosvg
    from PIL import Image
    import io
    import os
    
    # Convert SVG to PNG
    svg_path = "assets/icon/secure_bdrs_icon.svg"
    png_path = "assets/icon/secure_bdrs_icon.png"
    
    if not os.path.exists(svg_path):
        print(f"Error: {svg_path} not found!")
        exit(1)
    
    # Convert SVG to PNG (1024x1024 for app icons)
    png_data = cairosvg.svg2png(url=svg_path, output_width=1024, output_height=1024)
    
    # Save PNG file
    with open(png_path, 'wb') as f:
        f.write(png_data)
    
    print(f"✓ Successfully converted {svg_path} to {png_path}")
    print(f"  Size: 1024x1024 pixels")
    
except ImportError:
    print("Error: Required packages not installed.")
    print("Please install: pip install cairosvg pillow")
    print("\nAlternatively, you can:")
    print("1. Use an online SVG to PNG converter")
    print("2. Open the SVG in a browser and export as PNG (1024x1024)")
    print("3. Use Inkscape or another vector graphics tool")
except Exception as e:
    print(f"Error: {e}")
    print("\nAlternative: Use an online converter or graphics tool")

