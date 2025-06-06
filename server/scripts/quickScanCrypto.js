require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');

// Top liquid crypto pairs on both eToro and TAAPI
const TOP_CRYPTO_PAIRS = [
  'BTC/USDT', 'ETH/USDT', 'BNB/USDT', 'ADA/USDT', 
  'SOL/USDT', 'XRP/USDT', 'DOT/USDT', 'LINK/USDT'
];

const TIMEFRAME_MAP = {
  'short_term': '1h',
  'mid_term': '4h', 
  'long_term': '1d'
};

// Lower threshold for crypto (but higher than stocks due to volatility)
const MIN_SIGNAL_STRENGTH = 0.8;

async function quickScanCrypto(timeframe = 'short_term') {
  console.log('⚡ QUICK ETORO CRYPTO SCANNER');
  console.log('=============================');
  console.log(`📊 Timeframe: ${timeframe} (${TIMEFRAME_MAP[timeframe]})`);
  console.log(`💰 Analyzing ${TOP_CRYPTO_PAIRS.length} top crypto pairs`);
  console.log(`⚡ Signal threshold: ${MIN_SIGNAL_STRENGTH} (optimized for crypto)`);
  console.log('=============================\n');

  const results = [];
  const startTime = Date.now();

  // Process crypto pairs quickly
  for (const pair of TOP_CRYPTO_PAIRS) {
    try {
      const symbol = pair.replace('/', ''); // Format for TAAPI
      console.log(`💰 ${pair}...`);
      
      const analysis = await technicalAnalysisService.getTechnicalAnalysis(symbol, timeframe);
      
      if (Math.abs(analysis.analysis.strength) >= MIN_SIGNAL_STRENGTH) {
        results.push({
          pair,
          symbol,
          crypto: getCryptoName(pair),
          timeframe,
          sentiment: analysis.analysis.sentiment,
          strength: analysis.analysis.strength,
          confidence: analysis.analysis.confidence,
          entryPrice: analysis.analysis.entryPrice,
          stopLoss: analysis.analysis.stopLoss,
          takeProfit: analysis.analysis.takeProfit,
          riskReward: analysis.analysis.riskRewardRatio,
          reasoning: analysis.analysis.reasoning.slice(0, 2)
        });
        console.log(`   ✅ Signal: ${analysis.analysis.sentiment} (${analysis.analysis.strength.toFixed(2)})`);
      } else {
        console.log(`   ⚪ Weak: ${analysis.analysis.strength.toFixed(2)}`);
      }
      
      // Minimal delay for crypto
      await new Promise(resolve => setTimeout(resolve, 150));
      
    } catch (error) {
      console.error(`   ❌ Error ${pair}: ${error.message}`);
    }
  }

  // Sort by strength and get top 5
  results.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
  const top5 = results.slice(0, 5);
  const scanTime = ((Date.now() - startTime) / 1000).toFixed(1);

  console.log('\n🏆 QUICK CRYPTO SCAN RESULTS');
  console.log('=============================');
  console.log(`⏱️  Scan completed in: ${scanTime} seconds`);
  console.log(`💰 Crypto pairs analyzed: ${TOP_CRYPTO_PAIRS.length}`);
  console.log(`⚡ Signals found: ${results.length}`);
  console.log(`🥇 Top picks: ${top5.length}`);
  console.log('=============================\n');

  if (top5.length === 0) {
    console.log('😔 No crypto signals found. Market might be consolidating.');
    return [];
  }

  // Quick display format for crypto
  console.log('🚀 TOP CRYPTO SIGNALS');
  console.log('=============================');

  top5.forEach((result, index) => {
    const emoji = ['🥇', '🥈', '🥉', '🏅', '⭐'][index];
    const arrow = result.sentiment === 'bullish' ? '🚀' : '📉';
    
    console.log(`${emoji} ${result.pair} (${result.crypto})`);
    console.log(`   ${arrow} ${result.sentiment.toUpperCase()} - Strength: ${result.strength.toFixed(2)}`);
    console.log(`   💰 Entry: $${result.entryPrice?.toFixed(6)} | Target: $${result.takeProfit?.toFixed(6)}`);
    console.log(`   🛡️  Stop: $${result.stopLoss?.toFixed(6)} | R/R: 1:${result.riskReward?.toFixed(1)}`);
    if (result.reasoning?.length > 0) {
      console.log(`   🧠 ${result.reasoning[0]}`);
    }
    console.log('');
  });

  console.log('💡 CRYPTO TIPS:');
  console.log(`• Analysis completed in ${scanTime}s using optimized approach`);
  console.log('• All pairs available on eToro for 24/7 trading');
  console.log('• Higher volatility = higher risk/reward potential');
  console.log(`• ${timeframe} timeframe - crypto moves faster than stocks`);
  console.log('• Consider smaller position sizes due to volatility');
  
  return top5;
}

function getCryptoName(pair) {
  const cryptoNames = {
    'BTC/USDT': 'Bitcoin',
    'ETH/USDT': 'Ethereum',
    'BNB/USDT': 'Binance Coin',
    'ADA/USDT': 'Cardano',
    'SOL/USDT': 'Solana',
    'XRP/USDT': 'Ripple',
    'DOT/USDT': 'Polkadot',
    'LINK/USDT': 'Chainlink'
  };
  return cryptoNames[pair] || pair;
}

// Command line execution
const timeframe = process.argv[2] || 'short_term';

if (!TIMEFRAME_MAP[timeframe]) {
  console.log('❌ Invalid timeframe. Use: short_term, mid_term, or long_term');
  process.exit(1);
}

console.log('🚀 Starting Quick Crypto Scanner...\n');
quickScanCrypto(timeframe).catch(console.error); 