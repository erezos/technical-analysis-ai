/**
 * SUPER ANALYZE ALL SCRIPT - COMPREHENSIVE MARKET SCANNER
 * ======================================================
 * 
 * PURPOSE:
 * Ultimate market scanning tool that analyzes ALL stocks and crypto across ALL timeframes
 * in a single execution. Optimized for TAAPI Pro plan with bulk API requests for maximum 
 * efficiency and comprehensive market coverage.
 * 
 * USAGE:
 * node analyzeAll.js [options]
 * 
 * EXAMPLES:
 * node analyzeAll.js                           # Full scan - all assets, all timeframes
 * node analyzeAll.js --stocks-only             # Stocks only, all timeframes
 * node analyzeAll.js --crypto-only             # Crypto only, all timeframes
 * node analyzeAll.js --timeframe short_term    # All assets, 1-hour only
 * node analyzeAll.js --generate-images         # Include image generation for strong signals
 * node analyzeAll.js --top 10                  # Show top 10 signals per timeframe
 * 
 * FEATURES:
 * ✓ Analyzes 42+ major stocks across all timeframes
 * ✓ Analyzes 15+ major crypto pairs across all timeframes  
 * ✓ Uses TAAPI Pro bulk requests for efficiency
 * ✓ Groups results by timeframe for easy selection
 * ✓ Ranks signals by strength within each timeframe
 * ✓ Optional image generation for strongest signals
 * ✓ Comprehensive market overview in single execution
 * ✓ Optimized for eToro trading opportunities
 * ✓ Firebase integration for mobile app consumption
 * 
 * OUTPUT STRUCTURE:
 * ├── Short Term (1h) Signals
 * │   ├── Top Stocks (ranked by strength)
 * │   └── Top Crypto (ranked by strength)
 * ├── Mid Term (4h) Signals  
 * │   ├── Top Stocks (ranked by strength)
 * │   └── Top Crypto (ranked by strength)
 * └── Long Term (1d) Signals
 *     ├── Top Stocks (ranked by strength)
 *     └── Top Crypto (ranked by strength)
 * 
 * BULK API OPTIMIZATION:
 * - Uses TAAPI Pro bulk endpoints with enhanced rate limiting
 * - Processes 5 stocks per bulk request (reduced for rate limits)
 * - Processes 4 crypto pairs per bulk request (reduced for rate limits) 
 * - Intelligent batching with 3-4 second delays to stay within rate limits
 * - Total analysis time: ~10-15 minutes for full scan (with rate limiting)
 * 
 * SIGNAL FILTERING:
 * - Stocks: Minimum strength ≥ 2.0 (quality filter)
 * - Crypto: Minimum strength ≥ 0.8 (volatility adjusted)
 * - Results ranked by absolute signal strength
 * - Top signals prioritized for image generation
 * 
 * DEPENDENCIES:
 * - TAAPI_API_KEY environment variable (Pro plan recommended)
 * - Firebase project configuration
 * - DALL-E 3 API access (if --generate-images enabled)
 * - Company/crypto logos in public/logos/
 */

require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');
const tradingTipsService = require('../src/services/tradingTipsServiceOptimized');
const imageGenerationService = require('../src/services/imageGenerationService');
const logoUtils = require('../src/utils/logoUtils');

// eToro + TAAPI supported assets
const ETORO_STOCKS = [
  'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'TSLA', 'NVDA', 'AMD', 'INTC', 'IBM',
  'NFLX', 'JPM', 'BAC', 'WMT', 'DIS', 'V', 'MA', 'JNJ', 'PG', 'KO',
  'PEP', 'ADBE', 'CRM', 'ORCL', 'CSCO', 'HD', 'MCD', 'NKE', 'UNH', 'XOM',
  'GE', 'F', 'GM', 'PYPL', 'UBER'
];

const ETORO_CRYPTO = [
  'BTC/USDT', 'ETH/USDT', 'BNB/USDT', 'ADA/USDT', 'SOL/USDT', 'XRP/USDT',
  'DOT/USDT', 'LINK/USDT', 'LTC/USDT', 'BCH/USDT', 'DOGE/USDT', 'AVAX/USDT',
  'MATIC/USDT', 'UNI/USDT', 'ATOM/USDT'
];

