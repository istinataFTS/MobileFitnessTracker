import 'package:dartz/dartz.dart';
import 'package:fitness_tracker/core/errors/failures.dart';
import 'package:fitness_tracker/domain/entities/voice_settings.dart';
import 'package:fitness_tracker/domain/repositories/voice_repository.dart';
import 'package:fitness_tracker/domain/usecases/voice/synthesise_speech.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVoiceRepository extends Mock implements VoiceRepository {}

void main() {
  late MockVoiceRepository repo;
  late SynthesizeSpeech useCase;

  setUpAll(() {
    registerFallbackValue(TtsVoice.nova);
  });

  setUp(() {
    repo = MockVoiceRepository();
    useCase = SynthesizeSpeech(repo);
  });

  group('SynthesizeSpeech', () {
    test('delegates to repository.synthesise with correct parameters',
        () async {
      when(() => repo.synthesise(
            text: 'Got it!',
            sessionId: 'sid',
            voice: TtsVoice.nova,
            sessionLoggingEnabled: false,
          )).thenAnswer((_) async => const Right(<int>[1, 2, 3]));

      final result = await useCase(
        text: 'Got it!',
        sessionId: 'sid',
        voice: TtsVoice.nova,
        sessionLoggingEnabled: false,
      );

      expect(result, const Right<Failure, List<int>>(<int>[1, 2, 3]));
    });

    test('propagates Left(failure) unchanged', () async {
      when(() => repo.synthesise(
            text: any(named: 'text'),
            sessionId: any(named: 'sessionId'),
            voice: any(named: 'voice'),
            sessionLoggingEnabled: any(named: 'sessionLoggingEnabled'),
          )).thenAnswer(
        (_) async => const Left(ServerFailure('tts error')),
      );

      final result = await useCase(
        text: 'hello',
        sessionId: 'sid',
        voice: TtsVoice.echo,
        sessionLoggingEnabled: true,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
