import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/meal.dart';
import '../../../../domain/usecases/meals/get_all_meals.dart';
import '../../../../domain/usecases/meals/get_meal_by_id.dart';
import '../../../../domain/usecases/meals/get_meal_by_name.dart';
import '../../../../domain/usecases/meals/add_meal.dart';
import '../../../../domain/usecases/meals/update_meal.dart';
import '../../../../domain/usecases/meals/delete_meal.dart';

// ==================== Events ====================

abstract class MealEvent extends Equatable {
  const MealEvent();
  @override
  List<Object?> get props => [];
}

class LoadMealsEvent extends MealEvent {}

class LoadMealByIdEvent extends MealEvent {
  final String id;
  const LoadMealByIdEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class LoadMealByNameEvent extends MealEvent {
  final String name;
  const LoadMealByNameEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class AddMealEvent extends MealEvent {
  final Meal meal;
  const AddMealEvent(this.meal);
  @override
  List<Object?> get props => [meal];
}

class UpdateMealEvent extends MealEvent {
  final Meal meal;
  const UpdateMealEvent(this.meal);
  @override
  List<Object?> get props => [meal];
}

class DeleteMealEvent extends MealEvent {
  final String id;
  const DeleteMealEvent(this.id);
  @override
  List<Object?> get props => [id];
}

// ==================== States ====================

abstract class MealState extends Equatable {
  const MealState();
  @override
  List<Object?> get props => [];
}

class MealInitial extends MealState {}

class MealLoading extends MealState {}

class MealsLoaded extends MealState {
  final List<Meal> meals;
  const MealsLoaded(this.meals);
  @override
  List<Object?> get props => [meals];
}

class MealLoaded extends MealState {
  final Meal meal;
  const MealLoaded(this.meal);
  @override
  List<Object?> get props => [meal];
}

class MealError extends MealState {
  final String message;
  const MealError(this.message);
  @override
  List<Object?> get props => [message];
}

class MealOperationSuccess extends MealState {
  final String message;
  const MealOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ==================== BLoC ====================

class MealBloc extends Bloc<MealEvent, MealState> {
  final GetAllMeals getAllMeals;
  final GetMealById getMealById;
  final GetMealByName getMealByName;
  final AddMeal addMeal;
  final UpdateMeal updateMeal;
  final DeleteMeal deleteMeal;

  MealBloc({
    required this.getAllMeals,
    required this.getMealById,
    required this.getMealByName,
    required this.addMeal,
    required this.updateMeal,
    required this.deleteMeal,
  }) : super(MealInitial()) {
    on<LoadMealsEvent>(_onLoadMeals);
    on<LoadMealByIdEvent>(_onLoadMealById);
    on<LoadMealByNameEvent>(_onLoadMealByName);
    on<AddMealEvent>(_onAddMeal);
    on<UpdateMealEvent>(_onUpdateMeal);
    on<DeleteMealEvent>(_onDeleteMeal);
  }

  Future<void> _onLoadMeals(
    LoadMealsEvent event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    final result = await getAllMeals();
    result.fold(
      (failure) => emit(MealError(failure.message)),
      (meals) => emit(MealsLoaded(meals)),
    );
  }

  Future<void> _onLoadMealById(
    LoadMealByIdEvent event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    final result = await getMealById(event.id);
    result.fold(
      (failure) => emit(MealError(failure.message)),
      (meal) {
        if (meal == null) {
          emit(const MealError('Meal not found'));
        } else {
          emit(MealLoaded(meal));
        }
      },
    );
  }

  Future<void> _onLoadMealByName(
    LoadMealByNameEvent event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    final result = await getMealByName(event.name);
    result.fold(
      (failure) => emit(MealError(failure.message)),
      (meal) {
        if (meal == null) {
          emit(const MealError('Meal not found'));
        } else {
          emit(MealLoaded(meal));
        }
      },
    );
  }

  Future<void> _onAddMeal(
    AddMealEvent event,
    Emitter<MealState> emit,
  ) async {
    final result = await addMeal(event.meal);
    await result.fold(
      (failure) async => emit(MealError(failure.message)),
      (_) async {
        emit(const MealOperationSuccess('Meal added successfully'));
        add(LoadMealsEvent());
      },
    );
  }

  Future<void> _onUpdateMeal(
    UpdateMealEvent event,
    Emitter<MealState> emit,
  ) async {
    final result = await updateMeal(event.meal);
    await result.fold(
      (failure) async => emit(MealError(failure.message)),
      (_) async {
        emit(const MealOperationSuccess('Meal updated successfully'));
        add(LoadMealsEvent());
      },
    );
  }

  Future<void> _onDeleteMeal(
    DeleteMealEvent event,
    Emitter<MealState> emit,
  ) async {
    final result = await deleteMeal(event.id);
    await result.fold(
      (failure) async => emit(MealError(failure.message)),
      (_) async {
        emit(const MealOperationSuccess('Meal deleted successfully'));
        add(LoadMealsEvent());
      },
    );
  }
}