#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <EEPROM.h>
#include <Adafruit_INA219.h>
#include <Autobonics_Soc.h>
#include <DFRobot_DHT11.h>
#define DHT11_PIN 23
#define WIFI_SSID "Autobonics_4G"
#define WIFI_PASSWORD "autobonics@27"
#define API_KEY "AIzaSyBrJgdBGlBUOPZeUmB6s8NWUObLUPzTHUg"
#define DATABASE_URL "https://iot-based-bms-2d49b-default-rtdb.firebaseio.com"
#define USER_EMAIL "sonusubi456@gmail.com"
#define USER_PASSWORD "123456"
#define BUTTON_PIN 2        // Pin connected to the push button
#define VOLTAGE_PIN 36        // Pin to read battery voltage
#define LI_VOLTAGE_PIN 33
#define BUTTON_ONE 39         // Secondary button for other functionalities
#define BUTTON_TWO 35
#define DEBOUNCE_DELAY 50     // Debounce delay for button press
#define LCD_ADDRESS 0x27
#define LCD_COLUMNS 16
#define LCD_ROWS 2
#define EEPROM_SIZE 512
#define SOC_ADDRESS 0
#define SOH_ADDRESS 4
#define SOC_LI_ADDRESS 8
#define SOH_LI_ADDRESS 12
Adafruit_INA219 ina219(0x40);
Adafruit_INA219 ina219_2(0x41);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
// Voltage divider constants
const float R1 = 29900.0;   // Resistor R1 value (30kΩ)
const float R2 = 7400.0;    // Resistor R2 value (7.4kΩ)
const float Vref = 3.3;     // Reference voltage for ADC
const int ADC_MAX = 4096;   // ADC resolution (12-bit)
const int TOTAL_SOC = 25000;
const int TOTAL_SOC_LI = 40000;
// Initial values
float initialSOC = 100.0;   // Start with 100% SOC
float previousSOC = 100.0;  // Track previous SOC
float totalSOCDrop = 0.0;   // Accumulate the SOC drop
int chargeCycles = 0;       // Track number of charge cycles
float SOH = 100.0;
float initialSOC_LI = 100.0;   // Start with 100% SOC
float previousSOC_LI = 100.0;  // Track previous SOC
float totalSOCDrop_LI = 0.0;   // Accumulate the SOC drop
int chargeCycles_LI = 0;       // Track number of charge cycles
float SOH_LI = 100.0;           // Start with 100% SOH

volatile bool isLithiumProgram = true; // Toggle flag for battery type (use volatile for ISR)
bool buttonPressed = false;            // Button state to handle ISR logic in `loop()`
SOC_Library socLib;
DFRobot_DHT11 DHT;
LiquidCrystal_I2C lcd(LCD_ADDRESS, LCD_COLUMNS, LCD_ROWS);

// Voltage-to-SOC lookup table
const float voltageTable[101] = {
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

// Forward declarations
float analogReadVoltage();
void reset();
int findSOC(float voltage);

// ISR function


void setup() {
    // Blynk.begin(BLYNK_AUTH_TOKEN, ssid, pass);
    Serial.begin(115200);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) delay(300);
  Serial.println("Connected to Wi-Fi");
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);
    pinMode(BUTTON_PIN, INPUT_PULLUP); // Configure button pin as input with pull-up
    pinMode(VOLTAGE_PIN, INPUT);
    pinMode(BUTTON_ONE, INPUT);
    pinMode(BUTTON_TWO,INPUT);
    EEPROM.begin(EEPROM_SIZE);
    lcd.init();
    lcd.backlight();

    // Attach the ISR to the button pin

    // Initialize variables from EEPROM
    totalSOCDrop = EEPROM.readFloat(SOC_ADDRESS);
    if (isnan(totalSOCDrop) || totalSOCDrop < 0) {
        totalSOCDrop = 0.0;
    }

    SOH = EEPROM.readFloat(SOH_ADDRESS);
    if (isnan(SOH) || SOH < 0 || SOH > 100) {
        SOH = 100.0;
    }
      totalSOCDrop_LI = EEPROM.readFloat(SOC_LI_ADDRESS);
    if (isnan(totalSOCDrop_LI) || totalSOCDrop_LI < 0) {
        totalSOCDrop_LI = 0.0;
    }

    SOH_LI = EEPROM.readFloat(SOH_LI_ADDRESS);
    if (isnan(SOH_LI) || SOH_LI < 0 || SOH_LI > 100) {
        SOH_LI = 100.0;
    }
  Serial.println("Initializing INA219...");
  if (!ina219.begin()) {
    Serial.println("Failed to find INA219 at 0x40");
    while (1) { delay(10); } // Halt if INA219 is not found
  }
  Serial.println("Initializing INA219_2...");
  if (!ina219_2.begin()) {
    Serial.println("Failed to find INA219 at 0x41");
    while (1) { delay(10); } // Halt if INA219 is not found
  }
    Serial.println("System initialized.");
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("  IOT ENABLED");
      lcd.setCursor(0, 1);
      lcd.print("      BMS");
      delay(1000);
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("  PRESS RED");
      lcd.setCursor(0, 1);
      lcd.print("     BUTTON");

}

