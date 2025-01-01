#ifndef Autobonics_Soc_h
#define Autobonics_Soc_h

#include "Arduino.h"

class SOC_Library {
public:
  SOC_Library(); // Constructor
  int getSOC(float voltage); // Function to calculate SOC
  float readBatteryVoltage(int pin); // Function to read voltage from a pin
  bool getStatus(float voltage);
private:
  static const int tableSize = 101; // Number of entries in the table
  static const float voltageTable[tableSize]; // Voltage lookup table
  static const int socTable[tableSize];       // SOC lookup table
};

#endif
