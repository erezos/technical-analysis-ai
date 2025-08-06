#!/usr/bin/env node

/**
 * Firebase Remote Config Setup Script
 * 
 * This script helps set up the geo-targeted URL system in Firebase Remote Config.
 * Run this script to initialize all the necessary parameters.
 * 
 * Usage: node scripts/setup_remote_config.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (you'll need to set up service account)
// const serviceAccount = require('../path/to/serviceAccountKey.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount)
// });

console.log('🌍 Firebase Remote Config Setup for Geo-Targeted URLs');
console.log('===================================================\n');

// Define all the geo-targeted URL parameters
const remoteConfigParameters = {
  trading_url_us: {
    value: 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=us_users',
    description: 'Trading platform URL for US users (ZuluTrade)',
    defaultValue: 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=us_users'
  },
  trading_url_eu: {
    value: 'https://www.trading212.com/ref/2915819?utm_source=2915819&utm_medium=affiliate&utm_campaign=eu_users',
    description: 'Trading platform URL for EU users (Trading212)',
    defaultValue: 'https://www.trading212.com/ref/2915819?utm_source=2915819&utm_medium=affiliate&utm_campaign=eu_users'
  },
  trading_url_uk: {
    value: 'https://www.trading212.com/ref/2915819?utm_source=2915819&utm_medium=affiliate&utm_campaign=uk_users',
    description: 'Trading platform URL for UK users (Trading212)',
    defaultValue: 'https://www.trading212.com/ref/2915819?utm_source=2915819&utm_medium=affiliate&utm_campaign=uk_users'
  },
  trading_url_ca: {
    value: 'https://www.questrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=ca_users',
    description: 'Trading platform URL for Canadian users (Questrade)',
    defaultValue: 'https://www.questrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=ca_users'
  },
  trading_url_au: {
    value: 'https://www.ig.com/au?utm_source=2915819&utm_medium=affiliate&utm_campaign=au_users',
    description: 'Trading platform URL for Australian users (IG)',
    defaultValue: 'https://www.ig.com/au?utm_source=2915819&utm_medium=affiliate&utm_campaign=au_users'
  },
  trading_url_asia: {
    value: 'https://www.ig.com/sg?utm_source=2915819&utm_medium=affiliate&utm_campaign=asia_users',
    description: 'Trading platform URL for Asian users (IG Singapore)',
    defaultValue: 'https://www.ig.com/sg?utm_source=2915819&utm_medium=affiliate&utm_campaign=asia_users'
  },
  trading_url_latam: {
    value: 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=latam_users',
    description: 'Trading platform URL for Latin American users (ZuluTrade)',
    defaultValue: 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=latam_users'
  },
  trading_url_default: {
    value: 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=global_users',
    description: 'Default trading platform URL for global users (ZuluTrade)',
    defaultValue: 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=global_users'
  }
};

/**
 * Manual Setup Instructions
 */
function printManualSetupInstructions() {
  console.log('📋 MANUAL SETUP INSTRUCTIONS');
  console.log('============================\n');
  
  console.log('1. Go to Firebase Console: https://console.firebase.google.com/');
  console.log('2. Select your project');
  console.log('3. Navigate to: Engage → Remote Config');
  console.log('4. Click "Add your first parameter" or "Add parameter"');
  console.log('5. Add each parameter below:\n');
  
  Object.entries(remoteConfigParameters).forEach(([key, config]) => {
    console.log(`📝 Parameter: ${key}`);
    console.log(`   Description: ${config.description}`);
    console.log(`   Value: ${config.value}`);
    console.log('');
  });
  
  console.log('6. After adding all parameters, click "Publish"');
  console.log('7. Your geo-targeted URL system will be active!\n');
}

/**
 * Firebase Admin Setup Instructions
 */
function printFirebaseAdminSetup() {
  console.log('🔧 FIREBASE ADMIN SETUP (Optional)');
  console.log('==================================\n');
  
  console.log('To use this script with Firebase Admin SDK:');
  console.log('');
  console.log('1. Download service account key from Firebase Console:');
  console.log('   - Go to Project Settings → Service Accounts');
  console.log('   - Click "Generate new private key"');
  console.log('   - Save as serviceAccountKey.json');
  console.log('');
  console.log('2. Uncomment the Firebase Admin initialization in this script');
  console.log('3. Update the path to your service account key');
  console.log('4. Run: node scripts/setup_remote_config.js\n');
}

