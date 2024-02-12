#!python3

import time
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from configparser import ConfigParser
import logging

logging.basicConfig(format='%(asctime)s[%(levelname)s] %(message)s', level=logging.DEBUG, datefmt='%Y-%m-%d %H:%M:%S')

cfgfile="linkedin.ini"
cfg = ConfigParser()
cfg.read(cfgfile)

#driver = webdriver.Chrome('/root/winhome/Desktop/')  # Optional argument, if not specified will search path.
driver = webdriver.Chrome()
driver.get('https://www.linkedin.com/login/fr');

time.sleep(5) # Let the user actually see something!

username = driver.find_element_by_id('username')
password=  driver.find_element_by_id('password')

username.send_keys(cfg.get('linkedin', 'user'))
password.send_keys(cfg.get('linkedin', 'password'))

time.sleep(3) # Let the user actually see something!

password.send_keys(Keys.RETURN)


time.sleep(4)
driver.get('https://www.linkedin.com/notifications/')
#driver.quit()
