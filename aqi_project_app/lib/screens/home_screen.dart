import 'dart:async';
import 'package:aqi_project/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/sensor_data.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Default to Dashboard
  final ApiService _apiService = ApiService();

  // State shared across tabs
  SensorData _currentData = SensorData.empty();
  final List<String> _aiSummaries = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startDataStream();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDataStream() {
    // Poll the ESP32 every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchData();
    });
    _fetchData(); // Initial fetch
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchSensorData();
      if (mounted) {
        setState(() {
          _currentData = data;
        });
      }
    } catch (e) {
      // On error, update connectivity status but keep old data values if possible
      if (mounted && _currentData.isConnected) {
        setState(() {
          // Create a copy of current data but mark as offline
          // (In a real app, use copyWith)
          // For simplicity, we just log the error for now
          print("Connection lost: $e");
        });
      }
    }
  }

  // Callback to add AI summary to the list
  void _addSummary(String summary) {
    final timestamp = DateFormat('hh:mm a').format(DateTime.now());
    setState(() {
      _aiSummaries.insert(0, "$timestamp: $summary");
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ReportsScreen(summaries: _aiSummaries),
      DashboardScreen(data: _currentData, onSummaryGenerated: _addSummary),
      MapScreen(data: _currentData),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.fileText),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(LucideIcons.map), label: 'Location'),
        ],
      ),
    );
  }
}
