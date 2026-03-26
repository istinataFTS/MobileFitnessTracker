import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/features/history/history.dart';
import 'package:fitness_tracker/features/home/application/home_bloc.dart';
import 'package:fitness_tracker/features/home/application/muscle_visual_bloc.dart';
import 'package:fitness_tracker/features/library/application/exercise_bloc.dart';
import 'package:fitness_tracker/features/library/application/meal_bloc.dart';
import 'package:fitness_tracker/features/log/log.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:fitness_tracker/features/settings/presentation/settings_scope.dart';
import 'package:fitness_tracker/features/targets/application/targets_bloc.dart';
import 'package:fitness_tracker/presentation/navigation/bottom_navigation.dart';
import 'package:fitness_tracker/presentation/pages/nutrition_log/bloc/nutrition_log_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

class MockMuscleVisualBloc
    extends MockBloc<MuscleVisualEvent, MuscleVisualState>
    implements MuscleVisualBloc {}

class MockExerciseBloc extends MockBloc<ExerciseEvent, ExerciseState>
    implements ExerciseBloc {}

class MockMealBloc extends MockBloc<MealEvent, MealState> implements MealBloc {}

class MockWorkoutBloc extends MockBloc<WorkoutEvent, WorkoutState>
    implements WorkoutBloc {}

class MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class MockTargetsBloc extends MockBloc<TargetsEvent, TargetsState>
    implements TargetsBloc {}

class MockNutritionLogBloc
    extends MockBloc<NutritionLogEvent, NutritionLogState>
    implements NutritionLogBloc {}

class FakeHomeEvent extends Fake implements HomeEvent {}

class FakeHomeState extends Fake implements HomeState {}

class FakeMuscleVisualEvent extends Fake implements MuscleVisualEvent {}

class FakeMuscleVisualState extends Fake implements MuscleVisualState {}

class FakeExerciseEvent extends Fake implements ExerciseEvent {}

class FakeExerciseState extends Fake implements ExerciseState {}

class FakeMealEvent extends Fake implements MealEvent {}

class FakeMealState extends Fake implements MealState {}

class FakeWorkoutEvent extends Fake implements WorkoutEvent {}

class FakeWorkoutState extends Fake implements WorkoutState {}

class FakeHistoryEvent extends Fake implements HistoryEvent {}

class FakeHistoryState extends Fake implements HistoryState {}

class FakeTargetsEvent extends Fake implements TargetsEvent {}

class FakeTargetsState extends Fake implements TargetsState {}

class FakeNutritionLogEvent extends Fake implements NutritionLogEvent {}

class FakeNutritionLogState extends Fake implements NutritionLogState {}

