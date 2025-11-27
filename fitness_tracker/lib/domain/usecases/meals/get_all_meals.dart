import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/meal.dart';
import '../../repositories/meal_repository.dart';

class GetAllMeals {
  final MealRepository repository;

  const GetAllMeals(this.repository);

  Future<Either<Failure, List<Meal>>> call() async {
    return await repository.getAllMeals();
  }
}