import '../../../../domain/entities/exercise.dart';
import '../../../../domain/usecases/exercises/get_all_exercises.dart';

/// Caches and resolves exercises by name for voice commands.
///
/// Injected as a lazy singleton so the cache persists across voice sessions
/// (the exercise library is static between sessions). The VoiceBloc and the
/// offline parser share this single instance so resolution logic never drifts.
class ExerciseLookup {
  ExerciseLookup(this._getAllExercises);

  final GetAllExercises _getAllExercises;
  List<Exercise> _cache = const [];

  bool get hasCached => _cache.isNotEmpty;

  /// Populate the cache from the repository if it is empty.
  /// No-op if already populated — safe to call before every lookup.
  Future<void> refreshIfEmpty() async {
    if (_cache.isNotEmpty) return;
    final result = await _getAllExercises();
    result.fold((_) {}, (list) => _cache = list);
  }

  /// Sync lookup against the current cache.
  /// Returns null if the cache is empty or no match is found.
  /// Resolution order: exact name → starts-with prefix.
  Exercise? byName(String spoken) => _matchName(spoken, _cache);

  /// Async version — refreshes the cache if empty, then resolves.
  Future<Exercise?> findByName(String spoken) async {
    await refreshIfEmpty();
    return byName(spoken);
  }

  /// Returns the exercise ID for [name], or null if unresolvable.
  String? resolveId(String name) => byName(name)?.id;

  /// Returns the human-readable exercise name for [id], or [id] itself as a
  /// fallback so callers never get an empty string in spoken output.
  String nameForId(String id) {
    for (final ex in _cache) {
      if (ex.id == id) return ex.name;
    }
    return id;
  }

  Exercise? _matchName(String spoken, List<Exercise> list) {
    final lower = spoken.toLowerCase().trim();
    for (final ex in list) {
      if (ex.name.toLowerCase() == lower) return ex;
    }
    for (final ex in list) {
      if (ex.name.toLowerCase().startsWith(lower)) return ex;
    }
    return null;
  }
}