const TIMEFRAMES = ['short_term', 'mid_term', 'long_term'];
const TIMEFRAME_LABELS = {
  'short_term': '1H (Short Term)',
  'mid_term': '4H (Mid Term)', 
  'long_term': '1D (Long Term)'
};

// Signal strength thresholds
const MIN_STOCK_STRENGTH = 2.0;
const MIN_CRYPTO_STRENGTH = 0.8;

class SuperMarketScanner {
  constructor(options = {}) {
    this.options = {
      stocksOnly: options.stocksOnly || false,
      cryptoOnly: options.cryptoOnly || false,
      timeframe: options.timeframe || null, // null = all timeframes
      generateImages: options.generateImages || false,
      topCount: options.topCount || 5,
      ...options
    };
    
    this.results = {
      short_term: { stocks: [], crypto: [] },
      mid_term: { stocks: [], crypto: [] },
      long_term: { stocks: [], crypto: [] }
    };
    
    this.stats = {
      totalProcessed: 0,
      totalSignals: 0,
      imagesGenerated: 0,
      processingTime: 0
    };
  }

  async scanAll() {
    const startTime = Date.now();
    
    console.log('🚀 SUPER ANALYZE ALL - COMPREHENSIVE MARKET SCANNER');
    console.log('===================================================');
    console.log(`📊 Mode: ${this.getModeDescription()}`);
    console.log(`⏰ Timeframes: ${this.getTimeframeDescription()}`);
    console.log(`🎯 Top results per timeframe: ${this.options.topCount}`);
    console.log(`🎨 Image generation: ${this.options.generateImages ? 'ENABLED' : 'DISABLED'}`);
    console.log('===================================================\n');

    // Determine which timeframes to scan
    const timeframesToScan = this.options.timeframe ? [this.options.timeframe] : TIMEFRAMES;
    
    // Scan each timeframe
    for (const timeframe of timeframesToScan) {
      console.log(`\n🔍 SCANNING ${TIMEFRAME_LABELS[timeframe].toUpperCase()}`);
      console.log('=' .repeat(50));
      
      // Scan stocks if enabled
      if (!this.options.cryptoOnly) {
        await this.scanStocks(timeframe);
      }
      
      // Scan crypto if enabled  
      if (!this.options.stocksOnly) {
        await this.scanCrypto(timeframe);
      }
    }

    this.stats.processingTime = (Date.now() - startTime) / 1000;
    
    // Generate comprehensive report
    await this.generateReport();
    
    // Generate images for top signals if enabled
    if (this.options.generateImages) {
      await this.generateTopImages();
    }

    console.log('\n✅ SUPER SCAN COMPLETED SUCCESSFULLY!');
    console.log('=====================================');
    console.log(`⏱️  Total processing time: ${this.stats.processingTime.toFixed(1)}s`);
    console.log(`📊 Total assets processed: ${this.stats.totalProcessed}`);
    console.log(`⚡ Strong signals found: ${this.stats.totalSignals}`);
    console.log(`🎨 Images generated: ${this.stats.imagesGenerated}`);
    console.log('=====================================');
  }

  async scanStocks(timeframe) {
    console.log(`📈 Scanning ${ETORO_STOCKS.length} stocks...`);
    
    const batchSize = 5; // Reduced batch size to respect rate limits
    const results = [];
    
    // Process stocks in batches for efficiency
    for (let i = 0; i < ETORO_STOCKS.length; i += batchSize) {
      const batch = ETORO_STOCKS.slice(i, i + batchSize);
      const batchNum = Math.floor(i/batchSize) + 1;
      const totalBatches = Math.ceil(ETORO_STOCKS.length/batchSize);
      
      console.log(`   📦 Batch ${batchNum}/${totalBatches}: ${batch.join(', ')}`);
      
      try {
        const batchResults = await this.processBatchStocks(batch, timeframe);
        results.push(...batchResults);
        this.stats.totalProcessed += batch.length;
        
                 // Rate limiting - delay between batches to respect API limits
         if (i + batchSize < ETORO_STOCKS.length) {
           await new Promise(resolve => setTimeout(resolve, 3000));
         }
      } catch (error) {
        console.error(`   ❌ Batch error: ${error.message}`);
      }
    }
    
    // Filter and sort results
    const strongSignals = results.filter(r => Math.abs(r.strength) >= MIN_STOCK_STRENGTH);
    strongSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    
    this.results[timeframe].stocks = strongSignals;
    this.stats.totalSignals += strongSignals.length;
    
    console.log(`   ✅ Found ${strongSignals.length} strong stock signals`);
  }

