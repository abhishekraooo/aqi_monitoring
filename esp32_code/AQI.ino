#include <WiFi.h>
#include <WiFiClient.h>
#include <WebServer.h>
#include <TinyGPSPlus.h>
#include <DHT.h>
#include <ArduinoJson.h> // JSON Library

// --- 1. CONFIGURATION ---

// !!! CHANGE THESE TO YOUR WIFI !!!
const char* ssid = "MountainDew";
const char* password = "passwordd";

// Server Setup
WebServer server(80); 

// Sensor Pins
#define DHT_PIN 2
#define MQ2_PIN 34 
#define MQ9_PIN 35
#define MQ135_PIN 32 

// Sharp GP2Y10 Pins
#define GP2Y10_LED_PIN 4      // Control Pulse
#define GP2Y10_VOUT_PIN 36    // Analog In (VP Pin on many ESP32 boards)

// GPS Setup
#define GPS_RX_PIN 16 
#define GPS_TX_PIN 17 
#define DHTTYPE DHT11

// --- 2. CONSTANTS & OBJECTS ---
DHT dht(DHT_PIN, DHTTYPE);
TinyGPSPlus gps;
HardwareSerial gpsSerial(2); 

// MQ Constants
const float RL = 10.0;     // Load Resistance (10kOhm)
// R0 values need calibration, but these are standard starting points
const float R0_MQ2 = 9.83; 
const float R0_MQ9 = 8.65;
const float R0_MQ135 = 7.7; 

// Sharp Dust Sensor Constants (Tweak these for calibration)
const float SHARP_VOC = 0.6; // Volts at zero dust (calibration point)
const float SHARP_K = 0.5;   // Sensitivity (0.5V per 100ug/m3)

// Global JSON String
String json_payload = "{}";

// --- 3. HELPER FUNCTIONS ---

void setup_wifi() {
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) { 
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi connected.");
    Serial.print("Server IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi Failed. Running Offline.");
  }
}

// Convert ADC (0-4095) to Voltage (0-5.0V)
float getVoltage(int adcValue) {
  // Note: ESP32 ADC is not perfectly linear, but this is sufficient for this level of project
  return (float)adcValue * (5.0 / 4095.0);
}

float getRs(float voltage) {
  // Avoid divide by zero
  if (voltage >= 5.0 || voltage <= 0.0) return 0; 
  // Rs = (Vcc * RL / VRL) - RL
  return (5.0 * RL / voltage) - RL; 
}

// --- SHARP SENSOR IMPROVED LOGIC ---
float readSharpDustDensity() {
  float totalVoltage = 0;
  int samples = 10; // Take 10 samples to average out noise

  for (int i = 0; i < samples; i++) {
    digitalWrite(GP2Y10_LED_PIN, LOW); // LED ON
    delayMicroseconds(280); 
    
    int raw = analogRead(GP2Y10_VOUT_PIN);
    
    delayMicroseconds(40); 
    digitalWrite(GP2Y10_LED_PIN, HIGH); // LED OFF
    
    // Add delay before next sample to let capacitor recover
    delayMicroseconds(9680); 
    
    totalVoltage += getVoltage(raw);
  }

  // Average Voltage
  float avgVoltage = totalVoltage / samples;
  
  // Calculate Density: (Voltage - Voc) / Sensitivity
  // Result is in units of 100ug/m3, so multiply by 100 to get ug/m3
  float dustDensity = (avgVoltage - SHARP_VOC) / SHARP_K * 100.0;
  
  if (dustDensity < 0) dustDensity = 0; // No negative dust
  return dustDensity;
}

String getAQIStatus(float mq135Ratio) {
  if (mq135Ratio < 0.7) return "HAZARDOUS";
  if (mq135Ratio < 0.9) return "UNHEALTHY";
  if (mq135Ratio < 1.1) return "MODERATE";
  return "GOOD";
}

// --- WEB SERVER HANDLERS ---
void handleData() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json_payload);
}

void handleNotFound() {
  server.send(404, "text/plain", "Not Found");
}

