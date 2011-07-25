import serial
import datetime
import time
import D710_start_stop
from glob import glob
import os

"""
	This was quickly hacked together to so that I could test some
	theories I had with TNC. As such the code is kinda ugly, and 
	very specific to my computer. I'll comment it where you can
	change it to work with yours.
"""

try:
	""" My serial driver sets up a device file with the format:
		/dev/tty.PL2303-(SOME NUMBER)
		for each usb port I have. I am using python's unix
		filename completing to change the star into whatever
		number the dirver come up with.
		
		If you are using a windows machine the following /should/
		work:
		
		ser=serial.Serial(0)
	"""
	ser=serial.Serial(glob("/dev/tty.PL2303-*")[0])
except IndexError:
	print "Seial Device not connected"
D710_start_stop.run_d710_tnc_startup(ser)

"""Windows users may have to change that path:
	
	backslashes instead of forward slashes (maybe)
	
	And IDK if tilde (~) becomes users home folder on windows."""

log=open(os.path.expanduser("~/Documents/tnc.log"),"a")

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