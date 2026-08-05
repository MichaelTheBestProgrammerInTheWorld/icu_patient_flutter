import 'package:equatable/equatable.dart';

abstract class HeavyDataEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchFdaEvents extends HeavyDataEvent {}
