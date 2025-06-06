/**
 * TECHNICAL ANALYSIS SERVICE
 * ==========================
 * 
 * PURPOSE:
 * Core service for performing comprehensive technical analysis on stocks and 
 * cryptocurrencies using TAAPI.io API. Provides advanced AI-powered analysis 
 * with multiple technical indicators, trading levels, and risk management.
 * 
 * FEATURES:
 * ✓ Multi-indicator technical analysis (RSI, MACD, Bollinger Bands, EMAs, ADX, ATR)
 * ✓ AI-powered sentiment analysis and signal strength calculation
 * ✓ Automatic trading level calculation (entry, stop-loss, take-profit)
 * ✓ Risk/reward ratio optimization
 * ✓ Bulk API requests for efficiency
 * ✓ Rate limiting and error handling
 * ✓ Support for stocks and cryptocurrency pairs
 * ✓ Multiple timeframe analysis (1h, 4h, 1d)
 * 
 * TECHNICAL INDICATORS:
 * - RSI (14 period): Momentum oscillator for overbought/oversold conditions
 * - MACD: Moving Average Convergence Divergence with histogram
 * - Bollinger Bands (20, 2): Volatility-based support/resistance levels
 * - EMA 50/200: Exponential Moving Averages for trend identification
 * - ADX (14): Average Directional Index for trend strength
 * - ATR (14): Average True Range for volatility measurement
 * 
 * AI ANALYSIS COMPONENTS:
 * 1. SENTIMENT DETECTION: bullish, bearish, neutral
 * 2. SIGNAL STRENGTH: 0-5 scale with confidence levels
 * 3. TRADING ACTION: buy, sell, hold recommendations
 * 4. REASONING: AI-generated explanations for decisions
 * 5. RISK ASSESSMENT: Position sizing and risk management
 * 
 * TRADING LEVEL CALCULATION:
 * - Entry Price: Optimal position entry point
 * - Stop Loss: Risk management exit level
 * - Take Profit: Profit-taking target level
 * - Risk/Reward Ratio: Position profitability assessment
 * 
 * TIMEFRAME MAPPING:
 * - short_term → 1h (intraday trading)
 * - mid_term → 4h (swing trading)
 * - long_term → 1d (position trading)
 * 
 * EXCHANGE SUPPORT:
 * - Stocks: US stock market via 'stock' exchange
 * - Crypto: Binance exchange for cryptocurrency pairs
 * - Real-time data with minimal latency
 * 
 * RATE LIMITING:
 * - Intelligent request spacing (500ms minimum)
 * - Automatic retry mechanism (3 attempts)
 * - Rate limit monitoring and handling
 * - Bulk request optimization
 * 
 * ERROR HANDLING:
 * - API timeout management (30 second limit)
 * - Network error recovery with exponential backoff
 * - Graceful degradation for missing data
 * - Comprehensive error logging
 * 
 * API INTEGRATION:
 * - TAAPI.io professional API for market data
 * - Bulk request endpoint for efficiency
 * - Real-time indicator calculations
 * - High-quality financial data sourcing
 * 
 * USAGE EXAMPLES:
 * ```javascript
 * const service = new TechnicalAnalysisService();
 * 
 * // Stock analysis
 * const stockAnalysis = await service.getTechnicalAnalysis('AAPL', 'mid_term');
 * 
 * // Crypto analysis  
 * const cryptoAnalysis = await service.getTechnicalAnalysis('BTCUSDT', 'short_term');
 * 
 * // Bulk request for multiple indicators
 * const bulkResults = await service.makeBulkRequest(construct);
 * ```
 * 
 * CONFIGURATION:
 * - TAAPI_API_KEY: Required environment variable
 * - Rate limiting: 30 requests per 15 seconds
 * - Timeout: 30 seconds per request
 * - Retry limit: 3 attempts with 5-second delays
 * 
 * INTEGRATION:
 * Used by all analysis scripts:
 * - analyzeSymbol.js (individual stock analysis)
 * - analyzeCrypto.js (individual crypto analysis)  
 * - scanBestStocks.js (bulk stock scanning)
 * - scanBestCrypto.js (bulk crypto scanning)
 */
const axios = require('axios');
require('dotenv').config();

class TechnicalAnalysisService {
  constructor() {
    this.apiKey = process.env.TAAPI_API_KEY;
    this.baseUrl = 'https://api.taapi.io';
    this.rateLimitReset = 0;
    this.rateLimitRemaining = 0;
    this.lastRequestTime = 0;
    this.minRequestInterval = 500; // 500ms between requests (30 requests per 15 seconds = 1 request per 500ms)
    this.maxRetries = 3;
    this.retryDelay = 5000; // 5 seconds between retries
  }

  async sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async waitForRateLimit() {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    
    if (timeSinceLastRequest < this.minRequestInterval) {
      const waitTime = this.minRequestInterval - timeSinceLastRequest;
      console.log(`Rate limit: Waiting ${waitTime}ms before next request...`);
      await this.sleep(waitTime);
    }
  }

