/*
  ClockTHREE XMas Tree display

  Justin Shaw Dec 19, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
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

ClockTHREE c3 = ClockTHREE();
uint32_t *old_display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));
uint32_t *new_display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));

void xmastree(){
  int row, col;
  // make the tree
  c3.displayfill(DARK);
  for(int col=6; col < 15; col++){
    for(int row=5 - (col - 6)/2; row <= 5 + (col - 6)/2; row++){
      c3.setPixel(col, row, GREEN);
    }
  }
  
  // decorate it
  c3.setPixel(6, 5, WHITE);
  c3.setPixel(9, 4, REDBLUE);
  c3.setPixel(10, 7, BLUE);
  c3.setPixel(11, 5, GREENBLUE);
  c3.setPixel(12, 2, RED);
  c3.setPixel(13, 4, WHITE);
  c3.setPixel(13, 7, REDBLUE);
  c3.setPixel(14, 1, REDBLUE);
  c3.setPixel(14, 9, RED);

}

const int N_FLAKE = 20;
int flake_xs[N_FLAKE];
int flake_ys[N_FLAKE];

void setup(){
  c3.init();
  c3.setdisplay(old_display);
  c3.set_column_hold(30);
  c3.displayfill(DARK);
  xmastree();
  
  for(int i = 0; i < N_FLAKE; i++){
    flake_xs[i] = random(-N_COL, N_COL);
    flake_ys[i] = random(0, 10);
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
      flake_xs[i] = -N_COL;
      flake_ys[i] = random(0, 10);
    }
    c3.setPixel(flake_xs[i], flake_ys[i], WHITE);
  }
  c3.refresh(hold);
  count++;
}