void loop() {
   temperature();
  bool toggleValue;

  // Fetch data from Firebase Realtime Database
  if (Firebase.getBool(fbdo, FPSTR("/batterydata/toggle"))) {
    toggleValue = fbdo.to<bool>(); // Assign the value to the variable
    Serial.printf("Toggle value: %s\n", toggleValue ? "true" : "false");
  } else {
    // Print the error if the operation fails
    Serial.printf("Error: %s\n", fbdo.errorReason().c_str());
  }
    if (toggleValue) {

        // Lithium-ion battery program
           int buttonState_LI =digitalRead(BUTTON_TWO);
           float batteryVoltage = socLib.readBatteryVoltage(LI_VOLTAGE_PIN); // Read voltage from A0
           int soc = socLib.getSOC(batteryVoltage); // Get SOC
           Serial.print("Voltage :");
           Serial.println(batteryVoltage);
           bool status =socLib.getStatus(batteryVoltage);
           Serial.print("status :");
           Serial.print(status);
           if(status==0)
           {
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("LI-ON not");
            lcd.setCursor(0, 1);
            lcd.print("connected");
        int zero =0;
        if (Firebase.setInt(fbdo, F("batterydata/lithium/soc"), zero)) {
          Serial.println("lithhium soc pushed successfully!");
        } else {
          Serial.println("Failed to push lithhium soc value: " + fbdo.errorReason());
         }
        if (Firebase.setInt(fbdo, F("batterydata/lithium/soh"), zero)) {
          Serial.println("lithium soh pushed successfully!");
        } else {
          Serial.println("Failed to push lithium soh value: " + fbdo.errorReason());
         }
            delay(1000);

            return;           
           }
        else{
             if (soc < previousSOC_LI) {
         float socDrop = previousSOC_LI - soc;
         totalSOCDrop_LI += socDrop;

         // Cap totalSOCDrop to TOTAL_SOC
         if (totalSOCDrop_LI > TOTAL_SOC_LI) {
             totalSOCDrop_LI = TOTAL_SOC_LI;
         }

         if (TOTAL_SOC_LI > 0) {
             SOH_LI = ((TOTAL_SOC_LI - totalSOCDrop_LI) / TOTAL_SOC_LI) * 100;
         } else {
             SOH_LI = 0;
         }
        EEPROM.writeFloat(SOC_LI_ADDRESS, totalSOCDrop_LI);
        EEPROM.writeFloat(SOH_LI_ADDRESS, SOH_LI);
        EEPROM.commit();
        previousSOC_LI = soc;
        }
        if (buttonState_LI == HIGH) {
         reset_LI();
        }
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("SOC: ");
        lcd.print(soc);
        lcd.print("%");
        lcd.setCursor(0, 1);
        lcd.print("SOH: ");
        lcd.print(SOH_LI, 2);
        lcd.print("%");
        if (Firebase.setInt(fbdo, F("batterydata/lithium/soc"), soc)) {
          Serial.println("lithium soc pushed successfully!");
        } else {
          Serial.println("Failed to push lithium soc value: " + fbdo.errorReason());
         }
        if (Firebase.setInt(fbdo, F("batterydata/lithium/soh"), SOH_LI)) {
          Serial.println("lithium soh  pushed successfully!");
        } else {
          Serial.println("Failed to push lithium soh value: " + fbdo.errorReason());
         }
        
        delay(2000);
        timeRemaining_LI(6100,SOH_LI,batteryVoltage);
        float time = timeRemaining_LI(6100,SOH_LI,batteryVoltage);
         if (Firebase.setInt(fbdo, F("batterydata/lithium/timeremaining"), time)) {
          Serial.println("lithium time pushed successfully!");
        } else {
          Serial.println("Failed to push lithium time  value: " + fbdo.errorReason());
         }

    }} 
    else {
        // Lead-acid battery program
        float voltage = voltagee();
        Serial.print("Voltage :");
        Serial.println(voltage);
        if (voltage < 9.80) {
            Serial.println("Battery not connected or voltage out of range.");
            lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("LEAD ACID not");
            lcd.setCursor(0, 1);
            lcd.print("connected");
        int zero =0;
        if (Firebase.setInt(fbdo, F("batterydata/leadacid/soc"), zero)) {
          Serial.println("leadacid soc pushed successfully!");
        } else {
          Serial.println("Failed to push leadacid soc value: " + fbdo.errorReason());
         }
        if (Firebase.setInt(fbdo, F("batterydata/leadacid/soh"), zero)) {
          Serial.println("leadacid soh pushed successfully!");
        } else {
          Serial.println("Failed to push leadacid soh value: " + fbdo.errorReason());
         }
            delay(1000);
            return; // Exit the loop if the battery is not connected
        }
      int buttonState = digitalRead(BUTTON_ONE);


        // Calculate SOC
        int soc = findSOC(voltage);

        // Update SOC and SOH if SOC drops
        if (soc < previousSOC) {
            float socDrop = previousSOC - soc;
            totalSOCDrop += socDrop;

            // Cap totalSOCDrop to TOTAL_SOC
            if (totalSOCDrop > TOTAL_SOC) {
                totalSOCDrop = TOTAL_SOC;
            }

            if (TOTAL_SOC > 0) {
                SOH = ((TOTAL_SOC - totalSOCDrop) / TOTAL_SOC) * 100;
            } else {
                SOH = 0;
            }

            // Save updated values to EEPROM
            EEPROM.writeFloat(SOC_ADDRESS, totalSOCDrop);
            EEPROM.writeFloat(SOH_ADDRESS, SOH);
            EEPROM.commit();

            previousSOC = soc; // Update previous SOC
        }
        if (buttonState == HIGH) {
            reset();
        }
            // Display results on LCD
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("SOC: ");
        lcd.print(soc);
        lcd.print("%");
        lcd.setCursor(0, 1);
        lcd.print("SOH: ");
        lcd.print(SOH, 2);
        lcd.print("%");

        Serial.print("Voltage: ");
        Serial.print(voltage, 2);
        Serial.print(" V, SOC: ");
        Serial.print(soc);
        Serial.print("%, SOH: ");
        Serial.print(SOH, 2);
        Serial.println("%");
        if (Firebase.setInt(fbdo, F("batterydata/leadacid/soc"), soc)) {
          Serial.println("leadacid soc pushed successfully!");
        } else {
          Serial.println("Failed to push leadacid soc value: " + fbdo.errorReason());
         }
        if (Firebase.setInt(fbdo, F("batterydata/leadacid/soh"), SOH)) {
          Serial.println("leadacid soh pushed successfully!");
        } else {
          Serial.println("Failed to push leadacid soh value: " + fbdo.errorReason());
         }
        delay(2000);
        timeRemaining(7000,SOH,voltage);
        float time = timeRemaining(7000,SOH,voltage);
        if (Firebase.setInt(fbdo, F("batterydata/leadacid/timeremaining"), time)) {
          Serial.println("leadacid time pushed successfully!");
        } else {
          Serial.println("Failed to push leadacid time value: " + fbdo.errorReason());
         }
    }
}

