/*
  C3JR_Slave.h -- I2C <--> C3jr interface. 

  Justin Shaw
  LIBRARY DATED 11/9/2011

Licenced under Creative Commons Attribution.
Attribution 3.0 Unported
This license is acceptable for Free Cultural Works.
You are free:

    * to Share — to copy, distribute and transmit the work
    * to Remix — to adapt the work
    *

Under the following conditions:

    *

      Attribution — You must attribute the work in the manner specified by 
the author or licensor (but not in any way that suggests that they endorse
you or your use of the work).

      Attribute this work:
      Information
      What does "Attribute this work" mean?
      The page you came from contained embedded licensing metadata, including
how the creator wishes to be attributed for re-use. You can use the HTML here 
to cite the work. Doing so will also include metadata on your page so that 
others can find the original work as well.

With the understanding that:
    * Waiver — Any of the above conditions can be waived if you get permission 
      from the copyright holder.
    * Public Domain — Where the work or any of its elements is in the public 
      domain under applicable law, that status is in no way affected by the 
      license.
    * Other Rights — In no way are any of the following rights affected by the
      license:
          o Your fair dealing or fair use rights, or other applicable copyright
	    exceptions and limitations;
          o The author's moral rights;
          o Rights other persons may have either in the work itself or in how 
            the work is used, such as publicity or privacy rights.
    * Notice — For any reuse or distribution, you must make clear to others 
     the license terms of this work. The best way to do this is with a link 
     to this web page.
*/
#ifndef PEGGY2_Slave_H
#define PEGGY2_Slave_H

#include <inttypes.h>
#include "ClockTHREE.h"
#include "Wire.h"
#include "mem_font.h"

const uint8_t PEGGY2_BASE_ADDR = 4; // MADE UP NUMBER
const uint8_t PEGGY2_N_COL = 25; 
const uint8_t PEGGY2_SET_MSG = 1;
const uint8_t PEGGY2_SCROLL_LEFT_MSG = 2;
const uint8_t PEGGY2_SET_PIXEL_MSG = 3;
const uint8_t PEGGY2_SET_CHAR_MSG = 4;
const uint8_t PEGGY2_SCROLL_CHAR_V_MSG = 5;
const uint8_t PEGGY2_SCROLL_CHAR_H_MSG = 6;
const uint8_t PEGGY2_CLEAR_MSG = 7;
const uint8_t PEGGY2_SCROLL_V_MSG = 8;
const uint8_t PEGGY2_DISPLAY_ID_MSG = 9;
const uint8_t PEGGY2_TONE_MSG = 10;
const uint8_t PEGGY2_SET_ROW_MSG = 11;
const uint8_t PEGGY2_SET_EMSL_PWM_MSG = 12;

const uint8_t PEGGY2_EMSL_PIN = 10;



class Peggy2_Slave{
 public:
  Peggy2_Slave();

  uint32_t cols[PEGGY2_N_COL];
  uint8_t next_pong;
  ClockTHREE c3;
  MemFont font;
  
  boolean init();
  void err_out(uint8_t err_no);
  void setDBG_LED(boolean state);
  uint8_t getAddr();
  
 private:
};
void Peggy2_Slave_onRequest();
void Peggy2_Slave_onReceive(int n_byte);
#endif
