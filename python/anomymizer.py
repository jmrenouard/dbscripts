#!python3

import faker
import csv
from dotenv import dotenv_values
import mysql.connector
from pprint import pprint
import fire

config = dotenv_values(".env")
#pprint(config)
schema_query = f'''SELECT DISTINCT(table_schema) AS table_schema
FROM information_schema.tables
WHERE table_schema NOT IN ('mysql', 'information_schema', 'performance_schema', 'sys');
'''


def execute_sql(cnx, query):
    out=[]
    with cnx.cursor(dictionary=True) as cursor:
        cursor.execute(query)
        result=cursor.fetchall()
        for row in result:
            out.append(row)
    return out

def get_connection(config):
    # Connect to the database
    cnx = mysql.connector.connect(user=config['SOURCE_MYSQL_USER'],
                                  password=config['SOURCE_MYSQL_PASSWORD'],
                                  host=config['SOURCE_MYSQL_HOST'],
                                  port=config['SOURCE_MYSQL_PORT'],
                                  database='mysql')
    return cnx

def tables(schema=None):
    with get_connection(config) as cnx:
        for current_schema in execute_sql(cnx, schema_query):
            if schema is not None and schema != current_schema['table_schema']:
                continue
            print("-"*40)
            print(f"* {current_schema['table_schema']}")
            print("-"*40)
            for table in execute_sql(cnx, f"SHOW TABLES FROM {current_schema['table_schema']};"):
                print(f"  - {table['Tables_in_'+current_schema['table_schema']]}")

def schemas():
    with get_connection(config) as cnx:
        for schema in execute_sql(cnx, schema_query):
            print(f"* {schema['table_schema']}")

def describe_table(schema, table):
    with get_connection(config) as cnx:
        for column in execute_sql(cnx, f"DESCRIBE {schema}.{table};"):
            print(f"  - {column['Field']}")

def show_table(schema, table):
    with get_connection(config) as cnx:
        for column in execute_sql(cnx, f"SHOW CREATE TABLE {schema}.{table};"):
            print(f"  - {column['Create Table']}")

def export(schema, table, output_file):
    with get_connection(config) as cnx:
        with open(output_file, 'w') as csvfile:
            writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            for column in execute_sql(cnx, f"SELECT * FROM {schema}.{table};"):
                writer.writerow(column.values())


if __name__ == '__main__':
    fire.Fire({
        'schemas': schemas,
        'tables': tables,
        'describe': describe_table,
        'show': show_table,
        'export': export
    })