#include "Autobonics_Soc.h"

// Constructor
SOC_Library::SOC_Library() {}

// Voltage lookup table
const float SOC_Library::voltageTable[tableSize] = {
  9.0, 9.036, 9.072, 9.108, 9.144, 9.18, 9.216, 9.252, 9.288, 9.324,
  9.36, 9.396, 9.432, 9.468, 9.504, 9.54, 9.576, 9.612, 9.648, 9.684,
  9.72, 9.756, 9.792, 9.828, 9.864, 9.9, 9.936, 9.972, 10.008, 10.044,
  10.08, 10.116, 10.152, 10.188, 10.224, 10.26, 10.296, 10.332, 10.368, 10.404,
  10.44, 10.476, 10.512, 10.548, 10.584, 10.62, 10.656, 10.692, 10.728, 10.764,
  10.8, 10.836, 10.872, 10.908, 10.944, 10.98, 11.016, 11.052, 11.088, 11.124,
  11.16, 11.196, 11.232, 11.268, 11.304, 11.34, 11.376, 11.412, 11.448, 11.484,
  11.52, 11.556, 11.592, 11.628, 11.664, 11.7, 11.736, 11.772, 11.808, 11.844,
  11.88, 11.916, 11.952, 11.988, 12.024, 12.06, 12.096, 12.132, 12.168, 12.204,
  12.24, 12.276, 12.312, 12.348, 12.384, 12.42, 12.456, 12.492, 12.528, 12.564, 12.6
};

// SOC lookup table
const int SOC_Library::socTable[tableSize] = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
  10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
  20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
  30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
  40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
  50, 51, 52, 53, 54, 55, 56, 57, 58, 59,
  60, 61, 62, 63, 64, 65, 66, 67, 68, 69,
  70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
  80, 81, 82, 83, 84, 85, 86, 87, 88, 89,
  90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100
};

// Function to calculate SOC based on voltage
int SOC_Library::getSOC(float voltage) {
  if (voltage <= voltageTable[0]) {
    return socTable[0];
  }
  if (voltage >= voltageTable[tableSize - 1]) {
    return socTable[tableSize - 1];
  }

  // Find the SOC using the lookup table
  for (int i = 0; i < tableSize - 1; i++) {
    if (voltage >= voltageTable[i] && voltage < voltageTable[i + 1]) {
      return socTable[i];
    }
  }
  return 0; // Default return
}

// Function to simulate reading the battery voltage
float SOC_Library::readBatteryVoltage(int VOLTAGE_PIN) {
    const float R1 = 29900.0;   // Resistor R1 value (30kΩ)
    const float R2 = 7400.0;    // Resistor R2 value (7.4kΩ)
    const float VREF = 3.3;     // Reference voltage for ADC
    const int ADC_MAX = 4096;
    const int numReadings = 100; // Number of readings to average
    long total = 0;             // Variable to accumulate readings

    // Take multiple readings and accumulate them
    for (int i = 0; i < numReadings; i++) {
        total += analogRead(VOLTAGE_PIN);
        delay(10); // Small delay between readings
    }

    // Calculate the average ADC value
    int adcValue = total / numReadings;

    // Convert the ADC value to voltage
    float adcVoltage = (adcValue / float(ADC_MAX)) * VREF;
    float batteryVoltage = adcVoltage * (R1 + R2) / R2;

    return batteryVoltage;
}
bool SOC_Library::getStatus(float voltage) {
  if(voltage>8){
    return true;
  }
  else{
    return false;
  }
}