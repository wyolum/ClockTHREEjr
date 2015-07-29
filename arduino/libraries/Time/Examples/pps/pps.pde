#include "rtcBOB.h"
#include "Time.h"
#include "Wire.h"
#include <NewSoftSerial.h>
#include <TinyGPS.h>
#include <EEPROM.h>
#include "EDL.h"

volatile unsigned long count = 0;
volatile unsigned long pps_start_us = 0;
volatile unsigned long pps_tick_us = 1000000;  // filtered
volatile unsigned long _pps_tick_us = 1000000; // unfiltered

volatile unsigned long rtc_start_us;          
volatile unsigned long rtc_tick_us = 1000000;  // filtered
volatile unsigned long _rtc_tick_us = 1000000; // unfiltered

// drift = actual_us - desired_us
// drift > 0 ==> pulse is late
// drift < 0 ==> pulse is early
volatile          long rtc_drift_us;          // Filtered


volatile boolean pps_led_state = true;
volatile boolean sqw_led_state = true;
volatile boolean synced = false;
const int SQW_PIN = 2;
const int PPS_PIN = 3;
const int  PPS_LED = 13;
const int SYNC_LED = 12;
const int  SQW_LED = 11;
const unsigned long  RTC_WRITE_US = 1064;
const uint8_t LAST_UPDATE_DID = 1;

TinyGPS gps;
NewSoftSerial sws(5, 4);

void pps_interrupt(){
  unsigned long  now_us = micros();
  _pps_tick_us = (now_us - pps_start_us);
  if(_pps_tick_us < pps_tick_us / 2 || _pps_tick_us > 3 * pps_tick_us / 2){
    // _pps_tick_us = rtc_tick_us;
  }
  if(pps_led_state){
    pps_led_state = false;
  }
  else{
    pps_led_state = true;
  }
  digitalWrite(PPS_LED, pps_led_state);
  digitalWrite(SQW_LED, sqw_led_state);
  if(now_us > 2e6){
    if(abs(((1000 * _pps_tick_us) / pps_tick_us) - 1000) < 10){
      // pps_tick_us = (2 * pps_tick_us + _pps_tick_us) / 3;
    }
  }
  pps_start_us = now_us;
}

void rtc_interrupt(){
  unsigned long  now_us = micros();
  long drift_us;

  if(sqw_led_state){
    sqw_led_state = false;
  }
  else{
    sqw_led_state = true;
  }
  digitalWrite(PPS_LED, pps_led_state);
  digitalWrite(SQW_LED, sqw_led_state);
  // actual - desired
  drift_us = (now_us - pps_start_us) % pps_tick_us;

  rtc_drift_us = (2 * rtc_drift_us + drift_us) / 3;
  rtc_drift_us = drift_us;
  rtc_start_us = now_us;
}

bool save_last_sync_time(time_t t){
  uint8_t len = 14;

  char dat[len];
  dat[0] = LAST_UPDATE_DID;
  dat[1] = len;
  Time_to_Serial(t, dat + 2);
  ulong_to_Serial(pps_tick_us, dat + 6); 
  ulong_to_Serial(rtc_tick_us, dat + 10);

#ifdef NOTDEF
  char dat2[len];
  Serial.println(Serial_to_time(dat + 2));
  Serial.println(Serial_to_ulong(dat + 6));
  Serial.println(Serial_to_ulong(dat + 10));
  did_write(dat);
  Serial.println(did_read(LAST_UPDATE_DID, dat2, &len));  
  Serial.print("len:");
  Serial.print(dat2[1], DEC);
  Serial.println(len, DEC);
  Serial.println(t);
  Serial.println(Serial_to_time(dat2 + 2));
  Serial.println(Serial_to_ulong(dat2 + 6));
  Serial.println(Serial_to_ulong(dat2 + 10));
  // while(1); delay(100);
#endif
  return did_write(dat);
}

bool restore_last_sync_time(){
  bool out;
  uint8_t len = 14;
  char dat2[len];

  LAST_UPDATE_DID;
  out = did_read(LAST_UPDATE_DID, dat2, &len);
#ifdef NOTDEF
  Serial.print("len:");
  Serial.print(dat2[1], DEC);
  Serial.println(len, DEC);
  Serial.println(Serial_to_time(dat2 + 2));
  Serial.println(Serial_to_ulong(dat2 + 6));
  Serial.println(Serial_to_ulong(dat2 + 10));
#endif
  //pps_tick_us = Serial_to_ulong(dat2 + 6);
  //rtc_tick_us = Serial_to_ulong(dat2 + 10);
  return out;
}

