/*
  ClockTHREE Test09 RTC
  scroll time from rtcBOB using font library

  Justin Shaw Dec 11, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0
 */

#include <Time.h>
#include <Wire.h>
#include "rtcBOB.h"
#include "SPI.h"
#include "font.h"
#include "english.h"
#include "EEPROM.h"
#include "MsTimer2.h"

const char SET_BYTE = 'S';

void setup(){
  // start comm protos
  digitalWrite(A4, HIGH);
  digitalWrite(A5, HIGH);

  Serial.begin(115200); // for debugging
  Serial.println("Begin rtcBOB test");
  Wire.begin();
  Serial.println("Wire started");
  Serial.println(getTime());

  // setSyncProvider(getTime);      // RTC
  // Serial.println("Sync providor set");
  setSyncInterval(60000);      // update every minute (and on boot)
  Serial.print("Type ");
  Serial.print(SET_BYTE);
  Serial.println(" to reset time to compile time.");
}

uint32_t count = 0;
void resettime(){
  setCompileTime();
  Serial.print("Time set time to compile time");
  Serial.println("Disconnect power and reconnect.");
  Serial.println("Displayed time should be a few seconds later.");
  Serial.println("");
  Serial.println("This tests RTC reading, writing, and back up battery");
  delay(5000);
}
void interact(){
  if(Serial.available()){
    if(Serial.read() == SET_BYTE){
      resettime();
    }
  }
}

void loop(){
  uint8_t ahh, amm, ass, is_set = count % 2;
  int ones, tens, dec_val, bcd_val;
  for(int tens = 0; tens < 10; tens++){
    for(int ones = 0; ones < 10; ones++){
      bcd_val = tens << 4 | ones; 
      dec_val = 10 * tens + ones;
      if(dec2bcd(dec_val) != bcd_val){
	Serial.print("dec2bcd broken: ");
	Serial.print(dec2bcd(dec_val), BIN);
	Serial.print("!=");
	Serial.print(bcd_val, BIN);
	done();
      }
      if(bcd2dec(bcd_val) != dec_val){
	Serial.print("bcd2dec broken: ");
	Serial.print(bcd2dec(bcd_val), DEC);
	Serial.print("!=");
	Serial.print(dec_val, DEC);
	done();
      }
    }
  }
  Serial.println("Verify that time = alarm time");
  for(int i = 0; i < 5; i++){
    is_set = i % 2;
    interact();
    Serial.print("rtc time:");
    Serial.print(getTime());
    Serial.print(" =? Arduino time:");
    Serial.print(year());
    Serial.print("/");
    Serial.print(month());
    Serial.print("/");
    Serial.print(day());
    Serial.print(" ");
    print_time(hour(), minute(), second());
    Serial.print(" ");
    Serial.print(is_set, DEC);
    Serial.print(" =? alarm time:");
    setRTC_alarm(hour(), minute(), second(), is_set);
    getRTC_alarm(&ahh, &amm, &ass, &is_set);
    print_time(ahh, amm, ass);
    Serial.print(" ");
    Serial.println(is_set, DEC);

    delay(1000);
    count++;
  }
  
  Serial.print("Type ");
  Serial.print(SET_BYTE);
  Serial.println(" to reset time to compile time");
  while(1){
    interact();
    delay(100);
  }
  done();
}
void print_time(uint8_t hh, uint8_t mm, uint8_t ss){
  two_digits(hh);
  Serial.print(":");
  two_digits(mm);
  Serial.print(":");
  two_digits(ss);
}
void two_digits(uint8_t val){
  Serial.print(val/10, DEC);
  Serial.print(val%10, DEC);
}

void done(){
  Serial.println("");
  Serial.println("DONE!");
  while(1){
    delay(1000);
  }
}


void setCompileTime(){
  char *date = __DATE__;
  char *tm   = __TIME__;
  byte i;
  int yyyy = 0;
  int hh = 0;
  int mm = 0;
  int ss = 0;
  int dd = 0;
  for(i = 0; i<4; i++){
    yyyy = (10 * yyyy) + (date[7 + i] - '0');
  }
  for(i = 0; i < 2; i++){
    hh = (10 * hh) + (tm[0 + i] - '0');
    mm = (10 * mm) + (tm[3 + i] - '0');
    ss = (10 * ss) + (tm[6 + i] - '0');
    dd = (10 * dd) + (date[4 + i] - '0');
  }

  long mmm = (date[0] - 'A') * (26 * 26) + 
    (date[1] - 'a') * 26 + 
    date[2] - 'a';
  switch (mmm) {
  case 6097:
    mmm = 1;
    break;
  case 3485:
    mmm = 2;
    break;
  case 8129:
    mmm = 3;
    break;
  case 407:
    mmm = 4;
    break;
  case 8136:
    mmm = 5;
    break;
  case 6617:
    mmm = 6;
    break;
  case 6615:
    mmm = 7;
    break;
  case 526:
    mmm = 8;
    break;
  case 12287:
    mmm = 9;
    break;
  case 9535:
    mmm = 10;
    break;
  case 9173:
    mmm = 11;
    break;
  case 2134:
    mmm = 12;
    break;
  default:
    mmm = 1;
    break;
  }
  /*
Jan 6097
   Feb 3485
   Mar 8129
   Apr 407
   May 8136
   Jun 6617
   Jul 6615
   Aug 526
   Sep 12287
   Oct 9535
   Nov 9173
   Dec 2134
   */

  
  setRTC(yyyy, mmm, dd, hh - 3, mm, ss);
  setTime(hh, mmm, ss, dd, mm, yyyy);

  Serial.print("Time set to ");
  print_time(hh, mm, ss);
  Serial.print("\nArduino time ");
  print_time(hour(), minute(), second());
  Serial.println("");
}
