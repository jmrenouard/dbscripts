#!python3

from ipaddress import IPv4Address  # for your IP address
from pyairmore.request import AirmoreSession  # to create an AirmoreSession
from pyairmore.services.messaging import MessagingService  # to send messages
from configparser import ConfigParser
import logging
import sys
import os

class AirMoreSmsServer:
	cfgfile='sms.ini'
	amip='192.168.0.25'
	amport=2333
	def __init__(self, cfgfile='sms.ini'):
		logging.basicConfig(format='%(asctime)s[%(levelname)s] %(message)s', level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')
		self.cfgfile=cfgfile

		cfg = ConfigParser()
		cfg.read(self.cfgfile)

		self.amip = cfg.get('PHONE', 'IP')
		self.amipaddr = IPv4Address(cfg.get('PHONE', 'IP'))
		self.amport = int(cfg.get('PHONE', 'PORT'))
		logging.debug("AirMore target on Android Device ("+self.get_srv_info() + ")")

	def get_srv_info(self):
		return self.amip+":" +str(self.amport)

	def send_sms_message(self, number, message):
		# now create a session
		logging.info("Trying connecting AirMore on Android Device ("+self.get_srv_info() + ")")
		session = AirmoreSession(self.amipaddr, self.amport)

		if not session.is_server_running:
			logging.error("AirMore is not Running on Android Device ("+self.get_srv_info() + ")")
			sys.exit(1)

		logging.info("AirMore is Running on Android Device ("+self.get_srv_info() + ")")

		was_accepted = session.request_authorization()
		if not was_accepted:
			logging.error("AirMore is rejecting session on Android Device ("+self.get_srv_info() + ")")
			sys.exit(2)

		logging.error("AirMore is accpeting this session on Android Device ("+self.get_srv_info() + ")")

		service = MessagingService(session)
		logging.info("Sending to " +number+ " message: "+message)
		service.send_message(number, message)
		logging.info("Message sent to " +number)

