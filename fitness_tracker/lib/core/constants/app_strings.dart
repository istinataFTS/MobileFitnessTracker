/// Centralized application strings for user-facing text
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
  static const String errorDatabaseConnection = 'Database connection error';
  static const String errorNoInternet = 'No internet connection';
  static const String errorTimeout = 'Request timed out';
  
  // ==================== Success Messages ====================
  static const String successSaved = 'Saved successfully';
  static const String successDeleted = 'Deleted successfully';
  static const String successUpdated = 'Updated successfully';
  static const String successSetLogged = 'Set logged successfully';
  static const String setLoggedSuccess = 'Set logged successfully';
  static const String successExerciseAdded = 'Exercise added successfully';
  static const String successTargetSet = 'Target set successfully';

  // ==================== Validation Messages ====================
  static const String validationRequired = 'This field is required';
  static const String required = 'Required';
  static const String validationInvalidNumber = 'Please enter a valid number';
  static const String invalid = 'Invalid';
  static const String validationMinValue = 'Value must be greater than 0';
  static const String validationMaxLength = 'Text is too long';
  static const String validationDuplicate = 'This already exists';

  // ==================== Loading States ====================
  static const String loadingData = 'Loading...';
  static const String loadingPleaseWait = 'Please wait...';
  static const String processingRequest = 'Processing...';

  // ==================== Empty States ====================
  static const String emptyNoData = 'No data available';
  static const String emptyNoExercises = 'No exercises found';
  static const String noExercisesAvailable = 'No exercises available';
  static const String createExercisesFirst = 'Create exercises first in the Exercises tab';
  static const String emptyNoWorkoutSets = 'No workout sets recorded yet';
  static const String emptyNoTargets = 'No targets set';
  static const String emptyStartTracking = 'Start tracking your workouts!';
  static const String noSetsLogged = 'No workout sets logged yet';
  static const String startLoggingSets = 'Start logging your workout sets!';
  static const String comingSoon = 'Coming soon!';

  // ==================== Confirmation Messages ====================
  static const String confirmDelete = 'Are you sure you want to delete this?';
  static const String confirmDeleteExercise = 'Delete this exercise?';
  static const String deleteExerciseConfirm = 'Are you sure you want to delete this exercise?';
  static const String confirmDeleteSet = 'Delete this workout set?';
  static const String confirmDeleteTarget = 'Delete this target?';
  static const String confirmClearAll = 'Clear all data?';
  static const String removeTargetConfirm = 'Remove this target?';

  // ==================== Navigation ====================
  static const String navHome = 'Home';
  static const String navLog = 'Log';
  static const String navHistory = 'History';
  static const String navExercises = 'Exercises';
  static const String navTargets = 'Targets';
  static const String navProfile = 'Profile';
  static const String navSettings = 'Settings';

  // ==================== Feature Specific ====================
  
  // Targets
  static const String targetsTitle = 'Weekly Targets';
  static const String targetsSetGoal = 'Set Weekly Goal';
  static const String targetsWeeklySets = 'sets per week';
  static const String setsPerWeek = 'sets/week';
  static const String targetsMuscleGroup = 'Muscle Group';
  static const String addTarget = 'Add Target';
  static const String addFirstTarget = 'Add Your First Target';
  static const String editTarget = 'Edit Target';
  static const String removeTarget = 'Remove Target';
  static const String noTargetsYet = 'No targets set yet';
  static const String noTargetsDescription = 'Set weekly goals for muscle groups to track your progress';
  static const String allMuscleGroupsAdded = 'All muscle groups have targets';
  static const String selectMuscleGroup = 'Select Muscle Group';
  static const String weeklyRepGoal = 'Weekly Set Goal';
  static const String aboutTargets = 'About Targets';
  static const String aboutTargetsDescription = 'Set weekly goals for each muscle group to stay on track with your fitness routine';
  
  // Exercises
  static const String exercisesTitle = 'Exercises';
  static const String exercisesAddNew = 'Add New Exercise';
  static const String exercisesEditExercise = 'Edit Exercise';
  static const String exercisesName = 'Exercise Name';
  static const String exercisesSelectMuscles = 'Select Muscle Groups';
  static const String exercise = 'Exercise';
  static const String addExercise = 'Add Exercise';
  static const String addFirstExercise = 'Add Your First Exercise';
  static const String editExercise = 'Edit Exercise';
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
  
  // Workout Logging
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
  
  // History
  static const String historyTitle = 'Workout History';
  static const String historyFilterByDate = 'Filter by Date';
  static const String historyNoSets = 'No workout sets recorded';
  static const String workoutDetails = 'Workout Details';
  static const String filterByMuscleGroup = 'Filter by Muscle Group';
  
  // Profile
  static const String profileTitle = 'Profile';
  static const String profileEditProfile = 'Edit Profile';
  static const String editProfile = 'Edit Profile';
  static const String profileSettings = 'Settings';
  static const String profileAbout = 'About';
  static const String about = 'About';
  static const String fitnessEnthusiast = 'Fitness Enthusiast';
  static const String totalWorkouts = 'Total Workouts';
  static const String streak = 'Day Streak';
  static const String signOut = 'Sign Out';
  
  // Profile Sections
  static const String workoutManagement = 'Workout Management';
  static const String manageTargets = 'Manage Targets';
  static const String manageTargetsDesc = 'Set and track your weekly muscle group goals';
  static const String account = 'Account';
  static const String changePassword = 'Change Password';
  static const String preferences = 'Preferences';
  static const String support = 'Support';
  static const String helpSupport = 'Help & Support';
  static const String sendFeedback = 'Send Feedback';
  
  // Settings
  static const String settingsTitle = 'Settings';
  static const String settings = 'Settings';
  static const String settingsDesc = 'App preferences and options';
  static const String settingsGeneral = 'General';
  static const String settingsDatabase = 'Database';
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
}