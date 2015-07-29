#ifndef MEM_FONT_H
#define MEM_FONT_H

#include <avr/pgmspace.h>
const uint8_t N_CHAR = 128;
class MemFont{
 public:
  /*
    Place character into output buffer out in selected color.
   */
  void getChar(char letter, uint8_t color, uint32_t* out);
 private:
};

#endif
