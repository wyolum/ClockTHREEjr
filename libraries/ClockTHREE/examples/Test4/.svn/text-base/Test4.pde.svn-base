/*
  ClockTHREE Test4 Diag Test.
  Draw a some lines

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
#include "rtcBOB.h"

ClockTHREE c3 = ClockTHREE();
uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));

void setup(){
  int xpos, ypos;

  c3.init();
  delay(100);
  c3.setdisplay(display);
  c3.set_column_hold(10);
}
uint32_t count = 0;
boolean dbg = true;
double x0 = 0, y0 = 0, x1 = 8, y1 = 10;
double vx0 = .4, vy0 = .15, vx1 = -.4, vy1 = -.3;
uint8_t color_i = 1;
int hold = 200;

void loop(){
  // c3.line(x0, y0, x1, y1, DARK);
  // c3.displayfill(DARK);
  x0 += vx0;
  if(x0 >= N_COL){
    color_i++;
    color_i %= N_COLOR;
    x0 = N_COL - 1;
    vx0 *= -1;
  }
  if(x0 < 0){
    color_i++;
    color_i %= N_COLOR;
    x0 = 0;
    vx0 *= -1;
  }

  if(x1 >= N_COL){
    color_i++;
    color_i %= N_COLOR;
    x1 = N_COL - 1;
    vx1 *= -1;
  }
  if(x1 < 0){
    color_i++;
    color_i %= N_COLOR;
    x1 = 0;
    vx1 *= -1;
  }
  if(y0 >= N_RGB_ROW){
    if((COLORS[color_i] == BLUE) || (COLORS[color_i] == DARK)){
      if(y0 > N_ROW){
	color_i++;
	color_i %= N_COLOR;
	y0 = N_ROW - 1;
	vy0 *= -1;
      }
    }
    else{
      color_i++;
      color_i %= N_COLOR;
      y0 = N_RGB_ROW - 1;
      vy0 *= -1;
    }
  }
  if(y0 < 0){
    color_i++;
    color_i %= N_COLOR;
    y0 = 0;
    vy0 *= -1;
  }

  if(y1 >= N_RGB_ROW){
    if((COLORS[color_i] == BLUE) || (COLORS[color_i] == DARK)){
      if(y1 > N_ROW){
	color_i++;
	color_i %= N_COLOR;
	y1 = N_ROW - 1;
	vy1 *= -1;
      }
    }
    else{
      color_i++;
      color_i %= N_COLOR;
      y1 = N_RGB_ROW - 1;
      vy1 *= -1;
    }
  }
  if(y1 < 0){
    color_i++;
    color_i %= N_COLOR;
    y1 = 0;
    vy1 *= -1;
  }
  x0 += vx0;
  y0 += vy0;
  x1 += vx1;
  y1 += vy1;
  if(true){
    c3.displayfill(DARK);
    c3.line(x0, y0, x1, y1, WHITE);
  }
  else{
    hold = 100;
    c3.set_column_hold(25);
    c3.line(x0, y0, x1, y1, COLORS[color_i]);
  }
  c3.refresh(hold);
  count++;
}
