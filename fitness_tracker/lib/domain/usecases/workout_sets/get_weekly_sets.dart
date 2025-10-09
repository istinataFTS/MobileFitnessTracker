import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/workout_set.dart';
import '../../repositories/workout_set_repository.dart';

class GetWeeklySets {
  final WorkoutSetRepository repository;

  const GetWeeklySets(this.repository);

  Future<Either<Failure, List<WorkoutSet>>> call() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endDate = DateTime.now();

    return await repository.getSetsByDateRange(startDate, endDate);
  }
}