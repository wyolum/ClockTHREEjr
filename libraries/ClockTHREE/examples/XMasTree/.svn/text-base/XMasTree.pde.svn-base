/*
  ClockTHREE XMas Tree display

  Justin Shaw Dec 19, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
 */

#include "ClockTHREE.h"
#include "SPI.h"
#include "EEPROM.h"
#include "MsTimer2.h"
#include "Time.h"
#include "Wire.h"
#include "rtcBOB.h"

ClockTHREE c3 = ClockTHREE();
uint32_t *old_display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));
uint32_t *new_display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));

void xmastree(){
  int row, col;
  // clear the screen
  c3.displayfill(DARK);

  // make the tree
  for(int col=6; col < 15; col++){
    for(int row=5 - (col - 6)/2; row <= 5 + (col - 6)/2; row++){
      c3.setPixel(col-2, row, GREEN);
    }
  }
  // put snow down
  c3.line(14, 0, 14, 10, WHITE);
  c3.line(15, 0, 15, 10, WHITE);

  // decorate it
  c3.setPixel(6-2, 5, WHITE);
  c3.setPixel(9-2, 4, REDBLUE);
  c3.setPixel(10-2, 7, BLUE);
  c3.setPixel(11-2, 5, GREENBLUE);
  c3.setPixel(12-2, 2, RED);
  c3.setPixel(13-2, 4, WHITE);
  c3.setPixel(13-2, 7, REDBLUE);
  c3.setPixel(14-2, 1, REDBLUE);
  c3.setPixel(14-2, 9, RED);
  c3.setPixel(15-2, 5, RED); // stump


}

const int N_FLAKE = 15;
int flake_xs[N_FLAKE];
int flake_ys[N_FLAKE];

void setup(){
  c3.init();
  c3.setdisplay(old_display);
  c3.set_column_hold(30);
  c3.displayfill(DARK);
  xmastree();
  
  for(int i = 0; i < N_FLAKE; i++){
    flake_xs[i] = random(-1, N_COL);
    flake_ys[i] = random(0, 12);
  }
}

uint32_t count = 0;
boolean dbg = true;
int hold = 400;

void loop(){
  xmastree();
  for(int i = 0; i < N_FLAKE; i++){
    flake_xs[i]++;
    if(flake_xs[i] > 16){
      flake_xs[i] = -1;
      flake_ys[i] = random(0, 12);
    }
    c3.setPixel(flake_xs[i], flake_ys[i], WHITE);
  }
  c3.refresh(hold);
  count++;
}
