import 'package:equatable/equatable.dart';

/// Represents an exercise with the muscle groups it targets
class Exercise extends Equatable {
  final String id;
  final String name;
  final List<String> muscleGroups; // List of muscle groups this exercise works
  final DateTime createdAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.createdAt,
  });

  Exercise copyWith({
    String? id,
    String? name,
    List<String>? muscleGroups,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, muscleGroups, createdAt];
}