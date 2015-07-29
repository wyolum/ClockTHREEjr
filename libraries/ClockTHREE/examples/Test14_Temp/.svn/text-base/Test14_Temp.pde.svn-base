/*
  ClockTHREE Test14 RTC Temperature
  print temperature in deg F and deg C via serial

  Justin Shaw Dec 11, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0
 */

#include <Wire.h>
#include "SPI.h"
#include "ClockTHREE.h"
#include "Time.h"
#include "rtcBOB.h"
#include "EEPROM.h"
#include "MsTimer2.h"
#include "rtcBOB.h"

void setup(){
  // start Wire proto
  Wire.begin();
  Serial.begin(57600); // for debugging
  pinMode(COL_DRIVER_ENABLE, OUTPUT);
  digitalWrite(COL_DRIVER_ENABLE, HIGH);
}

void loop(){
  int temp_c;
  temp_c = RTCgetTemp();
  Serial.print(temp_c, DEC);
  Serial.print(" Deg C, ");
  Serial.print((int)(9 * temp_c / 5. + 32), DEC);
  Serial.println(" Deg F");
  delay(10000);
}

// get current temperature
boolean RTCgetTemp(){
  boolean status;
  int temp;
  int temp_c;
  
  Wire.beginTransmission(104); // 104 is DS3231 device address
   Wire.send(0x11); // start at register 0x11
  Wire.endTransmission();
  Wire.requestFrom(104, 2); // request 2 bytes 
  status = Wire.available();
  if(status){
    uint8_t tmp[0];
    tmp[0] = Wire.receive();
    tmp[1] = Wire.receive();
    temp = (int)(tmp[0] << 5);
    temp |= (int)(tmp[1] >> 3); // will not work for negative temps (celcius)
    temp_c = .03125 * temp;
  }
  else{
    temp_c = 99;
  }
  return temp_c;
}

