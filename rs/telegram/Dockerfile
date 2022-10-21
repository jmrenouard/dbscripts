FROM python:3

RUN mkdir -p /code
RUN pip install --upgrade pip

ADD requirements.txt /
RUN pip install -r /requirements.txt

ADD ./code /code

CMD [ "python3", "/code/bot.py" ]