#ifndef GERMAN_H
#define GERMAN_H
#include "ClockTHREE.h"

/* char text[12 * 16 + 1] = 
ES-IST-VIERTEL--
FUNF-ZWANZIGZEHN
VORNACH-HALB----
EINSZWEIDREI--- 
VIERFUNFSECHS-- 
SIEBENACHTZWOLF 
ZEHNELFNEUN-UHR 
AM-NACHMITTAGS- 
MORGENSABENDS---
IN-DER-NACHTS---
PETERSCLOCKTHREE
 YMTUMSALARM     
*/
const uint8_t es[3] = {0, 0, 2};
const uint8_t ist[3] = {0, 3, 3};
const uint8_t viertel[3] = {0, 7, 7};
const uint8_t mfunf[3] = {1, 0, 4};
const uint8_t zwanzig[3] = {1, 5, 7};
const uint8_t mzehn[3] = {1, 12, 4};
const uint8_t vor[3] = {2, 0, 3};
const uint8_t mnach[3] = {2, 3, 4};
const uint8_t halb[3] = {2, 8, 4};
const uint8_t ein[3] = {3, 0, 3};
const uint8_t eins[3] = {3, 0, 4};
const uint8_t zwei[3] = {3, 4, 4};
const uint8_t drei[3] = {3, 8, 4};
const uint8_t vier[3] = {4, 0, 4};
const uint8_t ufunf[3] = {4, 4, 4};
const uint8_t sechs[3] = {4, 8, 5};
const uint8_t sieben[3] = {5, 0, 6};
const uint8_t acht[3] = {5, 6, 4};
const uint8_t zwolf[3] = {5, 10, 5};
const uint8_t uzehn[3] = {6, 0, 4};
const uint8_t elf[3] = {6, 4, 3};
const uint8_t neun[3] = {6, 7, 4};
const uint8_t uhr[3] = {6, 12, 3};
const uint8_t am[3] = {7, 0, 2};
const uint8_t znach[3] = {7, 3, 4};
const uint8_t mittag[3] = {7, 7, 6};
const uint8_t mittags[3] = {7, 7, 7};
const uint8_t morgen[3] = {8, 0, 6};
const uint8_t morgens[3] = {8, 0, 7};
const uint8_t abend[3] = {8, 7, 5};
const uint8_t abends[3] = {8, 7, 6};
const uint8_t in[3] = {9, 0, 2};
const uint8_t der[3] = {9, 3, 3};
const uint8_t nacht[3] = {9, 7, 5};
const uint8_t nachts[3] = {9, 7, 6};

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

class German{
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
