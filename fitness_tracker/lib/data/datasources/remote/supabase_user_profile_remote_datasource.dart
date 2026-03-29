import '../../../core/errors/sync_exceptions.dart';
import '../../../domain/entities/user_profile.dart';
import '../../dtos/supabase/supabase_user_profile_dto.dart';
import 'remote_datasource_guard.dart';
import 'supabase_client_provider.dart';
import 'user_profile_remote_datasource.dart';

class SupabaseUserProfileRemoteDataSource
    implements UserProfileRemoteDataSource {
  static const String _tableName = 'user_profiles';

  const SupabaseUserProfileRemoteDataSource({
    required this.clientProvider,
  });

  final SupabaseClientProvider clientProvider;

  @override
  bool get isConfigured => clientProvider.isConfigured;

  @override
  Future<UserProfile?> getProfile(String userId) {
    return RemoteDatasourceGuard.run(() async {
      if (!isConfigured) {
        return null;
      }

      final dynamic data = await clientProvider.client
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return SupabaseUserProfileDto.fromMap(
        Map<String, dynamic>.from(data as Map),
      ).toEntity();
    });
  }

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) {
    return RemoteDatasourceGuard.run(() async {
      if (!isConfigured) {
        throw const RemoteSyncException(
          'Supabase is not configured; cannot write to user_profiles',
        );
      }

      final dto = SupabaseUserProfileDto.fromEntity(profile);

      final dynamic data = await clientProvider.client
          .from(_tableName)
          .upsert(dto.toMap())
          .select()
          .single();

      return SupabaseUserProfileDto.fromMap(
        Map<String, dynamic>.from(data as Map),
      ).toEntity();
    });
  }
}
