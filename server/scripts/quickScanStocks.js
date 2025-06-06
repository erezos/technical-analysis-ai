require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');

// Reduced list - focus on most liquid eToro stocks
const TOP_ETORO_STOCKS = [
  'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 
  'TSLA', 'NVDA', 'AMD', 'NFLX', 'V'
];

const TIMEFRAME_MAP = {
  'short_term': '1h',
  'mid_term': '4h', 
  'long_term': '1d'
};

// Lower threshold for faster results
const MIN_SIGNAL_STRENGTH = 0.5;

async function quickScanStocks(timeframe = 'short_term') {
  console.log('⚡ QUICK ETORO STOCK SCANNER');
  console.log('===========================');
  console.log(`📊 Timeframe: ${timeframe} (${TIMEFRAME_MAP[timeframe]})`);
  console.log(`📈 Analyzing ${TOP_ETORO_STOCKS.length} top stocks`);
  console.log(`⚡ Signal threshold: ${MIN_SIGNAL_STRENGTH} (lowered for speed)`);
  console.log('===========================\n');

  const results = [];
  const startTime = Date.now();

  // Process stocks quickly without batching delays
  for (const symbol of TOP_ETORO_STOCKS) {
    try {
      console.log(`📊 ${symbol}...`);
      const analysis = await technicalAnalysisService.getTechnicalAnalysis(symbol, timeframe);
      
      if (Math.abs(analysis.analysis.strength) >= MIN_SIGNAL_STRENGTH) {
        results.push({
          symbol,
          company: getCompanyName(symbol),
          timeframe,
          sentiment: analysis.analysis.sentiment,
          strength: analysis.analysis.strength,
          confidence: analysis.analysis.confidence,
          entryPrice: analysis.analysis.entryPrice,
          stopLoss: analysis.analysis.stopLoss,
          takeProfit: analysis.analysis.takeProfit,
          riskReward: analysis.analysis.riskRewardRatio,
          reasoning: analysis.analysis.reasoning.slice(0, 2) // Limit reasoning for speed
        });
        console.log(`   ✅ Signal: ${analysis.analysis.sentiment} (${analysis.analysis.strength.toFixed(2)})`);
      } else {
        console.log(`   ⚪ Weak: ${analysis.analysis.strength.toFixed(2)}`);
      }
      
      // Minimal delay - just 100ms
      await new Promise(resolve => setTimeout(resolve, 100));
      
    } catch (error) {
      console.error(`   ❌ Error ${symbol}: ${error.message}`);
    }
  }

  // Sort by strength and get top 5
  results.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
  const top5 = results.slice(0, 5);
  const scanTime = ((Date.now() - startTime) / 1000).toFixed(1);

  console.log('\n🏆 QUICK SCAN RESULTS');
  console.log('===========================');
  console.log(`⏱️  Scan completed in: ${scanTime} seconds`);
  console.log(`📊 Stocks analyzed: ${TOP_ETORO_STOCKS.length}`);
  console.log(`⚡ Signals found: ${results.length}`);
  console.log(`🥇 Top picks: ${top5.length}`);
  console.log('===========================\n');

  if (top5.length === 0) {
    console.log('😔 No signals found. Market might be in consolidation.');
    return [];
  }

  // Quick display format
  console.log('🚀 TOP TRADING SIGNALS');
  console.log('===========================');

  top5.forEach((result, index) => {
    const emoji = ['🥇', '🥈', '🥉', '🏅', '⭐'][index];
    const arrow = result.sentiment === 'bullish' ? '📈' : '📉';
    
    console.log(`${emoji} ${result.symbol} (${result.company})`);
    console.log(`   ${arrow} ${result.sentiment.toUpperCase()} - Strength: ${result.strength.toFixed(2)}`);
    console.log(`   💰 Entry: $${result.entryPrice?.toFixed(2)} | Target: $${result.takeProfit?.toFixed(2)}`);
    console.log(`   🛡️  Stop: $${result.stopLoss?.toFixed(2)} | R/R: 1:${result.riskReward?.toFixed(1)}`);
    if (result.reasoning?.length > 0) {
      console.log(`   🧠 ${result.reasoning[0]}`);
    }
    console.log('');
  });

  console.log('💡 QUICK TIPS:');
  console.log(`• Analysis completed in ${scanTime}s using optimized approach`);
  console.log('• All signals are from top eToro liquid stocks');
  console.log('• Lower threshold used for faster market scanning');
  console.log(`• ${timeframe} timeframe - adjust position size accordingly`);
  
  return top5;
}

function getCompanyName(symbol) {
  const companies = {
    'AAPL': 'Apple Inc.',
    'MSFT': 'Microsoft Corp.',
    'GOOGL': 'Alphabet Inc.',
    'AMZN': 'Amazon.com Inc.',
    'META': 'Meta Platforms',
    'TSLA': 'Tesla Inc.',
    'NVDA': 'NVIDIA Corp.',
    'AMD': 'Advanced Micro Devices',
    'NFLX': 'Netflix Inc.',
    'V': 'Visa Inc.'
  };
  return companies[symbol] || symbol;
}

// Command line execution
const timeframe = process.argv[2] || 'short_term';

if (!TIMEFRAME_MAP[timeframe]) {
  console.log('❌ Invalid timeframe. Use: short_term, mid_term, or long_term');
  process.exit(1);
}

console.log('🚀 Starting Quick Stock Scanner...\n');
quickScanStocks(timeframe).catch(console.error); 