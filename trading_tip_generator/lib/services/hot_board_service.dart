import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hot_board_models.dart';

class HotBoardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'hotBoard';
  static const String _documentId = 'current';

  /// Fetch the current hot board data from Firebase
  static Future<HotBoardData?> getHotBoardData() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return HotBoardData.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching hot board data: $e');
      return null;
    }
  }

  /// Stream hot board data for real-time updates
  static Stream<HotBoardData?> getHotBoardStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return HotBoardData.fromJson(doc.data()!);
      }
      return null;
    });
  }

  /// Check if data is stale (older than 30 minutes)
  static bool isDataStale(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inMinutes > 30;
  }

  /// Get formatted time since last update
  static String getTimeSinceUpdate(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 