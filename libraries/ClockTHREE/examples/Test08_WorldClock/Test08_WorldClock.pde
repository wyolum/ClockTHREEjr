/*
  ClockTHREE Test5
  Draw a circle and an ellipse

  Justin Shaw Nov 28, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
 */

#include "ClockTHREE.h"
#include "SPI.h"
#include "Wire.h"
#include "Time.h"
#include "EEPROM.h"
#include "MsTimer2.h"
#include "rtcBOB.h"

const uint8_t N_DISPLAY = 8;
ClockTHREE c3 = ClockTHREE();
uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));

void setup(){

  display[0]  = 0b00011111111111111111111111111011;
  display[1]  = 0b00011111111111111111111111111011;
  display[2]  = 0b00011111111111111111111111111011;
  display[3]  = 0b00011111011011011011011011011000;
  display[4]  = 0b00011011000000000000000000000000;
  display[5]  = 0b00011000000000000000000000000000;
  display[6]  = 0b00000000000000000000000000000000;
  display[7]  = 0b00000000000000000000000000000000;
  display[8]  = 0b00000000000000000000000000000000;
  display[9]  = 0b00000000000000000000000000000000;
  display[10] = 0b00000000000000000000000000000000;
  display[11] = 0b00011000000000000000000000000000;
  display[12] = 0b00011011011011011011011011011000;
  display[13] = 0b00011111111111111111111111011000;
  display[14] = 0b00011111111111111111111111111011;
  display[15] = 0b00011111111111111111111111111011;

  display[0]  = 0b00001111111111111111111111111001;
  display[1]  = 0b00001111111111111111111111111001;
  display[2]  = 0b00001111111111111111111111111001;
  display[3]  = 0b00001111001001001001001001001000;
  display[4]  = 0b00001001000000000000000000000000;
  display[5]  = 0b00001000000000000000000000000000;
  display[6]  = 0b00000000000000000000000000000000;
  display[7]  = 0b00000000000000000000000000000000;
  display[8]  = 0b00000000000000000000000000000000;
  display[9]  = 0b00000000000000000000000000000000;
  display[10] = 0b00001000000000000000000000000000;
  display[11] = 0b00001001000000000000000000000000;
  display[12] = 0b00001111001001001001001001001000;
  display[13] = 0b00001111111111111111111111001000;
  display[14] = 0b00001111111111111111111111111001;
  display[15] = 0b00001111111111111111111111111001;

  c3.init();
  c3.setdisplay(display);
  c3.set_column_hold(1);
}
uint32_t count = 0;
boolean dbg = true;
uint8_t color_i = 0;
const int hold = 50;
void loop(){
  uint32_t tmp[N_COL];
  for(int i = 0; i < N_COL - 1; i++){
    tmp[i] = display[i + 1]; 
  }
  tmp[N_COL - 1] = display[0];
  c3.fadeto(tmp, 100);
  for(int i=0; i < N_COL - 1; i++){
    display[i] = tmp[i + 1];
  }

  display[N_COL - 1] = tmp[0];
  c3.fadeto(display, 100);
  count++;
}
