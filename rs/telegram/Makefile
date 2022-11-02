CWD=$(shell pwd)
dev: code/*.py code/.env
	docker run  --rm -v $(CWD)/code:/code  telegrambot
run:
	docker run -d --rm -v $(CWD)/code:/code -t telegramobt telegrambot

clean:
	 docker ps -a | grep Exited | awk '{print $1}' | xargs -n 1 docker rm -f
	 docker ps -a 

clean_images: clean

build:
	docker build -t telegrambot .
	docker images