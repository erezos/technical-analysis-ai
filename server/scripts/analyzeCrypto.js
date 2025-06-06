/**
 * CRYPTO TECHNICAL ANALYSIS SCRIPT
 * =================================
 * 
 * PURPOSE:
 * Performs AI-powered technical analysis on cryptocurrency pairs with enhanced 
 * crypto-specific features including 24/7 market sentiment, higher precision 
 * pricing (6 decimals), and crypto-themed background generation.
 * 
 * USAGE:
 * node analyzeCrypto.js <symbol> <timeframe>
 * 
 * EXAMPLES:
 * node analyzeCrypto.js BTC/USDT short_term     # Bitcoin 1-hour analysis
 * node analyzeCrypto.js ETH/USDT mid_term       # Ethereum 4-hour analysis
 * node analyzeCrypto.js LINK/USDT long_term     # Chainlink daily analysis
 * 
 * PARAMETERS:
 * - symbol: Crypto pair (BTC/USDT, ETH/USDT, ADA/USDT, etc.)
 * - timeframe: short_term (1h), mid_term (4h), long_term (1d)
 * 
 * FEATURES:
 * ✓ Uses Binance exchange data via TAAPI.io
 * ✓ Higher precision pricing (6 decimal places for crypto)
 * ✓ Crypto-specific volatility thresholds (0.8 vs 2.0 for stocks)
 * ✓ 24/7 market sentiment theming
 * ✓ Generates crypto-themed backgrounds with DeFi aesthetics
 * ✓ Optimized for eToro crypto revenue share
 * ✓ Saves to Firebase with push notifications
 * 
 * TECHNICAL INDICATORS ANALYZED:
 * - RSI (14 period)
 * - MACD with histogram
 * - Bollinger Bands (20 period, 2 stddev)
 * - EMA 50 and EMA 200
 * - ADX (trend strength)
 * - ATR (volatility)
 * 
 * OUTPUT:
 * - Detailed console analysis with crypto-specific formatting
 * - Beautiful crypto-themed background images (if signal strength ≥ 0.8)
 * - Trading levels with 6-decimal precision
 * - Risk/reward ratios optimized for crypto volatility
 * - Firebase storage with push notifications to mobile app
 * 
 * DEPENDENCIES:
 * - TAAPI_API_KEY environment variable
 * - Firebase project configuration
 * - DALL-E 3 API access for image generation
 * - Active crypto logos in public/logos/crypto/
 */
require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');
const tradingTipsService = require('../src/services/tradingTipsServiceOptimized');
const imageGenerationService = require('../src/services/imageGenerationService');
const logoUtils = require('../src/utils/logoUtils');

