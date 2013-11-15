#include <avr/pgmspace.h>

const uint8_t N_CHAR = 128;
class Font{
 public:
  /*
    Place character into output buffer out in selected color.
   */
  void getChar(char letter, uint8_t color, uint32_t* out);

  /*
    Prepare memory to scoll a phase typesetting each letter to aviod
    wasted white space.  
    Return length of output phase (number of uint32_t memory locations used).
  
    output buffer "out" should be at least 8 * strlen(word);
  */
  uint8_t typesetWord(char *phase, uint8_t color, uint32_t* out);
 private:
};