  async scanCrypto(timeframe) {
    console.log(`💰 Scanning ${ETORO_CRYPTO.length} crypto pairs...`);
    
    const batchSize = 4; // Smaller batches for crypto to respect rate limits
    const results = [];
    
    // Process crypto in batches
    for (let i = 0; i < ETORO_CRYPTO.length; i += batchSize) {
      const batch = ETORO_CRYPTO.slice(i, i + batchSize);
      const batchNum = Math.floor(i/batchSize) + 1;
      const totalBatches = Math.ceil(ETORO_CRYPTO.length/batchSize);
      
      console.log(`   📦 Batch ${batchNum}/${totalBatches}: ${batch.join(', ')}`);
      
      try {
        const batchResults = await this.processBatchCrypto(batch, timeframe);
        results.push(...batchResults);
        this.stats.totalProcessed += batch.length;
        
                 // Rate limiting - delay between batches to respect API limits
         if (i + batchSize < ETORO_CRYPTO.length) {
           await new Promise(resolve => setTimeout(resolve, 4000));
         }
      } catch (error) {
        console.error(`   ❌ Batch error: ${error.message}`);
      }
    }
    
    // Filter and sort results
    const strongSignals = results.filter(r => Math.abs(r.strength) >= MIN_CRYPTO_STRENGTH);
    strongSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    
    this.results[timeframe].crypto = strongSignals;
    this.stats.totalSignals += strongSignals.length;
    
    console.log(`   ✅ Found ${strongSignals.length} strong crypto signals`);
  }

  async processBatchStocks(symbols, timeframe) {
    const results = [];
    
    for (const symbol of symbols) {
      try {
        const analysis = await technicalAnalysisService.getTechnicalAnalysis(symbol, timeframe);
        
        if (Math.abs(analysis.analysis.strength) >= MIN_STOCK_STRENGTH) {
          const company = logoUtils.getStockCompanyInfo(symbol);
          
          results.push({
            type: 'stock',
            symbol: symbol,
            name: company.name,
            timeframe: timeframe,
            sentiment: analysis.analysis.sentiment,
            strength: analysis.analysis.strength,
            confidence: analysis.analysis.confidence,
            entryPrice: analysis.analysis.entryPrice,
            stopLoss: analysis.analysis.stopLoss,
            takeProfit: analysis.analysis.takeProfit,
            riskReward: analysis.analysis.riskRewardRatio,
            reasoning: analysis.analysis.reasoning,
            indicators: analysis.indicators,
            company: company,
            metadata: {
              generatedAt: new Date().toISOString(),
              scanner: 'analyzeAll_v1'
            }
          });
        }
        
        // Delay between symbols to respect API rate limits
        await new Promise(resolve => setTimeout(resolve, 500));
        
      } catch (error) {
        console.error(`      ❌ ${symbol}: ${error.message}`);
      }
    }
    
    return results;
  }

  async processBatchCrypto(pairs, timeframe) {
    const results = [];
    
    for (const pair of pairs) {
      try {
        // Use crypto analysis service with Binance exchange
        const analysis = await this.getCryptoAnalysis(pair, timeframe);
        
        if (Math.abs(analysis.analysis.strength) >= MIN_CRYPTO_STRENGTH) {
          const crypto = logoUtils.getCryptoCompanyInfo(pair);
          
          results.push({
            type: 'crypto',
            symbol: pair,
            name: crypto.name,
            timeframe: timeframe,
            sentiment: analysis.analysis.sentiment,
            strength: analysis.analysis.strength,
            confidence: analysis.analysis.confidence,
            entryPrice: analysis.analysis.entryPrice,
            stopLoss: analysis.analysis.stopLoss,
            takeProfit: analysis.analysis.takeProfit,
            riskReward: analysis.analysis.riskRewardRatio,
            reasoning: analysis.analysis.reasoning,
            indicators: analysis.indicators,
            company: crypto,
            metadata: {
              generatedAt: new Date().toISOString(),
              scanner: 'analyzeAll_v1',
              exchange: 'binance'
            }
          });
        }
        
        // Delay between crypto pairs to respect API rate limits  
        await new Promise(resolve => setTimeout(resolve, 800));
        
      } catch (error) {
        console.error(`      ❌ ${pair}: ${error.message}`);
      }
    }
    
    return results;
  }

