calculateATR(priceHistory) {
  // Defensive: must be array with at least 2 elements
  if (!Array.isArray(priceHistory) || priceHistory.length < 2) {
    console.warn('⚠️ ATR: priceHistory missing or too short:', priceHistory);
    return 0.001;
  }

  // Defensive: check for valid .close, .high, .low fields
  for (const p of priceHistory) {
    if (
      typeof p.close !== 'number' ||
      typeof p.high !== 'number' ||
      typeof p.low !== 'number'
    ) {
      console.warn('⚠️ ATR: Invalid price data in history:', p, 'Full history:', priceHistory);
      return 0.001;
    }
  }

  // Standard ATR calculation for symbols with enough data
  if (priceHistory.length >= 14) {
    const trueRanges = [];
    for (let i = 1; i < Math.min(priceHistory.length, 20); i++) {
      const current = priceHistory[i];
      const previous = priceHistory[i - 1];
      const highLow = Math.abs(current.high - current.low);
      const highClose = Math.abs(current.high - previous.close);
      const lowClose = Math.abs(current.low - previous.close);
      trueRanges.push(Math.max(highLow, highClose, lowClose));
    }
    const atr = trueRanges.reduce((sum, tr) => sum + tr, 0) / trueRanges.length;
    const currentPrice = priceHistory[0].close;
    const minimumATR = currentPrice * 0.001; // 0.1% of price minimum
    return Math.max(atr, minimumATR);
  }

  // Fallback ATR for symbols with limited data
  const recentPrices = priceHistory.slice(0, Math.min(priceHistory.length, 10));
  const prices = recentPrices.map(p => p.close);
  if (prices.length < 2) {
    console.warn('⚠️ ATR: Not enough valid closes in fallback:', prices, priceHistory);
    return prices[0] && typeof prices[0] === 'number' ? prices[0] * 0.001 : 0.001;
  }
  let totalVariation = 0;
  for (let i = 1; i < prices.length; i++) {
    totalVariation += Math.abs(prices[i] - prices[i - 1]);
  }
  const avgVariation = totalVariation / (prices.length - 1);
  const currentPrice = prices[0];
  const minimumATR = currentPrice * 0.001;
  const calculatedATR = Math.max(avgVariation, minimumATR);
  if (isNaN(calculatedATR) || !isFinite(calculatedATR)) {
    console.warn('⚠️ ATR: Calculated ATR is NaN or infinite:', calculatedATR, 'Prices:', prices, 'History:', priceHistory);
    return 0.001;
  }
  return calculatedATR;
} 