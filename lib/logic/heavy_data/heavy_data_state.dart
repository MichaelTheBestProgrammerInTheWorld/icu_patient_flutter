import 'package:equatable/equatable.dart';

abstract class HeavyDataState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HeavyDataInitial extends HeavyDataState {}

class HeavyDataLoading extends HeavyDataState {}

class HeavyDataLoaded extends HeavyDataState {
  final List<dynamic> events;
  HeavyDataLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class HeavyDataError extends HeavyDataState {
  final String message;
  HeavyDataError(this.message);

  @override
  List<Object?> get props => [message];
}
