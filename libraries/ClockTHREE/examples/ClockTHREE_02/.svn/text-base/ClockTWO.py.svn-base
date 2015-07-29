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

offset = -5 * 3600

def next_time(*args, **kw):
    clocktwo.offset += 60
    clocktwo.update()

def last_time(*args, **kw):
    clocktwo.offset -= 60
    clocktwo.update()

def key_press(event):
    c = event.char
    if event.char == '1':
        effects.wordfall_out(clocktwo)
        for color in COLOR_MASKS:
            clocktwo.set_by_key('CLOCKTWO', color)
            effects.scroll_msg(clocktwo, 'ClockTHREE', color, clearall=False)
            clocktwo.refresh()
            sleep(1)
    if event.char == '2':
        effects.wordfall_out(clocktwo)
        effects.clocktwo_rain(clocktwo, BLUE_MASK)
        clocktwo.update(refresh=False)
        effects.wordfall_in(clocktwo)
    if event.char == '3':
        effects.sweep_color(clocktwo, 0)
        effects.matrix(clocktwo)
        effects.wordfall_out(clocktwo)
        clocktwo.update(refresh=False)
        effects.wordfall_in(clocktwo)
    if event.char == '4':
        clocktwo.clearall()
        new_buff = zeros(N_COL, 'uint32')
        for o in range(ord('9'), ord('0') - 1, -1):
            new_buff[:8] = util.mono8x8_to_RGB(fonts.basic.get(chr(o)))
            new_buff[9:] = 0.
            effects.flip_in(clocktwo, new_buff)
            sleep(.2)
    if event.char == '5':
        effects.wordfall_out(clocktwo)
        effects.scroll_msg(clocktwo, 'But', BLUE_MASK)
        sleep(.2)
        effects.we_need_your_support(clocktwo)
    if event.char == '6':
        effects.wordfall_out(clocktwo)
        clocktwo.set_by_key('THANK')
        clocktwo.refresh()
        sleep(.3)
        clocktwo.set_by_key('YOU!')
        clocktwo.refresh()
        sleep(4)
    if event.char == '7':
        clocktwo.paused = True
        effects.sweep_color(clocktwo, 0)
        clocktwo.set_by_key('CHAI')
        clocktwo.refresh()
        sleep(.3)
        clocktwo.set_by_key('IN')
        clocktwo.set_by_key('THE')
        clocktwo.refresh()
        sleep(.3)
        clocktwo.set_by_key('MORNING')
        clocktwo.refresh()
        sleep(5)
        effects.wordfall_out(clocktwo)
        clocktwo.set_by_key('ITS')
        clocktwo.refresh()
        sleep(.3)
        clocktwo.set_by_key('BEER')
        clocktwo.refresh()
        sleep(.3)
        clocktwo.set_by_key('THIRTY')
        clocktwo.refresh()
        sleep(5)
        effects.sweep_color(clocktwo, 0)
        clocktwo.update(refresh=False)
        effects.wordfall_in(clocktwo)
        clocktwo.paused = False
        
    if event.char == 'X':
        effects.slide_in_RL(clocktwo, clocktwo.buffer)
    if event.char == 'x':
        effects.slide_in_LR(clocktwo, clocktwo.buffer)
    if event.char == 'W':
        effects.wordfall_out(clocktwo)
    if event.char == 'w':
        effects.wordfall_in(clocktwo)
    if event.char == 'C':
        effects.cascadeRL(clocktwo)
    if event.char == 'H':
        clocktwo.offset -= 3600
        clocktwo.update()
    if event.char == 'h':
        clocktwo.offset += 3600
        clocktwo.update()
    if event.char == 'M':
        clocktwo.offset -= 60
        clocktwo.update()
    if event.char == 'm':
        clocktwo.offset += 60
        clocktwo.update()
    if event.char == 'S':
        clocktwo.offset -= 1
        clocktwo.update()
    if event.char == 's':
        clocktwo.offset += 1
        clocktwo.update()
    if event.char == 'F':
        clocktwo.offset -= 5 * 60
        clocktwo.update()
    if event.char == 'f':
        clocktwo.offset += 5 * 60
        clocktwo.update()
    if event.char == 'u':
        effects.wordfall_out(clocktwo)
        clocktwo.update(refresh=False)
        effects.wordfall_in(clocktwo)

