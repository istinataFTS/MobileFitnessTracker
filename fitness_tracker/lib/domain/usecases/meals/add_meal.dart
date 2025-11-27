import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/meal.dart';
import '../../repositories/meal_repository.dart';

class AddMeal {
  final MealRepository repository;

  const AddMeal(this.repository);

  Future<Either<Failure, void>> call(Meal meal) async {
    return await repository.addMeal(meal);
  }
}