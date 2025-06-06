const express = require('express');
const router = express.Router();
const chartGenerationService = require('../services/chartGenerationService');

// Test endpoint for chart generation
router.get('/test-chart', async (req, res) => {
  try {
    const testData = {
      symbol: 'GOOG',
      timeframe: 'mid_term',
      analysis: {
        analysis: {
          sentiment: 'bullish',
          strength: 0.85,
          entryPrice: 150.25,
          stopLoss: 145.50,
          takeProfit: 160.00
        }
      },
      indicators: {
        rsi: { value: 65.5 },
        macd: { valueMACDHist: 2.5 },
        ema: { value: 148.75 },
        bbands2: {
          valueUpperBand: 155.00,
          valueMiddleBand: 150.00,
          valueLowerBand: 145.00
        }
      }
    };

    const chartBuffer = await chartGenerationService.generateChart(
      testData.symbol,
      testData.timeframe,
      testData,
      testData.indicators
    );

    res.set('Content-Type', 'image/png');
    res.send(chartBuffer);
  } catch (error) {
    console.error('Error generating test chart:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router; 