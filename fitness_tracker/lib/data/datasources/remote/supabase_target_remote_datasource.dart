import '../../../domain/entities/target.dart';
import '../../dtos/supabase/supabase_target_dto.dart';
import 'supabase_client_provider.dart';
import 'target_remote_datasource.dart';

class SupabaseTargetRemoteDataSource implements TargetRemoteDataSource {
  static const String _tableName = 'targets';
  static const String _userIdColumn = 'user_id';

  const SupabaseTargetRemoteDataSource({
    required this.clientProvider,
  });

  final SupabaseClientProvider clientProvider;

  @override
  bool get isConfigured => clientProvider.isConfigured;

  @override
  Future<List<Target>> getAllTargets() async {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return const <Target>[];
    }

    final dynamic data = await clientProvider.client
        .from(_tableName)
        .select()
        .eq(_userIdColumn, userId)
        .order('updated_at', ascending: false);

    final rows = _asMapList(data);
    return rows.map(_mapRowToEntity).toList();
  }

  @override
  Future<Target?> getTargetById(String id) async {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return null;
    }

    final dynamic data = await clientProvider.client
        .from(_tableName)
        .select()
        .eq(_userIdColumn, userId)
        .eq('id', id)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return _mapRowToEntity(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<Target?> getTargetByTypeAndCategory(
    TargetType type,
    String categoryKey,
    TargetPeriod period,
  ) async {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return null;
    }

    final dynamic data = await clientProvider.client
        .from(_tableName)
        .select()
        .eq(_userIdColumn, userId)
        .eq('type', _targetTypeToStorage(type))
        .eq('category_key', categoryKey)
        .eq('period', _targetPeriodToStorage(period))
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return _mapRowToEntity(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<Target> upsertTarget(Target target) async {
    final userId = _requireAuthenticatedUserId();

    final dto = SupabaseTargetDto.fromEntity(target);
    final payload = <String, dynamic>{
      ...dto.toMap(),
      _userIdColumn: userId,
    };

    final dynamic data = await clientProvider.client
        .from(_tableName)
        .upsert(payload)
        .select()
        .single();

    final row = Map<String, dynamic>.from(data as Map);
    return _mapRowToEntity(row);
  }

  @override
  Future<void> deleteTarget({
    required String localId,
    String? serverId,
  }) async {
    final userId = _requireAuthenticatedUserId();
    final remoteId = serverId ?? localId;

    await clientProvider.client
        .from(_tableName)
        .delete()
        .eq(_userIdColumn, userId)
        .eq('id', remoteId);
  }

  Target _mapRowToEntity(Map<String, dynamic> row) {
    final dto = SupabaseTargetDto.fromMap(row);
    return dto.toEntity(
      localId: dto.id,
      syncMetadata: dto.toSyncedMetadata(),
    );
  }

  List<Map<String, dynamic>> _asMapList(dynamic data) {
    final list = data as List<dynamic>;
    return list
        .map((dynamic row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  String? _currentUserIdOrNull() {
    if (!isConfigured) {
      return null;
    }

    return clientProvider.client.auth.currentUser?.id;
  }

  String _requireAuthenticatedUserId() {
    final userId = _currentUserIdOrNull();
    if (userId == null || userId.isEmpty) {
      throw StateError('Supabase target access requires an authenticated user.');
    }

    return userId;
  }

  String _targetTypeToStorage(TargetType value) {
    switch (value) {
      case TargetType.muscleSets:
        return 'muscle_sets';
      case TargetType.macro:
        return 'macro';
    }
  }

  String _targetPeriodToStorage(TargetPeriod value) {
    switch (value) {
      case TargetPeriod.daily:
        return 'daily';
      case TargetPeriod.weekly:
        return 'weekly';
    }
  }
}
