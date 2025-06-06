const tradingTipsService = require('../../src/services/tradingTipsService');
const { db } = require('../../src/config/firebase');

describe('TradingTipsService Integration Tests - BASELINE', () => {
  const testTimeframe = 'test_timeframe';
  const mockTipData = {
    symbol: 'TEST',
    timeframe: testTimeframe,
    sentiment: 'bullish',
    strength: 2.5,
    confidence: 85,
    entryPrice: 100.50,
    stopLoss: 95.00,
    takeProfit: 110.00,
    riskRewardRatio: 1.73,
    reasoning: ['Test reason 1', 'Test reason 2'],
    indicators: {
      rsi: { value: 65.5 },
      ema: {
        ema50: { value: 100.50 },
        ema200: { value: 95.20 }
      },
      macd: {
        valueMACD: 1.2,
        valueMACDHist: 0.3,
        valueMACDSignal: 0.9
      }
    },
    company: {
      name: 'Test Company',
      symbol: 'TEST',
      logoUrl: 'assets/logos/stocks/TEST.png',
      sector: 'Technology',
      business: 'Testing Software',
      isCrypto: false
    }
  };

  beforeEach(async () => {
    // Clean up test data before each test
    try {
      await db.collection('latest_tips').doc(testTimeframe).delete();
      await db.collection('trading_tips').where('symbol', '==', 'TEST').get()
        .then(snapshot => {
          const batch = db.batch();
          snapshot.docs.forEach(doc => batch.delete(doc.ref));
          return batch.commit();
        });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  afterAll(async () => {
    // Final cleanup
    try {
      await db.collection('latest_tips').doc(testTimeframe).delete();
      await db.collection('trading_tips').where('symbol', '==', 'TEST').get()
        .then(snapshot => {
          const batch = db.batch();
          snapshot.docs.forEach(doc => batch.delete(doc.ref));
          return batch.commit();
        });
    } catch (error) {
      // Ignore cleanup errors
    }
  });

  describe('BASELINE: Current Data Structure Tests', () => {
    test('should save tip with all current data fields', async () => {
      const tipId = await tradingTipsService.addTip(mockTipData);
      
      expect(tipId).toBeDefined();
      expect(tipId).toContain('TEST');
      expect(tipId).toContain(testTimeframe);

      // Verify data was saved to latest_tips
      const latestTip = await tradingTipsService.getLatestTip(testTimeframe);
      expect(latestTip).toBeDefined();
      expect(latestTip.symbol).toBe('TEST');
      expect(latestTip.entryPrice).toBe(100.50);
      expect(latestTip.stopLoss).toBe(95.00);
      expect(latestTip.takeProfit).toBe(110.00);
    });

    test('should maintain data consistency between collections', async () => {
      await tradingTipsService.addTip(mockTipData);
      
      // Get from both collections
      const latestTip = await tradingTipsService.getLatestTip(testTimeframe);
      const historicalTips = await tradingTipsService.getTips(testTimeframe);
      
      expect(latestTip.symbol).toBe(historicalTips[0].symbol);
      expect(latestTip.entryPrice).toBe(historicalTips[0].entryPrice);
      expect(latestTip.sentiment).toBe(historicalTips[0].sentiment);
    });

    test('should preserve all technical indicators', async () => {
      await tradingTipsService.addTip(mockTipData);
      
      const savedTip = await tradingTipsService.getLatestTip(testTimeframe);
      
      expect(savedTip.indicators.rsi.value).toBe(65.5);
      expect(savedTip.indicators.ema.ema50.value).toBe(100.50);
      expect(savedTip.indicators.ema.ema200.value).toBe(95.20);
      expect(savedTip.indicators.macd.valueMACD).toBe(1.2);
    });

    test('should preserve company information', async () => {
      await tradingTipsService.addTip(mockTipData);
      
      const savedTip = await tradingTipsService.getLatestTip(testTimeframe);
      
      expect(savedTip.company.name).toBe('Test Company');
      expect(savedTip.company.logoUrl).toBe('assets/logos/stocks/TEST.png');
      expect(savedTip.company.isCrypto).toBe(false);
      expect(savedTip.company.sector).toBe('Technology');
    });

    test('should maintain trading levels precision', async () => {
      await tradingTipsService.addTip(mockTipData);
      
      const savedTip = await tradingTipsService.getLatestTip(testTimeframe);
      
      expect(savedTip.entryPrice).toBeCloseTo(100.50, 2);
      expect(savedTip.stopLoss).toBeCloseTo(95.00, 2);
      expect(savedTip.takeProfit).toBeCloseTo(110.00, 2);
      expect(savedTip.riskRewardRatio).toBeCloseTo(1.73, 2);
    });
  });

  describe('BASELINE: Mobile App Compatibility Tests', () => {
    test('should provide data in format expected by mobile app', async () => {
      // Test the exact data structure mobile app expects
      const mockTipWithImages = {
        ...mockTipData,
        images: {
          latestTradingCard: {
            url: 'https://test-storage.com/test-image.png',
            type: 'titled_background'
          }
        }
      };

      await tradingTipsService.addTip(mockTipWithImages);
      const savedTip = await tradingTipsService.getLatestTip(testTimeframe);

      // Verify mobile app can access image URL
      const imageUrl = (savedTip.images?.latestTradingCard)?.url;
      expect(imageUrl).toBeDefined();
      expect(imageUrl).toContain('https://');
      
      // Verify all mobile app required fields
      expect(savedTip.symbol).toBeDefined();
      expect(savedTip.timeframe).toBeDefined();
      expect(savedTip.sentiment).toBeDefined();
      expect(savedTip.entryPrice).toBeDefined();
      expect(savedTip.company?.name).toBeDefined();
    });

    test('should handle missing optional fields gracefully', async () => {
      const minimalTip = {
        symbol: 'MIN',
        timeframe: testTimeframe,
        sentiment: 'neutral',
        entryPrice: 50.00
      };

      await tradingTipsService.addTip(minimalTip);
      const savedTip = await tradingTipsService.getLatestTip(testTimeframe);

      expect(savedTip.symbol).toBe('MIN');
      expect(savedTip.entryPrice).toBe(50.00);
      // Should not crash on missing fields
      expect(savedTip.indicators).toBeUndefined();
      expect(savedTip.company).toBeUndefined();
    });
  });

  describe('BASELINE: Data Size and Performance Tests', () => {
    test('should measure current data size for optimization baseline', async () => {
      // Create tip with all current redundant data
      const bloatedTip = {
        ...mockTipData,
        backgroundImages: {
          titledBackground: {
            url: 'https://storage.googleapis.com/test/background.png',
            fileName: 'TEST_2025-06-05_test_background.png',
            generatedAt: new Date(),
            hasTitle: true,
            title: 'TEST - BULLISH - Test-term'
          },
          accentIcon: {
            url: 'https://storage.googleapis.com/test/accent.png',
            fileName: 'TEST_2025-06-05_test_accent.png',
            generatedAt: new Date()
          }
        },
        images: {
          latestTradingCard: {
            url: 'https://storage.googleapis.com/test/trading_card.png',
            type: 'titled_background'
          }
        },
        latestBackground: {
          url: 'https://storage.googleapis.com/test/background.png',
          type: 'titled_background',
          hasTitle: true
        },
        latestAccent: {
          url: 'https://storage.googleapis.com/test/accent.png',
          type: 'accent_icon'
        }
      };

      await tradingTipsService.addTip(bloatedTip);
      const savedTip = await tradingTipsService.getLatestTip(testTimeframe);

      // Measure baseline data size
      const dataSize = JSON.stringify(savedTip).length;
      console.log(`📊 BASELINE DATA SIZE: ${dataSize} characters`);
      
      // Count redundant fields
      let redundantFields = 0;
      if (savedTip.backgroundImages) redundantFields++;
      if (savedTip.latestBackground) redundantFields++;
      if (savedTip.latestAccent) redundantFields++;
      
      console.log(`🗑️ REDUNDANT FIELDS: ${redundantFields}`);
      
      // This establishes our optimization baseline
      expect(dataSize).toBeGreaterThan(1000); // Current bloated size
      expect(redundantFields).toBeGreaterThan(0); // Has redundancy to optimize
    });
  });

  describe('BASELINE: Error Handling Tests', () => {
    test('should handle invalid data gracefully', async () => {
      const invalidTip = {
        symbol: null,
        timeframe: testTimeframe,
        entryPrice: 'not-a-number'
      };

      // Should not crash, but may not save properly
      try {
        await tradingTipsService.addTip(invalidTip);
        const savedTip = await tradingTipsService.getLatestTip(testTimeframe);
        // If it saves, verify it handles the invalid data
        if (savedTip) {
          console.log('⚠️ Invalid data was saved:', savedTip.symbol);
        }
      } catch (error) {
        // Expected behavior - should reject invalid data
        expect(error).toBeDefined();
      }
    });

    test('should handle concurrent updates correctly', async () => {
      // Test multiple simultaneous saves
      const promises = [
        tradingTipsService.addTip({...mockTipData, symbol: 'CONCURRENT1'}),
        tradingTipsService.addTip({...mockTipData, symbol: 'CONCURRENT2'}),
        tradingTipsService.addTip({...mockTipData, symbol: 'CONCURRENT3'})
      ];

      const results = await Promise.allSettled(promises);
      
      // All should succeed
      results.forEach((result, index) => {
        expect(result.status).toBe('fulfilled');
        console.log(`✅ Concurrent save ${index + 1}: ${result.status}`);
      });
    });
  });
}); 