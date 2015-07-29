/*
  Delivery ClockTHREE Word Clock App
  Display time 12:12 PM in words using english template
  Supports different modes:
  Normal
  Mode (Mode to switch modes)
  SetTime
  SetColor
  Serial

  Serial interface for interacting with computers supported.

  Justin Shaw Dec 22, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0

*/

// #define USE_NIL // comment out if speaker is installed, unless you are already deaf.
// #define USE_USA_DST // use standard USA dailight savings time rule
#define USE_EURO_DST // use dailight savings time for europe (TJS)

#include <avr/pgmspace.h>
#include <Wire.h>
#include <string.h>
#include "Time.h"
#include "MsTimer2.h"
#include "ClockTHREE.h"
#include "SPI.h"


// #include "dutch_v1.h"
// #include "english_v0.h"
// #include "english_v2.h"
// #include "english_v3.h"
// #include "french_v1.h"
// #include "german_v1.h"
#include "german_v3.h"
// #include "german_v5.h"
// #include "hebrew_v1.h"


#include "mem_font.h"
#include "rtcBOB.h"

// debounce buttons threshold
const uint8_t DEBOUNCE_THRESH = 200;     // Two button pushes within this time frame are counted only once.
const uint16_t SERIAL_TIMEOUT_MS = 1000; // Not working as expected.  Turned off.

// Define modes
typedef void (* CallBackPtr)(); // this is a typedef for callback funtions
inline void do_nothing(void){}  // empty call back

/*
 * ClockTHREE is mode driven.  A Mode is like a mini arduino program 
 * with its own setup and loop functions as well as an exit function
 * to clean up and prevent memory leeks.  Only one mode can be 
 * active at a time.  The active mode defines behaviors for events 
 * (like button pushes).  The switchmode function should be called 
 * to change modes.
 */
struct Mode{
  uint8_t id;        // Mode ID
  char sym;          // ASCII Symbol for mode (used to display mode in Mode mode)
  CallBackPtr setup; // to be called when Mode is initialized
  CallBackPtr loop;  // to be called as often as possible when mode is active
  CallBackPtr exit;  // to be called when mode is exited.
  CallBackPtr inc;   // to be called when increment button is pushed
  CallBackPtr dec;   // to be called when decrement button is pushed
  CallBackPtr mode;  // to be called when mode button is pushed
  CallBackPtr enter;   // to be called when enter button is pushed
};

/* The display memory buffer is larger than physical display for screen 
 * staging and fast display.
 */
const uint8_t N_DISPLAY = 3;

// Default display -- N_DISPLAY larger than physical display.
uint32_t *display = (uint32_t*)calloc(N_DISPLAY * N_COL + 2, sizeof(uint32_t));

// active mode pointer
Mode *mode_p;

// MODE Constants
const uint8_t N_MODE = 6;
const uint8_t N_MAIN_MODE = 3;  // main modes are accessable through Mode mode. (sub modes are not).
const uint8_t N_SUB_MODE = 3;

const uint8_t NORMAL_MODE = 0;
const uint8_t SET_TIME_MODE = 1;
const uint8_t MODE_MODE = 2;

// Sub Modes (this cannot be accessed though Mode mode selection.)
const uint8_t SECONDS_MODE = 3;
const uint8_t TEMPERATURE_MODE = 4;
const uint8_t SER_DISPLAY_MODE = 5;

// Temperature unit constants
const uint8_t DEG_C = 0;
const uint8_t DEG_F = 1;

/* last_mode_id is used for returning to previous mode.  
 * Usually best to return to NORMAL_MODE, but this allows sub-modes to return
 * to the mode that invoked them.
 */
uint8_t last_mode_id = NORMAL_MODE; // the last mode clock was in...

// indexed by mode.id
Mode Modes[N_MODE];

//Time units
typedef enum {YEAR, MONTH, DAY, HOUR, MINUTE, SECOND} unit_t;
const char* TIME_CODES = "YRMODAHRMISE";

// Begin mode declarations
Mode NormalMode = {NORMAL_MODE, 
		   'N', Normal_setup, Normal_loop, Normal_exit, 
		   Normal_inc, Normal_dec, Normal_mode, do_nothing};
Mode SecondsMode = {SECONDS_MODE, 
		    'S', Seconds_setup, Seconds_loop, Seconds_exit, 
		    Seconds_mode, Seconds_mode, Seconds_mode, Seconds_mode};
Mode SerDisplayMode = {SER_DISPLAY_MODE,
		       'X', do_nothing, SerDisplay_loop, do_nothing,
		       return_to_normal,return_to_normal,return_to_normal,
		       return_to_normal};

Mode TemperatureMode = {TEMPERATURE_MODE, 'X', 
			Temperature_setup, Temperature_loop, Temperature_exit, 
			Temperature_inc, Temperature_dec, Temperature_mode,
			Temperature_mode};
Mode SetTimeMode = {SET_TIME_MODE, 
		    'S', SetTime_setup,SetTime_loop,SetTime_exit,
		    SetTime_inc, SetTime_dec, SetTime_mode, SetTime_enter};
Mode ModeMode = {MODE_MODE, 
		 'M', Mode_setup, Mode_loop, Mode_exit, 
		 Mode_inc, Mode_dec, return_to_normal, Mode_enter};

/* Event types */
const uint8_t       NO_EVT = 0; // NONE
const uint8_t     MODE_EVT = 1; // Mode Button has been pressed
const uint8_t      INC_EVT = 2; // Increment Button has been pressed
const uint8_t      DEC_EVT = 3; // Decriment Button has been pressed
const uint8_t    ENTER_EVT = 4; // Enter Button has been pressed
const uint8_t     TICK_EVT = 5; // Second has ellapsed
const uint8_t EVENT_Q_SIZE = 5; // Max # events.

// Serial Messaging
struct MsgDef{
  uint8_t id;     // message type id

  /* n_byte holde the number of bytes or if n_byte == VAR_LENGTH, message type is variable length 
   * with message length in second byte of message. */
  uint8_t n_byte; 

  /* Function to call when this message type is recieved.
   * message content (header byte removed) will available to the call back function through
   * the global variabe "char serial_msg[]".
   */
  CallBackPtr cb; 
};

