/*
  Display time HH:MM:SS on THREE clockTHREE_jrs

  Slave Version See RaceClockMaster.pde as well

  Justin Shaw Dec 22, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0

*/

#include <avr/pgmspace.h>
#include <Wire.h>
#include "SPI.h"
#include "Time.h"
#include "MsTimer2.h"
#include "ClockTHREE.h"
#include "C3JR_Slave.h"

#include "mem_font.h"
#include "rtcBOB.h"

// const uint16_t BAUDRATE = 57600; // official:57600 (Scott Schenker 38400)

const uint8_t ADDR[] = {8, 3, 15, 2};

C3JR_Slave c3jr = C3JR_Slave();

void setup(){
  Serial.begin(BAUDRATE);
  
  Serial.println("ClockTHREEJr Slave");
  Serial.println("Copyright WyoLum, LLC, 2012");
  Serial.print("I2C Address:");
  uint8_t addr = c3jr.getAddr();
  Serial.println(addr, DEC);
  c3jr.init();
  c3jr.c3.clear();
  Wire.begin(addr);
}
void loop(){
  check_stack();
  if(c3jr.fade_steps > 0){
    c3jr.c3.fadeto(c3jr.cols + N_COL, c3jr.fade_steps);
    c3jr.fade_steps = 0;
    for(uint8_t i=0; i < N_COL; i++){
      c3jr.cols[i] = c3jr.cols[N_COL + i];
    }
    c3jr.c3.setdisplay(c3jr.cols);
  }
  c3jr.c3.refresh(16);
}
