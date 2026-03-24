import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/entity_sync_metadata.dart';
import 'package:fitness_tracker/domain/entities/target.dart';
import 'package:fitness_tracker/domain/usecases/targets/add_target.dart';
import 'package:fitness_tracker/domain/usecases/targets/delete_target.dart';
import 'package:fitness_tracker/domain/usecases/targets/get_all_targets.dart';
import 'package:fitness_tracker/domain/usecases/targets/update_target.dart';
import 'package:fitness_tracker/features/targets/application/targets_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllTargets extends Mock implements GetAllTargets {}

class MockAddTarget extends Mock implements AddTarget {}

class MockUpdateTarget extends Mock implements UpdateTarget {}

class MockDeleteTarget extends Mock implements DeleteTarget {}

void main() {
  late MockGetAllTargets mockGetAllTargets;
  late MockAddTarget mockAddTarget;
  late MockUpdateTarget mockUpdateTarget;
  late MockDeleteTarget mockDeleteTarget;
  late TargetsBloc bloc;

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

  List<Target> buildTargets() {
    return <Target>[
      chestTarget,
      proteinTarget,
    ];
  }

  setUp(() {
    mockGetAllTargets = MockGetAllTargets();
    mockAddTarget = MockAddTarget();
    mockUpdateTarget = MockUpdateTarget();
    mockDeleteTarget = MockDeleteTarget();

    bloc = TargetsBloc(
      getAllTargets: mockGetAllTargets,
      addTarget: mockAddTarget,
      updateTarget: mockUpdateTarget,
      deleteTarget: mockDeleteTarget,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('initial state is TargetsInitial', () {
    expect(bloc.state, isA<TargetsInitial>());
  });

  blocTest<TargetsBloc, TargetsState>(
    'emits [TargetsLoading, TargetsLoaded] when loading targets succeeds',
    build: () {
      when(() => mockGetAllTargets()).thenAnswer(
        (_) async => Right(buildTargets()),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(LoadTargetsEvent()),
    expect: () => <Matcher>[
      isA<TargetsLoading>(),
      isA<TargetsLoaded>().having(
        (TargetsLoaded state) => state.targets,
        'targets',
        buildTargets(),
      ),
    ],
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits [TargetsLoading, TargetsError] when loading targets fails',
    build: () {
      when(() => mockGetAllTargets()).thenAnswer(
        (_) async => const Left(CacheFailure('load failed')),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(LoadTargetsEvent()),
    expect: () => <Matcher>[
      isA<TargetsLoading>(),
      isA<TargetsError>().having(
        (TargetsError state) => state.message,
        'message',
        'load failed',
      ),
    ],
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits success then reloads when adding a target succeeds',
    build: () {
      when(() => mockAddTarget(chestTarget)).thenAnswer(
        (_) async => const Right(null),
      );
      when(() => mockGetAllTargets()).thenAnswer(
        (_) async => Right(buildTargets()),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(AddTargetEvent(chestTarget)),
    expect: () => <Matcher>[
      isA<TargetOperationSuccess>().having(
        (TargetOperationSuccess state) => state.message,
        'message',
        'Target added successfully',
      ),
      isA<TargetsLoading>(),
      isA<TargetsLoaded>().having(
        (TargetsLoaded state) => state.targets,
        'targets',
        buildTargets(),
      ),
    ],
    verify: (_) {
      verify(() => mockAddTarget(chestTarget)).called(1);
      verify(() => mockGetAllTargets()).called(1);
    },
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits TargetsError when adding a target fails',
    build: () {
      when(() => mockAddTarget(chestTarget)).thenAnswer(
        (_) async => const Left(CacheFailure('add failed')),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(AddTargetEvent(chestTarget)),
    expect: () => <Matcher>[
      isA<TargetsError>().having(
        (TargetsError state) => state.message,
        'message',
        'add failed',
      ),
    ],
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits success then reloads when updating a target succeeds',
    build: () {
      when(() => mockUpdateTarget(chestTarget)).thenAnswer(
        (_) async => const Right(null),
      );
      when(() => mockGetAllTargets()).thenAnswer(
        (_) async => Right(buildTargets()),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(UpdateTargetEvent(chestTarget)),
    expect: () => <Matcher>[
      isA<TargetOperationSuccess>().having(
        (TargetOperationSuccess state) => state.message,
        'message',
        'Target updated successfully',
      ),
      isA<TargetsLoading>(),
      isA<TargetsLoaded>().having(
        (TargetsLoaded state) => state.targets,
        'targets',
        buildTargets(),
      ),
    ],
    verify: (_) {
      verify(() => mockUpdateTarget(chestTarget)).called(1);
      verify(() => mockGetAllTargets()).called(1);
    },
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits TargetsError when updating a target fails',
    build: () {
      when(() => mockUpdateTarget(chestTarget)).thenAnswer(
        (_) async => const Left(CacheFailure('update failed')),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(UpdateTargetEvent(chestTarget)),
    expect: () => <Matcher>[
      isA<TargetsError>().having(
        (TargetsError state) => state.message,
        'message',
        'update failed',
      ),
    ],
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits success then reloads when deleting a target succeeds',
    build: () {
      when(() => mockDeleteTarget(chestTarget.id)).thenAnswer(
        (_) async => const Right(null),
      );
      when(() => mockGetAllTargets()).thenAnswer(
        (_) async => Right(<Target>[proteinTarget]),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(DeleteTargetEvent(chestTarget.id)),
    expect: () => <Matcher>[
      isA<TargetOperationSuccess>().having(
        (TargetOperationSuccess state) => state.message,
        'message',
        'Target deleted successfully',
      ),
      isA<TargetsLoading>(),
      isA<TargetsLoaded>().having(
        (TargetsLoaded state) => state.targets,
        'targets',
        <Target>[proteinTarget],
      ),
    ],
    verify: (_) {
      verify(() => mockDeleteTarget(chestTarget.id)).called(1);
      verify(() => mockGetAllTargets()).called(1);
    },
  );

  blocTest<TargetsBloc, TargetsState>(
    'emits TargetsError when deleting a target fails',
    build: () {
      when(() => mockDeleteTarget(chestTarget.id)).thenAnswer(
        (_) async => const Left(CacheFailure('delete failed')),
      );
      return bloc;
    },
    act: (TargetsBloc bloc) => bloc.add(DeleteTargetEvent(chestTarget.id)),
    expect: () => <Matcher>[
      isA<TargetsError>().having(
        (TargetsError state) => state.message,
        'message',
        'delete failed',
      ),
    ],
  );

  test('TargetsLoaded splits training and macro targets correctly', () {
    final TargetsLoaded state = TargetsLoaded(buildTargets());

    expect(state.trainingTargets, <Target>[chestTarget]);
    expect(state.macroTargets, <Target>[proteinTarget]);
  });
}