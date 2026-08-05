import 'package:equatable/equatable.dart';

abstract class TelemetryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTelemetry extends TelemetryEvent {}
class StopTelemetry extends TelemetryEvent {}
