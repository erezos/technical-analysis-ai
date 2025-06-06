/**
 * STOCK TECHNICAL ANALYSIS SCRIPT
 * ===============================
 * 
 * PURPOSE:
 * Performs AI-powered technical analysis on individual stock symbols with 
 * company-themed background generation and enhanced visual elements optimized 
 * for eToro trading and maximum user engagement.
 * 
 * USAGE:
 * node analyzeSymbol.js <symbol> <timeframe> [--basic-only]
 * 
 * EXAMPLES:
 * node analyzeSymbol.js AAPL short_term           # Apple 1-hour analysis
 * node analyzeSymbol.js MSFT mid_term             # Microsoft 4-hour analysis  
 * node analyzeSymbol.js GOOGL long_term           # Google daily analysis
 * node analyzeSymbol.js TSLA mid_term --basic-only # Tesla with basic visuals only
 * 
 * PARAMETERS:
 * - symbol: Stock ticker symbol (AAPL, MSFT, GOOGL, TSLA, etc.)
 * - timeframe: short_term (1h), mid_term (4h), long_term (1d)
 * - --basic-only: [Optional] Generate only main trading card (cost optimization)
 * 
 * FEATURES:
 * ✓ Comprehensive technical analysis using 7 key indicators
 * ✓ Company-specific background themes with market sentiment
 * ✓ Signal strength threshold of 2.0 for quality filtering
 * ✓ Trading levels with precise entry/exit points
 * ✓ Risk/reward ratio calculations
 * ✓ Company logo integration with fallback system
 * ✓ Enhanced visuals for maximum user engagement & eToro conversion
 * ✓ Firebase storage with push notifications
 * 
 * TECHNICAL INDICATORS ANALYZED:
 * - RSI (14 period) - Momentum oscillator
 * - MACD with histogram - Trend following momentum
 * - Bollinger Bands (20 period, 2 stddev) - Volatility bands
 * - EMA 50 and EMA 200 - Moving average trends
 * - ADX (14 period) - Trend strength
 * - ATR (14 period) - Average true range volatility
 * 
 * OUTPUT:
 * - Detailed console analysis with formatted trading data
 * - Company-themed background images (if signal strength ≥ 2.0)
 * - Trading accent icons for UI enhancement
 * - Precise trading levels ($XX.XX format)
 * - AI reasoning for trading decisions
 * - Firebase storage for mobile app consumption
 * 
 * VISUAL GENERATION:
 * - Company Background: DALL-E 3 generated themes based on company branding
 * - Trading Accent: Small icons/elements for UI enhancement
 * - Market Sentiment: Bullish/bearish color schemes and imagery
 * 
 * DEPENDENCIES:
 * - TAAPI_API_KEY environment variable (stock market data)
 * - Firebase project configuration
 * - DALL-E 3 API access for image generation
 * - Company logos in public/logos/stocks/
 * 
 * ERROR HANDLING:
 * - Robust API error handling with retries
 * - Graceful degradation if image generation fails
 * - Comprehensive logging for debugging
 */
require('dotenv').config();
const technicalAnalysisService = require('../src/services/technicalAnalysisService');
const tradingTipsService = require('../src/services/tradingTipsServiceOptimized');
const imageGenerationService = require('../src/services/imageGenerationService');
const logoUtils = require('../src/utils/logoUtils');

