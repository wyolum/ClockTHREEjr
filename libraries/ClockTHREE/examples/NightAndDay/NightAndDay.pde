/*
  Delivery ClockTHREE world clock application
  Light up world map where sun is currently shining.

  Justin Shaw Jan 29, 2011
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0

*/

#define CLOCKTWO // Use ClockTWO hardware configuration

#include <avr/pgmspace.h>
#include <EEPROM.h>
#include <Wire.h>
#include <string.h>
#include "Time.h"
#include "C3Alarms.h"
#include "MsTimer2.h"
#include "ClockTHREE.h"
#include "SPI.h"
#include "english.h"
#include "font.h"
#include "rtcBOB.h"
#include "EDL.h"

const uint8_t N_DISPLAY = 16;
ClockTHREE c3 = ClockTHREE();
uint32_t *display = (uint32_t*)calloc(N_COL * N_DISPLAY, sizeof(uint32_t));

// const double PI = 3.1415926;
// const double HALF_PI = PI / 2.;
const double DEG = PI / 180.;
const int WSOLSTICE = -8;
const double TROPIC_LAT = 23.45 * DEG;


const double DLON = 360. * DEG / N_COL;     // lon radiuns per led row
const double DLAT = -180 * DEG / N_RGB_ROW; // lat radians per led col
const double LON0 = -180 * DEG + DLON / 2.; // lon of left most column
const double LAT0 =   90 * DEG+ DLAT / 2.;  // lat of top row

// globals
double sunv[3];

/*
 * Convert lat/lon to xyz (ECEF) coordinates 
 * lat/lon - latitude / longetude coords in radians.
 * xyz -- unit vector in ECEF coords
 */
void latlon2xyz(double lat, double lon, double *xyz){
  xyz[0] = cos(lat) * cos(lon);
  xyz[1] = cos(lat) * sin(lon);
  xyz[2] = sin(lat);
}

/*
 * Compute sun vector in Earth Centered Earth Fixed (ECEF)coordinates
 */
void sun_pointing(int day, int minute, double *earth_to_sun){
  double lat, lon, theta;

  lon = PI - minute / 1440. * 2 * PI;
  theta = ((day - WSOLSTICE) / 365.25) * 2 * PI;
  lat = TROPIC_LAT - cos(theta);
  latlon2xyz(lat, lon, earth_to_sun);
}

double dot(double *v0, double *v1, int n){
  double out = 0.;
  for(int i = 0; i < n; i++){
    out += v0[i] * v1[i];
  }
  return out;
}

/*
 * Compute elevation angle of the sun.  
 * lat/lon - latitude / longetude coords in radians
 */
double sun_el(double lat, double lon, double *sunv){
  double xyz[3];
  latlon2xyz(lat, lon, xyz);
  return HALF_PI - acos(dot(xyz, sunv, 3));
}

uint8_t getColor(double el){
  uint8_t color = DARK;
  
  if(el > 15 * DEG){
    color = WHITE;
  }
  else if(el > 10 * DEG){
    color = GREENBLUE;
  }
  else if(el > 5 * DEG){
    color = REDBLUE;
  }
  else if(el > 0 * DEG){
    color = RED;
  }
  return color;
}

void setPixel(int column, int row, double *sunv){
  double lat, lon, el;
  uint8_t color;
  lat = LAT0 + row * DLAT;
  lon = LON0 + column * DLON;
  el = sun_el(lat, lon, sunv);

  color = getColor(el);
  c3.setPixel(column, row, color);
}

void setup(){
  c3.init();
  Wire.begin();
  c3.setdisplay(display);
  setSyncProvider(getTime);    // RTC
  setSyncInterval(60000);      // update every minute (and on boot)
  // Serial.begin(57600);
}

long count = 0;
void loop(){
  time_t t = now() + 5 * 3600;
  // t += 5 * 60;
  double sunv[3];
  int min;
  time_t day;
  day = t / ((time_t) 86400);
  min = int(elapsedSecsToday(t) / SECS_PER_MIN + .5);
  sun_pointing(day, min, sunv);
  double el = sun_el(0, 0, sunv);

  for(int c = 0; c < N_COL; c++){
    for(int r = 0; r < N_RGB_ROW; r++){
      setPixel(c, r, sunv);
      c3.refresh(1);
    }
  }
  c3.refresh(1);
}