// Function to find SOC based on voltage
int findSOC(float voltage) {
    for (int i = 0; i < 101; i++) {
        if (voltage >= voltageTable[i]) {
            return 100 - i; // Return the corresponding SOC (100 - index)
        }
    }
    return 0; // Return 0% SOC if voltage is lower than minimum
}

// Function to read voltage


// Function to reset SOC and SOH
void reset() {
    totalSOCDrop = 0;
    SOH = 100.0;

    // Save reset values to EEPROM
    EEPROM.writeFloat(SOC_ADDRESS, totalSOCDrop);
    EEPROM.writeFloat(SOH_ADDRESS, SOH);
    EEPROM.commit();

    Serial.println("System reset.");
}
void reset_LI() {
    totalSOCDrop_LI = 0;
    SOH_LI = 100.0;

    // Save reset values to EEPROM
    EEPROM.writeFloat(SOC_LI_ADDRESS, totalSOCDrop_LI);
    EEPROM.writeFloat(SOH_LI_ADDRESS, SOH_LI);
    EEPROM.commit();

    Serial.println("System reset.");
}
float timeRemaining( float totalCapacity,float soc,float voltage)
{
  float batteryCapacity=(totalCapacity*(soc/100));
  float remainingTime;  // hours
    float current = ina219.getCurrent_mA();
  if (current < 10) {
    current = 0;  // Ensure no negative current values
  }

  // Calculate remaining time in hours (battery capacity / current)
  if (current > 0) {
    remainingTime = batteryCapacity / current;  // hours
    Serial.print("Current: "); Serial.print(current); Serial.println(" mA");
    Serial.print("Remaining Time: "); Serial.print(remainingTime); Serial.println(" hours");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Remaining Time:");
    lcd.setCursor(0, 1);
    lcd.print(remainingTime, 2);
    lcd.print("hr");
    int power = abs(current*voltage);
   float sop = readSOP(power,7000);
        if (Firebase.setInt(fbdo, F("batterydata/leadacid/sop"), sop)) {
          Serial.println("leadacid sop pushed successfully!");
        } else {
          Serial.println("Failed to push leadacid sop value: " + fbdo.errorReason());
         }
  } else {
    Serial.println("Current is too low or zero; cannot calculate remaining time.");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Load not");
    lcd.setCursor(0, 1);
    lcd.print("connected");
    remainingTime = 0;
  }

 return remainingTime;
  delay(2000); // Wait 1 second before the next reading
}
float timeRemaining_LI( float totalCapacity,float soc,float voltage)
{
  float batteryCapacity=(totalCapacity*(soc/100));
    float current = ina219_2.getCurrent_mA();
    float power = abs(current*voltage);
    Serial.print("current :");
    Serial.println(current);
     Serial.print("voltage :");
    Serial.println(voltage); 
    Serial.print("power :");
    Serial.println(power);
    float remainingTime;
     if (current < 5) {
    current = 0;  // Ensure no negative current values
  }

  // Calculate remaining time in hours (battery capacity / current)
  if (current > 0) {
    remainingTime = batteryCapacity / current;
    Serial.print("Current: "); Serial.print(current); Serial.println(" mA");
    Serial.print("Remaining Time: "); Serial.print(remainingTime); Serial.println(" hours");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Remaining Time:");
    lcd.setCursor(0, 1);
    lcd.print(remainingTime, 2);
    lcd.print("hr");
    float sop = readSOP(power,6800);
        if (Firebase.setInt(fbdo, F("batterydata/lithium/sop"), sop)) {
          Serial.println("litium ion sop pushed successfully!");
          Serial.print("litium ion sop value");
          Serial.println(sop);

        } else {
          Serial.println("Failed to push lithium ion sop value: " + fbdo.errorReason());
         }
  } else {
    Serial.println("Current is too low or zero; cannot calculate remaining time.");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Load not");
    lcd.setCursor(0, 1);
    lcd.print("connected");
    remainingTime =0;
  }
return remainingTime;
delay(2000);
}
void temperature()
{
  DHT.read(DHT11_PIN);
  Serial.print("temp:");
  Serial.print(DHT.temperature);
    if (Firebase.setInt(fbdo, F("batterydata/temperature"),DHT.temperature)) {
    Serial.println("temperature pushed successfully!");
  } else {
    Serial.println("Failed to push temperature: " + fbdo.errorReason());
   }
}
float readSOP(float currentPower,float totalPower )
{
  Serial.print(" sopcurrent power :");
  Serial.println(currentPower);
  Serial.print(" sop totalPower :");
  Serial.println(totalPower);
  float power= (currentPower/totalPower)*100;
   Serial.print(" sop power :");
  Serial.println(power);
  return power;
}
float voltagee()
{
  int rawADC = analogRead(VOLTAGE_PIN); // Read raw ADC value
  float Vout = (rawADC / ADC_MAX) * Vref; // Convert ADC to voltage
  float Vin = Vout * ((R1 + R2) / R2);    // Calculate input voltage

  // Handle cases where Vin is too low due to the voltage divider
  if (Vin < 0.1) {
    Vin = 0.0; // To avoid negative or small incorrect readings
  }
      if (Firebase.setInt(fbdo, F("Solar/otherdata/voltage"), Vin)) {
    Serial.println("voltage pushed successfully!");
  } else {
    Serial.println("Failed to push voltage value: " + fbdo.errorReason());
   }
   return Vin;
}