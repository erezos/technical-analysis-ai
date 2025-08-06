# 🧪 A/B Testing with Firebase Remote Config

## 🎯 **Israel 50/50 Split Example**

This guide shows you how to set up A/B testing for Israeli users with a 50/50 split between two different trading platforms.

## 🔧 **Step-by-Step Setup**

### **Step 1: Create the Base Parameter**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Navigate to **Engage** → **Remote Config**
3. Find your `trading_url` parameter (or create it if it doesn't exist)
4. Set **Default value**: `https://www.zulutrade.com/?ref=2915819&utm_campaign=global_users`

### **Step 2: Create A/B Test for Israel**

1. Click **"Create experiment"** (or **"A/B Testing"** → **"Create experiment"**)
2. **Experiment name**: `Israel Trading Platform Test`
3. **Description**: `Testing ZuluTrade vs Trading212 for Israeli users`
4. **Service**: Select **Remote Config**
5. Click **"Next"**

### **Step 3: Configure the Experiment**

#### **Targeting:**
1. **App**: Select your app
2. **Audience**: 
   - **Country/Region** = **Israel**
   - **User percentage**: 100% (all Israeli users)
3. **Minimum app version**: Leave as default
4. Click **"Next"**

#### **Variants:**
1. **Control (A)**: 
   - **Name**: `ZuluTrade (Control)`
   - **Value**: `https://www.zulutrade.com/?ref=2915819&utm_campaign=il_users_zulutrade`
   - **Traffic allocation**: 50%

2. **Variant B**:
   - **Name**: `Trading212 (Test)`
   - **Value**: `https://www.trading212.com/ref/2915819?utm_campaign=il_users_trading212`
   - **Traffic allocation**: 50%

3. Click **"Next"**

#### **Goals:**
1. **Primary goal**: `copy_traders_button_click`
2. **Secondary goals** (optional):
   - `trading_platform_url_used`
   - `trading_platform_launched`
3. Click **"Next"**

### **Step 4: Review and Launch**

1. Review your experiment settings
2. Click **"Start experiment"**
3. Confirm the launch

## 📊 **How It Works**

### **For Israeli Users:**
- **50%** get ZuluTrade URL
- **50%** get Trading212 URL
- **Firebase automatically** splits traffic
- **Analytics track** which performs better

### **For Non-Israeli Users:**
- Get the **default URL** (no A/B testing)
- **Unchanged behavior**

## 🎯 **Monitoring Results**

### **In Firebase Console:**
1. Go to **A/B Testing**
2. Click on your experiment
3. View **real-time results**:
   - Conversion rates per variant
   - Statistical significance
   - User engagement metrics

### **Key Metrics to Watch:**
- **Click-through rate** per variant
- **Conversion rate** per variant
- **Revenue per user** per variant
- **User retention** per variant

## 🔧 **Advanced A/B Testing Scenarios**

### **Scenario 1: Multiple Countries**
```
Experiment: "European Trading Platform Test"
Targeting: Germany, France, Italy, Spain
Variants:
- A (50%): Trading212
- B (50%): eToro
```

### **Scenario 2: Platform-Specific Testing**
```
Experiment: "US Platform Test"
Targeting: United States
Variants:
- A (33%): Robinhood
- B (33%): TD Ameritrade  
- C (34%): Fidelity
```

### **Scenario 3: URL Parameter Testing**
```
Experiment: "UTM Parameter Test"
Targeting: United Kingdom
Variants:
- A (50%): utm_campaign=uk_users_premium
- B (50%): utm_campaign=uk_users_basic
```

## 📈 **Analytics Integration**

### **Enhanced Events for A/B Testing:**

The updated analytics events will track:

```dart
// When user clicks "Copy Traders"
FirebaseAnalytics.instance.logEvent(
  name: 'copy_traders_button_click',
  parameters: {
    'url': url,
    'country_code': 'IL', // Israel
    'country_name': 'Israel',
    'trading_platform': 'ZuluTrade', // or 'Trading212'
    'experiment_name': 'Israel Trading Platform Test',
    'variant': 'A', // or 'B'
    'platform': 'iOS', // or 'Android'
  },
);
```

### **Custom Events for A/B Testing:**
```dart
// Track experiment exposure
FirebaseAnalytics.instance.logEvent(
  name: 'ab_test_exposure',
  parameters: {
    'experiment_name': 'Israel Trading Platform Test',
    'variant': 'A',
    'country_code': 'IL',
  },
);

// Track conversion
FirebaseAnalytics.instance.logEvent(
  name: 'ab_test_conversion',
  parameters: {
    'experiment_name': 'Israel Trading Platform Test',
    'variant': 'A',
    'conversion_type': 'trading_platform_click',
    'country_code': 'IL',
  },
);
```

## 🛠️ **Implementation in Code**

### **Enhanced TradingLinkService for A/B Testing:**

```dart
class TradingLinkService {
  // ... existing code ...

  /// Get A/B test variant info for analytics
  static Map<String, dynamic> getABTestInfo() {
    return {
      'experiment_name': 'Israel Trading Platform Test',
      'variant': _getCurrentVariant(),
      'country_code': detectedCountryCode,
      'country_name': detectedCountryName,
    };
  }

  /// Determine current A/B test variant
  static String _getCurrentVariant() {
    // This would integrate with Firebase A/B Testing SDK
    // For now, we'll use a simple hash-based approach
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = userId.hashCode;
    return hash % 2 == 0 ? 'A' : 'B';
  }
}
```

## 🎯 **Best Practices**

### **1. Statistical Significance**
- **Wait for sufficient data** before making decisions
- **Minimum 1000 users** per variant
- **Run for at least 2 weeks**

### **2. Clear Hypotheses**
- **Before**: "Trading212 will convert 20% better than ZuluTrade for Israeli users"
- **After**: Measure actual performance

### **3. Multiple Metrics**
- **Primary**: Conversion rate
- **Secondary**: Revenue per user, retention, engagement

### **4. Gradual Rollouts**
- **Start with 10%** traffic
- **Monitor for issues**
- **Scale up gradually**

## 📊 **Expected Results**

### **For Israel A/B Test:**
- **Variant A (ZuluTrade)**: 50% of Israeli users
- **Variant B (Trading212)**: 50% of Israeli users
- **Firebase tracks** which performs better
- **Automatic optimization** based on results

### **Success Metrics:**
- **Higher conversion rate** on winning variant
- **Better user engagement** on winning variant
- **Increased revenue** on winning variant

## 🚀 **Scaling to More Countries**

### **Multiple Experiments:**
```
1. Israel Test: ZuluTrade vs Trading212
2. US Test: Robinhood vs TD Ameritrade  
3. UK Test: Trading212 vs eToro
4. EU Test: Trading212 vs IG
```

### **Global Optimization:**
- **Per-country optimization**
- **Platform-specific testing**
- **Continuous improvement**

## 🎉 **You're Ready for A/B Testing!**

With this setup, you can:
- ✅ **Test different platforms** per country
- ✅ **50/50 splits** or any percentage
- ✅ **Real-time monitoring** of results
- ✅ **Automatic optimization** based on performance
- ✅ **Statistical significance** tracking

**Your Israel A/B test is ready to launch!** 🚀 