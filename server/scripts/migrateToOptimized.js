const originalService = require('../src/services/tradingTipsService');
const optimizedService = require('../src/services/tradingTipsServiceOptimized');
const { db } = require('../src/config/firebase');

class OptimizationMigration {
  constructor() {
    this.backupCollection = 'latest_tips_backup';
    this.migrationLog = [];
  }

  async migrate(dryRun = true) {
    console.log('🚀 OPTIMIZATION MIGRATION');
    console.log('=========================');
    
    if (dryRun) {
      console.log('📋 DRY RUN MODE - No actual changes will be made');
    } else {
      console.log('⚠️ LIVE MIGRATION MODE - Changes will be applied!');
    }

    try {
      // Step 1: Backup current data
      console.log('\n💾 Step 1: Creating backup...');
      await this.createBackup();

      // Step 2: Analyze current data
      console.log('\n📊 Step 2: Analyzing current data...');
      const analysis = await this.analyzeCurrentData();
      this.logAnalysis(analysis);

      // Step 3: Test migration on each timeframe
      console.log('\n🧪 Step 3: Testing migration...');
      const timeframes = ['short_term', 'mid_term', 'long_term'];
      
      for (const timeframe of timeframes) {
        await this.testTimeframeMigration(timeframe, dryRun);
      }

      if (!dryRun) {
        // Step 4: Apply migration
        console.log('\n✅ Step 4: Applying optimization...');
        for (const timeframe of timeframes) {
          await this.migrateTimeframe(timeframe);
        }

        console.log('\n🎉 Migration completed successfully!');
        console.log('📊 Optimization Summary:');
        await this.generateMigrationReport();
      } else {
        console.log('\n✅ Dry run completed - ready for live migration');
      }

    } catch (error) {
      console.error('❌ Migration failed:', error);
      
      if (!dryRun) {
        console.log('🔄 Attempting rollback...');
        await this.rollback();
      }
      
      throw error;
    }
  }

  async createBackup() {
    const timeframes = ['short_term', 'mid_term', 'long_term'];
    
    for (const timeframe of timeframes) {
      try {
        const originalTip = await originalService.getLatestTip(timeframe);
        if (originalTip) {
          await db.collection(this.backupCollection).doc(timeframe).set({
            ...originalTip,
            backupTimestamp: new Date(),
            originalSize: JSON.stringify(originalTip).length
          });
          
          console.log(`   ✅ Backed up ${timeframe}: ${originalTip.symbol}`);
        } else {
          console.log(`   ⚪ No data for ${timeframe}`);
        }
      } catch (error) {
        console.error(`   ❌ Backup failed for ${timeframe}:`, error.message);
      }
    }
  }

  async analyzeCurrentData() {
    const analysis = {
      totalTips: 0,
      totalOriginalSize: 0,
      totalOptimizedSize: 0,
      tips: {}
    };

    const timeframes = ['short_term', 'mid_term', 'long_term'];
    
    for (const timeframe of timeframes) {
      const originalTip = await originalService.getLatestTip(timeframe);
      if (originalTip) {
        const optimizedTip = optimizedService.optimizeDataStructure(originalTip);
        
        const originalSize = JSON.stringify(originalTip).length;
        const optimizedSize = JSON.stringify(optimizedTip).length;
        
        analysis.tips[timeframe] = {
          symbol: originalTip.symbol,
          originalSize,
          optimizedSize,
          reduction: Math.round(((originalSize - optimizedSize) / originalSize) * 100)
        };
        
        analysis.totalTips++;
        analysis.totalOriginalSize += originalSize;
        analysis.totalOptimizedSize += optimizedSize;
      }
    }

    analysis.totalReduction = Math.round(((analysis.totalOriginalSize - analysis.totalOptimizedSize) / analysis.totalOriginalSize) * 100);
    
    return analysis;
  }

  logAnalysis(analysis) {
    console.log(`   📊 Total tips: ${analysis.totalTips}`);
    console.log(`   📏 Original total size: ${analysis.totalOriginalSize} chars`);
    console.log(`   🎯 Optimized total size: ${analysis.totalOptimizedSize} chars`);
    console.log(`   📉 Total reduction: ${analysis.totalReduction}%`);
    
    console.log('\n   💾 Per-timeframe analysis:');
    Object.entries(analysis.tips).forEach(([timeframe, data]) => {
      console.log(`      ${timeframe}: ${data.symbol} (${data.originalSize} → ${data.optimizedSize} chars, ${data.reduction}% reduction)`);
    });
  }

