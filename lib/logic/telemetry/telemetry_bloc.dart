import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:waveform_flutter/waveform_flutter.dart';
import '../../data/repositories/coinbase_repository.dart';
import 'telemetry_event.dart';
import 'telemetry_state.dart';

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  final CoinbaseRepository _repository;
  StreamSubscription? _subscription;
  Amplitude _lastAmplitude = Amplitude(current: 0, max: 1);

  TelemetryBloc(this._repository) : super(TelemetryInitial()) {
    on<StartTelemetry>(_onStartTelemetry);
    on<StopTelemetry>(_onStopTelemetry);
    on<InternalDataUpdate>(_onInternalDataUpdate);
    on<InternalError>(_onInternalError);
  }

  Future<void> _onStartTelemetry(
    StartTelemetry event,
    Emitter<TelemetryState> emit,
  ) async {
    // If already loading or update, don't emit loading again to avoid UI flicker
    if (state is! TelemetryDataUpdate && state is! TelemetryPaused) {
      emit(TelemetryLoading());
    }
    
    await _subscription?.cancel();
    _repository.setStreaming(true);
    
    _subscription = _repository.tickerStream
        .throttleTime(const Duration(milliseconds: 100), trailing: true, leading: true)
        .listen(
      (amplitude) {
        add(InternalDataUpdate(amplitude));
      },
      onError: (error) {
        add(InternalError(error.toString()));
      },
    );
  }

  void _onStopTelemetry(StopTelemetry event, Emitter<TelemetryState> emit) {
    _subscription?.cancel();
    _repository.setStreaming(false);
    
    // FIX 1: Emit TelemetryPaused instead of TelemetryInitial to preserve UI waveform state
    emit(TelemetryPaused(_lastAmplitude));
  }

  void _onInternalDataUpdate(InternalDataUpdate event, Emitter<TelemetryState> emit) {
    _lastAmplitude = event.amplitude;
    emit(TelemetryDataUpdate(event.amplitude));
  }

  void _onInternalError(InternalError event, Emitter<TelemetryState> emit) {
    emit(TelemetryError(event.message));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}


