FROM alpine:latest

RUN apk update
RUN apk upgrade
RUN apk add python3 gcc py3-pip curl py3-yaml openssh-client bash tar
RUN apk add musl-dev libffi-dev openssl-dev make gcc python3 py3-pip python3-dev
RUN pip3 install --upgrade pip

# Makes the Ansible directories
RUN mkdir /inventory /playbooks /roles
RUN mkdir ~/.ssh

RUN echo "host *" >> ~/.ssh/config &&\
echo "StrictHostKeyChecking no" >> ~/.ssh/config

# Last version
RUN pip install --no-cache-dir cffi ansible-lint ansible

# Last version 2.6
RUN pip install --no-cache-dir cffi ansible-lint ansible==2.6
RUN pip install --no-cache-dir cffi ansible-lint ansible==2.7
RUN pip install --no-cache-dir cffi ansible-lint ansible==2.8
RUN pip install --no-cache-dir cffi ansible-lint ansible==2.9
RUN pip install --no-cache-dir cffi ansible-lint ansible==2.10
RUN pip install --no-cache-dir cffi ansible-lint ansible==3
RUN pip install --no-cache-dir cffi ansible-lint ansible==4
RUN pip install --no-cache-dir cffi ansible-lint ansible==5
RUN pip install --no-cache-dir cffi ansible-lint ansible==6

# Makes a directory for ansible playbooks
RUN mkdir -p /ansible/playbooks
# Makes the playbooks directory the working directory
WORKDIR /ansible/playbooks

# Sets environment variables
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING False
ENV ANSIBLE_RETRY_FILES_ENABLED False
ENV ANSIBLE_ROLES_PATH /roles
ENV ANSIBLE_SSH_PIPELINING True
ENV ANSIBLE_STDOUT_CALLBACK debug
ENV ANSIBLE_INVENTORY /inventory/hosts.ini
ENV ANSIBLE_LOAD_CALLBACK_PLUGINS 1
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Sets entry point (same as running ansible-playbook)
CMD [ "ansible-playbook",  "-v" ]
