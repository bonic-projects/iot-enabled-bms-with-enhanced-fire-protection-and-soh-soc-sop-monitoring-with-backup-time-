import 'package:firebase_database/firebase_database.dart';
import '../models/temperature_data.dart';

class TemperatureService {
  final DatabaseReference _temperatureRef = FirebaseDatabase.instance.ref('batterydata/temperature');

  // Fetch temperature data as a stream
  Stream<Temperature> getTemperatureStream() {
    return _temperatureRef.onValue.map((event) {
      final data = event.snapshot.value;

      // Log the data for debugging purposes
      print('Received data from Firebase: $data');

      // Check if data is a number (assuming it represents the temperature)
      if (data != null && data is num) {
        // Create and return the Temperature object with the scalar value
        return Temperature(value: data.toDouble());
      } else {
        throw Exception("Data is not in the expected format. Received: $data");
      }
    });
  }

  // Update the temperature data in Firebase
  Future<void> updateTemperature(double temperature) async {
    try {
      // Update the temperature value in Firebase
      await _temperatureRef.set(temperature);
      print("Temperature updated in Firebase: $temperature");
    } catch (e) {
      print("Failed to update temperature in Firebase: $e");
    }
  }
}
