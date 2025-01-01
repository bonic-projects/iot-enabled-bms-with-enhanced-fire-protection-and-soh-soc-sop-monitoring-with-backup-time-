#include <Autobonics_Soc.h>

SOC_Library socLib;

void setup() {
  Serial.begin(9600);
}

void loop() {
  float batteryVoltage = socLib.readBatteryVoltage(A0); // Read voltage from A0
  int soc = socLib.getSOC(batteryVoltage); // Get SOC
  Serial.print("Voltage: ");
  Serial.print(batteryVoltage, 2);
  Serial.print(" V, SOC: ");
  Serial.print(soc);
  Serial.println(" %");
  delay(1000);
}
