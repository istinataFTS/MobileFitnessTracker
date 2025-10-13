/// All application strings - centralized for easy maintenance and i18n
class AppStrings {
  AppStrings._();

  // Navigation
  static const String navHome = 'Home';
  static const String navLog = 'Log';
  static const String navHistory = 'History';
  static const String navExercises = 'Exercises';
  static const String navTargets = 'Targets';
  static const String navProfile = 'Profile';

  // Home Page
  static const String homeTitle = 'Home';
  static const String today = 'Today';
  static const String weeklyProgress = 'Weekly Progress';
  static const String setsCompleted = 'sets completed';
  static const String complete = 'Complete';
  static const String setsRemaining = 'sets remaining';
  static const String targetProgress = 'Target Progress';
  static const String noTargetsSet = 'No Targets Set';
  static const String addTargetsToTrack = 'Add targets to track your weekly progress';
  static const String noTargetsForProgress = 'Add targets to see your progress here';
  static const String targetCompleted = 'Target completed!';
  
  // Log Set Page
  static const String logSetTitle = 'Log Set';
  static const String selectExercise = 'Select Exercise';
  static const String noExercisesAvailable = 'No Exercises Available';
  static const String createExercisesFirst = 'Create exercises first in the Exercises tab';
  static const String exercise = 'Exercise';
  static const String reps = 'Reps';
  static const String weight = 'Weight (kg)';
  static const String muscleGroupsWorked = 'Muscle Groups Worked';
  static const String setWillCountToward = 'This set will count toward all muscle groups above';
  static const String workoutDate = 'Workout Date';
  static const String changeDate = 'Change';
  static const String logSetButton = 'Log Set';
  static const String setLoggedSuccess = 'Set logged successfully!';
  static const String countedFor = 'Counted for';
  
  // History Page
  static const String historyTitle = 'History';
  static const String noSetsLogged = 'No sets logged yet';
  static const String startLoggingSets = 'Start logging sets to see them here';
  static const String filterByMuscleGroup = 'Filter by Muscle Group';
  static const String all = 'All';
  static const String workoutDetails = 'Workout Details';
  static const String moreSets = 'more set';
  
  // Exercises Page
  static const String exercisesTitle = 'Exercises';
  static const String noExercisesYet = 'No Exercises Yet';
  static const String createExercisesDescription = 'Create exercises and assign muscle groups to track your workouts';
  static const String addExercise = 'Add Exercise';
  static const String addFirstExercise = 'Add Your First Exercise';
  static const String editExercise = 'Edit Exercise';
  static const String deleteExercise = 'Delete Exercise';
  static const String deleteExerciseConfirm = 'Delete exercise? This cannot be undone.';
  static const String exerciseAdded = 'added!';
  static const String exerciseUpdated = 'updated!';
  static const String exerciseDeleted = 'deleted';
  static const String exerciseName = 'Exercise Name';
  static const String exerciseNameHint = 'e.g., Bench Press';
  static const String muscleGroups = 'Muscle Groups';
  static const String aboutExercises = 'About Exercises';
  static const String aboutExercisesDescription = 
      'Create exercises and assign which muscle groups they work. '
      'When you log a set, it will count toward all assigned muscle groups.\n\n'
      'Example: Bench Press works Chest, Shoulders, and Triceps. '
      'Logging 1 set counts as 1 set for each muscle group.';
  
  // Targets Page
  static const String targetsTitle = 'Targets';
  static const String noTargetsYet = 'No Targets Yet';
  static const String noTargetsDescription = 
      'Add muscle groups you want to focus on and set weekly rep targets for each';
  static const String addFirstTarget = 'Add Your First Target';
  static const String addTarget = 'Add Target';
  static const String allMuscleGroupsAdded = 'All Muscle Groups Added';
  static const String selectMuscleGroup = 'Select Muscle Group';
  static const String weeklyRepGoal = 'Weekly Rep Goal';
  static const String editTarget = 'Edit';
  static const String removeTarget = 'Remove Target';
  static const String removeTargetConfirm = 'Remove from your targets?';
  static const String targetAdded = 'added to targets!';
  static const String targetUpdated = 'updated!';
  static const String targetRemoved = 'removed from targets';
  static const String setsPerWeek = 'sets per week';
  static const String sets = 'sets';
  static const String aboutTargets = 'About Targets';
  static const String aboutTargetsDescription = 
      'Targets let you focus on specific muscle groups. '
      'Add the muscles you want to train and set weekly rep goals for each. '
      'Track your progress on the home page!';
  
  // Profile Page
  static const String profileTitle = 'Profile';
  static const String fitnessEnthusiast = 'Fitness Enthusiast';
  static const String totalWorkouts = 'Total Workouts';
  static const String thisWeek = 'This Week';
  static const String streak = 'Streak';
  static const String workoutManagement = 'Workout Management';
  static const String manageExercises = 'Manage Exercises';
  static const String manageExercisesDesc = 'Create and edit exercises';
  static const String manageTargets = 'Manage Targets';
  static const String manageTargetsDesc = 'Set weekly muscle group goals';
  static const String settings = 'Settings';
  static const String settingsDesc = 'Weekly goals and preferences';
  static const String account = 'Account';
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';
  static const String notifications = 'Notifications';
  static const String preferences = 'Preferences';
  static const String theme = 'Theme';
  static const String dark = 'Dark';
  static const String language = 'Language';
  static const String english = 'English';
  static const String support = 'Support';
  static const String helpSupport = 'Help & Support';
  static const String sendFeedback = 'Send Feedback';
  static const String about = 'About';
  static const String version = 'Version';
  static const String signOut = 'Sign Out';
  
  // Settings Page
  static const String settingsTitle = 'Settings';
  static const String weeklyGoals = 'Weekly Goals';
  static const String muscleGroupGoals = 'Muscle Group Goals';
  static const String customizeWeeklyTargets = 'Customize your weekly set targets for each muscle group';
  static const String editGoals = 'Edit';
  static const String editWeeklyGoals = 'Edit Weekly Goals';
  static const String resetToDefault = 'Reset to Default';
  static const String goalsUpdated = 'Goals updated!';
  static const String general = 'General';
  static const String notificationsSettings = 'Notifications';
  static const String manageWorkoutReminders = 'Manage workout reminders';
  static const String weekStartDay = 'Week Start Day';
  static const String monday = 'Monday';
  static const String backupRestore = 'Backup & Restore';
  static const String exportImportData = 'Export or import your data';
  static const String appVersion = 'App Version';
  static const String termsPrivacy = 'Terms & Privacy';
  static const String reportBug = 'Report a Bug';
  
  // Common Actions
  static const String save = 'Save';
  static const String saveChanges = 'Save Changes';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String change = 'Change';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String close = 'Close';
  static const String gotIt = 'Got it';
  static const String comingSoon = 'Coming soon!';
  
  // Validation
  static const String required = 'Required';
  static const String invalid = 'Invalid';
  static const String pleaseSelectExercise = 'Please select an exercise';
  static const String pleaseSelectMuscleGroup = 'Please select a muscle group';
  
  // Date Formats (used with DateFormat)
  static const String dateFormatFull = 'EEEE, MMMM d, y';
  static const String dateFormatShort = 'EEEE, MMM d';
  static const String dateFormatTime = 'h:mm a';
  static const String dateFormatDate = 'MMMM d';
}