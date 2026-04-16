import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/data_source_preference.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/repositories/target_repository.dart';
import 'package:fitness_tracker/domain/services/authenticated_data_source_preference_resolver.dart';
import 'package:fitness_tracker/domain/usecases/targets/get_all_targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTargetRepository extends Mock implements TargetRepository {}

class MockAuthenticatedDataSourcePreferenceResolver extends Mock
    implements AuthenticatedDataSourcePreferenceResolver {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Target(
        id: 'fallback-id',
        type: TargetType.muscleSets,
        categoryKey: 'chest',
        targetValue: 12,
        unit: 'sets',
        period: TargetPeriod.weekly,
        createdAt: DateTime(2026),
      ),
    );
  });

  late MockTargetRepository repository;
  late MockAuthenticatedDataSourcePreferenceResolver resolver;
  late GetAllTargets getAllTargets;

  final target = Target(
    id: 'target-1',
    type: TargetType.macro,
    categoryKey: 'protein',
    targetValue: 180,
    unit: 'grams',
    period: TargetPeriod.daily,
    createdAt: DateTime(2026, 3, 26),
  );

  setUp(() {
    repository = MockTargetRepository();
    resolver = MockAuthenticatedDataSourcePreferenceResolver();
    getAllTargets = GetAllTargets(
      repository,
      sourcePreferenceResolver: resolver,
    );
  });

  test('GetAllTargets uses resolved source preference', () async {
    when(() => resolver.resolveReadPreference()).thenAnswer(
      (_) async => DataSourcePreference.remoteThenLocal,
    );
    when(
      () => repository.getAllTargets(
        sourcePreference: DataSourcePreference.remoteThenLocal,
      ),
    ).thenAnswer((_) async => Right(<Target>[target]));

    final result = await getAllTargets();

    expect(result.isRight(), isTrue);
    expect((result as Right).value, <Target>[target]);
    verify(
      () => repository.getAllTargets(
        sourcePreference: DataSourcePreference.remoteThenLocal,
      ),
    ).called(1);
  });
}
