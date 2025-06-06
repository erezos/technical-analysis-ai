const { admin } = require('../config/firebase');

class NotificationService {
  constructor() {
    this.messaging = admin.messaging();
  }

  /**
   * Send push notification for new trading tip
   * @param {Object} tipData - The trading tip data
   * @param {Object} company - Company information with logo
   */
  async sendTipNotification(tipData, company) {
    try {
      console.log('📱 Preparing push notification...');
      
      const { symbol, timeframe, sentiment, strength, entryPrice } = tipData;
      const companyName = company.name || symbol;
      
      // Format timeframe for display
      const timeframeDisplay = timeframe.replace('_', ' ').toUpperCase();
      
      // Create notification content
      const title = `🚀 New ${timeframeDisplay} Tip: ${companyName}`;
      const body = `${sentiment.toUpperCase()} signal (${Math.abs(strength).toFixed(1)}) - Entry: $${entryPrice?.toFixed(2) || 'TBD'}`;
      
      // Use local company logo asset path for rich notification
      const logoAssetPath = company.logoUrl;
      
      // Build the notification message
      const message = {
        notification: {
          title: title,
          body: body,
          // Note: FCM doesn't support local assets in notifications
          // We'll use a default icon and save logo display for in-app
        },
        data: {
          type: 'trading_tip',
          symbol: symbol,
          timeframe: timeframe,
          sentiment: sentiment,
          strength: strength.toString(),
          companyName: companyName,
          companyLogo: logoAssetPath, // Pass for in-app display
          entryPrice: entryPrice?.toString() || '',
          timestamp: new Date().toISOString()
        },
        android: {
          notification: {
            icon: 'ic_notification', // Default notification icon
            color: sentiment === 'bullish' ? '#4CAF50' : '#F44336',
            channelId: 'trading_tips',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              category: 'TRADING_TIP'
            }
          }
        },
        // Send to topic for all users (we'll implement user-specific tokens later)
        topic: 'trading_tips'
      };
      
      console.log('📤 Sending notification:', {
        title: message.notification.title,
        body: message.notification.body,
        symbol: symbol,
        sentiment: sentiment
      });
      
      // Send the notification
      const response = await this.messaging.send(message);
      console.log('✅ Notification sent successfully:', response);
      
      return {
        success: true,
        messageId: response,
        title: title,
        body: body
      };
      
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Send test notification
   */
  async sendTestNotification() {
    try {
      const message = {
        notification: {
          title: '🧪 Trading Tip Generator Test',
          body: 'Push notifications are working! 🎉'
        },
        data: {
          type: 'test',
          timestamp: new Date().toISOString()
        },
        topic: 'trading_tips'
      };
      
      const response = await this.messaging.send(message);
      console.log('✅ Test notification sent:', response);
      return { success: true, messageId: response };
      
    } catch (error) {
      console.error('❌ Error sending test notification:', error);
      return { success: false, error: error.message };
    }
  }
}

module.exports = new NotificationService(); 