const uint8_t MAX_MSG_LEN = 100; // official: 100
// const uint16_t BAUDRATE = 57600; // official:57600 (Scott Schenker 38400)
const uint8_t SYNC_BYTE = 254;   // 0xEF; (does not seem to work!)
const uint8_t VAR_LENGTH = 255;  // 0xFF;
const uint8_t N_MSG_TYPE = 25;

// Message types
const MsgDef  NOT_USED_MSG = {0x00, 1, do_nothing};
const MsgDef  ABS_TIME_REQ = {0x01, 1, send_time};
const MsgDef  ABS_TIME_SET = {0x02, 5, Serial_time_set};
// const MsgDef     EVENT_REQ = {0x08, 2, do_nothing}; // not used
// const MsgDef     EVENT_SET = {0x09, 6, do_nothing}; // not used
const MsgDef   DISPLAY_REQ = {0x0A, 1, display_send};
const MsgDef   DISPLAY_SET = {0x0B, 65, display_set};
const MsgDef  TRIGGER_MODE = {0x0C, 1, mode_interrupt};
const MsgDef   TRIGGER_INC = {0x0D, 1, do_nothing};
const MsgDef   TRIGGER_DEC = {0x0E, 1, do_nothing};
const MsgDef TRIGGER_ENTER = {0x0F, 1, do_nothing};
const MsgDef   VERSION_REQ = {0x10, 1, do_nothing};
const MsgDef     ABOUT_REQ = {0x11, 1, do_nothing};
const MsgDef          PING = {0x12, MAX_MSG_LEN, pong}; // can make variable length.

const MsgDef          SYNC = {SYNC_BYTE, MAX_MSG_LEN, do_nothing}; // must already be in sync
const MsgDef      ERR_OUT = {0x71, VAR_LENGTH, do_nothing}; // variable length

// array to loop over when new messages arrive.
const MsgDef *MSG_DEFS[N_MSG_TYPE] = {&NOT_USED_MSG,
				      &ABS_TIME_REQ,
				      &ABS_TIME_SET,
				      //&EVENT_REQ,
				      //&EVENT_SET,
				      &DISPLAY_REQ,
				      &DISPLAY_SET,
				      &TRIGGER_MODE,
				      &TRIGGER_INC,
				      &TRIGGER_DEC,
				      &TRIGGER_ENTER,
				      &VERSION_REQ,
				      &ABOUT_REQ,
				      &PING,
				      };


// Globals
/*
 * This is a input/output buffer for serial communications.  
 * This buffer is also used for some non-serial processing to save memory.
 */
char serial_msg[MAX_MSG_LEN];
uint8_t serial_msg_len;       // Stores actual length of serial message.  Should be updated upon transmit or reciept.

/*
 * Array to store button push events or clock "TICK" events.
 */
uint8_t event_q[EVENT_Q_SIZE];
uint8_t n_evt = 0;                  // number of events awaiting processing
unsigned long last_mode_time = 0;   // for debounce
unsigned long last_inc_time = 0;    // for debounce
unsigned long last_dec_time = 0;    // for debounce
unsigned long last_enter_time = 0;    // for debounce

ClockTHREE c3;                      // ClockTHREE singleton

//Font font = Font();                 // Only font at this time.
MemFont font = MemFont();
time_t t;                           // TODO: remove this, not needed (I think)
uint8_t mode_counter;               // Used for selecting mode
unsigned long count = 0;            // Number of interations current mode has been running.
uint16_t YY;                        // current time variables.
uint8_t MM, DD, hh, mm, ss;
uint8_t ahh, amm, ass;              // time of day time (tod) variables.
boolean tick = true;                // tick is true whenever a second changes (false when change has been dealt with)
unit_t SetTime_unit = YEAR;         // Part of time being set {YEAR | MONTH | DAY | HOUR | MINUTE}
uint8_t temp_unit = DEG_C;          // Temperature display units {DEG_C | DEC_F}
uint8_t sync_msg_byte_counter = 0;  // How many byte in a row has sync byte been recieved 

// language constants
uint8_t n_minute_led;               // number of minute hack leds
uint8_t n_minute_state;             // number of minute hack states to cycle through
uint8_t n_byte_per_display;         // number of bytes used for each 5 minunte time incriment

uint8_t display_idx;
uint8_t last_min_hack_inc = 0;
uint16_t last_time_inc = 289;

// NIL values
int nil_count = 0;
double nil_val = 1;
double nil_rate = 1.1;
const uint8_t NIL_PIN = 10;

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
  last_enter_time = now;
}

/*
 * Called when second boundary is crossed
 */
void tick_interrupt(){
  if(n_evt < EVENT_Q_SIZE){
    event_q[n_evt++] = TICK_EVT;
  }
}

/*
 * Three time systems are with varying degrees of processor use and accuracy.
 * YY, MM, DD ... are the least accurate and least procesor hungry
 * Time.h time -- year(), month() ... are kinda slow.
 * rtcBOB -- most accrate (and slowest?  need to verify this.)
 */
void update_time(){
  // update global time variables.  resync with Time.h
  c3.refresh();  // keep display going.
  YY = year();
  c3.refresh();
  MM = month();
  c3.refresh();
  DD = day();
  c3.refresh();
  hh = hour();
  c3.refresh();
  mm = minute();
  c3.refresh();
  ss = second();
  c3.refresh();
}

