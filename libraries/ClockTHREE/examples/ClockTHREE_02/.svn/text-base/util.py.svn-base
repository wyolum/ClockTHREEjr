from constants import *
from numpy import *

N_COL = 16
N_ROW = 12

def bits2num(bits):
    out = 0L
    for p, b in enumerate(bits[::-1]):
        if b == 1 or b == '*':
            out += 2**p
    return out
def num2bits(uint32, n=32, head='', zero=' ', one='*'):
    out = []
    for i in range(n):
        if uint32 & 1 << i:
            out.append(one)
        else:
            out.append(zero)
    out.reverse()
    return head + ''.join(out)

def reflect8x8(bytes):
    ''' 
    reflect about main diagonal
    '''
    out = zeros(8, 'uint8')
    for i in range(8):
        for j in range(8):
            out[j] += ((bytes[i] >> j) & 1) << i
    return out
def rotate8x8(bytes):
    ''' 
    reflect about main diagonal
    '''
    out = zeros(8, 'uint8')
    for i in range(8):
        for j in range(8):
            out[j] += ((bytes[i] >> (7 - j)) & 1) << i
    return out

def print8x8(bytes):
    for b in bytes:
        print num2bits(b, 8)
    print

def printx32(bytes):
    for b in bytes:
        print num2bits(b, 32)
    print

def rotate8x8__test__():
    arrow = rotate8x8([0b00001000,
                       0b00001100,
                       0b11111110,
                       0b11111111,
                       0b11111111,
                       0b11111110,
                       0b00001100,
                       0b00001000])
    print8x8(arrow)
    
    e = rotate8x8([0b00000011,
                   0b00000101,
                   0b00001001,
                   0b00010001,
                   0b00010001,
                   0b00001001,
                   0b00000101,
                   0b00010001])
    print8x8(e)
# rotate8x8__test__()

def mono8x8_to_RGB(bytes):
    out = zeros(len(bytes), 'uint32')
    for i, b in enumerate(bytes):
        for j in range(8):
            out[i] += (((b >> j) & 1) *  0b111) << (3 * j)
    return out
def mono_to_RGB__test__():
    bytes = [0b00000001,
             0b00000000,
             0b00000000,
             0b00000000,
             0b00000000,
             0b00000000,
             0b00000000,
             0b10000001]
    print8x8(bytes)
    printx32(mono8x8_to_RGB(bytes))
# mono_to_RGB__test__()

def scroll_down(buffer):
    out = (((buffer << 3) & RGB) | 
           (((buffer << 1) & ROWS[10])) | 
           (((buffer << 1) & ROWS[11])))
    out %= 2 ** 32
    return out

def scroll_up(buffer):
    return ((buffer & RGB) >> 3) | ((buffer & MONO) >> 1)

def scroll__test__():
    col = zeros(1, 'uint32')[0]
    col = col | (0b111)

    for i in range(11):
        col = scroll_down(col)
        print num2bits(col)
    for i in range(11):
        col = scroll_up(col)
        print num2bits(col)
# scroll__test__()

