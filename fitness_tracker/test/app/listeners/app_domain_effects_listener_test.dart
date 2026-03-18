import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/app/app.dart';
import 'package:fitness_tracker/app/listeners/app_domain_effects_listener.dart';
import 'package:fitness_tracker/features/history/history.dart';
import 'package:fitness_tracker/features/log/presentation/bloc/workout_bloc.dart';
import 'package:fitness_tracker/presentation/pages/home/bloc/home_bloc.dart';
import 'package:fitness_tracker/presentation/pages/home/bloc/muscle_visual_bloc.dart';
import 'package:fitness_tracker/presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutBloc extends MockBloc<WorkoutEvent, WorkoutState>
    implements WorkoutBloc {}

class MockNutritionLogBloc
    extends MockBloc<NutritionLogEvent, NutritionLogState>
    implements NutritionLogBloc {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class MockMuscleVisualBloc
    extends MockBloc<MuscleVisualEvent, MuscleVisualState>
    implements MuscleVisualBloc {}

class FakeWorkoutEvent extends Fake implements WorkoutEvent {}

class FakeWorkoutState extends Fake implements WorkoutState {}

class FakeNutritionLogEvent extends Fake implements NutritionLogEvent {}

class FakeNutritionLogState extends Fake implements NutritionLogState {}

class FakeHomeEvent extends Fake implements HomeEvent {}

class FakeHomeState extends Fake implements HomeState {}

class FakeHistoryEvent extends Fake implements HistoryEvent {}

class FakeHistoryState extends Fake implements HistoryState {}

class FakeMuscleVisualEvent extends Fake implements MuscleVisualEvent {}

class FakeMuscleVisualState extends Fake implements MuscleVisualState {}

void main() {
  late MockWorkoutBloc workoutBloc;
  late MockNutritionLogBloc nutritionLogBloc;
  late MockHomeBloc homeBloc;
  late MockHistoryBloc historyBloc;
  late MockMuscleVisualBloc muscleVisualBloc;

  setUpAll(() {
    registerFallbackValue(FakeWorkoutEvent());
    registerFallbackValue(FakeWorkoutState());
    registerFallbackValue(FakeNutritionLogEvent());
    registerFallbackValue(FakeNutritionLogState());
    registerFallbackValue(FakeHomeEvent());
    registerFallbackValue(FakeHomeState());
    registerFallbackValue(FakeHistoryEvent());
    registerFallbackValue(FakeHistoryState());
    registerFallbackValue(FakeMuscleVisualEvent());
    registerFallbackValue(FakeMuscleVisualState());
  });

  setUp(() {
    workoutBloc = MockWorkoutBloc();
    nutritionLogBloc = MockNutritionLogBloc();
    homeBloc = MockHomeBloc();
    historyBloc = MockHistoryBloc();
    muscleVisualBloc = MockMuscleVisualBloc();

    when(() => workoutBloc.state).thenReturn(WorkoutInitial());
    when(() => nutritionLogBloc.state).thenReturn(NutritionLogInitial());
    when(() => homeBloc.state).thenReturn(HomeInitial());
    when(() => historyBloc.state).thenReturn(const HistoryInitial());
    when(() => muscleVisualBloc.state).thenReturn(MuscleVisualInitial());

    when(() => workoutBloc.add(any())).thenReturn(null);
    when(() => nutritionLogBloc.add(any())).thenReturn(null);
    when(() => homeBloc.add(any())).thenReturn(null);
    when(() => historyBloc.add(any())).thenReturn(null);
    when(() => muscleVisualBloc.add(any())).thenReturn(null);

    whenListen(
      workoutBloc,
      const Stream<WorkoutState>.empty(),
      initialState: WorkoutInitial(),
    );
    whenListen(
      nutritionLogBloc,
      const Stream<NutritionLogState>.empty(),
      initialState: NutritionLogInitial(),
    );
    whenListen(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: HomeInitial(),
    );
    whenListen(
      historyBloc,
      const Stream<HistoryState>.empty(),
      initialState: const HistoryInitial(),
    );
    whenListen(
      muscleVisualBloc,
      const Stream<MuscleVisualState>.empty(),
      initialState: MuscleVisualInitial(),
    );
  });

  Widget buildSubject() {
    return AppShell(
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<WorkoutBloc>.value(value: workoutBloc),
          BlocProvider<NutritionLogBloc>.value(value: nutritionLogBloc),
          BlocProvider<HomeBloc>.value(value: homeBloc),
          BlocProvider<HistoryBloc>.value(value: historyBloc),
          BlocProvider<MuscleVisualBloc>.value(value: muscleVisualBloc),
        ],
        child: const AppDomainEffectsListener(
          child: SizedBox.shrink(),
        ),
      ),
    );
  }

  group('AppDomainEffectsListener', () {
    testWidgets(
      'reacts to WorkoutLoggedEffect by refreshing related blocs',
      (tester) async {
        when(() => workoutBloc.effects).thenAnswer(
          (_) => Stream<WorkoutUiEffect>.value(
            const WorkoutLoggedEffect(
              message: 'Set logged',
              affectedMuscles: <String>['chest'],
            ),
          ),
        );
        when(() => nutritionLogBloc.effects)
            .thenAnswer((_) => const Stream<NutritionLogUiEffect>.empty());

        await tester.pumpWidget(buildSubject());
        await tester.pump();
        await tester.pump();

        verify(() => homeBloc.add(RefreshHomeDataEvent())).called(1);
        verify(() => historyBloc.add(const RefreshCurrentMonthEvent()))
            .called(1);
        verify(() => workoutBloc.add(const RefreshWeeklySetsEvent())).called(1);
        verify(() => muscleVisualBloc.add(const RefreshVisualsEvent()))
            .called(1);
      },
    );

    testWidgets(
      'reacts to NutritionLogSuccessEffect by refreshing home and history',
      (tester) async {
        when(() => workoutBloc.effects)
            .thenAnswer((_) => const Stream<WorkoutUiEffect>.empty());
        when(() => nutritionLogBloc.effects).thenAnswer(
          (_) => Stream<NutritionLogUiEffect>.value(
            const NutritionLogSuccessEffect('Meal logged'),
          ),
        );

        await tester.pumpWidget(buildSubject());
        await tester.pump();
        await tester.pump();

        verify(() => homeBloc.add(RefreshHomeDataEvent())).called(1);
        verify(() => historyBloc.add(const RefreshCurrentMonthEvent()))
            .called(1);

        verifyNever(() => workoutBloc.add(const RefreshWeeklySetsEvent()));
        verifyNever(() => muscleVisualBloc.add(const RefreshVisualsEvent()));
      },
    );
  });
}