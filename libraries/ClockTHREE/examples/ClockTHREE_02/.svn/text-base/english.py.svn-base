from time import *

text = ("ITSXATENRQUARTER "
        "TWENTYFIVEDPASTO "
        "TWELVETWONESEVEN "
        "FOURFIVESIXTHREE "
        "EIGHTENINELEVEN- "
        "BEERCHAIOCLOCKM- "
        "THIRTYUINITHEAT- "
        "MIDNIGHTEVENING- "
        "IXICLOCKTHREE78- "
        "MORNINGAFTERNOON "
        "THANKVIWEMNEED17 "
        "YMDYMSALARMTCFAN ").split()

macros = {'ITS':((0,0,0),(0,1,2)),
          'A':((0,),(4,)),
          'MTEN':((0,0,0),(5,6,7)),
          'QUARTER':((0,0,0,0,0,0,0),(9,10,11,12,13,14,15)),
          'TWENTY':((1,1,1,1,1,1),(0,1,2,3,4,5)),
          'MFIVE':((1,1,1,1),(6,7,8,9)),
          'PAST':((1,1,1,1),(11,12,13,14)),
          'TO':((1,1),(14,15)),
          'TWELVE':((2,2,2,2,2,2),(0,1,2,3,4,5)),
          'TWO':((2,2,2),(6,7,8)),
          'ONE':((2,2,2),(8,9,10)),
          'SEVEN':((2,2,2,2,2),(11,12,13,14,15)),
          'FOUR':((3,3,3,3),(0,1,2,3)),
          'HFIVE':((3,3,3,3),(4,5,6,7)),
          'SIX':((3,3,3),(8,9,10)),
          'THREE':((3,3,3,3,3),(11,12,13,14,15)),
          'EIGHT':((4,4,4,4,4),(0,1,2,3,4)),
          'HTEN':((4,4,4),(4,5,6)),
          'NINE':((4,4,4,4),(6,7,8,9)),
          'ELEVEN':((4,4,4,4,4,4),(9,10,11,12,13,14)),
          'I':((4,),(15,)),
          'BEER':((5,5,5,5),(0,1,2,3)),
          'CHAI':((5,5,5,5),(4,5,6,7)),
          'OCLOCK':((5,5,5,5,5,5),(8,9,10,11,12,13)),
          'II':((5,),(15,)),
          'THIRTY':((6,6,6,6,6,6),(0,1,2,3,4,5)),
          'IN':((6,6,),(7,8)),
          'IN THE':((6,6,6,6,6),(7,8,10,11,12)),
          'THE':((6,6,6),(10,11,12)),
          'AT':((6,6),(13,14)),
          'III':((6,),(15,)),
          'MIDNIGHT':((7,7,7,7,7,7,7,7),(0,1,2,3,4,5,6,7)),
          'NIGHT':((7,7,7,7,7),(3,4,5,6,7)),
          'EVENING':((7,7,7,7,7,7,7,7),(8,9,10,11,12,13,14)),
          'IIII':((7,),(15,)),
          'MORNING':((9,9,9,9,9,9,9),(0,1,2,3,4,5,6)),
          'AFTERNOON':((9,9,9,9,9,9,9,9,9),(7,8,9,10,11,12,13,14,15)),
          'AFTER':((8,8,8,8),(7,8,9,10,11)),
          'NOON':((8,8,8,8),(12,13,14,15)),
          'CLOCKTWO':((8,8,8,8,8,8,8,8,8,8),(3,4,5,6,7,8,9,10,11,12)),
          'WE':((10,10), (7, 8)),
          'NEED':((10,10,10,10),(10,11,12,13)),
          'YOUR':((11,11,11,11),(0,1,2,3)),
          'SUPPORT':((11,11,11,11,11,11,11),(5,6,7,8,9,10,11)),
          '!!':((11,11),(12,13)),
          'THANK':((10,10,10,10,10),(0,1,2,3,4)),
          'YOU!':((11,11,11,11),(0,1,2,4)),
          }

