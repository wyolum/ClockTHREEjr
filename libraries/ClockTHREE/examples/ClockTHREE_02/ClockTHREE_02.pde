/*
  Delivery ClockTHREE Word Clock App
  Display time 12:12 PM in words using english template
  Supports different modes:
  Normal
  Mode (Mode to switch modes)
  SetTime
  SetAlarm
  SetColor
  Serial

  Multiple persistant alarms are supported.

  Serial interface for interacting with computers supported.

  Justin Shaw Dec 22, 2010
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0

*/

#include <avr/pgmspace.h>
#include <EEPROM.h>
#include <Wire.h>
#include <string.h>
#include "Time.h"
#include "C3Alarms.h"
#include "MsTimer2.h"
#include "ClockTHREE.h"
#include "SPI.h"
// #include "english.h" // only need one language at a time
// #include "german.h"
#include "english_jr.h"
// #include "german_jr.h"
// #include "hungarian.h"

#include "mem_font.h"
#include "rtcBOB.h"
#include "EDL.h"

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

/* 
 * Special offset pointer for HH:MM:SS countdown display.
 */
uint32_t *countdown_display = display + 2;

/*
 * These are for countdown mode.  The display data are changed
 * only when needed to minimized flicker.  In otherwords update
 * hour display when hh != last_hh and so on.
 */
uint8_t last_hh, last_mm, last_ss; 

// active mode pointer
Mode *mode_p;

// MODE Constants
const uint8_t N_MODE = 12;
const uint8_t N_MAIN_MODE = 6;  // main modes are accessable through Mode mode. (sub modes are not).
const uint8_t N_SUB_MODE = 4;

const uint8_t NORMAL_MODE = 0;
const uint8_t SET_TIME_MODE = 1;
const uint8_t SET_COLOR_MODE = 2;
const uint8_t SET_ALARM_MODE = 3;
// const uint8_t SERIAL_MODE = 4;
const uint8_t MODE_MODE = 4;

// Sub Modes (this cannot be accessed though Mode mode selection.)
const uint8_t SECONDS_MODE = 6;
const uint8_t ALARM_MODE = 7;
const uint8_t TEMPERATURE_MODE = 8;
const uint8_t SCROLL_MODE = 9;
const uint8_t COUNTDOWN_MODE = 10;
const uint8_t SER_DISPLAY_MODE = 11;

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

// Begin mode declarations
Mode NormalMode = {NORMAL_MODE, 
		   'N', Normal_setup, Normal_loop, Normal_exit, 
		   Normal_inc, Normal_dec, Normal_mode, do_nothing};
Mode SecondsMode = {SECONDS_MODE, 
		    'S', Seconds_setup, Seconds_loop, Seconds_exit, 
		    Seconds_mode, Seconds_mode, Seconds_mode, Seconds_mode};
Mode AlarmMode = {ALARM_MODE, 
		  'X', Alarm_setup, Alarm_loop, Alarm_exit, 
		  Alarm_mode, Alarm_mode, Alarm_mode, Alarm_mode};
Mode CountdownMode = {COUNTDOWN_MODE, 
		      'X', Countdown_setup, Countdown_loop, do_nothing, 
		      Countdown_exit, Countdown_exit, Countdown_exit, 
		      Countdown_exit};
Mode SerDisplayMode = {SER_DISPLAY_MODE,
		       'X', do_nothing, SerDisplay_loop, do_nothing,
		       return_to_normal,return_to_normal,return_to_normal,
		       return_to_normal};

Mode TemperatureMode = {TEMPERATURE_MODE, 'X', 
			Temperature_setup, Temperature_loop, Temperature_exit, 
			Temperature_inc, Temperature_dec, Temperature_mode,
			Temperature_mode};
Mode ScrollMode = {SCROLL_MODE, 'X', 
		   Scroll_setup, Scroll_loop, Scroll_exit, 
		   Scroll_inc, Scroll_dec, return_to_normal, return_to_normal};
Mode SetTimeMode = {SET_TIME_MODE, 
		    'T', SetTime_setup,SetTime_loop,SetTime_exit,
		    SetTime_inc, SetTime_dec, SetTime_mode, SetTime_enter};
Mode SetColorMode = {SET_COLOR_MODE, 
		     'C', SetColor_setup, SetColor_loop, SetColor_exit, 
		     SetColor_inc, SetColor_dec, SetColor_mode, SetColor_mode};
Mode SetAlarmMode = {SET_ALARM_MODE, 
		     'A', SetAlarm_setup,SetAlarm_loop,SetAlarm_exit,
		     SetAlarm_inc, SetAlarm_dec, SetAlarm_mode, SetAlarm_enter};
