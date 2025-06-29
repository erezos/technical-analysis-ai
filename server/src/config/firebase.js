/**
 * Firebase Admin SDK Configuration
 * Handles initialization with proper error handling and validation
 */

import admin from 'firebase-admin';

class FirebaseConfig {
  constructor() {
    this.admin = admin;
    this.isInitialized = false;
    this.db = null;
    this.messaging = null;
  }

  async initialize() {
    try {
      console.log('🔥 Initializing Firebase Admin SDK...');
      
      // Validate required environment variables
      const requiredVars = {
        FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID,
        FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL,
        FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY
      };

      const missing = Object.entries(requiredVars)
        .filter(([key, value]) => !value)
        .map(([key]) => key);

      if (missing.length > 0) {
        throw new Error(`Missing Firebase environment variables: ${missing.join(', ')}`);
      }

      // Validate private key format
      const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
      if (!privateKey.includes('BEGIN PRIVATE KEY')) {
        throw new Error('Invalid Firebase private key format. Ensure it contains the full PEM structure.');
      }

      // Initialize Firebase Admin SDK
      const serviceAccount = {
        type: 'service_account',
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID || 'auto-generated',
        private_key: privateKey,
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: process.env.FIREBASE_CLIENT_ID || 'auto-generated',
        auth_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_uri: 'https://oauth2.googleapis.com/token',
        auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
        client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${encodeURIComponent(process.env.FIREBASE_CLIENT_EMAIL)}`
      };

      // Check if Firebase is already initialized
      if (!admin.apps.length) {
        const initConfig = {
          credential: admin.credential.cert(serviceAccount),
          projectId: process.env.FIREBASE_PROJECT_ID
        };

        // Add storage bucket if available (optional)
        if (process.env.FIREBASE_STORAGE_BUCKET) {
          initConfig.storageBucket = process.env.FIREBASE_STORAGE_BUCKET;
          console.log('📦 Firebase Storage bucket configured:', process.env.FIREBASE_STORAGE_BUCKET);
        } else {
          console.log('⚠️ Firebase Storage bucket not configured (optional)');
        }

        admin.initializeApp(initConfig);
        console.log('✅ Firebase Admin SDK initialized successfully');
      } else {
        console.log('🔄 Firebase Admin SDK already initialized');
      }

      // Initialize services
      this.db = admin.firestore();
      this.messaging = admin.messaging();
      
      // Test Firestore connection
      await this.testConnection();
      
      this.isInitialized = true;
      console.log('🎯 Firebase services ready: Firestore + FCM');
      
      return {
        db: this.db,
        messaging: this.messaging,
        admin: this.admin,
        isReady: true
      };

    } catch (error) {
      console.error('❌ Firebase initialization failed:', error.message);
      
      // Provide helpful debugging information
      if (error.message.includes('private_key')) {
        console.error('🔑 Private key issue detected. Ensure FIREBASE_PRIVATE_KEY is properly formatted with \\n for line breaks');
      }
      
      if (error.message.includes('project_id')) {
        console.error('��️ Project ID issue. Verify FIREBASE_PROJECT_ID matches your Firebase project');
      }
      
      if (error.message.includes('client_email')) {
        console.error('📧 Client email issue. Verify FIREBASE_CLIENT_EMAIL is the service account email');
      }
      
      // Return test mode configuration
      console.log('🧪 Falling back to test mode - Firebase features disabled');
      return {
        db: null,
        messaging: null,
        admin: null,
        isReady: false,
        testMode: true
      };
    }
  }

  async testConnection() {
    try {
      // Test Firestore connection by attempting to read from a collection
      console.log('🔍 Testing Firestore connection...');
      await this.db.collection('_test_connection').limit(1).get();
      console.log('✅ Firestore connection verified');
      
      // Test FCM by validating the service
      console.log('🔍 Testing FCM service...');
      // FCM doesn't have a simple test method, but if messaging was created successfully, it should work
      console.log('✅ FCM service initialized');
      
    } catch (error) {
      console.warn('⚠️ Firebase connection test failed:', error.message);
      // Don't throw here - we'll continue in test mode
    }
  }

  getServices() {
    if (!this.isInitialized) {
      console.warn('⚠️ Firebase not initialized - returning test mode services');
      return {
        db: null,
        messaging: null,
        admin: null,
        isReady: false,
        testMode: true
      };
    }

    return {
      db: this.db,
      messaging: this.messaging,
      admin: this.admin,
      isReady: true,
      testMode: false
    };
  }

  async shutdown() {
    try {
      if (this.isInitialized && admin.apps.length > 0) {
        console.log('🔥 Shutting down Firebase Admin SDK...');
        await Promise.all(admin.apps.map(app => app.delete()));
        console.log('✅ Firebase shutdown complete');
      }
    } catch (error) {
      console.error('❌ Error shutting down Firebase:', error);
    }
  }
}

// Export singleton instance
export default new FirebaseConfig(); 