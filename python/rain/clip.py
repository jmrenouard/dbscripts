#!python3
import fire
import requests
import json
import logging
import os.path

from utils import *
from moviepy.editor import VideoFileClip, AudioFileClip, ImageClip, CompositeVideoClip
import moviepy.video.fx
import moviepy.audio.fx
import ffmpeg
import cv2
from dotenv import dotenv_values
from simple_youtube_api.Channel import Channel
from simple_youtube_api.LocalVideo import LocalVideo

def upload_videos(video_path="2491284_resultcps_.mp4", title="Rain drop", description="Relaxing video of rain", tags=["rain", "relax", "2minutes" ], category="relax", default_language="en-US", embeddable=True, license="creativeCommon", privacy_status="public", public_stats_viewable=True, thumbnail_path='2491284_resultcps_.jpg'):
    logging.info("Upload video to youtube")
    # loggin into the channel
    channel = Channel()
    logging.info("After channel creation")
    channel.login("client_secret.json", "credentials.storage")
    logging.info("After channel login")
    
    # setting up the video that is going to be uploaded
    video = LocalVideo(file_path=video_path)

    # setting snippet
    video.set_title(title)
    video.set_description(description)
    video.set_tags(tags)
    video.set_category(category)
    video.set_default_language(default_language)

    # setting status
    video.set_embeddable(embeddable)
    video.set_license(license)
    video.set_privacy_status(privacy_status)
    video.set_public_stats_viewable(public_stats_viewable)

    # setting thumbnail
    video.set_thumbnail_path(thumbnail_path)

    # uploading video and printing the results
    video = channel.upload_video(video)
    print(video.id)
    print(video)

    # liking video
    video.like()

def generate_videos_image(videopath="2491284_result.mp4", outpath= ""):
    if outpath == "":
        outpath=os.path.splitext(videopath)[0]+".jpg"

    vidcap = cv2.VideoCapture(videopath)
    # get total number of frames
    totalFrames = vidcap.get(cv2.CAP_PROP_FRAME_COUNT)
    randomFrameNumber=random.randint(0, totalFrames)
    # set frame position
    vidcap.set(cv2.CAP_PROP_POS_FRAMES,randomFrameNumber)
    success, image = vidcap.read()
    if success:
        cv2.imwrite(outpath, image)
        
        