/**
 * Test Configuration
 */
function printTestConfiguration() {
  console.log('🧪 TESTING CONFIGURATION');
  console.log('========================\n');
  
  console.log('After setup, test with:');
  console.log('');
  console.log('1. Run the Flutter app: flutter run');
  console.log('2. Check logs for location detection:');
  console.log('   - Look for: "🌍 Enhanced location detection complete"');
  console.log('   - Look for: "🎯 Geo-targeted URL fetched"');
  console.log('');
  console.log('3. Test different regions:');
  console.log('   - Use VPN to test different countries');
  console.log('   - Check that correct URLs are generated');
  console.log('');
  console.log('4. Verify Firebase Analytics events:');
  console.log('   - geo_targeted_url_fetched');
  console.log('   - location_detection_success');
  console.log('');
}

/**
 * Country-to-Region Mapping
 */
function printRegionMapping() {
  console.log('🗺️  COUNTRY-TO-REGION MAPPING');
  console.log('=============================\n');
  
  const mapping = {
    'US': 'US → ZuluTrade',
    'GB': 'UK → Trading212',
    'CA': 'CA → Questrade',
    'AU': 'AU → IG',
    'DE, FR, IT, ES, NL, BE, AT, CH': 'EU → Trading212',
    'JP, KR, SG, HK, TW': 'ASIA → IG Singapore',
    'BR, MX, AR, CL, CO': 'LATAM → ZuluTrade',
    'Others': 'GLOBAL → ZuluTrade'
  };
  
  Object.entries(mapping).forEach(([countries, platform]) => {
    console.log(`   ${countries}: ${platform}`);
  });
  
  console.log('');
}

/**
 * Analytics Setup
 */
function printAnalyticsSetup() {
  console.log('📊 ANALYTICS SETUP');
  console.log('==================\n');
  
  console.log('The app automatically tracks:');
  console.log('');
  console.log('✅ Location detection success/failure');
  console.log('✅ Geo-targeted URL fetch success/failure');
  console.log('✅ Trading platform launches');
  console.log('✅ Fallback URL usage');
  console.log('✅ Regional performance metrics');
  console.log('');
  console.log('View analytics in Firebase Console:');
  console.log('- Go to Analytics → Events');
  console.log('- Filter by custom events');
  console.log('- Monitor regional conversion rates');
  console.log('');
}

/**
 * Troubleshooting Guide
 */
function printTroubleshooting() {
  console.log('🔧 TROUBLESHOOTING');
  console.log('==================\n');
  
  console.log('Common Issues:');
  console.log('');
  console.log('❌ "Remote Config not initialized"');
  console.log('   → Check Firebase project configuration');
  console.log('   → Verify internet connectivity');
  console.log('');
  console.log('❌ "Wrong region detected"');
  console.log('   → Check IP geolocation service');
  console.log('   → Verify device locale settings');
  console.log('');
  console.log('❌ "URL not loading"');
  console.log('   → Verify parameter names in Remote Config');
  console.log('   → Check fallback URLs in code');
  console.log('');
  console.log('❌ "Location detection failed"');
  console.log('   → Check ipapi.co service availability');
  console.log('   → Verify network permissions');
  console.log('');
}

// Main execution
function main() {
  printManualSetupInstructions();
  printRegionMapping();
  printFirebaseAdminSetup();
  printTestConfiguration();
  printAnalyticsSetup();
  printTroubleshooting();
  
  console.log('🎉 SETUP COMPLETE!');
  console.log('==================\n');
  console.log('Your geo-targeted URL system is ready to deploy!');
  console.log('');
  console.log('Next steps:');
  console.log('1. Follow the manual setup instructions above');
  console.log('2. Test with the Flutter app');
  console.log('3. Monitor analytics in Firebase Console');
  console.log('4. Deploy to production when ready');
  console.log('');
}

// Run the script
if (require.main === module) {
  main();
}

module.exports = {
  remoteConfigParameters,
  printManualSetupInstructions,
  printRegionMapping
}; 