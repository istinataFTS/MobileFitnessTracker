import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/repository_guard.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/local/app_metadata_local_datasource.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  static const String _notificationsEnabledKey =
      'settings.notifications_enabled';
  static const String _weekStartDayKey = 'settings.week_start_day';
  static const String _weightUnitKey = 'settings.weight_unit';
  static const String _uiExpansionStateKey = 'settings.ui_expansion_state';

  final AppMetadataLocalDataSource localDataSource;

  const AppSettingsRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AppSettings>> getSettings() {
    return RepositoryGuard.run(() async {
      final notificationsEnabled =
          await localDataSource.readBool(_notificationsEnabledKey);
      final weekStartDayRaw =
          await localDataSource.readString(_weekStartDayKey);
      final weightUnitRaw =
          await localDataSource.readString(_weightUnitKey);
      final uiExpansionRaw =
          await localDataSource.readJsonObject(_uiExpansionStateKey);

      return AppSettings(
        notificationsEnabled: notificationsEnabled ?? true,
        weekStartDay: _parseWeekStartDay(weekStartDayRaw),
        weightUnit: _parseWeightUnit(weightUnitRaw),
        uiExpansionState: _parseUiExpansionState(uiExpansionRaw),
      );
    });
  }

  @override
  Future<Either<Failure, void>> saveSettings(AppSettings settings) {
    return RepositoryGuard.run(() async {
      await localDataSource.writeBool(
        _notificationsEnabledKey,
        settings.notificationsEnabled,
      );
      await localDataSource.writeString(
        _weekStartDayKey,
        settings.weekStartDay.name,
      );
      await localDataSource.writeString(
        _weightUnitKey,
        settings.weightUnit.name,
      );
      await localDataSource.writeJsonObject(
        _uiExpansionStateKey,
        settings.uiExpansionState.cast<String, dynamic>(),
      );
    });
  }

  Map<String, bool> _parseUiExpansionState(Map<String, dynamic>? raw) {
    if (raw == null) return const <String, bool>{};
    try {
      return raw.map(
        (String k, dynamic v) => MapEntry(k, v == true),
      );
    } catch (_) {
      return const <String, bool>{};
    }
  }

  WeekStartDay _parseWeekStartDay(String? rawValue) {
    switch (rawValue) {
      case 'sunday':
        return WeekStartDay.sunday;
      case 'monday':
      default:
        return WeekStartDay.monday;
    }
  }

  WeightUnit _parseWeightUnit(String? rawValue) {
    switch (rawValue) {
      case 'pounds':
        return WeightUnit.pounds;
      case 'kilograms':
      default:
        return WeightUnit.kilograms;
    }
  }
}