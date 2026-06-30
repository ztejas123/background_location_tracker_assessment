import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper.instance;

  service.on('stopService').listen((event) async {
    if (service is AndroidServiceInstance) {
      await service.setAsBackgroundService();

      service.setForegroundNotificationInfo(
        title: "TELEMETRY ENGINE: ACTIVE",
        content: "Initializing spatial tracking loops...",
      );
    }
    await service.stopSelf();
  });

  // Capture first location immediately on start
  Future<void> captureLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      await dbHelper.insertLocation({
        DatabaseHelper.columnLatitude: position.latitude,
        DatabaseHelper.columnLongitude: position.longitude,
        DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String(),
        DatabaseHelper.columnAccuracy: position.accuracy,
      });

      service.invoke('onLocationUpdated');
    } catch (e) {
      // Direct error recording fallback block
      await dbHelper.insertLocation({
        DatabaseHelper.columnLatitude: 0.0,
        DatabaseHelper.columnLongitude: 0.0,
        DatabaseHelper.columnTimestamp: DateTime.now().toIso8601String(),
        DatabaseHelper.columnAccuracy: 0.0,
      });
      service.invoke('onLocationUpdated');
    }
  }

  // Capture first location immediately
  await captureLocation();

  // Check instance status directly without calling method channels
  Timer.periodic(const Duration(seconds: 60), (timer) async {
    // If the service is an Android instance, verify it hasn't been closed out externally
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) {
        timer.cancel();
        return;
      }
      final rows = await dbHelper.queryAllRows();
      service.setForegroundNotificationInfo(
        title: "ENGINE RUNNING",
        content: "Synchronized logs: ${rows.length} tracking points secured.",
      );
    }

    await captureLocation();
  });
}

class BackgroundTrackerService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'geo_tracker_channel',
        initialNotificationTitle: 'Tracking Active',
        initialNotificationContent: 'Continuous tracking enabled (60s cycles)',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (service) async => true,
      ),
    );
  }
}