from util import *

class Font:
    def __init__(self):
        pass
    def get(self, char):
        return self.data[ord(char)]
    def __getattr__(self, char):
        return self.get(char)

class Basic8x8(Font):
    def __init__(self):
        f = open('8x8.txt')
        lines = f.readlines()
        data = []
        for i in range(128): # char
            data.append([])
            for j in range(8): # row
                row = lines[i * 8 + j]
                data[-1].append(bits2num(row))
        self.data = data
    def get(self, char):
        return rotate8x8(self.data[ord(char)])

    def printFont(self):
        print 'const uint8_t N_CHAR = 128'
        print 'uint8_t font[N_CHAR] = {'
        for o in range(128):
            char = chr(o)
            x = self.get(char)
            for l in x:
                out = '    %s, // %s' % (
                    num2bits(l, n=8, head='0b', zero='0', one='1'),
                    char)
                print out.strip()
            print
        print '}'

basic = Basic8x8()
# basic.printFont()
