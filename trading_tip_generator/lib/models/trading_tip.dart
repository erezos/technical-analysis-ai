import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String name;
  final String symbol;
  final String logoUrl;
  final String sector;
  final String business;
  final bool isCrypto;

  Company({
    required this.name,
    required this.symbol,
    required this.logoUrl,
    required this.sector,
    required this.business,
    required this.isCrypto,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      name: map['name'] ?? '',
      symbol: map['symbol'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      sector: map['sector'] ?? '',
      business: map['business'] ?? '',
      isCrypto: map['isCrypto'] ?? false,
    );
  }
}

class TradingTip {
  final String symbol;
  final String timeframe;
  final Map<String, dynamic> images;
  final DateTime createdAt;
  
  // Company information
  final Company? company;
  
  // Analysis fields
  final String? sentiment;
  final double? strength;
  final double? entryPrice;
  final double? stopLoss;
  final double? takeProfit;
  final List<String>? reasoning;
  
  // Technical indicators
  final Map<String, dynamic>? indicators;
  final String? timestamp;

  TradingTip({
    required this.symbol,
    required this.timeframe,
    required this.images,
    required this.createdAt,
    this.company,
    this.sentiment,
    this.strength,
    this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    this.reasoning,
    this.indicators,
    this.timestamp,
  });

  factory TradingTip.fromMap(Map<String, dynamic> map) {
    // Handle analysis nested object if it exists
    final analysisData = map['analysis'] as Map<String, dynamic>?;
    
    // Handle company data
    Company? company;
    if (map['company'] != null) {
      company = Company.fromMap(map['company'] as Map<String, dynamic>);
    }
    
    return TradingTip(
      symbol: map['symbol'] ?? '',
      timeframe: map['timeframe'] ?? '',
      images: map['images'] ?? {},
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      company: company,
      sentiment: analysisData?['sentiment'] ?? map['sentiment'],
      strength: (analysisData?['strength'] ?? map['strength'])?.toDouble(),
      entryPrice: (analysisData?['entryPrice'] ?? map['entryPrice'])?.toDouble(),
      stopLoss: (analysisData?['stopLoss'] ?? map['stopLoss'])?.toDouble(),
      takeProfit: (analysisData?['takeProfit'] ?? map['takeProfit'])?.toDouble(),
      reasoning: (analysisData?['reasoning'] ?? map['reasoning'])?.cast<String>(),
      indicators: map['indicators'] as Map<String, dynamic>?,
      timestamp: map['timestamp'] ?? map['timestamp'],
    );
  }

  // Helper methods for display
  String get formattedTimeframe => timeframe.replaceAll('_', ' ').toUpperCase();
  
  String get sentimentDisplay => sentiment?.toUpperCase() ?? 'N/A';
  
  String get strengthDisplay => strength != null ? strength!.toStringAsFixed(1) : 'N/A';
  
  bool get hasAnalysisData => sentiment != null || entryPrice != null;
  
  bool get hasIndicatorData => indicators != null && indicators!.isNotEmpty;
  
  // Company display helpers
  String get companyName => company?.name ?? symbol;
  String get logoUrl => company?.logoUrl ?? '';
  bool get hasLogo => logoUrl.isNotEmpty;
  String get businessInfo => company?.business ?? '';
} 