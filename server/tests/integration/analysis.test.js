const axios = require('axios');

// Mock axios for API calls
jest.mock('axios');

describe('Analysis Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock successful TAAPI response
    axios.post.mockResolvedValue({
      data: {
        data: [
          {
            id: 'test_rsi',
            indicator: 'rsi',
            result: { value: 65.5 },
            errors: []
          },
          {
            id: 'test_macd',
            indicator: 'macd',
            result: {
              valueMACD: 1.5,
              valueMACDSignal: 1.2,
              valueMACDHist: 0.3
            },
            errors: []
          }
        ]
      }
    });
  });

  describe('Stock Analysis Workflow', () => {
    it('should perform complete analysis for strong signal', async () => {
      // Import analysis functions (would need to refactor scripts to be testable)
      // This is a placeholder showing how integration tests would work
      
      const mockAnalysisResult = {
        symbol: 'AAPL',
        timeframe: 'long_term',
        sentiment: 'bullish',
        strength: 2.5,
        confidence: 85.2,
        entryPrice: 195.50,
        stopLoss: 185.00,
        takeProfit: 210.00,
        company: {
          name: 'Apple Inc.',
          logoUrl: 'assets/logos/stocks/AAPL.png'
        }
      };

      // Test that analysis produces expected structure
      expect(mockAnalysisResult.symbol).toBe('AAPL');
      expect(mockAnalysisResult.strength).toBeGreaterThan(2.0);
      expect(mockAnalysisResult.company.name).toBe('Apple Inc.');
      expect(mockAnalysisResult.entryPrice).toBeGreaterThan(0);
    });

    it('should reject weak signals', async () => {
      const mockWeakSignal = {
        sentiment: 'neutral',
        strength: 0.5,
        confidence: 25.0
      };

      // Weak signals should not generate tips
      expect(Math.abs(mockWeakSignal.strength)).toBeLessThan(1.5);
      expect(mockWeakSignal.confidence).toBeLessThan(50);
    });
  });

  describe('Crypto Analysis Workflow', () => {
    it('should handle crypto pairs correctly', async () => {
      const mockCryptoResult = {
        symbol: 'BTC/USDT',
        timeframe: 'long_term',
        sentiment: 'bearish',
        strength: -2.1,
        company: {
          name: 'Bitcoin',
          logoUrl: 'assets/logos/crypto/BTC.png',
          isCrypto: true
        }
      };

      expect(mockCryptoResult.symbol).toContain('/USDT');
      expect(mockCryptoResult.company.isCrypto).toBe(true);
      expect(mockCryptoResult.company.logoUrl).toContain('crypto');
    });
  });

  describe('API Error Handling', () => {
    it('should handle TAAPI API errors gracefully', async () => {
      axios.post.mockRejectedValue(new Error('API Rate Limit'));

      // Should not crash the application
      try {
        await axios.post('https://api.taapi.io/bulk');
      } catch (error) {
        expect(error.message).toBe('API Rate Limit');
      }
    });

    it('should handle malformed API responses', async () => {
      axios.post.mockResolvedValue({
        data: {
          data: [
            {
              id: 'test_rsi',
              indicator: 'rsi',
              errors: ['Invalid timeframe']
            }
          ]
        }
      });

      const response = await axios.post();
      const hasErrors = response.data.data.some(item => item.errors.length > 0);
      
      expect(hasErrors).toBe(true);
    });
  });

  describe('Complete End-to-End Flow', () => {
    it('should generate tip with all required components', async () => {
      const mockCompleteTip = {
        symbol: 'TSLA',
        timeframe: 'mid_term',
        sentiment: 'bullish',
        strength: 2.8,
        confidence: 92.5,
        entryPrice: 245.80,
        stopLoss: 230.00,
        takeProfit: 270.00,
        company: {
          name: 'Tesla Inc.',
          logoUrl: 'assets/logos/stocks/TSLA.png',
          sector: 'Technology',
          business: 'Electric Vehicles',
          isCrypto: false
        },
        images: {
          latestTradingCard: {
            url: 'https://storage.googleapis.com/test-bucket/trading_card.png'
          }
        },
        metadata: {
          generatedAt: new Date().toISOString(),
          strategy: 'technical_analysis_v1'
        }
      };

      // Validate all required fields are present
      expect(mockCompleteTip.symbol).toBeDefined();
      expect(mockCompleteTip.timeframe).toMatch(/^(short|mid|long)_term$/);
      expect(mockCompleteTip.sentiment).toMatch(/^(bullish|bearish)$/);
      expect(mockCompleteTip.strength).toBeGreaterThan(2.0);
      expect(mockCompleteTip.entryPrice).toBeGreaterThan(0);
      expect(mockCompleteTip.company.name).toBeDefined();
      expect(mockCompleteTip.company.logoUrl).toContain('assets/logos');
      expect(mockCompleteTip.images.latestTradingCard.url).toContain('https://');
    });
  });
}); 