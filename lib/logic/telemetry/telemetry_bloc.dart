import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/repositories/coinbase_repository.dart';
import 'telemetry_event.dart';
import 'telemetry_state.dart';

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  final CoinbaseRepository _repository;
  StreamSubscription? _subscription;

  TelemetryBloc(this._repository) : super(TelemetryInitial()) {
    on<StartTelemetry>(_onStartTelemetry);
    on<StopTelemetry>(_onStopTelemetry);
    on<_InternalDataUpdate>(_onInternalDataUpdate);
    on<_InternalError>(_onInternalError);
  }

  Future<void> _onStartTelemetry(
    StartTelemetry event,
    Emitter<TelemetryState> emit,
  ) async {
    emit(TelemetryLoading());
    await _subscription?.cancel();
    
    // Throttle state emissions to exactly 100ms interval for high-frequency data
    _subscription = _repository.tickerStream
        .throttleTime(const Duration(milliseconds: 100), trailing: true, leading: true)
        .listen(
      (amplitude) {
        add(_InternalDataUpdate(amplitude));
      },
      onError: (error) {
        add(_InternalError(error.toString()));
      },
    );
  }

  void _onStopTelemetry(StopTelemetry event, Emitter<TelemetryState> emit) {
    _subscription?.cancel();
    emit(TelemetryInitial());
  }

  void _onInternalDataUpdate(_InternalDataUpdate event, Emitter<TelemetryState> emit) {
    emit(TelemetryDataUpdate(event.amplitude));
  }

  void _onInternalError(_InternalError event, Emitter<TelemetryState> emit) {
    emit(TelemetryError(event.message));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _InternalDataUpdate extends TelemetryEvent {
  final dynamic amplitude;
  _InternalDataUpdate(this.amplitude);
}

class _InternalError extends TelemetryEvent {
  final String message;
  _InternalError(this.message);
}
