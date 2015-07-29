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

// debounce buttons threshold
const uint8_t DEBOUNCE_THRESH = 200;     // Two button pushes within this time

/* Event types */
const uint8_t       NO_EVT = 0; // NONE
const uint8_t     MODE_EVT = 1; // Mode Button has been pressed
const uint8_t      INC_EVT = 2; // Increment Button has been pressed
const uint8_t      DEC_EVT = 3; // Decriment Button has been pressed
const uint8_t    ENTER_EVT = 4; // Enter Button has been pressed
const uint8_t     TICK_EVT = 5; // Second has ellapsed
const uint8_t EVENT_Q_SIZE = 5; // Max # events.

uint8_t event_q[EVENT_Q_SIZE];
uint8_t n_evt = 0;                  // number of events awaiting processing
unsigned long last_mode_time = 0;   // for debounce
unsigned long last_inc_time = 0;    // for debounce
unsigned long last_dec_time = 0;    // for debounce
unsigned long last_enter_time = 0;    // for debounce
bool alarm_beeping = false;         // Beeping or Not? when alarm sounds.

ClockTHREE c3;                      // ClockTHREE singleton

/*
 * Called when mode button is pressed
 */
void mode_interrupt(){
  unsigned long now = millis();
  if(now - last_mode_time > DEBOUNCE_THRESH){
    // add mode_press event to mode event queue
    if(n_evt < EVENT_Q_SIZE){
      event_q[n_evt++] = MODE_EVT;
    }
  }
  alarm_beeping = false;
  last_mode_time = now;
}

/*
 * Called when inc button is pressed
 */
void inc_interrupt(){
  unsigned long now = millis();
  if(now - last_inc_time > DEBOUNCE_THRESH){
    // add mode_press event to mode event queue
    if(n_evt < EVENT_Q_SIZE){
      event_q[n_evt++] = INC_EVT;
    }
  }
  alarm_beeping = false;
  last_inc_time = now;
}

/*
 * Called when dec button is pressed
 */
void dec_interrupt(){
  unsigned long now = millis();
  if(now - last_dec_time > DEBOUNCE_THRESH){
    // add mode_press event to mode event queue
    if(n_evt < EVENT_Q_SIZE){
      event_q[n_evt++] = DEC_EVT;
    }
  }
  alarm_beeping = false;
  last_dec_time = now;
}


/*
 * Called when dec button is pressed
 */
void enter_interrupt(){
  unsigned long now = millis();
  if(now - last_enter_time > DEBOUNCE_THRESH){
    // add mode_press event to mode event queue
    if(n_evt < EVENT_Q_SIZE){
      event_q[n_evt++] = ENTER_EVT;
    }
  }
  alarm_beeping = false;
  last_enter_time = now;
}

void setup(){
  Wire.begin();
  Serial.begin(57600);
  c3.init();
  
  pinMode(MODE_PIN, INPUT);
  pinMode(DEC_PIN, INPUT);
  pinMode(INC_PIN, INPUT);
  pinMode(ENTER_PIN, INPUT);

  Serial.println("MODE_PIN: 1");
  Serial.println("DEC_PIN: 3");
  Serial.println("INC_PIN: 2");
  Serial.println("ENTER_PIN: 4");
}

void loop(){
#ifdef CLOCKTWO
  if(PIND & 1 << 5){
    mode_interrupt();
  }
  if(PIND & 1 << 6){
    inc_interrupt();
  }
  if(PIND & 1 << 7){
    dec_interrupt();
  }
#else
  if(PINC & (1 << 1)){
    dec_interrupt();
  }
  if(PINB & (1 << 0)){
    enter_interrupt();
  }
  attachInterrupt(0, mode_interrupt, FALLING); // Does not work on C2
  attachInterrupt(1, inc_interrupt, FALLING);  // Does not work on C2
#endif
  delay(100);
  // Serial.print(PINC, BIN);
  // Serial.print(" ");
  if(n_evt > 0){
    for(int i = 0; i < n_evt; i++){
      Serial.print(event_q[i], DEC);
      Serial.print(" ");
    }
    Serial.println("");
    n_evt = 0;
  }
  else{
    // Serial.println("No events");
  }
}