//Mode SerialMode = {SERIAL_MODE, 
//		   'P', Serial_setup,Serial_loop,Serial_exit,
//		   Serial_inc,Serial_dec,Serial_mode, do_nothing};
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
char* EEPROM_ERR = "EE";
char* EEPROM_DELETE_ERR = "ED";
const uint8_t N_MSG_TYPE = 25;

// Message types
const MsgDef  NOT_USED_MSG = {0x00, 1, do_nothing};
const MsgDef  ABS_TIME_REQ = {0x01, 1, send_time};
const MsgDef  ABS_TIME_SET = {0x02, 5, Serial_time_set};
const MsgDef TOD_ALARM_REQ = {0x03, 1, tod_alarm_get};
const MsgDef TOD_ALARM_SET = {0x04, 6, tod_alarm_set};
const MsgDef      DATA_REQ = {0x05, 2, send_data};
const MsgDef   DATA_DELETE = {0x06, 2, delete_data};
const MsgDef   SCROLL_DATA = {0x07, 2, scroll_data};
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
const MsgDef  EEPROM_CLEAR = {0x43, MAX_MSG_LEN, eeprom_clear}; // 0x43 = ASCII 'C'
const MsgDef   EEPROM_DUMP = {0x44, 1, eeprom_dump}; // 0x44 = ASCII 'D'
const MsgDef    DID_ALARM_SET = {0x15, 2, set_did_alarm};
const MsgDef NEXT_ALARM_REQ = {0x16, 1, next_alarm_send};
const MsgDef DID_ALARM_DELETE = {0x17, 2, delete_did_alarm};

const MsgDef          SYNC = {SYNC_BYTE, MAX_MSG_LEN, do_nothing}; // must already be in sync
const MsgDef      DATA_SET = {0x70, VAR_LENGTH, receive_data}; // variable length
const MsgDef      ERR_OUT = {0x71, VAR_LENGTH, do_nothing}; // variable length

// array to loop over when new messages arrive.
const MsgDef *MSG_DEFS[N_MSG_TYPE] = {&NOT_USED_MSG,
				      &ABS_TIME_REQ,
				      &ABS_TIME_SET,
				      &TOD_ALARM_REQ,
				      &TOD_ALARM_SET,
				      &DATA_REQ,
				      &DATA_DELETE,
				      &SCROLL_DATA,
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
				      &EEPROM_CLEAR,
				      &PING,
				      &EEPROM_DUMP,
				      &DID_ALARM_SET,
				      &NEXT_ALARM_REQ,
				      &DID_ALARM_DELETE,
				      &DATA_SET};

const uint8_t MAX_ALARM_DID = 63;        // Alarm Data IDs should be less than or equal to this #.
const uint8_t DID_ALARM_LEN = 12;        // Alarm records are twelve bytes long

/* Alarms have a Data ID for EEPROM referencing and an ID for TimeAlarms.h referencing.
 * the TimeAlarms.h reference is stored in the EEPROM record at given byte offset */
const uint8_t ALARM_ID_OFFSET = 11;

/* There can be at most one countdown timer active at at time.  
 * The countdown timer has this DID reserved.
 *
 * When the main timer expires, if a countdown flag is set, a secondary countdown alarm is initated.
 */
const uint8_t COUNTDOWN_TIMER_DID = MAX_ALARM_DID;


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
English faceplate = English();      // Only need one at a time
// German faceplate = German();      
// EnglishJr faceplate = EnglishJr();
// Hungarian faceplate = Hungarian();
// GermanJr faceplate = GermanJr();      

//Font font = Font();                 // Only font at this time.
MemFont font = MemFont();
time_t t;                           // TODO: remove this, not needed (I think)
uint8_t mode_counter;               // Used for selecting mode
uint8_t color_i = 1;                // Default color
unsigned long count = 0;            // Number of interations current mode has been running.
uint16_t YY;                        // current time variables.
uint8_t MM, DD, hh, mm, ss;
uint8_t ahh, amm, ass;              // time of day time (tod) variables.
AlarmId todAlarm;                   // AlarmID for tod alarm
boolean tick = true;                // tick is true whenever a second changes (false when change has been dealt with)
unit_t SetTime_unit = YEAR;         // Part of time being set {YEAR | MONTH | DAY | HOUR | MINUTE}
uint8_t temp_unit = DEG_C;          // Temperature display units {DEG_C | DEC_F}
boolean alarm_set = false;          // Whether or not tod alarm is set.
uint8_t sync_msg_byte_counter = 0;  // How many byte in a row has sync byte been recieved (sync not working as expected)
uint8_t scroll_did = 0;             // When a message is to be scrolled accross screen, this is its data ID.
bool alarm_beeping = false;         // Beeping or Not? when alarm sounds.
time_t countdown_time = 0;          // for countdown alarms.

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

