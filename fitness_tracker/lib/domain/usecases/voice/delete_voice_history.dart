import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../repositories/voice_repository.dart';

class DeleteVoiceHistory {
  const DeleteVoiceHistory(this.repository);

  final VoiceRepository repository;

  Future<Either<Failure, void>> call() => repository.deleteHistory();
}
