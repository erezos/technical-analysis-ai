/**
 * TRUE BULK STOCK SCANNER SCRIPT (EXPERIMENTAL)
 * =============================================
 * 
 * PURPOSE:
 * Experimental implementation using TAAPI.io's true bulk API endpoint to analyze
 * multiple stocks simultaneously in a single API call. This approach attempts to
 * maximize efficiency by reducing the total number of API requests required.
 * 
 * USAGE:
 * node scanBestStocksBulk.js [timeframe]
 * 
 * EXAMPLES:
 * node scanBestStocksBulk.js                    # Default mid_term analysis
 * node scanBestStocksBulk.js short_term         # 1-hour analysis
 * node scanBestStocksBulk.js long_term          # Daily analysis
 * 
 * PARAMETERS:
 * - timeframe: [Optional] short_term (1h), mid_term (4h), long_term (1d)
 *   Default: mid_term
 * 
 * KEY DIFFERENCES FROM OTHER SCANNERS:
 * 
 * 📊 TRUE BULK API APPROACH:
 * - Uses TAAPI.io bulk endpoint with multiple constructs
 * - Sends array of symbol requests in single API call
 * - Processes 10 stocks per bulk request (vs 1 per request)
 * - Potentially faster but less reliable due to API complexity
 * 
 * 🔧 CUSTOM ANALYSIS ENGINE:
 * - Built-in analysis logic (doesn't use technicalAnalysisService)
 * - Simplified scoring system with direct indicator calculations
 * - Custom signal strength calculation using weighted indicators
 * - Faster processing but less sophisticated than AI-powered analysis
 * 
 * ⚡ PERFORMANCE OPTIMIZATIONS:
 * - Batch size: 10 stocks per bulk request
 * - Longer timeout: 45 seconds (vs standard 30s)
 * - Reduced API call count (theoretical improvement)
 * - Direct indicator processing without service layer
 * 
 * TRADE-OFFS:
 * ✅ PROS:
 * - Potentially faster scanning (fewer API calls)
 * - Direct control over bulk request structure
 * - Custom lightweight analysis engine
 * - Reduced dependency on service layer
 * 
 * ❌ CONS:
 * - Experimental/unstable (bulk API complexity)
 * - Less sophisticated analysis vs AI-powered approach
 * - Higher failure rate due to bulk request complexity
 * - Limited error handling for individual symbols
 * - No image generation or Firebase integration
 * 
 * WHEN TO USE:
 * - Experimental testing of bulk API approach
 * - Speed testing vs individual requests
 * - Research into TAAPI bulk endpoint capabilities
 * - Quick market overview without detailed analysis
 * 
 * RECOMMENDED ALTERNATIVE:
 * For production use, prefer scanBestStocks.js or scanBestStocksImproved.js
 * which offer more reliable results with better error handling.
 * 
 * TECHNICAL IMPLEMENTATION:
 * - StockBulkScanner class with custom analysis
 * - Direct TAAPI.io bulk API integration
 * - Simplified indicator scoring (RSI, MACD, EMA, BB, ADX)
 * - Hardcoded company names and stock list
 * - Basic signal strength calculation (1-5 scale)
 * 
 * DEPENDENCIES:
 * - TAAPI_API_KEY environment variable
 * - axios for HTTP requests
 * - No service layer dependencies
 */
require('dotenv').config();
const axios = require('axios');

// eToro + TAAPI supported US stocks (major ones with high trading volume)
const ETORO_TAAPI_STOCKS = [
  'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'TSLA', 'NVDA', 'AMD', 'INTC', 'IBM',
  'NFLX', 'JPM', 'BAC', 'WMT', 'DIS', 'V', 'MA', 'JNJ', 'PG', 'KO',
  'PEP', 'ADBE', 'CRM', 'ORCL', 'CSCO', 'HD', 'MCD', 'NKE', 'UNH', 'XOM'
];

