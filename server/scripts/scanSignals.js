require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');

// List of symbols to scan
const SYMBOLS = [
  'AAPL',  // Apple
  'MSFT',  // Microsoft
  'GOOGL', // Google
  'AMZN',  // Amazon
  'META',  // Meta (Facebook)
  'TSLA',  // Tesla
  'NVDA',  // NVIDIA
  'AMD',   // AMD
  'INTC',  // Intel
  'IBM'    // IBM
];

// Timeframes to scan
const TIMEFRAMES = [
  'short_term', // 1h
  'mid_term',   // 4h
  'long_term'   // 1d
];

// Minimum signal strength to consider
const MIN_SIGNAL_STRENGTH = 1.0;

async function scanSignals() {
  console.log('Starting signal scan...');
  console.log('----------------------------------------');
  
  const results = [];
  
  // Scan each symbol and timeframe
  for (const symbol of SYMBOLS) {
    console.log(`\nScanning ${symbol}...`);
    
    for (const timeframe of TIMEFRAMES) {
      try {
        console.log(`  Checking ${timeframe}...`);
        const analysis = await technicalAnalysisService.getTechnicalAnalysis(symbol, timeframe);
        
        // Only include results with significant signals
        if (Math.abs(analysis.analysis.strength) >= MIN_SIGNAL_STRENGTH) {
          results.push({
            symbol,
            timeframe,
            sentiment: analysis.analysis.sentiment,
            strength: analysis.analysis.strength,
            entryPrice: analysis.analysis.entryPrice,
            stopLoss: analysis.analysis.stopLoss,
            takeProfit: analysis.analysis.takeProfit,
            reasoning: analysis.analysis.reasoning,
            indicators: {
              rsi: analysis.indicators.rsi?.value,
              macd: analysis.indicators.macd?.valueMACDHist,
              ema: analysis.indicators.ema?.value,
              bbands2: {
                upper: analysis.indicators.bbands2?.valueUpperBand,
                middle: analysis.indicators.bbands2?.valueMiddleBand,
                lower: analysis.indicators.bbands2?.valueLowerBand
              }
            }
          });
        }
      } catch (error) {
        console.error(`  Error analyzing ${symbol} on ${timeframe}:`, error.message);
      }
    }
  }
  
  // Sort results by absolute signal strength
  results.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
  
  // Print results
  console.log('\nStrongest Signals Found:');
  console.log('----------------------------------------');
  
  if (results.length === 0) {
    console.log('No significant signals found.');
    return;
  }
  
  results.forEach((result, index) => {
    console.log(`\n${index + 1}. ${result.symbol} (${result.timeframe})`);
    console.log(`   Sentiment: ${result.sentiment}`);
    console.log(`   Strength: ${result.strength.toFixed(2)}`);
    console.log('\n   Technical Indicators:');
    console.log(`   RSI: ${result.indicators.rsi?.toFixed(2) ?? 'N/A'}`);
    console.log(`   MACD Histogram: ${result.indicators.macd?.toFixed(2) ?? 'N/A'}`);
    console.log(`   EMA: ${result.indicators.ema?.toFixed(2) ?? 'N/A'}`);
    console.log(`   Bollinger Bands:`);
    console.log(`     Upper: ${result.indicators.bbands2.upper?.toFixed(2) ?? 'N/A'}`);
    console.log(`     Middle: ${result.indicators.bbands2.middle?.toFixed(2) ?? 'N/A'}`);
    console.log(`     Lower: ${result.indicators.bbands2.lower?.toFixed(2) ?? 'N/A'}`);
    
    console.log('\n   Trading Levels:');
    console.log(`   Entry: ${result.entryPrice?.toFixed(2) ?? 'N/A'}`);
    console.log(`   Stop Loss: ${result.stopLoss?.toFixed(2) ?? 'N/A'}`);
    console.log(`   Take Profit: ${result.takeProfit?.toFixed(2) ?? 'N/A'}`);
    
    console.log('\n   Reasoning:');
    result.reasoning.forEach((reason, i) => {
      console.log(`   ${i + 1}. ${reason}`);
    });
    console.log('----------------------------------------');
  });
}

// Run the scan
scanSignals().catch(console.error); 