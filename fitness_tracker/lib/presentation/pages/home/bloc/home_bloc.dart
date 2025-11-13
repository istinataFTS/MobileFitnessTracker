import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/entities/workout_set.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/workout_sets/get_weekly_sets.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

// States
abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Target> targets;
  final List<WorkoutSet> weeklySets;
  
  const HomeLoaded({
    required this.targets,
    required this.weeklySets,
  });
  
  @override
  List<Object?> get props => [targets, weeklySets];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAllTargets getAllTargets;
  final GetWeeklySets getWeeklySets;

  HomeBloc({
    required this.getAllTargets,
    required this.getWeeklySets,
  }) : super(HomeInitial()) {
    on<LoadHomeDataEvent>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeDataEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    
    final targetsResult = await getAllTargets();
    final setsResult = await getWeeklySets();
    
    if (targetsResult.isLeft() || setsResult.isLeft()) {
      emit(const HomeError(AppStrings.errorLoadData));
      return;
    }
    
    final targets = targetsResult.getOrElse(() => []);
    final sets = setsResult.getOrElse(() => []);
    
    emit(HomeLoaded(targets: targets, weeklySets: sets));
  }
}