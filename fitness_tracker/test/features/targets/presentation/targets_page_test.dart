import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/features/targets/application/targets_bloc.dart';
import 'package:fitness_tracker/features/targets/presentation/targets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTargetsBloc extends MockBloc<TargetsEvent, TargetsState>
    implements TargetsBloc {}

class FakeTargetsEvent extends Fake implements TargetsEvent {}

class FakeTargetsState extends Fake implements TargetsState {}

void main() {
  late MockTargetsBloc targetsBloc;

  final DateTime now = DateTime(2026, 3, 24, 10, 0);

  final Target chestTarget = Target(
    id: 'target-chest',
    type: TargetType.muscleSets,
    categoryKey: 'chest',
    targetValue: 12,
    unit: 'sets',
    period: TargetPeriod.weekly,
    createdAt: now,
    syncMetadata: const EntitySyncMetadata(),
  );

  final Target proteinTarget = Target(
    id: 'target-protein',
    type: TargetType.macro,
    categoryKey: 'protein',
    targetValue: 180,
    unit: 'g',
    period: TargetPeriod.daily,
    createdAt: now,
    syncMetadata: const EntitySyncMetadata(),
  );

  setUpAll(() {
    registerFallbackValue(FakeTargetsEvent());
    registerFallbackValue(FakeTargetsState());
  });

  setUp(() {
    targetsBloc = MockTargetsBloc();

    when(() => targetsBloc.state).thenReturn(
      TargetsLoaded(<Target>[chestTarget, proteinTarget]),
    );
    whenListen<TargetsState>(
      targetsBloc,
      const Stream<TargetsState>.empty(),
      initialState: TargetsLoaded(<Target>[chestTarget, proteinTarget]),
    );
  });

  Widget buildSubject() {
    return BlocProvider<TargetsBloc>.value(
      value: targetsBloc,
      child: const MaterialApp(
        home: TargetsPage(),
      ),
    );
  }

  testWidgets('shows loading state', (WidgetTester tester) async {
    when(() => targetsBloc.state).thenReturn(TargetsLoading());
    whenListen<TargetsState>(
      targetsBloc,
      const Stream<TargetsState>.empty(),
      initialState: TargetsLoading(),
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Targets'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no targets', (
    WidgetTester tester,
  ) async {
    when(() => targetsBloc.state).thenReturn(const TargetsLoaded(<Target>[]));
    whenListen<TargetsState>(
      targetsBloc,
      const Stream<TargetsState>.empty(),
      initialState: const TargetsLoaded(<Target>[]),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('No goals yet'), findsOneWidget);
    expect(find.text('Add Training Goal'), findsOneWidget);
    expect(find.text('Add Macro Goal'), findsOneWidget);
  });

  testWidgets('renders training and nutrition sections with targets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Training Goals'), findsOneWidget);
    expect(find.text('Nutrition Goals'), findsOneWidget);

    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('12 sets / week'), findsOneWidget);

    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('180 g / day'), findsOneWidget);
  });

  testWidgets('error state retry dispatches LoadTargetsEvent', (
    WidgetTester tester,
  ) async {
    when(() => targetsBloc.state).thenReturn(
      const TargetsError('targets failed'),
    );
    whenListen<TargetsState>(
      targetsBloc,
      const Stream<TargetsState>.empty(),
      initialState: const TargetsError('targets failed'),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('targets failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => targetsBloc.add(LoadTargetsEvent())).called(1);
  });

  testWidgets('opens info dialog from app bar action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('About Goals'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('opens add macro goal dialog from bottom action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Add Macro Goal'));
    await tester.pumpAndSettle();

    expect(find.text('Add Macro Goal'), findsWidgets);
    expect(find.text('Target grams per day'), findsOneWidget);
    expect(find.text('Protein'), findsWidgets);
  });

  testWidgets('opens edit training dialog when a training target is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Chest'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Training Goal'), findsOneWidget);
    expect(find.text('Weekly Sets Goal'), findsOneWidget);
  });

  testWidgets('opens edit macro dialog when a macro target is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('Protein'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Macro Goal'), findsOneWidget);
    expect(find.text('Target grams per day'), findsOneWidget);
  });
}