// Timeframe mapping for TAAPI
const TIMEFRAME_MAP = {
  'short_term': '1h',
  'mid_term': '4h', 
  'long_term': '1d'
};

// Minimum signal strength to consider
const MIN_SIGNAL_STRENGTH = 1.5;

class StockBulkScanner {
  constructor() {
    this.apiKey = process.env.TAAPI_API_KEY;
    this.baseUrl = 'https://api.taapi.io';
  }

  async makeTrueBulkRequest(symbols, timeframe) {
    try {
      console.log(`🚀 Making TRUE bulk API request for ${symbols.length} stocks...`);
      
      // Create multiple bulk constructs for different symbols
      const constructs = symbols.map(symbol => ({
        exchange: 'stock',
        symbol: symbol,
        interval: TIMEFRAME_MAP[timeframe],
        type: 'stocks',
        indicators: [
          { indicator: 'rsi', period: 14 },
          { indicator: 'macd' },
          { indicator: 'bbands', period: 20, stddev: 2 },
          { indicator: 'ema', period: 50 },
          { indicator: 'ema', period: 200 },
          { indicator: 'adx', period: 14 },
          { indicator: 'atr', period: 14 }
        ]
      }));

      const response = await axios.post(`${this.baseUrl}/bulk`, {
        secret: this.apiKey,
        constructs: constructs // Note: plural for multiple symbols
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 45000 // Longer timeout for bulk requests
      });

      console.log(`   ✅ Received bulk data for ${symbols.length} stocks`);
      return response.data;

    } catch (error) {
      console.error(`   ❌ Bulk API Error: ${error.response?.data?.message || error.message}`);
      throw error;
    }
  }

  analyzeSymbolData(symbol, data) {
    try {
      const indicators = data;
      
      // Get current price from EMA50 (most reliable price source)
      const currentPrice = indicators.ema_50?.value || indicators.ema_200?.value || 100;
      
      // Calculate RSI score (0-100 scale, optimal around 30-70)
      const rsi = indicators.rsi?.value || 50;
      const rsiScore = rsi > 70 ? -1 : rsi < 30 ? 1 : 0; // Overbought/Oversold signals
      
      // Calculate MACD score
      const macd = indicators.macd?.valueMACDHist || 0;
      const macdScore = macd > 0 ? 1 : -1;
      
      // Calculate EMA trend score
      const ema50 = indicators.ema_50?.value || currentPrice;
      const ema200 = indicators.ema_200?.value || currentPrice;
      const trendScore = ema50 > ema200 ? 1 : -1;
      
      // Calculate Bollinger Bands position
      const bbUpper = indicators.bbands?.valueUpperBand || currentPrice * 1.02;
      const bbLower = indicators.bbands?.valueLowerBand || currentPrice * 0.98;
      const bbPosition = (currentPrice - bbLower) / (bbUpper - bbLower);
      const bbScore = bbPosition > 0.8 ? -1 : bbPosition < 0.2 ? 1 : 0;
      
      // Calculate ADX trend strength
      const adx = indicators.adx?.value || 20;
      const adxMultiplier = adx > 25 ? 1.5 : 1.0; // Strong trend multiplier
      
      // Calculate overall signal strength (1-5 scale)
      const rawScore = (rsiScore + macdScore + trendScore + bbScore) * adxMultiplier;
      const strength = Math.min(5, Math.max(-5, rawScore)); // Clamp to -5 to 5 range
      
      // Determine sentiment
      const sentiment = strength > 0 ? 'bullish' : strength < 0 ? 'bearish' : 'neutral';
      
      // Calculate confidence based on indicator agreement
      const agreementScore = Math.abs(rsiScore) + Math.abs(macdScore) + Math.abs(trendScore) + Math.abs(bbScore);
      const confidence = Math.min(95, (agreementScore / 4) * adxMultiplier * 25);
      
      // Calculate trading levels using ATR
      const atr = indicators.atr?.value || currentPrice * 0.02;
      const entryPrice = currentPrice;
      const stopLoss = sentiment === 'bullish' ? currentPrice - (atr * 2) : currentPrice + (atr * 2);
      const takeProfit = sentiment === 'bullish' ? currentPrice + (atr * 3) : currentPrice - (atr * 3);
      const riskReward = Math.abs(takeProfit - entryPrice) / Math.abs(entryPrice - stopLoss);
      
      // Generate reasoning
      const reasoning = [];
      if (Math.abs(rsiScore) > 0) reasoning.push(`RSI (${rsi.toFixed(1)}) suggests ${rsiScore > 0 ? 'oversold' : 'overbought'} conditions`);
      if (macdScore > 0) reasoning.push('MACD histogram shows bullish momentum');
      else reasoning.push('MACD histogram shows bearish momentum');
      if (trendScore > 0) reasoning.push('EMA50 above EMA200 indicates uptrend');
      else reasoning.push('EMA50 below EMA200 indicates downtrend');
      if (adx > 25) reasoning.push(`Strong trend strength (ADX: ${adx.toFixed(1)})`);
      
      return {
        symbol,
        company: this.getCompanyName(symbol),
        sentiment,
        strength: Math.abs(strength),
        confidence: confidence,
        entryPrice,
        stopLoss,
        takeProfit,
        riskReward,
        reasoning,
        indicators: {
          rsi: rsi,
          macd: macd,
          ema50: ema50,
          ema200: ema200,
          bbands: {
            upper: bbUpper,
            middle: indicators.bbands?.valueMiddleBand || currentPrice,
            lower: bbLower
          },
          adx: adx,
          atr: atr
        }
      };
    } catch (error) {
      console.error(`   ❌ Error analyzing ${symbol}: ${error.message}`);
      return null;
    }
  }

