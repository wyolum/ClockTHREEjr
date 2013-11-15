from __future__ import print_function
import sys
import glob
import serial
import time
import datetime
import struct
import os

MAX_ALARM_DID = chr(0x3F)
DID_ALARM_LEN = 12
SER_TIMEOUT = .1 # Serial timeout, seconds
eeprom = None

class EEPROMError(Exception):
    pass

class MsgDef:
    def __init__(self, v, const):
        v = v.strip()
        v = v[1:-1]
        val, msg_size, callback = v.split(',')
        msg_size = msg_size.strip()
        if 'x' in val:
            self.val = int(val, 16)
        else:
            if val not in const:
                raise Exception('Unknown constant %s' % val)
            self.val = const[val]
        try:
            self.n_byte = int(msg_size)
        except:
            try:
                self.n_byte = const[msg_size]
            except:
                raise
        self.callback = callback
    def __str__(self):
        return chr(self.val)

def read_constants(fn):
    f = open(fn)
    out = {}
    for line in f.readlines():
        if line.startswith('const'):
            line = line.split(';')[0]
            try:
                d, v = line.split('=')
                c, t, n = d.split()
                if 'int' in t:
                    if 'X' in v.upper():
                        base = 16
                    else:
                        base = 10
                        out[n] = int(v, base)
                elif t == 'MsgDef':
                    try:
                        out[n] = MsgDef(v, out)
                    except Exception, e:
                        if '*' not in line:
                            print('problem with ', line, e)
                else:
                    out[n] = v
            except:
                pass
    return out
            
class Struct:
    def __init__(self, **dict):
        self.d = dict
    def __getattr__(self, name):
        return self.d[name]
    def __add__(self, other):
        out = {}
        for key in self.d:
            out[key] = self.d[key]
        for key in other.d:
            out[key] = other.d[key]
        return Struct(**out)

const = {'MAX_EEPROM_ADDR':1023}
c_files = glob.glob("*.ino")
c_files.extend(glob.glob("*.h"))
for file in c_files:
    next = read_constants(file)
    for key in next:
        # print '%s = %s' % (key, next[key])
        const[key] = next[key]
const = Struct(**const)
def set_gmt_offset(offset):
    global gmt_offset
    gmt_offset = offset

def getSerialports():
    if sys.platform.startswith('win'): # windows
        out = []
        import scanwin32
        for order, port, desc, hwid in sorted(scanwin32.comports()):
            print( "%-10s: %s (%s) ->" % (port, desc, hwid),)
            try:
                s = serial.Serial(port) # test open
                s.close()
            except serial.serialutil.SerialException:
                print( "can't be opened")
            else:
                print("Ready")
                out.append(port)
    elif sys.platform.startswith('darwin'): # mac
        out = glob.glob('/dev/tty.usb*')
        out.sort()
    else: # assume linux 
        out = glob.glob('/dev/ttyUSB*')
        out.sort()
    return out

# def connect(serialport='/dev/ttyUSB0', _gmt_offset=None):
def connect(serialport='/dev/ttyUSB0', _gmt_offset=None):
    if _gmt_offset is None:
        local_time = time.localtime()
        _gmt_offset = (local_time.tm_isdst * 3600 - time.timezone)
    global ser
    set_gmt_offset(_gmt_offset)

    try:
        ser.close() # need to close serial port on windows.
    except:
        pass
        
    # raw_input('...')
    print( 'serialport', serialport)
    ser = serial.Serial(serialport,
                        baudrate=112500,
                        timeout=SER_TIMEOUT)
    return ser
        

gmt_offset = -7 * 3600
def flush():
    dat = ser.read(1000)
    while len(dat) > 0:
        dat = ser.read(1000)

def time_req():
    # flush serial data
    flush()
    ser.write(str(const.ABS_TIME_REQ))
    id = ser.read(1)
    assert id == str(const.ABS_TIME_SET)
    dat = ser.read(4)
    if len(dat) < 4:
        out = 0
    else:
        out = c3_to_wall_clock(dat)
    return out

def time_set(now=None):
    flush()
    if now is None:
        now = int(round(time.time()) + gmt_offset)
    # now = time.mktime(time.localtime())
    dat = wall_clock_to_c3(now)
    ser.write(str(const.ABS_TIME_SET))
    ser.write(dat)
    
def c3_to_wall_clock(bytes):
    return struct.unpack('<I', bytes)[0]

def wall_clock_to_c3(t):
    return struct.pack('<I', int(round(t)))

def to_gmt(t):
    return t + gmt_offset

def from_gmt(t):
    return t - gmt_offset

def fmt_time(when):
    return '%02d/%02d/%04d %d:%02d:%02d' % (when.tm_mday, when.tm_mon, when.tm_year,
                                            when.tm_hour, when.tm_min, when.tm_sec)
def main():
    ser.flush()
    now = time_req()

    now = time.gmtime(time_req())
    year = now.tm_year
    print('year', year)

    time_set()
    print (time_req())

if __name__ == '__main__':
    connect(getSerialports()[0])
    if len(sys.argv) > 1:
        for arg in sys.argv[1:]:
            if arg == 'set':
                time_set()
                print ('      P2 time',  fmt_time(time.gmtime(time_req())))
            elif arg == 'time':
                print ('      P2 time',  fmt_time(time.gmtime(time_req())))
            elif arg == 'pc_time':
                print ('     PC TIME:', fmt_time(time.gmtime(to_gmt(time.time()))))
            else:
                print ('huh?', arg)
        else:
            # read_write_test()
            main()
