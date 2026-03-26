import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../entities/target.dart';
import '../../repositories/target_repository.dart';
import '../../services/authenticated_data_source_preference_resolver.dart';

class GetAllTargets {
  final TargetRepository repository;
  final AuthenticatedDataSourcePreferenceResolver sourcePreferenceResolver;

  const GetAllTargets(
    this.repository, {
    required this.sourcePreferenceResolver,
  });

  Future<Either<Failure, List<Target>>> call() async {
    final sourcePreference =
        await sourcePreferenceResolver.resolveReadPreference();

    return repository.getAllTargets(sourcePreference: sourcePreference);
  }
}
