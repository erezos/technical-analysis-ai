const tradingTipsService = require('../../src/services/tradingTipsService');

// Mock node-fetch
const fetch = require('node-fetch');

describe('TradingTipsService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('addTip', () => {
    it('should add tip to both collections', async () => {
      const mockTipData = {
        symbol: 'AAPL',
        timeframe: 'long_term',
        sentiment: 'bullish',
        strength: 2.5,
        entryPrice: 195.50,
        stopLoss: 185.00,
        takeProfit: 210.00
      };

      const tipId = await tradingTipsService.addTip(mockTipData);
      
      expect(tipId).toContain('AAPL');
      expect(tipId).toContain('long_term');
    });

    it('should format tip ID correctly', async () => {
      const mockTipData = {
        symbol: 'BTC/USDT',
        timeframe: 'short_term',
        sentiment: 'bearish'
      };

      const tipId = await tradingTipsService.addTip(mockTipData);
      
      expect(tipId).toMatch(/BTC\/USDT_\d{4}-\d{2}-\d{2}_short_term/);
    });
  });

  describe('getTips', () => {
    it('should fetch tips for specific timeframe', async () => {
      const tips = await tradingTipsService.getTips('long_term');
      
      expect(Array.isArray(tips)).toBe(true);
    });

    it('should handle empty results gracefully', async () => {
      const tips = await tradingTipsService.getTips('nonexistent_timeframe');
      
      expect(tips).toEqual([]);
    });
  });

  describe('getLatestTip', () => {
    it('should fetch latest tip for timeframe', async () => {
      const tip = await tradingTipsService.getLatestTip('long_term');
      
      // Should return either a tip object or null
      expect(tip === null || typeof tip === 'object').toBe(true);
    });
  });

  describe('downloadImage', () => {
    it('should download image successfully', async () => {
      fetch.mockResolvedValue({
        ok: true,
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(1024))
      });

      const buffer = await tradingTipsService.downloadImage('https://test-image.com');
      
      expect(Buffer.isBuffer(buffer)).toBe(true);
      expect(buffer.length).toBe(1024);
    });

    it('should handle failed downloads', async () => {
      fetch.mockResolvedValue({
        ok: false,
        statusText: 'Not Found'
      });

      await expect(tradingTipsService.downloadImage('https://invalid-url.com'))
        .rejects
        .toThrow('Failed to download image: Not Found');
    });

    it('should handle network errors', async () => {
      fetch.mockRejectedValue(new Error('Network error'));

      await expect(tradingTipsService.downloadImage('https://test-url.com'))
        .rejects
        .toThrow('Network error');
    });
  });

  describe('formatTimeframe', () => {
    it('should format timeframes correctly', () => {
      expect(tradingTipsService.formatTimeframe('short_term')).toBe('Short-term');
      expect(tradingTipsService.formatTimeframe('mid_term')).toBe('Mid-term');
      expect(tradingTipsService.formatTimeframe('long_term')).toBe('Long-term');
    });

    it('should return original value for unknown timeframes', () => {
      expect(tradingTipsService.formatTimeframe('custom_timeframe')).toBe('custom_timeframe');
    });
  });

  describe('saveBackgroundImages', () => {
    const mockTipData = {
      symbol: 'AAPL',
      timeframe: 'long_term',
      sentiment: 'bullish',
      company: {
        name: 'Apple Inc.',
        logoUrl: 'assets/logos/stocks/AAPL.png'
      }
    };

    beforeEach(() => {
      fetch.mockResolvedValue({
        ok: true,
        arrayBuffer: () => Promise.resolve(new ArrayBuffer(1024))
      });
    });

    it('should save background images successfully', async () => {
      const result = await tradingTipsService.saveBackgroundImages(
        mockTipData,
        'https://test-background.com',
        'https://test-accent.com'
      );

      expect(result.backgroundUrl).toBe('https://test-url.com');
      expect(result.accentUrl).toBe('https://test-url.com');
      expect(result.documentId).toBe('long_term');
    });

    it('should handle missing accent URL', async () => {
      const result = await tradingTipsService.saveBackgroundImages(
        mockTipData,
        'https://test-background.com'
      );

      expect(result.backgroundUrl).toBe('https://test-url.com');
      expect(result.accentUrl).toBeNull();
    });

    it('should handle notification sending', async () => {
      // Mock notification service
      const notificationService = require('../../src/services/notificationService');
      const sendSpy = jest.spyOn(notificationService, 'sendTipNotification')
        .mockResolvedValue({ success: true, title: 'Test notification' });

      await tradingTipsService.saveBackgroundImages(
        mockTipData,
        'https://test-background.com'
      );

      expect(sendSpy).toHaveBeenCalledWith(mockTipData, mockTipData.company);
    });
  });
}); 