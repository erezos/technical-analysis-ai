const optimizedService = require('../src/services/tradingTipsServiceOptimized');

async function debugOptimizedData() {
  console.log('🔍 DEBUG: Optimized Service Data Structure');
  console.log('==========================================');

  try {
    const tip = await optimizedService.getLatestTip('short_term');
    
    if (tip) {
      console.log('\n📊 Raw Data Structure:');
      console.log(JSON.stringify(tip, null, 2));
      
      console.log('\n🔍 Key Fields Check:');
      console.log(`backgroundImageUrl: ${tip.backgroundImageUrl || 'MISSING'}`);
      console.log(`images.latestTradingCard.url: ${tip.images?.latestTradingCard?.url || 'MISSING'}`);
      
      console.log('\n📱 Mobile App Access Test:');
      const mobileImageUrl = (tip.images?.latestTradingCard)?.url;
      console.log(`Mobile can access image: ${mobileImageUrl ? '✅ YES' : '❌ NO'}`);
      
    } else {
      console.log('❌ No tip found');
    }

  } catch (error) {
    console.error('❌ Debug failed:', error);
  }
}

if (require.main === module) {
  debugOptimizedData().catch(console.error);
}

module.exports = { debugOptimizedData }; 