  async getCryptoAnalysis(pair, timeframe) {
    // Use technicalAnalysisService but with Binance exchange for crypto
    const timeframeMap = {
      'short_term': '1h',
      'mid_term': '4h', 
      'long_term': '1d'
    };
    
    const construct = {
      exchange: 'binance',
      symbol: pair,
      interval: timeframeMap[timeframe],
      indicators: [
        { indicator: 'rsi', period: 14 },
        { indicator: 'macd' },
        { indicator: 'bbands', period: 20, stddev: 2 },
        { indicator: 'ema', period: 50 },
        { indicator: 'ema', period: 200 },
        { indicator: 'adx', period: 14 },
        { indicator: 'atr', period: 14 }
      ]
    };

    const results = await technicalAnalysisService.makeBulkRequest(construct);
    
    // Process results into analysis format
    const indicators = {};
    let currentPrice = null;
    
    results.forEach(result => {
      if (result.indicator === 'rsi') {
        indicators.rsi = result;
        if (!currentPrice) currentPrice = result.value;
      } else if (result.indicator === 'macd') {
        indicators.macd = result;
      } else if (result.indicator === 'bbands') {
        indicators.bbands = result;
        if (!currentPrice && result.valueMiddleBand) currentPrice = result.valueMiddleBand;
      } else if (result.indicator === 'ema' && result.period === 50) {
        if (!indicators.ema) indicators.ema = {};
        indicators.ema.ema50 = result;
        if (!currentPrice) currentPrice = result.value;
      } else if (result.indicator === 'ema' && result.period === 200) {
        if (!indicators.ema) indicators.ema = {};
        indicators.ema.ema200 = result;
      } else if (result.indicator === 'adx') {
        indicators.adx = result;
      } else if (result.indicator === 'atr') {
        indicators.atr = result;
      }
    });

    // Generate analysis using the same logic as crypto analysis
    const analysis = this.generateCryptoAnalysis(pair, indicators, currentPrice, timeframe);
    
    return {
      symbol: pair,
      timeframe: timeframe,
      indicators: indicators,
      analysis: analysis
    };
  }

  generateCryptoAnalysis(symbol, indicators, currentPrice, timeframe) {
    // Simplified crypto analysis logic (similar to analyzeCrypto.js)
    const signals = [];
    let signalStrength = 0;
    
    // RSI Analysis  
    const rsi = indicators.rsi?.value;
    if (rsi) {
      if (rsi < 30) {
        signals.push(`RSI (${rsi.toFixed(1)}) indicates oversold conditions - potential bounce`);
        signalStrength += 1;
      } else if (rsi > 70) {
        signals.push(`RSI (${rsi.toFixed(1)}) indicates overbought conditions - potential correction`);
        signalStrength -= 1;
      }
    }
    
    // MACD Analysis
    const macdHist = indicators.macd?.valueMACDHist;
    if (macdHist) {
      if (macdHist > 0) {
        signals.push('MACD histogram positive - bullish momentum building');
        signalStrength += 0.5;
      } else {
        signals.push('MACD histogram negative - bearish momentum building');
        signalStrength -= 0.5;
      }
    }
    
    // EMA Trend Analysis
    const ema50 = indicators.ema?.ema50?.value;
    const ema200 = indicators.ema?.ema200?.value;
    if (ema50 && ema200) {
      if (ema50 > ema200) {
        signals.push('EMA50 above EMA200 - uptrend confirmed');
        signalStrength += 0.8;
      } else {
        signals.push('EMA50 below EMA200 - downtrend confirmed');
        signalStrength -= 0.8;
      }
    }
    
    // Bollinger Bands Analysis
    const bbUpper = indicators.bbands?.valueUpperBand;
    const bbLower = indicators.bbands?.valueLowerBand;
    if (bbUpper && bbLower && currentPrice) {
      if (currentPrice <= bbLower) {
        signals.push('Price near lower Bollinger Band - potential bounce');
        signalStrength += 0.5;
      } else if (currentPrice >= bbUpper) {
        signals.push('Price near upper Bollinger Band - potential pullback');
        signalStrength -= 0.5;
      }
    }
    
    // Determine sentiment and calculate levels
    const sentiment = signalStrength > 0.3 ? 'bullish' : signalStrength < -0.3 ? 'bearish' : 'neutral';
    const confidence = Math.min(95, Math.abs(signalStrength) * 30 + 50);
    
    // Calculate trading levels using ATR
    const atr = indicators.atr?.value || currentPrice * 0.03;
    const entryPrice = currentPrice;
    const stopLoss = sentiment === 'bullish' ? currentPrice - (atr * 2) : currentPrice + (atr * 2);
    const takeProfit = sentiment === 'bullish' ? currentPrice + (atr * 3) : currentPrice - (atr * 3);
    const riskRewardRatio = Math.abs(takeProfit - entryPrice) / Math.abs(entryPrice - stopLoss);
    
    return {
      sentiment: sentiment,
      strength: signalStrength,
      confidence: confidence,
      entryPrice: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      riskRewardRatio: riskRewardRatio,
      reasoning: signals
    };
  }

