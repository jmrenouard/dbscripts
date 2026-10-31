up:
	docker compose up -d --build  --remove-orphans

down:
	docker compose down

logs:
	docker compose logs -f

inject:
	cd ../../../test_db;cat ./employees.sql | mysql -uroot -psecret 

mt:
	cd ../../../MySQLTuner-perl;perl mysqltuner.pl --user root --password secret --verbose

mts:
	cd ../../../MySQLTuner-perl;perl mysqltuner.pl --user root --password secret --skippassword

mtf:
	cd ../../../MySQLTuner-perl;perl mysqltuner.pl --user root --password secret --verbose --dumpdir=output
