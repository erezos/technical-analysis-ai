const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./src/config/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const messaging = admin.messaging();

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