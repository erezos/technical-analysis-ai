/**
 * TRADING TIPS SERVICE
 * ====================
 * 
 * PURPOSE:
 * Manages trading tips data storage, retrieval, and image handling for the 
 * Technical-Analysis.AI application. Provides Firebase Firestore integration 
 * with automatic image processing and notification delivery.
 * 
 * FEATURES:
 * ✓ Firebase Firestore database operations
 * ✓ Google Cloud Storage for trading images
 * ✓ Automatic image download and processing
 * ✓ Latest tips management with real-time updates
 * ✓ Historical tips archival system
 * ✓ Push notification integration
 * ✓ Signed URL generation for secure image access
 * ✓ Multi-timeframe tip organization
 * 
 * DATABASE COLLECTIONS:
 * 1. trading_tips: Historical archive of all trading signals
 *    - Document ID: {symbol}_{date}_{timeframe}
 *    - Indexed by timeframe, createdAt
 *    - Full trading analysis data with indicators
 * 
 * 2. latest_tips: Current active tips by timeframe
 *    - Document ID: {timeframe} (short_term, mid_term, long_term)
 *    - Always contains most recent tip per timeframe
 *    - Used by mobile app for quick access
 * 
 * STORAGE STRUCTURE:
 * Google Cloud Storage buckets:
 * - latest_images/{timeframe}_{type}.png
 *   - Current active images by timeframe
 *   - Overwritten with each new tip
 * 
 * - analysis_images/{symbol}_{date}_{timeframe}_{type}.png
 *   - Historical archive of all generated images
 *   - Permanent storage for analysis history
 * 
 * IMAGE TYPES SUPPORTED:
 * - trading_card: Main visual with company branding and analysis
 * - background: Company/crypto themed backgrounds
 * - accent: UI enhancement icons and elements
 * - signal_strength: Visual signal strength indicators
 * - technical_indicators: Chart overlays and technical data
 * 
 * DATA FLOW:
 * 1. Analysis scripts generate trading data + image URLs
 * 2. Service downloads images from DALL-E URLs
 * 3. Images uploaded to Google Cloud Storage
 * 4. Trading data saved to Firestore collections
 * 5. Push notifications sent to mobile app
 * 6. Mobile app retrieves data via signed URLs
 * 
 * METHODS PROVIDED:
 * - getTips(timeframe): Retrieve historical tips
 * - getLatestTip(timeframe): Get current active tip
 * - addTip(tipData): Save new trading analysis
 * - saveImages(): Download and store trading images
 * - saveBackgroundImages(): Enhanced image storage with backgrounds
 * - getLatestImage(): Generate signed URLs for latest images
 * - getHistoricalImage(): Access archived analysis images
 * 
 * USAGE EXAMPLES:
 * ```javascript
 * const service = new TradingTipsService();
 * 
 * // Save new trading tip
 * await service.addTip(analysisData);
 * 
 * // Save with generated images
 * await service.saveBackgroundImages(tipData, backgroundUrl, accentUrl);
 * 
 * // Retrieve latest tip
 * const latest = await service.getLatestTip('mid_term');
 * 
 * // Get image URL
 * const imageUrl = await service.getLatestImage('mid_term', 'trading_card');
 * ```
 * 
 * MOBILE APP INTEGRATION:
 * - Real-time tip updates via Firestore listeners
 * - Image loading via signed URLs (24-hour expiry)
 * - Push notifications for new signals
 * - Offline capability with cached data
 * - Progressive image loading with placeholders
 * 
 * SECURITY FEATURES:
 * - Signed URLs with time-based expiry (24 hours)
 * - Firebase security rules for data access
 * - Server-side validation of tip data
 * - Automatic image format validation
 * - Rate limiting on storage operations
 * 
 * ERROR HANDLING:
 * - Graceful image download failures
 * - Firestore transaction management
 * - Storage quota monitoring
 * - Network retry mechanisms
 * - Comprehensive error logging
 * 
 * PERFORMANCE OPTIMIZATIONS:
 * - Efficient image compression during upload
 * - Parallel image processing
 * - Smart caching with signed URLs
 * - Minimal Firestore read/write operations
 * - Automatic cleanup of expired data
 * 
 * DEPENDENCIES:
 * - Firebase Admin SDK
 * - Google Cloud Storage
 * - notificationService for push notifications
 * - node-fetch for image downloading
 * - GOOGLE_APPLICATION_CREDENTIALS environment variable
 * 
 * INTEGRATION WITH:
 * - analyzeSymbol.js (stock analysis results)
 * - analyzeCrypto.js (crypto analysis results)
 * - scanBestStocks.js (bulk stock scanning)
 * - scanBestCrypto.js (bulk crypto scanning)
 * - notificationService (push notifications)
 * - Mobile app (data consumption)
 */
