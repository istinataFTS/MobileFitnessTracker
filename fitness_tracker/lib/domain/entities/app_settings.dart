import 'package:equatable/equatable.dart';

enum WeekStartDay {
  monday,
  sunday,
}

enum WeightUnit {
  kilograms,
  pounds,
}

class AppSettings extends Equatable {
  final bool notificationsEnabled;
  final WeekStartDay weekStartDay;
  final WeightUnit weightUnit;

  const AppSettings({
    required this.notificationsEnabled,
    required this.weekStartDay,
    required this.weightUnit,
  });

  const AppSettings.defaults()
      : notificationsEnabled = true,
        weekStartDay = WeekStartDay.monday,
        weightUnit = WeightUnit.kilograms;

  AppSettings copyWith({
    bool? notificationsEnabled,
    WeekStartDay? weekStartDay,
    WeightUnit? weightUnit,
  }) {
    return AppSettings(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      weekStartDay: weekStartDay ?? this.weekStartDay,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }

  String get weekStartDayLabel {
    switch (weekStartDay) {
      case WeekStartDay.monday:
        return 'Monday';
      case WeekStartDay.sunday:
        return 'Sunday';
    }
  }

  String get weightUnitLabel {
    switch (weightUnit) {
      case WeightUnit.kilograms:
        return 'Kilograms (kg)';
      case WeightUnit.pounds:
        return 'Pounds (lb)';
    }
  }

  @override
  List<Object?> get props => [
        notificationsEnabled,
        weekStartDay,
        weightUnit,
      ];
}