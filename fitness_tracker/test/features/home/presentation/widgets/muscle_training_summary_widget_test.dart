import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_tracker/core/constants/app_strings.dart';
import 'package:fitness_tracker/presentation/pages/home/models/muscle_training_summary_view_data.dart';
import 'package:fitness_tracker/presentation/pages/home/widgets/muscle_training_summary_widget.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('MuscleTrainingSummaryWidget', () {
    testWidgets('shows empty state when there is no summary data',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(
            viewData: MuscleTrainingSummaryViewData.empty(),
          ),
        ),
      );

      expect(find.text(AppStrings.noMuscleActivityYet), findsOneWidget);
      expect(
        find.text(AppStrings.noMuscleActivityDescription),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows ranked muscles in display order', (tester) async {
      final viewData = MuscleTrainingSummaryViewData(
        trainedCount: 3,
        topFocusLabel: 'Lats',
        averageIntensityLabel: AppStrings.intensityHeavy,
        averageIntensityColor: Colors.orange,
        items: const [
          MuscleTrainingSummaryItem(
            displayName: 'Lats',
            stimulus: 20.0,
            visualIntensity: 0.85,
            color: Colors.red,
            intensityLabel: AppStrings.intensityMaximum,
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Mid Chest',
            stimulus: 12.0,
            visualIntensity: 0.55,
            color: Colors.orange,
            intensityLabel: AppStrings.intensityHeavy,
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Biceps',
            stimulus: 7.0,
            visualIntensity: 0.18,
            color: Colors.green,
            intensityLabel: AppStrings.intensityLight,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(viewData: viewData),
        ),
      );

      expect(find.text(AppStrings.trained), findsOneWidget);
      expect(find.text('3 ${AppStrings.musclesSuffix}'), findsOneWidget);
      expect(find.text(AppStrings.topFocus), findsOneWidget);
      expect(find.text(AppStrings.averageIntensity), findsOneWidget);

      final latsFinder = find.text('Lats');
      final chestFinder = find.text('Mid Chest');
      final bicepsFinder = find.text('Biceps');

      expect(latsFinder, findsOneWidget);
      expect(chestFinder, findsOneWidget);
      expect(bicepsFinder, findsOneWidget);

      expect(
        tester.getTopLeft(latsFinder).dy,
        lessThan(tester.getTopLeft(chestFinder).dy),
      );
      expect(
        tester.getTopLeft(chestFinder).dy,
        lessThan(tester.getTopLeft(bicepsFinder).dy),
      );

      expect(find.text('${AppStrings.stimulusLabel}: 20.0'), findsOneWidget);
      expect(find.text('${AppStrings.stimulusLabel}: 12.0'), findsOneWidget);
      expect(find.text('${AppStrings.stimulusLabel}: 7.0'), findsOneWidget);
    });

    testWidgets('shows correct intensity badges', (tester) async {
      final viewData = MuscleTrainingSummaryViewData(
        trainedCount: 4,
        topFocusLabel: 'Calves',
        averageIntensityLabel: AppStrings.intensityHeavy,
        averageIntensityColor: Colors.orange,
        items: const [
          MuscleTrainingSummaryItem(
            displayName: 'Biceps',
            stimulus: 5.0,
            visualIntensity: 0.10,
            color: Colors.green,
            intensityLabel: AppStrings.intensityLight,
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Quads',
            stimulus: 10.0,
            visualIntensity: 0.30,
            color: Colors.yellow,
            intensityLabel: AppStrings.intensityModerate,
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Mid Chest',
            stimulus: 14.0,
            visualIntensity: 0.55,
            color: Colors.orange,
            intensityLabel: AppStrings.intensityHeavy,
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Calves',
            stimulus: 18.0,
            visualIntensity: 0.85,
            color: Colors.red,
            intensityLabel: AppStrings.intensityMaximum,
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(viewData: viewData),
        ),
      );

      expect(find.text(AppStrings.intensityLight), findsOneWidget);
      expect(find.text(AppStrings.intensityModerate), findsOneWidget);
      expect(find.text(AppStrings.intensityHeavy), findsAtLeastNWidgets(2));
      expect(find.text(AppStrings.intensityMaximum), findsOneWidget);

      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });
  });
}