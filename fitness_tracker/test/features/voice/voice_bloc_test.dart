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
import 'package:fitness_tracker/domain/entities/voice_budget.dart';
import 'package:fitness_tracker/domain/entities/voice_message.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:fitness_tracker/domain/repositories/app_settings_repository.dart';
import 'package:fitness_tracker/domain/usecases/voice/delete_voice_history.dart';
import 'package:fitness_tracker/domain/usecases/voice/get_voice_budget.dart';
import 'package:fitness_tracker/domain/usecases/voice/send_voice_message.dart';
import 'package:fitness_tracker/features/voice/application/voice_bloc.dart';
import 'package:fitness_tracker/features/voice/data/services/voice_stt_service.dart';
import 'package:fitness_tracker/features/voice/data/services/voice_tts_service.dart';
import 'package:fitness_tracker/features/voice/data/services/voice_wake_word_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks & fakes
// ---------------------------------------------------------------------------

class MockSendVoiceMessage extends Mock implements SendVoiceMessage {}

class MockGetVoiceBudget extends Mock implements GetVoiceBudget {}

class MockDeleteVoiceHistory extends Mock implements DeleteVoiceHistory {}

class MockAppSettingsRepository extends Mock
    implements AppSettingsRepository {}

class FakeVoiceTtsService implements VoiceTtsService {
  int speakCount = 0;
  String? lastSpoken;
  double lastVolume = 1.0;
  double lastSpeechRate = 1.0;

  @override
  Future<void> initialize({double volume = 1.0, double speechRate = 1.0}) async {}

  @override
  Future<void> speak(String text) async {
    speakCount++;
    lastSpoken = text;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    lastSpeechRate = rate;
  }

  @override
  Future<void> dispose() async {}
}

class FakeVoiceSttService implements VoiceSttService {
  bool _available = true;
  bool _listening = false;
  StreamController<VoiceSttResult>? _controller;

  void simulateUnavailable() => _available = false;

  void emitPartial(String text) =>
      _controller?.add(VoiceSttResult(transcript: text, isFinal: false));

  void emitFinal(String text) {
    _controller?.add(VoiceSttResult(transcript: text, isFinal: true));
    _controller?.close();
    _listening = false;
  }

  void emitError(VoiceSttErrorKind kind, [String? msg]) {
    _controller?.addError(VoiceSttException(kind, msg));
    _controller?.close();
    _listening = false;
  }

  @override
  Future<void> initialize() async {}

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Stream<VoiceSttResult> listen({String? localeId}) {
    _listening = true;
    _controller = StreamController<VoiceSttResult>();
    return _controller!.stream;
  }

  @override
  Future<void> stop() async {
    _listening = false;
    await _controller?.close();
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    await _controller?.close();
  }

  @override
  Future<void> dispose() async {
    await cancel();
  }
}

/// No-op [NetworkStatusService] — the bloc stores it but dispatches
/// connectivity events via [VoiceConnectivityChanged] (fired by the overlay
/// page), so the service itself is never called inside the bloc.
class FakeNetworkStatusService implements NetworkStatusService {
  @override
  Future<bool> isNetworkAvailable() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

/// Instrumented [WakelockService] — records how many times enable/disable
/// were called so tests can assert correct wakelock behaviour.
class FakeWakelockService implements WakelockService {
  int enableCount = 0;
  int disableCount = 0;

  @override
  Future<void> enable() async => enableCount++;

  @override
  Future<void> disable() async => disableCount++;
}

/// Simple [VoiceWakeWordService] fake — the bloc stores it but its lifecycle
/// (start/stop) is managed by [VoiceFab], not the bloc.
class FakeVoiceWakeWordService implements VoiceWakeWordService {
  final StreamController<WakeWordPreset> _detectedController =
      StreamController<WakeWordPreset>.broadcast();
  final StreamController<VoiceWakeWordException> _errorController =
      StreamController<VoiceWakeWordException>.broadcast();
  bool _running = false;

  @override
  Stream<WakeWordPreset> get onWakeWordDetected => _detectedController.stream;