  getCompanyName(symbol) {
    const companies = {
      'AAPL': 'Apple Inc.', 'MSFT': 'Microsoft Corp.', 'GOOGL': 'Alphabet Inc.',
      'AMZN': 'Amazon.com Inc.', 'META': 'Meta Platforms', 'TSLA': 'Tesla Inc.',
      'NVDA': 'NVIDIA Corp.', 'AMD': 'Advanced Micro Devices', 'INTC': 'Intel Corp.',
      'IBM': 'IBM Corp.', 'NFLX': 'Netflix Inc.', 'JPM': 'JPMorgan Chase',
      'BAC': 'Bank of America', 'WMT': 'Walmart Inc.', 'DIS': 'Walt Disney Co.',
      'V': 'Visa Inc.', 'MA': 'Mastercard Inc.', 'JNJ': 'Johnson & Johnson',
      'PG': 'Procter & Gamble', 'KO': 'Coca-Cola Co.', 'PEP': 'PepsiCo Inc.',
      'ADBE': 'Adobe Inc.', 'CRM': 'Salesforce Inc.', 'ORCL': 'Oracle Corp.',
      'CSCO': 'Cisco Systems', 'HD': 'Home Depot Inc.', 'MCD': 'McDonald\'s Corp.',
      'NKE': 'Nike Inc.', 'UNH': 'UnitedHealth Group', 'XOM': 'Exxon Mobil'
    };
    return companies[symbol] || symbol;
  }

