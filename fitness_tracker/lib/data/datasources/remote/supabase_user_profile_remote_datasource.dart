import '../../../core/errors/sync_exceptions.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/entities/user_profile_summary.dart';
import '../../dtos/supabase/supabase_user_profile_dto.dart';
import '../../dtos/supabase/supabase_user_profile_summary_dto.dart';
import 'remote_datasource_guard.dart';
import 'supabase_client_provider.dart';
import 'user_profile_remote_datasource.dart';

class SupabaseUserProfileRemoteDataSource
    implements UserProfileRemoteDataSource {
  static const String _tableName = 'user_profiles';

  const SupabaseUserProfileRemoteDataSource({required this.clientProvider});

  final SupabaseClientProvider clientProvider;

  @override
  bool get isConfigured => clientProvider.isConfigured;

  @override
  Future<UserProfile?> getProfile(String userId) {
    return RemoteDatasourceGuard.run(() async {
      if (!isConfigured) return null;

      final dynamic data = await clientProvider.client
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

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

  @override
  Future<List<UserProfileSummary>> searchByUsername(
    String query, {
    int limit = 20,
  }) {
    return RemoteDatasourceGuard.run(() async {
      if (!isConfigured) return const <UserProfileSummary>[];

      final String trimmed = query.trim();
      if (trimmed.isEmpty) return const <UserProfileSummary>[];

      final dynamic data = await clientProvider.client
          .from(_tableName)
          .select('id, username, display_name, avatar_url')
          .ilike('username', '%$trimmed%')
          .limit(limit);

      return (data as List<dynamic>)
          .map((dynamic row) => SupabaseUserProfileSummaryDto.fromMap(
                Map<String, dynamic>.from(row as Map),
              ).toEntity())
          .toList();
    });
  }
}
