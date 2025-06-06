const notificationService = require('../../src/services/notificationService');

describe('NotificationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('sendTipNotification', () => {
    const mockTipData = {
      symbol: 'AAPL',
      timeframe: 'long_term',
      sentiment: 'bullish',
      strength: 2.5,
      entryPrice: 195.50
    };

    const mockCompany = {
      name: 'Apple Inc.',
      logoUrl: 'assets/logos/stocks/AAPL.png',
      sector: 'Technology',
      business: 'Consumer Electronics',
      isCrypto: false
    };

    it('should send notification successfully', async () => {
      const result = await notificationService.sendTipNotification(mockTipData, mockCompany);
      
      expect(result.success).toBe(true);
      expect(result.title).toContain('Apple Inc.');
      expect(result.title).toContain('LONG TERM');
      expect(result.body).toContain('BULLISH');
      expect(result.body).toContain('2.5');
      expect(result.body).toContain('$195.50');
    });

    it('should format crypto notifications correctly', async () => {
      const cryptoTipData = {
        ...mockTipData,
        symbol: 'BTC/USDT',
        sentiment: 'bearish',
        strength: -1.8
      };

      const cryptoCompany = {
        name: 'Bitcoin',
        logoUrl: 'assets/logos/crypto/BTC.png',
        sector: 'Cryptocurrency',
        business: 'Digital Gold',
        isCrypto: true
      };

      const result = await notificationService.sendTipNotification(cryptoTipData, cryptoCompany);
      
      expect(result.success).toBe(true);
      expect(result.title).toContain('Bitcoin');
      expect(result.body).toContain('BEARISH');
      expect(result.body).toContain('1.8');
    });

    it('should handle missing entry price gracefully', async () => {
      const tipDataWithoutPrice = {
        ...mockTipData,
        entryPrice: undefined
      };

      const result = await notificationService.sendTipNotification(tipDataWithoutPrice, mockCompany);
      
      expect(result.success).toBe(true);
      expect(result.body).toContain('TBD');
    });

    it('should format timeframe display correctly', async () => {
      const shortTermData = {
        ...mockTipData,
        timeframe: 'short_term'
      };

      const result = await notificationService.sendTipNotification(shortTermData, mockCompany);
      
      expect(result.title).toContain('SHORT TERM');
    });
  });

  describe('sendTestNotification', () => {
    it('should send test notification successfully', async () => {
      const result = await notificationService.sendTestNotification();
      
      expect(result.success).toBe(true);
      expect(result.messageId).toBe('test-message-id');
    });
  });

  describe('error handling', () => {
    it('should handle Firebase messaging errors gracefully', async () => {
      // Mock the messaging instance to throw an error
      const originalSend = notificationService.messaging.send;
      notificationService.messaging.send = jest.fn().mockRejectedValue(new Error('Network error'));

      const mockTipData = {
        symbol: 'AAPL',
        timeframe: 'long_term',
        sentiment: 'bullish',
        strength: 2.5,
        entryPrice: 195.50
      };

      const mockCompany = {
        name: 'Apple Inc.',
        logoUrl: 'assets/logos/stocks/AAPL.png'
      };

      const result = await notificationService.sendTipNotification(mockTipData, mockCompany);
      
      expect(result.success).toBe(false);
      expect(result.error).toBe('Network error');

      // Restore original mock
      notificationService.messaging.send = originalSend;
    });
  });
}); 