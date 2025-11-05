import 'package:flutter/foundation.dart' show kDebugMode;

class EnvConfig {
  EnvConfig._(); // Private constructor to prevent instantiation

  // ==================== App Configuration ====================
  
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Fitness Tracker',
  );
  
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  
  // ==================== User Configuration ====================
  
  static const String userName = String.fromEnvironment(
    'USER_NAME',
    defaultValue: 'Fitness User',
  );
  
  // ==================== Environment ====================
  
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  // ==================== Feature Flags ====================
  
  /// Enable device preview in debug mode
  static bool get enableDevicePreview => kDebugMode;
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );
  
  // ==================== Database Configuration ====================
  
  static const String databaseName = String.fromEnvironment(
    'DATABASE_NAME',
    defaultValue: 'fitness_tracker.db',
  );
  
  static const int databaseVersion = int.fromEnvironment(
    'DATABASE_VERSION',
    defaultValue: 3,
  );
  
  // ==================== Seeding Configuration ====================
  
  /// Enable automatic database seeding on first launch
  /// Set to false in production to prevent accidental data seeding
  static const bool seedDefaultData = bool.fromEnvironment(
    'SEED_DEFAULT_DATA',
    defaultValue: true, // Default true for development convenience
  );
  
  /// Seed data version - increment when default data changes
  /// This allows re-seeding when seed data is updated
  static const int seedDataVersion = int.fromEnvironment(
    'SEED_DATA_VERSION',
    defaultValue: 1,
  );
  
  /// Enable detailed seeding logs for debugging
  static const bool enableSeedingLogs = bool.fromEnvironment(
    'ENABLE_SEEDING_LOGS',
    defaultValue: true, // Enabled in development by default
  );
  
  /// Force re-seeding even if data exists (dangerous in production!)
  /// Should ONLY be true in development/testing environments
  static const bool forceReseed = bool.fromEnvironment(
    'FORCE_RESEED',
    defaultValue: false,
  );
  
  // ==================== API Configuration ====================
  
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
  
  // ==================== Logging Configuration ====================
  
  /// Enable debug logging
  static bool get enableDebugLogs => isDevelopment || kDebugMode;
  
  /// Log level: 'verbose', 'debug', 'info', 'warning', 'error'
  static const String logLevel = String.fromEnvironment(
    'LOG_LEVEL',
    defaultValue: 'debug',
  );
  
  // ==================== Validation Helpers ====================
  
  /// Validate that production environment has correct settings
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
  
  /// Print current configuration (for debugging)
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
    debugPrint('==============================================');
  }
}
