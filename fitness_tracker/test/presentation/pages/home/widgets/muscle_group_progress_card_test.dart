import 'package:fitness_tracker/app/app.dart';
import 'package:fitness_tracker/presentation/pages/home/models/home_progress_view_data.dart';
import 'package:fitness_tracker/presentation/pages/home/widgets/muscle_group_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(MuscleGroupProgressItemViewData viewData) {
    return AppShell(
      home: Scaffold(
        body: Center(
          child: MuscleGroupProgressCard(viewData: viewData),
        ),
      ),
    );
  }

  group('MuscleGroupProgressCard', () {
    testWidgets('renders progress content without completion badge',
        (tester) async {
      const viewData = MuscleGroupProgressItemViewData(
        categoryKey: 'quads',
        title: 'Quads',
        progressLabel: '1 / 3 sets',
        percentageLabel: '33%',
        progressValue: 0.333,
        showCompleteBadge: false,
        tone: MuscleGroupProgressTone.primary,
      );

      await tester.pumpWidget(buildSubject(viewData));
      await tester.pumpAndSettle();

      expect(find.text('Quads'), findsOneWidget);
      expect(find.text('1 / 3 sets'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders completion badge for completed muscle target',
        (tester) async {
      const viewData = MuscleGroupProgressItemViewData(
        categoryKey: 'chest',
        title: 'Chest',
        progressLabel: '2 / 2 sets',
        percentageLabel: '100%',
        progressValue: 1.0,
        showCompleteBadge: true,
        tone: MuscleGroupProgressTone.success,
      );

      await tester.pumpWidget(buildSubject(viewData));
      await tester.pumpAndSettle();

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('2 / 2 sets'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}