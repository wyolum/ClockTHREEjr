from numpy import *
import os.path
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import glob
import os.path

import PIL.Image
from numpy import array, sin, cos, dot, arange
from constants import *
from copy import deepcopy
from reportlab.pdfgen import canvas
from reportlab.graphics import renderPDF
from reportlab.graphics.shapes import Drawing, Group, String, Circle, Rect
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle
from reportlab.lib.colors import pink, black, red, blue, green, white

class MyText(object):
    def __init__(self, x, y, txt, fontname=None, fontsize=12, centered=True, color=black):
        self.x = x
        self.y = y
        self.fontname = fontname
        self.fontsize = fontsize
        self.centered = centered
        self.txt = txt
        self.color = color

    def drawOn(self, can):
        can.saveState()
        can.setFillColor(self.color)        
        if self.fontname:
            can.setFont(self.fontname, self.fontsize)
        if self.centered:
            can.drawCentredString(self.x, self.y, self.txt)
        else:
            can.drawString(self.x, self.y, self.txt)
        can.restoreState()
    def translate(self, dx, dy): 
        self.x =  self.x + dx
        self.y = self.y + dy

class MyPath:
    UNIT = mm
    def __init__(self, color=red):
        self.points = []
        self.paths = []
        self.holes = []
        self.subtract = []
        self.linewidth = LASER_THICKNESS
        self.texts = []
        self.color = color

    def addText(self, x, y, txt, fontname=None, fontsize=12, centered=True, color=black):
        self.texts.append(MyText(x, y, txt, fontname=fontname, fontsize=fontsize, centered=True, color=color))

    def getLast(self):
        if len(self.points) > 0:
            out = array(self.points[-1])
        else:
            out = None
        return out
    last = property(getLast)
    def copy(self):
        out = MyPath()
        out.points = deepcopy(self.points)
        out.paths = deepcopy(self.paths)
        out.holes = deepcopy(self.holes)
        out.subtract = deepcopy(self.subtract)
        return out
    def add(self, other):
        end = self.points[-1]
        start = other.points[0]
        for p in other.points[1:]:
            x = p[0] - start[0] + end[0]
            y = p[1] - start[1] + end[1]
            self.lineTo(x, y)
        return self
    def reverse(self):
        self.points = self.points[::-1]
        return self

    def moveTo(self, x, y):
        self.points.append([x, y])
        self.paths.append([])
        self.paths[-1].append(len(self.points) - 1)
    def lineTo(self, x, y=None):
        if y is None:
            x, y = x
        self.points.append([x, y])
        self.paths[-1].append(len(self.points) - 1)
    def curveTo(self, x, y, radius):
        last = array(self.paths[-1][-1])
        assert radius / 2 > linalg.norm(last - [x, y]), 'radius too small'
        raise Exception('not implimented')

    def getleft(self):
        return min([l[0] for l in self.points])
    def getright(self):
        return max([l[0] for l in self.points])
    def getwidth(self):
        return self.getright() - self.getleft()
    def getbottom(self):
        return min([l[1] for l in self.points])
    def gettop(self):
        return max([l[1] for l in self.points])
    def getheight(self):
        return self.getop() - self.getbottom()
    
    def toPDF(self, filename):
        W = self.getright() - self.getleft()
        H = self.gettop() - self.getbottom()
        c = canvas.Canvas(filename,
                          pagesize=(W + .5 * inch, H + .5 * inch)
                          )
        c.setLineWidth(self.linewidth)
        self.translate(-self.getleft() + .25 * inch, -self.getbottom() + .25 * inch)
        self.drawOn(c)
        return c

    def drawOn(self, c, linewidth=None, color=None, segmentate=False):
        if linewidth is None:
            linewidth = self.linewidth
        if color is None:
            color = self.color
        c.setStrokeColor(color)
        c.setLineWidth(linewidth)
        if segmentate:
            length, height = c._pagesize

            for path in self.paths:
                for start, stop in zip(path[:-1], path[1:]):
                    start = self.points[start]
                    stop = self.points[stop]
                    p = c.beginPath()
                    p.moveTo(*start)
                    p.lineTo(*stop)
                    c.drawPath(p)

        else:
            p = c.beginPath()
            for path in self.paths:
                p.moveTo(*self.points[path[0]])
                for i in path[1:]:
                    p.lineTo(*self.points[i])
            c.drawPath(p)
        for x, y, r in self.holes:
            c.circle(x, y, r)
        for poly in self.subtract:
            poly.drawOn(c, linewidth=linewidth)
        for txt in self.texts:
            txt.drawOn(c)

    def rotate(self, rotate_deg, center=None, copy=False):
        if copy:
            self = self.copy()
        if center is not None:
            self.points = [array(p) - center for p in self.points]
        theta = rotate_deg * pi / 180.
        rot_mat = array([[cos(theta), sin(theta)],
                         [-sin(theta), cos(theta)]])
        self.points = list(dot(self.points, rot_mat))
        for xyr in self.holes:
            x, y = dot(rot_mat, xyr[:2])
            xyr[0] = x
            xyr[1] = y
        if center is not None:
            self.points = [array(p) + center for p in self.points]
        return self

    def translate(self, dx, dy, copy=False):
        if copy:
            self = self.copy()
        for l in self.points:
            l[0] += dx
            l[1] += dy
        for xyr in self.holes:
            xyr[0] += dx
            xyr[1] += dy
        for s in self.subtract:
            s.translate(dx, dy)
        for txt in self.texts:
            txt.translate(dx, dy)
        return self

    def scale(self, f, copy=False):
        if copy:
            self = self.copy()
        for l in self.points:
            l[0] *= f
            l[1] *= f
        for xyr in self.holes:
            xyr[0] *= f
            xyr[1] *= f
            xyr[2] *= f
        for s in self.subtract:
            s.scale(f)
        return self
    def rect(self, bbox):
        self.moveTo(bbox[0], bbox[1])
        self.lineTo(bbox[0] + bbox[2], bbox[1])
        self.lineTo(bbox[0] + bbox[2], bbox[1] + bbox[3])
        self.lineTo(bbox[0], bbox[1] + bbox[3])
        self.lineTo(bbox[0], bbox[1])
        
    def drill(self, x, y, r):
        self.holes.append([x, y, r])
    def route(self, polygon):
        self.subtract.append(deepcopy(polygon))
    def getBottom(self):
        return min(l[1] for l in self.points)
    def getTop(self):
        return max(l[1] for l in self.points)
    def getLeft(self):
        return min(l[0] for l in self.points)
    def getRight(self):
        return max(l[0] for l in self.points)
    def toOpenScad(self, thickness, outfile, module_name=None, color=None):
        if module_name is not None:
            print >> outfile, 'module %s(){' % module_name
        if color is not None:
            print >> outfile, 'color([%s, %s, %s, %s])' % tuple(color)
        if len(self.holes) > 0 or len(self.subtract) > 0:
            print >> outfile, 'difference(){'
        print >> outfile, '''\
linear_extrude(height=%s, center=true, convexity=10, twist=0)
polygon(points=[''' % (thickness / self.UNIT)
        for x, y in self.points:
            print >> outfile, '[%s, %s],' % (x / self.UNIT, y / self.UNIT)
        print >> outfile, '],'
        print >> outfile, 'paths=['
        for path in self.paths:
            print >> outfile, '%s,' % path
        print >> outfile, ']);'

        if len(self.holes) > 0 or len(self.subtract) > 0:
            for hole in self.holes:
                x, y, r = hole
                print >> outfile, 'translate(v=[%s, %s, %s])' % (x/self.UNIT, y/self.UNIT, -5*inch)
                print >> outfile, 'cylinder(h=%s, r=%s, $fn=25);' % (10*inch, r / self.UNIT)
            for poly in self.subtract:
                print >> outfile, '//subtract'
                ## print >> outfile, 'translate(v=[0, 0, -%s])' % (thickness / self.UNIT)
                poly.toOpenScad(thickness * 2, outfile)
            print >> outfile, '}'
        if module_name is not None:
            print >> outfile, '}'
    toScad = toOpenScad
    
