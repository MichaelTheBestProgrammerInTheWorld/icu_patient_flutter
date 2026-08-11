import 'package:equatable/equatable.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

abstract class TelemetryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTelemetry extends TelemetryEvent {}
class StopTelemetry extends TelemetryEvent {}

class InternalDataUpdate extends TelemetryEvent {
  final Amplitude amplitude;
  InternalDataUpdate(this.amplitude);
  @override
  List<Object?> get props => [amplitude];
}

class InternalError extends TelemetryEvent {
  final String message;
  InternalError(this.message);
  @override
  List<Object?> get props => [message];
}