  async generateReport() {
    console.log('\n📊 COMPREHENSIVE MARKET ANALYSIS REPORT');
    console.log('=======================================');
    
    const timeframesToShow = this.options.timeframe ? [this.options.timeframe] : TIMEFRAMES;
    
    for (const timeframe of timeframesToShow) {
      const stocks = this.results[timeframe].stocks.slice(0, this.options.topCount);
      const crypto = this.results[timeframe].crypto.slice(0, this.options.topCount);
      
      console.log(`\n🕐 ${TIMEFRAME_LABELS[timeframe].toUpperCase()}`);
      console.log('=' .repeat(40));
      
      // Stock signals
      if (!this.options.cryptoOnly && stocks.length > 0) {
        console.log(`\n📈 TOP ${stocks.length} STOCK SIGNALS:`);
        stocks.forEach((stock, index) => {
          const emoji = ['🥇', '🥈', '🥉', '🏅', '⭐'][index] || '🔥';
          const sentimentEmoji = stock.sentiment === 'bullish' ? '📈' : '📉';
          console.log(`${emoji} ${stock.symbol} (${stock.name}) ${sentimentEmoji}`);
          console.log(`   Strength: ${stock.strength.toFixed(2)} | Entry: $${stock.entryPrice?.toFixed(2)} | R/R: 1:${stock.riskReward?.toFixed(2)}`);
        });
      }
      
      // Crypto signals  
      if (!this.options.stocksOnly && crypto.length > 0) {
        console.log(`\n💰 TOP ${crypto.length} CRYPTO SIGNALS:`);
        crypto.forEach((coin, index) => {
          const emoji = ['🥇', '🥈', '🥉', '🏅', '⭐'][index] || '🚀';
          const sentimentEmoji = coin.sentiment === 'bullish' ? '🚀' : '📉';
          console.log(`${emoji} ${coin.symbol} (${coin.name}) ${sentimentEmoji}`);
          console.log(`   Strength: ${coin.strength.toFixed(2)} | Entry: $${coin.entryPrice?.toFixed(6)} | R/R: 1:${coin.riskReward?.toFixed(2)}`);
        });
      }
    }
    
    console.log('\n🎯 SELECTION GUIDE:');
    console.log('• Short Term (1H): Quick scalping opportunities');  
    console.log('• Mid Term (4H): Swing trading setups');
    console.log('• Long Term (1D): Position trading entries');
    console.log('• Higher strength = higher conviction signals');
    console.log('• Diversify across timeframes for balanced portfolio');
  }

