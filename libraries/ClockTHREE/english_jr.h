#ifndef ENGLISH_JR_H
#define ENGLISH_JR_H
#include "ClockTHREE.h"

/* 
letters = '''
KITRISCTENHALFX.
QUARTERTWENTYBZ:
IFIVECMINUTESAL.
PASTOBTWONEIGHTS
THREELEVENSIXTEN
FOURFIVESEVENINE
TWELVEXOCLOCKYAM
PMYDMTHWMFSUALR!'''.splitlines()
*/
const uint8_t it[3] = {0, 1, 2};
const uint8_t is[3] = {0, 4, 2};
const uint8_t a[3] = {0, 11, 1};
const uint8_t mten[3] = {0, 7, 3};
const uint8_t half[3] = {0, 10, 4};
const uint8_t quarter[3] = {1, 0, 7};
const uint8_t twenty[3] = {1, 7, 6};
const uint8_t mfive[3] = {2, 1, 4};
const uint8_t minutes[3] = {2, 6, 7};
const uint8_t past[3] = {3, 0, 4};
const uint8_t to[3] = {3, 3, 2};
const uint8_t two[3] = {3, 6, 3};
const uint8_t one[3] = {3, 8, 3};
const uint8_t eight[3] = {3, 10, 5};
const uint8_t three[3] = {4, 0, 5};
const uint8_t eleven[3] = {4, 4, 6};
const uint8_t six[3] = {4, 10, 3};
const uint8_t hten[3] = {4, 13, 3};
const uint8_t four[3] = {5, 0, 4};
const uint8_t hfive[3] = {5, 4, 4};
const uint8_t seven[3] = {5, 8, 5};
const uint8_t nine[3] = {5, 12, 4};
const uint8_t twelve[3] = {6, 0, 6};
const uint8_t oclock[3] = {6, 7, 6};
const uint8_t am[3] = {6, 14, 2};
const uint8_t pm[3] = {7, 0, 2};
const uint8_t c_led[3] = {7, 0, 0};
const uint8_t f_led[3] = {7, 9, 1};
const uint8_t alarm[3] = {7, 0, 0};
const uint8_t alarm_off_led[3] = {7, 0, 0};
const uint8_t alarm_on_led[3] = {7, 15, 1};

const uint8_t usb_led[3] = {7, 0, 0};
const uint8_t year_led[3] = {7, 2, 1};
const uint8_t month_led[3] = {7, 4, 1};
const uint8_t day_led[3] = {7, 3, 1};
const uint8_t hour_led[3] = {7, 6, 1};
const uint8_t minute_led[3] = {7, 8, 1};
const uint8_t second_led[3] = {7, 10, 1};

class EnglishJr{
 public:
  void display_word(ClockTHREE c3, uint8_t color, 
		    const uint8_t *w);
  /* display time on ClockTHREE in words.
   * fade_steps is a parameter for smoothing the transistion
   * 0 -- no smoothing, 50 -- high smoothing.
   * its_flag controls whether "IT'S" is displayed
   */
  void display_time(int YY, int MM, int DD, int hh, int mm, int ss,
		    ClockTHREE c3, uint8_t color, uint8_t fade_steps);
  void display_time(int YY, int MM, int DD, int hh, int mm, int ss,
		    ClockTHREE c3, uint8_t color, uint8_t fade_steps, 
		    uint8_t its_flag, uint8_t minutes_hack_flag);
  void minutes_hack(ClockTHREE c3, int mm, int ss);
};

#endif
