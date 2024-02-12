NAME=sql2xlsx
PORT=5000
DOCKERCMD=docker.exe

stop:
	$(DOCKERCMD) ps | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) kill

rm: remove

remove:
	$(DOCKERCMD) ps -a | grep -E "($(NAME)|$(PORT)/tcp)"  | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) rm -f

build:
	$(DOCKERCMD) build . -t "$(NAME)"

ls: list

list:
	$(DOCKERCMD) ps -a | grep -E "($(NAME)|$(PORT)/tcp)"

run: runsrv

runsrv:  build
	$(DOCKERCMD) run -d -p $(PORT):$(PORT) --name "$(NAME)" "$(NAME)"

log: logs

logs:
	$(DOCKERCMD) ps -a | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) logs

sh: shell

shell:
	$(DOCKERCMD) exec -it $(NAME) bash

up: update

update:
	$(DOCKERCMD) ps | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 -I{} $(DOCKERCMD) cp src/.env {}:/code/src
	$(DOCKERCMD) ps | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 -I{} $(DOCKERCMD) cp src/server.py {}:/code/src
