import 'package:cloud_firestore/cloud_firestore.dart';

class EducationalLesson {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String estimatedTime;
  final Map<String, dynamic> content;
  final DateTime createdAt;
  final String version;

  EducationalLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.estimatedTime,
    required this.content,
    required this.createdAt,
    required this.version,
  });

  factory EducationalLesson.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EducationalLesson(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? '',
      estimatedTime: data['estimatedTime'] ?? '',
      content: data['content'] ?? {},
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      version: data['version'] ?? '1.0',
    );
  }
}

class EducationalMetadata {
  final int totalLessons;
  final DateTime lastUpdated;
  final String version;
  final List<String> categories;
  final List<String> difficulties;

  EducationalMetadata({
    required this.totalLessons,
    required this.lastUpdated,
    required this.version,
    required this.categories,
    required this.difficulties,
  });

  factory EducationalMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EducationalMetadata(
      totalLessons: data['totalLessons'] ?? 0,
      lastUpdated: DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String()),
      version: data['version'] ?? '1.0',
      categories: List<String>.from(data['categories'] ?? []),
      difficulties: List<String>.from(data['difficulties'] ?? []),
    );
  }
}

class EducationalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'educational_content';
  
  // Cache for lessons
  static List<EducationalLesson>? _cachedLessons;
  static EducationalMetadata? _cachedMetadata;
  static DateTime? _lastFetchTime;
  
  // Cache duration (1 hour)
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Initialize and fetch all educational content on app startup
  static Future<void> initializeEducationalContent() async {
    try {
      print('📚 Initializing educational content...');
      
      // Fetch metadata first
      await _fetchMetadata();
      
      // Fetch all lessons
      await _fetchAllLessons();
      
      print('✅ Educational content initialized successfully');
      print('📊 Total lessons: ${_cachedLessons?.length ?? 0}');
      print('📂 Categories: ${_cachedMetadata?.categories.join(", ") ?? "None"}');
      
    } catch (e) {
      print('❌ Error initializing educational content: $e');
      // Initialize with empty data to prevent crashes
      _cachedLessons = [];
      _cachedMetadata = EducationalMetadata(
        totalLessons: 0,
        lastUpdated: DateTime.now(),
        version: '1.0',
        categories: [],
        difficulties: [],
      );
    }
  }

  /// Get all lessons (from cache if available)
  static Future<List<EducationalLesson>> getAllLessons() async {
    // Return cached data if available and fresh
    if (_cachedLessons != null && _isCacheValid()) {
      return _cachedLessons!;
    }

    // Fetch fresh data
    await _fetchAllLessons();
    return _cachedLessons ?? [];
  }

  /// Get lessons by category
  static Future<List<EducationalLesson>> getLessonsByCategory(String category) async {
    final allLessons = await getAllLessons();
    return allLessons.where((lesson) => lesson.category == category).toList();
  }

  /// Get lessons by difficulty
  static Future<List<EducationalLesson>> getLessonsByDifficulty(String difficulty) async {
    final allLessons = await getAllLessons();
    return allLessons.where((lesson) => lesson.difficulty == difficulty).toList();
  }

  /// Get metadata
  static Future<EducationalMetadata?> getMetadata() async {
    if (_cachedMetadata != null && _isCacheValid()) {
      return _cachedMetadata;
    }

    await _fetchMetadata();
    return _cachedMetadata;
  }

  /// Get unique categories
  static Future<List<String>> getCategories() async {
    final metadata = await getMetadata();
    return metadata?.categories ?? [];
  }

  /// Get unique difficulties
  static Future<List<String>> getDifficulties() async {
    final metadata = await getMetadata();
    return metadata?.difficulties ?? [];
  }

  /// Get lesson by ID
  static Future<EducationalLesson?> getLessonById(String id) async {
    final allLessons = await getAllLessons();
    try {
      return allLessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Private method to fetch all lessons
  static Future<void> _fetchAllLessons() async {
    try {
      print('📖 Fetching educational lessons from Firebase...');
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where(FieldPath.documentId, isNotEqualTo: '_metadata')
          .get();

      _cachedLessons = querySnapshot.docs
          .map((doc) => EducationalLesson.fromFirestore(doc))
          .toList();

      // Sort by category and then by title
      _cachedLessons!.sort((a, b) {
        final categoryComparison = a.category.compareTo(b.category);
        if (categoryComparison != 0) return categoryComparison;
        return a.title.compareTo(b.title);
      });

      _lastFetchTime = DateTime.now();
      
      print('✅ Fetched ${_cachedLessons!.length} lessons');
      
    } catch (e) {
      print('❌ Error fetching lessons: $e');
      _cachedLessons = [];
    }
  }

  /// Private method to fetch metadata
  static Future<void> _fetchMetadata() async {
    try {
      print('📊 Fetching educational metadata...');
      
      final doc = await _firestore
          .collection(_collection)
          .doc('_metadata')
          .get();

      if (doc.exists) {
        _cachedMetadata = EducationalMetadata.fromFirestore(doc);
        print('✅ Metadata fetched: ${_cachedMetadata!.totalLessons} lessons available');
      } else {
        print('⚠️ No metadata found, using defaults');
        _cachedMetadata = EducationalMetadata(
          totalLessons: 0,
          lastUpdated: DateTime.now(),
          version: '1.0',
          categories: [],
          difficulties: [],
        );
      }
      
    } catch (e) {
      print('❌ Error fetching metadata: $e');
      _cachedMetadata = EducationalMetadata(
        totalLessons: 0,
        lastUpdated: DateTime.now(),
        version: '1.0',
        categories: [],
        difficulties: [],
      );
    }
  }

  /// Check if cache is still valid
  static bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  /// Force refresh cache
  static Future<void> refreshCache() async {
    _cachedLessons = null;
    _cachedMetadata = null;
    _lastFetchTime = null;
    await initializeEducationalContent();
  }

  /// Get cache status for debugging
  static Map<String, dynamic> getCacheStatus() {
    return {
      'lessonsCount': _cachedLessons?.length ?? 0,
      'hasMetadata': _cachedMetadata != null,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'isCacheValid': _isCacheValid(),
    };
  }
} 