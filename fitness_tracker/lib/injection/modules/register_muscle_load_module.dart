import 'package:get_it/get_it.dart';

import '../../domain/services/muscle_load_resolver.dart';
import '../../domain/services/muscle_load_resolver_impl.dart';

void registerMuscleLoadModule(GetIt sl) {
  sl.registerLazySingleton<MuscleLoadResolver>(
    () => MuscleLoadResolverImpl(
      workoutSetRepository: sl(),
      muscleFactorRepository: sl(),
    ),
  );
}
