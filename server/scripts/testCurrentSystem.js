const tradingTipsService = require('../src/services/tradingTipsServiceOptimized');

async function testCurrentSystem() {
  console.log('🧪 Testing Current System - BASELINE');
  console.log('=====================================');

  try {
    // Test 1: Get current latest tips
    console.log('\n📊 Current Latest Tips:');
    const shortTerm = await tradingTipsService.getLatestTip('short_term');
    const midTerm = await tradingTipsService.getLatestTip('mid_term');
    const longTerm = await tradingTipsService.getLatestTip('long_term');

    console.log(`Short-term: ${shortTerm?.symbol || 'None'}`);
    console.log(`Mid-term: ${midTerm?.symbol || 'None'}`);
    console.log(`Long-term: ${longTerm?.symbol || 'None'}`);

    // Test 2: Analyze data structure size
    if (shortTerm) {
      console.log('\n📏 Data Structure Analysis (short_term):');
      const dataString = JSON.stringify(shortTerm);
      console.log(`Total Size: ${dataString.length} characters`);
      
      // Count fields
      let fieldCount = 0;
      let imageFields = 0;
      let redundantFields = 0;
      
      Object.keys(shortTerm).forEach(key => {
        fieldCount++;
        if (key.includes('image') || key.includes('Background') || key.includes('Accent')) {
          imageFields++;
        }
        if (key === 'latestBackground' || key === 'latestAccent' || key === 'backgroundImages') {
          redundantFields++;
        }
      });
      
      console.log(`Total Fields: ${fieldCount}`);
      console.log(`Image-related Fields: ${imageFields}`);
      console.log(`Redundant Fields: ${redundantFields}`);
      
      // Test 3: Mobile app compatibility
      console.log('\n📱 Mobile App Compatibility Check:');
      const mobileImageUrl = shortTerm.images?.latestTradingCard?.url;
      console.log(`Mobile image URL: ${mobileImageUrl ? '✅ Available' : '❌ Missing'}`);
      
      // Essential fields check
      const essentialFields = ['symbol', 'entryPrice', 'stopLoss', 'takeProfit', 'sentiment'];
      essentialFields.forEach(field => {
        console.log(`${field}: ${shortTerm[field] !== undefined ? '✅' : '❌'}`);
      });
      
      // Test 4: Redundancy Analysis
      console.log('\n🗑️ Redundancy Analysis:');
      
      // Count duplicate URLs
      const urls = [];
      if (shortTerm.backgroundImages?.titledBackground?.url) urls.push('backgroundImages.titledBackground');
      if (shortTerm.images?.latestTradingCard?.url) urls.push('images.latestTradingCard');
      if (shortTerm.latestBackground?.url) urls.push('latestBackground');
      
      console.log(`Image URL references: ${urls.length}`);
      console.log(`References: ${urls.join(', ')}`);
      
      // Check if URLs are the same (redundant)
      const backgroundUrl = shortTerm.backgroundImages?.titledBackground?.url;
      const cardUrl = shortTerm.images?.latestTradingCard?.url;
      const latestUrl = shortTerm.latestBackground?.url;
      
      if (backgroundUrl && cardUrl && latestUrl) {
        const allSame = backgroundUrl === latestUrl && cardUrl === latestUrl;
        console.log(`All URLs identical: ${allSame ? '❌ REDUNDANT' : '✅ Different'}`);
      }
      
      // Test 5: Essential vs Non-essential data
      console.log('\n⚖️ Data Classification:');
      
      const essential = {
        symbol: shortTerm.symbol,
        timeframe: shortTerm.timeframe,
        sentiment: shortTerm.sentiment,
        strength: shortTerm.strength,
        entryPrice: shortTerm.entryPrice,
        stopLoss: shortTerm.stopLoss,
        takeProfit: shortTerm.takeProfit,
        company: shortTerm.company,
        images: { latestTradingCard: shortTerm.images?.latestTradingCard }
      };
      
      const essentialSize = JSON.stringify(essential).length;
      const totalSize = JSON.stringify(shortTerm).length;
      const wastePercentage = Math.round(((totalSize - essentialSize) / totalSize) * 100);
      
      console.log(`Essential data: ${essentialSize} chars`);
      console.log(`Total data: ${totalSize} chars`);
      console.log(`Waste: ${wastePercentage}% 🗑️`);
      
    } else {
      console.log('❌ No short-term tip found for analysis');
    }

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

if (require.main === module) {
  testCurrentSystem().catch(console.error);
}

module.exports = { testCurrentSystem }; 