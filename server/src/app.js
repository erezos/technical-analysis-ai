const express = require('express');
const cors = require('cors');
const tradingTipsRoutes = require('./routes/tradingTips');

const app = express();

app.use(cors());
app.use(express.json());

// Serve static logo files (must be before API routes)
app.use('/logos', express.static('public/logos'));

// API Routes
app.use('/api/trading-tips', tradingTipsRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Trading Tip Generator API',
    endpoints: {
      logos: '/logos/stocks/{SYMBOL}.png or /logos/crypto/{SYMBOL}.png',
      tradingTips: '/api/trading-tips',
      health: '/health'
    }
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message });
});

module.exports = app; 