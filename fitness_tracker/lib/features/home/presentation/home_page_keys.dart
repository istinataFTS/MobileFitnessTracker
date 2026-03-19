import 'package:flutter/material.dart';

class HomePageKeys {
  const HomePageKeys._();

  static const Key pageLoadingIndicatorKey = ValueKey<String>(
    'home_page_loading_indicator',
  );
  static const Key refreshListKey = ValueKey<String>(
    'home_refresh_list',
  );
  static const Key progressCardKey = ValueKey<String>(
    'home_progress_card',
  );
  static const Key progressLoadingIndicatorKey = ValueKey<String>(
    'home_progress_loading_indicator',
  );
  static const Key progressRetryButtonKey = ValueKey<String>(
    'home_progress_retry_button',
  );
  static const Key homeRetryButtonKey = ValueKey<String>(
    'home_page_retry_button',
  );
  static const Key nutritionEmptyStateKey = ValueKey<String>(
    'home_nutrition_empty_state',
  );
  static const Key latestEntriesSectionKey = ValueKey<String>(
    'home_latest_entries_section',
  );
  static const Key muscleGroupsSectionKey = ValueKey<String>(
    'home_muscle_groups_section',
  );
  static const Key totalSetsValueKey = ValueKey<String>(
    'home_total_sets_value',
  );
  static const Key targetValueKey = ValueKey<String>(
    'home_target_value',
  );
  static const Key trainedMusclesValueKey = ValueKey<String>(
    'home_trained_muscles_value',
  );
}