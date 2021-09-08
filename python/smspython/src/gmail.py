from envelopes import Envelope, GMailSMTP
from configparser import ConfigParser
import logging

logging.basicConfig(format='%(asctime)s[%(levelname)s] %(message)s', level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')

cfgfile="gmail.ini"
cfg = ConfigParser()
cfg.read(cfgfile)

#The mail addresses and password
sender_address = cfg.get('GMAIL', 'GUSER')
sender_pass    = cfg.get('GMAIL', 'GPASS')
from_address   = cfg.get('GMAIL', 'FROM')
receiver_address = cfg.get('GMAIL', 'TO')

mail_subject=u'Test from mail LIGTHPATH => GMAIL'
mail_content = u'''Hello,
This is a simple mail. There is only text, no attachments are there The mail is sent using Python SMTP library.
Thank You
'''

envelope = Envelope(
    from_addr=(from_address, from_address),
    to_addr=(receiver_address, receiver_address),
    subject=mail_subject,
    text_body=mail_content
)

# Or send the envelope using a shared GMail connection...
gmail = GMailSMTP(sender_address, sender_pass)
gmail.send(envelope)