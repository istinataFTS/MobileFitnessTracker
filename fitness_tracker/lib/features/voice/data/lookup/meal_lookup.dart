import '../../../../domain/entities/meal.dart';
import '../../../../domain/repositories/meal_repository.dart';

/// Resolves spoken meal names to [Meal] entities for the offline parser.
///
/// Resolution order:
/// 1. Exact name match via [MealRepository.getMealByName].
/// 2. Starts-with prefix match via [MealRepository.searchMealsByName].
/// 3. First result from the search as a loose fallback.
/// 4. null — caller should ask the user to clarify.
class MealLookup {
  MealLookup(this._repository);

  final MealRepository _repository;

  Future<Meal?> findByName(String spoken) async {
    final normalised = spoken.trim();
    if (normalised.isEmpty) return null;

    // 1. Exact match
    final exactResult = await _repository.getMealByName(normalised);
    final exact = exactResult.fold((_) => null, (m) => m);
    if (exact != null) return exact;

    // 2. Prefix search
    final lower = normalised.toLowerCase();
    final searchResult = await _repository.searchMealsByName(lower);
    final candidates = searchResult.fold((_) => <Meal>[], (list) => list);
    if (candidates.isEmpty) return null;

    for (final meal in candidates) {
      if (meal.name.toLowerCase().startsWith(lower)) return meal;
    }

    // 3. Loose fallback — first search hit
    return candidates.first;
  }
}
