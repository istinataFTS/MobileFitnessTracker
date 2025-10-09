import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/target.dart';
import '../../../../domain/usecases/targets/add_target.dart';
import '../../../../domain/usecases/targets/delete_target.dart';
import '../../../../domain/usecases/targets/get_all_targets.dart';
import '../../../../domain/usecases/targets/update_target.dart';

// Events
abstract class TargetsEvent extends Equatable {
  const TargetsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTargetsEvent extends TargetsEvent {}

class AddTargetEvent extends TargetsEvent {
  final Target target;
  const AddTargetEvent(this.target);
  @override
  List<Object?> get props => [target];
}

class UpdateTargetEvent extends TargetsEvent {
  final Target target;
  const UpdateTargetEvent(this.target);
  @override
  List<Object?> get props => [target];
}

class DeleteTargetEvent extends TargetsEvent {
  final String muscleGroup;
  const DeleteTargetEvent(this.muscleGroup);
  @override
  List<Object?> get props => [muscleGroup];
}

// States
abstract class TargetsState extends Equatable {
  const TargetsState();
  @override
  List<Object?> get props => [];
}

class TargetsInitial extends TargetsState {}

class TargetsLoading extends TargetsState {}

class TargetsLoaded extends TargetsState {
  final List<Target> targets;
  const TargetsLoaded(this.targets);
  @override
  List<Object?> get props => [targets];
}

class TargetsError extends TargetsState {
  final String message;
  const TargetsError(this.message);
  @override
  List<Object?> get props => [message];
}

class TargetOperationSuccess extends TargetsState {
  final String message;
  const TargetOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TargetsBloc extends Bloc<TargetsEvent, TargetsState> {
  final GetAllTargets getAllTargets;
  final AddTarget addTarget;
  final UpdateTarget updateTarget;
  final DeleteTarget deleteTarget;

  TargetsBloc({
    required this.getAllTargets,
    required this.addTarget,
    required this.updateTarget,
    required this.deleteTarget,
  }) : super(TargetsInitial()) {
    on<LoadTargetsEvent>(_onLoadTargets);
    on<AddTargetEvent>(_onAddTarget);
    on<UpdateTargetEvent>(_onUpdateTarget);
    on<DeleteTargetEvent>(_onDeleteTarget);
  }

  Future<void> _onLoadTargets(
    LoadTargetsEvent event,
    Emitter<TargetsState> emit,
  ) async {
    emit(TargetsLoading());
    final result = await getAllTargets();
    result.fold(
      (failure) => emit(TargetsError(failure.message)),
      (targets) => emit(TargetsLoaded(targets)),
    );
  }

  Future<void> _onAddTarget(
    AddTargetEvent event,
    Emitter<TargetsState> emit,
  ) async {
    final result = await addTarget(event.target);
    await result.fold(
      (failure) async => emit(TargetsError(failure.message)),
      (_) async {
        emit(const TargetOperationSuccess('Target added successfully'));
        add(LoadTargetsEvent());
      },
    );
  }

  Future<void> _onUpdateTarget(
    UpdateTargetEvent event,
    Emitter<TargetsState> emit,
  ) async {
    final result = await updateTarget(event.target);
    await result.fold(
      (failure) async => emit(TargetsError(failure.message)),
      (_) async {
        emit(const TargetOperationSuccess('Target updated successfully'));
        add(LoadTargetsEvent());
      },
    );
  }

  Future<void> _onDeleteTarget(
    DeleteTargetEvent event,
    Emitter<TargetsState> emit,
  ) async {
    final result = await deleteTarget(event.muscleGroup);
    await result.fold(
      (failure) async => emit(TargetsError(failure.message)),
      (_) async {
        emit(const TargetOperationSuccess('Target deleted successfully'));
        add(LoadTargetsEvent());
      },
    );
  }
}