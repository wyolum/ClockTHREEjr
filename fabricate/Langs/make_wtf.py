import numpy
import spreadsheet

def make_wtf(letters, sentences, index, filename, author='unknown', licence="CC BySA", email='', desc=''):
    '''
    letters is a string of all the letters in row order
    
    index is a list of lists, one list for each sentence.
       it      is  ...
    [[(0, 2), (3, 2), ...
    '''
    word_idx = set()
    for s in index:
        for w in s:
            word_idx.add(w)
    n_word = len(word_idx)
    word_idx = list(word_idx)
    print n_word, 'n_word'
    rows = [start / 16 for start, l in word_idx]
    cols = [start % 16 for start, l in word_idx]
    lens = [l for start, l in word_idx]

    bitmap = numpy.zeros((288, n_word), int)
    for r, s in enumerate(index):
        for w in s:
            col = word_idx.index(w)
            bitmap[r][col] = 1
    words = [letters[start:start + l] for start, l in word_idx]
    
    wtf =  {'letters': letters,
            'data':bitmap, 
            'rows':rows, ## starting row of words
            'cols':cols, ## starting col of words
            'lens':lens, ## length of words
            'words':words, ## words themselves
            'min_rows':None, ## minute hacks
            'min_cols':None, ## minute hacks
            'n_min_led': None, ## minute hacks
            'n_min_state': 0, ## minute hacks
            'min_bitmap': None, ## minute hacks
            'author':author,
            'email':email,
            'licence':licence,
            'desc':desc,
            'filename':filename,
            }
    
    ss = spreadsheet.Spreadsheet()
    ss.putRegion("C1", [range(16)])
    ss.putRegion("B2", numpy.arange(16)[numpy.newaxis])
    ss.putCell('U1', 'startrow')
    ss.putCell('U2', 'startcol')
    ss.putCell('U3', 'length')
    ss.putRegion('V1', [rows, cols, lens])
    ss.putRegion('V4', [words])
    wordmap = [[['', '1'][bitmap[i, j]] for j in range(len(bitmap[i]))] for i in range(len(bitmap))]
    ss.putRegion('V6', wordmap)
    ss.putCell('V294', 0) ## n minute leds
    ss.putCell('X294', 0) ## n minute led states
    ss.putCell('A20', 'Author:')
    ss.putCell('B20', author)
    ss.putCell('A21', 'Email:')
    ss.putCell('B21', email)
    ss.putCell('A23', 'Desc:')
    ss.putCell('B23', desc)
    layout =  []   
    for i in range(len(letters) // 16 + 1):
        layout.append(list(letters[i * 16: (i + 1) * 16]))
    ss.putRegion('C2', layout)
    open(filename, 'w').write(ss.toString().encode('utf-8'))
    print 'wrote', filename
