const logoUtils = require('../../src/utils/logoUtils');
const fs = require('fs');
const path = require('path');

// Mock fs module
jest.mock('fs');

describe('LogoUtils Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getStockLogoUrl', () => {
    it('should return asset path for existing stock logo', () => {
      fs.existsSync.mockReturnValue(true);
      
      const result = logoUtils.getStockLogoUrl('AAPL');
      
      expect(result).toBe('assets/logos/stocks/AAPL.png');
      expect(fs.existsSync).toHaveBeenCalledWith(
        expect.stringContaining('public/logos/stocks/AAPL.png')
      );
    });

    it('should return default logo for non-existing stock', () => {
      fs.existsSync.mockReturnValue(false);
      
      const result = logoUtils.getStockLogoUrl('NONEXISTENT');
      
      expect(result).toContain('data:image/svg+xml');
      expect(result).toContain('📈');
    });

    it('should handle empty symbol gracefully', () => {
      const result = logoUtils.getStockLogoUrl('');
      
      expect(result).toContain('data:image/svg+xml');
    });
  });

  describe('getCryptoLogoUrl', () => {
    it('should return asset path for existing crypto logo', () => {
      fs.existsSync.mockReturnValue(true);
      
      const result = logoUtils.getCryptoLogoUrl('BTC/USDT');
      
      expect(result).toBe('assets/logos/crypto/BTC.png');
    });

    it('should extract symbol from trading pair', () => {
      fs.existsSync.mockReturnValue(true);
      
      logoUtils.getCryptoLogoUrl('ETH/USDT');
      
      expect(fs.existsSync).toHaveBeenCalledWith(
        expect.stringContaining('crypto/ETH.png')
      );
    });

    it('should return default crypto logo for non-existing crypto', () => {
      fs.existsSync.mockReturnValue(false);
      
      const result = logoUtils.getCryptoLogoUrl('FAKE/USDT');
      
      expect(result).toContain('🪙');
    });
  });

  describe('getStockCompanyInfo', () => {
    it('should return company info for known stock', () => {
      fs.existsSync.mockReturnValue(false); // Use default logo
      
      const result = logoUtils.getStockCompanyInfo('AAPL');
      
      expect(result).toEqual({
        name: 'Apple Inc.',
        symbol: 'AAPL',
        logoUrl: expect.stringContaining('data:image/svg+xml'),
        sector: 'Technology',
        business: 'Consumer Electronics',
        isCrypto: false
      });
    });

    it('should return default info for unknown stock', () => {
      fs.existsSync.mockReturnValue(false);
      
      const result = logoUtils.getStockCompanyInfo('UNKNOWN');
      
      expect(result).toEqual({
        name: 'UNKNOWN',
        symbol: 'UNKNOWN',
        logoUrl: expect.stringContaining('data:image/svg+xml'),
        sector: 'Financial Markets',
        business: 'Public Company',
        isCrypto: false
      });
    });
  });

  describe('getCryptoCompanyInfo', () => {
    it('should return crypto info for known cryptocurrency', () => {
      fs.existsSync.mockReturnValue(false); // Use default logo
      
      const result = logoUtils.getCryptoCompanyInfo('BTC/USDT');
      
      expect(result).toEqual({
        name: 'Bitcoin',
        symbol: 'BTC/USDT',
        logoUrl: expect.stringContaining('data:image/svg+xml'),
        sector: 'Store of Value',
        business: 'Digital Gold',
        isCrypto: true
      });
    });

    it('should handle trading pairs correctly', () => {
      const result = logoUtils.getCryptoCompanyInfo('ETH/USDT');
      
      expect(result.name).toBe('Ethereum');
      expect(result.isCrypto).toBe(true);
    });
  });

  describe('integration tests', () => {
    it('should provide complete logo and company data for stock', () => {
      fs.existsSync.mockReturnValue(true);
      
      const symbol = 'TSLA';
      const logoUrl = logoUtils.getStockLogoUrl(symbol);
      const companyInfo = logoUtils.getStockCompanyInfo(symbol);
      
      expect(logoUrl).toBe('assets/logos/stocks/TSLA.png');
      expect(companyInfo.name).toBe('Tesla'); // Actual name in implementation
      expect(companyInfo.isCrypto).toBe(false);
    });

    it('should provide fallback for completely unknown asset', () => {
      fs.existsSync.mockReturnValue(false);
      
      const logoUrl = logoUtils.getStockLogoUrl('FAKESYMBOL');
      const companyInfo = logoUtils.getStockCompanyInfo('FAKESYMBOL');
      
      expect(logoUrl).toContain('📈');
      expect(companyInfo.name).toBe('FAKESYMBOL');
    });
  });
}); 