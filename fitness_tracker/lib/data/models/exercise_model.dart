import 'dart:convert';
import '../../core/constants/database_tables.dart';
import '../../domain/entities/exercise.dart';

/// Data model for Exercise with database serialization
/// Extends Exercise entity to maintain clean architecture separation
class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.name,
    required super.muscleGroups,
    required super.createdAt,
  });

  /// Create model from entity
  factory ExerciseModel.fromEntity(Exercise exercise) {
    return ExerciseModel(
      id: exercise.id,
      name: exercise.name,
      muscleGroups: exercise.muscleGroups,
      createdAt: exercise.createdAt,
    );
  }

  /// Create model from database map
  /// Decodes muscle_groups from JSON string
  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      id: map[DatabaseTables.exerciseId] as String,
      name: map[DatabaseTables.exerciseName] as String,
      muscleGroups: _decodeMuscleGroups(
        map[DatabaseTables.exerciseMuscleGroups] as String,
      ),
      createdAt: DateTime.parse(
        map[DatabaseTables.exerciseCreatedAt] as String,
      ),
    );
  }

  /// Convert model to database map
  /// Encodes muscle_groups to JSON string for storage
  Map<String, dynamic> toMap() {
    return {
      DatabaseTables.exerciseId: id,
      DatabaseTables.exerciseName: name,
      DatabaseTables.exerciseMuscleGroups: _encodeMuscleGroups(muscleGroups),
      DatabaseTables.exerciseCreatedAt: createdAt.toIso8601String(),
    };
  }

  /// Create model from JSON (API compatibility)
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroups: (json['muscleGroups'] as List).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert model to JSON (API compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroups': muscleGroups,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Encode muscle groups list to JSON string for database storage
  static String _encodeMuscleGroups(List<String> muscleGroups) {
    return jsonEncode(muscleGroups);
  }

  /// Decode JSON string from database to muscle groups list
  static List<String> _decodeMuscleGroups(String json) {
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      // Return empty list if decoding fails (defensive programming)
      return [];
    }
  }
}
