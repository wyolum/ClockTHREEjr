/*
  Peggy2_Slave.cpp -- I2C <--> C3jr interface.

  Justin Shaw
  
  LIBRARY VERSION: 0.01, DATED 11/9/2011

Licenced under Creative Commons Attribution.
Attribution 3.0 Unported
This license is acceptable for Free Cultural Works.
You are free:

    * to Share — to copy, distribute and transmit the work
    * to Remix — to adapt the work

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
#include "Peggy2_Slave.h"

Peggy2_Slave* peggy2_p;

union data{
  uint8_t bytes[4];
  uint16_t uint16_vals[2];
  int int_val;
  float float_val;
} p2_type_converter;
  
Peggy2_Slave::Peggy2_Slave(){
  
}

uint8_t Peggy2_Slave::getAddr(){
  uint8_t addr = PEGGY2_BASE_ADDR;
  return addr;
}

boolean Peggy2_Slave::init(){

  pinMode(PEGGY2_EMSL_PIN, OUTPUT);
  peggy2_p = this;
  Wire.onReceive(Peggy2_Slave_onReceive);
  Wire.onRequest(Peggy2_Slave_onRequest);
  c3.init();
  c3.setdisplay(cols);
  font = MemFont();
}

void Peggy2_Slave::err_out(uint8_t err_no){
  // display error code indication
}


// Slave event handler
void Peggy2_Slave_onRequest(){
  uint8_t i;
  WIRE_WRITE((uint8_t*)peggy2_p->cols, PEGGY2_N_COL);
}

// Slave event handler
void Peggy2_Slave_onReceive(int n_byte){
  uint8_t msg_type = WIRE_READ;
  uint8_t i;

  if(msg_type == PEGGY2_SET_MSG){
    // PEGGY2 is to large to set with single msg. IGNORE, use SET_ROW
  }
  else if(msg_type == PEGGY2_SET_ROW_MSG){
    uint8_t row_index, tmp;
    uint32_t row = 0;
    row_index = WIRE_READ;
    for(i = 0; Wire.available() && i < 4; i++){
      tmp = WIRE_READ;
      row |= ((uint32_t)tmp) << (8 * i);
    }
    peggy2_p->cols[row_index] = row; // setcol(row_index, row); // Peggy2 has rows and columns swapped.
    // peggy2_p->c3.setPixel(5, row_index, row & 1);
  }
  else if (msg_type == PEGGY2_SCROLL_V_MSG){
    // TBD
  }
  else if (msg_type == PEGGY2_SCROLL_LEFT_MSG){
    // TBD
  }
  else if (msg_type == PEGGY2_SET_PIXEL_MSG){
    // first byte -- row (MSB is on/off state)
    // second byte -- col
    // examples
    // 0b00000000 0b00000000 -- turns row 0, col 0 off
    // 0b10000000 0b00000000-- turns row 0, col 0 on
    // 0b00000000 0b00000001 -- turns row 0, col 1 off
    // 0b10000000 0b00000001 -- turns row 0, col 1 on
    // 0b10000001 0b00000001 -- turns row 1, col 1 on
    uint8_t led_num, row, col;
    boolean state;
    while(Wire.available() > 1){ // use provided led number
      row = WIRE_READ;
      col = WIRE_READ;
      state = (row & 0b10000000) == 128;
      row = (row & 0b01111111);

      peggy2_p->c3.setPixel(col, row, state);
    }
  }
  else if (msg_type == PEGGY2_SET_EMSL_PWM_MSG){
    uint8_t pwm = 15;     // default pwm
    if(Wire.available()){  
      pwm = WIRE_READ;    // use provided pwm
    }
    // analogWrite(PEGGY2_EMSL_PIN, pwm);
  }
  else if (msg_type == PEGGY2_SET_CHAR_MSG){
    // TBD
  }
  else if(msg_type == PEGGY2_SCROLL_CHAR_V_MSG){
    // TBD
  }
  else if(msg_type == PEGGY2_SCROLL_CHAR_H_MSG){
    // TBD
  }
  else if(msg_type == PEGGY2_CLEAR_MSG){
    peggy2_p->c3.clear();
  }
  else if(msg_type == PEGGY2_DISPLAY_ID_MSG){
    // TBD
  }
  else{
  }
}

