import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/app/app.dart';
import 'package:fitness_tracker/features/log/log.dart';
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

class FakeWorkoutEvent extends Fake implements WorkoutEvent {}

class FakeWorkoutState extends Fake implements WorkoutState {}

class FakeNutritionLogEvent extends Fake implements NutritionLogEvent {}

class FakeNutritionLogState extends Fake implements NutritionLogState {}

void main() {
  late MockWorkoutBloc workoutBloc;
  late MockNutritionLogBloc nutritionLogBloc;

  setUpAll(() {
    registerFallbackValue(FakeWorkoutEvent());
    registerFallbackValue(FakeWorkoutState());
    registerFallbackValue(FakeNutritionLogEvent());
    registerFallbackValue(FakeNutritionLogState());
  });

  setUp(() {
    workoutBloc = MockWorkoutBloc();
    nutritionLogBloc = MockNutritionLogBloc();

    when(() => workoutBloc.state).thenReturn(WorkoutInitial());
    when(() => nutritionLogBloc.state).thenReturn(NutritionLogInitial());

    when(() => workoutBloc.add(any())).thenReturn(null);
    when(() => nutritionLogBloc.add(any())).thenReturn(null);

    when(() => workoutBloc.effects)
        .thenAnswer((_) => const Stream<WorkoutUiEffect>.empty());
    when(() => nutritionLogBloc.effects)
        .thenAnswer((_) => const Stream<NutritionLogUiEffect>.empty());

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
  });

  Widget buildSubject() {
    return AppShell(
      home: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<WorkoutBloc>.value(value: workoutBloc),
          BlocProvider<NutritionLogBloc>.value(value: nutritionLogBloc),
        ],
        child: const LogPage(),
      ),
    );
  }

  group('LogPage', () {
    testWidgets('renders segmented tabs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Meal'), findsOneWidget);
      expect(find.text('Macros'), findsOneWidget);
    });

    testWidgets('switches tabs when tapped', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meal'));
      await tester.pumpAndSettle();

      expect(find.text('Meal'), findsWidgets);

      await tester.tap(find.text('Macros'));
      await tester.pumpAndSettle();

      expect(find.text('Macros'), findsWidgets);
    });
  });
}