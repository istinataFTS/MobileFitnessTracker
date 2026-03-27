import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/constants/muscle_stimulus_constants.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/muscle_factor.dart';
import 'package:fitness_tracker/domain/repositories/muscle_factor_repository.dart';
import 'package:fitness_tracker/domain/usecases/muscle_factors/sync_exercise_muscle_factors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMuscleFactorRepository extends Mock
    implements MuscleFactorRepository {}

void main() {
  late MockMuscleFactorRepository muscleFactorRepository;
  late SyncExerciseMuscleFactors usecase;
  late List<MuscleFactor> savedFactors;

  final exercise = Exercise(
    id: 'exercise-1',
    name: 'Klek',
    muscleGroups: <String>[
      MuscleStimulus.hamstrings,
      MuscleStimulus.quads,
      MuscleStimulus.glutes,
      MuscleStimulus.lowerBack,
    ],
    createdAt: DateTime(2026, 3, 27),
  );

  setUpAll(() {
    registerFallbackValue(const <MuscleFactor>[]);
  });

  setUp(() {
    muscleFactorRepository = MockMuscleFactorRepository();
    usecase = SyncExerciseMuscleFactors(muscleFactorRepository);
    savedFactors = <MuscleFactor>[];

    when(
      () => muscleFactorRepository.deleteMuscleFactorsByExerciseId(exercise.id),
    ).thenAnswer((_) async => const Right(null));

    when(() => muscleFactorRepository.addMuscleFactorsBatch(any())).thenAnswer((
      invocation,
    ) async {
      savedFactors = invocation.positionalArguments.first as List<MuscleFactor>;
      return const Right(null);
    });
  });

  test('creates full factors for all selected muscle groups', () async {
    final result = await usecase(exercise);

    expect(result, const Right(null));
    expect(savedFactors, hasLength(4));
    expect(
      savedFactors.map((factor) => factor.muscleGroup),
      containsAll(exercise.muscleGroups),
    );
    expect(savedFactors.every((factor) => factor.factor == 1.0), isTrue);
  });
}
