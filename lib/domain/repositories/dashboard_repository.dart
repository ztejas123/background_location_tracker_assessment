import 'package:flutter_background_service/flutter_background_service.dart';

abstract class DashboardRepository {
  Future<int> getBatteryLevel();
  Future<bool> isTrackingRunning();
  Future<List<Map<String, dynamic>>> getLocationRecords();
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<void> verifyPermissions();
  Stream<void> get locationUpdates;
}
