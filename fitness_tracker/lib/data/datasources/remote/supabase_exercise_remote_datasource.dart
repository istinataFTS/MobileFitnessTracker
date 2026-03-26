import '../../../domain/entities/exercise.dart';
import '../../dtos/supabase/supabase_exercise_dto.dart';
import 'exercise_remote_datasource.dart';
import 'supabase_client_provider.dart';

class SupabaseExerciseRemoteDataSource implements ExerciseRemoteDataSource {
  static const String _tableName = 'exercises';
  static const String _userIdColumn = 'user_id';

  const SupabaseExerciseRemoteDataSource({
    required this.clientProvider,
  });

  final SupabaseClientProvider clientProvider;

  @override
  bool get isConfigured => clientProvider.isConfigured;

  @override
  Future<List<Exercise>> getAllExercises() async {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return const <Exercise>[];
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
  Future<Exercise?> getExerciseById(String id) async {
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
  Future<Exercise?> getExerciseByName(String name) async {
    final userId = _currentUserIdOrNull();
    if (userId == null) {
      return null;
    }

    final dynamic data = await clientProvider.client
        .from(_tableName)
        .select()
        .eq(_userIdColumn, userId)
        .eq('name', name)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return _mapRowToEntity(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<Exercise>> getExercisesForMuscle(String muscleGroup) async {
    final exercises = await getAllExercises();
    return exercises
        .where((exercise) => exercise.muscleGroups.contains(muscleGroup))
        .toList();
  }

  @override
  Future<Exercise> upsertExercise(Exercise exercise) async {
    final userId = _requireAuthenticatedUserId();

    final dto = SupabaseExerciseDto.fromEntity(exercise);
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
  Future<void> deleteExercise({
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

  Exercise _mapRowToEntity(Map<String, dynamic> row) {
    final dto = SupabaseExerciseDto.fromMap(row);
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
      throw StateError(
        'Supabase exercise access requires an authenticated user.',
      );
    }

    return userId;
  }
}
