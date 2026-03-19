import 'package:fitness_tracker/app/app.dart';
import 'package:fitness_tracker/presentation/pages/home/models/home_progress_view_data.dart';
import 'package:fitness_tracker/presentation/pages/home/widgets/progress_stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    required Widget child,
  }) {
    return AppShell(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('ProgressStatsWidget', () {
    testWidgets('renders prepared home progress stats', (tester) async {
      const viewData = HomeProgressStatsViewData(
        totalSetsStat: HomeProgressStatViewData(
          value: '9',
          label: 'Sets',
          tone: HomeProgressTone.primary,
        ),
        targetStat: HomeProgressStatViewData(
          value: '3',
          label: 'Target',
          tone: HomeProgressTone.warning,
        ),
        trainedMusclesStat: HomeProgressStatViewData(
          value: '4',
          label: 'Muscles',
          tone: HomeProgressTone.primary,
        ),
      );

      await tester.pumpWidget(
        buildSubject(
          child: const ProgressStatsWidget(viewData: viewData),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Muscles'), findsOneWidget);

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('renders muted target placeholder when target is hidden',
        (tester) async {
      const viewData = HomeProgressStatsViewData(
        totalSetsStat: HomeProgressStatViewData(
          value: '12',
          label: 'Sets',
          tone: HomeProgressTone.primary,
        ),
        targetStat: HomeProgressStatViewData(
          value: '-',
          label: 'Target',
          tone: HomeProgressTone.muted,
        ),
        trainedMusclesStat: HomeProgressStatViewData(
          value: '6',
          label: 'Muscles',
          tone: HomeProgressTone.primary,
        ),
      );

      await tester.pumpWidget(
        buildSubject(
          child: const ProgressStatsWidget(viewData: viewData),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-'), findsOneWidget);
      expect(find.text('Target'), findsOneWidget);
    });

    testWidgets('renders detailed progress stats card from prepared view data',
        (tester) async {
      const viewData = DetailedHomeProgressStatsViewData(
        progressValue: 0.8,
        progressLabel: '80% Complete',
        progressTone: HomeProgressTone.primary,
        completedSetsStat: HomeProgressStatViewData(
          value: '8 / 10',
          label: 'Sets Completed',
          tone: HomeProgressTone.primary,
        ),
        trainedMusclesStat: HomeProgressStatViewData(
          value: '4 / 20',
          label: 'Muscles Trained',
          tone: HomeProgressTone.primary,
        ),
        targetCallout: HomeProgressCalloutViewData(
          message: '2 sets remaining',
          tone: HomeProgressTone.warning,
        ),
      );

      await tester.pumpWidget(
        buildSubject(
          child: const DetailedProgressStatsWidget(viewData: viewData),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('80% Complete'), findsOneWidget);
      expect(find.text('8 / 10'), findsOneWidget);
      expect(find.text('Sets Completed'), findsOneWidget);
      expect(find.text('4 / 20'), findsOneWidget);
      expect(find.text('Muscles Trained'), findsOneWidget);
      expect(find.text('2 sets remaining'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}