

create_secrets:
	[ -d "secrets" ] ||mkdir secrets
	echo "Admin2023:" > secrets/mysql-root-password

start_mysql:
	 docker run --name mysql -d \
	 -p 3306:3306 \
	 -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root-password \
	 -v ./secrets:/run/secrets \
	 -v mysql:/var/lib/mysql \
	 --restart unless-stopped \
	 mysql:latest

stop_mysql:
	docker stop mysql

log_mysql:
	docker logs -f mysql

start_mariadb:
	 docker run --name mariadb -d \
	 -p 3307:3306 \
	 -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root-password \
	 -v ./secrets:/run/secrets \
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