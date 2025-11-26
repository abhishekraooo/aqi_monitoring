import 'dart:convert';
import 'package:aqi_project/models/sensor_data.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // !!! REPLACE WITH YOUR ESP32 IP !!!
  static const String esp32Ip = "10.190.70.173";
  static const String _baseUrl = "http://$esp32Ip/data";

  Future<SensorData> fetchSensorData() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final jsonMap = json.decode(response.body);
        return SensorData.fromJson(jsonMap);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}
