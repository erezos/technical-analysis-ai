# Trading Tip Generator Server

This is the server-side component of the Trading Tip Generator application. It manages trading tips and graph images using Firebase.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a Firebase project and download the service account key:
   - Go to Firebase Console
   - Create a new project
   - Go to Project Settings > Service Accounts
   - Generate new private key
   - Save as `firebase-service-account.json` in the server root directory

3. Create a `.env` file in the server root with:
```
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com
```

## Usage

### Development
```bash
npm run dev
```

### Update Tips
```bash
npm run update-tips
```

### Update Graphs
```bash
npm run update-graphs
```

## Structure

- `src/config/` - Configuration files
- `src/services/` - Business logic
- `src/models/` - Data models
- `src/utils/` - Helper functions
- `scripts/` - Update scripts

## Firebase Collections

### trading_tips
- timeframe (short_term, mid_term, long_term)
- title
- description
- symbol
- entryPrice
- stopLoss
- takeProfit
- riskRewardRatio
- analysis
- graphId
- createdAt

### Storage
- graphs/{graphId}.png 