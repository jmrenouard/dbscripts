#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon May  3 21:04:00 2021
"""
import json
import requests
import base64
import fire 
from pprint import pprint 
import html
from dotenv import load_dotenv
import os

class Wordpress(object):
	def __init__(self) -> None:
		load_dotenv()
		
		keys = {
			'wp_key': str(os.getenv('SECRET_KEY_WP')),
			'user': str(os.getenv('USER_WP'))
			}

		# Define your WP URL
		self.url = os.getenv('URL_WP')

		# Create WP Connection
		wp_connection = keys['wp_key'] + ':' + keys['user']

		# Encode the connection of your website
		token = base64.b64encode(wp_connection.encode())

		# Prepare the header of our request
		self.headers = {
				'Authorization': 'Basic ' + token.decode('utf-8')
				}

	# Define Function to Call the Posts Endpoint
	def get_posts(self):
			api_url = self.url + f'/posts'
			response = requests.get(api_url, headers=self.headers)
			return response.json()


	def get_last_post(self):
			response=self.get_posts()

			pprint(response[0]['title']['rendered'])

	def get_last_posts(self, maxp=10):
			response=self.get_posts()

			for i in range(0, min( [maxp, len(response)])):
				pprint(html.unescape(response[i]['title']['rendered']))

if __name__ == '__main__':
  fire.Fire(Wordpress())
