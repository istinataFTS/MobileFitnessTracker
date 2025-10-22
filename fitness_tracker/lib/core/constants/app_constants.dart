/// Application-wide constants
class AppConstants {
  AppConstants._();

  // Database
  static const int databaseVersion = 1;
  static const String databaseName = 'fitness_tracker.db';
  
  // Limits
  static const int maxExercisesPerWorkout = 20;
  static const int maxSetsPerExercise = 10;
  static const int maxReps = 1000;
  static const double maxWeight = 1000.0; // kg
  static const int maxWeeklyGoal = 100;
  static const int maxExerciseNameLength = 50;
  
  // Defaults
  static const int defaultWeeklyGoal = 10;
  static const int defaultReps = 12;
  static const double defaultWeight = 20.0;
  
  // Time
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration dataSyncInterval = Duration(hours: 6);
  static const int daysToKeepHistory = 365; // 1 year
  
  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration splashDuration = Duration(seconds: 2);
  static const double maxBottomSheetHeight = 0.9; // 90% of screen height
  
  // Pagination
  static const int itemsPerPage = 20;
  static const int historyItemsPerPage = 50;
  
  // Cache
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCacheSize = 100; // MB
  
  // Performance
  static const int slowOperationThresholdMs = 500;
  static const int criticalOperationThresholdMs = 1000;
  
  // Validation Regex
  static final RegExp exerciseNameRegex = RegExp(r'^[a-zA-Z0-9\s\-()]+$');
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  // File paths
  static const String assetsPath = 'assets/';
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/images/icons/';
  static const String dataPath = 'assets/data/';
  
  // Network (for future use)
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}