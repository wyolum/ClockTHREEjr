/*
  ClockTHREE Test2 -- Color Test
  Justin Shaw Nov 28, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
 */

#include "ClockTHREE.h"
#include "SPI.h"
#include "Wire.h"
#include "Time.h"
#include "rtcBOB.h"
#include "EEPROM.h"
#include "MsTimer2.h"

#define CLOCKTWO // comment this line out for C3 hardware

ClockTHREE c3 = ClockTHREE();
uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));
void setup(){
  Serial.begin(57600);
  Serial.println("setup()");
  c3.init();
  c3.setdisplay(display);
  c3.displayfill(RED);
  Serial.println("end setup()");
}
uint32_t count = 4000;
boolean dbg = true;
const int hold = 500;
void loop(){
  uint8_t color_i;
  
  if(count % hold == 0){
    Serial.println("HERE0");
    color_i = count / hold;
    Serial.println("HERE1");
    // color_i %=  N_COLOR;
    color_i %=  8;
    Serial.print(count, DEC);
    Serial.println(" ");
    Serial.println(color_i, DEC);
    c3.displayfill(COLORS[color_i]);
    Serial.println("HERE3");
    if(color_i % 2){
      c3.displayfill(WHITE);
    }
    else{
      c3.displayfill(DARK);
    }
    Serial.println("HERE4");
    dbg = !dbg;
    Serial.println("HERE5");
    digitalWrite(DBG, dbg);
    Serial.println("THERE");
  }
  
  c3.refresh();
  count++;
}
