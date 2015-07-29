#include <avr/pgmspace.h>
#include "ClockTHREE.h"
#include "rtcBOB.h"
#include <EEPROM.h>
#include <Wire.h>
#include <string.h>
#include "Time.h"
#include "MsTimer2.h"
#include "SPI.h"
// #include "dutch_v1.h"
// #include "english_v1.h"
// #include "english_v3.h"
#include "hebrew_v1.h"
#include "messaging.h"

ClockTHREE c3;                      // ClockTHREE singleton
uint32_t display[2 * N_COL];               // 2X display (16 columns per display) for swapping back and forth

// language constants
uint8_t n_minute_led;               // number of minute hack leds
uint8_t n_minute_state;             // number of minute hack states to cycle through
uint8_t n_byte_per_display;         // number of bytes used for each 5 minunte time incriment

unsigned int my_delay = 50;
// called once
void setup(){
  Wire.begin();
  setRTC(2000, 1, 1, 0, 0, 0);
  c3.init();
  c3.setdisplay(display); // 2x actual LED array size for staging data. // required by fade to

  // read language constants
  n_byte_per_display = pgm_read_byte(DISPLAYS);
  n_minute_state = pgm_read_byte(MINUTE_LEDS);
  n_minute_led = pgm_read_byte(MINUTE_LEDS + 1);

  // MAX Serial
  Serial.begin(57600);
  Serial.println("*********************");
  Serial.println("");
  Serial.println("ClockTHREEjr Kickstarter Edition!");
  Serial.println("WyoLum, LLC 2012");
  Serial.println("Creative Commons 3.0");
  Serial.println("CC BY SA");
  Serial.println("Open Hardware");
  Serial.println("");
  Serial.println("*********************");
}

// globals
int count;                        // one-up loop counter
int display_idx;                  // display index (0 or 1)
uint8_t last_min_hack_inc = 0;    // last mininte hack incriment (to know when it has changed)
uint8_t last_time_inc = 289;        // last time incriment (to know when it has changed)

void loop(){
  
  uint8_t word[3];                // will store start_x, start_y, length of word
  time_t spm = getTime() % 86400; // seconds past midnight
  uint16_t time_inc = spm / 300;  // 5-minute time increment are we in

  // which mininute hack incriment are we on?
  uint8_t minute_hack_inc = (spm % 300) / (300. / float(n_minute_state));

  // if minute hack or time has changed, update the display
  if(minute_hack_inc != last_min_hack_inc || time_inc != last_time_inc){
    
    // prepare other display on change
    display_idx++;
    display_idx %= 2;
    uint32_t* tmp_d = display + N_COL * (display_idx % 2);

    // clear the new display
    for(int ii = 0; ii < N_COL; ii++){
      tmp_d[ii] = 0;
    }

    // read display for next time incement
    getdisplay(time_inc, tmp_d);
  
    // read minutes hack for next time incement
    minutes_hack(minute_hack_inc, tmp_d);
    c3.fadeto(tmp_d, 32); // 32 fade steps to new display

    last_min_hack_inc = minute_hack_inc;
    last_time_inc = time_inc;
  }
  // Keep active LEDs lit
  // my_refresh(1000);
  c3.refresh(100);
  count++;
  messaging_loop();
}

/*
 * DISPLAYS: 288 32 bit settings.  one for each 5-minute period.  up to 32 words per setting.
 * To turn on word one in ith display: 10000000000000000000000000000000
 *
 * WORDS:  3 * n + 1 bytes.  first byte is # words followed by ordered words.
 *                                    x         y       l
 *        Each word is defined by startcol, startrow, len
 */

void getword(int i, uint8_t* out){
  out[0] = pgm_read_byte(WORDS + 3 * i + 1);
  out[1] = pgm_read_byte(WORDS + 3 * i + 2);
  out[2] = pgm_read_byte(WORDS + 3 * i + 3);
}

