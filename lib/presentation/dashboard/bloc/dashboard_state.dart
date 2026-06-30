import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final int batteryLevel;
  final bool trackingRunning;
  final List<Map<String, dynamic>> records;

  const DashboardState({
    this.batteryLevel = 100,
    this.trackingRunning = false,
    this.records = const [],
  });

  DashboardState copyWith({
    int? batteryLevel,
    bool? trackingRunning,
    List<Map<String, dynamic>>? records,
  }) {
    return DashboardState(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      trackingRunning: trackingRunning ?? this.trackingRunning,
      records: records ?? this.records,
    );
  }

  @override
  List<Object?> get props => [batteryLevel, trackingRunning, records];
}