// Main setup function
void setup(void){
  Serial.begin(BAUDRATE);
  Wire.begin();
  c3.init();
  
  mode_p = &NormalMode;

  // ensure mode ids are consistant.
  Modes[NORMAL_MODE] = NormalMode;
  Modes[SET_TIME_MODE] = SetTimeMode;
  //  Modes[SERIAL_MODE] = SerialMode;
  Modes[MODE_MODE] = ModeMode;

  // Sub Modes
  Modes[SECONDS_MODE] = SecondsMode;
  Modes[SER_DISPLAY_MODE] = SerDisplayMode;
  Modes[TEMPERATURE_MODE] = TemperatureMode;
  mode_p->setup();

  attachInterrupt(0, mode_interrupt, FALLING); // Does not work on C2
  attachInterrupt(1, inc_interrupt, FALLING);  // Does not work on C2
  c3.setdisplay(display); // 2x actual LED array size for staging data. // required by fade to
  c3.set_column_hold(50);

  if(digitalRead(MODE_PIN)){
    self_test();
  }

  MsTimer2::set(1000, tick_interrupt); // 1ms period
  MsTimer2::start();


  // Set Time and Alarms
  setSyncProvider(getTime);      // RTC
  setSyncInterval(60000);      // update every minute (and on boot)
  update_time();

  // read language constants
  n_byte_per_display = pgm_read_byte(DISPLAYS);
  n_minute_state = pgm_read_byte(MINUTE_LEDS);
  n_minute_led = pgm_read_byte(MINUTE_LEDS + 1);

#ifdef USE_NIL
  // setup NIL
  pinMode(NIL_PIN, OUTPUT);
  analogWrite(NIL_PIN, 0);
#endif
  //Serial.println("Checking DST");
#if defined(USE_USA_DST) || defined(USE_EURO_DST)
  //  Serial.print("Using dailight savings time rules:");
#endif
#ifdef USE_USA_DST
  // Serial.println("USA dailight savings time");
#endif
#ifdef USE_EURO_DST
  // Serial.println("EURO dailight savings time");
#endif
}

// main loop function.  Dellegate to mode_p->loop();
void loop(void){
  //check button status // C2 hack
  if(PINC & (1 << 1)){
    dec_interrupt();
  }
  if(PINB & (1 << 0)){
    enter_interrupt();
  }
  /* with auto reset, 
   * serial connection to C3 causes a reset so entering serial mode
   * manually is fuitless.  This is way better anyway.
   */
  Serial_loop();
  // process new events before calling mode loop()
  for(uint8_t i = 0; i < n_evt; i++){
    switch(event_q[i]){
    case NO_EVT:
      break;
    case MODE_EVT:
      mode_p->mode();
      break;
    case INC_EVT:
      mode_p->inc();
      break;
    case DEC_EVT:
      mode_p->dec();
      break;
    case ENTER_EVT:
      mode_p->enter();
      break;
    case TICK_EVT:
      tick = true;
      ss++;
      if(ss >= 60){
	ss %= 60;
	mm++;
	if(mm >= 60){
	  mm %= 60;
	  hh++;
	  if(hh == 24){
	    update_time();
	  }
	}
      }
    }
    event_q[i] = NO_EVT;
  }

#ifdef USE_NIL
  // NIL
  nil_val = cos(nil_count++ / 100.) * 75 + 180;
  analogWrite(NIL_PIN, (int)nil_val);
#endif
  n_evt = 0;
  mode_p->loop(); // finally call mode_p loop()
  count++;        // counts times mode_p->loop() has run since mode start

}

// Begin Normal Mode Code 
/* 
   Initalize mode.
*/
void Normal_setup(void){
  tick = true;
}
void Normal_loop(void) {
  tick = true;
  time_t standard_time = getTime();

  uint8_t word[3];                // will store start_x, start_y, length of word
  time_t spm = standard_time % 86400; // seconds past midnight
#if defined(USE_USA_DST) || defined(USE_EURO_DST)
  if(is_dst(standard_time)){
    spm += 3600;
    spm %= 86400;
    // c3.setPixel(7, 7, 1);
  }
#endif
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
  count++;
#ifdef AUTO_DIM
  uint8_t ldr_val;
  ldr_val = analogRead(LDR_PIN);
  c3.dim = (ldr_val - MIN_LDR_VAL) * 16 / (MAX_LDR_VAL - MIN_LDR_VAL)
#endif
  c3.refresh(16);
}
/*
  Get ready for next mode.
*/
void Normal_exit(void) {
  last_time_inc = 289;
}
/*
  Respond to button presses.
*/
void Normal_inc(void) {
#ifdef DIM
  if(c3.dim > 1){
    c3.dim /= 2;
  }
  Serial.println(c3.dim);
#else
  switchmodes(SECONDS_MODE);
#endif
}
void Normal_dec(void) {
#ifdef DIM
  if(c3.dim < 15){
    c3.dim *= 2;
  }
  Serial.println(c3.dim);
#else
  switchmodes(TEMPERATURE_MODE);
#endif
}
void Normal_mode(void) {
  switchmodes(MODE_MODE);
}

// Sub mode of normal mode ** display seconds
void Seconds_setup(void){
  tick = true;
}
void Seconds_loop(){
  if(tick){
    tick = false;
    two_digits(ss);
  }
  c3.refresh(16);
}
void Seconds_exit(void) {
}
void Seconds_mode(){
  switchmodes(last_mode_id);
}

// Sub mode of normal mode ** display temp
void Temperature_setup(void){
  if(temp_unit == DEG_C){
    // faceplate.display_word(c3, MONO, c_led);
  }
  else{
    // faceplate.display_word(c3, MONO, f_led);
  }
}
void Temperature_loop(){
  int8_t temp = getTemp();
  if(temp_unit == DEG_F){
    temp = toF(temp);
  }
  two_digits(temp);
  c3.refresh(16);
}
void Temperature_exit(void) {
}
// toggle temp_unit
void Temperature_inc(){
  if(temp_unit == DEG_F){
    temp_unit = DEG_C;
  }
  else{
    temp_unit = DEG_F;
  }
}
void Temperature_dec(){
  switchmodes(last_mode_id);
}
void Temperature_mode(){
  switchmodes(last_mode_id);
}

void SerDisplay_loop(){
  c3.refresh(16);
}

