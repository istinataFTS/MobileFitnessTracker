import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/meal.dart';
import '../../repositories/meal_repository.dart';

class GetMealById {
  final MealRepository repository;

  const GetMealById(this.repository);

  Future<Either<Failure, Meal?>> call(String id) async {
    return await repository.getMealById(id);
  }
}