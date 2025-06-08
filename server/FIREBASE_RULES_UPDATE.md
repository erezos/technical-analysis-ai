# Firebase Security Rules Update Required

## Trading Link Feature - Security Rules

To enable the mobile app to read trading platform links from Firebase, add this rule to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Existing rules...
    
    // Allow read access to app configuration (trading links)
    match /app_config/{document} {
      allow read: if true; // Anyone can read app configuration
      allow write: if false; // Only server can write configuration
    }
    
    // Allow read access to app statistics
    match /app_stats/{document} {
      allow read: if true; // Anyone can read app statistics
      allow write: if false; // Only server can write statistics
    }
    
    // Existing latest_tips rules...
    match /latest_tips/{document} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

## How to Update Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `fmm-config-manager`
3. Navigate to **Firestore Database** > **Rules**
4. Add the `app_config` rule above
5. Click **Publish**

## What This Enables

- ✅ Mobile app can fetch trading platform URLs from `app_config/trading_links`
- ✅ Mobile app can fetch app statistics from `app_stats/global_stats`
- ✅ Server can update URLs without app updates
- ✅ URLs are cached per session for performance
- ✅ Fallback URLs work if Firebase is unavailable

## Security Notes

- Only read access is granted to mobile apps
- Write access remains server-only
- No authentication required for app configuration
- URLs are public (they're meant to be shared anyway)

## Testing

After updating rules, test with:
```bash
cd server
node test_trading_link.js
```

The mobile app will automatically use the new trading link on next launch! 