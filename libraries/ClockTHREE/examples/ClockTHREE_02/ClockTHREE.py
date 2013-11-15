import effects
import datetime
from time import *
from numpy import *
from Tkinter import *
import random
import english, german
from constants import *
import fonts
import util
import C3_interface

offset = -5 * 3600

def next_time(*args, **kw):
    clockthree.offset += 60
    clockthree.update()

def last_time(*args, **kw):
    clockthree.offset -= 60
    clockthree.update()

def key_press(event):
    c = event.char
    if event.char == '1':
        effects.wordfall_out(clockthree)
        for color in COLOR_MASKS:
            clockthree.set_by_key('CLOCKTHREE', color)
            effects.scroll_msg(clockthree, 'ClockTHREE', color, clearall=False)
            clockthree.refresh()
            sleep(1)
    if event.char == '2':
        effects.wordfall_out(clockthree)
        effects.clockthree_rain(clockthree, BLUE_MASK)
        clockthree.update(refresh=False)
        effects.wordfall_in(clockthree)
    if event.char == '3':
        effects.sweep_color(clockthree, 0)
        effects.matrix(clockthree)
        effects.wordfall_out(clockthree)
        clockthree.update(refresh=False)
        effects.wordfall_in(clockthree)
    if event.char == '4':
        clockthree.clearall()
        new_buff = zeros(N_COL, 'uint32')
        for o in range(ord('9'), ord('0') - 1, -1):
            new_buff[:8] = util.mono8x8_to_RGB(fonts.basic.get(chr(o)))
            new_buff[9:] = 0.
            effects.flip_in(clockthree, new_buff)
            sleep(.2)
    if event.char == '5':
        effects.wordfall_out(clockthree)
        effects.scroll_msg(clockthree, 'But', BLUE_MASK)
        sleep(.2)
        effects.we_need_your_support(clockthree)
    if event.char == '6':
        effects.wordfall_out(clockthree)
        clockthree.set_by_key('THANK')
        clockthree.refresh()
        sleep(.3)
        clockthree.set_by_key('YOU!')
        clockthree.refresh()
        sleep(4)
    if event.char == '7':
        clockthree.paused = True
        effects.sweep_color(clockthree, 0)
        clockthree.set_by_key('CHAI')
        clockthree.refresh()
        sleep(.3)
        clockthree.set_by_key('IN')
        clockthree.set_by_key('THE')
        clockthree.refresh()
        sleep(.3)
        clockthree.set_by_key('MORNING')
        clockthree.refresh()
        sleep(5)
        effects.wordfall_out(clockthree)
        clockthree.set_by_key('ITS')
        clockthree.refresh()
        sleep(.3)
        clockthree.set_by_key('BEER')
        clockthree.refresh()
        sleep(.3)
        clockthree.set_by_key('THIRTY')
        clockthree.refresh()
        sleep(5)
        effects.sweep_color(clockthree, 0)
        clockthree.update(refresh=False)
        effects.wordfall_in(clockthree)
        clockthree.paused = False
        
    if event.char == 'X':
        effects.slide_in_RL(clockthree, clockthree.buffer)
    if event.char == 'x':
        effects.slide_in_LR(clockthree, clockthree.buffer)
    if event.char == 'W':
        effects.wordfall_out(clockthree)
    if event.char == 'w':
        effects.wordfall_in(clockthree)
    if event.char == 'C':
        effects.cascadeRL(clockthree)
    if event.char == 'H':
        clockthree.offset -= 3600
        clockthree.update()
    if event.char == 'h':
        clockthree.offset += 3600
        clockthree.update()
    if event.char == 'M':
        clockthree.offset -= 60
        clockthree.update()
    if event.char == 'm':
        clockthree.offset += 60
        clockthree.update()
    if event.char == 'S':
        clockthree.offset -= 1
        clockthree.update()
    if event.char == 's':
        clockthree.offset += 1
        clockthree.update()
    if event.char == 'F':
        clockthree.offset -= 5 * 60
        clockthree.update()
    if event.char == 'f':
        clockthree.offset += 5 * 60
        clockthree.update()
    if event.char == 'u':
        effects.wordfall_out(clockthree)
        clockthree.update(refresh=False)
        effects.wordfall_in(clockthree)
    if event.char == 't':
        if clockthree.led_test == True:
            clockthree.led_test = False
        else:
            effects.led_test(clockthree)

class Screen:
    def __init__(self, n_col=N_COL):
        self.buffer = zeros(n_col, 'uint32')

    def __getitem__(self, idx):
        return self.buffer[idx]

    def setPixel(self, row, col, color):
        if(row < 10):
            self.buffer[col] &= ~ROWS[row]
            self.buffer[col] |= (color & 0b00000111) << 3 * row
        elif ((color == OFF | color == MONO) & row < 12):
            if(color):
                self.buffer[col] |=  ROWS[row]
            else:
                self.buffer[col] &= ~ROWS[row]

    def clearall(self):
        self.buffer *= 0
    def clear_rgb(self):
        self.buffer = self.buffer & MONO

    
