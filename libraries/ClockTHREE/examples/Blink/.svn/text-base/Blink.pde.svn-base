const int DBG = 16;
#define COL_DRIVER_ENABLE 17
void setup(){
  Serial.begin(57600); // for debugging
  Serial.println("Begin Blink test");
  pinMode(DBG, OUTPUT);
  pinMode(COL_DRIVER_ENABLE, OUTPUT);
  digitalWrite(COL_DRIVER_ENABLE, HIGH); // Enable col driver (slower)
}

void loop(){
  digitalWrite(DBG, HIGH);
  delay(500);
  digitalWrite(DBG, LOW);
  delay(500);
}
