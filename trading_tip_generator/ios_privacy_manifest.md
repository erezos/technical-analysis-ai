# iOS App Store Privacy Manifest
## Technical-Analysis.AI

### Data Types Collected:
1. **No Personal Data Collected**
   - No email, name, or personal identifiers
   - No location data
   - No contact information

### Data Used:
1. **Push Notification Tokens**
   - Purpose: Send trading alerts 
   - Retention: Until user uninstalls app
   - Sharing: Not shared with third parties

2. **App Analytics (Firebase)**
   - Purpose: App performance and crash reporting
   - Data: Device type, OS version, app version
   - Retention: 60 days
   - Sharing: Not shared with third parties

3. **Technical Analysis Data**
   - Purpose: Display trading tips and market analysis
   - Data: Stock symbols, technical indicators, market data
   - Source: Public market data APIs (TAAPI.io)
   - Retention: Historical data for app functionality
   - Sharing: Not shared with third parties

### Third-Party SDKs:
1. **Firebase (Google)**
   - Push notifications
   - Data storage for trading tips
   - Analytics and crash reporting

2. **TAAPI.io API**
   - Technical analysis data
   - Public market data only

### User Rights:
- Users can disable push notifications in device settings
- No personal account or login required
- No data deletion requests needed (no personal data stored)

### Contact:
- Developer: IOA Technologies
- Email: [your-email]
- Privacy Policy: [your-privacy-policy-url] 