async function analyzeCrypto(symbol, timeframe) {
  console.log(`\n💎 Analyzing ${symbol} on ${timeframe} timeframe...`);
  console.log('==========================================');

  try {
    // Get crypto technical analysis using Binance exchange
    const analysis = await getCryptoTechnicalAnalysis(symbol, timeframe);
    
    // Print detailed analysis
    console.log('\n📊 Technical Indicators:');
    console.log('----------------------------------------');
    console.log(`RSI: ${analysis.indicators.rsi?.value?.toFixed(2) ?? 'N/A'}`);
    console.log(`MACD Histogram: ${analysis.indicators.macd?.valueMACDHist?.toFixed(4) ?? 'N/A'}`);
    console.log(`EMA50: ${analysis.indicators.ema?.ema50?.value?.toFixed(6) ?? 'N/A'}`);
    console.log(`EMA200: ${analysis.indicators.ema?.ema200?.value?.toFixed(6) ?? 'N/A'}`);
    console.log(`Bollinger Bands:`);
    console.log(`  Upper: ${analysis.indicators.bbands?.valueUpperBand?.toFixed(6) ?? 'N/A'}`);
    console.log(`  Middle: ${analysis.indicators.bbands?.valueMiddleBand?.toFixed(6) ?? 'N/A'}`);
    console.log(`  Lower: ${analysis.indicators.bbands?.valueLowerBand?.toFixed(6) ?? 'N/A'}`);
    console.log(`ADX: ${analysis.indicators.adx?.value?.toFixed(2) ?? 'N/A'}`);
    console.log(`ATR: ${analysis.indicators.atr?.value?.toFixed(6) ?? 'N/A'}`);
    
    console.log('\n🔍 Analysis:');
    console.log('----------------------------------------');
    console.log(`Sentiment: ${analysis.analysis.sentiment}`);
    console.log(`Strength: ${analysis.analysis.strength.toFixed(2)}`);
    console.log(`Confidence: ${analysis.analysis.confidence.toFixed(1)}%`);
    
    console.log('\n🧠 Reasoning:');
    analysis.analysis.reasoning.forEach((reason, index) => {
      console.log(`${index + 1}. ${reason}`);
    });
    
    console.log('\n💰 Trading Levels:');
    console.log('----------------------------------------');
    console.log(`Entry Price: $${analysis.analysis.entryPrice?.toFixed(6) ?? 'N/A'}`);
    console.log(`Stop Loss: $${analysis.analysis.stopLoss?.toFixed(6) ?? 'N/A'}`);
    console.log(`Take Profit: $${analysis.analysis.takeProfit?.toFixed(6) ?? 'N/A'}`);
    console.log(`Risk/Reward: 1:${analysis.analysis.riskRewardRatio?.toFixed(2) ?? 'N/A'}`);
    
    // Check if signal is strong enough to save (lower threshold for crypto volatility)
    if (Math.abs(analysis.analysis.strength) >= 0.8) {
      console.log('\n🚀 Strong crypto signal detected! Generating beautiful crypto-themed backgrounds...');
      
      // Generate crypto-specific background with market sentiment
      console.log('🎨 Generating crypto background with market sentiment...');
      const backgroundUrl = await generateCryptoBackgroundImage(analysis);
      console.log('✅ Crypto Background URL:', backgroundUrl);

      // Generate trading accent/icon for UI elements
      console.log('🔸 Generating crypto accent icon...');
      const accentUrl = await generateCryptoAccentImage(analysis);
      console.log('✅ Accent Icon URL:', accentUrl);

      // Save trading tip with beautiful backgrounds (app will overlay precise data)
      console.log('💾 Saving crypto trading tip with background images...');
      
      // Get crypto information with robust logo fallback
      const crypto = logoUtils.getCryptoCompanyInfo(symbol);
      console.log(`💎 Crypto: ${crypto.name} | Logo: ${crypto.logoUrl.includes('data:') ? 'DEFAULT FALLBACK' : 'LOCAL FILE'}`);

      const tipData = {
        symbol: analysis.symbol,
        timeframe: analysis.timeframe,
        sentiment: analysis.analysis.sentiment,
        entryPrice: analysis.analysis.entryPrice,
        stopLoss: analysis.analysis.stopLoss,
        takeProfit: analysis.analysis.takeProfit,
        riskRewardRatio: analysis.analysis.riskRewardRatio,
        strength: analysis.analysis.strength,
        confidence: analysis.analysis.confidence,
        reasoning: analysis.analysis.reasoning,
        indicators: analysis.indicators,
        // Crypto information with robust logo fallback
        company: crypto,
        metadata: {
          generatedAt: new Date().toISOString(),
          strategy: 'crypto_backgrounds_v1',
          exchange: 'binance',
          assetType: 'crypto'
        }
      };

      // Save images with crypto naming scheme
      await tradingTipsService.saveBackgroundImages(tipData, backgroundUrl, accentUrl);
      console.log('✅ Crypto trading tip saved successfully with themed backgrounds!');
      
      console.log('\n📱 Crypto App Benefits:');
      console.log('✓ Beautiful crypto-specific backgrounds');
      console.log('✓ 24/7 market sentiment theming');
      console.log('✓ Higher precision pricing (6 decimals)');
      console.log('✓ Crypto volatility optimized thresholds');
      console.log('✓ Enhanced DeFi user engagement');
      console.log('✓ Perfect for eToro crypto revenue share');
      
    } else {
      console.log(`\n⚠️  Signal strength ${analysis.analysis.strength.toFixed(2)} is below crypto threshold (0.8). Skipping image generation.`);
      console.log('💡 Crypto markets are more volatile - consider lowering threshold or trying different timeframe');
    }

  } catch (error) {
    console.error('❌ Error analyzing crypto symbol:', error);
  }
}

