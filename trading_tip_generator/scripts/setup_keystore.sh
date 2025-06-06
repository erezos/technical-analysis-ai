#!/bin/bash

# Technical-Analysis.AI - Release Keystore Setup Script

echo "🚀 Technical-Analysis.AI - Setting up Release Keystore"
echo "================================================="

# Navigate to android directory
cd android

echo "📋 This script will help you create a release keystore for Google Play Store publishing."
echo ""
echo "⚠️  IMPORTANT: Save these credentials securely!"
echo "   - You'll need them for every app update"
echo "   - Store them in a password manager"
echo "   - Never commit them to version control"
echo ""

# Prompt for organization details
echo "📝 Please provide your organization details:"
read -p "Organization Name (e.g., Your Company): " org_name
read -p "Your Name: " dev_name
read -p "City: " city
read -p "State/Province: " state
read -p "Country Code (e.g., US): " country

echo ""
echo "🔐 Creating keystore with the following details:"
echo "   - Keystore: upload-keystore.jks"
echo "   - Alias: upload"
echo "   - Validity: 10000 days (~27 years)"
echo "   - Organization: $org_name"
echo "   - Developer: $dev_name"
echo ""

# Generate keystore
echo "🔑 Generating keystore..."
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -dname "CN=$dev_name, OU=Development, O=$org_name, L=$city, ST=$state, C=$country"

echo ""
echo "✅ Keystore created successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Create android/key.properties file with your passwords"
echo "2. Add the following content to android/key.properties:"
echo ""
echo "storePassword=your_keystore_password"
echo "keyPassword=your_key_password"
echo "keyAlias=upload"
echo "storeFile=upload-keystore.jks"
echo ""
echo "3. NEVER commit key.properties or upload-keystore.jks to version control!"
echo "4. Store these credentials safely - you'll need them for updates!"
echo ""
echo "🚀 Ready to build release APK/AAB for Google Play Store!" 