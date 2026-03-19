import 'package:bloc_test/bloc_test.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/features/settings/application/app_settings_cubit.dart';
import 'package:fitness_tracker/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

void main() {
  late MockAppSettingsCubit cubit;

  AppSettingsState buildState({
    AppSettings settings = const AppSettings.defaults(),
    bool isLoading = false,
    bool isSaving = false,
    bool hasLoaded = true,
    String? errorMessage,
  }) {
    return AppSettingsState(
      settings: settings,
      isLoading: isLoading,
      isSaving: isSaving,
      hasLoaded: hasLoaded,
      errorMessage: errorMessage,
    );
  }

  Widget buildSubject() {
    return BlocProvider<AppSettingsCubit>.value(
      value: cubit,
      child: const MaterialApp(
        home: SettingsPage(),
      ),
    );
  }

  setUp(() {
    cubit = MockAppSettingsCubit();

    final AppSettingsState initialState = buildState(
      settings: const AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.monday,
        weightUnit: WeightUnit.kilograms,
      ),
    );

    when(() => cubit.state).thenReturn(initialState);
    whenListen<AppSettingsState>(
      cubit,
      const Stream<AppSettingsState>.empty(),
      initialState: initialState,
    );

    when(() => cubit.ensureLoaded()).thenAnswer((_) async {});
    when(() => cubit.refreshSettings()).thenAnswer((_) async {});
    when(() => cubit.setNotificationsEnabled(any())).thenAnswer((_) async => true);
    when(() => cubit.setWeekStartDay(any())).thenAnswer((_) async => true);
    when(() => cubit.setWeightUnit(any())).thenAnswer((_) async => true);
    when(() => cubit.clearError()).thenReturn(null);
  });

  testWidgets('calls ensureLoaded when page opens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    verify(() => cubit.ensureLoaded()).called(1);
  });

  testWidgets('shows loading state with dedicated loading indicator', (
    WidgetTester tester,
  ) async {
    final AppSettingsState loadingState = buildState(
      isLoading: true,
      hasLoaded: false,
    );

    when(() => cubit.state).thenReturn(loadingState);
    whenListen<AppSettingsState>(
      cubit,
      const Stream<AppSettingsState>.empty(),
      initialState: loadingState,
    );

    await tester.pumpWidget(buildSubject());

    expect(find.byKey(SettingsPage.loadingIndicatorKey), findsOneWidget);
    expect(find.byKey(SettingsPage.refreshListKey), findsNothing);
  });

  testWidgets('renders settings content after load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(SettingsPage.notificationsSwitchKey), findsOneWidget);
    expect(find.byKey(SettingsPage.weekStartTileKey), findsOneWidget);
    expect(find.byKey(SettingsPage.weightUnitTileKey), findsOneWidget);
    expect(find.textContaining('Week preview:'), findsOneWidget);
    expect(find.textContaining('Display preview:'), findsOneWidget);
  });

  testWidgets('toggling notifications delegates to cubit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(SettingsPage.notificationsSwitchKey));
    await tester.pump();

    verify(() => cubit.setNotificationsEnabled(false)).called(1);
  });

  testWidgets('changing week start day delegates to cubit only after selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(SettingsPage.weekStartTileKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunday'));
    await tester.pumpAndSettle();

    verify(() => cubit.setWeekStartDay(WeekStartDay.sunday)).called(1);
  });

  testWidgets('selecting current week start day does not delegate again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(SettingsPage.weekStartTileKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.setWeekStartDay(any()));
  });

  testWidgets('changing weight unit delegates to cubit only after selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(SettingsPage.weightUnitTileKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pounds (lb)'));
    await tester.pumpAndSettle();

    verify(() => cubit.setWeightUnit(WeightUnit.pounds)).called(1);
  });

  testWidgets('selecting current weight unit does not delegate again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.tap(find.byKey(SettingsPage.weightUnitTileKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kilograms (kg)'));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.setWeightUnit(any()));
  });

  testWidgets('pull to refresh delegates to refreshSettings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    await tester.drag(
      find.byKey(SettingsPage.refreshListKey),
      const Offset(0, 300),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => cubit.refreshSettings()).called(1);
  });

  testWidgets('saving state disables selection tiles and shows saving indicator', (
    WidgetTester tester,
  ) async {
    final AppSettingsState savingState = buildState(
      isSaving: true,
      settings: const AppSettings(
        notificationsEnabled: true,
        weekStartDay: WeekStartDay.monday,
        weightUnit: WeightUnit.kilograms,
      ),
    );

    when(() => cubit.state).thenReturn(savingState);
    whenListen<AppSettingsState>(
      cubit,
      const Stream<AppSettingsState>.empty(),
      initialState: savingState,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(SettingsPage.savingIndicatorKey), findsOneWidget);

    await tester.tap(find.byKey(SettingsPage.weekStartTileKey));
    await tester.pumpAndSettle();

    expect(find.text('Sunday'), findsNothing);
    verifyNever(() => cubit.setWeekStartDay(any()));
  });

  testWidgets('error state shows feature error banner and clears error', (
    WidgetTester tester,
  ) async {
    final AppSettingsState errorState = buildState(
      errorMessage: 'save failed',
    );

    when(() => cubit.state).thenReturn(errorState);
    whenListen<AppSettingsState>(
      cubit,
      Stream<AppSettingsState>.fromIterable(<AppSettingsState>[errorState]),
      initialState: errorState,
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.byKey(SettingsPage.errorBannerKey), findsOneWidget);
    expect(find.text('save failed'), findsWidgets);
    verify(() => cubit.clearError()).called(1);
  });
}