import string
import StringIO
import csv

class Spreadsheet:
    def __init__(self, lines=None):
        ''' lines is a list of lists'''
        if lines is None:
            lines = []
        self.lines = lines

    def _getCell(self, row, col):
        out = None
        if row < len(self.lines):
            l = self.lines[row]
            if col < len(l):
                out = l[col]
        return out
    def getCell(self, cellstr):
        j, i = self.parsecell(cellstr)
        return self._getCell(j, i)
    def _putCell(self, row, col, data):
        while len(self.lines) <= row:
            self.lines.append([])
        while len(self.lines[row]) <= col:
            self.lines[row].append('')
        self.lines[row][col] = data

    def putCell(self, cellstr, data):
        j, i = self.parsecell(cellstr)
        return self._putCell(j, i, data)
        
    def _getRegion(self, row, col, length, width):
        out = []
        i = row - 1
        while i < row + length:
            i += 1
            out.append([])
            j = col - 1
            while j < col + width:
                j += 1
                next = self._getCell(i, j)
                if next is not None:
                    out[-1].append(next)
                else:
                    break
            if length == inf and len(out[-1]) == 0:
                break
        return out
    def _putRegion(self, row, col, data):
        for j in range(len(data)):
            for i, d in enumerate(data[j]):
                self._putCell(j + row, i + col, d)
        
    @staticmethod
    def parsecell(cell_str):
        cell_str = cell_str.upper()
        i = 0
        if cell_str[0] == '*':
            col = inf
        else:
            col = ord(cell_str[0]) - ord('A') + 1
            for i, l in enumerate(cell_str[1:]):
                if l in string.uppercase:
                    col = col * 26  + ord(l) - ord('A') + 1
                else:
                    break
        if cell_str[i + 1:] == '*':
            row = inf
        else:
            row = int(cell_str[i + 1:])
        return row - 1, col - 1
        
    def getRegion(self, reg_str):
        'examples  r11, R11:Q23 R11:R23 R11:R*  R11:*11 R11:**'
        reg_str = reg_str.upper()
        if ':' in reg_str:
            start, stop = [self.parsecell(x) for x in reg_str.split(':')]
            out = self._getRegion(start[0], start[1], 
                                  stop[0] - start[0], stop[1] - start[1])
        else:
            out = [[self._getCell(*self.parsecell(reg_str))]]
        return out
    def putRegion(self, upper_left_cellstr, data):
        row, col = self.parsecell(upper_left_cellstr)
        self._putRegion(row, col, data)
        
    def toString(self):
        sio = StringIO.StringIO()
        for line in self.lines:
            line = [unicode(c) for c in line]
            line = ','.join(line)
            sio.write(line + '\n')
        sio.seek(0)
        return sio.read()

def __Spreadsheet__test__():
    ss = Spreadsheet([])
    ss.putCell("A1", "a1")
    ss.putCell("C10", "C10")
    assert ss.getCell('A1') == 'a1'
    assert ss.getCell('A2') == None
    assert ss.getCell('C10') == 'C10'
    ss._putRegion(5, 5, [[1, 2], [3, 4, 5]])
    assert ss.getCell("F6") == 1, '%s != "1"' % ss.getCell("F6")
    assert ss.getCell("G7") == 4
if __name__ == '__main__':
    __Spreadsheet__test__()
