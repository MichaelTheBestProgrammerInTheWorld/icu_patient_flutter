import 'package:equatable/equatable.dart';
import 'package:waveform_flutter/waveform_flutter.dart';

abstract class TelemetryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TelemetryInitial extends TelemetryState {}

class TelemetryLoading extends TelemetryState {}

class TelemetryDataUpdate extends TelemetryState {
  final Amplitude amplitude;
  final DateTime timestamp;

  TelemetryDataUpdate(this.amplitude) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [amplitude, timestamp];
}

/// NEW: State to represent paused telemetry without resetting the UI graph
class TelemetryPaused extends TelemetryState {
  final Amplitude lastAmplitude;
  
  TelemetryPaused(this.lastAmplitude);

  @override
  List<Object?> get props => [lastAmplitude];
}

class TelemetryError extends TelemetryState {
  final String message;
  TelemetryError(this.message);

  @override
  List<Object?> get props => [message];
}
