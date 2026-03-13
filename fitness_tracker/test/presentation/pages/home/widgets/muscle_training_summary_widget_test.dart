import 'package:fitness_tracker/domain/entities/muscle_visual_data.dart';
import 'package:fitness_tracker/presentation/pages/home/widgets/muscle_training_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('MuscleTrainingSummaryWidget', () {
    testWidgets('shows empty state when no trained muscle data exists',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MuscleTrainingSummaryWidget(
            muscleData: {},
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

    testWidgets('shows trained muscles sorted by total stimulus descending',
        (tester) async {
      final back = const MuscleVisualData(
        muscleGroup: 'lats',
        totalStimulus: 20.0,
        visualIntensity: 0.85,
        color: Colors.red,
        hasTrained: true,
      );

      final chest = const MuscleVisualData(
        muscleGroup: 'mid-chest',
        totalStimulus: 12.0,
        visualIntensity: 0.55,
        color: Colors.orange,
        hasTrained: true,
      );

      final biceps = const MuscleVisualData(
        muscleGroup: 'biceps',
        totalStimulus: 7.0,
        visualIntensity: 0.18,
        color: Colors.green,
        hasTrained: true,
      );

      final muscleData = <String, MuscleVisualData>{
        back.muscleGroup: back,
        chest.muscleGroup: chest,
        biceps.muscleGroup: biceps,
      };

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(
            muscleData: muscleData,
            maxItems: 3,
          ),
        ),
      );

      expect(find.text('Trained'), findsOneWidget);
      expect(find.text('3 muscles'), findsOneWidget);
      expect(find.text('Top focus'), findsOneWidget);
      expect(find.text('Avg intensity'), findsOneWidget);

      final backFinder = find.text(back.displayName);
      final chestFinder = find.text(chest.displayName);
      final bicepsFinder = find.text(biceps.displayName);

      expect(backFinder, findsOneWidget);
      expect(chestFinder, findsOneWidget);
      expect(bicepsFinder, findsOneWidget);

      expect(
        tester.getTopLeft(backFinder).dy,
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

    testWidgets('shows correct intensity badges for trained muscles',
        (tester) async {
      final light = const MuscleVisualData(
        muscleGroup: 'biceps',
        totalStimulus: 5.0,
        visualIntensity: 0.10,
        color: Colors.green,
        hasTrained: true,
      );

      final moderate = const MuscleVisualData(
        muscleGroup: 'quads',
        totalStimulus: 10.0,
        visualIntensity: 0.30,
        color: Colors.yellow,
        hasTrained: true,
      );

      final heavy = const MuscleVisualData(
        muscleGroup: 'mid-chest',
        totalStimulus: 14.0,
        visualIntensity: 0.55,
        color: Colors.orange,
        hasTrained: true,
      );

      final maximum = const MuscleVisualData(
        muscleGroup: 'lats',
        totalStimulus: 18.0,
        visualIntensity: 0.85,
        color: Colors.red,
        hasTrained: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(
            muscleData: {
              light.muscleGroup: light,
              moderate.muscleGroup: moderate,
              heavy.muscleGroup: heavy,
              maximum.muscleGroup: maximum,
            },
            maxItems: 4,
          ),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Heavy'), findsOneWidget);
      expect(find.text('Maximum'), findsOneWidget);

      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    });

    testWidgets('respects maxItems and hides lower ranked muscles',
        (tester) async {
      final first = const MuscleVisualData(
        muscleGroup: 'lats',
        totalStimulus: 30.0,
        visualIntensity: 0.90,
        color: Colors.red,
        hasTrained: true,
      );

      final second = const MuscleVisualData(
        muscleGroup: 'mid-chest',
        totalStimulus: 20.0,
        visualIntensity: 0.60,
        color: Colors.orange,
        hasTrained: true,
      );

      final third = const MuscleVisualData(
        muscleGroup: 'biceps',
        totalStimulus: 10.0,
        visualIntensity: 0.30,
        color: Colors.yellow,
        hasTrained: true,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(
            muscleData: {
              first.muscleGroup: first,
              second.muscleGroup: second,
              third.muscleGroup: third,
            },
            maxItems: 2,
          ),
        ),
      );

      expect(find.text(first.displayName), findsOneWidget);
      expect(find.text(second.displayName), findsOneWidget);
      expect(find.text(third.displayName), findsNothing);
    });
  });
}