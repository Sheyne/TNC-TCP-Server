import serial
import datetime
import time
import D710_start_stop
from glob import glob
import os
try:
	ser=serial.Serial(glob("/dev/tty.PL2303-*")[0])
except IndexError:
	print "Seial Device not connected"
D710_start_stop.run_d710_tnc_startup(ser)

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
			#print out
			log.write(currentTimestamp+"\n")
			log.write(out+"\n")
			log.flush()
except:
	D710_start_stop.run_d710_tnc_shutdown(ser)
	log.close()
	ser.close()
	raise