class ClockTHREE:
    def __init__(self, language, offset, yesconnect=False, parent=None):
        self.N_ROW = N_ROW
        self.N_COL = N_COL
        self.screen = Screen()
        self.macros = language.macros
        self.update_time = language.update_time
        self.text = language.text
        self.default_color = 0b111
        self.offset = offset
        self.paused = False
        if yesconnect:
            C3_interface.connect(yesping=False)
            offset = C3_interface.gmt_offset
        self.led_test = False
        
        if parent is None:
            self.parent = Tk()
        else:
            self.parent = Toplevel(parent)
        self.parent.title('ClockTHREE')
        self.parent.tk_setPalette('#000000')
        
        self.r = Frame(self.parent, background='#000000')
        self.r.grid(row=0, column=0)
        self.r.bind("<Button-1>", next_time)
        self.r.bind("<Button-3>", last_time)
        self.parent.bind("<Key>", key_press)


    def __del__(self):
        C3_interface.trigger_mode()

    def getBuffer(self):
        return self.screen.buffer
    buffer = property(getBuffer)
    def setPixel(self, row, col, color):
        return self.screen.setPixel(row, col, color)
    def update(self, refresh=True):
        if not self.paused:
            self.update_time(self, refresh=refresh)
    def clearall(self):
        self.screen.clearall()

    def clear_rgb(self):
        self.screen.clear_rgb()

    def set_by_key(self, key, color=None):
        # print key
        if color is None:
            color = self.default_color
        if self.macros.has_key(key):
            rows, cols = self.macros[key]
            for row, col in zip(rows, cols):
                self.screen.setPixel(row, col, color)

    def refresh(self, delay=.05):
        for col in range(self.N_COL):
            data = self.screen[col]
            for row in range(self.N_ROW):
                if row < 10:
                    color = (data >> 3 * row) & 0b111
                    s = '#'
                    if color & 1 << 0:
                        s = s + "FF"
                    else:
                        s = s + "10"
                    if color & 1 << 1:
                        s = s + "FF"
                    else:
                        s = s + "10"
                    if color & 1 << 2:
                        s = s + "FF"
                    else:
                        s = s + "10"
                else:
                    color = (data >> 20 + row) & 0b1
                    if color:
                        s ="#1010FF"
                    else:
                        s = "#101010"
                labels[row][col].config(foreground=s)
        if delay > 0:
            sleep(delay)
        if C3_interface.is_connected():
            C3_interface.display_set(self.buffer.astype('uint32').tostring())
        clockthree.parent.update()

def main(language, yesconnect=False):
    import sys
    global labels, clockthree
    if len(sys.argv) > 1 and sys.argv[1].lower() == 'german':
        faceplate = german
    else:
        faceplate = english
    offset = 0
    clockthree = ClockTHREE(faceplate, offset, yesconnect=yesconnect)

    labels = []
    l = Label(clockthree.parent, 
              text='   ',
              font='Courier 28', 
              background="#000000",
              foreground="#000000")
    l.grid(row=0, column=0)
    l = Label(clockthree.parent, 
              text='   ',
              font='Courier 28', 
              background="#000000",
              foreground="#000000")
    l.grid(row=13, column=17)
    for row in range(N_ROW):
        labels.append([])
        for col in range(N_COL):
            l = Label(clockthree.parent,
                      text='%s' % clockthree.text[row][col], 
                      font='Times 28', 
                      background="#000000",
                      foreground="#000000")
            l.grid(column=col+1, row=row+1, ipadx=8)
            labels[-1].append(l)
    if clockthree.text[0].startswith('ITS'):
        labels[0][1].config(text="T'")
        labels[5][8].config(text="O'")
    def do_dec():
        clockthree.offset -= 60
        clockthree.update()

    def do_inc():
        clockthree.offset += 60
        clockthree.update()

    def do_mode():
        clockthree.default_color += 1
        clockthree.default_color %= 8
        clockthree.update()

    def do_reset():
        clockthree.offset = offset
        clockthree.update()
        # stop led_test if active
        clockthree.led_test = False

    reset_b = Button(clockthree.parent, text='R', foreground='#ff0000', command=do_reset)
    mode_b = Button(clockthree.parent, text='M', foreground='#ff0000', command=do_mode)
    dec_b = Button(clockthree.parent, text='D', foreground='#ff0000', command=do_dec)
    inc_b = Button(clockthree.parent, text='I', foreground='#ff0000', command=do_inc)

    reset_b.grid(column=3, row=13)
    dec_b.grid(column=8, row=13)
    mode_b.grid(column=7, row=13)
    inc_b.grid(column=6, row=13)


    after_id = None
    def tick_tock():
        global after_id
        clockthree.update()
        after_id = clockthree.parent.after(5 * 1000, tick_tock)
    clockthree.refresh()
    clockthree.update()
    after_id = clockthree.parent.after(5 * 1000, tick_tock)
    def on_close(*args):
        clockthree.r.after_cancel(after_id)
        clockthree.parent.destroy()
    clockthree.parent.protocol('WM_DELETE_WINDOW', on_close)
    clockthree.parent.mainloop()
if __name__ == '__main__':
    main(english, yesconnect=True)
