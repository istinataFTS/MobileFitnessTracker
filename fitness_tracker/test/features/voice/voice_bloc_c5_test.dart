// Tests for C-5 VoiceBloc behaviour:
// — mutation tool confirmation dispatch to target blocs
// — query tool local execution
// — exercise-not-found spoken error

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/constants/app_strings.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/core/network/network_status_service.dart';
import 'package:fitness_tracker/core/platform/wakelock_service.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_settings.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/exercise.dart';
import 'package:fitness_tracker/domain/entities/nutrition_log.dart';
import 'package:fitness_tracker/domain/entities/voice_budget.dart';
import 'package:fitness_tracker/domain/entities/voice_chat_result.dart';
import 'package:fitness_tracker/domain/entities/voice_message.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:fitness_tracker/domain/entities/voice_tool_call.dart';
import 'package:fitness_tracker/domain/entities/workout_set.dart';
import 'package:fitness_tracker/domain/repositories/app_settings_repository.dart';
import 'package:fitness_tracker/domain/usecases/exercises/get_all_exercises.dart';
import 'package:fitness_tracker/domain/usecases/nutrition_logs/get_daily_macros.dart';
import 'package:fitness_tracker/domain/usecases/nutrition_logs/get_logs_for_date.dart';
import 'package:fitness_tracker/domain/usecases/voice/delete_voice_history.dart';
import 'package:fitness_tracker/domain/usecases/voice/get_voice_budget.dart';
import 'package:fitness_tracker/domain/usecases/voice/send_voice_message.dart';
import 'package:fitness_tracker/domain/usecases/workout_sets/get_sets_by_date_range.dart';
import 'package:fitness_tracker/domain/usecases/workout_sets/get_weekly_sets.dart';
import 'package:fitness_tracker/features/history/history.dart';
import 'package:fitness_tracker/features/log/log.dart';
import 'package:fitness_tracker/features/voice/application/voice_bloc.dart';
import 'package:fitness_tracker/features/voice/data/services/voice_stt_service.dart';
import 'package:fitness_tracker/features/voice/data/services/voice_tts_service.dart';
import 'package:fitness_tracker/features/voice/data/services/voice_wake_word_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSendVoiceMessage extends Mock implements SendVoiceMessage {}

class MockGetVoiceBudget extends Mock implements GetVoiceBudget {}

class MockDeleteVoiceHistory extends Mock implements DeleteVoiceHistory {}

class MockWorkoutBloc extends MockBloc<WorkoutEvent, WorkoutState>
    implements WorkoutBloc {}

class MockNutritionLogBloc
    extends MockBloc<NutritionLogEvent, NutritionLogState>
    implements NutritionLogBloc {}

class MockHistoryBloc extends MockBloc<HistoryEvent, HistoryState>
    implements HistoryBloc {}

class MockGetSetsByDateRange extends Mock implements GetSetsByDateRange {}

class MockGetDailyMacros extends Mock implements GetDailyMacros {}

class MockGetWeeklySets extends Mock implements GetWeeklySets {}

class MockGetAllExercises extends Mock implements GetAllExercises {}

class MockGetLogsForDate extends Mock implements GetLogsForDate {}

// Fakes for abstract event base types — needed as fallback values for any() matchers
class _FakeWorkoutEvent extends Fake implements WorkoutEvent {}

class _FakeNutritionLogEvent extends Fake implements NutritionLogEvent {}

class _FakeHistoryEvent extends Fake implements HistoryEvent {}

// ---------------------------------------------------------------------------
// Minimal fakes
// ---------------------------------------------------------------------------

class _FakeTts implements VoiceTtsService {
  final List<String> spoken = [];

  @override
  Future<void> initialize({double volume = 1.0, double speechRate = 1.0}) async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> dispose() async {}
}

class _FakeStt implements VoiceSttService {
  @override
  Future<void> initialize() async {}

  @override
  bool get isAvailable => false;

  @override
  bool get isListening => false;

