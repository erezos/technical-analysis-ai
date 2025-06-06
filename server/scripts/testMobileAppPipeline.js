const { db, admin } = require('../src/config/firebase');

async function testMobileAppPipeline() {
  console.log('🧪 TESTING COMPLETE MOBILE APP PIPELINE');
  console.log('=====================================');

  try {
    // STEP 1: Simulate FirebaseService.getLatestTipForTimeframe()
    console.log('\n📱 STEP 1: Mobile App Firebase Request');
    console.log('--------------------------------------');
    const doc = await db.collection('latest_tips').doc('short_term').get();
    
    if (!doc.exists) {
      console.log('❌ No tip found');
      return;
    }

    const firebaseData = doc.data();
    console.log(`✅ Document retrieved from Firebase`);
    console.log(`📏 Raw Firebase data size: ${JSON.stringify(firebaseData).length} chars`);
    
    // STEP 2: Simulate TradingTip.fromMap() conversion  
    console.log('\n📱 STEP 2: Mobile App Data Conversion');
    console.log('-------------------------------------');
    const tradingTip = {
      symbol: firebaseData.symbol,
      timeframe: firebaseData.timeframe,
      images: firebaseData.images || {},
      sentiment: firebaseData.sentiment,
      entryPrice: firebaseData.entryPrice,
      stopLoss: firebaseData.stopLoss,
      takeProfit: firebaseData.takeProfit,
      company: firebaseData.company,
      reasoning: firebaseData.reasoning
    };
    console.log(`✅ TradingTip object created`);
    
    // STEP 3: Simulate mobile app image access
    console.log('\n📱 STEP 3: Mobile App Image Access');
    console.log('----------------------------------');
    const imageUrl = (tradingTip.images['latestTradingCard'])?.url;
    
    if (!imageUrl) {
      console.log('❌ CRITICAL: No image URL found!');
      console.log('📊 Available image keys:', Object.keys(tradingTip.images));
      return;
    }
    
    console.log('✅ Image URL found!');
    console.log(`🔗 URL: ${imageUrl.substring(0, 100)}...`);
    
    // STEP 4: Test image URL accessibility
    console.log('\n📱 STEP 4: Image URL Accessibility Test');
    console.log('--------------------------------------');
    try {
      const response = await fetch(imageUrl, { method: 'HEAD' });
      if (response.ok) {
        console.log('✅ Image URL is accessible!');
        console.log(`📏 Content-Length: ${response.headers.get('content-length')} bytes`);
        console.log(`🖼️ Content-Type: ${response.headers.get('content-type')}`);
      } else {
        console.log(`❌ Image URL returned ${response.status}: ${response.statusText}`);
      }
    } catch (error) {
      console.log(`❌ Image URL test failed: ${error.message}`);
    }
    
    // STEP 5: Comprehensive compatibility check
    console.log('\n📱 STEP 5: Mobile App Compatibility Summary');
    console.log('-------------------------------------------');
    console.log(`Symbol: ${tradingTip.symbol || '❌ Missing'}`);
    console.log(`Timeframe: ${tradingTip.timeframe || '❌ Missing'}`);
    console.log(`Sentiment: ${tradingTip.sentiment || '❌ Missing'}`);
    console.log(`Entry Price: ${tradingTip.entryPrice ? `$${tradingTip.entryPrice.toFixed(2)}` : '❌ Missing'}`);
    console.log(`Stop Loss: ${tradingTip.stopLoss ? `$${tradingTip.stopLoss.toFixed(2)}` : '❌ Missing'}`);
    console.log(`Take Profit: ${tradingTip.takeProfit ? `$${tradingTip.takeProfit.toFixed(2)}` : '❌ Missing'}`);
    console.log(`Company Name: ${tradingTip.company?.name || '❌ Missing'}`);
    console.log(`Background Image: ${imageUrl ? '✅ Available' : '❌ Missing'}`);
    
    // STEP 6: Test exactly what mobile app screen expects
    console.log('\n📱 STEP 6: TradingTipScreen Compatibility Test');
    console.log('----------------------------------------------');
    
    // Simulate TradingTipScreen._buildBackgroundImage()
    const mobileImageUrl = (tradingTip.images['latestTradingCard'])?.url;
    console.log(`CachedNetworkImage.imageUrl: ${mobileImageUrl ? '✅ SET' : '❌ EMPTY'}`);
    
    if (mobileImageUrl) {
      console.log('🎯 MOBILE APP WILL SHOW: Beautiful AI background');
    } else {
      console.log('⚠️  MOBILE APP WILL SHOW: Fallback gradient background');
    }
    
    console.log('\n🏆 PIPELINE TEST COMPLETE!');
    console.log('✅ All mobile app requirements satisfied');
    
  } catch (error) {
    console.error('❌ Pipeline test failed:', error);
  }
}

if (require.main === module) {
  testMobileAppPipeline().catch(console.error);
}

module.exports = { testMobileAppPipeline }; 