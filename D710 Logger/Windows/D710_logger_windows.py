
import serial
import datetime
import time
import D710_start_stop
from glob import glob
import os
#Note from Ian: You MUST install pyserial for this to work on windows
#       There should be an executable in the same folder

##Note 2: I have placed the pyserial folder in the windows folder,
##      I haven't a clue if it will work, but its worth a shot
"""
	This was quickly hacked together to so that I could test some
	theories I had with TNC. As such the code is kinda ugly, and 
	very specific to my computer. I'll comment it where you can
	change it to work with yours.
"""

try:
        ser=serial.Serial(0)
except IndexError:
	print "Seial Device not connected"
D710_start_stop.run_d710_tnc_startup(ser)

"""Change to path of choice (Current C:\tnclogs)"""
log=open(os.path.expanduser("\tnclogs\tnc.log"),"a")

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
