 # -*- coding: latin-1 -*-
import string
from string import *
import os.path
from random import choice
import string
from numpy import *
import PIL.Image
from reportlab.pdfgen import canvas
from reportlab.graphics import renderPDF
from reportlab.graphics.shapes import Drawing, Group, String, Circle, Rect
from reportlab.lib.units import inch, mm, cm
from reportlab.lib.colors import pink, black, red, blue, green, white
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle
import reportlab.rl_config
import codecs
reportlab.rl_config.warnOnMissingFontGlyphs = 0
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import glob
import os.path
import sys

from cnc import *
from baffles import *

from numpy import arange
from copy import deepcopy

english_v3 = '''\
ITDISPTENTWENTY-
FIVEJHALFQUARTER
PASTOBTWONEIGHTA
THREELEVENSIXTEN
FOURFIVESEVENINE
TWELVELATMINFTHE
MIDNIGHTMORNINGJ
AFTERNOONEVENING
'''

english_v4 = '''
IT IS TWENTYFIVE
TENHALFQUARTER  
PASTO TWONE     
THREELEVENSIXTEN
FOURFIVESEVENINE
TWELVEIGHT  INAT
THEMORNINGNIGHT 
AFTERNOONEVENING
'''

class Image:
    def __init__(self, filename, x, y, w=None, h=None):
        self.filename = filename
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    def drawOn(self, c):
        im = PIL.Image.open(self.filename)
        c.drawInlineImage(im, 
                          self.x, self.y, self.w, self.h)
    def translate(self, dx, dy):
        return Image(self.filename, self.x + dx, self.y + dy, self.w, self.h)


PCB_OFF = .05 * inch
HEIGHT = 9 * inch + 2 * PCB_OFF
WIDTH = 9 * inch + 2 * PCB_OFF
BEND_R = 10 * mm
# EDGE_THICKNESS = 3 * mm
EDGE_THICKNESS = .075 * inch

MARGIN = 1 * inch

__version__ = 'std1.0' # refers to mechichanical version.

def setDir(_directory='Faceplates_v2'):
    '''
    Set the global directory variable
    '''
    global directory
    directory = _directory
    return True
setDir()
    
mount_r =  1.5 * mm
corner_holes = array([ ## mount posts
        (        .15 * inch,          .15 * inch, mount_r),
        (        .15 * inch, HEIGHT - .15 * inch, mount_r),
        (WIDTH - .15 * inch,          .15 * inch, mount_r),
        (WIDTH - .15 * inch, HEIGHT - .15 * inch, mount_r)])


fontdir = '/home/justin/Documents/Arduino/clockthree/Faceplate/fonts/'
fontdir = './fonts/'
fontpath = ['./fonts/', '/home/justin/Documents/googlefontdirectory/']
fontnames = ['HELVETICA-BOLD', 'Helvetica-Bold',
             'HELVETICA', 'Helvetica','Times-Roman','TIMES-ROMAN'
             ]

def add_font(fontname, path=None):
    fontname = fontname.upper()
    if fontname not in fontnames:
        if path is None:
            def addit(args, d, names):
                for fn in names:
                    FN = fn.upper()
                    if FN[:-4] == fontname and FN[-4:] == '.TTF':
                        pdfmetrics.registerFont(TTFont(FN[:-4], os.path.join(d, fn)))
                        fontnames.append(fontname)
                        if not os.path.exists(os.path.join('./fonts/', fn)):
                            source = open(os.path.join(d, fn), 'rb')
                            dest = open(os.path.join('./fonts/', fn), 'wb')
                            dest.write(source.read())
                            dest.close()
                        break
            for fontdir in fontpath:
                os.path.walk(fontdir, addit, ())
                if fontname in fontnames:
                    break
        else:
            path = '%s/%s.ttf' % (path, fontname)
            pdfmetrics.registerFont(TTFont(fontname, path))
            fontnames.append(fontname)
    return fontname in fontnames

def drawline(p, x0, y0, x1, y1, linewidth=1):
    p.moveTo(x0, y0)
    p.lineTo(x1, y1)

def outline(color=red):
    p = MyPath(color=color)
    p.moveTo(0, 0)
    p.lineTo(WIDTH, 0)
    p.lineTo(WIDTH, HEIGHT)
    p.lineTo(0, HEIGHT)
    p.lineTo(0, 0)
    
    return p

def new_canvas(basename):
    can = canvas.Canvas('%s/%sjr_%s.pdf' % (directory, basename, __version__),
                        pagesize=(WIDTH + 2 * MARGIN, HEIGHT + 2 * MARGIN))
    return can
