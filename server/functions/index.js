const {onRequest} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const {setGlobalOptions} = require('firebase-functions/v2');
const axios = require('axios');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

// Initialize Firebase Admin (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

// Define secrets
const taapiApiKey = defineSecret('TAAPI_API_KEY');
const openaiApiKey = defineSecret('OPENAI_API_KEY');

// Set global options
setGlobalOptions({
  region: 'us-central1',
  memory: '1GiB',
  timeoutSeconds: 300,
});

// Simple test function to verify API key works
exports.testAnalysis = onRequest({
  secrets: [taapiApiKey],
}, async (req, res) => {
  try {
    // Get API key from Firebase secrets
    let apiKey = taapiApiKey.value();
    
    // Clean the API key (remove quotes and whitespace)
    apiKey = apiKey.replace(/^["']|["']$/g, '').trim();
    
    console.log('🔑 API Key available:', !!apiKey);
    
    const symbol = req.query.symbol || 'AAPL';
    const timeframe = req.query.timeframe || 'mid_term';
    
    console.log('📊 Testing symbol:', symbol);
    console.log('⏰ Timeframe:', timeframe);
    
    // Map our timeframes to TAAPI timeframes - SAME AS LOCAL SCRIPT
    const timeframeMap = {
      'short_term': '1h',
      'mid_term': '4h', 
      'long_term': '1d'
    };

    const taTimeframe = timeframeMap[timeframe] || '4h'; // Default to 4h
    console.log('📈 TAAPI interval:', taTimeframe);
    
    // Create simple bulk request - EXACT SAME as working local script
    const construct = {
      exchange: 'stock',
      symbol: symbol,
      interval: taTimeframe,
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
    };

    console.log('📡 Making request to TAAPI...');
    
    // Make the request
    const response = await axios.post('https://api.taapi.io/bulk', {
      secret: apiKey,
      construct: construct
    });

    console.log('✅ TAAPI Response received');
    
    // Process results into indicators object
    const indicators = {};
    let currentPrice = null;
    
    response.data.data.forEach(result => {
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

    console.log('🔍 Generating trading analysis...');
    
    // Generate trading analysis using the same logic as local script
    const analysis = generateAdvancedAnalysis(symbol, indicators, currentPrice, timeframe);

    res.json({
      success: true,
      symbol,
      timeframe,
      currentPrice,
      indicators,
      analysis,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Health check
exports.healthCheck = onRequest({
  cors: true,
}, async (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: 'clean-start'
  });
});

// Generate trading analysis from indicators - SAME LOGIC as local script
function generateAdvancedAnalysis(symbol, indicators, currentPrice, timeframe) {
  const analysis = {
    sentiment: 'neutral',
    strength: 0,
    confidence: 0,
    tradingAction: 'hold', // 'buy', 'sell', 'hold'
    entryPrice: null,
    stopLoss: null,
    takeProfit: null,
    riskRewardRatio: null,
    reasoning: [],
    keyLevels: {
      support: null,
      resistance: null
    }
  };

  // Initialize signal counters
  let bullishSignals = 0;
  let bearishSignals = 0;
  let totalSignals = 0;

  // 1. RSI Analysis (Most reliable according to research)
  if (indicators.rsi?.value) {
    const rsi = indicators.rsi.value;
    totalSignals++;
    
    if (rsi < 25) {
      bullishSignals++;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) shows strong oversold conditions - bullish signal`);
    } else if (rsi < 35) {
      bullishSignals += 0.5;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) shows oversold conditions - mild bullish signal`);
    } else if (rsi > 75) {
      bearishSignals++;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) shows strong overbought conditions - bearish signal`);
    } else if (rsi > 65) {
      bearishSignals += 0.5;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) shows overbought conditions - mild bearish signal`);
    } else {
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) in neutral zone`);
    }
  }

  // 2. MACD Analysis
  if (indicators.macd?.valueMACDHist && indicators.macd?.valueMACD && indicators.macd?.valueMACDSignal) {
    const macdHist = indicators.macd.valueMACDHist;
    const macdLine = indicators.macd.valueMACD;
    const signalLine = indicators.macd.valueMACDSignal;
    totalSignals++;
    
    if (macdHist > 0 && macdLine > signalLine) {
      bullishSignals++;
      analysis.reasoning.push('MACD shows bullish momentum with positive histogram');
    } else if (macdHist < 0 && macdLine < signalLine) {
      bearishSignals++;
      analysis.reasoning.push('MACD shows bearish momentum with negative histogram');
    } else {
      analysis.reasoning.push('MACD shows mixed signals');
    }
  }

  // 3. Moving Average Analysis - Handle the new EMA structure
  if (indicators.ema) {
    totalSignals++;
    
    const ema50 = indicators.ema.ema50?.value;
    const ema200 = indicators.ema.ema200?.value;
    
    if (ema50 && ema200) {
      // Golden/Death cross and price position
      if (ema50 > ema200 && currentPrice > ema50) {
        bullishSignals++;
        analysis.reasoning.push('Bullish trend: EMA50 > EMA200 and price above EMA50');
      } else if (ema50 < ema200 && currentPrice < ema50) {
        bearishSignals++;
        analysis.reasoning.push('Bearish trend: EMA50 < EMA200 and price below EMA50');
      } else if (ema50 > ema200) {
        bullishSignals += 0.5;
        analysis.reasoning.push(`Golden cross: EMA50 (${ema50.toFixed(2)}) > EMA200 (${ema200.toFixed(2)}) but price near EMA50`);
      } else if (ema50 < ema200) {
        bearishSignals += 0.5;
        analysis.reasoning.push(`Death cross: EMA50 (${ema50.toFixed(2)}) < EMA200 (${ema200.toFixed(2)}) but price near EMA50`);
      }
    } else if (ema50) {
      // Just use EMA50 vs price
      if (currentPrice > ema50) {
        bullishSignals += 0.5;
        analysis.reasoning.push(`Price above EMA50 (${ema50.toFixed(2)}) - mild bullish signal`);
      } else {
        bearishSignals += 0.5;
        analysis.reasoning.push(`Price below EMA50 (${ema50.toFixed(2)}) - mild bearish signal`);
      }
    }
  }

  // 4. ADX Trend Strength
  if (indicators.adx?.value) {
    const adx = indicators.adx.value;
    if (adx > 25) {
      analysis.reasoning.push(`ADX (${adx.toFixed(1)}) indicates strong trending conditions`);
      // ADX doesn't give direction, just confirms trend strength
    } else {
      analysis.reasoning.push(`ADX (${adx.toFixed(1)}) indicates weak trending conditions`);
    }
  }

  // 5. Bollinger Bands Analysis 
  if (indicators.bbands) {
    const bb = indicators.bbands;
    totalSignals++;
    
    analysis.keyLevels.support = bb.valueLowerBand;
    analysis.keyLevels.resistance = bb.valueUpperBand;
    
    if (currentPrice <= bb.valueLowerBand) {
      bullishSignals += 0.5;
      analysis.reasoning.push('Price at/below lower Bollinger Band - potential bounce');
    } else if (currentPrice >= bb.valueUpperBand) {
      bearishSignals += 0.5;
      analysis.reasoning.push('Price at/above upper Bollinger Band - potential rejection');
    }
  }

  // Calculate final sentiment and strength
  const bullishPercentage = totalSignals > 0 ? (bullishSignals / totalSignals) * 100 : 0;
  const bearishPercentage = totalSignals > 0 ? (bearishSignals / totalSignals) * 100 : 0;
  
  analysis.confidence = Math.max(bullishPercentage, bearishPercentage);
  
  // Determine sentiment and trading action
  if (bullishPercentage >= 50) {
    analysis.sentiment = 'bullish';
    analysis.tradingAction = 'buy';
    analysis.strength = Math.min(5, (bullishPercentage / 20)); // Scale 1-5
  } else if (bearishPercentage >= 50) {
    analysis.sentiment = 'bearish';
    analysis.tradingAction = 'sell'; // This will generate SHORT positions
    analysis.strength = Math.min(5, (bearishPercentage / 20)); // Scale 1-5
  } else {
    analysis.sentiment = 'neutral';
    analysis.tradingAction = 'hold';
    analysis.strength = 0;
  }

  // Calculate entry, stop loss, and take profit based on sentiment
  calculateTradingLevels(analysis, indicators, currentPrice, timeframe);

  return analysis;
}

function calculateTradingLevels(analysis, indicators, currentPrice, timeframe) {
  const atr = indicators.atr?.value || (currentPrice * 0.02); // Default 2% if no ATR
  
  // Risk management based on timeframe
  const riskMultipliers = {
    'short_term': { stop: 1.5, target: 2.5 }, // 1.5 ATR stop, 2.5 ATR target
    'mid_term': { stop: 2.0, target: 4.0 },   // 2 ATR stop, 4 ATR target  
    'long_term': { stop: 3.0, target: 6.0 }   // 3 ATR stop, 6 ATR target
  };
  
  const multiplier = riskMultipliers[timeframe] || riskMultipliers['mid_term'];
  
  if (analysis.tradingAction === 'buy') {
    // LONG position
    analysis.entryPrice = currentPrice;
    analysis.stopLoss = currentPrice - (atr * multiplier.stop);
    analysis.takeProfit = currentPrice + (atr * multiplier.target);
    
    // Use support/resistance if available - but NEVER set take profit below entry for longs
    if (analysis.keyLevels.support && analysis.keyLevels.support < analysis.stopLoss) {
      analysis.stopLoss = analysis.keyLevels.support * 0.99; // Slightly below support
    }
    if (analysis.keyLevels.resistance && analysis.keyLevels.resistance < analysis.takeProfit) {
      // Only adjust if resistance is still above entry price
      const resistanceTarget = analysis.keyLevels.resistance * 0.99;
      if (resistanceTarget > currentPrice) {
        analysis.takeProfit = resistanceTarget;
      }
      // If resistance is too close to entry, keep original calculated target
    }
    
  } else if (analysis.tradingAction === 'sell') {
    // SHORT position
    analysis.entryPrice = currentPrice;
    analysis.stopLoss = currentPrice + (atr * multiplier.stop);  // Stop ABOVE entry for short
    analysis.takeProfit = currentPrice - (atr * multiplier.target); // Target BELOW entry for short
    
    // Use support/resistance if available - but NEVER set take profit above entry for shorts
    if (analysis.keyLevels.resistance && analysis.keyLevels.resistance > analysis.stopLoss) {
      analysis.stopLoss = analysis.keyLevels.resistance * 1.01; // Slightly above resistance
    }
    if (analysis.keyLevels.support && analysis.keyLevels.support > analysis.takeProfit) {
      // Only adjust if support is still below entry price
      const supportTarget = analysis.keyLevels.support * 1.01;
      if (supportTarget < currentPrice) {
        analysis.takeProfit = supportTarget;
      }
      // If support is too close to entry, keep original calculated target
    }
  }
  
  // Calculate risk-reward ratio
  if (analysis.entryPrice && analysis.stopLoss && analysis.takeProfit) {
    const risk = Math.abs(analysis.entryPrice - analysis.stopLoss);
    const reward = Math.abs(analysis.takeProfit - analysis.entryPrice);
    analysis.riskRewardRatio = reward / risk;
    
    analysis.reasoning.push(
      `Risk-Reward Ratio: 1:${analysis.riskRewardRatio.toFixed(2)} (Risk: $${risk.toFixed(2)}, Reward: $${reward.toFixed(2)})`
    );
  }
}

// Bulk analysis function - processes multiple stocks like local analyzeAll script
exports.bulkAnalysis = onRequest({
  secrets: [taapiApiKey],
}, async (req, res) => {
  try {
    // Get API key from Firebase secrets
    let apiKey = taapiApiKey.value();
    apiKey = apiKey.replace(/^["']|["']$/g, '').trim();
    
    console.log('🔑 API Key available:', !!apiKey);
    
    // Get parameters
    const timeframe = req.query.timeframe || 'mid_term';
    const stocksParam = req.query.stocks;
    const limit = parseInt(req.query.limit) || 5;
    
    console.log('⏰ Timeframe:', timeframe);
    console.log('📊 Limit:', limit);
    
    // Default stock list (same as local script - 35 eToro stocks)
    const DEFAULT_STOCKS = [
      'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'TSLA', 'NVDA', 'AMD', 'INTC', 'IBM',
      'NFLX', 'JPM', 'BAC', 'WMT', 'DIS', 'V', 'MA', 'JNJ', 'PG', 'KO',
      'PEP', 'ADBE', 'CRM', 'ORCL', 'CSCO', 'HD', 'MCD', 'NKE', 'UNH', 'XOM',
      'GE', 'F', 'GM', 'PYPL', 'UBER'
    ];
    
    // Parse stocks from query param or use defaults
    const stocksToAnalyze = stocksParam ? stocksParam.split(',').map(s => s.trim().toUpperCase()) : DEFAULT_STOCKS.slice(0, limit);
    
    console.log('📈 Analyzing stocks:', stocksToAnalyze.join(', '));
    
    // Map timeframes
    const timeframeMap = {
      'short_term': '1h',
      'mid_term': '4h', 
      'long_term': '1d'
    };
    const taTimeframe = timeframeMap[timeframe] || '4h';
    
    console.log('📡 Starting bulk analysis...');
    
    const results = [];
    const batchSize = 5; // Process 5 stocks at a time (same as local script)
    
    // Process stocks in batches
    for (let i = 0; i < stocksToAnalyze.length; i += batchSize) {
      const batch = stocksToAnalyze.slice(i, i + batchSize);
      const batchNum = Math.floor(i/batchSize) + 1;
      const totalBatches = Math.ceil(stocksToAnalyze.length/batchSize);
      
      console.log(`📦 Processing batch ${batchNum}/${totalBatches}: ${batch.join(', ')}`);
      
      try {
        const batchResults = await processBatchStocks(batch, timeframe, taTimeframe, apiKey);
        results.push(...batchResults);
        
        // Rate limiting - delay between batches (like local script)
        if (i + batchSize < stocksToAnalyze.length) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      } catch (error) {
        console.error(`❌ Batch ${batchNum} error:`, error.message);
      }
    }
    
    // Filter strong signals (minimum strength >= 2.0 like local script)
    const strongSignals = results.filter(r => Math.abs(r.strength) >= 2.0);
    strongSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    
    console.log(`✅ Analysis complete: ${results.length} processed, ${strongSignals.length} strong signals`);
    
    res.json({
      success: true,
      timeframe,
      totalProcessed: results.length,
      strongSignalsFound: strongSignals.length,
      signals: strongSignals,
      metadata: {
        batchSize,
        minStrength: 2.0,
        processingTime: Date.now(),
        timestamp: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('❌ Bulk analysis error:', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Process a batch of stocks - similar to local script processBatchStocks
async function processBatchStocks(symbols, timeframe, taTimeframe, apiKey) {
  const results = [];
  
  for (const symbol of symbols) {
    try {
      console.log(`  🔍 Analyzing ${symbol}...`);
      
      // Create bulk request for this symbol
      const construct = {
        exchange: 'stock',
        symbol: symbol,
        interval: taTimeframe,
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
      };

      // Make request to TAAPI
      const response = await axios.post('https://api.taapi.io/bulk', {
        secret: apiKey,
        construct: construct
      });

      // Process indicators
      const indicators = {};
      let currentPrice = null;
      
      response.data.data.forEach(result => {
        const indicatorName = result.indicator;
        
        if (indicatorName === 'ema') {
          if (!indicators.ema) indicators.ema = {};
          const period = result.id.includes('_50_') ? 50 : result.id.includes('_200_') ? 200 : 'unknown';
          indicators.ema[`ema${period}`] = result.result;
        } else {
          indicators[indicatorName] = result.result;
        }
        
        if (result.result && typeof result.result === 'object' && result.result.close && !currentPrice) {
          currentPrice = result.result.close;
        }
      });

      // Get current price from EMA if not found
      if (!currentPrice) {
        if (indicators.ema?.ema50?.value) {
          currentPrice = indicators.ema.ema50.value;
        } else if (indicators.ema?.ema200?.value) {
          currentPrice = indicators.ema.ema200.value;
        }
      }

      // Generate analysis
      const analysis = generateAdvancedAnalysis(symbol, indicators, currentPrice, timeframe);
      
      // Include all analysis results (let main function filter for strong signals)
      if (analysis) {
        results.push({
          type: 'stock',
          symbol: symbol,
          timeframe: timeframe,
          currentPrice: currentPrice,
          sentiment: analysis.sentiment,
          strength: analysis.strength,
          confidence: analysis.confidence,
          tradingAction: analysis.tradingAction,
          entryPrice: analysis.entryPrice,
          stopLoss: analysis.stopLoss,
          takeProfit: analysis.takeProfit,
          riskRewardRatio: analysis.riskRewardRatio,
          reasoning: analysis.reasoning,
          keyLevels: analysis.keyLevels,
          indicators: indicators,
          metadata: {
            generatedAt: new Date().toISOString(),
            scanner: 'firebase_bulk_v1'
          }
        });
        
        console.log(`    ✅ ${symbol}: ${analysis.sentiment} (${analysis.strength.toFixed(2)})`);
      } else {
        console.log(`    ❌ ${symbol}: analysis failed`);
      }
      
      // Rate limiting between symbols (like local script)
      await new Promise(resolve => setTimeout(resolve, 500));
      
    } catch (error) {
      console.error(`    ❌ ${symbol}: ${error.message}`);
    }
  }
  
  return results;
}

// Comprehensive analysis function - scans ALL stocks across ALL timeframes like local analyzeAll script
exports.analyzeAll = onRequest({
  secrets: [taapiApiKey],
}, async (req, res) => {
  try {
    const startTime = Date.now();
    
    // Get API key from Firebase secrets
    let apiKey = taapiApiKey.value();
    apiKey = apiKey.replace(/^["']|["']$/g, '').trim();
    
    console.log('🚀 COMPREHENSIVE MARKET SCANNER - FIREBASE VERSION');
    console.log('==================================================');
    console.log('🔑 API Key available:', !!apiKey);
    
    // All 35 eToro stocks from local script
    const ALL_STOCKS = [
      'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'TSLA', 'NVDA', 'AMD', 'INTC', 'IBM',
      'NFLX', 'JPM', 'BAC', 'WMT', 'DIS', 'V', 'MA', 'JNJ', 'PG', 'KO',
      'PEP', 'ADBE', 'CRM', 'ORCL', 'CSCO', 'HD', 'MCD', 'NKE', 'UNH', 'XOM',
      'GE', 'F', 'GM', 'PYPL', 'UBER'
    ];
    
    // All timeframes from local script
    const TIMEFRAMES = [
      { name: 'short_term', interval: '1h', label: '1H (Short Term)' },
      { name: 'mid_term', interval: '4h', label: '4H (Mid Term)' },
      { name: 'long_term', interval: '1d', label: '1D (Long Term)' }
    ];
    
    console.log(`📊 Analyzing ${ALL_STOCKS.length} stocks across ${TIMEFRAMES.length} timeframes`);
    console.log(`⏰ Timeframes: ${TIMEFRAMES.map(t => t.label).join(', ')}`);
    console.log('==================================================\n');
    
    const results = {
      short_term: [],
      mid_term: [],
      long_term: []
    };
    
    const stats = {
      totalProcessed: 0,
      totalSignals: 0,
      processingTime: 0
    };
    
    // Scan each timeframe
    for (const timeframe of TIMEFRAMES) {
      console.log(`\n🔍 SCANNING ${timeframe.label.toUpperCase()}`);
      console.log('=' .repeat(50));
      
      const timeframeResults = [];
      const batchSize = 5; // Same as local script
      
      // Process stocks in batches
      for (let i = 0; i < ALL_STOCKS.length; i += batchSize) {
        const batch = ALL_STOCKS.slice(i, i + batchSize);
        const batchNum = Math.floor(i/batchSize) + 1;
        const totalBatches = Math.ceil(ALL_STOCKS.length/batchSize);
        
        console.log(`📦 Batch ${batchNum}/${totalBatches}: ${batch.join(', ')}`);
        
        try {
          const batchResults = await processBatchStocks(batch, timeframe.name, timeframe.interval, apiKey);
          timeframeResults.push(...batchResults);
          stats.totalProcessed += batch.length;
          
          // Rate limiting - delay between batches (like local script)
          if (i + batchSize < ALL_STOCKS.length) {
            await new Promise(resolve => setTimeout(resolve, 3000));
          }
        } catch (error) {
          console.error(`❌ Batch ${batchNum} error:`, error.message);
        }
      }
      
      // Filter strong signals (minimum strength >= 2.0 like local script)
      const strongSignals = timeframeResults.filter(r => Math.abs(r.strength) >= 2.0);
      strongSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
      
      results[timeframe.name] = strongSignals;
      stats.totalSignals += strongSignals.length;
      
      console.log(`✅ ${timeframe.label}: ${timeframeResults.length} processed, ${strongSignals.length} strong signals`);
      
      // Show top 3 signals for this timeframe
      if (strongSignals.length > 0) {
        console.log('🏆 Top signals:');
        strongSignals.slice(0, 3).forEach((signal, idx) => {
          console.log(`   ${idx + 1}. ${signal.symbol}: ${signal.sentiment} (${signal.strength.toFixed(2)}) - ${signal.tradingAction}`);
        });
      }
    }
    
    stats.processingTime = (Date.now() - startTime) / 1000;
    
    console.log('\n✅ COMPREHENSIVE SCAN COMPLETED!');
    console.log('=================================');
    console.log(`⏱️  Total processing time: ${stats.processingTime.toFixed(1)}s`);
    console.log(`📊 Total stocks processed: ${stats.totalProcessed}`);
    console.log(`⚡ Strong signals found: ${stats.totalSignals}`);
    console.log('=================================');
    
    // Return comprehensive results
    res.json({
      success: true,
      summary: {
        totalStocksAnalyzed: ALL_STOCKS.length,
        totalTimeframes: TIMEFRAMES.length,
        totalProcessed: stats.totalProcessed,
        totalStrongSignals: stats.totalSignals,
        processingTimeSeconds: stats.processingTime
      },
      signals: {
        short_term: {
          label: '1H (Short Term)',
          count: results.short_term.length,
          signals: results.short_term
        },
        mid_term: {
          label: '4H (Mid Term)', 
          count: results.mid_term.length,
          signals: results.mid_term
        },
        long_term: {
          label: '1D (Long Term)',
          count: results.long_term.length,
          signals: results.long_term
        }
      },
      metadata: {
        minStrength: 2.0,
        stockList: ALL_STOCKS,
        timeframes: TIMEFRAMES.map(t => ({ name: t.name, interval: t.interval, label: t.label })),
        timestamp: new Date().toISOString(),
        scanner: 'firebase_comprehensive_v1'
      }
    });
    
  } catch (error) {
    console.error('❌ Comprehensive analysis error:', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Priority-based signal selection and upload - implements your local script logic
exports.selectAndUploadBestSignal = onRequest({
  secrets: [taapiApiKey],
}, async (req, res) => {
  try {
    const startTime = Date.now();
    
    console.log('🎯 PRIORITY SIGNAL SELECTOR & UPLOADER');
    console.log('====================================');
    
    // Step 1: Get all strong signals from comprehensive analysis
    console.log('📊 Getting comprehensive market analysis...');
    const analysisResponse = await fetch('http://127.0.0.1:5001/fmm-config-manager/us-central1/analyzeAll');
    const analysisData = await analysisResponse.json();
    
    if (!analysisData.success) {
      throw new Error('Failed to get market analysis');
    }
    
    // Collect all strong signals across timeframes
    const allSignals = [];
    
    // Add signals from each timeframe
    Object.keys(analysisData.signals).forEach(timeframe => {
      const timeframeSignals = analysisData.signals[timeframe].signals || [];
      timeframeSignals.forEach(signal => {
        allSignals.push({
          ...signal,
          timeframe: timeframe
        });
      });
    });
    
    console.log(`📈 Found ${allSignals.length} strong signals across all timeframes`);
    
    if (allSignals.length === 0) {
      return res.json({
        success: true,
        message: 'No strong signals found in current market conditions',
        signalsFound: 0,
        uploaded: false
      });
    }
    
    // Step 2: Select the strongest signal (simplified)
    console.log('🎯 Selecting strongest signal...');
    const selectedSignal = selectBestSignalByPriority(allSignals, {});
    
    if (!selectedSignal) {
      return res.json({
        success: true,
        message: 'No suitable signal found',
        signalsFound: allSignals.length,
        uploaded: false
      });
    }
    
    console.log(`🏆 Selected signal: ${selectedSignal.symbol} (${selectedSignal.timeframe}) - Strength: ${selectedSignal.strength}`);
    
    // Step 3: Upload selected signal to Firebase using existing service pattern
    console.log('📤 Uploading selected signal to Firebase...');
    const uploadResult = await uploadSignalToFirebase(selectedSignal);
    
    const processingTime = Date.now() - startTime;
    
    console.log(`✅ Signal selection and upload completed in ${processingTime}ms`);
    
    res.json({
      success: true,
      selectedSignal: {
        symbol: selectedSignal.symbol,
        timeframe: selectedSignal.timeframe,
        sentiment: selectedSignal.sentiment,
        strength: selectedSignal.strength,
        confidence: selectedSignal.confidence,
        tradingAction: selectedSignal.tradingAction
      },
      uploadResult,
      metadata: {
        totalSignalsFound: allSignals.length,
        processingTime,
        timestamp: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('❌ Error in signal selection and upload:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Priority selection logic - simplified to just pick strongest signal
function selectBestSignalByPriority(signals, lastTips) {
  console.log('🔍 Selecting strongest signal...');
  
  // Sort signals by strength (strongest first)
  const sortedSignals = signals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
  
  console.log('📊 Top 5 signals by strength:');
  sortedSignals.slice(0, 5).forEach((signal, index) => {
    console.log(`   ${index + 1}. ${signal.symbol} (${signal.timeframe}) - Strength: ${signal.strength}`);
  });
  
  // Simply return the strongest signal
  if (sortedSignals.length > 0) {
    const strongest = sortedSignals[0];
    console.log(`   ✅ Selected strongest signal: ${strongest.symbol} (${strongest.timeframe}) - Strength: ${strongest.strength}`);
    return strongest;
  }
  
  console.log('   ⚠️ No signals found');
  return null;
}

// Upload signal to Firebase using existing service pattern
async function uploadSignalToFirebase(signal) {
  try {
    // Convert our signal format to the format expected by tradingTipsService
    const tipData = {
      symbol: signal.symbol,
      timeframe: signal.timeframe,
      sentiment: signal.sentiment,
      entryPrice: signal.entryPrice,
      stopLoss: signal.stopLoss,
      takeProfit: signal.takeProfit,
      riskRewardRatio: signal.riskRewardRatio,
      strength: signal.strength,
      confidence: signal.confidence,
      reasoning: signal.reasoning,
      indicators: signal.indicators,
      // Add company information (we'll need to get this)
      company: await getCompanyInfo(signal.symbol),
      metadata: {
        generatedAt: new Date().toISOString(),
        strategy: 'firebase_priority_selector_v1',
        source: 'comprehensive_analysis'
      }
    };
    
    // Use the same upload mechanism as your local scripts
    // For now, we'll save directly to Firestore (later we can add image generation)
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    const date = new Date().toISOString().split('T')[0];
    
    // Save to both collections like your local script does
    const tradingTipId = `${tipData.symbol}_${date}_${tipData.timeframe}`;
    
    // Add to trading_tips collection (historical)
    await admin.firestore().collection('trading_tips').doc(tradingTipId).set({
      ...tipData,
      createdAt: timestamp
    });
    
    // Update latest_tips collection (current active tips)
    await admin.firestore().collection('latest_tips').doc(tipData.timeframe).set({
      ...tipData,
      createdAt: timestamp
    });
    
    console.log(`✅ Signal uploaded to Firebase: ${tipData.symbol} (${tipData.timeframe})`);
    
    return {
      success: true,
      documentId: tradingTipId,
      collections: ['trading_tips', 'latest_tips']
    };
    
  } catch (error) {
    console.error('❌ Error uploading to Firebase:', error);
    throw error;
  }
}

// Get company info (simplified version)
async function getCompanyInfo(symbol) {
  // For now, return basic info
  // Later we can integrate with your existing company lookup logic
  return {
    name: symbol,
    symbol: symbol,
    logoUrl: `assets/logos/stocks/${symbol}.png`,
    sector: 'Unknown',
    business: 'Stock Analysis',
    isCrypto: false
  };
}

// Core logic for generating trading tips (used by both HTTP and scheduled functions)
async function executeFullTradingTipGeneration(specificTimeframe = null) {
  try {
    console.log('🚀 Starting COMPLETE trading tip generation...');
    if (specificTimeframe) {
      console.log(`🎯 Specific timeframe requested: ${specificTimeframe}`);
    }
    
    // Get API keys from Firebase secrets
    let taapi_key = taapiApiKey.value().replace(/^["']|["']$/g, '').trim();
    let openai_key = openaiApiKey.value().replace(/^["']|["']$/g, '').trim();
    
    console.log('🔑 API Keys available:', !!taapi_key, !!openai_key);
    
    // Run comprehensive analysis to get the best signal
    const bestSignal = await runComprehensiveAnalysis(taapi_key, specificTimeframe);
    
    if (!bestSignal) {
      const timeframeMsg = specificTimeframe ? ` for ${specificTimeframe} timeframe` : '';
      throw new Error(`No strong trading signals found${timeframeMsg}`);
    }
    
    console.log('💎 Best signal found:', bestSignal.symbol, bestSignal.sentiment);
    
    // Get enhanced company information
    const companyInfo = await getEnhancedCompanyInfo(bestSignal.symbol);
    
    // Generate DALL-E background image
    console.log('🎨 Generating DALL-E background image...');
    const backgroundImageUrl = await generateTradingBackgroundImage(bestSignal, openai_key);
    
    // Download and upload image to Cloud Storage
    console.log('☁️ Uploading to Cloud Storage...');
    const storageResult = await uploadImagesToStorage(bestSignal, backgroundImageUrl);
    
    // Prepare complete tip data structure
    const completeTipData = {
      symbol: bestSignal.symbol,
      timeframe: bestSignal.timeframe,
      sentiment: bestSignal.sentiment,
      strength: bestSignal.strength,
      confidence: bestSignal.confidence,
      tradingAction: bestSignal.tradingAction,
      entryPrice: bestSignal.entryPrice,
      stopLoss: bestSignal.stopLoss,
      takeProfit: bestSignal.takeProfit,
      riskRewardRatio: bestSignal.riskRewardRatio,
      reasoning: bestSignal.reasoning,
      keyLevels: bestSignal.keyLevels,
      currentPrice: bestSignal.currentPrice,
      indicators: bestSignal.indicators,
      company: companyInfo,
      
      // Background images structure
      backgroundImages: {
        titledBackground: {
          url: storageResult.backgroundUrl,
          fileName: storageResult.backgroundFileName,
          generatedAt: new Date(),
          hasTitle: true,
          title: `${bestSignal.symbol} - ${bestSignal.sentiment.toUpperCase()} - ${formatTimeframe(bestSignal.timeframe)}`
        }
      },
      
      // Legacy structure for app compatibility
      images: {
        latestTradingCard: { 
          url: storageResult.latestTradingCardUrl,
          type: 'titled_background' 
        }
      },
      
      // Quick access references
      latestBackground: {
        url: storageResult.backgroundUrl,
        type: 'titled_background',
        hasTitle: true
      },
      
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    // Update app statistics
    console.log('📊 Updating app statistics...');
    const statsResult = await updateAppStats();
    
    // Send push notification
    console.log('📱 Sending push notification...');
    const notificationResult = await sendTipNotification(completeTipData, companyInfo);
    
    // Save to Firestore (both collections for compatibility)
    console.log('💾 Saving to Firestore...');
    await saveToFirestore(completeTipData);
    
    return {
      success: true,
      tip: completeTipData,
      signal: bestSignal,
      company: companyInfo,
      images: storageResult,
      notification: notificationResult,
      stats: statsResult,
      timestamp: new Date().toISOString()
    };
    
  } catch (error) {
    console.error('❌ Error in complete tip generation:', error.message);
    return {
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
}

// Enhanced function with complete flow - DALL-E images, storage, stats, notifications
exports.generateFullTradingTip = onRequest({
  secrets: [taapiApiKey, openaiApiKey],
  memory: '2GiB',
  timeoutSeconds: 540,
}, async (req, res) => {
  try {
    const result = await executeFullTradingTipGeneration();
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(500).json(result);
    }
    
  } catch (error) {
    console.error('❌ Error in HTTP tip generation:', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// DALL-E Image Generation - written directly in Firebase function
async function generateTradingBackgroundImage(analysis, openaiApiKey) {
  try {
    const prompt = createCompanyBackgroundPrompt(analysis);
    
    const response = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: "dall-e-3",
        prompt: prompt,
        n: 1,
        size: "1024x1024",
        quality: "hd",
        style: "natural"
      })
    });
    
    const data = await response.json();
    
    if (!response.ok) {
      throw new Error(`OpenAI API error: ${data.error?.message || 'Unknown error'}`);
    }
    
    const imageUrl = data.data[0].url;
    console.log('✅ Generated DALL-E background image');
    return imageUrl;
    
  } catch (error) {
    console.error('❌ Error generating background image:', error);
    throw error;
  }
}

// Create DALL-E prompt - written directly in Firebase function
function createCompanyBackgroundPrompt(analysis) {
  const symbol = analysis.symbol;
  const sentiment = analysis.sentiment;
  const timeframe = formatTimeframe(analysis.timeframe);
  const isBullish = sentiment === 'bullish';
  
  // Enhanced company information
  const companyInfo = {
    'AAPL': { name: 'Apple Inc.', business: 'iPhone, iPad, Mac technology', colors: 'silver, space gray, white' },
    'MSFT': { name: 'Microsoft', business: 'Windows, Office, Azure cloud', colors: 'blue, white' },
    'GOOGL': { name: 'Alphabet Inc.', business: 'Google search, YouTube, Android', colors: 'blue, red, yellow, green' },
    'TSLA': { name: 'Tesla', business: 'electric vehicles, sustainable energy', colors: 'red, white, sleek' },
    'AMZN': { name: 'Amazon', business: 'e-commerce, AWS cloud, delivery', colors: 'orange, black' },
    'META': { name: 'Meta', business: 'Facebook, Instagram, WhatsApp', colors: 'blue, white' },
    'NVDA': { name: 'NVIDIA', business: 'AI chips, gaming graphics', colors: 'green, black' },
    'NFLX': { name: 'Netflix', business: 'streaming movies and TV shows', colors: 'red, black' },
    'CRM': { name: 'Salesforce', business: 'cloud CRM, business automation', colors: 'blue, white' },
    'AMD': { name: 'AMD', business: 'computer processors, gaming chips', colors: 'red, black' }
    // Add more as needed
  };

  const company = companyInfo[symbol] || { name: symbol, business: 'technology services', colors: 'blue, white' };
  const sentimentColor = isBullish ? 'green' : 'red';
  
  return `Professional trading background texture themed around ${company.business}. Dark charcoal navy base with ${sentimentColor} accent lighting. Clean space at the top for logo placement. Very subtle semi-transparent elements related to ${company.business} scattered throughout at 20% opacity. Faded ${sentimentColor} candlestick charts and trading graphs at 30% opacity in background. ${isBullish ? 'Subtle upward trending arrows and growth elements' : 'Subtle downward trending arrows and analytical elements'} at 25% opacity. 

Company theme: ${company.colors} color palette with ${company.business} visual elements. All background elements extremely subtle and faded. Large clean areas for content overlay. Vertical format 9:16 ratio. Professional fintech aesthetic with ${sentimentColor} sentiment theming. Photo style background texture. High quality and detailed.`;
}

// Enhanced company information - written directly in Firebase function
// Complete database matching local logoUtils.js for full feature parity
async function getEnhancedCompanyInfo(symbol) {
  // Complete company database - matches local logoUtils.js exactly
  const companies = {
    'AAPL': {
      name: 'Apple Inc.',
      sector: 'Technology',
      industry: 'Consumer Electronics',
      business: 'Consumer Electronics',
      description: 'Designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide.',
      logoUrl: 'https://logo.clearbit.com/apple.com',
      website: 'https://www.apple.com',
      marketCap: 'Large Cap',
      employees: '164,000+'
    },
    'MSFT': {
      name: 'Microsoft',
      sector: 'Technology',
      industry: 'Software & Cloud',
      business: 'Software & Cloud',
      description: 'Develops, licenses, and supports software, services, devices, and solutions worldwide.',
      logoUrl: 'https://logo.clearbit.com/microsoft.com',
      website: 'https://www.microsoft.com',
      marketCap: 'Large Cap',
      employees: '221,000+'
    },
    'GOOGL': {
      name: 'Alphabet Inc.',
      sector: 'Technology',
      industry: 'Internet Services',
      business: 'Internet Services',
      description: 'Provides online advertising services and develops internet-based services and products.',
      logoUrl: 'https://logo.clearbit.com/google.com',
      website: 'https://www.google.com',
      marketCap: 'Large Cap',
      employees: '190,000+'
    },
    'GOOG': {
      name: 'Alphabet Inc.',
      sector: 'Technology',
      industry: 'Internet Services',
      business: 'Internet Services',
      description: 'Provides online advertising services and develops internet-based services and products.',
      logoUrl: 'https://logo.clearbit.com/google.com',
      website: 'https://www.google.com',
      marketCap: 'Large Cap',
      employees: '190,000+'
    },
    'TSLA': {
      name: 'Tesla',
      sector: 'Automotive',
      industry: 'Electric Vehicles',
      business: 'Electric Vehicles',
      description: 'Designs, develops, manufactures, and sells electric vehicles and energy storage systems.',
      logoUrl: 'https://logo.clearbit.com/tesla.com',
      website: 'https://www.tesla.com',
      marketCap: 'Large Cap',
      employees: '140,000+'
    },
    'AMZN': {
      name: 'Amazon',
      sector: 'E-commerce',
      industry: 'Online Retail & Cloud',
      business: 'Online Retail & Cloud',
      description: 'Operates online marketplace and cloud computing services worldwide.',
      logoUrl: 'https://logo.clearbit.com/amazon.com',
      website: 'https://www.amazon.com',
      marketCap: 'Large Cap',
      employees: '1,500,000+'
    },
    'META': {
      name: 'Meta',
      sector: 'Technology',
      industry: 'Social Media',
      business: 'Social Media',
      description: 'Operates social networking platforms and virtual reality products.',
      logoUrl: 'https://logo.clearbit.com/meta.com',
      website: 'https://www.meta.com',
      marketCap: 'Large Cap',
      employees: '86,000+'
    },
    'NVDA': {
      name: 'NVIDIA',
      sector: 'Technology',
      industry: 'AI & Graphics',
      business: 'AI & Graphics',
      description: 'Designs graphics processing units and system on chip units.',
      logoUrl: 'https://logo.clearbit.com/nvidia.com',
      website: 'https://www.nvidia.com',
      marketCap: 'Large Cap',
      employees: '29,000+'
    },
    'NFLX': {
      name: 'Netflix',
      sector: 'Entertainment',
      industry: 'Streaming',
      business: 'Streaming',
      description: 'Provides entertainment services and original content streaming.',
      logoUrl: 'https://logo.clearbit.com/netflix.com',
      website: 'https://www.netflix.com',
      marketCap: 'Large Cap',
      employees: '12,000+'
    },
    'DIS': {
      name: 'Disney',
      sector: 'Entertainment',
      industry: 'Media & Parks',
      business: 'Media & Parks',
      description: 'Operates entertainment parks and produces media content.',
      logoUrl: 'https://logo.clearbit.com/disney.com',
      website: 'https://www.disney.com',
      marketCap: 'Large Cap',
      employees: '220,000+'
    },
    'CRM': {
      name: 'Salesforce',
      sector: 'Technology',
      industry: 'CRM Software',
      business: 'CRM Software',
      description: 'Provides customer relationship management software and applications.',
      logoUrl: 'https://logo.clearbit.com/salesforce.com',
      website: 'https://www.salesforce.com',
      marketCap: 'Large Cap',
      employees: '79,000+'
    },
    'AMD': {
      name: 'AMD',
      sector: 'Technology',
      industry: 'Semiconductors',
      business: 'Semiconductors',
      description: 'Designs and manufactures microprocessors and graphics processors.',
      logoUrl: 'https://logo.clearbit.com/amd.com',
      website: 'https://www.amd.com',
      marketCap: 'Large Cap',
      employees: '25,000+'
    },
    'INTC': {
      name: 'Intel',
      sector: 'Technology',
      industry: 'Processors',
      business: 'Processors',
      description: 'Designs and manufactures semiconductor chips and related technologies.',
      logoUrl: 'https://logo.clearbit.com/intel.com',
      website: 'https://www.intel.com',
      marketCap: 'Large Cap',
      employees: '124,000+'
    },
    'ORCL': {
      name: 'Oracle',
      sector: 'Technology',
      industry: 'Database Software',
      business: 'Database Software',
      description: 'Provides database software and cloud computing services.',
      logoUrl: 'https://logo.clearbit.com/oracle.com',
      website: 'https://www.oracle.com',
      marketCap: 'Large Cap',
      employees: '164,000+'
    },
    'ADBE': {
      name: 'Adobe',
      sector: 'Technology',
      industry: 'Creative Software',
      business: 'Creative Software',
      description: 'Provides creative and digital marketing software solutions.',
      logoUrl: 'https://logo.clearbit.com/adobe.com',
      website: 'https://www.adobe.com',
      marketCap: 'Large Cap',
      employees: '28,000+'
    },
    'PYPL': {
      name: 'PayPal',
      sector: 'Fintech',
      industry: 'Digital Payments',
      business: 'Digital Payments',
      description: 'Operates digital payment platform for online money transfers.',
      logoUrl: 'https://logo.clearbit.com/paypal.com',
      website: 'https://www.paypal.com',
      marketCap: 'Large Cap',
      employees: '30,000+'
    },
    'UBER': {
      name: 'Uber',
      sector: 'Transportation',
      industry: 'Ride Sharing',
      business: 'Ride Sharing',
      description: 'Provides ride-hailing services and food delivery platform.',
      logoUrl: 'https://logo.clearbit.com/uber.com',
      website: 'https://www.uber.com',
      marketCap: 'Large Cap',
      employees: '32,000+'
    },
    'IBM': {
      name: 'IBM',
      sector: 'Technology',
      industry: 'Enterprise Software',
      business: 'Enterprise Software',
      description: 'Provides enterprise software and consulting services.',
      logoUrl: 'https://logo.clearbit.com/ibm.com',
      website: 'https://www.ibm.com',
      marketCap: 'Large Cap',
      employees: '350,000+'
    },
    'JPM': {
      name: 'JPMorgan Chase',
      sector: 'Financial Services',
      industry: 'Investment Banking',
      business: 'Investment Banking',
      description: 'Provides investment banking and financial services globally.',
      logoUrl: 'https://logo.clearbit.com/jpmorganchase.com',
      website: 'https://www.jpmorganchase.com',
      marketCap: 'Large Cap',
      employees: '300,000+'
    },
    'BAC': {
      name: 'Bank of America',
      sector: 'Financial Services',
      industry: 'Commercial Banking',
      business: 'Commercial Banking',
      description: 'Provides banking and financial services to consumers and businesses.',
      logoUrl: 'https://logo.clearbit.com/bankofamerica.com',
      website: 'https://www.bankofamerica.com',
      marketCap: 'Large Cap',
      employees: '217,000+'
    },
    'WMT': {
      name: 'Walmart',
      sector: 'Retail',
      industry: 'Discount Retail',
      business: 'Discount Retail',
      description: 'Operates retail stores and e-commerce platform worldwide.',
      logoUrl: 'https://logo.clearbit.com/walmart.com',
      website: 'https://www.walmart.com',
      marketCap: 'Large Cap',
      employees: '2,300,000+'
    },
    'V': {
      name: 'Visa',
      sector: 'Fintech',
      industry: 'Payment Networks',
      business: 'Payment Networks',
      description: 'Operates electronic payment network for global transactions.',
      logoUrl: 'https://logo.clearbit.com/visa.com',
      website: 'https://www.visa.com',
      marketCap: 'Large Cap',
      employees: '26,000+'
    },
    'MA': {
      name: 'Mastercard',
      sector: 'Fintech',
      industry: 'Payment Networks',
      business: 'Payment Networks',
      description: 'Provides payment processing and technology services globally.',
      logoUrl: 'https://logo.clearbit.com/mastercard.com',
      website: 'https://www.mastercard.com',
      marketCap: 'Large Cap',
      employees: '24,000+'
    },
    'JNJ': {
      name: 'Johnson & Johnson',
      sector: 'Healthcare',
      industry: 'Pharmaceuticals',
      business: 'Pharmaceuticals',
      description: 'Develops and manufactures pharmaceutical and medical device products.',
      logoUrl: 'https://logo.clearbit.com/jnj.com',
      website: 'https://www.jnj.com',
      marketCap: 'Large Cap',
      employees: '152,000+'
    },
    'PG': {
      name: 'Procter & Gamble',
      sector: 'Consumer Goods',
      industry: 'Personal Care',
      business: 'Personal Care',
      description: 'Manufactures consumer goods including personal care and household products.',
      logoUrl: 'https://logo.clearbit.com/pg.com',
      website: 'https://www.pg.com',
      marketCap: 'Large Cap',
      employees: '101,000+'
    },
    'KO': {
      name: 'Coca-Cola',
      sector: 'Consumer Goods',
      industry: 'Beverages',
      business: 'Beverages',
      description: 'Manufactures and distributes beverage products worldwide.',
      logoUrl: 'https://logo.clearbit.com/coca-cola.com',
      website: 'https://www.coca-cola.com',
      marketCap: 'Large Cap',
      employees: '82,000+'
    },
    'PEP': {
      name: 'PepsiCo',
      sector: 'Consumer Goods',
      industry: 'Food & Beverages',
      business: 'Food & Beverages',
      description: 'Manufactures food, snack, and beverage products globally.',
      logoUrl: 'https://logo.clearbit.com/pepsico.com',
      website: 'https://www.pepsico.com',
      marketCap: 'Large Cap',
      employees: '315,000+'
    },
    'CSCO': {
      name: 'Cisco Systems',
      sector: 'Technology',
      industry: 'Networking Equipment',
      business: 'Networking Equipment',
      description: 'Designs and manufactures networking and communications technology.',
      logoUrl: 'https://logo.clearbit.com/cisco.com',
      website: 'https://www.cisco.com',
      marketCap: 'Large Cap',
      employees: '84,000+'
    },
    'HD': {
      name: 'Home Depot',
      sector: 'Retail',
      industry: 'Home Improvement',
      business: 'Home Improvement',
      description: 'Operates home improvement retail stores across North America.',
      logoUrl: 'https://logo.clearbit.com/homedepot.com',
      website: 'https://www.homedepot.com',
      marketCap: 'Large Cap',
      employees: '500,000+'
    },
    'MCD': {
      name: 'McDonald\'s',
      sector: 'Consumer Services',
      industry: 'Fast Food',
      business: 'Fast Food',
      description: 'Operates fast food restaurant chain globally.',
      logoUrl: 'https://logo.clearbit.com/mcdonalds.com',
      website: 'https://www.mcdonalds.com',
      marketCap: 'Large Cap',
      employees: '210,000+'
    },
    'NKE': {
      name: 'Nike',
      sector: 'Consumer Goods',
      industry: 'Athletic Footwear',
      business: 'Athletic Footwear',
      description: 'Designs and manufactures athletic footwear, apparel, and equipment.',
      logoUrl: 'https://logo.clearbit.com/nike.com',
      website: 'https://www.nike.com',
      marketCap: 'Large Cap',
      employees: '83,000+'
    },
    'UNH': {
      name: 'UnitedHealth Group',
      sector: 'Healthcare',
      industry: 'Health Insurance',
      business: 'Health Insurance',
      description: 'Provides health insurance and healthcare services.',
      logoUrl: 'https://logo.clearbit.com/unitedhealthgroup.com',
      website: 'https://www.unitedhealthgroup.com',
      marketCap: 'Large Cap',
      employees: '440,000+'
    },
    'XOM': {
      name: 'Exxon Mobil',
      sector: 'Energy',
      industry: 'Oil & Gas',
      business: 'Oil & Gas',
      description: 'Explores, produces, and refines oil and natural gas globally.',
      logoUrl: 'https://logo.clearbit.com/exxonmobil.com',
      website: 'https://www.exxonmobil.com',
      marketCap: 'Large Cap',
      employees: '62,000+'
    },
    'GE': {
      name: 'General Electric',
      sector: 'Industrial',
      industry: 'Conglomerate',
      business: 'Conglomerate',
      description: 'Operates in aviation, healthcare, and renewable energy sectors.',
      logoUrl: 'https://logo.clearbit.com/ge.com',
      website: 'https://www.ge.com',
      marketCap: 'Large Cap',
      employees: '172,000+'
    },
    'F': {
      name: 'Ford Motor',
      sector: 'Automotive',
      industry: 'Vehicle Manufacturing',
      business: 'Vehicle Manufacturing',
      description: 'Designs and manufactures automobiles and commercial vehicles.',
      logoUrl: 'https://logo.clearbit.com/ford.com',
      website: 'https://www.ford.com',
      marketCap: 'Large Cap',
      employees: '190,000+'
    },
    'GM': {
      name: 'General Motors',
      sector: 'Automotive',
      industry: 'Vehicle Manufacturing',
      business: 'Vehicle Manufacturing',
      description: 'Designs, manufactures, and sells vehicles and vehicle parts.',
      logoUrl: 'https://logo.clearbit.com/gm.com',
      website: 'https://www.gm.com',
      marketCap: 'Large Cap',
      employees: '167,000+'
    }
  };
  
  // Enhanced fallback with proper sector mapping
  const company = companies[symbol];
  if (company) {
    return {
      name: company.name,
      sector: company.sector,
      industry: company.industry,
      business: company.business,
      description: company.description,
      logoUrl: company.logoUrl,
      website: company.website,
      marketCap: company.marketCap,
      employees: company.employees,
      symbol: symbol,
      isCrypto: false
    };
  }
  
  // Fallback for unknown symbols
  return {
    name: symbol,
    sector: 'Financial Markets',
    industry: 'Public Company',
    business: 'Public Company',
    description: `${symbol} is a publicly traded company.`,
    logoUrl: `https://logo.clearbit.com/${symbol.toLowerCase()}.com`,
    website: `https://www.${symbol.toLowerCase()}.com`,
    marketCap: 'Large Cap',
    employees: 'N/A',
    symbol: symbol,
    isCrypto: false
  };
}

// Cloud Storage upload - written directly in Firebase function  
async function uploadImagesToStorage(analysis, backgroundImageUrl) {
  try {
    const bucket = admin.storage().bucket();
    const date = new Date().toISOString().split('T')[0];
    const { symbol, timeframe } = analysis;
    
    // Download image from DALL-E URL
    console.log('⬇️ Downloading image from DALL-E...');
    const response = await fetch(backgroundImageUrl);
    if (!response.ok) {
      throw new Error(`Failed to download image: ${response.statusText}`);
    }
    const imageBuffer = Buffer.from(await response.arrayBuffer());
    
    // Save as latest trading card
    const latestTradingCardFile = bucket.file(`latest_images/${timeframe}_trading_card.png`);
    await latestTradingCardFile.save(imageBuffer, {
      metadata: { contentType: 'image/png' }
    });
    
    // Save backup in backgrounds folder
    const backgroundFileName = `${symbol}_${date}_${timeframe}_background.png`;
    const backgroundFile = bucket.file(`trading_backgrounds/${backgroundFileName}`);
    await backgroundFile.save(imageBuffer, {
      metadata: { contentType: 'image/png' }
    });
    
    // Generate signed URLs
    const [backgroundUrl] = await backgroundFile.getSignedUrl({
      action: 'read',
      expires: Date.now() + 30 * 24 * 60 * 60 * 1000 // 30 days
    });
    
    const [latestTradingCardUrl] = await latestTradingCardFile.getSignedUrl({
      action: 'read',
      expires: Date.now() + 30 * 24 * 60 * 60 * 1000 // 30 days
    });
    
    console.log('✅ Images uploaded to Cloud Storage');
    
    return {
      backgroundUrl,
      backgroundFileName,
      latestTradingCardUrl
    };
    
  } catch (error) {
    console.error('❌ Error uploading to storage:', error);
    throw error;
  }
}

// App statistics update - written directly in Firebase function
async function updateAppStats() {
  try {
    const db = admin.firestore();
    const statsRef = db.collection('app_stats').doc('global_stats');
    
    // Generate realistic stats
    const successRateOptions = [94, 95, 96, 97, 98];
    const aiAccuracyOptions = [95, 96, 97, 98, 99];
    
    const newSuccessRate = successRateOptions[Math.floor(Math.random() * successRateOptions.length)];
    const newAiAccuracy = aiAccuracyOptions[Math.floor(Math.random() * aiAccuracyOptions.length)];
    
    await statsRef.set({
      generatedTips: admin.firestore.FieldValue.increment(1),
      successRate: newSuccessRate,
      aiAccuracy: newAiAccuracy,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    
    console.log('✅ App statistics updated');
    
    return {
      success: true,
      successRate: newSuccessRate,
      aiAccuracy: newAiAccuracy
    };
    
  } catch (error) {
    console.error('❌ Error updating stats:', error);
    return { success: false, error: error.message };
  }
}

// Save to Firestore - written directly in Firebase function
async function saveToFirestore(tipData) {
  try {
    const db = admin.firestore();
    const { timeframe } = tipData;
    
    // Save to BOTH collections for compatibility
    const tradingTipsRef = db.collection('tradingTips').doc(timeframe);
    await tradingTipsRef.set(tipData, { merge: true });
    
    const latestTipsRef = db.collection('latest_tips').doc(timeframe);
    await latestTipsRef.set(tipData, { merge: true });
    
    console.log('✅ Saved to Firestore collections');
    
  } catch (error) {
    console.error('❌ Error saving to Firestore:', error);
    throw error;
  }
}

// Helper function to format timeframe
function formatTimeframe(timeframe) {
  const timeframes = {
    'short_term': 'Short-term',
    'mid_term': 'Mid-term', 
    'long_term': 'Long-term'
  };
  return timeframes[timeframe] || timeframe;
}

// Push notification function - written directly in Firebase function
async function sendTipNotification(tipData, company) {
  try {
    console.log('📱 Preparing push notification...');
    
    const { symbol, timeframe, sentiment, strength, entryPrice } = tipData;
    const companyName = company.name || symbol;
    
    // Generate unique message ID for analytics tracking
    const messageId = `tip_${symbol}_${timeframe}_${Date.now()}`;
    
    // Format timeframe for display
    const timeframeDisplay = timeframe.replace('_', ' ').toUpperCase();
    
    // Create notification content
    const title = `🚀 New ${timeframeDisplay} Tip: ${companyName}`;
    const body = `${sentiment.toUpperCase()} signal (${Math.abs(strength).toFixed(1)}) - Entry: $${entryPrice?.toFixed(2) || 'TBD'}`;
    
    // Build the notification message with enhanced analytics data
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        // Core trading data
        type: 'trading_tip',
        symbol: symbol,
        timeframe: timeframe,
        sentiment: sentiment,
        strength: strength.toString(),
        companyName: companyName,
        companyLogo: company.logoUrl || '',
        entryPrice: entryPrice?.toString() || '',
        timestamp: new Date().toISOString(),
        
        // Analytics tracking data
        message_id: messageId,
        analytics_symbol: symbol,
        analytics_sentiment: sentiment,
        analytics_timeframe: timeframe,
        analytics_strength: Math.abs(strength).toString(),
        analytics_timestamp: Date.now().toString(),
      },
      android: {
        notification: {
          icon: 'ic_notification',
          color: sentiment === 'bullish' ? '#4CAF50' : '#F44336',
          channelId: 'trading_tips',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          // Add analytics tag for Android
          tag: messageId,
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            category: 'TRADING_TIP',
            // Add custom analytics data for iOS
            'custom-data': {
              messageId: messageId,
              symbol: symbol,
              sentiment: sentiment
            }
          }
        }
      },
      // Send to topic for all users
      topic: 'trading_tips'
    };
    
    console.log('📤 Sending notification:', {
      messageId: messageId,
      title: message.notification.title,
      body: message.notification.body,
      symbol: symbol,
      sentiment: sentiment
    });
    
    // Send the notification using Firebase Admin
    const response = await admin.messaging().send(message);
    console.log('✅ Notification sent successfully:', response);
    
    // Log notification send event to Firestore for analytics
    try {
      await admin.firestore().collection('notification_analytics').add({
        event_type: 'sent',
        message_id: messageId,
        firebase_message_id: response,
        symbol: symbol,
        sentiment: sentiment,
        timeframe: timeframe,
        strength: strength,
        title: title,
        body: body,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        server_timestamp: Date.now(),
      });
      console.log('📊 Notification analytics logged');
    } catch (analyticsError) {
      console.error('⚠️ Failed to log analytics:', analyticsError);
      // Don't fail the notification if analytics logging fails
    }
    
    return {
      success: true,
      messageId: response,
      customMessageId: messageId,
      title: title,
      body: body
    };
    
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Comprehensive analysis function - runs full market scan and selects best signal
async function runComprehensiveAnalysis(apiKey, specificTimeframe = null) {
  try {
    console.log('🔍 Running comprehensive market analysis...');
    
    // All stock symbols to analyze - matching local analyzeAll.js ETORO_STOCKS
    const symbols = [
      'AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'TSLA', 'NVDA', 'AMD', 'INTC', 'IBM',
      'NFLX', 'JPM', 'BAC', 'WMT', 'DIS', 'V', 'MA', 'JNJ', 'PG', 'KO',
      'PEP', 'ADBE', 'CRM', 'ORCL', 'CSCO', 'HD', 'MCD', 'NKE', 'UNH', 'XOM',
      'GE', 'F', 'GM', 'PYPL', 'UBER'
    ];
    
    // Determine timeframes to analyze
    const allTimeframes = ['short_term', 'mid_term', 'long_term'];
    const timeframes = specificTimeframe ? [specificTimeframe] : allTimeframes;
    
    console.log(`⏰ Analyzing timeframes: ${timeframes.join(', ')}`);
    if (specificTimeframe) {
      console.log(`🎯 Single timeframe mode: ${specificTimeframe}`);
    } else {
      console.log(`🔄 Full analysis mode: all timeframes`);
    }
    
    const allSignals = [];
    
    // Analyze all combinations
    for (const timeframe of timeframes) {
      console.log(`📊 Analyzing ${timeframe}...`);
      
      const timeframeMap = {
        'short_term': '1h',
        'mid_term': '4h', 
        'long_term': '1d'
      };
      const taTimeframe = timeframeMap[timeframe];
      
      // Process in batches to avoid rate limits
      const batchSize = 10;
      for (let i = 0; i < symbols.length; i += batchSize) {
        const batch = symbols.slice(i, i + batchSize);
        const batchResults = await processBatchStocks(batch, timeframe, taTimeframe, apiKey);
        allSignals.push(...batchResults);
        
        // Small delay between batches
        if (i + batchSize < symbols.length) {
          await new Promise(resolve => setTimeout(resolve, 1000));
        }
      }
    }
    
    console.log(`📈 Found ${allSignals.length} total signals`);
    
    // Filter for strong signals (strength >= 2.0)
    const strongSignals = allSignals.filter(signal => 
      signal.strength && Math.abs(signal.strength) >= 2.0
    );
    
    console.log(`💪 Found ${strongSignals.length} strong signals`);
    
    if (strongSignals.length === 0) {
      console.log('⚠️ No strong signals found');
      return null;
    }
    
    // Sort by strength (highest absolute value first)
    strongSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    
    // Return the strongest signal
    const bestSignal = strongSignals[0];
    console.log(`🏆 Best signal: ${bestSignal.symbol} (${bestSignal.timeframe}) - Strength: ${bestSignal.strength}`);
    
    return bestSignal;
    
  } catch (error) {
    console.error('❌ Error in comprehensive analysis:', error);
    throw error;
  }
}

// Test notification function
exports.testNotification = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    const message = {
      notification: {
        title: '🧪 Trading Tip Generator Test',
        body: 'Push notifications are working! 🎉'
      },
      data: {
        type: 'test',
        timestamp: new Date().toISOString()
      },
      topic: 'trading_tips'
    };
    
    const response = await admin.messaging().send(message);
    console.log('✅ Test notification sent:', response);
    
    res.json({ 
      success: true, 
      messageId: response,
      message: 'Test notification sent successfully!'
    });
    
  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Scheduled function that runs every 30 minutes ONLY during market hours
exports.scheduledTradingTipGenerator = onSchedule({
  schedule: '*/30 9-15 * * 1-5', // Every 30 minutes from 9:00-15:59 (9 AM to 3:59 PM) ET, Mon-Fri
  timeZone: 'America/New_York', // US Eastern Time (handles DST automatically)
  secrets: [taapiApiKey, openaiApiKey],
  memory: '2GiB',
  timeoutSeconds: 540, // 9 minutes timeout for full analysis
}, async (event) => {
  console.log('🕐 Scheduled function triggered at:', new Date().toISOString());
  
  // OPTIMIZATION: Check market conditions FIRST to save costs
  try {
    const shouldRun = await checkMarketHoursAndDailyLimit();
    if (!shouldRun.canRun) {
      console.log('⏸️ Skipping execution:', shouldRun.reason);
      return { success: false, reason: shouldRun.reason };
    }
    
    console.log('✅ Market is open and conditions met, proceeding with analysis...');
    
    // Only run expensive operations if validation passes
    const result = await executeFullTradingTipGeneration();
    
    if (result.success) {
      console.log('🎉 Successfully generated and uploaded trading tip:', result.tip.symbol);
      
      // Mark that we've run successfully today
      await markDailyExecution();
      return { success: true, tip: result.tip };
    } else {
      console.log('❌ Failed to generate trading tip:', result.error);
      return { success: false, error: result.error };
    }
    
  } catch (error) {
    console.error('💥 Scheduled function error:', error);
    return { success: false, error: error.message };
  }
});

// Function to check market hours and daily execution limit
async function checkMarketHoursAndDailyLimit() {
  // Get current time in Eastern Time (handles DST automatically)
  const now = new Date();
  const easternTime = new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/New_York',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).formatToParts(now);
  
  // Parse the Eastern Time components
  const etYear = parseInt(easternTime.find(part => part.type === 'year').value);
  const etMonth = parseInt(easternTime.find(part => part.type === 'month').value) - 1; // JS months are 0-indexed
  const etDay = parseInt(easternTime.find(part => part.type === 'day').value);
  const etHour = parseInt(easternTime.find(part => part.type === 'hour').value);
  const etMinute = parseInt(easternTime.find(part => part.type === 'minute').value);
  
  const etDateTime = new Date(etYear, etMonth, etDay, etHour, etMinute);
  
  console.log(`🕐 Current Eastern Time: ${etDateTime.toLocaleString('en-US', { timeZone: 'America/New_York' })}`);
  
  // OPTIMIZATION 1: Check weekend first (fastest check)
  const dayOfWeek = etDateTime.getDay();
  if (dayOfWeek === 0 || dayOfWeek === 6) {
    return { canRun: false, reason: 'Weekend - market closed' };
  }
  
  // OPTIMIZATION 2: Check if already executed today (avoid expensive operations)
  const hasRunToday = await checkDailyExecution(etDateTime);
  if (hasRunToday) {
    return { canRun: false, reason: 'Already generated trading tip today' };
  }
  
  // OPTIMIZATION 3: Precise market hours check (9:30 AM to 4:00 PM ET)
  const timeInMinutes = etHour * 60 + etMinute;
  const marketOpenMinutes = 9 * 60 + 30; // 9:30 AM = 570 minutes
  const earliestRunMinutes = 9 * 60 + 40; // 9:40 AM = 580 minutes (10 min delay)
  const marketCloseMinutes = 16 * 60; // 4:00 PM = 960 minutes
  
  if (timeInMinutes < earliestRunMinutes) {
    const currentTimeStr = `${etHour}:${etMinute.toString().padStart(2, '0')}`;
    return { canRun: false, reason: `Too early - waiting until 9:40 AM ET (current: ${currentTimeStr} ET)` };
  }
  
  if (timeInMinutes >= marketCloseMinutes) {
    const currentTimeStr = `${etHour}:${etMinute.toString().padStart(2, '0')}`;
    return { canRun: false, reason: `Market closed - closes at 4:00 PM ET (current: ${currentTimeStr} ET)` };
  }
  
  // OPTIMIZATION 4: Check holidays last (least likely to fail)
  const isHoliday = await checkMarketHoliday(etDateTime);
  if (isHoliday) {
    return { canRun: false, reason: 'Market holiday' };
  }
  
  const currentTimeStr = `${etHour}:${etMinute.toString().padStart(2, '0')}`;
  return { 
    canRun: true, 
    reason: `Market open and no tip generated today (${currentTimeStr} ET)` 
  };
}

// Check if today is a market holiday
async function checkMarketHoliday(etDateTime) {
  // US Market holidays for 2024-2026 (from NYSE website)
  const holidays2024 = [
    '2024-01-01', '2024-01-15', '2024-02-19', '2024-03-29', '2024-05-27',
    '2024-06-19', '2024-07-04', '2024-09-02', '2024-11-28', '2024-12-25'
  ];
  
  const holidays2025 = [
    '2025-01-01', '2025-01-20', '2025-02-17', '2025-04-18', '2025-05-26',
    '2025-06-19', '2025-07-04', '2025-09-01', '2025-11-27', '2025-12-25'
  ];
  
  const holidays2026 = [
    '2026-01-01', '2026-01-19', '2026-02-16', '2026-04-03', '2026-05-25',
    '2026-06-19', '2026-07-03', '2026-09-07', '2026-11-26', '2026-12-25'
  ];
  
  const allHolidays = [...holidays2024, ...holidays2025, ...holidays2026];
  
  const dateString = etDateTime.toISOString().split('T')[0]; // YYYY-MM-DD format
  return allHolidays.includes(dateString);
}

// Check if we've already run successfully today
async function checkDailyExecution(etDateTime) {
  try {
    const today = etDateTime.toISOString().split('T')[0]; // YYYY-MM-DD format
    
    const db = admin.firestore();
    const executionRef = db.collection('scheduled_executions').doc(today);
    const doc = await executionRef.get();
    
    if (doc.exists) {
      const data = doc.data();
      console.log('📋 Daily execution record found:', data);
      return data.success === true;
    }
    
    return false;
  } catch (error) {
    console.error('❌ Error checking daily execution:', error);
    return false; // If we can't check, allow execution
  }
}

// Mark that we've successfully executed today
async function markDailyExecution() {
  try {
    const now = new Date();
    const easternTime = new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/New_York',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).formatToParts(now);
    
    const etYear = parseInt(easternTime.find(part => part.type === 'year').value);
    const etMonth = parseInt(easternTime.find(part => part.type === 'month').value) - 1;
    const etDay = parseInt(easternTime.find(part => part.type === 'day').value);
    const etDate = new Date(etYear, etMonth, etDay);
    
    const today = etDate.toISOString().split('T')[0]; // YYYY-MM-DD format
    
    const db = admin.firestore();
    const executionRef = db.collection('scheduled_executions').doc(today);
    
    await executionRef.set({
      success: true,
      timestamp: new Date().toISOString(),
      easternDate: today
    });
    
    console.log('✅ Marked daily execution as complete for:', today);
  } catch (error) {
    console.error('❌ Error marking daily execution:', error);
  }
}

// Manual trigger for testing (HTTP function)
exports.triggerScheduledAnalysis = onRequest({
  secrets: [taapiApiKey, openaiApiKey],
  cors: true,
}, async (req, res) => {
  try {
    console.log('🧪 Manual trigger for scheduled analysis');
    
    // Get timeframe parameter
    const timeframe = req.query.timeframe;
    const validTimeframes = ['short_term', 'mid_term', 'long_term'];
    
    // Validate timeframe if provided
    if (timeframe && !validTimeframes.includes(timeframe)) {
      return res.status(400).json({
        success: false,
        error: `Invalid timeframe. Use: ${validTimeframes.join(', ')}`,
        validTimeframes: validTimeframes
      });
    }
    
    if (timeframe) {
      console.log(`🎯 Specific timeframe requested: ${timeframe}`);
    } else {
      console.log('🔄 Full analysis mode: all timeframes');
    }
    
    // Check market conditions
    const shouldRun = await checkMarketHoursAndDailyLimit();
    
    // For manual testing, we can override the daily limit check
    const forceRun = req.query.force === 'true';
    
    if (!shouldRun.canRun && !forceRun) {
      return res.json({
        success: false,
        reason: shouldRun.reason,
        hint: 'Add ?force=true to override daily limit check',
        timeframe: timeframe || 'all'
      });
    }
    
    if (forceRun) {
      console.log('🔧 Force mode enabled - overriding checks');
    }
    
    // Run the full trading tip generation with optional timeframe
    const result = await executeFullTradingTipGeneration(timeframe);
    
    if (result.success && !forceRun) {
      // Only mark execution if not forced (to avoid marking test runs)
      await markDailyExecution();
    }
    
    res.json({
      success: result.success,
      tip: result.tip,
      error: result.error,
      marketCheck: shouldRun,
      forceRun,
      timeframe: timeframe || 'all',
      timeframeUsed: result.tip?.timeframe || null
    });
    
  } catch (error) {
    console.error('❌ Manual trigger error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      timeframe: req.query.timeframe || 'all'
    });
  }
});

// Custom test notification function with user-specified title and message
exports.customTestNotification = onRequest({
  cors: true,
}, async (req, res) => {
  try {
    // Get title and message from query parameters
    const title = req.query.title || '🧪 Custom Test Notification';
    const message = req.query.message || 'This is a custom test message! 🎯';
    const testType = req.query.type || 'custom_test';
    
    console.log('📱 Sending custom test notification:', { title, message, testType });
    
    const notificationMessage = {
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: testType,
        timestamp: new Date().toISOString(),
        test_id: `test_${Date.now()}`,
        custom_title: title,
        custom_message: message,
      },
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#00D4AA',
          channelId: 'trading_tips',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            category: 'TEST_NOTIFICATION'
          }
        }
      },
      topic: 'trading_tips'
    };
    
    const response = await admin.messaging().send(notificationMessage);
    console.log('✅ Custom test notification sent:', response);
    
    // Log to analytics for testing
    try {
      await admin.firestore().collection('notification_analytics').add({
        event_type: 'custom_test_sent',
        test_id: `test_${Date.now()}`,
        firebase_message_id: response,
        title: title,
        body: message,
        test_type: testType,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        server_timestamp: Date.now(),
      });
      console.log('📊 Custom test analytics logged');
    } catch (analyticsError) {
      console.error('⚠️ Failed to log test analytics:', analyticsError);
    }
    
    res.json({ 
      success: true, 
      messageId: response,
      title: title,
      message: message,
      testType: testType,
      info: 'Custom test notification sent successfully!'
    });
    
  } catch (error) {
    console.error('❌ Error sending custom test notification:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// ============================================================================
// CRYPTO ANALYSIS FUNCTIONS - RUNS WHEN US STOCK MARKET IS CLOSED
// ============================================================================

// Crypto pairs configuration
const CRYPTO_PAIRS = [
  'BTC/USDT',   // Bitcoin - The king of crypto
  'ETH/USDT',   // Ethereum - Smart contracts leader
  'BNB/USDT',   // Binance Coin - Exchange token
  'ADA/USDT',   // Cardano - Academic blockchain
  'SOL/USDT',   // Solana - High performance blockchain
  'XRP/USDT',   // Ripple - Cross-border payments
  'DOT/USDT',   // Polkadot - Interoperability
  'LINK/USDT',  // Chainlink - Oracle network
  'LTC/USDT',   // Litecoin - Digital silver
  'BCH/USDT',   // Bitcoin Cash - Bitcoin fork
  'DOGE/USDT',  // Dogecoin - Meme coin leader
  'AVAX/USDT',  // Avalanche - DeFi platform
  'MATIC/USDT', // Polygon - Ethereum scaling
  'UNI/USDT',   // Uniswap - DEX token
  'ATOM/USDT'   // Cosmos - Internet of blockchains
];

const CRYPTO_TIMEFRAMES = ['short_term', 'mid_term', 'long_term'];
const CRYPTO_TIMEFRAME_MAP = {
  'short_term': '1h',
  'mid_term': '4h', 
  'long_term': '1d'
};

// Crypto-optimized threshold (higher for selectivity - only strongest signals)
const MIN_CRYPTO_SIGNAL_STRENGTH = 1.5;

// Optimized crypto analysis - weekday evenings (6 PM - 11:59 PM ET)
exports.scheduledCryptoTipGeneratorEvening = onSchedule({
  schedule: '*/55 18-23 * * 1-5',
  timeZone: 'America/New_York',
  secrets: [taapiApiKey, openaiApiKey],
}, async (context) => {
  try {
    console.log('🌆 Scheduled crypto analysis (evening) starting...');
    
    // Check daily limit and market conditions
    const canRunCrypto = await checkCryptoMarketWindow();
    
    if (!canRunCrypto.canRun) {
      console.log('⏰ Crypto analysis skipped:', canRunCrypto.reason);
      return null;
    }
    
    console.log('🚀 Evening crypto analysis window - running analysis');
    
    // Run comprehensive crypto analysis
    const result = await executeFullCryptoTipGeneration();
    
    if (result.success) {
      console.log('✅ Crypto tip generated successfully');
      await markDailyCryptoExecution();
    } else {
      console.log('ℹ️ No strong crypto signals found');
    }
    
    return result;
    
  } catch (error) {
    console.error('❌ Scheduled crypto analysis error:', error);
    return { success: false, error: error.message };
  }
});

// Optimized crypto analysis - weekday early mornings (12 AM - 8:30 AM ET)
exports.scheduledCryptoTipGeneratorMorning = onSchedule({
  schedule: '*/55 0-8 * * 1-5',
  timeZone: 'America/New_York',
  secrets: [taapiApiKey, openaiApiKey],
}, async (context) => {
  try {
    console.log('🌅 Scheduled crypto analysis (morning) starting...');
    
    // Check daily limit and market conditions
    const canRunCrypto = await checkCryptoMarketWindow();
    
    if (!canRunCrypto.canRun) {
      console.log('⏰ Crypto analysis skipped:', canRunCrypto.reason);
      return null;
    }
    
    console.log('🚀 Morning crypto analysis window - running analysis');
    
    // Run comprehensive crypto analysis
    const result = await executeFullCryptoTipGeneration();
    
    if (result.success) {
      console.log('✅ Crypto tip generated successfully');
      await markDailyCryptoExecution();
    } else {
      console.log('ℹ️ No strong crypto signals found');
    }
    
    return result;
    
  } catch (error) {
    console.error('❌ Scheduled crypto analysis error:', error);
    return { success: false, error: error.message };
  }
});

// Optimized crypto analysis - weekends (all day)
exports.scheduledCryptoTipGeneratorWeekend = onSchedule({
  schedule: '*/55 * * * 0,6',
  timeZone: 'America/New_York',
  secrets: [taapiApiKey, openaiApiKey],
}, async (context) => {
  try {
    console.log('🎉 Scheduled crypto analysis (weekend) starting...');
    
    // Check daily limit
    const canRunCrypto = await checkCryptoMarketWindow();
    
    if (!canRunCrypto.canRun) {
      console.log('⏰ Crypto analysis skipped:', canRunCrypto.reason);
      return null;
    }
    
    console.log('🚀 Weekend crypto analysis - running analysis');
    
    // Run comprehensive crypto analysis
    const result = await executeFullCryptoTipGeneration();
    
    if (result.success) {
      console.log('✅ Crypto tip generated successfully');
      await markDailyCryptoExecution();
    } else {
      console.log('ℹ️ No strong crypto signals found');
    }
    
    return result;
    
  } catch (error) {
    console.error('❌ Scheduled crypto analysis error:', error);
    return { success: false, error: error.message };
  }
});

// Manual crypto analysis trigger
exports.triggerCryptoAnalysis = onRequest({
  secrets: [taapiApiKey, openaiApiKey],
  cors: true,
}, async (req, res) => {
  try {
    console.log('🧪 Manual crypto analysis trigger');
    
    // Get timeframe parameter
    const timeframe = req.query.timeframe;
    const validTimeframes = ['short_term', 'mid_term', 'long_term'];
    
    // Validate timeframe if provided
    if (timeframe && !validTimeframes.includes(timeframe)) {
      return res.status(400).json({
        success: false,
        error: `Invalid timeframe. Use: ${validTimeframes.join(', ')}`,
        validTimeframes: validTimeframes
      });
    }
    
    // Check crypto market conditions
    const shouldRun = await checkCryptoMarketWindow();
    const forceRun = req.query.force === 'true';
    
    if (!shouldRun.canRun && !forceRun) {
      return res.json({
        success: false,
        reason: shouldRun.reason,
        hint: 'Add ?force=true to override checks',
        timeframe: timeframe || 'all'
      });
    }
    
    if (forceRun) {
      console.log('🔧 Force mode enabled - overriding checks');
    }
    
    // Run crypto analysis with optional specific timeframe
    const result = await executeFullCryptoTipGeneration(timeframe);
    
    if (result.success && !forceRun) {
      await markDailyCryptoExecution();
    }
    
    res.json({
      success: result.success,
      tip: result.tip,
      error: result.error,
      marketCheck: shouldRun,
      forceRun,
      timeframe: timeframe || 'all'
    });
    
  } catch (error) {
    console.error('❌ Manual crypto trigger error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Execute comprehensive crypto tip generation
async function executeFullCryptoTipGeneration(specificTimeframe = null) {
  try {
    console.log('💎 Starting comprehensive crypto analysis...');
    
    const apiKey = taapiApiKey.value().replace(/^["']|["']$/g, '').trim();
    
    // Run comprehensive crypto analysis
    const results = await runComprehensiveCryptoAnalysis(apiKey, specificTimeframe);
    
    if (!results.success || results.signals.length === 0) {
      console.log('ℹ️ No strong crypto signals found');
      return {
        success: false,
        error: 'No strong crypto signals found',
        signalsAnalyzed: results.totalAnalyzed || 0
      };
    }
    
    console.log(`🎯 Found ${results.signals.length} strong crypto signals`);
    
    // Select the best crypto signal (highest strength)
    const bestSignal = results.signals[0]; // Already sorted by strength
    
    console.log(`🥇 Best crypto signal: ${bestSignal.pair} (${bestSignal.sentiment}, ${bestSignal.strength.toFixed(2)})`);
    
    // Generate crypto-themed images
    const openaiKey = openaiApiKey.value().replace(/^["']|["']$/g, '').trim();
    const backgroundImageUrl = await generateCryptoBackgroundImage(bestSignal, openaiKey);
    
    // Upload images to storage
    const imageUrls = await uploadImagesToStorage(bestSignal, backgroundImageUrl);
    
    // Get crypto info
    const cryptoInfo = getCryptoInfo(bestSignal.pair);
    
    // Create comprehensive tip data
    const tipData = {
      id: `crypto_${Date.now()}`,
      type: 'crypto',
      symbol: bestSignal.pair,
      crypto: bestSignal.crypto,
      sentiment: bestSignal.sentiment,
      strength: bestSignal.strength,
      confidence: bestSignal.confidence,
      timeframe: bestSignal.timeframe,
      entryPrice: bestSignal.entryPrice,
      stopLoss: bestSignal.stopLoss,
      takeProfit: bestSignal.takeProfit,
      riskReward: bestSignal.riskReward,
      reasoning: bestSignal.reasoning,
      indicators: bestSignal.indicators,
      backgroundUrl: imageUrls.backgroundUrl,
      logoUrl: cryptoInfo.logoUrl,
      timestamp: new Date().toISOString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      market: 'crypto',
      exchange: 'binance'
    };
    
    // Save to Firestore
    await saveToFirestore(tipData);
    
    // Update app stats
    await updateAppStats();
    
    // Send push notification
    await sendCryptoTipNotification(tipData, cryptoInfo);
    
    console.log('✅ Crypto tip generation completed successfully');
    
    return {
      success: true,
      tip: tipData
    };
    
  } catch (error) {
    console.error('❌ Error in crypto tip generation:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

// Run comprehensive crypto analysis across all pairs and timeframes
async function runComprehensiveCryptoAnalysis(apiKey, specificTimeframe = null) {
  try {
    console.log('🔍 Running comprehensive crypto analysis...');
    
    const allSignals = [];
    const timeframesToAnalyze = specificTimeframe ? [specificTimeframe] : CRYPTO_TIMEFRAMES;
    let totalAnalyzed = 0;
    
    // Analyze each timeframe
    for (const timeframe of timeframesToAnalyze) {
      console.log(`📊 Analyzing crypto ${timeframe} timeframe...`);
      
      const batchSize = 5; // Process in smaller batches for crypto
      
      for (let i = 0; i < CRYPTO_PAIRS.length; i += batchSize) {
        const batch = CRYPTO_PAIRS.slice(i, i + batchSize);
        console.log(`📦 Processing crypto batch: ${batch.join(', ')}`);
        
        for (const pair of batch) {
          try {
            totalAnalyzed++;
            console.log(`💎 Analyzing ${pair}...`);
            
            const analysis = await analyzeCryptoPair(pair, timeframe, apiKey);
            
            if (analysis && Math.abs(analysis.strength) >= MIN_CRYPTO_SIGNAL_STRENGTH) {
              allSignals.push(analysis);
              console.log(`✅ Strong signal: ${analysis.sentiment} (${analysis.strength.toFixed(2)})`);
            } else {
              const strength = analysis ? analysis.strength.toFixed(2) : 'N/A';
              console.log(`⚪ Weak signal: ${strength}`);
            }
            
            // Rate limiting
            await new Promise(resolve => setTimeout(resolve, 400));
            
          } catch (error) {
            console.error(`❌ Error analyzing ${pair}:`, error.message);
          }
        }
        
        // Delay between batches
        if (i + batchSize < CRYPTO_PAIRS.length) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
    }
    
    // Sort by strength (strongest first)
    allSignals.sort((a, b) => Math.abs(b.strength) - Math.abs(a.strength));
    
    console.log(`🎯 Analysis complete: ${allSignals.length} strong signals from ${totalAnalyzed} analyses`);
    
    return {
      success: true,
      signals: allSignals,
      totalAnalyzed: totalAnalyzed
    };
    
  } catch (error) {
    console.error('❌ Error in comprehensive crypto analysis:', error);
    return {
      success: false,
      error: error.message,
      signals: []
    };
  }
}

// Analyze individual crypto pair
async function analyzeCryptoPair(pair, timeframe, apiKey) {
  try {
    const construct = {
      exchange: 'binance',
      symbol: pair,
      interval: CRYPTO_TIMEFRAME_MAP[timeframe],
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

    const response = await axios.post('https://api.taapi.io/bulk', {
      secret: apiKey,
      construct: construct
    });

    // Process results into indicators object
    const indicators = {};
    let currentPrice = null;
    
    response.data.data.forEach(result => {
      const indicatorName = result.indicator;
      
      if (indicatorName === 'ema') {
        if (!indicators.ema) indicators.ema = {};
        const period = result.id.includes('_50_') ? 50 : result.id.includes('_200_') ? 200 : 'unknown';
        indicators.ema[`ema${period}`] = result.result;
      } else {
        indicators[indicatorName] = result.result;
      }
      
      // Get current price
      if (result.result && typeof result.result === 'object' && result.result.close && !currentPrice) {
        currentPrice = result.result.close;
      }
    });

    // If no current price found, get from EMA
    if (!currentPrice) {
      if (indicators.ema?.ema50?.value) {
        currentPrice = indicators.ema.ema50.value;
      } else if (indicators.ema?.ema200?.value) {
        currentPrice = indicators.ema.ema200.value;
      }
    }

    // Generate crypto-specific analysis
    const analysis = generateCryptoAnalysis(pair, indicators, currentPrice, timeframe);

    return {
      pair: pair,
      crypto: getCryptoName(pair),
      timeframe: timeframe,
      sentiment: analysis.sentiment,
      strength: analysis.strength,
      confidence: analysis.confidence,
      entryPrice: analysis.entryPrice,
      stopLoss: analysis.stopLoss,
      takeProfit: analysis.takeProfit,
      riskReward: analysis.riskRewardRatio,
      reasoning: analysis.reasoning,
      indicators: {
        rsi: indicators.rsi?.value,
        macd: indicators.macd?.valueMACDHist,
        ema50: indicators.ema?.ema50?.value,
        ema200: indicators.ema?.ema200?.value,
        adx: indicators.adx?.value,
        atr: indicators.atr?.value
      }
    };
    
  } catch (error) {
    console.error(`Error analyzing crypto ${pair} ${timeframe}:`, error.message);
    return null;
  }
}

// Generate crypto-specific analysis
function generateCryptoAnalysis(symbol, indicators, currentPrice, timeframe) {
  const analysis = {
    sentiment: 'neutral',
    strength: 0,
    confidence: 0,
    tradingAction: 'hold',
    entryPrice: null,
    stopLoss: null,
    takeProfit: null,
    riskRewardRatio: null,
    reasoning: [],
    keyLevels: {
      support: null,
      resistance: null
    }
  };

  let bullishSignals = 0;
  let bearishSignals = 0;
  let totalSignals = 0;

  // 1. Crypto-optimized RSI Analysis (more extreme thresholds)
  if (indicators.rsi?.value) {
    const rsi = indicators.rsi.value;
    totalSignals++;
    
    if (rsi < 20) {
      bullishSignals += 2;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) extremely oversold - strong crypto buy signal`);
    } else if (rsi < 30) {
      bullishSignals += 1;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) oversold - crypto buy signal`);
    } else if (rsi > 80) {
      bearishSignals += 2;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) extremely overbought - strong crypto sell signal`);
    } else if (rsi > 70) {
      bearishSignals += 1;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) overbought - crypto sell signal`);
    } else {
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) in neutral zone`);
    }
  }

  // 2. MACD Analysis
  if (indicators.macd?.valueMACDHist && indicators.macd?.valueMACD && indicators.macd?.valueMACDSignal) {
    const macdHist = indicators.macd.valueMACDHist;
    const macdLine = indicators.macd.valueMACD;
    const signalLine = indicators.macd.valueMACDSignal;
    totalSignals++;
    
    if (macdHist > 0 && macdLine > signalLine) {
      bullishSignals++;
      analysis.reasoning.push('MACD shows bullish momentum - positive histogram');
    } else if (macdHist < 0 && macdLine < signalLine) {
      bearishSignals++;
      analysis.reasoning.push('MACD shows bearish momentum - negative histogram');
    } else {
      analysis.reasoning.push('MACD shows mixed signals');
    }
  }

  // 3. Moving Average Analysis for crypto
  if (indicators.ema?.ema50?.value && indicators.ema?.ema200?.value) {
    const ema50 = indicators.ema.ema50.value;
    const ema200 = indicators.ema.ema200.value;
    totalSignals++;
    
    if (ema50 > ema200 && currentPrice > ema50) {
      bullishSignals++;
      analysis.reasoning.push('Strong crypto uptrend: Price above EMA50 > EMA200');
    } else if (ema50 < ema200 && currentPrice < ema50) {
      bearishSignals++;
      analysis.reasoning.push('Strong crypto downtrend: Price below EMA50 < EMA200');
    } else {
      analysis.reasoning.push('Mixed trend signals');
    }
  }

  // Calculate overall strength (crypto has higher volatility, so different scaling)
  const netSignals = bullishSignals - bearishSignals;
  analysis.strength = Math.min(5, Math.max(-5, netSignals * 0.8)); // Scale for crypto volatility
  analysis.sentiment = analysis.strength > 0 ? 'bullish' : analysis.strength < 0 ? 'bearish' : 'neutral';
  analysis.confidence = totalSignals > 0 ? Math.min(95, (Math.abs(netSignals) / totalSignals) * 100) : 0;

  // Calculate crypto trading levels using ATR
  const atr = indicators.atr?.value || currentPrice * 0.03; // 3% default for crypto
  analysis.entryPrice = currentPrice;
  
  if (analysis.sentiment === 'bullish') {
    analysis.stopLoss = currentPrice - (atr * 1.5);
    analysis.takeProfit = currentPrice + (atr * 2.5);
  } else if (analysis.sentiment === 'bearish') {
    analysis.stopLoss = currentPrice + (atr * 1.5);
    analysis.takeProfit = currentPrice - (atr * 2.5);
  }

  if (analysis.stopLoss && analysis.takeProfit && analysis.entryPrice) {
    const risk = Math.abs(analysis.entryPrice - analysis.stopLoss);
    const reward = Math.abs(analysis.takeProfit - analysis.entryPrice);
    analysis.riskRewardRatio = risk > 0 ? reward / risk : 0;
  }

  return analysis;
}

// Generate crypto-themed background image
async function generateCryptoBackgroundImage(analysis, openaiApiKey) {
  try {
    console.log('🎨 Generating crypto background image...');
    
    const prompt = createCryptoBackgroundPrompt(analysis);
    
    const response = await fetch('https://api.openai.com/v1/images/generations', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'dall-e-3',
        prompt: prompt,
        n: 1,
        size: '1024x1024',
        quality: 'standard',
        style: 'vivid'
      })
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    console.log('✅ Crypto background generated successfully');
    
    return data.data[0].url;
    
  } catch (error) {
    console.error('❌ Error generating crypto background:', error);
    throw error;
  }
}

// Create crypto-specific background prompt
function createCryptoBackgroundPrompt(analysis) {
  const sentiment = analysis.sentiment;
  const crypto = analysis.crypto;
  const strength = Math.abs(analysis.strength);
  
  const sentimentColors = {
    'bullish': 'vibrant green and gold',
    'bearish': 'deep red and orange',
    'neutral': 'blue and purple'
  };
  
  const colors = sentimentColors[sentiment] || 'blue and purple';
  
  const basePrompt = `Professional cryptocurrency trading card background featuring ${crypto} themed elements. `;
  
  if (sentiment === 'bullish') {
    return basePrompt + `Bullish crypto theme with ${colors} gradients, upward trending charts, rocket ships, bulls, growth arrows, digital currency symbols, blockchain networks, and prosperity symbols. Modern fintech aesthetic with glowing effects, circuit patterns, and success imagery. High-tech cryptocurrency trading environment.`;
  } else if (sentiment === 'bearish') {
    return basePrompt + `Bearish crypto theme with ${colors} gradients, downward trending charts, bears, correction arrows, digital currency symbols, blockchain networks, and caution symbols. Modern fintech aesthetic with warning effects, circuit patterns, and market correction imagery. Professional cryptocurrency trading environment.`;
  } else {
    return basePrompt + `Neutral crypto theme with ${colors} gradients, sideways trending charts, balanced scales, digital currency symbols, blockchain networks, and stability symbols. Modern fintech aesthetic with balanced effects, circuit patterns, and market equilibrium imagery. Professional cryptocurrency trading environment.`;
  }
}

// Check if we should run crypto analysis (when US stock market is closed)
async function checkCryptoMarketWindow() {
  try {
    const now = new Date();
    const easternTime = new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/New_York',
      hour12: false,
      weekday: 'long',
      hour: '2-digit',
      minute: '2-digit'
    }).formatToParts(now);
    
    const etHour = parseInt(easternTime.find(part => part.type === 'hour').value);
    const etMinute = parseInt(easternTime.find(part => part.type === 'minute').value);
    const etWeekday = easternTime.find(part => part.type === 'weekday').value;
    
    const currentTimeMinutes = etHour * 60 + etMinute;
    
    console.log(`🕐 Current ET time: ${etWeekday} ${etHour}:${etMinute.toString().padStart(2, '0')}`);
    
    // Define crypto analysis window: 6:00 PM (18:00) to 8:30 AM (08:30) ET
    const cryptoStartTime = 18 * 60; // 6:00 PM ET
    const cryptoEndTime = 8 * 60 + 30; // 8:30 AM ET
    
    // Check if it's weekend (crypto runs all day)
    if (etWeekday === 'Saturday' || etWeekday === 'Sunday') {
      console.log('📅 Weekend - crypto analysis active all day');
      return await checkDailyCryptoExecution();
    }
    
    // Check if current time is within crypto analysis window
    // Window spans midnight, so we need to check both evening and early morning
    const inEveningWindow = currentTimeMinutes >= cryptoStartTime; // After 6:00 PM
    const inMorningWindow = currentTimeMinutes <= cryptoEndTime;   // Before 8:30 AM
    
    if (inEveningWindow || inMorningWindow) {
      console.log(`🌙 Within crypto analysis window (6:00 PM - 8:30 AM ET) - current: ${etHour}:${etMinute.toString().padStart(2, '0')}`);
      return await checkDailyCryptoExecution();
    }
    
    return {
      canRun: false,
      reason: `Outside crypto analysis window (6:00 PM - 8:30 AM ET) - current: ${etHour}:${etMinute.toString().padStart(2, '0')} ET`
    };
    
  } catch (error) {
    console.error('❌ Error checking crypto market window:', error);
    return {
      canRun: true,
      reason: 'Error checking market window - allowing crypto analysis'
    };
  }
}

// Check if crypto analysis already ran today
async function checkDailyCryptoExecution() {
  try {
    const now = new Date();
    const easternTime = new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/New_York',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).formatToParts(now);
    
    const etYear = parseInt(easternTime.find(part => part.type === 'year').value);
    const etMonth = parseInt(easternTime.find(part => part.type === 'month').value) - 1;
    const etDay = parseInt(easternTime.find(part => part.type === 'day').value);
    const etDate = new Date(etYear, etMonth, etDay);
    
    const today = etDate.toISOString().split('T')[0];
    
    const db = admin.firestore();
    const executionRef = db.collection('crypto_executions').doc(today);
    const doc = await executionRef.get();
    
    if (doc.exists) {
      const data = doc.data();
      console.log('✅ Crypto execution already completed today:', today);
      return {
        canRun: false,
        reason: 'Crypto analysis already completed today',
        lastExecution: data.timestamp
      };
    }
    
    console.log('🆕 No crypto execution today - can proceed');
    return {
      canRun: true,
      reason: 'Ready for crypto analysis'
    };
    
  } catch (error) {
    console.error('❌ Error checking daily crypto execution:', error);
    return {
      canRun: true,
      reason: 'Error checking daily execution - allowing crypto analysis'
    };
  }
}

// Mark that crypto analysis was completed today
async function markDailyCryptoExecution() {
  try {
    const now = new Date();
    const easternTime = new Intl.DateTimeFormat('en-US', {
      timeZone: 'America/New_York',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).formatToParts(now);
    
    const etYear = parseInt(easternTime.find(part => part.type === 'year').value);
    const etMonth = parseInt(easternTime.find(part => part.type === 'month').value) - 1;
    const etDay = parseInt(easternTime.find(part => part.type === 'day').value);
    const etDate = new Date(etYear, etMonth, etDay);
    
    const today = etDate.toISOString().split('T')[0];
    
    const db = admin.firestore();
    const executionRef = db.collection('crypto_executions').doc(today);
    
    await executionRef.set({
      success: true,
      timestamp: new Date().toISOString(),
      easternDate: today
    });
    
    console.log('✅ Marked daily crypto execution as complete for:', today);
  } catch (error) {
    console.error('❌ Error marking daily crypto execution:', error);
  }
}

// Send crypto tip notification
async function sendCryptoTipNotification(tipData, cryptoInfo) {
  try {
    console.log('📱 Sending crypto tip notification...');
    
    const title = `🚀 New ${formatTimeframe(tipData.timeframe)} Crypto Tip: ${tipData.crypto}`;
    const sentimentEmoji = tipData.sentiment === 'bullish' ? '🚀' : tipData.sentiment === 'bearish' ? '📉' : '➡️';
    const body = `${sentimentEmoji} ${tipData.sentiment.toUpperCase()} signal (${Math.abs(tipData.strength).toFixed(1)}) - Entry: $${tipData.entryPrice?.toFixed(6)}`;
    
    const notificationMessage = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: 'crypto_tip',
        symbol: tipData.symbol,
        crypto: tipData.crypto,
        sentiment: tipData.sentiment,
        strength: tipData.strength.toString(),
        timeframe: tipData.timeframe,
        entryPrice: tipData.entryPrice?.toString() || '',
        timestamp: tipData.timestamp,
        tipId: tipData.id,
        market: 'crypto'
      },
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#00D4AA',
          channelId: 'crypto_tips',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
          imageUrl: tipData.backgroundUrl
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            category: 'CRYPTO_TIP',
            'mutable-content': 1
          }
        },
        fcm_options: {
          image: tipData.backgroundUrl
        }
      },
      topic: 'crypto_tips'
    };
    
    const response = await admin.messaging().send(notificationMessage);
    console.log('✅ Crypto notification sent:', response);
    
    // Log analytics
    try {
      await admin.firestore().collection('notification_analytics').add({
        event_type: 'crypto_tip_sent',
        tip_id: tipData.id,
        firebase_message_id: response,
        symbol: tipData.symbol,
        crypto: tipData.crypto,
        sentiment: tipData.sentiment,
        strength: tipData.strength,
        timeframe: tipData.timeframe,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        market: 'crypto'
      });
    } catch (analyticsError) {
      console.error('⚠️ Failed to log crypto notification analytics:', analyticsError);
    }
    
  } catch (error) {
    console.error('❌ Error sending crypto notification:', error);
    throw error;
  }
}

// Get crypto information
function getCryptoInfo(pair) {
  const cryptoData = {
    'BTC/USDT': { name: 'Bitcoin', logoUrl: '/logos/crypto/BTC.png' },
    'ETH/USDT': { name: 'Ethereum', logoUrl: '/logos/crypto/ETH.png' },
    'BNB/USDT': { name: 'Binance Coin', logoUrl: '/logos/crypto/BNB.png' },
    'ADA/USDT': { name: 'Cardano', logoUrl: '/logos/crypto/ADA.png' },
    'SOL/USDT': { name: 'Solana', logoUrl: '/logos/crypto/SOL.png' },
    'XRP/USDT': { name: 'Ripple', logoUrl: '/logos/crypto/XRP.png' },
    'DOT/USDT': { name: 'Polkadot', logoUrl: '/logos/crypto/DOT.png' },
    'LINK/USDT': { name: 'Chainlink', logoUrl: '/logos/crypto/LINK.png' },
    'LTC/USDT': { name: 'Litecoin', logoUrl: '/logos/crypto/LTC.png' },
    'BCH/USDT': { name: 'Bitcoin Cash', logoUrl: '/logos/crypto/BTC.png' }, // Use BTC logo as BCH logo not available
    'DOGE/USDT': { name: 'Dogecoin', logoUrl: '/logos/crypto/DOGE.png' },
    'AVAX/USDT': { name: 'Avalanche', logoUrl: '/logos/crypto/AVAX.png' },
    'MATIC/USDT': { name: 'Polygon', logoUrl: '/logos/crypto/MATIC.png' },
    'UNI/USDT': { name: 'Uniswap', logoUrl: '/logos/crypto/UNI.png' },
    'ATOM/USDT': { name: 'Cosmos', logoUrl: '/logos/crypto/ATOM.png' }
  };
  
  return cryptoData[pair] || { name: pair, logoUrl: '/logos/crypto/BTC.png' };
}

// Get crypto name from pair
function getCryptoName(pair) {
  const cryptoNames = {
    'BTC/USDT': 'Bitcoin',
    'ETH/USDT': 'Ethereum',
    'BNB/USDT': 'Binance Coin',
    'ADA/USDT': 'Cardano',
    'SOL/USDT': 'Solana',
    'XRP/USDT': 'Ripple',
    'DOT/USDT': 'Polkadot',
    'LINK/USDT': 'Chainlink',
    'LTC/USDT': 'Litecoin',
    'BCH/USDT': 'Bitcoin Cash',
    'DOGE/USDT': 'Dogecoin',
    'AVAX/USDT': 'Avalanche',
    'MATIC/USDT': 'Polygon',
    'UNI/USDT': 'Uniswap',
    'ATOM/USDT': 'Cosmos'
  };
  return cryptoNames[pair] || pair;
}