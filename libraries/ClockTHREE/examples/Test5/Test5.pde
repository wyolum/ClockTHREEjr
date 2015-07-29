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
#include "rtcBOB.h"
#include "EEPROM.h"
#include "MsTimer2.h"

const uint8_t N_DISPLAY = 8;
ClockTHREE c3 = ClockTHREE();
uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));
uint32_t *displays = (uint32_t*)calloc(N_DISPLAY * N_COL, sizeof(uint32_t));

void bin32Print(uint32_t num){
  for(int i=31; i >= 0; i--){
    if(num >= (1LU << i)){
      Serial.print('1');
      num -= (1LU << i);
    }
    else{
      Serial.print("0");
    }
  }
  Serial.println("");
}
void printData(){
  Serial.println("");
  for(int i=0; i < N_COL; i++){
    bin32Print(display[i]);
  }
}

void setup(){
  int xpos, ypos;

  c3.init();
  // Serial.begin(9600);
  delay(100);
  for(int i = 0; i < N_DISPLAY; i++){
    c3.setdisplay(displays + i * 32);
    c3.displayfill(DARK);
    c3.circle(7.5, 5.5, (i + 1) % 9, BLUE);
    c3.circle(7.5, 5.5, (i + 2) % 9, RED);
    c3.circle(7.5, 5.5, (i + 3) % 9, GREEN);

  }
}
uint32_t count = 0;
boolean dbg = true;
uint8_t color_i = 0;
const int hold = 100;
void loop(){
  if(count % hold == 0){
    int n = (count / hold) % N_DISPLAY;
    c3.setdisplay(displays + n * 32);
  }
  c3.refresh();
  count++;
}
