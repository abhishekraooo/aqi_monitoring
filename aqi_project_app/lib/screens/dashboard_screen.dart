import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/sensor_data.dart';
import '../widgets/ai_chat_modal.dart';

class DashboardScreen extends StatelessWidget {
  final SensorData data;
  final Function(String) onSummaryGenerated;

  const DashboardScreen({
    super.key,
    required this.data,
    required this.onSummaryGenerated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Dashboard'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              data.isConnected ? Icons.wifi : Icons.wifi_off,
              color: data.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => AIChatModal(
              sensorDataString: data.toAIString(),
              onSave: onSummaryGenerated,
            ),
          );
        },
        label: const Text("Summarize with AI"),
        icon: const Icon(LucideIcons.sparkles),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _buildMainStatus(context),
          const SizedBox(height: 20),
          _sectionHeader("Environment"),
          _buildEnvGrid(),
          const SizedBox(height: 20),
          _sectionHeader("Gas Sensors"),
          _buildGasList(),
        ],
      ),
    );
  }

  Widget _buildMainStatus(BuildContext context) {
    Color color = _getStatusColor(data.status);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.9), color]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "AIR QUALITY INDEX",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Dust Density: ${data.pmDensity.toStringAsFixed(1)} µg/m³",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _statCard(
          LucideIcons.thermometer,
          "Temp",
          "${data.temperature}°C",
          Colors.orange,
        ),
        _statCard(
          LucideIcons.droplets,
          "Humidity",
          "${data.humidity}%",
          Colors.blue,
        ),
        _statCard(
          LucideIcons.wind,
          "PM Voltage",
          "${data.pmVolt.toStringAsFixed(2)}V",
          Colors.grey,
        ),
        _statCard(
          LucideIcons.satellite,
          "Satellites",
          "${data.satellites}",
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildGasList() {
    return Column(
      children: [
        _gasTile("MQ-2 (Smoke)", data.mq2Ratio, data.mq2Volt, Colors.brown),
        _gasTile("MQ-9 (CO)", data.mq9Ratio, data.mq9Volt, Colors.redAccent),
        _gasTile("MQ-135 (Air)", data.mq135Ratio, data.mq135Volt, Colors.teal),
      ],
    );
  }

  Widget _gasTile(String name, double ratio, double volt, Color color) {
    double progress = (2.0 - ratio).clamp(0.0, 2.0) / 2.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "R/R0: ${ratio.toStringAsFixed(2)}",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: color.withOpacity(0.1),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Raw: ${volt.toStringAsFixed(2)} V",
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains("GOOD")) return Colors.green;
    if (status.contains("MODERATE")) return Colors.orange;
    if (status.contains("UNHEALTHY")) return Colors.red;
    return Colors.grey;
  }
}
