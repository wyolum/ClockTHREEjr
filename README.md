ClockTHREEjr and supporting libraries
=====================================

Open source, multi-lingual word clock

To program your ClockTHREEjr,

1. download and unzip (or git clone) the files to a local directory (for example `/home/justin/code/ClockTHREEjr/`)
2. set your arduino sketchbook path to the arduino subdirectory of your install path (for example `/home/justin/code/ClockTHREEjr/arduino`) by either 
   * editing your `~/.arduino/preferences.txt` (the `sketchbook.path` variable)
   * selecting from the "File->Preferences" drop down menu item
3. start or restart the Arduino IDE
4. Open `ClockTHREEjr.ino` with the IDE:
   File->Sketchbook->libraries->ClockTHREE->ClockTHREEjr
5. Edit `ClockTHREEjr.ino` for daylight savings time as you desire:
   * The line "`#define USE_USA_DST`" is used to automatically adjust for daylight savings time using American rules.
   * The line "`#define USE_EURO_DST`" is used to automatically adjust for daylight savings time using European rules
   * Comment out both lines if NO daylight savings time should be used.
   * NOTE: at most one of `USE_USA_DST` or `USE_EURO_DST` should be defined at the same time
6. You should select the Duemilanove from the Tools->Boards menu and ATmega328 from Tools->Processor.
7. Upload the new code to the ClockTHREEjr using an FTDI cable.  Please double check the label on the back to ensure you install the cable correctly.  
