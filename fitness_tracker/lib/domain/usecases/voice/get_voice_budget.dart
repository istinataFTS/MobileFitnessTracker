import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/voice_budget.dart';
import '../../repositories/voice_repository.dart';

class GetVoiceBudget {
  const GetVoiceBudget(this.repository);

  final VoiceRepository repository;

  Future<Either<Failure, VoiceBudget>> call() => repository.getBudget();
}
