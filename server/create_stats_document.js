/**
 * CREATE STATS DOCUMENT IN FIREBASE
 * =================================
 * 
 * This script automatically creates the app_stats/global_stats document
 * in Firebase using the same configuration as existing services.
 */

const { db, admin } = require('./src/config/firebase');

async function createStatsDocument() {
  console.log('📊 Creating app_stats document in Firebase...');
  
  try {
    const statsRef = db.collection('app_stats').doc('global_stats');
    
    // Check if document already exists
    const doc = await statsRef.get();
    if (doc.exists) {
      console.log('✅ Stats document already exists!');
      console.log('Current data:', doc.data());
      return;
    }
    
    // Create new stats document with initial values
    const initialStats = {
      generatedTips: 1,
      successRate: 95,
      aiAccuracy: 97,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    await statsRef.set(initialStats);
    
    console.log('✅ Stats document created successfully!');
    console.log('📈 Generated Tips: 1');
    console.log('✅ Success Rate: 95%');
    console.log('🤖 AI Accuracy: 97%');
    console.log('');
    console.log('🚀 Ready for testing! Next tip upload will:');
    console.log('   • Increment Generated Tips to 2');
    console.log('   • Set new random Success Rate (94-98%)');
    console.log('   • Set new random AI Accuracy (95-99%)');
    
  } catch (error) {
    console.error('❌ Error creating stats document:', error);
  } finally {
    process.exit(0);
  }
}

// Run the script
createStatsDocument(); 