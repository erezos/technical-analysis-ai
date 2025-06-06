#!/bin/bash

# Technical-Analysis.AI - Screenshot Resizer for iOS App Store
# Converts Android screenshots to iOS App Store requirements

echo "🔧 Technical-Analysis.AI - iOS Screenshot Resizer"
echo "================================================="

# Create output directory
mkdir -p ios_screenshots

# iPhone 6.7" Screenshots (1242x2688px)
echo "📱 Resizing for iPhone 6.7\" (1242x2688px)..."

# Process all PNG files in current directory
for file in *.png; do
    if [ -f "$file" ]; then
        echo "  📸 Processing: $file"
        convert "$file" -resize 1242x2688^ -gravity center -extent 1242x2688 -background black "ios_screenshots/ios_${file}"
    fi
done

# Process all JPG files too
for file in *.jpg *.jpeg; do
    if [ -f "$file" ]; then
        echo "  📸 Processing: $file"
        # Convert to PNG for iOS
        convert "$file" -resize 1242x2688^ -gravity center -extent 1242x2688 -background black "ios_screenshots/ios_${file%.*}.png"
    fi
done

echo ""
echo "✅ Screenshots resized for iOS!"
echo "📁 Check the 'ios_screenshots' folder"
echo ""
echo "📋 iOS Requirements:"
echo "   • Size: 1242x2688px (iPhone 6.7\")"
echo "   • Format: PNG"
echo "   • Minimum: 3 screenshots"
echo "   • Maximum: 10 screenshots"
echo ""
echo "🚀 Ready to upload to App Store Connect!" 