def update_time(clocktwo, refresh=True):
    now_sec = time()
    now = gmtime(now_sec + clocktwo.offset)
    clocktwo.clearall()
    clocktwo.set_by_key('ITS')
    if False:#todo delete me!!!
        clocktwo.set_by_key('BEER')
        clocktwo.set_by_key('THIRTY')
        if refresh:
            clocktwo.refresh()
        return
    if True: # minutes hack
        if now.tm_min % 5 > 0:
            clocktwo.set_by_key('I')
        if now.tm_min % 5 > 1:
            clocktwo.set_by_key('II')
        if now.tm_min % 5 > 2:
            clocktwo.set_by_key('III')
        if now.tm_min % 5 > 3:
            clocktwo.set_by_key('IIII')

    if 0 <= now.tm_min and now.tm_min < 5:
        clocktwo.set_by_key('OCLOCK')
        h_offset = 0
    elif 5 <= now.tm_min and now.tm_min < 10:
        clocktwo.set_by_key('MFIVE')
        clocktwo.set_by_key('PAST')
        h_offset = 0
    elif 10 <= now.tm_min and now.tm_min < 15:
        clocktwo.set_by_key('MTEN')
        clocktwo.set_by_key('PAST')
        h_offset = 0
    elif 15 <= now.tm_min and now.tm_min < 20:
        clocktwo.set_by_key('A')
        clocktwo.set_by_key('QUARTER')
        clocktwo.set_by_key('PAST')
        h_offset = 0
    elif 20 <= now.tm_min and now.tm_min < 25:
        clocktwo.set_by_key('TWENTY')
        clocktwo.set_by_key('PAST')
        h_offset = 0
    elif 25 <= now.tm_min and now.tm_min < 30:
        clocktwo.set_by_key('MFIVE')
        clocktwo.set_by_key('TWENTY')
        clocktwo.set_by_key('PAST')
        h_offset = 0
    elif 30 <= now.tm_min and now.tm_min < 35:
        clocktwo.set_by_key('THIRTY')
        h_offset = 0
    elif 35 <= now.tm_min and now.tm_min < 40:
        clocktwo.set_by_key('MFIVE')
        clocktwo.set_by_key('TWENTY')
        clocktwo.set_by_key('TO')
        h_offset = 1
    elif 40 <= now.tm_min and now.tm_min < 45:
        clocktwo.set_by_key('TWENTY')
        clocktwo.set_by_key('TO')
        h_offset = 1
    elif 45 <= now.tm_min and now.tm_min < 50:
        clocktwo.set_by_key('A') 
        clocktwo.set_by_key('QUARTER')
        clocktwo.set_by_key('TO')
        h_offset = 1
    elif 50 <= now.tm_min and now.tm_min < 55:
        clocktwo.set_by_key('MTEN')
        clocktwo.set_by_key('TO')
        h_offset = 1
    elif 55 <= now.tm_min and now.tm_min < 60:
        clocktwo.set_by_key('MFIVE')
        clocktwo.set_by_key('TO')
        h_offset = 1
    else:
        raise ValueError('now.tm_min: %s' % now.tm_min)
    hour = (now.tm_hour + h_offset) % 12
    if(hour == 0):
        clocktwo.set_by_key('TWELVE')
    elif(hour == 1):
        clocktwo.set_by_key('ONE')
    elif(hour == 2):
        clocktwo.set_by_key('TWO')
    elif(hour == 3):
        clocktwo.set_by_key('THREE')
    elif(hour == 4):
        clocktwo.set_by_key('FOUR')
    elif(hour == 5):
        clocktwo.set_by_key('HFIVE')
    elif(hour == 6):
        clocktwo.set_by_key('SIX')
    elif(hour == 7):
        clocktwo.set_by_key('SEVEN')
    elif(hour == 8):
        clocktwo.set_by_key('EIGHT')
    elif(hour == 9):
        clocktwo.set_by_key('NINE')
    elif(hour == 10):
        clocktwo.set_by_key('HTEN')
    elif(hour == 11):
        clocktwo.set_by_key('ELEVEN')

    hour24 = (now.tm_hour + h_offset) % 24
    if 0 <= hour24  and hour24 < 1:
        if 30 <= now.tm_min and now.tm_min < 35:
            clocktwo.set_by_key('IN')
            clocktwo.set_by_key('THE')
            clocktwo.set_by_key('MORNING')
        else:
            clocktwo.set_by_key('MIDNIGHT')
    elif 1 <= hour24  and hour24 < 12:
        clocktwo.set_by_key('IN')
        clocktwo.set_by_key('THE')
        clocktwo.set_by_key('MORNING')
    elif 12 <= hour24  and hour24 < 13:
        if 30 <= now.tm_min and now.tm_min < 35:
            clocktwo.set_by_key('IN')
            clocktwo.set_by_key('THE')
            clocktwo.set_by_key('MORNING')
        else:
            clocktwo.set_by_key('NOON')
    elif 13 <= hour24  and hour24 < 17:
        clocktwo.set_by_key('IN')
        clocktwo.set_by_key('THE')
        clocktwo.set_by_key('AFTERNOON')
    elif 17 <= hour24  and hour24 < 20:
        clocktwo.set_by_key('IN')
        clocktwo.set_by_key('THE')
        clocktwo.set_by_key('EVENING')
    elif 20 <= hour24  and hour24 < 24:
        clocktwo.set_by_key('AT')
        clocktwo.set_by_key('NIGHT')
    if refresh:
        clocktwo.refresh()
    # r.after(500,update_time)

