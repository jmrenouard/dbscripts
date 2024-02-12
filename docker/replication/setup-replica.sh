#!/bin/bash
# Script d'initialisation pour configurer le serveur MySQL comme replica²

# Ajout de la configuration de réplication au fichier de configuration de MySQL
cat <<EOF >>/etc/mysql/my.cnf
[mysqld]
server-id=$SERVER_ID
log_bin=mysql-bin
binlog_format=row
gtid_mode=ON
enforce_gtid_consistency=ON
EOF

# Attendez que le serveur soit prêt
until mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "Status"; do
	echo 'Waiting for MySQL to become available...'
	sleep 1
done

# Wait util primary is ready
until mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "Status"; do
	echo 'Waiting for MySQL to become available...'
	sleep 1
done

# perform a sync with mysqldump
mysqldump --master-data=2 ....

# Création de l'utilisateur de réplication avec les variables d'environnement
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
	    CREATE USER IF NOT EXISTS '$REPLICATION_USER'@'%' IDENTIFIED BY '$REPLICATION_PASSWORD';
	    GRANT REPLICATION SLAVE ON *.* TO '$REPLICATION_USER'@'%';
	    FLUSH PRIVILEGES;
	      CHANGE MASTER TO ...;
	      START SLAVE;
EOSQL

# Wait until slave correcty started ...
until mysql -u -p"$MYSQL_ROOT_PASSWORD" -e "Status"; do
	echo 'Waiting for MySQL to become available...'
	sleep 1
done
