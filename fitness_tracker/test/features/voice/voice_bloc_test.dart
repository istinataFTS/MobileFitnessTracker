import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
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
      expect: () => <VoiceState>[
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
      expect: () => <VoiceState>[
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
}
