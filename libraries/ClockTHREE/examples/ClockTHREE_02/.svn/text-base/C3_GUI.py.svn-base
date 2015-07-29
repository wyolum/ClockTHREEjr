import ClockTHREE
import english
import glob
import time
from numpy import *
import Tkinter
import Pmw
import C3_interface
import serial

class Main:
    def __init__(self):
        self.root = Pmw.initialise(fontScheme='pmw1')
        self.eeprom = None
        class DatetimeField:
            def __init__(self, parent, label, tm=None, getcmd=None, setcmd=None, clearcmd=None,
                         modifiedcommand=None):
                self.tk = parent
                self.f = Tkinter.Frame(parent)
                now = time.time()
                if tm is None:
                    time_val = ''
                    date_val = ''
                else:
                    time_val = time.strftime('%H:%M:%S', tm)
                    date_val = time.strftime('%Y/%m/%d', tm)
                self.date = Pmw.EntryField(self.f,
                                           label_text=label,
                                           value=date_val,
                                           labelpos='w',
                                           validate = 'date',
                                           modifiedcommand=modifiedcommand,
                                           )
                self.time = Pmw.EntryField(self.f,
                                           value=time_val,
                                           validate='time',
                                           modifiedcommand=modifiedcommand,
                                           )
                self.set(tm)
                self.wids = [self.date, self.time]
                self.wids[0].component('entry').config(width=9)
                self.wids[1].component('entry').config(width=7)
                if setcmd:
                    self.wids.insert(0, Tkinter.Button(self.f, text='Set', command=setcmd))
                if getcmd:
                    self.wids.insert(0, Tkinter.Button(self.f, text='Get', command=getcmd))
                if clearcmd:
                    self.wids.insert(0, Tkinter.Button(self.f, text='Clear', command=clearcmd))

            def grid(self, *args, **kw):
                for i, wid in enumerate(self.wids):
                    wid.grid(row=0, column=i)
                self.f.grid(*args,**kw)
            
            def set(self, tm=None):
                if tm is None:
                    time_val = ''
                    date_val = ''
                else:
                    time_val = time.strftime('%H:%M:%S', tm)
                    date_val = time.strftime('%Y/%m/%d', tm)
                self.date.setvalue(date_val)
                self.time.setvalue(time_val)
                self.date.checkentry()
                self.time.checkentry()

            def get(self):
                if self.valid():
                    ymd = self.date.getvalue()
                    hms = self.time.getvalue()
                    tm = time.strptime(ymd + ' ' + hms, '%Y/%m/%d %H:%M:%S')
                    tm = int(round(time.mktime(tm))) + C3_interface.gmt_offset
                else:
                    raise ValueError("Date/Time not valid")
                return tm

            def valid(self):
                return self.date.valid() and self.time.valid()
        class Repeat:
            def __init__(self, parent, row, column):
                self.vars = [Tkinter.IntVar() for i in range(9)]
                self.checks = []
                for i, var in enumerate(self.vars):
                    c = Tkinter.Checkbutton(parent, text="", variable=var, command=self.on_click, borderwidth=0)
                    c.grid(row=row, column=column + i)
                    self.checks.append(c)
            def reset(self):
                for i, var in enumerate(self.vars):
                    var.set(0)
                
            def on_click(self):
                annual = self.vars[0].get()
                if annual:
                    for i, var in enumerate(self.vars[1:]):
                        var.set(False)
                        self.checks[i + 1].config(state=Tkinter.DISABLED)
                else:
                    for i, var in enumerate(self.vars[1:]):
                        self.checks[i + 1].config(state=Tkinter.NORMAL)

                m5 = self.vars[-1].get()
                if m5:
                    for i, var in enumerate(self.vars[:-1]):
                        var.set(False)
                        self.checks[i].config(state=Tkinter.DISABLED)
                else:
                    self.checks[0].config(state=Tkinter.NORMAL)

            def set(self, byte):
                if type(byte) == type(''):
                    byte = ord(byte)
                if byte == 255:
                    self.vars[-1].set(True)
                else:
                    self.vars[-1].set(False)
                    n = True
                    for i in range(8):
                        if byte & (1 << i):
                            n = False
                            self.vars[i].set(True)
                        else:
                            self.vars[i].set(False)
                    if n:
                        pass # set annual
                    else: 
                        pass # unset annual

            def get(self):
                if self.vars[-1].get():
                    byte = 255
                else:
                    byte = 0
                    for i in range(8):
                        byte |= (self.vars[i].get() << i)
                return byte
            def config(self, *args, **kw):
                for cb in self.checks:
                    cb.config(*args, **kw)

        class Countdown:
            def __init__(self, parent, row, column):
                self.radio_buttons = []
                self.var = Tkinter.IntVar()
                for i in range(6):
                    c = Tkinter.Radiobutton(parent, 
                                            text="", 
                                            variable=self.var, 
                                            value=4 - i, 
                                            borderwidth=0)
                    c.grid(row=row, column=column + i)
                    self.radio_buttons.append(c)
                self.radio_buttons[-1].select()

                self.countdown_secs = {4:86400, # one day
                                       3:3600,  # one hour
                                       2:300,   # five minutes
                                       1:60,    # one minute
                                       0:10,    # ten seconds
                                      -1:0}     # no countdown
                self.decoder = {4:0b10000,
                                3:0b01000,
                                2:0b00100,
                                1:0b00010,
                                0:0b00001,
                               -1:0b0000}
            def get_countdown_duration(self):
                return self.countdown_secs[self.var.get()]
            def reset(self):
                self.var.set(-1)
            def set(self, byte):
                if type(byte) == type(''):
                    byte = ord(byte)
                self.var.set([key for key in self.decoder if self.decoder[key] == byte][0])

            def get(self):
                try:
                    key = self.var.get()
                    out = self.decoder[key]
                except:
                    out = 0
                return out

            def config(self, *args, **kw):
                for rb in self.radio_buttons:
                    rb.config(*args, **kw)

        class DID_AlarmField:
            def __init__(self, parent, row):
                self.did = None
                self.tm = None
                self.is_beeping = Tkinter.IntVar()
                self.set_b = Tkinter.Button(parent, text='Set', command=self.on_set)
                self.set_b.grid(row=row, column=0)
                self.clear_b = Tkinter.Button(parent, text='Clear', command=self.on_clear)
                self.clear_b.grid(row=row, column=1)

                self.check_b = Tkinter.Checkbutton(parent, text="", variable=self.is_beeping, borderwidth=0)
                self.check_b.grid(row=row, column=2)
                self.when = DatetimeField(parent, '', None, getcmd=None, setcmd=None, clearcmd=None,
                                          modifiedcommand=self.on_whenchange)
                self.balloon = Pmw.Balloon(parent)
                self.balloon.bind(self.when.date, 'YYYY/MM/DD')
                self.balloon.bind(self.when.time, 'HH:MM:SS')

                self.when.grid(row=row, column=3)
                self.scrollable = Pmw.EntryField(parent, value='')
                self.scrollable.component('entry').config(width=30)
                self.scrollable.grid(row=row, column=4)
                self.repeat = Repeat(parent, row=row, column=5)
                self.countdown = Countdown(parent, row=row, column=14)
                self.row = row

                self.clear_b.config(state=Tkinter.DISABLED)
                self.set_b.config(state=Tkinter.DISABLED)
                self.disable()

            def on_whenchange(self):
                if self.did is None and hasattr(self, 'when'):
                    if self.when.valid():
                        self.set_b.config(state=Tkinter.NORMAL)
                    else:
                        self.set_b.config(state=Tkinter.DISABLED)
                else:
                    self.set_b.config(state=Tkinter.DISABLED)

            def disable(self):
                self.check_b.config(state=Tkinter.DISABLED)
                self.when.date.component('entry').config(state=Tkinter.DISABLED)
                self.when.time.component('entry').config(state=Tkinter.DISABLED)
                self.scrollable.component('entry').config(state=Tkinter.DISABLED)
                self.repeat.config(state=Tkinter.DISABLED)
                self.countdown.config(state=Tkinter.DISABLED)
                self.clear_b.config(state=Tkinter.NORMAL)

            def normal(self):
                self.check_b.config(state=Tkinter.NORMAL)
                self.when.date.component('entry').config(state=Tkinter.NORMAL)
                self.when.time.component('entry').config(state=Tkinter.NORMAL)
                self.scrollable.component('entry').config(state=Tkinter.NORMAL)
                self.repeat.config(state=Tkinter.NORMAL)
                self.countdown.config(state=Tkinter.NORMAL)
                self.clear_b.config(state=Tkinter.DISABLED)

            def reset(self):
                self.normal()
                self.when.date.component('entry').delete(0, Tkinter.END)
                self.when.time.component('entry').delete(0, Tkinter.END)
                self.when.date.checkentry()
                self.when.time.checkentry()
                self.scrollable.component('entry').delete(0, Tkinter.END)
                self.is_beeping.set(0)
                self.repeat.reset()
                self.countdown.reset()

            def set(self, tm):
                self.tm = tm
                self.when.set(tm)

            def on_set(self):
                scroll_text = self.scrollable.getvalue()
                if self.when.valid():
                    if self.did is not None:
                        C3_interface.EEPROM.singleton.delete_did_alarm(self.did)
                        self.did = None
                    self.did = C3_interface.set_alarm(self.when.get() - self.countdown.get_countdown_duration(),
                                                      self.countdown.get(),
                                                      self.repeat.get(),
                                                      scroll_text,
                                                      effect_id=0,
                                                      sound_id=self.is_beeping.get())
                    self.disable()
                    self.set_b.config(state=Tkinter.DISABLED)
                
            def on_clear(self):
                if self.did is not None:
                    C3_interface.EEPROM.singleton.delete_did_alarm(self.did)
                    self.normal()
                    self.did = None
                    self.when.set(None)
                    self.scrollable.component('entry').delete(0, Tkinter.END)
                    self.repeat.set(0)
                    self.countdown.set(0)
                    self.is_beeping.set(0)

        c3tm = self.getC3_time()
        pctm = time.localtime()
        self.control_frame = Tkinter.Frame(self.root)
        self.control_left = Tkinter.Frame(self.control_frame)
        self.control_right = Tkinter.Frame(self.control_frame)
        serialports = C3_interface.getSerialports()
        self.serialport_dd = Pmw.ComboBox(self.control_left,
                                   label_text='Serial Port:',
                                   labelpos='w',
                                   scrolledlist_items=serialports,
                                   selectioncommand=self.on_portchange,
                             )
        self.serialport_dd.component('entry').config(width=20)
        self.connect_b = Tkinter.Button(self.control_left, 
                                        text="Connect", 
                                        command=self.connect)
        self.mirror_b = Tkinter.Button(self.control_left, 
                                       text="MirrorC3", 
                                       command=self.mirror,
                                       state=Tkinter.DISABLED)
        if len(serialports) > 0:
            self.serialport_dd.selectitem(0)
            self.on_portchange(serialports[0])
        self.serialport_dd.grid(row=0, column=0)
        self.connect_b.grid(row=1,column=0)
        self.mirror_b.grid(row=2,column=0)
        self.ardtime = DatetimeField(self.control_right, 'Arduino Time', c3tm)
        self.ardtime.grid(row=0)
        self.pctime = DatetimeField(self.control_right, '       PC Time', pctm)
        self.pctime.grid(row=1)
        delta_frame = Tkinter.Frame(self.control_right)
        self.delta = Pmw.EntryField(delta_frame, 
                                    label_text='Delta Seconds:',
                                    labelpos='w',
                                    value='0',
                                    validate='real',
                                    )

        self.format_eeprom_dialog = Pmw.Dialog(self.control_frame,
                                               buttons = ('Format', 'Cancel'),
                                               defaultbutton = 'Cancel',
                                               title = 'Format EEPROM?',
                                               command = self.format_eeprom)
        self.format_eeprom_dialog.withdraw()

        self.delta.component('entry').config(width=12, justify=Tkinter.CENTER)
        self.delta.grid(row=0, column=0)
        self.sync_b = Tkinter.Button(delta_frame, text="SYNC", command=synctime)
        self.sync_b.config(state=Tkinter.DISABLED)

        self.sync_b.grid(row=0, column=1)
        delta_frame.grid(row=2)
        timezones = map(str, arange(-12, 12, .5))
        combo = Pmw.ComboBox(self.control_right,
                             label_text='GMT Offset (Hours):',
                             labelpos='w',
                             scrolledlist_items=timezones,
                             selectioncommand=self.gmt_change,
                             )
        combo.component('entry').config(width=6, justify=Tkinter.CENTER)
        local_time = time.localtime()
        tz = (local_time.tm_isdst - time.timezone / 3600.)
        i = timezones.index(str(tz))
        combo.selectitem(i)
        combo.grid(row=3)
        alarm_frame = Tkinter.Frame(self.control_right)
        self.alarm_entry = Pmw.EntryField(alarm_frame,
                                          label_text='Daily Alarm:',
                                          labelpos='w',
                                          value='00:00:00',
                                          validate='time')

        self.alarm_entry.component('entry').config(width=7)
        self.alarm_entry.grid(row=0, column=0)
        self.alarm_isset = Tkinter.IntVar()
        alarm_set_c = Tkinter.Checkbutton(alarm_frame, text="", variable=self.alarm_isset, borderwidth=0)
        alarm_set_c.grid(row=0, column=2)
        self.set_b = Tkinter.Button(alarm_frame, text="Set", command=self.alarm_set)
        self.set_b.grid(row=0, column=3)
        self.set_b.config(state=Tkinter.DISABLED)

        alarm_frame.grid(row=4)
        try:
            self.logo = Tkinter.PhotoImage(file="logo.gif")
            self.w = Tkinter.Label(self.control_frame, image=self.logo)
            self.w.grid(column=0)
        except: # don't crash for lack of logo!
            pass
        self.control_left.grid(row=0, column=1)
        self.control_right.grid(row=0, column=2)
        self.control_frame.grid(row=0)
        # f = Tkinter.Frame(self.root)
        def getter():
            pass
        def setter():
            pass
        
        self.scroll_frame = Pmw.ScrolledFrame(self.root,
                                              labelpos = 'n', 
                                              label_text = 'Calendar Alarms',
                                              usehullsize = 1,
                                              hull_width = 1200,
                                              hull_height = 500)

        # did_frame = Tkinter.Frame(self.root)
        did_frame = self.scroll_frame.interior()
        Tkinter.Label(did_frame, text='Repeat').grid(row=0, column=4, columnspan=9)
        Tkinter.Label(did_frame, text='Countdown').grid(row=0, column=12, columnspan=6)
        Tkinter.Label(did_frame, text='Beep').grid(row=1, column=2)
        Tkinter.Label(did_frame, text='When').grid(row=1, column=3)
        Tkinter.Label(did_frame, text='Scrollable Text').grid(row=1, column=4)
        Tkinter.Label(did_frame, text="A").grid(row=1, column=5)
        Tkinter.Label(did_frame, text="S").grid(row=1, column=6)
        Tkinter.Label(did_frame, text="M").grid(row=1, column=7)
        Tkinter.Label(did_frame, text="T").grid(row=1, column=8)
        Tkinter.Label(did_frame, text="W").grid(row=1, column=9)
        Tkinter.Label(did_frame, text="T").grid(row=1, column=10)
        Tkinter.Label(did_frame, text="F").grid(row=1, column=11)
        Tkinter.Label(did_frame, text="S").grid(row=1, column=12)
        Tkinter.Label(did_frame, text="5'").grid(row=1, column=13)

        Tkinter.Label(did_frame, text="D").grid(row=1, column=14)
        Tkinter.Label(did_frame, text="H").grid(row=1, column=15)
        Tkinter.Label(did_frame, text="5'").grid(row=1, column=16)
        Tkinter.Label(did_frame, text="M").grid(row=1, column=17)
        Tkinter.Label(did_frame, text='10"').grid(row=1, column=18)
        Tkinter.Label(did_frame, text="0").grid(row=1, column=19)

        didas = [] #did alarm fields
        for row in range(2, 32):
            dida = DID_AlarmField(did_frame, row)
            didas.append(dida)
        self.didas = didas
        did_frame.grid(row=5)
        self.scroll_frame.grid(row=6)
        self.root.title('ClockTHREE Connect!')
        self.root.after(1000, self.tick)
        self.root.mainloop()

    def on_portchange(self, *args, **kw):
        self.com = args[0]

    def gmt_change(self, args):
        C3_interface.set_gmt_offset(float(args) * 3600)
        

    def tick(self):
        c3tm = self.getC3_time()
        pctm = time.localtime()
        diff = time.mktime(c3tm) - time.mktime(pctm) - 3600 * pctm.tm_isdst
        self.ardtime.date.component('entry').delete(0, Tkinter.END)
        self.ardtime.time.component('entry').delete(0, Tkinter.END)
        self.pctime.date.component('entry').delete(0, Tkinter.END)
        self.pctime.time.component('entry').delete(0, Tkinter.END)
        self.delta.component('entry').delete(0, Tkinter.END)
        
        self.ardtime.date.component('entry').insert(
            0, 
            time.strftime('%Y/%m/%d', c3tm))
        self.ardtime.time.component('entry').insert(
            0, 
            time.strftime('%H:%M:%S', c3tm))

        self.pctime.date.component('entry').insert(
            0, 
            time.strftime('%Y/%m/%d', pctm))
        self.pctime.time.component('entry').insert(
            0, 
            time.strftime('%H:%M:%S', pctm))
        self.delta.component('entry').insert(
            0,
            str(int(round(diff)))
            )
        self.root.after(1000, self.tick)

    def getC3_time(self):
        if self.eeprom:
            t = C3_interface.time_req()
        else:
            t = 0
        out = time.gmtime(t)
        return out

    def format_eeprom(self, button_label):
        self.format_eeprom_dialog.deactivate(button_label)
        print button_label
        if button_label.upper() == 'FORMAT':
            C3_interface.clear_eeprom()
        else:
            raise C3_interface.EEPROMError('EEPROM not formatted')

        
    def connect(self):
        self.connect_b.config(command=self.disconnect,
                              text='Disconnect')
        self.sync_b.config(state=Tkinter.NORMAL)
        self.set_b.config(state=Tkinter.NORMAL)
        self.mirror_b.config(state=Tkinter.NORMAL)

        try:
            C3_interface.connect(self.com)
        except C3_interface.EEPROMError:
            if self.format_eeprom_dialog.activate().upper() == "FORMAT":
                C3_interface.connect()
            else:
                self.disconnect()
                return
        self.eeprom = C3_interface.eeprom
        self.alarm_get()
        data = []
        for i, did in enumerate([d for d in self.eeprom.dids 
                                 if d <= C3_interface.MAX_ALARM_DID]):
            data.append((self.eeprom.read_did_alarm(did), did))
        data.sort()
        i = -1 # default for loop over "normal" didas 1/2 page down
        for i, line in enumerate(data):
            line, did = line
            when, scroll_text, repeat, countdown, beeping = line
            self.didas[i].normal()
            self.didas[i].did = did
            self.didas[i].is_beeping.set(ord(beeping))
            self.didas[i].scrollable.delete(0, Tkinter.END)
            self.didas[i].scrollable.insert(0, scroll_text)
            self.didas[i].repeat.set(repeat)
            self.didas[i].countdown.set(countdown)
            self.didas[i].set(when)
            # + self.didas[i].countdown.get_countdown_duration())
            
            self.didas[i].clear_b.config(state=Tkinter.NORMAL)
            self.didas[i].disable()
        for j in range(i + 1, 30):
            self.didas[j].reset()
            self.didas[j].normal()

    def disconnect(self):
        C3_interface.disconnect()
        self.sync_b.config(state=Tkinter.DISABLED)
        self.set_b.config(state=Tkinter.DISABLED)
        self.mirror_b.config(state=Tkinter.DISABLED)
        self.eeprom = None
        self.connect_b.config(command=self.connect,
                              text='Connect')
        for j in range(30):
            self.didas[j].reset()
            self.didas[j].disable()

    def mirror(self):
        # ClockTHREE.ClockTHREE(english, C3_interface.gmt_offset,
        #                       parent=self.root)
        ClockTHREE.main(english)

    def alarm_set(self):
        h, m, s = self.alarm_entry.getvalue().split(':')
        is_set = self.alarm_isset.get()
        C3_interface.set_tod_alarm(int(h), int(m), int(s), is_set)

    def alarm_get(self):
        h, m, s, is_set = C3_interface.get_tod_alarm()
        self.alarm_entry.setvalue("%02d:%02d:%02d" % (h, m, s))
        self.alarm_isset.set(is_set)

def synctime(args=None):
    C3_interface.time_set()

usage = '''
Linux example:
python C3_GUI.py /dev/ttyusb0

Windows Example:
python C3_GUI.py COM1
'''

if __name__ == '__main__':
    import sys
    Main()
    if False:
        if len(sys.argv) > 1:
            com = sys.argv[1]
            if sys.platform == 'win32':
                com = int(com[-1]) - 1
        else:
            print usage
