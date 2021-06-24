NAME=sql2xlsx
PORT=5000
DOCKERCMD=docker.exe
stop:
	$(DOCKERCMD) ps | grep -E "($(NAME)|$(PORT)/tcp)" | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) kill

remove:
	$(DOCKERCMD) ps -a | grep -E "($(NAME)|$(PORT)/tcp)"  | cut -d " " -f1 | xargs -n 1 $(DOCKERCMD) rm -f

build:
	$(DOCKERCMD) build . -t "$(NAME)"

list:
	$(DOCKERCMD) ps -a | grep -E "($(NAME)|$(PORT)/tcp)"

runsrv:  build
	$(DOCKERCMD) run -d -p $(PORT):$(PORT) --name "$(NAME)" "$(NAME)"