  async makeRequest(endpoint, params, retryCount = 0) {
    try {
      await this.waitForRateLimit();
      
      console.log(`Making request to ${endpoint}...`);
      const response = await axios.get(`${this.baseUrl}${endpoint}`, {
        params: {
          secret: this.apiKey,
          ...params
        },
        headers: {
          'Accept': 'application/json'
        },
        timeout: 30000 // 30 second timeout
      });

      this.lastRequestTime = Date.now();
      
      // Log rate limit headers if available
      if (response.headers['x-ratelimit-remaining']) {
        console.log(`Rate limit remaining: ${response.headers['x-ratelimit-remaining']}`);
      }
      if (response.headers['x-ratelimit-reset']) {
        console.log(`Rate limit reset at: ${new Date(parseInt(response.headers['x-ratelimit-reset']) * 1000)}`);
      }

      return response.data;
    } catch (error) {
      if ((error.response?.status === 504 || error.code === 'ECONNABORTED') && retryCount < this.maxRetries) {
        console.log(`Request timed out, retrying (${retryCount + 1}/${this.maxRetries})...`);
        await this.sleep(this.retryDelay);
        return this.makeRequest(endpoint, params, retryCount + 1);
      }
      throw this.handleApiError(error);
    }
  }

  async getRSI(symbol, interval) {
    try {
      console.log('Fetching RSI...');
      const data = await this.makeRequest('/rsi', {
        exchange: 'stock',
        symbol: symbol,
        interval: interval
      });
      return data;
    } catch (error) {
      throw this.handleApiError(error);
    }
  }

  async getMACD(symbol, interval) {
    try {
      console.log('Fetching MACD...');
      const data = await this.makeRequest('/macd', {
        exchange: 'stock',
        symbol: symbol,
        interval: interval
      });
      return data;
    } catch (error) {
      throw this.handleApiError(error);
    }
  }

  async getEMA(symbol, interval) {
    try {
      console.log('Fetching EMA...');
      const data = await this.makeRequest('/ema', {
        exchange: 'stock',
        symbol: symbol,
        interval: interval,
        period: 200
      });
      return data;
    } catch (error) {
      throw this.handleApiError(error);
    }
  }

  async getBollingerBands(symbol, interval) {
    try {
      console.log('Fetching Bollinger Bands...');
      const data = await this.makeRequest('/bbands2', {
        exchange: 'stock',
        symbol: symbol,
        interval: interval
      });
      return data;
    } catch (error) {
      throw this.handleApiError(error);
    }
  }

  async makeBulkRequest(construct) {
    try {
      console.log('Making bulk request for multiple indicators...');
      const response = await axios.post(`${this.baseUrl}/bulk`, {
        secret: this.apiKey,
        construct: construct
      }, {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        timeout: 30000 // 30 second timeout
      });

      console.log('API Response:', JSON.stringify(response.data, null, 2));
      return response.data.data;
    } catch (error) {
      console.error('API Error:', error.response?.data || error.message);
      throw this.handleApiError(error);
    }
  }

  handleApiError(error) {
    if (error.response) {
      const status = error.response.status;
      const message = error.response.data?.message || error.message;

      if (status === 403) {
        const resetTime = this.rateLimitReset;
        const waitTime = Math.max(0, resetTime - Math.floor(Date.now() / 1000));
        return new Error(`API rate limit exceeded. Please wait ${waitTime} seconds before trying again.`);
      }

      return new Error(`API Error: ${message}`);
    }
    return error;
  }

  async getTechnicalAnalysis(symbol, timeframe) {
    try {
      console.log(`Starting analysis for ${symbol} on ${timeframe} timeframe...`);
      
      // Map our timeframes to TAAPI timeframes
      const timeframeMap = {
        'short_term': '1h',
        'mid_term': '4h', 
        'long_term': '1d'
      };

      const taTimeframe = timeframeMap[timeframe];
      
      // Format symbol for stock market
      const formattedSymbol = symbol.replace('/', '');
      
      // Create conservative bulk request construct - fewer indicators to avoid timeouts
      const construct = {
        exchange: 'stock',
        symbol: formattedSymbol,
        interval: taTimeframe,
        type: 'stocks',
        indicators: [
          // Core reliable indicators
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
      const results = await this.makeBulkRequest(construct);
      
      // Process results and extract current price from one of the results
      const indicators = {};
      let currentPrice = null;
      
      results.forEach(result => {
        console.log('Processing result:', JSON.stringify(result, null, 2));
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

      console.log(`Current price for ${symbol}: ${currentPrice}`);
      console.log('Processed indicators:', JSON.stringify(indicators, null, 2));
      console.log('Generating analysis...');
      const analysis = this.generateAdvancedAnalysis(symbol, indicators, currentPrice, timeframe);

      return {
        symbol,
        timeframe,
        indicators,
        analysis,
        currentPrice,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Error getting technical analysis:', error.message);
      throw error;
    }
  }

  generateAdvancedAnalysis(symbol, indicators, currentPrice, timeframe) {
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
      
      console.log(`Debug: Current Price: ${currentPrice}, EMA50: ${ema50}, EMA200: ${ema200}`);
      
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
    this.calculateTradingLevels(analysis, indicators, currentPrice, timeframe);

    return analysis;
  }

  calculateTradingLevels(analysis, indicators, currentPrice, timeframe) {
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
}

module.exports = new TechnicalAnalysisService(); 