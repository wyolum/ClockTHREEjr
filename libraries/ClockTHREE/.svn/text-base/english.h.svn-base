#ifndef ENGLISH_H
#define ENGLISH_H
#include "ClockTHREE.h"

/* char text[12 * 16 + 1] = 
  "ITSXATENRQUARTER"
  "TWENTYFIVEDPASTO"
  "TWELVETWONESEVEN"
  "FOURFIVESIXTHREE"
  "EIGHTENINELEVEN-"
  "BEERCHAIOCLOCKM-"
  "THIRTYUINITHEAT-"
  "MIDNIGHTEVENING-"
  "IXICLOCKTHREE78-"
  "MORNINGAFTERNOON"
  "THANKVIWEMNEED17"
  "YMDYMSALARMTCFAN";
*/
const uint8_t its[3] = {0, 0, 3};
const uint8_t a[3] = {0, 4, 1};
const uint8_t mten[3] = {0, 5, 3};
const uint8_t quarter[3] = {0, 9, 7};
const uint8_t twenty[3] = {1, 0, 6};
const uint8_t mfive[3] = {1, 6, 4};
const uint8_t past[3] = {1, 11, 4};
const uint8_t to[3] = {1, 14, 2};
const uint8_t twelve[3] = {2, 0, 6};
const uint8_t two[3] = {2, 6, 3};
const uint8_t one[3] = {2, 8, 3};
const uint8_t seven[3] = {2, 11, 5};
const uint8_t four[3] = {3, 0, 4};
const uint8_t hfive[3] = {3, 4, 4};
const uint8_t six[3] = {3, 8, 3};
const uint8_t three[3] = {3, 11, 5};
const uint8_t eight[3] = {4, 0, 5};
const uint8_t hten[3] = {4, 4, 3};
const uint8_t nine[3] = {4, 6, 4};
const uint8_t eleven[3] = {4, 9, 6};
const uint8_t beer[3] = {5, 0, 4};
const uint8_t chai[3] = {5, 4, 4};
const uint8_t oclock[3] = {5, 8, 6};
const uint8_t thirty[3] = {6, 0, 6};
const uint8_t in_the[3] = {6, 7, 5};
const uint8_t in[3] = {6, 7, 2};
const uint8_t the[3] = {6, 10, 3};
const uint8_t at[3] = {6, 13, 2};
const uint8_t midnight[3] = {7, 0, 8};
const uint8_t night[3] = {7, 3, 5};
const uint8_t evening[3] = {7, 8, 7};
const uint8_t morning[3] = {9, 0, 7};
const uint8_t after[3] = {9, 7, 5};
const uint8_t afternoon[3] = {9, 7, 9};
const uint8_t noon[3] = {9, 12, 4};
const uint8_t clocktwo[3] = {8, 3, 10};
const uint8_t thank[3] = {10, 0, 5};
const uint8_t usb_led[3] = {11, 0, 1};
const uint8_t year_led[3] = {11, 1, 1};
const uint8_t month_led[3] = {11, 2, 1};
const uint8_t day_led[3] = {11, 3, 1};
const uint8_t hour_led[3] = {11, 4, 1};
const uint8_t minute_led[3] = {11, 5, 1};
const uint8_t second_led[3] = {11, 6, 1};
const uint8_t alarm[3] = {11, 7, 5};
const uint8_t c_led[3] = {11, 12, 1};
const uint8_t f_led[3] = {11, 13, 1};
const uint8_t alarm_on_led[3] = {11, 14, 1};
const uint8_t alarm_off_led[3] = {11, 15, 1};

class English{
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
