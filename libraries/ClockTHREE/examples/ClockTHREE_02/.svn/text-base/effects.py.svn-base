from time import *
from fonts import basic
from util import *
import time
from numpy import *
ONES = 0b11111111111111111111111111111111

def print_buffer(buff):
    for col in buff:
        print num2bits(col)
    print
    
def cascadeRL(c2):
    saved = array(c2.screen.buffer, copy=True)
    c2.clearall()
    c2.paused = True
    for col_i, col in enumerate(saved):
        for i in range(c2.N_COL - 1, col_i, -1):
            c2.screen.buffer[i] = ONES
            if i < c2.N_COL - 1:
                c2.screen.buffer[i + 1] = 0
            c2.refresh()
        if col_i < c2.N_COL - 1:
            c2.screen.buffer[col_i + 1] = 0
        c2.screen.buffer[col_i] = col
        c2.refresh()
        if False:
            for i in range(col_i - 1, -1, -1):
                col = c2.screen.buffer[i]
                c2.screen.buffer[i] |= ONES
                c2.refresh()
                c2.screen.buffer[i] = col
                c2.refresh()
    c2.paused = False

def wordfall_in_old(c2):
    c2.paused = True
    saved = array(c2.screen.buffer, copy=True)
    c2.screen.buffer *= 0
    for row_i in range(31, -1, -3):
        row = (saved & 0b111 << row_i) >> (row_i - 1)
        if sum(row) > 0:
            for row_j in range((row_i - 1)//3):
                c2.screen.buffer += row
                c2.refresh()
                c2.screen.buffer -= row
                c2.refresh()
                row = row << 3
            c2.screen.buffer += row
            c2.refresh()
    c2.paused = False
    return

def wordfall_in_slow(c2):
    c2.paused = True
    saved = array(c2.screen.buffer, copy=True)
    c2.screen.buffer *= 0
    for row_i in range(9, -1, -1):
        row = (saved & 0b111 <<  3 * row_i) >> 3 * row_i
        if sum(row) > 0:
            for row_j in range(row_i):
                c2.screen.buffer += row
                c2.refresh()
                c2.screen.buffer -= row
                c2.refresh()
                row = row << 3
            c2.screen.buffer += row
            c2.refresh()
    c2.paused = False
    return

def wordfall_in(c2):
    c2.paused = True
    saved = array(c2.screen.buffer, copy=True)
    c2.screen.buffer *= 0
    for row_i in range(9, -1, -1):
        c2.screen.buffer = saved >> (3 * row_i)
        c2.refresh()
    c2.paused = False
    return

def wordfall_out(c2):
    c2.paused = True
    saved = array(c2.screen.buffer, copy=True)
    for row_i in range(12):
        c2.screen.buffer = scroll_down(c2.screen.buffer)
        c2.refresh()
    c2.paused = False
    return

def slide_in_RL(c2, new):
    new = array(new, copy=True)
    c2.paused = True
    for i in range(c2.N_COL):
        c2.screen.buffer[:-1] = c2.screen.buffer[1:]
        c2.screen.buffer[-1] = new[i]
        c2.refresh()
    c2.paused = False

def slide_in_LR(c2, new):
    new = array(new, copy=True)
    c2.paused = True
    for i in range(c2.N_COL):
        c2.screen.buffer[1:] = c2.screen.buffer[:-1]
        c2.screen.buffer[0] = new[c2.N_COL - i - 1]
        c2.refresh()
    c2.paused = False

def clockthree_rain(c2, color):
    c2.paused = True
    c2.screen.buffer *= 0
    i_s = array([9, 2, 11, 7, 5, 8, 10, 3, 4, 6]) + 1
    fix   = 0b00000111000000000000000000000000
    erase = 0b00000111111111111111111111111111
    for i in i_s:
        fixed = fix & c2.screen.buffer
        c2.screen.buffer = ((c2.screen.buffer & fix) |
                            ((c2.screen.buffer << 3) & erase))
                            
        c2.setPixel(0, i, color)
        c2.screen.buffer = ((c2.screen.buffer & fix) |
                            ((c2.screen.buffer << 3) & erase))
        c2.refresh()
        c2.screen.buffer = ((c2.screen.buffer & fix) |
                            ((c2.screen.buffer << 3) & erase))
        c2.refresh()

    for i in range(8):
        fixed = fix & c2.screen.buffer
        c2.screen.buffer = ((c2.screen.buffer & fix) |
                            ((c2.screen.buffer << 3) & erase))
        c2.refresh()
    sleep(2)
    
    c2.screen.buffer <<= 3
    c2.refresh()
    c2.screen.buffer <<= 1
    c2.refresh()
    c2.screen.buffer <<= 1
    c2.refresh()
    c2.paused = False

def clockthree_rain_orig(c2, color):
    c2.paused = True
    c2.screen.buffer *= 0
    sleep(3)
    i_s = [9, 7, 5, 8, 10, 3, 4, 6]
    for i in i_s:
        for j in range(9):
            c2.setPixel(j, i, color)
            c2.refresh()
            c2.setPixel(j, i, 0)
            c2.refresh()
        c2.setPixel(9, i, color)
        c2.refresh()
    sleep(3)
    wordfall(c2)
    c2.update()
    wordfall_in(c2)
    c2.paused = False

def led_test(c2):
    c2.paused = True
    c2.led_test = True
    buffer = c2.screen.buffer.copy()
    while c2.led_test:
        c2.screen.buffer *= 0
        c2.refresh(delay=.4)
        for color in COLOR_MASKS:
            c2.screen.buffer *= 0
            c2.screen.buffer += color
            c2.refresh(delay=.4)
            if not c2.led_test:
                break
    c2.screen.buffer = buffer
    c2.refresh()
    c2.paused = False

def scroll_msg(c2, msg, color_mask, clearall=True, clear_rgb=False):
    c2.paused = True
    if clearall:
        c2.clearall()
    if clear_rgb:
        c2.clear_rgb()
    msg_font = zeros(8 * len(msg), 'uint32')
    for i, char in enumerate(msg):
        msg_font[8 * i: 8 * (i + 1)] = mono8x8_to_RGB(basic.get(char))

    # apply color
    cols = []
    for col in msg_font:
        cols.append(col & color_mask)

    # scroll msg in
    fixed = 0b11111 << 27
    for col in cols:
        c2.screen.buffer[:-1] = (c2.screen.buffer[1:] & ~fixed) | (
            c2.screen.buffer[:-1] & fixed)
        c2.screen.buffer[-1] = (col & ~fixed) | (c2.screen.buffer[-1] & fixed)
        c2.refresh(delay=.05)

    # scroll msg out
    for i in range(c2.N_COL):
        c2.screen.buffer[:-1] =c2.screen.buffer[1:]
        c2.screen.buffer[-1] *= 0
        c2.refresh()
        
    c2.paused = False

def clockthree_scroll(c2, color_mask):
    c2.paused = True
    c2.clearall()
    msg = 'ClockTHREE'
    msg_font = zeros(8 * len(msg), 'uint32')
    for i, char in enumerate(msg):
        msg_font[8 * i: 8 * (i + 1)] = mono8x8_to_RGB(basic.get(char))
        
    # trim pairs of zeros
    cols = [msg_font[0]]
    for col in msg_font:
        if col == 0 and cols[-1] == 0:
            continue
        else:
            cols.append(col & color_mask)

    for col in cols:
        c2.screen.buffer[:-1] =c2.screen.buffer[1:]
        c2.screen.buffer[-1] = col
        c2.refresh()

    for i in range(c2.N_COL):
        c2.screen.buffer[:-1] =c2.screen.buffer[1:]
        c2.screen.buffer[-1] *= 0
        c2.refresh()
        
    c2.paused = False
    
def matrix(c2):
    import random

    c2.paused = True
    inds = range(N_COL)
    
    for i in range(20):
        col_i = random.randrange(N_COL)
        col = c2.screen.buffer[col_i]
        steps = random.randrange(N_ROW)
        if col & 0b111:
            # shift in zeros
            for j in range(steps):
                c2.screen.buffer[col_i] = scroll_down(c2.screen.buffer[col_i])
                c2.refresh()
        else:
            # shift in blues
            for j in range(steps):
                c2.screen.buffer[col_i] = scroll_down(c2.screen.buffer[col_i])
                c2.screen.buffer[col_i] |= 4
                c2.refresh()
    c2.paused = False

def sweep_color(c2, color):
    c2.paused = True
    for i in range(N_COL):
        c2.buffer[i] &= color
        c2.refresh()
    c2.paused = False
    
def flip_in(c2, in_buff, delay=.01):
    c2.paused = True
    out = array(c2.screen.buffer, copy=True)
    buff = c2.screen.buffer
    buff[0] = 0
    buff[1] = out[0] | out[1]
    buff[2] = out[2]
    buff[3] = out[3]
    buff[4] = out[4]
    buff[5] = out[5]
    buff[6] = out[6] | out[7]
    buff[7] = 0
    c2.refresh()
    sleep(delay)

    buff[0] = 0    
    buff[1] = 0
    buff[2] = out[0] | out[1]
    buff[3] = out[2] | out[3]
    buff[4] = out[4] | out[5] 
    buff[5] = out[6] | out[7]
    buff[6] = 0
    buff[7] = 0    
    c2.refresh()
    sleep(delay)

    buff[0] = 0    
    buff[1] = 0
    buff[2] = 0
    buff[3] = out[0] | out[1] | out[2] | out[3]
    buff[4] = out[4] | out[5] | out[6] | out[7]
    buff[5] = 0
    buff[6] = 0
    buff[7] = 0    
    c2.refresh()
    sleep(delay)

    buff[0] = 0    
    buff[1] = 0
    buff[2] = 0
    buff[3] = 0
    buff[4] = 0
    buff[5] = 0
    buff[6] = 0
    buff[7] = 0    
    c2.refresh()
    sleep(delay)

#----------------- swap in new buff
    
    buff[0] = 0    
    buff[1] = 0
    buff[2] = 0
    buff[3] = in_buff[0] | in_buff[1] | in_buff[2] | in_buff[3]
    buff[4] = in_buff[4] | in_buff[5] | in_buff[6] | in_buff[7]
    buff[5] = 0
    buff[6] = 0
    buff[7] = 0    
    c2.refresh()
    sleep(delay)

    buff[0] = 0    
    buff[1] = 0
    buff[2] = in_buff[0] | in_buff[1]
    buff[3] = in_buff[2] | in_buff[3]
    buff[4] = in_buff[4] | in_buff[5] 
    buff[5] = in_buff[6] | in_buff[7]
    buff[6] = 0
    buff[7] = 0    
    c2.refresh()
    sleep(delay)

    buff[0] = 0
    buff[1] = in_buff[0] | in_buff[1]
    buff[2] = in_buff[2]
    buff[3] = in_buff[3]
    buff[4] = in_buff[4]
    buff[5] = in_buff[5]
    buff[6] = in_buff[6] | in_buff[7]
    buff[7] = 0
    c2.refresh()
    sleep(delay)

    buff[:8] = in_buff[:8]
    c2.refresh()
    c2.paused = False

def we_need_your_support(c2):
    c2.paused = True
    c2.set_by_key('WE', BLUE_MASK)
    c2.refresh()
    sleep(.3)
    c2.set_by_key('NEED', BLUE_MASK)
    c2.refresh()
    sleep(.3)
    c2.set_by_key('YOUR', BLUE_MASK)
    c2.refresh()
    sleep(.3)
    c2.set_by_key('SUPPORT', BLUE_MASK)
    c2.refresh()
    sleep(.3)
    c2.set_by_key('!!', BLUE_MASK)
    c2.refresh()
    c2.paused = False

