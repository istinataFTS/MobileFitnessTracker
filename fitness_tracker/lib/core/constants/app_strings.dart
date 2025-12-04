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
  
  // ==================== Home Screen ====================
  static const String homeTitle = 'Fitness Tracker';
  static const String homeWeeklySummary = 'Weekly Summary';
  static const String homeQuickActions = 'Quick Actions';
  static const String homeRecentActivity = 'Recent Activity';
  static const String homeNoData = 'No workout data yet';
  static const String homeGetStarted = 'Start logging workouts to see your progress';

  // ==================== Navigation ====================
  static const String navHome = 'Home';
  static const String navLog = 'Log';
  static const String navHistory = 'History';
  static const String navExercises = 'Exercises';
  static const String navLibrary = 'Library';
  static const String navTargets = 'Targets';
  static const String navProfile = 'Profile';

  // ==================== Library Page ====================
  static const String libraryTitle = 'Library';
  static const String exercisesTab = 'Exercises';
  static const String mealsTab = 'Meals';
  
  // ==================== Exercises ====================
  static const String exercisesTitle = 'Exercises';
  static const String addNewExercise = 'Add New Exercise';
  static const String editExercise = 'Edit Exercise';
  static const String exercisesName = 'Exercise Name';
  static const String exercisesSelectMuscles = 'Select Muscle Groups';
  static const String exercise = 'Exercise';
  static const String addExercise = 'Add Exercise';
  static const String addFirstExercise = 'Add Your First Exercise';
  static const String deleteExercise = 'Delete Exercise';
  static const String noExercisesYet = 'No exercises yet';
  static const String createExercisesDescription = 'Create custom exercises to track your workouts';
  static const String exerciseName = 'Exercise Name';
  static const String exerciseNameHint = 'e.g., Bench Press';
  static const String muscleGroups = 'Muscle Groups';
  static const String selectExercise = 'Select Exercise';
  static const String muscleGroupsWorked = 'Muscle Groups Worked';
  static const String aboutExercises = 'About Exercises';
  static const String aboutExercisesDescription = 'Create custom exercises and assign them to muscle groups for better tracking';
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
  static const String selectMuscleGroup = 'Select Muscle Group';
  static const String weeklyRepGoal = 'Weekly Rep Goal';
  static const String setsPerWeek = 'sets/week';
  static const String removeTarget = 'Remove Target';
  static const String removeTargetConfirm = 'Are you sure you want to remove this target?';
  static const String allMuscleGroupsAdded = 'All muscle groups have targets';
  static const String manageTargets = 'Manage Targets';
  static const String manageTargetsDesc = 'Set and edit your weekly muscle group goals';

  // ==================== History ====================
  static const String historyTitle = 'History';
  static const String historyEmpty = 'No workout history';
  static const String historyEmptyDescription = 'Start logging sets to build your history';
  static const String viewHistory = 'View History';
  static const String noSetsLogged = 'No sets logged yet';
  static const String startLoggingSets = 'Start logging sets to track your progress';
  static const String filterByMuscle = 'Filter by muscle';
  static const String filterByDate = 'Filter by date';
  static const String showAll = 'Show All';

  // ==================== Log Page ====================
  static const String logTitle = 'Log';
  static const String logExerciseTab = 'Exercise';
  static const String logMealTab = 'Meal';
  static const String logMacrosTab = 'Macros';
  
  // ==================== Workout Logging ====================
  static const String logSetTitle = 'Log Workout Set';
  static const String logSetExercise = 'Exercise';
  static const String logSetReps = 'Reps';
  static const String logSetWeight = 'Weight';
  static const String logSetDate = 'Date';
  static const String logSetButton = 'Log Set';
  static const String reps = 'Reps';
  static const String weight = 'Weight';
  static const String workoutDate = 'Workout Date';
  static const String setWillCountToward = 'This set will count toward:';
  static const String countedFor = 'Counted for';
  
  // ==================== Meal Logging ====================
  static const String logMealTitle = 'Log Meal';
  static const String selectMeal = 'Select Meal';
  static const String searchMeals = 'Search meals...';
  static const String amountGrams = 'Amount (g)';
  static const String amountGramsHint = 'e.g., 150';
  static const String logMealButton = 'Log Meal';
  static const String mealLogged = 'Meal logged successfully';
  static const String noMealsInLibrary = 'No meals in library';
  static const String addMealsToLibrary = 'Add meals to your library first';
  static const String createMealsInLibrary = 'Create meals in Library to start logging';
  
  // ==================== Direct Macro Logging ====================
  static const String logMacrosTitle = 'Log Macros';
  static const String logMacrosButton = 'Log Macros';
  static const String enterMacros = 'Enter Macros';
  static const String macrosLogged = 'Macros logged successfully';
  static const String enterProtein = 'Enter protein';
  static const String enterCarbs = 'Enter carbs';
  static const String enterFats = 'Enter fats';
  
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
  
  // ==================== Time/Date ====================
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String thisWeek = 'This Week';
  static const String lastWeek = 'Last Week';
  static const String thisMonth = 'This Month';
  static const String dateFormatDate = 'MMM d';
  static const String dateFormatFull = 'EEEE, MMM d, yyyy';

  // ==================== Calendar Navigation ====================
  static const String goToToday = 'Go to Today';
  static const String previousMonth = 'Previous Month';
  static const String nextMonth = 'Next Month';
  
  // ==================== Calendar View ====================
  static const String selectDate = 'Select a date';
  static const String noWorkoutsOnDate = 'No workouts logged on this date';
  static const String workoutsOnDate = 'Workouts on';
  
  // ==================== Day Details ====================
  static const String setsLogged = 'sets logged';
  static const String setLogged = 'set logged';
  static const String totalVolume = 'Total Volume';
  static const String exercisesTrained = 'Exercises Trained';
  
  // ==================== Actions ====================
  static const String editSet = 'Edit Set';
  static const String deleteSet = 'Delete Set';
  static const String logWorkoutHere = 'Log Workout';
  static const String addWorkout = 'Add Workout';
  
  // ==================== Edit Dialog ====================
  static const String editWorkoutSet = 'Edit Workout Set';
  static const String updateSet = 'Update Set';
  static const String cancelEdit = 'Cancel';
  
  // ==================== Confirmations ====================
  static const String deleteSetConfirm = 'Delete this set?';
  static const String deleteSetMessage = 'This action cannot be undone.';
  static const String setUpdatedSuccess = 'Set updated successfully';
  static const String setDeletedSuccess = 'Set deleted successfully';
  
  // ==================== Weekdays (Short) ====================
  static const String sun = 'S';
  static const String mon = 'M';
  static const String tue = 'T';
  static const String wed = 'W';
  static const String thu = 'T';
  static const String fri = 'F';
  static const String sat = 'S';
  
  // ==================== Weekdays (Full) ====================
  static const String sunday = 'Sunday';
  static const String monday = 'Monday';
  static const String tuesday = 'Tuesday';
  static const String wednesday = 'Wednesday';
  static const String thursday = 'Thursday';
  static const String friday = 'Friday';
  static const String saturday = 'Saturday';
}