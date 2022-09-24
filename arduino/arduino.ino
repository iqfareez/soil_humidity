#include <SoftwareSerial.h>

#define SOIL_PIN A0
#define PUMP_PIN 7

SoftwareSerial btSerial(2, 3);  // RX, TX (Cross connect to HC05)

int pumpState = LOW;               // used to set the LED state
unsigned long previousMillis = 0;  //will store last time LED was blinked
const long period = 6000;         // period at which to blink in ms
bool pumpShouldRun = false;

void setup() {
  Serial.begin(9600);
  btSerial.begin(9600);

  pinMode(SOIL_PIN, INPUT);
  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, HIGH);
}

int brightness = 0;  // how bright the LED is
int fadeAmount = 5;  // how many points to fade the LED by

void loop() {
  if (btSerial.available() > 0) {
    String payload = btSerial.readString();
    payload.trim();
    Serial.print(payload);
    if (payload.equals("water")) {
      pumpShouldRun = true;
    }
  }

  if (pumpShouldRun) {
     unsigned long currentMillis = millis();  // store the current time

    if (currentMillis - previousMillis >= period) {  // check if time has passed
      previousMillis = currentMillis;                
      pumpShouldRun = false;
      pumpState = HIGH;
    } else {
      pumpState = LOW;
    }
    digitalWrite(PUMP_PIN, pumpState);  
  }

  int humidity = analogRead(SOIL_PIN);
  btSerial.println(humidity); 
  
  delay(200);
}