// read persistant alarms.  Kick off TimeAlarms to manage them
void read_did_alarms(){
  int16_t addr;
  uint8_t len;

  for(uint8_t did = 0; did <= MAX_ALARM_DID; did++){
    if(get_did_addr(did, &addr, &len)){
      if(len == DID_ALARM_LEN){
	serial_msg[0] = did;
	set_did_alarm();
      }
    }
  }
  // ck if countdown alarm was interuppted
  if(get_did_addr(COUNTDOWN_TIMER_DID, &addr, &len)){
    time_t t = now();
    did_read(COUNTDOWN_TIMER_DID, serial_msg, &serial_msg_len);
    countdown_time = Serial_to_Time(serial_msg + 2);
    if(countdown_time > t){
      switchmodes(COUNTDOWN_MODE);
    }
    else{
      countdown_time = 0;
    }
  } 
}

// Main setup function
void setup(void){
  Serial.begin(BAUDRATE);

  Wire.begin();
  c3.init();
  
  // TOD_Alarm_Set(todAlarm, hh, mm, ss + 5, alarm_set);
  // Alarm.timerOnce(5, fire_alarm);
  
  mode_p = &NormalMode;
  // mode_p = &SerialMode;

  // ensure mode ids are consistant.
  Modes[NORMAL_MODE] = NormalMode;
  Modes[SET_TIME_MODE] = SetTimeMode;
  Modes[SET_COLOR_MODE] = SetColorMode;
  Modes[SET_ALARM_MODE] = SetAlarmMode;
  //  Modes[SERIAL_MODE] = SerialMode;
  Modes[MODE_MODE] = ModeMode;

  // Sub Modes
  Modes[SECONDS_MODE] = SecondsMode;
  Modes[ALARM_MODE] = AlarmMode;
  Modes[COUNTDOWN_MODE] = CountdownMode;
  Modes[SER_DISPLAY_MODE] = SerDisplayMode;
  Modes[TEMPERATURE_MODE] = TemperatureMode;
  Modes[SCROLL_MODE] = ScrollMode;
  mode_p->setup();

  attachInterrupt(0, mode_interrupt, FALLING); // Does not work on C2
  attachInterrupt(1, inc_interrupt, FALLING);  // Does not work on C2
  c3.setdisplay(display); // 2x actual LED array size for staging data. // required by fade to
  c3.set_column_hold(50);

  MsTimer2::set(1000, tick_interrupt); // 1ms period
  MsTimer2::start();

  // Set Time and Alarms
  setSyncProvider(getTime);      // RTC
  setSyncInterval(60000);      // update every minute (and on boot)
  update_time();
  getRTC_alarm(&ahh, &amm, &ass, &alarm_set);
  TOD_Alarm_Set(todAlarm, ahh, amm, ass, alarm_set);
  read_did_alarms();
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
      Alarm.serviceAlarms();
      // if((alarm_set) && (mm == amm) && (hh == ahh) && (ss == ass)){
      // switchmodes(ALARM_MODE); // should not be needed?
      // }
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
  n_evt = 0;
  if(alarm_beeping){
    beep();
  }
  else{
    c3.nonote();
  }
  mode_p->loop(); // finally call mode_p loop()
  count++;        // counts times mode_p->loop() has run since mode start

}

// Begin Normal Mode Code 
/* 
   Initalize mode.
*/
void Normal_setup(void){
  tick = true;
  if(alarm_set){
    faceplate.display_word(c3, DARK, alarm_off_led);
    faceplate.display_word(c3, MONO, alarm_on_led);
  }
  else{
    faceplate.display_word(c3, DARK, alarm_off_led);
    faceplate.display_word(c3, DARK, alarm_on_led);
  }
}
void Normal_loop(void) {
  if((count == 0 || ss % 6 == 0 || ss % 4 == 0) && tick){
    // minutes hack updates every six seconds 
    faceplate.display_time(YY, MM, DD, hh, mm, ss,
			   c3, getColor(COLORS[color_i]), 16);
    tick = false;
  }
  else{
    tick = true;
    c3.refresh(16);
  }
}
/*
  Get ready for next mode.
*/
void Normal_exit(void) {
}
/*
  Respond to button presses.
*/
void Normal_inc(void) {
  switchmodes(SECONDS_MODE);
}
void Normal_dec(void) {
  switchmodes(TEMPERATURE_MODE);
}
void Normal_mode(void) {
  switchmodes(MODE_MODE);
}