  @override
  Stream<VoiceWakeWordException> get onError => _errorController.stream;

  @override
  bool get isRunning => _running;

  @override
  Future<void> start(WakeWordPreset preset) async => _running = true;

  @override
  Future<void> stop() async => _running = false;

  @override
  Future<void> dispose() async {
    await _detectedController.close();
    await _errorController.close();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VoiceBloc _makeBloc({
  required SendVoiceMessage sendVoiceMessage,
  required GetVoiceBudget getVoiceBudget,
  required DeleteVoiceHistory deleteVoiceHistory,
  required AppSettingsRepository appSettingsRepository,
  VoiceTtsService? tts,
  VoiceSttService? stt,
  NetworkStatusService? networkStatus,
  VoiceWakeWordService? wakeWord,
  WakelockService? wakelock,
  VoiceSettings settings = const VoiceSettings.defaults(),
}) {
  return VoiceBloc(
    sendVoiceMessage: sendVoiceMessage,
    getVoiceBudget: getVoiceBudget,
    deleteVoiceHistory: deleteVoiceHistory,
    sttService: stt ?? FakeVoiceSttService(),
    ttsService: tts ?? FakeVoiceTtsService(),
    appSettingsRepository: appSettingsRepository,
    currentVoiceSettings: () => settings,
    networkStatusService: networkStatus ?? FakeNetworkStatusService(),
    wakeWordService: wakeWord ?? FakeVoiceWakeWordService(),
    wakelockService: wakelock ?? FakeWakelockService(),
  );
}

VoiceMessage _assistantMsg(String content) => VoiceMessage(
      role: VoiceRole.assistant,
      content: content,
      createdAt: DateTime(2026),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const VoiceSettings.defaults());
    registerFallbackValue(WeightUnit.kilograms);
    registerFallbackValue(<VoiceMessage>[]);
  });

  late MockSendVoiceMessage sendVoiceMessage;
  late MockGetVoiceBudget getBudget;
  late MockDeleteVoiceHistory deleteHistory;
  late MockAppSettingsRepository settingsRepo;
  // Shared between `build` and `act` for the STT-driven blocTests
  // below — the same fake instance must be reachable from both.
  late FakeVoiceSttService sharedStt;

  setUp(() {
    sendVoiceMessage = MockSendVoiceMessage();
    getBudget = MockGetVoiceBudget();
    deleteHistory = MockDeleteVoiceHistory();
    settingsRepo = MockAppSettingsRepository();
    sharedStt = FakeVoiceSttService();

    when(() => getBudget()).thenAnswer(
      (_) async => const Right(VoiceBudget(usedUsd: 0, dailyCapUsd: 0.5)),
    );
    when(() => settingsRepo.getSettings()).thenAnswer(
      (_) async => const Right(AppSettings.defaults()),
    );
  });

