#include "Wire.h"
#include "Time.h"
#include "rtcBOB.h"

/*
 * single front end interface to both PCgetTime and RTCgetTime()
 * Uses RTC if available or INT if not.
 * Updates time from PC if available
 */

#define IS_BCD true
#define IS_DEC false
#define IS_BYTES false

time_t getTime(){
  uint8_t date[7];
  if(rtc_raw_read(0, 7, IS_BCD, date)){
    setTime(date[2], date[1], date[0], date[4], date[5], date[6]);
  }
  return now();
}

void setRTC(time_t t){
  tmElements_t tm;
  breakTime(t, tm);
  setRTC(tm.Year + 1970, tm.Month, tm.Day, tm.Hour, tm.Minute, tm.Second);
}
void setRTC(uint16_t YY, uint8_t MM, uint8_t DD, 
	    uint8_t hh, uint8_t mm, uint8_t ss){
  uint8_t date[7];
  date[0] = ss;
  date[1] = mm;
  date[2] = hh;
  date[3] = 0;
  date[4] = DD;
  date[5] = MM;
  date[6] = YY % 100;
  
  rtc_raw_write(0, 7, IS_BCD, date);
}

void setRTC_alarm(uint8_t ahh, uint8_t amm, uint8_t ass, uint8_t alarm_set){
  uint8_t date[3];
  date[0] = ass;
  date[1] = amm;
  date[2] = ahh;
  rtc_raw_write(DS3231_ALARM1_OFSET, 3, IS_BCD, date);
  rtc_raw_read(DS3231_ALARM1_OFSET + 3, 1, IS_BYTES, date);
  if(alarm_set){
    date[0] |= (1 << 7);
  }
  else{
    date[0] &= (~1 << 7);
  }
  rtc_raw_write(DS3231_ALARM1_OFSET + 3, 1, IS_BYTES, date);
}

void setSquareWave(int val){
  
}

void getRTC_alarm(uint8_t *ahh, uint8_t *amm, uint8_t *ass, 
		  uint8_t *alarm_set){
  uint8_t x;
  uint8_t date[3];
  if(rtc_raw_read(DS3231_ALARM1_OFSET, 3, IS_BCD, date)){
    *ass = date[0];
    *amm = date[1];
    *ahh = date[2];
    rtc_raw_read(DS3231_ALARM1_OFSET + 3, 1, IS_BYTES, date);
    *alarm_set = (date[0] >> 7) & 1; // use A1M4 as set bit
  }
  else{
    *ass = 0;
    *amm = 0;
    *ahh = 0;
  }
}

// get current temperature
int getTemp(){
  int temp_c;
  uint8_t tmp[2];

  if(rtc_raw_read(DS3231_TEMP_OFFSET, 2, IS_BYTES, tmp)){
    temp_c = (int)(tmp[0] << 5);
    temp_c |= (int)(tmp[1] >> 3); // will not work for negative temps (celcius)
    temp_c *= .03125;
  }
  else{
    temp_c = 99;
  }
  return temp_c;
}

// conversion routines
int toF(int C){
  return C * 9./5 + 32;
}
int toC(int F){
  return (F  - 32)* 5./9;
}

// decimal to binary coded decimal
uint8_t dec2bcd(int dec){
  uint8_t t = dec / 10;
  uint8_t o = dec - t * 10;
  return (t << 4) + o;
}

// binary coded decimal to decimal
int bcd2dec(uint8_t bcd){
  return (((bcd & 0b11110000)>>4)*10 + (bcd & 0b00001111));
}

bool rtc_raw_read(uint8_t addr,
		  uint8_t n_bytes,
		  bool is_bcd,
		  uint8_t *dest){

  bool out = false;
  Wire.beginTransmission(DS3231_ADDR); 
  // Wire.send(addr); 
  Wire.write((uint8_t)(addr));
  Wire.endTransmission();
  Wire.requestFrom(DS3231_ADDR, (int)n_bytes); // request n_bytes bytes 
  if(Wire.available()){
    for(uint8_t i = 0; i < n_bytes; i++){
      dest[i] = WIRE_READ;
      if(is_bcd){ // needs to be converted to dec
	dest[i] = bcd2dec(dest[i]);
      }
    }
    out = true;
  }
  return out;
}
void set_control_reg(){
  // From MaceTech.com
  // set 1Hz reference square wave
  Wire.beginTransmission(0x68); // address DS3231
  WIRE_WRITE1(0x0E); // select register
  WIRE_WRITE1(0b00000000); // write register bitmap, bit 7 is /EOSC
  Wire.endTransmission();
}
void rtc_raw_write(uint8_t addr,
		   uint8_t n_byte,
		   bool is_bcd,
		   uint8_t *source){
  uint8_t byte;

  Wire.beginTransmission(DS3231_ADDR); 
  WIRE_WRITE1(addr); // start at address addr
  for(uint8_t i = 0; i < n_byte; i++){
    if(is_bcd){
      byte = dec2bcd(source[i]);
    }
    else{
      byte = source[i];
    }
    WIRE_WRITE1(byte);
  }
  Wire.endTransmission();  
}