def MyPath__test__():
    dy = 0.7 * inch
    dx = 0.4 * inch
    baffle_thickness = .06 * inch

    locator = MyPath()
    locator.moveTo(MARGIN, MARGIN)
    locator.lineTo(.28*inch - MARGIN, MARGIN)
    locator.lineTo(.28*inch - MARGIN, dy - baffle_thickness - MARGIN)
    locator.lineTo(MARGIN, dy - baffle_thickness - MARGIN)
    locator.lineTo(MARGIN, MARGIN)
    locator.drill((.28 * inch)/2, (dy - baffle_thickness)/2, 1.8 * mm)
    filename = 'locator_test.pdf'
    can = canvas.Canvas(filename,
                        pagesize=(8.5 * inch, 11 * inch))

    locator.drawOn(can)
    can.showPage()

    can.save()
    print 'wrote', filename
    scad_fn = 'test.scad'
    scad = open(scad_fn, 'w')
    locator.toOpenScad(baffle_thickness, scad)
    print 'wrote', scad_fn

class Image:
    def __init__(self, filename, x, y, w=None, h=None):
        self.filename = filename
        self.x = x
        self.y = y
        self.w = w
        self.h = h

    def drawOn(self, c):
        im = PIL.Image.open(self.filename)
        dims = im.size
        aspect = dims[1] / float(dims[0])
        if self.h is None and self.w is not None:
            self.h = aspect * self.w
            
        c.drawInlineImage(im, 
                          self.x, self.y, self.w, self.h)
    def translate(self, dx, dy):
        return Image(self.filename, self.x + dx, self.y + dy, self.w, self.h)

