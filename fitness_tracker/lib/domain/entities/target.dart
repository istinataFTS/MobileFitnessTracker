import 'package:equatable/equatable.dart';

class Target extends Equatable {
  final String id;
  final String muscleGroup;
  final int weeklyGoal;
  final DateTime createdAt;

  const Target({
    required this.id,
    required this.muscleGroup,
    required this.weeklyGoal,
    required this.createdAt,
  });

  Target copyWith({
    String? id,
    String? muscleGroup,
    int? weeklyGoal,
    DateTime? createdAt,
  }) {
    return Target(
      id: id ?? this.id,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, muscleGroup, weeklyGoal, createdAt];
}