// Begin SetTime Mode Code 
/* 
   Initalize mode.
*/
void SetTime_setup(void){
  MsTimer2::stop(); // Ticks stop while setting time
  getTime(); // sync with rtcBOB
  SetTime_unit = YEAR;
}
void SetTime_loop(void) {
  switch(SetTime_unit){
  case YEAR:
    if(count % 200 > 75){
      c3.clear();
      two_digits(YY % 100);
    }
    else{
      c3.clear();
      font.getChar('Y', MONO, display + 5);  
    }
    // faceplate.display_word(c3, MONO, year_led);
    break;
  case MONTH:
    if(count % 200 > 75){
      c3.clear();
      two_digits(MM);
    }
    else{
      c3.clear();
      font.getChar('M', MONO, display + 5);  
    }
    // faceplate.display_word(c3, MONO, month_led);
    break;
  case DAY:
    if(count % 200 > 75){
      c3.clear();
      two_digits(DD);
    }
    else{
      c3.clear();
      font.getChar('D', MONO, display + 5);  
    }
    // faceplate.display_word(c3, MONO, day_led);
    break;
  case HOUR:
    if(count % 200 > 75){
      c3.clear();
      two_digits(hh);
    }
    else{
      c3.clear();
      font.getChar('H', MONO, display + 5);  
    }
    // faceplate.display_word(c3, MONO, hour_led);
    break;
  case MINUTE:
    if(count % 200 > 75){
      c3.clear();
      two_digits(mm);
    }
    else{
      c3.clear();
      font.getChar('M', MONO, display + 5);  
    }
    // faceplate.display_word(c3, MONO, minute_led);
    break;
  default:
    break;
  }
  c3.refresh(16);
}
/*
  Get ready for next mode.
*/
void SetTime_exit(void) {
  setRTC(YY, MM, DD, hh, mm, ss);
  MsTimer2::start();
}
/*
  Respond to button presses.
*/
void SetTime_inc(void) {
  switch(SetTime_unit){
  case YEAR:
    YY++;
    two_digits(YY % 100);
    break;
  case MONTH:
    MM = (MM + 1) % 13;
    if(MM == 0){
      MM = 1;
    }
    two_digits(MM);
    break;
  case DAY:
    DD = (DD + 1) % (MONTHS[MM] + LEAP_YEAR(YY) + 1);
    if(DD == 0){
      DD = 1;
    }
    two_digits(DD);
    break;
  case HOUR:
    hh = (hh + 1) % 24;
    two_digits(hh);
    break;
  case MINUTE:
    mm = (mm + 1) % 60;
    ss = 0;
    two_digits(mm);
    break;
  }
}
void SetTime_dec(void) {
  switch(SetTime_unit){
  case YEAR:
    YY--;
    two_digits(YY % 100);
    break;
  case MONTH:
    MM = (MM - 1) % 13;
    if(MM == 0){
      MM = 12;
    }
    two_digits(MM);
    break;
  case DAY:
    DD = (DD - 1) % (MONTHS[MM] + LEAP_YEAR(YY) + 1);
    if(DD == 0){
      DD = 1;
    }
    two_digits(DD);
    break;
  case HOUR:
    if(hh == 1){
      hh = 23; // uint cannot go neg
    }
    else{
      hh--;
    }
    two_digits(hh);
    break;
  case MINUTE:
    if(mm == 0){
      mm = 59; // uint cannot go neg
    }
    else{
      mm--;
    }
    ss = 0;
    two_digits(mm);
    break;
  }
}
void SetTime_mode(void) {
  c3.clear();
  switch(SetTime_unit){
  case YEAR:
    SetTime_unit = MONTH;
    break;
  case MONTH:
    SetTime_unit = DAY;
    break;
  case DAY:
    SetTime_unit = HOUR;
    break;
  case HOUR:
    SetTime_unit = MINUTE;
    break;
  default:
    SetTime_unit = YEAR;
    break;
  }
}

void SetTime_enter(void){
  switchmodes(NORMAL_MODE);
}

void Serial_loop(void) {
  uint8_t val;
  boolean resync_flag = true;
  if(Serial.available()){
    val = Serial.read();
    // two_digits(val);
    // find msg type
    for(uint8_t msg_i = 0; msg_i < N_MSG_TYPE; msg_i++){
      if(MSG_DEFS[msg_i]->id == val){
	if(Serial_get_msg(MSG_DEFS[msg_i]->n_byte)){
	  /*
	   * Entire payload (n_byte - 1) bytes 
	   * is stored in serial_msg: callback time.
	   */

	  MSG_DEFS[msg_i]->cb();
	  //two_digits(val);
	  //c3.refresh(10000);
	}
	else{
	  // Got a sync message unexpectedly. Get ready for new message.
	  // no callback
	  // or timeout
	}
	resync_flag = false;
	break;
	// return;
      }
    }
    if(resync_flag){
      Serial_sync_wait();
    }
  }
}

void Serial_sync_wait(){
  // wait for SYNC message;
  uint8_t val;
  uint8_t n = 0;
  digitalWrite(DBG, HIGH);
  while(n < SYNC.n_byte){
    if(Serial.available()){
      val = Serial.read();
      if(val == SYNC_BYTE){
	n++;
      }
      else{
	n = 0;
      }
    }
  }
  digitalWrite(DBG, LOW);
}

// Transmit contents of PING message back to sender.
void pong(){
  for(uint8_t i=0; i < MAX_MSG_LEN - 1; i++){
    // Serial.print(serial_msg[i], BYTE);
    Serial.write(serial_msg[i]);
  }
}

void send_time(){
  char ser_data[4];
  // Serial.print(ABS_TIME_SET.id, BYTE);
  Serial.write(ABS_TIME_SET.id);
  Time_to_Serial(now(), ser_data);
  for(uint8_t i = 0; i < 4; i++){
    // Serial.print(ser_data[i], BYTE);
    Serial.write(ser_data[i]);
  }
}

void Serial_time_set(){
  setTime(Serial_to_Time(serial_msg));
  
  /* // old way
  Serial_time_t data;

  for(uint8_t i = 0; i < 4; i++){
    data.dat8[i] = serial_msg[i];
  }
  setTime(data.dat32);
  */
  YY = year();
  MM = month();
  DD = day();
  hh = hour();
  mm = minute();
  ss = second();
  setRTC(YY, MM, DD, hh, mm, ss);
}

void Serial_send_err(char *err){
  uint8_t len = strlen(err);
  // Serial.print(ERR_OUT.id, BYTE);
  Serial.write(ERR_OUT.id);
  //// Serial.print(len + 2 + MAX_MSG_LEN, BYTE);
  // Serial.print(len + 2, BYTE);
  Serial.write(len + 2);
  Serial.print(err);
  c3.note(55);
  // Serial.print(serial_msg);
}