def hex(d=4.75 * mm):
    theta = arange(0, 2 * pi, pi/3)
    h = MyPath()
    h.moveTo(1, 0)
    for t in theta:
        h.lineTo(cos(t), sin(t))
    h.lineTo(1, 0)
    h.scale(d/2.)
    return h

def washer(id, od):
    p = MyPath()
    p.moveTo(id, 0)
    theta = arange(0, 361, 1) * pi / 180
    for t in theta:
        p.lineTo(id * cos(t), id * sin(t))

    p.moveTo(od, 0)
    theta = arange(0, 361, 1) * pi / 180
    for t in theta:
        p.lineTo(od * cos(t), od * sin(t))

    return p

FONT_DIR = '/home/justin/Documents/Arduino/clockthree/Faceplate/fonts/'
def findfilecb(target_dest, directory, names):
    target, dest = target_dest
    for name in names:
        if name == target:
            out = '/'.join([directory, name])
            dest[0] = out
            break
    else:
        pass

def add_font(fontname):
    arg = ['%s.ttf' % fontname, [None]]
    x = os.path.walk(FONT_DIR, findfilecb, arg)
    if arg[1][0] is not None:
        pdfmetrics.registerFont(TTFont(fontname, arg[1][0]))

def getKnob(scale=.25*inch, hole=False):
    knob = MyPath()
    knob.moveTo(-4, 0)
    cx = 2 - 2/sqrt(2) - 4
    cy = -2 + 2/sqrt(2)
    for theta in arange(-arcsin(cy) / DEG, -45, -1) * DEG:
        knob.lineTo(cx + cos(theta), cy + sin(theta))
    cx = -2
    cy = -2
    for theta in arange(180 - 45, 360 + 45, 1) * DEG:
        knob.lineTo(cx + cos(theta), cy + sin(theta))
    cx = -2 + 2 / sqrt(2)
    cy = sqrt(2) - 2
    phi = arcsin(cy)
    for theta in arange(180 + 45, 180 + phi / DEG, -1) * DEG:
        knob.lineTo(cx + cos(theta), cy + sin(theta))
    knob.lineTo(cx + cos(pi + phi), cy + sin(pi + phi))
        
    knob.lineTo(0, 0)
    knob.scale(scale)
    if hole:
        print 'hole'
        T = LASER_THICKNESS
        new_points = [knob.points[0][:], knob.points[1][:]]
        new_points[0][1] -= T / 2.
        new_points[1][0] -= T / 2.
        new_points[1][1] -= T / 2.
        for i in range(2, len(knob.points) - 2):
            dx = knob.points[i + 1][0] - knob.points[i - 1][0]
            dy = knob.points[i + 1][1] - knob.points[i - 1][1]
            norm = linalg.norm([dx, dy])
            x, y = dx / norm, dy / norm
            dperp = array([y, -x])
            new_points.append(array(knob.points[i]) + dperp * T/2)
            
        new_points.append(knob.points[-2][:])
        new_points[-1][1] -= T / 2
        new_points[-1][-0] += T / 2.
        new_points.append(knob.points[-1][:])
        new_points[-1][1] -= T / 2
        print len(new_points), len(knob.points)
        knob.points = new_points
    return knob

class Keyhole(MyPath):
        def __init__(self, Center, *args, **kw):
            MyPath.__init__(self, *args, **kw)

            # Center = 0.75 * inch, 7.5 * inch  # larger keyhole circle center
            # center = 0.75 * inch, 7.875 * inch # smaller keyhole circle center
            center = (Center[0], Center[1] + .375 * inch)
            r = .125 * inch # smaller keyhole circle radius
            R = .25 * inch  # larger keyhole circle radius
            phi = arcsin(r/R)
            
            start = Center[0] + R * cos(pi/2 + phi), Center[1] + R * sin(pi/2 + phi)
            self.moveTo(*start)
            dtheta = 1 * DEG
            for theta in arange(pi/2 + phi,
                                2 * pi + pi / 2 - phi + dtheta/2,
                                dtheta):
                next = Center[0] + R * cos(theta), Center[1] + R * sin(theta)
                self.lineTo(*next)
            for theta in arange(0, pi, dtheta):
                next = center[0] + r * cos(theta), center[1] + r * sin(theta)
                self.lineTo(*next)
            self.lineTo(*start)

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

# MyPath__test__()


