import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class BatteryStatusRequested extends DashboardEvent {
  const BatteryStatusRequested();
}

class TrackingToggled extends DashboardEvent {
  const TrackingToggled();
}

class DataRefreshed extends DashboardEvent {
  const DataRefreshed();
}

class LocationUpdated extends DashboardEvent {
  const LocationUpdated();
}