def create_faceplate(basename, style, case, font, fontsize, reverse=True, color=None,
                     can=None, showtime=False, who=None, baffles=False, do_corner_holes=True,
                     top=None,
                     bottom=None,
                     NIL=False,
                     edgecolor=red):
    if font.title().startswith('Helvetica'):
        font = font.title()
    elif font.title().startswith('Times-Roman'):
        font = font.title()
    else:
        font = font.upper()

    if can is None:
        can = new_canvas(basename)
        save_can = True
    else:
        save_can = False
    can.saveState()

    if save_can:
        can.setFont('Courier', 18)
        can.drawCentredString(W / 2 + MARGIN, HEIGHT+1.5*MARGIN, "%s %s" % (basename, __version__))
    if who:
        can.drawCentredString(W / 2 + MARGIN, .5*MARGIN, who)
    can.setFont(font, fontsize)

    if reverse:
        can.translate(W + 2 * MARGIN, 0)
        can.scale(-1, 1)
    else:
        can.drawCentredString(W / 2 + MARGIN, H/2 - MARGIN, "BACKWARDS, DO NOT PRINT")
    #     can.drawCentredString(W / 2 + MARGIN, HEIGHT + 1.5 * MARGIN, "If you can read this, do not print!")

    if top:
        print H  / inch
        can.drawCentredString(WIDTH / 2 + MARGIN, HEIGHT - 1.3 * inch + MARGIN, top)
    if bottom:
        lines = bottom.splitlines()
        line_h = .4 * inch
        start_y = .5 * inch + MARGIN + len(lines) * line_h
        for i, l in enumerate(lines):
            can.drawCentredString(WIDTH / 2 + MARGIN, start_y - i * line_h, l)
    if color:
        can.setFillColor(color)
        can.rect(MARGIN, MARGIN, WIDTH, HEIGHT, fill=True)
        can.setFillColor(white)

    can.translate(MARGIN, MARGIN)

    if NIL:
        NIL_LED_X = (WIDTH - 3 * inch) / 2
        NIL_LED_Y = HEIGHT - .75 * inch
        NIL_DX = 0.3 * inch
        NIL_DY = .36 * inch
        for i in range(10):
            x = NIL_LED_X + i * NIL_DX
            for j in range(2):
                y = NIL_LED_Y + j * NIL_DY
                can.rect(x, y, .1*inch, .2 * inch, fill=False)

    print edgecolor == black
    p = outline(color=edgecolor)
    if do_corner_holes:
        for hole in corner_holes:
            p.drill(*hole)
    p.drawOn(can, linewidth)
    
    x0 = (WIDTH - pcb_w)/2 + .2 * inch
    dx = 0.4 * inch
    nx = 16

    y0 = 2.05 * inch
    dy = 0.7 * inch
    ny = 8

    baffle_xs = arange(nx + 1) * dx + x0 - dx/2
    baffle_ys = arange(ny + 1) * dy + y0 - dy/2

    led_xs = arange(nx) * dx + x0
    led_ys = (arange(ny) * dy + y0)[::-1]
    if type(style) == type(''):
        lines = style.strip().splitlines()
    else:
        lines = style

################################################################################
    encName = 'winansi'
    encName = 'utf-8'
    decoder = codecs.lookup(encName)[1]
    def decodeFunc(txt):
        if txt is None:
            return ' '
        else:
            return case(decoder(txt, errors='replace')[0])
    def decodeFunc(txt):
        if txt is None:
            return ' '
        else:
            return txt
    lines = [[decodeFunc(case(char)) for char in line] for line in lines]
    print '\n'.join([''.join(l) for l in lines])
