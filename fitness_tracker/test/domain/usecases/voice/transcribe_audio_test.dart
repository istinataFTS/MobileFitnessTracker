import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/repositories/voice_repository.dart';
import 'package:fitness_tracker/domain/usecases/voice/transcribe_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  late MockVoiceRepository repo;
  late TranscribeAudio useCase;

  setUp(() {
    repo = MockVoiceRepository();
    useCase = TranscribeAudio(repo);
  });

  group('TranscribeAudio', () {
    const audioBytes = <int>[1, 2, 3];
    const sessionId = 'session-123';
    const mimeType = 'audio/wav';

    test('delegates to repository.transcribe with correct parameters',
        () async {
      when(() => repo.transcribe(
            audioBytes: audioBytes,
            sessionId: sessionId,
            mimeType: mimeType,
            sessionLoggingEnabled: true,
          )).thenAnswer((_) async => const Right('hello world'));

      final result = await useCase(
        audioBytes: audioBytes,
        sessionId: sessionId,
        mimeType: mimeType,
        sessionLoggingEnabled: true,
      );

      expect(result, const Right<Failure, String>('hello world'));
      verify(() => repo.transcribe(
            audioBytes: audioBytes,
            sessionId: sessionId,
            mimeType: mimeType,
            sessionLoggingEnabled: true,
          )).called(1);
    });

    test('propagates Left(failure) when repo returns failure', () async {
      when(() => repo.transcribe(
            audioBytes: any(named: 'audioBytes'),
            sessionId: any(named: 'sessionId'),
            mimeType: any(named: 'mimeType'),
            sessionLoggingEnabled: any(named: 'sessionLoggingEnabled'),
          )).thenAnswer(
        (_) async => const Left(ServerFailure('network error')),
      );

      final result = await useCase(
        audioBytes: audioBytes,
        sessionId: sessionId,
        mimeType: mimeType,
        sessionLoggingEnabled: false,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