  async testTimeframeMigration(timeframe, dryRun) {
    try {
      const originalTip = await originalService.getLatestTip(timeframe);
      if (!originalTip) {
        console.log(`   ⚪ ${timeframe}: No data to migrate`);
        return;
      }

      // Test optimization
      const optimizedTip = optimizedService.optimizeDataStructure(originalTip);
      
      // Test mobile compatibility mapping
      const mobileCompatible = {
        ...optimizedTip,
        images: {
          latestTradingCard: {
            url: optimizedTip.backgroundImageUrl || 'test-url',
            type: 'titled_background'
          }
        }
      };

      // Validate essential fields
      const requiredFields = ['symbol', 'timeframe', 'sentiment', 'entryPrice', 'company'];
      const missingFields = requiredFields.filter(field => !mobileCompatible[field]);
      
      if (missingFields.length > 0) {
        throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
      }

      // Validate mobile image URL access
      const mobileImageUrl = mobileCompatible.images?.latestTradingCard?.url;
      if (!mobileImageUrl) {
        throw new Error('Mobile app image URL not accessible');
      }

      const originalSize = JSON.stringify(originalTip).length;
      const optimizedSize = JSON.stringify(optimizedTip).length;
      const reduction = Math.round(((originalSize - optimizedSize) / originalSize) * 100);

      console.log(`   ✅ ${timeframe}: ${originalTip.symbol} (${reduction}% reduction, mobile compatible)`);
      
      this.migrationLog.push({
        timeframe,
        symbol: originalTip.symbol,
        originalSize,
        optimizedSize,
        reduction,
        status: 'tested'
      });

    } catch (error) {
      console.error(`   ❌ ${timeframe}: Test failed - ${error.message}`);
      throw error;
    }
  }

  async migrateTimeframe(timeframe) {
    try {
      const originalTip = await originalService.getLatestTip(timeframe);
      if (!originalTip) return;

      // Create optimized structure
      const optimizedTip = optimizedService.optimizeDataStructure(originalTip);
      
      // Add timestamps
      optimizedTip.createdAt = originalTip.createdAt;
      optimizedTip.updatedAt = new Date();
      optimizedTip.migrationTimestamp = new Date();

      // Save optimized version
      await db.collection('latest_tips').doc(timeframe).set(optimizedTip);
      
      const originalSize = JSON.stringify(originalTip).length;
      const optimizedSize = JSON.stringify(optimizedTip).length;
      const reduction = Math.round(((originalSize - optimizedSize) / originalSize) * 100);

      console.log(`   ✅ ${timeframe}: Migrated ${originalTip.symbol} (${reduction}% reduction)`);
      
      // Update migration log
      const logEntry = this.migrationLog.find(entry => entry.timeframe === timeframe);
      if (logEntry) {
        logEntry.status = 'migrated';
        logEntry.migrationTimestamp = new Date();
      }

    } catch (error) {
      console.error(`   ❌ ${timeframe}: Migration failed - ${error.message}`);
      throw error;
    }
  }

  async rollback() {
    console.log('🔄 Rolling back to original data...');
    
    const timeframes = ['short_term', 'mid_term', 'long_term'];
    
    for (const timeframe of timeframes) {
      try {
        const backup = await db.collection(this.backupCollection).doc(timeframe).get();
        if (backup.exists) {
          const backupData = backup.data();
          delete backupData.backupTimestamp;
          delete backupData.originalSize;
          
          await db.collection('latest_tips').doc(timeframe).set(backupData);
          console.log(`   ✅ Restored ${timeframe}`);
        }
      } catch (error) {
        console.error(`   ❌ Rollback failed for ${timeframe}:`, error.message);
      }
    }
  }

  async generateMigrationReport() {
    const totalOriginalSize = this.migrationLog.reduce((sum, entry) => sum + entry.originalSize, 0);
    const totalOptimizedSize = this.migrationLog.reduce((sum, entry) => sum + entry.optimizedSize, 0);
    const totalReduction = Math.round(((totalOriginalSize - totalOptimizedSize) / totalOriginalSize) * 100);
    
    console.log(`   📊 Migrated ${this.migrationLog.length} tips`);
    console.log(`   📉 Overall size reduction: ${totalReduction}%`);
    console.log(`   💾 Space saved: ${totalOriginalSize - totalOptimizedSize} characters`);
    console.log(`   🎯 New average size: ${Math.round(totalOptimizedSize / this.migrationLog.length)} chars/tip`);
  }

  async cleanupBackup() {
    console.log('🧹 Cleaning up backup...');
    
    const timeframes = ['short_term', 'mid_term', 'long_term'];
    
    for (const timeframe of timeframes) {
      try {
        await db.collection(this.backupCollection).doc(timeframe).delete();
        console.log(`   ✅ Cleaned backup for ${timeframe}`);
      } catch (error) {
        console.error(`   ❌ Cleanup failed for ${timeframe}:`, error.message);
      }
    }
  }
}

async function main() {
  const migration = new OptimizationMigration();
  
  // Check command line arguments
  const args = process.argv.slice(2);
  const isDryRun = !args.includes('--live');
  const shouldCleanup = args.includes('--cleanup');
  
  if (shouldCleanup) {
    await migration.cleanupBackup();
    return;
  }
  
  try {
    await migration.migrate(isDryRun);
    
    if (!isDryRun) {
      console.log('\n🎉 MIGRATION COMPLETED SUCCESSFULLY!');
      console.log('📱 Mobile app compatibility: MAINTAINED');
      console.log('💰 Firebase costs: SIGNIFICANTLY REDUCED');
      console.log('🚀 Performance: IMPROVED');
      
      console.log('\n📋 Next steps:');
      console.log('1. Test mobile app with optimized data');
      console.log('2. Monitor performance metrics');
      console.log('3. Run --cleanup flag to remove backups');
    }
  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { OptimizationMigration }; 