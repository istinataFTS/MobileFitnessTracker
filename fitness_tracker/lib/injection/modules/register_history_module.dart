import 'package:get_it/get_it.dart';

import '../../presentation/pages/history/bloc/history_bloc.dart';

void registerHistoryModule(GetIt sl) {
  sl.registerFactory(
    () => HistoryBloc(
      getAllWorkoutSets: sl(),
      getSetsByDateRange: sl(),
      getNutritionLogsByDateRange: sl(),
      deleteWorkoutSet: sl(),
      updateWorkoutSet: sl(),
      deleteNutritionLog: sl(),
      updateNutritionLog: sl(),
    ),
  );
}