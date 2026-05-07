import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/voice_budget.dart';
import '../../domain/entities/voice_message.dart';
import '../../domain/entities/voice_settings.dart';
import '../../domain/repositories/voice_repository.dart';
import '../datasources/remote/voice_remote_datasource.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  const VoiceRepositoryImpl({required this.remoteDataSource});

  final VoiceRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, String>> transcribe({
    required List<int> audioBytes,
    required String sessionId,
    required String mimeType,
    bool sessionLoggingEnabled = false,
  }) =>
      _guard(() => remoteDataSource.transcribe(
            audioBytes: audioBytes,
            sessionId: sessionId,
            mimeType: mimeType,
            sessionLoggingEnabled: sessionLoggingEnabled,
          ));

  @override
  Future<Either<Failure, VoiceMessage>> chat({
    required String userMessage,
    required String sessionId,
    required List<VoiceMessage> history,
    required VoiceSettings settings,
  }) =>
      _guard(() => remoteDataSource.chat(
            userMessage: userMessage,
            sessionId: sessionId,
            history: history,
            settings: settings,
          ));

  @override
  Future<Either<Failure, List<int>>> synthesise({
    required String text,
    required String sessionId,
    required TtsVoice voice,
    bool sessionLoggingEnabled = false,
  }) =>
      _guard(() => remoteDataSource.synthesise(
            text: text,
            sessionId: sessionId,
            voice: voice,
            sessionLoggingEnabled: sessionLoggingEnabled,
          ));

  @override
  Future<Either<Failure, VoiceBudget>> getBudget() =>
      _guard(() => remoteDataSource.getBudget());

  @override
  Future<Either<Failure, void>> deleteHistory() =>
      _guard(() => remoteDataSource.deleteHistory());

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
