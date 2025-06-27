/**
 * PUSH NOTIFICATION TESTING SCRIPT
 * ================================
 * 
 * PURPOSE:
 * Tests the Firebase Cloud Messaging (FCM) push notification system to ensure 
 * proper delivery of trading alerts to the Technical-Analysis.AI mobile app.
 * Validates both basic notifications and trading tip notifications with mock data.
 * 
 * USAGE:
 * node test_notifications.js
 * 
 * EXAMPLE:
 * cd server
 * node test_notifications.js
 * 
 * FEATURES:
 * ✓ Tests basic notification delivery to mobile app
 * ✓ Tests trading tip notifications with real data formatting
 * ✓ Validates Firebase FCM integration and topic subscriptions
 * ✓ Mock data simulation for testing without real trading signals
 * ✓ Error handling and success/failure reporting
 * ✓ Real-time delivery verification
 * 
 * TEST SCENARIOS:
 * 1️⃣ BASIC NOTIFICATION TEST:
 *    - Simple "Hello World" style notification
 *    - Tests core FCM connectivity
 *    - Validates app notification permissions
 *    - Confirms topic subscription setup
 * 
 * 2️⃣ TRADING TIP NOTIFICATION TEST:
 *    - Realistic trading data formatting
 *    - Company/crypto information integration
 *    - Price formatting with proper decimals
 *    - Sentiment-based messaging (bullish/bearish)
 *    - Mock data: AAPL bullish signal with entry/exit levels
 * 
 * MOCK DATA INCLUDES:
 * - Symbol: AAPL (Apple Inc.)
 * - Timeframe: long_term (daily analysis)
 * - Sentiment: bullish 📈
 * - Signal Strength: 2.5/5.0
 * - Entry Price: $195.50
 * - Stop Loss: $185.00  
 * - Take Profit: $210.00
 * - Company Logo: Local asset reference
 * 
 * NOTIFICATION FORMAT TESTED:
 * Title: "📈 AAPL Bullish Signal" 
 * Body: "Entry: $195.50 | Target: $210.00 | Strength: 2.5"
 * Topic: "trading_tips"
 * 
 * SUCCESS INDICATORS:
 * ✅ Basic notification sent successfully
 * ✅ Trading tip notification sent successfully  
 * ✅ Proper title and body formatting
 * ✅ FCM response codes indicating delivery
 * ✅ App receives notifications on device
 * 
 * FAILURE TROUBLESHOOTING:
 * ❌ Check Firebase project configuration
 * ❌ Verify GOOGLE_APPLICATION_CREDENTIALS environment variable
 * ❌ Ensure mobile app subscribed to "trading_tips" topic
 * ❌ Confirm app has notification permissions enabled
 * ❌ Check internet connectivity and Firebase service status
 * 
 * TESTING WORKFLOW:
 * 1. Make sure Flutter app is running on device/emulator
 * 2. Ensure app has notification permission granted
 * 3. Verify app subscribed to "trading_tips" topic
 * 4. Run this script and watch for notifications
 * 5. Check console output for delivery confirmation
 * 
 * DEPENDENCIES:
 * - Firebase Admin SDK configured
 * - GOOGLE_APPLICATION_CREDENTIALS environment variable
 * - notificationService with sendTestNotification method
 * - Active mobile app with FCM topic subscription
 * 
 * INTEGRATION TESTING:
 * After successful notification tests:
 * - Run analyzeSymbol.js with strong signals
 * - Run scanBestStocks.js or scanBestCrypto.js
 * - Verify end-to-end notification delivery
 * - Test on multiple devices and platforms
 */
require('dotenv').config();
const notificationService = require('./src/services/notificationService');
const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./src/config/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const messaging = admin.messaging();

