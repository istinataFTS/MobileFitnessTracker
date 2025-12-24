import 'package:flutter/foundation.dart';
import '../../config/env_config.dart';

/// Constants for muscle stimulus calculation and visualization system
/// All values are sourced from environmental configuration to avoid hardcoding
class MuscleStimulus {
  MuscleStimulus._(); // Private constructor to prevent instantiation

  // ==================== MUSCLE GROUPS ====================
  /// Complete list of 20 muscle groups for detailed tracking
  static const List<String> allMuscleGroups = [
    frontDelts,
    sideDelts,
    rearDelts,
    upperTraps,
    middleTraps,
    lowerTraps,
    upperChest,
    midChest,
    lowerChest,
    lats,
    biceps,
    triceps,
    forearms,
    abs,
    obliques,
    lowerBack,
    glutes,
    quads,
    hamstrings,
    calves,
  ];

  // Individual muscle group constants (kebab-case for database consistency)
  static const String frontDelts = 'front-delts';
  static const String sideDelts = 'side-delts';
  static const String rearDelts = 'rear-delts';
  static const String upperTraps = 'upper-traps';
  static const String middleTraps = 'middle-traps';
  static const String lowerTraps = 'lower-traps';
  static const String upperChest = 'upper-chest';
  static const String midChest = 'mid-chest';
  static const String lowerChest = 'lower-chest';
  static const String lats = 'lats';
  static const String biceps = 'biceps';
  static const String triceps = 'triceps';
  static const String forearms = 'forearms';
  static const String abs = 'abs';
  static const String obliques = 'obliques';
  static const String lowerBack = 'lower-back';
  static const String glutes = 'glutes';
  static const String quads = 'quads';
  static const String hamstrings = 'hamstrings';
  static const String calves = 'calves';

  // ==================== DISPLAY NAMES ====================
  /// User-friendly names for UI display
  static const Map<String, String> displayNames = {
    frontDelts: 'Front Delts',
    sideDelts: 'Side Delts',
    rearDelts: 'Rear Delts',
    upperTraps: 'Upper Traps',
    middleTraps: 'Middle Traps',
    lowerTraps: 'Lower Traps',
    upperChest: 'Upper Chest',
    midChest: 'Mid Chest',
    lowerChest: 'Lower Chest',
    lats: 'Lats',
    biceps: 'Biceps',
    triceps: 'Triceps',
    forearms: 'Forearms',
    abs: 'Abs',
    obliques: 'Obliques',
    lowerBack: 'Lower Back',
    glutes: 'Glutes',
    quads: 'Quads',
    hamstrings: 'Hamstrings',
    calves: 'Calves',
  };

  // ==================== RECOVERY RATES (k values) ====================
  /// Recovery decay rates for each muscle group (per hour)
  /// These determine how quickly stimulus decays based on muscle fiber composition
  /// Higher k = faster recovery (more fast-twitch), Lower k = slower recovery (more slow-twitch)
  static const Map<String, double> recoveryRates = {
    // Shoulders (moderate-fast recovery)
    frontDelts: 0.030,
    sideDelts: 0.030,
    rearDelts: 0.030,
    
    // Traps (moderate recovery)
    upperTraps: 0.028,
    middleTraps: 0.028,
    lowerTraps: 0.028,
    
    // Chest (moderate recovery)
    upperChest: 0.027,
    midChest: 0.027,
    lowerChest: 0.027,
    
    // Back (slower recovery, large muscles)
    lats: 0.024,
    lowerBack: 0.023,
    
    // Arms (faster recovery, smaller muscles)
    biceps: 0.032,
    triceps: 0.032,
    forearms: 0.035, // Very fast recovery
    
    // Core (very slow recovery, postural muscles)
    abs: 0.020,
    obliques: 0.020,
    
    // Legs (slowest recovery, largest muscles)
    glutes: 0.022,
    quads: 0.021,
    hamstrings: 0.022,
    calves: 0.033, // Faster recovery despite being legs
  };

  /// Default recovery rate for unknown muscles
  static const double defaultRecoveryRate = 0.025;

  // ==================== CALCULATION CONSTANTS ====================
  
  /// Intensity exponent for non-linear scaling
  /// Formula: (intensity / maxIntensity) ^ intensityExponent
  /// From env config to avoid hardcoding
  static double get intensityExponent => 
      const double.fromEnvironment('INTENSITY_EXPONENT', defaultValue: 1.35);

  /// Weekly decay factor applied to rolling weekly load each day
  /// From env config to avoid hardcoding
  static double get weeklyDecayFactor => 
      const double.fromEnvironment('WEEKLY_DECAY_FACTOR', defaultValue: 0.6);

  // ==================== INTENSITY LEVELS ====================
  
  /// Minimum intensity value
  static const int minIntensity = 0;
  
  /// Maximum intensity value
  static const int maxIntensity = 5;
  
  /// Default intensity when not specified
  static const int defaultIntensity = 3;