################################################################################

    can.setFont(font, fontsize)

    asc, dsc = pdfmetrics.getAscentDescent(font,fontsize)
    if case('here') == 'HERE':
        v_off = asc/2
    else:
        v_off = asc/3
        if 'thegirlnextdoor' in font.lower():
            v_off = asc/5
    if 'italic' in font.lower():
        h_off = pdfmetrics.stringWidth('W', font, fontsize) / 8.
    else:
        h_off = 0
    
    if showtime:
        can.setFillColor((.1, .1, .1))
    xmin = min(baffle_xs)
    xmax = max(baffle_xs)
    ymin = min(baffle_ys)
    ymax = max(baffle_ys)
    if baffles: ## DRAW_GRID???
        p = MyPath()
        for x in baffle_xs:
            drawline(p, x, ymin, x, ymax)
        for y in baffle_ys:
            drawline(p, xmin, y, xmax, y)
        p.drawOn(can, linewidth=1)

    for i, y in enumerate(led_ys):
        for j, x in enumerate(led_xs):
            # can.circle(x, y, 2.5 * mm, fill=False)
            if len(lines[i]) > j:
                can.drawCentredString(x - h_off, y  - v_off, case(lines[i][j]))
                # can.drawCentredString(x - h_off, y  - v_off, (lines[i][j]).upper())
    if showtime:
        can.setFillColor((1, 1, 1))
        timechars = [[0, 0], [0, 1],  # it 
                [0, 3], [0, 4],  # is
                [1, 0], [1, 1], [1, 2], [1, 3], # five
                [2, 3], [2, 4], # to
                [3, 0], [3, 1], [3, 2], [3, 3], [3, 4], # three
                [5, 10], [5, 11], [5, 13], [5, 14], [5, 15], # in the
                [6, 8], [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14], # morning
                ]
        for i, j in timechars:
            can.drawCentredString(led_xs[j], led_ys[i]  - v_off, case(lines[i][j]))
            
        
    if save_can:
        can.showPage()
        can.save()
        print 'wrote', can._filename
    try:
        can.restoreState()
    except:
        pass
    return can._filename


def curve(path, center, radius, tstart, tstop):
    '''add an arc to path
    tstart/tstop in degrees
    '''
    center = array(center)
    if tstart > tstop:
        dt = -1.
    else:
        dt = 1.
    for t in arange(tstart, tstop, dt) * DEG:
        pt = center + [radius * cos(t), radius * sin(t)]
        path.lineTo(*pt)
    pt = center + [radius * cos(tstop * DEG), radius * sin(tstop * DEG)]
    path.lineTo(*pt)
    return path
    
linewidth = None
W = WIDTH + 2 * MARGIN
H = HEIGHT + 2 * MARGIN

def button_hole(x, y, p):
    w = .3 * inch
    h = .3 * inch
    p.translate(-x + w/2, -y + w/2)
    p.moveTo(0, 0)
    p.lineTo(w, 0)
    p.lineTo(w, h)
    p.lineTo(0, h)
    p.lineTo(0, 0)
    p.translate(x - w/2, y - w/2)
    return p


pcb_w = 6.4 * inch
pcb_h = 9 * inch
def create_backplate():
    can = canvas.Canvas('%s/backplate_jr_%s.pdf' % (directory, __version__),
                        pagesize=(WIDTH + 2 * MARGIN, HEIGHT + 2 * MARGIN))
    can.drawCentredString(WIDTH / 2, -MARGIN / 2, "ClockTHREEjr_v2 Backplate %s" % __version__)
    if False:
        can.translate(W + 2 * MARGIN, 0)
        can.scale(-1, 1)
    can.translate(MARGIN, MARGIN)

    p = outline()


    for hole in corner_holes:
        p.drill(*hole)

    cord_r = .1 * inch
    p.moveTo(0, .5*inch + cord_r)
    p.lineTo(cord_r, .5*inch + cord_r)
    center = array((cord_r, .5*inch))
    for theta in arange(90, -90, -1) * DEG:
        p.lineTo(center + [cord_r * cos(theta), cord_r * sin(theta)])
    p.lineTo(0, .5*inch - cord_r)
    p.drawOn(can, linewidth)
    if True:
        keyhole = Keyhole([1 * inch, 8 * inch])
        keyhole.drawOn(can, linewidth)
        keyhole = Keyhole([WIDTH - 1 * inch, 8 * inch])
        keyhole.drawOn(can, linewidth)

    pcb = MyPath()
    if False:
        pcb.rect([0, 0,
                  pcb_w, pcb_h,])

    
    pcb_mounts = [[.2 * inch, 1.5*inch, mount_r],
                  [.2 * inch, pcb_h - 1.5 * inch, mount_r],
                  [pcb_w - .2 * inch, 1.5*inch, mount_r],
                  [pcb_w - .2 * inch, pcb_h - 1.5 * inch, mount_r],
                    ]
    for hole in pcb_mounts:
        pcb.drill(*hole)
    labels = 'RST MODE DEC INC ENT'.split()
    for i in range(5):
        x = pcb_w - .5*inch - i * .6 * inch
        y = pcb_h - .4 * inch
        button_hole(x, y, pcb)

        can.drawCentredString(x + (WIDTH - pcb_w)/2, y + .25 * inch + PCB_OFF, labels[i])
    ## thumbwheel
    x = pcb_w - .5 * inch - 5 * .6 * inch
    y = pcb_h - .5 * inch
    pcb.drill(x, y, .25 * inch)
    can.drawCentredString(x + (WIDTH - pcb_w)/2, pcb_h - .4 * inch + .25 * inch + PCB_OFF, 'DIM')
    pcb.rect([pcb_w - .44 * inch - .62 * inch, .44 * inch,
              .62 * inch, .12 * inch])
    can.rotate(90)
    x = pcb_w - .44 * inch - .62 * inch + (WIDTH - pcb_w)/2
    y = .32 * inch
    can.drawCentredString(y - .04 * inch, -x,'GRN')
    can.drawCentredString(y, -x - .75 * inch,'BLK')
    can.rotate(-90)
    

    pcb.translate((WIDTH - pcb_w)/2, PCB_OFF)
    pcb.drawOn(can, linewidth)


    can.save()
    print 'wrote', can._filename



