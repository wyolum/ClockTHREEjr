#IGNORE ME## -*- coding: iso-8859-15 -*-

from time import *

text = '''\
ES-IST-VIERTEL--
FUNF-ZWANZIGZEHN
VORNACH-HALBEIR-
EINSZWEIDREIZEIT
VIERFUNFSECHS-- 
SIEBENACHTZWOLF 
ZEHNELFNEUN-UHR 
AMINACHMITTAGS-
MORGENSABENDS---
DER-MITTERNACHTS
PETERSCLOCKTHREE
 YMTUMSALARMCF   
'''.splitlines()

def X(start, stop, n):
    out = []
    for i in range(n):
        out.append(start + i * (stop - start) // n)
    return out

# test
x005 = X(0, 0, 5)
x055 = X(0, 5, 5)
assert len(x005) == 5
assert x005[1] == 0
assert x055[1] == 1

macros = {
    'ES':((0,0), (0,1)),
    'IST':((0,0,0), (3,4,5)), 
    'VIERTEL':(X(0,0,7),X(7,14,7)),
    'FUNF':(X(1,1,4),X(0,4,4)),
    'ZWANZIG':(X(1,1,7),X(5,12,7)),
    'ZEHN':(X(1,1,4),X(12,16,4)),
    'VOR':(X(2,2,3,),X(0,3,3)),
    'NACH':(X(2,2,4),X(3,7,4)),
    'HALB':(X(2,2,4,),X(8,12,4)),
    'EIN':(X(3,3,3),X(0,3,3)),
    'EINS':(X(3,3,4),X(0,4,4)),
    'ZWEI':(X(3,3,4),X(4,8,4)),
    'DREI':(X(3,3,4),X(8,12,4)),
    'VIER':(X(4,4,4),X(0,4,4)),
    'UFUNF':(X(4,4,4),X(4,8,4)),
    'SECHS':(X(4,4,5),X(8,13,5)),
    'SEIBEN':(X(5,5,6),X(0,6,6)),
    'ACHT':(X(5,5,4),X(6,10,4)),
    'ZWOLF':(X(5,5,5),X(10,15,5)),
    'UZEHN':(X(6,6,4),X(0,4,4)),
    'ELF':(X(6,6,3),X(4,7,3)),
    'NEUN':(X(6,6,4),X(7,11,4)),
    'UHR':(X(6,6,3),X(12,15,3)),
    'AM':(X(7,7,2),X(0,2,2)),
    'IN':(X(7,7,2),X(2,4,2)),
    'NACHMITTAG':(X(7,7,10),X(3,13,10)),
    'NACHMITTAGS':(X(7,7,11),X(3,14,11)),
    'MITTAG':(X(7,7,6),X(7,13,6)),
    'MITTAGS':(X(7,7,7),X(7,14,7)),
    'MORGEN':(X(8,8,6),X(0,6,6)),
    'MORGENS':(X(8,8,7),X(0,7,7)),
    'ABEND':(X(8,8,5),X(7,12,5)),
    'ABENDS':(X(8,8,6),X(7,13,6)),
    'DER':(X(9,9,3),X(0,3,3)),
    'MITTER':(X(9,9,6),X(4,10,6)),
    'NACHT':(X(9,9,5),X(10,15,5)),
    'NACHTS':(X(9,9,6),X(10,16,6))
    }
def update_time(clocktwo, refresh=True):
    now_sec = time()
    now_sec = 0
    now = gmtime(now_sec + clocktwo.offset)
    clocktwo.clearall()
    clocktwo.time_str = ''
    clocktwo.set_by_key('ES')
    clocktwo.set_by_key('IST')
    if now.tm_min % 5 > 0:
        clocktwo.set_by_key('I')
    if now.tm_min % 5 > 1:
        clocktwo.set_by_key('II')
    if now.tm_min % 5 > 2:
        clocktwo.set_by_key('III')
    if now.tm_min % 5 > 3:
        clocktwo.set_by_key('IIII')

    if 0 <= now.tm_min and now.tm_min < 5:
        if now.tm_hour != 0:
            clocktwo.set_by_key('UHR')
        h_offset = 0
    elif 5 <= now.tm_min and now.tm_min < 10:
        clocktwo.set_by_key('FUNF')
        clocktwo.set_by_key('NACH')
        clocktwo.set_by_key('UHR')
        h_offset = 0
    elif 10 <= now.tm_min and now.tm_min < 15:
        clocktwo.set_by_key('ZEHN')
        clocktwo.set_by_key('NACH')
        clocktwo.set_by_key('UHR')
        h_offset = 0
    elif 15 <= now.tm_min and now.tm_min < 20:
        clocktwo.set_by_key('VIERTEL')
        clocktwo.set_by_key('NACH')
        clocktwo.set_by_key('UHR')
        h_offset = 0
    elif 20 <= now.tm_min and now.tm_min < 25:
        clocktwo.set_by_key('ZWANZIG')
        clocktwo.set_by_key('NACH')
        clocktwo.set_by_key('UHR')
        h_offset = 0
    elif 25 <= now.tm_min and now.tm_min < 30:
        clocktwo.set_by_key('FUNF')
        clocktwo.set_by_key('VOR')
        clocktwo.set_by_key('HALB')
        h_offset = 1
    elif 30 <= now.tm_min and now.tm_min < 35:
        clocktwo.set_by_key('HALB')
        h_offset = 1
    elif 35 <= now.tm_min and now.tm_min < 40:
        clocktwo.set_by_key('FUNF')
        clocktwo.set_by_key('NACH')
        clocktwo.set_by_key('HALB')
        h_offset = 1
    elif 40 <= now.tm_min and now.tm_min < 45:
        clocktwo.set_by_key('ZWANSIG')
        clocktwo.set_by_key('VOR')
        clocktwo.set_by_key('UHR')
        h_offset = 1
    elif 45 <= now.tm_min and now.tm_min < 50:
        clocktwo.set_by_key('VIERTEL')
        clocktwo.set_by_key('VOR')
        clocktwo.set_by_key('UHR')
        h_offset = 1
    elif 50 <= now.tm_min and now.tm_min < 55:
        clocktwo.set_by_key('ZEHN')
        clocktwo.set_by_key('VOR')
        clocktwo.set_by_key('UHR')
        h_offset = 1
    elif 55 <= now.tm_min and now.tm_min < 60:
        clocktwo.set_by_key('FUNF')
        clocktwo.set_by_key('VOR')
        clocktwo.set_by_key('UHR')
        h_offset = 1
    else:
        raise ValueError('now.tm_min: %s' % now.tm_min)
    hour = (now.tm_hour + h_offset) % 12
    if(hour == 0):
        if now.tm_hour == 0 and now.tm_min < 5:
            pass
        else:
            clocktwo.set_by_key('ZWOLF')
    elif(hour == 1):
        if 25 <= now.tm_min and now.tm_min < 40:
            clocktwo.set_by_key('EINS')
        else:
            clocktwo.set_by_key('EIN')
    elif(hour == 2):
        clocktwo.set_by_key('ZWEI')
    elif(hour == 3):
        clocktwo.set_by_key('DREI')
    elif(hour == 4):
        clocktwo.set_by_key('VIER')
    elif(hour == 5):
        clocktwo.set_by_key('UFUNF')
    elif(hour == 6):
        clocktwo.set_by_key('SECHS')
    elif(hour == 7):
        clocktwo.set_by_key('SEIBEN')
    elif(hour == 8):
        clocktwo.set_by_key('ACHT')
    elif(hour == 9):
        clocktwo.set_by_key('NEUN')
    elif(hour == 10):
        clocktwo.set_by_key('UZEHN')
    elif(hour == 11):
        clocktwo.set_by_key('ELF')

    hour24 = (now.tm_hour) % 24
    if 0 <= hour24 and hour24 < 6:
        if now.tm_min < 5:
            if hour == 0:
                clocktwo.set_by_key('MITTER')
                clocktwo.set_by_key('NACHT')
            else:
                clocktwo.set_by_key('NACHTS')
        else:
            clocktwo.set_by_key('IN')
            clocktwo.set_by_key('DER')
            clocktwo.set_by_key('NACHT')
    elif 6 <= hour24  and hour24 < 12:
        if now.tm_min < 5:
            clocktwo.set_by_key('MORGENS')
        else:
            clocktwo.set_by_key('AM')
            clocktwo.set_by_key('MORGEN')
    elif 12 <= hour24  and hour24 < 13:
        if now.tm_min < 5:
            clocktwo.set_by_key('MITTAGS')
        else:
            clocktwo.set_by_key('AM')
            clocktwo.set_by_key('MITTAG')
    elif 13 <= hour24  and hour24 < 17:
        if now.tm_min < 5:
            clocktwo.set_by_key('NACHMITTAGS')
        else:
            clocktwo.set_by_key('AM')
            clocktwo.set_by_key('NACHMITTAG')
    elif 17 <= hour24  and hour24 < 23:
        if now.tm_min < 5:
            clocktwo.set_by_key('ABENDS')
        else:
            clocktwo.set_by_key('AM')
            clocktwo.set_by_key('ABEND')
    elif 23 <= hour24  and hour24 < 24:
        if now.tm_min < 5:
            clocktwo.set_by_key('NACHTS')
        else:
            clocktwo.set_by_key('IN')
            clocktwo.set_by_key('DER')
            clocktwo.set_by_key('NACHT')
    if refresh:
        clocktwo.refresh()
    # clocktwo.print_screen()
    # r.after(500,update_time)
