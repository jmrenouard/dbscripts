-- init-permissions.sql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'rootpass' WITH GRANT OPTION;
GRANT REPLICATION SLAVE ON *.* TO 'repli_user'@'%' IDENTIFIED BY 'replipass';
FLUSH PRIVILEGES;
