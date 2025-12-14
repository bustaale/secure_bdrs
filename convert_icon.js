/**
 * Convert SVG icon to PNG for Flutter launcher icons
 * Requires: npm install sharp
 */

const fs = require('fs');
const path = require('path');

async function convertIcon() {
  try {
    // Check if sharp is installed
    let sharp;
    try {
      sharp = require('sharp');
    } catch (e) {
      console.log('Error: sharp package not installed.');
      console.log('Please install it: npm install sharp');
      console.log('\nAlternatively, use an online converter:');
      console.log('1. Go to https://convertio.co/svg-png/');
      console.log('2. Upload assets/icon/secure_bdrs_icon.svg');
      console.log('3. Set size to 1024x1024');
      console.log('4. Download and save as assets/icon/secure_bdrs_icon.png');
      process.exit(1);
    }

    const svgPath = path.join(__dirname, 'assets', 'icon', 'secure_bdrs_icon.svg');
    const pngPath = path.join(__dirname, 'assets', 'icon', 'secure_bdrs_icon.png');

    if (!fs.existsSync(svgPath)) {
      console.log(`Error: ${svgPath} not found!`);
      process.exit(1);
    }

    // Convert SVG to PNG
    await sharp(svgPath)
      .resize(1024, 1024)
      .png()
      .toFile(pngPath);

    console.log('✓ Successfully converted SVG to PNG!');
    console.log(`  Input: ${svgPath}`);
    console.log(`  Output: ${pngPath}`);
    console.log(`  Size: 1024x1024 pixels\n`);
    console.log('Next step: Run "flutter pub run flutter_launcher_icons"');

  } catch (error) {
    console.error('Error:', error.message);
    console.log('\nAlternative: Use an online SVG to PNG converter');
    process.exit(1);
  }
}

convertIcon();

