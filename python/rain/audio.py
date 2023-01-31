#!python3
import fire
import requests
import json
import logging
import os.path
from utils import *

from dotenv import dotenv_values
from bs4 import BeautifulSoup


def download_audios(tag=''):
    stag = tag
    if stag == '' or stag is None:
        stag = config['VIDEVO_DEFAULT_TAG']
    result_dir = os.path.join(config['VIDEVO_DOWNLOAD_BASEDIR'] or '.', stag or 'default')
    mkdir(result_dir)
    cache_file = os.path.join(result_dir, config['CACHE_ID_FILE']or 'cache.txt')

    logging.info('-' * 50)
    logging.info(f"Download audios for Tag: {stag}")
    logging.info('-' * 50)
    logging.info("")

    logging.debug(f"USING FILE ID CACHE: {cache_file}")
    deduplicate_file_content(cache_file)
    retrieved_audios = read_file_content(cache_file)
    logging.debug(f"{len(retrieved_audios)} IDS FOUND IN CACHE")
    logging.info('-' * 50)

    audio_found_flag = True
    num_page = 1
    remaining_audios = config['VIDEVO_MAX_AUDIOS']
    if remaining_audios is None or remaining_audios == '':
        remaining_audios = 10
    else:
        remaining_audios = int(remaining_audios)
    logging.debug(f"MAX AUDIOS TO DOWNLOAD: {remaining_audios}")

    per_page = config['VIDEVO_PER_PAGE']
    if per_page is None or per_page == '':
        per_page = 10
    else:
        per_page = int(per_page)

    url = f'https://www.videvo.net/search/{stag}/clip_type/royalty-free-sound-effects/'
    while audio_found_flag:
        logging.info('-' * 50)
        if remaining_audios <= 0:
            logging.info(f"Max audios reached {config['VIDEVO_MAX_AUDIOS']}")
            break
        logging.info("Start Videvo search")
        page = requests.get(url)
        soup = BeautifulSoup(page.text, 'html.parser')

        mp3_urls=[]
        for mp3link in soup.find_all('a', class_='play-icon'):
            logging.debug(f"Content: {mp3link['audio-source']}")
            mp3_urls.append(mp3link['audio-source'])
        if len(mp3_urls) == 0:
            audio_found_flag = False
            logging.info(f"No more audios")
            break
        for url_audio in mp3_urls:
            if url_audio not in retrieved_audios:
                remaining_audios -= 1
                basename_audio = os.path.basename(url_audio)
                # create the url with the audio id
                logging.info('-'*50)
                r = requests.get(url_audio)
                logging.info('-'*50)
                audio_file = os.path.join(result_dir, basename_audio)
                logging.info(f"Save audio {basename_audio} into {audio_file}")
                with open(f"{audio_file}", 'wb') as outfile:
                    outfile.write(r.content)

                append_file_content(cache_file, url_audio)

                json_file = f"{audio_file}.json"
                logging.info(
                    f"Save audio info {basename_audio} into {json_file}")
                # Save meta data
                #with open(f"{json_file}", 'wb') as outfile:
                #    outfile.write(json.dumps(data).encode('utf-8'))

                logging.info('-'*50)
                if remaining_audios <= 0:
                    logging.debug(
                        f"{config['VIDEVO_MAX_AUDIOS']} MAX AUDIOS LIMIT REACHED")
                    audio_found_flag = False
                    break
            else:
                logging.debug(
                    f"Audios found: id: {url_audio} ALREADY DOWNLOADED")
            logging.debug(
            f"MAX AUDIOS: {remaining_audios} / {config['VIDEVO_MAX_AUDIOS']}")
            random_sleep(int(config['VIDEVO_MAX_WAIT'] or 10))

        num_page += 1
    logging.info('-' * 50)

if __name__ == '__main__':
    init_logging()
    config = dotenv_values(".env")
    fire.Fire( {"download_audios": download_audios})
