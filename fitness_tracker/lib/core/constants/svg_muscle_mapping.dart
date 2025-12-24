class SvgMuscleMapping {
  SvgMuscleMapping._(); // Private constructor

  // ==================== FRONT VIEW MUSCLES ====================
  
  /// Muscles visible on front body diagram
  static const List<String> frontViewMuscles = [
    'front-delts',      // Front deltoids
    'side-delts',       // Side deltoids (partially visible)
    'upper-chest',      // Upper pectoralis major
    'mid-chest',        // Mid pectoralis major
    'lower-chest',      // Lower pectoralis major
    'biceps',           // Biceps brachii
    'forearms',         // Forearm flexors
    'abs',              // Rectus abdominis
    'obliques',         // External obliques
    'quads',            // Quadriceps femoris
  ];

  // ==================== BACK VIEW MUSCLES ====================
  
  /// Muscles visible on back body diagram
  static const List<String> backViewMuscles = [
    'rear-delts',       // Rear deltoids
    'side-delts',       // Side deltoids (partially visible)
    'upper-traps',      // Upper trapezius
    'middle-traps',     // Middle trapezius
    'lower-traps',      // Lower trapezius
    'lats',             // Latissimus dorsi
    'triceps',          // Triceps brachii
    'forearms',         // Forearm extensors
    'lower-back',       // Erector spinae
    'glutes',           // Gluteus maximus
    'hamstrings',       // Hamstring complex
    'calves',           // Gastrocnemius & soleus
  ];

  // ==================== SVG PATH MAPPING ====================
  
  /// Map muscle groups to SVG path IDs (to be filled after SVG analysis)
  /// 
  /// INSTRUCTIONS:
  /// 1. Open FrontLook.svg and BackLook.svg in a text editor
  /// 2. Identify <path> elements for each muscle region
  /// 3. Note the 'id' attribute or 'd' (path data) for each muscle
  /// 4. Update this map with actual SVG path identifiers
  /// 
  /// Example structure:
  /// 'front-delts': 'path-front-delts' or coordinates
  static const Map<String, String> svgPathIds = {
    // Front view paths
    'front-delts-front': 'TODO',
    'side-delts-front': 'TODO',
    'upper-chest-front': 'TODO',
    'mid-chest-front': 'TODO',
    'lower-chest-front': 'TODO',
    'biceps-front': 'TODO',
    'forearms-front': 'TODO',
    'abs-front': 'TODO',
    'obliques-front': 'TODO',
    'quads-front': 'TODO',
    
    // Back view paths
    'rear-delts-back': 'TODO',
    'side-delts-back': 'TODO',
    'upper-traps-back': 'TODO',
    'middle-traps-back': 'TODO',
    'lower-traps-back': 'TODO',
    'lats-back': 'TODO',
    'triceps-back': 'TODO',
    'forearms-back': 'TODO',
    'lower-back-back': 'TODO',
    'glutes-back': 'TODO',
    'hamstrings-back': 'TODO',
    'calves-back': 'TODO',
  };

  // ==================== BILATERAL MUSCLES ====================
  
  /// Muscles that appear on both sides (left/right)
  /// May need separate path IDs for left and right sides
  static const List<String> bilateralMuscles = [
    'front-delts',
    'side-delts',
    'rear-delts',
    'upper-chest',
    'mid-chest',
    'lower-chest',
    'lats',
    'biceps',
    'triceps',
    'forearms',
    'obliques',
    'glutes',
    'quads',
    'hamstrings',
    'calves',
  ];

  // ==================== MIDLINE MUSCLES ====================
  
  /// Muscles that are single/central (not bilateral)
  static const List<String> midlineMuscles = [
    'upper-traps',
    'middle-traps',
    'lower-traps',
    'abs',
    'lower-back',
  ];

  // ==================== COLOR APPLICATION ====================
  
  /// Get view type for a muscle group
  static String? getMuscleView(String muscleGroup) {
    if (frontViewMuscles.contains(muscleGroup)) {
      return 'front';
    } else if (backViewMuscles.contains(muscleGroup)) {
      return 'back';
    }
    return null; // Muscle not visible in either view
  }

  /// Check if muscle appears on front view
  static bool isVisibleOnFront(String muscleGroup) {
    return frontViewMuscles.contains(muscleGroup);
  }

  /// Check if muscle appears on back view
  static bool isVisibleOnBack(String muscleGroup) {
    return backViewMuscles.contains(muscleGroup);
  }

  /// Check if muscle is bilateral
  static bool isBilateral(String muscleGroup) {
    return bilateralMuscles.contains(muscleGroup);
  }

  /// Check if muscle is on midline
  static bool isMidline(String muscleGroup) {
    return midlineMuscles.contains(muscleGroup);
  }
}