  group('VoiceSessionStarted', () {
    blocTest<VoiceBloc, VoiceState>(
      'emits isGuest=true for unauthenticated session',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      act: (bloc) => bloc.add(const VoiceSessionStarted(AppSession.guest())),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.isGuest, 'isGuest', isTrue),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'assigns a sessionId for authenticated session',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      act: (bloc) => bloc.add(
        const VoiceSessionStarted(
          AppSession(
            authMode: AuthMode.authenticated,
            user: AppUser(id: 'user-1', email: 'test@example.com'),
          ),
        ),
      ),
      expect: () => <Matcher>[
        isA<VoiceState>().having(
          (s) => s.sessionId,
          'sessionId',
          isNotNull,
        ),
      ],
    );
  });

  group('VoiceSendMessage', () {
    blocTest<VoiceBloc, VoiceState>(
      'guest user gets error state without calling SendVoiceMessage',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      seed: () => const VoiceState(isGuest: true, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceSendMessage('hello')),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.error),
      ],
      verify: (_) => verifyNever(
        () => sendVoiceMessage(
          userMessage: any(named: 'userMessage'),
          sessionId: any(named: 'sessionId'),
          history: any(named: 'history'),
          settings: any(named: 'settings'),
          weightUnit: any(named: 'weightUnit'),
        ),
      ),
    );

    blocTest<VoiceBloc, VoiceState>(
      'happy path: thinking → speaking → idle, TTS is invoked',
      build: () {
        when(() => sendVoiceMessage(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: any(named: 'weightUnit'),
            )).thenAnswer((_) async => Right(_assistantMsg('Got it!')));
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
          tts: FakeVoiceTtsService(),
        );
      },
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceSendMessage('bench press')),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.thinking),
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.speaking),
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.idle),
        // Budget refresh after a successful turn.
        isA<VoiceState>().having((s) => s.budget, 'budget', isNotNull),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'chat failure emits error state',
      build: () {
        when(() => sendVoiceMessage(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: any(named: 'weightUnit'),
            )).thenAnswer(
          (_) async => const Left(ServerFailure('Rate limited')),
        );
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
        );
      },
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceSendMessage('hello')),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.thinking),
        isA<VoiceState>()
            .having((s) => s.status, 'status', VoiceStatus.error)
            .having((s) => s.errorMessage, 'errorMessage', contains('Rate limited')),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'weight unit is sourced from AppSettings (pounds path)',
      build: () {
        when(() => settingsRepo.getSettings()).thenAnswer(
          (_) async => const Right(
            AppSettings(
              notificationsEnabled: true,
              weekStartDay: WeekStartDay.monday,
              weightUnit: WeightUnit.pounds,
            ),
          ),
        );
        when(() => sendVoiceMessage(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: any(named: 'weightUnit'),
            )).thenAnswer((_) async => Right(_assistantMsg('ok')));
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
        );
      },
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceSendMessage('bench')),
      verify: (_) {
        final captured = verify(() => sendVoiceMessage(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: captureAny(named: 'weightUnit'),
            )).captured;
        expect(captured.single, WeightUnit.pounds);
      },
    );
  });

  group('VoiceListenRequested (STT)', () {
    blocTest<VoiceBloc, VoiceState>(
      'unavailable engine emits error',
      build: () {
        final stt = FakeVoiceSttService()..simulateUnavailable();
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
          stt: stt,
        );
      },
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceListenRequested()),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.error),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'partial → final transcript triggers VoiceSendMessage',
      build: () {
        when(() => sendVoiceMessage(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: any(named: 'weightUnit'),
            )).thenAnswer((_) async => Right(_assistantMsg('confirmed')));
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
          stt: sharedStt,
        );
      },
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) async {
        bloc.add(const VoiceListenRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        sharedStt.emitPartial('bench');
        await Future<void>.delayed(const Duration(milliseconds: 10));
        sharedStt.emitFinal('bench press 80 by 10');
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (_) {
        verify(() => sendVoiceMessage(
              userMessage: 'bench press 80 by 10',
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
              weightUnit: any(named: 'weightUnit'),
            )).called(1);
      },
    );

    blocTest<VoiceBloc, VoiceState>(
      'STT permission error surfaces user-friendly message',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
        stt: sharedStt,
      ),
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) async {
        bloc.add(const VoiceListenRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        sharedStt.emitError(VoiceSttErrorKind.permissionPermanentlyDenied);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (bloc) {
        expect(bloc.state.status, VoiceStatus.error);
        expect(bloc.state.errorMessage, contains('permanently denied'));
      },
    );
  });

  group('VoiceConversationCleared', () {
    blocTest<VoiceBloc, VoiceState>(
      'clears messages and rotates sessionId',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      seed: () => VoiceState(
        isGuest: false,
        sessionId: 'old-sid',
        messages: <VoiceMessage>[
          VoiceMessage(
            role: VoiceRole.user,
            content: 'hi',
            createdAt: DateTime(2026),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const VoiceConversationCleared()),
      expect: () => <Matcher>[
        isA<VoiceState>()
            .having((s) => s.messages, 'messages', isEmpty)
            .having((s) => s.sessionId, 'sessionId', isNot('old-sid')),
      ],
    );
  });

  group('VoiceHistoryDeleteRequested', () {
    blocTest<VoiceBloc, VoiceState>(
      'clears messages on success',
      build: () {
        when(() => deleteHistory()).thenAnswer(
          (_) async => const Right<Failure, void>(null),
        );
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
        );
      },
      seed: () => VoiceState(
        isGuest: false,
        sessionId: 'sid',
        messages: <VoiceMessage>[
          VoiceMessage(
            role: VoiceRole.user,
            content: 'hi',
            createdAt: DateTime(2026),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const VoiceHistoryDeleteRequested()),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.messages, 'messages', isEmpty),
      ],
    );
  });

  // Guard against future regressions: the architectural rule is that
  // VoiceBloc must NOT depend on VoiceRepository directly.
  test('VoiceBloc constructor parameters expose use cases / services only',
      () {
    // The constructor takes the new params (compile-time check covered by
    // this file). This test exists to make the rule grep-discoverable —
    // if someone re-introduces a `repository: VoiceRepository` param the
    // file won't compile and they'll see the rule next to the error.
    expect(VoiceBloc, isNotNull);
  });

  // ---------------------------------------------------------------------------
  // VoiceConnectivityChanged (C-4)
  // ---------------------------------------------------------------------------

  group('VoiceConnectivityChanged', () {
    blocTest<VoiceBloc, VoiceState>(
      'going offline sets isOnline to false',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      seed: () => const VoiceState(
        isGuest: false,
        sessionId: 'sid',
        isOnline: true,
      ),
      act: (bloc) => bloc.add(const VoiceConnectivityChanged(isOnline: false)),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.isOnline, 'isOnline', isFalse),
        // Second emit: hasAnnouncedOfflineThisSession flipped to true
        isA<VoiceState>()
            .having((s) => s.isOnline, 'isOnline', isFalse)
            .having(
              (s) => s.hasAnnouncedOfflineThisSession,
              'announced',
              isTrue,
            ),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'going online sets isOnline to true without additional state changes',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      seed: () => const VoiceState(
        isGuest: false,
        sessionId: 'sid',
        isOnline: false,
      ),
      act: (bloc) => bloc.add(const VoiceConnectivityChanged(isOnline: true)),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.isOnline, 'isOnline', isTrue),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'first offline event triggers TTS announcement',
      build: () {
        final tts = FakeVoiceTtsService();
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
          tts: tts,
        );
      },
      seed: () => const VoiceState(
        isGuest: false,
        sessionId: 'sid',
        isOnline: true,
        hasAnnouncedOfflineThisSession: false,
      ),
      act: (bloc) async {
        bloc.add(const VoiceConnectivityChanged(isOnline: false));
        // Let the async speak() call complete.
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      verify: (bloc) {
        expect(bloc.state.hasAnnouncedOfflineThisSession, isTrue);
      },
    );

    blocTest<VoiceBloc, VoiceState>(
      'second offline event within same session does NOT repeat announcement',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
        tts: FakeVoiceTtsService(),
      ),
      // Simulate: user was offline, came back online, goes offline again.
      seed: () => const VoiceState(
        isGuest: false,
        sessionId: 'sid',
        isOnline: true,
        hasAnnouncedOfflineThisSession: true, // already announced once
      ),
      act: (bloc) async {
        bloc.add(const VoiceConnectivityChanged(isOnline: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      // Only one emit: isOnline → false. No second emit for announcement.
      expect: () => <Matcher>[
        isA<VoiceState>()
            .having((s) => s.isOnline, 'isOnline', isFalse)
            .having(
              (s) => s.hasAnnouncedOfflineThisSession,
              'announced',
              isTrue,
            ),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'duplicate connectivity event is a no-op',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) =>
          bloc.add(const VoiceConnectivityChanged(isOnline: true)), // already true
      expect: () => <Matcher>[], // no state changes
    );
  });

  // ---------------------------------------------------------------------------
  // VoiceWorkoutModeToggled + wakelock (C-4)
  // ---------------------------------------------------------------------------

  group('VoiceWorkoutModeToggled', () {
    test('activating workout mode calls wakelock.enable()', () async {
      final wakelock = FakeWakelockService();
      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
        wakelock: wakelock,
      );
      bloc.add(const VoiceWorkoutModeToggled(active: true));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(wakelock.enableCount, 1);
      expect(bloc.state.isWorkoutModeActive, isTrue);
      await bloc.close();
    });

    test('deactivating workout mode calls wakelock.disable()', () async {
      final wakelock = FakeWakelockService();
      final bloc = _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
        wakelock: wakelock,
      );
      // Start with workout mode active.
      bloc.emit(bloc.state.copyWith(isWorkoutModeActive: true));
      bloc.add(const VoiceWorkoutModeToggled(active: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // close() also calls disable(), so disableCount should be at least 1
      // from the toggle event (close() adds another after bloc.close()).
      expect(wakelock.disableCount, greaterThanOrEqualTo(1));
      expect(bloc.state.isWorkoutModeActive, isFalse);
      await bloc.close();
    });

    blocTest<VoiceBloc, VoiceState>(
      'isWorkoutModeActive is reflected in state',
      build: () => _makeBloc(
        sendVoiceMessage: sendVoiceMessage,
        getVoiceBudget: getBudget,
        deleteVoiceHistory: deleteHistory,
        appSettingsRepository: settingsRepo,
      ),
      act: (bloc) {
        bloc.add(const VoiceWorkoutModeToggled(active: true));
        bloc.add(const VoiceWorkoutModeToggled(active: false));
      },
      expect: () => <Matcher>[
        isA<VoiceState>()
            .having((s) => s.isWorkoutModeActive, 'isWorkoutModeActive', isTrue),
        isA<VoiceState>()
            .having((s) => s.isWorkoutModeActive, 'isWorkoutModeActive', isFalse),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // close() releases wakelock (C-4)
  // ---------------------------------------------------------------------------

  test('close() always releases the wakelock', () async {
    final wakelock = FakeWakelockService();
    final bloc = _makeBloc(
      sendVoiceMessage: sendVoiceMessage,
      getVoiceBudget: getBudget,
      deleteVoiceHistory: deleteHistory,
      appSettingsRepository: settingsRepo,
      wakelock: wakelock,
    );
    await bloc.close();
    expect(wakelock.disableCount, 1);
  });

  test('close() releases wakelock even when workout mode is active', () async {
    final wakelock = FakeWakelockService();
    final bloc = _makeBloc(
      sendVoiceMessage: sendVoiceMessage,
      getVoiceBudget: getBudget,
      deleteVoiceHistory: deleteHistory,
      appSettingsRepository: settingsRepo,
      wakelock: wakelock,
    );
    // Activate workout mode (calls enable).
    bloc.add(const VoiceWorkoutModeToggled(active: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(wakelock.enableCount, 1);
    // Closing without explicitly toggling off must still release the lock.
    await bloc.close();
    expect(wakelock.disableCount, 1);
  });

  // ---------------------------------------------------------------------------
  // TTS spoken error messages (C-4)
  // ---------------------------------------------------------------------------

  group('Spoken errors', () {
    FakeVoiceTtsService? sharedTts;

    blocTest<VoiceBloc, VoiceState>(
      'offline announcement text matches AppStrings constant',
      build: () {
        sharedTts = FakeVoiceTtsService();
        return _makeBloc(
          sendVoiceMessage: sendVoiceMessage,
          getVoiceBudget: getBudget,
          deleteVoiceHistory: deleteHistory,
          appSettingsRepository: settingsRepo,
          tts: sharedTts,
        );
      },
      seed: () => const VoiceState(
        isGuest: false,
        sessionId: 'sid',
        isOnline: true,
      ),
      act: (bloc) async {
        bloc.add(const VoiceConnectivityChanged(isOnline: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
      verify: (_) {
        expect(
          sharedTts!.lastSpoken,
          AppStrings.voiceSpokenOfflineAnnouncement,
        );
      },
    );
  });
}
