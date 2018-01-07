ClockTHREEjr
============

Open source, multi-lingual word clock

To program your ClockTHREEjr, 
1. download and unzip (or git clone) the files to a local directory
   for example, my this is /home/justin/code/ClockTHREEjr/
2. set your arduino sketchbook path to the arduino subdirectory of your install path by either 
    a. editing your ~/.arduino/preferences.txt (the sketchbook.path variable)
    b. selecting from the "File->Preferences" drop down menu item
    for example, my sketchbook path is /home/justin/code/ClockTHREEjr/arduino
3. start or restart the Arduino IDE
4. Open ClockTHREEjr.ino with the IDE
   File->Sketchbook->libraries->ClockTHREE->ClockTHREEjr
5. Edit ClockTHREEjr.ino for dailight savings time as you desire:
   a. The line "#define USE_USA_DST" is used to automatically adjust for daylight savings time using American rules.
   b. The line "#define USE_EURO_DST" is used to automatically adjust for daylight savings time using European rules
   c. Comment out both lines if NO daylight savigs time should be used.
   NOTE: at most one of USE_USA_DST or USE_EURO_DST shoud be defined at the same time
6. You should select the Duemillinove from the Tools->Boards menu.
7. Upload the new code to ClockTHREEjr using an FTDI cable.  Please double check the lable on the back to ensure you install the cable correctly.
