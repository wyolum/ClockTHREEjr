/*
  C3JR_Driver.cpp -- I2C <--> C3jr interface.

  Justin Shaw
  
  LIBRARY VERSION: 0.01, DATED 5/17/2011

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
#include "C3JR_Driver.h"
#include "C3JR_Slave.h"

C3JR_Driver::C3JR_Driver(){
}
void C3JR_Driver::init(uint8_t _addr){
  addr = _addr;
}
void C3JR_Driver::set_display(uint32_t *display){
  uint8_t display8[N_COL];
  for(uint8_t i = 0; i < N_COL; i++){
    display8[i] = (uint8_t)display[i];
  }
  send_msg(C3JR_SET_MSG, 16, display8);
}
void C3JR_Driver::scroll_left(uint8_t new_col){
  send_msg(C3JR_SCROLL_LEFT_MSG, 1, &new_col);
}
void C3JR_Driver::set_pixel(uint8_t col, uint8_t row, bool val){
  uint8_t pix[1];
  pix[0] = (val << 7) | (row << 4) | (col << 0);
  send_msg(C3JR_SET_PIXEL_MSG, 1, pix);
}
void C3JR_Driver::set_char(char c){
  uint8_t* dat = (uint8_t*)&c;
  send_msg(C3JR_SET_CHAR_MSG, 1, dat);
}
void C3JR_Driver::scroll_char_v(char c){
  uint8_t* dat = (uint8_t*)&c;
  send_msg(C3JR_SCROLL_CHAR_V_MSG, 1, dat);
}
void C3JR_Driver::scroll_char_h(char c){
  uint8_t* dat = (uint8_t*)&c;
  send_msg(C3JR_SCROLL_CHAR_H_MSG, 1, dat);
}
void C3JR_Driver::clear(){
  send_msg(C3JR_CLEAR_MSG, 0, NULL);
}
void C3JR_Driver::scroll_v(uint8_t n_row){
  send_msg(C3JR_SCROLL_V_MSG, 1, &n_row);
}
void C3JR_Driver::display_id(){
  send_msg(C3JR_DISPLAY_ID_MSG, 0, NULL);
}
void C3JR_Driver::fadeto(uint32_t *display, uint8_t steps){
  uint8_t display8[N_COL + 1];
  display8[0] = steps;
  for(uint8_t i = 0; i < N_COL; i++){
    display8[i + 1] = (uint8_t)display[i];
  }
  send_msg(C3JR_FADETO_MSG, N_COL + 1, display8);
}
void C3JR_Driver::fadeto(uint8_t *display, uint8_t steps){
  uint8_t display8[N_COL + 1];
  display8[0] = steps;
  for(uint8_t i = 0; i < N_COL; i++){
    display8[i + 1] = display[i];
  }
  send_msg(C3JR_FADETO_MSG, N_COL + 1, display8);
}
void C3JR_Driver::send_msg(uint8_t msg_id, uint8_t msg_len, uint8_t *msg){
  Wire.beginTransmission(addr);
  Wire.write(msg_id);
  for(uint8_t i = 0; i < msg_len && i < 31; i++){
    Wire.write(msg[i]);
  }
  Wire.endTransmission();
}

