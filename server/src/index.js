const express = require('express');
const cors = require('cors');
const tradingTipsService = require('./services/tradingTipsService');
const technicalAnalysisService = require('./services/technicalAnalysisService');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Get tips by timeframe
app.get('/api/tips/:timeframe', async (req, res) => {
  try {
    const tips = await tradingTipsService.getTips(req.params.timeframe);
    res.json(tips);
  } catch (error) {
    console.error('Error fetching tips:', error);
    res.status(500).json({ error: 'Failed to fetch tips' });
  }
});

// Analyze a symbol
app.get('/api/analyze/:symbol/:timeframe', async (req, res) => {
  try {
    const { symbol, timeframe } = req.params;
    const analysis = await technicalAnalysisService.getTechnicalAnalysis(symbol, timeframe);
    res.json(analysis);
  } catch (error) {
    console.error('Error analyzing symbol:', error);
    res.status(500).json({ error: 'Failed to analyze symbol' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
}); 