// --- DATA COLLECTION ROUTINE ---
void update_sensor_data() {
  // 1. Read Raw ADC Values
  int raw_mq2 = analogRead(MQ2_PIN);
  int raw_mq9 = analogRead(MQ9_PIN);
  int raw_mq135 = analogRead(MQ135_PIN);
  
  // 2. Convert to Voltage
  float v_mq2 = getVoltage(raw_mq2);
  float v_mq9 = getVoltage(raw_mq9);
  float v_mq135 = getVoltage(raw_mq135);
  
  // 3. Calculate Resistance (Rs)
  float rs_mq2 = getRs(v_mq2);
  float rs_mq9 = getRs(v_mq9);
  float rs_mq135 = getRs(v_mq135);
  
  // 4. Calculate Ratios
  float r_mq2 = rs_mq2 / R0_MQ2;
  float r_mq9 = rs_mq9 / R0_MQ9;
  float r_mq135 = rs_mq135 / R0_MQ135;
  
  // 5. Read Environmental & Dust
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  float pm_ugm3 = readSharpDustDensity();
  
  // 6. Construct JSON Payload
  // Increased size to 1024 to hold all the raw data fields
  DynamicJsonDocument doc(1024);

  // --- GPS Section ---
  if (gps.location.isValid()) {
    doc["GPS_LAT"] = gps.location.lat();
    doc["GPS_LNG"] = gps.location.lng();
    doc["GPS_ALT"] = gps.altitude.meters();
    doc["GPS_SPD"] = gps.speed.kmph();
    doc["GPS_SAT"] = gps.satellites.value();
  } else {
    doc["GPS_LAT"] = 0.0;
    doc["GPS_LNG"] = 0.0;
    doc["GPS_SAT"] = 0;
  }

  // --- Environmental Section ---
  doc["ENV_TEMP"] = isnan(t) ? 0.0 : t;
  doc["ENV_HUM"] = isnan(h) ? 0.0 : h;

  // --- Dust Section ---
  doc["PM_DENSITY"] = pm_ugm3;
  // Calculate a rough raw voltage for the dust sensor (approx)
  doc["PM_VOLT"] = (pm_ugm3 / 100.0 * SHARP_K) + SHARP_VOC; 

  // --- Gas Raw Section (For advanced app features) ---
  // Sending ADC values (0-4095)
  doc["RAW_MQ2"] = raw_mq2;
  doc["RAW_MQ9"] = raw_mq9;
  doc["RAW_MQ135"] = raw_mq135;

  // Sending Voltages (0-5V)
  doc["VOLT_MQ2"] = v_mq2;
  doc["VOLT_MQ9"] = v_mq9;
  doc["VOLT_MQ135"] = v_mq135;

  // Sending Calculated Ratios
  doc["RATIO_MQ2"] = r_mq2;
  doc["RATIO_MQ9"] = r_mq9;
  doc["RATIO_MQ135"] = r_mq135;

  // --- Metadata ---
  doc["STATUS"] = getAQIStatus(r_mq135);
  doc["UPTIME"] = millis();
  doc["WIFI_RSSI"] = WiFi.RSSI(); // Signal strength

  // Serialize
  json_payload = "";
  serializeJson(doc, json_payload);
  
  Serial.print("JSON Updated: ");
  Serial.println(json_payload);
}

// --- 4. MAIN SETUP & LOOP ---

void setup() {
  Serial.begin(115200);
  pinMode(GP2Y10_LED_PIN, OUTPUT);
  digitalWrite(GP2Y10_LED_PIN, HIGH); // LED OFF
  
  dht.begin();
  gpsSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

  setup_wifi();

  if (WiFi.status() == WL_CONNECTED) {
    server.on("/data", HTTP_GET, handleData);
    server.onNotFound(handleNotFound);
    server.begin();
    Serial.println("HTTP Server started.");
  }
  
  Serial.println("System Initialized. Warming up...");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    server.handleClient();
  }

  // Continuous GPS processing
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }

  // Data Refresh Timer (Every 3 seconds)
  static unsigned long last_update = 0;
  if (millis() - last_update > 3000) {
    update_sensor_data();
    last_update = millis();
  }
  
  delay(10); 
}