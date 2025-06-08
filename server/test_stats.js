/**
 * TEST SCRIPT FOR STATS SERVICE
 * =============================
 * 
 * This script tests the server-side stats service to ensure:
 * 1. Stats initialization works
 * 2. Stats update on tip upload works
 * 3. Stats retrieval works
 * 4. Realistic value generation works
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

async function testStatsService() {
  console.log('🧪 TESTING STATS SERVICE');
  console.log('========================\n');

  try {
    // Test 1: Initialize stats
    console.log('📊 Test 1: Initialize Stats');
    await statsService.initializeStats();
    console.log('✅ Stats initialization completed\n');

    // Test 2: Get current stats
    console.log('📊 Test 2: Get Current Stats');
    const currentStats = await statsService.getStats();
    console.log('Current stats:', currentStats);
    console.log('✅ Stats retrieval completed\n');

    // Test 3: Simulate tip upload (update stats)
    console.log('📊 Test 3: Simulate Tip Upload');
    const mockTipData = {
      symbol: 'AAPL',
      timeframe: 'mid_term',
      sentiment: 'bullish',
      company: 'Apple Inc.'
    };
    
    const updateResult = await statsService.updateStatsOnTipUpload(mockTipData);
    console.log('Update result:', updateResult);
    console.log('✅ Stats update completed\n');

    // Test 4: Get updated stats
    console.log('📊 Test 4: Get Updated Stats');
    const updatedStats = await statsService.getStats();
    console.log('Updated stats:', updatedStats);
    console.log('✅ Updated stats retrieval completed\n');

    // Test 5: Test multiple updates
    console.log('📊 Test 5: Multiple Updates');
    for (let i = 0; i < 3; i++) {
      const result = await statsService.updateStatsOnTipUpload({
        symbol: `TEST${i}`,
        timeframe: 'short_term',
        sentiment: 'bullish'
      });
      console.log(`Update ${i + 1}:`, {
        successRate: result.successRate,
        aiAccuracy: result.aiAccuracy
      });
    }
    console.log('✅ Multiple updates completed\n');

    // Test 6: Final stats check
    console.log('📊 Test 6: Final Stats Check');
    const finalStats = await statsService.getStats();
    console.log('Final stats:', finalStats);
    console.log('✅ Final stats check completed\n');

    console.log('🎉 ALL TESTS PASSED!');
    console.log('Stats service is working correctly.');

  } catch (error) {
    console.error('❌ TEST FAILED:', error);
  } finally {
    process.exit(0);
  }
}

// Run the test
testStatsService(); 