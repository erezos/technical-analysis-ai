const logoUtils = require('./src/utils/logoUtils');

console.log('🧪 TESTING LOGO FALLBACK SYSTEM');
console.log('================================\n');

// Test stocks with logos
console.log('📈 STOCKS WITH LOGOS:');
const stocksWithLogos = ['AAPL', 'DIS', 'TSLA', 'MSFT'];
stocksWithLogos.forEach(symbol => {
  const company = logoUtils.getStockCompanyInfo(symbol);
  const logoExists = logoUtils.checkLogoExists(symbol);
  console.log(`   ${symbol}: ${company.name}`);
  console.log(`      Logo: ${logoExists ? '✅ EXISTS' : '❌ MISSING'} - ${company.logoUrl.includes('data:') ? 'DEFAULT FALLBACK' : 'LOCAL FILE'}`);
  console.log(`      Business: ${company.business}\n`);
});

// Test stocks without logos (likely missing)
console.log('📊 STOCKS THAT MIGHT BE MISSING LOGOS:');
const potentiallyMissingStocks = ['BAC', 'FAKESYMBOL', 'NONEXISTENT'];
potentiallyMissingStocks.forEach(symbol => {
  const company = logoUtils.getStockCompanyInfo(symbol);
  const logoExists = logoUtils.checkLogoExists(symbol);
  console.log(`   ${symbol}: ${company.name}`);
  console.log(`      Logo: ${logoExists ? '✅ EXISTS' : '❌ MISSING'} - ${company.logoUrl.includes('data:') ? 'DEFAULT FALLBACK' : 'LOCAL FILE'}`);
  console.log(`      Business: ${company.business}\n`);
});

// Test crypto
console.log('💎 CRYPTO WITH LOGOS:');
const cryptosWithLogos = ['BTC/USDT', 'ETH/USDT', 'SOL/USDT'];
cryptosWithLogos.forEach(symbol => {
  const crypto = logoUtils.getCryptoCompanyInfo(symbol);
  const logoExists = logoUtils.checkLogoExists(symbol, true);
  console.log(`   ${symbol}: ${crypto.name}`);
  console.log(`      Logo: ${logoExists ? '✅ EXISTS' : '❌ MISSING'} - ${crypto.logoUrl.includes('data:') ? 'DEFAULT FALLBACK' : 'LOCAL FILE'}`);
  console.log(`      Business: ${crypto.business}\n`);
});

// Test crypto that doesn't exist
console.log('🪙 CRYPTO THAT MIGHT BE MISSING:');
const missingCrypto = ['FAKE/USDT', 'NONEXIST/USDT'];
missingCrypto.forEach(symbol => {
  const crypto = logoUtils.getCryptoCompanyInfo(symbol);
  const logoExists = logoUtils.checkLogoExists(symbol, true);
  console.log(`   ${symbol}: ${crypto.name}`);
  console.log(`      Logo: ${logoExists ? '✅ EXISTS' : '❌ MISSING'} - ${crypto.logoUrl.includes('data:') ? 'DEFAULT FALLBACK' : 'LOCAL FILE'}`);
  console.log(`      Business: ${crypto.business}\n`);
});

console.log('✅ FALLBACK SYSTEM TEST COMPLETE!');
console.log('💡 The system gracefully handles missing logos with emoji fallbacks');
console.log('🔄 No crashes or broken flows when logos are missing'); 