/*
 * Prepare out to display ith time increment
 *   i -- 0 to 287 time increment indexa
 * out -- points to column data to prepare
 */
void getdisplay(int i, uint32_t* out){
  uint8_t bits;     // holds the on off state for 8 words at a time
  uint8_t word[3];  // start columm, start row, length of the current word

  for(uint8_t j = 0; j < n_byte_per_display; j++){ // j is a byte index 

    // read the state for the next set of 8 words
    bits = pgm_read_byte(DISPLAYS + 1 + (i * n_byte_per_display) + j);
    for(uint8_t k = 0; k < 8; k++){                     // k is a bit index
      if((bits >> k) & 1){                              // check to see if word is on or off
	getword(j * 8 + k, word);                       // if on, read location and length
	for(int m=word[0]; m < word[0] + word[2]; m++){ // and display it
	  out[m] |= 1 << word[1];
	}
      }
    }
  } 
}


/*
 * MINUTES_HACK (for 4 LEDS cumulative)
 * 00000000000000000000000000000000 // minutes hack = 0
 * 00000000000000000000000000000001 // minutes hack = 1
 * 00000000000000000000000000000011 // minutes hack = 2
 * 00000000000000000000000000000111 // minutes hack = 3
 * 00000000000000000000000000001111 // minutes hack = 4
 *
 * MINUTE_LEDS: n_state, n_led, led0, led2,       led3,       led4
 *                    5,     4,  127,    0, 0b01110000,  0b0001111
 *
 * led_num = (row << 4) & col
 */

/*
 * minutes_hack -- prepare display to show ith minute hack intrement
 *   i -- minute hack index
 * out -- display to prepare
 */
void minutes_hack(uint8_t i, uint32_t *out){
  uint8_t col, row, led_num; // position variables for a minute hack LED
  boolean state;             // on/off state variable for a n minute hack LED
  
  // bits is a bit vector that indicates the on/off state for this time incriment i
  uint32_t bits = getminutebits(i);
  for(uint8_t j = 0; j < n_minute_led; j++){      // j is a minute-hack LED index

    // read LED location:
    //     skip first two bytes that contain values for number of minute hack states and number of minute hack leds
    led_num = pgm_read_byte(MINUTE_LEDS + 2 + j); 

    // pull location information for this LED
    col =   (led_num & 0b00001111);
    row =   (led_num & 0b01110000) >> 4; // msb is ignored
    state = (bits >> j) & 1;
    if(state){
      out[col] |= 1<<row;
    }
    else{
      out[col] &= (~(1<<row));
    }
  } 
}

// read the ith minute hack from program memory
uint32_t getminutebits(uint8_t i){
  return pgm_read_dword(MINUTES_HACK + i);
}


void my_refresh(int n_hold){
  uint8_t col_j;
  
  union Column_t {
    uint32_t dat32; 
    uint8_t dat8[4];
  } Column;
  
  if(display != NULL){
    for(int hold_i = 0; hold_i < n_hold; hold_i++){
      PORTC &= 0b11110111; // Enable col driver
      // for(col_j=0; col_j < N_COL; col_j++){
      col_j = 0;
      _delay(10);
      while (col_j < N_COL){
	// Column.dat32 = RGBW_MASKS[rgb_i] & display[col_j];
	Column.dat32 = display[15 - col_j];
	// transfer column to row drivers
	SPI.transfer(Column.dat8[3]);
	SPI.transfer(Column.dat8[2]);
	SPI.transfer(Column.dat8[1]);
	PORTC |= 0b00001000; // Disable col driver 
	SPI.transfer(Column.dat8[0]);
	PORTB |= 0b00000010; // Start latch pulse 
	PORTB &= 0b11111101; // End latch pulse 

	PORTD = (PORTD & 0b00001111) | (col_j << 4); //only impacts upper 4 bits of PORTD
	PORTC &= 0b11110111; // Enable col driver
	_delay(my_delay);
	col_j++;
      }
      PORTC |= 0b00001000; // Disable col driver
    }
  }
}
