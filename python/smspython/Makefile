NAME=smspython
DOCKERCMD=docker.exe

stop:
	$(DOCKERCMD) ps | grep -E "($(NAME))" | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) kill

rm: remove

remove:
	$(DOCKERCMD) ps -a | grep -E "($(NAME))"  | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) rm -f

build:
	$(DOCKERCMD) build . -t "$(NAME)"

ls: list

list:
	$(DOCKERCMD) ps -a | grep -E "($(NAME))"

run: runsrv

runsrv:  build
	$(DOCKERCMD) run -d --name "$(NAME)" "$(NAME)"

runsrv:  build
	$(DOCKERCMD) run -d --name "$(NAME)" "$(NAME)"

runargs: build
	echo SENDING TO $(phone) msg: $(message)
	$(DOCKERCMD) run -d -e "phone=$(phone)" -e "message=$(message)" --name "$(NAME)" "$(NAME)"

log: logs

logs:
	$(DOCKERCMD) ps -a | grep -E "($(NAME))" | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) logs

sh: shell

shell:
	$(DOCKERCMD) exec -it $(NAME) bash

up: update

update:
	$(DOCKERCMD) ps | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 -I{} $(DOCKERCMD) cp src/sms.ini {}:/code/src
	$(DOCKERCMD) ps | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 -I{} $(DOCKERCMD) cp src/sms_message.py {}:/code/src