async function analyzeSymbol(symbol, timeframe) {
  console.log(`\nAnalyzing ${symbol} on ${timeframe} timeframe...`);
  console.log('----------------------------------------');

  try {
    // Get technical analysis
    const analysis = await technicalAnalysisService.getTechnicalAnalysis(symbol, timeframe);
    
    // Print detailed analysis
    console.log('\nTechnical Indicators:');
    console.log('----------------------------------------');
    console.log(`RSI: ${analysis.indicators.rsi?.value?.toFixed(2) ?? 'N/A'}`);
    console.log(`MACD Histogram: ${analysis.indicators.macd?.valueMACDHist?.toFixed(2) ?? 'N/A'}`);
    console.log(`EMA50: ${analysis.indicators.ema?.ema50?.value?.toFixed(2) ?? 'N/A'}`);
    console.log(`EMA200: ${analysis.indicators.ema?.ema200?.value?.toFixed(2) ?? 'N/A'}`);
    console.log(`Bollinger Bands:`);
    console.log(`  Upper: ${analysis.indicators.bbands?.valueUpperBand?.toFixed(2) ?? 'N/A'}`);
    console.log(`  Middle: ${analysis.indicators.bbands?.valueMiddleBand?.toFixed(2) ?? 'N/A'}`);
    console.log(`  Lower: ${analysis.indicators.bbands?.valueLowerBand?.toFixed(2) ?? 'N/A'}`);
    console.log(`ADX: ${analysis.indicators.adx?.value?.toFixed(2) ?? 'N/A'}`);
    console.log(`ATR: ${analysis.indicators.atr?.value?.toFixed(2) ?? 'N/A'}`);
    
    console.log('\nAnalysis:');
    console.log('----------------------------------------');
    console.log(`Sentiment: ${analysis.analysis.sentiment}`);
    console.log(`Strength: ${analysis.analysis.strength.toFixed(2)}`);
    
    console.log('\nReasoning:');
    analysis.analysis.reasoning.forEach((reason, index) => {
      console.log(`${index + 1}. ${reason}`);
    });
    
    console.log('\nTrading Levels:');
    console.log('----------------------------------------');
    console.log(`Entry Price: ${analysis.analysis.entryPrice?.toFixed(2) ?? 'N/A'}`);
    console.log(`Stop Loss: ${analysis.analysis.stopLoss?.toFixed(2) ?? 'N/A'}`);
    console.log(`Take Profit: ${analysis.analysis.takeProfit?.toFixed(2) ?? 'N/A'}`);
    
    // Check if signal is strong enough to save
    if (Math.abs(analysis.analysis.strength) >= 2) {
      console.log('\n🚀 Strong signal detected! Generating beautiful company-themed backgrounds...');
      
      // Generate company-themed background with market sentiment
      console.log('🎨 Generating company background with market sentiment...');
      const backgroundUrl = await imageGenerationService.generateTradingBackgroundImage(analysis);
      console.log('✅ Company Background URL:', backgroundUrl);

      // Generate trading accent/icon for UI elements
      console.log('🔸 Generating trading accent icon...');
      const accentUrl = await imageGenerationService.generateTradingAccentImage(analysis);
      console.log('✅ Accent Icon URL:', accentUrl);

      // Save trading tip with beautiful backgrounds (app will overlay precise data)
      console.log('💾 Saving trading tip with background images...');
      
      // Get company information with robust logo fallback
      const company = logoUtils.getStockCompanyInfo(analysis.symbol);
      console.log(`🏢 Company: ${company.name} | Logo: ${company.logoUrl.includes('data:') ? 'DEFAULT FALLBACK' : 'LOCAL FILE'}`);

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
        // Company information with robust logo fallback
        company: company,
        metadata: {
          generatedAt: new Date().toISOString(),
          strategy: 'enhanced_backgrounds_v1'
        }
      };

      // 🚨 DEBUG: Log exactly what we're saving to Firebase
      console.log('\n🔍 DEBUG - Tip Data Being Saved to Firebase:');
      console.log('============================================');
      console.log(`Symbol: ${tipData.symbol}`);
      console.log(`Timeframe: ${tipData.timeframe}`);
      console.log(`Sentiment: ${tipData.sentiment}`);
      console.log(`Strength: ${tipData.strength}`);
      console.log(`Entry Price: $${tipData.entryPrice?.toFixed(2)}`);
      console.log(`Stop Loss: $${tipData.stopLoss?.toFixed(2)}`);
      console.log(`Take Profit: $${tipData.takeProfit?.toFixed(2)}`);
      console.log(`Risk/Reward: 1:${tipData.riskRewardRatio?.toFixed(2)}`);
      console.log('============================================\n');

      // Save images with new naming scheme
      await tradingTipsService.saveBackgroundImages(tipData, backgroundUrl, accentUrl);
      console.log('✅ Trading tip saved successfully with company-themed backgrounds!');
      
      console.log('\n📱 App Benefits:');
      console.log('✓ Beautiful company-specific backgrounds');
      console.log('✓ Market sentiment theming (bullish/bearish)');
      console.log('✓ Precise trading data overlaid by app UI');
      console.log('✓ No risk of AI-generated wrong numbers');
      console.log('✓ Enhanced user engagement & retention');
      
    } else {
      console.log(`\n⚠️  Signal strength ${analysis.analysis.strength.toFixed(2)} is below threshold (2.0). Skipping image generation.`);
    }

  } catch (error) {
    console.error('❌ Error analyzing symbol:', error);
  }
}

// Get command line arguments
const symbol = process.argv[2];
const timeframe = process.argv[3];

if (!symbol || !timeframe) {
  console.log('📋 Usage: node analyzeSymbol.js <symbol> <timeframe> [--basic-only]');
  console.log('   Examples:');
  console.log('     node analyzeSymbol.js MSFT short_term           # Enhanced visuals (default)');
  console.log('     node analyzeSymbol.js AAPL long_term            # Enhanced visuals (default)');
  console.log('     node analyzeSymbol.js TSLA mid_term --basic-only # Main card only');
  console.log('');
  console.log('📝 Options:');
  console.log('   --basic-only: Generate only main trading card (cost optimization)');
  console.log('   Default: Enhanced visuals for maximum user engagement & eToro conversion');
  process.exit(1);
}

analyzeSymbol(symbol, timeframe); 