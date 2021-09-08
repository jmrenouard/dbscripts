#!python3

from AirMoreSmsServer import AirMoreSmsServer
import os

if __name__ == '__main__':
	smsserver=AirMoreSmsServer()

	number="+33662695881"
	if os.getenv('phone'):
		number=os.getenv('phone')

	message = "reponds"
	if os.getenv('message'):
		message=os.getenv('message')

	smsserver.send_sms_message(number, message)
