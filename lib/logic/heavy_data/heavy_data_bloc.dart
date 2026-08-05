import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/open_fda_repository.dart';
import 'heavy_data_event.dart';
import 'heavy_data_state.dart';

class HeavyDataBloc extends Bloc<HeavyDataEvent, HeavyDataState> {
  final OpenFDARepository _repository;

  HeavyDataBloc(this._repository) : super(HeavyDataInitial()) {
    on<FetchFdaEvents>(_onFetchFdaEvents);
  }

  Future<void> _onFetchFdaEvents(
    FetchFdaEvents event,
    Emitter<HeavyDataState> emit,
  ) async {
    emit(HeavyDataLoading());
    try {
      final events = await _repository.fetchEvents();
      emit(HeavyDataLoaded(events));
    } catch (e) {
      emit(HeavyDataError(e.toString()));
    }
  }
}
