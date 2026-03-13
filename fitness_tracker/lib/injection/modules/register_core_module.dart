import 'package:get_it/get_it.dart';

import '../../data/datasources/local/database_helper.dart';

void registerCoreModule(GetIt sl) {
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
}