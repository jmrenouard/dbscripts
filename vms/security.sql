DROP DATABASE IF EXISTS test;

DELETE FROM mysql.user where user='';

FLUSH PRIVILEGES;

GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.33.%' IDENTIFIED BY 'secret';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'secret';


CREATE OR REPLACE USER 'galera'@'192.168.33.%' IDENTIFIED BY 'galera';
GRANT ALL PRIVILEGES ON *.* TO 'galera'@'192.168.33.%';
CREATE OR REPLACE USER 'galera'@'localhost' IDENTIFIED BY 'galera';
GRANT ALL PRIVILEGES ON *.* TO 'galera'@'localhost';
