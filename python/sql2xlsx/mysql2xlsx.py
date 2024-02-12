import xlsxwriter
import mysql.connector
from dotenv import load_dotenv
import argparse
from os import getenv
from pprint import pprint
import datetime
import re

def get_conn(schema='mysql'):
    load_dotenv()
    return mysql.connector.connect(
        host=getenv("host"),
        database=schema,
        user=getenv("user"),
        password=getenv("password")
    )

def fetch_table_data(table_name):
    # The connect() constructor creates a connection to the MySQL server and returns a MySQLConnection object.
    cnx =get_conn()

    cursor = cnx.cursor()
    sql=f"select * from {table_name} LIMIT 16384"
    print(f"Running: {sql}")
    cursor.execute(sql)

    header = [row[0] for row in cursor.description]

    rows = cursor.fetchall()

    # Closing connection
    cnx.close()

    return header, rows

def fetch_table_list(schema):
    cnx =get_conn(schema)
    cursor = cnx.cursor()
    sql='show tables'
    print(f"Running: {sql}")
    cursor.execute(sql)

    result=[row[0] for row in cursor.fetchall()]
    pprint(result)
    # Closing connection
    cnx.close()

    return result

def fetch_schema_list():
    cnx =get_conn()
    cursor = cnx.cursor()
    sql='show databases'
    print(f"Running: {sql}")
    cursor.execute(sql)

    result=[row[0] for row in cursor.fetchall()]
    pprint(result)
    # Closing connection
    cnx.close()

    return result

def open_sheet(sheet_name):
    return xlsxwriter.Workbook(sheet_name + '.xlsx')

def close_sheet(sheet):
    # Closing workbook
    sheet.close()

def export(sheet, table_name):
    # Create an new Excel file and add a worksheet.
    sheetname=table_name
    pprint(sheetname)
    if len(sheetname)>29:
        sheetname=table_name.split('.')[1]
        if len(sheetname)>30:
            sheetname=table_name[0:31]
    pprint(sheetname)
    worksheet = sheet.add_worksheet(sheetname)

    # Create style for cells
    header_cell_format = sheet.add_format({'bold': True, 'border': True, 'bg_color': 'yellow'})
    body_cell_format = sheet.add_format({'border': True})

    header, rows = fetch_table_data(table_name)

    row_index = 0
    column_index = 0
    for column_name in header:
        worksheet.write_string(row_index, column_index, column_name, header_cell_format)
        column_index += 1

    row_index += 1
    for row in rows:
        column_index = 0
        for column in row:
            if isinstance(column, int):
                worksheet.write_number(row_index, column_index, column, body_cell_format)
            elif isinstance(column, datetime.datetime):
                worksheet.write_datetime(row_index, column_index, column, body_cell_format)
            else:
                worksheet.write_string(row_index, column_index, str(column), body_cell_format)

            column_index += 1
        row_index += 1

    print(f"* {row_index} rows written successfully into {table_name} worksheet...")


def export_all(sheet, schema_name):
    for table in fetch_table_list(schema_name):
        if schema_name != "information_schema" and table != "FILES":
            export(sheet, f"{schema_name}.{table}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--schema", type=str, help="target schema")
    parser.add_argument("--table", type=str, help="target table")
    parser.add_argument("--result", type=str, help="target sheetname", default="output")
    args = parser.parse_args()

    sheet=open_sheet(args.result)
    if args.table is not None:
        export(sheet, f"{args.schema}.{args.table}")
    else:
        if args.schema is not None:
            print(f"Exporting schema: {args.schema}")
            for sch in args.schema.split(','):
                export_all(sheet, schema_name=sch)
        else:
            for sch in fetch_schema_list():
                print(f"Exporting schema: {sch}")
                export_all(sheet, schema_name=sch)
    close_sheet(sheet)