import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/app_settings.dart';

abstract class AppSettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();

  Future<Either<Failure, void>> saveSettings(AppSettings settings);
}