import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/meal.dart';
import '../../repositories/meal_repository.dart';

class UpdateMeal {
  final MealRepository repository;

  const UpdateMeal(this.repository);

  Future<Either<Failure, void>> call(Meal meal) async {
    return await repository.updateMeal(meal);
  }
}