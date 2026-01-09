import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

class EnvConfig {
  EnvConfig._(); // Private constructor to prevent instantiation

  // ==================== APP INFORMATION ====================
  
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Fitness Tracker',
  );
  
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  
  static const String userName = String.fromEnvironment(
    'USER_NAME',
    defaultValue: 'Fitness User',
  );

  // ==================== ENVIRONMENT ====================
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';

  // ==================== FEATURE FLAGS ====================
  
  static bool get enableDevicePreview => kDebugMode;
  
  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );

  // ==================== DATABASE CONFIGURATION ====================
  
  static const String databaseName = String.fromEnvironment(
    'DATABASE_NAME',
    defaultValue: 'fitness_tracker.db',
  );
  
  /// Database version for migrations
  /// IMPORTANT: Increment this when adding new tables or columns
  /// Version 5: Added exercise_muscle_factors and muscle_stimulus tables, intensity column
  static const int databaseVersion = int.fromEnvironment(
    'DATABASE_VERSION',
    defaultValue: 5,
  );
  
  static const bool seedDefaultData = bool.fromEnvironment(
    'SEED_DEFAULT_DATA',
    defaultValue: true,
  );
  
  static const int seedDataVersion = int.fromEnvironment(
    'SEED_DATA_VERSION',
    defaultValue: 1,
  );
  
  static const bool enableSeedingLogs = bool.fromEnvironment(
    'ENABLE_SEEDING_LOGS',
    defaultValue: true,
  );
  
  static const bool forceReseed = bool.fromEnvironment(
    'FORCE_RESEED',
    defaultValue: false,
  );

  // ==================== API CONFIGURATION ====================
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yourapp.com',
  );
  
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );
  
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  // ==================== MUSCLE STIMULUS CONFIGURATION ====================
  
  /// Intensity exponent for non-linear scaling
  /// Formula: (intensity / maxIntensity) ^ intensityExponent
  /// Higher values = more dramatic difference between intensity levels
  static const double intensityExponent = 1.35;
  static const double weeklyDecayFactor = 0.6;
  static const double dailyThreshold = 8.0;
  static const double weeklyThreshold = 25.0;
  static const double monthlyThreshold = 90.0;
  static const double colorThresholdGreen = 0.20;
  static const double colorThresholdYellow = 0.45;
  static const double colorThresholdOrange = 0.70;
  static const double colorThresholdRed = 0.70;

  // ==================== LOGGING ====================
  
  static bool get enableDebugLogs => isDevelopment || kDebugMode;
  
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'debug',
  );

  // ==================== VALIDATION ====================
  
  /// Validate production configuration
  /// Call this in main() to ensure production settings are correct
  static void validateProductionConfig() {
    if (isProduction) {
      assert(
        !forceReseed,
        'FORCE_RESEED must be false in production!',
      );
      assert(
        apiKey.isNotEmpty,
        'API_KEY must be set in production!',
      );
    }
  }
  
  /// Print current configuration (development only)
  static void printConfig() {
    if (!enableDebugLogs) return;
    
    debugPrint('========== Environment Configuration ==========');
    debugPrint('App Name: $appName');
    debugPrint('App Version: $appVersion');
    debugPrint('Environment: $environment');
    debugPrint('Database: $databaseName (v$databaseVersion)');
    debugPrint('Seed Default Data: $seedDefaultData');
    debugPrint('Seed Data Version: $seedDataVersion');
    debugPrint('Force Reseed: $forceReseed');
    debugPrint('Enable Seeding Logs: $enableSeedingLogs');
    debugPrint('');
    debugPrint('Muscle Stimulus Configuration:');
    debugPrint('  Intensity Exponent: $intensityExponent');
    debugPrint('  Weekly Decay Factor: $weeklyDecayFactor');
    debugPrint('  Daily Threshold: $dailyThreshold');
    debugPrint('  Weekly Threshold: $weeklyThreshold');
    debugPrint('  Monthly Threshold: $monthlyThreshold');
    debugPrint('==============================================');
  }
}