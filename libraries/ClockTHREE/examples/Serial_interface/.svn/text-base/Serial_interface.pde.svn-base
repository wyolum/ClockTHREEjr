// Messaging constants
const uint8_t MAX_MSG_LEN = 100;
// const uint8_t BAUDRATE = 115200; // official
const uint16_t BAUDRATE = 57600; // max

const uint8_t DBG = 12;
const uint8_t COL_DRIVER_ENABLE = 17;
const uint8_t SYNC_BYTE = 0xEF;

char serial_msg[MAX_MSG_LEN];
uint8_t serial_midxo;
uint8_t serial_msg_len;

void setup(){
  pinMode(DBG, OUTPUT);
  Serial.begin(BAUDRATE);
  for(int i = 0; i < 4; i++){
    digitalWrite(DBG, HIGH);
    delay(50);
    digitalWrite(DBG, LOW);
    delay(50);
  }
  digitalWrite(DBG, HIGH);
}

typedef void (* CallBackPtr)(); // this is a typedef for callback funtions

struct MsgDef{
  uint8_t id;
  uint8_t n_byte; // if n_byte > 100, variable length message
  CallBackPtr cb;
};

void do_nothing(){
}

void ping_cb(){
  for(int i=0; i < 99; i++){
    Serial.print(serial_msg[i],BYTE);
  }
}

char *current_time = "OOOO";
void send_time_cb(){
  for(int i = 0; i < 4; i++){
    Serial.print(current_time[i], BYTE);
  }
}

void set_time_cb(){
  for(int i = 0; i < 4; i++){
    current_time[i] = serial_msg[i];
  }
}


const uint8_t N_MSG_TYPE = 19;
const MsgDef  NOT_USED_MSG = {0x00, 1, do_nothing};
const MsgDef  ABS_TIME_REQ = {0x01, 1, send_time_cb};
const MsgDef  ABS_TIME_SET = {0x02, 5, set_time_cb};
const MsgDef TOD_ALARM_REQ = {0x03, 1, do_nothing};
const MsgDef TOD_ALARM_SET = {0x04, 5, do_nothing};
const MsgDef       MSG_REQ = {0x05, 2, do_nothing};
const MsgDef    SCROLL_MSG = {0x06, 2, do_nothing};
const MsgDef     EVENT_REQ = {0x07, 2, do_nothing};
const MsgDef     EVENT_SET = {0x08, 6, do_nothing};
const MsgDef   DISPLAY_REQ = {0x09, 1, do_nothing};
const MsgDef   DISPLAY_SET = {0x0A, 0x41, do_nothing};
const MsgDef  TRIGGER_MODE = {0x0B, 1, do_nothing};
const MsgDef   TRIGGER_INC = {0x0C, 1, do_nothing};
const MsgDef   TRIGGER_DEC = {0x0D, 1, do_nothing};
const MsgDef   TRIGGER_AUX = {0x0E, 1, do_nothing};
const MsgDef   VERSION_REQ = {0x0F, 1, do_nothing};
const MsgDef     ABOUT_REQ = {0x10, 1, do_nothing};
const MsgDef          PING = {0x11, 100, ping_cb};
const MsgDef          SYNC = {SYNC_BYTE, 2, do_nothing}; // must already be in sync
const MsgDef       MSG_SET = {0x70, 255, do_nothing}; // variable length

const MsgDef *MSG_DEFS[N_MSG_TYPE] = {&NOT_USED_MSG,
				      &ABS_TIME_REQ,
				      &ABS_TIME_SET,
				      &TOD_ALARM_REQ,
				      &TOD_ALARM_SET,
				      &MSG_REQ,
				      &SCROLL_MSG,
				      &EVENT_REQ,
				      &EVENT_SET,
				      &DISPLAY_REQ,
				      &DISPLAY_SET,
				      &TRIGGER_MODE,
				      &TRIGGER_INC,
				      &TRIGGER_DEC,
				      &TRIGGER_AUX,
				      &VERSION_REQ,
				      &ABOUT_REQ,
				      &PING,
				      &MSG_SET};

void sync_wait(){
  // wait for SYNC message;
  uint8_t val;
  uint8_t n = 0;
  digitalWrite(DBG, LOW);
  while(n < SYNC.n_byte){
    if(Serial.available()){
      val = Serial.read();
      if(val == SYNC_BYTE){ // look for other chars
	n++;
      }
      else{
	n = 0;
      }
    }
  }
  digitalWrite(DBG, HIGH);
}

void loop(){
  uint8_t val;
  uint8_t incoming_type_index;
  boolean resync_flag = true;

  if(Serial.available()){
    val = Serial.read();
    // find msg type
    for(uint8_t msg_i = 0; msg_i < N_MSG_TYPE; msg_i++){
      if(MSG_DEFS[msg_i]->id == val){
	incoming_type_index = msg_i;
	if(getMsg(MSG_DEFS[msg_i]->n_byte - 1)){
	  // payload stored in serial_msg: callback time.
	  MSG_DEFS[msg_i]->cb();
	}
	else{
	  // Got a sync message unexpectedly. Get ready for new message.
	  // no callback
	}
	resync_flag = false;
	break;
	// return;
      }
    }
    if(resync_flag){
      sync_wait();
    }
  }
}

boolean getMsg(uint8_t n_byte) {
  int i = 0;
  uint8_t val, next;
  boolean out = true;
  digitalWrite(DBG, LOW);
  while(i < n_byte){
    if(Serial.available()){
      val = Serial.read();
      if (val == SYNC_BYTE){
	next = Serial.peek();
	if(next == SYNC_BYTE){
	  // SYNC MESSAGE RECEIVED!  Next byte is start of new message
	  // abort message
	  out = false;
	  break;
	}
      }
      serial_msg[i++] = val;
    }
  }
  digitalWrite(DBG, HIGH);
  return out;
}