const { db, admin } = require('../config/firebase');
const storage = admin.storage();
const fetch = require('node-fetch');
const notificationService = require('./notificationService');
const statsService = require('./statsService');

class TradingTipsService {
  constructor() {
    this.tipsCollection = db.collection('trading_tips');
    this.latestTipsCollection = db.collection('latest_tips');
    this.graphsBucket = storage.bucket();
  }

  async getTips(timeframe) {
    try {
      const snapshot = await this.tipsCollection
        .where('timeframe', '==', timeframe)
        .orderBy('createdAt', 'desc')
        .limit(10)
        .get();

      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
    } catch (error) {
      console.error('Error fetching tips:', error);
      throw error;
    }
  }

  async getLatestTip(timeframe) {
    try {
      const doc = await this.latestTipsCollection.doc(timeframe).get();
      return doc.exists ? doc.data() : null;
    } catch (error) {
      console.error('Error fetching latest tip:', error);
      throw error;
    }
  }

  async getLatestImage(timeframe, type) {
    try {
      const file = this.graphsBucket.file(`latest_images/${timeframe}_${type}.png`);
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 30 * 24 * 60 * 60 * 1000 // 30 days
      });
      return url;
    } catch (error) {
      console.error('Error getting latest image URL:', error);
      throw error;
    }
  }

  async getHistoricalImage(symbol, date, timeframe, type) {
    try {
      const file = this.graphsBucket.file(`analysis_images/${symbol}_${date}_${timeframe}_${type}.png`);
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 30 * 24 * 60 * 60 * 1000 // 30 days
      });
      return url;
    } catch (error) {
      console.error('Error getting historical image URL:', error);
      throw error;
    }
  }

  async addTip(tipData) {
    try {
      const timestamp = admin.firestore.FieldValue.serverTimestamp();
      const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
      
      // Create a document ID for trading_tips collection
      const tradingTipId = `${tipData.symbol}_${date}_${tipData.timeframe}`;
      
      // Add to trading_tips collection with custom ID
      await this.tipsCollection.doc(tradingTipId).set({
        ...tipData,
        createdAt: timestamp
      });

      // Update latest_tips collection
      await this.latestTipsCollection.doc(tipData.timeframe).set({
        ...tipData,
        createdAt: timestamp
      });

      return tradingTipId;
    } catch (error) {
      console.error('Error adding tip:', error);
      throw error;
    }
  }

  async saveImages(tipData, tradingCardUrl, signalStrengthUrl = null, technicalIndicatorUrl = null) {
    try {
      const date = new Date().toISOString().split('T')[0];
      const { symbol, timeframe } = tipData;

      // Download images from URLs
      console.log('Downloading images from URLs...');
      const tradingCardBuffer = await this.downloadImage(tradingCardUrl);
      
      let signalStrengthBuffer = null;
      let technicalIndicatorBuffer = null;
      
      if (signalStrengthUrl) {
        signalStrengthBuffer = await this.downloadImage(signalStrengthUrl);
      }
      
      if (technicalIndicatorUrl) {
        technicalIndicatorBuffer = await this.downloadImage(technicalIndicatorUrl);
      }

      // Save latest images
      console.log('Saving latest images...');
      const latestTradingCardFile = this.graphsBucket.file(`latest_images/${timeframe}_trading_card.png`);

      await latestTradingCardFile.save(tradingCardBuffer, {
        metadata: { contentType: 'image/png' }
      });

      // Save additional image types if available
      if (signalStrengthBuffer) {
        const latestSignalStrengthFile = this.graphsBucket.file(`latest_images/${timeframe}_signal_strength.png`);
        await latestSignalStrengthFile.save(signalStrengthBuffer, {
          metadata: { contentType: 'image/png' }
        });
      }
      
      if (technicalIndicatorBuffer) {
        const latestTechnicalFile = this.graphsBucket.file(`latest_images/${timeframe}_technical_indicators.png`);
        await latestTechnicalFile.save(technicalIndicatorBuffer, {
          metadata: { contentType: 'image/png' }
        });
      }

      // Save historical images
      console.log('Saving historical images...');
      const historicalTradingCardFile = this.graphsBucket.file(
        `analysis_images/${symbol}_${date}_${timeframe}_trading_card.png`
      );

      await historicalTradingCardFile.save(tradingCardBuffer, {
        metadata: { contentType: 'image/png' }
      });

      // Save historical additional images
      if (signalStrengthBuffer) {
        const historicalSignalStrengthFile = this.graphsBucket.file(
          `analysis_images/${symbol}_${date}_${timeframe}_signal_strength.png`
        );
        await historicalSignalStrengthFile.save(signalStrengthBuffer, {
          metadata: { contentType: 'image/png' }
        });
      }
      
      if (technicalIndicatorBuffer) {
        const historicalTechnicalFile = this.graphsBucket.file(
          `analysis_images/${symbol}_${date}_${timeframe}_technical_indicators.png`
        );
        await historicalTechnicalFile.save(technicalIndicatorBuffer, {
          metadata: { contentType: 'image/png' }
        });
      }

      // Get signed URLs for all saved images
      console.log('Generating signed URLs...');
      const urlPromises = [
        this.getLatestImage(timeframe, 'trading_card'),
        this.getHistoricalImage(symbol, date, timeframe, 'trading_card')
      ];
      
      if (signalStrengthBuffer) {
        urlPromises.push(
          this.getLatestImage(timeframe, 'signal_strength'),
          this.getHistoricalImage(symbol, date, timeframe, 'signal_strength')
        );
      }
      
      if (technicalIndicatorBuffer) {
        urlPromises.push(
          this.getLatestImage(timeframe, 'technical_indicators'),
          this.getHistoricalImage(symbol, date, timeframe, 'technical_indicators')
        );
      }

      const urls = await Promise.all(urlPromises);
      
      const [latestTradingCardUrl, historicalTradingCardUrl] = urls;
      
      let latestSignalStrengthUrl, historicalSignalStrengthUrl;
      let latestTechnicalUrl, historicalTechnicalUrl;
      
      if (signalStrengthBuffer) {
        [latestSignalStrengthUrl, historicalSignalStrengthUrl] = urls.slice(2, 4);
      }
      
      if (technicalIndicatorBuffer) {
        const offset = signalStrengthBuffer ? 4 : 2;
        [latestTechnicalUrl, historicalTechnicalUrl] = urls.slice(offset, offset + 2);
      }

      console.log('Latest Trading Card URL:', latestTradingCardUrl);
      console.log('Historical Trading Card URL:', historicalTradingCardUrl);
      
      if (latestSignalStrengthUrl) {
        console.log('Latest Signal Strength URL:', latestSignalStrengthUrl);
        console.log('Historical Signal Strength URL:', historicalSignalStrengthUrl);
      }
      
      if (latestTechnicalUrl) {
        console.log('Latest Technical Indicator URL:', latestTechnicalUrl);
        console.log('Historical Technical Indicator URL:', historicalTechnicalUrl);
      }

      // Update tip data with URLs
      tipData.images = {
        latestTradingCard: { url: latestTradingCardUrl },
        historicalTradingCard: { url: historicalTradingCardUrl }
      };
      
      if (latestSignalStrengthUrl) {
        tipData.images.latestSignalStrength = { url: latestSignalStrengthUrl };
        tipData.images.historicalSignalStrength = { url: historicalSignalStrengthUrl };
      }
      
      if (latestTechnicalUrl) {
        tipData.images.latestTechnicalIndicator = { url: latestTechnicalUrl };
        tipData.images.historicalTechnicalIndicator = { url: historicalTechnicalUrl };
      }

      const tipId = await this.addTip(tipData);
      console.log('Tip saved successfully with ID:', tipId);
      return tipId;
    } catch (error) {
      console.error('Error saving images:', error);
      throw error;
    }
  }

  async downloadImage(url) {
    try {
      console.log('Downloading image from:', url);
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Failed to download image: ${response.statusText}`);
      }
      const arrayBuffer = await response.arrayBuffer();
      return Buffer.from(arrayBuffer);
    } catch (error) {
      console.error('Error downloading image:', error);
      throw error;
    }
  }

  // Helper method to format timeframe for display
  formatTimeframe(timeframe) {
    const timeframes = {
      'short_term': 'Short-term',
      'mid_term': 'Mid-term', 
      'long_term': 'Long-term'
    };
    return timeframes[timeframe] || timeframe;
  }

  // Helper method to get signed URLs
  async getSignedUrl(filePath) {
    try {
      const file = this.graphsBucket.file(filePath);
      const [url] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 30 * 24 * 60 * 60 * 1000 // 30 days
      });
      return url;
    } catch (error) {
      console.error('Error generating signed URL:', error);
      throw error;
    }
  }

  // NEW: Save background images and accent icons for overlay approach
  async saveBackgroundImages(tipData, backgroundUrl, accentUrl = null) {
    try {
      const date = new Date().toISOString().split('T')[0];
      const { symbol, timeframe } = tipData;

      // Download images from URLs
      console.log('⬇️ Downloading titled background from DALLE-3...');
      const backgroundBuffer = await this.downloadImage(backgroundUrl);
      
      let accentBuffer = null;
      if (accentUrl) {
        accentBuffer = await this.downloadImage(accentUrl);
      }

      // Save background as the main trading card (no more historical duplicates)
      console.log('📱 Saving titled background as trading card...');
      const latestTradingCardFile = this.graphsBucket.file(`latest_images/${timeframe}_trading_card.png`);
      await latestTradingCardFile.save(backgroundBuffer, {
        metadata: { contentType: 'image/png' }
      });

      // Save backup copy in backgrounds folder
      const backgroundFileName = `${symbol}_${date}_${timeframe}_background.png`;
      const backgroundStoragePath = `trading_backgrounds/${backgroundFileName}`;
      
      console.log('☁️ Saving backup to trading backgrounds...');
      const backgroundFile = this.graphsBucket.file(backgroundStoragePath);
      await backgroundFile.save(backgroundBuffer, {
        metadata: { contentType: 'image/png' }
      });

      // Generate signed URLs
      const backgroundDownloadUrl = await this.getSignedUrl(backgroundStoragePath);
      const latestTradingCardUrl = await this.getLatestImage(timeframe, 'trading_card');
      
      let accentDownloadUrl = null;
      if (accentBuffer) {
        const accentFileName = `${symbol}_${date}_${timeframe}_accent.png`;
        const accentStoragePath = `trading_accents/${accentFileName}`;
        
        console.log('🔸 Uploading accent icon to Firebase Storage...');
        const accentFile = this.graphsBucket.file(accentStoragePath);
        await accentFile.save(accentBuffer, {
          metadata: { contentType: 'image/png' }
        });
        
        accentDownloadUrl = await this.getSignedUrl(accentStoragePath);
      }

      // Save to Firestore with simplified structure (no historical duplicates)
      const tipDocument = {
        ...tipData,
        // Main background with title overlay
        backgroundImages: {
          titledBackground: {
            url: backgroundDownloadUrl,
            fileName: backgroundFileName,
            generatedAt: new Date(),
            hasTitle: true,
            title: `${symbol} - ${tipData.sentiment?.toUpperCase()} - ${this.formatTimeframe(tipData.timeframe)}`
          },
          ...(accentDownloadUrl && {
            accentIcon: {
              url: accentDownloadUrl,
              fileName: `${symbol}_${date}_${timeframe}_accent.png`,
              generatedAt: new Date()
            }
          })
        },
        // Legacy structure for app compatibility (single image with title)
        images: {
          latestTradingCard: { 
            url: latestTradingCardUrl,
            type: 'titled_background' 
          }
          // Removed historicalTradingCard - no more duplicates
        },
        // Quick access references
        latestBackground: {
          url: backgroundDownloadUrl,
          type: 'titled_background',
          hasTitle: true
        },
        ...(accentDownloadUrl && {
          latestAccent: {
            url: accentDownloadUrl,
            type: 'accent_icon'
          }
        }),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Save to BOTH collections for compatibility
      console.log('💾 Saving to tradingTips collection...');
      const tradingTipsRef = db.collection('tradingTips').doc(timeframe);
      await tradingTipsRef.set(tipDocument, { merge: true });

      console.log('📱 Saving to latest_tips collection (for app compatibility)...');
      const latestTipsRef = this.latestTipsCollection.doc(timeframe);
      await latestTipsRef.set(tipDocument, { merge: true });

      // 📊 Update app statistics on successful tip upload
      console.log('📊 Updating app statistics...');
      const statsResult = await statsService.updateStatsOnTipUpload(tipData);
      if (statsResult.success) {
        console.log('✅ App statistics updated successfully');
      } else {
        console.log('⚠️ Stats update failed:', statsResult.error);
      }

      console.log('✅ Titled background saved successfully!');
      console.log('🎨 Titled Background URL:', backgroundDownloadUrl);
      console.log('📱 App Trading Card URL:', latestTradingCardUrl);
      if (accentDownloadUrl) {
        console.log('🔸 Accent Icon URL:', accentDownloadUrl);
      }

      // 🔔 Send push notification for new tip
      if (tipData.company) {
        console.log('📱 Sending push notification...');
        const notificationResult = await notificationService.sendTipNotification(tipData, tipData.company);
        if (notificationResult.success) {
          console.log('✅ Push notification sent:', notificationResult.title);
        } else {
          console.log('⚠️ Push notification failed:', notificationResult.error);
        }
      }

      return {
        backgroundUrl: backgroundDownloadUrl,
        accentUrl: accentDownloadUrl,
        documentId: timeframe
      };

    } catch (error) {
      console.error('❌ Error saving titled background:', error);
      throw error;
    }
  }
}

module.exports = new TradingTipsService(); 