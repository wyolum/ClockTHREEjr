import time
import datetime
epoch = datetime.datetime(1970, 1, 1)


for y in range(2000, 2099):
  d = (31 - ((((5 * y) / 4) + 4) % 7))
  e = (31 - ((((5 * y) / 4) + 1) % 7))
  est_start = datetime.datetime(y, 3, d,  1, 0, 0)
  est_stop = datetime.datetime(y, 10, e,  1, 0, 0)
  print '%11d,%11d,    // %s -- %s' % (time.mktime(est_start.timetuple()),time.mktime(est_stop.timetuple()),
                                       est_start, est_stop)
