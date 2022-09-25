#include <SoftwareSerial.h>

#define SOIL_PIN A0
#define RELAY_PIN 7

SoftwareSerial btSerial(2, 3);  // RX, TX (Cross connect to HC05)

int relayState = LOW;  // for pump
unsigned long previousMillis = 0;
const long interval = 3200;
bool pumpShouldRun = false;

void setup() {
  Serial.begin(9600);
  btSerial.begin(9600);

  pinMode(SOIL_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);
}

void loop() {
  if (btSerial.available() > 0) {
    String payload = btSerial.readString();
    payload.trim();
    if (payload.equals("water")) {
      Serial.println("Trigger pump");
      pumpShouldRun = true;
    }
  }

 unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    if (pumpShouldRun) {
        pumpShouldRun = false;
    }
  }

  if (pumpShouldRun) {
    digitalWrite(RELAY_PIN, LOW);
  } else {
    digitalWrite(RELAY_PIN, HIGH);
  }

  int humidity = analogRead(SOIL_PIN);
  btSerial.println(humidity);

  delay(200);
}