  @override
  Stream<VoiceSttResult> listen({String? localeId}) =>
      const Stream.empty();

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeNetworkStatus implements NetworkStatusService {
  @override
  Future<bool> isNetworkAvailable() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _FakeWakelock implements WakelockService {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}

class _FakeAppSettingsRepository implements AppSettingsRepository {
  @override
  Future<Either<Failure, AppSettings>> getSettings() async =>
      const Right(AppSettings.defaults());

  @override
  Future<Either<Failure, void>> saveSettings(AppSettings settings) async =>
      const Right(null);

  @override
  Stream<AppSettings> watchSettings() => const Stream.empty();
}

class _FakeWakeWord implements VoiceWakeWordService {
  @override
  Stream<WakeWordPreset> get onWakeWordDetected => const Stream.empty();

  @override
  Stream<VoiceWakeWordException> get onError => const Stream.empty();

  @override
  bool get isRunning => false;

  @override
  Future<void> start(WakeWordPreset preset) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

// ---------------------------------------------------------------------------
// Factory
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 5, 13);

final _benchExercise = Exercise(
  id: 'ex-bench',
  name: 'Bench Press',
  muscleGroups: const ['chest'],
  createdAt: _now,
);

VoiceBloc _makeBloc({
  required MockSendVoiceMessage sendVoiceMessage,
  required MockGetVoiceBudget getBudget,
  required MockGetAllExercises getAllExercises,
  required MockGetSetsByDateRange getSetsByDateRange,
  required MockGetLogsForDate getLogsForDate,
  required MockGetDailyMacros getDailyMacros,
  MockWorkoutBloc? workoutBloc,
  MockNutritionLogBloc? nutritionLogBloc,
  MockHistoryBloc? historyBloc,
  _FakeTts? tts,
}) {
  return VoiceBloc(
    sendVoiceMessage: sendVoiceMessage,
    getVoiceBudget: getBudget,
    deleteVoiceHistory: MockDeleteVoiceHistory(),
    sttService: _FakeStt(),
    ttsService: tts ?? _FakeTts(),
    appSettingsRepository: _FakeAppSettingsRepository(),
    currentVoiceSettings: () => const VoiceSettings.defaults(),
    networkStatusService: _FakeNetworkStatus(),
    wakeWordService: _FakeWakeWord(),
    wakelockService: _FakeWakelock(),
    workoutBloc: workoutBloc ?? MockWorkoutBloc(),
    nutritionLogBloc: nutritionLogBloc ?? MockNutritionLogBloc(),
    historyBloc: historyBloc ?? MockHistoryBloc(),
    getSetsByDateRange: getSetsByDateRange,
    getDailyMacros: getDailyMacros,
    getWeeklySets: MockGetWeeklySets(),
    getAllExercises: getAllExercises,
    getLogsForDate: getLogsForDate,
  );
}

/// Stubs the context-building use cases to return a single bench press set
/// and no nutrition logs, making the exercise cache resolvable.
void _stubContextUseCases({
  required MockGetAllExercises getAllExercises,
  required MockGetSetsByDateRange getSetsByDateRange,
  required MockGetLogsForDate getLogsForDate,
  required MockGetDailyMacros getDailyMacros,
}) {
  when(() => getAllExercises())
      .thenAnswer((_) async => Right([_benchExercise]));
  when(() => getSetsByDateRange(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        muscleGroup: any(named: 'muscleGroup'),
      )).thenAnswer((_) async => const Right([]));
  when(() => getLogsForDate(any()))
      .thenAnswer((_) async => const Right([]));
  when(() => getDailyMacros(any()))
      .thenAnswer((_) async => const Right({}));
}

VoiceToolCall _mutationToolCall(
  String toolName,
  Map<String, dynamic> args,
) =>
    VoiceToolCall(
      id: 'call-1',
      toolName: toolName,
      displaySummary: toolName,
      args: args,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const VoiceSettings.defaults());
    registerFallbackValue(WeightUnit.kilograms);
    registerFallbackValue(<VoiceMessage>[]);
    // Abstract event types needed for any(that: isA<XxxEvent>()) matchers
    registerFallbackValue(_FakeWorkoutEvent());
    registerFallbackValue(_FakeNutritionLogEvent());
    registerFallbackValue(_FakeHistoryEvent());
    registerFallbackValue(
      WorkoutSet(
        id: 'set-1',
        exerciseId: 'ex-bench',
        reps: 8,
        weight: 80,
        intensity: 3,
        date: DateTime(2026, 5, 13),
        createdAt: DateTime(2026, 5, 13),
      ),
    );
    registerFallbackValue(
      NutritionLog(
        id: 'log-1',
        mealName: 'Chicken',
        calories: 300,
        proteinGrams: 30,
        carbsGrams: 10,
        fatGrams: 5,
        loggedAt: DateTime(2026, 5, 13),
        createdAt: DateTime(2026, 5, 13),
      ),
    );
  });

  tearDown(resetMocktailState);

  late MockSendVoiceMessage sendVoiceMessage;
  late MockGetVoiceBudget getBudget;
  late MockGetAllExercises getAllExercises;
  late MockGetSetsByDateRange getSetsByDateRange;
  late MockGetLogsForDate getLogsForDate;
  late MockGetDailyMacros getDailyMacros;

  setUp(() {
    sendVoiceMessage = MockSendVoiceMessage();
    getBudget = MockGetVoiceBudget();
    getAllExercises = MockGetAllExercises();
    getSetsByDateRange = MockGetSetsByDateRange();
    getLogsForDate = MockGetLogsForDate();
    getDailyMacros = MockGetDailyMacros();

    when(() => getBudget()).thenAnswer(
      (_) async => const Right(VoiceBudget(usedUsd: 0, dailyCapUsd: 0.5)),
    );
  });

  // -------------------------------------------------------------------------
  // Helper: create an authenticated session
  // -------------------------------------------------------------------------
  AppSession authSession() => const AppSession(
        authMode: AuthMode.authenticated,
        user: AppUser(id: 'u1', email: 'a@b.com'),
      );

  // -------------------------------------------------------------------------
  // Mutation dispatch — logWorkoutSet
  // -------------------------------------------------------------------------

  group('logWorkoutSet', () {
    test('dispatches AddWorkoutSetEvent when exerciseId is resolved', () async {
      _stubContextUseCases(
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
      );

      final workoutBloc = MockWorkoutBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{
        'exerciseName': 'Bench Press',
        'exerciseId': 'ex-bench',
        'reps': 8,
        'weight': 80.0,
        'intensity': 3,
      };
      final toolCall = _mutationToolCall('logWorkoutSet', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        workoutBloc: workoutBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('log bench press'));
      // Wait for full async pipeline: getAllExercises + getSetsByDateRange +
      // getLogsForDate + sendVoiceMessage (all mocks) + state emit.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Confirm the pending mutation
      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => workoutBloc.add(any(that: isA<AddWorkoutSetEvent>()))).called(1);
      expect(tts.spoken.last, AppStrings.voiceSpokenSetLogged);

      await bloc.close();
    });

    test('speaks voiceSpokenExerciseNotFound when exercise cannot be resolved',
        () async {
      when(() => getAllExercises())
          .thenAnswer((_) async => const Right([])); // no exercises
      when(() => getSetsByDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            muscleGroup: any(named: 'muscleGroup'),
          )).thenAnswer((_) async => const Right([]));
      when(() => getLogsForDate(any()))
          .thenAnswer((_) async => const Right([]));

      final workoutBloc = MockWorkoutBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{
        'exerciseName': 'Unknown Exercise',
        // no exerciseId — forces name resolution, which will fail
        'reps': 5,
        'weight': 50.0,
      };
      final toolCall = _mutationToolCall('logWorkoutSet', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        workoutBloc: workoutBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('log an exercise'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verifyNever(() => workoutBloc.add(any()));
      expect(tts.spoken.last, AppStrings.voiceSpokenExerciseNotFound);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Mutation dispatch — logNutrition
  // -------------------------------------------------------------------------

  group('logNutrition', () {
    test('dispatches AddNutritionLogEvent to nutritionLogBloc', () async {
      _stubContextUseCases(
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
      );

      final nutritionLogBloc = MockNutritionLogBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{
        'mealName': 'Chicken',
        'calories': 300.0,
        'proteinGrams': 30.0,
        'carbsGrams': 10.0,
        'fatGrams': 5.0,
      };
      final toolCall = _mutationToolCall('logNutrition', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        nutritionLogBloc: nutritionLogBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('log chicken'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => nutritionLogBloc.add(any(that: isA<AddNutritionLogEvent>()))).called(1);
      expect(tts.spoken.last, AppStrings.voiceSpokenNutritionLogged);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Mutation dispatch — deleteWorkoutSet via HistoryBloc
  // -------------------------------------------------------------------------

  group('deleteWorkoutSet', () {
    test('dispatches DeleteSetEvent to historyBloc', () async {
      _stubContextUseCases(
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
      );

      final historyBloc = MockHistoryBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{'setId': 'set-999'};
      final toolCall = _mutationToolCall('deleteWorkoutSet', args);

      // For delete, we need the setId to exist in the recent cache.
      // Since we return empty sets from getSetsByDateRange, the cache is empty
      // and _fetchSetById would return null (empty setId guard prevents null,
      // but setId is 'set-999' which isn't in cache) — however the setId
      // IS non-empty so the guard passes. The cache lookup fails, returns null.
      // Actually deleteWorkoutSet just needs setId to be non-empty.
      // Let me check the code again...
      // In voice_bloc.dart deleteWorkoutSet: checks setId.isEmpty then dispatches
      // directly — no cache lookup! So setId just needs to be non-empty.

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        historyBloc: historyBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('delete that set'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => historyBloc.add(any(that: isA<DeleteSetEvent>()))).called(1);
      expect(tts.spoken.last, AppStrings.voiceSpokenSetDeleted);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Query tool — getDailyMacros
  // -------------------------------------------------------------------------

  group('getDailyMacros query', () {
    test('speaks formatted macro result when data is available', () async {
      _stubContextUseCases(
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
      );

      when(() => getDailyMacros(any())).thenAnswer(
        (_) async => const Right({
          'protein': 120.0,
          'carbs': 200.0,
          'fats': 60.0,
          'calories': 1820.0,
        }),
      );

      final tts = _FakeTts();

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => const Right(VoiceChatQueryCall(
          toolCallId: 'call-2',
          toolName: 'getDailyMacros',
          args: {'date': '2026-05-13'},
        )),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('what are my macros today?'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have spoken the macro summary
      expect(tts.spoken.any((s) => s.contains('1820')), isTrue);
      expect(tts.spoken.any((s) => s.contains('120')), isTrue);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Mutation dispatch — editWorkoutSet via HistoryBloc
  // -------------------------------------------------------------------------

  group('editWorkoutSet', () {
    final editableSet = WorkoutSet(
      id: 'set-edit-1',
      exerciseId: 'ex-bench',
      reps: 8,
      weight: 80.0,
      intensity: 3,
      date: _now,
      createdAt: _now,
    );

    test('dispatches UpdateSetEvent when setId is found in recent cache',
        () async {
      when(() => getAllExercises())
          .thenAnswer((_) async => Right([_benchExercise]));
      // Populate _cachedWorkoutSets with the editable set.
      when(() => getSetsByDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            muscleGroup: any(named: 'muscleGroup'),
          )).thenAnswer((_) async => Right([editableSet]));
      when(() => getLogsForDate(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getDailyMacros(any()))
          .thenAnswer((_) async => const Right({}));

      final historyBloc = MockHistoryBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{
        'setId': 'set-edit-1',
        'reps': 10,
        'weight': 90.0,
      };
      final toolCall = _mutationToolCall('editWorkoutSet', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        historyBloc: historyBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('change that bench press to 90 kg, 10 reps'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() => historyBloc.add(any(that: isA<UpdateSetEvent>()))).called(1);
      expect(tts.spoken.last, AppStrings.voiceSpokenSetUpdated);

      await bloc.close();
    });

    test('speaks voiceSpokenToolFailed when setId is not in recent cache',
        () async {
      // Empty sets → _cachedWorkoutSets is empty → _fetchSetById returns null.
      when(() => getAllExercises())
          .thenAnswer((_) async => Right([_benchExercise]));
      when(() => getSetsByDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            muscleGroup: any(named: 'muscleGroup'),
          )).thenAnswer((_) async => const Right([]));
      when(() => getLogsForDate(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getDailyMacros(any()))
          .thenAnswer((_) async => const Right({}));

      final historyBloc = MockHistoryBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{'setId': 'phantom-set', 'reps': 12};
      final toolCall = _mutationToolCall('editWorkoutSet', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        historyBloc: historyBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('edit that last set'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verifyNever(() => historyBloc.add(any()));
      expect(tts.spoken.last, AppStrings.voiceSpokenToolFailed);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Mutation dispatch — editNutritionLog via HistoryBloc
  // -------------------------------------------------------------------------

  group('editNutritionLog', () {
    test('dispatches UpdateNutritionHistoryLogEvent when logId is in recent cache',
        () async {
      final editableLog = NutritionLog(
        id: 'log-edit-1',
        mealName: 'Chicken',
        calories: 300,
        proteinGrams: 30,
        carbsGrams: 10,
        fatGrams: 5,
        loggedAt: _now,
        createdAt: _now,
      );

      when(() => getAllExercises())
          .thenAnswer((_) async => Right([_benchExercise]));
      when(() => getSetsByDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            muscleGroup: any(named: 'muscleGroup'),
          )).thenAnswer((_) async => const Right([]));
      // Populate _cachedNutritionLogs with the editable log.
      when(() => getLogsForDate(any()))
          .thenAnswer((_) async => Right([editableLog]));
      when(() => getDailyMacros(any()))
          .thenAnswer((_) async => const Right({}));

      final historyBloc = MockHistoryBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{
        'logId': 'log-edit-1',
        'calories': 400.0,
        'proteinGrams': 35.0,
      };
      final toolCall = _mutationToolCall('editNutritionLog', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        historyBloc: historyBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('change that chicken to 400 calories'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() =>
              historyBloc.add(any(that: isA<UpdateNutritionHistoryLogEvent>())))
          .called(1);
      expect(tts.spoken.last, AppStrings.voiceSpokenNutritionUpdated);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Mutation dispatch — deleteNutritionLog via HistoryBloc
  // -------------------------------------------------------------------------

  group('deleteNutritionLog', () {
    test('dispatches DeleteNutritionHistoryLogEvent to historyBloc', () async {
      _stubContextUseCases(
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
      );

      final historyBloc = MockHistoryBloc();
      final tts = _FakeTts();

      final args = <String, dynamic>{'logId': 'log-del-1'};
      final toolCall = _mutationToolCall('deleteNutritionLog', args);

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        historyBloc: historyBloc,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('delete that nutrition log'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      bloc.add(const VoiceConfirmationAccepted());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(() =>
              historyBloc.add(any(that: isA<DeleteNutritionHistoryLogEvent>())))
          .called(1);
      expect(tts.spoken.last, AppStrings.voiceSpokenNutritionDeleted);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Query tool — getWeeklyVolume
  // -------------------------------------------------------------------------

  group('getWeeklyVolume query', () {
    test('speaks set count and exercise name breakdown', () async {
      when(() => getAllExercises())
          .thenAnswer((_) async => Right([_benchExercise]));
      final benchSet = WorkoutSet(
        id: 'set-wv-1',
        exerciseId: 'ex-bench',
        reps: 8,
        weight: 80.0,
        intensity: 3,
        date: _now,
        createdAt: _now,
      );
      // Used by both context build (7-day) and the query itself.
      when(() => getSetsByDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            muscleGroup: any(named: 'muscleGroup'),
          )).thenAnswer((_) async => Right([benchSet]));
      when(() => getLogsForDate(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getDailyMacros(any()))
          .thenAnswer((_) async => const Right({}));

      final tts = _FakeTts();

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => const Right(VoiceChatQueryCall(
          toolCallId: 'call-wv',
          toolName: 'getWeeklyVolume',
          args: {},
        )),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('how many sets did I do this week?'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Response should name the exercise and mention the set count.
      expect(tts.spoken.any((s) => s.contains('Bench Press')), isTrue);
      expect(tts.spoken.any((s) => s.contains('1')), isTrue);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Query tool — getRecentSets
  // -------------------------------------------------------------------------

  group('getRecentSets query', () {
    test('speaks formatted recent sets with exercise name and weight', () async {
      when(() => getAllExercises())
          .thenAnswer((_) async => Right([_benchExercise]));
      final benchSet = WorkoutSet(
        id: 'set-rs-1',
        exerciseId: 'ex-bench',
        reps: 10,
        weight: 85.0,
        intensity: 3,
        date: _now,
        createdAt: _now,
      );
      when(() => getSetsByDateRange(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            muscleGroup: any(named: 'muscleGroup'),
          )).thenAnswer((_) async => Right([benchSet]));
      when(() => getLogsForDate(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getDailyMacros(any()))
          .thenAnswer((_) async => const Right({}));

      final tts = _FakeTts();

      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => const Right(VoiceChatQueryCall(
          toolCallId: 'call-rs',
          toolName: 'getRecentSets',
          args: {},
        )),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('what were my recent sets?'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Response should include exercise name and weight.
      expect(tts.spoken.any((s) => s.contains('Bench Press')), isTrue);
      expect(tts.spoken.any((s) => s.contains('85')), isTrue);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Clarify — ambiguous input returns a clarifying question (text response)
  // -------------------------------------------------------------------------

  group('clarify', () {
    test('speaks clarifying question and shows no confirmation card', () async {
      _stubContextUseCases(
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
      );

      final tts = _FakeTts();

      const question =
          'Which exercise did you mean — bench press or overhead press?';
      when(() => sendVoiceMessage(
            userMessage: any(named: 'userMessage'),
            sessionId: any(named: 'sessionId'),
            history: any(named: 'history'),
            settings: any(named: 'settings'),
            weightUnit: any(named: 'weightUnit'),
            recentSets: any(named: 'recentSets'),
            recentNutritionLogs: any(named: 'recentNutritionLogs'),
          )).thenAnswer(
        (_) async => Right(VoiceChatTextResponse(
          message: VoiceMessage(
            role: VoiceRole.assistant,
            content: question,
            createdAt: _now,
          ),
        )),
      );

      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getBudget: getBudget,
        getAllExercises: getAllExercises,
        getSetsByDateRange: getSetsByDateRange,
        getLogsForDate: getLogsForDate,
        getDailyMacros: getDailyMacros,
        tts: tts,
      );

      bloc.add(VoiceSessionStarted(authSession()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      bloc.add(const VoiceSendMessage('log that exercise I did last time'));
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Clarifying question must be spoken.
      expect(tts.spoken.any((s) => s.contains(question)), isTrue);
      // No confirmation card — the user needs to answer first.
      expect(bloc.state.pendingConfirmation, isNull);

      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // Confirmation cancelled — clears pending confirmation, no dispatch
  // -------------------------------------------------------------------------

  group('VoiceConfirmationCancelled', () {
    blocTest<VoiceBloc, VoiceState>(
      'clears pendingConfirmation without dispatching to target blocs',
      build: () {
        _stubContextUseCases(
          getAllExercises: getAllExercises,
          getSetsByDateRange: getSetsByDateRange,
          getLogsForDate: getLogsForDate,
          getDailyMacros: getDailyMacros,
        );

        final args = <String, dynamic>{
          'exerciseName': 'Bench Press',
          'exerciseId': 'ex-bench',
          'reps': 5,
          'weight': 100.0,
        };
        final toolCall = _mutationToolCall('logWorkoutSet', args);

        when(() => sendVoiceMessage(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: any(named: 'weightUnit'),
              recentSets: any(named: 'recentSets'),
              recentNutritionLogs: any(named: 'recentNutritionLogs'),
            )).thenAnswer(
          (_) async => Right(VoiceChatMutationCall(toolCall: toolCall)),
        );

        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getBudget: getBudget,
          getAllExercises: getAllExercises,
          getSetsByDateRange: getSetsByDateRange,
          getLogsForDate: getLogsForDate,
          getDailyMacros: getDailyMacros,
        );
      },
      seed: () => const VoiceState(
        isGuest: false,
        sessionId: 'sid',
        pendingConfirmation: VoiceToolCall(
          id: 'call-1',
          toolName: 'logWorkoutSet',
          displaySummary: 'Log Bench Press',
          args: {},
        ),
      ),
      act: (bloc) => bloc.add(const VoiceConfirmationCancelled()),
      expect: () => [
        isA<VoiceState>()
            .having((s) => s.pendingConfirmation, 'pendingConfirmation', isNull),
      ],
    );
  });
}
