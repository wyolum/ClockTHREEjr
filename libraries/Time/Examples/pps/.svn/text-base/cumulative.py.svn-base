from scipy import *
from pylab import *
from numpy import *

f = open('uSec.csv')
f.readline()
for l in f.readlines():
    try:
        x, y = l.split(',')
        float(x)
        float(y)
    except:
        print l
        raise

dat = loadtxt('uSec.csv', skiprows=1, delimiter=",")
# plot(dat[:,0])
# plot(dat[:,1])
# show()
diff = cumsum(dat[:,0]) - cumsum(dat[:,1])
diff -= mean(diff)
diff %= 1000
diff = unwrap(diff * 2 * pi /1000) * 1000 / (2 * pi)
# diff -= 1e6 + 19

A = ones((len(diff), 2))
A[:,0] = range(len(diff))

m, b = dot(linalg.inv(dot(A.T, A)), dot(A.T, diff))
i_s = arange(len(diff))
y = m * i_s + b

plot(diff)
# i_s = where(greater(diff, y))[0]
plot(i_s, diff[i_s])
N = len(i_s)
A = ones((N, 2))
A[:,0] = i_s
m, b = dot(linalg.inv(dot(A.T, A)), dot(A.T, diff[i_s]))
y = m * i_s + b
plot(i_s, y, '--')


print m, 'us/s =', m * 86400 * 365.25/1e6, 's/year'
print m*1000, 'ns/s'
print 1000/m / 3600., ' h/ms'

xlabel('Seconds')
ylabel('uSec')
text(10000, -120, 'drift: %.2f ns/s' % (m*1000), rotation=-36)
show()
