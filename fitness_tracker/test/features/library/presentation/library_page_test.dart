import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/meal.dart';
import 'package:fitness_tracker/features/library/presentation/library_page.dart';
import 'package:fitness_tracker/presentation/pages/exercises/bloc/exercise_bloc.dart';
import 'package:fitness_tracker/presentation/pages/meals/bloc/meal_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseBloc extends MockBloc<ExerciseEvent, ExerciseState>
    implements ExerciseBloc {}

class MockMealBloc extends MockBloc<MealEvent, MealState> implements MealBloc {}

class FakeExerciseEvent extends Fake implements ExerciseEvent {}

class FakeExerciseState extends Fake implements ExerciseState {}

class FakeMealEvent extends Fake implements MealEvent {}

class FakeMealState extends Fake implements MealState {}

void main() {
  late MockExerciseBloc exerciseBloc;
  late MockMealBloc mealBloc;

  setUpAll(() {
    registerFallbackValue(FakeExerciseEvent());
    registerFallbackValue(FakeExerciseState());
    registerFallbackValue(FakeMealEvent());
    registerFallbackValue(FakeMealState());
  });

  setUp(() {
    exerciseBloc = MockExerciseBloc();
    mealBloc = MockMealBloc();

    when(() => exerciseBloc.state).thenReturn(
      ExercisesLoaded(
        <Exercise>[
          Exercise(
            id: '1',
            name: 'Bench Press',
            muscleGroups: const <String>['chest'],
            createdAt: DateTime(2026, 1, 1),
          ),
          Exercise(
            id: '2',
            name: 'Pull Up',
            muscleGroups: const <String>['back'],
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );

    whenListen<ExerciseState>(
      exerciseBloc,
      const Stream<ExerciseState>.empty(),
      initialState: ExercisesLoaded(
        <Exercise>[
          Exercise(
            id: '1',
            name: 'Bench Press',
            muscleGroups: const <String>['chest'],
            createdAt: DateTime(2026, 1, 1),
          ),
          Exercise(
            id: '2',
            name: 'Pull Up',
            muscleGroups: const <String>['back'],
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );

    when(() => mealBloc.state).thenReturn(
      MealsLoaded(
        <Meal>[
          Meal(
            id: 'm1',
            name: 'Chicken Bowl',
            servingSizeGrams: 100,
            proteinPer100g: 30,
            carbsPer100g: 20,
            fatPer100g: 10,
            caloriesPer100g: 290,
            createdAt: DateTime(2026, 1, 1),
          ),
          Meal(
            id: 'm2',
            name: 'Oats',
            servingSizeGrams: 100,
            proteinPer100g: 12,
            carbsPer100g: 60,
            fatPer100g: 7,
            caloriesPer100g: 347,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );

    whenListen<MealState>(
      mealBloc,
      const Stream<MealState>.empty(),
      initialState: MealsLoaded(
        <Meal>[
          Meal(
            id: 'm1',
            name: 'Chicken Bowl',
            servingSizeGrams: 100,
            proteinPer100g: 30,
            carbsPer100g: 20,
            fatPer100g: 10,
            caloriesPer100g: 290,
            createdAt: DateTime(2026, 1, 1),
          ),
          Meal(
            id: 'm2',
            name: 'Oats',
            servingSizeGrams: 100,
            proteinPer100g: 12,
            carbsPer100g: 60,
            fatPer100g: 7,
            caloriesPer100g: 347,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
      ),
    );
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ExerciseBloc>.value(value: exerciseBloc),
        BlocProvider<MealBloc>.value(value: mealBloc),
      ],
      child: const MaterialApp(
        home: LibraryPage(),
      ),
    );
  }

  testWidgets('renders library tabs', (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
  });

  testWidgets('filters exercises by search query', (WidgetTester tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Pull Up'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'bench',
    );
    await tester.pump();

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Pull Up'), findsNothing);
  });

  testWidgets('switches to meals tab and filters meals', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.text('Meals'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken Bowl'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'chicken');
    await tester.pump();

    expect(find.text('Chicken Bowl'), findsOneWidget);
    expect(find.text('Oats'), findsNothing);
  });
}