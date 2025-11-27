import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/nutrition_log.dart';
import '../../../../domain/usecases/nutrition_logs/get_logs_for_date.dart';
import '../../../../domain/usecases/nutrition_logs/add_nutrition_log.dart';
import '../../../../domain/usecases/nutrition_logs/update_nutrition_log.dart';
import '../../../../domain/usecases/nutrition_logs/delete_nutrition_log.dart';
import '../../../../domain/usecases/nutrition_logs/get_daily_macros.dart';

// ==================== Events ====================

abstract class NutritionLogEvent extends Equatable {
  const NutritionLogEvent();
  @override
  List<Object?> get props => [];
}

/// Load all nutrition logs for a specific date
class LoadDailyLogsEvent extends NutritionLogEvent {
  final DateTime date;
  const LoadDailyLogsEvent(this.date);
  @override
  List<Object?> get props => [date];
}

/// Add a new nutrition log entry
class AddNutritionLogEvent extends NutritionLogEvent {
  final NutritionLog log;
  const AddNutritionLogEvent(this.log);
  @override
  List<Object?> get props => [log];
}

/// Update an existing nutrition log entry
class UpdateNutritionLogEvent extends NutritionLogEvent {
  final NutritionLog log;
  const UpdateNutritionLogEvent(this.log);
  @override
  List<Object?> get props => [log];
}

/// Delete a nutrition log entry
class DeleteNutritionLogEvent extends NutritionLogEvent {
  final String id;
  const DeleteNutritionLogEvent(this.id);
  @override
  List<Object?> get props => [id];
}

/// Refresh current day's data
class RefreshDailyLogsEvent extends NutritionLogEvent {
  final DateTime date;
  const RefreshDailyLogsEvent(this.date);
  @override
  List<Object?> get props => [date];
}

// ==================== States ====================

abstract class NutritionLogState extends Equatable {
  const NutritionLogState();
  @override
  List<Object?> get props => [];
}

class NutritionLogInitial extends NutritionLogState {}

class NutritionLogLoading extends NutritionLogState {}

/// State when daily logs are loaded
/// Contains logs for the day plus calculated total macros
class DailyLogsLoaded extends NutritionLogState {
  final DateTime date;
  final List<NutritionLog> logs;
  final Map<String, double> dailyMacros;
  
  const DailyLogsLoaded({
    required this.date,
    required this.logs,
    required this.dailyMacros,
  });
  
  /// Get total protein for the day
  double get totalProtein => dailyMacros['protein'] ?? 0.0;
  
  /// Get total carbs for the day
  double get totalCarbs => dailyMacros['carbs'] ?? 0.0;
  
  /// Get total fats for the day
  double get totalFats => dailyMacros['fats'] ?? 0.0;
  
  /// Get total calories for the day
  double get totalCalories => dailyMacros['calories'] ?? 0.0;
  
  @override
  List<Object?> get props => [date, logs, dailyMacros];
}

class NutritionLogError extends NutritionLogState {
  final String message;
  const NutritionLogError(this.message);
  @override
  List<Object?> get props => [message];
}

class NutritionLogOperationSuccess extends NutritionLogState {
  final String message;
  const NutritionLogOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ==================== BLoC ====================

class NutritionLogBloc extends Bloc<NutritionLogEvent, NutritionLogState> {
  final GetLogsForDate getLogsForDate;
  final AddNutritionLog addNutritionLog;
  final UpdateNutritionLog updateNutritionLog;
  final DeleteNutritionLog deleteNutritionLog;
  final GetDailyMacros getDailyMacros;

  // Cache current date for refresh operations
  DateTime _currentDate = DateTime.now();

  NutritionLogBloc({
    required this.getLogsForDate,
    required this.addNutritionLog,
    required this.updateNutritionLog,
    required this.deleteNutritionLog,
    required this.getDailyMacros,
  }) : super(NutritionLogInitial()) {
    on<LoadDailyLogsEvent>(_onLoadDailyLogs);
    on<AddNutritionLogEvent>(_onAddNutritionLog);
    on<UpdateNutritionLogEvent>(_onUpdateNutritionLog);
    on<DeleteNutritionLogEvent>(_onDeleteNutritionLog);
    on<RefreshDailyLogsEvent>(_onRefreshDailyLogs);
  }

  Future<void> _onLoadDailyLogs(
    LoadDailyLogsEvent event,
    Emitter<NutritionLogState> emit,
  ) async {
    emit(NutritionLogLoading());
    _currentDate = event.date;
    
    // Load logs for the date
    final logsResult = await getLogsForDate(event.date);
    
    await logsResult.fold(
      (failure) async => emit(NutritionLogError(failure.message)),
      (logs) async {
        // Calculate daily macros
        final macrosResult = await getDailyMacros(event.date);
        
        macrosResult.fold(
          (failure) => emit(NutritionLogError(failure.message)),
          (macros) => emit(DailyLogsLoaded(
            date: event.date,
            logs: logs,
            dailyMacros: macros,
          )),
        );
      },
    );
  }

  Future<void> _onAddNutritionLog(
    AddNutritionLogEvent event,
    Emitter<NutritionLogState> emit,
  ) async {
    final result = await addNutritionLog(event.log);
    
    await result.fold(
      (failure) async => emit(NutritionLogError(failure.message)),
      (_) async {
        emit(const NutritionLogOperationSuccess('Nutrition log added successfully'));
        // Reload current day's data
        add(LoadDailyLogsEvent(_currentDate));
      },
    );
  }

  Future<void> _onUpdateNutritionLog(
    UpdateNutritionLogEvent event,
    Emitter<NutritionLogState> emit,
  ) async {
    final result = await updateNutritionLog(event.log);
    
    await result.fold(
      (failure) async => emit(NutritionLogError(failure.message)),
      (_) async {
        emit(const NutritionLogOperationSuccess('Nutrition log updated successfully'));
        // Reload current day's data
        add(LoadDailyLogsEvent(_currentDate));
      },
    );
  }

  Future<void> _onDeleteNutritionLog(
    DeleteNutritionLogEvent event,
    Emitter<NutritionLogState> emit,
  ) async {
    final result = await deleteNutritionLog(event.id);
    
    await result.fold(
      (failure) async => emit(NutritionLogError(failure.message)),
      (_) async {
        emit(const NutritionLogOperationSuccess('Nutrition log deleted successfully'));
        // Reload current day's data
        add(LoadDailyLogsEvent(_currentDate));
      },
    );
  }

  Future<void> _onRefreshDailyLogs(
    RefreshDailyLogsEvent event,
    Emitter<NutritionLogState> emit,
  ) async {
    add(LoadDailyLogsEvent(event.date));
  }
}