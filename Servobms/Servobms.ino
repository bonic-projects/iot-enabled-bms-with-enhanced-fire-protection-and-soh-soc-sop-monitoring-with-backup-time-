#include <Servo.h>
#define FLAME_SENSOR_PIN A1
#define SERVO_PIN 4
Servo flameServo;
void setup() {
  pinMode(FLAME_SENSOR_PIN, INPUT);
  flameServo.attach(SERVO_PIN);
  flameServo.write(90);
  Serial.begin(9600);
  Serial.println("Flame detector servo control initialized");
}
void loop() {
  int flameValue = analogRead(FLAME_SENSOR_PIN);
  Serial.print("Flame sensor value: ");
  Serial.println(flameValue);
  if (flameValue < 100) { // Adjust threshold as needed
    Serial.println("Flame detected! Moving servo to 0 degrees.");
    flameServo.write(90);
  } else {
    Serial.println("No flame detected. Moving servo to 90 degrees.");
    flameServo.write(0);
  }
  delay(100);
}
