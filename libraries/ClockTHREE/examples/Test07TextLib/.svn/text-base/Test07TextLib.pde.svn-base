/*
  ClockTHREE Test7 Text
  scroll some text using font library

  Justin Shaw Dec 9, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0
 */

#include "ClockTHREE.h"
#include "SPI.h"
#include "Wire.h"
#include "Time.h"
#include "EEPROM.h"
#include "rtcBOB.h"
#include "MsTimer2.h"
#include <avr/pgmspace.h>
#include "font.h"

ClockTHREE c3 = ClockTHREE();
Font font = Font();
uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));

void setup(){
  c3.init();
  c3.setdisplay(display);
  c3.set_column_hold(20);
  for(int i = 0; i < N_COL; i++){
    display[i] = 0;
  }
}

uint32_t count = 0;
uint8_t color_i = 0;
const int display_hold = 200;
int myx = 0;
uint32_t next_char[8];

char msg[] = "Thank you ClockTHREE Backers!!!!!    ";
void loop(){
  uint8_t c;
  int n = strlen(msg);

  if(count % 8 == 0){
    font.getChar(msg[(count / 8) % n], GREENBLUE, display + N_COL);
  }
  for(int i = 0; i < N_COL + 7; i++){
    // make room for new column
    display[i] = display[i + 1];
  }
  count++;
  c3.refresh(display_hold);
}
