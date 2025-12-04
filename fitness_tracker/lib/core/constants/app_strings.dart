class AppStrings {
  AppStrings._();

  // ==================== App Information ====================
  static const String appName = 'Fitness Tracker';
  static const String appVersion = '1.0.0';
  static const String version = 'Version';

  // ==================== General Actions ====================
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String saveChanges = 'Save Changes';
  static const String ok = 'OK';
  static const String confirm = 'Confirm';
  static const String done = 'Done';
  static const String close = 'Close';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String remove = 'Remove';
  static const String gotIt = 'Got it';
  static const String all = 'All';
  static const String required = 'Required';
  static const String invalid = 'Invalid';

  // ==================== Web Platform Messages ====================
  static const String webMobileOnlyTitle = 'Mobile Only App';
  static const String webMobileOnlyDescription = 
      'This fitness tracker is designed for mobile devices.';
  static const String webMobileOnlyInstruction = 
      'Please install the app on your Android or iOS device.';

  // ==================== Error Messages ====================
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorLoadData = 'Failed to load data';
  static const String errorSaveData = 'Failed to save data';
  static const String errorDeleteData = 'Failed to delete data';
  static const String errorUpdateData = 'Failed to update data';
  static const String errorNetwork = 'Network connection failed';
  static const String errorDatabase = 'Database error occurred';
  static const String successSetLogged = 'Set logged successfully';
  static const String comingSoon = 'Coming soon!';

  // ==================== Navigation ====================
  static const String home = 'Home';
  static const String log = 'Log';
  static const String history = 'History';
  static const String library = 'Library';
  static const String profile = 'Profile';

  // ==================== Exercises ====================
  static const String exercisesTitle = 'Exercises';
  static const String addExercise = 'Add Exercise';
  static const String editExercise = 'Edit Exercise';
  static const String deleteExercise = 'Delete Exercise';
  static const String exerciseName = 'Exercise Name';
  static const String exerciseNameHint = 'e.g., Bench Press';
  static const String muscleGroup = 'Muscle Group';
  static const String selectMuscleGroup = 'Select Muscle Group';
  static const String addFirstExercise = 'Add Your First Exercise';
  static const String noExercisesYet = 'No exercises yet';
  static const String createExercisesDescription = 'Create custom exercises to start logging workouts';
  static const String aboutExercises = 'About Exercises';
  static const String aboutExercisesDescription = 'Build your personal exercise library for workout tracking';
  static const String deleteExerciseConfirm = 'Are you sure you want to delete this exercise?';
  static const String noExercisesAvailable = 'No exercises available';
  static const String createExercisesFirst = 'Create some exercises first to start logging workouts';
  
  // ==================== Meals ====================
  static const String mealsTitle = 'Meals';
  static const String addMeal = 'Add Meal';
  static const String editMeal = 'Edit Meal';
  static const String deleteMeal = 'Delete Meal';
  static const String mealName = 'Meal Name';
  static const String mealNameHint = 'e.g., Chicken Breast';
  static const String addFirstMeal = 'Add Your First Meal';
  static const String noMealsYet = 'No meals yet';
  static const String createMealsDescription = 'Create custom meals with their macros for easy logging';
  static const String aboutMeals = 'About Meals';
  static const String aboutMealsDescription = 'Create a library of meals with their nutritional information for quick logging';
  static const String deleteMealConfirm = 'Are you sure you want to delete this meal?';
  static const String servingSize = 'Serving Size';
  static const String servingSizeHint = '100';
  static const String per100g = 'per 100g';
  static const String macrosPerServing = 'Macros per Serving';
  
  // ==================== Macros ====================
  static const String protein = 'Protein';
  static const String carbs = 'Carbs';
  static const String fats = 'Fats';
  static const String calories = 'Calories';
  static const String proteinGrams = 'Protein (g)';
  static const String carbsGrams = 'Carbs (g)';
  static const String fatsGrams = 'Fats (g)';
  static const String caloriesKcal = 'Calories (kcal)';
  static const String totalCalories = 'Total Calories';
  static const String macroBreakdown = 'Macro Breakdown';
  static const String autocalculated = 'Auto-calculated';
  static const String grams = 'g';
  static const String kcal = 'kcal';
  
  // ==================== Calorie Information ====================
  /// Energy content per gram of macronutrients
  static const String caloriesPerGramProtein = '4 kcal per gram';
  static const String caloriesPerGramCarbs = '4 kcal per gram';
  static const String caloriesPerGramFats = '9 kcal per gram';
  
  /// Short format for calorie descriptions
  static const String proteinCalories = '4 kcal/g';
  static const String carbsCalories = '4 kcal/g';
  static const String fatsCalories = '9 kcal/g';

  // ==================== Log Page ====================
  static const String logTitle = 'Log Workout';
  static const String selectExercise = 'Select Exercise';
  static const String searchExercises = 'Search exercises...';
  static const String weight = 'Weight';
  static const String weightKg = 'Weight (kg)';
  static const String reps = 'Reps';
  static const String logSet = 'Log Set';
  static const String logExerciseTab = 'Exercise';
  static const String logMealTab = 'Meal';
  static const String logMacrosTab = 'Macros';
  
  // ==================== Meal Logging ====================
  static const String selectMeal = 'Select Meal';
  static const String searchMeals = 'Search meals...';
  static const String amountGrams = 'Amount (g)';
  static const String amountGramsHint = 'e.g., 150';
  static const String logMealButton = 'Log Meal';
  static const String mealLogged = 'Meal logged successfully';
  static const String noMealsInLibrary = 'No meals in library';
  static const String addMealsToLibrary = 'Add meals to your library first';
  static const String createMealsInLibrary = 'Create meals in Library to start logging';
  static const String nutritionFor = 'Nutrition for'; // Used in "Nutrition for Xg"
  
  // ==================== Direct Macro Logging ====================
  static const String logMacrosTitle = 'Log Macros';
  static const String logMacrosButton = 'Log Macros';
  static const String enterMacros = 'Enter Macros';
  static const String macrosLogged = 'Macros logged successfully';
  static const String enterProtein = 'Enter protein';
  static const String enterCarbs = 'Enter carbs';
  static const String enterFats = 'Enter fats';

  // ==================== History ====================
  static const String historyTitle = 'History';
  static const String todayTitle = 'Today';
  static const String noWorkoutsToday = 'No workouts today';
  static const String noWorkoutsYet = 'No workouts yet';
  static const String startLoggingSets = 'Start logging sets to see your history';
  static const String sets = 'sets';
  static const String viewAll = 'View All';
  static const String recentWorkouts = 'Recent Workouts';

  // ==================== Home ====================
  static const String homeTitle = 'Home';
  static const String welcome = 'Welcome';
  static const String weeklyProgress = 'Weekly Progress';
  static const String quickActions = 'Quick Actions';
  static const String todayWorkout = "Today's Workout";
  static const String recentActivity = 'Recent Activity';
  static const String logWorkout = 'Log Workout';
  static const String viewHistory = 'View History';
  static const String manageTargets = 'Manage Targets';
  static const String manageTargetsDesc = 'Set and track weekly muscle group goals';

  // ==================== Targets ====================
  static const String targetsTitle = 'Targets';
  static const String addTarget = 'Add Target';
  static const String editTarget = 'Edit Target';
  static const String deleteTarget = 'Delete Target';
  static const String targetMuscleGroup = 'Muscle Group';
  static const String targetWeeklyGoal = 'Weekly Goal';
  static const String targetProgress = 'Progress';
  static const String targetCompleted = 'Completed';
  static const String targetInProgress = 'In Progress';
  static const String noTargetsYet = 'No targets yet';
  static const String noTargetsDescription = 'Set weekly goals for muscle groups to track your progress';
  static const String createTargetsDescription = 'Set weekly goals for each muscle group';
  static const String aboutTargets = 'About Targets';
  static const String aboutTargetsDescription = 'Set weekly goals for muscle groups and track your progress';
  static const String targetDeleteConfirm = 'Delete this target?';
  static const String setsThisWeek = 'sets this week';

  // ==================== Profile/Settings ====================
  static const String profileTitle = 'Profile';
  static const String settingsTitle = 'Settings';
  static const String settings = 'Settings';
  static const String settingsDesc = 'App preferences and configuration';
  static const String settingsAccount = 'Account';
  static const String settingsPreferences = 'Preferences';
  static const String settingsAbout = 'About';
  static const String settingsHelp = 'Help & Support';
  static const String settingsFeedback = 'Send Feedback';
  static const String settingsPrivacy = 'Privacy Policy';
  static const String settingsTerms = 'Terms of Service';
  static const String settingsClearData = 'Clear All Data';
  static const String settingsExportData = 'Export Data';
  static const String settingsImportData = 'Import Data';
  static const String settingsNotifications = 'Notifications';
  static const String notifications = 'Notifications';
  static const String settingsTheme = 'Theme';
  static const String theme = 'Theme';
  static const String dark = 'Dark';
  static const String language = 'Language';
  static const String english = 'English';
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';
  static const String helpSupport = 'Help & Support';
  static const String sendFeedback = 'Send Feedback';
  static const String about = 'About';
  static const String signOut = 'Sign Out';
  static const String account = 'Account';
  static const String preferences = 'Preferences';
  static const String support = 'Support';
  static const String workoutManagement = 'Workout Management';
  static const String fitnessEnthusiast = 'Fitness Enthusiast';
  static const String totalWorkouts = 'Total Workouts';
  static const String thisWeek = 'This Week';
  static const String streak = 'Streak';
  
  // ==================== Muscle Groups ====================
  static const String muscleChest = 'Chest';
  static const String muscleBack = 'Back';
  static const String muscleShoulders = 'Shoulders';
  static const String muscleBiceps = 'Biceps';
  static const String muscleTriceps = 'Triceps';
  static const String muscleQuads = 'Quads';
  static const String muscleHamstring = 'Hamstring';
  static const String muscleGlutes = 'Glutes';
  static const String muscleCalves = 'Calves';
  static const String muscleAbs = 'Abs';
  static const String muscleObliques = 'Obliques';
  static const String muscleTraps = 'Traps';

  // ==================== Units ====================
  static const String unitKg = 'kg';
  static const String unitLbs = 'lbs';
  static const String unitReps = 'reps';
  static const String unitSets = 'sets';

  // ==================== Time ====================
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String thisWeekLower = 'this week';
  static const String lastWeek = 'Last Week';
  static const String thisMonth = 'This Month';
  static const String lastMonth = 'Last Month';

  // ==================== Empty States ====================
  static const String noDataAvailable = 'No data available';
  static const String noResultsFound = 'No results found';
  static const String trySearchingAgain = 'Try searching again';
  static const String emptyLibrary = 'Your library is empty';
  static const String getStarted = 'Get Started';
  
  // ==================== Validation Messages ====================
  static const String fieldRequired = 'This field is required';
  static const String invalidNumber = 'Please enter a valid number';
  static const String invalidEmail = 'Please enter a valid email';
  static const String valueTooLow = 'Value is too low';
  static const String valueTooHigh = 'Value is too high';
  static const String nameTooLong = 'Name is too long';
  
  // ==================== Success Messages ====================
  static const String savedSuccessfully = 'Saved successfully';
  static const String deletedSuccessfully = 'Deleted successfully';
  static const String updatedSuccessfully = 'Updated successfully';

  // ==================== Confirmation Messages ====================
  static const String areYouSure = 'Are you sure?';
  static const String cannotBeUndone = 'This action cannot be undone';
  static const String deleteConfirmation = 'Are you sure you want to delete this?';
}