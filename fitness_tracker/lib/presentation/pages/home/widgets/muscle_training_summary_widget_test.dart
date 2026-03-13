import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

      expect(find.text('No muscle activity yet'), findsOneWidget);
      expect(
        find.text(
          'Complete some training and your top muscle groups will appear here.',
        ),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows ranked muscles in display order', (tester) async {
      final viewData = MuscleTrainingSummaryViewData(
        trainedCount: 3,
        topFocusLabel: 'Lats',
        averageIntensityLabel: 'Heavy',
        averageIntensityColor: Colors.orange,
        items: const [
          MuscleTrainingSummaryItem(
            displayName: 'Lats',
            stimulus: 20.0,
            visualIntensity: 0.85,
            color: Colors.red,
            intensityLabel: 'Maximum',
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Mid Chest',
            stimulus: 12.0,
            visualIntensity: 0.55,
            color: Colors.orange,
            intensityLabel: 'Heavy',
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Biceps',
            stimulus: 7.0,
            visualIntensity: 0.18,
            color: Colors.green,
            intensityLabel: 'Light',
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(viewData: viewData),
        ),
      );

      expect(find.text('Trained'), findsOneWidget);
      expect(find.text('3 muscles'), findsOneWidget);
      expect(find.text('Top focus'), findsOneWidget);
      expect(find.text('Avg intensity'), findsOneWidget);

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

      expect(find.text('Stimulus: 20.0'), findsOneWidget);
      expect(find.text('Stimulus: 12.0'), findsOneWidget);
      expect(find.text('Stimulus: 7.0'), findsOneWidget);
    });

    testWidgets('shows correct intensity badges', (tester) async {
      final viewData = MuscleTrainingSummaryViewData(
        trainedCount: 4,
        topFocusLabel: 'Calves',
        averageIntensityLabel: 'Heavy',
        averageIntensityColor: Colors.orange,
        items: const [
          MuscleTrainingSummaryItem(
            displayName: 'Biceps',
            stimulus: 5.0,
            visualIntensity: 0.10,
            color: Colors.green,
            intensityLabel: 'Light',
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Quads',
            stimulus: 10.0,
            visualIntensity: 0.30,
            color: Colors.yellow,
            intensityLabel: 'Moderate',
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Mid Chest',
            stimulus: 14.0,
            visualIntensity: 0.55,
            color: Colors.orange,
            intensityLabel: 'Heavy',
          ),
          MuscleTrainingSummaryItem(
            displayName: 'Calves',
            stimulus: 18.0,
            visualIntensity: 0.85,
            color: Colors.red,
            intensityLabel: 'Maximum',
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(viewData: viewData),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Heavy'), findsAtLeastNWidgets(2));
      expect(find.text('Maximum'), findsOneWidget);

      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });
  });
}