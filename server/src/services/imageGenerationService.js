const { OpenAI } = require('openai');
require('dotenv').config();

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

class ImageGenerationService {
  
  // NEW: Generate beautiful company-themed backgrounds with market sentiment
  async generateTradingBackgroundImage(analysis) {
    try {
      const prompt = this.createCompanyBackgroundPrompt(analysis);

      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: prompt,
        n: 1,
        size: "1024x1024",
        quality: "hd",
        style: "natural"
      });

      const imageUrl = response.data[0].url;
      console.log('Generated company background image URL:', imageUrl);
      return imageUrl;
    } catch (error) {
      console.error('Error generating background image:', error);
      return null;
    }
  }

  createCompanyBackgroundPrompt(analysis) {
    const symbol = analysis.symbol;
    const sentiment = analysis.analysis.sentiment;
    const timeframe = this.formatTimeframe(analysis.timeframe);
    const isBullish = sentiment === 'bullish';
    
    // Get company full names and what they actually do
    const companyInfo = {
      'AAPL': { name: 'Apple Inc.', business: 'iPhone, iPad, Mac technology', logo: 'Apple logo', colors: 'silver, space gray, white' },
      'MSFT': { name: 'Microsoft', business: 'Windows, Office, Azure cloud', logo: 'Microsoft logo', colors: 'blue, white' },
      'GOOGL': { name: 'Alphabet Inc.', business: 'Google search, YouTube, Android', logo: 'Google logo', colors: 'blue, red, yellow, green' },
      'GOOG': { name: 'Alphabet Inc.', business: 'Google search, YouTube, Android', logo: 'Google logo', colors: 'blue, red, yellow, green' },
      'TSLA': { name: 'Tesla', business: 'electric vehicles, sustainable energy', logo: 'Tesla T logo', colors: 'red, white, sleek' },
      'AMZN': { name: 'Amazon', business: 'e-commerce, AWS cloud, delivery', logo: 'Amazon logo with arrow', colors: 'orange, black' },
      'META': { name: 'Meta', business: 'Facebook, Instagram, WhatsApp', logo: 'Meta infinity logo', colors: 'blue, white' },
      'NVDA': { name: 'NVIDIA', business: 'AI chips, gaming graphics', logo: 'NVIDIA eye logo', colors: 'green, black' },
      'NFLX': { name: 'Netflix', business: 'streaming movies and TV shows', logo: 'Netflix N logo', colors: 'red, black' },
      'DIS': { name: 'Disney', business: 'movies, theme parks, streaming', logo: 'Disney castle logo', colors: 'blue, gold, magical' },
      'CRM': { name: 'Salesforce', business: 'cloud CRM, business automation', logo: 'Salesforce cloud logo', colors: 'blue, white' },
      'AMD': { name: 'AMD', business: 'computer processors, gaming chips', logo: 'AMD logo', colors: 'red, black' },
      'INTC': { name: 'Intel', business: 'computer processors, semiconductors', logo: 'Intel logo', colors: 'blue, white' },
      'ORCL': { name: 'Oracle', business: 'database software, enterprise cloud', logo: 'Oracle logo', colors: 'red, white' },
      'ADBE': { name: 'Adobe', business: 'Photoshop, creative software', logo: 'Adobe A logo', colors: 'red, creative' },
      'PYPL': { name: 'PayPal', business: 'digital payments, online transactions', logo: 'PayPal logo', colors: 'blue, white' },
      'UBER': { name: 'Uber', business: 'ride-sharing, food delivery', logo: 'Uber logo', colors: 'black, white' },
      'ZOOM': { name: 'Zoom', business: 'video conferencing, remote work', logo: 'Zoom camera logo', colors: 'blue, white' },
      'SQ': { name: 'Block', business: 'payment processing, Square terminals', logo: 'Square logo', colors: 'black, white' },
      'SPOT': { name: 'Spotify', business: 'music streaming, podcasts', logo: 'Spotify logo', colors: 'green, black' },
      'SHOP': { name: 'Shopify', business: 'e-commerce platforms, online stores', logo: 'Shopify bag logo', colors: 'green, white' }
    };

    const company = companyInfo[symbol] || { name: symbol, business: 'technology services', logo: 'company logo', colors: 'blue, white' };
    const sentimentText = isBullish ? 'BULLISH' : 'BEARISH';
    const sentimentColor = isBullish ? 'green' : 'red';
    
    return `Professional trading background texture themed around ${company.business}. Dark charcoal navy base with ${sentimentColor} accent lighting. Clean space at the top for logo placement. Very subtle semi-transparent elements related to ${company.business} scattered throughout at 20% opacity. Faded ${sentimentColor} candlestick charts and trading graphs at 30% opacity in background. ${isBullish ? 'Subtle upward trending arrows and growth elements' : 'Subtle downward trending arrows and analytical elements'} at 25% opacity. 

Company theme: ${company.colors} color palette with ${company.business} visual elements. All background elements extremely subtle and faded. Large clean areas for content overlay. Vertical format 9:16 ratio. Professional fintech aesthetic with ${sentimentColor} sentiment theming. Photo style background texture. High quality and detailed.`;
  }

  // NEW: Generate smaller accent/icon images for UI elements
  async generateTradingAccentImage(analysis) {
    try {
      const symbol = analysis.symbol;
      const sentiment = analysis.analysis.sentiment;
      const isBullish = sentiment === 'bullish';

      const prompt = `Create a minimal trading accent icon for ${symbol}. 
      
      Style: Modern fintech app icon, ${isBullish ? 'green bullish' : 'red bearish'} theme.
      Design: Simple geometric shapes suggesting ${isBullish ? 'upward growth' : 'downward analysis'}.
      Background: Transparent or dark.
      Size: Small icon suitable for mobile UI.
      
      AVOID: Text, numbers, or complex details.`;

      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: prompt,
        n: 1,
        size: "1024x1024",
        quality: "standard" // Use standard for smaller accent images
      });

      const imageUrl = response.data[0].url;
      console.log('Generated accent image URL:', imageUrl);
      return imageUrl;
    } catch (error) {
      console.error('Error generating accent image:', error);
      return null;
    }
  }

  // Legacy method - keeping for backward compatibility but updating
  async generateTradingTipImage(analysis) {
    // Redirect to background generation for better UX
    return this.generateTradingBackgroundImage(analysis);
  }

  formatTimeframe(timeframe) {
    const timeframes = {
      'short_term': 'Short-term',
      'mid_term': 'Mid-term', 
      'long_term': 'Long-term'
    };
    return timeframes[timeframe] || timeframe;
  }

  // Alternative method for generating signal strength visualization images
  async generateSignalStrengthImage(analysis) {
    try {
      const prompt = `Create a signal strength visualization for ${analysis.symbol}. Dark background with ${analysis.analysis.sentiment === 'bullish' ? 'green' : 'red'} accents. Show: ${analysis.analysis.strength.toFixed(1)}/5 star rating, ${analysis.analysis.confidence.toFixed(0)}% confidence meter, Risk/Reward 1:${analysis.analysis.riskRewardRatio?.toFixed(2) ?? '2.0'}, ${this.formatTimeframe(analysis.timeframe)} timeframe. Professional trading app style.`;

      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: prompt,
        n: 1,
        size: "1024x1024", // Fixed: Using valid DALLE-3 size
        quality: "standard",
        style: "natural"
      });

      return response.data[0].url;
    } catch (error) {
      console.error('Error generating signal strength image:', error);
      throw error;
    }
  }

  // Method for generating technical indicator focused images
  async generateTechnicalIndicatorImage(analysis) {
    try {
      const indicators = analysis.indicators;
      const prompt = `Create a technical analysis dashboard for ${analysis.symbol}. Dark theme with blue accents. Display: RSI ${indicators.rsi?.value?.toFixed(1) ?? 'N/A'}, MACD ${indicators.macd?.valueMACDHist?.toFixed(3) ?? 'N/A'}, Moving averages, Bollinger Bands, ADX ${indicators.adx?.valueADX?.toFixed(1) ?? 'N/A'}. Clean data visualization, professional trading platform design.`;

      const response = await openai.images.generate({
        model: "dall-e-3",
        prompt: prompt,
        n: 1,
        size: "1792x1024", // Fixed: Using valid DALLE-3 wide format
        quality: "standard",
        style: "natural"
      });

      return response.data[0].url;
    } catch (error) {
      console.error('Error generating technical indicator image:', error);
      throw error;
    }
  }
}

module.exports = new ImageGenerationService(); 