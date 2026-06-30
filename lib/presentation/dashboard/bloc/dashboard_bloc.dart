import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;
  StreamSubscription? _locationSubscription;
  Timer? _batteryPoller;

  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<BatteryStatusRequested>(_onBatteryStatusRequested);
    on<TrackingToggled>(_onTrackingToggled);
    on<DataRefreshed>(_onDataRefreshed);
    on<LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    await _repository.verifyPermissions();
    await _syncInterfaceState(emit);
    await _fetchBatteryStatus(emit);

    _locationSubscription = _repository.locationUpdates.listen((_) {
      add(LocationUpdated());
    });

    _batteryPoller = Timer.periodic(const Duration(seconds: 30), (_) {
      add(BatteryStatusRequested());
    });
  }

  Future<void> _onBatteryStatusRequested(
    BatteryStatusRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _fetchBatteryStatus(emit);
  }

  Future<void> _onTrackingToggled(
    TrackingToggled event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.trackingRunning) {
      await _repository.stopTracking();
      emit(state.copyWith(trackingRunning: false));
    } else {
      await _repository.startTracking();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    await _syncInterfaceState(emit);
  }

  Future<void> _onDataRefreshed(
    DataRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    await _syncInterfaceState(emit);
  }

  Future<void> _onLocationUpdated(
    LocationUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    await _syncInterfaceState(emit);
  }

  Future<void> _fetchBatteryStatus(Emitter<DashboardState> emit) async {
    final level = await _repository.getBatteryLevel();
    emit(state.copyWith(batteryLevel: level));
  }

  Future<void> _syncInterfaceState(Emitter<DashboardState> emit) async {
    final active = await _repository.isTrackingRunning();
    final rows = await _repository.getLocationRecords();
    emit(state.copyWith(
      trackingRunning: active,
      records: rows,
    ));
  }

  @override
  Future<void> close() {
    _batteryPoller?.cancel();
    _locationSubscription?.cancel();
    return super.close();
  }
}
