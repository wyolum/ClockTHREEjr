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

from cnc import MyPath

def create_baffle(baffle_height, 
                  baffle_thickness, 
                  n_notch, 
                  delta,
                  overhang=0,
                  overhang_height=None,
                  overhang_taper=False,
                  margin=MARGIN):
    '''
    delta = DX/DY
    overhang = amount of extra plastic from center of last notch    
    overhang_height = height of overhang.  if None, baffle_height
    margin = extra gap for slots
    '''
    return asym_baffle(baffle_height, 
                       baffle_thickness, 
                       n_notch, 
                       delta,
                       overhangs=(overhang, overhang),
                       overhang_heights=(overhang_height, overhang_height),
                       overhang_tapers=(overhang_taper, overhang_taper),
                       margin=MARGIN)

def asym_baffle(baffle_height, 
                baffle_thickness, 
                n_notch, 
                delta,
                overhangs=(0,0),
                overhang_heights=(None,None),
                overhang_tapers=(False, False),
                board_catches=(False, False),
                margin=MARGIN):
    '''
    delta = DX/DY
    overhangs = amount of extra plastic from center of last notch    
    overhang_heights = height of overhang.  if None, baffle_height
    overhang_tapers = straight~False, tapered~True,
    board_catches = hooks to grab the board and hold the baffle in place.
    margin = extra gap for slots
    '''

    overhang_heights = list(overhang_heights)
    for i in range(2):
        if overhang_heights[i] is None:
            overhang_heights[i] = baffle_height

    p = MyPath()
    p.moveTo(0, 0)
    if overhangs[0] > 0:
        p.lineTo(-overhangs[0], 0)
        if overhang_tapers[0]:
            p.lineTo(-overhangs[0], overhang_heights[0]/2.)
        else:
            p.lineTo(-overhangs[0], overhang_heights[0])
        p.lineTo(-baffle_thickness / 2. - margin, overhang_heights[0])
        p.lineTo(-baffle_thickness / 2. - margin,
                  baffle_height / 2 - margin)
    p.lineTo(0, baffle_height / 2 - margin)
    for i in range(n_notch):
        p.lineTo(i * delta + baffle_thickness / 2. + margin,
                  baffle_height / 2 - margin)
        p.lineTo(i * delta + baffle_thickness / 2. + margin,
                  baffle_height)

        p.lineTo((i + 1) * delta - baffle_thickness / 2. - margin,
                  baffle_height)
        p.lineTo((i + 1) * delta - baffle_thickness / 2. - margin,
                  baffle_height / 2 - margin)
        p.lineTo((i + 1) * delta,
                  baffle_height / 2 - margin)
    if overhangs[1] > 0:
        p.lineTo(n_notch * delta + baffle_thickness / 2 + margin,
                 baffle_height / 2 - margin)
        p.lineTo(n_notch * delta + baffle_thickness / 2 + margin,
                 overhang_heights[1])
        if overhang_tapers[1]:
            p.lineTo(n_notch * delta + overhangs[1], overhang_heights[1]/2)
        else:
            p.lineTo(n_notch * delta + overhangs[1], overhang_heights[1])
        p.lineTo(n_notch * delta + overhangs[1], 0)
    p.lineTo(n_notch * delta, 0)
    p.lineTo(0, 0)
    return p

