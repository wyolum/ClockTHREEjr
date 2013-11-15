from C3_interface import *
import sys

if __name__ == '__main__':
    if len(sys.argv) > 1:
        msg = ' '.join(sys.argv[1:])
    else:
        msg = 'THIS IS A TEST'
    J = 'J'
    try:
        delete_did(J)
    except:
        pass
    print msg
    set_data(J, (msg + '  '))
    scroll_data(J)
