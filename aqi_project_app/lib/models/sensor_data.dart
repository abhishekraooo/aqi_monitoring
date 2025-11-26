class SensorData {
  final double temperature;
  final double humidity;
  final double pmDensity;
  final double pmVolt;
  final double mq2Ratio;
  final double mq9Ratio;
  final double mq135Ratio;
  final double mq2Volt;
  final double mq9Volt;
  final double mq135Volt;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final int satellites;
  final String status;
  final DateTime timestamp;
  final bool isConnected;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.pmDensity,
    required this.pmVolt,
    required this.mq2Ratio,
    required this.mq9Ratio,
    required this.mq135Ratio,
    required this.mq2Volt,
    required this.mq9Volt,
    required this.mq135Volt,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.satellites,
    required this.status,
    required this.timestamp,
    required this.isConnected,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['ENV_TEMP'] ?? 0.0).toDouble(),
      humidity: (json['ENV_HUM'] ?? 0.0).toDouble(),
      pmDensity: (json['PM_DENSITY'] ?? 0.0).toDouble(),
      pmVolt: (json['PM_VOLT'] ?? 0.0).toDouble(),
      mq2Ratio: (json['RATIO_MQ2'] ?? 0.0).toDouble(),
      mq9Ratio: (json['RATIO_MQ9'] ?? 0.0).toDouble(),
      mq135Ratio: (json['RATIO_MQ135'] ?? 0.0).toDouble(),
      mq2Volt: (json['VOLT_MQ2'] ?? 0.0).toDouble(),
      mq9Volt: (json['VOLT_MQ9'] ?? 0.0).toDouble(),
      mq135Volt: (json['VOLT_MQ135'] ?? 0.0).toDouble(),
      latitude: (json['GPS_LAT'] ?? 0.0).toDouble(),
      longitude: (json['GPS_LNG'] ?? 0.0).toDouble(),
      altitude: (json['GPS_ALT'] ?? 0.0).toDouble(),
      speed: (json['GPS_SPD'] ?? 0.0).toDouble(),
      satellites: (json['GPS_SAT'] ?? 0).toInt(),
      status: json['STATUS'] ?? 'Offline',
      timestamp: DateTime.now(),
      isConnected: true,
    );
  }

  factory SensorData.empty() {
    return SensorData(
      temperature: 0,
      humidity: 0,
      pmDensity: 0,
      pmVolt: 0,
      mq2Ratio: 0,
      mq9Ratio: 0,
      mq135Ratio: 0,
      mq2Volt: 0,
      mq9Volt: 0,
      mq135Volt: 0,
      latitude: 0,
      longitude: 0,
      altitude: 0,
      speed: 0,
      satellites: 0,
      status: "Connecting...",
      timestamp: DateTime.now(),
      isConnected: false,
    );
  }

  // Helper to format data for the AI prompt
  String toAIString() {
    return """
    Current Air Quality Telemetry:
    - PM2.5 Dust Density: ${pmDensity.toStringAsFixed(1)} µg/m³
    - MQ-135 (General Pollutants) Ratio: ${mq135Ratio.toStringAsFixed(3)}
    - MQ-2 (Smoke/LPG) Ratio: ${mq2Ratio.toStringAsFixed(3)}
    - MQ-9 (CO/Flammable) Ratio: ${mq9Ratio.toStringAsFixed(3)}
    - Temperature: $temperature °C
    - Humidity: $humidity %
    
    Please analyze this data. Is the air safe? Are there specific gas warnings?
    """;
  }
}