void main() {
  late MockAppSettingsCubit appSettingsCubit;
  late MockHomeBloc homeBloc;
  late MockMuscleVisualBloc muscleVisualBloc;
  late MockExerciseBloc exerciseBloc;
  late MockMealBloc mealBloc;
  late MockWorkoutBloc workoutBloc;
  late MockHistoryBloc historyBloc;
  late MockTargetsBloc targetsBloc;
  late MockNutritionLogBloc nutritionLogBloc;

  setUpAll(() {
    registerFallbackValue(FakeHomeEvent());
    registerFallbackValue(FakeHomeState());
    registerFallbackValue(FakeMuscleVisualEvent());
    registerFallbackValue(FakeMuscleVisualState());
    registerFallbackValue(FakeExerciseEvent());
    registerFallbackValue(FakeExerciseState());
    registerFallbackValue(FakeMealEvent());
    registerFallbackValue(FakeMealState());
    registerFallbackValue(FakeWorkoutEvent());
    registerFallbackValue(FakeWorkoutState());
    registerFallbackValue(FakeHistoryEvent());
    registerFallbackValue(FakeHistoryState());
    registerFallbackValue(FakeTargetsEvent());
    registerFallbackValue(FakeTargetsState());
    registerFallbackValue(FakeNutritionLogEvent());
    registerFallbackValue(FakeNutritionLogState());
  });

  setUp(() {
    appSettingsCubit = MockAppSettingsCubit();
    homeBloc = MockHomeBloc();
    muscleVisualBloc = MockMuscleVisualBloc();
    exerciseBloc = MockExerciseBloc();
    mealBloc = MockMealBloc();
    workoutBloc = MockWorkoutBloc();
    historyBloc = MockHistoryBloc();
    targetsBloc = MockTargetsBloc();
    nutritionLogBloc = MockNutritionLogBloc();

    when(
      () => appSettingsCubit.state,
    ).thenReturn(AppSettingsState.initial().copyWith(hasLoaded: true));
    whenListen<AppSettingsState>(
      appSettingsCubit,
      const Stream<AppSettingsState>.empty(),
      initialState: AppSettingsState.initial().copyWith(hasLoaded: true),
    );

    when(() => homeBloc.state).thenReturn(HomeInitial());
    whenListen<HomeState>(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: HomeInitial(),
    );

    when(() => muscleVisualBloc.state).thenReturn(MuscleVisualInitial());
    whenListen<MuscleVisualState>(
      muscleVisualBloc,
      const Stream<MuscleVisualState>.empty(),
      initialState: MuscleVisualInitial(),
    );

    when(() => exerciseBloc.state).thenReturn(ExerciseInitial());
    whenListen<ExerciseState>(
      exerciseBloc,
      const Stream<ExerciseState>.empty(),
      initialState: ExerciseInitial(),
    );

    when(() => mealBloc.state).thenReturn(MealInitial());
    whenListen<MealState>(
      mealBloc,
      const Stream<MealState>.empty(),
      initialState: MealInitial(),
    );

    when(() => workoutBloc.state).thenReturn(WorkoutInitial());
    whenListen<WorkoutState>(
      workoutBloc,
      const Stream<WorkoutState>.empty(),
      initialState: WorkoutInitial(),
    );

    when(() => historyBloc.state).thenReturn(const HistoryInitial());
    whenListen<HistoryState>(
      historyBloc,
      const Stream<HistoryState>.empty(),
      initialState: const HistoryInitial(),
    );
    when(
      () => historyBloc.effects,
    ).thenAnswer((_) => const Stream<HistoryUiEffect>.empty());

    when(() => targetsBloc.state).thenReturn(TargetsInitial());
    whenListen<TargetsState>(
      targetsBloc,
      const Stream<TargetsState>.empty(),
      initialState: TargetsInitial(),
    );

    when(() => nutritionLogBloc.state).thenReturn(NutritionLogInitial());
    whenListen<NutritionLogState>(
      nutritionLogBloc,
      const Stream<NutritionLogState>.empty(),
      initialState: NutritionLogInitial(),
    );
    when(
      () => nutritionLogBloc.effects,
    ).thenAnswer((_) => const Stream<NutritionLogUiEffect>.empty());

    when(() => exerciseBloc.add(any())).thenReturn(null);
    when(() => mealBloc.add(any())).thenReturn(null);
    when(() => historyBloc.add(any())).thenReturn(null);
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AppSettingsCubit>.value(value: appSettingsCubit),
        BlocProvider<HomeBloc>.value(value: homeBloc),
        BlocProvider<MuscleVisualBloc>.value(value: muscleVisualBloc),
        BlocProvider<ExerciseBloc>.value(value: exerciseBloc),
        BlocProvider<MealBloc>.value(value: mealBloc),
        BlocProvider<WorkoutBloc>.value(value: workoutBloc),
        BlocProvider<HistoryBloc>.value(value: historyBloc),
        BlocProvider<TargetsBloc>.value(value: targetsBloc),
        BlocProvider<NutritionLogBloc>.value(value: nutritionLogBloc),
      ],
      child: SettingsScope(child: const MaterialApp(home: BottomNavigation())),
    );
  }

  testWidgets('opening History eagerly loads exercise and meal library data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.text('History'));
    await tester.pump();

    verify(() => exerciseBloc.add(LoadExercisesEvent())).called(1);
    verify(() => mealBloc.add(LoadMealsEvent())).called(1);
  });
}
