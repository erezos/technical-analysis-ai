require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');

// Top crypto pairs available on both eToro and TAAPI Binance (using TAAPI format)
const TOP_CRYPTO_PAIRS = [
  'BTC/USDT', 'ETH/USDT', 'BNB/USDT', 'ADA/USDT', 
  'SOL/USDT', 'XRP/USDT', 'DOT/USDT', 'LINK/USDT',
  'AVAX/USDT', 'MATIC/USDT', 'LTC/USDT', 'ATOM/USDT',
  'ALGO/USDT', 'VET/USDT', 'FIL/USDT', 'TRX/USDT'
];

const TIMEFRAME_MAP = {
  'short_term': '1h',
  'mid_term': '4h', 
  'long_term': '1d'
};

const MIN_SIGNAL_STRENGTH = 0.8;

class CryptoBulkScanner {
  constructor() {
    this.requestCount = 0;
    this.startTime = Date.now();
    this.requestTimes = [];
    
    // TAAPI Pro plan rate limiting
    this.maxRequestsPerWindow = 30; // Pro plan limit
    this.windowDurationMs = 15000; // 15 seconds
    this.safetyBuffer = 100; // Minimal safety buffer for Pro plan
    this.batchDelay = 300; // Very fast for crypto with Pro plan
    this.skippedPairs = [];
    
    console.log('⚡ CRYPTO SCANNER - TAAPI PRO PLAN OPTIMIZED');
    console.log('🚀 Using technicalAnalysisService.js with Binance exchange');
    console.log('💎 Crypto optimized thresholds and analysis');
  }

