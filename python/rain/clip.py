#!python3
import fire
import requests
import json
import logging
import os.path
from utils import *


from moviepy.editor import VideoFileClip, AudioFileClip, concatenate_videoclips, concatenate_audioclips
from dotenv import dotenv_values
from pexelsapi.pexels import Pexels


def download_videos(tag=''):
    api = Pexels(config['PEXELS_API'])
    stag = tag
    if stag == '' or stag is None:
        stag = config['PEXELS_DEFAULT_TAG']
    result_dir = os.path.join(config['PEXELS_DOWNLOAD_BASEDIR'] or '.', stag or 'default')
    mkdir(result_dir)
    cache_file = os.path.join(result_dir, config['CACHE_ID_FILE']or 'cache.txt')

    logging.info('-' * 50)
    logging.info(f"Download videos for Tag: {stag}")
    logging.info('-' * 50)
    logging.info("")

    logging.debug(f"USING FILE ID CACHE: {cache_file}")
    deduplicate_file_content(cache_file)
    retrieved_videos = read_file_content(cache_file)
    logging.debug(f"{len(retrieved_videos)} IDS FOUND IN CACHE")
    logging.info('-' * 50)

    video_found_flag = True
    num_page = 1
    remaining_videos = config['PEXELS_MAX_VIDEOS']
    if remaining_videos is None or remaining_videos == '':
        remaining_videos = 10
    else:
        remaining_videos = int(remaining_videos)
    logging.debug(f"MAX VIDEOS TO DOWNLOAD: {remaining_videos}")

    per_page = config['PEXELS_PER_PAGE']
    if per_page is None or per_page == '':
        per_page = 10
    else:
        per_page = int(per_page)
    api = Pexels(config['PEXELS_API'])
    while video_found_flag:
        logging.info('-' * 50)
        if remaining_videos <= 0:
            logging.info(f"Max videos reached {config['PEXELS_MAX_VIDEOS']}")
            break
        logging.info("Start Pexels API search")
        videos = api.search_videos(
            query=f"{stag}", page=num_page, per_page=per_page)
        if len(videos['videos']) == 0:
            video_found_flag = False
            logging.info(f"No more videos")
            break
        for data in videos['videos']:
            if data['width'] < data['height'] and config['PEXELS_ORIENTATION'] == 'horizontal':
                logging.warning(
                    f"Videos found: id: {data['id']} SKIPPED FOR BAD ORIENTATION {config['PEXELS_ORIENTATION']}")
                continue
            if data['width'] > data['height'] and config['PEXELS_ORIENTATION'] == 'vertical':
                logging.warning(
                    f"Videos found: id: {data['id']} SKIPPED FOR BAD ORIENTATION {config['PEXELS_ORIENTATION']}")
                continue
            if str(data['id']) not in retrieved_videos:
                remaining_videos -= 1
                # create the url with the video id
                url_video = 'https://www.pexels.com/video/' + \
                    str(data['id']) + \
                    '/download'
                logging.info('-'*50)
                r = requests.get(url_video)
                logging.info('-'*50)
                video_file = os.path.join(result_dir, f"{data['id']}.mp4")
                logging.info(f"Save video {data['id']} into {video_file}")
                with open(f"{video_file}", 'wb') as outfile:
                    outfile.write(r.content)

                append_file_content(cache_file, data['id'])

                json_file = os.path.join(result_dir, f"{data['id']}.json")
                logging.info(
                    f"Save video info {data['id']} into {json_file}")
                # Save meta data
                with open(f"{json_file}", 'wb') as outfile:
                    outfile.write(json.dumps(data).encode('utf-8'))

                logging.info('-'*50)
                if remaining_videos <= 0:
                    logging.debug(
                        f"{config['PEXELS_MAX_VIDEOS']} MAX VIDEOS LIMIT REACHED")
                    video_found_flag = False
                    break
            else:
                logging.debug(
                    f"Videos found: id: {data['id']} ALREADY DOWNLOADED")
            logging.debug(
            f"MAX VIDEOS: {remaining_videos} / {config['PEXELS_MAX_VIDEOS']}")
            random_sleep(int(config['PEXELS_MAX_WAIT'] or 10))

        num_page += 1
    logging.info('-' * 50)


def generate_videos():
    # Read The Rain/Sound Clips
    rain_clip = VideoFileClip("")
    rain_sound = AudioFileClip("")
    # Add the number of clips you wanna make
    number_clips = 5

    # Concatenate Rain/Sound Clips
    rain_clip = concatenate_videoclips(
        [rain_clip for i in range(number_clips)])
    rain_sound = concatenate_audioclips(
        [rain_sound for i in range(number_clips)])

    # Set Duration Time of the rain_sound to the rain_clip
    rain_sound = rain_sound.set_duration(rain_clip.duration)

    # Exporting The Final Clip
    final_clip = rain_clip.set_audio(rain_sound)
    final_clip.write_videofile("", threads=8, fps=15, preset='ultrafast')


if __name__ == '__main__':
    init_logging()
    config = dotenv_values(".env")
    fire.Fire()
