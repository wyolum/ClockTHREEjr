/*
  Initial ClockTHREE Word Clock App (no frills or modes adjustment or 
  interaction)
  Display time 12:12 PM in words using english template

  Justin Shaw Dec 22, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0
 */

#include <avr/pgmspace.h>
#include <Wire.h>
#include <Time.h>
#include "EEPROM.h"
#include "MsTimer2.h"
#include "ClockTHREE.h"
#include "SPI.h"
#include "english.h"
#include "rtcBOB.h"

// globals
ClockTHREE c3 = ClockTHREE();
English lang = English();

uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));
time_t t;

void setup(){
  c3.init();
  Wire.begin();
  c3.setdisplay(display);
  c3.set_column_hold(50);

  setSyncProvider(getTime);      // RTC
  setSyncInterval(3600000);      // update hour (and on boot)

}

uint32_t count = 0;
uint8_t color_i = 2;
const int display_hold = 500;

void loop(){
  // digitalWrite(SPEAKER_PIN, HIGH);
  lang.display_time(year(),
		    month(),
		    day(),
		    hour(),
		    minute(),
		    second(),
		    c3, COLORS[color_i], 32);
    c3.refresh(100);
}
