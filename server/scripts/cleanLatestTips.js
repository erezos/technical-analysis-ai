const { db } = require('../src/config/firebase');

async function cleanLatestTips() {
  console.log('🧹 Cleaning corrupted latest_tips data...');
  
  const timeframes = ['short_term', 'mid_term', 'long_term'];
  
  for (const timeframe of timeframes) {
    try {
      console.log(`\n🔍 Checking ${timeframe}...`);
      
      const doc = await db.collection('latest_tips').doc(timeframe).get();
      if (!doc.exists) {
        console.log(`   ⚠️ No document found for ${timeframe}`);
        continue;
      }
      
      const data = doc.data();
      console.log(`   📊 Current symbol: ${data.symbol}`);
      
      // Check for analysis object (corrupted structure)
      if (data.analysis) {
        console.log('   ❌ Found corrupted analysis object - cleaning...');
        
        // Create clean data structure using root level values (correct ones)
        const cleanData = {
          symbol: data.symbol,
          timeframe: data.timeframe,
          sentiment: data.sentiment,
          entryPrice: data.entryPrice,
          stopLoss: data.stopLoss,
          takeProfit: data.takeProfit,
          riskRewardRatio: data.riskRewardRatio,
          strength: data.strength,
          confidence: data.confidence,
          reasoning: data.reasoning,
          indicators: data.indicators,
          company: data.company,
          backgroundImages: data.backgroundImages,
          images: data.images,
          latestBackground: data.latestBackground,
          latestAccent: data.latestAccent,
          createdAt: data.createdAt,
          updatedAt: data.updatedAt,
          // Clean metadata with correct asset type
          metadata: {
            generatedAt: new Date().toISOString(),
            strategy: 'enhanced_backgrounds_v1',
            ...(data.company?.isCrypto ? {
              assetType: 'crypto',
              exchange: 'binance'
            } : {
              assetType: 'stock'
            })
          }
        };
        
        // Remove analysis object and update with clean structure
        await db.collection('latest_tips').doc(timeframe).set(cleanData);
        
        console.log('   ✅ Cleaned data structure');
        console.log(`   📈 Entry Price: $${cleanData.entryPrice?.toFixed(2)}`);
        console.log(`   📉 Stop Loss: $${cleanData.stopLoss?.toFixed(2)}`);
        console.log(`   📊 Take Profit: $${cleanData.takeProfit?.toFixed(2)}`);
        console.log(`   🏢 Asset Type: ${cleanData.metadata.assetType}`);
        
      } else {
        console.log('   ✅ Data structure is clean');
      }
      
    } catch (error) {
      console.error(`   ❌ Error cleaning ${timeframe}:`, error);
    }
  }
  
  console.log('\n🎉 Cleaning completed!');
}

if (require.main === module) {
  cleanLatestTips().catch(console.error);
}

module.exports = { cleanLatestTips }; 