/*
  ClockTHREE Countdown
  
  Justin Shaw DEC 31, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
 */

#include "ClockTHREE.h"
#include "SPI.h"
#include "Wire.h"
#include "Time.h"
#include "font.h"
#include "rtcBOB.h"
#include "english.h"
#include "EEPROM.h"
#include "MsTimer2.h"

const uint8_t N_DISPLAY = 20;
ClockTHREE c3 = ClockTHREE();

uint32_t *displays = (uint32_t*)calloc(N_COL * N_DISPLAY, sizeof(uint32_t));
uint32_t *clock_display = displays + 2;

time_t seconds_to_go;
tmElements_t alarm_tm;
uint8_t ahh, amm, ass, alarm_set;
uint8_t color = BLUE;
Font font = Font();
time_t alarm_seconds;
English faceplate = English();
uint32_t colen[8];

void setup(){
  Wire.begin();
  c3.init();
  c3.setdisplay(displays);
  c3.clear();
  setSyncProvider(getTime);      // RTC
  setSyncInterval(60000);      // update minute (and on boot)
  alarm_seconds = now() % 86400 + 125;
  
  // from RTC alarm
  //getRTC_alarm(&ahh, &amm, &ass, &alarm_set);
  //alarm_tm.Second = ass;
  //alarm_tm.Minute = amm;
  //alarm_tm.Hour = ahh;
  //alarm_seconds = makeTime(alarm_tm) % 86400;
  // alarm_seconds = 0; // midnight
  font.getChar(':', color, colen);
}

uint32_t count = 0;
int p;
int last_ss = -1;
int last_mm = -1;
int last_hh = -1;
void loop(){
  
  time_t t = now() % 86400;
  if(t > alarm_seconds){
    t = alarm_seconds + 86400 - t;
  }
  else{
    t = alarm_seconds - t;
  }
  uint8_t hh, mm, ss;
  hh = t / 3600;
  mm = (t % 3600) / 60;
  ss = t % 60;
  if(hh != last_hh){
    two_digits(hh, clock_display + 0);
  }
  if(mm != last_mm){
    two_digits(mm, clock_display + 17);
  }
  if(ss != last_ss){
    two_digits(ss, clock_display + 34);
  }
  last_hh = hh;
  last_mm = mm;
  last_ss = ss;
  clock_display[14] = colen[2];
  clock_display[15] = colen[3];
  clock_display[17+14] = colen[2];
  clock_display[17+15] = colen[3];
  if(hh > 0){
    p = (int)(16 - 18.9 * cos(count * 3.14159 / 180));
  }
  else if(mm > 0){
    p = (int)(25 - 18.9 / 2 * cos(count * 3.14159 / 180));
  }
  else{
    p = 32;
  }
  c3.setdisplay(clock_display + p);
  c3.refresh(100);
  if(t == 0){
    fireworks();
  }
  count++;
}

void two_digits(uint8_t val, uint32_t* display){
  font.getChar('0' + val / 10, color, display);
  font.getChar('0' + val % 10, color, display + 7);
}

void fireworks(){
  int x, y;
  
  c3.refresh(1800);
  while(1){
    memset(displays, 0, N_COL * N_DISPLAY * sizeof(uint32_t));
    for(int k = 0; k < 8; k++){
      if(random(0, 10) < 5){
	memset(displays, 0, N_COL * N_DISPLAY * sizeof(uint32_t));
      }
      x = random(3, 13);
      y = random(3, 10);
      int istart = random(0, 10);
      c3.setdisplay(displays + istart * N_COL);
      // c3.line(7, 11, x, y, WHITE);
      for(int i = istart; i < istart + 10; i++){
	c3.setdisplay(displays + i * N_COL);
	c3.circle(x, y, (i + 1 - istart), COLORS[random(0, 8)]);
	c3.circle(x, y, (i + 2 - istart), COLORS[random(0, 8)]);
	c3.circle(x, y, (i + 3 - istart), COLORS[random(0, 8)]);
      }
      x = random(0, 16);
      y = random(0, 9);
      istart = random(0, 100);
      if(istart < 10){
	for(int i = istart; i < istart + 10; i++){
	  c3.setdisplay(displays + i * N_COL);
	  c3.circle(x, y, (i + 1 - istart), COLORS[random(0, 8)]);
	  c3.circle(x, y, (i + 2 - istart), COLORS[random(0, 8)]);
	  c3.circle(x, y, (i + 3 - istart), COLORS[random(0, 8)]);
	}
      }
      int iter = random(1, 2);
      for(int j = 0; j < iter; j++){
	for(int i = 0; i < N_DISPLAY; i++){
	  c3.setdisplay(displays + N_COL * i);
	  c3.refresh(100);
	}
      }
    }
    memset(displays, 0, N_COL * N_DISPLAY * sizeof(uint32_t));
    font.getChar('M', GREENBLUE, displays + N_COL * 1);
    font.getChar('M', GREENBLUE, displays + N_COL * 1 + 8);
    font.getChar('X', GREENBLUE, displays + N_COL * 1 + 16);
    font.getChar('I', GREENBLUE, displays + N_COL * 1 + 23);
    font.getChar('2', GREEN, displays + N_COL * 3 + 0);
    font.getChar('0', GREEN, displays + N_COL * 3 + 8);
    font.getChar('1', GREEN, displays + N_COL * 3 + 15);
    font.getChar('1', GREEN, displays + N_COL * 3 + 22);
    for(int i = 0; i < N_COL * 4 + 12; i++){
      c3.setdisplay(displays + i);
      c3.refresh(180);
    }
  }
}
