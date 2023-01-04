import os
import time
import random
from pprint import pprint
import logging


def init_logging():
    logging.basicConfig(
        format='%(asctime)s %(levelname)-8s %(message)s',
        level=logging.DEBUG,
        datefmt='%Y-%m-%d %H:%M:%S')


def mkdir(path):
    if os.path.isdir(path) == False:
        os.makedirs(path, exist_ok=True)


def random_sleep(max_time=5):
    duration = random.randint(1, max_time)
    logging.info(f"Sleeping for {duration} seconds")
    time.sleep(duration)


def append_file_content(file_name, content):
    if content is None or content == '':
        return
    with open(file_name, 'a+') as file:
        file.write(f"{content}\n")


def read_file_content(file_name):
    if os.path.isfile(file_name) == False:
        return []

    with open(file_name, 'r') as file:
        return file.read().splitlines()


def deduplicate_file_content(file_name):
    if os.path.isfile(file_name) == False:
        return []

    with open(file_name, 'r') as file:
        lines = file.read().splitlines()
        lines = list(dict.fromkeys(lines))
        with open(file_name, 'w') as file:
            for line in lines:
                file.write(f"{line}\n")
