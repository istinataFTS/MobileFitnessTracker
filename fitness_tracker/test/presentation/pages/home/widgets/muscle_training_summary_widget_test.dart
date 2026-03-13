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
    testWidgets('shows empty state when there is no trained muscle data',
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

    testWidgets('shows top muscles sorted by total stimulus descending',
        (tester) async {
      final muscleData = <String, MuscleVisualData>{
        'chest': const MuscleVisualData(
          muscleGroup: 'chest',
          totalStimulus: 12.0,
          visualIntensity: 0.45,
          color: Colors.orange,
          hasTrained: true,
        ),
        'back': const MuscleVisualData(
          muscleGroup: 'back',
          totalStimulus: 20.0,
          visualIntensity: 0.75,
          color: Colors.red,
          hasTrained: true,
        ),
        'biceps': const MuscleVisualData(
          muscleGroup: 'biceps',
          totalStimulus: 7.0,
          visualIntensity: 0.18,
          color: Colors.green,
          hasTrained: true,
        ),
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

      expect(find.text('back'), findsOneWidget);
      expect(find.text('chest'), findsOneWidget);
      expect(find.text('biceps'), findsOneWidget);

      final backFinder = find.text('back');
      final chestFinder = find.text('chest');
      final bicepsFinder = find.text('biceps');

      expect(tester.getTopLeft(backFinder).dy, lessThan(tester.getTopLeft(chestFinder).dy));
      expect(tester.getTopLeft(chestFinder).dy, lessThan(tester.getTopLeft(bicepsFinder).dy));

      expect(find.text('Stimulus: 20.0'), findsOneWidget);
      expect(find.text('Stimulus: 12.0'), findsOneWidget);
      expect(find.text('Stimulus: 7.0'), findsOneWidget);
    });

    testWidgets('shows intensity badges for trained muscles',
        (tester) async {
      final muscleData = <String, MuscleVisualData>{
        'quads': const MuscleVisualData(
          muscleGroup: 'quads',
          totalStimulus: 5.0,
          visualIntensity: 0.10,
          color: Colors.green,
          hasTrained: true,
        ),
        'hamstrings': const MuscleVisualData(
          muscleGroup: 'hamstrings',
          totalStimulus: 10.0,
          visualIntensity: 0.30,
          color: Colors.yellow,
          hasTrained: true,
        ),
        'glutes': const MuscleVisualData(
          muscleGroup: 'glutes',
          totalStimulus: 14.0,
          visualIntensity: 0.55,
          color: Colors.orange,
          hasTrained: true,
        ),
        'calves': const MuscleVisualData(
          muscleGroup: 'calves',
          totalStimulus: 18.0,
          visualIntensity: 0.85,
          color: Colors.red,
          hasTrained: true,
        ),
      };

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(
            muscleData: muscleData,
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

    testWidgets('respects maxItems and hides lower-ranked muscles',
        (tester) async {
      final muscleData = <String, MuscleVisualData>{
        'a': const MuscleVisualData(
          muscleGroup: 'a',
          totalStimulus: 30.0,
          visualIntensity: 0.90,
          color: Colors.red,
          hasTrained: true,
        ),
        'b': const MuscleVisualData(
          muscleGroup: 'b',
          totalStimulus: 20.0,
          visualIntensity: 0.60,
          color: Colors.orange,
          hasTrained: true,
        ),
        'c': const MuscleVisualData(
          muscleGroup: 'c',
          totalStimulus: 10.0,
          visualIntensity: 0.30,
          color: Colors.yellow,
          hasTrained: true,
        ),
      };

      await tester.pumpWidget(
        buildTestableWidget(
          MuscleTrainingSummaryWidget(
            muscleData: muscleData,
            maxItems: 2,
          ),
        ),
      );

      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsNothing);
    });
  });
}