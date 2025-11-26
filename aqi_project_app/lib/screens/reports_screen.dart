import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportsScreen extends StatelessWidget {
  final List<String> summaries;

  const ReportsScreen({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Report History")),
      body: summaries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.fileJson,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No reports generated yet.\nGo to Dashboard and click 'Analyze'.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      summaries[index],
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
