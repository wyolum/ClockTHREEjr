import serial
import time
import datetime
import wx
from wx.lib.analogclock import *
import struct

from C3_interface import *

connect('/dev/ttyUSB0')
ping()
print 'ping ok'

time_set()

t = int(round(time.time())) + gmt_offset
alm_time = time.gmtime(t + 5)
is_set = True
ahh = 10
amm = 45
ass = 0
set_tod_alarm(ahh, amm, ass, is_set)
now = time.gmtime(time_req())
print ' my alarm time:', (ahh, amm, ass, is_set)
print 'set alarm time:', get_tod_alarm();
if False:
    now = time.gmtime(time_req())
    print '  now:', fmt_time(now)
    print 'alarm:', fmt_time(time.gmtime(get_next_alarm()))
    trigger_mode()
