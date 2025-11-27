import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/meal.dart';
import '../../repositories/meal_repository.dart';

class GetMealByName {
  final MealRepository repository;

  const GetMealByName(this.repository);

  Future<Either<Failure, Meal?>> call(String name) async {
    return await repository.getMealByName(name);
  }
}