// Sub mode of normal mode ** display seconds
void Seconds_setup(void){
  tick = true;
  if(countdown_time > now()){
    switchmodes(COUNTDOWN_MODE);
  }
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

// Sub mode of normal mode ** scoll message ID stored in first byte of serial_msg scroll_did;
void Scroll_setup(){
  // Display is 2x as large as screen.  Use larger induces to stage display.
  if(serial_msg[0] && did_read(serial_msg[0], serial_msg, &serial_msg_len)){
    // remove header
    for(uint8_t i = 2; i < serial_msg_len; i++){
      serial_msg[i - 2] =  serial_msg[i];
    }
    serial_msg_len -= 2;
    if(serial_msg_len > 0){
      font.getChar(serial_msg[0], getColor(COLORS[color_i]), display + 16);
    }
  }
  else{
    strcpy(serial_msg, "JANK");
    serial_msg_len = strlen("JANK");
    // Scroll_mode();// hit the mode button to exit out of this mode, no mesage to scroll
  }
}
void Scroll_loop(){
  c3.refresh(16);
  if(count % 12 == 0){
    scroll_RGB_left(false);
  }
  if(count % (8 * 12) == 0){
    uint8_t i = (count / (8 * 12));
    if(i < serial_msg_len){
      font.getChar(serial_msg[i], getColor(COLORS[color_i]), display + N_COL - 1);
    }
    else{
      ScrollMode.mode();
    }
  }
}
void Scroll_exit() {
}

void Scroll_inc(){
}
void Scroll_dec(){
}

// Sub mode of normal mode ** display temp
void Temperature_setup(void){
  if(temp_unit == DEG_C){
    faceplate.display_word(c3, MONO, c_led);
  }
  else{
    faceplate.display_word(c3, MONO, f_led);
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
    faceplate.display_word(c3, DARK, f_led);
    faceplate.display_word(c3, MONO, c_led);
  }
  else{
    temp_unit = DEG_F;
    faceplate.display_word(c3, DARK, c_led);
    faceplate.display_word(c3, MONO, f_led);
  }
}
void Temperature_dec(){
  switchmodes(last_mode_id);
}
void Temperature_mode(){
  switchmodes(last_mode_id);
}

// Sub mode of normal mode ** sound the alarm!
void Alarm_setup(void){

  // see if alarm msg is stored in serial_msg
  // two_digits(serial_msg[0]); // DBG
  // c3.refresh(10000); // DBG
  if(0 < serial_msg[0] && serial_msg[0] <= MAX_ALARM_DID && 
     serial_msg_len == DID_ALARM_LEN){ // 0x3F

    if(serial_msg[6]){ // countdown bit field
      time_t t = now();
      switch(serial_msg[6]){
      case(1 << 0): // 10 sec
	countdown_time = t + 10;
	break;
      case(1 << 1): // 1 minute
	countdown_time = t + 1 * SECS_PER_MIN;
	break;
      case(1 << 2): // 5 minute
	countdown_time = t + 5 * SECS_PER_MIN;
	break;
      case(1 << 3): // 1 hour
	countdown_time = t + 1 * SECS_PER_HOUR;
	break;
      case(1 << 4): // 1 day
	countdown_time = t + 1 * SECS_PER_DAY;
	break;
      default:
	countdown_time = 0;
      }
      // set another alarm for when countdown is complete
      serial_msg[6] = 0; // do not countdown
      serial_msg[0] = 0; // do not repeat

      // update alarmtime
      Time_to_Serial(countdown_time, serial_msg + 2);

      did_delete(COUNTDOWN_TIMER_DID); // just in case it already exists (ignore return value)
      serial_msg[0] = COUNTDOWN_TIMER_DID;
      if(!did_write(serial_msg)){
	two_letters("CD"); // Countdown Error
	c3.refresh(2000);
      }
      else{
	serial_msg[0] = COUNTDOWN_TIMER_DID;
	set_did_alarm();
	switchmodes(COUNTDOWN_MODE);
      }
    }
    else{
      if(serial_msg[10] > 0){
	alarm_beeping = true;
      }
      if(0 < serial_msg[8] && serial_msg[8] < 255){ // valid scroll_did
	serial_msg[0] = serial_msg[8];
	serial_msg_len = 1;
	switchmodes(SCROLL_MODE);
      }
    }
  }
  else{
    two_letters("XX");
    alarm_beeping = true;
  }
}
void beep(){
  if(alarm_beeping){
    if((count % (6 * 24) < (3 * 24)) && (count % 12) < 6){
      c3.note(880);
    }
    else{
      c3.nonote();
    }
  }
}
void Alarm_loop(){
  c3.refresh(16);
  // actual beeping done through main loop()
  // just need to keep display going.
}
void Alarm_exit(void) {
  // resync with RTC and start ticking again
  getTime();

  MsTimer2::set(1000, tick_interrupt); // 1ms period
  MsTimer2::start();
}
void Alarm_mode(){
  alarm_beeping = false;
  switchmodes(NORMAL_MODE);
}

// Sub mode of alarm submode ** display countdown
void Countdown_setup(void){
  // explicit clearing of super large display
  for(int i=0; i < N_DISPLAY * N_COL; i++){
    countdown_display[i] = 0;
  }
}
void Countdown_loop_old(){
  time_t t = now();
  if(countdown_time > t){
    two_digits(countdown_time - t);
    c3.refresh(16);
  }
  else{
    switchmodes(NORMAL_MODE);
  }
}
void Countdown_exit(){
  switchmodes(NORMAL_MODE);
  last_hh = last_mm = last_ss = 0;
}

void Countdown_loop(){
  time_t t = now();
  uint8_t hh, mm, ss;
  uint32_t *save_display = display;
  int p;
  double rate = .006666;

  if(countdown_time > t){
    hh = hour(countdown_time - t);
    mm = minute(countdown_time - t);
    ss = second(countdown_time - t);
    if(hh != last_hh){
      two_digits(hh, countdown_display);
      two_digits(mm, countdown_display + 17);
    }
    else if(mm != last_mm){
      two_digits(mm, countdown_display + 17);
    }
    else if(ss != last_ss){
      two_digits(ss, countdown_display + 34);
      add_char(':', countdown_display, 14);
      add_char(':', countdown_display, 31);
    }
    last_hh = hh;
    last_mm = mm;
    last_ss = ss;

    if(hh > 0){
      // p = (int)(16 - 18.9 * cos(count * 3.14159 / 180));
      p = (int)(18 - 17.9 * cos(count * rate));
    }
    else if(mm > 0){
      // p = (int)(25 - 18.9 / 2 * cos(count * 3.14159 / 180));
      p = (int)(27 - 17.9 / 2 * cos(count * rate));
    }
    else{
      p = 35;
    }
    c3.setdisplay(countdown_display + p);
    c3.refresh(16);
  }
  else{
    switchmodes(NORMAL_MODE);
  }
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
    two_digits(YY % 100);
    faceplate.display_word(c3, MONO, year_led);
    break;
  case MONTH:
    two_digits(MM);
    faceplate.display_word(c3, MONO, month_led);
    break;
  case DAY:
    two_digits(DD);
    faceplate.display_word(c3, MONO, day_led);
    break;
  case HOUR:
    two_digits(hh);
    faceplate.display_word(c3, MONO, hour_led);
    break;
  case MINUTE:
    two_digits(mm);
    faceplate.display_word(c3, MONO, minute_led);
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
// Begin SetAlarm Mode Code 
/* 
   Initalize mode.
*/
void SetAlarm_setup(void){
  faceplate.display_word(c3, MONO, alarm);
  faceplate.display_time(YY, MM, DD, ahh, amm, ass,
			 c3, getColor(COLORS[color_i]), 0, false, false);
  faceplate.display_word(c3, MONO, hour_led);
  SetTime_unit = HOUR;
    if(alarm_set){
      faceplate.display_word(c3, DARK, alarm_off_led);
      faceplate.display_word(c3, MONO, alarm_on_led);
    }
    else{
      faceplate.display_word(c3, DARK, alarm_on_led);
      faceplate.display_word(c3, MONO, alarm_off_led);
    }
}
void SetAlarm_loop(void){
  c3.refresh(16);
}
/*
  Get ready for next mode.
*/
void SetAlarm_exit(void){
  setRTC_alarm(ahh, amm, ass, alarm_set);
  TOD_Alarm_Set(todAlarm, ahh, amm, ass, alarm_set);
}
/*
  Respond to button presses.
*/
void SetAlarm_inc(void){
  switch(SetTime_unit){
  case HOUR:
    ahh = (ahh + 1) % 24;
    faceplate.display_time(YY, MM, DD, ahh, amm, ass,
			   c3, getColor(COLORS[color_i]), 0, false, false);
    break;
  case MINUTE:
    amm = (amm + 5) % 60;
    ass = 0;
    faceplate.display_time(YY, MM, DD, ahh, amm, ass,
			   c3, getColor(COLORS[color_i]), 0, false, false);
    break;
  case SECOND:
    if(!alarm_set){
      alarm_set = true;
      faceplate.display_word(c3, DARK, alarm_off_led);
      faceplate.display_word(c3, MONO, alarm_on_led);
    }
    else{
      alarm_set = false;
      faceplate.display_word(c3, DARK, alarm_on_led);
      faceplate.display_word(c3, MONO, alarm_off_led);
    }
    break;
  default:
    switchmodes(last_mode_id); // Error?! get out of here.
  }
}

void SetAlarm_dec(void){
  switch(SetTime_unit){
  case HOUR:
    if(ahh == 0){
      ahh = 23; // uint cannot go neg
    }
    else{
      ahh--;
    }
    faceplate.display_time(YY, MM, DD, ahh, amm, ass,
			   c3, getColor(COLORS[color_i]), 0, false, false);
    break;
  case MINUTE:
    if(amm < 5){
      amm = 55; // uint cannot go neg
    }
    else{
      amm -= 5;
    }
    ass = 0;
    faceplate.display_time(YY, MM, DD, ahh, amm, ass,
			   c3, getColor(COLORS[color_i]), 0, false, false);
    break;
  case SECOND:
    if(!alarm_set){
      alarm_set = true;
      faceplate.display_word(c3, DARK, alarm_off_led);
      faceplate.display_word(c3, MONO, alarm_on_led);
    }
    else{
      alarm_set = false;
      faceplate.display_word(c3, DARK, alarm_on_led);
      faceplate.display_word(c3, MONO, alarm_off_led);
    }
    break;
  default:
    switchmodes(last_mode_id); // Error?! get out of here.
  }
}
void SetAlarm_mode(void){
  switch(SetTime_unit){
  case HOUR:
    SetTime_unit = MINUTE;
    faceplate.display_word(c3, DARK, hour_led);
    faceplate.display_word(c3, MONO, minute_led);
    break;
  case MINUTE:
    SetTime_unit = SECOND;
    c3.clear();
    if(alarm_set){
      faceplate.display_word(c3, MONO, alarm_on_led);
    }
    else{
      faceplate.display_word(c3, MONO, alarm_off_led);
    }
    break;
  case SECOND:
    SetAlarm_setup();
  }
}
void SetAlarm_enter(void){
  switchmodes(NORMAL_MODE);
}
// Begin SetColor Mode Code 
/* 
   Initalize mode.
*/
void SetColor_setup(void) {
}
void SetColor_loop(void) {
  if(color_i == DARK){
    c3.displayfill(DARK);
    c3.moveto(        0,         0);
    c3.lineto(N_COL - 1,         0, MONO);
    c3.lineto(N_COL - 1, N_ROW - 1, MONO);
    c3.lineto(        0, N_ROW - 1, MONO);
    c3.lineto(        0,         0, MONO);
  }
  else{
    c3.clear();
    font.getChar('0' + color_i, getColor(COLORS[color_i]), display + 5);
  }
  c3.refresh(16);
}
/*
  Get ready for next mode.
*/
void SetColor_exit(void) {
}
/*
  Respond to button presses.
*/
void SetColor_inc(void) {
  color_i++;
  color_i %= N_COLOR; // DARK=OFF
}

void SetColor_dec(void) {
  if(color_i == 0){
    color_i = N_COLOR - 1;// DARK=OFF
  }
  else{
    color_i--;
  }
}

void SetColor_mode(void) {
  switchmodes(NORMAL_MODE);
}

// Begin Serial Modes
/* 
   Initalize mode.
*/
void Serial_setup(void){
  faceplate.display_word(c3, MONO, usb_led);
  c3.refresh();
  for(uint8_t i = 0; i < 4; i++){
    digitalWrite(DBG, HIGH);
    delay(50);
    digitalWrite(DBG, LOW);
    delay(50);
  }
  digitalWrite(DBG, LOW);
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
void tod_alarm_set(){
  tmElements_t tm;
  breakTime(Serial_to_Time(serial_msg), tm);
  /* // old way
  Serial_time_t data;
  for(uint8_t i = 0; i < 4; i++){
    data.dat8[i] = serial_msg[i];
  }
  breakTime(data.dat32, tm);
  */
  ahh = tm.Hour;
  amm = tm.Minute;
  ass = tm.Second;
  alarm_set = serial_msg[4];

  TOD_Alarm_Set(todAlarm, ahh, amm, ass, alarm_set);
  setRTC_alarm(ahh, amm, ass, alarm_set);
}

void tod_alarm_get(){
  tmElements_t tm;

  tm.Hour = ahh;
  tm.Minute = amm;
  tm.Second = ass;
  tm.Year = 1;
  tm.Month = 1;
  tm.Day = 1;

  // Serial.print(TOD_ALARM_SET.id, BYTE);
  Serial.write(TOD_ALARM_SET.id);
  Time_to_Serial(makeTime(tm) % SECS_PER_DAY, serial_msg);
  serial_msg_len = 4;
  for(uint8_t i = 0; i < 4; i++){
    // Serial.print(serial_msg[i], BYTE);
    Serial.write(serial_msg[i]);
  }
  /* // old way
  Serial_time_t data;
  for(uint8_t i = 0; i < 4; i++){
    Serial.print(data.dat8[i], BYTE);
  }
  data.dat32 = makeTime(tm);
  data.dat32 %= 86400;
  */
  // Serial.print(alarm_set, BYTE);
  Serial.write(alarm_set);
}

void eeprom_dump(){
  for(uint16_t i = 0; i <= MAX_EEPROM_ADDR; i++){
    // Serial.print(EEPROM.read(i), BYTE);
    Serial.write(EEPROM.read(i));
  }
}

void next_alarm_send(){
  Time_to_Serial(Alarm.nextTrigger, serial_msg);
  serial_msg_len = 4;
  // Serial.print(ABS_TIME_SET.id, BYTE);
  Serial.write(ABS_TIME_SET.id);
  for(uint8_t i = 0; i < 4; i++){
    // Serial.print(serial_msg[i], BYTE);
    Serial.write(serial_msg[i]);
  }
  // new way (not implimented but could save a little space)
  /*
    serial_msg_len = 5;
    serial_msg[0] = ABS_TIME_SET.id;
    Time_to_Serial(Alarm.nextTrigger, serial_msg + 1);
    xmit_serial_msg();
   */
}
void set_did_alarm(){
  tmElements_t tm;
  uint8_t len;
  bool status = false;
  uint8_t did;
  AlarmID_t aid;
  // did stored in serial_msg[0] (MID pealed off already)
  // record stored in eeprom
  did = serial_msg[0];

  if(0 < did && did <= MAX_ALARM_DID){
    if(did_read(did, serial_msg, &serial_msg_len)) {
      time_t t = Serial_to_Time(serial_msg + 2);
      /* // old way
       Serial_time_t data;

      for(uint8_t i = 2; i < 6; i++){
	data.dat8[i - 2] = serial_msg[i];
      }
      t = data.dat32;
      */
      // countdown bits: MSb     -->                  LSb
      // blank, blank, blank, day, hour, 5min, min, 10sec, 
      uint8_t countdown = serial_msg[6];
      uint8_t repeat = serial_msg[7];
      bool stale = ((t < now()) && (repeat == 0));
      if(stale){
	did_delete(did);
	status = true;
      }
      else{ // fresh
	aid = Alarm.create(t,                          // time 
			   fire_alarm,                 // callback
			   true,                       // alarm_f (true for c3)
			   countdown,                  // countdown_flags
			   repeat,                     // repeat_flags      
			   did);                       // arg=alarm_did

	// update alarm_id in EEPROM.
	if(!did_edit(did, ALARM_ID_OFFSET, aid)){
	  Serial.end();
	  two_digits(did);
	  c3.refresh(2000);
	  two_letters("EA"); // Edit Alarm DID failed
	  c3.refresh(2000);
	  status = false;
	}
	else if(aid != dtINVALID_ALARM_ID){
	  status = true;
	}
      }
    }
  }
  if(!status){
    // error
    Serial.end();
    two_letters("AL");
    c3.refresh(2000);
  }
}

void delete_did_alarm(){
  bool status = false;
  uint8_t did;
  AlarmID_t aid;
  // did stored in serial_msg[0] (MID pealed off already)
  // record stored in eeprom
  did = serial_msg[0];
  if(0 < did && did <= MAX_ALARM_DID){
    if(did_read(did, serial_msg, &serial_msg_len)){
      if(serial_msg_len == DID_ALARM_LEN){
	// grab aid
	aid = serial_msg[ALARM_ID_OFFSET];
	Alarm.free(aid);
	if(did_delete(did)){
	  status = true;
	}
      }
    }
  }
  if(!status){
    // error
    two_letters(EEPROM_ERR);
    c3.refresh(10000);
    Serial_send_err("AL");
  }
}
void receive_data(){
  int16_t tmp_addr;
  uint8_t tmp_l;

  if(!did_write(serial_msg + 1)){
    Serial_send_err(EEPROM_ERR);
  }
}

void delete_data(){
  uint8_t did = serial_msg[0];
  if(!did_delete(did)){
    Serial_send_err(EEPROM_DELETE_ERR);
  }
}

void scroll_data(){
  // scroll_did stored in serial_msg[0], just kick off Scroll Mode.
  switchmodes(SCROLL_MODE);
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

void send_data(){

  uint8_t did = serial_msg[0];
  uint8_t n_byte;

  if(did_read(did, serial_msg, &n_byte)){
    // Serial.print(DATA_SET.id, BYTE);
    //Serial.print(n_byte + 2, BYTE);
    Serial.write(DATA_SET.id);
    Serial.write(n_byte + 2);
    for(uint8_t i=0; i < n_byte; i++){
      Serial.print(serial_msg[i]);
    }
  }
  else{
    Serial_send_err(EEPROM_ERR);
  }
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
  uint8_t did = serial_msg[0];
  if(mode_p->id != SER_DISPLAY_MODE){
    switchmodes(SER_DISPLAY_MODE);
  }
  uint8_t *display_p = (uint8_t *)display;
  for(uint8_t i = 0; i < N_COL * sizeof(uint32_t); i++){
    display_p[i] = serial_msg[i];
  }
}

void eeprom_clear(){
  bool confirmed = true;					

  // make sure entire message is filled with EEPROM_CLEAR bytes.
  for(uint8_t i = 0; i < EEPROM_CLEAR.n_byte - 1; i++){
    if(serial_msg[i] != EEPROM_CLEAR.id){
      confirmed = false;
      break;
    }
  }
  // do the deed
  if(confirmed){
    for(uint16_t i = 0; i <= MAX_EEPROM_ADDR; i++){
      EEPROM.write(i, 0);
    }
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
  font.getChar('M', BLUE, display);
  mode_counter = 1;
  font.getChar(Modes[mode_counter].sym, BLUE, display + 8);
}
void Mode_loop(void) {
  c3.refresh(16);
}
void Mode_exit(void) {
}
void Mode_inc(void) {
  mode_counter++;
  mode_counter %= N_MAIN_MODE - 1; // skip ModeMode
  font.getChar(Modes[mode_counter].sym, BLUE, display + 8);
}
void Mode_dec(void) {
  if(mode_counter == 0){
    mode_counter = N_MAIN_MODE - 2;// skip ModeMode
  }
  else{
    mode_counter--;
  }
  font.getChar(Modes[mode_counter].sym, BLUE, display + 8);
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
void fire_alarm(uint8_t did){
  // read in record at DID and switch to alarm mode

  /* if did is 0, just switch to alarm mode
   * otherwise -- look up record at did and switch
   */

  if(0 < did && did < 255){
    if(!did_read(did, serial_msg, &serial_msg_len)){
      two_letters(EEPROM_ERR);
      c3.refresh(10000);
    }
  }
  switchmodes(ALARM_MODE);
}

void two_digits(uint8_t val){
  font.getChar('0' + val / 10, getColor(COLORS[color_i]), display + 2);
  font.getChar('0' + val % 10, getColor(COLORS[color_i]), display + 9);
}

void two_digits(uint8_t val, uint32_t *display){
  font.getChar('0' + val / 10, getColor(COLORS[color_i]), display + 2);
  font.getChar('0' + val % 10, getColor(COLORS[color_i]), display + 9);
}

/*
 * Add a letter without erasing existing pixels
 */
void add_char(char letter, uint32_t* display, uint8_t col){
  uint32_t data[8];
  font.getChar(letter, getColor(COLORS[color_i]), data);
  for(uint8_t i = 0; i < 7; i++){
    display[col + i] |= (data[i] & 0b00000000111111111111111111111111);
  }
}
void two_letters(char* letters){
  font.getChar(letters[0], getColor(COLORS[color_i]), display + 2);
  font.getChar(letters[1], getColor(COLORS[color_i]), display + 9);
}

void TOD_Alarm_Set(AlarmId id, uint8_t ahh, uint8_t amm, uint8_t ass, boolean alarm_set){
  Alarm.free(todAlarm);
  todAlarm = Alarm.alarmRepeat(ahh, amm, ass, fire_alarm);
  if(alarm_set){
    Alarm.enable(todAlarm);
  }
  else{
    Alarm.disable(todAlarm);
  }
}

void copy_RGB(uint32_t *frm, uint32_t *to){
  uint32_t mask = RGBW_MASKS[3];
  *to = (*to & (~mask)) | (*frm & mask);
}

void scroll_RGB_left(bool wrap_f){
  // display array is 2x as large as screen
  uint32_t tmp = display[0];
  for(uint8_t i = 0; i < 2 * N_COL - 1; i++){
    copy_RGB(&display[i + 1], &display[i]);
  }
  if(wrap_f){
    copy_RGB(&tmp, &display[2 * N_COL - 1]);
  }
}

void scroll_RGB_right(bool wrap_f){
  // display array is 2x as large as screen
  uint32_t tmp = display[2 * N_COL - 1];
  for(uint8_t i = 2 * N_COL - 1; i > 0; i--){
    copy_RGB(&display[i - 1], &display[i]);
  }
  if(wrap_f){
    copy_RGB(&tmp, &display[0]);
  }
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