// write 4 bytes of in into char buffer out.
void Time_to_Serial(time_t in, char *out){
  time_t *out_p = (time_t *)out;
  *out_p = in;
}

time_t Serial_to_time(char *in){
  time_t out;
  out = *(time_t *)in;
  return out;
}

// write 4 bytes of in into char buffer out.
void ulong_to_Serial(unsigned long in, char *out){
  unsigned long *out_p = (unsigned long *)out;
  *out_p = in;
}
unsigned long Serial_to_ulong(char *in){
  unsigned long out;
  out = *(unsigned long *)in;
  return out;
}

void setup(){
  gps.add_callback(grab_datetime);
  if(!did_check_eeprom()){
    did_format_eeprom();
  }

  Serial.begin(115200);
  // sws.begin(9600);
  
  Wire.begin();
  pinMode(PPS_LED, OUTPUT);
  pinMode(SYNC_LED, OUTPUT);
  pinMode(SQW_LED, OUTPUT);

  pinMode(PPS_PIN, INPUT);
  pinMode(SQW_PIN, INPUT);

  digitalWrite(SYNC_LED, HIGH);
  digitalWrite(PPS_LED, HIGH);
  digitalWrite(SQW_LED, HIGH);

  delay(100);
  digitalWrite(PPS_LED, LOW);
  digitalWrite(SQW_LED, LOW);
  
  //while(digitalRead(PPS_PIN) == LOW){
  //}
  // setRTC(2011, 1, 1, 0, 0, 0);  
  //// time RTC write opration: 1064 uS ~ 1mS
  // unsigned long now_us = micros();
  restore_last_sync_time();
  wait_for_next_rtc_second();
  setTime(getTime());

  sync_time_with_gps();

  Serial.println(now());
  attachInterrupt(1, pps_interrupt, RISING);
}

void wait_for_next_rtc_second(){
  while(digitalRead(SQW_PIN) == LOW){}
  while(digitalRead(SQW_PIN) == HIGH){}
}
void wait_for_next_gps_second(){
  while(digitalRead(PPS_PIN) == HIGH){}
  while(digitalRead(PPS_PIN) == LOW){}
}

void grab_datetime(unsigned long date, 
		   unsigned long time,
		   long lat,
		   long lon,
		   long alt,
		   unsigned long speed,
		   unsigned long course){
  Serial.print(date);
  Serial.print(",");
  Serial.print(time);
  Serial.println();
}

