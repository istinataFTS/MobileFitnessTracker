import '../../core/enums/data_source_preference.dart';
import '../repositories/app_session_repository.dart';

class AuthenticatedDataSourcePreferenceResolver {
  final AppSessionRepository appSessionRepository;

  const AuthenticatedDataSourcePreferenceResolver({
    required this.appSessionRepository,
  });

  Future<DataSourcePreference> resolveReadPreference() async {
    final sessionResult = await appSessionRepository.getCurrentSession();

    return sessionResult.fold(
      (_) => DataSourcePreference.localOnly,
      (session) {
        final shouldPreferRemote =
            session.isAuthenticated &&
            appSessionRepository
                .syncPolicy
                .remoteIsSourceOfTruthWhenAuthenticated;

        if (shouldPreferRemote) {
          return DataSourcePreference.remoteThenLocal;
        }

        return DataSourcePreference.localOnly;
      },
    );
  }
}