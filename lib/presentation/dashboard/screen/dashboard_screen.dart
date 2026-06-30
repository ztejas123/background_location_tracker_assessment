import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/repositories/dashboard_repository_impl.dart';
import '../widgets/hero_stat_tile.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../map/screen/map_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = DashboardRepositoryImpl();
    return BlocProvider(
      create: (context) => DashboardBloc(repository)..add(const DashboardStarted()),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final latestLog = state.records.isNotEmpty ? state.records.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TELEMETRY ENGINE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18)),
        centerTitle: true,
        backgroundColor: AppColors.slate800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw, size: 18),
            onPressed: () => context.read<DashboardBloc>().add(const DataRefreshed()),
          ),
          IconButton(
            icon: const Icon(LucideIcons.map, size: 18),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: state.trackingRunning
                    ? [AppColors.emeraldActive, AppColors.emeraldDark]
                    : [AppColors.slate800, AppColors.slate900],
              ),
              border: Border(bottom: BorderSide(color: state.trackingRunning ? AppColors.emeraldBrand.withOpacity(0.3) : Colors.white10)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.trackingRunning ? 'ENGINE RUNNING' : 'SYSTEM DORMANT',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: state.trackingRunning ? AppColors.emeraldAccent : Colors.amberAccent
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.trackingRunning ? 'Tracking continuous GPS loops' : 'Ready to begin session logs',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    Icon(
                      state.trackingRunning ? LucideIcons.radar : LucideIcons.activity,
                      color: state.trackingRunning ? AppColors.emeraldAccent : Colors.grey,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    HeroStatTile(
                      icon: LucideIcons.battery,
                      title: 'BATTERY STATUS',
                      value: state.batteryLevel == -1 ? 'ERROR' : '${state.batteryLevel}%',
                      color: state.batteryLevel > 20 ? AppColors.emeraldAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 16),
                    HeroStatTile(
                      icon: LucideIcons.database,
                      title: 'TOTAL DATA POINTS',
                      value: '${state.records.length} logs',
                      color: Colors.cyanAccent,
                    ),
                  ],
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => context.read<DashboardBloc>().add(const TrackingToggled()),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: state.trackingRunning
                        ? [Colors.redAccent, Colors.red.shade900]
                        : [AppColors.emeraldBrand, Colors.teal.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (state.trackingRunning ? Colors.red : AppColors.emeraldBrand).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(state.trackingRunning ? LucideIcons.square : LucideIcons.play, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      state.trackingRunning ? 'TERMINATE ENGINE TRACKING' : 'INITIALIZE TRACKING ENGINE',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SPATIAL STREAM LOGGER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white60)),
                if (latestLog != null)
                  Text(
                    'Last Update: ${DateFormat('jm').format(DateTime.parse(latestLog[DatabaseHelper.columnTimestamp]))}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.records.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.map_pin, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No active telemetry data records found.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.records.length,
              itemBuilder: (context, index) {
                final data = state.records[index];
                final logTime = DateTime.parse(data[DatabaseHelper.columnTimestamp]);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.slate800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: index == 0 && state.trackingRunning ? AppColors.emeraldBrand.withOpacity(0.5) : Colors.white),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: index == 0 && state.trackingRunning ? AppColors.emeraldBrand.withOpacity(0.1) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          LucideIcons.navigation,
                          color: index == 0 && state.trackingRunning ? AppColors.emeraldAccent : Colors.grey,
                          size: 16
                      ),
                    ),
                    title: Text(
                      '${data[DatabaseHelper.columnLatitude].toStringAsFixed(6)}, ${data[DatabaseHelper.columnLongitude].toStringAsFixed(6)}',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Variance: ±${data[DatabaseHelper.columnAccuracy].toStringAsFixed(1)}m • ${DateFormat('yMMMd').format(logTime)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    trailing: Text(
                      DateFormat('HH:mm:ss').format(logTime),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
      },
    );
  }
}