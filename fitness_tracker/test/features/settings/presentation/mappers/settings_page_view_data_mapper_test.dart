import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:fitness_tracker/features/settings/presentation/mappers/settings_page_view_data_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps settings state into stable page view data', () {
    const AppSettingsState state = AppSettingsState(
      settings: AppSettings(
        notificationsEnabled: false,
        weekStartDay: WeekStartDay.sunday,
        weightUnit: WeightUnit.pounds,
      ),
      isLoading: false,
      isSaving: true,
      hasLoaded: true,
      errorMessage: 'save failed',
    );

    final viewData = SettingsPageViewDataMapper.map(state);

    expect(viewData.notificationsEnabled, isFalse);
    expect(viewData.weekStartSubtitle, 'Sunday');
    expect(viewData.weightUnitSubtitle, 'Pounds (lb)');
    expect(viewData.weekStartPreview, 'Week preview: Mar 15 - Mar 21');
    expect(viewData.weightUnitPreview, 'Display preview: 181.9 lbs');
    expect(viewData.isLoading, isFalse);
    expect(viewData.isSaving, isTrue);
    expect(viewData.errorMessage, 'save failed');
    expect(viewData.deferredItems, hasLength(4));
  });

  test('keeps loading visible only before first successful load', () {
    const AppSettingsState state = AppSettingsState(
      settings: AppSettings.defaults(),
      isLoading: true,
      isSaving: false,
      hasLoaded: false,
      errorMessage: null,
    );

    final viewData = SettingsPageViewDataMapper.map(state);

    expect(viewData.isLoading, isTrue);
  });
}