  async generateTopImages() {
    console.log('\n🎨 GENERATING IMAGES FOR TOP SIGNALS...');
    console.log('======================================');
    
    const allSignals = [];
    
    // Collect all strong signals across timeframes
    for (const timeframe of TIMEFRAMES) {
      allSignals.push(...this.results[timeframe].stocks);
      allSignals.push(...this.results[timeframe].crypto);
    }
    
    // Sort by strength and take top signals
    allSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    const topSignals = allSignals.slice(0, 10); // Top 10 signals for image generation
    
    for (const signal of topSignals) {
      try {
        console.log(`🎨 Generating images for ${signal.symbol}...`);
        
        let backgroundUrl, accentUrl;
        
        if (signal.type === 'stock') {
          backgroundUrl = await imageGenerationService.generateTradingBackgroundImage(signal);
          accentUrl = await imageGenerationService.generateTradingAccentImage(signal);
        } else {
          // Use crypto-specific image generation
          backgroundUrl = await this.generateCryptoBackground(signal);
          accentUrl = await this.generateCryptoAccent(signal);
        }
        
        // Save to Firebase
        await tradingTipsService.saveBackgroundImages(signal, backgroundUrl, accentUrl);
        
        this.stats.imagesGenerated++;
        console.log(`   ✅ Images saved for ${signal.symbol}`);
        
        // Small delay between image generations
        await new Promise(resolve => setTimeout(resolve, 1000));
        
      } catch (error) {
        console.error(`   ❌ Image generation failed for ${signal.symbol}: ${error.message}`);
      }
    }
  }

  async generateCryptoBackground(signal) {
    // Simplified crypto background generation
    return await imageGenerationService.generateTradingBackgroundImage(signal);
  }

  async generateCryptoAccent(signal) {
    // Simplified crypto accent generation  
    return await imageGenerationService.generateTradingAccentImage(signal);
  }

  getModeDescription() {
    if (this.options.stocksOnly) return 'STOCKS ONLY';
    if (this.options.cryptoOnly) return 'CRYPTO ONLY';
    return 'STOCKS + CRYPTO';
  }

  getTimeframeDescription() {
    if (this.options.timeframe) return TIMEFRAME_LABELS[this.options.timeframe];
    return 'ALL (1H, 4H, 1D)';
  }
}

// Command line argument parsing
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {};
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--stocks-only':
        options.stocksOnly = true;
        break;
      case '--crypto-only':
        options.cryptoOnly = true;
        break;
      case '--timeframe':
        options.timeframe = args[++i];
        break;
      case '--generate-images':
        options.generateImages = true;
        break;
      case '--top':
        options.topCount = parseInt(args[++i]) || 5;
        break;
    }
  }
  
  return options;
}

// Main execution
async function main() {
  const options = parseArgs();
  
  // Validate timeframe if specified
  if (options.timeframe && !TIMEFRAMES.includes(options.timeframe)) {
    console.error('❌ Invalid timeframe. Use: short_term, mid_term, or long_term');
    process.exit(1);
  }
  
  const scanner = new SuperMarketScanner(options);
  await scanner.scanAll();
}

// Show usage if no arguments or help requested
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
🚀 SUPER ANALYZE ALL - COMPREHENSIVE MARKET SCANNER
==================================================

USAGE:
  node analyzeAll.js [options]

OPTIONS:
  --stocks-only              Analyze stocks only
  --crypto-only              Analyze crypto only  
  --timeframe <timeframe>    Analyze specific timeframe only
                            (short_term, mid_term, long_term)
  --generate-images          Generate images for top signals
  --top <number>            Show top N results per timeframe (default: 5)
  --help, -h                Show this help message

EXAMPLES:
  node analyzeAll.js                           # Full comprehensive scan
  node analyzeAll.js --stocks-only             # Stocks across all timeframes
  node analyzeAll.js --crypto-only             # Crypto across all timeframes
  node analyzeAll.js --timeframe short_term    # 1-hour analysis only
  node analyzeAll.js --generate-images --top 3 # Generate images, show top 3

FEATURES:
  ✓ Analyzes 40+ stocks and 15+ crypto pairs
  ✓ Uses TAAPI Pro bulk requests for efficiency
  ✓ Groups results by timeframe for easy selection
  ✓ Ranks signals by strength within each timeframe
  ✓ Optional image generation for strongest signals
  ✓ Comprehensive market overview in single execution

ESTIMATED TIME:
  Full scan: ~5-7 minutes
  Single timeframe: ~2-3 minutes  
  With images: +2-5 minutes additional
`);
  process.exit(0);
}

// Run the scanner
if (require.main === module) {
  main().catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });
}

module.exports = SuperMarketScanner;