BAFFLE_H = 20.00 * mm - 3.9 * mm
BAFFLE_T = .076 * inch
W = 9 * inch
H = 5 * inch
PAGE_MARGIN = 1 * inch
DX = .4 * inch
DY = .7 * inch

h_baffle = c3jr_h_baffle(BAFFLE_H,
                         BAFFLE_T,
                         n_notch=17,
                         delta=DX,
                         overhangs=(BAFFLE_T/2, BAFFLE_T/2),
                         overhang_heights=(None, None),
                         overhang_tapers=(False, False),
                         board_hooks=(5*mm, 5*mm),
                         board_hooks_up=False,
                         margin=0.016
                         )
v_baffle = c3jr_v_baffle(BAFFLE_H,
                         BAFFLE_T,
                         n_notch=9,
                         delta=DY,
                         overhangs=(.15 * inch, .15 * inch),
                         overhang_heights=(None, None),
                         overhang_tapers=(True, True),
                         margin=0.016
                         )
def create_baffles():
    localizer = MyPath()
    lw = .34 * inch
    localizer.drill(lw/2, lw/2, 1.5 * mm)
    localizer.drill(lw/2, lw/2, 4.5 * mm)

    can = canvas.Canvas('%s/baffles_jr_%s.pdf' % (directory, __version__),
                        pagesize=(W, H))
    can.translate(PAGE_MARGIN, PAGE_MARGIN)
    can.setFont('Courier', 15)

    h_baffle.translate(0, .5*inch)
    can.drawCentredString(2 * inch, .25 * inch, 'H baffle: 10 per clock')

    v_baffle.translate(0, 2*inch)
    can.drawCentredString(2 * inch, 1.75 * inch, 'V baffle: 18 per clock')

    localizer.translate(0, 3 * inch)
    can.drawCentredString(1.75 * inch, 3.2 * inch, 'localizer: 4 per clock')

    h_baffle.drawOn(can, linewidth)
    v_baffle.drawOn(can, linewidth)
    localizer.drawOn(can, linewidth)
    can.drawCentredString(2.5 * inch, -.75* inch, 'ClockTHREE_v2 Baffles 0.06" BLACK Acrylic')

    can.showPage()
    can.save()
    print 'wrote', can._filename

def makeGlam():
    add_all_fonts()
    directory = 'GlamShots'
    can = canvas.Canvas('%sjr_%s.pdf' % ('GlamShots', __version__),
                        pagesize=(WIDTH + 2 * MARGIN, HEIGHT + 2 * MARGIN))
    can.drawCentredString(WIDTH / 2, HEIGHT+1.5*MARGIN, "English_v3")
    can.showPage()
    for font in fontnames:
        for case in [lower, upper]:
            try:
                case_str = ['UPPER', 'lower'][case == lower]
                create_faceplate('english_v3 %s %s' % (font, case_str), english_v3, case, font, 35, False,
                                 color=black, can=can, showtime=False)
                can.showPage()
                create_faceplate('english_v3 %s %s' % (font, case_str), english_v3, case, font, 35, False,
                                 color=black, can=can, showtime=True)
                can.showPage()
            except Exception, e:
                pass
    can.save()
    print 'wrote', can._filename

if __name__ == '__main__':
    create_backplate()
    create_baffles()
    add_font('Kranky')
    add_font('JosefinSans-Regular')    
    font = 'JosefinSans-Regular'
    create_faceplate('%s_lower_v2' % font, english_v3, lower, font, 35, 
                     reverse=True,
                     color=None)
    if False: ## test a single font
        add_font('plantin', 'fonts/CustomerFonts/plantin.ttf')
        create_faceplate('eng_plantin_lower_v3', english_v3, lower, 'plantin', 35, False,
                         color=None)
        create_faceplate('eng_plantin_lower_v3_blk_', english_v3, lower, 'plantin', 35, False,
                         color=black, showtime=True)

