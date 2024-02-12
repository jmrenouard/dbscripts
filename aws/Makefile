AWS_PROFILE ?= test-account
AWS_CMD=aws --profile ${AWS_PROFILE}

.DEFAULT: help

help:
	$(info make <help|start|stop|status|count> target=<(all|docker|metrics)>)
	@echo "target=all     : all instances."
	@echo "target=docker  : dockers and docker-db."
	@echo "target=metrics : metrics and metrics-nfs."
	@echo 
	@echo "AWS_PROFILE=${AWS_PROFILE}"

.PHONY: help status start stop 

ifndef target
target := all
endif
ifeq ($(target),all)
FILTER := 
else ifeq ($(target),docker)
FILTER := Name=tag:Name,Values="*docker*"
else ifeq ($(target),metrics)
FILTER := Name=tag:Name,Values="*metrics*"
else 
$(info make <help|start|stop|status|count> target=<(all|docker|metrics)>)
$(info target is $(target))
endif

status:
	echo "Account: ${AWS_PROFILE}"
	${AWS_CMD} ec2 describe-instances --filters ${FILTER} --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,InstanceId:InstanceId}" --output table

running:
	echo "Account: ${AWS_PROFILE}"
	${AWS_CMD} ec2 describe-instances --filters ${FILTER} --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,InstanceId:InstanceId}" --output table| grep running

stopped:
	echo "Account: ${AWS_PROFILE}"
	${AWS_CMD} ec2 describe-instances --filters ${FILTER} --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,InstanceId:InstanceId}" --output table| grep -v running

start:
	echo "Account: ${AWS_PROFILE}"
	${AWS_CMD} ec2 describe-instances --filters ${FILTER} Name=instance-state-name,Values=stopped --query "Reservations[*].Instances[*].{InstanceId:InstanceId}" --output text | xargs ${AWS_CMD} ec2 start-instances --output text --instance-ids

stop:
	echo "Account: ${AWS_PROFILE}"
	echo "$AWS_PROFILE" | grep -qE '(prd|prod|production|backup|core)' && echo 'Production account' && exit 1 || echo 'Non-production account
	${AWS_CMD} ec2 describe-instances --filters ${FILTER} Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].{InstanceId:InstanceId}" --output text | xargs ${AWS_CMD} ec2 stop-instances --output text --instance-ids

count:
	echo "Account: ${AWS_PROFILE}"
	${AWS_CMD} ec2 describe-instances --filters ${FILTER} --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name,InstanceId:InstanceId}" --output table | grep  'i-' | cut -d\| -f 6 | sort | uniq -c

clear_config:
	echo "# Account: ${AWS_PROFILE}"
	sudo sed -i "/# start ${AWS_PROFILE}/,/# end ${AWS_PROFILE}/d" /etc/hosts
	#sed -i "/# start ${AWS_PROFILE}/,/# end ${AWS_PROFILE}/d" $$HOME/.ssh/config

host_config: 
	echo "# Account: ${AWS_PROFILE}"
	echo "" | sudo tee -a /etc/hosts
	echo "# start ${AWS_PROFILE}" | sudo tee -a /etc/hosts
	aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|awk '{print $$2,"\t" ,$$1}'| perl -pe "s/\s*$$/.${AWS_PROFILE}.aws\n/" | tr '_' '-' | sudo tee -a /etc/hosts
	aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|awk '{print $$2,"\t" ,$$1}'| perl -pe "s/\s+/\taws.${AWS_PROFILE}./"   | tr '_' '-' | sudo tee -a /etc/hosts
	echo "# start ${AWS_PROFILE}" | sudo tee -a /etc/hosts

get_bastions: 
	echo "# Account: ${AWS_PROFILE}"
	aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|awk '{print $$2,"\t" ,$$1}'| grep -Ei '(bastion|autom)'

get_bastion_ips:
	echo "# Account: ${AWS_PROFILE}"
	aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|awk '{print $$2,"\t" ,$$1}'| grep -Ei '(bastion|autom)'|awk '{print $$1}' | sort |uniq | xargs -n 30

#alias_config:
#	echo "# Account: ${AWS_PROFILE}"
#	sed -i "/# start ${AWS_PROFILE}/,/# end ${AWS_PROFILE}/d" $$HOME/.bashrc
#	echo -e "\n# start ${AWS_PROFILE}" | tee -a $$HOME/.bashrc
#	aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|awk '{print $$2,"\t" ,$$1}'| perl -pe "s/\s*$$/.${AWS_PROFILE}.aws\n/" | tr '_' '-' | tee -a $$HOME/.bashrc
#	echo "# start ${AWS_PROFILE}" | tee -a $$HOME/.bashrc

test_access:
	echo "# Account: ${AWS_PROFILE}"
#	aws --profile ${AWS_PROFILE} ec2 describe-instances --filters Name=tag:Name,Values="*bastion*" --query "Reservations[*].Instances[*].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}" --output text|grep bastion
	export bastion=$(shell aws --profile ${AWS_PROFILE} ec2 describe-instances --filters Name=tag:Name,Values="*bastion*" --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|grep bastion| awk '{print $$2}' | head -n1)
	echo "bastion: $$bastion)"
	[ "$$bastion" = "" ] && aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|grep -vE '(bastion|autom)'|awk '{print $$2}' | xargs -I {} ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {} hostname
	[ "$$bastion" = "" ] || aws --profile ${AWS_PROFILE} ec2 describe-instances --filters  --query "Reservations[*].Instances[*].{PrivateIP:PrivateIpAddress,Name:Tags[?Key=='Name']|[0].Value}" --output text|grep -vE '(bastion|autom)'|awk '{print $$2}' | xargs -I {} ssh -q -o ProxyCommand="ssh -W %h:%p $$bastion" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null {} hostname

get_aws_profiles:
	cat ~/.aws/credentials | grep -E '^\[.*\]' | sed 's/\[//g' | sed 's/\]//g' | grep -v default