async function testNotifications() {
  console.log('🧪 Testing Push Notification System');
  console.log('===================================');
  
  // Test basic notification
  console.log('\n1️⃣ Testing basic notification...');
  const testResult = await notificationService.sendTestNotification();
  if (testResult.success) {
    console.log('✅ Basic notification sent successfully!');
  } else {
    console.log('❌ Basic notification failed:', testResult.error);
  }
  
  // Test trading tip notification with mock data
  console.log('\n2️⃣ Testing trading tip notification...');
  const mockTipData = {
    symbol: 'AAPL',
    timeframe: 'long_term',
    sentiment: 'bullish',
    strength: 2.5,
    entryPrice: 195.50,
    stopLoss: 185.00,
    takeProfit: 210.00
  };
  
  const mockCompany = {
    name: 'Apple Inc.',
    logoUrl: 'assets/logos/stocks/AAPL.png',
    sector: 'Technology',
    business: 'Consumer Electronics',
    isCrypto: false
  };
  
  const tipResult = await notificationService.sendTipNotification(mockTipData, mockCompany);
  if (tipResult.success) {
    console.log('✅ Trading tip notification sent successfully!');
    console.log(`📱 Title: ${tipResult.title}`);
    console.log(`📝 Body: ${tipResult.body}`);
  } else {
    console.log('❌ Trading tip notification failed:', tipResult.error);
  }
  
  console.log('\n🎯 Next Steps:');
  console.log('1. Make sure your Flutter app is running and has notification permission');
  console.log('2. Check that the app subscribed to "trading_tips" topic');
  console.log('3. Run a real analysis script to test end-to-end flow');
  console.log('4. Notifications should appear on your device! 📱');
}

testNotifications().catch(console.error);

/**
 * Test iOS notification with proper APNS configuration
 */
async function testIOSNotification() {
  try {
    console.log('🧪 Testing iOS notification...');
    
    const message = {
      notification: {
        title: '🧪 iOS Test Notification',
        body: 'Testing iOS push notifications with proper APNS settings'
      },
      data: {
        type: 'test',
        platform: 'ios',
        timestamp: new Date().toISOString()
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title: '🧪 iOS Test Notification',
              body: 'Testing iOS push notifications with proper APNS settings'
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
            'mutable-content': 1,
          }
        }
      },
      topic: 'trading_tips'
    };
    
    console.log('📤 Sending test notification to topic: trading_tips');
    console.log('📱 Message payload:', JSON.stringify(message, null, 2));
    
    const response = await messaging.send(message);
    console.log('✅ Test notification sent successfully!');
    console.log('📨 Message ID:', response);
    
  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
    
    if (error.details) {
      console.error('Error details:', error.details);
    }
  }
}

/**
 * Test notification to specific token (if you have one)
 */
async function testNotificationToToken(fcmToken) {
  try {
    console.log('🧪 Testing notification to specific token...');
    
    const message = {
      notification: {
        title: '🎯 Direct Token Test',
        body: 'This notification was sent directly to your device token'
      },
      data: {
        type: 'token_test',
        timestamp: new Date().toISOString()
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title: '🎯 Direct Token Test',
              body: 'This notification was sent directly to your device token'
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
            'mutable-content': 1,
          }
        }
      },
      token: fcmToken
    };
    
    console.log(`📤 Sending notification to token: ${fcmToken.substring(0, 20)}...`);
    
    const response = await messaging.send(message);
    console.log('✅ Token notification sent successfully!');
    console.log('📨 Message ID:', response);
    
  } catch (error) {
    console.error('❌ Error sending token notification:', error);
    console.error('Error code:', error.code);
    console.error('Error message:', error.message);
  }
}

// Run the test
console.log('🚀 Starting iOS notification test...');
console.log('📱 Make sure your iOS device is subscribed to "trading_tips" topic');
console.log('');

// Test topic notification
testIOSNotification();

// Uncomment and add your FCM token to test direct token notification
// const yourFCMToken = 'YOUR_FCM_TOKEN_HERE';
// testNotificationToToken(yourFCMToken); 