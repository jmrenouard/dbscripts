# syntax=docker/dockerfile:1
FROM python:3.8

# set the working directory in the container
WORKDIR /code

# copy the dependencies file to the working directory
COPY requirements.txt .

# install dependencies
RUN pip install -r requirements.txt

# copy the content of the local src directory to the working directory
RUN mkdir src

COPY src/*.py src/
COPY src/.env src/

# command to run on container start
CMD [ "python", "./src/server.py" ]