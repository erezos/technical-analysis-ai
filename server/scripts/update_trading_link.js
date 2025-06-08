// Use existing Firebase configuration from the project
const { db, admin } = require('../src/config/firebase');

/**
 * Update trading platform link in Firebase
 * Usage: node scripts/update_trading_link.js "https://your-trading-platform.com/ref=yourcode"
 */
async function updateTradingLink(newUrl) {
  try {
    console.log('🔗 Updating trading platform link...');
    console.log(`📝 New URL: ${newUrl}`);
    
    const docRef = db.collection('app_config').doc('trading_links');
    
    await docRef.set({
      primary_url: newUrl,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      backup_url: 'https://www.trading212.com/', // Fallback URL
      description: 'Primary trading platform affiliate link',
      version: '1.0'
    }, { merge: true });

    console.log('✅ Trading link updated successfully!');
    console.log('📱 Mobile apps will use the new link on next launch');
    
    // Verify the update
    const updatedDoc = await docRef.get();
    if (updatedDoc.exists) {
      const data = updatedDoc.data();
      console.log('📊 Current config:', {
        primary_url: data.primary_url,
        backup_url: data.backup_url,
        updated_at: data.updated_at?.toDate()
      });
    }
    
  } catch (error) {
    console.error('❌ Error updating trading link:', error);
    process.exit(1);
  }
}

/**
 * Initialize trading link with default URL
 */
async function initializeTradingLink() {
  try {
    console.log('🔗 Initializing trading platform link...');
    
    const docRef = db.collection('app_config').doc('trading_links');
    const doc = await docRef.get();
    
    if (doc.exists) {
      console.log('ℹ️ Trading link already exists');
      const data = doc.data();
      console.log(`📝 Current URL: ${data.primary_url}`);
      return;
    }
    
    // Create initial document with default URL
    const defaultUrl = 'https://www.trading212.com/';
    await docRef.set({
      primary_url: defaultUrl,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      backup_url: 'https://www.trading212.com/',
      description: 'Primary trading platform affiliate link',
      version: '1.0',
      initialized: true
    });

    console.log('✅ Trading link initialized successfully!');
    console.log(`📝 Default URL: ${defaultUrl}`);
    console.log('💡 Use: node scripts/update_trading_link.js "https://your-affiliate-link" to update');
    
  } catch (error) {
    console.error('❌ Error initializing trading link:', error);
    process.exit(1);
  }
}

/**
 * Get current trading link
 */
async function getCurrentTradingLink() {
  try {
    const docRef = db.collection('app_config').doc('trading_links');
    const doc = await docRef.get();
    
    if (doc.exists) {
      const data = doc.data();
      console.log('📊 Current Trading Link Configuration:');
      console.log('=====================================');
      console.log(`Primary URL: ${data.primary_url}`);
      console.log(`Backup URL: ${data.backup_url}`);
      console.log(`Last Updated: ${data.updated_at?.toDate()}`);
      console.log(`Version: ${data.version}`);
      return data.primary_url;
    } else {
      console.log('❌ No trading link configuration found');
      console.log('💡 Run: node scripts/update_trading_link.js init');
      return null;
    }
  } catch (error) {
    console.error('❌ Error getting trading link:', error);
    return null;
  }
}

// Main execution
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log('📋 Trading Link Management');
    console.log('==========================');
    console.log('Usage:');
    console.log('  node scripts/update_trading_link.js init                    # Initialize with default');
    console.log('  node scripts/update_trading_link.js "https://example.com"   # Update URL');
    console.log('  node scripts/update_trading_link.js get                     # Get current URL');
    console.log('');
    await getCurrentTradingLink();
    process.exit(0);
  }
  
  const command = args[0];
  
  switch (command) {
    case 'init':
      await initializeTradingLink();
      break;
    case 'get':
      await getCurrentTradingLink();
      break;
    default:
      // Treat as URL to update
      if (command.startsWith('http://') || command.startsWith('https://')) {
        await updateTradingLink(command);
      } else {
        console.error('❌ Invalid URL. Must start with http:// or https://');
        process.exit(1);
      }
      break;
  }
  
  process.exit(0);
}

main().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
}); 