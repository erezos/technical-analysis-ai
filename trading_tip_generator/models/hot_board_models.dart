class HotBoardStock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changesPercentage;
  final DateTime lastUpdated;

  HotBoardStock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changesPercentage,
    required this.lastUpdated,
  });

  factory HotBoardStock.fromJson(Map<String, dynamic> json) {
    return HotBoardStock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changesPercentage: (json['changePercentage'] ?? 0).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'price': price,
      'change': change,
      'changesPercentage': changesPercentage,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }

  bool get isGainer => changesPercentage > 0;
  
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  String get formattedChange => '${change >= 0 ? '+' : ''}\$${change.toStringAsFixed(2)}';
  
  String get formattedPercentage => '${changesPercentage >= 0 ? '+' : ''}${changesPercentage.toStringAsFixed(2)}%';
}

class HotBoardData {
  final List<HotBoardStock> gainers;
  final List<HotBoardStock> losers;
  final DateTime lastUpdated;

  HotBoardData({
    required this.gainers,
    required this.losers,
    required this.lastUpdated,
  });

  factory HotBoardData.fromJson(Map<String, dynamic> json) {
    return HotBoardData(
      gainers: (json['gainers'] as List<dynamic>? ?? [])
          .map((item) => HotBoardStock.fromJson(item))
          .toList(),
      losers: (json['losers'] as List<dynamic>? ?? [])
          .map((item) => HotBoardStock.fromJson(item))
          .toList(),
      lastUpdated: _parseTimestamp(json['lastUpdated']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    // Handle Firebase Timestamp objects
    if (timestamp.runtimeType.toString().contains('Timestamp')) {
      return timestamp.toDate();
    }
    
    // Handle integer milliseconds
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    
    // Handle string timestamps
    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    // Fallback
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'gainers': gainers.map((stock) => stock.toJson()).toList(),
      'losers': losers.map((stock) => stock.toJson()).toList(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
} 