BOARD_THICKNESS = 0.06 * inch
def peggy_baffle(baffle_height, 
                 baffle_thickness, 
                 n_notch, 
                 delta,
                 overhangs=(0,0),
                 overhang_heights=(None,None),
                 overhang_tapers=(False, False),
                 board_hooks=(False, False),
                 board_hooks_up=False,
                 margin=MARGIN,
                 skip_notches=()):
    '''
    delta = DX/DY
    overhangs = amount of extra plastic from center of last notch    
    overhang_heights = height of overhang.  if None, baffle_height
    overhang_tapers = straight~False, tapered~True,
    board_hooks = hooks to grab the board and hold the baffle in place.
    margin = extra gap for slots
    '''

    overhang_heights = list(overhang_heights)
    for i in range(2):
        if overhang_heights[i] is None:
            overhang_heights[i] = baffle_height

    p = MyPath()
    p.moveTo(0, 0)
    if overhangs[0] > 0:
        p.lineTo(-overhangs[0], 0)
        if overhang_tapers[0]:
            p.lineTo(-overhangs[0], overhang_heights[0]/2.)
        elif board_hooks[0]:
            if board_hooks_up: ## h baffles
                p.lineTo(-overhangs[0] - board_hooks[0], 0)
                p.lineTo(-overhangs[0] - board_hooks[0], 
                          overhang_heights[0] + BOARD_THICKNESS)
                p.lineTo(-overhangs[0],
                          overhang_heights[0] + BOARD_THICKNESS)
                p.lineTo(-overhangs[0],
                          overhang_heights[0])
            else: ## v baffles
                p.lineTo(-overhangs[0], -BOARD_THICKNESS)
                p.lineTo(-overhangs[0] - board_hooks[0], -BOARD_THICKNESS)
                p.lineTo(-overhangs[0] - board_hooks[0], baffle_height)
                p.lineTo(-overhangs[0], baffle_height)
        else:
            p.lineTo(-overhangs[0], overhang_heights[0])
        p.lineTo(-baffle_thickness / 2. - margin, overhang_heights[0])
    for i in range(n_notch - 1):
        if i in skip_notches:
            p.lineTo((i + 0) * delta, baffle_height)
        else:
            p.lineTo(i * delta - baffle_thickness / 2. - margin,
                     baffle_height)
            p.lineTo(i * delta - baffle_thickness / 2. - margin,
                     baffle_height/2 - margin)
            p.lineTo(i * delta + baffle_thickness / 2. + margin,
                     baffle_height/2 - margin)
            p.lineTo(i * delta + baffle_thickness / 2. + margin,
                     baffle_height)
            p.lineTo((i + 1) * delta - baffle_thickness / 2. - margin,
                     baffle_height)
    if n_notch - 1 not in  skip_notches:
        ## do last notch
        i = n_notch - 1
        p.lineTo(i * delta - baffle_thickness / 2. - margin,
                 baffle_height)
        p.lineTo(i * delta - baffle_thickness / 2. - margin,
                 baffle_height/2 - margin)
        p.lineTo(i * delta + baffle_thickness / 2. + margin,
                 baffle_height/2 - margin)
    if overhangs[1] > 0:
        p.lineTo((n_notch - 1) * delta + baffle_thickness / 2 + margin,
                 baffle_height / 2 - margin)
        p.lineTo((n_notch - 1) * delta + baffle_thickness / 2 + margin,
                 overhang_heights[1])
        if overhang_tapers[1]:
            p.lineTo((n_notch - 1) * delta + overhangs[1], overhang_heights[1]/2)
        elif board_hooks[1]:
            x0 = (n_notch - 1) * delta + overhangs[1]
            if board_hooks_up:
                p.lineTo(x0, overhang_heights[1])
                p.lineTo(x0, overhang_heights[1] + BOARD_THICKNESS)
                p.lineTo(x0 + board_hooks[1], 
                         overhang_heights[1] + BOARD_THICKNESS)
                p.lineTo(x0 + board_hooks[1], 0)
                p.lineTo(x0, 0)
            else:
                p.lineTo(x0 + board_hooks[1], baffle_height)
                p.lineTo(x0 + board_hooks[1], -BOARD_THICKNESS)
                p.lineTo(x0, -BOARD_THICKNESS)
                p.lineTo(x0, 0)
        else:
            p.lineTo((n_notch - 1) * delta + overhangs[1], overhang_heights[1])
        p.lineTo((n_notch - 1) * delta + overhangs[1], 0)
    p.lineTo((n_notch - 1) * delta, 0)
    p.lineTo(0, 0)
    return p

def c3jr_h_baffle(baffle_height, 
                  baffle_thickness, 
                  n_notch, 
                  delta,
                  overhangs=(0,0),
                  overhang_heights=(None,None),
                  overhang_tapers=(False, False),
                  board_hooks=(False, False),
                  board_hooks_up=False,
                  margin=MARGIN,
                  skip_notches=()):
    '''
    delta = DX/DY
    overhangs = amount of extra plastic from center of last notch    
    overhang_heights = height of overhang.  if None, baffle_height
    overhang_tapers = straight~False, tapered~True,
    board_hooks = hooks to grab the board and hold the baffle in place.
    margin = extra gap for slots
    '''
    overhang_heights = list(overhang_heights)
    for i in range(2):
        if overhang_heights[i] is None:
            overhang_heights[i] = baffle_height

    p = MyPath()
    p.moveTo(0, 0)
    if overhangs[0] > 0:
        if board_hooks[0]:
            if not board_hooks_up: ## h baffles
                p.lineTo(-0.25 * mm, 0)
                p.lineTo(-0.25 * mm, -BOARD_THICKNESS)
                p.lineTo( - board_hooks[0], -BOARD_THICKNESS)
                p.lineTo( - board_hooks[0], baffle_height)
                p.lineTo(-overhangs[0], baffle_height)
        else:
            p.lineTo(-overhangs[0], overhang_heights[0])
        p.lineTo(-baffle_thickness / 2. - margin, overhang_heights[0])
    for i in range(n_notch - 1):
        if i in skip_notches:
            p.lineTo((i + 0) * delta, baffle_height)
        else:
            p.lineTo(i * delta - baffle_thickness / 2. - margin,
                     baffle_height)
            p.lineTo(i * delta - baffle_thickness / 2. - margin,
                     baffle_height/2 - margin)
            p.lineTo(i * delta + baffle_thickness / 2. + margin,
                     baffle_height/2 - margin)
            p.lineTo(i * delta + baffle_thickness / 2. + margin,
                     baffle_height)
            p.lineTo((i + 1) * delta - baffle_thickness / 2. - margin,
                     baffle_height)
    if n_notch - 1 not in  skip_notches:
        ## do last notch
        i = n_notch - 1
        p.lineTo(i * delta - baffle_thickness / 2. - margin,
                 baffle_height)
        p.lineTo(i * delta - baffle_thickness / 2. - margin,
                 baffle_height/2 - margin)
        p.lineTo(i * delta + baffle_thickness / 2. + margin,
                 baffle_height/2 - margin)
    if overhangs[1] > 0:
        p.lineTo((n_notch - 1) * delta + baffle_thickness / 2 + margin,
                 baffle_height / 2 - margin)
        p.lineTo((n_notch - 1) * delta + baffle_thickness / 2 + margin,
                 overhang_heights[1])
        if overhang_tapers[1]:
            p.lineTo((n_notch - 1) * delta + overhangs[1], overhang_heights[1]/2)
        elif board_hooks[1]:
            x0 = (n_notch - 1) * delta 
            if not board_hooks_up:
                p.lineTo(x0 + board_hooks[1], baffle_height)
                p.lineTo(x0 + board_hooks[1], -BOARD_THICKNESS)
                p.lineTo(x0 + 0.25 * mm, -BOARD_THICKNESS)
                p.lineTo(x0 + 0.25 * mm, 0)
        p.lineTo((n_notch - 1) * delta + MARGIN, 0)
    p.lineTo((n_notch - 1) * delta + MARGIN, 0)
    p.lineTo(0, 0)
    return p

