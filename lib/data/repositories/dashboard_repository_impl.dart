import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../database/database_helper.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  static const _channel = MethodChannel('samples.flutter.dev/battery');
  final _locationUpdatesController = StreamController<void>.broadcast();

  @override
  Future<int> getBatteryLevel() async {
    try {
      final int level = await _channel.invokeMethod('getBatteryLevel');
      return level;
    } on PlatformException catch (_) {
      return -1;
    }
  }

  @override
  Future<bool> isTrackingRunning() async {
    return await FlutterBackgroundService().isRunning();
  }

  @override
  Future<List<Map<String, dynamic>>> getLocationRecords() async {
    return await DatabaseHelper.instance.queryAllRows();
  }

  @override
  Future<void> startTracking() async {
    await FlutterBackgroundService().startService();
  }

  @override
  Future<void> stopTracking() async {
    FlutterBackgroundService().invoke('stopService');
  }

  @override
  Future<void> verifyPermissions() async {
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
      await Permission.notification.request();
    }

    LocationPermission status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    if (status == LocationPermission.whileInUse) {
      await Geolocator.requestPermission();
    }
  }

  @override
  Stream<void> get locationUpdates {
    FlutterBackgroundService().on('onLocationUpdated').listen((_) {
      _locationUpdatesController.add(null);
    });
    return _locationUpdatesController.stream;
  }

  void dispose() {
    _locationUpdatesController.close();
  }
}
