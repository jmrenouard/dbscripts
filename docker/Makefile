SECRET_PASSWORD="Admin2024_"

create_secrets:
	[ -d "secrets" ] ||mkdir secrets
	echo "$(SECRET_PASSWORD)" > secrets/mysql-root-password

enable_pf:
	sudo sysctl -w net.ipv4.ip_forward=1
	sudo sysctl -w net.ipv6.conf.all.forwarding=1
	 
start_mysql: enable_pf
	 docker run --name mysql -d \
	 -p 3306:3306 \
	 -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root-password \
	 -v .$(shell pwd)/secrets:/run/secrets \
	 -v mysql:/var/lib/mysql \
	 --restart unless-stopped \
	 mysql:latest

stop_mysql:
	docker stop mysql

log_mysql:
	docker logs -f mysql

start_sa_mariadb: enable_pf
	 docker run --name mariadb -d \
	 -p 3307:3306 
	 -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root-password \
	 -v $(shell pwd)/secrets:/run/secrets \
	 -v mariadb:/var/lib/mysql \
	 --restart unless-stopped \
	 mariadb:latest

stop_mariadb:
	docker stop mariadb

log_mariadb:
	docker logs -f mariadb

list_containers:
	docker ps -a | grep -E '(mysql|mariadb)'

cleanup_mysql:
	docker rm -f mysql

cleanup_mariadb:
	docker rm -f mariadb
cleanup_containers: cleanup_mysql cleanup_mariadb
