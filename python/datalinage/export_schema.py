#!/usr/bin/python3
from urllib import request
import json
import os
from os.path import exists
from pprint import pprint
from datetime import datetime

from dotenv import dotenv_values
import mysql.connector
import fire

class MySQLUtils:
    def __init__(self, config_file='', dictionary=True, format='python'):
        self.dictionary=dictionary
        self.format=format
        if config_file != '' and exists(config_file):
            config = dotenv_values(config_file)
        elif exists(os.getenv("HOME") + "/.env"):
            config = dotenv_values(os.getenv("HOME") + "/.env")
        else:
            raise Exception("Config file not found")
        self.config=config
        #pprint(self.config)

    def select(self, statement='SELECT 1'):
        with mysql.connector.connect(**self.config) as conn:
            with conn.cursor(dictionary=self.dictionary) as c:
                c.execute(statement)
                result=c.fetchall()
                if self.format == 'json':
                    return json.dumps(result, sort_keys=True, indent=4)
                elif self.format == 'md':
                    resultMD="||"
                    for col in c.description:
                        resultMD=f"{resultMD} *{col[0]}* ||"
                    #resultMD=f"{resultMD}\n|"
                    #for col in c.description:
                    #    resultMD=f" {resultMD} ---------------- |"
                    
                    for row in result:
                        resultMD=f"{resultMD}\n|"
                        for col in c.description:
                            resultMD=f"{resultMD} {row[col[0]]} |"
                    return resultMD
        return result

class MySQLRequest:
    """ Execute SQL statements
    """
    userSQL = """
        SELECT USER, HOST FROM mysql.user
        """

    userDbSQL = """
        SELECT SCHEMA_NAME AS BASENAME FROM information_schema.SCHEMATA
        WHERE SCHEMA_NAME NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys', 'percona')
        """

    tableColumnsSQL = """
        SELECT c.TABLE_SCHEMA AS "BASENAME", c.TABLE_NAME AS "TABLE",
        c.COLUMN_NAME AS "COLUMN", c.COLUMN_TYPE AS TYPE,
        c.IS_NULLABLE, c.COLUMN_COMMENT AS "DESCRIPTION",
        "" AS "RGPD DESCRIPTION", "" AS "RGPD_TRANSFORMATION"
        FROM information_schema.columns c
        WHERE c.TABLE_SCHEMA = '{schema}' AND c.TABLE_NAME = '{table}'
        """

    databaseTablesSQL= """
        SELECT t.TABLE_SCHEMA AS "BASENAME", t.TABLE_NAME AS "TABLE"
        FROM information_schema.TABLES t
        WHERE t.TABLE_SCHEMA = '{schema}'
        AND t.TABLE_TYPE = 'BASE TABLE';
        """

    def users(self, format='json', config='', dict=True):
        driver=MySQLUtils(config, format=format)
        result=driver.select(statement=MySQLRequest.userSQL)
        print(result)

    def databases(self, format='python', config='', dict=True):
        driver=MySQLUtils(config, format=format)
        result=driver.select(statement=MySQLRequest.userDbSQL)
        print(result)


    def tables(self, schema='mysql', format='python', config=''):
        driver=MySQLUtils(config, format=format)
        result=driver.select(statement=MySQLRequest.databaseTablesSQL.format(schema=schema))
        print(result)


    def columns(self, schema='mysql', table='user', format='python', config=''):
        driver=MySQLUtils(config, format=format)
        result=driver.select(statement=MySQLRequest.tableColumnsSQL.format(schema=schema, table=table))
        print(result)


    def generateMdPage(self, config=''):
        driver=MySQLUtils(config, format='python')
        print("h1. Extraction des schemas de données MySQL\n")
        print("\nh2. Informations générales\n")
        print(f"\n - Server: {os.getenv('HOSTNAME')}")
        print(f" - User  : {os.getenv('USER')}")
        info_date=datetime.now().strftime("%d/%m/%Y %H:%M:%S")
        print(f" - Date  : {info_date}\n")

        for schema in [ schema['BASENAME'] for schema in driver.select(statement=MySQLRequest.userDbSQL) ]:
            print(f"\nh2. Description de la base de données '{schema}'\n")
            for table in [ table['TABLE'] for table in driver.select(statement=MySQLRequest.databaseTablesSQL.format(schema=schema)) ]:
                print(f"\nh3. Description de la table '{schema}.{table}'\n")
                self.columns(schema=schema, table=table, format='md',config=config)


if __name__ == '__main__':
  fire.Fire(MySQLRequest)