def c3jr_v_baffle(baffle_height, 
                  baffle_thickness, 
                  n_notch, 
                  delta,
                  overhangs=(0,0),
                  overhang_heights=(None,None),
                  overhang_tapers=(False, False),
                  margin=MARGIN,
                  skip_notches=()):
    '''
    delta = DX/DY
    overhangs = amount of extra plastic from center of last notch    
    overhang_heights = height of overhang.  if None, baffle_height
    overhang_tapers = straight~False, tapered~True,
    margin = extra gap for slots
    '''

    overhang_heights = list(overhang_heights)
    for i in range(2):
        if overhang_heights[i] is None:
            overhang_heights[i] = baffle_height

    p = MyPath()
    p.moveTo(0, 0)
    p.lineTo(-overhangs[0], 0)
    p.lineTo(-overhangs[0], overhang_heights[0]/2.)
    p.lineTo(-baffle_thickness / 2. - margin, overhang_heights[0] * 3/4.)

    for i in range(n_notch - 1):
        p.lineTo(i * delta - baffle_thickness / 2. - margin,
                 baffle_height/2 - margin)
        p.lineTo(i * delta + baffle_thickness / 2. + margin,
                 baffle_height/2 - margin)
        p.lineTo(i * delta + baffle_thickness / 2. + margin,
                 baffle_height)
        p.lineTo((i + 1) * delta - baffle_thickness / 2. - margin,
                 baffle_height)
    ## do last notch
    i = n_notch - 1
    p.lineTo(i * delta - baffle_thickness / 2. - margin,
             baffle_height)
    p.lineTo(i * delta - baffle_thickness / 2. - margin,
             baffle_height/2 - margin)
    p.lineTo(i * delta + baffle_thickness / 2. + margin,
             baffle_height/2 - margin)

    # do last taper
    p.lineTo(i * delta + baffle_thickness / 2 + margin,
             overhang_heights[1] * 3 / 4.)
    if overhang_tapers[1]:
        p.lineTo((n_notch - 1) * delta + overhangs[1], overhang_heights[1]/2)
    else:
        p.lineTo((n_notch - 1) * delta + overhangs[1], overhang_heights[1])
    p.lineTo((n_notch - 1) * delta + overhangs[1], 0)
    p.lineTo((n_notch - 1) * delta, 0)
    p.lineTo(0, 0)
    return p

def folded_h_baffle():
    BAFFLE_H = 20.00 * mm - 3.9 * mm
    BAFFLE_T = .076 * inch
    dx = 0.4 * inch
    dy = 0.7 * inch

    h_baffle = c3jr_h_baffle(BAFFLE_H,
                             BAFFLE_T,
                             n_notch=33,
                             delta=dx,
                             overhangs=(BAFFLE_T/2, BAFFLE_T/2),
                             overhang_heights=(None, None),
                             overhang_tapers=(False, False),
                             board_hooks=(5*mm, 5*mm),
                             board_hooks_up=False,
                             margin=0.016
                             )


def test():
    create_baffle(1 * inch,
                  .06 * inch,
                  5,
                  .75 * inch,
                  overhang=.5 * inch,
                  overhang_height=None,
                  overhang_taper=True)

    
