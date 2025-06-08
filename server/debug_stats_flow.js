/**
 * COMPREHENSIVE STATS FLOW DEBUGGER
 * ==================================
 * 
 * This script tests every aspect of the stats system to identify where it's failing.
 * It will help us debug why stats aren't updating when tips are uploaded.
 */

const { db, admin } = require('./src/config/firebase');

async function debugStatsFlow() {
  console.log('🔍 DEBUGGING STATS FLOW - COMPREHENSIVE TEST');
  console.log('=============================================\n');

  try {
    // Test 1: Check if stats document exists and current values
    console.log('📊 TEST 1: Current Stats Document');
    console.log('----------------------------------');
    const statsRef = db.collection('app_stats').doc('global_stats');
    const doc = await statsRef.get();
    
    if (doc.exists) {
      const currentStats = doc.data();
      console.log('✅ Stats document exists');
      console.log('📈 Generated Tips:', currentStats.generatedTips);
      console.log('✅ Success Rate:', currentStats.successRate + '%');
      console.log('🤖 AI Accuracy:', currentStats.aiAccuracy + '%');
      console.log('🕒 Last Updated:', currentStats.lastUpdated?.toDate());
    } else {
      console.log('❌ Stats document does NOT exist');
      return;
    }
    console.log('');

    // Test 2: Test statsService import and methods
    console.log('📊 TEST 2: StatsService Import & Methods');
    console.log('---------------------------------------');
    try {
      const statsService = require('./src/services/statsService');
      console.log('✅ statsService imported successfully');
      
      // Check if methods exist
      if (typeof statsService.updateStatsOnTipUpload === 'function') {
        console.log('✅ updateStatsOnTipUpload method exists');
      } else {
        console.log('❌ updateStatsOnTipUpload method MISSING');
      }
      
      if (typeof statsService.getStats === 'function') {
        console.log('✅ getStats method exists');
      } else {
        console.log('❌ getStats method MISSING');
      }
    } catch (error) {
      console.log('❌ statsService import FAILED:', error.message);
      return;
    }
    console.log('');

    // Test 3: Test direct stats update (simulate tip upload)
    console.log('📊 TEST 3: Direct Stats Update Test');
    console.log('----------------------------------');
    const statsService = require('./src/services/statsService');
    const mockTipData = {
      symbol: 'TEST',
      timeframe: 'mid_term',
      sentiment: 'bullish',
      company: 'Test Company'
    };
    
    console.log('🔄 Simulating tip upload with mock data...');
    const updateResult = await statsService.updateStatsOnTipUpload(mockTipData);
    
    if (updateResult.success) {
      console.log('✅ Stats update SUCCESSFUL');
      console.log('📈 New Success Rate:', updateResult.successRate + '%');
      console.log('🤖 New AI Accuracy:', updateResult.aiAccuracy + '%');
    } else {
      console.log('❌ Stats update FAILED:', updateResult.error);
      return;
    }
    console.log('');

    // Test 4: Verify stats were actually updated
    console.log('📊 TEST 4: Verify Database Update');
    console.log('--------------------------------');
    const updatedDoc = await statsRef.get();
    if (updatedDoc.exists) {
      const newStats = updatedDoc.data();
      console.log('📈 New Generated Tips:', newStats.generatedTips);
      console.log('✅ New Success Rate:', newStats.successRate + '%');
      console.log('🤖 New AI Accuracy:', newStats.aiAccuracy + '%');
      console.log('🕒 Updated At:', newStats.lastUpdated?.toDate());
      
      if (newStats.generatedTips > currentStats.generatedTips) {
        console.log('✅ Generated Tips INCREMENTED correctly');
      } else {
        console.log('❌ Generated Tips did NOT increment');
      }
    }
    console.log('');

    // Test 5: Check tradingTipsService integration
    console.log('📊 TEST 5: TradingTipsService Integration');
    console.log('---------------------------------------');
    try {
      const tradingTipsService = require('./src/services/tradingTipsService');
      console.log('✅ tradingTipsService imported successfully');
      
      // Check if statsService is imported in tradingTipsService
      const fs = require('fs');
      const tradingTipsContent = fs.readFileSync('./src/services/tradingTipsService.js', 'utf8');
      
      if (tradingTipsContent.includes('statsService')) {
        console.log('✅ statsService is imported in tradingTipsService');
      } else {
        console.log('❌ statsService NOT imported in tradingTipsService');
      }
      
      if (tradingTipsContent.includes('updateStatsOnTipUpload')) {
        console.log('✅ updateStatsOnTipUpload is called in tradingTipsService');
      } else {
        console.log('❌ updateStatsOnTipUpload NOT called in tradingTipsService');
      }
      
    } catch (error) {
      console.log('❌ tradingTipsService check FAILED:', error.message);
    }
    console.log('');

    // Test 6: Test which upload scripts exist and which method they use
    console.log('📊 TEST 6: Upload Scripts Analysis');
    console.log('---------------------------------');
    const fs = require('fs');
    const path = require('path');
    const scriptsDir = './scripts';
    
    if (fs.existsSync(scriptsDir)) {
      const scriptFiles = fs.readdirSync(scriptsDir).filter(file => file.endsWith('.js'));
      console.log('📂 Found scripts:', scriptFiles.join(', '));
      
      for (const script of scriptFiles) {
        try {
          const scriptPath = path.join(scriptsDir, script);
          const scriptContent = fs.readFileSync(scriptPath, 'utf8');
          
          if (scriptContent.includes('saveBackgroundImages')) {
            console.log(`✅ ${script} uses saveBackgroundImages (HAS stats integration)`);
          } else if (scriptContent.includes('saveImages')) {
            console.log(`⚠️  ${script} uses saveImages (NO stats integration)`);
          } else {
            console.log(`❓ ${script} - upload method unclear`);
          }
        } catch (error) {
          console.log(`❌ Error reading ${script}:`, error.message);
        }
      }
    } else {
      console.log('❌ Scripts directory not found');
    }
    console.log('');

    console.log('🎯 DEBUGGING COMPLETE!');
    console.log('======================');
    console.log('📋 Summary:');
    console.log('1. Check the results above to identify the issue');
    console.log('2. Look for any ❌ marks indicating problems');
    console.log('3. Pay attention to which upload method your scripts use');
    console.log('4. Verify the integration chain is working');

  } catch (error) {
    console.error('❌ DEBUGGING FAILED:', error);
  } finally {
    process.exit(0);
  }
}

// Run the comprehensive debug
debugStatsFlow(); 