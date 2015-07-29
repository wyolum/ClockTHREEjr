from pylab import *
import time
import C3_interface
import struct
from numpy import *
import PIL.Image
mario = PIL.Image.open('_242-.gif')
RED = 0b001
GREEN = 0b010
BLUE = 0b100

C3_interface.connect()

N_COL = 16
ROWS = [
  0b00000000000000000000000000000111,
  0b00000000000000000000000000111000,
  0b00000000000000000000000111000000,
  0b00000000000000000000111000000000,
  0b00000000000000000111000000000000,
  0b00000000000000111000000000000000,
  0b00000000000111000000000000000000,
  0b00000000111000000000000000000000,
  0b00000111000000000000000000000000,
  0b00111000000000000000000000000000,
  0b01000000000000000000000000000000,
  0b10000000000000000000000000000000
]
OFF = 0
MONO = 0b100
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

a = transpose(asarray(mario)[3::3,9:-6:3])[::-1]
mario.seek(1)
b = transpose(asarray(mario)[3::3,9:-6:3])[::-1]
mario.seek(2)
c = transpose(asarray(mario)[3::3,9:-6:3])[::-1]
mariomap = {4:0b000,
            2:0b001,
            3:0b011,
            1:0b100}
luigimap = {4:0b000,
            2:0b010,
            3:0b011,
            1:0b100}
remap = luigimap
def toC3(data):
    '''
    data is a 12 x 16 array of 8-bit colors
    '''
    s = Screen()
    for r, row in enumerate(data):
        for c, pix in enumerate(row):
            s.setPixel(r, c, remap[pix])
    return s.buffer.tostring()

# pcolormesh(a)
# colorbar()
# show()
# here
a  = toC3(a)
b  = toC3(b)
c  = toC3(c)

def run(n):
    for i in range(n):
        delay = .25
        C3_interface.display_set(a)
        time.sleep(delay)
        C3_interface.display_set(b)
        time.sleep(delay)
        C3_interface.display_set(c)
        time.sleep(delay)

if __name__ == '__main__':
    try:
        C3_interface.connect()
        run(1000000)
    finally:
        C3_interface.trigger_mode()
