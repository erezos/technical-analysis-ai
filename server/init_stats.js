/**
 * INITIALIZE STATS IN FIREBASE
 * ============================
 * 
 * Run this script once to initialize the app statistics in Firebase.
 * After this, stats will auto-update with each tip upload.
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'config', 'firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
  storageBucket: 'technical-analysis-ai.appspot.com'
});

const statsService = require('./src/services/statsService');

async function initializeStats() {
  console.log('📊 Initializing App Statistics in Firebase...');
  
  try {
    await statsService.initializeStats();
    
    const stats = await statsService.getStats();
    console.log('✅ Stats initialized successfully!');
    console.log('📈 Generated Tips:', stats.generatedTips);
    console.log('✅ Success Rate:', stats.successRate + '%');
    console.log('🤖 AI Accuracy:', stats.aiAccuracy + '%');
    
  } catch (error) {
    console.error('❌ Error initializing stats:', error);
  } finally {
    process.exit(0);
  }
}

initializeStats(); 