import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:fitness_tracker/features/home/application/models/home_dashboard_data.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockMuscleVisualBloc
    extends MockBloc<MuscleVisualEvent, MuscleVisualState>
    implements MuscleVisualBloc {}

class FakeHomeEvent extends Fake implements HomeEvent {}

class FakeHomeState extends Fake implements HomeState {}

class FakeMuscleVisualEvent extends Fake implements MuscleVisualEvent {}

class FakeMuscleVisualState extends Fake implements MuscleVisualState {}

void main() {
  late MockHomeBloc homeBloc;
  late MockMuscleVisualBloc muscleVisualBloc;

  final DateTime now = DateTime(2026, 3, 19, 10, 0);

  const AppSettings settings = AppSettings.defaults();

  setUpAll(() {
    registerFallbackValue(FakeHomeEvent());
    registerFallbackValue(FakeHomeState());
    registerFallbackValue(FakeMuscleVisualEvent());
    registerFallbackValue(FakeMuscleVisualState());
  });

  setUp(() {
    homeBloc = MockHomeBloc();
    muscleVisualBloc = MockMuscleVisualBloc();

    when(() => muscleVisualBloc.state).thenReturn(const MuscleVisualInitial());
    whenListen<MuscleVisualState>(
      muscleVisualBloc,
      const Stream<MuscleVisualState>.empty(),
      initialState: const MuscleVisualInitial(),
    );
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<MuscleVisualBloc>.value(value: muscleVisualBloc),
      ],
      child: const MaterialApp(
        home: HomePage(settings: settings),
      ),
    );
  }

  group('HomePage muscle group section', () {
    testWidgets('renders progress content without completion badge', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final HomeLoaded state = HomeLoaded(
        data: HomeDashboardData(
          targets: <Target>[
            Target(
              id: 'target-quads',
              type: TargetType.muscleSets,
              categoryKey: 'quads',
              targetValue: 3,
              unit: 'sets',
              period: TargetPeriod.weekly,
              createdAt: now,
              syncMetadata: const EntitySyncMetadata(),
            ),
          ],
          todaysLogs: const <NutritionLog>[],
          dailyMacros: const <String, double>{},
          muscleSetCounts: const <String, int>{'quads': 1},
        ),
      );

      when(() => homeBloc.state).thenReturn(state);
      whenListen<HomeState>(
        homeBloc,
        const Stream<HomeState>.empty(),
        initialState: state,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Muscle Groups'), findsOneWidget);
      expect(find.text('Quads'), findsOneWidget);
      expect(find.text('1 / 3 sets'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('Complete'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('renders completion badge for completed muscle target', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final HomeLoaded state = HomeLoaded(
        data: HomeDashboardData(
          targets: <Target>[
            Target(
              id: 'target-chest',
              type: TargetType.muscleSets,
              categoryKey: 'chest',
              targetValue: 2,
              unit: 'sets',
              period: TargetPeriod.weekly,
              createdAt: now,
              syncMetadata: const EntitySyncMetadata(),
            ),
          ],
          todaysLogs: const <NutritionLog>[],
          dailyMacros: const <String, double>{},
          muscleSetCounts: const <String, int>{'chest': 2},
        ),
      );

      when(() => homeBloc.state).thenReturn(state);
      whenListen<HomeState>(
        homeBloc,
        const Stream<HomeState>.empty(),
        initialState: state,
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('2 / 2 sets'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Complete'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));
    });
  });
}