void display_send(){
  uint8_t *display_p = (uint8_t *)display;
  // Serial.print(DISPLAY_SET.id, BYTE);
  Serial.write(DISPLAY_SET.id);
  for(uint8_t i = 0; i < N_COL * sizeof(uint32_t); i++){
    // Serial.print(display_p[i], BYTE);
    Serial.write(display_p[i]);
  }
}

void display_set(){
  if(mode_p->id != SER_DISPLAY_MODE){
    switchmodes(SER_DISPLAY_MODE);
  }
  uint8_t *display_p = (uint8_t *)display;
  for(uint8_t i = 0; i < N_COL * sizeof(uint32_t); i++){
    display_p[i] = serial_msg[i];
  }
}

void trigger_mode(){
  
}

// store serial data into serial_msg staring from first byte AFTER MID
// to be clear MID is not in serial_msg
boolean Serial_get_msg(uint8_t n_byte) {
  /*
    n_byte = message length including 1 byte MID
  */
  uint16_t i = 0;
  unsigned long start_time = millis();

  uint8_t val, next;
  boolean out;

  // digitalWrite(DBG, HIGH);
  if(n_byte == VAR_LENGTH){
    // variable length message
    while(!Serial.available()){/* && 
				  ((millis() - start_time) < SERIAL_TIMEOUT_MS)){*/
      delay(1);
    }
    n_byte = Serial.peek();
  }
  while((i < n_byte - 1)){/* && 
			     ((millis() - start_time) < SERIAL_TIMEOUT_MS)){*/
    if(Serial.available()){
      val = Serial.read();
      if (val == SYNC_BYTE){
	sync_msg_byte_counter++;
	if(sync_msg_byte_counter == MAX_MSG_LEN){
	   // no other valid msg combination can have MAX_MSG_LEN sync bytes.
	   // sync msg recieved! break out, next char is start of new message
	   sync_msg_byte_counter = 0;
	   break;
	 }
       }
       else{
	 sync_msg_byte_counter = 0;
       }
       serial_msg[i++] = val;
     }
   }
   if(i == n_byte - 1){
     digitalWrite(DBG, LOW);
     out = true;
   }
   else{
    digitalWrite(DBG, HIGH);
    out = false;
  }
  return out;
}

/*
  Get ready for next mode.
*/
void Serial_exit(void) {
  Serial.end();
}
/*
  Respond to button presses.
*/
void Serial_inc(void) {
}
void Serial_dec(void) {
}
void Serial_mode(void) {
  switchmodes(NORMAL_MODE);  // or maybe just go back to NORMAL_MODE? or last_mode?
}

// Begin Mode Mode Code
void Mode_setup(void) {
  // font.getChar('M', MONO, display);
  mode_counter = 1;
  font.getChar(Modes[mode_counter].sym, MONO, display + 5);
}
void Mode_loop(void) {
  c3.refresh(16);
}
void Mode_exit(void) {
}
void Mode_inc(void) {
  mode_counter++;
  mode_counter %= N_MAIN_MODE - 1; // skip ModeMode
  font.getChar(Modes[mode_counter].sym, MONO, display + 5);
}
void Mode_dec(void) {
  if(mode_counter == 0){
    mode_counter = N_MAIN_MODE - 2;// skip ModeMode
  }
  else{
    mode_counter--;
  }
  font.getChar(Modes[mode_counter].sym, MONO, display + 5);
}
void Mode_enter(void) {
  switchmodes(mode_counter);
}

void switchmodes(uint8_t new_mode_id){
  // only switch if we are not in this mode already ... or not...
  // if(new_mode_id != mode_p->id){
  last_mode_id = mode_p->id;
  c3.clear(); // clear both screens
  c3.setdisplay(display + N_COL); 
  c3.clear(); // clear both screens
  c3.setdisplay(display);
  mode_p->exit();
  mode_p = &Modes[new_mode_id];
  mode_p->setup();
  count = 0;
  // }
}

void return_to_normal(){
  switchmodes(NORMAL_MODE);
}
void two_digits(uint8_t val){
  font.getChar('0' + val / 10, MONO, display + 2);
  font.getChar('0' + val % 10, MONO, display + 9);
}

void two_digits(uint8_t val, uint32_t *display){
  font.getChar('0' + val / 10, MONO, display + 2);
  font.getChar('0' + val % 10, MONO, display + 9);
}

/*
 * Add a letter without erasing existing pixels
 */
void add_char(char letter, uint32_t* display, uint8_t col){
  uint32_t data[8];
  font.getChar(letter, MONO, data);
  for(uint8_t i = 0; i < 7; i++){
    display[col + i] |= (data[i] & 0b00000000111111111111111111111111);
  }
}
void two_letters(char* letters){
  font.getChar(letters[0], MONO, display + 2);
  font.getChar(letters[1], MONO, display + 9);
}

uint8_t my_random_value = 0;
const uint8_t prime = 31;
int my_random(uint8_t min, uint8_t max){
  my_random_value += prime;
  return (my_random_value % (max - min)) + min;
}

void too_big_fireworks(){ // will not fit special effect // need SD!
  int x, y;
  c3.refresh(1800);
  //while(1){
    memset(display, 0, N_COL * N_DISPLAY * sizeof(uint32_t));
    for(int k = 0; k < 8; k++){
      if(my_random(0, 10) < 5){
	memset(display, 0, N_COL * N_DISPLAY * sizeof(uint32_t));
      }
      x = my_random(3, 13);
      y = my_random(3, 10);
      int istart = my_random(0, 10);
      c3.setdisplay(display + istart * N_COL);
      // c3.line(7, 11, x, y, WHITE);
      for(int i = istart; i < istart + 10; i++){
	c3.setdisplay(display + i * N_COL);
	c3.circle(x, y, (i + 1 - istart), COLORS[my_random(0, 8)]);
	c3.circle(x, y, (i + 2 - istart), COLORS[my_random(0, 8)]);
	c3.circle(x, y, (i + 3 - istart), COLORS[my_random(0, 8)]);
      }
      x = my_random(0, 16);
      y = my_random(0, 9);
      istart = my_random(0, 100);
      if(istart < 10){
	for(int i = istart; i < istart + 10; i++){
	  c3.setdisplay(display + i * N_COL);
	  c3.circle(x, y, (i + 1 - istart), COLORS[my_random(0, 8)]);
	  c3.circle(x, y, (i + 2 - istart), COLORS[my_random(0, 8)]);
	  c3.circle(x, y, (i + 3 - istart), COLORS[my_random(0, 8)]);
	}
      }
      int iter = my_random(1, 2);
      for(int j = 0; j < iter; j++){
	for(int i = 0; i < N_DISPLAY; i++){
	  c3.setdisplay(display + N_COL * i);
	  c3.refresh(100);
	}
      }
    }
    memset(display, 0, N_COL * N_DISPLAY * sizeof(uint32_t));
    for(int i = 0; i < N_COL * 4 + 12; i++){
      c3.setdisplay(display + i);
      c3.refresh(180);
    }
    //  }
}

