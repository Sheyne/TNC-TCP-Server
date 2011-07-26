

import serial
import datetime
import time
import D710_start_stop
from glob import glob
import os

"""Currently, the pyserial module is located in the same folder as the program,
    If that is ever not the case, or must be changed, then pyserial must be installed,
        The window's binary of which is located in the same folder as this file"""


if os.name=="posix":
    try:
        ser=serial.Serial(glob("/dev/tty.PL2303-*")[0])
    except:
        print "Error Connecting to Device"
    log=open(os.path.expanduser("~/Documents/tnc.log"),"a")
elif os.name=="nt":
    #The best way to determine what the port is, is to open Device manager and look under COM
    comport = raw_input("What is the name of the COM Port? (COM1, etc) ")
    try:
            ser=serial.Serial(comport)
    except IndexError:
            print "Seial Device not connected"
    try:
        log=open(os.path.expanduser(os.path.join('~','tnclogs','tnc.log')),"a")
    except IOError:
        os.mkdir(os.path.expanduser(os.path.join('~','tnclogs')))
        log=open(os.path.expanduser(os.path.join('~','tnclogs','tnc.log')),"a")


D710_start_stop.run_d710_tnc_startup(ser)

"""Change to path of choice (Current C:\tnclogs)"""

try:
	while 1:
		got=ser.read()
		out=""
		while got!="\r":
			out+=got
			got=ser.read()
		if out!="":
			currentTimestamp="# "+str(int(round(time.time())))+datetime.datetime.now().strftime(" %a %b %d %H:%M:%S %Z %Y")
			print currentTimestamp
			log.write(currentTimestamp+"\n")
			log.write(out+"\n")
			log.flush()
except:
	D710_start_stop.run_d710_tnc_shutdown(ser)
	log.close()
	ser.close()
	raise
