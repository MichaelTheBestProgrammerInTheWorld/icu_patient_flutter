import 'package:equatable/equatable.dart';

abstract class TelemetryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTelemetry extends TelemetryEvent {}
class StopTelemetry extends TelemetryEvent {}

class InternalDataUpdate extends TelemetryEvent {
  final dynamic amplitude;
  InternalDataUpdate(this.amplitude);
}

class InternalError extends TelemetryEvent {
  final String message;
  InternalError(this.message);
}
