import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIChatModal extends StatefulWidget {
  final String sensorDataString;
  final Function(String) onSave;

  const AIChatModal({
    super.key,
    required this.sensorDataString,
    required this.onSave,
  });

  @override
  State<AIChatModal> createState() => _AIChatModalState();
}

class _AIChatModalState extends State<AIChatModal> {
  // !!! REPLACE WITH YOUR GEMINI API KEY !!!
  final String _apiKey = "AIzaSyCWS0K6wxfw4xZd69FS-ki8aiBNQ8mbSwE";

  final List<String> _messages = [];
  bool _isLoading = false;
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    // Using 'gemini-pro' for text analysis
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    _sendDeclarativeAnalysis();
  }

  Future<void> _sendDeclarativeAnalysis() async {
    setState(() {
      _messages.add("System: Analyzing Telemetry...");
      _isLoading = true;
    });

    try {
      // Simplified Prompt for Non-Technical Output
      final prompt =
          """
      Act as a simple air quality assistant.
      Analyze the sensor data below.
      
      THRESHOLDS:
      - Dust: > 35 is Unhealthy.
      - Gas Ratios: < 0.8 is Dangerous, < 1.1 is Warning.

      DATA:
      ${widget.sensorDataString}

      INSTRUCTIONS:
      1. Give a simple status: "Air is [Safe/Unhealthy/Moderate]".
      2. Briefly mention the reason in plain English (e.g., "High smoke detected" or "Dust levels are high").
      3. Do NOT use technical units (like µg/m³), sensor model numbers, or jargon.
      4. Keep it very short, simple, and direct.
      """;

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      setState(() {
        _isLoading = false;
        if (response.text != null) {
          // We prefix with "Report:" instead of a persona name to look more technical
          _messages.add("Report:\n${response.text}");
          widget.onSave(response.text!); // Save to history
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          "System Error: Analysis Failed. Check API Key or Network.",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Safety Analysis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isSystem = msg.startsWith("System:");
                final isReport = msg.startsWith("Report:");

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Technical look: Green tint for reports, Grey for system
                    color: isReport
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: isReport
                        ? Border.all(color: Colors.green.shade200)
                        : null,
                  ),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: isReport ? Colors.green.shade900 : Colors.black87,
                      fontFamily: 'Poppins', // Keep consistent font
                      fontWeight: isReport
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Colors.black),
            ),
        ],
      ),
    );
  }
}