tk = Tk()
tk.title('ClockTWO')
tk.tk_setPalette('#000000')
r = Frame(tk, background='#000000')
r.grid(row=0, column=0)
r.bind("<Button-1>", next_time)
r.bind("<Button-3>", last_time)
tk.bind("<Key>", key_press)

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

    def getPixel(self, row, col):
        out = self.buffer[col] & ROWS[row]
        if row < 10:
            out <<= 3 * row
        else:
            out <<= 30 + (row - 10)
        return out
    def clearall(self):
        self.buffer *= 0
    def clear_rgb(self):
        self.buffer = self.buffer & MONO

    
class ClockTWO:
    def __init__(self, language, offset):
        self.N_ROW = N_ROW
        self.N_COL = N_COL
        self.screen = Screen()
        self.macros = language.macros
        self.update_time = language.update_time
        self.text = language.text
        self.default_color = 0b111
        self.offset = offset
        self.paused = False
        self.time_str = ''
        self.language = language

    def getBuffer(self):
        return self.screen.buffer
    buffer = property(getBuffer)
    def setPixel(self, row, col, color):
        return self.screen.setPixel(row, col, color)
    def getPixel(self, row, col):
        return self.screen.getPixel(row, col)
    def update(self, refresh=True):
        if not self.paused:
            self.update_time(self, refresh=refresh)
    def clearall(self):
        self.screen.clearall()
    def clear_rgb(self):
        self.screen.clear_rgb()
    def print_screen(self):
        out = ''
        for row in range(12):
            for col in range(16):
                if self.getPixel(row, col) > 0:
                    out += self.language.text[row][col]
                else:
                    out += ' '
            out += ' '
        print '%02d:%02d' % divmod(self.offset / 60, 60), ' '.join(out.split())

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
                else:
                    color = (data >> 20 + row) & 0b1

                s = '#'
                if color & 1 << 2:
                    s = s + "FF"
                else:
                    s = s + "20"
                if color & 1 << 1:
                    s = s + "FF"
                else:
                    s = s + "20"
                if color & 1 << 0:
                    s = s + "FF"
                else:
                    s = s + "20"
                labels[row][col].config(foreground=s)
        if delay > 0:
            sleep(delay)
        r.update()

def main(language, offset):
    import sys
    global labels, clocktwo
    if len(sys.argv) > 1 and sys.argv[1].lower() == 'german':
        clocktwo = ClockTWO(german, 0)
    else:
        clocktwo = ClockTWO(english, -5 * 3600)

    labels = []
    l = Label(r, 
              text='   ',
              font='Courier 28', 
              background="#000000",
              foreground="#000000")
    l.grid(row=0, column=0)
    l = Label(r, 
              text='   ',
              font='Courier 28', 
              background="#000000",
              foreground="#000000")
    l.grid(row=13, column=17)
    for row in range(N_ROW):
        labels.append([])
        for col in range(N_COL):
            l = Label(r,
                      text='%s' % clocktwo.text[row][col], 
                      font='Times 28', 
                      background="#000000",
                      foreground="#000000")
            l.grid(column=col+1, row=row+1, ipadx=8)
            labels[-1].append(l)
    if clocktwo.text[0].startswith('ITS'):
        labels[0][1].config(text="T'")
        labels[5][8].config(text="O'")
    def do_dec():
        clocktwo.offset -= 60
        clocktwo.update()

    def do_inc():
        clocktwo.offset += 60
        clocktwo.update()

    def do_mode():
        clocktwo.default_color += 1
        clocktwo.default_color %= 8
        clocktwo.update()

    def do_reset():
        clocktwo.offset = offset
        clocktwo.update()

    reset_b = Button(r, text='R', foreground='#ff0000', command=do_reset)
    mode_b = Button(r, text='M', foreground='#ff0000', command=do_mode)
    dec_b = Button(r, text='D', foreground='#ff0000', command=do_dec)
    inc_b = Button(r, text='I', foreground='#ff0000', command=do_inc)

    reset_b.grid(column=3, row=13)
    dec_b.grid(column=8, row=13)
    mode_b.grid(column=7, row=13)
    inc_b.grid(column=6, row=13)


    after_id = None
    def tick_tock():
        global after_id
        clocktwo.update()
        # after_id = r.after(5 * 1000, tick_tock)
    clocktwo.refresh()
    if False:
        for minute in range(0, 1440, 5):
            clocktwo.offset = minute * 60
            clocktwo.update()
            clocktwo.print_screen()
        here
    else:
        clocktwo.update()
    after_id = r.after(5 * 1000, tick_tock)
    def on_close(*args):
        r.after_cancel(after_id)
        tk.destroy()
    tk.protocol('WM_DELETE_WINDOW', on_close)
    tk.mainloop()
if __name__ == '__main__':
    main(english, 4 * 4600)
