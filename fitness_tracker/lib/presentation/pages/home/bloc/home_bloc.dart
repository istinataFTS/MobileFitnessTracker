import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';
import '../../../../domain/usecases/workout_sets/get_sets_by_date_range.dart';

// ==================== EVENTS ====================

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  
  @override
  List<Object?> get props => [];
}

/// Event to load all home page data
class LoadHomeDataEvent extends HomeEvent {}

/// Event to refresh home data (after workout logged)
class RefreshHomeDataEvent extends HomeEvent {}

// ==================== STATES ====================

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state
class HomeInitial extends HomeState {}

/// Loading state
class HomeLoading extends HomeState {}

/// Loaded state with comprehensive home data
class HomeLoaded extends HomeState {
  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  final HomeStats stats; // NEW: Comprehensive stats
  
  const HomeLoaded({
    required this.targets,
    required this.weeklySets,
    required this.stats,
  });
  
  @override
  List<Object?> get props => [targets, weeklySets, stats];
}

/// Error state
class HomeError extends HomeState {
  final String message;
  
  const HomeError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// ==================== DATA CLASSES ====================

/// Comprehensive statistics for home page display
class HomeStats extends Equatable {
  final int totalWeeklySets;
  final int totalWeeklyTarget;
  final int remainingTarget;
  final int trainedMuscleCount;
  final double progressPercentage;
  
  const HomeStats({
    required this.totalWeeklySets,
    required this.totalWeeklyTarget,
    required this.remainingTarget,
    required this.trainedMuscleCount,
    required this.progressPercentage,
  });
  
  /// Check if user has met their weekly target
  bool get hasMetTarget => totalWeeklySets >= totalWeeklyTarget;
  
  /// Check if user has any targets set
  bool get hasTargets => totalWeeklyTarget > 0;
  
  /// Check if user has done any sets this week
  bool get hasWorkouts => totalWeeklySets > 0;
  
  @override
  List<Object?> get props => [
        totalWeeklySets,
        totalWeeklyTarget,
        remainingTarget,
        trainedMuscleCount,
        progressPercentage,
      ];
}

// ==================== BLOC ====================

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;
  final GetSetsByDateRange getSetsByDateRange; // NEW: For muscle counting
  
  HomeBloc({
    required this.getAllTargets,
    required this.getWeeklySets,
    required this.getSetsByDateRange,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
    on<RefreshHomeDataEvent>(_onRefreshHomeData);
  }
  
  /// Load all home page data
  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    // Load targets
    final targetsResult = await getAllTargets();
    
    await targetsResult.fold(
      (failure) async {
        emit(HomeError(failure.message));
      },
      (targets) async {
        // Load weekly sets
        final setsResult = await getWeeklySets();
        
        await setsResult.fold(
          (failure) async {
            emit(HomeError(failure.message));
          },
          (weeklySets) async {
            // Calculate stats
            final stats = await _calculateStats(
              targets: targets,
              weeklySets: weeklySets,
            );
            
            emit(HomeLoaded(
              targets: targets,
              weeklySets: weeklySets,
              stats: stats,
            ));
          },
        );
      },
    );
  }
  
  /// Refresh home data (called after workout logged)
  Future<void> _onRefreshHomeData(
    RefreshHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Reload data without showing loading state
    final targetsResult = await getAllTargets();
    final setsResult = await getWeeklySets();
    
    await targetsResult.fold(
      (failure) async {
        // Keep previous state on error
        if (state is HomeLoaded) {
          emit(state);
        } else {
          emit(HomeError(failure.message));
        }
      },
      (targets) async {
        setsResult.fold(
          (failure) {
            // Keep previous state on error
            if (state is HomeLoaded) {
              emit(state);
            } else {
              emit(HomeError(failure.message));
            }
          },
          (weeklySets) async {
            final stats = await _calculateStats(
              targets: targets,
              weeklySets: weeklySets,
            );
            
            emit(HomeLoaded(
              targets: targets,
              weeklySets: weeklySets,
              stats: stats,
            ));
          },
        );
      },
    );
  }
  
  /// Calculate comprehensive statistics
  Future<HomeStats> _calculateStats({
    required List<Target> targets,
    required List<WorkoutSet> weeklySets,
  }) async {
    // Calculate total weekly target
    final totalWeeklyTarget = targets.fold<int>(
      0,
      (sum, target) => sum + target.weeklyGoal,
    );
    
    // Total sets done this week
    final totalWeeklySets = weeklySets.length;
    
    // Remaining sets to meet target
    final remainingTarget = (totalWeeklyTarget - totalWeeklySets).clamp(0, totalWeeklyTarget);
    
    // Progress percentage
    final progressPercentage = totalWeeklyTarget > 0
        ? ((totalWeeklySets / totalWeeklyTarget) * 100).clamp(0.0, 100.0)
        : 0.0;
    
    // Calculate trained muscle count
    final trainedMuscleCount = await _calculateTrainedMuscleCount(weeklySets);
    
    return HomeStats(
      totalWeeklySets: totalWeeklySets,
      totalWeeklyTarget: totalWeeklyTarget,
      remainingTarget: remainingTarget,
      trainedMuscleCount: trainedMuscleCount,
      progressPercentage: progressPercentage,
    );
  }
  
  /// Calculate count of unique trained muscle groups this week
  /// 
  /// Uses GetSetsByDateRange to get detailed set information with exercises
  Future<int> _calculateTrainedMuscleCount(List<WorkoutSet> weeklySets) async {
    if (weeklySets.isEmpty) return 0;
    
    // Get week start date (Monday)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final today = DateTime.now();
    
    // Get sets with exercise details
    final detailedSetsResult = await getSetsByDateRange(
      start: weekStartDate,
      end: today,
    );
    
    return detailedSetsResult.fold(
      (failure) => 0, // Return 0 on error
      (detailedSets) {
        // Extract unique muscle groups from exercises
        final Set<String> uniqueMuscles = {};
        
        for (final detailedSet in detailedSets) {
          if (detailedSet.exercise != null) {
            uniqueMuscles.addAll(detailedSet.exercise!.muscleGroups);
          }
        }
        
        return uniqueMuscles.length;
      },
    );
  }
}