/// All application strings in one place
/// Use environment variables for user-facing strings that might change
class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Fitness Tracker',
  );

  // Targets Page
  static const String targetsTitle = 'Targets';
  static const String noTargetsTitle = 'No Targets Yet';
  static const String noTargetsMessage =
      'Add muscle groups you want to focus on and set weekly rep targets for each';
  static const String addFirstTarget = 'Add Your First Target';
  static const String addTarget = 'Add Target';
  static const String allMuscleGroupsAdded = 'All Muscle Groups Added';
  static const String selectMuscleGroup = 'Select Muscle Group';
  static const String weeklyRepGoal = 'Weekly Rep Goal';
  static const String editTarget = 'Edit';
  static const String removeTarget = 'Remove Target';
  static const String targetAdded = 'added to targets!';
  static const String targetUpdated = 'updated!';
  static const String targetRemoved = 'removed from targets';
  static const String setsPerWeek = 'sets per week';
  static const String sets = 'sets';

  // Log Set Page
  static const String logSetTitle = 'Log Set';
  static const String workoutDate = 'Workout Date';
  static const String muscleGroup = 'Muscle Group';
  static const String exerciseName = 'Exercise Name';
  static const String exerciseNameHint = 'e.g., Bench Press';
  static const String reps = 'Reps';
  static const String weight = 'Weight (kg)';
  static const String weeklyProgress = 'Weekly Progress';
  static const String noTargetSet = 'No target set for';
  static const String setLogged = 'Set logged:';
  static const String logSet = 'Log Set';

  // Home Page
  static const String home = 'Home';
  static const String today = 'Today';
  static const String noTargetsSetHome = 'No Targets Set';
  static const String addTargetsMessage = 'Add targets to track your weekly progress';
  static const String weeklyProgressTitle = 'Weekly Progress';
  static const String setsCompleted = 'sets completed';
  static const String complete = 'Complete';
  static const String setsRemaining = 'sets remaining';
  static const String targetProgress = 'Target Progress';
  static const String addTargetsToSeeProgress = 'Add targets to see your progress here';
  static const String targetCompleted = 'Target completed!';

  // History Page
  static const String historyTitle = 'History';
  static const String noSetsLogged = 'No sets logged yet';
  static const String startLoggingSets = 'Start logging sets to see them here';
  static const String filterByMuscleGroup = 'Filter by Muscle Group';
  static const String all = 'All';
  static const String workoutDetails = 'Workout Details';
  static const String moreSets = 'more set';

  // Profile Page
  static const String profileTitle = 'Profile';
  static const String fitnessEnthusiast = 'Fitness Enthusiast';
  static const String totalWorkouts = 'Total Workouts';
  static const String thisWeek = 'This Week';
  static const String streak = 'Streak';
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
  static const String helpAndSupport = 'Help & Support';
  static const String sendFeedback = 'Send Feedback';
  static const String about = 'About';
  static const String version = 'Version';
  static const String signOut = 'Sign Out';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String change = 'Change';
  static const String add = 'Add';
  static const String remove = 'Remove';
  static const String comingSoon = 'Coming soon!';
  static const String gotIt = 'Got it';
  static const String close = 'Close';
  static const String required = 'Required';
  static const String invalid = 'Invalid';

  // Validation
  static const String pleaseSelectMuscleGroup = 'Please select a muscle group';
  static const String pleaseEnterExerciseName = 'Please enter exercise name';

  // Date Formats
  static const String dateFormatFull = 'EEEE, MMMM d, y';
  static const String dateFormatShort = 'EEEE, MMM d';
  static const String dateFormatTime = 'h:mm a';
  static const String dateFormatDate = 'EEEE, MMMM d';
}