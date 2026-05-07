import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/enums/auth_mode.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/app_session.dart';
import 'package:fitness_tracker/domain/entities/app_user.dart';
import 'package:fitness_tracker/domain/entities/voice_budget.dart';
import 'package:fitness_tracker/domain/entities/voice_message.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:fitness_tracker/domain/repositories/voice_repository.dart';
import 'package:fitness_tracker/domain/usecases/voice/delete_voice_history.dart';
import 'package:fitness_tracker/domain/usecases/voice/get_voice_budget.dart';
import 'package:fitness_tracker/features/voice/application/voice_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockVoiceRepository extends Mock implements VoiceRepository {}

class MockGetVoiceBudget extends Mock implements GetVoiceBudget {}

class MockDeleteVoiceHistory extends Mock implements DeleteVoiceHistory {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VoiceBloc _makeBloc({
  required VoiceRepository repository,
  GetVoiceBudget? getBudget,
  DeleteVoiceHistory? deleteHistory,
}) {
  return VoiceBloc(
    repository: repository,
    getVoiceBudget: getBudget ?? MockGetVoiceBudget(),
    deleteVoiceHistory: deleteHistory ?? MockDeleteVoiceHistory(),
  );
}

VoiceMessage _assistantMsg(String content) => VoiceMessage(
      role: VoiceRole.assistant,
      content: content,
      createdAt: DateTime(2026),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockVoiceRepository repository;
  late MockGetVoiceBudget getBudget;
  late MockDeleteVoiceHistory deleteHistory;

  setUp(() {
    repository = MockVoiceRepository();
    getBudget = MockGetVoiceBudget();
    deleteHistory = MockDeleteVoiceHistory();

    // Default budget stub
    when(() => getBudget()).thenAnswer(
      (_) async => const Right(VoiceBudget(usedUsd: 0, dailyCapUsd: 1.0)),
    );
  });

  group('VoiceSessionStarted', () {
    blocTest<VoiceBloc, VoiceState>(
      'emits isGuest=true for unauthenticated session',
      build: () => _makeBloc(repository: repository, getBudget: getBudget),
      act: (bloc) => bloc.add(
        VoiceSessionStarted(AppSession.guest()),
      ),
      expect: () => <VoiceState>[
        isA<VoiceState>().having((s) => s.isGuest, 'isGuest', isTrue),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'assigns a sessionId for authenticated session',
      build: () => _makeBloc(repository: repository, getBudget: getBudget),
      act: (bloc) => bloc.add(
        VoiceSessionStarted(
          const AppSession(
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
      'guest user gets GUEST_FORBIDDEN error state without calling repository',
      build: () => _makeBloc(repository: repository, getBudget: getBudget),
      seed: () => const VoiceState(isGuest: true, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceSendMessage('hello')),
      expect: () => <VoiceState>[
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.error),
      ],
      verify: (_) => verifyNever(
        () => repository.chat(
          userMessage: any(named: 'userMessage'),
          sessionId: any(named: 'sessionId'),
          history: any(named: 'history'),
          settings: any(named: 'settings'),
        ),
      ),
    );

    blocTest<VoiceBloc, VoiceState>(
      'happy path: thinking → speaking → idle with audio',
      build: () {
        when(() => repository.chat(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
            )).thenAnswer(
          (_) async => Right(_assistantMsg('Got it!')),
        );
        when(() => repository.synthesise(
              text: any(named: 'text'),
              sessionId: any(named: 'sessionId'),
              voice: any(named: 'voice'),
              sessionLoggingEnabled: any(named: 'sessionLoggingEnabled'),
            )).thenAnswer((_) async => const Right(<int>[1, 2, 3]));
        return _makeBloc(
            repository: repository, getBudget: getBudget);
      },
      seed: () => const VoiceState(isGuest: false, sessionId: 'sid'),
      act: (bloc) => bloc.add(const VoiceSendMessage('bench press')),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.thinking),
        isA<VoiceState>().having((s) => s.status, 'status', VoiceStatus.speaking),
        isA<VoiceState>()
            .having((s) => s.status, 'status', VoiceStatus.idle)
            .having((s) => s.lastAudioBytes, 'audio', isNotEmpty),
      ],
    );

    blocTest<VoiceBloc, VoiceState>(
      'chat failure emits error state',
      build: () {
        when(() => repository.chat(
              userMessage: any(named: 'userMessage'),
              sessionId: any(named: 'sessionId'),
              history: any(named: 'history'),
              settings: any(named: 'settings'),
            )).thenAnswer(
          (_) async => const Left(ServerFailure('Rate limited')),
        );
        return _makeBloc(repository: repository, getBudget: getBudget);
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
  });

  group('VoiceConversationCleared', () {
    blocTest<VoiceBloc, VoiceState>(
      'clears messages and rotates sessionId',
      build: () => _makeBloc(repository: repository, getBudget: getBudget),
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
      act: (bloc) => bloc.add(VoiceConversationCleared()),
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
          repository: repository,
          getBudget: getBudget,
          deleteHistory: deleteHistory,
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
      act: (bloc) => bloc.add(VoiceHistoryDeleteRequested()),
      expect: () => <Matcher>[
        isA<VoiceState>().having((s) => s.messages, 'messages', isEmpty),
      ],
    );
  });
}
