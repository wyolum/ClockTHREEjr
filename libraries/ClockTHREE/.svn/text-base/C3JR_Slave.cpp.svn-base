/*
  C3JR_Slave.cpp -- I2C <--> C3jr interface.

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
#include "C3JR_Slave.h"

C3JR_Slave* c3jr_p;

union data{
  uint8_t bytes[4];
  uint16_t uint16_vals[2];
  int int_val;
  float float_val;
} type_converter;
  
C3JR_Slave::C3JR_Slave(){
  
}

uint8_t C3JR_Slave::getAddr(){
  uint8_t addr = C3JR_BASE_ADDR;
  uint8_t p = 1;

  for(int i = 0; i < 4; i++){
    addr += digitalRead(C3JR_ADDR_PINS[i]) * p;
    p *= 2;
  } 
  return addr;
}

boolean C3JR_Slave::init(){
  pinMode(C3JR_DBG_PIN, OUTPUT);
  for(int i = 0; i < 4; i++){
    pinMode(C3JR_ADDR_PINS[i], INPUT);
  }  
  c3jr_p = this;
  Wire.onReceive(C3JR_Slave_onReceive);
  Wire.onRequest(C3JR_Slave_onRequest);
  c3.init();
  c3.setdisplay(cols);
  font = MemFont();
}

void C3JR_Slave::err_out(uint8_t err_no){
  // display error code indication
}

void C3JR_Slave::setDBG_LED(boolean state){
  digitalWrite(C3JR_DBG_PIN, state);
}

// Slave event handler
void C3JR_Slave_onRequest(){
  uint8_t i;
  c3jr_p->setDBG_LED(HIGH);
  WIRE_WRITE((uint8_t*)c3jr_p->cols, C3JR_N_COL);
  c3jr_p->setDBG_LED(LOW);
}

int8_t v_stack_counts[16];
uint32_t buffer_stack[16];

// Slave event handler
void C3JR_Slave_onReceive(int n_byte){
  uint8_t msg_type = WIRE_READ;
  uint8_t i;
  c3jr_p->setDBG_LED(HIGH);
  // Serial.print("Msg rec: ID=");
  // Serial.println(msg_type);
  if(msg_type == C3JR_SET_MSG){
    for(i = 0; Wire.available(); i++){
      c3jr_p->cols[i]= WIRE_READ;
    }
  }
  else if (msg_type == C3JR_SCROLL_V_MSG){
    uint8_t n_row = 1;
    if(Wire.available()){ // use provided column
      n_row = WIRE_READ;
    }
    for(i = 0; i < 16; i++){
      c3jr_p->cols[i] = (c3jr_p->cols[i] << n_row);
    }
  }
  else if (msg_type == C3JR_SCROLL_LEFT_MSG){
    uint8_t new_col;
    if(Wire.available()){ // use provided column
      new_col = WIRE_READ;
    }
    else{ // wrap from left
      new_col = c3jr_p->cols[0];
    }
    for(i = 0; i < C3JR_N_COL - 1; i++){
      c3jr_p->cols[i] = c3jr_p->cols[i + 1];
    }
    c3jr_p->cols[C3JR_N_COL - 1] = new_col;
  }
  else if (msg_type == C3JR_SET_PIXEL_MSG){
    // first 7 bits give LED number 
    // first 4 bits are row, next three bits are col
    // eigth bit -- on/off state
    // examples
    // 0b00000000 -- turns row 0, col 0 off
    // 0b10000000 -- turns row 0, col 0 on
    // 0b00000001 -- turns row 0, col 1 off
    // 0b10000001 -- turns row 0, col 1 on
    uint8_t led_num, row, col;
    boolean state;
    while(Wire.available()){ // use provided led number
      led_num = WIRE_READ;
      col =   (led_num & 0b00001111);
      row =   (led_num & 0b01110000) >> 4;
      state = (led_num & 0b10000000) == 128;
      c3jr_p->c3.setPixel(col, row, state);
    }
  }
  else if (msg_type == C3JR_SET_CHAR_MSG){
    uint8_t letter, pos, msg;
    pos = 0; // receive two chars, this counts 0, 1
    c3jr_p->c3.clear();
    while(Wire.available()){ // use provided led char
      msg = WIRE_READ;
      letter = (msg & 0b01111111);
      c3jr_p->font.getChar(letter, MONO, c3jr_p->c3.display + pos * 8);
      pos++;
      pos %= 2;
    }
  }
  else if(msg_type == C3JR_SCROLL_CHAR_V_MSG){
    // first bit tells position: 0 left, 1 right
    uint8_t letter, pos, msg;
    int8_t stack_pos;

    if(Wire.available()){
      msg = WIRE_READ;
      letter = (msg & 0b01111111);
      pos =    (msg & 0b10000000) >> 7;
      c3jr_p->font.getChar(letter, MONO, buffer_stack + pos * 8);
      if(Wire.available()){ // grab stack position
	stack_pos = (int8_t)WIRE_READ;
      }
      else{
	stack_pos = 9;
      }
      for(i = 0; i < 7; i++){
	v_stack_counts[i + 8 * pos] = stack_pos;
      }
    }
  }
  else if(msg_type == C3JR_SCROLL_CHAR_H_MSG){
  }
  else if(msg_type == C3JR_CLEAR_MSG){
    c3jr_p->c3.clear();
  }
  else if(msg_type == C3JR_DISPLAY_ID_MSG){
    uint8_t ones, tens, addr;
    addr = c3jr_p->getAddr();
    Serial.print("addr: ");
    Serial.println(addr);
    ones = addr % 10;
    tens = addr / 10;
    c3jr_p->font.getChar(tens + '0', MONO, c3jr_p->c3.display +  0 * 8);
    c3jr_p->font.getChar(ones + '0', MONO, c3jr_p->c3.display +  1 * 8);
  }
  else if(msg_type == C3JR_TONE_MSG){
    // data follows: 
    //     2 bytes ~ freq Hz
    //     2 bytes ~ duration
    uint16_t freq, duration_ms = 0;
    i = 0;
    while(Wire.available() && i < 4){ // grab stack position
      type_converter.bytes[i] = (int8_t)WIRE_READ;
    }
    freq = type_converter.uint16_vals[0];
    duration_ms = type_converter.uint16_vals[1];
    if(duration_ms > 0){
      c3jr_p->c3.note(freq, duration_ms);
    }
  }
  else if(msg_type == C3JR_FADETO_MSG){
    uint8_t n_step;
    if(Wire.available()){
      n_step = (int8_t)WIRE_READ;
    }
    i = 0;
    while(Wire.available() && i < N_COL){ 
      c3jr_p->cols[N_COL + i] = (int8_t)WIRE_READ; // write to aux display
      i++;
    }
    c3jr_p->fade_steps = n_step;
  }
  else{
    Serial.print("unknown message type: ");
    Serial.println(msg_type, DEC);
  }
  c3jr_p->setDBG_LED(LOW);
}

void check_stack(){
  for(int i = 0; i < 16; i++){
    if(v_stack_counts[i] > 0){ 
      v_stack_counts[i]--;
      if(v_stack_counts[i] < 9){
	c3jr_p->c3.display[i] =  (c3jr_p->c3.display[i]  << 1)  | (buffer_stack[i] >> 8);
	buffer_stack[i] <<= 1;
      }
    }
    else if(v_stack_counts[i] < 0){
      v_stack_counts[i]++;
      if(v_stack_counts[i] > -9){
	c3jr_p->c3.display[i] =  (c3jr_p->c3.display[i]  >> 1)  | (buffer_stack[i] << 8);
	buffer_stack[i] >>= 1;
      }
    }
  }
  
}
