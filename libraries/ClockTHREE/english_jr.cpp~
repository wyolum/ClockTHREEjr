#include "ClockTHREE.h"
#include "english.h"

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

void minutes_hack(ClockTHREE c3, int mm, int ss); // not public declaration

void English::display_word(ClockTHREE c3, uint8_t color, 
			   const uint8_t *w){
  c3.horizontal_line(w[0], w[1], w[2], color);
}

void English::display_time(int YY, int MM, int DD, int hh, int mm, int ss, 
			   ClockTHREE c3, uint8_t color, uint8_t fade_steps
			   ){
  display_time(YY, MM, DD, hh, mm, ss, c3, color, fade_steps, (uint8_t)1, 
	       (uint8_t)1);
}
void English::display_time(int YY, int MM, int DD, int hh, int mm, int ss, 
			   ClockTHREE c3, uint8_t color, uint8_t fade_steps,
			   uint8_t its_flag, uint8_t minutes_hack_flag){
  uint8_t hour = 0;
  uint8_t hour24 = 0;
  uint8_t h_offset = 0;
  uint32_t *new_display = c3.display + N_COL;
  uint32_t *old_display;

  old_display = c3.setdisplay(new_display);
  // copy mono rows; clear rest
  for(int i = 0; i < N_COL; i++){
    new_display[i] = old_display[i] & 0xc0000000;
  }
  if(its_flag){
    display_word(c3, color, its);
  }
  if (0 <= mm and mm < 5){
    display_word(c3, color, oclock);
    h_offset = 0;
  }
  else if(5 <= mm && mm < 10){
    display_word(c3, color, mfive);
    display_word(c3, color, past);
    h_offset = 0;
  }
  else if( 10 <= mm && mm < 15){
    display_word(c3, color, mten);
    display_word(c3, color, past);
    h_offset = 0;
  }
  else if( 15 <= mm && mm < 20){
    display_word(c3, color, a);
    display_word(c3, color, quarter);
    display_word(c3, color, past);
    h_offset = 0;
  }
  else if( 20 <= mm && mm < 25){
    display_word(c3, color, twenty);
    display_word(c3, color, past);
    h_offset = 0;
  }
  else if( 25 <= mm && mm < 30){
    display_word(c3, color, mfive);
    display_word(c3, color, twenty);
    display_word(c3, color, past);
    h_offset = 0;
  }
  else if( 30 <= mm && mm < 35){
    display_word(c3, color, thirty);
    h_offset = 0;
  }
  else if( 35 <= mm && mm < 40){
    display_word(c3, color, mfive);
    display_word(c3, color, twenty);
    display_word(c3, color, to);
    h_offset = 1;
  }
  else if( 40 <= mm && mm < 45){
    display_word(c3, color, twenty);
    display_word(c3, color, to);
    h_offset = 1;
  }
  else if( 45 <= mm && mm < 50){
    display_word(c3, color, a);
    display_word(c3, color, quarter);
    display_word(c3, color, to);
    h_offset = 1;
  }
  else if( 50 <= mm && mm < 55){
    display_word(c3, color, mten);
    display_word(c3, color, to);
    h_offset = 1;
  }
  else if( 55 <= mm && mm < 60){
    display_word(c3, color, mfive);
    display_word(c3, color, to);
    h_offset = 1;
  }
  else{
    // ValueError('mm: %s' % mm);
  }
  hour = (hh + h_offset) % 12;
  if(hour == 0){
    display_word(c3, color, twelve);
  }
  else if(hour == 1){
    display_word(c3, color, one);
  }
  else if(hour == 2){
    display_word(c3, color, two);
  }
  else if(hour == 3){
    display_word(c3, color, three);
  }
  else if(hour == 4){
    display_word(c3, color, four);
  }
  else if(hour == 5){
    display_word(c3, color, hfive);
  }
  else if(hour == 6){
    display_word(c3, color, six);
  }
  else if(hour == 7){
    display_word(c3, color, seven);
  }
  else if(hour == 8){
    display_word(c3, color, eight);
  }
  else if(hour == 9){
    display_word(c3, color, nine);
  }
  else if(hour == 10){
    display_word(c3, color, hten);
  }
  else if(hour == 11){
    display_word(c3, color, eleven);
  }
  
  hour24 = (hh + h_offset) % 24;
  if(0 <= hour24  && hour24 < 1){
    if(30 <= mm && mm < 35){
      display_word(c3, color, in);
      display_word(c3, color, the);
      display_word(c3, color, morning);
    }
    else{
      display_word(c3, color, midnight);
    }
  }
  else if(1 <= hour24  && hour24 < 12){
    display_word(c3, color, in);
    display_word(c3, color, the);
    display_word(c3, color, morning);
  }
  else if( 12 <= hour24  && hour24 < 13){
    if (30 <= mm && mm < 35){
      display_word(c3, color, in);
      display_word(c3, color, the);
      display_word(c3, color, morning);
    }
    else{
      display_word(c3, color, noon);
    }
  }
  else if( 13 <= hour24  && hour24 < 17){
    display_word(c3, color, in);
    display_word(c3, color, the);
    display_word(c3, color, afternoon);
  }
  else if( 17 <= hour24  && hour24 < 20){
    display_word(c3, color, in);
    display_word(c3, color, the);
    display_word(c3, color, evening);
  }
  else if( 20 <= hour24  && hour24 < 24){
    display_word(c3, color, at);
    display_word(c3, color, night);
  }

  if(minutes_hack_flag){
    minutes_hack(c3, mm, ss);
  }
  c3.setdisplay(old_display);
  c3.fadeto(new_display, fade_steps);
  // copy new_display over
  for(int i = 0; i < N_COL; i++){
    old_display[i] = new_display[i];
  }
}

void minutes_hack(ClockTHREE c3, int mm, int ss){
  mm %= 5;
  uint8_t color, num;
  num = ss / 10;
  for(int i = 0; i < mm; i++){
    c3.setPixel(15, 4 + i, WHITE);
  }
  switch(num){
  case 0:
    color = BLUE;
    break;
  case 1:
    color = GREEN;
    break;
  case 2:
    color = RED;
    break;
  case 3:
    color = REDBLUE;
    break;
  case 4:
    color = REDGREEN;
    break;
  case 5:
    color = WHITE;
    break;
  }
  c3.setPixel(15, 4 + mm, color);
  // c3.setPixel(ss / 4, 10, BLUE);
  // c3.setPixel(ss / 4, 11, BLUE);
}