  async scanBestStocks(timeframe = 'mid_term') {
    console.log('🔍 ETORO STOCK SCANNER - TRUE BULK MODE');
    console.log('=======================================');
    console.log(`📊 Timeframe: ${timeframe} (${TIMEFRAME_MAP[timeframe]})`);
    console.log(`📈 Analyzing ${ETORO_TAAPI_STOCKS.length} stocks`);
    console.log(`⚡ Minimum signal strength: ${MIN_SIGNAL_STRENGTH}`);
    console.log(`🚀 Using TRUE TAAPI bulk requests`);
    console.log('=======================================\n');

    const results = [];
    const batchSize = 10; // Process 10 stocks per bulk request

    // Process in smaller batches to avoid API limits
    for (let i = 0; i < ETORO_TAAPI_STOCKS.length; i += batchSize) {
      const batch = ETORO_TAAPI_STOCKS.slice(i, i + batchSize);
      console.log(`📦 Batch ${Math.floor(i/batchSize) + 1}/${Math.ceil(ETORO_TAAPI_STOCKS.length/batchSize)}: ${batch.join(', ')}`);

      try {
        const bulkData = await this.makeTrueBulkRequest(batch, timeframe);
        
        // Process each symbol's data
        batch.forEach((symbol, index) => {
          const symbolData = bulkData.data?.[index] || bulkData[symbol] || bulkData[index];
          if (symbolData) {
            const analysis = this.analyzeSymbolData(symbol, symbolData);
            if (analysis && Math.abs(analysis.strength) >= MIN_SIGNAL_STRENGTH) {
              results.push({
                ...analysis,
                timeframe
              });
              console.log(`   ✅ ${symbol}: ${analysis.sentiment} (${analysis.strength.toFixed(2)})`);
            } else if (analysis) {
              console.log(`   ⚪ ${symbol}: weak signal (${analysis.strength.toFixed(2)})`);
            }
          } else {
            console.log(`   ❌ ${symbol}: No data received`);
          }
        });

        // Wait between batches
        if (i + batchSize < ETORO_TAAPI_STOCKS.length) {
          console.log(`   ⏳ Waiting 3 seconds before next batch...`);
          await new Promise(resolve => setTimeout(resolve, 3000));
        }

      } catch (error) {
        console.error(`   ❌ Batch failed: ${error.message}`);
        // Continue with next batch
      }
    }

    // Sort and display results
    results.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    const top5 = results.slice(0, 5);

    console.log('\n🏆 SCAN RESULTS');
    console.log('=======================================');
    console.log(`📊 Stocks processed: ${ETORO_TAAPI_STOCKS.length}`);
    console.log(`⚡ Strong signals: ${results.length}`);
    console.log(`🥇 Top 5: ${top5.length}`);
    console.log('=======================================\n');

    if (top5.length === 0) {
      console.log('😔 No strong signals found. Try different timeframe.');
      return;
    }

    // Display top 5
    console.log('🚀 TOP 5 ETORO STOCK SIGNALS');
    console.log('=======================================');

    top5.forEach((result, index) => {
      const emoji = ['🥇', '🥈', '🥉', '🏅', '⭐'][index];
      const sentimentEmoji = result.sentiment === 'bullish' ? '📈' : '📉';
      
      console.log(`\n${emoji} ${index + 1}. ${result.symbol} - ${result.company}`);
      console.log(`${sentimentEmoji} ${result.sentiment.toUpperCase()} (${result.strength.toFixed(2)}/5.0)`);
      console.log(`🎯 Confidence: ${result.confidence.toFixed(1)}%`);
      console.log(`💰 Entry: $${result.entryPrice.toFixed(2)} | Stop: $${result.stopLoss.toFixed(2)} | Target: $${result.takeProfit.toFixed(2)}`);
      console.log(`📊 Risk/Reward: 1:${result.riskReward.toFixed(2)}`);
      console.log(`🧠 ${result.reasoning.slice(0, 2).join(', ')}`);
      console.log('─'.repeat(40));
    });

    console.log('\n💡 BULK ANALYSIS COMPLETE!');
    console.log('• Used efficient TAAPI bulk requests');
    console.log('• Minimized API calls and rate limits');
    console.log('• Ready for eToro trading integration');
    
    return top5;
  }
}

// Command line execution
const timeframe = process.argv[2] || 'mid_term';

if (!TIMEFRAME_MAP[timeframe]) {
  console.log('❌ Invalid timeframe. Use: short_term, mid_term, or long_term');
  process.exit(1);
}

const scanner = new StockBulkScanner();
scanner.scanBestStocks(timeframe).catch(console.error); 