def compress_video(video_full_path="2491284_result.mp4", size_upper_bound=51200, two_pass=True, filename_suffix='_cps'):
    """
    Compress video file to max-supported size.
    :param video_full_path: the video you want to compress.
    :param size_upper_bound: Max video size in KB.
    :param two_pass: Set to True to enable two-pass calculation.
    :param filename_suffix: Add a suffix for new video.
    :return: out_put_name or error
    """
    filename, extension = os.path.splitext(video_full_path)
    extension = '.mp4'
    output_file_name = filename + filename_suffix + extension

    # Adjust them to meet your minimum requirements (in bps), or maybe this function will refuse your video!
    total_bitrate_lower_bound = 11000
    min_audio_bitrate = 32000
    max_audio_bitrate = 256000
    min_video_bitrate = 100000

    try:
        # Bitrate reference: https://en.wikipedia.org/wiki/Bit_rate#Encoding_bit_rate
        probe = ffmpeg.probe(video_full_path)
        # Video duration, in s.
        duration = float(probe['format']['duration'])
        # Audio bitrate, in bps.
        audio_bitrate = float(next((s for s in probe['streams'] if s['codec_type'] == 'audio'), None)['bit_rate'])
        # Target total bitrate, in bps.
        target_total_bitrate = (size_upper_bound * 1024 * 8) / (1.073741824 * duration)
        if target_total_bitrate < total_bitrate_lower_bound:
            print('Bitrate is extremely low! Stop compress!')
            return False

        # Best min size, in kB.
        best_min_size = (min_audio_bitrate + min_video_bitrate) * (1.073741824 * duration) / (8 * 1024)
        if size_upper_bound < best_min_size:
            print('Quality not good! Recommended minimum size:', '{:,}'.format(int(best_min_size)), 'KB.')
            # return False

        # Target audio bitrate, in bps.
        audio_bitrate = audio_bitrate

        # target audio bitrate, in bps
        if 10 * audio_bitrate > target_total_bitrate:
            audio_bitrate = target_total_bitrate / 10
            if audio_bitrate < min_audio_bitrate < target_total_bitrate:
                audio_bitrate = min_audio_bitrate
            elif audio_bitrate > max_audio_bitrate:
                audio_bitrate = max_audio_bitrate

        # Target video bitrate, in bps.
        video_bitrate = target_total_bitrate - audio_bitrate
        if video_bitrate < 1000:
            print('Bitrate {} is extremely low! Stop compress.'.format(video_bitrate))
            return False

        i = ffmpeg.input(video_full_path)
        if two_pass:
            ffmpeg.output(i, os.devnull,
                          **{'c:v': 'libx265', 'b:v': video_bitrate, 'pass': 1, 'f': 'mp4'}
                          ).overwrite_output().run()
            ffmpeg.output(i, output_file_name,
                          **{'c:v': 'libx265', 'b:v': video_bitrate, 'pass': 2, 'c:a': 'aac', 'b:a': audio_bitrate}
                          ).overwrite_output().run()
        else:
            ffmpeg.output(i, output_file_name,
                          **{'c:v': 'libx265', 'b:v': video_bitrate, 'c:a': 'aac', 'b:a': audio_bitrate}
                          ).overwrite_output().run()

        if os.path.getsize(output_file_name) <= size_upper_bound * 1024:
            return output_file_name
        elif os.path.getsize(output_file_name) < os.path.getsize(video_full_path):  # Do it again
            return compress_video(output_file_name, size_upper_bound)
        else:
            return False
    except FileNotFoundError as e:
        print('You do not have ffmpeg installed!', e)
        print('You can install ffmpeg by reading https://github.com/kkroening/ffmpeg-python/issues/251')
        return False


def generate_videos(outpath= "2491284_result.mp4", videopath="pexels/rain/2491284.mp4", soundpath="videvo/rain/Rain-Medium-Grass-And-Concrete-Distant-Traffic_GEN-HD2-31223_preview.mp3", duration=2):
    is_logo = False
    # Read The Rain/Sound Clips
    rain_clip = VideoFileClip(videopath)
    rain_sound = AudioFileClip(soundpath)

    # get video duration
    logging.info("VIDEO DURATION: " + str(rain_clip.duration))
    
    # get audio duration
    logging.info("AUDIO DURATION: " + str(rain_sound.duration))
    
    rain_clip=moviepy.video.fx.all.loop(rain_clip, duration=2*60)
    merge_clip = rain_clip.set_duration(2*60)
    merge_clip = rain_clip.set_audio(rain_sound)
    merge_clip.resize(height=1080,width=1920)

    if is_logo is True:
        logo = (ImageClip("logo.png")
          .set_duration(rain_clip.duration)
          .resize(height=50) # if you need to resize...
          .margin(right=8, top=8, opacity=0) # (optional) logo-border padding
          .set_pos(("right","top")))
    
        final_clip = CompositeVideoClip([merge_clip, logo])
    else:
        final_clip=merge_clip
    
    # Exporting The Final Clip
    merge_clip.resize(0.2)
    final_clip.write_videofile(outpath, threads=16, fps=15,codec = 'libx265', preset='ultrafast')
    compress_video(outpath, 1024*50)
    #ffmpeg -i input.mkv -vf "scale=trunc(iw/10)*2:trunc(ih/10)*2" -c:v libx265 -crf 28 a_fifth_the_frame_size.mkv


if __name__ == '__main__':
    init_logging()
    config = dotenv_values(".env")
    fire.Fire()