  /// Intensity level descriptions (full version for dialogs)
  static const Map<int, String> intensityDescriptions = {
    0: 'No effort - Warm-up sets, technique practice, or mobility work. Minimal muscle activation.',
    1: 'Very Light - Easy sets with high reps remaining. Low muscle engagement, recovery work.',
    2: 'Light - Moderate effort with several reps in reserve. Building volume without strain.',
    3: 'Moderate - Working sets with 2-3 reps in reserve (RIR). Solid muscle activation.',
    4: 'Hard - Challenging sets with 1-2 RIR. High muscle activation, approaching failure.',
    5: 'Maximum - All-out effort, 0 RIR or actual failure. Maximum muscle stimulus.',
  };

  /// Intensity level short labels (for UI sliders)
  static const Map<int, String> intensityLabels = {
    0: 'Warm-up',
    1: 'Very Light',
    2: 'Light',
    3: 'Moderate',
    4: 'Hard',
    5: 'Max Effort',
  };

  // ==================== VISUAL INTENSITY THRESHOLDS ====================
  
  /// Daily stimulus threshold for visual intensity calculation
  static double get dailyThreshold => 
      const double.fromEnvironment('DAILY_STIMULUS_THRESHOLD', defaultValue: 8.0);
  
  /// Weekly stimulus threshold for visual intensity calculation
  static double get weeklyThreshold => 
      const double.fromEnvironment('WEEKLY_STIMULUS_THRESHOLD', defaultValue: 25.0);
  
  /// Monthly stimulus threshold for visual intensity calculation
  static double get monthlyThreshold => 
      const double.fromEnvironment('MONTHLY_STIMULUS_THRESHOLD', defaultValue: 90.0);

  // ==================== COLOR THRESHOLDS ====================
  
  /// Visual intensity threshold for green color (0.0 - 0.20)
  static double get colorThresholdGreen => 
      const double.fromEnvironment('COLOR_THRESHOLD_GREEN', defaultValue: 0.20);
  
  /// Visual intensity threshold for yellow color (0.20 - 0.45)
  static double get colorThresholdYellow => 
      const double.fromEnvironment('COLOR_THRESHOLD_YELLOW', defaultValue: 0.45);
  
  /// Visual intensity threshold for orange color (0.45 - 0.70)
  static double get colorThresholdOrange => 
      const double.fromEnvironment('COLOR_THRESHOLD_ORANGE', defaultValue: 0.70);
  
  /// Visual intensity threshold for red color (0.70 - 1.0)
  /// Note: Red starts at orange threshold
  static double get colorThresholdRed => 
      const double.fromEnvironment('COLOR_THRESHOLD_RED', defaultValue: 0.70);

  // ==================== VALIDATION & HELPER METHODS ====================
  
  /// Validate if a muscle group name is valid
  static bool isValidMuscleGroup(String muscleGroup) {
    return allMuscleGroups.contains(muscleGroup.toLowerCase());
  }

  /// Get display name for a muscle group
  static String getDisplayName(String muscleGroup) {
    return displayNames[muscleGroup.toLowerCase()] ?? muscleGroup;
  }

  /// Get recovery rate for a muscle group (returns default if not found)
  static double getRecoveryRate(String muscleGroup) {
    return recoveryRates[muscleGroup.toLowerCase()] ?? defaultRecoveryRate;
  }

  /// Get intensity description
  static String getIntensityDescription(int intensity) {
    // Clamp intensity to valid range
    final clampedIntensity = intensity.clamp(minIntensity, maxIntensity);
    return intensityDescriptions[clampedIntensity] ?? 
           intensityDescriptions[defaultIntensity]!;
  }

  /// Get intensity label
  static String getIntensityLabel(int intensity) {
    // Clamp intensity to valid range
    final clampedIntensity = intensity.clamp(minIntensity, maxIntensity);
    return intensityLabels[clampedIntensity] ?? 
           intensityLabels[defaultIntensity]!;
  }

  /// Validate intensity value
  static bool isValidIntensity(int intensity) {
    return intensity >= minIntensity && intensity <= maxIntensity;
  }

  /// Clamp intensity to valid range
  static int clampIntensity(int intensity) {
    return intensity.clamp(minIntensity, maxIntensity);
  }

  // ==================== DEBUG & LOGGING ====================
  
  /// Print configuration (development only)
  static void printConfiguration() {
    if (!EnvConfig.enableDebugLogs) return;
    
    debugPrint('========== Muscle Stimulus Configuration ==========');
    debugPrint('Total Muscle Groups: ${allMuscleGroups.length}');
    debugPrint('Intensity Exponent: $intensityExponent');
    debugPrint('Weekly Decay Factor: $weeklyDecayFactor');
    debugPrint('');
    debugPrint('Visual Thresholds:');
    debugPrint('  Daily: $dailyThreshold');
    debugPrint('  Weekly: $weeklyThreshold');
    debugPrint('  Monthly: $monthlyThreshold');
    debugPrint('');
    debugPrint('Color Thresholds:');
    debugPrint('  Green: 0.0 - $colorThresholdGreen');
    debugPrint('  Yellow: $colorThresholdGreen - $colorThresholdYellow');
    debugPrint('  Orange: $colorThresholdYellow - $colorThresholdOrange');
    debugPrint('  Red: $colorThresholdOrange - 1.0');
    debugPrint('==================================================');
  }
}