// in is the address of the start of 4 time bytes.
time_t Serial_to_Time(char *in){
  return *((uint32_t *)in);
}

// write 4 bytes of in into char buffer out.
void Time_to_Serial(time_t in, char *out){
  time_t *out_p = (time_t *)out;
  *out_p = in;
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


void self_test(){
  boolean state = false;
  if(!testRTC()){ // RTC Failed  Display X
    display[0] = 0b10000001;
    display[1] = 0b01000010;
    display[2] = 0b00100100;
    display[3] = 0b00011000;
    display[4] = 0b00100100;
    display[5] = 0b01000010;
    display[6] = 0b10000001;
    while(1){
      c3.refresh(1000);
    }
  }
  while(true){
    state = !state;
    for(uint8_t i = 0; i < 8; i++){
      for(uint8_t j = 0; j < 16; j++){
	c3.setPixel(j, i, state);
	c3.refresh(100);
      }
    }
  }
}

bool testRTC(){
  bool status = true;
  uint8_t date[7];
  delay(100);
  if(rtc_raw_read(0, 7, true, date)){
    Serial.print("DATE: ");
    // date[2], date[1], date[0], date[4], date[5], date[6]
    //      hr,     min,     sec,     day,   month,  yr;
      Serial.print(date[2], DEC);
      Serial.print(":");
      Serial.print(date[1], DEC);
      Serial.print(":");
      Serial.print(date[0], DEC);
      Serial.print("  ");

      Serial.print(date[4], DEC);
      Serial.print("/");
      Serial.print(date[5], DEC);
      Serial.print("/");
      Serial.print(date[6], DEC);
      Serial.print(".");

    Serial.println("");
  }
  else{
    Serial.print("RTC FAIL");
    status = false;
  }
  return status;
}

#ifdef USE_USA_DST
PROGMEM  prog_uint32_t DST[]  = {
//       start,       stop,      // year
     952840800,  973404000,      // 2000
     984290400, 1004853600,      // 2001
    1015740000, 1036303200,      // 2002
    1047189600, 1067752800,      // 2003
    1079244000, 1099807200,      // 2004
    1110693600, 1131256800,      // 2005
    1142143200, 1162706400,      // 2006
    1173592800, 1194156000,      // 2007
    1205042400, 1225605600,      // 2008
    1236492000, 1257055200,      // 2009
    1268546400, 1289109600,      // 2010
    1299996000, 1320559200,      // 2011
    1331445600, 1352008800,      // 2012
    1362895200, 1383458400,      // 2013
    1394344800, 1414908000,      // 2014
    1425794400, 1446357600,      // 2015
    1457848800, 1478412000,      // 2016
    1489298400, 1509861600,      // 2017
    1520748000, 1541311200,      // 2018
    1552197600, 1572760800,      // 2019
    1583647200, 1604210400,      // 2020
    1615701600, 1636264800,      // 2021
    1647151200, 1667714400,      // 2022
    1678600800, 1699164000,      // 2023
    1710050400, 1730613600,      // 2024
    1741500000, 1762063200,      // 2025
    1772949600, 1793512800,      // 2026
    1805004000, 1825567200,      // 2027
    1836453600, 1857016800,      // 2028
    1867903200, 1888466400,      // 2029
    1899352800, 1919916000,      // 2030
    1930802400, 1951365600,      // 2031
    1962856800, 1983420000,      // 2032
    1994306400, 2014869600,      // 2033
    2025756000, 2046319200,      // 2034
    2057205600, 2077768800,      // 2035
    2088655200, 2109218400,      // 2036
    2120104800, 2140668000,      // 2037
    2152159200, 2172722400,      // 2038
    2183608800, 2204172000,      // 2039
    2215058400, 2235621600,      // 2040
    2246508000, 2267071200,      // 2041
    2277957600, 2298520800,      // 2042
    2309407200, 2329970400,      // 2043
    2341461600, 2362024800,      // 2044
    2372911200, 2393474400,      // 2045
    2404360800, 2424924000,      // 2046
    2435810400, 2456373600,      // 2047
    2467260000, 2487823200,      // 2048
    2499314400, 2519877600,      // 2049
    2530764000, 2551327200,      // 2050
    2562213600, 2582776800,      // 2051
    2593663200, 2614226400,      // 2052
    2625112800, 2645676000,      // 2053
    2656562400, 2677125600,      // 2054
    2688616800, 2709180000,      // 2055
    2720066400, 2740629600,      // 2056
    2751516000, 2772079200,      // 2057
    2782965600, 2803528800,      // 2058
    2814415200, 2834978400,      // 2059
    2846469600, 2867032800,      // 2060
    2877919200, 2898482400,      // 2061
    2909368800, 2929932000,      // 2062
    2940818400, 2961381600,      // 2063
    2972268000, 2992831200,      // 2064
    3003717600, 3024280800,      // 2065
    3035772000, 3056335200,      // 2066
    3067221600, 3087784800,      // 2067
    3098671200, 3119234400,      // 2068
    3130120800, 3150684000,      // 2069
    3161570400, 3182133600,      // 2070
    3193020000, 3213583200,      // 2071
    3225074400, 3245637600,      // 2072
    3256524000, 3277087200,      // 2073
    3287973600, 3308536800,      // 2074
    3319423200, 3339986400,      // 2075
    3350872800, 3371436000,      // 2076
    3382927200, 3403490400,      // 2077
    3414376800, 3434940000,      // 2078
    3445826400, 3466389600,      // 2079
    3477276000, 3497839200,      // 2080
    3508725600, 3529288800,      // 2081
    3540175200, 3560738400,      // 2082
    3572229600, 3592792800,      // 2083
    3603679200, 3624242400,      // 2084
    3635128800, 3655692000,      // 2085
    3666578400, 3687141600,      // 2086
    3698028000, 3718591200,      // 2087
    3730082400, 3750645600,      // 2088
    3761532000, 3782095200,      // 2089
    3792981600, 3813544800,      // 2090
    3824431200, 3844994400,      // 2091
    3855880800, 3876444000,      // 2092
    3887330400, 3907893600,      // 2093
    3919384800, 3939948000,      // 2094
    3950834400, 3971397600,      // 2095
    3982284000, 4002847200,      // 2096
    4013733600, 4034296800,      // 2097
    4045183200, 4065746400,      // 2098
    4076632800, 4097196000,      // 2099
};


#endif

#ifdef USE_EURO_DST
PROGMEM  prog_uint32_t DST[]  = {
//    start,       stop,    //
  954050400,  972799200,    // 2000-03-26 01:00:00 -- 2000-10-29 01:00:00
  985500000, 1004248800,    // 2001-03-25 01:00:00 -- 2001-10-28 01:00:00
 1017554400, 1035698400,    // 2002-03-31 01:00:00 -- 2002-10-27 01:00:00
 1049004000, 1067148000,    // 2003-03-30 01:00:00 -- 2003-10-26 01:00:00
 1080453600, 1099202400,    // 2004-03-28 01:00:00 -- 2004-10-31 01:00:00
 1111903200, 1130652000,    // 2005-03-27 01:00:00 -- 2005-10-30 01:00:00
 1143352800, 1162101600,    // 2006-03-26 01:00:00 -- 2006-10-29 01:00:00
 1174798800, 1193547600,    // 2007-03-25 01:00:00 -- 2007-10-28 01:00:00
 1206853200, 1224997200,    // 2008-03-30 01:00:00 -- 2008-10-26 01:00:00
 1238302800, 1256446800,    // 2009-03-29 01:00:00 -- 2009-10-25 01:00:00
 1269752400, 1288501200,    // 2010-03-28 01:00:00 -- 2010-10-31 01:00:00
 1301202000, 1319950800,    // 2011-03-27 01:00:00 -- 2011-10-30 01:00:00
 1332651600, 1351400400,    // 2012-03-25 01:00:00 -- 2012-10-28 01:00:00
 1364706000, 1382850000,    // 2013-03-31 01:00:00 -- 2013-10-27 01:00:00
 1396155600, 1414299600,    // 2014-03-30 01:00:00 -- 2014-10-26 01:00:00
 1427605200, 1445749200,    // 2015-03-29 01:00:00 -- 2015-10-25 01:00:00
 1459054800, 1477803600,    // 2016-03-27 01:00:00 -- 2016-10-30 01:00:00
 1490504400, 1509253200,    // 2017-03-26 01:00:00 -- 2017-10-29 01:00:00
 1521954000, 1540702800,    // 2018-03-25 01:00:00 -- 2018-10-28 01:00:00
 1554008400, 1572152400,    // 2019-03-31 01:00:00 -- 2019-10-27 01:00:00
 1585458000, 1603602000,    // 2020-03-29 01:00:00 -- 2020-10-25 01:00:00
 1616907600, 1635656400,    // 2021-03-28 01:00:00 -- 2021-10-31 01:00:00
 1648357200, 1667106000,    // 2022-03-27 01:00:00 -- 2022-10-30 01:00:00
 1679806800, 1698555600,    // 2023-03-26 01:00:00 -- 2023-10-29 01:00:00
 1711861200, 1730005200,    // 2024-03-31 01:00:00 -- 2024-10-27 01:00:00
 1743310800, 1761454800,    // 2025-03-30 01:00:00 -- 2025-10-26 01:00:00
 1774760400, 1792904400,    // 2026-03-29 01:00:00 -- 2026-10-25 01:00:00
 1806210000, 1824958800,    // 2027-03-28 01:00:00 -- 2027-10-31 01:00:00
 1837659600, 1856408400,    // 2028-03-26 01:00:00 -- 2028-10-29 01:00:00
 1869109200, 1887858000,    // 2029-03-25 01:00:00 -- 2029-10-28 01:00:00
 1901163600, 1919307600,    // 2030-03-31 01:00:00 -- 2030-10-27 01:00:00
 1932613200, 1950757200,    // 2031-03-30 01:00:00 -- 2031-10-26 01:00:00
 1964062800, 1982811600,    // 2032-03-28 01:00:00 -- 2032-10-31 01:00:00
 1995512400, 2014261200,    // 2033-03-27 01:00:00 -- 2033-10-30 01:00:00
 2026962000, 2045710800,    // 2034-03-26 01:00:00 -- 2034-10-29 01:00:00
 2058411600, 2077160400,    // 2035-03-25 01:00:00 -- 2035-10-28 01:00:00
 2090466000, 2108610000,    // 2036-03-30 01:00:00 -- 2036-10-26 01:00:00
 2121915600, 2140059600,    // 2037-03-29 01:00:00 -- 2037-10-25 01:00:00
 2153365200, 2172114000,    // 2038-03-28 01:00:00 -- 2038-10-31 01:00:00
 2184814800, 2203563600,    // 2039-03-27 01:00:00 -- 2039-10-30 01:00:00
 2216264400, 2235013200,    // 2040-03-25 01:00:00 -- 2040-10-28 01:00:00
 2248318800, 2266462800,    // 2041-03-31 01:00:00 -- 2041-10-27 01:00:00
 2279768400, 2297912400,    // 2042-03-30 01:00:00 -- 2042-10-26 01:00:00
 2311218000, 2329362000,    // 2043-03-29 01:00:00 -- 2043-10-25 01:00:00
 2342667600, 2361416400,    // 2044-03-27 01:00:00 -- 2044-10-30 01:00:00
 2374117200, 2392866000,    // 2045-03-26 01:00:00 -- 2045-10-29 01:00:00
 2405566800, 2424315600,    // 2046-03-25 01:00:00 -- 2046-10-28 01:00:00
 2437621200, 2455765200,    // 2047-03-31 01:00:00 -- 2047-10-27 01:00:00
 2469070800, 2487214800,    // 2048-03-29 01:00:00 -- 2048-10-25 01:00:00
 2500520400, 2519269200,    // 2049-03-28 01:00:00 -- 2049-10-31 01:00:00
 2531970000, 2550718800,    // 2050-03-27 01:00:00 -- 2050-10-30 01:00:00
 2563419600, 2582168400,    // 2051-03-26 01:00:00 -- 2051-10-29 01:00:00
 2595474000, 2613618000,    // 2052-03-31 01:00:00 -- 2052-10-27 01:00:00
 2626923600, 2645067600,    // 2053-03-30 01:00:00 -- 2053-10-26 01:00:00
 2658373200, 2676517200,    // 2054-03-29 01:00:00 -- 2054-10-25 01:00:00
 2689822800, 2708571600,    // 2055-03-28 01:00:00 -- 2055-10-31 01:00:00
 2721272400, 2740021200,    // 2056-03-26 01:00:00 -- 2056-10-29 01:00:00
 2752722000, 2771470800,    // 2057-03-25 01:00:00 -- 2057-10-28 01:00:00
 2784776400, 2802920400,    // 2058-03-31 01:00:00 -- 2058-10-27 01:00:00
 2816226000, 2834370000,    // 2059-03-30 01:00:00 -- 2059-10-26 01:00:00
 2847675600, 2866424400,    // 2060-03-28 01:00:00 -- 2060-10-31 01:00:00
 2879125200, 2897874000,    // 2061-03-27 01:00:00 -- 2061-10-30 01:00:00
 2910574800, 2929323600,    // 2062-03-26 01:00:00 -- 2062-10-29 01:00:00
 2942024400, 2960773200,    // 2063-03-25 01:00:00 -- 2063-10-28 01:00:00
 2974078800, 2992222800,    // 2064-03-30 01:00:00 -- 2064-10-26 01:00:00
 3005528400, 3023672400,    // 2065-03-29 01:00:00 -- 2065-10-25 01:00:00
 3036978000, 3055726800,    // 2066-03-28 01:00:00 -- 2066-10-31 01:00:00
 3068427600, 3087176400,    // 2067-03-27 01:00:00 -- 2067-10-30 01:00:00
 3099877200, 3118626000,    // 2068-03-25 01:00:00 -- 2068-10-28 01:00:00
 3131931600, 3150075600,    // 2069-03-31 01:00:00 -- 2069-10-27 01:00:00
 3163381200, 3181525200,    // 2070-03-30 01:00:00 -- 2070-10-26 01:00:00
 3194830800, 3212974800,    // 2071-03-29 01:00:00 -- 2071-10-25 01:00:00
 3226280400, 3245029200,    // 2072-03-27 01:00:00 -- 2072-10-30 01:00:00
 3257730000, 3276478800,    // 2073-03-26 01:00:00 -- 2073-10-29 01:00:00
 3289179600, 3307928400,    // 2074-03-25 01:00:00 -- 2074-10-28 01:00:00
 3321234000, 3339378000,    // 2075-03-31 01:00:00 -- 2075-10-27 01:00:00
 3352683600, 3370827600,    // 2076-03-29 01:00:00 -- 2076-10-25 01:00:00
 3384133200, 3402882000,    // 2077-03-28 01:00:00 -- 2077-10-31 01:00:00
 3415582800, 3434331600,    // 2078-03-27 01:00:00 -- 2078-10-30 01:00:00
 3447032400, 3465781200,    // 2079-03-26 01:00:00 -- 2079-10-29 01:00:00
 3479086800, 3497230800,    // 2080-03-31 01:00:00 -- 2080-10-27 01:00:00
 3510536400, 3528680400,    // 2081-03-30 01:00:00 -- 2081-10-26 01:00:00
 3541986000, 3560130000,    // 2082-03-29 01:00:00 -- 2082-10-25 01:00:00
 3573435600, 3592184400,    // 2083-03-28 01:00:00 -- 2083-10-31 01:00:00
 3604885200, 3623634000,    // 2084-03-26 01:00:00 -- 2084-10-29 01:00:00
 3636334800, 3655083600,    // 2085-03-25 01:00:00 -- 2085-10-28 01:00:00
 3668389200, 3686533200,    // 2086-03-31 01:00:00 -- 2086-10-27 01:00:00
 3699838800, 3717982800,    // 2087-03-30 01:00:00 -- 2087-10-26 01:00:00
 3731288400, 3750037200,    // 2088-03-28 01:00:00 -- 2088-10-31 01:00:00
 3762738000, 3781486800,    // 2089-03-27 01:00:00 -- 2089-10-30 01:00:00
 3794187600, 3812936400,    // 2090-03-26 01:00:00 -- 2090-10-29 01:00:00
 3825637200, 3844386000,    // 2091-03-25 01:00:00 -- 2091-10-28 01:00:00
 3857691600, 3875835600,    // 2092-03-30 01:00:00 -- 2092-10-26 01:00:00
 3889141200, 3907285200,    // 2093-03-29 01:00:00 -- 2093-10-25 01:00:00
 3920590800, 3939339600,    // 2094-03-28 01:00:00 -- 2094-10-31 01:00:00
 3952040400, 3970789200,    // 2095-03-27 01:00:00 -- 2095-10-30 01:00:00
 3983490000, 4002238800,    // 2096-03-25 01:00:00 -- 2096-10-28 01:00:00
 4015544400, 4033688400,    // 2097-03-31 01:00:00 -- 2097-10-27 01:00:00
 4046994000, 4065138000     // 2098-03-30 01:00:00 -- 2098-10-26 01:00:00
};
#endif

bool is_dst(time_t time){
  bool out = false;
#if defined(USE_USA_DST) || defined(USE_EURO_DST)
  int yy = year(time) % 100;
  time_t start = pgm_read_dword_near(DST + 2 * yy);
  time_t stop = pgm_read_dword_near(DST + 2 * yy + 1);
  out = (start < time) && (time < stop);
#endif
  return out;
}