void sync_time_with_gps(){
  // set time to within a second
  unsigned long age;
  unsigned long start_ms;
  bool newdata;
  int Year = 1999;
  byte Month, Day, Hour, Minute, Second, hundredths;

  while(1){ // start test loop
  // wait for start of second
  wait_for_next_gps_second();
  start_ms = millis();

  sws.begin(9600);
  bool done = false;
  age = 1001;
  Serial.println("Waiting for GPS...");
  bool clock_set = false;

  while(Year < 2011){
    age = millis();
    newdata = false;
    while (millis() - age < 5000){
      if(feedgps()){
	newdata = true;
      }
    }
  }
  unsigned long now_ms = millis();
  unsigned long sec_frac_ms = (now_ms - start_ms) % 1000;
  Serial.print("sec_frac_ms:");
  Serial.println(sec_frac_ms);
    
  sws.end();
  int millisec = millisecond();
  int sec = second();
  wait_for_next_gps_second();
  Serial.println("Pre setting");
  Serial.print(Year);
  Serial.print("/");
  Serial.print(Month, DEC);
  Serial.print("/");
  Serial.print(Day, DEC);
  Serial.print(" ");
  Serial.print(Hour, DEC);
  Serial.print(":");
  Serial.print(Minute, DEC);
  Serial.print(":");
  Serial.print(Second, DEC);
  
  Serial.print(" rtc second:");
  Serial.print(sec, DEC);
  Serial.print(" ");
  Serial.print(millisec, DEC);
  Serial.print(" ");
  Serial.print(sec - Second, DEC);
  Serial.println("...");
  if(!clock_set){
    wait_for_next_gps_second();
    // setRTC(Year - 30, Month, Day, Hour, Minute, Second);
    delay(10);
    set_1Hz_ref(getTime(), SQW_PIN, rtc_interrupt, FALLING); 

    Serial.println("RTC synced with GPS");
    clock_set = true;
  }
  wait_for_next_gps_second();
  millisec = millisecond();
  sec = second();
  Serial.println("post setting");
  Serial.print(Year);
  Serial.print("/");
  Serial.print(Month, DEC);
  Serial.print("/");
  Serial.print(Day, DEC);
  Serial.print(" ");
  Serial.print(Hour, DEC);
  Serial.print(":");
  Serial.print(Minute, DEC);
  Serial.print(":");
  Serial.print(Second + 1, DEC);
  
  Serial.print(" rtc second:");
  Serial.print(sec, DEC);
  Serial.print(" ");
  Serial.print(millisec, DEC);
  Serial.print(" ");
  Serial.print(sec - Second - 1, DEC);
  Serial.println("...");
  wait_for_next_gps_second();
  for(int ii = 0; ii < 15; ii++){
    bool pins[2];
    pins[0] = digitalRead(SQW_PIN);
    pins[1] = digitalRead(PPS_PIN);
    millisec = millisecond();
    sec = second();

    Serial.print(pins[0]);   
    Serial.print(pins[1]);   
    Serial.print(" ");    
    Serial.print(sec);    
    Serial.print(" ");    
    Serial.print(millisec);    
    Serial.println("");
    delay(99);
  }
  Year = 1999;} // end test loop
  digitalWrite(SYNC_LED, LOW);
}
void loop(){
  long d;
  time_t next_time;


  unsigned long now_us = micros();

  if((millis() > 5000) &&                              // everything is stable
     (pps_start_us > 0) &&                             // pps is active
     (rtc_start_us > 0) &&                             // rtc is active
     abs(rtc_drift_us - 500000) > 1000 &&              // rtc has drifted
     (now_us - pps_start_us < 3 * pps_tick_us / 2)     // pps is current
     ){
    // Serial.println("not synced");
    long sleep_us;

    // expected = pps_start_us + pps_tick_us / 2
    next_time = now();
    sleep_us = (((long)pps_start_us + (long)pps_tick_us) - (long)micros());
    if((1000 < sleep_us) && (sleep_us < pps_tick_us)){
      //while(digitalRead(PPS_PIN) == LOW){
      // }
      delay(sleep_us/1000 - 1);
      setRTC(next_time);
      save_last_sync_time(next_time);
      Serial.print("pps_tick_us:");
      Serial.println(pps_tick_us);
      Serial.print("sleep_ms:");
      Serial.println(sleep_us / 1000 - 1);
    }
  }
  if(now_us > 2e6){
    Serial.print("G ");
    Serial.print(pps_start_us);
    Serial.print(" ");
    Serial.print(pps_tick_us);
    Serial.print(" ");
    Serial.println(_pps_tick_us);
    Serial.print("R ");
    Serial.print(rtc_start_us);
    Serial.print(" ");
    Serial.print(rtc_tick_us);
    Serial.print(" ");
    Serial.println(_rtc_tick_us);
    Serial.print("D ");
    Serial.print(now_us);
    Serial.print(" ");
    Serial.println(rtc_drift_us - 500000);
    Serial.print("Race Time ");
    printFloat(second() + (float)millisecond()/1000., 3);
    Serial.println("");
    Serial.println(year());
    Serial.print(pps_start_us > 0);
    Serial.print(rtc_start_us > 0);
    Serial.print(abs(rtc_drift_us - 500000) < 1000);
    Serial.println(now_us - pps_start_us < 3 * pps_tick_us / 2);    // pps is current);

    Serial.print(year());
    Serial.print("/");
    Serial.print(month(), DEC);
    Serial.print("/");
    Serial.print(day(), DEC);
    Serial.print(" ");
    Serial.print(hour(), DEC);
    Serial.print(":");
    Serial.print(minute(), DEC);
    Serial.print(":");
    Serial.print(second(), DEC);
    Serial.println("");
    
    synced = rtc_drift_us - 500000 < 1000;
    digitalWrite(SYNC_LED, !(synced));
    delay(5000);
  }
  if(now_us > 30e6){
    Serial.println("Resyncing");
    sync_time_with_gps();
  }
}

void do_nothing(){
}
bool feedgps()
{
  while (sws.available())
  {
    if (gps.encode(sws.read()))
      return true;
  }
  return false;
}

void printFloat(double number, int digits)
{
  // Handle negative numbers
  if (number < 0.0)
  {
     Serial.print('-');
     number = -number;
  }

  // Round correctly so that print(1.999, 2) prints as "2.00"
  double rounding = 0.5;
  for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
  
  number += rounding;

  // Extract the integer part of the number and print it
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;
  Serial.print(int_part);

  // Print the decimal point, but only if there are digits beyond
  if (digits > 0)
    Serial.print("."); 

  // Extract digits from the remainder one at a time
  while (digits-- > 0)
  {
    remainder *= 10.0;
    int toPrint = int(remainder);
    Serial.print(toPrint);
    remainder -= toPrint; 
  } 
}
