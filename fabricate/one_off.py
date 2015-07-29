import sys
sys.path.append('Langs')
from Simulate import *
import glob
from create_faceplate_jr_v2 import *

# top = "Bear & Wal"
# bottom = "September 28, 2012"
# top = 'Amy & Justin'
# bottom = 'June 12, 1993'
top = None
bottom = None # "Wyatt James Barriere\n Febuary 11, 2014"

download_dir = '/home/justin/Downloads/'
def find_lang_file(lang):
    test1 = 'Langs/%s.wtf' % lang
    test2 = 'Langs/%s.csv' % lang
    if os.path.exists(test1):
        out = test1
    elif os.path.exists(test2):
        out = test2
    else:
        lang = lang.capitalize()
        csvs = glob.glob(download_dir + '*.csv')
        out = None
        for file in csvs:
            dir, file = os.path.split(file)
            if file.startswith('ClockTHREEjr'):
                layout = file.split(' - ')[1][:-4]
                # print layout, lang
                if file.endswith(lang + '.csv'):
                    out = os.path.join(dir, file)
                    break
    return out


# lang = 'Hebrew_v1'
lang = 'Dutch_v1'
lang = 'German_v3'
lang = 'German_v5'
lang = 'Spanish_v1'
lang = 'English_v3'

wtf_file = find_lang_file(lang)
wtf = readwtf(wtf_file)
letters = wtf['letters']

if True: ### irish version hack
    lang = 'Irish_v1'

    letters = open("Langs/Irish_v1.txt").readlines()
    for i in range(len(letters)):
        line = letters[i].strip().decode('utf-8')
        letters[i] = letters[i] + ' ' * (16 - len(line))
    
    for line in letters:
        for c in line.decode('utf-8'):
            print c,
        print
    letters = [list(line.decode('utf-8')) for line in letters]

if lang == 'Spanish_v1':
    letters[-1][2] = chr(209) ### hacked in to get Spanish_v1 working
if lang == 'German_v3':
    letters[0][8] = chr(220) ## hack for german_v3
    letters[4][11] = chr(220) ## hack for german_v3
    letters[7][7] = chr(214) ## hack for german_v3
if lang == 'German_v5':
    letters[0][8] = chr(220) ## hack for german_v3
    letters[5][1] = chr(220) ## hack for german_v3
    letters[6][9] = chr(214) ## hack for german_v3
    for i in range(6, 10, 1):
        letters[7][i] = chr(149)
    
# create_backplate()
# create_baffles()
font = 'Questrial-Regular'
font = 'Futura'
font = 'DOSIS-MEDIUM'
# font = 'DOSIS-BOLD'
font = 'Helvetica-Bold'
font = 'Righteous-Regular'
font = 'Fondamento-Regular'
font = 'Karla-Regular'
font = 'MarcellusSC-Regular'
font = 'Orbitron-Regular'
font = 'PatrickHand-Regular'
font = 'RobotoCondensed-Regular'
font = 'Montserrat-Regular'
font = 'asap-regular'
font = "Inika-Regular"
font = "DroidSerif-Regular"
font = "SourceSansPro-Regular"
font = "AlegreyaSansSC-Regular"
font = 'JosefinSans-Regular'

fontsize = 25
assert add_font(font), "Font %s not found" % font

cases = {'lower':lower,
         'UPPER':upper}

case = 'UPPER'
case = 'lower'

name = 'PeterN'

color = 'Black'
color = None
fontcolor = pink
fpid = name

name = '%s_%s_%s_%s_%s_%s_%s' % (name, lang, font, case, fontsize, color, fpid)
if name.startswith('_'):
    name = name[1:]
print name
can = new_canvas(name)

if color != None:
    do_corner_holes = False
else:
    do_corner_holes = True

create_faceplate(name, letters, cases[case], font, fontsize, 
                 reverse=True,
                 color=color, 
                 baffles=False,
                 do_corner_holes=do_corner_holes,
                 can=can,
                 top=top,
                 bottom=bottom,
                 NIL=False,
                 edgecolor=pink)

xtext = WIDTH / 2 + MARGIN
ytext = .25*MARGIN
# can.setFont(font.upper(), 35)
can.setFont(font.upper(), fontsize)
can.setFillColor(fontcolor)
can.drawCentredString(xtext, ytext, "FPID: %s, %s" % (fpid, color))

can.showPage()
can.save()
print 'wrote', can._filename
from subprocess import call
call(["evince", can._filename])
