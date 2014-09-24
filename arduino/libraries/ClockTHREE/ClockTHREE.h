/*
  ClockTHREE.h -- ClockTHREE RGB LED Matrix library for Arduino

  Justin Shaw
  The hardware and software for ClockTHREE have been enabled by the 
  open souce Peggy2.  Thanks to the Evil Mad Science Team for making them
  available.
  
  LIBRARY VERSION: 0.01, DATED 26/11/2010

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
#ifndef ClockTHREE_h
#define ClockTHREE_h 
#define CLOCKTHREEJR // uncomment this line for ClockTHREEjr
// #define PEGGY2 // uncomment this line for Peggy2

// Arduino 1.0 compatibility
#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#define WIRE_READ Wire.read();
#else
#include "WProgram.h"
#define WIRE_READ Wire.receive()
#endif

#include <inttypes.h>
#include "SPI.h"
#include "rtcBOB.h"
// #include "Screen.h"
#ifdef CLOCKTHREEJR
const int     N_ROW = 8;
const int N_RGB_ROW = 0;
const int     N_COL = 16;
const int   N_COLOR = 2;

#elif defined PEGGY2
const int     N_ROW = 25;
const int N_RGB_ROW = 0;
const int     N_COL = 25;
const int   N_COLOR = 2;

#else
const int     N_ROW = 12;
const int N_RGB_ROW = 10;
const int     N_COL = 16;
const int   N_COLOR = 9;
#endif

const unsigned long BAUDRATE = 112500;

const int COL_DRIVER_ENABLE = 17;

const int SPEAKER_PIN = 10;
const int DBG = 16;
const int MODE_PIN = 2;
const int INC_PIN = 3;
const int DEC_PIN = 15;
const int ENTER_PIN = 8;

const int LDR_PIN = 0;

// bitmasks for the colors
const unsigned long RGBW_MASKS[] = {
  0b001001001001001001001001001001, // RED
  0b010010010010010010010010010010, // GREEN
  0b100100100100100100100100100100, // BLUE
  0b001111111111111111111111111111  // WHITE
};

const uint8_t      DARK = 0b000;
const uint8_t      RED = 0b001;
const uint8_t     GREEN = 0b010;
const uint8_t      BLUE = 0b100;
const uint8_t GREENBLUE = GREEN | BLUE;
const uint8_t  REDGREEN = RED | GREEN;
const uint8_t   REDBLUE = RED | BLUE;
const uint8_t     WHITE = 0b111;

// not a real color, use temperature for color;
const uint8_t TEMPERATURE_COLOR = 8; 
const uint8_t BLUE_TEMP_C = 15;
const uint8_t WHITE_TEMP_C = 33;

const uint8_t MONO = BLUE;

// cold to warm
const uint8_t COLORS[9] = {
  DARK,
  BLUE,
  GREENBLUE,
  GREEN,
  REDBLUE,
  REDGREEN,
  RED,
  WHITE,
  TEMPERATURE_COLOR // hidden color for temperature control
};

class ClockTHREE {//:public Screen{ 
 public:
  ClockTHREE(); 
    
  // Hardware initialization
  void init();
  
  // Scan current display 1 time (if display is not NULL)
  void refresh();

  // Scan current display n times (if display is not NULL)
  void refresh(int n);
  void refresh_old(int n);

  // Gradually change display to new_display in over "steps" screens
  // return pointer to old display
  uint32_t *fadeto(uint32_t *new_display, uint32_t steps);

  // Interleave two images at specified duty cycle.
  void blend(uint32_t *new_display, 
	     uint8_t k,
	     uint8_t n,
	     uint32_t cycles);
  
  // Clears the display: LEDs set to OFF
  void clear(void);

  /* 
   * Set the hold time between column writes defaults to 50
   * (my_delay = # of times noop is called)
   */
  void set_column_hold(uint16_t _my_delay);
    
  void setcol(uint8_t xpos, uint32_t col);
  uint32_t getcol(uint8_t xpos);

  // Turn a pixel to color (0 == off)
  void setPixel(uint8_t xpos, uint8_t ypos, uint8_t color);

  // Determine color value of pixel at xpos, ypos
  uint8_t getPixel(uint8_t xpos, uint8_t ypos); 
		
  //Draw a line from (x1,y1) to (x2,y2)
  void line(double x1, double y1, double x2, double y2, uint8_t color);

  // Draw an ellipse centered at x, y with radius rx in the x direction and
  // ry in the y direction
  void ellipsalArc(double cx, double cy, 
		   double sma, double smi, double orientation, 
		   uint8_t color);
  /*
   * Draw an arc of an ellipse centered at x, y with 
   * semi-major axis sma
   * semi-minor axis smi
   * with semimajor axis oriented by orientation angle in radians
   * orient = 0 => sma oriented along x axis
   * orient = pi / 2 => sma oriented along x axis
   */
  void ellipse(double cx, double cy, 
	       double sma, double smi, double orientation, 
	       uint8_t color);

  // Draw a circle centered at x, y with radius r
  void circle(double x, double y, double r, uint8_t color);
  
  // Draw a rectangle
  
  //Set cursor position to (xpos,ypos)
  void moveto(int8_t xpos, int8_t ypos);
	
  //Draw line from cursor position to (xpos,ypos)
  // updating cursor position
  void lineto(int8_t xpos, int8_t ypos, uint8_t color);
  
  // Replace current display buffer, return pointer to old buffer
  uint32_t *setdisplay(uint32_t *display);

  /*
    Fill in a horizontal line of LEDs from start to start + n_char.
    n_char = # characters.
  */
  void horizontal_line(uint8_t row, 
		       uint8_t start, 
		       uint8_t n_char, 
		       uint8_t color);
   
  // Fill the display with single color
  void displayfill(uint8_t color);

  // turn display off
  void off();

  // play a note
  void note(uint16_t freq);
  void note(uint16_t freq, uint16_t duration_ms);
  void nonote();
/*
 * Uses RTC if available or INT if not.
 */
  
  uint32_t* display;
  uint8_t dim;
  uint8_t xpos;
  uint8_t ypos;
  uint16_t my_delay;
  uint8_t n_disp_col; // number of columns in the display data (at least N_COL, may be more)
  
 private:
};
uint8_t getColor(uint8_t color);
void _delay(unsigned int n);

#endif


