/*
  ClockTHREE Test12 LDR test
  blink LED based on LDR value

  Original source _Getting_Started_With_Arduino_ p. 64.
  Modified by Justin Shaw Dec 14, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
 */

 // the pin for the LED
int val;
const int LDR_PIN = 0;
const int DBG = 16;
void setup() {
  Serial.begin(57600);
  pinMode(DBG, OUTPUT); // LED is as an OUTPUT
  // Note: Analogue pins are
  // automatically set as inputs
}
void loop() {
  val = analogRead(LDR_PIN);
  Serial.println(val);
  digitalWrite(DBG, HIGH);
  delay(val/2); // stop the program for
  digitalWrite(DBG, LOW);
  delay(val/2); // stop the program for
}

