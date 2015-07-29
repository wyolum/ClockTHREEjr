/*
  ClockTHREE Test01_LEDTest
  Light LEDs sequentially

  Justin Shaw March 11, 2012
  
  Licenced under Creative Commons Attribution.
  Attribution 3.0 Unported
 */

#include "SPI.h"
#include "Wire.h"

const int     N_ROW = 8;
const int N_RGB_ROW = 0;
const int     N_COL = 16;
const int   N_COLOR = 2;

const unsigned long BAUDRATE = 115200;

const int COL_DRIVER_ENABLE = 17;
const int SPEAKER_PIN = 10;
const int DBG = 16;
const int MODE_PIN = 2;
const int INC_PIN = 3;
const int DEC_PIN = 15;
const int ENTER_PIN = 8;

uint32_t *display = (uint32_t*)calloc(N_COL, sizeof(uint32_t));

uint8_t my_delay;	 
void setup(){
  Serial.begin(BAUDRATE);
  Serial.println("ClockTHREEjr stand alone test.");
  Serial.println("WyoLum, LLC, 2012");
  
  SPI.begin(); // start SPI communications

  pinMode(DBG, OUTPUT);
  pinMode(COL_DRIVER_ENABLE, OUTPUT);


  // set column driver outputs.
  PORTC |= 0b00001000; // Disable col driver
  DDRD |= 0b11110000;

  pinMode(DEC_PIN, INPUT);
  
  ////SET MOSI, SCK Output, all other SPI as input: 
  DDRB |= 0b00101110;
  
  //ENABLE SPI, MASTER, CLOCK RATE fck/4:  
  SPI.transfer(0);
  SPI.transfer(0);
  SPI.transfer(0);
  SPI.transfer(0);
  my_delay = 50;
  
  // turn off speaker;
  pinMode(SPEAKER_PIN, OUTPUT);
  digitalWrite(SPEAKER_PIN, HIGH);

  Wire.begin();
  if(!testRTC()){
    display[0] = 0b10000001;
    display[1] = 0b01000010;
    display[2] = 0b00100100;
    display[3] = 0b00011000;
    display[4] = 0b00100100;
    display[5] = 0b01000010;
    display[6] = 0b10000001;
    while(1){
      refresh(1000);
    }
  }
}

uint32_t count = 0;
uint8_t color_i = 0;
const int hold = 2500;

bool led_value = true;

void rows(){
  setPixel(count % 16, count / 16, led_value);
  refresh(30);
  count++;
  if(count >= 128){
    count = 0;
    refresh(10000 * led_value);
    led_value = !led_value;
  }
}

void cols(){
  setPixel(count % 10, count / 10, led_value);
  refresh(30);
  count++;
  if(count >= 128){
    count = 0;
    refresh(10000 * led_value);
    led_value = !led_value;
  }
}

void loop(){
  // BY ROWS
  for(int row_i=0; row_i < 8; row_i++){
    for(int col_j=0; col_j < 16; col_j++){
      setPixel(col_j, row_i, 1);
      refresh(30);
    }
  }
  // BY ROWS
  for(int row_i=0; row_i < 8; row_i++){
    for(int col_j=0; col_j < 16; col_j++){
      setPixel(col_j, row_i, 0);
      refresh(30);
    }
  }
  // BY COLS
  for(int col_j=0; col_j < 16; col_j++){
    for(int row_i=0; row_i < 8; row_i++){
      setPixel(col_j, row_i, 1);
      refresh(30);
    }
  }
  // BY COLS
  for(int col_j=0; col_j < 16; col_j++){
    for(int row_i=0; row_i < 8; row_i++){
      setPixel(col_j, row_i, 0);
      refresh(30);
    }
  }
}
/********************************************************************************
 * RTC code
 ********************************************************************************/
#define IS_BCD true
#define IS_DEC false
#define IS_BYTES false
const int DS3231_ADDR = 104;

// decimal to binary coded decimal
uint8_t dec2bcd(int dec){
  uint8_t t = dec / 10;
  uint8_t o = dec - t * 10;
  return (t << 4) + o;
}

// binary coded decimal to decimal
int bcd2dec(uint8_t bcd){
  return (((bcd & 0b11110000)>>4)*10 + (bcd & 0b00001111));
}


bool rtc_raw_read(uint8_t addr,
		  uint8_t n_bytes,
		  bool is_bcd,
		  uint8_t *dest){

  bool out = false;
  Wire.beginTransmission(DS3231_ADDR); 
  // Wire.send(addr); 
  Wire.write(addr);
  Wire.endTransmission();
  Wire.requestFrom(DS3231_ADDR, (int)n_bytes); // request n_bytes bytes 
  if(Wire.available()){
    for(uint8_t i = 0; i < n_bytes; i++){
      dest[i] = Wire.read();
      if(is_bcd){ // needs to be converted to dec
	dest[i] = bcd2dec(dest[i]);
      }
    }
    out = true;
  }
  return out;
}

bool testRTC(){
  bool status = true;
  uint8_t date[7];
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
/********************************************************************************
 * END RTC code
 ********************************************************************************/
/********************************************************************************
 * LED Array code
 ********************************************************************************/
void refresh(int n_hold){
  uint8_t col_j;
  
  union Column_t {
    uint32_t dat32; 
    uint8_t dat8[4];
  } Column;
  
  if(display != NULL){
    for(int hold_i = 0; hold_i < n_hold; hold_i++){
      PORTC &= 0b11110111; // Enable col driver
      // for(col_j=0; col_j < N_COL; col_j++){
      col_j = 0;
      _delay(10);
      while (col_j < N_COL){
	// Column.dat32 = RGBW_MASKS[rgb_i] & display[col_j];
	Column.dat32 = display[15 - col_j];
	// transfer column to row drivers
	SPI.transfer(Column.dat8[3]);
	SPI.transfer(Column.dat8[2]);
	SPI.transfer(Column.dat8[1]);
	PORTC |= 0b00001000; // Disable col driver 
	SPI.transfer(Column.dat8[0]);
	PORTB |= 0b00000010; // Start latch pulse 
	PORTB &= 0b11111101; // End latch pulse 

	PORTD = (PORTD & 0b00001111) | (col_j << 4); //only impacts upper 4 bits of PORTD
	PORTC &= 0b11110111; // Enable col driver
	_delay(my_delay);
	col_j++;
      }
      PORTC |= 0b00001000; // Disable col driver
    }
  }
}
void setPixel(uint8_t xpos, uint8_t ypos, uint8_t color){

  if(display != NULL){
    if(ypos < N_ROW && xpos < N_COL){
      if(color == 0){
	// clear pixel
	display[xpos] &= ~((uint32_t)1 << (ypos)); 
      }
      else{
	// set pixel to color
	display[xpos] |= ((uint32_t)1 << (ypos));
      }
    }
  }
}
void _delay(unsigned int n){
  unsigned int delayvar;
  delayvar = 0; 
  while (delayvar <=  n){ 
    asm("nop");  
    delayvar++;
  }
}
/********************************************************************************
 * END array code
 ********************************************************************************/
