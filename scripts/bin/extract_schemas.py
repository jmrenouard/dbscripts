#!/usr/bin/env python3

import mysql.connector
import fire

class MysqlExtractor(object):
    def genConnParams(self, host="localhost", port=3306, user="root", password="", database="mysql"):
        connection_params = {
                            'host': host,
                            'user': user,
                            'password': password,
                            'database': database,
        }
        return connection_params

    def extract_db_list(self, host="localhost", port=3306, user="root", password="", database="mysql" ):
        query  = ("SELECT DISTINCT(DBNAME) FROM information_schema")
        with mysql.connector.connect(self.getConnParams(host, port, user, password))as cnx:
            with cnx.cursor() as cursor:
                cursor.execute(query)



    def extract_db_user_list(self):
        pass

    def extract_db_table_list(self):
        pass

    def extract_user_table_list(self):
        pass

    def extract_database_schema(self):
        pass

    def extract_record_count():
        pass


if __name__ == '__main__':
  fire.Fire(MysqlExtractor)