  async smartDelay() {
    const now = Date.now();
    
    // Remove old requests outside the current 15-second window
    this.requestTimes = this.requestTimes.filter(time => 
      now - time < this.windowDurationMs
    );
    
    // If we've hit the limit for this window, wait until we can make another request
    if (this.requestTimes.length >= this.maxRequestsPerWindow) {
      const oldestRequest = Math.min(...this.requestTimes);
      const waitTime = (oldestRequest + this.windowDurationMs + this.safetyBuffer) - now;
      
      if (waitTime > 0) {
        console.log(`   ⏳ Rate limit window full (${this.requestTimes.length}/${this.maxRequestsPerWindow}). Waiting ${(waitTime/1000).toFixed(1)}s...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
    
    // Record this request
    this.requestTimes.push(Date.now());
    this.requestCount++;
  }

  async analyzeCryptoWithRetry(symbol, timeframe, retryCount = 0) {
    try {
      await this.smartDelay();
      console.log(`   📊 ${symbol}... (request #${this.requestCount})`);
      
      // Create a custom crypto-optimized technical analysis call
      const analysis = await this.getCryptoTechnicalAnalysis(symbol, timeframe);
      
      // Apply crypto-specific adjustments to the analysis
      return this.adaptForCrypto(symbol, analysis);
      
    } catch (error) {
      if (error.message.includes('rate limit') && retryCount < 3) {
        console.log(`      ⚠️  Rate limit hit for ${symbol}, retrying in 15 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 15000));
        return this.analyzeCryptoWithRetry(symbol, timeframe, retryCount + 1);
      } else if (error.message.includes('timeout') && retryCount < 3) {
        console.log(`      ⚠️  Timeout for ${symbol}, retrying with longer delay...`);
        await new Promise(resolve => setTimeout(resolve, 10000));
        return this.analyzeCryptoWithRetry(symbol, timeframe, retryCount + 1);
      } else {
        console.error(`      ❌ Error ${symbol}: ${error.message}`);
        console.log(`      ⏭️  Skipping ${symbol} and continuing...`);
        this.skippedPairs.push(symbol);
        return null;
      }
    }
  }

  async getCryptoTechnicalAnalysis(symbol, timeframe) {
    // Use the technicalAnalysisService but override for crypto exchange
    const service = technicalAnalysisService;
    
    // Map our timeframes to TAAPI timeframes
    const timeframeMap = {
      'short_term': '1h',
      'mid_term': '4h', 
      'long_term': '1d'
    };

    const taTimeframe = timeframeMap[timeframe];
    
    // Create crypto-specific bulk request construct
    const construct = {
      exchange: 'binance', // Use binance exchange for crypto
      symbol: symbol, // Use symbol as-is (BTC/USDT format)
      interval: taTimeframe,
      indicators: [
        // Core reliable indicators for crypto
        { indicator: 'rsi', period: 14 },
        { indicator: 'macd' },
        { indicator: 'bbands', period: 20, stddev: 2 },
        { indicator: 'ema', period: 50 },
        { indicator: 'ema', period: 200 },
        { indicator: 'adx', period: 14 },
        { indicator: 'atr', period: 14 }
      ]
    };

    // Make bulk request for all indicators
    const results = await service.makeBulkRequest(construct);
    
    // Process results same way as technicalAnalysisService
    const indicators = {};
    let currentPrice = null;
    
    results.forEach(result => {
      const indicatorName = result.indicator;
      
      // Handle multiple EMA periods properly
      if (indicatorName === 'ema') {
        if (!indicators.ema) indicators.ema = {};
        // Extract period from the ID
        const period = result.id.includes('_50_') ? 50 : result.id.includes('_200_') ? 200 : 'unknown';
        indicators.ema[`ema${period}`] = result.result;
      } else {
        indicators[indicatorName] = result.result;
      }
      
      // Get current price from any result that has 'close' value
      if (result.result && typeof result.result === 'object' && result.result.close && !currentPrice) {
        currentPrice = result.result.close;
      }
    });

    // If no current price found, get latest from EMA50 or any EMA
    if (!currentPrice) {
      if (indicators.ema?.ema50?.value) {
        currentPrice = indicators.ema.ema50.value;
      } else if (indicators.ema?.ema200?.value) {
        currentPrice = indicators.ema.ema200.value;
      }
    }

    // Generate analysis using the same method as technicalAnalysisService
    const analysis = service.generateAdvancedAnalysis(symbol, indicators, currentPrice, timeframe);

    return {
      symbol,
      timeframe,
      indicators,
      analysis,
      currentPrice,
      timestamp: new Date().toISOString()
    };
  }

  adaptForCrypto(symbol, analysis) {
    // Adapt the analysis for crypto-specific characteristics
    const cryptoAnalysis = {
      symbol,
      pair: symbol, // Already in BTC/USDT format
      crypto: this.getCryptoName(symbol),
      sentiment: analysis.analysis.sentiment,
      strength: analysis.analysis.strength,
      confidence: analysis.analysis.confidence,
      entryPrice: analysis.analysis.entryPrice,
      stopLoss: analysis.analysis.stopLoss,
      takeProfit: analysis.analysis.takeProfit,
      riskReward: analysis.analysis.riskRewardRatio,
      reasoning: analysis.analysis.reasoning.slice(0, 2),
      indicators: {
        rsi: analysis.indicators.rsi?.value,
        macd: analysis.indicators.macd?.valueMACDHist,
        ema50: analysis.indicators.ema?.ema50?.value,
        ema200: analysis.indicators.ema?.ema200?.value,
        atr: analysis.indicators.atr?.value
      }
    };

    // Apply crypto-specific RSI threshold adjustments
    if (cryptoAnalysis.indicators.rsi) {
      const rsi = cryptoAnalysis.indicators.rsi;
      
      // Crypto uses more extreme RSI thresholds (20/80 vs 30/70 for stocks)
      if (rsi < 20) {
        cryptoAnalysis.reasoning.unshift(`RSI (${rsi.toFixed(1)}) extremely oversold - strong crypto buy signal`);
        cryptoAnalysis.strength = Math.min(5, cryptoAnalysis.strength + 0.5); // Boost strength for crypto
      } else if (rsi > 80) {
        cryptoAnalysis.reasoning.unshift(`RSI (${rsi.toFixed(1)}) extremely overbought - strong crypto sell signal`);
        cryptoAnalysis.strength = Math.min(5, cryptoAnalysis.strength + 0.5); // Boost strength for crypto
      }
    }

    return cryptoAnalysis;
  }

  getCryptoName(symbol) {
    const cryptoNames = {
      'BTC/USDT': 'Bitcoin',
      'ETH/USDT': 'Ethereum', 
      'BNB/USDT': 'Binance Coin',
      'ADA/USDT': 'Cardano',
      'SOL/USDT': 'Solana',
      'XRP/USDT': 'Ripple',
      'DOT/USDT': 'Polkadot',
      'LINK/USDT': 'Chainlink',
      'AVAX/USDT': 'Avalanche',
      'MATIC/USDT': 'Polygon',
      'LTC/USDT': 'Litecoin',
      'ATOM/USDT': 'Cosmos',
      'ALGO/USDT': 'Algorand',
      'VET/USDT': 'VeChain',
      'FIL/USDT': 'Filecoin',
      'TRX/USDT': 'TRON'
    };
    return cryptoNames[symbol] || symbol;
  }

  async scanBestCrypto(timeframe = 'short_term') {
    console.log('💎 ETORO CRYPTO SCANNER - PRO PLAN OPTIMIZED');
    console.log('============================================');
    console.log(`📊 Timeframe: ${timeframe} (${TIMEFRAME_MAP[timeframe]})`);
    console.log(`💰 Analyzing ${TOP_CRYPTO_PAIRS.length} crypto pairs`);
    console.log(`⚡ Signal threshold: ${MIN_SIGNAL_STRENGTH}`);
    console.log(`🔧 Using Binance exchange via technicalAnalysisService.js`);
    console.log(`🚀 Pro batch delay: ${this.batchDelay}ms`);
    console.log('============================================\n');

    const results = [];
    const batchSize = 8; // Optimal for crypto with Pro plan
    
    for (let i = 0; i < TOP_CRYPTO_PAIRS.length; i += batchSize) {
      const batch = TOP_CRYPTO_PAIRS.slice(i, i + batchSize);
      const batchNum = Math.floor(i/batchSize) + 1;
      const totalBatches = Math.ceil(TOP_CRYPTO_PAIRS.length/batchSize);
      
      console.log(`📦 Crypto Batch ${batchNum}/${totalBatches}: ${batch.join(', ')}`);

      for (const symbol of batch) {
        const analysis = await this.analyzeCryptoWithRetry(symbol, timeframe);
        
        if (analysis && Math.abs(analysis.strength) >= MIN_SIGNAL_STRENGTH) {
          results.push({
            ...analysis,
            timeframe
          });
          console.log(`      ✅ Signal: ${analysis.sentiment} (${analysis.strength.toFixed(2)})`);
        } else if (analysis) {
          console.log(`      ⚪ Weak: ${analysis.strength.toFixed(2)}`);
        }
      }
      
      // Pro plan optimized batch delay
      if (i + batchSize < TOP_CRYPTO_PAIRS.length) {
        console.log(`   🚀 Crypto batch complete. Waiting ${this.batchDelay}ms before next batch...\n`);
        await new Promise(resolve => setTimeout(resolve, this.batchDelay));
      }
    }

    return this.displayResults(results, timeframe);
  }

  displayResults(results, timeframe) {
    // Sort and display results
    results.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    const top5 = results.slice(0, 5);
    const scanTime = ((Date.now() - this.startTime) / 1000).toFixed(1);

    console.log('\n🏆 CRYPTO SCAN RESULTS - PRO OPTIMIZED');
    console.log('=====================================');
    console.log(`⏱️  Scan completed in: ${scanTime} seconds`);
    console.log(`💰 Crypto pairs analyzed: ${TOP_CRYPTO_PAIRS.length - this.skippedPairs.length}`);
    console.log(`⏭️  Pairs skipped: ${this.skippedPairs.length}`);
    if (this.skippedPairs.length > 0) {
      console.log(`   Skipped: ${this.skippedPairs.join(', ')}`);
    }
    console.log(`📈 API requests made: ${this.requestCount}`);
    console.log(`⚡ Strong signals found: ${results.length}`);
    console.log(`🥇 Top picks: ${top5.length}`);
    console.log('=====================================\n');

    if (top5.length === 0) {
      console.log('😔 No strong crypto signals found. Market consolidating.');
      console.log('💡 Try a different timeframe or lower the threshold.');
      return [];
    }

    // Display results
    console.log('🚀 TOP CRYPTO SIGNALS');
    console.log('=====================================');

    top5.forEach((result, index) => {
      const emoji = ['🥇', '🥈', '🥉', '🏅', '⭐'][index];
      const arrow = result.sentiment === 'bullish' ? '🚀' : '📉';
      
      console.log(`\n${emoji} ${result.pair} - ${result.crypto}`);
      console.log(`   ${arrow} ${result.sentiment.toUpperCase()} (${result.strength.toFixed(2)}/5.0)`);
      console.log(`   🎯 Confidence: ${result.confidence.toFixed(1)}%`);
      console.log(`   💰 Entry: $${result.entryPrice?.toFixed(6)} | Target: $${result.takeProfit?.toFixed(6)}`);
      console.log(`   🛡️  Stop: $${result.stopLoss?.toFixed(6)} | R/R: 1:${result.riskReward?.toFixed(2)}`);
      console.log(`   📊 RSI: ${result.indicators.rsi?.toFixed(1)} | MACD: ${result.indicators.macd?.toFixed(4)}`);
      if (result.reasoning?.length > 0) {
        console.log(`   🧠 ${result.reasoning[0]}`);
      }
    });

    console.log('\n💡 CRYPTO TRADING INSIGHTS:');
    console.log(`• Fixed! Now using Binance exchange for crypto data`);
    console.log(`• Pro plan scan completed in ${scanTime}s`);
    console.log('• All pairs available on eToro for 24/7 trading');
    console.log('• Crypto-optimized RSI thresholds (20/80 vs stocks 30/70)');
    console.log('• Higher volatility = wider stop losses and targets');
    console.log(`• ${timeframe} timeframe - crypto moves 3x faster than stocks`);
    console.log('• Extended list includes DeFi and Layer-1 tokens');
    console.log(`• Average ${(parseFloat(scanTime) / this.requestCount).toFixed(1)}s per crypto analysis`);
    
    return top5;
  }
}

// Command line execution
const timeframe = process.argv[2] || 'short_term';

if (!TIMEFRAME_MAP[timeframe]) {
  console.log('❌ Invalid timeframe. Use: short_term, mid_term, or long_term');
  process.exit(1);
}

const scanner = new CryptoBulkScanner();
scanner.scanBestCrypto(timeframe).catch(console.error); 