async function getCryptoTechnicalAnalysis(symbol, timeframe) {
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

  // Generate analysis using the same method as technicalAnalysisService but with crypto adjustments
  const analysis = generateCryptoAnalysis(symbol, indicators, currentPrice, timeframe);

  return {
    symbol,
    timeframe,
    indicators,
    analysis,
    currentPrice,
    timestamp: new Date().toISOString()
  };
}

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

  // Initialize signal counters
  let bullishSignals = 0;
  let bearishSignals = 0;
  let totalSignals = 0;

  // 1. Crypto-optimized RSI Analysis (more extreme thresholds)
  if (indicators.rsi?.value) {
    const rsi = indicators.rsi.value;
    totalSignals++;
    
    if (rsi < 20) {
      bullishSignals += 2; // Strong oversold in crypto
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) extremely oversold - strong crypto buy signal`);
    } else if (rsi < 30) {
      bullishSignals += 1;
      analysis.reasoning.push(`RSI (${rsi.toFixed(1)}) oversold - crypto buy signal`);
    } else if (rsi > 80) {
      bearishSignals += 2; // Strong overbought in crypto
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
  analysis.stopLoss = analysis.sentiment === 'bullish' ? currentPrice - (atr * 2.5) : currentPrice + (atr * 2.5);
  analysis.takeProfit = analysis.sentiment === 'bullish' ? currentPrice + (atr * 4) : currentPrice - (atr * 4);
  analysis.riskRewardRatio = Math.abs(analysis.takeProfit - analysis.entryPrice) / Math.abs(analysis.entryPrice - analysis.stopLoss);
  analysis.tradingAction = Math.abs(analysis.strength) >= 0.8 ? (analysis.sentiment === 'bullish' ? 'buy' : 'sell') : 'hold';

  return analysis;
}

async function generateCryptoBackgroundImage(analysis) {
  try {
    const prompt = createCryptoBackgroundPrompt(analysis);
    
    // Use the imageGenerationService's OpenAI instance properly
    const { OpenAI } = require('openai');
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const response = await openai.images.generate({
      model: "dall-e-3",
      prompt: prompt,
      n: 1,
      size: "1024x1024",
      quality: "hd",
      style: "natural"
    });

    return response.data[0].url;
  } catch (error) {
    console.error('Error generating crypto background image:', error);
    return null;
  }
}

function createCryptoBackgroundPrompt(analysis) {
  const symbol = analysis.symbol;
  const sentiment = analysis.analysis.sentiment;
  const timeframe = formatTimeframe(analysis.timeframe);
  const isBullish = sentiment === 'bullish';
  
  // Detailed crypto information with logos and simplified descriptions
  const cryptoInfo = {
    'BTC/USDT': { name: 'Bitcoin', business: 'digital gold, store of value', logo: '₿ Bitcoin logo', colors: 'orange, gold, black' },
    'ETH/USDT': { name: 'Ethereum', business: 'smart contracts, DeFi, NFTs', logo: 'Ξ Ethereum diamond logo', colors: 'blue, purple, silver' },
    'BNB/USDT': { name: 'Binance Coin', business: 'exchange token, trading fees', logo: 'BNB Binance logo', colors: 'yellow, gold, black' },
    'ADA/USDT': { name: 'Cardano', business: 'proof-of-stake blockchain', logo: 'ADA Cardano logo', colors: 'blue, white, green' },
    'SOL/USDT': { name: 'Solana', business: 'high-speed blockchain, DeFi', logo: 'SOL Solana logo', colors: 'purple, blue, gradient' },
    'XRP/USDT': { name: 'Ripple', business: 'cross-border payments', logo: 'XRP Ripple logo', colors: 'blue, white, silver' },
    'DOT/USDT': { name: 'Polkadot', business: 'interoperability, parachains', logo: 'DOT Polkadot logo', colors: 'pink, purple, black' },
    'LINK/USDT': { name: 'Chainlink', business: 'oracle network, real-world data', logo: 'LINK Chainlink logo', colors: 'blue, white' },
    'AVAX/USDT': { name: 'Avalanche', business: 'DeFi platform, subnets', logo: 'AVAX Avalanche logo', colors: 'red, white' },
    'MATIC/USDT': { name: 'Polygon', business: 'Layer-2 scaling, sidechains', logo: 'MATIC Polygon logo', colors: 'purple, blue' },
    'LTC/USDT': { name: 'Litecoin', business: 'digital silver, fast payments', logo: 'Ł Litecoin logo', colors: 'silver, gray, blue' },
    'ATOM/USDT': { name: 'Cosmos', business: 'internet of blockchains', logo: 'ATOM Cosmos logo', colors: 'purple, blue' },
    'ALGO/USDT': { name: 'Algorand', business: 'pure proof-of-stake', logo: 'ALGO Algorand logo', colors: 'black, white' },
    'VET/USDT': { name: 'VeChain', business: 'supply chain verification', logo: 'VET VeChain logo', colors: 'blue, white' },
    'FIL/USDT': { name: 'Filecoin', business: 'decentralized storage', logo: 'FIL Filecoin logo', colors: 'blue, white' },
    'TRX/USDT': { name: 'TRON', business: 'content entertainment', logo: 'TRX TRON logo', colors: 'red, black' }
  };

  const crypto = cryptoInfo[symbol] || { name: symbol, business: 'blockchain technology', logo: 'crypto logo', colors: 'blue, white' };
  const sentimentText = isBullish ? 'BULLISH' : 'BEARISH';
  const sentimentColor = isBullish ? 'green' : 'red';
  
  return `Professional crypto trading background texture themed around ${crypto.business}. Dark navy charcoal base with ${sentimentColor} accent lighting. Clean space at the top for logo placement. Very subtle semi-transparent elements related to ${crypto.business} scattered throughout at 20% opacity. Faded ${sentimentColor} cryptocurrency candlestick charts and trading graphs at 30% opacity in background. ${isBullish ? 'Subtle upward trending arrows and small rockets' : 'Subtle downward trending arrows'} at 25% opacity. Faded blockchain nodes and ${crypto.business} icons at 15% opacity. Very subtle blockchain network connections at 10% opacity.

Crypto theme: ${crypto.colors} color palette with ${crypto.business} visual elements. All background elements extremely subtle and faded. Large clean areas for content overlay. Vertical format 9:16 ratio. Professional crypto DeFi aesthetic with ${sentimentColor} sentiment theming. 24/7 crypto market energy. Photo style background texture. High quality and detailed.`;
}

async function generateCryptoAccentImage(analysis) {
  try {
    const symbol = analysis.symbol;
    const sentiment = analysis.analysis.sentiment;
    const isBullish = sentiment === 'bullish';

    const prompt = `Create a minimal crypto trading accent icon for ${symbol}. 
    
    Style: Modern crypto/DeFi app icon, ${isBullish ? 'green bullish' : 'red bearish'} neon theme.
    Design: Simple geometric blockchain elements suggesting ${isBullish ? 'upward growth and prosperity' : 'downward analysis and caution'}.
    Background: Transparent or dark with subtle hex pattern.
    Size: Small icon suitable for mobile crypto UI.
    Elements: Subtle blockchain network nodes or crypto symbols.
    
    AVOID: Text, numbers, or complex details.`;

    // Use the same OpenAI setup as the background function
    const { OpenAI } = require('openai');
    const openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });

    const response = await openai.images.generate({
      model: "dall-e-3",
      prompt: prompt,
      n: 1,
      size: "1024x1024",
      quality: "standard"
    });

    return response.data[0].url;
  } catch (error) {
    console.error('Error generating crypto accent image:', error);
    return null;
  }
}

function formatTimeframe(timeframe) {
  const timeframes = {
    'short_term': 'Short-term (1h)',
    'mid_term': 'Mid-term (4h)', 
    'long_term': 'Long-term (1d)'
  };
  return timeframes[timeframe] || timeframe;
}

function getCryptoName(symbol) {
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

// Get command line arguments
const symbol = process.argv[2];
const timeframe = process.argv[3];

if (!symbol || !timeframe) {
  console.log('📋 Usage: node analyzeCrypto.js <crypto_pair> <timeframe>');
  console.log('   Examples:');
  console.log('     node analyzeCrypto.js BTC/USDT short_term     # Bitcoin 1h analysis');
  console.log('     node analyzeCrypto.js ETH/USDT mid_term       # Ethereum 4h analysis');
  console.log('     node analyzeCrypto.js SOL/USDT long_term      # Solana 1d analysis');
  console.log('');
  console.log('📝 Supported Crypto Pairs:');
  console.log('   BTC/USDT, ETH/USDT, BNB/USDT, ADA/USDT, SOL/USDT, XRP/USDT');
  console.log('   DOT/USDT, LINK/USDT, AVAX/USDT, MATIC/USDT, LTC/USDT, ATOM/USDT');
  console.log('   ALGO/USDT, VET/USDT, FIL/USDT, TRX/USDT');
  console.log('');
  console.log('🎯 Features:');
  console.log('   • Binance exchange data for accurate crypto analysis');
  console.log('   • Crypto-optimized RSI thresholds (20/80 vs stocks 30/70)');
  console.log('   • Lower signal threshold (0.8 vs stocks 2.0) for crypto volatility');
  console.log('   • 6-decimal precision pricing for crypto accuracy');
  console.log('   • 24/7 market analysis - perfect for global crypto trading');
  console.log('   • Enhanced backgrounds for eToro crypto revenue share');
  process.exit(1);
}

analyzeCrypto(symbol, timeframe); 